// Photographs Explore under the shelves that were always there: the month,
// the deck of myths, the round against the clock, the six ways to work a
// number out, the ruler of ages, the pile of facts, the charts unmasked, one
// card from anywhere at the end — each at rest and each played.
//
//   flutter test tool/explore_shots.dart --update-goldens
//
// A camera, not a check, so it lives outside test/ like the other shots.
// The pictures land in tool/shots/explore/.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/main.dart';
import 'package:astuto/state/explore_play.dart';

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

const Size _phone = Size(402, 874);

void _store({bool paper = false}) {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    if (paper) 'knowit.theme': 'light',
  });
}

void main() {
  setUpAll(_loadFonts);

  void size(Size logical, double ratio) {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = logical * ratio;
    view.devicePixelRatio = ratio;
  }

  setUp(() {
    size(_phone, 3);
    // ignore: invalid_use_of_visible_for_testing_member
    ExplorePlay.resetForTest();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> settle(WidgetTester tester) async {
    for (int f = 0; f < 14; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('shots/explore/$name.png'),
  );

  Finder down() => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;

  Future<void> open(WidgetTester tester, {bool paper = false}) async {
    _store(paper: paper);
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);
  }

  /// Scrolls until [key] is on screen, then brings its top near the top.
  Future<void> reach(
    WidgetTester tester,
    String key, {
    double above = 90,
  }) async {
    final Finder target = find.byKey(ValueKey(key), skipOffstage: false);
    for (int i = 0; i < 80 && target.evaluate().isEmpty; i++) {
      await tester.drag(down(), const Offset(0, -500));
      await tester.pump();
    }
    await tester.ensureVisible(target);
    await settle(tester);
    final double top = tester.getTopLeft(target).dy;
    await tester.drag(down(), Offset(0, -(top - above)));
    await settle(tester);
  }

  testWidgets('Explore, top to bottom', (tester) async {
    await open(tester);
    await shoot(tester, '00-top');
    final ScrollableState list = tester.state(down());
    for (int i = 1; i < 40; i++) {
      final double before = list.position.pixels;
      await tester.drag(down(), const Offset(0, -640));
      await settle(tester);
      if (list.position.pixels == before) break;
      await shoot(tester, i.toString().padLeft(2, '0'));
    }
  });

  testWidgets('Explore, the whole page in one picture', (tester) async {
    size(const Size(402, 15000), 1);
    await open(tester);
    await shoot(tester, 'full-page');
  });

  testWidgets('Explore on paper', (tester) async {
    await open(tester, paper: true);
    await reach(tester, 'mix-month');
    await shoot(tester, 'paper-month');
    await reach(tester, 'mix-work');
    await shoot(tester, 'paper-work');
    await reach(tester, 'front-page', above: 60);
    await shoot(tester, 'paper-front');
    await reach(tester, 'mix-surprise', above: 60);
    await shoot(tester, 'paper-surprise');
  });

  testWidgets('played: true or false, the round, the deck', (tester) async {
    await open(tester);
    await reach(tester, 'theme-trueOrFalse-0');
    final Finder sides = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('tf-') &&
          (w.key! as ValueKey<String>).value.endsWith('-true'),
    );
    if (sides.evaluate().isNotEmpty) {
      await tester.tap(sides.first);
      await settle(tester);
    }
    await shoot(tester, 'play-true-false');

    await reach(tester, 'mix-sixty');
    await tester.tap(find.byKey(const ValueKey('sixty-start')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sixty-true')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sixty-false')));
    await settle(tester);
    await shoot(tester, 'play-sixty-running');
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('sixty-true')));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await settle(tester);
    await shoot(tester, 'play-sixty-end');
  });

  testWidgets('played: the six ways to work it out', (tester) async {
    await open(tester);
    await reach(tester, 'mix-work');
    await shoot(tester, 'work-pick');
    final Finder firstOption = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          RegExp(r'^pick-.*-0$').hasMatch((w.key! as ValueKey<String>).value),
    );
    if (firstOption.evaluate().isNotEmpty) {
      await tester.tap(firstOption.first);
      await settle(tester);
      await shoot(tester, 'work-pick-answered');
    }
    // The chips are a lazy row: drag it until the one wanted is built.
    final Finder chips = find
        .ancestor(
          of: find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('work-pick-'),
          ),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
          ),
        )
        .first;
    for (final mode in ['slide', 'closer', 'bigger', 'range', 'stake']) {
      final Finder chip = find.byKey(ValueKey('work-$mode-off'));
      for (int i = 0; i < 12 && chip.evaluate().isEmpty; i++) {
        await tester.drag(chips, const Offset(-90, 0));
        await settle(tester);
      }
      if (chip.evaluate().isEmpty) continue;
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await settle(tester);
      await reach(tester, 'mix-work', above: 70);
      await shoot(tester, 'work-$mode');
      if (mode == 'slide' || mode == 'range') {
        final String prefix = mode == 'slide' ? 'slide-check-' : 'range-bet-';
        final Finder act = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith(prefix),
        );
        if (act.evaluate().isNotEmpty) {
          await tester.tap(act.first);
          await settle(tester);
          await shoot(tester, 'work-$mode-done');
        }
      }
      if (mode == 'closer') {
        for (final side in ['more', 'less', 'more']) {
          final Finder tap = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                RegExp('^closer-.*-$side\$')
                    .hasMatch((w.key! as ValueKey<String>).value),
          );
          if (tap.evaluate().isEmpty) break;
          await tester.tap(tap.first);
          await settle(tester);
        }
        await shoot(tester, 'work-closer-done');
      }
      if (mode == 'bigger') {
        final Finder side = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('bigger-'),
        );
        if (side.evaluate().isNotEmpty) {
          await tester.tap(side.first);
          await settle(tester);
          await shoot(tester, 'work-bigger-done');
        }
      }
      if (mode == 'stake') {
        final Finder option = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              RegExp(r'^stake-.*-o1$')
                  .hasMatch((w.key! as ValueKey<String>).value),
        );
        if (option.evaluate().isNotEmpty) {
          await tester.tap(option.first);
          await settle(tester);
          final Finder bet = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('stake-bet-'),
          );
          if (bet.evaluate().isNotEmpty) {
            await tester.tap(bet.first);
            await settle(tester);
          }
          await shoot(tester, 'work-stake-done');
        }
      }
    }
  });

  testWidgets('played: did you know, the ruler, the chart', (tester) async {
    await open(tester);
    // In the page's order: the chart is among the cards to play, the ruler
    // and the pile among the ways in by time.
    await reach(tester, 'mix-unmask');
    final Finder unmask = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('unmask-'),
    );
    await shoot(tester, 'play-unmask-before');
    if (unmask.evaluate().isNotEmpty) {
      await tester.tap(unmask.first);
      await tester.pump(const Duration(milliseconds: 900));
      await settle(tester);
    }
    await shoot(tester, 'play-unmask-after');

    await reach(tester, 'mix-through-time');
    await tester.tap(find.byKey(const ValueKey('era-on')));
    await settle(tester);
    await shoot(tester, 'play-through-time');

    await reach(tester, 'mix-did-you-know');
    final Finder pile = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('dyk-') &&
          (w.key! as ValueKey<String>).value != 'dyk-new' &&
          (w.key! as ValueKey<String>).value != 'dyk-knew',
    );
    if (pile.evaluate().isNotEmpty) {
      await tester.tap(pile.first);
      await settle(tester);
    }
    await shoot(tester, 'play-did-you-know');

    await reach(tester, 'mix-surprise');
    await tester.tap(find.byKey(const ValueKey('surprise-me')));
    await settle(tester);
    await shoot(tester, 'play-surprise');
  });
}
