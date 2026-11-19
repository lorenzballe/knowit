import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
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

/// What the reader wants to learn: asked on the profile, kept on the phone
/// and told to analytics, changing nothing in the app.
void main() {
  late _Recorder sink;

  setUp(() {
    sink = _Recorder();
    Analytics.useForTest(sink);
  });

  tearDown(() => Analytics.useForTest(null));

  Future<AppState> open(
    WidgetTester tester, {
    List<String> picked = const [],
  }) async {
    final AppState app = await tester.runAsync(
      () => readyApp({'knowit.skills': picked}),
    ) as AppState;
    await tester.pumpWidget(
      MaterialApp(
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
    // From the top each time: a tile above the fold is not found by
    // scrolling on down.
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('every skill is offered by its name, none picked at first', (
    tester,
  ) async {
    await open(tester);
    final l = lookupAppLocalizations(const Locale('en'));
    for (final Skill s in Skill.values) {
      await tester.scrollUntilVisible(
        tile(s, false),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l.skillName(s.name)), findsOneWidget, reason: s.name);
    }
  });

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
