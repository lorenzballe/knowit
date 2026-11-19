// The app on an iPhone simulator, for photographs of what only iOS draws:
// Apple's own Liquid Glass, the tab bar and the round back and close
// buttons, which no camera of the app's own can show (tool/app_shots.dart
// draws the app without iOS under it).
//
// It walks the app as a reader a fortnight in would, holding each screen a
// few seconds and saying which with a line `SHOT <name>`; the workflow that
// runs it (.github/workflows/glass-shots.yml) photographs the simulator's
// screen every second or so and names each picture by the last line said.
//
// Nothing is measured: the app is pumped without main(), so no analytics
// start, and the reader is the camera's own, made up on the device.
//
//   flutter test integration_test/glass_shots_test.dart -d <simulator>
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/genres.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/data/goals.dart';
import 'package:astuto/screens/area_screen.dart';
import 'package:astuto/screens/card_path_screen.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/screens/subject_home_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/skills_screen.dart';
import 'package:astuto/state/app_state.dart';

/// Draws for [time], without waiting for everything to stop: Explore has
/// rows that move on by themselves, and would never settle.
Future<void> _run(WidgetTester tester, Duration time) async {
  final DateTime until = DateTime.now().add(time);
  while (DateTime.now().isBefore(until)) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 60));
  }
}

/// Holds what is on screen for [seconds], drawing it the while, after
/// saying which screen it is.
Future<void> _hold(WidgetTester tester, String name, int seconds) async {
  await _run(tester, const Duration(milliseconds: 1500));
  // ignore: avoid_print
  print('SHOT $name');
  // And in the app's own tmp folder, which the workflow reads as the walk
  // goes: a printed line reaches its log only when the test ends.
  File('${Directory.systemTemp.path}/glass_shot.txt').writeAsStringSync(name);
  await _run(tester, Duration(seconds: seconds));
}

/// Goes to tab [i] as a swipe would, by the tabs' own pages.
Future<void> _tab(WidgetTester tester, int i) async {
  final PageView pages = tester.widget<PageView>(find.byType(PageView).first);
  pages.controller?.jumpToPage(i);
  await _run(tester, const Duration(milliseconds: 800));
}

/// Opens what [key] opens on the profile, holds it as [name], and comes back.
Future<void> _open(WidgetTester tester, String key, String name) async {
  final Finder it = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    it,
    300,
    scrollable: find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(it);
  await _hold(tester, name, 5);
  // Its back and close buttons are Apple's own on iOS 26, out of reach of
  // a finder: the route is let go of as they would.
  await Navigator.of(tester.element(find.byType(Scaffold).last)).maybePop();
  await _run(tester, const Duration(milliseconds: 1200));
}

/// Opens [page] over what is up, holds it as [name], and comes back.
Future<void> _push(WidgetTester tester, Widget page, String name) async {
  final NavigatorState nav = Navigator.of(
    tester.element(find.byType(Scaffold).last),
  );
  unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => page)));
  await _hold(tester, name, 5);
  await nav.maybePop();
  await _run(tester, const Duration(milliseconds: 1200));
}

/// The first part of the first theme with a path.
CardPath _firstPath() {
  for (final MapEntry<String, List<Genre>> s in kGenres.entries) {
    for (final Genre g in s.value) {
      final List<CardPath> parts = partsOf(g, s.key, PillBank.live);
      if (parts.isNotEmpty) return parts.first;
    }
  }
  throw StateError('no path');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final String theme in ['dark', 'light']) {
    testWidgets('the app on an iPhone, $theme', (tester) async {
      // The build of today, so Explore is today's (its sections ask for
      // one), and a reader a fortnight in.
      Remote.build = 300;
      final List<String> read = PillBank.cards
          .take(46)
          .map((p) => p.id)
          .toList();
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.seenIds': read,
        'knowit.streak': 13,
        'knowit.savedIds': read.take(6).toList(),
        'knowit.theme': theme,
      });
      await tester.pumpWidget(const AstutoApp());
      await _hold(tester, '$theme-today', 5);

      await _tab(tester, 1);
      await _hold(tester, '$theme-explore', 6);
      await tester.drag(
        find
            .descendant(
              of: find.byType(ExploreScreen),
              matching: find.byType(CustomScrollView),
            )
            .first,
        const Offset(0, -700),
      );
      await _hold(tester, '$theme-explore-scrolled', 6);

      await _tab(tester, 2);
      await _hold(tester, '$theme-profile', 4);
      await _open(tester, 'profile-saved', '$theme-back');
      await _open(tester, 'profile-plan', '$theme-close');

      // A page whose way back stays put above its list (a path), and one
      // whose way back scrolls with it (the skills): Apple's glass is drawn
      // by iOS, and only here is it seen whether it sits where the page
      // puts it.
      final AppState app = tester
          .widget<ProfileScreen>(find.byType(ProfileScreen))
          .app;
      await _push(
        tester,
        CardPathScreen(app: app, path: _firstPath()),
        '$theme-path',
      );
      await _push(tester, SkillsScreen(app: app), '$theme-skills');
      await _push(
        tester,
        AreaScreen(app: app, area: Goal.values.first),
        '$theme-area',
      );
      await _push(
        tester,
        SubjectHomeScreen(app: app, topicKey: _firstPath().topicKey),
        '$theme-subject',
      );
      await _push(
        tester,
        PillDetailScreen(app: app, pill: _firstPath().cards.first),
        '$theme-card',
      );
      await _push(
        tester,
        JourneyScreen(app: app, onBack: () {}),
        '$theme-journey',
      );
    });
  }
}
