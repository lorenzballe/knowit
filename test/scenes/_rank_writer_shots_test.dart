// Throwaway: photographs the bank cards given a `rank` scene.
//   flutter test test/scenes/_rank_writer_shots_test.dart --update-goldens --dart-define=SHOTS=true
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

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

const _ids = [
  'psychology-rewards-2',
  'psychology-reciprocity-2',
  'science-1',
  'sport-hosting-2',
  'history-1',
  'human_body-smell-3',
  'science-risk-in-numbers-1',
  'weird_facts-fastest-5',
  'weird_facts-oldest-2',
  'nature-3',
  'food-meat-1',
];

Map<String, Object?> _load(String id) {
  final topic = Directory('tool/cards/bank')
      .listSync()
      .whereType<Directory>()
      .firstWhere((d) => File('${d.path}/$id.json').existsSync());
  return (jsonDecode(File('${topic.path}/$id.json').readAsStringSync()) as Map)
      .cast<String, Object?>();
}

void main() {
  setUpAll(_loadFonts);
  for (final id in _ids) {
    testWidgets('shoot $id', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final pill = cardFromJson(_load(id));
      await tester.pumpWidget(_card(pill));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/rankw-$id-small-start.png'));
      await tester.tap(find.text('LOCK IT IN'));
      for (var f = 0; f < 50; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/rankw-$id-small-end.png'));
      await tester.pumpWidget(_card(pill, flipped: true));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/rankw-$id-small-back.png'));
    });
  }
}
