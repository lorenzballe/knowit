// Photographs the charts that mislead (lib/widgets/explore/unmask_chart.dart)
// in the app itself, in each of its looks: the block where Explore shows it,
// on Wednesdays, between where you live and the ten-card paths; the first
// card after its button; and the card it opens.
//
//   flutter test tool/unmask_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder) and LANG_SHOT (a language, Italian by default) move it;
// UNMASK_LOOKS (a comma-separated list) picks the looks.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart' show canUnmask;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/unmask_chart.dart';

import '../test/explore/core_harness.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);

  final String out = Platform.environment['SHOTS'] ?? 'shots/unmask';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');
  final List<String> looks =
      (Platform.environment['UNMASK_LOOKS'] ?? 'current,in-place,before-after')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();

  // A phone of today's middle size, with the room its status bar and its
  // home bar take.
  const Size phone = Size(390, 844);
  const EdgeInsets safe = EdgeInsets.only(top: 47, bottom: 34);

  Future<void> settle(WidgetTester tester, [int frames = 14]) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Finder down() => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;

  Finder prefixed(String prefix) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(prefix),
  );

  /// Explore as a first-time reader meets it on a Wednesday: where you
  /// live, the charts, the ten-card paths; the charts in [look].
  Future<void> open(
    WidgetTester tester, {
    required String look,
    bool paper = false,
  }) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(
      top: safe.top * 3,
      bottom: safe.bottom * 3,
    );
    tester.view.viewPadding = FakeViewPadding(
      top: safe.top * 3,
      bottom: safe.bottom * 3,
    );
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [locale];
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    Remote.adopt(
      RemoteConfig(
        hash: 'unmask-$look-${paper ? 'light' : 'dark'}',
        schema: kRemoteSchema,
        parts: {
          ...Remote.embedded.parts,
          'explore': {
            'sections': [
              {'id': 'where-you-live', 'block': 'where-you-live'},
              {'id': 'surprise-wed', 'block': 'unmask', 'look': look},
              {'id': 'paths', 'block': 'paths'},
            ],
          },
        },
      ),
    );
    // ignore: invalid_use_of_visible_for_testing_member
    addTearDown(Remote.reset);
    // ignore: invalid_use_of_visible_for_testing_member
    ExplorePlay.resetForTest();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      if (paper) 'knowit.theme': 'light',
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);
  }

  /// Scrolls until the block is on screen, then brings its top to [above].
  Future<void> reach(WidgetTester tester, {double above = 150}) async {
    final Finder target = find.byKey(
      const ValueKey('mix-unmask'),
      skipOffstage: false,
    );
    for (int i = 0; i < 40 && target.evaluate().isEmpty; i++) {
      await tester.drag(down(), const Offset(0, -400));
      await tester.pump();
    }
    await tester.ensureVisible(target);
    await settle(tester);
    final double top = tester.getTopLeft(target).dy;
    await tester.drag(down(), Offset(0, -(top - above)));
    await settle(tester);
  }

  Future<void> take(String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$out/$name.png'),
  );

  for (final String look in looks) {
    testWidgets('unmask: $look', (tester) async {
      await open(tester, look: look);
      await reach(tester);
      await take('$look-1-explore');
      // The first card's button, and the chart turned honest.
      final Finder button = prefixed('unmask-');
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button.first);
        await tester.pump(const Duration(milliseconds: 900));
        await settle(tester);
      }
      await take('$look-2-tapped');
      // In place, the switch back to the chart as it ran, and on again.
      Finder side(String end) => find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('unmask-') &&
            (w.key! as ValueKey<String>).value.endsWith(end),
      );
      if (side('-original').evaluate().isNotEmpty) {
        await tester.tap(side('-original').first);
        await tester.pump(const Duration(milliseconds: 900));
        await settle(tester);
        await take('$look-2b-original-again');
        await tester.tap(side('-corrected').first);
        await tester.pump(const Duration(milliseconds: 900));
        await settle(tester);
      }
      // Before and after, the button that hides the trick and asks again.
      if (look == 'before-after' && button.evaluate().isNotEmpty) {
        await tester.tap(button.first);
        await tester.pump(const Duration(milliseconds: 900));
        await settle(tester);
        await take('$look-2b-hidden-again');
      }
      // The card behind it, opened from the chart.
      final Finder card = prefixed('explore-');
      final Finder first = find.descendant(
        of: find.byKey(const ValueKey('mix-unmask')),
        matching: card,
      );
      if (first.evaluate().isNotEmpty) {
        await tester.tapAt(
          tester.getTopLeft(first.first) + const Offset(40, 40),
        );
        await settle(tester, 30);
      }
      await take('$look-3-opened');
    });

    testWidgets('unmask: $look on paper', (tester) async {
      await open(tester, look: look, paper: true);
      await reach(tester);
      await take('$look-1-explore-light');
    });
  }

  // Every chart the shelf can draw, before its button and after, in each
  // clearer look: for the eye that checks every trick is said, and fits.
  // Into all/, at two pixels a point; then again at the largest text the
  // shelves are checked at, where a line that does not fit fails the run.
  for (final double text in const [1.0, 1.35]) {
    testWidgets('unmask: every chart, text at $text', (tester) async {
      final List<Pill> charts = PillBank.cards.where(canUnmask).toList();
      tester.view.physicalSize = const Size(360, 460) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = text;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final String big = text == 1 ? '' : '-text${(text * 100).round()}';
      for (final String look in looks.where((l) => l != 'current')) {
        for (final Pill p in charts) {
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAstutoTheme(Brightness.dark),
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: UnmaskRow(
                    key: ValueKey('$look-${p.id}-$text'),
                    look: UnmaskLook.named(look),
                    pills: [p],
                    onOpen: (_, _) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await take('all/$look-${p.id}$big-a');
          await tester.tap(find.byKey(ValueKey('unmask-${p.id}')));
          // The first frame starts the turn; the rest play it to its end.
          await tester.pump();
          await settle(tester, 10);
          await take('all/$look-${p.id}$big-b');
        }
      }
    });
  }
}
