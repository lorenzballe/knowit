// The looks the developer tools let a phone try on (lib/state/debug_looks.dart),
// set from the debug section at the foot of the profile: the finished day
// with no row over its card, so the card is bigger; which top the profile
// opens on, Auto (A free, C Astute+), A, B or C; What to learn's look, as it
// ships or one of the three answers to it (lib/widgets/learn_looks.dart);
// which paywall, A as it ships or the prototypes B, C and D; and the foot
// of a card, A line, B two lines, C buttons or D links. Kept on the phone
// and read back at the next start, kept through the wipe, shown at once,
// and never read by a build without the tools.
//
//   flutter test test/debug_looks_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/source_foot.dart';

Future<void> _loadRealFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// Today's five, as the day deals them.
List<String> _deck() =>
    dealDay(date: DateTime.now()).cards
        .take(kPillsPerDay)
        .map((p) => p.id)
        .toList();

/// A reader on the third day running with today's five read, so Today is
/// the shelf; nothing asked of them over it.
Map<String, Object> _finished({bool plus = false}) {
  final DateTime now = DateTime.now();
  String day(int back) => dateKey(now.subtract(Duration(days: back)));
  final List<String> deck = _deck();
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': deck.length,
    'knowit.streak': 3,
    'knowit.bestStreak': 3,
    'knowit.lastCompletionDate': day(0),
    'knowit.completedDates': [day(2), day(1), day(0)],
    'knowit.seenIds': deck,
  };
}

/// A reader on the third day running, today's five dealt and none read
/// yet, so Today is the deck; nothing asked of them over it.
Map<String, Object> _reading() {
  final DateTime now = DateTime.now();
  String day(int back) => dateKey(now.subtract(Duration(days: back)));
  return {
    ..._finished(),
    'knowit.todayIndex': 0,
    'knowit.streak': 2,
    'knowit.bestStreak': 2,
    'knowit.lastCompletionDate': day(1),
    'knowit.completedDates': [day(2), day(1)],
    'knowit.seenIds': <String>[],
  };
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The profile's own list. The tabs sit in a page view, which is a
/// scrollable too, and comes first.
final Finder _profileList = find
    .descendant(
      of: find.byType(ProfileScreen),
      matching: find.byType(Scrollable),
    )
    .first;

/// Down the profile to [target], at its foot.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 400, scrollable: _profileList);
  await _settle(tester);
}

void main() {
  setUpAll(_loadRealFonts);

  late bool tools;

  setUp(() {
    tools = debugToolsOn;
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  test('kept on the phone, read back at the next start, and kept through the '
      'wipe, which forgets the reader and not the phone', () async {
    SharedPreferences.setMockInitialValues(_finished());
    debugToolsOn = true;
    await DebugLooks.setNoTopRow(true);
    await DebugLooks.setProfileTop(ProfileTopPick.b);
    await DebugLooks.setPaywall(PaywallLook.d);
    await DebugLooks.setCardFoot(CardFootPick.c);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('knowit.debug.todayNoTopRow'), isTrue);
    expect(prefs.getString('knowit.debug.profileTop'), 'b');
    expect(prefs.getString('knowit.debug.paywallLook'), 'd');
    expect(prefs.getString('knowit.debug.cardFoot'), 'c');

    // The next start reads them back.
    DebugLooks.reset();
    expect(DebugLooks.cardFoot.value, isNull);
    final AppState app = AppState();
    await app.init();
    expect(DebugLooks.noTopRow.value, isTrue);
    expect(DebugLooks.profileTop.value, ProfileTopPick.b);
    expect(DebugLooks.paywall.value, PaywallLook.d);
    expect(DebugLooks.cardFoot.value, CardFootPick.c);
    expect(sourceFoot, SourceFoot.pill);

    await app.signOut();
    expect(prefs.getBool('knowit.onboarded'), isNull);
    expect(prefs.getBool('knowit.debug.todayNoTopRow'), isTrue);
    expect(prefs.getString('knowit.debug.profileTop'), 'b');
    expect(prefs.getString('knowit.debug.paywallLook'), 'd');
    expect(prefs.getString('knowit.debug.cardFoot'), 'c');

    // Back as they ship.
    await DebugLooks.setNoTopRow(false);
    await DebugLooks.setProfileTop(ProfileTopPick.auto);
    await DebugLooks.setPaywall(PaywallLook.a);
    await DebugLooks.setCardFoot(CardFootPick.a);
    DebugLooks.load(prefs);
    expect(DebugLooks.noTopRow.value, isFalse);
    expect(DebugLooks.profileTop.value, ProfileTopPick.auto);
    expect(DebugLooks.paywall.value, PaywallLook.a);
    expect(DebugLooks.cardFoot.value, CardFootPick.a);
    expect(sourceFoot, SourceFoot.line);
  });

  test('read only while the tools are on: a look a TestFlight build kept is '
      'still on the phone under the App Store build, and never read', () async {
    SharedPreferences.setMockInitialValues({
      'knowit.debug.todayNoTopRow': true,
      'knowit.debug.profileTop': 'c',
      'knowit.debug.paywallLook': 'b',
      'knowit.debug.cardFoot': 'd',
    });
    DebugLooks.load(await SharedPreferences.getInstance());

    debugToolsOn = false;
    expect(DebugLooks.todayWithoutTopRow, isFalse);
    expect(DebugLooks.profileTopPicked, ProfileTopPick.auto);
    expect(DebugLooks.paywallPicked, PaywallLook.a);
    expect(TodayDoneView.head, kDoneHead);
    expect(DebugLooks.cardFootPicked, isNull);
    expect(sourceFoot, builtSourceFoot);

    debugToolsOn = true;
    expect(DebugLooks.todayWithoutTopRow, isTrue);
    expect(DebugLooks.profileTopPicked, ProfileTopPick.c);
    expect(DebugLooks.paywallPicked, PaywallLook.b);
    expect(TodayDoneView.head, DoneHead.none);
    expect(DebugLooks.cardFootPicked, CardFootPick.d);
    expect(sourceFoot, SourceFoot.links);
  });

  testWidgets('picked in the debug section, the paywall opens in that look '
      'at once, from the row under it; A is the paywall as it ships', (
    tester,
  ) async {
    debugToolsOn = true;
    SharedPreferences.setMockInitialValues(_finished());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);

    for (final String look in const ['b', 'c', 'd', 'a']) {
      final Finder choice = find.byKey(ValueKey('debug-paywall-$look'));
      await _scrollTo(tester, choice);
      await tester.tap(choice);
      await _settle(tester);
      expect(DebugLooks.paywall.value.name, look);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'knowit.debug.paywallLook',
        ),
        look,
      );
      final Finder row = find.byKey(const ValueKey('debug-open-paywall'));
      await _scrollTo(tester, row);
      await tester.tap(row);
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsOneWidget, reason: look);
      // A has its drawn marks; the prototypes their list of their own.
      expect(
        find.byKey(const ValueKey('paywall-features')),
        look == 'a' ? findsNothing : findsOneWidget,
        reason: look,
      );
      await tester.tap(find.bySemanticsLabel('Close').last);
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsNothing, reason: look);
    }
  });

  testWidgets('switched in the debug section, the finished day loses its top '
      'row at once: the card bigger, See again and the share at the two ends '
      'of the dots; and switched back, the row returns', (tester) async {
    debugToolsOn = true;
    SharedPreferences.setMockInitialValues(_finished());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    final Finder name = find.byKey(const ValueKey('shelf-day'));
    final Finder again = find.byKey(const ValueKey('shelf-see-again'));
    final Finder send = find.byKey(const ValueKey('shelf-share-day'));
    final Finder card = find.byKey(
      ValueKey('shelf-face-${_deck().first}-front'),
    );

    // As it ships: the day's name over the card, See again and the share at
    // the end of its row.
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(name, findsOneWidget);
    final Rect before = tester.getRect(card);
    expect(tester.getCenter(again).dy, lessThan(before.top));
    expect(tester.getCenter(send).dy, lessThan(before.top));

    // The switch, first in the debug section at the foot of the profile.
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    final Finder row = find.byKey(const ValueKey('debug-no-top-row'));
    await _scrollTo(tester, row);
    // The looks before the readouts, measured down the page: the section is
    // long now, so the readouts are built only once scrolled to.
    final ScrollPosition list = tester
        .state<ScrollableState>(_profileList)
        .position;
    final double rowAt = tester.getRect(row).top + list.pixels;
    await _scrollTo(tester, find.text('Firebase'));
    final double readoutsAt =
        tester.getRect(find.text('Firebase')).top + list.pixels;
    expect(rowAt, lessThan(readoutsAt), reason: 'the looks before the readouts');
    await tester.scrollUntilVisible(row, -400, scrollable: _profileList);
    await _settle(tester);
    await tester.tap(row);
    await _settle(tester);
    expect(DebugLooks.noTopRow.value, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'knowit.debug.todayNoTopRow',
      ),
      isTrue,
    );

    // Today, without going anywhere else: no row over the card, and the
    // card grown into the room it left.
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await _settle(tester);
    expect(name, findsNothing);
    final Rect after = tester.getRect(card);
    expect(after.height, greaterThan(before.height + 20));
    expect(after.top, lessThan(before.top));
    // See again at the start of the row of dots and the day sent at its
    // end, both under the card, on one line.
    expect(tester.getCenter(again).dy, greaterThan(after.bottom));
    expect(tester.getCenter(send).dy, closeTo(tester.getCenter(again).dy, 1));
    expect(tester.getCenter(again).dx, lessThan(after.center.dx));
    expect(tester.getCenter(send).dx, greaterThan(after.center.dx));
    // Still the five from the first.
    await tester.tap(again);
    await _settle(tester);
    expect(
      tester
          .widget<DeckViewerScreen>(find.byType(DeckViewerScreen))
          .initialIndex,
      0,
    );
    await tester.tap(
      find
          .descendant(
            of: find.byType(DeckViewerScreen),
            matching: find.bySemanticsLabel('Close'),
          )
          .first,
    );
    await _settle(tester);
    expect(find.byType(DeckViewerScreen), findsNothing);

    // Switched back from the same row, the row is back over the card.
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    await _scrollTo(tester, row);
    await tester.tap(row);
    await _settle(tester);
    expect(DebugLooks.noTopRow.value, isFalse);
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await _settle(tester);
    expect(name, findsOneWidget);
    expect(tester.getRect(card).height, closeTo(before.height, 0.5));
  });

  test(
    'What to learn\'s look: kept on the phone, read back at the next '
    'start, kept through the wipe, and never read without the tools',
    () async {
      SharedPreferences.setMockInitialValues(_finished());
      debugToolsOn = true;
      await DebugLooks.setLearn(LearnLook.aim);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.debug.learn'), 'aim');

      DebugLooks.reset();
      final AppState app = AppState();
      await app.init();
      expect(DebugLooks.learn.value, LearnLook.aim);
      expect(DebugLooks.learnPicked, LearnLook.aim);

      await app.signOut();
      expect(prefs.getBool('knowit.onboarded'), isNull);
      expect(prefs.getString('knowit.debug.learn'), 'aim');

      debugToolsOn = false;
      expect(DebugLooks.learnPicked, LearnLook.today);

      debugToolsOn = true;
      await DebugLooks.setLearn(LearnLook.today);
      DebugLooks.load(prefs);
      expect(DebugLooks.learn.value, LearnLook.today);
    },
  );

  testWidgets('What to learn\'s look, picked in the debug section, shows at '
      'once: the profile\'s box under the subjects, and the marks on the '
      'day\'s cards', (tester) async {
    debugToolsOn = true;
    SharedPreferences.setMockInitialValues({
      ..._finished(plus: true),
      'knowit.skills': [for (final Skill s in Skill.values) s.name],
    });
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);

    // As it ships: the day's cards carry the marks of the skills picked.
    final Finder marks = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('skill-mark-'),
    );
    expect(marks, findsWidgets);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    final Finder skills = find.byKey(const ValueKey('profile-skills'));
    await _scrollTo(tester, skills);
    expect(skills, findsOneWidget);

    // C: where the reader is strong, in place of the skills picked.
    await _scrollTo(tester, find.byKey(const ValueKey('debug-learn-profile')));
    await tester.tap(find.byKey(const ValueKey('debug-learn-profile')));
    await _settle(tester);
    expect(DebugLooks.learn.value, LearnLook.profile);
    expect(
      (await SharedPreferences.getInstance()).getString('knowit.debug.learn'),
      'profile',
    );
    final Finder strengths = find.byKey(const ValueKey('profile-strengths'));
    await tester.scrollUntilVisible(strengths, -400, scrollable: _profileList);
    expect(strengths, findsOneWidget);
    expect(skills, findsNothing);

    // B: the reader's aim.
    await _scrollTo(tester, find.byKey(const ValueKey('debug-learn-aim')));
    await tester.tap(find.byKey(const ValueKey('debug-learn-aim')));
    await _settle(tester);
    final Finder aim = find.byKey(const ValueKey('profile-aim'));
    await tester.scrollUntilVisible(aim, -400, scrollable: _profileList);
    expect(aim, findsOneWidget);

    // A: nothing under the subjects, and no card carries a skill's mark.
    await _scrollTo(tester, find.byKey(const ValueKey('debug-learn-score')));
    await tester.tap(find.byKey(const ValueKey('debug-learn-score')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('profile-aim')), findsNothing);
    expect(find.byKey(const ValueKey('profile-strengths')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await _settle(tester);
    expect(marks, findsNothing);

    // Now, as it ships, from the same row: the marks are back.
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    await _scrollTo(tester, find.byKey(const ValueKey('debug-learn-today')));
    await tester.tap(find.byKey(const ValueKey('debug-learn-today')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await _settle(tester);
    expect(marks, findsWidgets);
  });

  testWidgets('picked in the debug section, the profile opens on that top at '
      'once, on either plan; Auto is the plan\'s own', (tester) async {
    debugToolsOn = true;
    SharedPreferences.setMockInitialValues(_finished(plus: true));
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('profile-top-board')), findsOneWidget);

    for (final (String pick, String top) in [
      ('a', 'score'),
      ('b', 'week'),
      ('c', 'board'),
      ('auto', 'board'),
    ]) {
      final Finder choice = find.byKey(ValueKey('debug-profile-top-$pick'));
      await _scrollTo(tester, choice);
      // Auto says what it is.
      expect(
        find.bySemanticsLabel('Auto (A free · C Astute+)'),
        findsOneWidget,
      );
      await tester.tap(choice);
      await _settle(tester);
      expect(DebugLooks.profileTop.value.name, pick);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'knowit.debug.profileTop',
        ),
        pick,
      );
      // Back up at the top of the same screen, the top picked.
      final Finder shown = find.byKey(ValueKey('profile-top-$top'));
      await tester.scrollUntilVisible(shown, -400, scrollable: _profileList);
      expect(shown, findsOneWidget, reason: pick);
    }
  });

  testWidgets('the card foot picked in the debug section: A as the app '
      'ships, the one picked lit and kept, and Today\'s cards drawn with it '
      'at once, B saying Why this card on every front', (tester) async {
    debugToolsOn = true;
    SharedPreferences.setMockInitialValues(_reading());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    expect(find.byType(PillCardStack), findsOneWidget);
    final String whyTitle = lookupAppLocalizations(
      const Locale('en'),
    ).whyTitle;
    Map<String, String> notes() =>
        tester.widget<PillCardStack>(find.byType(PillCardStack)).notes;
    expect(notes().values, isNot(contains(whyTitle)));

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    final Finder block = find.byKey(const ValueKey('debug-card-foot'));
    await _scrollTo(tester, block);
    // Under the profile's top, before the readouts, in English.
    expect(
      tester.getRect(block).top,
      greaterThan(
        tester.getRect(find.byKey(const ValueKey('debug-profile-top-c'))).top,
      ),
    );
    expect(find.text('Card foot'), findsOneWidget);
    for (final String said in [
      'A, line',
      'B, two lines',
      'C, buttons',
      'D, links',
    ]) {
      expect(find.bySemanticsLabel(said), findsOneWidget, reason: said);
    }
    void lit(String pick, {bool on = true}) => expect(
      tester.getSemantics(find.byKey(ValueKey('debug-card-foot-$pick'))),
      on
          ? containsSemantics(isSelected: true)
          : isNot(containsSemantics(isSelected: true)),
      reason: pick,
    );
    // A as the app ships.
    lit('a');
    expect(DebugLooks.cardFoot.value, isNull);

    await tester.tap(find.byKey(const ValueKey('debug-card-foot-b')));
    await _settle(tester);
    expect(DebugLooks.cardFoot.value, CardFootPick.b);
    expect(sourceFoot, SourceFoot.stack);
    lit('b');
    lit('a', on: false);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'knowit.debug.cardFoot',
      ),
      'b',
    );

    // Today, without going anywhere else: every card but one about a place
    // says Why this card on its front, or its own reason.
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await _settle(tester);
    final List<Pill> deck = [
      for (final String id in _deck()) PillBank.byId(id)!,
    ];
    expect(
      notes().keys,
      containsAll([
        for (final Pill p in deck)
          if (p.place == null) p.id,
      ]),
    );

    // And back to A from the same row: no front says it any more.
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    await _scrollTo(tester, block);
    await tester.tap(find.byKey(const ValueKey('debug-card-foot-a')));
    await _settle(tester);
    expect(sourceFoot, SourceFoot.line);
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await _settle(tester);
    expect(notes().values, isNot(contains(whyTitle)));
  });
}
