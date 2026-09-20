import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/models/pill.dart';

/// A bundle document with [cards], stamped [version].
String bundle({
  required int version,
  required List<Map<String, Object?>> cards,
  Map<String, String> editions = const {},
}) => jsonEncode({
  'format': 1,
  'version': version,
  'built': '2026-09-17T03:00:00Z',
  'cards': cards,
  'editions': editions,
});

Map<String, Object?> read(String id, {String topic = 'space'}) => {
  'id': id,
  'topic': topic,
  'kind': 'read',
  'difficulty': 'easy',
  'principle': 'none',
  'question': 'What is $id about?',
  'answer': 'It is about $id, and that is all it is about.',
  'move': 'The move of $id.',
  'source': 'A source',
};

Map<String, Object?> pick(String id) => {
  'id': id,
  'topic': 'thinking',
  'kind': 'pickOne',
  'difficulty': 'medium',
  'principle': 'baseRate',
  'question': 'Which is $id?',
  'options': ['This', 'That'],
  'correct': 1,
  'answer': 'That one.',
  'move': 'The move of $id.',
  'trap': 'Picking this.',
  'source': 'A source',
};

void main() {
  setUp(() {
    PillBank.reset();
    resetCalendar();
    SharedPreferences.setMockInitialValues({});
  });

  group('The bank on disk', () {
    test('every card survives the round trip through JSON', () {
      for (final p in PillBank.cards) {
        final json = cardToJson(p);
        final back = cardFromJson(json);
        expect(cardToJson(back), json, reason: p.id);
        expect(back.challenge.runtimeType, p.challenge.runtimeType);
        expect(back.topic, p.topic);
        expect(back.color, p.color);
      }
    });

    test('is the same cards the bank folder holds, one file each', () {
      final files = Directory('tool/cards/bank')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      final onDisk = {
        for (final f in files)
          (jsonDecode(f.readAsStringSync()) as Map<String, Object?>)['id']:
              f.path,
      };
      final embedded = PillBank.embedded.cards.map((p) => p.id).toSet();
      expect(onDisk.keys.toSet(), embedded, reason: 'run tool/cards/bundle.py');
      for (final f in files) {
        final raw = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
        expect(
          f.path,
          contains('/${raw['topic']}/'),
          reason: 'a card lives in its topic folder',
        );
        // Word for word: an edit to a file that was not bundled is the
        // other way a phone and the bank could disagree.
        final id = raw['id'] as String;
        raw.removeWhere(
          (k, _) => k == 'reference' || k == 'written' || k == 'disabled',
        );
        expect(
          cardToJson(PillBank.byId(id)!),
          raw,
          reason: '$id differs from its file: run tool/cards/bundle.py',
        );
      }
    });

    test('is the same document the site serves', () {
      final served = BankBundle.parse(
        File('web/cards/cards.json').readAsStringSync(),
      );
      expect(
        served.cards.map((p) => p.id),
        PillBank.embedded.cards.map((p) => p.id),
      );
      expect(served.editions, PillBank.embedded.editions);
    });

    test('names the graded question of the day for every edition it holds', () {
      for (final e in PillBank.editions.entries) {
        final card = PillBank.byId(e.value);
        expect(card, isNotNull, reason: 'edition ${e.key}');
        expect(card!.isGraded, isTrue, reason: 'edition ${e.key}');
      }
    });
  });

  group('A bundle', () {
    test('is refused whole when a card cannot be drawn', () {
      final bad = read('space-x')..['topic'] = 'astrology';
      expect(
        () =>
            BankBundle.parse(bundle(version: 1, cards: [read('space-1'), bad])),
        throwsFormatException,
      );
      expect(
        () => BankBundle.parse(
          bundle(version: 1, cards: [read('space-1')..remove('question')]),
        ),
        throwsFormatException,
      );
      expect(
        () => BankBundle.parse(
          bundle(
            version: 1,
            cards: [read('space-1')],
            editions: {'1': 'nobody'},
          ),
        ),
        throwsFormatException,
      );
      expect(() => BankBundle.parse('not json'), throwsFormatException);
      expect(() => BankBundle.parse('{"cards": []}'), throwsFormatException);
    });

    test('keeps a retired card out of the deal but findable', () {
      final b = BankBundle.parse(
        bundle(
          version: 1,
          cards: [read('space-1'), read('space-2')..['disabled'] = true],
        ),
      );
      PillBank.adopt(b);
      expect(PillBank.cards.map((p) => p.id), ['space-1']);
      expect(PillBank.byId('space-2'), isNotNull);
      expect(pillsByIds(['space-2', 'space-1']).map((p) => p.id), [
        'space-2',
        'space-1',
      ]);
    });

    test('re-deals the calendar when adopted', () {
      final before = questionOfEdition(1).id;
      PillBank.adopt(
        BankBundle.parse(
          bundle(
            version: 1,
            cards: [pick('thinking-a'), pick('thinking-b'), read('space-1')],
            editions: {'1': 'thinking-b', '2': 'thinking-a'},
          ),
        ),
      );
      expect(questionOfEdition(1).id, 'thinking-b');
      expect(questionOfEdition(2).id, 'thinking-a');
      expect(questionOfEdition(1).id, isNot(before));
      PillBank.reset();
      expect(questionOfEdition(1).id, before);
    });
  });

  group('Keeping the bank fresh', () {
    test(
      'restores a newer stored bundle at start, never an older one',
      () async {
        final newer = PillBank.embedded.version + 1;
        SharedPreferences.setMockInitialValues({
          'knowit.bank': bundle(version: newer, cards: [read('space-9')]),
        });
        PillBank.restore(await SharedPreferences.getInstance());
        expect(PillBank.version, newer);
        expect(PillBank.cards.single.id, 'space-9');

        PillBank.reset();
        SharedPreferences.setMockInitialValues({
          'knowit.bank': bundle(version: 1, cards: [read('space-9')]),
        });
        PillBank.restore(await SharedPreferences.getInstance());
        expect(PillBank.version, PillBank.embedded.version);
      },
    );

    test('forgets a stored bundle it can no longer read', () async {
      SharedPreferences.setMockInitialValues({'knowit.bank': '{"broken":'});
      final prefs = await SharedPreferences.getInstance();
      PillBank.restore(prefs);
      expect(PillBank.version, PillBank.embedded.version);
      expect(prefs.getString('knowit.bank'), isNull);
    });

    test('stores what it downloads only when it is newer', () async {
      final prefs = await SharedPreferences.getInstance();
      final newer = PillBank.embedded.version + 1;
      PillBank.fetch = (url) async {
        expect(url, kBankUrl);
        return bundle(version: newer, cards: [read('space-9')]);
      };
      expect(await PillBank.refresh(prefs), isTrue);
      expect(prefs.getString('knowit.bank'), isNotNull);
      // Not adopted mid-run: the table is not re-dealt under the reader.
      expect(PillBank.version, PillBank.embedded.version);

      await prefs.remove('knowit.bank');
      PillBank.fetch = (url) async =>
          bundle(version: 1, cards: [read('space-9')]);
      expect(await PillBank.refresh(prefs), isFalse);
      expect(prefs.getString('knowit.bank'), isNull);
    });

    test('shrugs at no signal, a bad body, or a server that is down', () async {
      final prefs = await SharedPreferences.getInstance();
      PillBank.fetch = (url) async => null;
      expect(await PillBank.refresh(prefs), isFalse);
      PillBank.fetch = (url) async => '<html>502</html>';
      expect(await PillBank.refresh(prefs), isFalse);
      PillBank.fetch = (url) async => throw const SocketException('offline');
      expect(await PillBank.refresh(prefs), isFalse);
      expect(prefs.getString('knowit.bank'), isNull);
    });
  });

  group('A card from JSON', () {
    test('carries every kind of challenge', () {
      expect(
        cardFromJson({...pick('thinking-q')}).challenge,
        isA<PickOne>().having((c) => c.correct, 'correct', 1),
      );
      expect(
        cardFromJson({
          ...read('thinking-n', topic: 'thinking'),
          'kind': 'number',
          'difficulty': 'medium',
          'principle': 'computation',
          'value': 190,
          'unit': 'journeys',
          'steps': ['20 x 19 = 380', '380 / 2 = 190'],
          'hint': 'Pairs.',
        }).challenge,
        isA<TypeNumber>().having((c) => c.answer, 'answer', 190),
      );
      expect(
        cardFromJson({
          ...read('thinking-e', topic: 'thinking'),
          'kind': 'estimate',
          'difficulty': 'medium',
          'principle': 'estimation',
          'value': 370,
          'unit': 'thousand tonnes',
          'withinFactor': 2,
          'steps': ['a', 'b'],
          'hint': 'Cups.',
        }).challenge,
        isA<Estimate>().having((c) => c.withinFactor, 'withinFactor', 2),
      );
      expect(
        cardFromJson({
          ...read('thinking-d', topic: 'thinking'),
          'kind': 'debate',
          'difficulty': 'medium',
          'sides': ['Yes', 'No'],
          'counterpoint': 'The other side.',
        }).challenge,
        isA<TakeASide>().having((c) => c.positions, 'positions', ['Yes', 'No']),
      );
    });

    test('refuses what the app could not draw', () {
      expect(
        () => cardFromJson(read('space-1')..['kind'] = 'riddle'),
        throwsFormatException,
      );
      expect(
        () => cardFromJson(read('space-1')..['principle'] = 'vibes'),
        throwsFormatException,
      );
      expect(
        () => cardFromJson(pick('thinking-q')..['correct'] = 5),
        throwsFormatException,
      );
      expect(
        () => cardFromJson({
          ...read('thinking-d', topic: 'thinking'),
          'kind': 'debate',
          'sides': ['Only one'],
        }),
        throwsFormatException,
      );
    });
  });
}
