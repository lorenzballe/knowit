// Photographs the moment a level of the Astute score is reached
// (lib/widgets/level_up.dart): the take at three moments — the count
// beginning, the light passing across the name, at rest — the same at rest
// in Italian for a first level, the sheet that sends it, and the level, small,
// in Your journey.
//
//   flutter test tool/level_up_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. SHOTS
// (a folder) moves it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/levels.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/level_up.dart';

import '../test/explore/core_harness.dart';

final String _out = Platform.environment['SHOTS'] ?? 'shots/levelup';

/// A reader four weeks in, three answers a day, right seven times in ten.
Map<String, Object> _reader() {
  final List<Pill> cards = PillBank.cards
      .where((p) => p.isGraded)
      .take(3 * 28)
      .toList();
  const List<bool> pattern = [
    true, true, false, true, true, false, true, false, true, true, //
  ];
  final DateTime now = DateTime.now();
  return {
    'knowit.plus': true,
    'knowit.skills': ['numbers', 'critical'],
    'knowit.judgements': jsonEncode([
      for (var k = 0; k < cards.length; k++)
        {
          'c': null,
          'k': pattern[k % pattern.length],
          'p': cards[k].id,
          'd': dateKey(DateTime(now.year, now.month, now.day - 27 + k ~/ 3)),
        },
    ]),
  };
}

void main() {
  setUpAll(loadFonts);

  Future<void> phone(WidgetTester tester) async {
    final view = tester.view;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    view.padding = const FakeViewPadding(top: 47.0 * 3, bottom: 34.0 * 3);
    view.viewPadding = view.padding;
    addTearDown(view.reset);
  }

  Widget app(Widget home, {String language = 'en', bool dark = true}) =>
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
        debugShowCheckedModeBanner: false,
        home: home,
      );

  Future<void> shot(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_out/$name.png'),
  );

  testWidgets('the take', (tester) async {
    await phone(tester);
    const LevelMoment judgement = LevelMoment(
      level: 3,
      score: 158,
      from: 141,
      answers: 186,
      skill: Skill.numbers,
      gain: 34,
    );
    await tester.pumpWidget(app(const LevelUpScreen(moment: judgement)));
    Future<void> at(int ms) async {
      for (var i = 0; i < ms ~/ 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await at(700);
    await shot('levelup-1-count');
    await at(900);
    await shot('levelup-2-light');
    await at(1900);
    await shot('levelup-3-rest');

    // The sheet that sends it.
    await tester.tap(find.byKey(const ValueKey('level-up-share')));
    await tester.pumpAndSettle();
    await shot('levelup-5-share');

    // A first level, in Italian, at rest.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      app(
        const LevelUpScreen(
          moment: LevelMoment(
            level: 1,
            score: 31,
            from: 18,
            answers: 12,
            skill: Skill.critical,
            gain: 19,
          ),
        ),
        language: 'it',
      ),
    );
    await at(3600);
    await shot('levelup-4-it');
  });

  testWidgets('the level, small, in Your journey', (tester) async {
    await phone(tester);
    final AppState reader = await readyApp(_reader());
    // Told already: the journey opens with nothing to tell.
    await LevelMemory.keep(levelStandingOf(reader, null).reached);
    for (final bool dark in const [true, false]) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        app(
          JourneyScreen(key: ValueKey(dark), app: reader, onBack: () {}),
          dark: dark,
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The first chapter: the score, the skills, and under them the level,
      // near the foot of the screen.
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('level-line')),
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.pump();
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('level-line'))),
        alignment: 0.92,
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await shot('levelup-6-journey${dark ? '' : '-light'}');
    }
  });
}
