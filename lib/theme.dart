import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static TextStyle outfit({
    required double size,
    FontWeight weight = FontWeight.w600,
    double? height,
    double? spacing,
    Color? color,
  }) => GoogleFonts.outfit(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: spacing,
    color: color,
  );

  static TextStyle figtree({
    required double size,
    FontWeight weight = FontWeight.w400,
    double? height,
    Color? color,
  }) => GoogleFonts.figtree(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w500,
    double? spacing,
    double? height,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
    color: color,
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
    textTheme: GoogleFonts.figtreeTextTheme(base.textTheme),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
