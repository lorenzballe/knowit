// The reader's own settings and shelves, once the app has been in use: the
// mix fine-tuned from where the reader's likes have moved it, the topics
// editor that leads there, and the archive that holds what the reader saw.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/screens/topics_screen.dart';
import 'package:astuto/screens/tune_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import 'explore/core_harness.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(402, 874),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: child,
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

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
      await tester.tap(find.byKey(const ValueKey('tune-save')));
      await tester.pump(const Duration(milliseconds: 600));
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
      await tester.tap(find.byKey(const ValueKey('tune-save')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(app.pickedTopics.contains('music'), isFalse);
      expect(app.pickedTopics.contains('thinking'), isTrue);
      expect(app.topicWeights.containsKey('music'), isFalse);
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
