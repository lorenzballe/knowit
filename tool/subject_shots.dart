// Photographs everything the newest subject, Life, touches: the mix, the
// genres and Explore's shelf for it.
//
//   flutter test tool/subject_shots.dart --update-goldens
//
// A camera, not a check, so it lives outside test/ like the other shots.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

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

void main() {
  setUpAll(_loadFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = _phone * 3;
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

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('shots/subjects-$name.png'),
  );

  Widget onboarding(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    debugShowCheckedModeBanner: false,
    home: child,
  );

  testWidgets('the mix and the genres', (tester) async {
    await tester.pumpWidget(
      onboarding(MixScreen(onDone: (_) {}, onSkip: () {})),
    );
    await settle(tester);
    await shoot(tester, 'mix');

    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    final app = AppState(
      hasPermission: () async => false,
      askPermission: () async => false,
      arm: (_) async {},
      disarm: () async {},
      pushWidget: (_) async {},
    );
    await tester.runAsync(app.init);
    // The new one asked for most, so it leads the list.
    await tester.runAsync(() => app.setTopicMix({'life': 0.8, 'science': 0.3}));
    await tester.pumpWidget(
      onboarding(GenresScreen(app: app, onDone: (_, _) {}, onSkip: () {})),
    );
    await settle(tester);
    await shoot(tester, 'genres');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await settle(tester);
    await shoot(tester, 'genres-2');

    // Hold a genre for its strands, then a strand for its angles.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => app.setTopicMix({'economics': 0.9, 'life': 0.3}),
    );
    await tester.pumpWidget(
      onboarding(GenresScreen(app: app, onDone: (_, _) {}, onSkip: () {})),
    );
    await settle(tester);
    await tester.longPress(find.text('Think in incentives'));
    await settle(tester);
    await shoot(tester, 'reasoning-genre');
    await tester.longPress(find.text('Think in incentives'));
    await tester.longPress(find.text('Pricing tricks'));
    await settle(tester);
    await tester.longPress(find.text('Anchoring'));
    await settle(tester);
    await shoot(tester, 'angles');
  });

  testWidgets('the week told back', (tester) async {
    final now = DateTime.now();
    String key(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    const ids = [
      'life-big-choices-1',
      'life-conversation-1',
      'life-deep-work-1',
      'life-failure-1',
      'life-friendship-1',
    ];
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.seenIds': ids,
      'knowit.deckHistory':
          '{"${key(now.subtract(const Duration(days: 1)))}": ["${ids.join('","')}"]}',
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('week-recap')));
    await settle(tester);
    await shoot(tester, 'week-recap');
  });

  testWidgets('Explore, for the new subject', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);

    // The chips are a lazy row: drag it from a fixed point on the row until
    // the one wanted is built.
    final double rowY = tester
        .getCenter(find.byKey(const ValueKey('subject-All-on')))
        .dy;
    Future<void> reveal(Finder chip) async {
      for (int i = 0; i < 40 && chip.evaluate().isEmpty; i++) {
        await tester.dragFrom(Offset(300, rowY), const Offset(-120, 0));
        await settle(tester);
      }
      await tester.ensureVisible(chip);
      await settle(tester);
    }

    for (final subject in ['Life']) {
      final chip = find.byKey(ValueKey('subject-$subject-off'));
      await reveal(chip);
      await tester.tap(chip);
      await settle(tester);
      await shoot(tester, '${subject.toLowerCase()}-shelf');
      await tester.tap(find.byKey(ValueKey('subject-$subject-on')));
      await settle(tester);
    }
  });

  testWidgets('Explore, scrolled to the turning themes', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);
    final down = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    for (int i = 0; i < 4; i++) {
      await tester.drag(down, const Offset(0, -560));
      await settle(tester);
      await shoot(tester, 'explore-themes-$i');
    }
  });
}
