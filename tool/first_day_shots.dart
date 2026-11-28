// Photographs the end of a reader's first day (lib/widgets/first_day.dart)
// in the real app, the fifth card thrown on an iPhone, at night and on
// paper:
//
// * as it ships, celebrated: the celebration with the cards' how-sure
//   answers (after-dark-1, after-light-1) and without them (after-dark-1b,
//   after-light-1b); the reminder sheet risen from it (-2); the time set,
//   in the button's place (-3); the card that offers Astute+, there once
//   it has gone (-4); and Explore at its top, where Today's challenge
//   takes the reader (-5);
// * as it was before, the developer tools' look: the card that offers
//   Astute+ at once (before-dark-1, before-light-1), the shelf once it is
//   thrown (-2), the reminder sheet over the shelf (-3);
// * the celebration on the 320-wide phone in German, at the ordinary text
//   size and at 1.6× (first-day-de-small, first-day-de-small-large).
//
//   SHOTS=/some/folder flutter test tool/first_day_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// phone speaks Italian (LANG_SHOT moves it); SHOTS is where the pictures go
// (tool/shots by default).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/sync/push.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/flutter_test_config.dart' show NoPicture;

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

void _prefs(Map<String, Object> values) {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(values);
}

void _push(Push push) {
  // ignore: invalid_use_of_visible_for_testing_member
  Push.useForTest(push);
}

/// The system's notification prompt, there to be put, and answered yes.
class _Asker extends Push {
  @override
  bool get canAsk => true;

  @override
  Future<String?> ask() async => 'token-a';

  @override
  Future<String?> refresh() async => null;
}

/// A new reader on the free plan, on their first day, four of its five
/// read a little after seven in the evening and four answers given, three
/// right; said how sure on each when [sure], and on none otherwise.
Map<String, Object> _reader(String theme, {bool sure = true}) {
  final DateTime now = DateTime.now();
  final String today = dateKey(DateTime(now.year, now.month, now.day));
  final List<String> five = dealDay(
    date: now,
  ).cards.take(kPillsPerDay).map((p) => p.id).toList();
  final List<Pill> answered = PillBank.cards
      .where((p) => p.isGraded && p.difficulty == Difficulty.medium)
      .where((p) => !five.contains(p.id))
      .take(4)
      .toList();
  const List<bool> right = [true, true, false, true];
  const List<int> said = [80, 70, 60, 70];
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    'knowit.todayDate': today,
    'knowit.todayDeckIds': five,
    'knowit.todayIndex': kPillsPerDay - 1,
    'knowit.seenIds': five.take(kPillsPerDay - 1).toList(),
    'knowit.readStarts': '{"$today":1145}',
    'knowit.judgements': jsonEncode([
      for (var i = 0; i < answered.length; i++)
        {
          'c': sure ? said[i] : null,
          'k': right[i],
          'p': answered[i].id,
          'd': today,
        },
    ]),
    'knowit.theme': theme,
  };
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // A card's picture fails at once, as under test, so a card on the shelf
    // is drawn as it is without one rather than waiting, grey, on a network
    // there is none of here.
    CardThumb.image = NoPicture.new;
  });

  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');

  setUp(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    // A European phone's clock.
    dispatcher.alwaysUse24HourFormatTestValue = true;
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    // An iPhone's notch and home bar.
    view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    dispatcher.localeTestValue = locale;
    dispatcher.localesTestValue = [locale];
    _push(_Asker());
  });

  tearDown(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.views.first.reset();
    dispatcher.clearLocaleTestValue();
    dispatcher.clearLocalesTestValue();
    dispatcher.clearAlwaysUse24HourTestValue();
    _push(Push());
    debugToolsOn = false;
    // ignore: invalid_use_of_visible_for_testing_member
    DebugLooks.reset();
  });

  Future<void> settle(WidgetTester tester, {int frames = 14}) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$out/$name.png'),
  );

  /// The reminder sheet's pictures, read off the disk for real.
  Future<void> pictures(WidgetTester tester) async {
    final List<Element> marks = find
        .descendant(
          of: find.byKey(const ValueKey('reminder-ask')),
          matching: find.byType(Image),
        )
        .evaluate()
        .toList();
    await tester.runAsync(() async {
      for (final Element e in marks) {
        await precacheImage(
          (e.widget as Image).image,
          e,
        ).timeout(const Duration(seconds: 10), onTimeout: () {});
      }
    });
    await settle(tester, frames: 4);
  }

  /// The card on top of the deck, thrown from its question.
  Future<void> fling(WidgetTester tester) async {
    final Rect deck = tester.getRect(find.byType(PillCardStack));
    await tester.flingFrom(
      Offset(deck.center.dx, deck.top + 90),
      const Offset(-320, 0),
      900,
    );
  }

  /// The app open on the last of the first day's five, with soft shadows
  /// as a phone draws them.
  Future<void> open(
    WidgetTester tester, {
    required String theme,
    bool sure = true,
    bool asBefore = false,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    debugDisableShadows = false;
    debugToolsOn = asBefore;
    _prefs({
      ..._reader(theme, sure: sure),
      if (asBefore) 'knowit.debug.firstDayEnd': 'asBefore',
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester, frames: 20);
  }

  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  }

  for (final String theme in ['dark', 'light']) {
    testWidgets('after-$theme', (tester) async {
      await open(tester, theme: theme);
      await fling(tester);
      // The throw, the beat, the rise, the points counted.
      await settle(tester, frames: 36);
      expect(find.byKey(const ValueKey('first-day')), findsOneWidget);
      await shoot('after-$theme-1');
      await tester.tap(find.byKey(const ValueKey('first-day-remind')));
      await settle(tester, frames: 16);
      expect(find.byKey(const ValueKey('reminder-ask')), findsOneWidget);
      await pictures(tester);
      await shoot('after-$theme-2');
      await tester.tap(find.byKey(const ValueKey('reminder-yes')));
      await settle(tester, frames: 16);
      await shoot('after-$theme-3');
      await tester.tap(find.byKey(const ValueKey('first-day-close')));
      await settle(tester, frames: 16);
      expect(find.byKey(const ValueKey('magic-card')), findsOneWidget);
      await shoot('after-$theme-4');
      await leave(tester);
    });

    testWidgets('after-$theme-nosure', (tester) async {
      await open(tester, theme: theme, sure: false);
      await fling(tester);
      await settle(tester, frames: 36);
      await shoot('after-$theme-1b');
      await leave(tester);
    });

    // Today's challenge, from the celebration: Explore at its top.
    testWidgets('after-$theme-challenge', (tester) async {
      await open(tester, theme: theme);
      await fling(tester);
      await settle(tester, frames: 36);
      await tester.tap(find.byKey(const ValueKey('first-day-challenge')));
      await settle(tester, frames: 24);
      expect(find.byKey(const ValueKey('first-day')), findsNothing);
      await shoot('after-$theme-5');
      await leave(tester);
    });

    testWidgets('before-$theme', (tester) async {
      await open(tester, theme: theme, asBefore: true);
      await fling(tester);
      await settle(tester, frames: 24);
      expect(find.byKey(const ValueKey('first-day')), findsNothing);
      expect(find.byKey(const ValueKey('magic-card')), findsOneWidget);
      await shoot('before-$theme-1');
      await fling(tester);
      // The shelf landed, before the sheet's beat is over.
      await settle(tester, frames: 15);
      await shoot('before-$theme-2');
      await settle(tester, frames: 40);
      expect(find.byKey(const ValueKey('reminder-ask')), findsOneWidget);
      await pictures(tester);
      await shoot('before-$theme-3');
      await leave(tester);
    });
  }

  // The 320-wide phone, no notch, in German: at the ordinary text size and
  // at 1.6×.
  for (final double text in [1, 1.6]) {
    final String name = 'first-day-de-small${text == 1 ? '' : '-large'}';
    testWidgets(name, (tester) async {
      final dispatcher = tester.platformDispatcher;
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.padding = const FakeViewPadding(top: 20 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
      dispatcher.localeTestValue = const Locale('de');
      dispatcher.localesTestValue = [const Locale('de')];
      dispatcher.textScaleFactorTestValue = text;
      addTearDown(dispatcher.clearTextScaleFactorTestValue);
      await open(tester, theme: Platform.environment['THEME'] ?? 'dark');
      await fling(tester);
      await settle(tester, frames: 36);
      await shoot(name);
      await leave(tester);
    });
  }
}
