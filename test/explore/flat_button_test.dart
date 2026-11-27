// A shelf's button (the lock of Today's five, of a bet) gives under the
// finger the instant it is touched, as a challenge's own button does, and
// only where it can be pressed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/widgets/explore/parts.dart';

void main() {
  testWidgets('pressed, it shows pressed; let go, it comes back; a button '
      'that cannot be pressed never gives', (tester) async {
    int taps = 0;
    Future<void> host(VoidCallback? onTap) => tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: FlatButton(
            label: 'Lock in',
            background: Colors.black,
            foreground: Colors.white,
            onTap: onTap,
          ),
        ),
      ),
    );
    double scale() => tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.byType(FlatButton),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;

    await host(() => taps++);
    TestGesture finger = await tester.startGesture(
      tester.getCenter(find.text('Lock in')),
    );
    await tester.pump();
    expect(scale(), lessThan(1));
    await finger.up();
    await tester.pump();
    expect(scale(), 1);
    expect(taps, 1);

    await host(null);
    finger = await tester.startGesture(tester.getCenter(find.text('Lock in')));
    await tester.pump();
    expect(scale(), 1);
    await finger.up();
    await tester.pump();
    expect(taps, 1);
  });
}
