// Photographs the top of Your journey — today, and two weeks in — on a
// reader with three months behind them.
//
//   flutter test tool/journey_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
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

/// Eighty-six days of a reader who got surer and more right: early on, sure
/// and often wrong; lately, sure about as often as right.
Map<String, Object> journeyed() {
  final DateTime now = DateTime.now();
  String ago(int days) => dateKey(now.subtract(Duration(days: days)));
  final graded = PillBank.cards.where((p) => p.isGraded).toList();
  final judgements = <Map<String, Object>>[];
  var n = 0;
  // Level by level: how many answers, and how many right, in the first two
  // weeks and in the months since.
  const plan = {
    50: [(20, 12), (60, 34)],
    60: [(20, 11), (60, 35)],
    70: [(20, 10), (60, 40)],
    80: [(20, 11), (60, 43)],
    90: [(20, 10), (60, 48)],
  };
  for (final MapEntry<int, List<(int, int)>> level in plan.entries) {
    for (final (int part, (int count, int right)) in level.value.indexed) {
      for (var i = 0; i < count; i++) {
        // Two weeks in is days 85 to 72; after that, days 71 to 1.
        final int day = part == 0 ? 85 - i % 14 : 71 - i % 71;
        judgements.add({
          'c': level.key,
          'k': i < right,
          'p': graded[n++ % graded.length].id,
          'd': ago(day),
        });
      }
    }
  }
  judgements.sort(
    (a, b) => (b['d'] as String).compareTo(a['d'] as String) * -1,
  );
  final read = PillBank.cards.take(312).map((p) => p.id).toList();
  final answers = {
    for (final p in graded.take(104))
      p.id: {
        'r': '0',
        'c': 70,
        'd': ago(-20),
        's': graded.indexOf(p) < 41 ? 3 : 1,
      },
  };
  return {
    'knowit.onboarded': true,
    'knowit.plus': true,
    'knowit.streak': 13,
    'knowit.bestStreak': 21,
    'knowit.lastCompletionDate': ago(1),
    'knowit.completedDates': [
      for (var d = 85; d >= 1; d--)
        if (d % 7 != 3) ago(d),
    ],
    'knowit.seenIds': read,
    'knowit.judgements': jsonEncode(judgements),
    'knowit.answersJson': jsonEncode(answers),
    'knowit.rungDates': jsonEncode({
      'day_one': ago(85),
      'reading': ago(81),
      'answering': ago(77),
      'saying_how_sure': ago(60),
      'calibrated': ago(40),
      'holding': ago(12),
    }),
    'knowit.recordDays': jsonEncode({
      ago(85): [5, 0, 0],
      ago(78): [40, 0, 0],
      ago(73): [62, 0, 0],
      ago(40): [170, 12, 5],
      ago(1): [312, 41, 9],
    }),
  };
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the top of the journey, today and two weeks in', (tester) async {
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
      SharedPreferences.setMockInitialValues(journeyed());
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
        await tester.tap(find.byKey(const ValueKey('journey-then')));
        for (int f = 0; f < 6; f++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(
          find.byType(JourneyScreen),
          matchesGoldenFile('$out/journey-top-then.png'),
        );
      }
    }
  });
}
