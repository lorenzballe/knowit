import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/genre_names.dart';
import 'package:astuto/data/genres.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';

void main() {
  final List<String> languages = [
    for (final Locale l in AppLocalizations.supportedLocales)
      if (l.languageCode != 'en') l.languageCode,
  ];

  test('every theme has a name in every language the app speaks', () {
    expect(languages, isNotEmpty);
    for (final String language in languages) {
      final Map<String, String>? names = kThemeNames[language];
      expect(names, isNotNull, reason: language);
      for (final Genre g in kAllGenres) {
        final String? name = names![g.id];
        expect(name, isNotNull, reason: '$language ${g.id}');
        expect(name!.trim(), name, reason: '$language ${g.id}');
        expect(name, isNotEmpty, reason: '$language ${g.id}');
      }
      // Nothing named that is not a theme: a name left behind by a theme
      // renamed or dropped would never be shown, and would hide the gap.
      final Set<String> ids = {for (final Genre g in kAllGenres) g.id};
      expect(names!.keys.where((k) => !ids.contains(k)), isEmpty);
    }
  });

  test('a theme is named in the reader\'s language, English otherwise', () {
    final Genre physics = genreById('science.physics')!;
    expect(
      lookupAppLocalizations(const Locale('it')).themeOf(physics),
      'Fisica',
    );
    expect(
      lookupAppLocalizations(const Locale('de')).themeOf(physics),
      'Physik',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).themeOf(physics),
      'Physics',
    );
    expect(themeName(physics, 'xx'), 'Physics');
    expect(lookupAppLocalizations(const Locale('it')).themeById('no.such'), '');
  });

  test('the line under a move card names the theme in its language', () {
    final Pill card = PillBank.live.firstWhere(
      (p) => p.genre == 'science.physics',
    );
    expect(
      hidesInLine(lookupAppLocalizations(const Locale('en')), card),
      'In physics',
    );
    expect(
      hidesInLine(lookupAppLocalizations(const Locale('it')), card),
      'Tema: Fisica',
    );
    expect(
      hidesInLine(lookupAppLocalizations(const Locale('de')), card),
      'Thema: Physik',
    );
  });
}
