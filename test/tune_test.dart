// The reader's own settings and shelves, once the app has been in use: the
// mix fine-tuned from where the reader's likes have moved it, the topics
// editor that leads there, and the archive that holds what the reader saw.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/genre_names.dart';
import 'package:astuto/data/genres.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/screens/topics_screen.dart';
import 'package:astuto/screens/tune_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/ui.dart' show BackCircle;

import 'explore/core_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(402, 874),
  bool calm = false,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: calm),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

/// The fine-tuning's page, the one list it scrolls in.
ScrollPosition _page(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('tune-page')),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

/// The page scrolled to its foot: as far as it goes once all of it has been
/// laid out, which a list built as it comes into view only knows on the way.
Future<void> _toFoot(WidgetTester tester) async {
  for (int i = 0; i < 40; i++) {
    final ScrollPosition page = _page(tester);
    if (i > 0 && (page.pixels - page.maxScrollExtent).abs() < 0.5) break;
    page.jumpTo(page.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The button at the page's foot, scrolled to and tapped.
Future<void> _save(WidgetTester tester) async {
  await _toFoot(tester);
  await tester.tap(find.byKey(const ValueKey('tune-save')));
  await tester.pump(const Duration(milliseconds: 600));
}

/// The page brought to rest with the first subject's parts on screen, and
/// [after] of what follows played.
Future<void> _restOnParts(WidgetTester tester, Duration after) async {
  _page(tester).jumpTo(560);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(after);
}

/// The first subject whose parts the page shows, and the first of them.
Genre _firstPart(WidgetTester tester) =>
    kGenres[tester
            .widgetList<GenreSubject>(find.byType(GenreSubject))
            .first
            .topicKey]!
        .first;

/// The bar of [key], 0 to 100, as the tile draws it.
int _bar(WidgetTester tester, String key) =>
    tester.widget<MixTile>(find.byKey(ValueKey('tune-$key'))).value;

/// Where the reader had the bar of [key], or null where the app has not
/// moved it.
int? _mark(WidgetTester tester, String key) =>
    tester.widget<MixTile>(find.byKey(ValueKey('tune-$key'))).mark;

List<Pill> _of(String topic, int n) =>
    PillBank.cards.where((p) => p.topic == topic).take(n).toList();

void main() {
  setUpAll(loadFonts);

  group('Fine-tuning the mix', () {
    testWidgets('a reader who has liked nothing finds the bars where they '
        'put them, and no marks', (tester) async {
      final AppState app = await readyApp({
        'knowit.topicWeights': jsonEncode({
          for (final s in kMixSubjects) s.key: s.key == 'sport' ? 0.4 : 1.0,
        }),
      });
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      expect(tester.takeException(), isNull);
      expect(_bar(tester, 'space'), 100);
      expect(_bar(tester, 'sport'), 40);
      expect(_mark(tester, 'sport'), isNull);
      expect(find.text('Slide a subject to see more or less of it.'), findsOne);
    });

    testWidgets('likes and throws have already moved the bars, and a mark '
        'keeps where the reader had them', (tester) async {
      final AppState app = await readyApp({
        'knowit.likedIds': [for (final p in _of('Space', 4)) p.id],
        'knowit.dislikedIds': [for (final p in _of('Economics', 3)) p.id],
      });
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      expect(tester.takeException(), isNull);
      // Space, liked, all the way; economics, thrown away, down; the rest
      // close to where they were, a little under it.
      expect(_bar(tester, 'space'), 100);
      expect(_bar(tester, 'economics'), lessThan(_bar(tester, 'nature')));
      expect(_bar(tester, 'nature'), greaterThan(85));
      expect(_mark(tester, 'economics'), 100);
      expect(
        find.text(
          'Already moved by the cards you liked and threw away. '
          'Slide to change it.',
        ),
        findsOne,
      );
    });

    testWidgets('saved untouched, the mix is the reader\'s as it was: the '
        'lean is not counted twice', (tester) async {
      final AppState app = await readyApp({
        'knowit.likedIds': [for (final p in _of('Space', 4)) p.id],
        'knowit.topicWeights': jsonEncode({
          for (final s in kMixSubjects) s.key: s.key == 'art' ? 0.5 : 1.0,
        }),
      });
      final Map<String, double> before = {...app.topicWeights};
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      await _save(tester);
      expect(app.topicWeights, before);
    });

    testWidgets('a bar dragged to nothing takes its subject out of the mix, '
        'and the parts turned off are kept', (tester) async {
      final AppState app = await readyApp();
      await _pump(
        tester,
        TuneScreen(app: app, picked: app.pickedTopics),
        size: const Size(402, 1400),
      );
      final Finder music = find.byKey(const ValueKey('tune-music'));
      await tester.timedDrag(
        music,
        Offset(-tester.getSize(music).width, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pump();
      expect(_bar(tester, 'music'), 0);
      await _save(tester);
      expect(app.pickedTopics.contains('music'), isFalse);
      expect(app.pickedTopics.contains('thinking'), isTrue);
      expect(app.topicWeights.containsKey('music'), isFalse);
    });
  });

  group('One page, and the hint that a part opens', () {
    testWidgets('the whole page scrolls: the title goes up with it, the way '
        'back stays where it is, and the button is the foot of the page', (
      tester,
    ) async {
      final AppState app = await readyApp({'knowit.tuneHoldHint': true});
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      final Finder title = find.byKey(
        const ValueKey('tune-title'),
        skipOffstage: false,
      );
      final Offset back = tester.getTopLeft(find.byType(BackCircle));
      final double titleTop = tester.getTopLeft(title).dy;
      // At rest, the title stands beside the way back.
      expect(
        (tester.getCenter(title).dy -
                tester.getCenter(find.byType(BackCircle)).dy)
            .abs(),
        lessThan(2),
      );
      _page(tester).jumpTo(120);
      await tester.pump();
      expect(tester.getTopLeft(find.byType(BackCircle)), back);
      expect(tester.getTopLeft(title).dy, closeTo(titleTop - 120, 0.5));
      // The button scrolls with the rest: at the foot of the page, and off
      // the screen until the page gets there.
      expect(
        find.byKey(const ValueKey('tune-save')).hitTestable(),
        findsNothing,
      );
      await _toFoot(tester);
      expect(
        tester.getBottomLeft(find.byKey(const ValueKey('tune-save'))).dy,
        greaterThan(874 - 80),
      );
      expect(tester.getTopLeft(find.byType(BackCircle)), back);
    });

    testWidgets('the first time the parts come to rest on screen, the first '
        'of them is pressed and opens what is inside, with a line, folds '
        'again, and never again', (tester) async {
      final AppState app = await readyApp();
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      final BuildContext context = tester.element(find.byType(TuneScreen));
      final String line = context.l10n.tuneHoldHint;
      expect(find.text(line), findsNothing);
      final Genre first = _firstPart(tester);
      final String inside = context.l10n.strandOf(first.strands.first);
      expect(find.text(inside), findsNothing);

      await _restOnParts(tester, const Duration(milliseconds: 1700));
      expect(find.text(line), findsOneWidget);
      expect(find.text(inside), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text(line), findsNothing);
      expect(find.text(inside), findsNothing);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.tuneHoldHint'), isTrue);

      // Opened again, the page does not show it again.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      await _restOnParts(tester, const Duration(milliseconds: 1700));
      expect(find.text(line), findsNothing);
    });

    testWidgets('for a reader who asked for less motion, the hint is its line, '
        'still', (tester) async {
      final AppState app = await readyApp();
      await _pump(
        tester,
        TuneScreen(app: app, picked: app.pickedTopics),
        calm: true,
      );
      final BuildContext context = tester.element(find.byType(TuneScreen));
      await _restOnParts(tester, const Duration(milliseconds: 1700));
      expect(find.text(context.l10n.tuneHoldHint), findsOneWidget);
      expect(
        find.text(context.l10n.strandOf(_firstPart(tester).strands.first)),
        findsNothing,
      );
    });

    testWidgets('a part held opens what is inside it, and the hint is not '
        'owed once the reader has found it', (tester) async {
      final AppState app = await readyApp();
      await _pump(tester, TuneScreen(app: app, picked: app.pickedTopics));
      final BuildContext context = tester.element(find.byType(TuneScreen));
      final Genre first = _firstPart(tester);
      // Held where the page opens, before the hint had its turn.
      await tester.longPress(find.text(context.l10n.themeOf(first)).first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.text(context.l10n.strandOf(first.strands.first)),
        findsOneWidget,
      );
      // At rest on the parts later, nothing is shown: still open as the
      // reader left it, and the hint gone for good.
      await _restOnParts(tester, const Duration(seconds: 2));
      expect(
        find.text(context.l10n.strandOf(first.strands.first)),
        findsOneWidget,
      );
      expect(find.text(context.l10n.tuneHoldHint), findsNothing);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.tuneHoldHint'), isTrue);
    });
  });

  group('The topics editor', () {
    testWidgets('counts the subjects on the grid, not the deck\'s own '
        'Thinking, and leads to the fine-tuning', (tester) async {
      Set<String>? handed;
      await _pump(
        tester,
        TopicsScreen(
          initial: {for (final s in kMixSubjects) s.key, 'thinking'},
          isOnboarding: false,
          onDone: (_) {},
          onFineTune: (picked) async {
            handed = picked;
            return {'space', 'history', 'art', 'thinking'};
          },
        ),
      );
      // Counted once, on the button, not again in grey above it.
      expect(find.text('Save 20 topics'), findsOneWidget);
      expect(find.text('20 selected'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('topics-fine-tune')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(handed, contains('space'));
      // What the fine-tuning saved is what the editor shows on its return.
      expect(find.text('Save 3 topics'), findsOneWidget);
    });
  });

  group('The archive', () {
    testWidgets('holds what the reader saw, and nothing they did not', (
      tester,
    ) async {
      final List<Pill> seen = _of('Space', 3);
      final Pill unseen = _of('Space', 10).last;
      final AppState app = await readyApp({
        'knowit.seenIds': [for (final p in seen) p.id],
      });
      await _pump(tester, ArchiveScreen(app: app, onBack: () {}));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('archive-filter-space')));
      await tester.pump(const Duration(milliseconds: 600));
      for (final Pill p in seen) {
        expect(find.text(p.question), findsOneWidget);
      }
      expect(find.text(unseen.question), findsNothing);
      // A subject none of whose cards were seen has no chip to open.
      expect(find.byKey(const ValueKey('archive-filter-cinema')), findsNothing);
    });
  });
}
