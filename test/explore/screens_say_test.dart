// Say it tonight (141e): only claims that are true make a line; "I said
// it" is the said the readers' top already counts, said once and for good,
// noted, and kept with its day so the week can be counted; a line opens its
// card.
//
//   flutter test test/explore/screens_say_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/explore/blocks/screens/say_it_tonight.dart';
import 'package:astuto/l10n/app_localizations_en.dart';
import 'package:astuto/models/pill.dart';

import 'fake_host.dart';
import 'screens_harness.dart';

void main() {
  setUpAll(loadScreensFonts);

  final l = AppLocalizationsEn();

  late List<Pill> lines;
  late List<Pill> notLines;

  setUpAll(() {
    lines = bankWhere(makesALine, most: 3);
    notLines = [
      ...bankWhere((p) => isTrueOrFalse(p) && !trueOrFalseAnswer(p), most: 2),
      ...bankWhere((p) => !isTrueOrFalse(p), most: 2),
    ];
  });

  test('a line is a claim that is true', () {
    for (final Pill p in lines) {
      expect(isTrueOrFalse(p) && trueOrFalseAnswer(p), isTrue);
      expect(reasonOf(p).toLowerCase().startsWith('true'), isFalse);
    }
    for (final Pill p in notLines) {
      expect(makesALine(p), isFalse);
    }
  });

  test('the week is counted from Monday to Sunday', () {
    final DateTime wednesday = DateTime(2026, 10, 21);
    expect(
      saidThisWeek({
        'a': '2026-10-19',
        'b': '2026-10-25',
        'c': '2026-10-18',
        'd': '2026-10-26',
      }, wednesday),
      2,
    );
    expect(saidThisWeek(const {}, wednesday), 0);
  });

  testWidgets('only lines are drawn, the first as tonight\'s', (tester) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = [...notLines, ...lines];
    await pumpBlock(
      tester,
      const SayItTonightBlock(),
      screensSection('say-it-tonight'),
      host,
    );
    expect(host.shown.map((s) => s.$2).toSet(), {for (final p in lines) p.id});
    expect(
      find.textContaining(l.screensSayTonight.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(claimOf(lines.first)), findsOneWidget);
    expect(find.text(l.screensSayWeek(0)), findsOneWidget);
  });

  testWidgets('a line said is said for good, noted and counted', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = lines;
    await pumpBlock(
      tester,
      const SayItTonightBlock(),
      screensSection('say-it-tonight'),
      host,
    );
    final Pill line = lines.first;
    await tester.tap(find.byKey(ValueKey('say-${line.id}-not')));
    await settle(tester);
    expect(app.saidIds, contains(line.id));
    expect(ScreensMemory.instance.said[line.id], screensDayKey(DateTime.now()));
    expect(host.notes.single.$2, 'said');
    expect(host.notes.single.$3, {'pill_id': line.id});
    expect(find.byKey(ValueKey('say-${line.id}-said')), findsOneWidget);
    expect(find.text(l.screensSayWeek(1)), findsOneWidget);
    // Said is said: the button does nothing more.
    await tester.tap(find.byKey(ValueKey('say-${line.id}-said')));
    await settle(tester);
    expect(host.notes, hasLength(1));
    expect(app.saidIds.where((id) => id == line.id), hasLength(1));
  });

  testWidgets('a line said before shows said', (tester) async {
    final app = await screensReader({
      'knowit.saidIds': [bankWhere(makesALine).first.id],
    });
    final host = FakeExploreHost(app)..cards['x'] = lines;
    await pumpBlock(
      tester,
      const SayItTonightBlock(),
      screensSection('say-it-tonight'),
      host,
    );
    expect(find.byKey(ValueKey('say-${lines.first.id}-said')), findsOneWidget);
    // Said before these screens kept days: not this week's.
    expect(find.text(l.screensSayWeek(0)), findsOneWidget);
  });

  testWidgets('small, every line is in the row; a line opens its card', (
    tester,
  ) async {
    final app = await screensReader();
    final host = FakeExploreHost(app)..cards['x'] = lines;
    await pumpBlock(
      tester,
      const SayItTonightBlock(),
      screensSection('say-it-tonight', {
        'size': 's',
        'style': {'counter': false},
      }),
      host,
    );
    expect(
      find.textContaining(l.screensSayTonight.toUpperCase()),
      findsNothing,
    );
    expect(find.text(l.screensSayCounts), findsNothing);
    await tester.tap(find.byKey(ValueKey('explore-${lines.first.id}')));
    expect(host.opened, [('x', lines.first.id)]);
  });
}
