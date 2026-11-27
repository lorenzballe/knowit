import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/card_ask.dart';
import 'package:astuto/sync/coach.dart';
import 'package:astuto/theme.dart';

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState();
  await app.init();
  return app;
}

/// Judgements on the cards of one subject: so many said at [sure], the
/// first [right] of them right, [daysAgo] days back.
List<Map<String, Object>> _said(
  String topic,
  int count, {
  required int sure,
  required int right,
  int daysAgo = 0,
  int skip = 0,
}) {
  final List<Pill> cards = PillBank.live
      .where((p) => p.topic == topic)
      .skip(skip)
      .take(count)
      .toList();
  final String on = dateKey(DateTime.now().subtract(Duration(days: daysAgo)));
  return [
    for (var i = 0; i < cards.length; i++)
      {'c': sure, 'k': i < right, 'p': cards[i].id, 'd': on},
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final String topic = PillBank.live.first.topic;

  group('what the week says, in one sentence', () {
    test('how often they were right when sure, once five such answers are '
        'in, in tens; and against last week when it says something', () async {
      final app = await _app({
        'knowit.judgements': jsonEncode([
          // Last Friday: inside last week whatever day today is.
          ..._said(
            topic,
            6,
            sure: 80,
            right: 3,
            daysAgo: DateTime.now().weekday - 1 + 3,
          ),
          ..._said(topic, 5, sure: 90, right: 4, skip: 6),
        ]),
      });
      final StoryHeadline h = storyHeadline(app);
      expect(h.kind, StoryHeadlineKind.sure);
      expect(h.n, 8);
      // Last week was 3 in 6; this week 4 in 5: better.
      expect(h.better, isTrue);
    });

    test('then a run of days, then the strongest subject, then what was '
        'read', () async {
      final streak = await _app({
        'knowit.streak': 4,
        'knowit.lastCompletionDate': dateKey(DateTime.now()),
      });
      expect(storyHeadline(streak).kind, StoryHeadlineKind.streak);

      final strong = await _app({
        'knowit.judgements': jsonEncode(_said(topic, 6, sure: 60, right: 5)),
      });
      expect(storyHeadline(strong).kind, StoryHeadlineKind.strong);

      final fresh = await _app({});
      expect(storyHeadline(fresh).kind, StoryHeadlineKind.read);
      expect(storyHeadline(fresh).n, 0);
    });

    group('what was read, past the first day, with the week', () {
      final DateTime now = DateTime.now();
      String ago(int d) => dateKey(DateTime(now.year, now.month, now.day - d));
      // A day of the week before this one, whatever today is.
      final String lastWeek = ago(now.weekday + 2);
      final List<String> ids = PillBank.live.take(13).map((p) => p.id).toList();
      Future<AppState> reading(
        Map<String, List<String>> days, {
        Map<String, Object> also = const {},
      }) => _app({
        'knowit.seenIds': [for (final d in days.values) ...d],
        'knowit.readDays': jsonEncode(days),
        ...also,
      });

      test('this week\'s share of it, all of it, or none yet; on the first '
          'day, where the journey starts', () async {
        // Ten last week, three today.
        final some = await reading({
          lastWeek: ids.take(10).toList(),
          ago(0): ids.skip(10).toList(),
        });
        StoryHeadline h = storyHeadline(some);
        expect(h.kind, StoryHeadlineKind.read);
        expect([h.n, h.week, h.firstDay], [13, 3, false]);
        expect(weekCards(some).map((p) => p.id), ids.skip(10));

        // Ten last week, none since.
        h = storyHeadline(await reading({lastWeek: ids.take(10).toList()}));
        expect([h.n, h.week, h.firstDay], [10, 0, false]);

        // Three today, on a record that started last week.
        h = storyHeadline(
          await reading(
            {ago(0): ids.take(3).toList()},
            also: {
              'knowit.dayLog': jsonEncode({
                lastWeek: [0, 0, 0, 0, 0, 0],
              }),
            },
          ),
        );
        expect([h.n, h.week, h.firstDay], [3, 3, false]);

        // Three today, and nothing before: the first day.
        h = storyHeadline(await reading({ago(0): ids.take(3).toList()}));
        expect([h.n, h.firstDay], [3, true]);
      });

      test('said so in the reader\'s language', () {
        final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
        final AppLocalizations it = lookupAppLocalizations(const Locale('it'));
        expect(en.storyHeadlineReadWeek(32, 9), '32 cards read, 9 this week.');
        expect(
          it.storyHeadlineReadWeek(32, 9),
          '32 carte lette, 9 questa settimana.',
        );
        expect(
          it.storyHeadlineReadWeek(32, 0),
          '32 carte lette, nessuna ancora questa settimana.',
        );
        expect(
          it.storyHeadlineReadWeek(32, 1),
          '32 carte lette, una questa settimana.',
        );
        expect(
          it.storyHeadlineReadAllWeek(12),
          '12 carte lette, tutte questa settimana.',
        );
        // The first day keeps its line.
        expect(
          it.storyHeadlineRead(5),
          '5 carte lette. Il percorso comincia qui.',
        );
      });

      testWidgets('the headline on the page', (tester) async {
        tester.view.physicalSize = const Size(402, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final app = await reading({
          lastWeek: ids.take(10).toList(),
          ago(0): ids.skip(10).toList(),
        });
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.dark),
            home: JourneyScreen(app: app, onBack: () {}),
          ),
        );
        await tester.pump();
        expect(find.text('13 cards read, 3 this week.'), findsOneWidget);
        expect(find.textContaining('starts here'), findsNothing);
      });
    });
  });

  test('where the reader trusts themselves too much: the subject whose said '
      'confidence runs furthest past its accuracy, once six are in', () async {
    final app = await _app({
      'knowit.judgements': jsonEncode([
        // Said 90, right half the time: forty points over.
        ..._said(topic, 6, sure: 90, right: 3),
      ]),
    });
    final over = overconfidentIn(app);
    expect(over, isNotNull);
    expect(over!.points, 40);

    final calibrated = await _app({
      'knowit.judgements': jsonEncode(_said(topic, 6, sure: 50, right: 3)),
    });
    expect(overconfidentIn(calibrated), isNull);
  });

  testWidgets('with the answers by Claude on, the coach comes after the '
      'week: on Astute+ the week\'s note a tap away, sent as numbers; on '
      'the free plan, what it is behind the lock', (tester) async {
    tester.view.physicalSize = const Size(402, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    debugToolsOn = true;
    addTearDown(() => debugToolsOn = false);
    Coach.kept.clear();
    Map<String, Object?>? sent;
    Coach.call = (week, language, stats) async {
      sent = stats;
      return const AskAnswer('A good week: 8 in 10 right when sure.');
    };
    addTearDown(
      () => Coach.call = (w, l, s) async => const AskNone(AskWhyNot.later),
    );
    Future<void> show(AppState app) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: JourneyScreen(app: app, onBack: () {}),
      ),
    );
    final plus = await _app({
      'knowit.plus': true,
      'knowit.judgements': jsonEncode(_said(topic, 6, sure: 90, right: 5)),
    });
    await show(plus);
    await tester.pump();
    expect(find.text('2  ·  PRACTISE'), findsOneWidget);
    expect(find.text('3  ·  THIS WEEK'), findsOneWidget);
    expect(find.text('4  ·  YOUR COACH'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey-coach-ask')));
    // The coach's outline keeps turning, so the page never settles: the
    // answer is waited for a frame at a time.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('A good week: 8 in 10 right when sure.'), findsOneWidget);
    expect(sent?['sure'], 8);
    expect(sent!.keys, containsAll(['read', 'days', 'streak', 'missed']));

    final free = await _app({});
    await show(free);
    await tester.pump();
    expect(find.byKey(const ValueKey('journey-coach-locked')), findsOneWidget);
  });

  testWidgets('the journey reads in chapters: the one number, what to '
      'practise and the week first, then the story, and the week to go '
      'over again last; on the free plan the line Astute+ shows sits behind '
      'glass with the way through', (tester) async {
    tester.view.physicalSize = const Size(402, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final List<Map<String, Object>> said = [
      ..._said(topic, 6, sure: 90, right: 3),
      ..._said(PillBank.live.last.topic, 6, sure: 70, right: 6),
    ];
    final app = await _app({
      'knowit.seenIds': [for (final j in said) j['p']! as String],
      'knowit.judgements': jsonEncode(said),
      'knowit.reactions': jsonEncode({PillBank.live.first.id: 'changed'}),
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: JourneyScreen(app: app, onBack: () {}),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    // One number at the head, what to practise right under it, what the
    // reader knows before how they reason; what stays with them only once
    // something has.
    final bool stays = find
        .textContaining('WHAT STAYS WITH YOU')
        .evaluate()
        .isNotEmpty;
    final List<String> chapters = [
      '1  ·  YOUR TRAINING',
      '2  ·  PRACTISE',
      '3  ·  THIS WEEK',
      '4  ·  WHAT YOU KNOW',
      '5  ·  HOW YOU REASON',
      '6  ·  YOUR HABITS',
      if (stays) '7  ·  WHAT STAYS WITH YOU',
      stays ? '8  ·  YOUR STORY' : '7  ·  YOUR STORY',
      stays ? '9  ·  REVIEW THE WEEK' : '8  ·  REVIEW THE WEEK',
    ];
    double last = -1;
    for (final String c in chapters) {
      expect(find.text(c), findsOneWidget, reason: c);
      final double y = tester.getTopLeft(find.text(c)).dy;
      expect(y, greaterThan(last), reason: '$c comes after the one before');
      last = y;
    }
    // The one number is the Astute score, in the first chapter; the points
    // and the ladder that repeated it are gone.
    expect(find.byKey(const ValueKey('training-score')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-score')), findsNothing);
    expect(find.textContaining('WHERE YOU ARE'), findsNothing);
    expect(find.text('See it with Astute+'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-practice-misses')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-practice-changed')),
      findsOneWidget,
    );
  });

  testWidgets('a miss practised from the journey is asked afresh: a question '
      'again, its back says how this answer went, and the first answer and '
      'the day it comes back stand', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Pill card = PillBank.live.firstWhere(
      (p) => !p.hasPage && p.challenge is PickOne && p.isGraded,
    );
    final PickOne pick = card.challenge as PickOne;
    final String wrong = '${(pick.correct + 1) % pick.options.length}';
    final DateTime now = DateTime.now();
    final String today = dateKey(now);
    final String back = dateKey(now.add(const Duration(days: 2)));
    final app = await _app({
      'knowit.seenIds': [card.id],
      'knowit.answersJson': jsonEncode({
        card.id: {'r': wrong, 'c': 80, 'd': back},
      }),
      'knowit.judgements': jsonEncode([
        {'c': 80, 'k': false, 'p': card.id, 'd': today},
      ]),
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: JourneyScreen(app: app, onBack: () {}),
      ),
    );
    await tester.pump();
    Future<void> wait() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final Finder row = find.byKey(const ValueKey('story-practice-misses'));
    await tester.scrollUntilVisible(
      row,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(row);
    await wait();

    // The question, every option there to be picked, none marked as the
    // reader's: not the first answer, turned over.
    expect(find.text(card.question), findsOneWidget);
    expect(find.textContaining('Not quite.'), findsNothing);
    expect(find.text('YOURS'), findsNothing);
    for (final String option in pick.options) {
      expect(find.text(option), findsOneWidget);
    }

    // Right, this time: the back says so.
    await tester.tap(find.text(pick.options[pick.correct]));
    await wait();
    if (find.text('80%').evaluate().isNotEmpty) {
      await tester.tap(find.text('80%').last);
      await wait();
    }
    expect(find.textContaining('Right.'), findsOneWidget);
    expect(find.textContaining('Not quite.'), findsNothing);

    // The record never hears of it: the first answer, its judgement and the
    // day the card comes back stand as they were.
    expect(app.answerFor(card.id)!.response, wrong);
    expect(app.answerFor(card.id)!.dueOn, back);
    expect(app.judgements, hasLength(1));
  });
}
