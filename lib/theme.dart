import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFECEAE4);
  static const paper = Color(0xFFF5F3EE);
  static const ink = Color(0xFF131316);
  static const dark = Color(0xFF0D0D0F);
  static const lime = Color(0xFFC6F24E);
  static const limeDark = Color(0xFFA8E02C);
  static const blue = Color(0xFF2B4BFF);
  static const red = Color(0xFFFF4E2D);
  static const limeInk = Color(0xFF17200A);
}

class AppText {
  /// Questions, titles, numbers — the voice of the app. A warm editorial
  /// serif rather than a geometric sans, which read as machine-set.
  ///
  /// Fraunces is a variable font: [soft] rounds the terminals and [wonk]
  /// turns on its quirkier letterforms. Both stay low here — enough warmth to
  /// lose the mechanical feel without turning into a novelty face.
  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w600,
    double? height,
    double? spacing,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Fraunces',
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: color,
    fontVariations: [
      FontVariation('wght', weight.value.toDouble()),
      // Optical size follows the type size, so large headings get the
      // tighter, more dramatic cut and small text stays readable.
      FontVariation('opsz', size.clamp(9, 144).toDouble()),
      const FontVariation('SOFT', 30),
      const FontVariation('WONK', 0),
    ],
  );

  /// Running text.
  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? spacing,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Figtree',
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: color,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
  );

  /// Small uppercase meta — topic names, section eyebrows, counters. Spaced
  /// out rather than set in a monospace, which looked like terminal output.
  static TextStyle label({
    required double size,
    FontWeight weight = FontWeight.w600,
    double? spacing,
    double? height,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Figtree',
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing ?? 1.2,
    height: height,
    color: color,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
  );
}

ThemeData buildKnowitTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lime,
      brightness: Brightness.light,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Figtree'),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body(
        size: 13.5,
        height: 1.35,
        color: Colors.white,
      ),
      actionTextColor: AppColors.lime,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        // The web build should slide like the phone build, not fade like
        // desktop Chrome would by default.
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
