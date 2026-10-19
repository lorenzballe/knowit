// What a reader does on the purpose family's shelves, and what each shelf
// does with it: answers recorded as the card would record them, marks,
// picks and tricks kept for the day and noted, a filter that narrows, sets
// that count what was read.
//
//   flutter test test/explore/purpose_play_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart' show percentOf;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/purpose/kit.dart' show PurposePlay;
import 'package:astuto/explore/blocks/purpose/read_or_do.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';

import 'fake_host.dart';
import 'purpose_harness.dart';

final AppLocalizations l = lookupAppLocalizations(const Locale('en'));

/// The card a widget keyed `<prefix><id><suffix>` is for.
Pill cardOf(Finder found, String prefix, [String suffix = '']) {
  final String key =
      (found.evaluate().first.widget.key! as ValueKey<String>).value;
  final String id = key.substring(prefix.length, key.length - suffix.length);
  return PillBank.byId(id)!;
}

/// The first card on a commit shelf.
Pill firstCommitCard() {
  for (final Element e in keyedLike(
    (k) => k.startsWith('commit-'),
  ).evaluate()) {
    final String id = (e.widget.key! as ValueKey<String>).value.substring(
      'commit-'.length,
    );
    final Pill? p = PillBank.byId(id);
    if (p != null) return p;
  }
  throw StateError('no card on the shelf');
}

/// Checks the last thing [host] was told to note.
void expectNoted(
  FakeExploreHost host,
  String event,
  Map<String, Object?> facts,
) {
  expect(host.notes, isNotEmpty);
  expect(host.notes.last.$1, 'x');
  expect(host.notes.last.$2, event);
  expect(host.notes.last.$3, facts);
}

void main() {
  setUp(ExplorePlay.resetForTest);

  group('purpose.commit', () {
    testWidgets('true or false, answered on the shelf, says if it was right', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.commit'),
        host,
        purposeSection('purpose.commit', {'kind': 'true-false'}),
      );
      final Pill p = firstCommitCard();
      final PickOne c = p.challenge as PickOne;
      await tester.tap(find.byKey(ValueKey('commit-${p.id}-${c.correct}')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(host.answered, [(p.id, '${c.correct}')]);
      expect(PurposePlay.setOf('said'), {p.id});
      expect(find.text(l.tfRight), findsOneWidget);
      // Answered once: the buttons take no second answer.
      await tester.tap(
        find.byKey(ValueKey('commit-${p.id}-${1 - c.correct}')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(host.answered, hasLength(1));
    });

    testWidgets('a side is taken as the card takes it, by its index', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.commit'),
        host,
        purposeSection('purpose.commit', {'kind': 'side'}),
      );
      final Finder no = keyedLike(
        (k) => k.startsWith('commit-') && k.endsWith('-1'),
      );
      final Pill p = cardOf(no, 'commit-', '-1');
      expect(p.challenge, isA<TakeASide>());
      // Debates taken already are not asked again.
      expect(takenDebates().map((d) => d.id), isNot(contains(p.id)));
      await tester.tap(no.first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(host.answered, [(p.id, '1')]);
    });

    testWidgets('three amounts: a wrong one is struck, the right one ticked', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.commit'),
        host,
        purposeSection('purpose.commit', {'kind': 'pick'}),
      );
      final Pill p = firstCommitCard();
      final PickOne c = p.challenge as PickOne;
      final int wrong = (c.correct + 1) % c.options.length;
      await tester.tap(find.byKey(ValueKey('commit-${p.id}-$wrong')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(host.answered, [(p.id, '$wrong')]);
      final Text struck = tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey('commit-${p.id}-$wrong')),
          matching: find.text(c.options[wrong]),
        ),
      );
      expect(struck.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('a card answered before is not asked again; one answered '
        'here today keeps its verdict', (tester) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      final Pill p = PillBank.cards.firstWhere(
        (p) => isTf(p) && !app.seenIds.contains(p.id),
      );
      await tester.runAsync(() => app.recordAnswer(p.id, '0'));
      host.cards['x'] = [p];
      Built built = await pumpPurpose(
        tester,
        purposeBlock('purpose.commit'),
        host,
        purposeSection('purpose.commit'),
      );
      expect(built.widget, isNull);
      PurposePlay.said(p.id);
      built = await pumpPurpose(
        tester,
        purposeBlock('purpose.commit'),
        host,
        purposeSection('purpose.commit'),
      );
      expect(built.widget, isNotNull);
      expect(find.byKey(ValueKey('commit-verdict-${p.id}')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('commit-${p.id}-1')));
      await tester.pump();
      expect(host.answered, isEmpty);
    });
  });

  group('purpose.in-your-head', () {
    testWidgets('the number typed in the box is the card\'s answer', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.in-your-head'),
        host,
        purposeSection('purpose.in-your-head'),
      );
      final Finder box = keyedLike((k) => k.startsWith('head-box-'));
      final Pill p = cardOf(box, 'head-box-');
      await tester.tap(box.first);
      await tester.pump();
      // Nothing that is not a number is taken.
      await tester.enterText(find.byKey(ValueKey('head-field-${p.id}')), 'ab');
      await tester.tap(find.byKey(ValueKey('head-send-${p.id}')));
      await tester.pump();
      expect(host.answered, isEmpty);
      final num answer = switch (p.challenge) {
        TypeNumber(:final answer) || Estimate(:final answer) => answer,
        _ => throw StateError('not a number card'),
      };
      await tester.enterText(
        find.byKey(ValueKey('head-field-${p.id}')),
        '$answer',
      );
      await tester.tap(find.byKey(ValueKey('head-send-${p.id}')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(host.answered.single.$1, p.id);
      expect(p.challenge.accepts(host.answered.single.$2), isTrue);
      expect(PurposePlay.setOf('said'), {p.id});
      expect(find.text(l.tfRight), findsOneWidget);
    });
  });

  group('purpose.thats-me', () {
    testWidgets('a mark is kept for the day, counted and noted', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.thats-me'),
        host,
        purposeSection('purpose.thats-me'),
      );
      expect(find.text(l.purposeMeFooter), findsOneWidget);
      final Finder off = keyedLike(
        (k) => k.startsWith('me-') && k.endsWith('-off'),
      );
      final Pill p = cardOf(off, 'me-', '-off');
      await tester.tap(off.first);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(ValueKey('me-${p.id}-on')), findsOneWidget);
      expect(find.text(l.purposeMeMarked(1)), findsOneWidget);
      expect(PurposePlay.setOf('me:x'), {p.id});
      expectNoted(host, 'thats me', {'pill_id': p.id, 'on': true});
      // And unmarked again.
      await tester.tap(find.byKey(ValueKey('me-${p.id}-on')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(PurposePlay.setOf('me:x'), isEmpty);
      expect(host.notes.last.$3['on'], false);
      expect(find.text(l.purposeMeFooter), findsOneWidget);
    });

    testWidgets('every card on it is about something people do', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.thats-me'),
        host,
        purposeSection('purpose.thats-me', {'limit': 3}),
      );
      expect(host.shown, hasLength(3));
      for (final (String _, String id) in host.shown) {
        final Pill p = PillBank.byId(id)!;
        expect(p.challenge, isNot(isA<TakeASide>()));
        expect(p.hook, isNot('story'));
      }
    });
  });

  group('purpose.life-topics', () {
    testWidgets('a pick brings the cards that ask about it, and is noted', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.life-topics'),
        host,
        purposeSection('purpose.life-topics', {
          'topics': ['money', 'love', 'body'],
        }),
      );
      // A part of life this build does not know is passed over.
      expect(keyedLike((k) => k.startsWith('life-')), findsNWidgets(2));
      expect(keyedLike((k) => k.startsWith('explore-')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('life-money-off')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('life-money-on')), findsOneWidget);
      expect(keyedLike((k) => k.startsWith('explore-')), findsWidgets);
      expect(PurposePlay.setOf('life:x'), {'money'});
      expectNoted(host, 'life topics', {'topic': 'money', 'on': true});
      for (final (String _, String id) in host.shown) {
        expect(
          PillBank.byId(id)!.genre,
          matches(RegExp(r'^(economics|life)\.')),
        );
      }
    });
  });

  group('purpose.spot-trick', () {
    testWidgets('a pick says whether it was the card\'s move', (tester) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.spot-trick'),
        host,
        purposeSection('purpose.spot-trick'),
      );
      final Pill p = PillBank.byId(host.shown.first.$2)!;
      final Principle wrong = Principle.values.firstWhere(
        (m) =>
            m != p.principle &&
            find
                .byKey(ValueKey('trick-${p.id}-${m.name}'))
                .evaluate()
                .isNotEmpty,
      );
      expect(
        find.byKey(ValueKey('trick-${p.id}-${p.principle.name}')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey('trick-${p.id}-${wrong.name}')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text(l.tfWrong(l.purposeMoveName(p.principle.name))),
        findsOneWidget,
      );
      expect(host.notes.last.$2, 'trick spotted');
      expect(host.notes.last.$3, {
        'pill_id': p.id,
        'move': wrong.name,
        'right': false,
      });
      // One pick a card: the others take no tap.
      await tester.tap(
        find.byKey(ValueKey('trick-${p.id}-${p.principle.name}')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(host.notes.where((n) => n.$2 == 'trick spotted'), hasLength(1));
    });
  });

  group('purpose.played', () {
    testWidgets('counts what was played today, and only that', (tester) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.played'),
        host,
        purposeSection('purpose.played'),
      );
      expect(find.text('–'), findsNWidgets(3));
      final Pill share = PillBank.cards.firstWhere((p) => percentOf(p) != null);
      ExplorePlay.instance.put('slide:${share.id}', {
        'v': percentOf(share)!.value + 12,
        'ck': true,
      });
      PurposePlay.write('tricks', {
        'a': {'move': 'baseRate', 'right': true},
        'b': {'move': 'sampling', 'right': false},
      });
      PurposePlay.said('c');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('12'), findsOneWidget);
      expect(find.text(l.purposeOf(1, 2)), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('with no cards and nothing played, is left out', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app)..cards['x'] = const [];
      Built built = await pumpPurpose(
        tester,
        purposeBlock('purpose.played'),
        host,
        purposeSection('purpose.played'),
      );
      expect(built.widget, isNull);
      PurposePlay.said('c');
      built = await pumpPurpose(
        tester,
        purposeBlock('purpose.played'),
        host,
        purposeSection('purpose.played'),
      );
      expect(built.widget, isNotNull);
    });
  });

  group('purpose.read-or-do', () {
    testWidgets('the filter narrows every shelf, and is kept and noted', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.read-or-do'),
        host,
        purposeSection('purpose.read-or-do'),
      );
      Iterable<Pill> shown() => [
        for (final Element e in keyedLike(
          (k) => k.startsWith('verb-'),
        ).evaluate())
          PillBank.byId(
            (e.widget.key! as ValueKey<String>).value.substring('verb-'.length),
          )!,
      ];
      expect(shown().map((p) => isToDo(verbOf(p))).toSet(), {true, false});
      await tester.tap(find.byKey(const ValueKey('read-or-do-x-2-off')));
      await tester.pump(const Duration(milliseconds: 300));
      expectNoted(host, 'read or do', {'filter': 'toDo'});
      expect(shown(), isNotEmpty);
      expect(shown().every((p) => isToDo(verbOf(p))), isTrue);
      expect(find.byKey(const ValueKey('read-or-do-x-2-on')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('read-or-do-x-1-off')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(shown(), isNotEmpty);
      expect(shown().every((p) => !isToDo(verbOf(p))), isTrue);
    });
  });

  group('purpose.set and its stamps', () {
    testWidgets('a set counts what was read, and a finished one fans out', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final List<Pill> read = readCards().take(5).toList();
      final List<Pill> unread = PillBank.cards
          .where((p) => !app.seenIds.contains(p.id))
          .take(3)
          .toList();
      final FakeExploreHost host = FakeExploreHost(app)
        ..cards['x'] = [...read, ...unread];
      final Map<String, Object?> fromSource = {
        'source': {'kind': 'given'},
        'title': {'en': 'Mine'},
      };
      await pumpPurpose(
        tester,
        purposeBlock('purpose.set'),
        host,
        purposeSection('purpose.set', fromSource),
      );
      expect(find.text(l.purposeSetRead(5, 8)), findsOneWidget);
      expect(keyedLike((k) => k.startsWith('set-read-')), findsWidgets);
      host.cards['x'] = read;
      await pumpPurpose(
        tester,
        purposeBlock('purpose.set'),
        host,
        purposeSection('purpose.set', fromSource),
      );
      expect(find.byKey(const ValueKey('set-finished')), findsOneWidget);
      expect(find.text(l.purposeSetDone(5)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('set-finished')));
      await tester.pump();
      expect(host.opened, [('x', read.first.id)]);
    });

    testWidgets('a set from a source with no title is left out', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final Built built = await pumpPurpose(
        tester,
        purposeBlock('purpose.set'),
        FakeExploreHost(app),
        purposeSection('purpose.set', {
          'source': {'kind': 'given'},
        }),
      );
      expect(built.widget, isNull);
    });

    testWidgets('a theme this build does not know leaves the set out', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      for (final String block in ['purpose.set', 'purpose.stamps']) {
        final Built built = await pumpPurpose(
          tester,
          purposeBlock(block),
          FakeExploreHost(app),
          purposeSection(block, {'theme': 'dragons'}),
        );
        expect(built.widget, isNull, reason: block);
      }
    });

    testWidgets('stamps carry the section\'s labels and count the read', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final List<Pill> read = readCards().take(2).toList();
      final List<Pill> unread = PillBank.cards
          .where((p) => !app.seenIds.contains(p.id))
          .take(2)
          .toList();
      final FakeExploreHost host = FakeExploreHost(app)
        ..cards['x'] = [...read, ...unread];
      await pumpPurpose(
        tester,
        purposeBlock('purpose.stamps'),
        host,
        purposeSection('purpose.stamps', {
          'source': {'kind': 'given'},
          'title': {'en': 'Europe'},
          'labels': {read.first.id: 'HU', unread.first.id: 'FR'},
        }),
      );
      expect(find.text('HU'), findsOneWidget);
      expect(find.text('FR'), findsOneWidget);
      expect(find.text(l.purposeOf(2, 4)), findsOneWidget);
    });
  });

  group('purpose.sets', () {
    testWidgets('each set the section names, with how far along it is', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.sets'),
        host,
        purposeSection('purpose.sets', {
          'sets': [
            {'id': 'a', 'theme': 'myths'},
            {'id': 'b', 'theme': 'dragons'},
            {
              'id': 'c',
              'source': {'kind': 'given'},
              'title': 'Mine',
            },
          ],
        }),
      );
      expect(find.byKey(const ValueKey('sets-x/a')), findsOneWidget);
      expect(find.byKey(const ValueKey('sets-x/b')), findsNothing);
      expect(find.byKey(const ValueKey('sets-x/c')), findsOneWidget);
      expect(find.text(l.themeMyths), findsOneWidget);
      expect(find.text('Mine'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sets-x/a')));
      await tester.pump();
      expect(host.opened.single.$1, 'x/a');
    });
  });

  group('words of the section\'s own', () {
    testWidgets('a move named, with its name and line in the app\'s words', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      await pumpPurpose(
        tester,
        purposeBlock('purpose.move'),
        FakeExploreHost(app),
        purposeSection('purpose.move', {'move': 'survivorship'}),
      );
      expect(find.text(Principle.survivorship.label), findsOneWidget);
      expect(find.text(Principle.survivorship.oneLine), findsOneWidget);
      expect(find.text(l.purposeMoveNew(10)), findsOneWidget);
    });

    testWidgets('a question for your own life, by its topic', (tester) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      await pumpPurpose(
        tester,
        purposeBlock('purpose.life-question'),
        FakeExploreHost(app),
        purposeSection('purpose.life-question', {'topic': 'time'}),
      );
      expect(find.text(l.purposeLifeQuestion('clock')), findsOneWidget);
      final Built built = await pumpPurpose(
        tester,
        purposeBlock('purpose.life-question'),
        FakeExploreHost(app),
        purposeSection('purpose.life-question', {'topic': 'love'}),
      );
      expect(built.widget, isNull);
    });

    testWidgets('what to keep: the moves named, or nothing for unknown ones', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      await pumpPurpose(
        tester,
        purposeBlock('purpose.keep'),
        FakeExploreHost(app),
        purposeSection('purpose.keep', {
          'moves': ['baseRate', 'luck'],
        }),
      );
      expect(find.text(l.purposeKeepHeading('1')), findsOneWidget);
      expect(find.text(l.purposeMoveAsk('baseRate')), findsOneWidget);
      final Built built = await pumpPurpose(
        tester,
        purposeBlock('purpose.keep'),
        FakeExploreHost(app),
        purposeSection('purpose.keep', {
          'moves': ['luck'],
        }),
      );
      expect(built.widget, isNull);
    });

    testWidgets('still moving says when a card was brought up to date', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final Pill p = PillBank.cards.firstWhere((p) => p.shelfLife == 'years');
      final FakeExploreHost host = FakeExploreHost(app)..cards['x'] = [p];
      await pumpPurpose(
        tester,
        purposeBlock('purpose.moving'),
        host,
        purposeSection('purpose.moving', {
          'updated': {p.id: '2026-10-04'},
        }),
      );
      expect(
        find.text(l.purposeMovingUpdated('Oct 4').toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('tomorrow\'s shelves, as the section names them', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      await pumpPurpose(
        tester,
        purposeBlock('purpose.tomorrow'),
        FakeExploreHost(app),
        purposeSection('purpose.tomorrow', {
          'shelves': [
            {'title': 'Where it came from'},
            {'subtitle': 'No name, passed over'},
          ],
        }),
      );
      expect(find.text('Where it came from'), findsOneWidget);
      expect(find.text('No name, passed over'), findsNothing);
    });

    testWidgets('the other side names the side the reader took', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(purposeReader) as AppState;
      final FakeExploreHost host = FakeExploreHost(app);
      await pumpPurpose(
        tester,
        purposeBlock('purpose.other-side'),
        host,
        purposeSection('purpose.other-side'),
      );
      expect(host.shown, isNotEmpty);
      final Set<String> taken = {for (final p in takenDebates()) p.id};
      for (final (String _, String id) in host.shown) {
        expect(taken, contains(id));
      }
    });
  });
}

/// Whether [p] is a true-or-false card.
bool isTf(Pill p) {
  final Challenge c = p.challenge;
  return c is PickOne &&
      c.options.map((o) => o.toLowerCase()).toSet().containsAll({
        'true',
        'false',
      });
}
