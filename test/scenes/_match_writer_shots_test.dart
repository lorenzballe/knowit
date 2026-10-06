import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

// Throwaway: photographs the bank cards given a match scene by the writer.
const _ids = [
  'psychology-anchoring-bias-2',
  'psychology-social-proof-2',
  'economics-free-is-not-free-2',
  'economics-percent-or-points-3',
  'economics-decoy-options-1',
  'science-mixing-cleaners-1',
  'science-insulation-2',
  'science-why-things-break-1',
  'language-words-that-changed-meaning-1',
  'language-jargon-3',
  'technology-telephones-2',
  'history-2',
  'space-spinoffs-2',
  'philosophy-good-arguments-2',
  'sport-rule-changes-1',
  'cinema-editing-tricks-1',
  'pop_culture-why-brands-sell-feelings-2',
  'food-labels-2',
  'art-synthetics-2',
  'nature-unintended-fixes-1',
  'human_body-digestion-3',
  'human_body-miracle-cures-1',
  'life-second-order-effects-1',
  'medicine-bad-cures-1',
  'weird_facts-still-on-the-books-1',
];

Future<void> _loadFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  Map<String, Object?> load(String id) {
    final dir = id.substring(0, id.indexOf('-'));
    final f = File('tool/cards/bank/$dir/$id.json');
    return (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
  }

  Widget frame(Map<String, Object?> card) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 60, 14, 96),
          child: PillCard(pill: cardFromJson(card)),
        ),
      ),
    ),
  );

  for (final id in _ids) {
    testWidgets('shoot $id', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final card = load(id);
      Future<void> shoot(String stage) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/$id-small-$stage.png'),
      );
      await tester.pumpWidget(frame(card));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await shoot('start');

      final pairs = [
        for (final p in (card['scene'] as Map)['pairs'] as List)
          (p as Map).cast<String, Object?>(),
      ];
      final n = pairs.length;
      // Right on all but the first two, which are swapped.
      for (var i = 0; i < n; i++) {
        final j = i == 0 ? 1 : (i == 1 ? 0 : i);
        await tester.tap(find.text(pairs[i]['left'] as String));
        await tester.tap(find.text(pairs[j]['right'] as String));
        await tester.pumpAndSettle();
      }
      await shoot('full');
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await shoot('end');
      for (final rp in tester.renderObjectList<RenderParagraph>(
        find.byType(RichText),
      )) {
        expect(rp.didExceedMaxLines, isFalse, reason: '$id: ${rp.text.toPlainText()}');
      }
    });
  }
}
