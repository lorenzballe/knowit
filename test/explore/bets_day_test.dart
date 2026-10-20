// The day's hundred points and what was bet with them: spent and won,
// kept across a restart for the day they belong to, and gone the next day
// on the phone's calendar.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/state/explore_play.dart';

Bet stake(String pill, {required bool right, int stake = 20}) => Bet(
  kind: 'stake',
  section: 'stakes',
  pill: pill,
  said: '1',
  right: right,
  points: right ? stake : -stake,
  confidence: 70,
  facts: {'stake': stake},
  at: 0,
);

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() {
    now = DateTime(2026, 10, 18, 23, 30);
    SharedPreferences.setMockInitialValues({});
    BetsDay.resetForTest(clock: clock);
  });

  test('a day starts with a hundred points', () async {
    await BetsDay.instance.load();
    expect(BetsDay.instance.points, BetsDay.dailyPoints);
    expect(BetsDay.dailyPoints, 100);
    expect(BetsDay.instance.slip, isEmpty);
  });

  test('a stake lost is spent, a stake won is doubled', () async {
    final BetsDay day = BetsDay.instance;
    await day.load();
    day.place(stake('a', right: false, stake: 30));
    expect(day.points, 70);
    day.place(stake('b', right: true));
    expect(day.points, 90);
    expect([for (final b in day.slip) b.pill], ['a', 'b']);
    expect(day.betOn('stake', 'a')!.confidence, 70);
  });

  test('the first bet on a card stands', () async {
    final BetsDay day = BetsDay.instance;
    await day.load();
    day.place(stake('a', right: false));
    day.place(stake('a', right: true));
    expect(day.points, 80);
    expect(day.slip, hasLength(1));
    // Another kind of bet on the same card is its own bet.
    day.place(
      const Bet(
        kind: 'magnitude',
        section: 'sizes',
        pill: 'a',
        said: '1000',
        right: true,
        at: 0,
      ),
    );
    expect(day.slip, hasLength(2));
  });

  test('a bet half laid is kept, and gone once laid', () async {
    final BetsDay day = BetsDay.instance;
    await day.load();
    final String key = BetsDay.draftKey('stake', 'a');
    day.keepDraft(key, {'o': 1, 'k': 2});
    expect(day.draft(key), {'o': 1, 'k': 2});
    day.place(stake('a', right: true));
    expect(day.draft(key), isNull);
  });

  test('kept on the phone for the rest of the day', () async {
    final BetsDay day = BetsDay.instance;
    await day.load();
    day.place(stake('a', right: false, stake: 30));
    day.keepDraft(BetsDay.draftKey('range', 'b'), {'g': 40, 'w': 0});
    day.keepDeal('stakes|', ['a', 'c']);
    await pumpEventQueue();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.startsWith(BetsDay.prefix)),
      unorderedEquals([
        'knowit.explore.bets.day',
        'knowit.explore.bets.slip',
        'knowit.explore.bets.play',
        'knowit.explore.bets.deals',
      ]),
    );
    expect(prefs.getString('knowit.explore.bets.day'), '2026-10-18');

    // A restart later the same day.
    now = DateTime(2026, 10, 18, 23, 59);
    BetsDay.resetForTest(clock: clock);
    final BetsDay again = BetsDay.instance;
    await again.load();
    expect(again.points, 70);
    expect(again.betOn('stake', 'a'), isNotNull);
    expect(again.draft(BetsDay.draftKey('range', 'b')), {'g': 40, 'w': 0});
    expect(again.deal('stakes|'), ['a', 'c']);
    expect(again.claimedBesides('other|'), {'a', 'c'});
    expect(again.claimedBesides('stakes|'), isEmpty);
  });

  test('the next day starts clean, on the phone calendar', () async {
    final BetsDay day = BetsDay.instance;
    await day.load();
    day.place(stake('a', right: false, stake: 30));
    day.keepDraft(BetsDay.draftKey('range', 'b'), {'g': 40});
    day.keepDeal('stakes|', ['a']);
    await pumpEventQueue();
    expect(day.points, 70);

    // Past midnight, with the app still open.
    now = DateTime(2026, 10, 19, 0, 1);
    expect(day.points, 100);
    expect(day.slip, isEmpty);
    expect(day.betOn('stake', 'a'), isNull);
    expect(day.draft(BetsDay.draftKey('range', 'b')), isNull);
    expect(day.deal('stakes|'), isNull);

    // And after a restart on the new day: yesterday's are not read back.
    BetsDay.resetForTest(clock: clock);
    await BetsDay.instance.load();
    expect(BetsDay.instance.points, 100);
    expect(BetsDay.instance.slip, isEmpty);
  });

  test('a bet laid before the day is read is not lost to it', () async {
    SharedPreferences.setMockInitialValues({
      'knowit.explore.bets.day': '2026-10-18',
      'knowit.explore.bets.slip': '[{"k":"stake","s":"stakes","p":"a","w":"1","r":false,"n":-20,"t":0}]',
    });
    BetsDay.resetForTest(clock: clock);
    final BetsDay day = BetsDay.instance;
    day.place(stake('b', right: true, stake: 10));
    await day.load();
    expect([for (final b in day.slip) b.pill], ['a', 'b']);
  });

  test('one purse with Work it out: what either spends, both see', () async {
    final BetsDay day = BetsDay.instance;
    await day.load();
    day.place(stake('a', right: false, stake: 30));
    expect(ExplorePlay.instance.points, 70);
    // A stake on Work it out, from the same hundred.
    ExplorePlay.instance.addPoints(-20);
    expect(day.points, 50);
    // Never below none.
    ExplorePlay.instance.addPoints(-500);
    expect(day.points, 0);
  });

  test('a store that cannot be read starts the day clean', () async {
    SharedPreferences.setMockInitialValues({
      'knowit.explore.bets.day': '2026-10-18',
      'knowit.explore.bets.slip': 'not json',
      'knowit.explore.bets.deals': '[1, 2]',
    });
    BetsDay.resetForTest(clock: clock);
    await BetsDay.instance.load();
    expect(BetsDay.instance.slip, isEmpty);
    expect(BetsDay.instance.deal('x'), isNull);
    expect(BetsDay.instance.points, 100);
  });

  test('a bet keeps what it was', () {
    final Bet bet = stake('a', right: true);
    final Bet? back = Bet.fromJson(bet.toJson());
    expect(back, isNotNull);
    expect(back!.kind, 'stake');
    expect(back.pill, 'a');
    expect(back.right, isTrue);
    expect(back.points, 20);
    expect(back.confidence, 70);
    expect(back.facts, {'stake': 20});
    expect(Bet.fromJson({'k': 'stake'}), isNull);
    expect(Bet.fromJson('nonsense'), isNull);
  });
}
