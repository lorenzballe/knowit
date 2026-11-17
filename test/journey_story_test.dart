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

  testWidgets('with the answers by Claude on, the coach is the second '
      'chapter: on Astute+ the week\'s note a tap away, sent as numbers; on '
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
    expect(find.text('2  ·  YOUR COACH'), findsOneWidget);
    expect(find.text('3  ·  PRACTISE'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey-coach-ask')));
    await tester.pumpAndSettle();
    expect(find.text('A good week: 8 in 10 right when sure.'), findsOneWidget);
    expect(sent?['sure'], 8);
    expect(sent!.keys, containsAll(['read', 'days', 'streak', 'missed']));

    final free = await _app({});
    await show(free);
    await tester.pump();
    expect(find.byKey(const ValueKey('journey-coach-locked')), findsOneWidget);
  });

  testWidgets('the journey reads in eight chapters: the week and what to '
      'practise first, the story last; on the free plan the line Astute+ '
      'shows sits behind glass with the way through', (tester) async {
    tester.view.physicalSize = const Size(402, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await _app({
      'knowit.judgements': jsonEncode([
        ..._said(topic, 6, sure: 90, right: 3),
        ..._said(PillBank.live.last.topic, 6, sure: 70, right: 6),
      ]),
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
    final List<String> chapters = [
      '1  ·  THIS WEEK',
      '2  ·  PRACTISE',
      '3  ·  WHERE YOU ARE',
      '4  ·  HOW YOU REASON',
      '5  ·  WHAT YOU KNOW',
      '6  ·  YOUR HABITS',
      '7  ·  WHAT STAYS WITH YOU',
      '8  ·  YOUR STORY',
    ];
    double last = -1;
    for (final String c in chapters) {
      expect(find.text(c), findsOneWidget, reason: c);
      final double y = tester.getTopLeft(find.text(c)).dy;
      expect(y, greaterThan(last), reason: '$c comes after the one before');
      last = y;
    }
    // The score is in the third chapter, under what to practise.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('journey-score'))).dy,
      greaterThan(tester.getTopLeft(find.text('3  ·  WHERE YOU ARE')).dy),
    );
    expect(find.text('See it with Astute+'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-practice-misses')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('story-practice-changed')),
      findsOneWidget,
    );
  });
}
