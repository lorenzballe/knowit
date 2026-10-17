// A card opened on its own page — from Saved, the archive, the week or the
// journey — reads in either theme: its colour, faint, under the page's own
// words, never the dark tint under the light theme's dark text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

void main() {
  for (final Brightness b in Brightness.values) {
    testWidgets('a card\'s own page on ${b.name}: the page and its words '
        'apart', (tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final AppState app = AppState();
      await app.init();
      final Pill pill = PillBank.cards.first;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(b),
          home: PillDetailScreen(pill: pill, app: app),
        ),
      );
      await tester.pumpAndSettle();

      final Scaffold page = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(PillDetailScreen),
          matching: find.byType(Scaffold),
        ),
      );
      final double ground = page.backgroundColor!.computeLuminance();
      final Palette p = tester.element(find.byType(Scaffold).first).p;
      final double ink = p.ink.computeLuminance();
      // WCAG's ratio between the page and the words on it.
      final double ratio =
          (ground > ink ? ground + 0.05 : ink + 0.05) /
          (ground > ink ? ink + 0.05 : ground + 0.05);
      expect(ratio, greaterThan(7), reason: 'ground $ground, ink $ink');
    });
  }
}
