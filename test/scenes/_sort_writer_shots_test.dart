// Throwaway: photographs the bank cards given a sort scene. Delete after use.
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

const _ids = String.fromEnvironment('IDS');

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

Map<String, Object?> _card(String id) {
  final f = Directory('tool/cards/bank')
      .listSync(recursive: true)
      .whereType<File>()
      .firstWhere((f) => f.path.endsWith('/$id.json'));
  return (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
}

void main() {
  setUpAll(_loadFonts);
  for (final id in _ids.split(',')) {
    for (final phone in const [Size(360, 740), Size(430, 932)]) {
      final tag = phone.width.round();
      testWidgets('$id $tag', (tester) async {
        tester.view.physicalSize = phone * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final List<Pill> deck = [cardFromJson(_card(id))];
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Padding(
                padding: const EdgeInsets.fromLTRB(18, 60, 18, 96),
                child: PillCardStack(
                  deck: deck,
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
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/sortw-$id-$tag-0.png'),
        );
        final scene = deck.first.scene! as SortScene;
        // Longest verdict, photographed on its back.
        var longest = 0;
        for (var i = 0; i < scene.items.length; i++) {
          if (scene.items[i].verdict.length >
              scene.items[longest].verdict.length) {
            longest = i;
          }
        }
        for (var i = 0; i < scene.items.length; i++) {
          final item = scene.items[i];
          // Every other slip thrown the wrong way, so the end shows misses.
          final side = i.isEven
              ? item.pile
              : (item.pile == SortSide.left ? SortSide.right : SortSide.left);
          await tester.drag(
            find.text(item.text).last,
            Offset(side == SortSide.right ? 170 : -170, 0),
          );
          if (i == longest && tag == 360) {
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 900));
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('../../tool/shots/cards/sortw-$id-$tag-1.png'),
            );
          }
          await tester.pumpAndSettle();
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/sortw-$id-$tag-2.png'),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
