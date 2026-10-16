import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// Sunday carries one more card chosen for the reader: on the free plan one
/// of the five that would have come at random is their own instead, and
/// Today says so. Astute+ is all the reader's own every day, so its Sunday
/// is like any other. The server deals the same (functions/src/deal.ts,
/// tested in deal.test.ts with readers' clocks either side of midnight).

/// The app opened at [now] on the reader's own clock, on a first install
/// unless [prefs] say more.
Future<AppState> _openedAt(
  DateTime now, {
  bool plus = false,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
    ...prefs,
  });
  final AppState app = AppState(clock: () => now);
  await app.init();
  return app;
}

/// Saturday 10 October 2026, Sunday the 11th, Monday the 12th.
final DateTime _saturday = DateTime(2026, 10, 10);
final DateTime _sunday = DateTime(2026, 10, 11);
final DateTime _monday = DateTime(2026, 10, 12);

void main() {
  setUp(() {
    PillBank.reset();
    resetCalendar();
  });

  group('one more card chosen for the reader on their Sunday', () {
    test(
      'a free day\'s one more, a week kept\'s too, and Astute+ as it was',
      () {
        expect(kOwnCardsSunday, 1);
        expect(ownCardsFor(plus: false, streak: 0, sunday: true), 3);
        expect(ownCardsFor(plus: false, streak: 0), kOwnCardsFree);
        expect(
          ownCardsFor(plus: false, streak: 7, sunday: true),
          kOwnCardsRewarded + kOwnCardsSunday,
        );
        expect(ownCardsFor(plus: false, streak: 8, sunday: true), 3);
        expect(ownCardsFor(plus: true, streak: 0, sunday: true), kPillsPerDay);
        expect(ownCardsFor(plus: true, streak: 7, sunday: true), kPillsPerDay);
      },
    );

    test('the reader\'s Sunday runs from their midnight to their next', () {
      expect(isSunday(DateTime(2026, 10, 10, 23, 59, 59)), isFalse);
      expect(isSunday(_sunday), isTrue);
      expect(isSunday(DateTime(2026, 10, 11, 23, 59, 59)), isTrue);
      expect(isSunday(_monday), isFalse);
      // The phone's dates are its own wall clock. One instant, 22:30 UTC on
      // the Saturday, is already Sunday on a clock two hours ahead (Rome in
      // October) and still Saturday on one four hours behind (New York).
      final DateTime instant = DateTime.utc(2026, 10, 10, 22, 30);
      expect(isSunday(instant.add(const Duration(hours: 2))), isTrue);
      expect(isSunday(instant.subtract(const Duration(hours: 4))), isFalse);
      expect(isSunday(instant), isFalse, reason: 'and in London, Saturday');
    });

    test('the phone deals it: three of the reader\'s own in the five, at '
        'either edge of the day', () async {
      final AppState lateSaturday = await _openedAt(
        DateTime(2026, 10, 10, 23, 59),
      );
      expect(lateSaturday.ownIdsToday, hasLength(kOwnCardsFree));
      expect(lateSaturday.sundayExtraToday, isFalse);
      // Tonight already knows what the morning holds.
      expect(lateSaturday.ownCardsOn(_sunday), kOwnCardsFree + 1);

      for (final DateTime now in [
        DateTime(2026, 10, 11, 0, 0, 1),
        DateTime(2026, 10, 11, 23, 59),
      ]) {
        final AppState app = await _openedAt(now);
        expect(app.todaysDeck, hasLength(kPillsPerDay), reason: '$now');
        expect(app.ownIdsToday, hasLength(kOwnCardsFree + 1), reason: '$now');
        expect(
          app.todaysDeck.where((p) => !app.ownIdsToday.contains(p.id)),
          hasLength(kPillsPerDay - kOwnCardsFree - 1),
          reason: 'one fewer at random',
        );
        expect(
          app.todaysDeck.where((p) => p.asksSomething),
          hasLength(asksInADay(kPillsPerDay)),
        );
        expect(app.sundayExtraToday, isTrue);
      }

      final AppState earlyMonday = await _openedAt(
        DateTime(2026, 10, 12, 0, 0, 1),
      );
      expect(earlyMonday.ownIdsToday, hasLength(kOwnCardsFree));
      expect(earlyMonday.sundayExtraToday, isFalse);
    });

    test('a week kept up to Saturday: Sunday has the week\'s one more and '
        'its own', () async {
      final AppState app = await _openedAt(
        DateTime(2026, 10, 11, 8),
        prefs: {
          'knowit.streak': 7,
          'knowit.bestStreak': 7,
          'knowit.lastCompletionDate': '2026-10-10',
          'knowit.completedDates': <String>[
            for (var d = 4; d <= 10; d++)
              '2026-10-${d.toString().padLeft(2, '0')}',
          ],
        },
      );
      expect(app.ownIdsToday, hasLength(kOwnCardsRewarded + kOwnCardsSunday));
      expect(app.sundayExtraToday, isTrue);
    });

    test('Astute+ is all the reader\'s own already: Sunday changes nothing, '
        'and says nothing', () async {
      final AppState app = await _openedAt(
        DateTime(2026, 10, 11, 8),
        plus: true,
      );
      expect(app.ownIdsToday, hasLength(kPillsPerDay));
      expect(app.sundayExtraToday, isFalse);
    });
  });

  group('Today says so', () {
    const Map<String, Size> phones = {
      'small': Size(360, 740),
      'large': Size(430, 932),
    };

    Future<void> pumpToday(
      WidgetTester tester,
      AppState app,
      Size phone,
    ) async {
      tester.view.physicalSize = phone;
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
    }

    testWidgets('a line under the day\'s name on a Sunday, on a small and a '
        'large phone', (tester) async {
      for (final MapEntry<String, Size> phone in phones.entries) {
        final AppState app = await _openedAt(DateTime(2026, 10, 11, 9));
        await pumpToday(tester, app, phone.value);
        expect(tester.takeException(), isNull, reason: phone.key);
        final Finder line = find.byKey(const ValueKey('sunday-line'));
        expect(line, findsOneWidget, reason: phone.key);
        expect(
          find.text('Sunday: one more card chosen for you'),
          findsOneWidget,
        );
        // Above the bars and the deck, inside the screen.
        expect(
          tester.getRect(line).bottom,
          lessThan(tester.getRect(find.byType(PillCardStack)).top),
        );
        expect(
          tester.getRect(line).right,
          lessThanOrEqualTo(phone.value.width),
        );
      }
    });

    testWidgets('nothing on a Saturday, nothing on Astute+', (tester) async {
      final Size phone = phones['small']!;
      await pumpToday(
        tester,
        await _openedAt(DateTime(2026, 10, 10, 9)),
        phone,
      );
      expect(find.byKey(const ValueKey('sunday-line')), findsNothing);
      await pumpToday(
        tester,
        await _openedAt(DateTime(2026, 10, 11, 9), plus: true),
        phone,
      );
      expect(find.byKey(const ValueKey('sunday-line')), findsNothing);
      expect(tester.takeException(), isNull);
      expect(_saturday.weekday, DateTime.saturday);
    });
  });

  group('the evening a week is kept', () {
    Future<(String, String)?> noteOn(WidgetTester tester, DateTime day) async {
      // A week kept today: seven days, the last of them today, all read.
      final AppState app = await _openedAt(
        day,
        prefs: {'knowit.streak': 7, 'knowit.lastCompletionDate': dateKey(day)},
      );
      app.todayIndex = app.todaysDeck.length;
      (String, String)? note;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              note = weekNoteOf(context, app);
              return const SizedBox();
            },
          ),
        ),
      );
      return note;
    }

    testWidgets('says four of the five when tomorrow is Sunday', (
      tester,
    ) async {
      final (String, String)? saturday = await noteOn(tester, _saturday);
      expect(saturday?.$1, 'week-reward');
      expect(saturday?.$2, contains('four of the five'));
    });

    testWidgets('says three of the five on any other evening', (tester) async {
      final (String, String)? sunday = await noteOn(tester, _sunday);
      expect(sunday?.$2, contains('three of the five'));
      final (String, String)? monday = await noteOn(tester, _monday);
      expect(monday?.$2, contains('three of the five'));
    });
  });
}
