// Text whose lines are as even as the width allows: as many lines as at
// the full width, never one more, and no word left alone on the last.
//
//   flutter test test/balanced_text_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/widgets/balanced_text.dart';

/// In the test face every letter and space is a square as wide as the type
/// is tall, so a width is a count of characters.
const TextStyle _style = TextStyle(fontSize: 10, height: 1);

Widget _in(double width, String text, {TextScaler? scaler}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(textScaler: scaler ?? TextScaler.noScaling),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: BalancedText(text, style: _style),
      ),
    ),
  ),
);

Size _set(WidgetTester tester) => tester.getSize(find.byType(RichText));

void main() {
  testWidgets('a line that wraps by one word is broken evenly', (tester) async {
    // 24 characters in 22: "aaaa bbbb cccc dddd" over "eeee" as it was.
    await tester.pumpWidget(_in(220, 'aaaa bbbb cccc dddd eeee'));
    final Size set = _set(tester);
    expect(set.height, 20, reason: 'still two lines');
    expect(set.width, lessThanOrEqualTo(150));
    expect(set.width, greaterThanOrEqualTo(140));
  });

  testWidgets('a line that fits stays one line, at the full width', (
    tester,
  ) async {
    await tester.pumpWidget(_in(220, 'aaaa bbbb'));
    expect(_set(tester), const Size(220, 10));
  });

  testWidgets('it never takes a line more than the full width does', (
    tester,
  ) async {
    for (final String text in [
      'aaaa bbbb cccc dddd eeee ffff gggg',
      'a bb ccc dddd eeeee ffffff ggggggg',
      'aaaaaaaaaaaa bb',
    ]) {
      for (final double width in [60.0, 130.0, 170.0, 230.0]) {
        await tester.pumpWidget(_in(width, text));
        final TextPainter plain = TextPainter(
          text: TextSpan(text: text, style: _style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width);
        expect(_set(tester).height, plain.height, reason: '"$text" in $width');
        plain.dispose();
      }
    }
  });

  testWidgets('the reader\'s text size is counted in', (tester) async {
    // At twice the size, 24 characters take 48 of 44 across: still two
    // lines, broken evenly.
    await tester.pumpWidget(
      _in(440, 'aaaa bbbb cccc dddd eeee', scaler: const TextScaler.linear(2)),
    );
    final Size set = _set(tester);
    expect(set.height, 40);
    expect(set.width, lessThanOrEqualTo(300));
  });
}
