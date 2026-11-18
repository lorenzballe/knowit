import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart'
    show NativeLiquidGlassUtils;

import '../theme.dart';

/// Whether the tab bar is Apple's own Liquid Glass: on iOS 26 and later,
/// where the system draws it (native_liquid_glass hosts the real UIKit tab
/// bar in the app). The screens that scroll then run on under the bar, as
/// under any bar on iOS 26; everywhere else the bar is ours, solid, and the
/// screens stop above it.
///
/// Nothing in the app imitates the glass. Apple keeps it to the layer of
/// controls that floats over the content, the tab bar first, and there it
/// is the real thing: its transparency, its colours, its light and its
/// motion are the system's, and move with iOS.
bool get appleGlass => NativeLiquidGlassUtils.supportsLiquidGlass;

/// The ground of a sheet that rises from the foot of the screen: the page's
/// own surface, with the sheets' corners, 30 at the top.
class SheetGround extends StatelessWidget {
  const SheetGround({super.key, required this.child, this.radius = 30});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.p.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    ),
    child: child,
  );
}
