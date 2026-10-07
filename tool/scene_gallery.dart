// Photographs every card that has a scene, front and back, on a medium phone,
// for a page the owner can scroll through.
//
//   flutter test tool/scene_gallery.dart --update-goldens
//
// Pictures land in tool/shots/gallery/<scene type>/<id>-{front,back}.png.
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

const _phone = Size(390, 844);

/// Only cards of this scene type, when given.
const _only = String.fromEnvironment('TYPE');

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

List<(String, Pill)> _sceneCards() {
  final out = <(String, Pill)>[];
  for (final dir in Directory(
    'tool/cards/bank',
  ).listSync().whereType<Directory>()) {
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final card = (jsonDecode(f.readAsStringSync()) as Map)
          .cast<String, Object?>();
      final scene = card['scene'];
      if (card['disabled'] == true || scene is! Map) continue;
      if (_only.isNotEmpty && scene['type'] != _only) continue;
      out.add((scene['type'] as String, cardFromJson(card)));
    }
  }
  out.sort((a, b) => '${a.$1}/${a.$2.id}'.compareTo('${b.$1}/${b.$2.id}'));
  return out;
}

class _Frame extends StatefulWidget {
  final Pill pill;
  const _Frame(this.pill);
  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  Answer? _given;
  bool _flipped = false;

  void flip() => setState(() => _flipped = true);

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 50, 14, 70),
        child: PillCard(
          pill: widget.pill,
          flipped: _flipped,
          given: _given,
          onAnswer: (r, c, w) => setState(() {
            _given = Answer(r, confidence: c, reason: w);
            _flipped = true;
          }),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_loadFonts);

  for (final (type, pill) in _sceneCards()) {
    testWidgets('$type ${pill.id}', (tester) async {
      tester.view.physicalSize = _phone * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      Future<void> settle() async {
        for (var f = 0; f < 30; f++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> shoot(String side) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('shots/gallery/$type/${pill.id}-$side.png'),
      );

      await tester.pumpWidget(_Frame(pill));
      await settle();
      await shoot('front');

      // Turn it over: an asking card is answered with its first option at
      // 70%; a card to read is simply turned.
      final options = switch (pill.challenge) {
        PickOne(:final options) => options,
        TakeASide(:final positions) => positions,
        _ => const <String>[],
      };
      if (options.isNotEmpty) {
        await tester.tap(find.text(options.first).first, warnIfMissed: false);
        await settle();
        final sure = find.text('70%');
        if (sure.evaluate().isNotEmpty) {
          await tester.tap(sure.first, warnIfMissed: false);
          await settle();
        }
      } else {
        tester.state<_FrameState>(find.byType(_Frame)).flip();
        await settle();
      }
      await shoot('back');
    });
  }
}
