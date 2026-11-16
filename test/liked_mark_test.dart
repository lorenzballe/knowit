import 'package:flutter_test/flutter_test.dart';
import 'package:astuto/widgets/liked_mark.dart';

void main() {
  test("a drawn card's tag is read from its page, and the heart stands "
      'before it', () {
    CardTags.remember(
      'tagged',
      '<div class="label"><span class="t">Science</span>'
          '<span class="tag">Rigid&nbsp;?</span></div>',
    );
    expect(CardTags.of('tagged'), 'Rigid ?');

    CardTags.remember(
      'bare',
      '<div class="label"><span class="t">Art</span></div>',
    );
    expect(CardTags.knows('bare'), isTrue);
    expect(CardTags.of('bare'), isNull);

    // No tag: the heart stands at the card's margin, as on a card in words.
    expect(CardTags.heartRight(null), CardTags.margin);
    // A tag: past it, its padding and the gap, and further for a longer one.
    expect(
      CardTags.heartRight('RIGID?'),
      greaterThan(CardTags.margin + 18 + 8),
    );
    expect(
      CardTags.heartRight('WHICH ONE IS REAL?'),
      greaterThan(CardTags.heartRight('RIGID?')),
    );
  });
}
