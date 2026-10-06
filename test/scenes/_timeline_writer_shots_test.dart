// Throwaway: photographs the bank's timeline cards. Delete after use.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final e in fonts.entries) {
    final file = File(e.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(e.key)
      ..addFont(
        Future.value(
          ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer),
        ),
      );
    await loader.load();
  }
}

List<Map<String, Object?>> _cards() {
  final out = <Map<String, Object?>>[];
  for (final f in Directory('tool/cards/bank').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.json')) continue;
    final c = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
    final s = c['scene'];
    if (s is Map && s['type'] == 'timeline' && c['written'] == '2026-10-06') {
      out.add(c);
    }
  }
  out.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  return out;
}

void main() {
  setUpAll(_loadFonts);
  for (final raw in _cards()) {
    final id = raw['id'] as String;
    testWidgets(id, (tester) async {
      tester.view.physicalSize = const Size(360, 740) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final card = cardFromJson(raw);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PillCardStack(
              deck: [card],
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
      );
      await tester.pump(const Duration(seconds: 3));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/tl-$id-start.png'),
      );
      final events = (raw['scene'] as Map)['events'] as List;
      final guesses = [0.55, 0.3, 0.7, 0.45, 0.6];
      for (var i = 0; i < events.length; i++) {
        final label = (events[i] as Map)['label'] as String;
        final lane = tester.getRect(find.bySemanticsLabel(label));
        final y = lane.top + lane.height * 0.7;
        final from = Offset(lane.left + 20, y);
        final to = Offset(lane.left + 14 + (lane.width - 28) * guesses[i], y);
        await tester.dragFrom(from, to - from);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../tool/shots/cards/tl-$id-end.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
