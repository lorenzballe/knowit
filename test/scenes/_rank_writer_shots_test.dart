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

const _ids = String.fromEnvironment('IDS');

Future<void> _loadFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

Widget _card(Pill pill, bool flipped) => MaterialApp(
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
  for (final id in _ids.split(',')) {
    final f = Directory('tool/cards/bank').listSync(recursive: true)
        .whereType<File>().firstWhere((f) => f.path.endsWith('/$id.json'));
    final c = (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
    testWidgets('shoot $id', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final pill = cardFromJson(c);
      await tester.pumpWidget(_card(pill, false));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/rank-$id-small-start.png'));
      await tester.tap(find.text('LOCK IT IN'));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/rank-$id-small-end.png'));
      await tester.pumpWidget(_card(pill, true));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/rank-$id-small-back.png'));
    });
  }
}
