// A scene's confirm (Lock it in under a drawn curve, or a timeline) gives
// under the finger the instant it is touched, and comes back when let go;
// never where it cannot be pressed, and it takes no tap of its own.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/widgets/press_scale.dart';

void main() {
  testWidgets('pressed, it shows pressed; let go, it comes back; not live, '
      'it never gives; taps still reach the button round it', (tester) async {
    int taps = 0;
    Future<void> host(bool live) => tester.pumpWidget(
      MaterialApp(
        home: Center(
          // Opaque, as the scenes' buttons are.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: PressScale(
              live: live,
              child: const SizedBox(width: 120, height: 44),
            ),
          ),
        ),
      ),
    );
    double scale() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    await host(true);
    TestGesture finger = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump();
    expect(scale(), lessThan(1));
    await finger.up();
    await tester.pump();
    expect(scale(), 1);
    expect(taps, 1);

    await host(false);
    finger = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump();
    expect(scale(), 1);
    await finger.up();
    await tester.pump();
    expect(taps, 2);
  });
}
