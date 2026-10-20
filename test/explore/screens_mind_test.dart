// Change your mind (141d): the bank's true-or-false claims, the myths
// first; a stance before the evidence, taken once, noted, kept, and the
// card counted as read since its answer is on the shelf; a stance after,
// measured against what the evidence says; the tally of minds changed.
//
//   flutter test test/explore/screens_mind_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/explore/blocks/screens/change_your_mind.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/l10n/app_localizations_en.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

void main() {
  setUpAll(loadScreensFonts);

  final l = AppLocalizationsEn();

  /// A false myth, a true claim, and cards that are no claim at all.
  late Pill myth;
  late Pill truth;
  late List<Pill> notClaims;

  setUpAll(() {
    myth = bankWhere(
      (p) =>
          isTrueOrFalse(p) &&
          !trueOrFalseAnswer(p) &&
          p.hook == 'misconception',
    ).first;
    truth = bankWhere(
      (p) =>
          isTrueOrFalse(p) && trueOrFalseAnswer(p) && p.hook != 'misconception',
    ).first;
    notClaims = bankWhere((p) => !isTrueOrFalse(p), most: 3);
  });

  Future<FakeExploreHost> pump(
    WidgetTester tester, {
    Map<String, Object> stored = const {},
  }) async {
    final app = await screensReader(stored);
    final host = FakeExploreHost(app)..cards['x'] = [...notClaims, truth, myth];
    await pumpBlock(
      tester,
      const ChangeYourMindBlock(),
      screensSection('change-your-mind'),
      host,
    );
    return host;
  }

  testWidgets('only claims are drawn, the myths first', (tester) async {
    final host = await pump(tester);
    expect(host.shown.map((s) => s.$2).toSet(), {myth.id, truth.id});
    final double mythTop = tester
        .getTopLeft(find.byKey(ValueKey('mind-${myth.id}')))
        .dy;
    final double truthTop = tester
        .getTopLeft(find.byKey(ValueKey('mind-${truth.id}')))
        .dy;
    expect(mythTop, lessThan(truthTop));
    expect(find.text(claimOf(myth)), findsOneWidget);
    expect(find.text(l.screensMindFirst), findsOneWidget);
  });

  testWidgets('a stance before shows the evidence, and is taken once', (
    tester,
  ) async {
    final host = await pump(tester);
    expect(find.text(evidenceOf(myth)), findsNothing);
    await tester.tap(find.byKey(ValueKey('mind-before-${myth.id}-3')));
    await settle(tester);
    expect(find.text(evidenceOf(myth)), findsOneWidget);
    expect(ScreensMemory.instance.stance(myth.id).before, 3);
    expect(host.notes.single.$2, 'stance');
    expect(host.notes.single.$3, {
      'pill_id': myth.id,
      'when': 'before',
      'level': 3,
    });
    // The answer is on the shelf now: the card has been read.
    expect(host.app.seenIds, contains(myth.id));
    // A second tap on the first scale changes nothing.
    await tester.tap(find.byKey(ValueKey('mind-before-${myth.id}-0')));
    await settle(tester);
    expect(ScreensMemory.instance.stance(myth.id).before, 3);
    expect(host.notes, hasLength(1));
  });

  testWidgets('a stance after is measured against the evidence', (
    tester,
  ) async {
    final host = await pump(tester);
    // The myth is false: the evidence stands at strongly disagree.
    await tester.tap(find.byKey(ValueKey('mind-before-${myth.id}-3')));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('mind-after-${myth.id}-1')));
    await settle(tester);
    expect(find.text(l.screensMindToward(2)), findsOneWidget);
    expect(host.notes.last.$3['moved'], 2);
    expect(find.text(l.screensMindChanged(1, 1)), findsOneWidget);
    // The truth is true: from agree to disagree is away from it.
    await tester.ensureVisible(
      find.byKey(ValueKey('mind-before-${truth.id}-3')),
    );
    await tester.tap(find.byKey(ValueKey('mind-before-${truth.id}-3')));
    await settle(tester);
    await tester.ensureVisible(
      find.byKey(ValueKey('mind-after-${truth.id}-1')),
    );
    await tester.tap(find.byKey(ValueKey('mind-after-${truth.id}-1')));
    await settle(tester);
    expect(find.text(l.screensMindAway), findsOneWidget);
    expect(find.text(l.screensMindChanged(2, 2)), findsOneWidget);
  });

  testWidgets('what was answered before is drawn as it was left', (
    tester,
  ) async {
    final app = await screensReader();
    ScreensMemory.instance
      ..setBefore(myth.id, 0, on: '2026-10-19')
      ..setAfter(myth.id, 0)
      ..setBefore(truth.id, 2, on: '2026-10-19')
      ..setAfter(truth.id, 2);
    final host = FakeExploreHost(app)..cards['x'] = [truth, myth];
    await pumpBlock(
      tester,
      const ChangeYourMindBlock(),
      screensSection('change-your-mind'),
      host,
    );
    expect(find.text(l.screensMindAlready), findsOneWidget);
    expect(find.text(l.screensMindSame), findsOneWidget);
    expect(find.text(l.screensMindChanged(0, 2)), findsOneWidget);
  });

  testWidgets('the claim opens its card', (tester) async {
    final host = await pump(tester);
    await tester.tap(find.text(claimOf(myth)));
    expect(host.opened, [('x', myth.id)]);
  });
}
