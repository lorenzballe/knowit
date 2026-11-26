// The top of the profile (lib/widgets/profile_top.dart): the Astute score on
// either plan, read exactly as Your journey reads it; the way into the
// journey, which says Astute+ on the free plan and has no lock; the tile
// back to Today's five; and Today opening out of that tile
// (lib/widgets/tab_zoom.dart), or dissolving in for a reader who asked for
// less motion.
//
//   flutter test test/profile_top_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/premium.dart';
import 'package:astuto/widgets/profile_top.dart';
import 'package:astuto/widgets/skill_score.dart';
import 'package:astuto/widgets/tab_zoom.dart';

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

/// A reader a week in, [read] of today's five read: graded answers on the
/// days before, right two times in three, so the score has moved.
Map<String, Object> _prefs({bool plus = false, int read = 3}) {
  final DateTime now = DateTime.now();
  String day(int back) => dateKey(now.subtract(Duration(days: back)));
  final List<Pill> asking = [
    for (final Pill p in PillBank.cards)
      if (p.isGraded) p,
  ].take(18).toList();
  final List<String> deck = dealDay(date: now).cards
      .take(kPillsPerDay)
      .map((p) => p.id)
      .toList();
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.streak': 6,
    'knowit.lastCompletionDate': day(read >= kPillsPerDay ? 0 : 1),
    'knowit.completedDates': [
      for (int back = 6; back >= 1; back--) day(back),
      if (read >= kPillsPerDay) day(0),
    ],
    'knowit.seenIds': [...asking.map((p) => p.id), ...deck.take(read)],
    'knowit.judgements': jsonEncode([
      for (final (int i, Pill p) in asking.indexed)
        {'c': 70, 'k': i % 3 != 0, 'p': p.id, 'd': day(1 + i ~/ 3)},
    ]),
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': read,
  };
}

Future<AppState> _app(WidgetTester tester, {bool plus = false}) async {
  SharedPreferences.setMockInitialValues(_prefs(plus: plus));
  final AppState app = AppState();
  await app.init();
  await tester.pump();
  return app;
}

Account _account() =>
    Account(uidOverride: 'me', boardsOverride: MemoryBoardStore());

Widget _host(
  AppState app, {
  Locale locale = const Locale('en'),
  ValueChanged<Rect?>? onToday,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    body: ProfileScreen(
      app: app,
      account: _account(),
      onSignedOut: () {},
      onToday: onToday,
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Whether the bar's tab named [label] is the one lit.
bool _onTab(WidgetTester tester, String label) =>
    tester
        .widget<Semantics>(
          find.byKey(ValueKey('tab-$label'), skipOffstage: false),
        )
        .properties
        .selected ??
    false;

void main() {
  setUpAll(_loadRealFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
    profileTopForShots = null;
  });

  testWidgets('the score is the journey\'s own number, on either plan', (
    tester,
  ) async {
    for (final bool plus in [false, true]) {
      final AppState app = await _app(tester, plus: plus);
      await tester.pumpWidget(_host(app));
      await _settle(tester);
      final BuildContext context = tester.element(find.byType(ProfileScreen));
      final String score = scoreNumber(context, scoreBookOf(app).overall.now);
      // The answers moved it, so this is a number the reader made.
      expect(scoreBookOf(app).overall.answers, greaterThan(0));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profile-score')),
          matching: find.textContaining(score),
          matchRoot: true,
        ),
        findsOneWidget,
        reason: plus ? 'Astute+' : 'free',
      );
      // The way into the journey says Astute+ on the free plan, and never
      // carries a lock: the score is the reader's, whole.
      final Finder journey = find.byKey(const ValueKey('profile-journey'));
      expect(journey, findsOneWidget);
      expect(
        find.descendant(
          of: journey,
          matching: find.byKey(const ValueKey('profile-journey-plus')),
        ),
        plus ? findsNothing : findsOneWidget,
      );
      expect(
        find.descendant(of: journey, matching: find.byType(PlusLock)),
        findsNothing,
      );
    }
  });

  testWidgets('the way into the journey: the plans, or the journey', (
    tester,
  ) async {
    for (final bool plus in [false, true]) {
      // A fresh app each time: the plans pushed for the free reader would
      // otherwise still be on top.
      await tester.pumpWidget(const SizedBox.shrink());
      final AppState app = await _app(tester, plus: plus);
      await tester.pumpWidget(_host(app));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('profile-journey')));
      await _settle(tester);
      expect(find.byType(PaywallScreen), plus ? findsNothing : findsOneWidget);
      expect(find.byType(JourneyScreen), plus ? findsOneWidget : findsNothing);
    }
  });

  testWidgets('the today tile says where it is, and what is left', (
    tester,
  ) async {
    final AppState app = await _app(tester);
    Rect? asked;
    await tester.pumpWidget(_host(app, onToday: (at) => asked = at));
    await _settle(tester);
    // Three of five: the count, not the day said twice.
    expect(find.byKey(const ValueKey('profile-today-count')), findsOneWidget);
    expect(find.text('3 of 5'), findsOneWidget);
    expect(find.textContaining('all read'), findsNothing);
    final Finder tile = find.byKey(const ValueKey('profile-today'));
    await tester.tap(tile);
    expect(asked, tester.getRect(tile));
  });

  testWidgets('every top lays out, free and Astute+, in long languages', (
    tester,
  ) async {
    // The narrowest phone the app is laid out for, at the text size most
    // readers have and one size up.
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .views
        .first
        .physicalSize = const Size(
      320,
      640,
    );
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final ProfileTop top in ProfileTop.values) {
      profileTopForShots = top;
      for (final bool plus in [false, true]) {
        final AppState app = await _app(tester, plus: plus);
        for (final String language in ['en', 'de', 'ru', 'fr', 'ja']) {
          for (final double scale in [1.0, 1.3]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            await tester.pumpWidget(_host(app, locale: Locale(language)));
            await tester.pump(const Duration(milliseconds: 300));
            expect(
              tester.takeException(),
              isNull,
              reason: '${top.name} ${plus ? 'plus' : 'free'} $language $scale',
            );
          }
        }
      }
    }
  });

  testWidgets('Today opens out of the tile, and the move leaves nothing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_prefs());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    expect(_onTab(tester, 'Profile'), isTrue);

    await tester.tap(find.byKey(const ValueKey('profile-today')));
    await tester.pump();
    final TabZoomState zoom = tester.state(find.byType(TabZoom));
    expect(zoom.moving, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    // Half way: Today in a rounded frame, growing; the profile a picture
    // behind it.
    final ClipPath frame = tester.widget(
      find
          .descendant(of: find.byType(TabZoom), matching: find.byType(ClipPath))
          .first,
    );
    expect(frame.clipBehavior, Clip.antiAlias);
    expect(zoom.moving, isTrue);

    await tester.pump(TabZoom.open);
    await tester.pump();
    expect(zoom.moving, isFalse);
    expect(_onTab(tester, 'Today'), isTrue);
    final ClipPath rest = tester.widget(
      find
          .descendant(of: find.byType(TabZoom), matching: find.byType(ClipPath))
          .first,
    );
    expect(rest.clipBehavior, Clip.none);
  });

  testWidgets('a tab tapped while Today opens lands the move at once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_prefs());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('profile-today')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final TabZoomState zoom = tester.state(find.byType(TabZoom));
    expect(zoom.moving, isTrue);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await tester.pump();
    expect(zoom.moving, isFalse);
    await _settle(tester);
    expect(_onTab(tester, 'Explore'), isTrue);
  });

  testWidgets('less motion: Today dissolves in, nothing grows', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(_prefs());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('profile-today')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final TabZoomState zoom = tester.state(find.byType(TabZoom));
    expect(zoom.moving, isTrue);
    final ClipPath frame = tester.widget(
      find
          .descendant(of: find.byType(TabZoom), matching: find.byType(ClipPath))
          .first,
    );
    expect(frame.clipBehavior, Clip.none, reason: 'no frame grows');
    // The bar's light is already on Today: it does not travel either.
    expect(_onTab(tester, 'Today'), isTrue);

    await tester.pump(TabZoom.dissolve);
    await tester.pump();
    expect(zoom.moving, isFalse);
  });
}
