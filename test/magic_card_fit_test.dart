import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/magic_card.dart';

/// The card after the fifth, on the finished day's shelf of a 375 by 667
/// phone, at the default text size: its button was cut off by 23 points,
/// because nothing in the card gave way. Now the line under the headline
/// goes first, then the week's note, and the button is always whole.
void main() {
  setUpAll(() async {
    for (final face in const {
      'Fraunces': 'assets/fonts/Fraunces.ttf',
      'Figtree': 'assets/fonts/Figtree.ttf',
    }.entries) {
      final loader = FontLoader(face.key);
      final bytes = await File(face.value).readAsBytes();
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
      await loader.load();
    }
  });

  for (final Locale locale in const [Locale('en'), Locale('it'), Locale('de')]) {
    for (final Size box in const [Size(268, 330), Size(300, 380), Size(339, 475)]) {
      testWidgets('the offer fits a ${box.width.round()} by '
          '${box.height.round()} card in ${locale.languageCode}', (
        tester,
      ) async {
        final AppLocalizations l = lookupAppLocalizations(locale);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.dark),
            home: MediaQuery(
              // The rim stands still, so the test can settle.
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Center(
                  child: SizedBox.fromSize(
                    size: box,
                    child: MagicCard(
                      eyebrow: l.plusNameCaps,
                      note: ('week-reward', l.weekKeptThreeOwn),
                      headline: l.plusCardHeadline,
                      line: l.magicLine,
                      action: l.magicUnlock(14),
                      onAction: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final Rect card = tester.getRect(find.byType(MagicCard));
        final Rect button = tester.getRect(find.text(l.magicUnlock(14)));
        expect(button.bottom, lessThanOrEqualTo(card.bottom));
      });
    }
  }
}
