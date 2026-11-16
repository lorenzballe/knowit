import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/reading_log.dart';
import 'package:astuto/sync/reader_snapshot.dart';

CardReadEntry _read(
  String id, {
  int front = 3000,
  int back = 0,
  int flips = 0,
  int? pct,
  bool thrown = true,
  bool reread = false,
}) => CardReadEntry(
  id: id,
  at: 1,
  msFront: front,
  msBack: back,
  flips: flips,
  backPct: pct,
  thrown: thrown,
  reread: reread,
);

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a read is written down from the facts it is said with', () {
    final CardReadEntry e = CardReadEntry.fromFacts(
      'a',
      {
        'ms_front': 4200,
        'ms_back': 9100,
        'flips': 1,
        'hint_opened': true,
        'options_changed': 2,
        'back_scroll_pct': 87,
        'reread': false,
      },
      thrown: true,
      at: DateTime.utc(2026, 11, 16),
    );
    expect(e.msFront, 4200);
    expect(e.msBack, 9100);
    expect(e.flips, 1);
    expect(e.hint, isTrue);
    expect(e.changed, 2);
    expect(e.backPct, 87);
    expect(e.thrown, isTrue);
    expect(e.held, isTrue);
    expect(CardReadEntry.fromJson(e.toJson())!.toJson(), e.toJson());
  });

  test('held and passed over: the latest word on each card', () {
    final s = ReadingLog.signals([
      _read('held', back: 8000, flips: 1, pct: 90),
      _read('skipped', front: 900),
      _read('again', reread: true),
      // Turned and put down: neither held nor passed over.
      _read('turned', front: 900, flips: 1, back: 1200),
      // Passed over once, held after: held.
      _read('changed', front: 800),
      _read('changed', back: 7000, flips: 1),
    ]);
    expect(s.held, {'held', 'again', 'changed'});
    expect(s.skipped, {'skipped'});
  });

  test('the log keeps the latest reads, up to its cap', () {
    var log = <CardReadEntry>[];
    for (var i = 0; i < ReadingLog.keep + 5; i++) {
      log = ReadingLog.added(log, _read('c$i'));
    }
    expect(log, hasLength(ReadingLog.keep));
    expect(log.first.id, 'c5');
    expect(
      ReadingLog.decode(ReadingLog.encode(log)).last.id,
      'c${ReadingLog.keep + 4}',
    );
    expect(ReadingLog.decode('not json'), isEmpty);
  });

  test("the reads go into the account's backup and come back; of two "
      'phones, the fuller record stands', () {
    final local = ReaderSnapshot(readingLog: [_read('a'), _read('b')]);
    final back = ReaderSnapshot.fromJson(
      jsonDecode(jsonEncode(local.toJson())) as Map<String, dynamic>,
    );
    expect(back.readingLog.map((e) => e.id), ['a', 'b']);
    final remote = ReaderSnapshot(readingLog: [_read('a')]);
    expect(mergeSnapshots(local, remote).readingLog.map((e) => e.id), [
      'a',
      'b',
    ]);
    expect(mergeSnapshots(remote, local).readingLog.map((e) => e.id), [
      'a',
      'b',
    ]);
  });

  group("an install that learns from reads (the experiment's implicit "
      'side)', () {
    final Pill card = PillBank.live.firstWhere((p) => p.traits.isNotEmpty);

    test('leans toward a card it held, by all its traits', () async {
      final app = await _app({
        'knowit.exp.tasteVariant': 'implicit',
        'knowit.readingLog': ReadingLog.encode([
          _read(card.id, back: 9000, flips: 1, pct: 100),
        ]),
      });
      expect(app.tasteVariant, 'implicit');
      for (final String trait in card.traits) {
        expect(app.taste[trait], greaterThan(0));
      }
    });

    test('and away from one it passed over', () async {
      final app = await _app({
        'knowit.exp.tasteVariant': 'implicit',
        'knowit.readingLog': ReadingLog.encode([_read(card.id, front: 700)]),
      });
      for (final String trait in card.traits) {
        expect(app.taste[trait], lessThan(0));
      }
    });

    test('while the other side learns only from what is said', () async {
      final app = await _app({
        'knowit.exp.tasteVariant': 'explicit',
        'knowit.readingLog': ReadingLog.encode([
          _read(card.id, back: 9000, flips: 1, pct: 100),
        ]),
      });
      expect(app.taste, isEmpty);
    });

    test('a fresh install is drawn to one side and keeps it', () async {
      final app = await _app({});
      expect(app.tasteVariant, anyOf('implicit', 'explicit'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.exp.tasteVariant'), app.tasteVariant);
    });
  });

  test('the strongest subject and the one missed most, from the latest '
      'answers in each, once six are in', () async {
    final app = await _app({});
    final Map<String, List<Pill>> byTopic = {};
    for (final Pill p in PillBank.live) {
      byTopic.putIfAbsent(p.topic, () => []).add(p);
    }
    final List<String> topics = [
      for (final e in byTopic.entries)
        if (e.value.length >= 6) e.key,
    ].take(3).toList();
    Judgement j(String topic, int i, bool correct) =>
        Judgement(70, correct: correct, pillId: byTopic[topic]![i].id);
    app.judgements = [
      for (var i = 0; i < 6; i++) j(topics[0], i, true),
      for (var i = 0; i < 6; i++) j(topics[1], i, i < 2),
      // Five: not measured yet.
      for (var i = 0; i < 5; i++) j(topics[2], i, false),
    ];
    final List<double> shares = [for (final s in subjectShares(app)) s.share]
      ..sort();
    expect(shares, [closeTo(1 / 3, 1e-9), 1.0]);
  });
}
