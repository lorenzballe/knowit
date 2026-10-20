// Through time (141c): the stops, the bank's ages by default or the
// section's own; the ruler in powers of ten; travelling it with its buttons,
// a drag, a tap or a screen reader, noted and remembered; a stop with no
// cards left off, and a ruler of one stop not drawn.
//
//   flutter test test/explore/screens_time_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/explore/blocks/screens/through_time.dart';
import 'package:astuto/l10n/app_localizations_en.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

/// A few cards of every age the bank tags.
List<Pill> _ages() => [
  for (final String era in kBankEras)
    ...bankWhere((p) => p.era == era, most: 3),
];

void main() {
  setUpAll(loadScreensFonts);

  final l = AppLocalizationsEn();

  test('with no stops of its own, a section travels the bank\'s ages', () {
    final stops = stopsOf(
      screensSection('through-time'),
      l,
      'en',
      now: DateTime(2026, 10, 19),
    );
    expect(stops.map((s) => s.id), kBankEras);
    expect(stops.first.label, l.screensEraAncient);
    expect(stops.first.when, l.screensEraAncientWhen);
    expect(stops.first.ago, 2026);
    for (int i = 1; i < stops.length; i++) {
      expect(stops[i].ago, lessThan(stops[i - 1].ago));
    }
  });

  test('a section\'s own stops, oldest first, an age\'s words its own', () {
    final stops = stopsOf(
      screensSection('through-time', {
        'stops': [
          {'id': 'ages', 'era': 'medieval', 'ago': 1000},
          {
            'id': 'light',
            'ago': 13.8e9,
            'label': {'en': 'The first light', 'it': 'La prima luce'},
            'when': {'en': '13.8 billion years ago'},
            'source': {
              'ids': ['x'],
            },
          },
          {
            'id': 'nowhere',
            'ago': 5,
            'label': 'No cards anywhere',
            'when': 'x',
          },
          {'id': 'unread', 'ago': -3, 'era': 'recent'},
        ],
      }),
      l,
      'it',
    );
    expect(stops.map((s) => s.id), ['light', 'ages']);
    expect(stops.first.label, 'La prima luce');
    expect(stops.first.when, '13.8 billion years ago');
    expect(stops.last.label, l.screensEraMedieval);
  });

  test('the ruler: the far end at 0, now at 1, a tick for every power', () {
    expect(rulerPlace(13.8e9, 10.14), closeTo(0, 0.001));
    expect(rulerPlace(1, 10.14), 1);
    expect(rulerPlace(0, 10.14), 1);
    expect(rulerPlace(1e6, 10.14), closeTo(0.408, 0.001));
    // A long ruler names a thousand, a million, a billion where there is
    // room; a short one every power.
    expect(rulerLabels(10.14), [6, 3]);
    expect(rulerLabels(3.3), [2, 1]);
  });

  testWidgets('the buttons travel, noted and remembered', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = _ages();
    await pumpBlock(
      tester,
      const ThroughTimeBlock(),
      screensSection('through-time'),
      host,
    );
    expect(find.text(l.screensEraAncientWhen), findsOneWidget);
    // At the far end there is nowhere further back to go.
    await tester.tap(find.byKey(const ValueKey('time-back')));
    await settle(tester);
    expect(host.notes, isEmpty);
    await tester.tap(find.byKey(const ValueKey('time-on')));
    await settle(tester);
    expect(find.text(l.screensEraMedievalWhen), findsOneWidget);
    expect(host.notes.single.$2, 'era picked');
    expect(host.notes.single.$3, {'stop': 'medieval'});
    expect(ScreensMemory.instance.pick('x'), 'medieval');
    await pumpBlock(
      tester,
      const ThroughTimeBlock(),
      screensSection('through-time'),
      host,
    );
    expect(find.text(l.screensEraMedievalWhen), findsOneWidget);
  });

  testWidgets('a tap on the ruler goes to the nearest stop', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = _ages();
    await pumpBlock(
      tester,
      const ThroughTimeBlock(),
      screensSection('through-time'),
      host,
    );
    final Rect ruler = tester.getRect(find.byKey(const ValueKey('time-ruler')));
    await tester.tapAt(ruler.centerRight - const Offset(4, 0));
    await settle(tester);
    expect(find.text(l.screensEraRecentWhen), findsOneWidget);
    await tester.dragFrom(
      ruler.centerRight - const Offset(4, 0),
      Offset(-ruler.width + 8, 0),
    );
    await settle(tester);
    expect(find.text(l.screensEraAncientWhen), findsOneWidget);
  });

  testWidgets('a screen reader moves along the ruler as along a slider', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = _ages();
    await pumpBlock(
      tester,
      const ThroughTimeBlock(),
      screensSection('through-time'),
      host,
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('time-ruler'))),
      matchesSemantics(
        isSlider: true,
        value: '${l.screensEraAncient}, ${l.screensEraAncientWhen}',
        increasedValue: '${l.screensEraMedieval}, ${l.screensEraMedievalWhen}',
        hasIncreaseAction: true,
      ),
    );
    final Semantics slider = tester.widget<Semantics>(
      find.ancestor(
        of: find.byKey(const ValueKey('time-ruler')),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.slider == true,
        ),
      ),
    );
    slider.properties.onIncrease!();
    await settle(tester);
    expect(find.text(l.screensEraMedievalWhen), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an age with no cards is left off; one age is no journey', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)
      ..cards['x'] = [
        ...bankWhere((p) => p.era == 'medieval', most: 2),
        ...bankWhere((p) => p.era == 'recent', most: 2),
      ];
    await pumpBlock(
      tester,
      const ThroughTimeBlock(),
      screensSection('through-time'),
      host,
    );
    expect(find.text(l.screensEraMedievalWhen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('time-on')));
    await settle(tester);
    expect(find.text(l.screensEraRecentWhen), findsOneWidget);
    host.cards['x'] = bankWhere((p) => p.era == 'recent', most: 2);
    expect(
      await pumpBlock(
        tester,
        const ThroughTimeBlock(),
        screensSection('through-time'),
        host,
      ),
      isFalse,
    );
  });

  testWidgets('a stop of the section\'s own shows its own cards', (
    tester,
  ) async {
    final app = await screensReader();
    final Pill first = bankWhere((p) => p.topic == 'Space').first;
    final host = FakeExploreHost(app)..cards['x'] = _ages();
    await pumpBlock(
      tester,
      const ThroughTimeBlock(),
      screensSection('through-time', {
        'limit': 1,
        'stops': [
          {
            'id': 'light',
            'ago': 13.8e9,
            'label': 'The first light',
            'when': '13.8 billion years ago',
            'source': {
              'ids': [first.id],
            },
          },
          {'id': 'recent', 'era': 'recent', 'ago': 14},
        ],
      }),
      host,
    );
    expect(find.text('13.8 billion years ago'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('explore-${first.id}')));
    expect(host.opened, [('x', first.id)]);
  });
}
