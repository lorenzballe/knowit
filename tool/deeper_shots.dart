// Photographs Go deeper (lib/widgets/deeper_sheet.dart): the sheet a tap on a
// card's source opens, on Astute+ with the answers on and one asked for.
//
//   flutter test tool/deeper_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder) and LANG_SHOT (a language, Italian by default) move it.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/card_ask.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/deeper_sheet.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('go deeper', (tester) async {
    const Size phone = Size(402, 1500);
    tester.view.physicalSize = phone * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    debugToolsOn = true;
    CardAsk.call = (card, mode, {text = '', required language}) async =>
        const AskAnswer(
          'Il punto forte: ti fidi del nome, che di solito aiuta. Il passo '
          'debole: «bronzi» è il nome dato dai collezionisti europei, non '
          'un\'analisi del metallo. Una domanda che lo mette alla prova: '
          'cosa direbbe un\'analisi chimica dei pezzi?',
        );
    final Pill pill = PillBank.cards.firstWhere(
      (p) =>
          p.reference.isNotEmpty &&
          p.principle == Principle.baseRate &&
          p.question.toLowerCase().contains('test'),
      orElse: () => PillBank.cards.firstWhere((p) => p.reference.isNotEmpty),
    );
    for (final Brightness b in [Brightness.dark, Brightness.light]) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.plus': true,
      });
      final app = AppState();
      await app.init();
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(Platform.environment['LANG_SHOT'] ?? 'it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(b),
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: context.p.surface,
              body: SizedBox.expand(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: phone.height * 0.95,
                    child: DeeperSheet(key: ValueKey(b), app: app, pill: pill),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('deeper-take')),
          matching: find.byType(TextField),
        ),
        'Secondo me erano di bronzo, lo dice il nome.',
      );
      await tester.pump();
      await tester.tap(find.text('Analizza'));
      for (int f = 0; f < 6; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final String tag = b == Brightness.dark ? '' : '-light';
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('$out/deeper$tag.png'),
      );
    }
  });
}
