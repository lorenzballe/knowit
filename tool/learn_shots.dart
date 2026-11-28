// Photographs What to learn as it ships and as the developer tools try it
// (lib/state/debug_looks.dart, LearnLook), the same pictures for every look
// so they can be laid side by side: the profile where the look's box sits
// under the question of the aim, Your journey's head, a card of the day and
// a card's back once answered, and Explore's first shelves; for a reader two
// weeks in, on the free plan and on Astute+, whose aim is everyday
// decisions.
//
//   SHOTS=/some/folder LOOK=today flutter test tool/learn_shots.dart \
//     --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real app, on a 390 × 844 phone at night, in Italian unless LANG_SHOT says
// otherwise. LOOK is one of today, score, aim, profile, aimProfile, weekly
// (all of them when not given); TEXT=1.3 sets the phone's text size and
// THEME=light the day's paper.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/learn_reading.dart';
import 'package:astuto/data/levels.dart' show LevelMemory;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/learn_looks.dart' show AimScreen;
import 'package:astuto/widgets/level_up.dart' show levelStandingOf;
import 'package:astuto/widgets/web/card_thumb.dart';

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

/// The skills the reader picked on What to learn, in the order picked.
const List<String> _picked = ['decisions', 'money', 'fakes'];

/// The reader's aim, picked on the profile: every look has it now.
const String _aim = 'decide';

/// Cards that ask, have no page of their own and are a pick of one.
List<Pill> _asking() => [
  for (final Pill p in PillBank.cards)
    if (p.isGraded && p.challenge is PickOne && !p.hasPage) p,
];

/// The cards today's five are made from, kept out of the weeks before so
/// the weeks are the same whichever five are dealt: for every skill the two
/// that ask and train it as closely as a card can, one of the everyday
/// decisions area's own besides, and a card that tells.
({Map<Skill, List<Pill>> closest, Pill decide, Pill told}) _kept() {
  final List<Pill> asking = _asking();
  final Set<String> used = {};
  final Map<Skill, List<Pill>> closest = {};
  for (final Skill s in Skill.values) {
    final List<Pill> two = [
      for (final Pill p in asking)
        if (!used.contains(p.id) && s.fitOf(p) == 0) p,
    ].take(2).toList();
    used.addAll(two.map((p) => p.id));
    closest[s] = two;
  }
  // One of the decisions skill's own that is also one of the everyday
  // decisions area's (lib/data/goals.dart): the aim names it.
  final Pill decide = asking.firstWhere(
    (p) =>
        !used.contains(p.id) &&
        Skill.decisions.fitOf(p) == 0 &&
        (Goal.decide.fitOf(p) ?? 2) < 2,
  );
  final Pill told = PillBank.cards.firstWhere((p) => !p.isGraded && !p.hasPage);
  return (closest: closest, decide: decide, told: told);
}

/// Today's five: two answered before the camera arrives, a card that tells,
/// then the one in front of the free reader, then one more. As it ships, a
/// card of money first and one of the aim in front; in E, where the week's
/// skill has a mark, a card of that skill first and in front.
List<Pill> _todayDeck({Skill? focus}) {
  final kept = _kept();
  final Pill fakes = kept.closest[Skill.fakes]!.first;
  final Pill critical = kept.closest[Skill.critical]!.first;
  if (focus != null) {
    final List<Pill> two = kept.closest[focus]!;
    final Pill other = focus == Skill.fakes ? critical : fakes;
    return [two.first, other, kept.told, two.last, kept.decide];
  }
  return [
    kept.closest[Skill.money]!.first,
    fakes,
    kept.told,
    kept.decide,
    critical,
  ];
}

/// A reader two weeks in: thirteen days before today, two of them missed,
/// three cards that ask on each day read and two that tell, right a little
/// over half the time at first and two in three by now, the cards harder as
/// they go. On the free plan three of today's five are read; on Astute+ all
/// five.
Map<String, Object> _reader({
  required bool plus,
  required String look,
  required List<Pill> deck,
}) {
  final rand = math.Random(14);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String day(int back) => dateKey(today.subtract(Duration(days: back)));
  const Set<int> missed = {4, 9};
  const int first = 13;

  final kept = _kept();
  final Set<String> todays = {
    for (final List<Pill> two in kept.closest.values)
      for (final Pill p in two) p.id,
    kept.decide.id,
    kept.told.id,
  };
  final List<Pill> asking = [
    for (final Pill p in _asking())
      if (!todays.contains(p.id)) p,
  ];
  // Half the cards that ask train a skill the reader picked: the deals lean
  // that way on Astute+, and a reader reads what they came for.
  final List<Pill> leaning = [
    for (final Pill p in asking)
      if (skillMarkOf(p, _picked) != null) p,
  ];
  final List<Pill> told = [
    for (final Pill p in PillBank.cards)
      if (!p.isGraded && !todays.contains(p.id)) p,
  ];

  final List<String> seen = [];
  final Map<String, List<String>> readDays = {};
  final List<String> completed = [];
  final List<Map<String, Object>> judged = [];
  final Map<String, Object> answers = {};
  var a = 0, l = 0, t = 0;
  for (int back = first; back >= 1; back--) {
    if (missed.contains(back)) continue;
    completed.add(day(back));
    final double progress = (first - back) / first;
    for (int i = 0; i < kPillsPerDay; i++) {
      if (i >= 3) {
        final String id = told[t++ % told.length].id;
        seen.add(id);
        readDays.putIfAbsent(day(back), () => []).add(id);
        continue;
      }
      final Pill card = rand.nextBool()
          ? leaning[(l++ * 7) % leaning.length]
          : asking[(a++ * 13) % asking.length];
      if (seen.contains(card.id)) continue;
      seen.add(card.id);
      readDays.putIfAbsent(day(back), () => []).add(card.id);
      final bool right = rand.nextDouble() < 0.52 + 0.16 * progress;
      final PickOne pick = card.challenge as PickOne;
      judged.add({
        'c': 60 + 10 * rand.nextInt(4),
        'k': right,
        'p': card.id,
        'd': day(back),
      });
      answers[card.id] = {
        'r':
            '${right ? pick.correct : (pick.correct + 1) % pick.options.length}',
        'c': 70,
      };
    }
  }

  final int readNow = plus ? kPillsPerDay : 3;
  // Today's answers: the first right, the second wrong; on Astute+ the
  // fourth and fifth right too.
  for (final (int i, Pill card) in deck.take(readNow).indexed) {
    if (!card.isGraded) continue;
    final bool right = i != 1;
    final PickOne pick = card.challenge as PickOne;
    judged.add({'c': 70, 'k': right, 'p': card.id, 'd': day(0)});
    answers[card.id] = {
      'r': '${right ? pick.correct : (pick.correct + 1) % pick.options.length}',
      'c': 70,
    };
  }
  if (plus) completed.add(day(0));
  readDays[day(0)] = [for (final Pill p in deck.take(readNow)) p.id];

  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.streak': plus ? 4 : 3,
    'knowit.bestStreak': 6,
    'knowit.lastCompletionDate': plus ? day(0) : day(1),
    'knowit.completedDates': completed,
    'knowit.seenIds': [...seen, for (final Pill p in deck.take(readNow)) p.id],
    'knowit.judgements': jsonEncode(judged),
    'knowit.answersJson': jsonEncode(answers),
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': [for (final Pill p in deck) p.id],
    'knowit.todayIndex': readNow,
    // On the free plan two of the five are the reader's own: the first, and
    // the one in front of them.
    if (!plus) 'knowit.todayOwnIds': [deck[0].id, deck[3].id],
    'knowit.readDays': jsonEncode(readDays),
    'knowit.skills': _picked,
    'knowit.goals': [_aim],
    'knowit.theme': Platform.environment['THEME'] ?? 'dark',
    'knowit.debug.learn': look,
  };
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    // No network in a camera: pictures stay as their drawn stand-ins.
    CardThumb.image = (url) => MemoryImage(Uint8List(0));
    Remote.fetch = (_) async => null;
  });

  final String out = Platform.environment['SHOTS'] ?? 'shots/learn';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');
  final double text = double.tryParse(Platform.environment['TEXT'] ?? '') ?? 1;
  final String? only = Platform.environment['LOOK'];
  final List<String> looks = [
    for (final LearnLook look in LearnLook.values)
      if (only == null || only == look.name) look.name,
  ];

  late bool tools;

  setUp(() {
    tools = debugToolsOn;
    debugToolsOn = true;
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    // An iPhone's notch and home bar, so the page sits where it would.
    view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    dispatcher.localeTestValue = locale;
    dispatcher.localesTestValue = [locale];
    dispatcher.textScaleFactorTestValue = text;
  });

  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.views.first.reset();
    dispatcher.clearLocaleTestValue();
    dispatcher.clearLocalesTestValue();
    dispatcher.clearTextScaleFactorTestValue();
  });

  Future<void> settle(WidgetTester tester, [int frames = 14]) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$out/$name.png'),
  );

  /// The week's skill this reader would have, on [plus] or not: worked out
  /// by the app itself from the weeks before, which no five change.
  Future<Skill> focusOf(WidgetTester tester, {required bool plus}) async {
    SharedPreferences.setMockInitialValues(
      _reader(plus: plus, look: 'weekly', deck: _todayDeck()),
    );
    final AppState app = AppState();
    await tester.runAsync(app.init);
    return weekFocusOf(app).skill;
  }

  /// The reader for [look], with the level their score stands at told
  /// already: the journey shows the level the score is at, and no level
  /// rises over it as it opens.
  Future<Map<String, Object>> readerFor(
    WidgetTester tester, {
    required bool plus,
    required String look,
  }) async {
    final Skill? focus = look == LearnLook.weekly.name
        ? await focusOf(tester, plus: plus)
        : null;
    final Map<String, Object> prefs = _reader(
      plus: plus,
      look: look,
      deck: _todayDeck(focus: focus),
    );
    SharedPreferences.setMockInitialValues(prefs);
    final AppState app = AppState();
    await tester.runAsync(app.init);
    return {...prefs, LevelMemory.key: levelStandingOf(app, null).at};
  }

  Future<void> open(
    WidgetTester tester, {
    required bool plus,
    required String look,
  }) async {
    SharedPreferences.setMockInitialValues(
      await readerFor(tester, plus: plus, look: look),
    );
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
  }

  /// The profile's own list. The tabs sit in a page view, which is a
  /// scrollable too, and comes first.
  Finder profileList() => find
      .descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  /// Down the profile until [key] stands [from] points under the top.
  Future<void> profileAt(
    WidgetTester tester,
    String key, {
    double from = 120,
  }) async {
    final Finder target = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(target, 300, scrollable: profileList());
    await settle(tester);
    final ScrollPosition position = tester
        .state<ScrollableState>(profileList())
        .position;
    position.jumpTo(
      (position.pixels + tester.getRect(target).top - from).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await settle(tester);
  }

  /// Explore's page, under its head.
  Finder explorePage() => find
      .descendant(
        of: find.byKey(const ValueKey('explore-refresh')),
        matching: find.byType(Scrollable),
      )
      .first;

  for (final String look in looks) {
    for (final bool plus in [false, true]) {
      final String who = plus ? 'plus' : 'free';

      // The profile where the look's box is: the question of the aim, its
      // last rows with the aim picked, and under it the box, or the next
      // section where the look has none. Then, on Astute+, Your journey's
      // head (on the free plan its door is the plans).
      testWidgets('$look $who profile and journey', (tester) async {
        await open(tester, plus: plus, look: look);
        await tester.tap(find.byKey(const ValueKey('tab-Profile')));
        await settle(tester);
        await profileAt(tester, 'profile-aim-health', from: 64);
        await shoot('$look-$who-1-profilo');
        if (!plus) return;
        final ScrollPosition position = tester
            .state<ScrollableState>(profileList())
            .position;
        position.jumpTo(0);
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('profile-journey')));
        await settle(tester, 24);
        await shoot('$look-$who-2-viaggio');
      });

      // The card in front of the reader, as Today shows it.
      testWidgets('$look $who today', (tester) async {
        await open(tester, plus: plus, look: look);
        await shoot('$look-$who-3-oggi');
      });
    }

    // The day read again on Astute+, its first card turned over: the verdict
    // and what the answer moved beside it.
    testWidgets('$look plus back', (tester) async {
      await open(tester, plus: true, look: look);
      await tester.tap(find.byKey(const ValueKey('shelf-see-again')));
      await settle(tester, 20);
      final Skill? focus = look == LearnLook.weekly.name
          ? await focusOf(tester, plus: true)
          : null;
      // The card on top, by its id: a tap turns it over.
      final Finder card = find
          .byKey(ValueKey(_todayDeck(focus: focus).first.id))
          .last;
      final Rect at = tester.getRect(card);
      await tester.tapAt(Offset(at.center.dx, at.top + at.height * 0.62));
      await settle(tester, 24);
      await shoot('$look-plus-4-retro');
    });
  }

  // E's own: Explore's first shelves with the week's skill over the aim's,
  // on either plan; the sheet a card's mark opens; and its Sunday, the
  // week's result, in Your journey.
  if (looks.contains(LearnLook.weekly.name)) {
    for (final bool plus in [false, true]) {
      final String who = plus ? 'plus' : 'free';
      testWidgets('weekly $who explore', (tester) async {
        await open(tester, plus: plus, look: 'weekly');
        await tester.tap(find.byKey(const ValueKey('tab-Explore')));
        await settle(tester, 20);
        final Finder shelf = find.byKey(const ValueKey('focus-shelf-mark'));
        await tester.scrollUntilVisible(shelf, 400, scrollable: explorePage());
        await settle(tester);
        final ScrollPosition position = tester
            .state<ScrollableState>(explorePage())
            .position;
        position.jumpTo(position.pixels + tester.getRect(shelf).top - 150);
        await settle(tester, 20);
        await shoot('weekly-$who-5-esplora');
      });
    }

    testWidgets('weekly free mark sheet', (tester) async {
      await open(tester, plus: false, look: 'weekly');
      final Finder mark = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('skill-mark-'),
      );
      await tester.tap(mark.hitTestable().first);
      await settle(tester, 20);
      await shoot('weekly-free-6-segno');
    });

    testWidgets('weekly plus sunday', (tester) async {
      // The Sunday of this week, at night, the five done.
      final DateTime now = DateTime.now();
      final DateTime sunday = DateTime(
        now.year,
        now.month,
        now.day + (DateTime.sunday - now.weekday),
        21,
      );
      SharedPreferences.setMockInitialValues(
        await readerFor(tester, plus: true, look: 'weekly'),
      );
      final AppState app = AppState(clock: () => sunday);
      await tester.runAsync(app.init);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(
            Platform.environment['THEME'] == 'light'
                ? Brightness.light
                : Brightness.dark,
          ),
          debugShowCheckedModeBanner: false,
          home: JourneyScreen(app: app, onBack: () {}),
        ),
      );
      await settle(tester, 24);
      await shoot('weekly-plus-7-domenica');
    });
  }

  // B: the question at the end of the first run, in B, D and E.
  if (looks.contains(LearnLook.aim.name)) {
    testWidgets('aim free question', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._reader(plus: false, look: 'aim', deck: _todayDeck()),
        'knowit.goals': <String>[],
      });
      final AppState app = AppState();
      await tester.runAsync(app.init);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          debugShowCheckedModeBanner: false,
          home: AimScreen(app: app, firstRun: true),
        ),
      );
      await settle(tester);
      await shoot('aim-free-6-domanda');
    });
  }

  // Where the developer tools pick the look, at the foot of the profile:
  // the mix, which ships, picked.
  if (looks.contains(LearnLook.mix.name)) {
    testWidgets('mix free debug', (tester) async {
      await open(tester, plus: false, look: 'mix');
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await settle(tester);
      await profileAt(tester, 'debug-learn', from: 300);
      await shoot('mix-free-9-debug');
    });
  }

  if (looks.contains(LearnLook.today.name)) {
    testWidgets('today free debug', (tester) async {
      await open(tester, plus: false, look: 'today');
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await settle(tester);
      await profileAt(tester, 'debug-learn', from: 300);
      await shoot('today-free-9-debug');
    });
  }
}
