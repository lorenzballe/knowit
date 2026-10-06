// Throwaway: photographs the bank's poll cards. Delete after use.
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
import 'package:astuto/widgets/scene_view.dart';
import 'package:astuto/models/scene.dart';

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

Future<void> _play(WidgetTester tester) async {
  for (var f = 0; f < 22; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(_loadFonts);
  for (final id in _ids.split(',')) {
    testWidgets('photograph $id', (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final path = Directory('tool/cards/bank').listSync(recursive: true)
          .whereType<File>().firstWhere((f) => f.path.endsWith('/$id.json'));
      final json = (jsonDecode(path.readAsStringSync()) as Map).cast<String, Object?>();
      final pill = cardFromJson(json);
      final s = pill.scene! as PollScene;
      Future<void> shoot(String stage) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/poll-bank-$id-$stage.png'),
      );
      await tester.pumpWidget(_card(pill));
      await _play(tester);
      await shoot('a-before');
      await tester.tap(find.text(s.questions[0].options[0].label).first);
      await _play(tester);
      if (s.twice) {
        await _play(tester);
        await shoot('b-second');
        await tester.tap(find.text(s.questions[1].options[1].label).last);
        await _play(tester);
      }
      await _play(tester);
      await shoot('c-end');
      await tester.pumpWidget(_card(pill, flipped: true));
      await _play(tester);
      await shoot('d-back');
      expect(tester.takeException(), isNull);
    });
  }
}
