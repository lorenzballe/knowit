// The grounds (lib/widgets/grounds.dart): a sheet's ground is the page's own
// surface everywhere, nothing imitates glass, and the tab bar is Apple's own
// glass only where the system draws it, on a real iOS 26: never in a test.
//
//   flutter test test/grounds_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/theme.dart';
import 'package:astuto/widgets/grounds.dart';

Widget _host(Widget child, Brightness b) => MaterialApp(
  theme: buildAstutoTheme(b),
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, height: 120, child: child)),
  ),
);

void main() {
  for (final TargetPlatform platform in [
    TargetPlatform.iOS,
    TargetPlatform.android,
  ]) {
    testWidgets('a sheet\'s ground is the page\'s surface, with nothing '
        'showing through, on ${platform.name}', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      for (final Brightness b in Brightness.values) {
        await tester.pumpWidget(
          _host(const SheetGround(child: Text('a sheet')), b),
        );
        // The theme eases from one to the other: read it once it has.
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsNothing);
        final DecoratedBox box = tester.widget(
          find
              .ancestor(
                of: find.text('a sheet'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final BoxDecoration d = box.decoration as BoxDecoration;
        expect(
          d.color,
          b == Brightness.dark ? Palette.dark.surface : Palette.light.surface,
        );
        expect(
          d.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(30)),
        );
      }
      debugDefaultTargetPlatformOverride = null;
    });
  }

  test('Apple\'s glass only on a real iOS 26: not in a test, not on another '
      'platform', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(appleGlass, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(appleGlass, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
