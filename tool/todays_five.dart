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
// - cards/<id>.json, one for each card a day names: its question, its
//   subject's name and colours, and how the five play it — a pick's options
//   and the right one, or a share's answer and the guesses on the track the
//   app counts right — with the line of the answer the app shows under it,
//   its why. Small: nothing of the card the five do not show.
//
// The landing page reads the first, picks the reader's date, fetches that
// day's five cards and shows them, each linking to its card's page (/c/<id>).
// The challenge on today's five (/sfida, tool/cards/sfida_page.py) plays
// them: the day the link names, the five one at a time, each judged as the
// app judges it, then the scores side by side, each answer with its why.
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
import 'package:astuto/explore/blocks/bets/answers.dart' show plainResponse;
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show answerOf;
import 'package:astuto/explore/blocks/bets/parts.dart' show firstLines;
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

/// What the pages show of a card: its question, its subject's name and
/// colours (the subject's mark is named for it on the page), how the five
/// play it ([todaysFivePlay]), and its why: the line of the answer the app
/// shows once a card of the five is locked in (BetWhy).
Map<String, Object> todaysFiveCard(Pill p) => {
  'id': p.id,
  'question': p.question,
  'topic': p.topic,
  'color': AppState.hexOf(p.color),
  'ink': AppState.hexOf(p.ink),
  ...todaysFivePlay(p),
  'why': firstLines(p.answer, max: null),
};

/// How the five play [p], as the challenge's page needs it to judge an
/// answer exactly as the app does (lib/explore/blocks/bets/three.dart):
///
/// - a pick (`kind: pick`): its options and the right one's index, right
///   when that one is picked;
/// - a share (`kind: share`): its answer, from 0 to 100, set on a track of
///   whole points, and `right`, the first and last of the whole points the
///   card itself counts right ([Challenge.accepts]: within the card's
///   tolerance, or its factor) — read here from the card's own test, guess
///   by guess, so the page cannot judge a guess any other way. Left out
///   where no whole point is right.
Map<String, Object> todaysFivePlay(Pill p) {
  switch (p.challenge) {
    case PickOne(:final options, :final correct):
      return {'kind': 'pick', 'options': options, 'correct': correct};
    default:
      final double value = answerOf(p)?.value ?? 0;
      final List<int> right = [
        for (int g = 0; g <= 100; g++)
          if (p.challenge.accepts(plainResponse(g.toDouble()))) g,
      ];
      return {
        'kind': 'share',
        'value': value == value.roundToDouble() ? value.round() : value,
        if (right.isNotEmpty) 'right': [right.first, right.last],
      };
  }
}

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
