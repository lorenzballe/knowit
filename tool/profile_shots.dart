// Photographs the top of the profile three ways (lib/widgets/profile_top.dart),
// each on the free plan and on Astute+; the top each plan opens on by itself
// (profile-free, profile-plus); the debug section's looks, as a TestFlight
// build shows them (profile-debug); and the way back to Today from its
// tile, frame by frame.
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/profile_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real app, on a 390 × 844 phone at night: the free reader halfway through
// the day, the Astute+ reader with the five read. SHOTS is where the
// pictures go (tool/shots by default); THEME=light shoots the day; LANG_SHOT
// is the phone's language, English when not given.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/widgets/profile_top.dart';

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

/// The profile's top the camera shoots, behind the single ignore the
/// camera allows itself: it lives outside test/ on purpose.
void _top(ProfileTop? top) {
  // ignore: invalid_use_of_visible_for_testing_member
  profileTopForShots = top;
}

void _prefs(Map<String, Object> values) {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(values);
}

/// A reader three weeks in: most days read, a few missed, answers that
/// start a little over half right and end three in four, the cards harder
/// as they go. [plus] has today's five read; the free reader is three in.
Map<String, Object> _reader({required bool plus}) {
  final rand = math.Random(11);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String day(int back) => dateKey(today.subtract(Duration(days: back)));
  // Missed: five days ago (so the streak is four, or five with today), and
  // two more further back.
  const Set<int> missed = {5, 11, 16};
  const int first = 21;

  // The cards that ask, by how hard; the bank's easy cards ask nothing, and
  // are read between them.
  List<Pill> asking(Difficulty d) => [
    for (final Pill p in PillBank.cards)
      if (p.isGraded && p.difficulty == d) p,
  ];
  final List<Pill> medium = asking(Difficulty.medium);
  final List<Pill> hardest = asking(Difficulty.hard);
  final List<Pill> told = [
    for (final Pill p in PillBank.cards)
      if (!p.isGraded) p,
  ];

  final List<String> seen = [];
  final List<String> completed = [];
  final List<Map<String, Object>> judged = [];
  var m = 0, h = 0, r = 0;
  for (int back = first; back >= 1; back--) {
    if (missed.contains(back)) continue;
    completed.add(day(back));
    final double t = (first - back) / first;
    for (int i = 0; i < kPillsPerDay; i++) {
      if (i >= 3) {
        seen.add(told[r++ % told.length].id);
        continue;
      }
      final bool hard = rand.nextDouble() < 0.2 + 0.4 * t;
      final Pill card = hard
          ? hardest[h++ % hardest.length]
          : medium[m++ % medium.length];
      seen.add(card.id);
      {
        final double chance = (hard ? 0.4 : 0.55) + 0.25 * t;
        judged.add({
          'c': 60 + 10 * rand.nextInt(4),
          'k': rand.nextDouble() < chance,
          'p': card.id,
          'd': day(back),
        });
      }
    }
  }

  final List<String> deck = dealDay(date: now).cards
      .take(kPillsPerDay)
      .map((p) => p.id)
      .toList();
  final int readNow = plus ? kPillsPerDay : 3;
  // Today's answers: the free reader is three cards in, the Astute+ reader
  // done, two of them right either way.
  for (final (int i, String id) in deck.take(readNow).indexed) {
    final Pill? card = PillBank.byId(id);
    if (card == null || !card.isGraded) continue;
    judged.add({'c': 70, 'k': i != 1, 'p': id, 'd': day(0)});
  }
  if (plus) completed.add(day(0));

  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.streak': plus ? 5 : 4,
    'knowit.bestStreak': 9,
    'knowit.lastCompletionDate': plus ? day(0) : day(1),
    'knowit.completedDates': completed,
    'knowit.seenIds': [...seen, ...deck.take(readNow)],
    'knowit.judgements': jsonEncode(judged),
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': readNow,
    'knowit.theme': Platform.environment['THEME'] ?? 'dark',
  };
}

void main() {
  setUpAll(_loadFonts);

  final String out = Platform.environment['SHOTS'] ?? 'shots';

  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'en');

  setUp(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    // An iPhone's notch and home bar, so the page sits where it would.
    view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    dispatcher.localeTestValue = locale;
    dispatcher.localesTestValue = [locale];
  });

  tearDown(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.views.first.reset();
    dispatcher.clearLocaleTestValue();
    dispatcher.clearLocalesTestValue();
    _top(null);
  });

  Future<void> settle(WidgetTester tester) async {
    for (int f = 0; f < 14; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$out/$name.png'),
  );

  for (final ProfileTop top in ProfileTop.values) {
    for (final bool plus in [false, true]) {
      final String name = 'profile-${top.name}-${plus ? 'plus' : 'free'}';
      testWidgets(name, (tester) async {
        _top(top);
        _prefs(_reader(plus: plus));
        await tester.pumpWidget(const AstutoApp());
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('tab-Profile')));
        await settle(tester);
        await shoot(name);
      });
    }
  }

  // The top each plan opens on by itself: A, the score, free; C, the
  // board with its streak lit, on Astute+.
  for (final bool plus in [false, true]) {
    final String name = 'profile-${plus ? 'plus' : 'free'}';
    testWidgets(name, (tester) async {
      _prefs(_reader(plus: plus));
      await tester.pumpWidget(const AstutoApp());
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await settle(tester);
      await shoot(name);
    });
  }

  // The looks at the head of the debug section, as a TestFlight build
  // shows it at the foot of the profile.
  testWidgets('profile-debug', (tester) async {
    final bool tools = debugToolsOn;
    debugToolsOn = true;
    addTearDown(() {
      debugToolsOn = tools;
      // ignore: invalid_use_of_visible_for_testing_member
      DebugLooks.reset();
    });
    _prefs(_reader(plus: false));
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    final Finder list = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    final Finder looks = find.byKey(const ValueKey('debug-no-top-row'));
    await tester.scrollUntilVisible(looks, 400, scrollable: list);
    await settle(tester);
    // The section's name high on the screen, the looks under it, and a
    // little of the profile over it.
    final ScrollPosition position = tester
        .state<ScrollableState>(list)
        .position;
    position.jumpTo(position.pixels + tester.getRect(looks).top - 250);
    await settle(tester);
    await shoot('profile-debug');
  });

  testWidgets('back to Today, out of the tile', (tester) async {
    _prefs(_reader(plus: false));
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('profile-today')));
    // The frame the tap lands on, then three along the way.
    await tester.pump();
    var at = 0;
    for (final (int i, int ms) in const [(1, 70), (2, 170), (3, 300)]) {
      await tester.pump(Duration(milliseconds: ms - at));
      at = ms;
      await shoot('profile-to-today-$i');
    }
    await settle(tester);
    await shoot('profile-to-today-4');
  });
}
