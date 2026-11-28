// Photographs the reminder sheet (lib/widgets/reminder_ask.dart) as it rises
// over a finished day, for a reader who reads in the evening: at night and
// on paper, as it opens (remind-dark-1, remind-light-1), once Morning is
// picked (-2) and once a time of the reader's own is, 21:45 on the phone's
// clock (-3), on an iPhone; as it opens on an Android phone
// (remind-android-dark, remind-android-light); and on the 320-wide phone in
// German, at the ordinary text size and at 1.6×, as it opens and scrolled
// to its foot (remind-de-small, remind-de-small-large, and -end for each).
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/reminder_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real app, on a 390 × 844 phone, with the day read and the sheet risen over
// its shelf, and its shadows soft, as a phone draws them (the test's own
// binding draws them hard). SHOTS is where the pictures go (tool/shots by
// default); LANG_SHOT is the phone's language, English when not given.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/sync/push.dart';

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

/// The system's notification prompt, there to be put: the sheet rises only
/// where one stands behind it.
class _Asker extends Push {
  @override
  bool get canAsk => true;

  @override
  Future<String?> ask() async => 'token-a';

  @override
  Future<String?> refresh() async => null;
}

/// A reader back for a second day, today's five read a little after seven
/// in the evening, as yesterday's were: the sheet opens on the evening.
Map<String, Object> _reader(String theme) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String day(int back) => dateKey(today.subtract(Duration(days: back)));
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    'knowit.streak': 2,
    'knowit.bestStreak': 2,
    'knowit.lastCompletionDate': day(0),
    'knowit.completedDates': [day(1), day(0)],
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': dealDay(date: now).cards
        .take(kPillsPerDay)
        .map((p) => p.id)
        .toList(),
    'knowit.todayIndex': kPillsPerDay,
    'knowit.readStarts': '{"${day(1)}":1150,"${day(0)}":1165}',
    'knowit.theme': theme,
  };
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
  });

  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'en');

  setUp(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    // A European phone's clock: 19:00, and 21:45 typed into it. Set before
    // the view below, whose change is what the app's reading of the phone
    // is taken again on.
    dispatcher.alwaysUse24HourFormatTestValue = true;
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    // An iPhone's notch and home bar, so the sheet sits where it would.
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

  /// The sheet's pictures — the app's icon on the notification — read off
  /// the disk for real, which the test's clock alone never finishes. Only
  /// the sheet's: a card's picture behind it waits on a network there is
  /// none of here.
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

  /// The app open on the finished day, and the sheet risen over its shelf
  /// a beat later, on [platform]'s phone.
  Future<void> rise(
    WidgetTester tester, {
    required String theme,
    TargetPlatform platform = TargetPlatform.iOS,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    // Shadows blurred, as on a phone: the light under the ground and under
    // the tile picked is a glow, not a band.
    debugDisableShadows = false;
    _prefs(_reader(theme));
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    // The beat before the sheet, and its rise.
    await settle(tester, frames: 40);
    expect(find.byKey(const ValueKey('reminder-ask')), findsOneWidget);
    await pictures(tester);
  }

  Future<void> leave(WidgetTester tester) async {
    // Gone with the app, so nothing of it outlives the platform it was on.
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  }

  /// The sheet scrolled to its foot.
  Future<void> foot(WidgetTester tester) async {
    final ScrollPosition position = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const ValueKey('reminder-ask')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    position.jumpTo(position.maxScrollExtent);
    await settle(tester);
  }

  /// A time of the reader's own picked on the phone's clock: [hour] and
  /// [minute], typed.
  Future<void> own(WidgetTester tester, String hour, String minute) async {
    await tester.tap(find.byKey(const ValueKey('reminder-at-own')));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(0), hour);
    await tester.enterText(find.byType(TextField).at(1), minute);
    final String ok = MaterialLocalizations.of(
      tester.element(find.byType(TimePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await settle(tester);
  }

  // As it opens, on the evening the reader reads at; once Morning is
  // picked; and once a time of the reader's own is: at night and on paper.
  for (final String theme in ['dark', 'light']) {
    testWidgets('remind-$theme', (tester) async {
      await rise(tester, theme: theme);
      await shoot('remind-$theme-1');
      await tester.tap(find.byKey(const ValueKey('reminder-at-08:30')));
      await settle(tester);
      await shoot('remind-$theme-2');
      await own(tester, '21', '45');
      await shoot('remind-$theme-3');
      await leave(tester);
    });
  }

  // On an Android phone.
  for (final String theme in ['dark', 'light']) {
    testWidgets('remind-android-$theme', (tester) async {
      await rise(tester, theme: theme, platform: TargetPlatform.android);
      await shoot('remind-android-$theme');
      await leave(tester);
    });
  }

  // The 320-wide phone, no notch, in German: at the ordinary text size and
  // at 1.6×, the sheet's top as it rises and its foot.
  for (final double text in [1, 1.6]) {
    final String name = 'remind-de-small${text == 1 ? '' : '-large'}';
    testWidgets(name, (tester) async {
      final dispatcher = tester.platformDispatcher;
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.padding = const FakeViewPadding(top: 20 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
      dispatcher.localeTestValue = const Locale('de');
      dispatcher.localesTestValue = [const Locale('de')];
      dispatcher.textScaleFactorTestValue = text;
      addTearDown(dispatcher.clearTextScaleFactorTestValue);
      await rise(tester, theme: Platform.environment['THEME'] ?? 'dark');
      await shoot(name);
      await foot(tester);
      await shoot('$name-end');
      await leave(tester);
    });
  }
}
