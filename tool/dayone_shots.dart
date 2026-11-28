// Photographs a new reader's first week where it speaks: the top of Today on
// the second morning, which says which day it is and how the first went
// (day2-dark, day2-light; day2-de-small on the 320-wide phone in German);
// the morning after a freeze kept the streak (freeze-dark, freeze-light); the
// streak's moment at two days, over the finished day (streak-dark,
// streak-light), and the shelf under it once it has gone, which says one
// missed day is covered (shelf-dark, shelf-light); and Go deeper on the
// first card, its source the paper with the video beside it as Watch more
// (deeper-dark, deeper-light). It also writes, to deals.txt, the cards the
// first week deals on its days one to seven, with which are drawn.
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/dayone_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real app on a 390 × 844 iPhone, with its shadows soft, as a phone draws
// them. SHOTS is where the pictures go (tool/shots by default); LANG_SHOT is
// the phone's language, English when not given.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/first_days.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/deeper_sheet.dart';
import 'package:astuto/widgets/streak_moment.dart';

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

DateTime _today() {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _day(int back) => dateKey(_today().subtract(Duration(days: back)));

/// A new reader on their second morning: the first day's five read
/// yesterday, two of its questions right of two, 70% and 90% sure.
Map<String, Object> _secondMorning(String theme) => {
  'knowit.onboarded': true,
  'knowit.firstDays': true,
  'knowit.streak': 1,
  'knowit.bestStreak': 1,
  'knowit.lastCompletionDate': _day(1),
  'knowit.completedDates': <String>[_day(1)],
  'knowit.seenIds': <String>[
    for (final FirstCard c in kFirstDays)
      if (c.day == 1) c.id,
  ],
  'knowit.judgements': jsonEncode([
    {'c': 70, 'k': true, 'p': 'food-estimated-weight-mark', 'd': _day(1)},
    {'c': 90, 'k': true, 'p': 'psychology-stroop-other-way', 'd': _day(1)},
  ]),
  'knowit.theme': theme,
};

/// A reader of five days who missed yesterday, one freeze held: it is
/// spent on this morning, and the streak goes on.
Map<String, Object> _afterFreeze(String theme) => {
  'knowit.onboarded': true,
  'knowit.streak': 5,
  'knowit.bestStreak': 5,
  'knowit.lastCompletionDate': _day(2),
  'knowit.completedDates': <String>[for (int b = 6; b >= 2; b--) _day(b)],
  'knowit.freezes': 1,
  'knowit.theme': theme,
};

/// A new reader whose second day is read, a freeze held.
Map<String, Object> _secondEvening(String theme) => {
  'knowit.onboarded': true,
  'knowit.firstDays': true,
  'knowit.streak': 2,
  'knowit.bestStreak': 2,
  'knowit.lastCompletionDate': _day(0),
  'knowit.completedDates': <String>[_day(1), _day(0)],
  'knowit.todayDate': _day(0),
  'knowit.todayDeckIds': <String>[
    for (final FirstCard c in kFirstDays)
      if (c.day == 2) c.id,
  ],
  'knowit.todayIndex': kPillsPerDay,
  'knowit.freezes': 1,
  'knowit.theme': theme,
};

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
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    // An iPhone's notch and home bar.
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
  });

  Future<void> settle(WidgetTester tester, {int frames = 14}) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$out/$name.png'),
  );

  Future<void> open(WidgetTester tester, Map<String, Object> prefs) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Shadows blurred, as on a phone.
    debugDisableShadows = false;
    _prefs(prefs);
    await tester.pumpWidget(const AstutoApp());
    await settle(tester, frames: 30);
  }

  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  }

  for (final String theme in ['dark', 'light']) {
    testWidgets('day2-$theme', (tester) async {
      await open(tester, _secondMorning(theme));
      expect(find.byKey(const ValueKey('today-line')), findsOneWidget);
      await shoot('day2-$theme');
      await leave(tester);
    });

    testWidgets('freeze-$theme', (tester) async {
      await open(tester, _afterFreeze(theme));
      expect(find.byKey(const ValueKey('today-line')), findsOneWidget);
      await shoot('freeze-$theme');
      await leave(tester);
    });

    testWidgets('streak-$theme', (tester) async {
      await open(tester, _secondEvening(theme));
      // The moment as it rises on the evening the day is read: pushed here
      // over the finished day, as the day's end pushes it.
      final NavigatorState nav = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        nav.push(StreakMomentScreen.route(days: 2, freezes: 1, plus: false)),
      );
      await settle(tester, frames: 30);
      expect(find.byKey(const ValueKey('streak-moment')), findsOneWidget);
      await shoot('streak-$theme');
      nav.pop();
      await settle(tester, frames: 20);
      await shoot('shelf-$theme');
      await leave(tester);
    });

    testWidgets('deeper-$theme', (tester) async {
      debugDisableShadows = false;
      _prefs({'knowit.onboarded': true});
      final AppState app = AppState();
      await tester.runAsync(app.init);
      final Pill pill = PillBank.byId('nature-half-mountain-tsunami')!;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(
            theme == 'dark' ? Brightness.dark : Brightness.light,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDeeperSheet(context, app, pill),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester, frames: 40);
      // Down to the source, where Watch more is.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('deeper-watch')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await settle(tester, frames: 20);
      await shoot('deeper-$theme');
      await tester.pumpWidget(const SizedBox());
      debugDisableShadows = true;
    });
  }

  testWidgets('day2-de-small', (tester) async {
    final dispatcher = tester.platformDispatcher;
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.padding = const FakeViewPadding(top: 20 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
    dispatcher.localeTestValue = const Locale('de');
    dispatcher.localesTestValue = [const Locale('de')];
    await open(tester, _secondMorning('dark'));
    expect(find.byKey(const ValueKey('today-line')), findsOneWidget);
    await shoot('day2-de-small');
    await leave(tester);
  });

  // What the first week deals on days one to seven to a reader who leaned
  // nowhere, read each day: its cards in order, each marked drawn or not
  // and what it asks.
  test('deals', () async {
    final StringBuffer said = StringBuffer();
    final List<String> read = [];
    for (int day = 0; day < 7; day++) {
      final DateTime now = _today().add(Duration(hours: 9 + day * 24));
      final List<String> done = [
        for (int b = day; b >= 1; b--) dateKey(now.subtract(Duration(days: b))),
      ];
      _prefs({
        'knowit.onboarded': true,
        'knowit.firstDays': true,
        'knowit.streak': day,
        'knowit.bestStreak': day,
        if (done.isNotEmpty) 'knowit.lastCompletionDate': done.last,
        'knowit.completedDates': done,
        'knowit.seenIds': read,
      });
      final AppState app = AppState(clock: () => now);
      await app.init();
      said.writeln('day ${day + 1} (${dateKey(now)}):');
      for (final Pill p in app.todaysDeck.take(kPillsPerDay)) {
        final String kind = switch (p.challenge) {
          NoChallenge() => 'read',
          _ => 'asks',
        };
        said.writeln('  ${p.id}\t${p.web != null ? 'drawn' : 'words'}\t$kind');
        read.add(p.id);
      }
    }
    Directory(out).createSync(recursive: true);
    File('$out/deals.txt').writeAsStringSync(said.toString());
  });
}
