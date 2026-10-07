// Throwaway: photographs the round-2 sort cards in the deck. Delete after use.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scenes/sort_view.dart';

const _ids = [
  'technology-scams-2',
  'human_body-supplements-4',
  'weird_facts-hoaxes-1',
  'economics-too-good-to-be-true-4',
  'human_body-small-daily-habits-4',
  'technology-checking-a-source-1',
  'language-spin-4',
  'food-food-safety-6',
  'science-correlation-or-cause-5',
  'science-sample-size-4',
  'medicine-side-effects-4',
  'technology-passwords-1',
  'life-regret-1',
  'life-gut-or-data-2',
];

Map<String, Object?> _load(String id) {
  final f = Directory('tool/cards/bank')
      .listSync(recursive: true)
      .whereType<File>()
      .firstWhere((f) => f.path.endsWith('/$id.json'));
  return (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
}

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    final bytes = await File(e.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  const phones = {'s': Size(360, 740), 'l': Size(430, 932)};
  for (final id in _ids) {
    for (final ph in phones.entries) {
      testWidgets('$id ${ph.key}', (tester) async {
        tester.view.physicalSize = ph.value * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final Pill pill = cardFromJson(_load(id));
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.fromLTRB(18, 60, 18, 96),
                child: PillCardStack(
                  deck: [pill],
                  index: 0,
                  onAdvance: () {},
                  answering: false,
                  reviewIds: const {},
                  answerFor: (_) => null,
                  onAnswer: (_, _, _, _) {},
                  isSaved: (_) => false,
                  onSave: (_) {},
                  onShare: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final shot = find.byType(PillCardStack);
        final dir = '../../tool/shots/cards/sortw';
        await expectLater(
          shot,
          matchesGoldenFile('$dir/$id-${ph.key}-0start.png'),
        );
        final scene = pill.scene! as SortScene;
        for (var i = 0; i < scene.items.length; i++) {
          final item = scene.items[i];
          // First slip thrown the wrong way, so the end shows a carried call.
          final right = (item.pile == SortSide.right) != (i == 0);
          await tester.drag(
            find.text(item.text).last,
            Offset(right ? 170 : -170, 0),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 700));
          if (ph.key == 's') {
            await expectLater(
              shot,
              matchesGoldenFile('$dir/$id-${ph.key}-back$i.png'),
            );
          }
          await tester.pumpAndSettle();
        }
        await expectLater(
          shot,
          matchesGoldenFile('$dir/$id-${ph.key}-9end.png'),
        );
      });
    }
  }
}
