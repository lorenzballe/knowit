import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';

/// The back of a card ends on one box, chosen by the card: what to keep, the
/// question to ask yourself, or — only when the card asks for it — both.
void main() {
  final Pill base = PillBank.cards.firstWhere(
    (p) => p.barMove.isNotEmpty && p.ask.isNotEmpty,
  );
  Pill withEnd(Map<String, Object?> extra) =>
      cardFromJson({...cardToJson(base), ...extra});

  test('by default the back ends on what to keep', () {
    final Pill p = withEnd({});
    expect(p.showsMove, isTrue);
    expect(p.showsAsk, isFalse);
  });

  test('a card can end on the question instead, and keeps its line', () {
    final Pill p = withEnd({'end': 'ask'});
    expect(p.endsOnAsk, isTrue);
    expect(p.showsMove, isFalse);
    expect(p.showsAsk, isTrue);
    expect(p.barMove, base.barMove);
    expect(cardToJson(p)['end'], 'ask');
  });

  test('both, only when the card asks for both', () {
    final Pill p = withEnd({'both': true});
    expect(p.showsMove, isTrue);
    expect(p.showsAsk, isTrue);
  });

  test('a card that ends on a question it has not got ends on its line', () {
    final Pill p = withEnd({'end': 'ask', 'ask': ''});
    expect(p.showsMove, isTrue);
    expect(p.showsAsk, isFalse);
  });
}
