// Writes today's shelf and the question of the day for the weeks ahead,
// each card with its id, subject and colours, where the home-screen widgets
// can fetch them: widget/days.json on the site. A widget the app has never
// spoken to — no App Group on the Apple account yet, or the app not opened
// since it was installed — shows today's shelf from this, which is the same
// for every reader, and a tap on a card still opens that card.
//
// The shelf is the phone's own pick of the day, the one Explore falls back
// on and the server makes too, from the bank this deploy carries. The
// question of the day stays beside it, with its id, for the copies of this
// file that widgets already keep.
//
//   flutter test tool/widget_days.dart            (the deploy runs this)
//   WIDGET_DAYS_OUT=some/path.json flutter test tool/widget_days.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Map<String, Object> _card(Pill p) => {
  'id': p.id,
  'question': p.question,
  'topic': p.topic,
  'color': AppState.hexOf(p.color),
  'ink': AppState.hexOf(p.ink),
};

void main() {
  test('the widget\'s days', () {
    final DateTime now = DateTime.now().toUtc();
    // A day either side of the deploy's own, for phones in every timezone,
    // and two months ahead, so a quiet month of deploys still leaves the
    // widget something to show.
    final DateTime start = DateTime(now.year, now.month, now.day - 1);
    final days = <String, Object>{};
    for (var i = 0; i < 62; i++) {
      final DateTime day = DateTime(start.year, start.month, start.day + i);
      final Pill p = questionOfTheDay(day);
      days[_key(day)] = {
        'edition': editionOf(day),
        ..._card(p),
        'shelf': [
          for (final Pill s in pickedPills(
            seed: daySeed(day),
            count: AppState.kWidgetShelf,
          ))
            _card(s),
        ],
      };
    }
    final File out = File(
      Platform.environment['WIDGET_DAYS_OUT'] ?? 'build/web/widget/days.json',
    );
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(
      jsonEncode({'version': 2, 'built': now.toIso8601String(), 'days': days}),
    );
    expect(days, hasLength(62));
    for (final Object day in days.values) {
      expect((day as Map)['id'], isNotEmpty);
      expect(day['shelf'], hasLength(AppState.kWidgetShelf));
    }
  });
}
