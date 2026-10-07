// Photographs the top of Your journey — how sure against how right — on a
// reader with a few weeks of answers behind them.
//
//   flutter test tool/journey_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder), LANG_SHOT (a language) and TALL (a phone height) move
// it for a one-off picture.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

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

/// A reader five weeks in who has got less sure of what they did not know:
/// level by level, how many answers and how many right, before the last
/// week and in it.
Map<String, Object> measured() {
  final DateTime now = DateTime.now();
  String ago(int days) => dateKey(now.subtract(Duration(days: days)));
  final graded = PillBank.cards.where((p) => p.isGraded).toList();
  const plan = {
    50: [(5, 3), (3, 2)],
    60: [(7, 4), (4, 2)],
    70: [(9, 5), (5, 4)],
    80: [(10, 6), (5, 4)],
    90: [(9, 5), (5, 5)],
  };
  final judgements = <Map<String, Object>>[];
  var n = 0;
  for (final MapEntry<int, List<(int, int)>> level in plan.entries) {
    for (final (int part, (int count, int right)) in level.value.indexed) {
      for (var i = 0; i < count; i++) {
        judgements.add({
          'c': level.key,
          'k': i < right,
          'p': graded[n++ % graded.length].id,
          'd': ago(part == 0 ? 34 - i * 3 : 6 - i),
        });
      }
    }
  }
  judgements.sort((a, b) => (a['d'] as String).compareTo(b['d'] as String));
  return {
    'knowit.onboarded': true,
    'knowit.plus': true,
    'knowit.streak': 6,
    'knowit.lastCompletionDate': ago(1),
    'knowit.completedDates': [
      for (var d = 34; d >= 1; d--)
        if (d % 6 != 2) ago(d),
    ],
    'knowit.seenIds': PillBank.cards.take(172).map((p) => p.id).toList(),
    'knowit.judgements': jsonEncode(judgements),
  };
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the top of the journey', (tester) async {
    final Size phone = Size(
      402,
      double.tryParse(Platform.environment['TALL'] ?? '') ?? 874,
    );
    const EdgeInsets notch = EdgeInsets.only(top: 59, bottom: 34);
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    for (final Brightness b in [Brightness.dark, Brightness.light]) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(measured());
      final app = AppState();
      await app.init();
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(Platform.environment['LANG_SHOT'] ?? 'en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(b),
          debugShowCheckedModeBanner: false,
          home: MediaQuery(
            data: MediaQueryData(size: phone, padding: notch),
            child: JourneyScreen(key: ValueKey(b), app: app, onBack: () {}),
          ),
        ),
      );
      for (int f = 0; f < 12; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final String tag = b == Brightness.dark ? '' : '-light';
      await expectLater(
        find.byType(JourneyScreen),
        matchesGoldenFile('$out/journey-top$tag.png'),
      );
      if (b == Brightness.dark) {
        // A level picked under the curve: the ring moves, and so does the
        // sentence.
        await tester.tap(find.byKey(const ValueKey('journey-level-70')));
        for (int f = 0; f < 6; f++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(
          find.byType(JourneyScreen),
          matchesGoldenFile('$out/journey-top-70.png'),
        );
      }
    }
  });
}
