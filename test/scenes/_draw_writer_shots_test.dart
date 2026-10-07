// Throwaway: photographs the draw writer's bank cards. Delete after use.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/scenes/draw_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const _ids = [
  'science/science-why-ice-floats-1', 'science/science-energy-5',
  'human_body/human_body-wellness-trends-4', 'psychology/psychology-insomnia-11',
  'psychology/psychology-framing-5', 'psychology/psychology-forgetting-curve-1',
  'nature/nature-overfishing-4', 'economics/economics-interest-13',
  'sport/sport-marathon-11', 'food/food-espresso-11', 'history/history-industrial-11',
  'art/art-perspective-11', 'life/life-saying-no-4', 'music/music-frequencies-11',
  'philosophy/philosophy-certainty-11', 'technology/technology-chips-11',
];

Future<void> _fonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final e in fonts.entries) {
    final bytes = await File(e.value).readAsBytes();
    final loader = FontLoader(e.key)
      ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  }
}

Future<void> _sweep(WidgetTester tester, double Function(double u) shape,
    {double from = 0.2, double to = 0.99}) async {
  final box = tester.getRect(find.byKey(const ValueKey('draw-chart')));
  Offset at(double u) => Offset(
      box.left + box.width * u, box.bottom - 40 - (box.height - 90) * shape(u));
  final g = await tester.startGesture(at(from));
  await tester.pump();
  for (var k = 1; k <= 24; k++) {
    await g.moveTo(at(from + (to - from) * k / 24));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var f = 0; f < 30; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(_fonts);
  for (final path in _ids) {
    final raw = (jsonDecode(File('tool/cards/bank/$path.json').readAsStringSync()) as Map)
        .cast<String, Object?>();
    final pill = cardFromJson(raw);
    for (final (phone, size) in [('small', const Size(360, 740)), ('large', const Size(430, 932))]) {
      testWidgets('${pill.id} $phone', (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_Card(pill));
        await _settle(tester);
        final s = pill.scene! as DrawScene;
        if (phone == 'small') {
          await expectLater(find.byType(MaterialApp),
              matchesGoldenFile('../../tool/shots/cards/${pill.id}-$phone-start.png'));
        }
        final x0 = (s.anchor + 0.5) / (s.count - 0.4);
        final falls = s.values.first > s.values.last;
        await _sweep(tester, falls ? (u) => 0.9 - 0.45 * u : (u) => 0.05 + 0.5 * u * u, from: x0);
        await tester.tap(find.text('LOCK IT IN'));
        await _settle(tester);
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('../../tool/shots/cards/${pill.id}-$phone-end.png'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _Card extends StatelessWidget {
  final Pill pill;
  const _Card(this.pill);
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 60, 14, 96),
              child: PillCard(pill: pill, flipped: false),
            ),
          ),
        ),
      );
}
