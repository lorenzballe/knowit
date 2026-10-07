// Photographs Your journey (artboard 137a) on a reader twelve weeks in.
//
//   flutter test tool/journey_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder), LANG_SHOT (a language) and TALL (a phone height) move
// it for a one-off picture; TALL=2900 takes the whole page in one.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/journey_record.dart';
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

/// Eighty-six days, today the last: the first day of the reader.
DateTime get _day0 {
  final DateTime now = DateTime.now();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 85));
}

String _key(int d) => dateKey(_day0.add(Duration(days: d)));

/// The days off, and the cards each week, as the artboard has them.
const Set<int> _off = {3, 5, 8, 12, 17, 22, 26, 31, 35, 39, 59, 63, 67, 70, 73};
const List<int> _weekly = [16, 21, 22, 24, 20, 25, 27, 24, 28, 27, 30, 33, 15];

/// How many cards of each subject, most read first.
const Map<String, int> _bySubject = {
  'space': 40,
  'history': 36,
  'psychology': 32,
  'economics': 27,
  'human_body': 24,
  'nature': 22,
  'technology': 19,
  'thinking': 18,
  'pop_culture': 14,
  'medicine': 12,
  'cinema': 11,
  'philosophy': 10,
  'food': 9,
  'science': 8,
  'art': 7,
  'language': 6,
  'music': 5,
  'weird_facts': 5,
  'sport': 4,
  'life': 3,
};

/// The reader, as what the phone would have written down.
({Map<String, Object> prefs, Map<String, List<int>> log}) _reader() {
  final rand = math.Random(7);

  // Cards a day, spread over each week's days on.
  final perDay = List<int>.filled(86, 0);
  for (var w = 0; w < 13; w++) {
    final days = [
      for (var d = 0; d < 86; d++)
        if ((d + 1) ~/ 7 == w && !_off.contains(d)) d,
    ];
    final int base = _weekly[w] ~/ days.length;
    final int rem = _weekly[w] - base * days.length;
    final order = [...days]
      ..sort((a, b) => (a * 37 % 11).compareTo(b * 37 % 11));
    for (final d in days) {
      perDay[d] = base + (order.indexOf(d) < rem ? 1 : 0);
    }
  }

  // Which subject each read is, in order: the subjects read most start
  // first, the rest come in later.
  final slots = <(double, String)>[];
  final ranked = _bySubject.keys.toList();
  for (var r = 0; r < ranked.length; r++) {
    final int c = _bySubject[ranked[r]]!;
    final double from = 0.6 * r / (ranked.length - 1);
    for (var j = 0; j < c; j++) {
      slots.add((from + (j + 0.5) / c * (1 - from), ranked[r]));
    }
  }
  slots.sort((a, b) => a.$1.compareTo(b.$1));

  // The cards, easy first and harder later, graded where the bank has them.
  final used = <String>{};
  Pill pick(String subject, double t) {
    final String name = kTopics[subject]!.name;
    final Difficulty want = t < 0.35
        ? Difficulty.easy
        : t < 0.75
        ? Difficulty.medium
        : (rand.nextBool() ? Difficulty.hard : Difficulty.medium);
    final pool = PillBank.cards.where(
      (p) => p.topic == name && !used.contains(p.id),
    );
    final Pill card =
        pool
            .where((p) => p.difficulty == want && p.challenge is PickOne)
            .firstOrNull ??
        pool.where((p) => p.difficulty == want).firstOrNull ??
        pool.first;
    used.add(card.id);
    return card;
  }

  final readDays = <String, List<String>>{};
  final reads = <(int, Pill, double)>[];
  var slot = 0;
  for (var d = 0; d < 86; d++) {
    for (var i = 0; i < perDay[d]; i++) {
      final (double t, String subject) = slots[slot++];
      final Pill card = pick(subject, t);
      readDays.putIfAbsent(_key(d), () => []).add(card.id);
      reads.add((d, card, d / 85));
    }
  }

  // Answers with how sure: over-sure at first, close to right by the end;
  // and the cards that came back after two days, a week and three.
  final events = <(int, Map<String, Object>)>[];
  final answers = <String, Map<String, Object>>{};
  const levels = [50, 60, 70, 80, 90];
  for (final (int d, Pill card, double t) in reads) {
    if (card.challenge is! PickOne || rand.nextDouble() > 0.75) continue;
    final pick = card.challenge as PickOne;
    final List<int> weights = t < 0.4 ? [1, 2, 3, 4, 4] : [2, 3, 4, 3, 2];
    var roll = rand.nextInt(weights.reduce((a, b) => a + b));
    var c = 0;
    while (roll >= weights[c]) {
      roll -= weights[c++];
    }
    final int sure = levels[c];
    final double off = 0.31 - 0.29 * t;
    var day = d;
    var right = rand.nextDouble() < (sure / 100 - off).clamp(0.05, 0.98);
    events.add((day, {'c': sure, 'k': right, 'p': card.id, 'd': _key(day)}));
    // The app's ladder: two days after a miss, a week after the first
    // right answer, three weeks after the second, then retired.
    const comeBack = [2, 7, 21];
    // What comes back is known about as well as it was said, a little
    // less the longer it waited.
    const keep = [1.08, 0.86, 0.52];
    var run = right ? 1 : 0;
    while (run < 3 && day + comeBack[run] <= 85) {
      day += comeBack[run];
      final double now = 0.31 - 0.29 * day / 85;
      right =
          rand.nextDouble() <
          ((sure / 100 - now) * keep[run]).clamp(0.05, 0.98);
      events.add((day, {'c': sure, 'k': right, 'p': card.id, 'd': _key(day)}));
      run = right ? run + 1 : 0;
    }
    answers[card.id] = {
      'r': '${right ? pick.correct : (pick.correct + 1) % pick.options.length}',
      'c': sure,
      if (run != 0) 's': run,
      if (run < 3) 'd': _key(day + comeBack[run]),
    };
  }
  events.sort((a, b) => a.$1.compareTo(b.$1));

  // The time on the cards and the part of the day they were read in:
  // mornings mostly, then evenings.
  final log = <String, List<int>>{};
  for (var d = 0; d < 86; d++) {
    if (perDay[d] == 0) continue;
    final parts = List<int>.filled(4, 0);
    for (var i = 0; i < perDay[d]; i++) {
      final int r = rand.nextInt(100);
      final int part = r < 44 ? 0 : (r < 56 ? 1 : (r < 92 ? 2 : 3));
      parts[part] += 1;
    }
    log[_key(d)] = [0, perDay[d] * (34 + 10 * d ~/ 85), ...parts];
  }

  final List<String> active = [
    for (var d = 0; d < 86; d++)
      if (perDay[d] > 0) _key(d),
  ];
  return (
    prefs: {
      'knowit.onboarded': true,
      'knowit.plus': true,
      'knowit.streak': 12,
      'knowit.bestStreak': 19,
      'knowit.lastCompletionDate': _key(85),
      'knowit.completedDates': active,
      'knowit.seenIds': [for (final r in reads) r.$2.id],
      'knowit.readDays': jsonEncode(readDays),
      'knowit.judgements': jsonEncode([for (final e in events) e.$2]),
      'knowit.answersJson': jsonEncode(answers),
    },
    log: log,
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('your journey', (tester) async {
    final Size phone = Size(
      402,
      double.tryParse(Platform.environment['TALL'] ?? '') ?? 874,
    );
    const EdgeInsets notch = EdgeInsets.only(top: 59, bottom: 34);
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final String out = Platform.environment['SHOTS'] ?? 'shots';
    final reader = _reader();
    for (final Brightness b in [Brightness.dark, Brightness.light]) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(reader.prefs);
      final app = AppState();
      await app.init();
      // The score each day ended on, as the phone would have written it.
      final JourneyRecord before = app.record;
      app.dayLog = {
        for (final e in reader.log.entries)
          e.key: [before.scoreOn(e.key), ...e.value.skip(1)],
      };
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
        matchesGoldenFile('$out/journey$tag.png'),
      );
      if (b == Brightness.dark) {
        // A week tapped on the chart: the ring moves, and so does the
        // sentence under it.
        await tester.tap(find.byKey(const ValueKey('journey-week-6')));
        for (int f = 0; f < 6; f++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(
          find.byType(JourneyScreen),
          matchesGoldenFile('$out/journey-week.png'),
        );
      }
    }
  });
}
