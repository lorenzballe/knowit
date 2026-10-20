// Connect the dots (140c): the meetings are the bank's own (a card of one
// subject tagged with a strand of another), seen from either side; the
// subject in the middle is picked, noted and remembered, from its chip or
// from a subject round it; the cards between are listed round the subjects
// met, and open among themselves.
//
//   flutter test test/explore/screens_dots_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/screens/connect_dots.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

/// Whether [p] is tagged with a strand of another subject.
bool _meets(Pill p) => p.also.any(
  (s) =>
      s.split('.').first != topicKeyForName(p.topic) &&
      kTopics.containsKey(s.split('.').first),
);

void main() {
  setUpAll(loadScreensFonts);

  test('a card meets the other subject it is tagged with, from both sides', () {
    final Pill card = bankWhere(_meets).first;
    final String own = topicKeyForName(card.topic)!;
    final String other = card.also
        .map((s) => s.split('.').first)
        .firstWhere((s) => s != own);
    final meetings = meetingsOf([card]);
    expect(meetings[own]!.single.other, other);
    expect(meetings[other]!.single.other, own);
    expect(meetings[other]!.single.pill.id, card.id);
  });

  test('meetings by hand are added, and a subject never meets itself', () {
    final Pill card = bankWhere((p) => p.topic == 'Food' && !_meets(p)).first;
    final meetings = meetingsOf(
      [card],
      extra: [(card, 'economics'), (card, 'food'), (card, 'astrology')],
    );
    expect(meetings.keys.toSet(), {'food', 'economics'});
    expect(meetings['food']!.single.other, 'economics');
  });

  testWidgets('the subject in the middle is picked from its chip', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = bankWhere(_meets);
    await pumpBlock(
      tester,
      const ConnectDotsBlock(),
      screensSection('connect-dots'),
      host,
    );
    final Finder off = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('dots-') &&
          (w.key! as ValueKey<String>).value.endsWith('-off'),
    );
    final String key =
        (tester.widget(off.first).key! as ValueKey<String>).value;
    final String subject = key.substring(5, key.length - 4);
    await tester.tap(off.first);
    await settle(tester);
    expect(find.byKey(ValueKey('dots-$subject-on')), findsOneWidget);
    expect(ScreensMemory.instance.pick('x'), subject);
    expect(host.notes.last.$2, 'subject picked');
    expect(host.notes.last.$3, {'subject': subject});
  });

  testWidgets('a subject round the middle becomes the middle', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = bankWhere(_meets);
    await pumpBlock(
      tester,
      const ConnectDotsBlock(),
      screensSection('connect-dots', {'subject': 'science'}),
      host,
    );
    expect(find.byKey(const ValueKey('dots-science-on')), findsOneWidget);
    // Space is the subject science meets most in the bank.
    await tester.tap(find.byKey(const ValueKey('dots-spoke-space')));
    await settle(tester);
    expect(ScreensMemory.instance.pick('x'), 'space');
  });

  testWidgets('the cards between are listed round the subjects met', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = bankWhere(_meets);
    await pumpBlock(
      tester,
      const ConnectDotsBlock(),
      screensSection('connect-dots', {'subject': 'science', 'limit': 4}),
      host,
    );
    final List<String> pairs = [
      for (final Text t in tester.widgetList<Text>(find.byType(Text)))
        if ((t.data ?? '').contains(' × ')) t.data!,
    ];
    expect(pairs, hasLength(4));
    // Science meets space most, and still the first cards each meet a
    // different subject.
    expect(pairs.take(3).toSet(), hasLength(3));
    // The meetings opened are the meetings listed.
    final Pill first = host.shown.isEmpty
        ? throw StateError('nothing shown')
        : bankWhere((p) => p.id == host.shown.first.$2).single;
    await tester.tap(find.byKey(ValueKey('explore-${first.id}')));
    expect(host.opened, [('x', first.id)]);
  });

  testWidgets('narrowed to a subject, that subject is the middle, alone', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app, subject: 'Science')
      ..cards['x'] = bankWhere((p) => _meets(p) && p.topic == 'Science');
    await pumpBlock(
      tester,
      const ConnectDotsBlock(),
      screensSection('connect-dots'),
      host,
    );
    expect(find.text('Science'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            RegExp(r'^dots-[a-z_]+-o(n|ff)$')
                .hasMatch((w.key! as ValueKey<String>).value),
      ),
      findsNothing,
    );
  });

  testWidgets('meetings written into the section are fetched as cards', (
    tester,
  ) async {
    final app = await screensReader();
    final List<Pill> food = bankWhere((p) => p.topic == 'Food', most: 2);
    final host = FakeExploreHost(app)..cards['x'] = const [];
    final bool drew = await pumpBlock(
      tester,
      const ConnectDotsBlock(),
      screensSection('connect-dots', {
        'pairs': [
          for (final p in food) {'card': p.id, 'with': 'economics'},
        ],
      }),
      host,
    );
    expect(drew, isTrue);
    expect(find.text('ECONOMICS × FOOD'), findsWidgets);
  });

  testWidgets('with no subject meeting two others, nothing is drawn', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)
      ..cards['x'] = bankWhere((p) => !_meets(p), most: 50);
    final bool drew = await pumpBlock(
      tester,
      const ConnectDotsBlock(),
      screensSection('connect-dots'),
      host,
    );
    expect(drew, isFalse);
  });
}
