// Think like an expert (140a): the five experts the build carries, each
// with the question they always ask and the cards they are drawn to; a
// section's own experts; the pick, noted and remembered; a card opened
// among its expert's cards.
//
//   flutter test test/explore/screens_expert_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/explore/blocks/screens/expert.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/l10n/app_localizations_en.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

void main() {
  setUpAll(loadScreensFonts);

  final l = AppLocalizationsEn();

  /// A pool with a few cards for every built-in expert.
  List<Pill> pool() => [
    for (final String id in kBuiltInExperts)
      ...bankWhere(builtInExpert(id, l)!.fits!, most: 4),
  ];

  test('the five experts the build carries, each with what they ask', () {
    for (final String id in kBuiltInExperts) {
      final ScreenExpert e = builtInExpert(id, l)!;
      expect(e.name, isNotEmpty);
      expect(e.question, endsWith('?'));
      expect(e.kicker, contains(e.name.toLowerCase()));
      expect(
        bankWhere(e.fits!),
        hasLength(greaterThanOrEqualTo(2)),
        reason: id,
      );
    }
    expect(builtInExpert('astrologer', l), isNull);
  });

  test('a section names experts, changes one, or brings its own', () {
    final experts = expertsOf(
      screensSection('expert', {
        'experts': [
          'doctor',
          {
            'id': 'statistician',
            'question': {'en': 'Out of how many?', 'it': 'Su quanti?'},
          },
          {
            'id': 'chef',
            'name': {'en': 'Chef'},
            'as': {'en': 'Think like a chef'},
            'question': {'en': 'What does the heat do?'},
            'mark': 'food',
            'subjects': ['food'],
          },
          {'id': 'nameless', 'question': 'No name, no chip'},
          'doctor',
          42,
        ],
      }),
      l,
      'it',
    );
    expect([for (final e in experts) e.id], ['doctor', 'statistician', 'chef']);
    expect(experts[1].question, 'Su quanti?');
    expect(experts[1].mark, 'chart');
    expect(experts[2].mark, 'food');
    expect(experts[2].fits!(bankWhere((p) => p.topic == 'Food').first), isTrue);
    expect(
      experts[2].fits!(bankWhere((p) => p.topic == 'Space').first),
      isFalse,
    );
  });

  testWidgets('every expert drawn has a chip, and the first is lit', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = pool();
    await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert'),
      host,
    );
    for (final String id in kBuiltInExperts) {
      final bool first = id == kBuiltInExperts.first;
      // The row scrolls sideways: the last chips are past the edge.
      expect(
        find.byKey(
          ValueKey('expert-$id-${first ? 'on' : 'off'}'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    }
    expect(find.text('“${l.screensExpertStatisticianAsks}”'), findsOneWidget);
    expect(
      find.text(l.screensExpertStatisticianAs.toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('a pick is noted, remembered, and shows that expert', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = pool();
    await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert'),
      host,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('expert-historian-off')),
    );
    await tester.tap(find.byKey(const ValueKey('expert-historian-off')));
    await settle(tester);
    expect(find.byKey(const ValueKey('expert-historian-on')), findsOneWidget);
    expect(find.text('“${l.screensExpertHistorianAsks}”'), findsOneWidget);
    expect(host.notes.last.$2, 'expert picked');
    expect(host.notes.last.$3, {'expert': 'historian'});
    expect(ScreensMemory.instance.pick('x'), 'historian');
    // Drawn again, as on the next visit: still the historian.
    await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert'),
      host,
    );
    expect(find.byKey(const ValueKey('expert-historian-on')), findsOneWidget);
  });

  testWidgets('a card opens among its expert\'s cards', (tester) async {
    final app = await screensReader();
    final List<Pill> cards = pool();
    final host = FakeExploreHost(app)..cards['x'] = cards;
    await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert'),
      host,
    );
    final Pill hero = cards.firstWhere(builtInExpert('statistician', l)!.fits!);
    await tester.tap(find.byKey(ValueKey('explore-${hero.id}')));
    expect(host.opened, [('x', hero.id)]);
    expect(host.shown.map((s) => s.$2), contains(hero.id));
  });

  testWidgets('an expert with a source of its own gets those cards', (
    tester,
  ) async {
    final app = await screensReader();
    final List<Pill> own = bankWhere((p) => p.topic == 'Music', most: 3);
    final host = FakeExploreHost(app)..cards['x'] = const [];
    final bool drew = await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert', {
        'experts': [
          {
            'id': 'doctor',
            'source': {
              'ids': [for (final p in own) p.id],
            },
          },
        ],
      }),
      host,
    );
    expect(drew, isTrue);
    expect(find.byKey(ValueKey('explore-${own.first.id}')), findsOneWidget);
    // One expert is a question, not a choice: no chips.
    expect(find.byKey(const ValueKey('expert-doctor-on')), findsNothing);
  });

  testWidgets('an expert with fewer than two cards is left out', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)
      ..cards['x'] = bankWhere((p) => p.topic == 'Medicine', most: 1);
    final bool drew = await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert'),
      host,
    );
    expect(drew, isFalse);
  });

  testWidgets('small, the expert\'s cards are all in the row', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = pool();
    await pumpBlock(
      tester,
      const ExpertBlock(),
      screensSection('expert', {'size': 's', 'limit': 3}),
      host,
    );
    final ListView row = tester.widget<ListView>(
      find
          .byWidgetPredicate(
            (w) => w is ListView && w.scrollDirection == Axis.horizontal,
          )
          .last,
    );
    expect(row.childrenDelegate.estimatedChildCount, 5);
  });
}
