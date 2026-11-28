// The first reading of how sure against how right (AppState.earlyReading,
// `calibration.early`): from the second answer said how sure to the
// eleventh, what they came to so far — the level said most often, the
// higher of two said as often, and how often it was right — marked as a
// first reading, with how many more answers it takes to be measured. On the
// profile, free and Astute+ alike, and in Your journey. Before, the profile
// asked for ten more answers after two and said nothing else.
//
//   flutter test test/early_reading_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/progress.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/theme.dart';

int _docs = 0;

/// The server's word on the first reading.
void _switch({required bool on}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'early-reading-${_docs++}',
      'app': {
        'flags': {'calibration.early': on},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// A reader whose answers said how sure were [said], each a level and
/// whether it was right, on real cards of the bank.
Future<AppState> _app(List<(int, bool)> said, {bool plus = false}) async {
  final cards = PillBank.live.where((p) => p.isGraded).toList();
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.levelTold': 99,
    'knowit.judgements': jsonEncode([
      for (final (int i, (int level, bool right)) in said.indexed)
        {'c': level, 'k': right, 'p': cards[i].id, 'd': '2026-11-2${i % 8}'},
    ]),
  });
  final AppState app = AppState(
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
  setUp(() {
    Remote.reset();
    Remote.fetch = (url) async => null;
    PillBank.fetch = (url) async => null;
  });

  tearDown(Remote.reset);

  group('what it reads', () {
    test('from the second answer to the eleventh: the level said most '
        'often, the higher of two said as often, and how it went', () async {
      EarlyReading? read(AppState app) => app.earlyReading;
      expect(read(await _app([(80, true)])), isNull);
      final EarlyReading two = read(await _app([(80, true), (80, true)]))!;
      expect(
        (two.level, two.count, two.right, two.answers, two.toGo),
        (80, 2, 2, 2, 10),
      );
      final EarlyReading three = read(
        await _app([(80, true), (60, false), (80, false)]),
      )!;
      expect((three.level, three.count, three.right), (80, 2, 1));
      final EarlyReading tie = read(await _app([(60, true), (90, false)]))!;
      expect((tie.level, tie.count, tie.right), (90, 1, 0));
      expect(
        read(await _app([for (var i = 0; i < 11; i++) (70, i.isEven)])),
        isNotNull,
      );
      // From the floor on, the measure itself is said.
      expect(
        read(await _app([for (var i = 0; i < 12; i++) (70, i.isEven)])),
        isNull,
      );
    });

    test('the server can hold it back, and then nothing is read', () async {
      _switch(on: false);
      expect((await _app([(80, true), (80, true)])).earlyReading, isNull);
      _switch(on: true);
      expect((await _app([(80, true), (80, true)])).earlyReading, isNotNull);
    });

    test('in words: every one right, none, or some; as the tester wrote '
        'it in Italian; the level and its sign kept together in German', () {
      final AppLocalizations it = lookupAppLocalizations(const Locale('it'));
      final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
      final AppLocalizations de = lookupAppLocalizations(const Locale('de'));
      expect(
        it.earlyReadingAll(80, 2),
        'Finora: hai detto 80% due volte, e avevi ragione due volte.',
      );
      expect(
        it.earlyReadingSome(80, 3, 2),
        'Finora: hai detto 80% 3 volte, e avevi ragione due volte.',
      );
      expect(
        en.earlyReadingAll(80, 2),
        'So far: you said 80% twice, and you were right twice.',
      );
      expect(
        en.earlyReadingNone(90, 1),
        'So far: you said 90% once, and you were wrong.',
      );
      expect(
        en.earlyReadingSome(70, 5, 1),
        'So far: you said 70% 5 times, and you were right once.',
      );
      expect(de.earlyReadingAll(80, 2), contains('80 %'));
    });
  });

  group('where it is said', () {
    Widget host(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: home,
    );

    testWidgets('the profile, on either plan: marked as a first reading, '
        'with how many more it takes; the measure once there is one', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppLocalizations l = lookupAppLocalizations(const Locale('en'));
      for (final bool plus in [false, true]) {
        final AppState app = await _app([(80, true), (80, true)], plus: plus);
        await tester.pumpWidget(
          host(
            Scaffold(
              body: ProfileScreen(
                app: app,
                account: Account(
                  uidOverride: 'me',
                  boardsOverride: MemoryBoardStore(),
                ),
                onSignedOut: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('calibration-early')), findsOneWidget);
        expect(find.text(l.earlyReadingTag.toUpperCase()), findsOneWidget);
        expect(find.text(l.earlyReadingAll(80, 2)), findsOneWidget);
        expect(find.text(l.journeyOffNotYet(10)), findsOneWidget);
        expect(find.text(l.notEnoughAnswersYet), findsNothing);
      }
      final AppState measured = await _app([
        for (var i = 0; i < 12; i++) (70, i.isEven),
      ]);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: ProfileScreen(
              app: measured,
              account: Account(
                uidOverride: 'me',
                boardsOverride: MemoryBoardStore(),
              ),
              onSignedOut: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('calibration-early')), findsNothing);
      expect(find.text(l.acrossNAnswersHowSure(12)), findsOneWidget);
    });

    testWidgets('Your journey, under How you reason, with how many more '
        'answers it takes to be measured', (tester) async {
      tester.view.physicalSize = const Size(402, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppLocalizations l = lookupAppLocalizations(const Locale('en'));
      final AppState app = await _app([
        (80, true),
        (80, false),
        (60, true),
      ], plus: true);
      await tester.pumpWidget(host(JourneyScreen(app: app, onBack: () {})));
      await tester.pump(const Duration(milliseconds: 500));
      final Finder line = find.byKey(const ValueKey('story-early'));
      expect(line, findsOneWidget);
      expect(
        find.descendant(
          of: line,
          matching: find.text(l.earlyReadingSome(80, 2, 1)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: line,
          matching: find.textContaining(l.storySaidRightToGo(9)),
        ),
        findsOneWidget,
      );
    });
  });
}
