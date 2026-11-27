// Photographs Your journey's week as the owner's iPhone shows it (390 by 844
// points, dark, three pixels a point): the week's chapter, the review of the
// week at the foot of the page on both plans, the review opened and a card
// answered again in it, an empty week, and the tiles of a reader on their
// first day.
//
//   flutter test tool/week_review_shots.dart --update-goldens
//
// SHOTS (a folder) and LANG_SHOT (a language, Italian by default) move it.
// A camera, not a check: it lives outside test/ so CI never runs it. Run
// before a change and after it, it photographs both from the same readers;
// a picture the page has no place for yet is skipped.
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
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
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

const Size _phone = Size(390, 844);
const EdgeInsets _notch = EdgeInsets.only(top: 47, bottom: 34);

DateTime get _today {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The date key [d] days before today.
String _ago(int d) =>
    dateKey(DateTime(_today.year, _today.month, _today.day - d));

/// Cards in words that ask to pick one, not long of question, one subject
/// after another so that no subject gathers many: a reader's month.
List<Pill> _cards(int n, {int skip = 0}) {
  final Map<String, List<Pill>> bySubject = {};
  for (final Pill p in PillBank.live) {
    if (p.hasPage ||
        p.web != null ||
        p.isAboutAPlace ||
        p.scene != null ||
        p.challenge is! PickOne ||
        p.question.length > 90) {
      continue;
    }
    bySubject.putIfAbsent(p.topic, () => []).add(p);
  }
  final List<String> subjects = bySubject.keys.toList()..sort();
  final List<Pill> out = [];
  for (var round = 0; out.length < n + skip; round++) {
    final int had = out.length;
    for (final String s in subjects) {
      final List<Pill> pool = bySubject[s]!;
      if (round < pool.length) out.add(pool[round]);
      if (out.length == n + skip) break;
    }
    if (out.length == had) throw StateError('the bank has too few cards');
  }
  return out.skip(skip).toList();
}

/// A reader a few weeks in, whose run of days broke and who has not yet
/// answered six cards of any one subject: the week is told in what they
/// have read. [week] cards were first read this week, from Monday on, and
/// [before] in the three weeks before it.
Map<String, Object> _weekReader({
  required bool plus,
  int week = 9,
  int before = 23,
}) {
  final List<Pill> all = _cards(week + before);
  final List<Pill> old = all.take(before).toList();
  final List<Pill> now = all.skip(before).toList();
  final int sinceMonday = _today.weekday - 1;
  final readDays = <String, List<String>>{};
  // The weeks before: a few cards a day, a day off now and then.
  var i = 0;
  for (var d = sinceMonday + 21; d > sinceMonday && i < old.length; d--) {
    if (d % 4 == 0) continue;
    for (var k = 0; k < 2 && i < old.length; k++) {
      readDays.putIfAbsent(_ago(d), () => []).add(old[i++].id);
    }
  }
  // This week: Monday's first, spread over the days so far.
  final int days = math.max(1, sinceMonday + (sinceMonday == 0 ? 1 : 0));
  for (var j = 0; j < now.length; j++) {
    final int d = sinceMonday - (j * days ~/ now.length);
    readDays.putIfAbsent(_ago(math.max(0, d)), () => []).add(now[j].id);
  }
  // Answers: the first card of the week missed, the rest some right, some
  // wrong, a few said sure; never six in a subject.
  final answers = <String, Map<String, Object>>{};
  final judgements = <Map<String, Object>>[];
  void answer(Pill p, String on, {required bool right, int? sure}) {
    final PickOne pick = p.challenge as PickOne;
    final int r = right
        ? pick.correct
        : (pick.correct + 1) % pick.options.length;
    answers[p.id] = {
      'r': '$r',
      'c': ?sure,
      if (right) 's': 1,
      'd': dateKey(
        DateTime(
          int.parse(on.substring(0, 4)),
          int.parse(on.substring(5, 7)),
          int.parse(on.substring(8, 10)) + (right ? 7 : 2),
        ),
      ),
    };
    judgements.add({'c': ?sure, 'k': right, 'p': p.id, 'd': on});
  }

  String readOn(Pill p) =>
      readDays.entries.firstWhere((e) => e.value.contains(p.id)).key;
  if (now.isNotEmpty) {
    answer(now.first, readOn(now.first), right: false, sure: 70);
  }
  for (var j = 1; j < now.length; j += 2) {
    answer(now[j], readOn(now[j]), right: j % 3 != 0, sure: j == 3 ? 90 : null);
  }
  for (var j = 0; j < old.length; j += 3) {
    answer(old[j], readOn(old[j]), right: j % 2 == 0);
  }
  final List<String> completed = [
    for (final String d in readDays.keys)
      if (d != _ago(0)) d,
  ]..sort();
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.streak': 1,
    'knowit.bestStreak': 6,
    'knowit.lastCompletionDate': _ago(1),
    'knowit.completedDates': completed,
    'knowit.seenIds': [for (final p in all) p.id],
    'knowit.readDays': jsonEncode(readDays),
    // What each day dealt: the cards read on it, read on Today.
    'knowit.deckHistory': jsonEncode(readDays),
    'knowit.answersJson': jsonEncode(answers),
    'knowit.judgements': jsonEncode(judgements),
    'knowit.dayLog': jsonEncode({
      for (final String d in readDays.keys)
        d: [0, 60 * readDays[d]!.length + 25, readDays[d]!.length, 0, 0, 0],
    }),
  };
}

/// The owner's first day: five cards read today, three of them answered
/// wrong without saying how sure, the day finished, twenty seconds timed.
Map<String, Object> _firstDay() {
  final List<Pill> five = _cards(5, skip: 40);
  final answers = <String, Map<String, Object>>{};
  final judgements = <Map<String, Object>>[];
  for (final Pill p in five.take(3)) {
    final PickOne pick = p.challenge as PickOne;
    answers[p.id] = {
      'r': '${(pick.correct + 1) % pick.options.length}',
      'd': _ago(-2),
    };
    judgements.add({'k': false, 'p': p.id, 'd': _ago(0)});
  }
  return {
    'knowit.onboarded': true,
    'knowit.plus': true,
    'knowit.streak': 1,
    'knowit.bestStreak': 1,
    'knowit.lastCompletionDate': _ago(0),
    'knowit.completedDates': [_ago(0)],
    'knowit.seenIds': [for (final p in five) p.id],
    'knowit.readDays': jsonEncode({
      _ago(0): [for (final p in five) p.id],
    }),
    'knowit.answersJson': jsonEncode(answers),
    'knowit.judgements': jsonEncode(judgements),
    'knowit.dayLog': jsonEncode({
      _ago(0): [0, 20, 0, 0, 5, 0],
    }),
  };
}

void main() {
  setUpAll(_loadFonts);

  final String out = Platform.environment['SHOTS'] ?? 'shots/week-review';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');

  Future<AppState> open(WidgetTester tester, Map<String, Object> prefs) async {
    tester.view.physicalSize = _phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Every level told already: the camera photographs the page, not the
    // level rising over it.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({...prefs, 'knowit.levelTold': 99});
    final app = AppState();
    await app.init();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(size: _phone, padding: _notch),
          child: JourneyScreen(app: app, onBack: () {}),
        ),
      ),
    );
    await settle(tester);
    return app;
  }

  Future<void> take(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$out/$name.png'),
  );

  /// Scrolls the page until [target] stands [at] points from the top, or
  /// says it is not on the page.
  Future<bool> bring(
    WidgetTester tester,
    Finder target, {
    double at = 96,
  }) async {
    final ScrollPosition page = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('journey-page')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
      if (page.pixels >= page.maxScrollExtent) break;
      page.jumpTo(math.min(page.pixels + 300, page.maxScrollExtent));
      await tester.pump();
    }
    if (target.evaluate().isEmpty) return false;
    final double y = tester.getTopLeft(target.first).dy;
    final double to = (page.pixels + y - at).clamp(0, page.maxScrollExtent);
    page.jumpTo(math.max(0, to - 40));
    await tester.pump();
    page.jumpTo(to);
    await settle(tester);
    return true;
  }

  final AppLocalizations l = lookupAppLocalizations(locale);
  String chapter(String name) => locale.languageCode == 'tr'
      ? name.replaceAll('i', 'İ').toUpperCase()
      : name.toUpperCase();

  testWidgets('the week, on Astute+', (tester) async {
    await open(tester, _weekReader(plus: true));
    if (await bring(
      tester,
      find.byKey(const ValueKey('story-headline-read')),
      at: 150,
    )) {
      await take(tester, 'week-chapter');
    }
    if (await bring(
      tester,
      find.byKey(const ValueKey('journey-week-review')),
      at: 190,
    )) {
      await take(tester, 'review-plus');
      await tester.tap(find.byKey(const ValueKey('journey-week-review-go')));
      await settle(tester, 20);
      await take(tester, 'replay-front');
      // The first card of the week, missed the first time, answered again:
      // right, this time.
      final Pill first = _cards(32)[23];
      final PickOne pick = first.challenge as PickOne;
      await tester.tap(find.text(pick.options[pick.correct]).last);
      await settle(tester, 20);
      if (find.text('80%').evaluate().isNotEmpty) {
        await tester.tap(find.text('80%').last);
      }
      await settle(tester, 24);
      await take(tester, 'replay-back');
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('the week, on the free plan', (tester) async {
    await open(tester, _weekReader(plus: false));
    if (await bring(
      tester,
      find.byKey(const ValueKey('journey-week-review')),
      at: 190,
    )) {
      await take(tester, 'review-free');
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('a week not yet read', (tester) async {
    await open(tester, _weekReader(plus: true, week: 0, before: 30));
    if (await bring(
      tester,
      find.byKey(const ValueKey('journey-week-review')),
      at: 190,
    )) {
      await take(tester, 'review-empty');
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('the first day', (tester) async {
    await open(tester, _firstDay());
    if (await bring(
      tester,
      find.byKey(const ValueKey('story-headline-read')),
      at: 150,
    )) {
      await take(tester, 'first-day-week');
    }
    if (await bring(
      tester,
      find.textContaining(chapter(l.storyChapterReason)),
    )) {
      await take(tester, 'first-day-tiles');
    }
    if (await bring(
      tester,
      find.textContaining(chapter(l.journeyChapterHabits)),
    )) {
      await take(tester, 'first-day-habits');
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}

Future<void> settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
