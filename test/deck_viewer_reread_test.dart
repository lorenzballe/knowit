import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

/// A card with a drawing, opened again from the archive, saved or liked,
/// starts again from its question, and its page cannot say how the reader
/// did the first time: the line under it does.
void main() {
  Future<void> open(WidgetTester tester, Pill pill, String? response) async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      if (response != null)
        'knowit.answersJson': jsonEncode({
          pill.id: {'r': response, 'c': 80},
        }),
    });
    final AppState app = AppState();
    await app.init();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: DeckViewerScreen(app: app, deck: [pill], title: 'Saved'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  final Pill drawn = PillBank.cards.firstWhere(
    (p) => p.hasPage && p.isGraded && p.challenge is PageJudged,
  );

  testWidgets('right the first time', (tester) async {
    await open(tester, drawn, PageJudged.encode('0', true));
    expect(find.text('You got it right the first time.'), findsOneWidget);
  });

  testWidgets('missed the first time', (tester) async {
    await open(tester, drawn, PageJudged.encode('1', false));
    expect(find.text('You missed it the first time.'), findsOneWidget);
  });

  testWidgets('never answered: the usual line', (tester) async {
    await open(tester, drawn, null);
    expect(find.text('That was the only one'), findsOneWidget);
  });
}
