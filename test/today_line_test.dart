// The top of Today on a new reader's second and third days, which said
// nothing and opened exactly as the first: which day it is, how the day
// before went in its own numbers, and the subject met for the first time.
// The freeze, which saved the streak without a word: said on the morning
// after, and on the finished day as one missed day covered. And the streak
// reaching two, three and seven days, risen once, small.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/first_days.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/streak_moment.dart';
import 'package:astuto/widgets/today_line.dart';

/// A new reader whose first day, [first], was read: two of its questions
/// right of two, 70% and 90% sure, the opening's first five read.
Map<String, Object> _afterDayOne(String first) => {
  'knowit.onboarded': true,
  'knowit.firstDays': true,
  'knowit.streak': 1,
  'knowit.bestStreak': 1,
  'knowit.lastCompletionDate': first,
  'knowit.completedDates': <String>[first],
  'knowit.seenIds': <String>[
    for (final FirstCard c in kFirstDays)
      if (c.day == 1) c.id,
  ],
  'knowit.judgements': jsonEncode([
    {'c': 70, 'k': true, 'p': 'food-estimated-weight-mark', 'd': first},
    {'c': 90, 'k': true, 'p': 'psychology-stroop-other-way', 'd': first},
  ]),
};

Future<AppState> _open(DateTime now, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final AppState app = AppState(clock: () => now);
  await app.init();
  return app;
}

void _flags(Map<String, Object?> flags) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'today-line-${flags.hashCode}',
      'app': {'flags': flags},
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// What Today's line says, in [locale].
Future<String?> _line(
  WidgetTester tester,
  AppState app, {
  Locale locale = const Locale('en'),
}) async {
  String? said;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final line = todayLineOf(context, app);
          said = line == null ? null : '${line.lead ?? ''}|${line.text}';
          return const SizedBox();
        },
      ),
    ),
  );
  return said;
}

void main() {
  setUp(() {
    PillBank.reset();
    resetCalendar();
    Remote.reset();
    Remote.fetch = (url) async => null;
  });

  tearDown(Remote.reset);

  group('the line at the top of Today', () {
    testWidgets('on the second day: which day, the day before in its own '
        'numbers, and a subject met for the first time', (tester) async {
      final AppState app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 27, 9), _afterDayOne('2026-11-26')),
      ) as AppState;
      expect(app.dayNumberOf(app.today), 1);
      expect(app.numbersOn('2026-11-26'), (asked: 2, right: 2, sure: 80));
      final List<String> first = app.firstSubjectsToday;
      expect(first, isNotEmpty);
      final String? en = await _line(tester, app);
      expect(
        en,
        'Day 2.|Yesterday 2 of 2, and you were 80% sure. '
        'Today, your first card in ${first.first}.',
      );
      // In Italian the article before the eighty is mended.
      final String? it = await _line(tester, app, locale: const Locale('it'));
      expect(it, startsWith('Giorno 2.|Ieri 2 su 2, ed eri sicuro all’80%.'));
    });

    testWidgets('a day before with no question to count says it was read; '
        'none where the reader never said how sure says no percentage', (
      tester,
    ) async {
      final Map<String, Object> prefs = {..._afterDayOne('2026-11-26')}
        ..remove('knowit.judgements');
      AppState app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 27, 9), prefs),
      ) as AppState;
      expect(
        await _line(tester, app),
        startsWith('Day 2.|Yesterday you read all five.'),
      );
      app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 27, 9), {
          ...prefs,
          'knowit.judgements': jsonEncode([
            {'c': null, 'k': false, 'd': '2026-11-26'},
            {'c': null, 'k': true, 'd': '2026-11-26'},
          ]),
        }),
      ) as AppState;
      expect(await _line(tester, app), startsWith('Day 2.|Yesterday 1 of 2.'));
    });

    testWidgets('"yesterday" is said only of yesterday, only on the opening\'s '
        'second and third days, and not with the switch off', (tester) async {
      // The day before was not read, and no freeze covered it: nothing to
      // say of yesterday.
      AppState app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 28, 9), {
          ..._afterDayOne('2026-11-26'),
          'knowit.freezes': 0,
        }),
      ) as AppState;
      expect(await _line(tester, app), isNull);
      // The fourth day says nothing.
      app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 29, 9), {
          ..._afterDayOne('2026-11-28'),
          'knowit.streak': 3,
          'knowit.completedDates': ['2026-11-26', '2026-11-27', '2026-11-28'],
        }),
      ) as AppState;
      expect(await _line(tester, app), isNull);
      // A reader from before the opening is not told it.
      app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 27, 9), {
          ..._afterDayOne('2026-11-26'),
          'knowit.firstDays': false,
        }),
      ) as AppState;
      expect(await _line(tester, app), isNull);
      _flags({
        'opening.dayLine': {'on': false},
      });
      app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 27, 9), _afterDayOne('2026-11-26')),
      ) as AppState;
      expect(await _line(tester, app), isNull);
    });

    testWidgets('the morning after a freeze kept the streak says so first', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 28, 9), {
          'knowit.onboarded': true,
          'knowit.streak': 5,
          'knowit.bestStreak': 5,
          'knowit.lastCompletionDate': '2026-11-26',
          'knowit.completedDates': [
            for (var d = 22; d <= 26; d++) '2026-11-$d',
          ],
          'knowit.freezes': 1,
        }),
      ) as AppState;
      expect(app.streakWasFrozen, isTrue);
      expect(app.frozeDays, 1);
      expect(app.freezes, 0);
      expect(
        await _line(tester, app),
        '|You skipped yesterday: your streak is safe.',
      );
      expect(
        await _line(tester, app, locale: const Locale('it')),
        '|Ieri l’hai saltato: la tua serie è salva.',
      );
      _flags({
        'streak.told': {'on': false},
      });
      expect(await _line(tester, app), isNull);
    });

    testWidgets('Today sets it under its header, and fits on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppState app = await tester.runAsync(
        () => _open(DateTime(2026, 11, 27, 9), _afterDayOne('2026-11-26')),
      ) as AppState;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: SafeArea(child: TodayScreen(app: app)),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('today-line')), findsOneWidget);
    });
  });

  group('the streak told', () {
    test('a week reached today is due its moment, once; one, two, three, '
        'four or eight never', () async {
      for (final int n in [1, 2, 3, 4, 7, 8]) {
        final AppState app = await _open(DateTime(2026, 11, 28, 21), {
          'knowit.onboarded': true,
          'knowit.streak': n,
          'knowit.bestStreak': n,
          'knowit.lastCompletionDate': '2026-11-28',
          'knowit.completedDates': ['2026-11-28'],
        });
        expect(
          app.streakMomentDue,
          AppState.kStreakMoments.contains(n),
          reason: 'a streak of $n',
        );
        if (!app.streakMomentDue) continue;
        await app.noteStreakTold();
        expect(app.streakMomentDue, isFalse, reason: 'told once: $n');
        // Kept across a restart.
        final AppState again = await _open(DateTime(2026, 11, 28, 22), {
          'knowit.onboarded': true,
          'knowit.streak': n,
          'knowit.lastCompletionDate': '2026-11-28',
          'knowit.completedDates': ['2026-11-28'],
          'knowit.streakTold': ['$n'],
        });
        expect(again.streakMomentDue, isFalse, reason: 'kept: $n');
      }
    });

    test(
      'not before the day is finished, and not with the switch off',
      () async {
        final AppState open = await _open(DateTime(2026, 11, 28, 9), {
          'knowit.onboarded': true,
          'knowit.streak': 7,
          'knowit.lastCompletionDate': '2026-11-27',
          'knowit.completedDates': ['2026-11-26', '2026-11-27'],
        });
        expect(open.streakMomentDue, isFalse);
        _flags({
          'streak.told': {'on': false},
        });
        final AppState off = await _open(DateTime(2026, 11, 28, 21), {
          'knowit.onboarded': true,
          'knowit.streak': 7,
          'knowit.lastCompletionDate': '2026-11-28',
          'knowit.completedDates': ['2026-11-27', '2026-11-28'],
        });
        expect(off.streakMomentDue, isFalse);
      },
    );

    testWidgets('its line: the freezes held, the week\'s one more card on the '
        'free plan, or tomorrow\'s number', (tester) async {
      late BuildContext at;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              at = context;
              return const SizedBox();
            },
          ),
        ),
      );
      String line(int days, int freezes, bool plus) =>
          StreakMomentScreen.lineOf(
            at,
            days: days,
            freezes: freezes,
            plus: plus,
          );
      expect(
        line(2, 1, false),
        'Miss a day and your streak holds: you have 1 freeze.',
      );
      expect(line(3, 0, false), 'Tomorrow makes 4.');
      expect(line(7, 1, false), startsWith('A whole week.'));
      expect(
        line(7, 3, true),
        'Miss a day and your streak holds: you have 3 freezes.',
      );
    });

    testWidgets('the moment shows the streak big, says its line, and goes at '
        'a tap', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                StreakMomentScreen.route(days: 3, freezes: 1, plus: false),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('streak-moment')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('streak-moment-number')))
            .data,
        '3',
      );
      expect(find.text('IN A ROW'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(195, 600));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('streak-moment')), findsNothing);
    });
  });
}
