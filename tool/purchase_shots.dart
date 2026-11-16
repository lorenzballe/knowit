// Photographs the screen a purchase ends on while the store's answer is
// awaited, and the take once it is yes: to be looked at when the wait
// changes. A camera, not a check, like the other shots.
//
//   flutter test tool/purchase_shots.dart --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/theme.dart';

import '../test/explore/core_harness.dart';

const String _out = 'shots/purchase';

void main() {
  setUpAll(loadFonts);

  testWidgets('the wait, the long wait, and the take on yes', (tester) async {
    addTearDown(tester.view.reset);
    final view = tester.view;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    view.padding = FakeViewPadding(top: 62.0 * 3, bottom: 34.0 * 3);
    view.viewPadding = view.padding;

    for (final locale in const [Locale('it'), Locale('en')]) {
      final ValueNotifier<bool?> confirmed = ValueNotifier<bool?>(null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          locale: locale,
          debugShowCheckedModeBanner: false,
          home: PurchaseSuccessScreen(
            title: 'Free trial started.',
            welcome: 'Today’s five are yours, Lorenzo.',
            planName: 'Astute+ Yearly',
            planLine: 'Free until Nov 23, then €29.99/yr',
            foot: 'First charge on Nov 23. Cancel any time in Settings.',
            confirmed: confirmed,
          ),
        ),
      );
      Future<void> at(double seconds) async {
        final int steps = (seconds / .05).round();
        for (int i = 0; i < steps; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<void> shot(String name) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$_out/${locale.languageCode}-$name.png'),
      );

      await at(.6);
      await shot('1-waiting');
      if (locale.languageCode == 'it') {
        await at(21);
        await shot('2-waiting-long');
      }
      confirmed.value = true;
      await at(.15);
      await shot('3-yes-0.15s');
      await at(.45);
      await shot('4-yes-0.6s');
      await at(.4);
      await shot('5-yes-1.0s');
      await at(2.6);
      await shot('6-yes-3.6s');
    }
  });
}
