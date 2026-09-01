// Photographs the app past the onboarding, on a phone rather than in a
// browser.
//
//   flutter test tool/app_shots.dart --update-goldens
//
// Like tool/intro_shots.dart this lives outside test/ so CI never runs it:
// it is a camera, not a check. Both tabs and the paywall are here because a
// screen nobody looks at is a screen nobody notices breaking.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_data.dart';
import 'package:astuto/main.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

Future<void> _loadFonts() async {
  const fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons': '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
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

/// A store that is past the first run.
///
/// The analyzer only counts a file as a test if it sits under test/, and this
/// camera lives outside it on purpose so CI never runs it — hence the one
/// ignore, kept in a single place rather than repeated at every call.
void _installed() {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
}

/// An install with a fortnight behind it.
///
/// A record photographed at zero shows every bar empty and every subject the
/// same grey, which is a picture of the empty state rather than of the
/// screen. This is what the profile actually looks like in use.
void _wellUsed() {
  final read = kPillPool.take(46).map((pill) => pill.id).toList();
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.seenIds': read,
    'knowit.streak': 13,
    'knowit.savedIds': read.take(6).toList(),
  });
}

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
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

  Future<void> shoot(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/app-$name.png'),
    );
  }

  testWidgets('the three tabs', (tester) async {
    _installed();
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await shoot(tester, 'today');

    await tester.tap(find.byKey(const ValueKey('tab-Saved')));
    await settle(tester);
    await shoot(tester, 'saved');

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await shoot(tester, 'profile');
  });

  testWidgets('the record of somebody who has been reading', (tester) async {
    _wellUsed();
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await shoot(tester, 'profile-used');
  });

  testWidgets('a card, opened and answered', (tester) async {
    _installed();
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    // Whatever the day deals, tap the first card through to its answer.
    final card = find.byType(GestureDetector);
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card.first, warnIfMissed: false);
      await settle(tester);
    }
    await shoot(tester, 'card');
  });

  testWidgets('the foot of the profile, where the debug tools live', (
    tester,
  ) async {
    _installed();
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await settle(tester);
    await shoot(tester, 'profile-foot');
  });

  testWidgets('on paper, where the accent reverses', (tester) async {
    // The accent is no longer a colour, it is whatever reverses the page —
    // white on the black ground, near-black on the light one. That only
    // holds if the light theme is looked at, so it is looked at.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.theme': 'light',
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await shoot(tester, 'today-light');

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await shoot(tester, 'profile-light');
  });

  testWidgets('a card mid-throw, and the re-read', (tester) async {
    _wellUsed();
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    // Held part-way through a throw, up and to the left. The tab bar should
    // be on its way out, because a card thrown at a row of buttons is a card
    // thrown at a row of buttons.
    final TestGesture drag = await tester.startGesture(
      tester.getCenter(find.byType(PillCardStack)),
    );
    await drag.moveBy(const Offset(-70, -60));
    // Several frames, not one: the bar slides out over 220ms and a single
    // pump only starts it.
    for (int f = 0; f < 8; f++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await shoot(tester, 'card-thrown');
    await drag.up();
    await settle(tester);
  });

  testWidgets('the topics editor, with every subject live', (tester) async {
    // On the paid plan, because editing the mix is behind Astuto+ and the
    // free plan quite rightly answers that tap with the paywall.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': true,
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await settle(tester);
    await shoot(tester, 'topics-list');

    await tester.tap(find.text('Edit'));
    await settle(tester);
    await shoot(tester, 'topics-editor');
  });

  testWidgets('the paywall', (tester) async {
    _installed();
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);

    final plans = find.text('SEE THE PLANS');
    expect(plans, findsOneWidget, reason: 'the way into the paywall moved');
    await tester.tap(plans);
    await settle(tester);
    await shoot(tester, 'paywall');
  });
}
