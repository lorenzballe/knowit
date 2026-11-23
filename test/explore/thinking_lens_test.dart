// Thinking in every subject: Explore narrowed to Thinking holds, with
// Thinking's own cards, the cards of every other subject that train a way
// of reasoning, and Thinking's chip lights up beside a subject's, that
// subject's thinking (lib/explore/explore_block.dart `onSubject`,
// lib/screens/explore_screen.dart `pickSubject`).
//
//   flutter test test/explore/thinking_lens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';

import 'core_harness.dart';

Pill _card(bool Function(Pill p) where) =>
    PillBank.cards.firstWhere((p) => !p.isAboutAPlace && where(p));

void main() {
  late Pill econThinks, econTells, medicineThinks, thinking;

  setUpAll(() async {
    await readyApp();
    econThinks = _card((p) => p.topic == 'Economics' && p.principle.isReal);
    econTells = _card((p) => p.topic == 'Economics' && !p.principle.isReal);
    medicineThinks = _card((p) => p.topic == 'Medicine' && p.principle.isReal);
    thinking = _card((p) => p.topic == 'Thinking');
  });

  group('what each chip holds', () {
    test('a subject: its own cards, as ever', () {
      expect(onSubject(econThinks, 'Economics'), isTrue);
      expect(onSubject(econTells, 'Economics'), isTrue);
      expect(onSubject(medicineThinks, 'Economics'), isFalse);
      expect(onSubject(thinking, 'Economics'), isFalse);
    });

    test('Thinking: its own cards and every subject\'s that train a way of '
        'reasoning', () {
      expect(onSubject(thinking, 'Thinking'), isTrue);
      expect(onSubject(econThinks, 'Thinking'), isTrue);
      expect(onSubject(medicineThinks, 'Thinking'), isTrue);
      expect(onSubject(econTells, 'Thinking'), isFalse);
    });

    test('Thinking with Economics: the economics cards that train one', () {
      bool both(Pill p) => onSubject(p, 'Economics', thinking: true);
      expect(both(econThinks), isTrue);
      expect(both(econTells), isFalse);
      expect(both(medicineThinks), isFalse);
      expect(both(thinking), isFalse);
    });

    test('nothing chosen: every card', () {
      for (final Pill p in [econThinks, econTells, medicineThinks, thinking]) {
        expect(onSubject(p, null), isTrue);
      }
    });
  });

  group('the chips', () {
    (String?, bool) tap(String? name, (String?, bool) now) =>
        pickSubject(name, subject: now.$1, lens: now.$2);

    test('Thinking lit, a subject joins it; Thinking tapped again leaves the '
        'subject; the subject tapped again leaves Thinking', () {
      var now = tap('Thinking', (null, false));
      expect(now, ('Thinking', false));
      now = tap('Economics', now);
      expect(now, ('Economics', true));
      now = tap('Medicine', now);
      expect(now, ('Medicine', true), reason: 'another subject, same lens');
      expect(tap('Thinking', now), ('Medicine', false));
      expect(tap('Medicine', now), ('Thinking', false));
      expect(tap(null, now), (null, false));
    });

    test('a subject lit, Thinking joins it; with Thinking out, one subject '
        'at a time as before', () {
      var now = tap('Economics', (null, false));
      expect(now, ('Economics', false));
      expect(tap('Medicine', now), ('Medicine', false));
      expect(tap('Economics', now), (null, false));
      now = tap('Thinking', now);
      expect(now, ('Economics', true));
    });
  });

  testWidgets('on the screen: Thinking holds every subject\'s thinking, and '
      'lit beside Economics, the economics cards that train it', (
    tester,
  ) async {
    Analytics.useForTest(null);
    Served.useForTest(Served());
    addTearDown(Remote.reset);
    final AppState app = await tester.runAsync(readyApp) as AppState;
    Remote.adopt(
      RemoteConfig(
        hash: 'thinking-lens',
        schema: kRemoteSchema,
        parts: {
          'explore': {
            'sections': [
              {
                'id': 'picked',
                'block': 'list',
                'source': {
                  'ids': [
                    for (final Pill p in [
                      econThinks,
                      econTells,
                      medicineThinks,
                      thinking,
                    ])
                      p.id,
                  ],
                },
              },
            ],
          },
        },
      ),
    );
    tester.view.physicalSize = const Size(390, 2600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(body: ExploreScreen(app: app)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    Finder tile(Pill p) => find.byKey(ValueKey('explore-${p.id}'));
    Future<void> chip(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump(const Duration(milliseconds: 400));
    }

    await chip('subject-Thinking-off');
    expect(find.byKey(const ValueKey('subject-Thinking-on')), findsOneWidget);
    expect(tile(thinking), findsOneWidget);
    expect(tile(econThinks), findsOneWidget);
    expect(tile(medicineThinks), findsOneWidget);
    expect(tile(econTells), findsNothing);

    await chip('subject-Economics-off');
    expect(find.byKey(const ValueKey('subject-Thinking-on')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-Economics-on')), findsOneWidget);
    expect(tile(econThinks), findsOneWidget);
    expect(tile(econTells), findsNothing);
    expect(tile(medicineThinks), findsNothing);
    expect(tile(thinking), findsNothing);

    await chip('subject-Thinking-on');
    expect(find.byKey(const ValueKey('subject-Thinking-off')), findsOneWidget);
    expect(find.byKey(const ValueKey('subject-Economics-on')), findsOneWidget);
    expect(tile(econThinks), findsOneWidget);
    expect(tile(econTells), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
