// Throwaway: photographs the bank cards given a `draw` scene by the writer.
//   flutter test test/scenes/_draw_writer_shots_test.dart --update-goldens --dart-define=SHOTS=true
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const _ids = [
  'economics-1929-1',
  'economics-container-ships-7',
  'music-labels-2',
  'medicine-symptoms-6',
  'human_body-steps-1',
  'human_body-circulation-2',
  'science-why-ice-floats-1',
  'science-exponential-growth-3',
  'sport-why-records-fall-2',
  'technology-data-centres-2',
  'food-emulsions-2',
];

Map<String, Object?> _load(String id) {
  final dir = Directory('tool/cards/bank');
  final f = dir
      .listSync(recursive: true)
      .whereType<File>()
      .firstWhere((f) => f.path.endsWith('/$id.json'));
  return (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
}

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

Future<void> _sweep(
  WidgetTester tester,
  double Function(double u) shape, {
  double from = 0.2,
  double to = 0.99,
}) async {
  final box = tester.getRect(find.byKey(const ValueKey('draw-chart')));
  Offset at(double u) => Offset(
    box.left + box.width * u,
    box.bottom - 40 - (box.height - 90) * shape(u),
  );
  final g = await tester.startGesture(at(from));
  await tester.pump();
  const steps = 24;
  for (var k = 1; k <= steps; k++) {
    await g.moveTo(at(from + (to - from) * k / steps));
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
  for (final id in _ids) {
    for (final (phone, size) in [
      ('small', const Size(360, 740)),
      ('large', const Size(430, 932)),
    ]) {
      testWidgets('$id on $phone', (tester) async {
        final pill = cardFromJson(_load(id));
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_Card(pill));
        await _settle(tester);
        Future<void> shoot(String stage) => expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../../tool/shots/cards/$id-$phone-$stage.png'),
        );
        await shoot('start');
        final s = pill.scene! as DrawScene;
        final x0 = (s.anchor + 0.5) / (s.count - 0.4);
        await _sweep(tester, (u) => 0.5, from: x0);
        await tester.tap(find.text('LOCK IT IN'));
        await _settle(tester);
        await shoot('end');
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
