// The round controls of the layer over the content, back and close
// (lib/widgets/glass_round.dart): Apple's own glass button on iOS 26 and
// later, and everywhere else the button the screen draws, untouched; the
// tab bar Apple's own only where the system draws its glass.
//
//   flutter test test/glass_round_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart'
    show LiquidGlassButton;

import 'package:astuto/widgets/glass_round.dart';
import 'package:astuto/widgets/hand_glass.dart';

void main() {
  testWidgets('off iOS 26 a round control is the button its screen gives, '
      'and the system\'s glass is not asked for', (tester) async {
    // An iPhone as the camera draws one: no system to draw the glass.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(appleGlass, isFalse);
      expect(handGlass, isTrue);
      int pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: GlassRound(
              symbol: GlassRound.back,
              label: 'Back',
              onPressed: () => pressed++,
              fallback: GestureDetector(
                onTap: () => pressed++,
                child: const Text('the screen\'s own'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('the screen\'s own'), findsOneWidget);
      expect(find.byType(LiquidGlassButton), findsNothing);
      await tester.tap(find.text('the screen\'s own'));
      expect(pressed, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('back is Apple\'s chevron, close its cross', () {
    expect(GlassRound.back, 'chevron.left');
    expect(GlassRound.close, 'xmark');
  });
}
