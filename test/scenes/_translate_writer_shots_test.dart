// Throwaway: photographs the bank's translate cards. Delete after use.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/widgets/scenes/translate_view.dart';

const _shots = bool.fromEnvironment('SHOTS');

List<Map<String, Object?>> _cards() {
  final out = <Map<String, Object?>>[];
  for (final f in Directory('tool/cards/bank').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.json')) continue;
    final c = (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
    final s = c['scene'];
    if (s is Map && s['type'] == 'translate') out.add(c);
  }
  out.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  return out;
}

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    final bytes = await File(e.value).readAsBytes();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

Widget _host(TranslateScene scene, Size phone, double height) => MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: phone.width - 36,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9D9),
              borderRadius: BorderRadius.circular(28),
            ),
            child: SizedBox(
              height: height,
              child: TranslateSceneView(
                scene: scene,
                ink: const Color(0xFF10100C),
                ground: const Color(0xFF00D9D9),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(_loadFonts);
  const phone = Size(360, 740);
  for (final c in _cards()) {
    for (final band in [('front', 330.0), ('back', 270.0)]) {
      testWidgets('${c['id']} ${band.$1}', (tester) async {
        tester.view.physicalSize = phone * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scene = Scene.fromJson(c['scene'], id: c['id'] as String) as TranslateScene;
        await tester.pumpWidget(_host(scene, phone, band.$2));
        await tester.pumpAndSettle();
        String shot(String step) =>
            '../../tool/shots/cards/translate-${c['id']}-${band.$1}-$step.png';
        if (_shots && band.$1 == 'front') {
          await expectLater(find.byType(TranslateSceneView), matchesGoldenFile(shot('0-start')));
        }
        // Guess the catch first, then translate the rest in order.
        final order = [
          if (scene.catchIndex >= 0) scene.catchIndex,
          for (var i = 0; i < scene.phrases.length; i++)
            if (i != scene.catchIndex) i,
        ];
        for (final i in order) {
          await tester.tapAt(tester.getCenter(find.byKey(ValueKey('translate-phrase-$i')).last));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1100));
          if (_shots && i == order.first) {
            await expectLater(find.byType(TranslateSceneView), matchesGoldenFile(shot('1-first')));
          }
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(scene.watch), findsOneWidget);
        if (_shots) {
          await expectLater(find.byType(TranslateSceneView), matchesGoldenFile(shot('2-end')));
        }
      });
    }
  }
}
