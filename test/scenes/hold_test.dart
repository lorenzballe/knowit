import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';

/// `hold`: press for as long as you think it lasts, let go, see the truth.

/// Photographs only on request: `--dart-define=SHOTS=true --update-goldens`.
const _shots = bool.fromEnvironment('SHOTS');

void main() {
  // Real type, so overflow and the pictures are what a phone shows.
  setUpAll(() async {
    final fonts = {
      'Fraunces': 'assets/fonts/Fraunces.ttf',
      'Figtree': 'assets/fonts/Figtree.ttf',
      'MaterialIcons':
          '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
          '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    };
    for (final e in fonts.entries) {
      final bytes = File(e.value).readAsBytesSync();
      await (FontLoader(
        e.key,
      )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  const shot = {
    'type': 'hold',
    'what': 'One shot, 1940s Hollywood',
    'seconds': 10,
    'low': 8,
    'high': 11,
    'display': 'timecode',
    'comparisons': [
      {'label': 'A 2000s feature', 'seconds': 4},
      {'label': 'Armageddon, 1998', 'seconds': 2.3},
    ],
  };

  HoldScene parse(Map<String, Object?> m) =>
      Scene.fromJson(m, id: 't') as HoldScene;

  group('parse', () {
    test('reads every field', () {
      final s = parse(shot);
      expect(s.what, 'One shot, 1940s Hollywood');
      expect(s.seconds, 10);
      expect((s.low, s.high), (8, 11));
      expect(s.isBand, isTrue);
      expect(s.display, HoldDisplay.timecode);
      expect(s.comparisons.map((c) => c.label), [
        'A 2000s feature',
        'Armageddon, 1998',
      ]);
      expect(s.comparisons.last.seconds, 2.3);
    });

    test('a single value, seconds by default, no comparisons', () {
      final s = parse({'type': 'hold', 'what': 'Moonlight', 'seconds': 1.28});
      expect(s.isBand, isFalse);
      expect((s.low, s.high), (1.28, 1.28));
      expect(s.display, HoldDisplay.seconds);
      expect(s.comparisons, isEmpty);
    });

    for (final (why, bad) in [
      ('no what', {'type': 'hold', 'seconds': 1}),
      ('no seconds', {'type': 'hold', 'what': 'x'}),
      ('seconds not a number', {'type': 'hold', 'what': 'x', 'seconds': '1'}),
      ('seconds too long', {'type': 'hold', 'what': 'x', 'seconds': 90}),
      (
        'low without high',
        {'type': 'hold', 'what': 'x', 'seconds': 1, 'low': 0.5},
      ),
      (
        'truth outside its band',
        {'type': 'hold', 'what': 'x', 'seconds': 3, 'low': 1, 'high': 2},
      ),
      (
        'unknown display',
        {'type': 'hold', 'what': 'x', 'seconds': 1, 'display': 'hours'},
      ),
      (
        'a comparison without seconds',
        {
          'type': 'hold',
          'what': 'x',
          'seconds': 1,
          'comparisons': [
            {'label': 'y'},
          ],
        },
      ),
      (
        'four comparisons',
        {
          'type': 'hold',
          'what': 'x',
          'seconds': 1,
          'comparisons': [
            for (var i = 1; i <= 4; i++) {'label': '$i', 'seconds': i},
          ],
        },
      ),
    ]) {
      test('refuses $why', () {
        expect(() => parse(bad), throwsFormatException);
      });
    }

    test('the samples parse as whole cards', () {
      final cards = jsonDecode(
        File('tool/cards/samples/hold.json').readAsStringSync(),
      ) as List;
      expect(cards, hasLength(3));
      for (final c in cards) {
        final pill = cardFromJson((c as Map).cast<String, Object?>());
        expect(pill.scene, isA<HoldScene>());
      }
    });
  });

  // ------------------------------------------------------------- the scene

  Widget alone(
    Map<String, Object?> json,
    Size box, {
    bool dark = false,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Scaffold(
      backgroundColor: dark ? const Color(0xFF3D1E99) : const Color(0xFFFFD84D),
      body: Center(
        child: SizedBox(
          width: box.width,
          height: box.height,
          child: SceneView(
            scene: Scene.fromJson(json)!,
            ink: dark ? Colors.white : const Color(0xFF141414),
            ground: dark ? const Color(0xFF3D1E99) : const Color(0xFFFFD84D),
          ),
        ),
      ),
    ),
  );

  Future<void> hold(WidgetTester tester, Duration length) async {
    final g = await tester.startGesture(
      tester.getCenter(find.text('Press and hold')),
    );
    await tester.pump();
    var left = length;
    const frame = Duration(milliseconds: 100);
    while (left > Duration.zero) {
      final step = left < frame ? left : frame;
      await tester.pump(step);
      left -= step;
    }
    await g.up();
    await tester.pump();
  }

  // The scene's room on the front of a small and a large phone, and on the
  // back of an asking card.
  for (final (name, phone, box) in [
    ('small phone', const Size(360, 740), const Size(276, 330)),
    ('large phone', const Size(430, 932), const Size(346, 520)),
    ('card back', const Size(360, 740), const Size(276, 270)),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('on a $name (${dark ? 'white' : 'dark'} ink), '
          'a hold stops the clock and lays it beside the truth', (
        tester,
      ) async {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(alone(shot, box, dark: dark));
        await tester.pumpAndSettle();

        expect(find.text('ONE SHOT, 1940S HOLLYWOOD'), findsOneWidget);
        expect(find.text('00:00:00'), findsOneWidget);

        if (_shots && name != 'large phone') {
          // Mid-hold, for the picture: the dial in ink, the hand sweeping.
          final g = await tester.startGesture(
            tester.getCenter(find.text('Press and hold')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1300));
          await expectLater(
            find.byType(SceneView),
            matchesGoldenFile(
              '../../tool/shots/scenes/hold_holding_${name.replaceAll(' ', '_')}_${dark ? 'white' : 'dark'}.png',
            ),
          );
          await g.up();
          await tester.pumpAndSettle();
          await tester.tap(find.text('Try again'));
          await tester.pumpAndSettle();
        }

        await hold(tester, const Duration(milliseconds: 3500));
        await tester.pumpAndSettle();

        // 3.5 s at 24 frames a second: 00:03:12.
        expect(find.text('00:03:12'), findsOneWidget);
        expect(find.text('YOU'), findsOneWidget);
        expect(find.text('3.5 s'), findsOneWidget);
        expect(find.text('TRUTH'), findsOneWidget);
        expect(find.text('8–11 s'), findsOneWidget);
        expect(find.text('A 2000S FEATURE'), findsOneWidget);
        expect(find.text('2.3 s'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Show me: every bar played again in real time, then back to yours.
        await tester.tap(find.text('Show me'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('00:02:00'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('00:03:12'), findsOneWidget);

        if (_shots) {
          await expectLater(
            find.byType(SceneView),
            matchesGoldenFile(
              '../../tool/shots/scenes/hold_result_${name.replaceAll(' ', '_')}_${dark ? 'white' : 'dark'}.png',
            ),
          );
        }

        // Try again: back to the dial and a clock at zero.
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('Press and hold'), findsOneWidget);
        expect(find.text('00:00:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('milliseconds: a quick tap is still longer than the beat', (
    tester,
  ) async {
    await tester.pumpWidget(
      alone({
        'type': 'hold',
        'what': 'One hummingbird heartbeat',
        'seconds': 0.048,
        'display': 'ms',
        'comparisons': [
          {'label': "A mouse's heartbeat", 'seconds': 0.1},
        ],
      }, const Size(276, 330)),
    );
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('ms'), findsOneWidget);
    await hold(tester, const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
    expect(find.text('200 ms'), findsOneWidget);
    expect(find.text('48 ms'), findsOneWidget);
    expect(find.text('100 ms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with animations off it ends in the same place', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: alone(shot, const Size(276, 330)),
      ),
    );
    await tester.pump();
    await hold(tester, const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('TRUTH'), findsOneWidget);
    expect(find.text('1 s'), findsOneWidget);
  });

  testWidgets('a screen reader starts and stops the clock with two taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(alone(shot, const Size(276, 330)));
    await tester.pumpAndSettle();
    final dial = find.bySemanticsLabel(
      'One shot, 1940s Hollywood. Press and hold',
    );
    expect(dial, findsOneWidget);
    expect(
      tester.getSemantics(dial),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        label: 'One shot, 1940s Hollywood. Press and hold',
      ),
    );
    tester.semantics.tap(
      find.semantics.byLabel('One shot, 1940s Hollywood. Press and hold'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    tester.semantics.tap(
      find.semantics.byLabel('One shot, 1940s Hollywood. Press and hold'),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(r'^YOU 2 s\. TRUTH 8–11 s')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  // ------------------------------------------------- on the card, in the deck

  group('in the deck', () {
    final base = PillBank.cards.firstWhere((p) => p.challenge is NoChallenge);
    final card = cardFromJson({
      ...jsonDecode(File('tool/cards/samples/hold.json').readAsStringSync())[0]
          as Map<String, Object?>,
    });

    late Set<String> liked;
    late int advanced;

    Widget deck(Pill pill) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          height: 700,
          child: StatefulBuilder(
            builder: (context, set) => PillCardStack(
              isSaved: (_) => false,
              onSave: (_) {},
              onShare: (_) {},
              isLiked: liked.contains,
              onLike: (p) => set(() {
                if (!liked.remove(p.id)) liked.add(p.id);
              }),
              deck: [pill, base],
              index: 0,
              onAdvance: () => advanced++,
              answerFor: (_) => null,
              reviewIds: const {},
              onAnswer: (_, _, _, _) {},
            ),
          ),
        ),
      ),
    );

    final heart = find.byWidgetPredicate(
      (w) =>
          w is Icon &&
          (w.icon == Icons.favorite_border_rounded ||
              w.icon == Icons.favorite_rounded),
    );

    setUp(() {
      liked = {};
      advanced = 0;
    });

    testWidgets(
      'a long hold in the scene times it and does not like the card',
      (tester) async {
        await tester.pumpWidget(deck(card));
        await tester.pumpAndSettle();

        final g = await tester.startGesture(
          tester.getCenter(find.text('Press and hold')),
        );
        await tester.pump(); // the clock's first frame
        // Well past the 700 ms that likes a card, watching for the mark.
        for (var f = 0; f < 25; f++) {
          await tester.pump(const Duration(milliseconds: 100));
          expect(heart, findsNothing, reason: 'no heart while timing');
        }
        await g.up();
        await tester.pumpAndSettle();

        expect(liked, isEmpty, reason: 'the hold must not like the card');
        expect(heart, findsNothing);
        expect(find.text('00:02:12'), findsOneWidget);
        expect(find.text('TRUTH'), findsOneWidget);
        expect(find.text('WHAT TO KEEP'), findsNothing, reason: 'not turned');
        expect(advanced, 0);
      },
    );

    testWidgets('a drag while holding stays in the scene: the deck stays put', (
      tester,
    ) async {
      await tester.pumpWidget(deck(card));
      await tester.pumpAndSettle();

      final g = await tester.startGesture(
        tester.getCenter(find.text('Press and hold')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(-40, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();

      expect(advanced, 0, reason: 'a drag in the scene must not advance');
      expect(liked, isEmpty);
      expect(find.text('TRUTH'), findsOneWidget, reason: 'it was a hold');
      expect(find.text('WHAT TO KEEP'), findsNothing);
    });

    testWidgets('outside the scene the card still likes, turns and moves on', (
      tester,
    ) async {
      await tester.pumpWidget(deck(card));
      await tester.pumpAndSettle();
      final question = find.textContaining('Hold for as long as you think');

      // Long press on the question likes it.
      final g = await tester.startGesture(tester.getCenter(question));
      for (var f = 0; f < 9; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(liked, contains(card.id));

      // A tap on the question turns it.
      await tester.tap(question);
      await tester.pumpAndSettle();
      expect(find.text('WHAT TO KEEP'), findsOneWidget);

      // A throw from the question moves on.
      await tester.fling(question, const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(advanced, 1);
    });
  });
}
