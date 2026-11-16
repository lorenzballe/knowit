import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/reader_snapshot.dart';
import 'package:astuto/widgets/web/page_messages.dart';

Map<String, Object?> _pick(String id, {Object? sure, Object? reacts}) => {
  'id': id,
  'topic': 'thinking',
  'kind': 'pickOne',
  'difficulty': 'medium',
  'principle': 'baseRate',
  'question': 'Which is $id?',
  'options': ['A', 'B', 'C'],
  'correct': 1,
  'answer': 'B.',
  'move': 'Ask the base rate.',
  'source': 'A source',
  'sure': ?sure,
  'reacts': ?reacts,
};

Future<AppState> _app() async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('How sure, asked some of the time', () {
    final DateTime day = DateTime(2026, 11, 16);

    test('a card that gives no odds asks every time, as every card did', () {
      final Pill card = cardFromJson(_pick('always'));
      expect(card.sureOdds, isNull);
      expect(SureAsk.of(card, on: day), isTrue);
    });

    test('a card read from its file keeps its odds and whether it reacts', () {
      final Pill card = cardFromJson(_pick('some', sure: 0.35, reacts: true));
      expect(card.sureOdds, 0.35);
      expect(card.reacts, isTrue);
      expect(cardFromJson(_pick('wild', sure: 7)).sureOdds, 1);
      expect(cardFromJson(_pick('plain')).reacts, isFalse);
    });

    test('odds of none never ask, and odds of one always do', () {
      expect(SureAsk.of(cardFromJson(_pick('n', sure: 0)), on: day), isFalse);
      expect(SureAsk.of(cardFromJson(_pick('y', sure: 1)), on: day), isTrue);
    });

    test('odds of 0.4 ask about four cards in ten, the same way all day', () {
      SureAsk.seed = 'reader-a';
      final List<Pill> cards = [
        for (var i = 0; i < 600; i++) cardFromJson(_pick('c$i', sure: 0.4)),
      ];
      final int asked = cards.where((c) => SureAsk.of(c, on: day)).length;
      expect(asked / cards.length, closeTo(0.4, 0.08));
      for (final Pill c in cards.take(40)) {
        expect(
          SureAsk.of(c, on: day.add(const Duration(hours: 9))),
          SureAsk.of(c, on: day),
        );
      }
      // Another reader is drawn their own way.
      SureAsk.seed = 'reader-b';
      final int differ = cards
          .where((c) => SureAsk.of(c, on: day) != _askedFor('reader-a', c, day))
          .length;
      expect(differ, greaterThan(100));
      SureAsk.seed = '';
    });

    test('a card with nothing to be right about never asks', () {
      final Pill read = PillBank.live.firstWhere((p) => !p.isGraded);
      expect(SureAsk.of(read, on: day), isFalse);
    });

    test('the page is told whether this card asks', () {
      expect(const PageEnv().toJson()['sure'], isTrue);
      expect(const PageEnv(sure: false).toJson()['sure'], isFalse);
      expect(
        const PageEnv(sure: false).copyWith(shown: true).toJson()['sure'],
        isFalse,
      );
    });
  });

  test('right or wrong is kept on a card answered without a word on how '
      'sure; calibration reads only the ones with one', () async {
    final app = await _app();
    final List<Pill> graded = PillBank.live
        .where((p) => p.challenge is PickOne && p.isGraded)
        .take(2)
        .toList();
    final PickOne pick = graded[0].challenge as PickOne;
    await app.recordAnswer(graded[0].id, '${pick.correct}');
    await app.recordAnswer(graded[1].id, '0', confidence: 80);
    expect(app.judgements, hasLength(2));
    expect(app.judgements.first.confidence, isNull);
    expect(app.judgements.first.correct, isTrue);
    expect(app.calibrated, hasLength(1));
    expect(app.calibratedAnswers, 1);
    expect(app.standing.judged, 1);
    // And it goes through the backup as it is.
    final Judgement back = Judgement.fromJson(
      jsonDecode(jsonEncode(app.judgements.first.toJson())),
    )!;
    expect(back.confidence, isNull);
    expect(back.correct, isTrue);
  });

  group('What a card did for the reader', () {
    test('a page says it, and a word the app does not know says nothing', () {
      expect(
        PageMessage.parse('{"t":"react","value":"changed"}'),
        isA<PageReact>().having(
          (m) => m.reaction,
          'reaction',
          Reaction.changed,
        ),
      );
      expect(PageMessage.parse('{"t":"react","value":"meh"}'), isNull);
    });

    test('kept on the phone, counted, and the latest word stands', () async {
      final app = await _app();
      await app.react('a', Reaction.fresh);
      await app.react('b', Reaction.changed);
      await app.react('c', Reaction.knew);
      await app.react('a', Reaction.changed);
      expect(app.reactionCounts, {
        Reaction.fresh: 0,
        Reaction.changed: 2,
        Reaction.knew: 1,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('knowit.reactions')!), {
        'a': 'changed',
        'b': 'changed',
        'c': 'knew',
      });
      final again = AppState();
      await again.init();
      expect(again.reactions['a'], 'changed');
    });

    test('in the backup as words, never an array; two phones join, this '
        "one's word standing", () {
      final local = ReaderSnapshot(reactions: {'a': 'new', 'b': 'knew'});
      final back = ReaderSnapshot.fromJson(
        jsonDecode(jsonEncode(local.toJson())) as Map<String, dynamic>,
      );
      expect(back.reactions, {'a': 'new', 'b': 'knew'});
      expect(local.toJson()['reactions'], isA<Map>());
      final remote = ReaderSnapshot(reactions: {'a': 'changed', 'c': 'knew'});
      expect(mergeSnapshots(local, remote).reactions, {
        'a': 'new',
        'b': 'knew',
        'c': 'knew',
      });
      expect(
        ReaderSnapshot.fromJson({
          'reactions': {'a': 'new', 'b': 'meh', 'c': 3},
        }).reactions,
        {'a': 'new'},
      );
    });
  });
}

bool _askedFor(String seed, Pill card, DateTime day) {
  final String was = SureAsk.seed;
  SureAsk.seed = seed;
  final bool asked = SureAsk.of(card, on: day);
  SureAsk.seed = was;
  return asked;
}
