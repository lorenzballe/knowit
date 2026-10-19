import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/measure/card_read.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_gestures.dart';
import 'package:astuto/widgets/web/page_messages.dart';
import 'package:astuto/widgets/web/web_card_page.dart';
import 'package:astuto/widgets/web/web_surface.dart';

/// The kit, put together at once: what the page carries is card_kit_test's
/// to check; here it is enough that the page was asked for with its env.
class _InstantKit extends CardKit {
  final List<PageEnv> asked = [];

  @override
  Future<String> page(String html, PageEnv env) {
    asked.add(env);
    return Future.value('<assembled>$html');
  }
}

Pill _card(
  String id, {
  Challenge challenge = const PageJudged(),
  WebTouch touch = WebTouch.taps,
}) {
  final TopicStyle style = kTopics['medicine']!;
  return Pill(
    id: id,
    topic: style.name,
    color: style.color,
    ink: style.ink,
    tint: style.tint,
    question: 'Which group of children caught the most polio in 1954?',
    answer: 'The children given salt water.',
    barMove: 'Who picks a treatment can matter as much as the treatment.',
    source: 'Francis et al., 1955',
    challenge: challenge,
    web: WebFace(
      html: '<article class="card" id="card"></article><script>Kit.single()</script>',
      touch: touch,
      label: 'A table with three groups of children and ten chips to stake.',
    ),
  );
}

class _Deck extends StatefulWidget {
  const _Deck({
    required this.deck,
    required this.answers,
    required this.stints,
    this.answering = true,
  });

  final List<Pill> deck;
  final List<(String, String, int?)> answers;
  final List<CardStint> stints;
  final bool answering;

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> {
  int index = 0;
  final Map<String, Answer> given = {};

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: PillCardStack(
        deck: widget.deck,
        index: index,
        answering: widget.answering,
        onAdvance: () => setState(() => index++),
        reviewIds: const {},
        answerFor: (id) => given[id],
        onAnswer: (id, response, confidence, reason) {
          widget.answers.add((id, response, confidence));
          given[id] = Answer(response, confidence: confidence);
        },
        onRead: widget.stints.add,
        isSaved: (_) => false,
        onSave: (_) {},
        onShare: (_) {},
      ),
    ),
  );
}

Finder _back() => find.byWidgetPredicate((w) => w is PillCard && w.flipped);

double _pageOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('fake-page')).first,
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    )
    .opacity;

void main() {
  late _InstantKit kit;
  bool readyOnLoad = true;

  setUp(() {
    kit = _InstantKit();
    CardKit.instance = kit;
    readyOnLoad = true;
    FakeWebSurface.reset();
    WebSurfaces.live = 0;
    WebSurfaces.debugUse(() => FakeWebSurface(readyOnLoad: readyOnLoad));
  });

  tearDown(() {
    CardKit.instance = CardKit();
    WebSurfaces.debugUse(null);
  });

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('the poster stands until the page has drawn, then the page', (
    tester,
  ) async {
    readyOnLoad = false;
    await tester.pumpWidget(_Deck(deck: [_card('a')], answers: [], stints: []));
    await settle(tester);

    // The question, drawn natively, under a page not yet shown.
    expect(find.text(_card('a').question), findsWidgets);
    final FakeWebSurface page = FakeWebSurface.made.single;
    expect(page.html, startsWith('<assembled>'));
    expect(_pageOpacity(tester), 0);

    page.say(const PageReady());
    await settle(tester);
    expect(_pageOpacity(tester), 1);
  });

  testWidgets('the page is told where it is, and when it is in front of the '
      'reader', (tester) async {
    await tester.pumpWidget(_Deck(deck: [_card('a')], answers: [], stints: []));
    await settle(tester);

    final PageEnv env = kit.asked.single;
    expect(env.size.width, greaterThan(0));
    expect(env.corner, kCardCorner);
    expect(env.subject?.key, 'medicine');
    expect(env.subject?.name, 'Medicine');
    expect(env.language, 'en');
    expect(FakeWebSurface.made.single.told, anyElement(equals({'t': 'show'})));
  });

  testWidgets('an answer on the page is recorded as a native answer, and the '
      'card stays face up for the page to show why', (tester) async {
    final List<(String, String, int?)> answers = [];
    await tester.pumpWidget(
      _Deck(deck: [_card('a')], answers: answers, stints: []),
    );
    await settle(tester);
    final FakeWebSurface page = FakeWebSurface.made.single;

    // Before it is answered, a tap the page left alone does not turn it:
    // a card that asks is answered first, as every card is.
    page.say(const PageTap());
    await settle(tester);
    expect(_back(), findsNothing);

    page.say(const PageAnswer(choice: 'Salt water', correct: true, sure: 74));
    await settle(tester);
    expect(answers, [('a', '1|Salt water', 70)]);
    expect(_back(), findsNothing);

    // Answered, a tap on nothing turns it, and the back is the card's own.
    page.say(const PageTap());
    await settle(tester);
    expect(_back(), findsOneWidget);
  });

  testWidgets('a card that only tells turns at the first tap', (tester) async {
    await tester.pumpWidget(
      _Deck(
        deck: [_card('a', challenge: const NoChallenge())],
        answers: [],
        stints: [],
      ),
    );
    await settle(tester);
    FakeWebSurface.made.single.say(const PageFlip());
    await settle(tester);
    expect(_back(), findsOneWidget);
  });

  testWidgets('read back on the deck viewer, a page records nothing', (
    tester,
  ) async {
    final List<(String, String, int?)> answers = [];
    await tester.pumpWidget(
      _Deck(deck: [_card('a')], answers: answers, stints: [], answering: false),
    );
    await settle(tester);
    FakeWebSurface.made.single.say(
      const PageAnswer(choice: 'Vaccine', correct: false, sure: 90),
    );
    await settle(tester);
    expect(answers, isEmpty);
  });

  testWidgets('two pages at most: the card on top and the one under it, '
      'and a page done with its card sends it on', (tester) async {
    final List<CardStint> stints = [];
    final List<Pill> deck = [for (final id in 'abcd'.split('')) _card(id)];
    await tester.pumpWidget(_Deck(deck: deck, answers: [], stints: stints));
    await settle(tester);

    expect(WebSurfaces.live, 2);
    expect(FakeWebSurface.made.map((f) => f.html), [
      '<assembled>${deck[0].web!.html}',
      '<assembled>${deck[1].web!.html}',
    ]);
    // The one underneath is drawn, never shown.
    final FakeWebSurface first = FakeWebSurface.made[0];
    final FakeWebSurface second = FakeWebSurface.made[1];
    expect(second.told, isNot(anyElement(equals({'t': 'show'}))));

    first.say(const PageDone());
    await settle(tester);
    await settle(tester);

    expect(stints.single.exit, 'done');
    expect(stints.single.thrown, isTrue);
    expect(first.told.last, {'t': 'hide'});
    expect(first.disposed, isTrue);
    // The next one was ready when it came up: no new page for it, its own
    // shown; and the one after it is drawn now.
    expect(second.loads, 1);
    expect(second.told, anyElement(equals({'t': 'show'})));
    expect(FakeWebSurface.made, hasLength(3));
    expect(WebSurfaces.live, 2);
  });

  testWidgets('a page that never draws is given up on: the card is read '
      'like one that only tells', (tester) async {
    readyOnLoad = false;
    await tester.pumpWidget(_Deck(deck: [_card('a')], answers: [], stints: []));
    await settle(tester);
    await tester.pump(WebCardPage.patience);
    await settle(tester);

    expect(find.text('Tap to reveal'), findsOneWidget);
    await tester.tap(find.text('Tap to reveal'));
    await settle(tester);
    expect(_back(), findsOneWidget);
  });

  testWidgets('taps go to the page, and on a card that takes drags, every '
      'touch that starts where the page holds the finger', (tester) async {
    await tester.pumpWidget(
      _Deck(
        deck: [
          _card('a', touch: WebTouch.drags),
          _card('b'),
        ],
        answers: [],
        stints: [],
      ),
    );
    await settle(tester);
    final FakeWebSurface page = FakeWebSurface.made.first;
    page.say(const PageZones([Rect.fromLTWH(20, 200, 300, 120)]));

    expect(page.gestures, hasLength(2));
    final List<OneSequenceGestureRecognizer> made = [
      for (final f in page.gestures) f.constructor(),
    ];
    final TapGestureRecognizer tap = made
        .whereType<TapGestureRecognizer>()
        .single;
    expect(
      tap.onTap,
      isNotNull,
      reason: 'a tap recogniser with nothing to do never enters the arena',
    );
    final PageZoneRecognizer zone = made.whereType<PageZoneRecognizer>().single;
    expect(
      zone.isPointerAllowed(const PointerDownEvent(position: Offset(100, 250))),
      isTrue,
    );
    expect(
      zone.isPointerAllowed(const PointerDownEvent(position: Offset(100, 40))),
      isFalse,
    );
    for (final r in made) {
      r.dispose();
    }
    // A card that takes only taps is drawn with only the tap.
    expect(FakeWebSurface.made[1].gestures, hasLength(1));
    expect(
      pageGestures(WebTouch.taps, zones: () => const []).single.type,
      TapGestureRecognizer,
    );
  });
}
