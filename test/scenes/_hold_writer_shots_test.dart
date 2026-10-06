import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

// Throwaway: photographs the bank cards given hold scenes, on a 360x740 phone.
const _ids = [
  'art/art-seeing-for-yourself-2',
  'human_body/human_body-heartbeat-3',
  'human_body/human_body-heartbeat-5',
  'human_body/human_body-pain-1',
  'medicine/medicine-robots-2',
  'music/music-hooks-8',
  'music/music-rhythm-in-the-body-2',
  'nature/nature-animal-minds-1',
  'philosophy/philosophy-choice-2',
  'psychology/psychology-first-impressions-1',
  'psychology/psychology-focus-3',
  'space/space-star-death-3',
  'space/space-launch-windows-4',
  'sport/sport-sprint-1',
  'sport/sport-sprint-4',
  'technology/technology-refresh-rates-2',
];

void main() {
  setUpAll(() async {
    final fonts = {
      'Fraunces': 'assets/fonts/Fraunces.ttf',
      'Figtree': 'assets/fonts/Figtree.ttf',
      'MaterialIcons':
          '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
          '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    };
    for (final e in fonts.entries) {
      final bytes = File(e.value).readAsBytesSync();
      await (FontLoader(
        e.key,
      )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  final base = PillBank.cards.firstWhere((p) => p.challenge is NoChallenge);

  Widget deck(Pill pill) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Scaffold(
      body: PillCardStack(
        isSaved: (_) => false,
        onSave: (_) {},
        onShare: (_) {},
        isLiked: (_) => false,
        onLike: (_) {},
        deck: [pill, base],
        index: 0,
        onAdvance: () {},
        answerFor: (_) => null,
        reviewIds: const {},
        onAnswer: (_, _, _, _) {},
      ),
    ),
  );

  for (final path in _ids) {
    final name = path.split('/').last;
    for (final size in [const Size(360, 740), const Size(430, 932)]) {
      final tag = size.width == 360 ? 'small' : 'large';
      testWidgets('$name $tag', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final json =
            jsonDecode(File('tool/cards/bank/$path.json').readAsStringSync())
                as Map<String, Object?>;
        final pill = cardFromJson(json);
        await tester.pumpWidget(deck(pill));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final g = await tester.startGesture(
          tester.getCenter(find.text('Press and hold')),
        );
        await tester.pump();
        for (var f = 0; f < 12; f++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await g.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(PillCardStack),
          matchesGoldenFile('../../tool/shots/cards/hold_${name}_$tag.png'),
        );

        // The back of the card.
        await tester.tap(find.text(pill.question).first);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (tag == 'small') {
          await expectLater(
            find.byType(PillCardStack),
            matchesGoldenFile('../../tool/shots/cards/hold_${name}_back.png'),
          );
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}
