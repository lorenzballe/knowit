// Writes Today's five for the site: the five questions at the top of Explore
// that every reader is dealt that day, from the date alone, by the app's own
// deal (lib/explore/blocks/bets/daily_deal.dart, DailyDeal.five) on the bank
// this deploy carries. Every day from the day before the deploy to four
// hundred days after it, so that a page opened anywhere in the world, on any
// day before the next deploy, finds its own.
//
// Two things, in one folder of the site (five/):
//
// - days.json, small: each day's five card ids, in the app's order, and the
//   day's edition, under the day as the page writes the reader's own date
//   (yyyy-mm-dd, the phone's calendar);
// - cards/<id>.json, one for each card a day names: its question, and its
//   subject's name and colours, which is all the page shows of it.
//
// The landing page reads the first, picks the reader's date, fetches that
// day's five cards and shows them, each linking to its card's page (/c/<id>).
//
//   flutter test tool/todays_five.dart            (the deploy runs this)
//   TODAYS_FIVE_OUT=some/folder flutter test tool/todays_five.dart
//
// test/web/todays_five_test.dart checks what this writes against the app's
// deal, date by date.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

/// How many days the file holds: the day before the deploy's, and four
/// hundred after it.
const int kTodaysFiveDays = 401;

/// The days, as days.json holds them: for [days] days from the day before
/// [now], each day's edition and its five card ids, under the day's key.
Map<String, Object> todaysFiveDays(DateTime now, {int days = kTodaysFiveDays}) {
  final DateTime first = DateTime(now.year, now.month, now.day - 1);
  final Map<String, Object> out = {};
  for (int i = 0; i < days; i++) {
    // Noon: the calendar day, whatever the clocks do that night.
    final DateTime day = DateTime(first.year, first.month, first.day + i, 12);
    out[dateKey(day)] = {
      'edition': editionOf(day),
      'five': [for (final Pill p in DailyDeal.five(day)) p.id],
    };
  }
  return out;
}

/// What the page shows of a card: its question, and its subject's name and
/// colours (the subject's mark is named for it on the page).
Map<String, Object> todaysFiveCard(Pill p) => {
  'id': p.id,
  'question': p.question,
  'topic': p.topic,
  'color': AppState.hexOf(p.color),
  'ink': AppState.hexOf(p.ink),
};

/// Writes `days.json` and `cards/<id>.json` into [out], for the days from
/// the day before [now]: what the deploy publishes as `five/` on the site.
void writeTodaysFive(Directory out, DateTime now) {
  final Map<String, Object> days = todaysFiveDays(now);
  Directory('${out.path}/cards').createSync(recursive: true);
  File('${out.path}/days.json').writeAsStringSync(
    jsonEncode({
      'version': 1,
      'built': now.toUtc().toIso8601String(),
      'bank': PillBank.version,
      'days': days,
    }),
  );
  final Set<String> named = {
    for (final Object day in days.values)
      ...((day as Map<String, Object>)['five']! as List<String>),
  };
  for (final String id in named) {
    File('${out.path}/cards/$id.json')
        .writeAsStringSync(jsonEncode(todaysFiveCard(PillBank.byId(id)!)));
  }
}

void main() {
  test('Today\'s five, for the site', () {
    final Directory out = Directory(
      Platform.environment['TODAYS_FIVE_OUT'] ?? 'build/web/five',
    );
    writeTodaysFive(out, DateTime.now());
    final Map<String, Object?> written = jsonDecode(
      File('${out.path}/days.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final Map<String, Object?> days = written['days']! as Map<String, Object?>;
    expect(days, hasLength(kTodaysFiveDays));
    for (final Object? day in days.values) {
      expect((day! as Map)['five'], hasLength(5));
    }
  });
}
