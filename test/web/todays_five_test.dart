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
//
// The challenge on today's five (/sfida, tool/cards/sfida_page.py) plays the
// same five from the same files, and judges a friend's answers from what
// each card's file says: so each file must say exactly what the app judges
// by — a pick's options and its right one, and for a share every guess on
// the track the card itself counts right — and the line of the answer the
// app shows under a card once it is locked in.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/bets/answers.dart' show plainResponse;
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show answerOf;
import 'package:astuto/explore/blocks/bets/parts.dart' show firstLines;
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

  /// Every card the file names, by id.
  Set<String> named() => {
    for (final Object? day in days.values)
      for (final Object? id in (day! as Map)['five'] as List<Object?>)
        id! as String,
  };

  Map<String, Object?> shownOf(String id) =>
      jsonDecode(File('${out.path}/cards/$id.json').readAsStringSync())
          as Map<String, Object?>;

  test('the challenge plays the files the deploy writes', () {
    final String page = File('tool/cards/sfida_page.py').readAsStringSync();
    expect(page, contains("'/five/days.json'"));
    expect(page, contains("'/five/cards/'"));
    final String deploy = File('.github/workflows/deploy.yml')
        .readAsStringSync();
    expect(deploy, contains('python3 tool/cards/sfida_page.py _site'));
  });

  test('every card is judged on the site as the app judges it: a pick on '
      'its right option, a share on every guess the card counts right', () {
    int picks = 0, shares = 0;
    for (final String id in named()) {
      final Pill p = PillBank.byId(id)!;
      final Map<String, Object?> shown = shownOf(id);
      switch (dailyKindOf(p)) {
        case DailyKind.pick:
          picks++;
          final PickOne pick = p.challenge as PickOne;
          expect(shown['kind'], 'pick', reason: id);
          expect(shown['options'], pick.options, reason: id);
          // The page counts the option at `correct` right, and no other:
          // what the app's game keeps as the bet's `right`.
          for (int i = 0; i < pick.options.length; i++) {
            expect(
              i == shown['correct'],
              p.challenge.accepts('$i'),
              reason: '$id, option $i',
            );
          }
        case DailyKind.share:
          shares++;
          expect(shown['kind'], 'share', reason: id);
          expect(shown['value'], answerOf(p)!.value, reason: id);
          final List<Object?>? right = shown['right'] as List<Object?>?;
          // The track is set in whole points, from nought to a hundred: the
          // page counts a guess right between the two it is given, and the
          // app the guess its card accepts, in the form the game keeps it.
          for (int g = 0; g <= 100; g++) {
            final bool page =
                right != null &&
                g >= (right[0]! as num) &&
                g <= (right[1]! as num);
            expect(
              page,
              p.challenge.accepts(plainResponse(g.toDouble())),
              reason: '$id at $g',
            );
          }
        case null:
          fail('$id is not a card the five can play');
      }
      // The why under each answer: the line the app shows under the card.
      expect(shown['why'], firstLines(p.answer, max: null), reason: id);
      expect(shown['why'], isNotEmpty, reason: id);
    }
    // Over four hundred days both kinds come round.
    expect(picks, greaterThan(100));
    expect(shares, greaterThan(0));
  });

  test('a friend\'s score is the app\'s: five answers judged on the files '
      'count as many right as the same five locked in in the app', () {
    for (final DateTime date in dates) {
      final List<Pill> five = DailyDeal.five(date);
      // Every way of being right and wrong a day can be played: a pick
      // right or one along, a share on its answer or forty points off.
      for (int mask = 0; mask < 32; mask++) {
        int app = 0, site = 0;
        for (final (int i, Pill p) in five.indexed) {
          final bool aimRight = mask & (1 << i) != 0;
          final Map<String, Object?> shown = shownOf(p.id);
          final String said;
          switch (p.challenge) {
            case PickOne(:final correct, :final options):
              final int pick = aimRight
                  ? correct
                  : (correct + 1) % options.length;
              said = '$pick';
              if (pick == shown['correct']) site++;
            default:
              final double truth = answerOf(p)!.value;
              final int guess = (aimRight ? truth : (truth + 40) % 100)
                  .round()
                  .clamp(0, 100);
              said = plainResponse(guess.toDouble());
              final List<Object?>? right = shown['right'] as List<Object?>?;
              if (right != null &&
                  guess >= (right[0]! as num) &&
                  guess <= (right[1]! as num)) {
                site++;
              }
          }
          if (p.challenge.accepts(said)) app++;
        }
        expect(site, app, reason: '${dateKey(date)}, $mask');
      }
    }
  });

  test('each card\'s file stays small', () {
    for (final String id in named()) {
      final int bytes = File('${out.path}/cards/$id.json').lengthSync();
      expect(bytes, lessThan(2500), reason: id);
    }
  });
}
