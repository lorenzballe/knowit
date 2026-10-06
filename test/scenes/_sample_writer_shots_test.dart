// Throwaway: photographs the bank's sample cards. Delete after use.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/scene_view.dart';

const _ids = [
  'science/science-probability-1',
  'science/science-pseudoscience-1',
  'science/science-sample-size-3',
  'sport/sport-set-pieces-2',
  'sport/sport-streaks-3',
  'sport/sport-coin-tosses-2',
  'medicine/medicine-placebo-or-real-2',
  'medicine/medicine-side-effects-3',
  'medicine/medicine-bad-cures-3',
  'nature/nature-forecast-odds-1',
  'space/space-moon-and-sleep-3',
  'human_body/human_body-microbiome-4',
  'thinking/thinking-z20',
  'thinking/thinking-m2',
];

Future<void> _show(WidgetTester tester, Pill pill, bool flipped) async {
  tester.view.physicalSize = const Size(360, 740) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
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
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var f = 0; f < 20; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    for (final family in ['Fraunces', 'Figtree']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });

  for (final path in _ids) {
    final raw = jsonDecode(
      File('tool/cards/bank/$path.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final id = raw['id'] as String;
    testWidgets(id, (tester) async {
      final pill = cardFromJson(raw);
      final s = pill.scene! as SampleScene;
      final asks = raw['kind'] != 'read';
      await _show(tester, pill, asks);
      await _settle(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/w-sample-$id-0.png'),
      );
      for (var i = 1; i < s.steps.length; i++) {
        await tester.tap(find.text(s.button).first);
        await _settle(tester);
        expect(find.text(s.notes[i]), findsOneWidget);
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/w-sample-$id-end.png'),
      );
      if (!asks) {
        await _show(tester, pill, true);
        await _settle(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/w-sample-$id-back.png'),
        );
      }
    });
  }
}
