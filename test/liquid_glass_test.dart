// Liquid Glass (lib/widgets/liquid_glass.dart): glass on Apple's own
// platforms, the solid ground a control had before everywhere else, and
// solid ground on Apple too when high contrast is asked for.
//
//   flutter test test/liquid_glass_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/theme.dart';
import 'package:astuto/widgets/liquid_glass.dart';

Widget _host(Widget child, {bool highContrast = false}) => MaterialApp(
  theme: buildAstutoTheme(Brightness.dark),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(highContrast: highContrast),
      child: Scaffold(
        body: Center(child: SizedBox(width: 300, height: 120, child: child)),
      ),
    ),
  ),
);

const _solid = BoxDecoration(color: Color(0xFF123456));

void main() {
  testWidgets('glass on iOS: the backdrop blurred, under a tint and a rim', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(glassOn, isTrue);
    await tester.pumpWidget(
      _host(const LiquidGlass(solid: _solid, child: Text('in glass'))),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('in glass'), findsOneWidget);
    await tester.pumpWidget(_host(const GlassSheet(child: Text('a sheet'))));
    expect(find.byType(BackdropFilter), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('high contrast on iOS: solid ground, nothing showing through', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      _host(const LiquidGlass(child: Text('in glass')), highContrast: true),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(
      _host(const GlassSheet(child: Text('a sheet')), highContrast: true),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android: the ground the control had before glass', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(glassOn, isFalse);
    await tester.pumpWidget(
      _host(const LiquidGlass(solid: _solid, child: Text('solid'))),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final DecoratedBox box = tester.widget(
      find
          .ancestor(of: find.text('solid'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(box.decoration, _solid);
    await tester.pumpWidget(_host(const GlassSheet(child: Text('a sheet'))));
    expect(find.byType(BackdropFilter), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
