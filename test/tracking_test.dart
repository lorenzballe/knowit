// What the app measures under its own events: which screen the reader is
// on, for how long and how far down; how each card was read, to the
// millisecond; what Explore put in front of them; the sitting as a whole;
// the reader's profile; and where the install came from. And what it never
// says.
//
//   flutter test test/tracking_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/measure/card_read.dart';
import 'package:astuto/measure/install.dart';
import 'package:astuto/measure/screens.dart';
import 'package:astuto/measure/session.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/sync/trace.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/place_it.dart';

/// Keeps what the app measures, to be read back.
class _Recorder implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];
  final List<String> screens = [];
  final Map<String, Object> registered = {};
  final Map<String, Object> person = {};
  final Map<String, Object> personOnce = {};

  /// Every write to the profile, as it went: what was set, what set once.
  final List<(Map<String, Object>, Map<String, Object>)> writes = [];
  bool? collecting;

  Map<String, Object>? last(String event) {
    for (final e in events.reversed) {
      if (e.$1 == event) return e.$2;
    }
    return null;
  }

  List<Map<String, Object>> all(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

  List<String> get names => [for (final e in events) e.$1];

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async => screens.add(name);

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async =>
      registered[key] = value;

  @override
  Future<void> setCollecting(bool on) async => collecting = on;

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {
    writes.add((set, setOnce));
    person.addAll(set);
    personOnce.addAll(setOnce);
  }

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A phone's screen, so a card is laid out the size a reader sees it.
void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Out of the app and back, as the phone walks it.
void _background(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _foreground(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// A screen with a long list on it, and a way to push another over it.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'home',
      child: Scaffold(
        body: ListView(
          key: const ValueKey('list'),
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 80, child: Text('row $i')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          key: const ValueKey('push'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => ScreenView(
                name: 'pushed',
                child: Scaffold(
                  body: Center(
                    child: TextButton(
                      key: const ValueKey('back'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('back'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// A deck on a screen of its own, as Today and the viewer draw it, with the
/// screen's presence to turn on and off, and every stint kept.
class _Deck extends StatefulWidget {
  const _Deck({
    required this.deck,
    required this.showing,
    required this.stints,
    this.answering = false,
  });

  final List<Pill> deck;
  final ValueNotifier<bool> showing;
  final List<CardStint> stints;
  final bool answering;

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> {
  final ScreenObserver _observer = ScreenObserver();
  final Map<String, Answer> _answers = {};
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [_observer],
      home: ValueListenableBuilder<bool>(
        valueListenable: widget.showing,
        builder: (context, showing, _) => ScreenView(
          name: 'today',
          showing: showing,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(18),
              child: PillCardStack(
                deck: widget.deck,
                index: _index,
                answering: widget.answering,
                onAdvance: () =>
                    setState(() => _index = (_index + 1) % widget.deck.length),
                reviewIds: const {},
                answerFor: (id) => _answers[id],
                onAnswer: (id, response, confidence, reason) => setState(
                  () => _answers[id] = Answer(
                    response,
                    confidence: confidence,
                    reason: reason,
                  ),
                ),
                isSaved: (_) => false,
                onSave: (_) {},
                onShare: (_) {},
                onRead: widget.stints.add,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Throws the top card off to the left, fast.
Future<void> _throw(WidgetTester tester) async {
  final Rect deck = tester.getRect(find.byType(PillCardStack));
  final gesture = await tester.startGesture(
    Offset(deck.center.dx, deck.top + 90),
  );
  for (var i = 0; i < 6; i++) {
    await gesture.moveBy(const Offset(-26, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _settle(tester);
}

/// An app past the first run, so a day can be read without the onboarding.
Future<AppState> _ready([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
  );
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Recorder sink;

  setUp(() {
    sink = _Recorder();
    Analytics.useForTest(sink);
    Screens.instance.resetForTest();
    Session.instance.resetForTest();
    Trace.useForTest(Trace());
  });

  tearDown(() {
    Analytics.useForTest(null);
    Trace.useForTest(Trace());
  });

  group('every screen is a visit', () {
    testWidgets('one \$screen as it begins, one screen left as it ends, with '
        'the time, the taps, the scroll and the way in and out', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [ScreenObserver()],
          home: const _Home(),
        ),
      );
      await _settle(tester);
      expect(sink.screens, ['home']);

      // Two taps on rows, and one scroll down the list.
      await tester.tap(find.text('row 1'));
      await tester.tap(find.text('row 2'));
      await tester.drag(
        find.byKey(const ValueKey('list')),
        const Offset(0, -900),
      );
      await _settle(tester);

      // A screen pushed over it is a visit of its own; home waits under it.
      await tester.tap(find.byKey(const ValueKey('push')));
      await _settle(tester);
      expect(sink.screens, ['home', 'pushed']);
      expect(sink.all('screen left'), isEmpty);

      await tester.tap(find.byKey(const ValueKey('back')));
      await _settle(tester);
      final pushed = sink.last('screen left')!;
      expect(pushed['screen'], 'pushed');
      expect(pushed['from'], 'home');
      expect(pushed['left_to'], 'home');
      expect(pushed['taps'], 1);
      expect(pushed['ms_on_screen'], isA<int>());
      // Coming back is the same visit to home carrying on: no new $screen.
      expect(sink.screens, ['home', 'pushed']);

      Screens.instance.background();
      final home = sink.last('screen left')!;
      expect(home['screen'], 'home');
      expect(home['from'], 'launch');
      expect(home['left_to'], 'background');
      // The two rows and the button that pushed the other screen; the
      // scroll is a scroll, not a tap.
      expect(home['taps'], 3);
      expect(home['scrolls'], 1);
      expect(home['screens_opened'], 1);
      final int seen = home['max_scroll_pct']! as int;
      expect(seen, greaterThan(0));
      expect(seen, lessThanOrEqualTo(100));
      expect(sink.all('screen left'), hasLength(2));
    });

    testWidgets('a tab is in front only while it is the tab the reader is '
        'on, and leaving it says where to', (tester) async {
      final ValueNotifier<int> tab = ValueNotifier(0);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [ScreenObserver()],
          home: ValueListenableBuilder<int>(
            valueListenable: tab,
            builder: (context, at, _) => Stack(
              children: [
                ScreenView(
                  name: 'one',
                  showing: at == 0,
                  child: const SizedBox.expand(),
                ),
                ScreenView(
                  name: 'two',
                  showing: at == 1,
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(sink.screens, ['one']);

      tab.value = 1;
      await _settle(tester);
      expect(sink.screens, ['one', 'two']);
      final one = sink.last('screen left')!;
      expect(one['screen'], 'one');
      expect(one['left_to'], 'two');
      // A screen that does not scroll says nothing about scrolling far.
      expect(one.containsKey('max_scroll_pct'), isFalse);

      tab.value = 0;
      await _settle(tester);
      final two = sink.last('screen left')!;
      expect(two['screen'], 'two');
      expect(two['from'], 'one');
      expect(two['left_to'], 'one');
    });

    testWidgets('a sheet over a screen is not a screen, and covers nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [ScreenObserver()],
          home: ScreenView(
            name: 'home',
            child: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 200),
                  ),
                  child: const Text('sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('sheet'));
      await _settle(tester);
      expect(sink.screens, ['home']);
      expect(sink.all('screen left'), isEmpty);
      expect(Screens.instance.current, 'home');
    });

    testWidgets('the background ends every visit, each left for the screen '
        'over it, and the one in front comes back as a new visit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [ScreenObserver()],
          home: const _Home(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('push')));
      await _settle(tester);

      Screens.instance.background();
      final left = {
        for (final e in sink.all('screen left'))
          e['screen'] as String: e['left_to'],
      };
      expect(left, {'pushed': 'background', 'home': 'pushed'});

      Screens.instance.foreground();
      await _settle(tester);
      expect(sink.screens, ['home', 'pushed', 'pushed']);
      Screens.instance.background();
      expect(sink.last('screen left')!['from'], 'background');
    });
  });

  group('every card, to the millisecond', () {
    final Pill fact = PillBank.cards.firstWhere(
      (p) => p.challenge is NoChallenge && p.scene == null,
    );
    final Pill estimate = PillBank.cards.firstWhere(
      (p) => p.challenge is Estimate && p.scene == null && p.isGraded,
    );
    // Hints are written for the cards that ask for a number.
    final Pill hinted = PillBank.cards.firstWhere(
      (p) => p.challenge is TypeNumber && p.hasHint && p.scene == null,
    );

    testWidgets('a card turned and thrown says its front, its back, its turn '
        'and how it left', (tester) async {
      _phone(tester);
      final List<CardStint> stints = [];
      await tester.pumpWidget(
        _Deck(
          deck: [fact, estimate],
          showing: ValueNotifier(true),
          stints: stints,
        ),
      );
      await _settle(tester);

      await tester.tap(find.byType(PillCardStack));
      await _settle(tester);
      await _throw(tester);

      final CardStint stint = stints.single;
      expect(stint.pill.id, fact.id);
      expect(stint.thrown, isTrue);
      expect(stint.facts['exit'], isIn(['thrown', 'swiped']));
      expect(stint.facts['flips'], 1);
      expect(stint.facts['ms_front'], isA<int>());
      expect(stint.facts['ms_back'], isA<int>());
      expect(stint.facts['ms_to_flip'], isA<int>());
      expect(stint.facts['ms_to_first_touch'], isA<int>());
      final int back = stint.facts['back_scroll_pct']! as int;
      expect(back, inInclusiveRange(0, 100));
      expect(stint.facts['reread'], isFalse);
      // A card that only tells has no hint to open and no answer to take
      // back, and says neither.
      expect(stint.facts['hint_opened'], isNull);
      expect(stint.facts['options_changed'], isNull);
    });

    testWidgets('a mark moved again on the ruler before it is locked in is '
        'hesitation, counted', (tester) async {
      _phone(tester);
      final List<CardStint> stints = [];
      await tester.pumpWidget(
        _Deck(
          deck: [estimate, fact],
          showing: ValueNotifier(true),
          stints: stints,
          answering: true,
        ),
      );
      await _settle(tester);

      final Finder ruler = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is RulerPainter,
      );
      final Rect at = tester.getRect(ruler.first);
      await tester.tapAt(at.centerLeft + const Offset(30, 0));
      await tester.pump();
      await tester.tapAt(at.centerRight - const Offset(30, 0));
      await tester.pump();
      await tester.tap(find.text('LOCK IT IN'));
      await _settle(tester);
      await tester.tap(find.text('70%'));
      await _settle(tester);
      await _throw(tester);

      final CardStint stint = stints.single;
      expect(stint.facts['options_changed'], 1);
      // Answering turns the card over to its back.
      expect(stint.facts['flips'], 1);
    });

    testWidgets('a hint asked for is said, with how soon', (tester) async {
      _phone(tester);
      final List<CardStint> stints = [];
      await tester.pumpWidget(
        _Deck(
          deck: [hinted, fact],
          showing: ValueNotifier(true),
          stints: stints,
          answering: true,
        ),
      );
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
      await _settle(tester);
      await _throw(tester);

      final CardStint stint = stints.single;
      expect(stint.facts['hint_opened'], isTrue);
      expect(stint.facts['ms_to_hint'], isA<int>());
      // Nothing typed, so nothing taken back, and nothing said about it.
      expect(stint.facts['options_changed'], isNull);
    });

    testWidgets('a card left standing for another tab is said as left for '
        'it, and read anew when the reader is back', (tester) async {
      _phone(tester);
      final ValueNotifier<bool> showing = ValueNotifier(true);
      final List<CardStint> stints = [];
      await tester.pumpWidget(
        _Deck(deck: [fact, estimate], showing: showing, stints: stints),
      );
      await _settle(tester);

      showing.value = false;
      await _settle(tester);
      expect(stints.single.facts['exit'], 'tab');
      expect(stints.single.thrown, isFalse);

      showing.value = true;
      await _settle(tester);
      await _throw(tester);
      expect(stints, hasLength(2));
      expect(stints.last.facts['reread'], isTrue);
      expect(stints.last.thrown, isTrue);

      Screens.instance.background();
      expect(stints.last.pill.id, estimate.id);
      expect(stints.last.facts['exit'], 'background');
    });

    test('the play a card asks for is named: its scene, else its answer', () {
      final Pill scene = PillBank.cards.firstWhere((p) => p.scene != null);
      expect(interactionOf(scene), scene.scene!.raw['type']);
      expect(interactionOf(fact), 'read');
      expect(interactionOf(estimate), 'estimate');
      expect(interactionOf(hinted), 'type_number');
      expect(
        interactionOf(
          PillBank.cards.firstWhere(
            (p) => p.challenge is PickOne && p.scene == null,
          ),
        ),
        'pick_one',
      );
    });

    test('card advanced carries the read, and the trace keeps the time the '
        'card held the reader rather than the time to its turn', () async {
      final app = await _ready();
      final Pill top = app.todaysDeck.first;
      sink.events.clear();

      await app.advance(
        read: const {
          'ms_front': 1200,
          'ms_back': 3400,
          'ms_to_flip': 1200,
          'flips': 1,
          'options_changed': 2,
          'back_scroll_pct': 100,
          'reread': false,
          'exit': 'thrown',
        },
      );

      final advanced = sink.last('card advanced')!;
      expect(advanced['pill_id'], top.id);
      expect(advanced['ms_on_card'], isA<int>());
      expect(advanced['ms_back'], 3400);
      expect(advanced['options_changed'], 2);
      expect(advanced['exit'], 'thrown');
      expect(advanced['interaction'], interactionOf(top));

      final next = Trace.instance.queued.lastWhere((e) => e['e'] == 'next');
      expect(next['ms'], advanced['ms_on_card']);
      expect(next['mf'], 1200);
      expect(next['mb'], 3400);
      expect(next['fl'], 1);
      expect(next['oc'], 2);
      expect(next['bs'], 100);
      expect(next['x'], 'thrown');
    });

    test('a card closed says where it was read and how long it held the '
        'reader in sight', () async {
      final app = await _ready();
      final Pill card = app.todaysDeck.first;
      final CardRead read = CardRead(card);
      read.turned(toBack: true);
      app.cardClosed(read.end('closed'), where: 'explore');

      final closed = sink.last('card closed')!;
      expect(closed['where'], 'explore');
      expect(closed['exit'], 'closed');
      expect(closed['flips'], 1);
      expect(closed['ms_on_card'], isA<int>());
      final close = Trace.instance.queued.lastWhere((e) => e['e'] == 'close');
      expect(close['c'], card.id);
      expect(close['ms'], closed['ms_on_card']);
      expect(close['x'], 'closed');
    });
  });

  group('Explore: what was seen, not only what was opened', () {
    testWidgets('a shelf built beside Today is not seen until Explore is, '
        'and each shelf on screen for a second is said once as the reader '
        'leaves, with what was opened from it', (tester) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      // Explore is built beside Today before anyone opens it. None of what
      // is on it was seen.
      List<Map<String, Object?>> shown() => [
        for (final e in Trace.instance.queued)
          if (e['e'] == 'seen') e,
      ];
      expect(shown(), isEmpty);

      await tester.tap(find.byKey(const ValueKey('tab-Explore')));
      await _settle(tester);
      expect(shown(), isNotEmpty);
      expect(sink.all('explore shelf seen'), isEmpty);

      // A card opened from today's shelf, and closed again.
      final Finder tile = find.descendant(
        of: find.byKey(const ValueKey('watch-today')),
        matching: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('explore-'),
        ),
      );
      await tester.tap(tile.first);
      await _settle(tester);
      expect(find.byType(DeckViewerScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await _settle(tester);

      // A second on the shelves, in the reader's own time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)),
      );
      await tester.tap(find.byKey(const ValueKey('tab-Today')));
      await _settle(tester);

      final shelves = sink.all('explore shelf seen');
      expect(shelves, isNotEmpty);
      final today = shelves.firstWhere((e) => e['shelf'] == 'today');
      expect(today['position'], 1);
      expect(today['ms_visible']! as int, greaterThanOrEqualTo(1000));
      expect(today['tiles_seen']! as int, greaterThan(0));
      expect(today['tiles_opened'], 1);
      expect(today['scrolled_sideways'], isFalse);
      // One event per shelf for the stay, not one per card.
      expect(shelves.map((e) => e['shelf']).toSet(), hasLength(shelves.length));

      // The card read in the viewer, said as closed there.
      final closed = sink.last('card closed')!;
      expect(closed['where'], 'explore');
      expect(closed['exit'], 'closed');

      // And the screens around it: the viewer, opened from Explore and
      // back to it; Explore, one visit with a screen opened from it.
      final left = sink.all('screen left');
      final viewer = left.firstWhere((e) => e['screen'] == 'deck viewer');
      expect(viewer['from'], 'explore');
      expect(viewer['left_to'], 'explore');
      final explore = left.firstWhere((e) => e['screen'] == 'explore');
      expect(explore['screens_opened'], 1);
      expect(explore['left_to'], 'today');

      // The shelf goes into the reader's own trace too, short.
      final shelf = Trace.instance.queued.firstWhere(
        (e) => e['e'] == 'shelf' && e['sh'] == 'today',
      );
      expect(shelf['p'], 1);
      expect(shelf['tk'], 1);
    });
  });

  group('the sitting', () {
    testWidgets('app paused is the session summary, said after every screen '
        'and card still open, and a return is a sitting of its own', (
      tester,
    ) async {
      _phone(tester);
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      // The first card of the start, standing: how long it took.
      final first = sink.last('first card shown')!;
      expect(first['position'], 1);
      expect(first['ms_to_first_card'], isA<int>());
      expect(first['ms_to_deal'], isA<int>());
      expect(sink.last('day started')!['ms_to_deal'], isA<int>());

      await tester.tap(find.byKey(const ValueKey('tab-Explore')));
      await _settle(tester);
      // Today's card was left standing for the tab.
      final standing = sink.last('card closed')!;
      expect(standing['where'], 'today');
      expect(standing['exit'], 'tab');

      _background(tester);
      await tester.pump();
      final paused = sink.last('app paused')!;
      expect(paused['entry'], 'cold start');
      expect(paused['screens'], 2);
      expect(paused['explore_visits'], 1);
      expect(paused['cards_seen'], 1);
      expect(paused['cards_answered'], 0);
      expect(paused['ms_in_app'], isA<int>());
      expect(paused['hour_local'], inInclusiveRange(0, 23));
      expect(paused['weekday'], inInclusiveRange(1, 7));
      // Every screen was said left before the sitting was summed up.
      expect(
        sink.names.lastIndexOf('screen left'),
        lessThan(sink.names.lastIndexOf('app paused')),
      );

      _foreground(tester);
      await _settle(tester);
      expect(sink.screens.last, 'explore');
      _background(tester);
      await tester.pump();
      final again = sink.last('app paused')!;
      expect(again['entry'], 'warm resume');
      expect(again['screens'], 1);
      expect(again['explore_visits'], 1);
    });

    test('a reminder or a widget that opened the app is how the sitting '
        'began', () {
      Session.instance.cameFrom('notification');
      expect(Session.instance.end()['entry'], 'notification');
      Session.instance.cameFrom('widget');
      Session.instance.begin();
      expect(Session.instance.end()['entry'], 'widget');
      Session.instance.begin();
      expect(Session.instance.end()['entry'], 'warm resume');
    });

    test('a frame that took longer than the screen allows is late', () {
      final FrameMeter meter = FrameMeter()..budgetMicros = 16667;
      FrameTiming frame(int buildMicros, int rasterMicros) => FrameTiming(
        vsyncStart: 0,
        buildStart: 0,
        buildFinish: buildMicros,
        rasterStart: buildMicros,
        rasterFinish: buildMicros + rasterMicros,
        rasterFinishWallTime: buildMicros + rasterMicros,
      );
      expect(meter.said(), isEmpty);
      meter.add([frame(4000, 5000), frame(20000, 3000), frame(3000, 40000)]);
      expect(meter.said(), {
        'frames': 3,
        'janky_frames': 2,
        'ms_worst_frame': 40,
      });
    });
  });

  group('the reader, on every event and on their profile', () {
    test('every event carries the plan, the streak as a band, what the '
        'phone lets the app do, and how long ago it was installed', () async {
      final app = await _ready();
      expect(app.installedOn, isNotEmpty);
      expect(sink.registered['days_since_install'], 0);
      expect(sink.registered['streak_bucket'], '0');
      expect(sink.registered['notifications'], 'not asked');
      expect(sink.registered['dark_mode'], isA<bool>());
      expect(AppState.streakBucket(1), '1-2');
      expect(AppState.streakBucket(7), '7-13');
      expect(AppState.streakBucket(30), '30+');
      expect(textScaleBucket(1.0), 'default');
      expect(textScaleBucket(1.4), 'larger');
      expect(textScaleBucket(2.0), 'largest');
    });

    test('the plan is on every event and on the profile, at once: in a '
        'trial, paid, or none', () async {
      final Subscription store = Subscription(keyOverride: '');
      EntitlementInfo plus(PeriodType period, String product) =>
          EntitlementInfo(
            kPlusEntitlement,
            true,
            true,
            DateTime.now().toUtc().toIso8601String(),
            DateTime.now().toUtc().toIso8601String(),
            product,
            true,
            periodType: period,
          );

      store.noteForTest(null, active: false);
      await pumpEventQueue();
      expect(sink.registered['plan'], 'free');
      expect(sink.registered['is_trial'], false);
      expect(sink.person['plan_period'], 'none');
      expect(sink.person['is_trial'], false);

      store.noteForTest(
        plus(PeriodType.trial, 'astuto_pro_year'),
        active: true,
      );
      await pumpEventQueue();
      expect(sink.registered['is_trial'], true);
      expect(sink.registered['plan'], 'year');
      expect(sink.person['is_trial'], true);
      expect(sink.person['plan_period'], 'trial');

      store.noteForTest(
        plus(PeriodType.normal, 'astuto_pro_month'),
        active: true,
      );
      await pumpEventQueue();
      expect(sink.person['is_trial'], false);
      expect(sink.person['plan_period'], 'normal');
      expect(sink.person['plan'], 'month');
    });

    test('the profile is written once for what changed, and what is true '
        'from the start is written once ever', () async {
      SharedPreferences.setMockInitialValues({});
      await Analytics.person(
        set: {'streak_days': 2, 'saved_count': 1},
        setOnce: {'install_date': '2026-10-01'},
      );
      // Nothing yet: the profile waits for the app to leave the screen.
      expect(sink.writes, isEmpty);
      await Analytics.flushPerson();
      expect(sink.writes, hasLength(1));
      expect(sink.writes.single.$2, {'install_date': '2026-10-01'});

      // Moved again soon after: held for the next sitting's end.
      await Analytics.person(set: {'streak_days': 3, 'saved_count': 1});
      await Analytics.flushPerson();
      expect(sink.writes, hasLength(1));

      // Written, it says only what moved; and never the first day twice.
      await Analytics.person(
        set: {'streak_days': 3, 'saved_count': 1},
        setOnce: {'install_date': '2026-10-02'},
      );
      await Analytics.flushPerson(force: true);
      expect(sink.writes, hasLength(2));
      expect(sink.writes.last.$1, {'streak_days': 3});
      expect(sink.writes.last.$2, isEmpty);

      // And nothing at all when nothing moved.
      await Analytics.person(set: {'streak_days': 3});
      await Analytics.flushPerson(force: true);
      expect(sink.writes, hasLength(2));

      // Kept on the phone: a new launch does not say it all again.
      final prefs = await SharedPreferences.getInstance();
      final kept = jsonDecode(prefs.getString('knowit.analytics.person')!);
      expect((kept as Map)['set'], {'streak_days': 3, 'saved_count': 1});
    });

    test('a reader who turned measurement off has nothing written for them '
        'meanwhile, and their profile is said whole when they turn it back '
        'on', () async {
      SharedPreferences.setMockInitialValues({});
      await Analytics.setCollecting(false);
      await Analytics.person(set: {'streak_days': 4}, now: true);
      await Analytics.setCollecting(true);
      await Analytics.person(set: {'streak_days': 4}, now: true);
      expect(sink.writes.last.$1, {'streak_days': 4});
    });

    test('the reader as a reader: the subjects read most, how sure against '
        'how right, how much answered, and the first day finished', () async {
      final List<Pill> read = [
        ...PillBank.cards.where((p) => p.topic == 'Space').take(3),
        ...PillBank.cards.where((p) => p.topic == 'History').take(2),
        ...PillBank.cards.where((p) => p.topic == 'Psychology').take(1),
      ];
      final String today = dateKey(DateTime.now());
      final app = await _ready({
        'knowit.seenIds': [for (final p in read) p.id],
        'knowit.completedDates': [today],
        'knowit.judgements': jsonEncode([
          for (var i = 0; i < 12; i++)
            {'c': 80, 'k': i < 6, 'p': read[i % read.length].id, 'd': today},
        ]),
      });

      final facts = app.readerFacts;
      expect(facts['top_subjects'], 'Space,History,Psychology');
      expect(facts['top_subject'], 'Space');
      expect(facts['avg_sure'], 80);
      expect(facts['pct_right'], 50);
      expect(facts['calibration_gap'], 30);
      expect(facts['answers_count'], 0);
      expect(facts['last_active_local_hour'], inInclusiveRange(0, 23));
      expect(app.analyticsProfileOnce['first_day_completed'], today);
      expect(app.analyticsProfileOnce['install_date'], isA<String>());
    });
  });

  group('where the install came from', () {
    test('each phone, each store, each robot', () {
      String channel(
        ToolsPlatform platform, {
        bool debug = false,
        bool testFlight = false,
        String? installer,
        bool testLab = false,
      }) => installChannelFor(
        platform: platform,
        debugMode: debug,
        testFlight: testFlight,
        installer: installer,
        testLab: testLab,
      );

      expect(channel(ToolsPlatform.iOS, testFlight: true), 'testflight');
      expect(channel(ToolsPlatform.iOS), 'app_store');
      expect(channel(ToolsPlatform.iOS, debug: true), 'debug');
      expect(
        channel(ToolsPlatform.android, installer: 'com.android.vending'),
        'play',
      );
      expect(channel(ToolsPlatform.android), 'sideload');
      expect(
        channel(ToolsPlatform.android, installer: 'com.amazon.venezia'),
        'sideload',
      );
      // A test lab's phone is a robot, whoever installed the app on it.
      expect(
        channel(
          ToolsPlatform.android,
          installer: 'com.android.vending',
          testLab: true,
        ),
        'test_lab',
      );
      expect(channel(ToolsPlatform.android, debug: true), 'debug');
      expect(channel(ToolsPlatform.web), 'web');
      expect(isTestChannel('test_lab'), isTrue);
      expect(isTestChannel('debug'), isTrue);
      expect(isTestChannel('play'), isFalse);
      expect(isTestChannel('testflight'), isFalse);
    });

    group('asking the phone', () {
      const MethodChannel install = MethodChannel('astut/install');
      final TestDefaultBinaryMessenger messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      tearDown(() => messenger.setMockMethodCallHandler(install, null));

      Future<String> android() =>
          readInstallChannel(debugMode: false, platform: ToolsPlatform.android);

      test('an Android phone says which store installed it, and whether it '
          'is a test lab\'s', () async {
        messenger.setMockMethodCallHandler(
          install,
          (call) async => call.method == 'installSource'
              ? {'installer': 'com.android.vending', 'testLab': false}
              : null,
        );
        expect(await android(), 'play');

        messenger.setMockMethodCallHandler(
          install,
          (call) async => {'installer': 'com.android.vending', 'testLab': true},
        );
        expect(await android(), 'test_lab');

        messenger.setMockMethodCallHandler(
          install,
          (call) async => {'installer': null, 'testLab': false},
        );
        expect(await android(), 'sideload');
      });

      test('a phone that cannot say, or will not in time, is a sideload, '
          'and launch waits no longer than the bound', () async {
        // Nothing behind the channel.
        expect(await android(), 'sideload');

        messenger.setMockMethodCallHandler(
          install,
          (call) => Completer<Object?>().future,
        );
        final Stopwatch took = Stopwatch()..start();
        expect(await android(), 'sideload');
        expect(took.elapsed, lessThan(const Duration(seconds: 2)));
      });

      test('an iPhone is asked about TestFlight, and a debug build is a '
          'debug build anywhere', () async {
        expect(
          await readInstallChannel(
            debugMode: false,
            platform: ToolsPlatform.iOS,
            testFlight: () async => true,
          ),
          'testflight',
        );
        expect(
          await readInstallChannel(
            debugMode: false,
            platform: ToolsPlatform.iOS,
            testFlight: () async => false,
          ),
          'app_store',
        );
        expect(kDebugMode, isTrue, reason: 'tests run as a debug build');
        expect(await readInstallChannel(), 'debug');
      });
    });

    test('stamped on every event and on the profile at once; a robot or a '
        'developer is marked as no reader at all', () async {
      SharedPreferences.setMockInitialValues({});
      await Analytics.installedFrom('test_lab');
      expect(sink.registered['install_channel'], 'test_lab');
      expect(sink.person, {
        'install_channel': 'test_lab',
        r'$internal_or_test_user': true,
      });

      final _Recorder reader = _Recorder();
      Analytics.useForTest(reader);
      SharedPreferences.setMockInitialValues({});
      await Analytics.installedFrom('play');
      expect(reader.registered['install_channel'], 'play');
      expect(reader.person, {'install_channel': 'play'});
    });
  });

  group('never', () {
    testWidgets('anything the reader writes: a reason typed on a card goes '
        'nowhere near a card\'s read', (tester) async {
      _phone(tester);
      final Pill side = PillBank.cards.firstWhere(
        (p) => p.challenge is TakeASide && p.scene == null,
      );
      final Pill fact = PillBank.cards.firstWhere(
        (p) => p.challenge is NoChallenge && p.scene == null,
      );
      final List<CardStint> stints = [];
      await tester.pumpWidget(
        _Deck(
          deck: [side, fact],
          showing: ValueNotifier(true),
          stints: stints,
          answering: true,
        ),
      );
      await _settle(tester);

      final TakeASide challenge = side.challenge as TakeASide;
      await tester.tap(find.text(challenge.positions.first));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'because my aunt said');
      await _settle(tester);
      await tester.tap(find.text('Now show me the other side'));
      await _settle(tester);
      await _throw(tester);
      expect(stints, isNotEmpty);

      final String said = [
        for (final CardStint s in stints) s.facts.toString(),
        for (final e in sink.events) '${e.$1} ${e.$2}',
        sink.screens.join(' '),
      ].join(' ');
      expect(said, isNot(contains('aunt')));
    });
  });
}
