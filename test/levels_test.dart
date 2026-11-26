// The levels of the Astute score (lib/data/levels.dart) and the moment one
// is reached (lib/widgets/level_up.dart): the ladder on the score as the
// reader sees it, told once, at a calm moment, never in the middle of a
// card.
//
//   flutter test test/levels_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/levels.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/data/skill_scores.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/level_up.dart';

import 'explore/core_harness.dart';

/// A score as the book keeps it: [now] shown, [yesterday] shown at the end
/// of yesterday, on [answers] answers.
ScoreBook _book(int now, {int? yesterday, int answers = 40}) {
  final List<int> days = List.filled(
    kScoreDays,
    kScoreStart + (yesterday ?? now),
  );
  days[kScoreDays - 1] = kScoreStart + now;
  return ScoreBook(
    overall: SkillScore(now: kScoreStart + now, days: days, answers: answers),
    skills: const {},
  );
}

/// The graded medium cards of the bank, the deal's usual, [n] of them.
List<Pill> _medium(int n) => PillBank.cards
    .where((p) => p.isGraded && p.difficulty == Difficulty.medium)
    .take(n)
    .toList();

/// The reader's judgements as kept: right on each of [cards], today.
String _rightToday(List<Pill> cards) => jsonEncode([
  for (final Pill p in cards)
    {'c': null, 'k': true, 'p': p.id, 'd': dateKey(DateTime.now())},
]);

void main() {
  setUpAll(loadFonts);

  group('the ladder', () {
    test('the shown score starts every reader at 0, and never goes under '
        'it', () {
      expect(shownScore(kScoreStart), 0);
      expect(shownScore(kScoreStart + 24), 24);
      expect(shownScore(kScoreStart - 40), 0);
    });

    test('starts at 0, and each level asks 25 points more than the step '
        'before it: later ones are further apart', () {
      expect(kScoreLevels.first.from, 0);
      expect(
        {for (final ScoreLevel l in kScoreLevels) l.id}.length,
        kScoreLevels.length,
      );
      for (var i = 2; i < kScoreLevels.length; i++) {
        final int step = kScoreLevels[i].from - kScoreLevels[i - 1].from;
        final int before = kScoreLevels[i - 1].from - kScoreLevels[i - 2].from;
        expect(step - before, 25, reason: kScoreLevels[i].id);
      }
    });

    test('a level is the highest whose points the shown score has, once ten '
        'answers are behind it', () {
      expect(levelAt(0, answers: 0), 0);
      expect(levelAt(24, answers: 20), 0);
      expect(levelAt(25, answers: 20), 1);
      expect(levelAt(74, answers: 20), 1);
      expect(levelAt(75, answers: 20), 2);
      expect(levelAt(524, answers: 400), kScoreLevels.length - 2);
      expect(levelAt(525, answers: 400), kScoreLevels.length - 1);
      expect(levelAt(9000, answers: 400), kScoreLevels.length - 1);
      // Three lucky answers on the first day are not a level.
      expect(levelAt(60, answers: kLevelAnswers - 1), 0);
      expect(levelAt(60, answers: kLevelAnswers), 1);
    });

    test('a reader right six times in ten, three answers a day: the first '
        'level within the week, not on the first day; the second days '
        'after it; the third only by getting better', () async {
      await readyApp();
      final List<Pill> cards = _medium(3 * 70);
      // R R W R W, again and again: three right in five.
      const List<bool> pattern = [true, true, false, true, false];
      final DateTime today = DateTime(2026, 11, 25);
      final List<int> levelOn = [];
      final List<Judgement> said = [];
      for (var day = 0; day < 70; day++) {
        final String on = dateKey(
          DateTime(today.year, today.month, today.day - 69 + day),
        );
        for (var i = 0; i < 3; i++) {
          final int k = said.length;
          said.add(
            Judgement(
              null,
              correct: pattern[k % pattern.length],
              pillId: cards[k].id,
              on: on,
            ),
          );
        }
        final SkillScore o = scoresOf(said, today: today).overall;
        levelOn.add(levelAt(shownScore(o.now), answers: o.answers));
      }
      int firstDay(int level) => levelOn.indexWhere((l) => l >= level) + 1;
      expect(levelOn.first, 0);
      expect(firstDay(1), inInclusiveRange(2, 7));
      expect(firstDay(2), greaterThan(firstDay(1) + 3));
      expect(firstDay(2), lessThanOrEqualTo(40));
      expect(levelOn.every((l) => l < 3), isTrue);
    });
  });

  group('told once', () {
    test('a new reader is told the level their answers reach', () {
      final LevelStanding s = LevelStanding.of(
        _book(31, yesterday: 12, answers: 14),
        newReader: true,
      );
      expect(s.at, 1);
      expect(s.due, 1);
    });

    test('a level reached before levels were told stays quiet; one reached '
        'today is told', () {
      // Past Method last night already: nothing to tell.
      final LevelStanding quiet = LevelStanding.of(_book(90, yesterday: 80));
      expect(quiet.due, isNull);
      expect(quiet.told, 2);
      expect(quiet.reached, 2);
      // Over Judgement today: told.
      final LevelStanding today = LevelStanding.of(_book(156, yesterday: 140));
      expect(today.due, 3);
    });

    test('a level told is not told again, and a score that falls under it '
        'does not take it away', () {
      final LevelStanding again = LevelStanding.of(_book(160), told: 3);
      expect(again.due, isNull);
      final LevelStanding fell = LevelStanding.of(_book(120), told: 3);
      expect(fell.at, 2);
      expect(fell.due, isNull);
      expect(fell.reached, 3);
      expect(fell.next!.id, 'insight');
      expect(fell.pointsShort, 250 - 120);
      expect(fell.toNext, 0);
    });

    test('two levels crossed at once: the higher is told', () {
      final LevelStanding s = LevelStanding.of(
        _book(80, yesterday: 0, answers: 12),
        newReader: true,
      );
      expect(s.due, 2);
    });

    test('a reader whose first answer is under a week old is new', () {
      final DateTime today = DateTime(2026, 11, 25);
      Judgement on(int ago) => Judgement(
        null,
        correct: true,
        on: dateKey(DateTime(2026, 11, 25 - ago)),
      );
      expect(isNewReader(const [], today), isTrue);
      expect(isNewReader([on(6), on(0)], today), isTrue);
      expect(isNewReader([on(7), on(0)], today), isFalse);
      expect(
        isNewReader([const Judgement(80, correct: true), on(0)], today),
        isFalse,
      );
    });

    testWidgets('the moment rises once, and a restart does not bring it '
        'back', (tester) async {
      final AppState app = await readyApp({
        'knowit.judgements': _rightToday(_medium(12)),
      });
      await tester.pumpWidget(_host(const SizedBox()));
      Future<bool> tell(AppState who) async {
        final Future<bool> told = showLevelUpIfDue(
          tester.element(find.byKey(const ValueKey('host'))),
          who,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        return told;
      }

      expect(await tell(app), isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('level-up')), findsOneWidget);
      final int told = (await LevelMemory.read())!;
      expect(told, greaterThanOrEqualTo(1));
      expect(
        (await SharedPreferences.getInstance()).getInt(LevelMemory.key),
        told,
      );

      await tester.pump(LevelUpScreen.take);
      await tester.tap(find.byKey(const ValueKey('level-up-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('level-up')), findsNothing);
      expect(await tell(app), isFalse);

      // The phone starts again: the same prefs, a new state.
      final AppState again = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await again.init();
      expect(again.judgements.length, 12);
      expect(await tell(again), isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('level-up')), findsNothing);
    });

    testWidgets('a first look with nothing to tell keeps what counts as told', (
      tester,
    ) async {
      final AppState app = await readyApp({
        'knowit.judgements': _rightToday(_medium(3)),
      });
      await tester.pumpWidget(_host(const SizedBox()));
      final Future<bool> told = showLevelUpIfDue(
        tester.element(find.byKey(const ValueKey('host'))),
        app,
      );
      await tester.pump();
      expect(await told, isFalse);
      expect(await LevelMemory.read(), 0);
    });
  });

  group('never in the middle of a card', () {
    testWidgets('a level reached with a card still on the table waits for '
        'the day to be done, then rises over the shelf, with one tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<String> taps = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            taps.add('${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      // Twelve right today: past the first level, and nothing told yet.
      final AppState app = await readyApp({
        'knowit.plus': true,
        'knowit.judgements': _rightToday(_medium(12)),
      });
      app.todayIndex = app.todaysDeck.length - 1;
      await tester.pumpWidget(
        _host(
          ListenableBuilder(
            listenable: app,
            builder: (_, _) => TodayScreen(app: app),
          ),
        ),
      );
      // The last card on the table, for as long as the reader likes.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(app.todayCompleted, isFalse);
      expect(find.byKey(const ValueKey('level-up')), findsNothing);
      expect(await LevelMemory.read(), isNull);

      // The card thrown on: the day is done, the shelf lands, and then the
      // level.
      unawaited(app.advance());
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(app.todayCompleted, isTrue);
      expect(find.byKey(const ValueKey('level-up')), findsOneWidget);
      await tester.pump(LevelUpScreen.take);
      expect(taps.where((t) => t.contains('mediumImpact')).length, 1);
      expect(await LevelMemory.read(), greaterThanOrEqualTo(1));

      await tester.tap(find.byKey(const ValueKey('level-up-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('level-up')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the screen', () {
    const LevelMoment moment = LevelMoment(
      level: 3,
      score: 158,
      from: 141,
      answers: 120,
      skill: Skill.numbers,
      gain: 34,
    );

    testWidgets('the score counts up to where it stands, the name of the '
        'level, and what got the reader there', (tester) async {
      await tester.pumpWidget(_host(const LevelUpScreen(moment: moment)));
      await tester.pump(const Duration(milliseconds: 700));
      final String counting = tester
          .widget<Text>(find.byKey(const ValueKey('level-up-score')))
          .data!;
      expect(int.parse(counting), inExclusiveRange(141, 158));
      await tester.pump(LevelUpScreen.take);
      expect(find.text('158'), findsOneWidget);
      expect(find.text('Judgement'), findsOneWidget);
      expect(find.text('NEW LEVEL'), findsOneWidget);
      // The skill's name kept on one line.
      expect(
        find.text('Your biggest gain this week: Numbers and statistics, +34'),
        findsOneWidget,
      );
    });

    testWidgets('with less motion, everything where it ends at once', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: LevelUpScreen(moment: moment),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('158'), findsOneWidget);
    });

    testWidgets('with no skill risen, how many answers the score stands on; '
        'in Italian too', (tester) async {
      await tester.pumpWidget(
        _host(
          const LevelUpScreen(
            moment: LevelMoment(level: 1, score: 31, from: 18, answers: 14),
          ),
          language: 'it',
        ),
      );
      await tester.pump(LevelUpScreen.take);
      expect(find.text('Osservazione'), findsOneWidget);
      expect(find.text('14 risposte finora.'), findsOneWidget);
    });

    testWidgets('the level goes out the way the day does: its picture, and '
        'its words with the link', (tester) async {
      final List<String> copied = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(_host(const LevelUpScreen(moment: moment)));
      await tester.pump(LevelUpScreen.take);
      await tester.tap(find.byKey(const ValueKey('level-up-share')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('level-share')), findsOneWidget);
      expect(find.byType(LevelPicture), findsOneWidget);
      expect(find.text('Share your level'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('level-share-copy')));
      await tester.pump();
      expect(copied.single, startsWith('Astute · New level: Judgement\n'));
      expect(copied.single, contains('Astute score 158'));
      expect(copied.single, endsWith('?ref=share_level'));
    });
  });

  group('every language', () {
    for (final Locale locale in AppLocalizations.supportedLocales) {
      testWidgets('the screen and the line fit the smallest phone at a large '
          'text size in ${locale.languageCode}, every level', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (var level = 1; level < kScoreLevels.length; level++) {
          await tester.pumpWidget(
            _host(
              LevelUpScreen(
                moment: LevelMoment(
                  level: level,
                  score: kScoreLevels[level].from + 7,
                  from: kScoreLevels[level].from - 9,
                  answers: 1234,
                  // The longest skill name.
                  skill: Skill.science,
                  gain: 34,
                ),
              ),
              language: locale.languageCode,
            ),
          );
          await tester.pump(LevelUpScreen.take);
          expect(tester.takeException(), isNull, reason: '$level');
        }
        final AppState app = await readyApp({
          'knowit.judgements': _rightToday(_medium(12)),
        });
        await tester.pumpWidget(
          _host(LevelLine(app: app), language: locale.languageCode),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('in Your journey', () {
    testWidgets('the level reached, and how far the next one is', (
      tester,
    ) async {
      final AppState app = await readyApp({
        'knowit.judgements': _rightToday(_medium(12)),
      });
      await tester.pumpWidget(_host(LevelLine(app: app)));
      await tester.pump();
      final LevelStanding s = levelStandingOf(app, null);
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text(_en.scoreLevel(s.level.id)), findsOneWidget);
      expect(
        find.text(
          _en.levelPointsTo(s.pointsShort!, _en.scoreLevel(s.next!.id)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a new reader: how many answers the first level needs', (
      tester,
    ) async {
      final AppState app = await readyApp({
        'knowit.judgements': _rightToday(_medium(4)),
      });
      await tester.pumpWidget(_host(LevelLine(app: app)));
      await tester.pump();
      expect(find.text('Curiosity'), findsOneWidget);
      expect(find.text('6 answers to Observation'), findsOneWidget);
    });
  });
}

/// The English strings, for what the screens say.
final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));

/// The app's own frame around [child], the host the moment rises from.
Widget _host(Widget child, {String language = 'en'}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.light),
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    key: const ValueKey('host'),
    body: SafeArea(child: child),
  ),
);
