import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';

Map<String, Object?> _read(String id, [Map<String, Object?> more = const {}]) =>
    {
      'id': id,
      'topic': 'thinking',
      'kind': 'read',
      'difficulty': 'easy',
      'question': 'What is $id?',
      'answer': 'It is.',
      'move': 'Look again.',
      'source': 'A source',
      ...more,
    };

void main() {
  test('a card carries the link to its source: a page, or a DOI made one; '
      'a reference in words is no link', () {
    expect(
      cardFromJson(_read('a', {'reference': 'https://example.org/x'}))
          .reference,
      'https://example.org/x',
    );
    expect(
      cardFromJson(_read('b', {'reference': 'doi:10.1038/nature123'}))
          .reference,
      'https://doi.org/10.1038/nature123',
    );
    expect(
      cardFromJson(_read('c', {'reference': 'International Report, 2024'}))
          .reference,
      isEmpty,
    );
  });

  test('Go deeper: why it matters and the two views, read from the file', () {
    final Pill card = cardFromJson(
      _read('d', {
        'why': 'It changes how you read a poll.',
        'views': ['For: one.', 'Against: two.'],
      }),
    );
    expect(card.why, 'It changes how you read a poll.');
    expect(card.views, ['For: one.', 'Against: two.']);
    expect(card.goesDeeper, isTrue);
    expect(
      cardFromJson(
        _read('e', {
          'views': ['only one'],
        }),
      ).views,
      isEmpty,
    );
    expect(cardFromJson(_read('f')).goesDeeper, isFalse);
  });

  test('the bank as shipped carries the links', () {
    final int linked = PillBank.live
        .where((p) => p.reference.isNotEmpty)
        .length;
    expect(linked, greaterThan(1000));
  });
}
