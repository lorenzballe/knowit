// Why this card: every one of today's cards says why it is there, from what
// the deal weighed and nothing else, and the line opens a sheet that says
// what the deal knew, with more like this and less.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart' show topicKeyForName;
import 'package:astuto/data/why.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/l10n/l10n.dart' show SubjectNames;
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/why_sheet.dart';

final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

/// A Wednesday, nobody's Sunday.
final DateTime wednesday = DateTime(2026, 10, 14, 9);

Future<AppState> opened({bool plus = false}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
  });
  final AppState app = AppState(clock: () => wednesday);
  await app.init();
  return app;
}

/// Cards of the bank that ask one of several options and train [move].
List<Pill> picksOf(Principle move) => [
  for (final Pill p in PillBank.cards)
    if (p.principle == move && p.challenge is PickOne) p,
];

String wrongFor(Pill p) {
  final PickOne c = p.challenge as PickOne;
  return '${(c.correct + 1) % c.options.length}';
}

String rightFor(Pill p) => '${(p.challenge as PickOne).correct}';

/// [p] made one of today's cards, the reader's own or not.
void deal(AppState app, Pill p, {bool own = true, bool review = false}) {
  app.todaysDeck = [p];
  app.ownIdsToday = own ? {p.id} : {};
  app.reviewIdsToday = review ? {p.id} : {};
}

void main() {
  setUp(PillBank.reset);

  group('why a card is here', () {
    test('a move met and missed comes back saying so; one got right comes '
        'back in a new case', () async {
      final List<Pill> moves = picksOf(Principle.baseRate);
      expect(moves.length, greaterThanOrEqualTo(3));
      final Pill card = moves.first;

      AppState app = await opened(plus: true);
      await app.recordAnswer(moves[1].id, wrongFor(moves[1]));
      await app.recordAnswer(moves[2].id, wrongFor(moves[2]));
      deal(app, card, review: true);
      CardWhy why = whyOf(app, card);
      expect(why.kind, WhyKind.missing);
      expect(why.mastery!.met, 2);
      expect(why.mastery!.right, 0);
      expect(why.lastMet, 0);
      expect(whyLine(en, why), en.whyMissing('Base rates'));

      app = await opened(plus: true);
      await app.recordAnswer(moves[1].id, rightFor(moves[1]));
      await app.recordAnswer(moves[2].id, rightFor(moves[2]));
      deal(app, card, review: true);
      why = whyOf(app, card);
      expect(why.kind, WhyKind.again);
      expect(whyLine(en, why), en.whyMoveAgain('Base rates'));
    });

    test(
      'dealt at random on the free plan, and said so; never on Astute+',
      () async {
        final Pill card = picksOf(Principle.baseRate).first;
        AppState app = await opened();
        deal(app, card, own: false);
        expect(whyOf(app, card).kind, WhyKind.random);
        expect(whyLine(en, whyOf(app, card)), en.whyRandom);

        app = await opened(plus: true);
        deal(app, card, own: false);
        expect(whyOf(app, card).kind, isNot(WhyKind.random));
      },
    );

    test('the goal first, then what was liked (on Astute+ only), then the '
        'level', () async {
      final Pill card = picksOf(Principle.baseRate).first;
      expect(Goal.decide.fits(card), isTrue);
      final AppState app = await opened(plus: true);
      await app.setGoals(['decide']);
      deal(app, card);
      CardWhy why = whyOf(app, card);
      expect(why.kind, WhyKind.goal);
      expect(why.goal, Goal.decide);
      expect(whyLine(en, why), en.whyGoal(en.goalDecide));

      await app.setGoals(const []);
      final List<Pill> alike = [
        for (final Pill p in PillBank.cards)
          if (p.genre == card.genre && p.id != card.id) p,
      ];
      expect(alike, isNotEmpty);
      await app.toggleLiked(alike.first.id);
      why = whyOf(app, card);
      expect(why.kind, WhyKind.liked);
      expect(why.liked, 1);
      expect(whyLine(en, why), en.whyLiked(1));

      final AppState free = await opened();
      await free.toggleLiked(alike.first.id);
      deal(free, card);
      expect(whyOf(free, card).kind, isNot(WhyKind.liked));
    });

    test('the level in the subject, as the deal reads it', () async {
      final Pill hard = PillBank.cards.firstWhere(
        (p) => p.asksSomething && p.difficulty == Difficulty.hard,
      );
      final Pill read = PillBank.cards.firstWhere(
        (p) => !p.asksSomething && !p.principle.isReal && p.place == null,
      );
      final AppState app = await opened();

      String key(Pill p) => topicKeyForName(p.topic)!;
      deal(app, hard);
      app.topicLevels = {key(hard): 2};
      expect(whyOf(app, hard).kind, WhyKind.hard);
      expect(
        whyLine(en, whyOf(app, hard)),
        en.whyHard(en.subjectOf(hard.topic)),
      );
      app.topicLevels = {key(hard): 1};
      expect(whyOf(app, hard).kind, WhyKind.level);
      expect(whyOf(app, hard).level, WhyLevel.some);

      deal(app, read);
      app.topicLevels = {key(read): 0};
      expect(whyOf(app, read).kind, WhyKind.gentle);
      expect(whyOf(app, read).level, WhyLevel.starting);
      app.topicLevels = {key(read): 1};
      expect(whyOf(app, read).kind, WhyKind.subject);
      // True of nearly every card, these say nothing on the card itself.
      for (final Pill p in [hard, read]) {
        for (final int level in [0, 1]) {
          app.topicLevels = {key(p): level};
          final CardWhy why = whyOf(app, p);
          if (why.kind == WhyKind.level ||
              why.kind == WhyKind.gentle ||
              why.kind == WhyKind.subject) {
            expect(whyLine(en, why), isNull, reason: '${why.kind}');
          }
        }
      }
    });

    test(
      'the Sunday\'s one more says so; a card about home says why itself',
      () async {
        final AppState app = await opened();
        final Pill card = picksOf(Principle.baseRate).first;
        deal(app, card);
        expect(whyOf(app, card, sunday: true).kind, WhyKind.sunday);
        expect(whyLine(en, whyOf(app, card, sunday: true)), en.sundayOneMore);

        final Pill home = PillBank.live.firstWhere((p) => p.place != null);
        deal(app, home, own: false);
        expect(whyOf(app, home).kind, WhyKind.place);
        expect(whyLine(en, whyOf(app, home)), isNull);
      },
    );
  });

  group('on Today', () {
    testWidgets('a card with a reason to give says why under its head, and '
        'the line opens the sheet', (tester) async {
      final AppState app = await opened();
      // A card drawn natively in front, with something to say: a free
      // card's page draws the same line itself (docs/cards/kit, `kit-why`),
      // and a card only from one of the reader's subjects, at their level,
      // says nothing.
      final int native = app.todaysDeck.indexWhere(
        (p) => p.web == null && whyLine(en, whyOf(app, p)) != null,
      );
      expect(native, greaterThanOrEqualTo(0));
      app.todayIndex = native;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: SafeArea(child: TodayScreen(app: app)),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final Pill top = app.todaysDeck[app.todayIndex];
      final Finder note = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is PillCard && w.pill.id == top.id && !w.flipped,
        ),
        matching: find.byKey(const ValueKey('card-note')),
      );
      expect(note, findsOneWidget);
      final String said = whyLine(en, whyOf(app, top))!;
      expect(
        find.descendant(of: note, matching: find.textContaining(said)),
        findsOneWidget,
      );
      // Each card of the day has its own line.
      final Set<String> lines = {
        for (final PillCard c in tester.widgetList<PillCard>(
          find.byType(PillCard),
        ))
          ?c.note,
      };
      expect(lines, isNotEmpty);

      await tester.tap(note);
      // The card in front may be one that keeps moving: a fixed while for
      // the sheet to come up, not until everything is still.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('why-sheet')), findsOneWidget);
      expect(find.text(en.whyTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('why-line')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the sheet', () {
    Future<AppState> sheetFor(
      WidgetTester tester,
      Pill card, {
      bool plus = true,
      bool own = true,
      Locale locale = const Locale('en'),
      Size phone = const Size(390, 844),
      double text = 1,
      List<String> goals = const ['decide'],
      void Function(AppState app)? before,
    }) async {
      final AppState app = await tester.runAsync(() async {
        final AppState a = await opened(plus: plus);
        await a.setGoals(goals);
        return a;
      }) as AppState;
      before?.call(app);
      deal(app, card, own: own);
      tester.view.physicalSize = phone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(text)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showWhySheet(context, app, card),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets(
      'the move and how it went, the level, the last time, the goal',
      (tester) async {
        final List<Pill> moves = picksOf(Principle.baseRate);
        final Pill card = moves.first;
        await sheetFor(tester, card);
        expect(find.byKey(const ValueKey('why-move')), findsOneWidget);
        expect(
          find.text(en.whyTrains('Base rates').toUpperCase()),
          findsOneWidget,
        );
        expect(find.text(Principle.baseRate.oneLine), findsOneWidget);
        // Never met: new to the reader.
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('why-record'))).data,
          en.newMove,
        );
        expect(find.byKey(const ValueKey('why-level')), findsOneWidget);
        expect(find.byKey(const ValueKey('why-goal')), findsOneWidget);
        expect(find.text(en.goalDecide), findsOneWidget);
        expect(find.byKey(const ValueKey('why-last')), findsNothing);
        expect(find.byKey(const ValueKey('why-plus')), findsNothing);
      },
    );

    testWidgets('met before: how many times, how many right', (tester) async {
      final List<Pill> moves = picksOf(Principle.baseRate);
      final AppState app = await tester.runAsync(() async {
        final AppState a = await opened(plus: true);
        await a.recordAnswer(moves[1].id, rightFor(moves[1]));
        await a.recordAnswer(moves[2].id, wrongFor(moves[2]));
        return a;
      }) as AppState;
      deal(app, moves.first);
      final CardWhy why = whyOf(app, moves.first);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: WhySheet(app: app, why: why),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('why-record'))).data,
        '${en.whyMet(2)} ${en.whyRight(1)}',
      );
      expect(find.byKey(const ValueKey('why-last')), findsOneWidget);
      expect(find.text(en.whyDaysAgo(0)), findsOneWidget);
    });

    testWidgets(
      'more like this is a like; less is a throw, with the way back',
      (tester) async {
        final Pill card = picksOf(Principle.baseRate).first;
        final AppState app = await sheetFor(tester, card);
        expect(app.isLiked(card.id), isFalse);
        await tester.tap(find.byKey(const ValueKey('why-more')));
        await tester.pumpAndSettle();
        expect(app.isLiked(card.id), isTrue);
        expect(find.text(en.whyMoreDone), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('why-less')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('why-sheet')), findsNothing);
        expect(app.isDisliked(card.id), isTrue);
        expect(app.isLiked(card.id), isFalse);
        expect(find.text(en.lessLikeThis), findsOneWidget);
        await tester.tap(find.text(en.undo));
        await tester.pumpAndSettle();
        expect(app.isDisliked(card.id), isFalse);
      },
    );

    testWidgets('a card at random, on the free plan: so it is, and all five '
        'the reader\'s own with Astute+', (tester) async {
      final Pill card = picksOf(Principle.baseRate).first;
      await sheetFor(tester, card, plus: false, own: false);
      expect(find.byKey(const ValueKey('why-plus')), findsOneWidget);
      expect(find.text(en.whyRandomLine), findsOneWidget);
      expect(find.byKey(const ValueKey('why-make-mine')), findsOneWidget);
    });

    testWidgets('it fits the smallest phone at a large text size, in every '
        'language', (tester) async {
      final Pill card = picksOf(Principle.baseRate).first;
      for (final Locale locale in AppLocalizations.supportedLocales) {
        await sheetFor(
          tester,
          card,
          plus: false,
          own: false,
          locale: locale,
          phone: const Size(320, 568),
          text: 1.5,
        );
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.byKey(const ValueKey('why-sheet')), findsOneWidget);
        // Closed, for the next language.
        Navigator.of(tester.element(find.byKey(const ValueKey('why-sheet'))))
            .pop();
        await tester.pumpAndSettle();
      }
    });
  });
}
