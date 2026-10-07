// Throwaway: photographs the music cards written into the bank.
//   flutter test test/scenes/_music_writer_shots_test.dart --update-goldens --dart-define=SHOTS=true
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/scenes/music_view.dart';

class _Ears implements MusicSceneSpeaker {
  @override
  Future<void> play(Uint8List wav,
          {bool loop = false, Duration from = Duration.zero}) async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
        '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final e in fonts.entries) {
    final bytes = File(e.value).readAsBytesSync();
    await (FontLoader(e.key)..addFont(Future.value(ByteData.view(bytes.buffer))))
        .load();
  }
}

Pill _load(String id) => cardFromJson(
      jsonDecode(File('tool/cards/bank/music/$id.json').readAsStringSync())
          as Map<String, Object?>,
    );

// How each card is driven to its end: 'k:' a key (semantics label),
// 't:' a text to tap.
const _drive = {
  'music-music-and-mood-4': ['k:E4', 'k:Eb4'],
  'music-hooks-11': ['k:F#4', 'k:G4'],
  'music-guitar-2': ['k:E3', 'k:G#2'],
  'music-hearing-4': ['t:55', 't:110', 't:165'],
  'music-frequencies-12': ['k:Bb1', 'k:E2'],
  'music-hearing-5': ['k:C4', 'k:G3'],
  'music-chord-loops-1': ['t:Zombie'],
  'music-rhythm-11': ['t:On 2 & 4'],
  'music-rhythm-1': ['t:Tresillo', 't:Clave'],
  'music-frequencies-2': ['t:147', 't:735', 't:1029'],
  'music-voice-4': ['t:880'],
  'music-chills-1': ['t:Kick', 't:Bass', 't:Build'],
};

const _phones = {
  'small': (Size(360, 740), Size(324, 520)),
  'medium': (Size(390, 844), Size(354, 624)),
  'large': (Size(430, 932), Size(394, 712)),
};

void main() {
  setUpAll(_loadFonts);
  setUp(() => MusicSceneAudio.speaker = () => _Ears());

  for (final id in _drive.keys) {
    for (final p in _phones.entries) {
      testWidgets('$id ${p.key}', (t) async {
        final semantics = t.ensureSemantics();
        t.view.physicalSize = p.value.$1 * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final pill = _load(id);
        Widget card(bool flipped) => MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAstutoTheme(Brightness.dark),
              home: Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: SizedBox.fromSize(
                    size: p.value.$2,
                    child: PillCard(
                      key: ValueKey('$flipped'),
                      pill: pill,
                      flipped: flipped,
                      onSave: () {},
                      onShare: () {},
                    ),
                  ),
                ),
              ),
            );
        Future<void> shoot(String stage) => expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                  '../../tool/shots/cards/$id-${p.key}-$stage.png'),
            );
        await t.pumpWidget(card(false));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await shoot('start');
        for (final a in _drive[id]!) {
          final f = a.startsWith('k:')
              ? find.bySemanticsLabel(a.substring(2))
              : find.text(a.substring(2));
          expect(f, findsWidgets, reason: '$id: $a');
          await t.tapAt(t.getCenter(f.first));
          for (var i = 0; i < 4; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
        }
        await t.pump(const Duration(milliseconds: 700));
        await shoot('end');
        await t.pumpWidget(card(true));
        for (var i = 0; i < 14; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await shoot('back');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
        semantics.dispose();
      });
    }
  }
}
