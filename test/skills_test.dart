import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/goals.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/skill_levels.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/skills_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import 'explore/core_harness.dart';

class _Recorder implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Map<String, Object>? last(String event) {
    for (final e in events.reversed) {
      if (e.$1 == event) return e.$2;
    }
    return null;
  }

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

/// The app's own letters, so what fits a phone is measured as it is drawn.
Future<void> _loadRealFonts() async {
  final faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final file = File(face.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(face.key);
    final bytes = await file.readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// What the reader wants to learn and how far they have come in each: asked
/// on the profile, kept on the phone and told to analytics; each skill picks
/// its area of life, which leans the cards picked for the reader and the
/// coach, and shows the reader's level from the cards they read.
void main() {
  late _Recorder sink;

  setUpAll(_loadRealFonts);

  setUp(() {
    sink = _Recorder();
    Analytics.useForTest(sink);
  });

  tearDown(() => Analytics.useForTest(null));

  Future<AppState> open(
    WidgetTester tester, {
    List<String> picked = const [],
    List<String> read = const [],
    Locale locale = const Locale('en'),
  }) async {
    final AppState app = await tester.runAsync(
      () => readyApp({'knowit.skills': picked, 'knowit.seenIds': read}),
    ) as AppState;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SkillsScreen(app: app),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return app;
  }

  Finder tile(Skill s, bool on) =>
      find.byKey(ValueKey('skill-${s.name}-${on ? 'on' : 'off'}'));

  Future<void> tap(WidgetTester tester, Finder f) async {
    // All twelve are on the screen at once; only a text too large for
    // that lets the grid scroll, and then from the top each time.
    final Finder list = find.byType(Scrollable);
    if (list.evaluate().isNotEmpty) {
      tester.state<ScrollableState>(list.first).position.jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(f, 200, scrollable: list.first);
    }
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('every skill is offered by its name, none picked at first', (
    tester,
  ) async {
    await open(tester);
    final l = lookupAppLocalizations(const Locale('en'));
    for (final Skill s in Skill.values) {
      expect(tile(s, false), findsOneWidget, reason: s.name);
      expect(find.text(l.skillName(s.name)), findsOneWidget, reason: s.name);
    }
  });

  Future<void> phone(WidgetTester tester, Size size, double text) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final String language in ['en', 'it']) {
    testWidgets('all twelve fit the smallest phone at once, nothing to '
        'scroll, in $language', (tester) async {
      // An iPhone SE: 375 by 667, under a status bar of 20.
      await phone(tester, const Size(375, 667), 1);
      tester.view.padding = const FakeViewPadding(top: 20);
      tester.view.viewPadding = const FakeViewPadding(top: 20);
      await open(tester, picked: ['money', 'people'], locale: Locale(language));
      expect(find.byType(Scrollable), findsNothing);
      final Rect done = tester.getRect(
        find.byKey(const ValueKey('skills-done')),
      );
      for (final Skill s in Skill.values) {
        final bool on = s == Skill.money || s == Skill.people;
        final Rect r = tester.getRect(tile(s, on));
        expect(r.top, greaterThanOrEqualTo(20), reason: s.name);
        expect(r.bottom, lessThanOrEqualTo(done.top), reason: s.name);
        expect(r.right, lessThanOrEqualTo(375), reason: s.name);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('each skill shows its level and the cards read that made it; '
      'the picked ones are in focus', (tester) async {
    await phone(tester, const Size(402, 874), 1);
    final List<Pill> money = PillBank.cards
        .where(Skill.money.trains)
        .take(12)
        .toList();
    await open(
      tester,
      picked: ['money'],
      read: [for (final Pill p in money) p.id],
    );
    final l = lookupAppLocalizations(const Locale('en'));
    final Map<Skill, int> each = cardsTrainingEach(money.map((p) => p.id));
    for (final Skill s in Skill.values) {
      final SkillLevel level = SkillLevel.of(each[s]!);
      expect(
        find.text('${l.skillLevel(level.level)} · ${l.nCards(level.cards)}'),
        findsWidgets,
        reason: s.name,
      );
    }
    expect(find.text('${l.skillLevel(2)} · ${l.nCards(12)}'), findsWidgets);
    // In focus: the pill on a picked skill's edge, and on no other.
    double focus(Skill s) => tester
        .widget<AnimatedScale>(
          find
              .ancestor(
                of: find.byKey(ValueKey('skill-focus-${s.name}')),
                matching: find.byType(AnimatedScale),
              )
              .first,
        )
        .scale;
    expect(focus(Skill.money), 1);
    for (final Skill s in Skill.values.where((s) => s != Skill.money)) {
      expect(focus(s), 0, reason: s.name);
    }
    await tap(tester, tile(Skill.focus, false));
    expect(focus(Skill.focus), 1);
    expect(tester.takeException(), isNull);
  });

  for (final String language in ['en', 'de', 'ru', 'ja']) {
    testWidgets('at twice the text on a small phone the grid scrolls, '
        'nothing spills, in $language', (tester) async {
      await phone(tester, const Size(320, 640), 2);
      final AppState app = await tester.runAsync(
        () => readyApp({
          'knowit.skills': <String>['talk'],
        }),
      ) as AppState;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: SkillsScreen(app: app),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
    });
  }

  testWidgets('a tap picks a skill and keeps it; a second lets it go', (
    tester,
  ) async {
    final AppState app = await open(tester);
    await tap(tester, tile(Skill.money, false));
    expect(app.skills, ['money']);
    expect(tile(Skill.money, true), findsOneWidget);
    await tap(tester, tile(Skill.critical, false));
    expect(app.skills, ['money', 'critical']);
    await tap(tester, tile(Skill.money, true));
    expect(app.skills, ['critical']);
    final SharedPreferences prefs = await tester.runAsync(
      SharedPreferences.getInstance,
    ) as SharedPreferences;
    expect(prefs.getStringList('knowit.skills'), ['critical']);
  });

  testWidgets('the skills picked are the areas the cards lean towards', (
    tester,
  ) async {
    final AppState app = await open(tester);
    await tap(tester, tile(Skill.science, false));
    await tap(tester, tile(Skill.persuade, false));
    await tap(tester, tile(Skill.fakes, false));
    // Two skills of one area count once, in the order first picked.
    expect(app.goals, ['news', 'people']);
    await tap(tester, tile(Skill.culture, false));
    await tap(tester, tile(Skill.money, false));
    await tap(tester, tile(Skill.focus, false));
    // Three areas at most; general knowledge is no area.
    expect(app.goals, ['news', 'people', 'money']);
    for (final Skill s in [
      Skill.science,
      Skill.persuade,
      Skill.fakes,
      Skill.money,
      Skill.focus,
    ]) {
      await tap(tester, tile(s, true));
    }
    expect(app.skills, ['culture']);
    expect(app.goals, isEmpty);
    final SharedPreferences prefs = await tester.runAsync(
      SharedPreferences.getInstance,
    ) as SharedPreferences;
    expect(prefs.getStringList('knowit.goals'), isEmpty);
  });

  testWidgets('skills picked before they did anything pick their areas', (
    tester,
  ) async {
    final AppState fresh = await tester.runAsync(
      () => readyApp({
        'knowit.skills': ['lead', 'decisions', 'critical'],
      }),
    ) as AppState;
    expect(fresh.goals, ['business', 'decide']);
    // What the reader said they want stays what they said.
    final AppState said = await tester.runAsync(
      () => readyApp({
        'knowit.skills': ['lead'],
        'knowit.goals': ['health'],
      }),
    ) as AppState;
    expect(said.goals, ['health']);
  });

  test('every skill but general knowledge serves an area that exists', () {
    for (final Skill s in Skill.values) {
      if (s == Skill.culture) {
        expect(s.area, isNull);
      } else {
        expect(Goal.of(s.area!), isNotNull, reason: s.name);
      }
    }
  });

  testWidgets('what a build does not know is dropped', (tester) async {
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.skills': ['fakes', 'juggling', 'fakes', 'focus'],
      }),
    ) as AppState;
    expect(app.skills, ['fakes', 'focus']);
  });

  testWidgets('leaving says once what changed, and nothing when nothing did', (
    tester,
  ) async {
    await open(tester, picked: const ['lead']);
    await tap(tester, tile(Skill.science, false));
    await tester.tap(find.byKey(const ValueKey('skills-done')));
    await tester.pumpAndSettle();
    expect(sink.events.where((e) => e.$1 == 'skills saved'), hasLength(1));
    expect(sink.last('skills saved'), {
      'skills': 'lead,science',
      'count': 2,
      'added': 1,
      'removed': 0,
    });

    sink.events.clear();
    await open(tester, picked: const ['lead']);
    await tester.tap(find.byKey(const ValueKey('skills-done')));
    await tester.pumpAndSettle();
    expect(sink.last('skills saved'), isNull);
  });
}
