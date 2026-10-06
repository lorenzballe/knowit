// Throwaway: photographs the bank cards given a `clues` scene, on a 360×740
// phone, front (start, mid-play, verdict) and back. Delete after use.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

const _ids = [
  'medicine-doctors-who-were-right-3',
  'medicine-germ-theory-9',
  'philosophy-science-4',
  'science-peer-review-2',
  'science-experiments-3',
  'art-detection-5',
  'economics-averages-that-mislead-1',
  'human_body-blood-types-7',
  'human_body-smell-2',
  'history-plague-1',
  'nature-dinosaurs-1',
  'nature-migration-4',
  'space-cosmic-background-6',
  'space-extraordinary-claims-1',
  'food-coffee-and-health-claims-1',
  'weird_facts-oldest-10',
  'cinema-historical-errors-1',
];

Future<void> _loadFonts() async {
  for (final e in {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  }.entries) {
    final bytes = await File(e.value).readAsBytes();
    await (FontLoader(e.key)..addFont(
          Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
        ))
        .load();
  }
}

Widget _card(Pill pill, {bool flipped = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 60, 14, 96),
        child: PillCard(pill: pill, flipped: flipped),
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadFonts);
  final cards = {
    for (final id in _ids)
      id: jsonDecode(
        File(
          Directory('tool/cards/bank')
              .listSync()
              .whereType<Directory>()
              .map((d) => '${d.path}/$id.json')
              .firstWhere((p) => File(p).existsSync()),
        ).readAsStringSync(),
      ) as Map<String, Object?>,
  };
  for (final id in _ids) {
    testWidgets(id, (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pill = cardFromJson(cards[id]!);
      final s = pill.scene! as CluesScene;
      Future<void> shoot(String stage) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/clues-$id-$stage.png'),
      );
      await tester.pumpWidget(_card(pill));
      await tester.pumpAndSettle();
      await shoot('0-start');
      for (var k = 2; k <= s.clues.length; k++) {
        await tester.tap(find.text('$k OF ${s.clues.length}'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(s.options[(s.answer + 1) % s.options.length]));
      await tester.pumpAndSettle();
      await shoot('1-all-clues');
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      await shoot('2-verdict');
      await tester.pumpWidget(_card(pill, flipped: true));
      await tester.pumpAndSettle();
      await shoot('3-back');
    });
  }
}
