// Photographs every block of bets at every size, before it is played and
// after, on three phones, on the night paper and the day one — and on the
// smallest phone at a large text size, where a layout that fits only the
// text it was drawn around comes apart.
//
//   flutter test tool/bets_shots.dart --update-goldens
//
// A camera, not a check, so it lives outside test/ like the other shots.
// The pictures land in tool/shots/bets/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/bigger.dart';
import 'package:astuto/explore/blocks/bets/closer.dart';
import 'package:astuto/explore/blocks/bets/day.dart';
import 'package:astuto/explore/blocks/bets/magnitude.dart';
import 'package:astuto/explore/blocks/bets/number.dart';
import 'package:astuto/explore/blocks/bets/range.dart';
import 'package:astuto/explore/blocks/bets/stake.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/state/app_state.dart';

import '../test/explore/bets_host.dart';

const Map<String, Size> _phones = {
  '375': Size(375, 667),
  '402': Size(402, 874),
  '430': Size(430, 932),
};

/// The day every picture is taken on, so the cards dealt are the same.
DateTime _day() => DateTime(2026, 10, 18, 12);

Future<void> _settle(WidgetTester tester) async {
  for (int f = 0; f < 8; f++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final Finder f = find.byKey(ValueKey(key));
  expect(f, findsWidgets, reason: key);
  // The page is tall enough for every block whole, and the first tile of a
  // row is in sight: nothing is scrolled, so the picture is the shelf as it
  // first appears, played.
  await tester.tap(f.first, warnIfMissed: false);
  await _settle(tester);
}

/// Plays the first tile of a block: what a reader would do with it.
typedef Play = Future<void> Function(WidgetTester tester);

Future<void> _playRange(WidgetTester tester) async {
  final String id = tester
      .widget<RangeTile>(find.byType(RangeTile).first)
      .answer
      .pill
      .id;
  final Finder track = find.byKey(ValueKey('bets-range-track-$id'));
  final Rect r = tester.getRect(track);
  await tester.tapAt(Offset(r.left + 11 + (r.width - 22) * 0.3, r.center.dy));
  await _settle(tester);
  await _tapKey(tester, 'bets-range-$id-w0');
  await _tapKey(tester, 'bets-range-bet-$id');
}

Future<void> _playStake(WidgetTester tester) async {
  final String id = tester
      .widget<StakeTile>(find.byType(StakeTile).first)
      .answer
      .pill
      .id;
  await _tapKey(tester, 'bets-stake-$id-o1');
  await _tapKey(tester, 'bets-stake-$id-k1');
  await _tapKey(tester, 'bets-stake-bet-$id');
  await _tapKey(tester, 'bets-sure-$id-70');
}

Future<void> _playNumber(WidgetTester tester) async {
  final NumberTile tile = tester.widget<NumberTile>(
    find.byType(NumberTile).first,
  );
  final String id = tile.answer.pill.id;
  final Finder steppers = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('bets-number-$id-') &&
        !(w.key! as ValueKey<String>).value.contains('lock') &&
        !(w.key! as ValueKey<String>).value.contains('said') &&
        !(w.key! as ValueKey<String>).value.contains('sure'),
  );
  // The last stepper is the big step up.
  await tester.tap(steppers.at(3));
  await _settle(tester);
  await tester.tap(steppers.at(2));
  await _settle(tester);
  await _tapKey(tester, 'bets-number-lock-$id');
  await _tapKey(tester, 'bets-sure-$id-80');
}

Future<void> _playCloser(WidgetTester tester) async {
  final String id = tester
      .widget<CloserTile>(find.byType(CloserTile).first)
      .answer
      .pill
      .id;
  await _tapKey(tester, 'bets-closer-$id-more');
  await _tapKey(tester, 'bets-closer-$id-less');
  if (find.byKey(ValueKey('bets-closer-$id-more')).evaluate().isNotEmpty) {
    await _tapKey(tester, 'bets-closer-$id-more');
  }
}

Future<void> _playMagnitude(WidgetTester tester) async {
  final String id = tester
      .widget<MagnitudeTile>(find.byType(MagnitudeTile).first)
      .answer
      .pill
      .id;
  await _tapKey(tester, 'bets-magnitude-$id-2');
  await _tapKey(tester, 'bets-sure-$id-60');
}

Future<void> _playBigger(WidgetTester tester) async {
  final String id = tester
      .widget<BiggerPair>(find.byType(BiggerPair).first)
      .a
      .pill
      .id;
  await _tapKey(tester, 'bets-bigger-$id');
}

Future<void> _playDay(WidgetTester tester) async {
  final String id = tester
      .widget<DayTile>(find.byType(DayTile).first)
      .answer
      .pill
      .id;
  final Finder track = find.byKey(ValueKey('bets-day-track-$id'));
  await tester.ensureVisible(track);
  await _settle(tester);
  final Rect r = tester.getRect(track);
  await tester.dragFrom(r.center, Offset(-(r.width - 22) * 0.3, 0));
  await _settle(tester);
  await _tapKey(tester, 'bets-day-lock-$id');
  await _tapKey(tester, 'bets-sure-$id-70');
}

Future<void> _nothing(WidgetTester tester) async {}

/// Every block, its sizes, and how it is played.
final List<(String, List<String>, Play)> _blocks = [
  ('bets-range', ['s', 'm', 'l'], _playRange),
  ('bets-stake', ['s', 'm', 'l'], _playStake),
  ('bets-friend', ['s', 'm', 'l'], _nothing),
  ('bets-number', ['s', 'm', 'l'], _playNumber),
  ('bets-bigger', ['s', 'm', 'l'], _playBigger),
  ('bets-closer', ['s', 'm', 'l'], _playCloser),
  ('bets-magnitude', ['s', 'm', 'l'], _playMagnitude),
  ('bets-day', ['s', 'm', 'l'], _playDay),
  ('bets-slip', ['s', 'm', 'l'], _nothing),
];

Future<void> _photograph(
  WidgetTester tester, {
  required String phone,
  required Brightness brightness,
  double text = 1,
}) async {
  final Size size = _phones[phone]!;
  final view = tester.view;
  view.physicalSize = Size(size.width * 2, 9000 * 2);
  view.devicePixelRatio = 2;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);

  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  // ignore: invalid_use_of_visible_for_testing_member
  BetsDay.resetForTest(clock: _day);
  final AppState app = AppState(clock: _day);
  await tester.runAsync(app.init);
  final BetsTestHost host = BetsTestHost(app);
  await tester.runAsync(BetsDay.instance.load);

  final String theme = brightness == Brightness.dark ? 'dark' : 'light';
  final String scale = text == 1 ? '' : '-x$text';
  for (final (String block, List<String> sizes, Play play) in _blocks) {
    for (final String s in sizes) {
      final ExploreSection section = ExploreSection(
        id: '$block-$s',
        block: block,
        json: {'id': '$block-$s', 'block': block, 'size': s},
      );
      await tester.pumpWidget(
        betsApp(
          BetsPage(host: host, sections: [section]),
          brightness: brightness,
          phone: Size(size.width, 9000),
          text: text,
        ),
      );
      await _settle(tester);
      final Finder shot = find.byKey(ValueKey('page-${section.id}'));
      if (shot.evaluate().isEmpty) continue;
      final String name = '$phone-$theme$scale-$block-$s';
      await expectLater(shot, matchesGoldenFile('shots/bets/$name-0.png'));
      if (play == _nothing) continue;
      await play(tester);
      await _settle(tester);
      await expectLater(shot, matchesGoldenFile('shots/bets/$name-1.png'));
    }
  }
}

void main() {
  setUpAll(loadBetsFonts);

  for (final String phone in _phones.keys) {
    for (final Brightness b in Brightness.values) {
      testWidgets('every block on $phone, ${b.name}', (tester) async {
        await _photograph(tester, phone: phone, brightness: b);
      });
    }
  }

  for (final double text in [1.3, 2.0]) {
    testWidgets('every block on 375 at text $text', (tester) async {
      await _photograph(
        tester,
        phone: '375',
        brightness: Brightness.dark,
        text: text,
      );
    });
  }
}
