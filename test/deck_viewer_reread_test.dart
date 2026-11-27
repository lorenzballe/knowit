import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// A card with a drawing, opened again from the archive, saved or liked,
/// starts again from its question, and its page cannot say how the reader
/// did the first time: the line under it does.
void main() {
  Future<void> open(WidgetTester tester, Pill pill, String? response) async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      if (response != null)
        'knowit.answersJson': jsonEncode({
          pill.id: {'r': response, 'c': 80},
        }),
    });
    final AppState app = AppState();
    await app.init();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: DeckViewerScreen(app: app, deck: [pill], title: 'Saved'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  final Pill drawn = PillBank.cards.firstWhere(
    (p) => p.hasPage && p.isGraded && p.challenge is PageJudged,
  );

  testWidgets('right the first time', (tester) async {
    await open(tester, drawn, PageJudged.encode('0', true));
    expect(find.text('You got it right the first time.'), findsOneWidget);
  });

  testWidgets('missed the first time', (tester) async {
    await open(tester, drawn, PageJudged.encode('1', false));
    expect(find.text('You missed it the first time.'), findsOneWidget);
  });

  testWidgets('never answered: the usual line', (tester) async {
    await open(tester, drawn, null);
    expect(find.text('That was the only one'), findsOneWidget);
  });

  group('cards to answer again', () {
    // Two cards in words, the second read before: a book's ideas are
    // answered the way cards that came back are, and only one read before
    // is back "again".
    final List<Pill> deck = PillBank.cards
        .where((p) => !p.hasPage && p.challenge is PickOne)
        .take(2)
        .toList();

    Future<void> answering(WidgetTester tester, int at) async {
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.seenIds': [deck[1].id],
      });
      final AppState app = AppState();
      await app.init();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: DeckViewerScreen(
            app: app,
            deck: deck,
            title: 'A book',
            initialIndex: at,
            answering: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// The "again" chip on [pill]'s card, wherever it lies on the table.
    Finder againOn(Pill pill) => find.descendant(
      of: find.byWidgetPredicate((w) => w is PillCard && w.pill.id == pill.id),
      matching: find.text('AGAIN'),
    );

    testWidgets('a card never read is not marked again', (tester) async {
      await answering(tester, 0);
      expect(find.text(deck[0].question), findsOneWidget);
      expect(againOn(deck[0]), findsNothing);
      // The one under it, read before, is.
      expect(againOn(deck[1]), findsOneWidget);
    });

    testWidgets('a card read before is', (tester) async {
      await answering(tester, 1);
      expect(find.text(deck[1].question), findsOneWidget);
      expect(againOn(deck[1]), findsOneWidget);
    });
  });

  group('the week gone over again, answered for the reader alone', () {
    // Three cards in words read this week: one answered right and not due
    // for a week, one missed and due back today, one passed unanswered.
    final List<Pill> week = PillBank.cards
        .where((p) => !p.hasPage && p.challenge is PickOne && p.isGraded)
        .take(3)
        .toList();
    PickOne pick(Pill p) => p.challenge as PickOne;
    String wrong(Pill p) => '${(pick(p).correct + 1) % pick(p).options.length}';
    final String today = dateKey(DateTime.now());
    final String inAWeek = dateKey(DateTime.now().add(const Duration(days: 7)));

    Future<AppState> review(WidgetTester tester) async {
      // A phone, so the whole card is on the screen to be answered.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.plus': true,
        'knowit.seenIds': [for (final p in week) p.id],
        'knowit.answersJson': jsonEncode({
          week[0].id: {
            'r': '${pick(week[0]).correct}',
            'c': 80,
            's': 1,
            'd': inAWeek,
          },
          week[1].id: {'r': wrong(week[1]), 'c': 60, 'd': today},
        }),
        'knowit.judgements': jsonEncode([
          {'c': 80, 'k': true, 'p': week[0].id, 'd': today},
          {'c': 60, 'k': false, 'p': week[1].id, 'd': today},
        ]),
      });
      final AppState app = AppState();
      await app.init();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: DeckViewerScreen(
            app: app,
            deck: week,
            title: 'Review the week',
            answering: true,
            records: false,
            source: 'journey',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      return app;
    }

    /// Picks [option] on the card on top, says how sure once the card asks,
    /// and lets the card turn.
    Future<void> answer(WidgetTester tester, String option) async {
      Future<void> wait() async {
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.tap(find.text(option).last);
      await wait();
      if (find.text('80%').evaluate().isNotEmpty) {
        await tester.tap(find.text('80%').last);
        await wait();
      }
    }

    Future<void> next(WidgetTester tester) async {
      final Rect r = tester.getRect(find.byType(PillCardStack));
      await tester.flingFrom(
        Offset(r.center.dx, r.top + 90),
        const Offset(-320, 0),
        900,
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('each card asks afresh, its back says how this answer went, '
        'and the first answers, the ladder and when a card is due back '
        'stand as they were', (tester) async {
      final AppState app = await review(tester);
      final Answer? firstA = app.answerFor(week[0].id);
      final Answer? firstB = app.answerFor(week[1].id);
      final int judged = app.judgements.length;
      final int score = app.score.total;

      // Right the first time, nothing marked on the front now, and no
      // "again" on every card: missed, this time, and the back says so.
      expect(find.text(week[0].question), findsOneWidget);
      expect(find.text('AGAIN'), findsNothing);
      await answer(tester, pick(week[0]).options[int.parse(wrong(week[0]))]);
      expect(find.textContaining('Not quite.'), findsOneWidget);
      expect(find.textContaining('Right.'), findsNothing);

      // Missed the first time and due back today: right, this time. Being
      // due does not make this its review.
      await next(tester);
      await answer(tester, pick(week[1]).options[pick(week[1]).correct]);
      expect(find.textContaining('Right.'), findsOneWidget);

      // Passed the first time: asked, and answered, and still unanswered
      // in the record.
      await next(tester);
      await answer(tester, pick(week[2]).options[pick(week[2]).correct]);
      expect(find.textContaining('Right.'), findsOneWidget);

      Map<String, Object?> facts(Answer? a) => a == null
          ? const {}
          : {'r': a.response, 'c': a.confidence, 's': a.stage, 'd': a.dueOn};
      expect(facts(app.answerFor(week[0].id)), facts(firstA));
      expect(facts(app.answerFor(week[1].id)), facts(firstB));
      expect(app.answerFor(week[1].id)!.dueOn, today);
      expect(app.isDueForReview(week[1].id), isTrue);
      expect(app.answerFor(week[2].id), isNull);
      expect(app.judgements, hasLength(judged));
      expect(app.score.total, score);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('knowit.answersJson'),
        isNot(contains(week[2].id)),
      );
    });
  });
}
