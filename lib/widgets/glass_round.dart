/// The round buttons of the layer of controls that floats over a screen:
/// back and close.
///
/// Apple keeps Liquid Glass to that layer, the tab bar and the buttons that
/// leave or close a screen, never the content under it. On iOS 26 and later
/// these are Apple's own: a UIButton in the system's glass, its press, its
/// light and its symbol drawn by iOS. Everywhere else, and in the photographs
/// of the app, each is the button the app drew before, as its screen gives
/// it.
library;

import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart'
    show LiquidGlassButton, LiquidGlassButtonStyle, NativeLiquidGlassIcon;

import '../theme.dart';
import 'hand_glass.dart' show appleGlass;

/// A round control in Apple's glass on iOS 26, [fallback] elsewhere.
class GlassRound extends StatelessWidget {
  const GlassRound({
    super.key,
    required this.symbol,
    required this.label,
    required this.onPressed,
    required this.fallback,
    this.size = 44,
    this.iconSize = 17,
  });

  /// Going back: the chevron Apple's own back button carries.
  static const String back = 'chevron.left';

  /// Closing: the cross of Apple's close buttons.
  static const String close = 'xmark';

  /// The SF Symbol iOS draws on it.
  final String symbol;

  /// What it does, as VoiceOver says it.
  final String label;

  final VoidCallback onPressed;

  /// The button as the app draws it where the system's glass is not there.
  final Widget fallback;

  /// Its side: 44, the least a finger can be asked to find.
  final double size;

  /// The symbol's size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (!appleGlass) return fallback;
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: size,
        child: LiquidGlassButton.icon(
          onPressed: onPressed,
          icon: NativeLiquidGlassIcon.sfSymbol(symbol),
          size: size,
          iconSize: iconSize,
          iconColor: context.p.ink,
          style: LiquidGlassButtonStyle.glass,
        ),
      ),
    );
  }
}
