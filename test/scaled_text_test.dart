import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/widgets/scaled_text.dart';

/// A question set to its box is set to it as the reader will see it: at
/// their text size. Measured at a text size of one, a reader a step or two
/// up the iOS setting saw their question cut off inside its own box.
void main() {
  const String question =
      'A call goes up to a satellite 35,786 km high and back down. At '
      '300,000 km/s, how many milliseconds does that hop take?';

  Future<Size> setIn(
    WidgetTester tester, {
    required double scale,
    required Size box,
    String text = question,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.fromSize(
              size: box,
              child: ScaledText(
                text: text,
                min: 12,
                max: 30,
                styleFor: (size) => TextStyle(fontSize: size, height: 1.1),
              ),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.text(text));
  }

  double sizeOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.fontSize!;

  for (final double scale in [1.0, 1.15, 1.3, 2.0]) {
    testWidgets('the question fits its box at ${scale}x text', (tester) async {
      const Size box = Size(300, 200);
      final Size drawn = await setIn(tester, scale: scale, box: box);
      expect(drawn.height, lessThanOrEqualTo(box.height));
      expect(drawn.width, lessThanOrEqualTo(box.width));
    });
  }

  testWidgets('larger text is chosen smaller, and drawn the same size', (
    tester,
  ) async {
    const Size box = Size(300, 200);
    await setIn(tester, scale: 1, box: box);
    final double atOne = sizeOf(tester, question);
    await setIn(tester, scale: 1.3, box: box);
    final double atMore = sizeOf(tester, question);
    expect(atMore, lessThan(atOne));
    expect(atMore * 1.3, closeTo(atOne, 1.5));
  });

  testWidgets('a short question still grows with the reader\'s text', (
    tester,
  ) async {
    const String short = 'Why?';
    await setIn(tester, scale: 1.3, box: const Size(300, 200), text: short);
    expect(sizeOf(tester, short), 30);
  });

  testWidgets('no word is broken to make the question fit', (tester) async {
    const String text = 'Soil temperatures';
    await setIn(tester, scale: 2, box: const Size(160, 300), text: text);
    final double size = sizeOf(tester, text);
    final TextPainter word = TextPainter(
      text: TextSpan(
        text: 'temperatures',
        style: TextStyle(fontSize: size, height: 1.1),
      ),
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(2),
    )..layout();
    expect(word.width, lessThanOrEqualTo(160));
    word.dispose();
  });
}
