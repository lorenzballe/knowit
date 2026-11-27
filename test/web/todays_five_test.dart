// Today's five on the site against the app's own deal.
//
// The deploy writes five/days.json and five/cards/<id>.json with
// tool/todays_five.dart; the landing page reads them and shows the reader's
// day. Here the script writes them as the deploy does, and for every date
// checked the five ids the page will show are the five the app deals
// (DailyDeal.five), in the app's order, whatever the hour the phone asks at:
// at a minute past midnight, at noon and a minute before midnight. The dates
// are every twentieth day of the file and the awkward ones, the turn of the
// year, the end of February and the nights the clocks change in Europe and
// in America. Every card a day names is in the published bank and dealt, so
// its page (/c/<id>, tool/cards/challenge_pages.py) is on the site.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/models/pill.dart';

import '../../tool/todays_five.dart';

void main() {
  /// A deploy at 9:41 on 26 November 2026, and what it wrote.
  final DateTime deploy = DateTime(2026, 11, 26, 9, 41);
  late Map<String, Object?> days;
  late Directory out;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('todays_five');
    writeTodaysFive(out, deploy);
    final Map<String, Object?> file = jsonDecode(
      File('${out.path}/days.json').readAsStringSync(),
    ) as Map<String, Object?>;
    expect(file['bank'], PillBank.version);
    days = file['days']! as Map<String, Object?>;
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  test('the deploy writes it where the page reads it', () {
    final String deploy = File('.github/workflows/deploy.yml')
        .readAsStringSync();
    expect(deploy, contains('TODAYS_FIVE_OUT=_site/five'));
    expect(deploy, contains('tool/todays_five.dart'));
    final String script = File('site/assets/main.js').readAsStringSync();
    expect(script, contains("json('/five/days.json')"));
    expect(script, contains("'/five/cards/'"));
    expect(script, contains('href="/c/\' + encodeURIComponent(c.id)'));
  });

  test('holds the day before the deploy and the four hundred after it', () {
    expect(days, hasLength(401));
    final List<String> keys = days.keys.toList();
    expect(keys.first, '2026-11-25');
    expect(keys.last, '2027-12-30');
    for (int i = 0; i < keys.length; i++) {
      expect(keys[i], dateKey(DateTime(2026, 11, 25 + i)));
      expect(keys[i], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    }
  });

  final List<DateTime> dates = [
    for (int i = 0; i < 401; i += 20) DateTime(2026, 11, 25 + i),
    DateTime(2026, 12, 31),
    DateTime(2027, 1, 1),
    DateTime(2027, 2, 28),
    DateTime(2027, 3, 1),
    // The clocks: forward in America, then in Europe; back in Europe, then
    // in America.
    DateTime(2027, 3, 14),
    DateTime(2027, 3, 28),
    DateTime(2027, 10, 31),
    DateTime(2027, 11, 7),
  ];

  test('checks at least twenty dates', () {
    expect(
      {for (final DateTime d in dates) dateKey(d)}.length,
      greaterThan(20),
    );
  });

  for (final DateTime date in dates) {
    test('${dateKey(date)}: the five the app deals, at any hour', () {
      final Map<String, Object?> day =
          days[dateKey(date)]! as Map<String, Object?>;
      for (final (int h, int m) in [(0, 1), (12, 0), (23, 59)]) {
        final DateTime at = DateTime(date.year, date.month, date.day, h, m);
        expect(day['five'], [
          for (final Pill p in DailyDeal.five(at)) p.id,
        ], reason: 'at $at');
      }
      expect(day['edition'], editionOf(date));
    });
  }

  test('five cards a day, from five subjects', () {
    for (final MapEntry<String, Object?> e in days.entries) {
      final List<Object?> five = (e.value! as Map)['five'] as List<Object?>;
      expect(five, hasLength(5), reason: e.key);
      final Set<String> subjects = {
        for (final Object? id in five) PillBank.byId(id! as String)!.topic,
      };
      expect(subjects, hasLength(5), reason: e.key);
    }
  });

  test('every card named is in the published bank, dealt, with its page', () {
    final Map<String, Object?> bank = jsonDecode(
      File('web/cards/v2/cards.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final Map<String, Map<String, Object?>> published = {
      for (final Object? c in bank['cards']! as List<Object?>)
        (c! as Map<String, Object?>)['id']! as String:
            c as Map<String, Object?>,
    };
    final Set<String> named = {
      for (final Object? day in days.values)
        for (final Object? id in (day! as Map)['five'] as List<Object?>)
          id! as String,
    };
    for (final String id in named) {
      final Map<String, Object?>? card = published[id];
      expect(card, isNotNull, reason: '$id is not in the published bank');
      // challenge_pages.py writes a page for every card not taken out.
      expect(card!['disabled'], isNot(true), reason: id);
      expect(PillBank.cards.any((p) => p.id == id), isTrue, reason: id);
      final Map<String, Object?> shown = jsonDecode(
        File('${out.path}/cards/$id.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(shown, todaysFiveCard(PillBank.byId(id)!));
      expect(shown['question'], card['question']);
    }
  });
}
