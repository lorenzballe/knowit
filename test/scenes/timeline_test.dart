import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/flip_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';

/// Pictures are written only when asked for:
///   flutter test test/scenes/timeline_test.dart --dart-define=SHOTS=true
/// and land in tool/shots/cards/ (ignored by git). Without it the widget
/// tests still drive every scene to its end state and check it.
const _shots = bool.fromEnvironment('SHOTS');

const _calendar = {
  'type': 'timeline',
  'axis': 'years',
  'from': -3000,
  'to': 2025,
  'events': [
    {'label': 'Great Pyramid finished', 'year': -2560},
    {
      'label': 'Last mammoths die out',
      'year': -2000,
      'note': 'Mammoths still lived on Wrangel Island after the pyramid.',
    },
    {
      'label': 'Cleopatra dies',
      'year': -30,
      'note': 'Cleopatra lived closer to the Moon landing than to the pyramid.',
    },
    {'label': 'Moon landing', 'year': 1969},
  ],
};

const _deep = {
  'type': 'timeline',
  'axis': 'ago',
  'from': 10000000000,
  'to': 1000,
  'unit': 'years ago',
  'events': [
    {'label': 'Earth forms', 'ago': 4540000000},
    {'label': 'First dinosaurs', 'ago': 233000000},
    {'label': 'Dinosaurs die out', 'ago': 66000000},
    {
      'label': 'Our species appears',
      'ago': 300000,
      'note': 'Our species is 300,000 years old.',
    },
    {'label': 'Farming begins', 'ago': 12000},
  ],
};

TimelineScene _parse(Map<String, Object?> raw) =>
    Scene.fromJson(jsonDecode(jsonEncode(raw)))! as TimelineScene;

Map<String, Object?> _with(Map<String, Object?> base, Map<String, Object?> o) =>
    {...jsonDecode(jsonEncode(base)) as Map<String, Object?>, ...o};

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final e in fonts.entries) {
    final file = File(e.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(e.key)
      ..addFont(
        Future.value(
          ByteData.view(Uint8List.fromList(file.readAsBytesSync()).buffer),
        ),
      );
    await loader.load();
  }
}

/// The scene as the front of a card holds it: a block of the card's colour
/// at the phone's width, less the card's margins, and a given height.
Widget _host(
  TimelineScene scene, {
  required double height,
  Color ground = const Color(0xFFFFB000),
  Color ink = const Color(0xFF14110C),
  bool still = false,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: Scaffold(
          backgroundColor: ground,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                height: height,
                child: SceneView(scene: scene, ink: ink, ground: ground),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Drags lane [label]'s knob to 0..1 [at] along its track.
Future<void> _place(WidgetTester tester, String label, double at) async {
  final lane = tester.getRect(find.bySemanticsLabel(label));
  // The track is in the lower part of the lane; the whole lane takes it.
  final y = lane.top + lane.height * 0.7;
  final from = Offset(lane.left + 20, y);
  final to = Offset(lane.left + 14 + (lane.width - 28) * at, y);
  await tester.dragFrom(from, to - from);
  await tester.pump();
}

Future<void> _shoot(WidgetTester tester, String name) async {
  if (!_shots) return;
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../tool/shots/cards/scene-timeline-$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);

  group('parse', () {
    test('a calendar axis counts across BC and AD the way time passed', () {
      final s = _parse(_calendar);
      expect(s.axis, TimelineAxis.years);
      expect(s.events, hasLength(4));
      // 30 BC is astronomical −29; 1969 − (−29) = 1998 years.
      expect(s.events[3].at - s.events[2].at, 1998);
      expect(s.events[2].at - s.events[0].at, 2530);
      expect(s.say(s.events[0].at), '2560 BC');
      expect(s.say(s.events[2].at), '30 BC');
      expect(s.say(s.events[3].at), '1969');
      expect(s.say(TimelineScene.astronomical(79)), 'AD 79');
    });

    test('the calendar has marks at round years and none at year 0', () {
      final s = _parse(_calendar);
      final labels = s.ticks.map(s.tickLabel).toList();
      expect(labels, ['3000 BC', '2000 BC', '1000 BC', 'AD 1', '1000', '2000']);
    });

    test('a guess is rounded as it is shown and never lands on year 0', () {
      final s = _parse(_calendar);
      expect(s.grain, 25);
      expect(s.snap(TimelineScene.astronomical(-1012)), -1000 + 1);
      expect(s.say(s.snap(0.2)), '1 BC');
      expect(s.say(s.snap(0.9)), 'AD 1');
      expect(s.gap(s.events[2].at + 500, s.events[2].at), '+500');
      expect(s.gap(s.events[2].at - 1250, s.events[2].at), '−1,250');
      expect(s.gap(s.events[2].at + 5, s.events[2].at), '');
      expect(s.gap(s.events[0].at + 460, s.events[0].at), '+460');
    });

    test('deep time is drawn in powers of ten and said in rough numbers', () {
      final s = _parse(_deep);
      expect(s.axis, TimelineAxis.ago);
      expect(s.t(1e10), 0);
      expect(s.t(1e3), 1);
      expect(s.t(1e6), closeTo(4 / 7, 1e-9));
      expect(s.valueAt(s.t(66e6)), closeTo(66e6, 1));
      expect(s.ticks.map(s.tickLabel), [
        '10bn',
        '1bn',
        '100M',
        '10M',
        '1M',
        '100k',
        '10k',
        '1k',
      ]);
      expect(s.say(66e6), '66 million');
      expect(s.unit, 'years ago');
      expect(s.gap(3e6, 300000), '×10');
      expect(s.gap(900000, 300000), '×3');
      expect(s.gap(320000, 300000), '');
    });

    test('bad data is refused, not drawn', () {
      void bad(Map<String, Object?> raw) =>
          expect(() => _parse(raw), throwsFormatException);
      bad(_with(_calendar, {'axis': 'decades'}));
      bad(_with(_calendar, {'from': 2025, 'to': -3000}));
      bad(_with(_calendar, {'from': 0}));
      bad(_with(_deep, {'from': 1000, 'to': 1e10}));
      bad(
        _with(_calendar, {
          'events': (_calendar['events']! as List).take(2).toList(),
        }),
      );
      bad(
        _with(_calendar, {
          'events': [
            ...(_calendar['events']! as List).take(3),
            {'label': 'Year zero', 'year': 0},
          ],
        }),
      );
      bad(
        _with(_calendar, {
          'events': [
            ...(_calendar['events']! as List).take(3),
            {'label': 'The future', 'year': 2500},
          ],
        }),
      );
      bad(
        _with(_calendar, {
          'events': [
            for (final e in _calendar['events']! as List)
              {...(e as Map), 'note': null},
          ],
        }),
      );
      bad(
        _with(_deep, {
          'events': [
            for (final e in _deep['events']! as List)
              {'label': (e as Map)['label'], 'year': 1900, 'note': 'x'},
          ],
        }),
      );
    });

    test('the three sample cards parse', () {
      final cards = jsonDecode(
        File('tool/cards/samples/timeline.json').readAsStringSync(),
      ) as List;
      expect(cards, hasLength(3));
      for (final c in cards) {
        final pill = cardFromJson((c as Map).cast<String, Object?>());
        expect(pill.scene, isA<TimelineScene>());
      }
    });
  });

  group('play', () {
    for (final (phone, size, height) in [
      ('small', const Size(360, 740), 340.0),
      ('large', const Size(430, 932), 500.0),
      ('back', const Size(360, 740), 270.0),
    ]) {
      testWidgets('placed, locked and revealed on $phone', (tester) async {
        _phone(tester, size);
        final s = _parse(_calendar);
        await tester.pumpWidget(_host(s, height: height));
        await tester.pump(const Duration(seconds: 3));
        await _shoot(tester, '$phone-start');

        expect(find.text('0 of 4'), findsOneWidget);
        // Locking before everything is placed does nothing.
        await tester.tap(find.text('LOCK IT IN'));
        await tester.pump();
        expect(find.text('0 of 4'), findsOneWidget);

        await _place(tester, 'Great Pyramid finished', 0.18);
        await _place(tester, 'Last mammoths die out', 0.05);
        await _place(tester, 'Cleopatra dies', 0.62);
        await _place(tester, 'Moon landing', 0.98);
        expect(find.text('4 of 4'), findsOneWidget);
        await _shoot(tester, '$phone-placed');

        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('LOCK IT IN'));
        await tester.pump();
        // Mid-reveal: the first truths are sliding, nothing overflows.
        await tester.pump(const Duration(milliseconds: 500));
        await _shoot(tester, '$phone-mid');
        await tester.pumpAndSettle();
        await _shoot(tester, '$phone-end');

        for (final year in ['2560 BC', '2000 BC', '30 BC', '1969']) {
          expect(find.text(year), findsOneWidget, reason: year);
        }
        // The mammoths were missed by most: theirs is the note said.
        expect(
          find.text(
            'Mammoths still lived on Wrangel Island after the pyramid.',
          ),
          findsOneWidget,
        );
        // Another lane with a note can be read by tapping it.
        await tester.tap(
          find.bySemanticsLabel('Cleopatra dies'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Cleopatra lived closer to the Moon landing than to the pyramid.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // And again, from the start.
        await tester.tap(find.bySemanticsLabel('Try again'));
        await tester.pumpAndSettle();
        expect(find.text('0 of 4'), findsOneWidget);
      });
    }

    for (final (name, height) in [('deep', 360.0), ('deep-back', 270.0)])
      testWidgets('$name: deep time on white ink and a dark card', (
        tester,
      ) async {
        _phone(tester, const Size(360, 740));
        final s = _parse(_deep);
        await tester.pumpWidget(
          _host(
            s,
            height: height,
            ground: const Color(0xFF3A2C8F),
            ink: const Color(0xFFFFFFFF),
          ),
        );
        await tester.pump(const Duration(seconds: 3));
        await _shoot(tester, '$name-start');
        final at = [0.12, 0.3, 0.45, 0.8, 0.95];
        for (var i = 0; i < s.events.length; i++) {
          await _place(tester, s.events[i].label, at[i]);
        }
        await tester.tap(find.text('LOCK IT IN'));
        await tester.pumpAndSettle();
        await _shoot(tester, '$name-end');
        expect(find.text('66 million'), findsOneWidget);
        expect(find.text('300,000'), findsOneWidget);
        expect(find.text('Our species is 300,000 years old.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

    testWidgets('with animations off the truth is there at once', (
      tester,
    ) async {
      _phone(tester, const Size(360, 740));
      final s = _parse(_calendar);
      await tester.pumpWidget(_host(s, height: 340, still: true));
      await tester.pump();
      for (final e in s.events) {
        await _place(tester, e.label, 0.5);
      }
      await tester.tap(find.text('LOCK IT IN'));
      await tester.pump();
      await tester.pump();
      expect(find.text('30 BC'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader can place every event and lock in', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      _phone(tester, const Size(360, 740));
      final s = _parse(_calendar);
      await tester.pumpWidget(_host(s, height: 340));
      await tester.pump(const Duration(seconds: 3));
      final owner = tester.binding.pipelineOwner.semanticsOwner!;
      for (final e in s.events) {
        final node = tester.getSemantics(find.bySemanticsLabel(e.label));
        expect(node.getSemanticsData().value, '?');
        owner.performAction(node.id, SemanticsAction.increase);
        await tester.pump();
      }
      expect(find.text('4 of 4'), findsOneWidget);
      final lock = tester.getSemantics(find.bySemanticsLabel('LOCK IT IN'));
      owner.performAction(lock.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.bySemanticsLabel('Cleopatra dies'));
      expect(node.getSemanticsData().value, startsWith('30 BC'));
      handle.dispose();
    });

    testWidgets('in the deck, a drag in the scene moves a knob, not the card, '
        'and a tap in it does not turn the card', (tester) async {
      _phone(tester, const Size(360, 740));
      final cards = [
        for (final c in jsonDecode(
          File('tool/cards/samples/timeline.json').readAsStringSync(),
        ) as List)
          cardFromJson((c as Map).cast<String, Object?>()),
      ];
      var advanced = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PillCardStack(
              deck: cards,
              index: 0,
              onAdvance: () => advanced++,
              answering: false,
              reviewIds: const {},
              answerFor: (_) => null,
              onAnswer: (_, _, _, _) {},
              isSaved: (_) => false,
              onSave: (_) {},
              onShare: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      final lane = tester.getRect(find.bySemanticsLabel('Cleopatra dies'));
      final g = await tester.startGesture(
        Offset(lane.left + 30, lane.top + lane.height * 0.7),
      );
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(-24, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(find.text('1 of 4'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel('Moon landing'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FlipCard>(find.byType(FlipCard).first).showBack,
        isFalse,
      );
      expect(find.text('2 of 4'), findsOneWidget);
    });
  });
}
