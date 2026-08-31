import 'package:flutter/material.dart';

/// The app mark, in the version that suits the current theme.
///
/// The mark carries its own ground — cream in light, near-black in dark — so
/// showing the wrong one puts a pale square on a dark screen. It follows the
/// theme rather than the platform brightness, so it matches the Appearance
/// choice made in the profile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/brand/mark-dark.png' : 'assets/brand/mark-light.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Astuto',
    );
  }
}
