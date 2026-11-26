// Explore's top list says what readers kept, so it is real readers' counts
// and nothing else: no crowd made up under them. Until real readers make a
// list worth showing — five cards, three readers each — Astute's own picks
// stand in its place, in the same frame and the same row, under their own
// name and without the numbers; once they do, the list is the one it always
// was. A server's Explore from before has its lists dropped, and the phone
// ranks its own counts; loved since the start keeps to the same numbers.
//
//   flutter test test/explore/top_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/sync/tally.dart';
import 'package:astuto/widgets/explore/first_shelves.dart';

import 'core_harness.dart';

/// The days a count is filed under, [days] closed days back from now.
String _ago(int days) =>
    tallyDay(DateTime.now().subtract(Duration(days: days)));

/// [n] cards of the bank of [topic] (any when none), from [skip].
List<Pill> _cards(int n, {String? topic, int skip = 0}) => PillBank.cards
    .where((p) => topic == null || p.topic == topic)
    .skip(skip)
    .take(n)
    .toList();

/// Counts as the store holds them, read, and made the app's list.
Future<Tallies> _counted(
  WidgetTester tester,
  Map<String, Map<String, int>> days, {
  Map<String, int> totals = const {},
}) async {
  // The settled days are kept on the phone: a phone to keep them on.
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  final MemoryTallyStore store = MemoryTallyStore(days);
  store.totals.addAll(totals);
  final Tallies tallies = Tallies(storeOverride: store);
  Tallies.useForTest(tallies);
  addTearDown(() => Tallies.useForTest(Tallies()));
  await tester.runAsync(tallies.refresh);
  return tallies;
}

/// Each of [cards] held by [readers], on one closed day.
Map<String, int> _held(List<Pill> cards, int readers) => {
  for (final Pill p in cards) p.id: readers,
};

final Finder _picks = find.byKey(const ValueKey('top-picks'));
final Finder _readers = find.byKey(const ValueKey('top-readers'));

/// Every place drawn with a number on it.
final Finder _numbered = find.byWidgetPredicate(
  (w) => w is TopPlace && w.rank != null,
);

void main() {
  setUpAll(loadFonts);
  setUp(() => Served.useForTest(Served()));

  final List<ExploreSection> top = sectionsOf([
    {'id': 'top', 'block': 'top'},
  ]);

  group('until real readers make a list', () {
    testWidgets('Astute\'s picks stand in its place, said to be Astute\'s, '
        'with no number and no window to switch', (tester) async {
      await _counted(tester, {});
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, top, size: const Size(390, 844));

      expect(_picks, findsOneWidget);
      expect(find.text('Worth your time'), findsOneWidget);
      expect(
        find.text("Picked by Astute while the readers' list fills up"),
        findsOneWidget,
      );
      expect(_readers, findsNothing);
      expect(find.text('Top of the week'), findsNothing);
      expect(find.byType(WindowSwitch), findsNothing);
      expect(find.byType(TopPlace), findsWidgets);
      expect(_numbered, findsNothing);

      // The cards that ask the most, round the subjects, the same for
      // everybody this week: pickedPills, keyed apart from the list's.
      final List<Pill> picked = pickedPills(
        seed: 'picks:${weekSeed(DateTime.now())}',
        count: 40,
      ).take(10).toList();
      final Finder first = find.byKey(ValueKey('picks-${picked[0].id}'));
      final Finder second = find.byKey(ValueKey('picks-${picked[1].id}'));
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(tester.getCenter(first).dx, lessThan(tester.getCenter(second).dx));
      expect(find.byKey(ValueKey('top-${picked[0].id}')), findsNothing);
      expect(picked.every((p) => !p.isAboutAPlace && p.book == null), isTrue);

      await tester.tap(first);
      expect(host.opened, [('top', picked[0].id)]);
    });

    testWidgets('and before the counts are read at all', (tester) async {
      Tallies.useForTest(Tallies());
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, top);
      expect(Tallies.instance.answered, isFalse);
      expect(_picks, findsOneWidget);
      expect(_numbered, findsNothing);
    });

    testWidgets('a section\'s own name for the readers\' list never stands '
        'over the picks', (tester) async {
      await _counted(tester, {});
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(
        tester,
        host,
        sectionsOf([
          {
            'id': 'top',
            'block': 'top',
            'title': {'en': 'What everyone is reading'},
            'subtitle': {'en': 'Most loved this week'},
          },
        ]),
      );
      expect(find.text('Worth your time'), findsOneWidget);
      expect(find.text('What everyone is reading'), findsNothing);
      expect(find.text('Most loved this week'), findsNothing);
    });

    testWidgets('four cards, however many readers held them, are not a list, '
        'nor is any number of cards two readers held', (tester) async {
      await _counted(tester, {
        _ago(Tallies.closedAfter): {
          ..._held(_cards(4), 50),
          ..._held(_cards(8, skip: 4), 2),
        },
      });
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, top);
      expect(_picks, findsOneWidget);
      expect(_readers, findsNothing);
    });

    testWidgets('in Italian, plainly Astute\'s', (tester) async {
      await _counted(tester, {});
      final CoreHost host = CoreHost(await readyApp(), language: 'it');
      await pumpSections(tester, host, top, locale: const Locale('it'));
      expect(find.text('Meritano il tuo tempo'), findsOneWidget);
      expect(
        find.text(
          'Scelte da Astute mentre si riempie la classifica dei lettori',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a subject with no list of its own has the picks of that '
        'subject', (tester) async {
      await _counted(tester, {
        _ago(Tallies.closedAfter): _held(_cards(5, topic: 'Space'), 3),
      });
      final CoreHost host = CoreHost(await readyApp(), subject: 'History');
      await pumpSections(tester, host, top);
      expect(_picks, findsOneWidget);
      final List<String> keys = [
        for (final Element e
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith('picks-') &&
                      !(w.key! as ValueKey<String>).value.startsWith(
                        'picks-read',
                      ),
                )
                .evaluate())
          (e.widget.key! as ValueKey<String>).value.substring('picks-'.length),
      ];
      expect(keys, isNotEmpty);
      expect(keys.every((id) => PillBank.byId(id)!.topic == 'History'), isTrue);
    });
  });

  group('once real readers make one', () {
    testWidgets('five cards held by three readers each are the top of the '
        'week, numbered, at the picks\' height, and what fewer held is not on '
        'it', (tester) async {
      final List<Pill> five = _cards(5);
      final Pill few = _cards(1, skip: 5).single;
      await _counted(tester, {
        _ago(Tallies.closedAfter): {..._held(five, 3), few.id: 2},
        _ago(Tallies.closedAfter + 1): {five[0].id: 6},
      });
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, top, size: const Size(390, 844));

      expect(_readers, findsOneWidget);
      expect(_picks, findsNothing);
      expect(find.text('Top of the week'), findsOneWidget);
      expect(
        find.text('Most liked, saved and said in the last 7 days'),
        findsOneWidget,
      );
      expect(find.byType(WindowSwitch), findsOneWidget);
      expect(_numbered, findsWidgets);
      final Finder first = find.byKey(ValueKey('top-${five[0].id}'));
      expect(first, findsOneWidget, reason: 'nine readers, the most');
      expect(find.byKey(ValueKey('top-${few.id}')), findsNothing);
      expect(tester.getSize(find.byType(TopRow)).height, 196);
      // No count printed: the order says it.
      expect(find.textContaining(RegExp(r'\d+ readers?')), findsNothing);
    });

    testWidgets('only the month has a list: the month\'s, with no switch to '
        'an empty week', (tester) async {
      await _counted(tester, {
        _ago(Tallies.closedAfter + 12): _held(_cards(5), 3),
      });
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, top);
      expect(find.text('Top of the month'), findsOneWidget);
      expect(
        find.text('Most liked, saved and said in the last 30 days'),
        findsOneWidget,
      );
      expect(find.text('Top of the week'), findsNothing);
      expect(find.byType(WindowSwitch), findsNothing);
      expect(_numbered, findsWidgets);
    });

    testWidgets('the picks and the list stand at the same height, so the '
        'page does not move when one takes the other\'s place', (tester) async {
      const Size phone = Size(390, 844);
      await _counted(tester, {});
      await pumpSections(tester, CoreHost(await readyApp()), top, size: phone);
      final Size picks = tester.getSize(_picks);
      expect(tester.getSize(find.byType(TopRow)).height, 196);

      // The week and the month, with the switch between them.
      await _counted(tester, {_ago(Tallies.closedAfter): _held(_cards(5), 3)});
      await pumpSections(tester, CoreHost(await readyApp()), top, size: phone);
      expect(find.byType(WindowSwitch), findsOneWidget);
      expect(tester.getSize(_readers), picks);

      // The month alone, with no switch: its room kept.
      await _counted(tester, {
        _ago(Tallies.closedAfter + 12): _held(_cards(5), 3),
      });
      await pumpSections(tester, CoreHost(await readyApp()), top, size: phone);
      expect(find.byType(WindowSwitch), findsNothing);
      expect(tester.getSize(_readers), picks);
    });
  });

  group('the server\'s lists', () {
    Map<String, Object?> doc({required bool readersOnly}) {
      final List<Pill> seeded = _cards(3, skip: 40);
      Map<String, Object?> place(Pill p) => {
        'id': p.id,
        'readers': 1204,
        'card': cardToJson(p),
      };
      return {
        'day': '2026-11-26',
        'readersOnly': ?(readersOnly ? true : null),
        'topWeek': [for (final p in seeded) place(p)],
        'topMonth': [for (final p in seeded) place(p)],
        'loved': [for (final p in seeded) place(p)],
        'bySubject': {
          'space': {
            'week': [
              {'id': seeded[0].id, 'readers': 1204},
            ],
            'month': [],
            'loved': [],
          },
        },
      };
    }

    test('from a server from before, that laid a crowd under its counts, are '
        'dropped when read; the rest of its Explore stands', () {
      final ServedExplore old = ServedExplore.parse({
        ...doc(readersOnly: false),
        'today': [cardToJson(PillBank.cards.first)],
      }, null)!;
      expect(old.readersOnly, isFalse);
      expect(old.topWeek, isEmpty);
      expect(old.topMonth, isEmpty);
      expect(old.loved, isEmpty);
      expect(old.bySubject, isEmpty);
      expect(old.today, isNotEmpty);
    });

    test('from a server that says they are readers\' alone are kept', () {
      final ServedExplore now = ServedExplore.parse(
        doc(readersOnly: true),
        null,
      )!;
      expect(now.readersOnly, isTrue);
      expect(now.topWeek, hasLength(3));
      expect(now.bySubject['space']?.week, hasLength(1));
    });

    testWidgets('a server from before: the phone ranks its own counts, not the '
        'server\'s, and with too few of them shows the picks', (tester) async {
      final List<Pill> real = _cards(5, skip: 80);
      await _counted(tester, {_ago(Tallies.closedAfter): _held(real, 4)});
      Served.useForTest(
        Served(
          storeOverride: MemoryServedStore()
            ..shelves = ServedExplore.parse(doc(readersOnly: false), null),
          uidOverride: 'reader',
        ),
      );
      await tester.runAsync(() => Served.instance.explore(force: true));
      final ExploreShelves shelves = ExploreShelves(await readyApp())..begin();
      expect(shelves.served, isNotNull);
      expect([
        for (final (p, _) in shelves.top(month: false)) p.id,
      ], unorderedEquals([for (final p in real) p.id]));
      expect(shelves.top(month: false).every((t) => t.$2 == 4), isTrue);

      await _counted(tester, {});
      final ExploreShelves thin = ExploreShelves(await readyApp())..begin();
      expect(thin.top(month: false), isEmpty);
      expect(thin.picked, isNotEmpty);
    });

    testWidgets('a server that says so: its lists, as it sent them', (
      tester,
    ) async {
      await _counted(tester, {});
      Served.useForTest(
        Served(
          storeOverride: MemoryServedStore()
            ..shelves = ServedExplore.parse(doc(readersOnly: true), null),
          uidOverride: 'reader',
        ),
      );
      await tester.runAsync(() => Served.instance.explore(force: true));
      final ExploreShelves shelves = ExploreShelves(await readyApp())..begin();
      expect(shelves.top(month: false), hasLength(3));
    });
  });

  group('loved since the start', () {
    testWidgets('is no shelf until real readers make a list of it, and then '
        'the cards the reader has not read', (tester) async {
      final List<Pill> loved = _cards(6, skip: 120);
      await _counted(tester, {}, totals: _held(loved.take(4).toList(), 90));
      final ExploreShelves thin = ExploreShelves(await readyApp())..begin();
      expect(thin.loved, isEmpty);

      await _counted(tester, {}, totals: _held(loved, 3));
      final ExploreShelves shelves = ExploreShelves(
        await readyApp({
          'knowit.seenIds': [loved[0].id],
        }),
      )..begin();
      expect([
        for (final p in shelves.loved) p.id,
      ], unorderedEquals([for (final p in loved.skip(1)) p.id]));
    });
  });
}
