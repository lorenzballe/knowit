// True stories, played the way a story plays on a phone: a beat at a time,
// the bars filling across the top, a tap on the right on and on the left
// back, a finger held down to stop it and a pull down to close it; a story
// written to be played waiting at its question for a pick; nothing moving
// by itself with animations off or a screen reader on; every beat named
// for a screen reader; and every word of it whole, on a small phone and a
// large one, at the largest text sizes.
//
//   flutter test test/story_player_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/story_player.dart';

/// The faces the app ships, so what is measured is what a reader sees.
Future<void> _loadFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

const Size _small = Size(375, 667);
const Size _large = Size(430, 932);

/// The phone, with the status bar and home bar it has: an SE's bar on the
/// small one, a notch and a home bar on the large ones.
void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  final bool notched = size.height > 700;
  final FakeViewPadding bars = FakeViewPadding(
    top: (notched ? 59 : 20) * 2,
    bottom: notched ? 34 * 2 : 0,
  );
  tester.view.padding = bars;
  tester.view.viewPadding = bars;
  addTearDown(tester.view.reset);
}

/// A story told in its card's words, and one written to be played.
Pill get _told => PillBank.byId('sport-hosting-4')!;
Pill get _written => PillBank.byId('medicine-doctors-who-were-right-1')!;

Widget _host(
  Widget child, {
  bool calm = false,
  bool reader = false,
  double scale = 1,
  Locale? locale,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: calm,
        accessibleNavigation: reader,
        textScaler: TextScaler.linear(scale),
      ),
      child: child,
    ),
  ),
);

/// A button that opens [pill]'s story the way Explore does, in its route.
Widget _opener(Pill pill) => Builder(
  builder: (context) => Center(
    child: TextButton(
      onPressed: () =>
          Navigator.of(context)
              .push(StoryRoute(builder: (_) => StoryPlayer(pill: pill))),
      child: const Text('open'),
    ),
  ),
);

/// How full bar [i] is.
double _bar(WidgetTester tester, int i) => tester
    .widget<FractionallySizedBox>(find.byKey(ValueKey('story-bar-$i')))
    .widthFactor!;

Size _screen(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;

/// A tap on the right of the story, or on its left.
Future<void> _on(WidgetTester tester) async {
  final Size s = _screen(tester);
  await tester.tapAt(Offset(s.width * 0.8, s.height * 0.45));
  await tester.pump();
}

Future<void> _back(WidgetTester tester) async {
  final Size s = _screen(tester);
  await tester.tapAt(Offset(s.width * 0.1, s.height * 0.45));
  await tester.pump();
}

/// Pumps a tenth of a second at a time until [finder] finds something.
Future<void> _until(WidgetTester tester, Finder finder, {int max = 400}) async {
  for (var i = 0; i < max && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

final Finder _end = find.byKey(const ValueKey('story-end'));

/// The hint shown at the foot, as it reads.
String? _hint(WidgetTester tester) {
  final Finder hint = find.descendant(
    of: find.byKey(const ValueKey('story-hint')),
    matching: find.byType(Text),
  );
  if (hint.evaluate().isEmpty) return null;
  return tester.widget<Text>(hint).data;
}

/// Every paragraph on screen that did not get all its words out: cut by
/// its own line limit, or by a box too small for it.
List<String> _cut(WidgetTester tester) {
  final out = <String>[];
  for (final element in find.byType(RichText).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
    final String plain = ro.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    String? how;
    if (ro.didExceedMaxLines) how = 'lines';
    final painter = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      textScaler: ro.textScaler,
      textAlign: ro.textAlign,
      maxLines: ro.maxLines,
    )..layout(maxWidth: ro.softWrap ? ro.size.width : double.infinity);
    if (how == null && painter.height > ro.size.height + 0.5) how = 'height';
    if (how == null && !ro.softWrap && painter.width > ro.size.width + 0.5) {
      how = 'width';
    }
    // A word broken across two lines is a word cut, too.
    if (how == null && ro.softWrap) {
      for (final word in plain.split(RegExp(r'\s+'))) {
        final w = TextPainter(
          text: TextSpan(text: word, style: ro.text.style),
          textDirection: ro.textDirection,
          textScaler: ro.textScaler,
        )..layout();
        if (w.width > ro.size.width + 0.5) how = 'word "$word"';
        w.dispose();
      }
    }
    painter.dispose();
    if (how != null) out.add('"$plain" ($how)');
  }
  return out;
}

/// Words that only fit by scrolling, by however little: a beat that
/// scrolls by less than a line reads as words cut off at the foot.
List<String> _scrolled(WidgetTester tester) => [
  for (final element in find.byType(Scrollable).evaluate())
    if ((element as StatefulElement).state case final ScrollableState state
        when state.position.hasContentDimensions &&
            state.position.maxScrollExtent > 0.5)
      'scrolls by ${state.position.maxScrollExtent.toStringAsFixed(1)}',
];

/// Plays a story through to its last screen by tapping, picking the
/// outcome that came true where it stops to ask.
Future<void> _toTheEnd(WidgetTester tester, Pill pill) async {
  for (var i = 0; i < 12 && _end.evaluate().isEmpty; i++) {
    if (pill.scene case final StoryScene s
        when find.text(s.options[s.answer]).evaluate().isNotEmpty &&
            find.text('YOU').evaluate().isEmpty) {
      await tester.tap(find.text(s.options[s.answer]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    } else {
      await _on(tester);
      await tester.pump(const Duration(milliseconds: 900));
    }
  }
  expect(_end, findsOneWidget);
}

void main() {
  setUpAll(_loadFonts);

  setUp(ExplorePlay.resetForTest);

  group('a story told in its card\'s words', () {
    testWidgets('plays itself a beat at a time, the bars filling, to the '
        'line to keep and what the card offers', (tester) async {
      _phone(tester, _small);
      final Pill p = _told;
      final List<String> beats = toldBeats(p);
      expect(beats.first, p.question);
      await tester.pumpWidget(_host(StoryPlayer(pill: p)));
      await tester.pump();

      // The card's question first, as large as the space takes it, with the
      // subject's mark and name over it as on the card's front.
      expect(find.text(beats[0]), findsOneWidget);
      expect(find.text(p.topic.toUpperCase()), findsOneWidget);
      expect(find.byKey(const ValueKey('story-bar-0')), findsOneWidget);
      expect(
        find.byKey(ValueKey('story-bar-${beats.length - 1}')),
        findsOneWidget,
      );
      expect(_hint(tester), 'Tap to go on · hold to pause');

      // Half the beat gone, half its bar full.
      final int first = beatMs(beats[0]);
      await tester.pump(Duration(milliseconds: first ~/ 2));
      expect(_bar(tester, 0), closeTo(0.5, 0.05));
      expect(_bar(tester, 1), 0);

      // Then on by itself, to the answer a sentence at a time.
      await tester.pump(Duration(milliseconds: first ~/ 2 + 20));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(beats[1]), findsOneWidget);
      expect(find.text(beats[0]), findsNothing);
      expect(_bar(tester, 0), 1);
      // How to go on is said once, on the first beat.
      expect(_hint(tester), isNull);

      await _until(tester, _end);
      for (var i = 0; i < beats.length; i++) {
        expect(_bar(tester, i), 1);
      }
      expect(find.text('WHAT TO KEEP'), findsOneWidget);
      expect(find.text(p.barMove), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Open the card'), findsOneWidget);
      // The last screen stays: there is nowhere further to go by itself.
      await tester.pump(const Duration(seconds: 30));
      expect(_end, findsOneWidget);
    });

    testWidgets('a tap on the right goes on, on the left goes back', (
      tester,
    ) async {
      _phone(tester, _small);
      final List<String> beats = toldBeats(_told);
      await tester.pumpWidget(_host(StoryPlayer(pill: _told)));
      await tester.pump();

      await _on(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(beats[1]), findsOneWidget);
      await _on(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(beats[2]), findsOneWidget);
      expect(_bar(tester, 1), 1);

      await _back(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(beats[1]), findsOneWidget);
      expect(_bar(tester, 2), 0);

      // Back on the first beat plays it again from its start.
      await _back(tester);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1000));
      await _back(tester);
      await tester.pump();
      expect(find.text(beats[0]), findsOneWidget);
      expect(_bar(tester, 0), lessThan(0.05));
    });

    testWidgets('a finger held down stops it; let go, it goes on from there', (
      tester,
    ) async {
      _phone(tester, _small);
      final List<String> beats = toldBeats(_told);
      await tester.pumpWidget(_host(StoryPlayer(pill: _told)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      final double before = _bar(tester, 0);
      expect(before, greaterThan(0));

      final Size s = _screen(tester);
      final TestGesture finger = await tester.startGesture(
        Offset(s.width * 0.6, s.height * 0.5),
      );
      await tester.pump(const Duration(seconds: 30));
      expect(find.text(beats[0]), findsOneWidget);
      expect(_bar(tester, 0), closeTo(before, 0.02));

      // Let go: a hold is not a tap, so the beat stays, and its clock goes
      // on from where it stood.
      await finger.up();
      await tester.pump();
      expect(find.text(beats[0]), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(_bar(tester, 0), greaterThan(before));
      await _until(tester, find.text(beats[1]));
    });

    testWidgets('pulled down far enough it closes; a little, it stays', (
      tester,
    ) async {
      _phone(tester, _small);
      await tester.pumpWidget(_host(_opener(_told)));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(StoryPlayer), findsOneWidget);

      // A little, slowly: it goes back up and plays on.
      await tester.timedDrag(
        find.byKey(const ValueKey('story-player')),
        const Offset(0, 40),
        const Duration(milliseconds: 600),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(StoryPlayer), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('story-player'))).dy,
        0,
      );

      // Far: it goes.
      await tester.drag(
        find.byKey(const ValueKey('story-player')),
        const Offset(0, 320),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StoryPlayer), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('the close button closes it', (tester) async {
      _phone(tester, _small);
      await tester.pumpWidget(_host(_opener(_told)));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('story-close')));
      await tester.pumpAndSettle();
      expect(find.byType(StoryPlayer), findsNothing);
    });

    testWidgets('the last screen keeps, shares and opens the card, and '
        'goes back to the last beat', (tester) async {
      _phone(tester, _small);
      bool saved = false;
      int shared = 0;
      int opened = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => StoryPlayer(
              pill: _told,
              saved: saved,
              onSave: () => setState(() => saved = !saved),
              onShare: () => shared++,
              onOpenCard: () => opened++,
            ),
          ),
        ),
      );
      await tester.pump();
      await _toTheEnd(tester, _told);

      await tester.tap(find.byKey(const ValueKey('story-save')));
      await tester.pump();
      expect(saved, isTrue);
      expect(find.text('Saved'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-share')));
      await tester.pump();
      expect(shared, 1);

      // A tap on the left goes back to the last beat, and on comes back.
      await _back(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_end, findsNothing);
      expect(find.text(toldBeats(_told).last), findsOneWidget);
      await _on(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(_end, findsOneWidget);

      // Opening the card is the last thing: the story gives way to it.
      await tester.tap(find.byKey(const ValueKey('story-open-card')));
      await tester.pump();
      expect(opened, 1);
    });
  });

  group('a story written to be played', () {
    testWidgets('plays its scenes, waits at the question for a pick, then '
        'tells what happened and why', (tester) async {
      _phone(tester, _small);
      final Pill p = _written;
      final StoryScene s = p.scene! as StoryScene;
      await tester.pumpWidget(_host(StoryPlayer(pill: p)));
      await tester.pump();
      expect(find.text(s.scenes[0].fact.toUpperCase()), findsOneWidget);
      // A bar for every stop: the scenes, the question, what happened.
      expect(find.byKey(ValueKey('story-bar-${s.stops - 1}')), findsOneWidget);
      expect(find.byKey(ValueKey('story-bar-${s.stops}')), findsNothing);

      // The scenes play themselves.
      for (var i = 1; i < s.askAt; i++) {
        await _until(tester, find.text(s.scenes[i].fact.toUpperCase()));
      }
      await _until(tester, find.text(s.options.first));

      // The question waits for the reader, however long.
      await tester.pump(const Duration(seconds: 40));
      expect(find.text(s.options.first), findsOneWidget);
      expect(find.text('YOU'), findsNothing);
      expect(_hint(tester), 'Tap your pick');
      // A tap beside the outcomes does not skip it.
      await _on(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('YOU'), findsNothing);

      final int wrong = s.answer == 0 ? 1 : 0;
      await tester.tap(find.text(s.options[wrong]));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);

      // Read, then the last screen; back from it is what happened, which
      // stands.
      await _until(tester, _end);
      expect(find.text(p.barMove), findsOneWidget);
      await _back(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      await _back(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(s.outcome.fact.toUpperCase()), findsOneWidget);
    });

    testWidgets('a tap goes on and back through its scenes', (tester) async {
      _phone(tester, _small);
      final StoryScene s = _written.scene! as StoryScene;
      await tester.pumpWidget(_host(StoryPlayer(pill: _written)));
      await tester.pump();
      await _on(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(s.scenes[1].fact.toUpperCase()), findsOneWidget);
      expect(_bar(tester, 0), 1);
      await _back(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(s.scenes[0].fact.toUpperCase()), findsOneWidget);
      expect(_bar(tester, 1), 0);
    });
  });

  group('for every reader', () {
    testWidgets('with animations off nothing moves by itself: a tap goes on', (
      tester,
    ) async {
      _phone(tester, _small);
      final List<String> beats = toldBeats(_told);
      await tester.pumpWidget(_host(StoryPlayer(pill: _told), calm: true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 40));
      expect(find.text(beats[0]), findsOneWidget);
      expect(_hint(tester), 'Tap to go on');
      expect(tester.hasRunningAnimations, isFalse);

      await _on(tester);
      expect(find.text(beats[1]), findsOneWidget);
      expect(find.text(beats[0]), findsNothing);
      expect(_hint(tester), 'Tap to go on');
      await tester.pump(const Duration(seconds: 40));
      expect(find.text(beats[1]), findsOneWidget);
    });

    testWidgets('a screen reader hears every beat, which it is and what it '
        'says, and taps on through them', (tester) async {
      _phone(tester, _small);
      final SemanticsHandle semantics = tester.ensureSemantics();
      final List<String> beats = toldBeats(_told);
      await tester.pumpWidget(_host(StoryPlayer(pill: _told), reader: true));
      await tester.pump();
      final String first = '1 of ${beats.length}. ${beats[0]}';
      expect(find.bySemanticsLabel(first), findsOneWidget);
      // Nothing moves on while it is being read aloud.
      await tester.pump(const Duration(seconds: 40));
      expect(find.bySemanticsLabel(first), findsOneWidget);
      expect(find.bySemanticsLabel('Close the story'), findsOneWidget);

      tester.semantics.tap(find.semantics.byLabel(first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.bySemanticsLabel('2 of ${beats.length}. ${beats[1]}'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a written story names its stops for a screen reader too', (
      tester,
    ) async {
      _phone(tester, _small);
      final SemanticsHandle semantics = tester.ensureSemantics();
      final StoryScene s = _written.scene! as StoryScene;
      await tester.pumpWidget(_host(StoryPlayer(pill: _written), reader: true));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          '1 of ${s.stops}. ${s.scenes[0].fact}. ${s.scenes[0].line}',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    for (final Size phone in const [_small, _large]) {
      for (final double scale in const [1.0, 1.3, 2.0]) {
        testWidgets('every word whole on a ${phone.width.round()} wide phone '
            'at $scale× text', (tester) async {
          _phone(tester, phone);
          for (final Pill p in [_told, _written]) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(_host(StoryPlayer(pill: p), scale: scale));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 1500));
            final List<String> found = [..._cut(tester), ..._scrolled(tester)];
            for (var i = 0; i < 12 && _end.evaluate().isEmpty; i++) {
              if (p.scene case final StoryScene s
                  when find.text(s.options[s.answer]).evaluate().isNotEmpty &&
                      find.text('YOU').evaluate().isEmpty) {
                found.addAll(_cut(tester));
                await tester.tap(find.text(s.options[s.answer]));
                await tester.pump();
                await tester.pump(const Duration(seconds: 2));
              } else {
                await _on(tester);
                await tester.pump(const Duration(milliseconds: 1200));
              }
              found.addAll([..._cut(tester), ..._scrolled(tester)]);
            }
            expect(_end, findsOneWidget);
            expect(tester.takeException(), isNull);
            expect(found, isEmpty, reason: '${p.id}: $found');
          }
        });
      }
    }

    testWidgets('its words fit in every language on a small phone', (
      tester,
    ) async {
      _phone(tester, _small);
      for (final Locale locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _host(
            StoryPlayer(pill: _told, onOpenCard: () {}),
            locale: locale,
          ),
        );
        await tester.pump();
        final List<String> found = [..._cut(tester)];
        await _toTheEnd(tester, _told);
        found.addAll(_cut(tester));
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(found, isEmpty, reason: '$locale: $found');
      }
    });
  });

  group('on Explore', () {
    Finder down() => find
        .descendant(
          of: find.byType(ExploreScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first;

    Future<String> firstStory(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      await tester.pumpWidget(const AstutoApp());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.byKey(const ValueKey('tab-Explore')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final Finder shelf = find.byKey(const ValueKey('theme-stories-0'));
      final ScrollPosition list = tester
          .state<ScrollableState>(down())
          .position;
      for (var i = 0; i < 80 && shelf.evaluate().isEmpty; i++) {
        list.jumpTo(math.min(list.pixels + 500, list.maxScrollExtent));
        await tester.pump();
      }
      final double top = tester.getTopLeft(shelf).dy;
      list.jumpTo(list.pixels + top - 200);
      await tester.pump(const Duration(milliseconds: 300));
      final Finder tile = find
          .descendant(
            of: shelf,
            matching: find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('explore-'),
            ),
          )
          .first;
      return (tester.widget(tile).key! as ValueKey<String>).value.substring(
        'explore-'.length,
      );
    }

    testWidgets('a story tile plays its story, which counts the card read, '
        'and its last screen opens the card', (tester) async {
      _phone(tester, const Size(402, 874));
      final String id = await firstStory(tester);
      final Pill pill = PillBank.byId(id)!;
      expect(tellsAStory(pill), isTrue);
      final ExploreScreenState explore = tester.state<ExploreScreenState>(
        find.byType(ExploreScreen),
      );
      expect(explore.widget.app.seenIds, isNot(contains(id)));

      // The tile grows into the story.
      await tester.tap(find.byKey(ValueKey('explore-$id')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(StoryPlayer), findsOneWidget);
      expect(explore.widget.app.seenIds, contains(id));

      // Closed, it is back on its shelf, marked read.
      await tester.tap(find.byKey(const ValueKey('story-close')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(StoryPlayer), findsNothing);
      expect(find.byKey(ValueKey('explore-read-$id')), findsWidgets);

      // Played again to its end, the card itself opens in its place.
      await tester.tap(find.byKey(ValueKey('explore-$id')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await _toTheEnd(tester, pill);
      await tester.tap(find.byKey(const ValueKey('story-open-card')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(StoryPlayer), findsNothing);
      expect(find.byType(DeckViewerScreen), findsOneWidget);
      expect(
        tester.widget<DeckViewerScreen>(find.byType(DeckViewerScreen)).deck,
        [pill],
      );
    });
  });
}
