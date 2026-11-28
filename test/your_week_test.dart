// Sunday's week (lib/state/your_week.dart, lib/widgets/your_week_sheet.dart):
// on Sunday once the five are read, or on Monday morning for a reader who
// missed it, a reader on the free plan is shown what the week came to, once
// a week; never on Astute+, the first day, an empty week or an evening
// something else has; its numbers worked out from the record; one figure of
// Astute+'s blurred under them, its name clear; the account in one line to
// a reader with none, three weeks at most and never after a no; and the
// week gone over again from it, answered for the reader alone.
//
//   flutter test test/your_week_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/journey_screen.dart' show weekPlusFigure;
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/your_week.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/your_week_sheet.dart';

/// Sunday the 29th of November 2026, in the evening; the Monday after it,
/// in the morning and in the afternoon; and the Saturday before.
final DateTime _sunday = DateTime(2026, 11, 29, 19, 30);
final DateTime _mondayMorning = DateTime(2026, 11, 30, 9, 15);
final DateTime _mondayAfternoon = DateTime(2026, 11, 30, 14, 5);
final DateTime _saturday = DateTime(2026, 11, 28, 19, 30);

/// The week's Monday, as a date key.
const String _weekOf = '2026-11-23';

String _key(DateTime d) => dateKey(d);

/// Cards that ask to pick one, of [topic], [n] of them after [skip].
List<Pill> _of(String topic, int n, {int skip = 0}) => [
  for (final Pill p in PillBank.live)
    if (p.topic == topic &&
        p.web == null &&
        !p.isAboutAPlace &&
        p.challenge is PickOne)
      p,
].skip(skip).take(n).toList();

int _docs = 0;

/// The server's word on Sunday's week, and on the account's offer.
void _switch({bool week = true, bool account = true}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'your-week-${_docs++}',
      'app': {
        'flags': {'week.sunday': week, 'account.offer': account},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// A reader who read every day from Monday the 23rd to [last] (the Sunday,
/// unless given), five cards a day, the day [last] finished; History
/// answered right, Science wrong and said 80% sure, three a day of each.
Map<String, Object> _reader({
  bool plus = false,
  DateTime? last,
  bool readThisWeek = true,
  Map<String, Object> more = const {},
}) {
  final DateTime end = last ?? DateTime(2026, 11, 29);
  final List<Pill> history = _of('History', 21);
  final List<Pill> science = _of('Science', 21);
  final List<Pill> other = _of('Psychology', 14);
  final readDays = <String, List<String>>{};
  final judgements = <Map<String, Object>>[];
  final List<String> completed = [];
  var h = 0, s = 0, o = 0;
  for (
    var d = DateTime(2026, 11, 16, 12);
    !d.isAfter(DateTime(end.year, end.month, end.day, 12));
    d = DateTime(d.year, d.month, d.day + 1, 12)
  ) {
    final String day = _key(d);
    final bool inWeek = day.compareTo(_weekOf) >= 0;
    if (inWeek && !readThisWeek) continue;
    completed.add(day);
    if (!inWeek) continue;
    final List<Pill> five = [
      history[h++ % 21],
      science[s++ % 21],
      other[o++ % 14],
      history[h++ % 21],
      science[s++ % 21],
    ];
    readDays[day] = [for (final p in five) p.id];
    for (final Pill p in five.take(2)) {
      judgements.add({
        'k': p.topic == 'History',
        'p': p.id,
        'd': day,
        if (p.topic == 'Science') 'c': 80,
      });
    }
    judgements.add({'k': true, 'p': five[3].id, 'd': day});
  }
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.streak': completed.length,
    'knowit.bestStreak': completed.length,
    'knowit.lastCompletionDate': _key(end),
    'knowit.completedDates': completed,
    'knowit.seenIds': [for (final ids in readDays.values) ...ids],
    'knowit.readDays': jsonEncode(readDays),
    'knowit.judgements': jsonEncode(judgements),
    // Every other evening's question put already.
    'knowit.pushAsked': true,
    'knowit.reviewAsks': 9,
    ...more,
  };
}

Future<AppState> _app(Map<String, Object> prefs, {required DateTime at}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final AppState app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
    clock: () => at,
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

  group('when the week comes', () {
    test('on Sunday once the five are read: the week from Monday', () async {
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      expect(app.dayClosed, isTrue);
      expect(_key(yourWeekDue(app, now: _sunday)!), _weekOf);
      // Not before the five are read: the day counts in its week.
      final AppState reading = await _app(
        _reader(last: DateTime(2026, 11, 28)),
        at: _sunday,
      );
      expect(reading.dayClosed, isFalse);
      expect(yourWeekDue(reading, now: _sunday), isNull);
    });

    test('on Monday morning for a reader who missed Sunday, the week gone '
        'by; not in the afternoon, and not on the other days', () async {
      _switch();
      final AppState monday = await _app(
        _reader(last: DateTime(2026, 11, 29)),
        at: _mondayMorning,
      );
      expect(_key(yourWeekDue(monday, now: _mondayMorning)!), _weekOf);
      expect(yourWeekDue(monday, now: _mondayAfternoon), isNull);
      final AppState saturday = await _app(
        _reader(last: DateTime(2026, 11, 28)),
        at: _saturday,
      );
      expect(yourWeekDue(saturday, now: _saturday), isNull);
    });

    test('once a week: shown on Sunday, not again on Monday', () async {
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      await app.notedWeekShown(_weekOf, account: false);
      expect(yourWeekDue(app, now: _sunday), isNull);
      final AppState monday = await _app(
        _reader(more: {'knowit.weekShownFor': _weekOf}),
        at: _mondayMorning,
      );
      expect(yourWeekDue(monday, now: _mondayMorning), isNull);
    });

    test('never on Astute+, never while the server has it off, never on '
        'the first day, never for a week with nothing read', () async {
      _switch();
      expect(
        yourWeekDue(await _app(_reader(plus: true), at: _sunday), now: _sunday),
        isNull,
      );
      final AppState first = await _app({
        ..._reader(),
        'knowit.completedDates': [_key(_sunday)],
      }, at: _sunday);
      expect(yourWeekDue(first, now: _sunday), isNull);
      final AppState empty = await _app(
        _reader(readThisWeek: false, last: DateTime(2026, 11, 22)),
        at: _mondayMorning,
      );
      expect(yourWeekDue(empty, now: _mondayMorning), isNull);
      _switch(week: false);
      expect(
        yourWeekDue(await _app(_reader(), at: _sunday), now: _sunday),
        isNull,
      );
    });

    test('one moment an evening: not on the evening a level rose, the '
        'first week\'s page rose, or the reminder sheet is due', () async {
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      expect(yourWeekDue(app, now: _sunday, levelRoseToday: true), isNull);
      final AppState offered = await _app(
        _reader(more: {'knowit.firstWeekOfferedOn': _key(_sunday)}),
        at: _sunday,
      );
      expect(yourWeekDue(offered, now: _sunday), isNull);
      final AppState asking = await _app(
        _reader(more: {'knowit.pushAsked': false}),
        at: _sunday,
      );
      expect(asking.shouldAskForPush, isTrue);
      expect(yourWeekDue(asking, now: _sunday), isNull);
    });
  });

  group('what the week came to', () {
    test('the cards read, the days, the right answers, how sure against '
        'how right, the days in a row and the best subject', () async {
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      final YourWeek week = YourWeek.of(app, DateTime(2026, 11, 23));
      expect(week.cards, 35);
      expect(week.days, 7);
      // Three answers a day: History right, Science wrong, one more right.
      expect(week.answered.of, 21);
      expect(week.answered.right, 14);
      // Seven said 80% sure, all of them wrong.
      expect(week.sure, (sure: 80, right: 0, n: 7));
      expect(week.streak, 14);
      expect(week.best?.key, 'history');
      // The week before has its own numbers, and none of this week's.
      final YourWeek before = YourWeek.of(app, DateTime(2026, 11, 16));
      expect(before.cards, 0);
      expect(before.days, 7);
      expect(before.sure, isNull);
    });
  });

  group('the account, in one line', () {
    test('to a reader with no account who can make one, three weeks at '
        'most, never after a no, never while the server holds it', () async {
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      bool offers({bool signedIn = false, bool canSignIn = true}) =>
          weekOffersAccount(app, signedIn: signedIn, canSignIn: canSignIn);
      expect(offers(), isTrue);
      expect(offers(signedIn: true), isFalse);
      expect(offers(canSignIn: false), isFalse);
      for (var i = 0; i < kWeekAccountTimes; i++) {
        await app.notedWeekShown('2026-11-0${i + 1}', account: true);
      }
      expect(offers(), isFalse);
      final AppState declined = await _app(
        _reader(more: {'knowit.weekAccountDeclined': true}),
        at: _sunday,
      );
      expect(
        weekOffersAccount(declined, signedIn: false, canSignIn: true),
        isFalse,
      );
      _switch(account: false);
      final AppState held = await _app(_reader(), at: _sunday);
      expect(
        weekOffersAccount(held, signedIn: false, canSignIn: true),
        isFalse,
      );
    });
  });

  group('the sheet', () {
    Widget host(AppState app, Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(body: child),
    );

    testWidgets('its numbers, the best subject, the figure of Astute+\'s '
        'under a blur with its name clear, and the account\'s line only '
        'where it is offered', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      final AppLocalizations l = lookupAppLocalizations(const Locale('en'));
      for (final bool account in [true, false]) {
        await tester.pumpWidget(
          host(
            app,
            Builder(
              builder: (context) => YourWeekSheet(
                app: app,
                week: YourWeek.of(app, DateTime(2026, 11, 23)),
                plus: (key: 'blind', label: l.readBlind, value: 'Science'),
                account: account,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(l.yourWeek), findsOneWidget);
        expect(find.text('THE WEEK OF NOVEMBER 23'), findsOneWidget);
        expect(find.text('35'), findsOneWidget);
        expect(find.text(l.weekSheetRightValue(14, 21)), findsOneWidget);
        expect(find.text('80% · 0%'), findsOneWidget);
        expect(find.text(l.weekSheetAcross(7)), findsOneWidget);
        expect(find.text(l.streakDays(14)), findsOneWidget);
        expect(find.byKey(const ValueKey('your-week-best')), findsOneWidget);
        // The figure's name in the clear, the figure itself blurred.
        expect(find.text(l.readBlind.toUpperCase()), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Science').last,
            matching: find.byType(ImageFiltered),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('your-week-account')),
          account ? findsOneWidget : findsNothing,
        );
      }
    });

    testWidgets('with nothing of Astute+\'s that can be said yet, no blurred '
        'figure at all, rather than a sample', (tester) async {
      _switch();
      // Two days of the week read, two answers each, none said how sure:
      // no subject measured, no card back yet, nothing trusted too much.
      final List<Pill> cards = _of('History', 4);
      final AppState app = await _app({
        ..._reader(),
        'knowit.readDays': jsonEncode({
          '2026-11-28': [cards[0].id, cards[1].id],
          '2026-11-29': [cards[2].id, cards[3].id],
        }),
        'knowit.judgements': jsonEncode([
          for (final (int i, Pill p) in cards.indexed)
            {
              'k': i.isEven,
              'p': p.id,
              'd': i < 2 ? '2026-11-28' : '2026-11-29',
            },
        ]),
      }, at: _sunday);
      await tester.pumpWidget(
        host(
          app,
          Builder(
            builder: (context) => YourWeekSheet(
              app: app,
              week: YourWeek.of(app, DateTime(2026, 11, 23)),
              plus: weekPlusFigure(context, app),
              account: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('your-week')), findsOneWidget);
      expect(find.byKey(const ValueKey('your-week-plus')), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('shown once and noted; the week gone over from it is the '
        'week\'s first five, answered for the reader alone', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _switch();
      final AppState app = await _app(_reader(), at: _sunday);
      final Account account = Account(
        uidOverride: 'me',
        boardsOverride: MemoryBoardStore(),
      );
      await tester.pumpWidget(
        host(
          app,
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showYourWeek(
                  context,
                  app: app,
                  account: account,
                  monday: DateTime(2026, 11, 23),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(app.weekShownFor, _weekOf);
      expect(find.byKey(const ValueKey('your-week')), findsOneWidget);
      // No account can be made here (no Firebase in a test): no line.
      expect(find.byKey(const ValueKey('your-week-account')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('your-week-review')));
      await tester.pumpAndSettle();
      final DeckViewerScreen viewer = tester.widget(
        find.byType(DeckViewerScreen),
      );
      expect(viewer.records, isFalse);
      expect(viewer.deck.length, kWeekReviewFree);
      expect([
        for (final p in viewer.deck) p.id,
      ], app.record.readBetween(_weekOf, '2026-11-29').take(5).toList());
    });
  });
}
