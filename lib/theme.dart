import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Every colour the chrome uses, named for its job rather than its value.
///
/// The app used to paint Today dark and the other tabs on paper, which meant
/// it changed skin between tabs. One palette, chosen once in settings, is
/// what an app does — so nothing outside this file should name a raw colour
/// for chrome again.
@immutable
class Palette extends ThemeExtension<Palette> {
  /// The page itself.
  final Color surface;

  /// Cards and panels sitting on the page.
  final Color surfaceRaised;

  /// Text, in three weights of presence.
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;

  /// Hairlines, and the heavier borders around inputs.
  final Color line;
  final Color lineStrong;

  /// A filled control that reverses the page: dark on light, light on dark.
  final Color inverse;
  final Color onInverse;

  /// Links and destructive text.
  final Color link;
  final Color alert;

  const Palette({
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.line,
    required this.lineStrong,
    required this.inverse,
    required this.onInverse,
    required this.link,
    required this.alert,
  });

  static const light = Palette(
    surface: Color(0xFFF5F3EE),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF131316),
    inkMuted: Color(0xFF6B6B70),
    inkFaint: Color(0xFF9B9BA0),
    line: Color(0xFFE4E1DA),
    lineStrong: Color(0xFFD2CEC4),
    inverse: Color(0xFF131316),
    onInverse: Color(0xFFFFFFFF),
    link: Color(0xFF2B4BFF),
    alert: Color(0xFFD8341A),
  );

  static const dark = Palette(
    surface: Color(0xFF000000),
    surfaceRaised: Color(0xFF121215),
    ink: Color(0xFFF2F1EC),
    inkMuted: Color(0xFF9E9EA6),
    inkFaint: Color(0xFF6A6A72),
    line: Color(0xFF1E1E22),
    lineStrong: Color(0xFF303038),
    inverse: Color(0xFFF2F1EC),
    onInverse: Color(0xFF08080A),
    link: Color(0xFF7D93FF),
    alert: Color(0xFFFF7A5E),
  );

  bool get isDark => surface.computeLuminance() < 0.5;

  @override
  Palette copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? line,
    Color? lineStrong,
    Color? inverse,
    Color? onInverse,
    Color? link,
    Color? alert,
  }) => Palette(
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkFaint: inkFaint ?? this.inkFaint,
    line: line ?? this.line,
    lineStrong: lineStrong ?? this.lineStrong,
    inverse: inverse ?? this.inverse,
    onInverse: onInverse ?? this.onInverse,
    link: link ?? this.link,
    alert: alert ?? this.alert,
  );

  @override
  Palette lerp(covariant Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      inverse: Color.lerp(inverse, other.inverse, t)!,
      onInverse: Color.lerp(onInverse, other.onInverse, t)!,
      link: Color.lerp(link, other.link, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
    );
  }
}

extension PaletteOf on BuildContext {
  /// The palette in force. Every colour the chrome paints comes from here.
  Palette get p => Theme.of(this).extension<Palette>() ?? Palette.light;
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

ThemeData buildAstutoTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark ? Palette.dark : Palette.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.inverse,
      brightness: brightness,
    ),
  );
  return base.copyWith(
    extensions: [palette],
    textTheme: base.textTheme.apply(
      fontFamily: 'Figtree',
      bodyColor: palette.ink,
      displayColor: palette.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: palette.inverse,
      contentTextStyle: AppText.body(
        size: 13.5,
        height: 1.35,
        color: palette.onInverse,
      ),
      actionTextColor: palette.onInverse,
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
