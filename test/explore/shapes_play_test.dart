// What a reader does with the shapes, and what each block makes of what its
// section says: a side taken on a debate is the card's answer, a deck turns,
// a pager pages, a hand raises a card before it opens it, a checklist shows
// the rest, the reader's read cards are ticked; and a kind, a form of it, a
// limit, a country code, an order or a tilt named by the section is the one
// drawn.
//
//   flutter test test/explore/shapes_play_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/shapes/kinds.dart';
import 'package:astuto/explore/blocks/shapes/look.dart';
import 'package:astuto/explore/blocks/shapes/places.dart';
import 'package:astuto/explore/blocks/shapes/shelf.dart';
import 'package:astuto/explore/blocks/shapes/tile.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/explore/parts.dart' show ReadMark;

import 'shapes_harness.dart';

/// The section [block] is tried in, as JSON beside its id and name: aimed as
/// the canvas aimed it, so its kind has cards in the bank.
Map<String, Object?> _aimed(ShapeBlock block, [Map<String, Object?>? more]) {
  final Map<String, Object?> json = {...?more};
  final String kind =
      json['kind'] as String? ??
      block.words.kindWith(json['signature'] as String? ?? '');
  return {
    if (kind == 'past' || kind == 'place') 'variant': 2,
    if (kind == 'month') 'subject': 'pop_culture',
    ...json,
  };
}

/// [block]'s own kind of card, as [json] aims it.
List<Pill> _cards(ShapeBlock block, Map<String, Object?> json, {int n = 12}) =>
    cardsOfKind(
      block,
      ExploreSection.fromJson({'id': 'x', 'block': block.name, ...json}),
      n: n,
    );

/// The cards [run] showed, in the order it showed them, each once.
List<String> _shown(Pumped run) =>
    <String>{for (final (_, id) in run.host.shown) id}.toList();

Finder _card(String id) => find.byKey(ValueKey('explore-$id'));

AppLocalizations _l(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold)));

void main() {
  setUpAll(loadShapeFonts);

  group('a debate', () {
    final ShapeBlock sides = shapeNamed('shape-sides');
    final List<Pill> debates = _cards(
      sides,
      _aimed(sides),
      n: 400,
    ).where((p) => sidesOf(p).length >= 2).take(6).toList();

    testWidgets('a side tapped is the card’s answer, and taken once', (
      tester,
    ) async {
      // Once a side is taken its foot is the card's like the rest of it:
      // a tap there opens the card, where the other side can be read.
      final Pumped run = await pumpShape(
        tester,
        sides,
        json: _aimed(sides),
        cards: debates,
      );
      final String id = debates.first.id;
      await tester.tap(find.byKey(ValueKey('shape-side-$id-1')));
      await tester.pumpAndSettle();
      expect(run.host.answered, [(id, '1')]);
      expect(run.host.opened, isEmpty);
      await tester.tap(find.byKey(ValueKey('shape-side-$id-0')));
      await tester.pumpAndSettle();
      expect(run.host.answered, [(id, '1')]);
      expect(run.host.opened, [('x', id)]);
    });

    testWidgets('a side the reader already took cannot be taken again', (
      tester,
    ) async {
      final String id = debates.first.id;
      final Pumped run = await pumpShape(
        tester,
        sides,
        json: _aimed(sides),
        cards: debates,
        answers: {id: const Answer('0')},
      );
      await tester.tap(find.byKey(ValueKey('shape-side-$id-1')));
      await tester.pumpAndSettle();
      expect(run.host.answered, isEmpty);
      expect(run.host.opened, [('x', id)]);
      expect(
        tester.getSemantics(find.byKey(ValueKey('shape-side-$id-0'))),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('a pager takes a side, and says when it pages', (tester) async {
      final ShapeBlock pager = shapeNamed('shape-pager');
      final List<Pill> cards = _cards(
        pager,
        _aimed(pager),
        n: 400,
      ).where((p) => sidesOf(p).length >= 2).take(4).toList();
      final Pumped run = await pumpShape(
        tester,
        pager,
        json: _aimed(pager),
        cards: cards,
      );
      await tester.tap(find.byKey(ValueKey('shape-side-${cards[0].id}-0')));
      await tester.pumpAndSettle();
      expect(run.host.answered, [(cards[0].id, '0')]);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      final paged = run.host.notes.where((n) => n.$2 == 'paged').toList();
      expect(paged, hasLength(1));
      expect(paged.single.$1, 'x');
      expect(paged.single.$3, {'pill': cards[1].id, 'at': 1});
      expect(find.textContaining(_l(tester).nOfM(2, 4)), findsOneWidget);
    });
  });

  group('a pile', () {
    testWidgets('a deck turns to the next card with a swipe, and back', (
      tester,
    ) async {
      final ShapeBlock deck = shapeNamed('shape-deck');
      final List<Pill> cards = _cards(deck, _aimed(deck), n: 5);
      final Pumped run = await pumpShape(
        tester,
        deck,
        json: _aimed(deck),
        cards: cards,
      );
      final l = _l(tester);
      Map<String, VoidCallback> actions(String id) {
        final Semantics node = tester.widget<Semantics>(
          find
              .ancestor(
                of: _card(id),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Semantics &&
                      w.properties.customSemanticsActions != null,
                ),
              )
              .first,
        );
        return {
          for (final MapEntry<CustomSemanticsAction, VoidCallback> e
              in node.properties.customSemanticsActions!.entries)
            e.key.label!: e.value,
        };
      }

      expect(actions(cards[0].id).keys, [l.next]);
      await tester.drag(_card(cards[0].id), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(run.host.notes.last.$2, 'turned');
      expect(run.host.notes.last.$3, {'pill': cards[1].id, 'at': 1});
      expect(_card(cards[1].id).hitTestable(), findsOneWidget);

      // A reader who cannot swipe turns it from the card's actions.
      expect(
        actions(cards[1].id).keys,
        unorderedEquals([l.next, l.storyPrevious]),
      );
      actions(cards[1].id)[l.storyPrevious]!();
      await tester.pumpAndSettle();
      expect(run.host.notes.last.$3, {'pill': cards[0].id, 'at': 0});

      // A short pull lets it settle back where it was.
      await tester.drag(_card(cards[0].id), const Offset(-30, 0));
      await tester.pumpAndSettle();
      expect(run.host.notes, hasLength(2));
      await tester.tap(_card(cards[0].id));
      expect(run.host.opened, [('x', cards[0].id)]);
    });

    testWidgets('a hand raises a card from the back before it opens it', (
      tester,
    ) async {
      final ShapeBlock hand = shapeNamed('shape-hand');
      final List<Pill> cards = _cards(hand, _aimed(hand), n: 4);
      final Pumped run = await pumpShape(
        tester,
        hand,
        json: _aimed(hand),
        cards: cards,
      );
      // The first card lies at the back of the fan: tapped where it shows,
      // it is drawn up in front.
      final RenderBox back = tester.renderObject(_card(cards[0].id));
      await tester.tapAt(back.localToGlobal(Offset(14, back.size.height / 2)));
      await tester.pumpAndSettle();
      expect(run.host.opened, isEmpty);
      expect(run.host.notes.single.$2, 'raised');
      expect(run.host.notes.single.$3, {'pill': cards[0].id, 'at': 0});

      // In front now, a tap opens it.
      await tester.tap(_card(cards[0].id));
      expect(run.host.opened, [('x', cards[0].id)]);
    });

    testWidgets('a hand’s front card opens at once', (tester) async {
      final ShapeBlock hand = shapeNamed('shape-hand');
      final List<Pill> cards = _cards(hand, _aimed(hand), n: 4);
      final Pumped run = await pumpShape(
        tester,
        hand,
        json: _aimed(hand),
        cards: cards,
      );
      await tester.tap(_card(cards.last.id));
      expect(run.host.opened, [('x', cards.last.id)]);
      expect(run.host.notes, isEmpty);
    });
  });

  group('a checklist', () {
    final ShapeBlock list = shapeNamed('shape-checklist');
    final List<Pill> cards = _cards(list, _aimed(list), n: 8);
    final Finder all = find.byKey(const ValueKey('shape-checklist-all-x'));

    testWidgets('shows three, then all, then three again', (tester) async {
      final Pumped run = await pumpShape(
        tester,
        list,
        json: _aimed(list),
        cards: cards,
      );
      final l = _l(tester);
      expect(_card(cards[2].id), findsOneWidget);
      expect(_card(cards[3].id), findsNothing);
      expect(find.text(l.showAllN(8)), findsOneWidget);

      await tester.tap(all);
      await tester.pumpAndSettle();
      for (final Pill p in cards) {
        expect(_card(p.id), findsOneWidget);
      }
      expect(run.host.notes.last.$2, 'expanded');
      expect(run.host.notes.last.$3, {'count': 8});

      await tester.ensureVisible(all);
      await tester.pumpAndSettle();
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(_card(cards[3].id), findsNothing);
      expect(run.host.notes.last.$2, 'collapsed');
    });

    testWidgets('shows as many as its style says, and no button for none', (
      tester,
    ) async {
      await pumpShape(
        tester,
        list,
        json: _aimed(list, {
          'style': {'shown': 5},
        }),
        cards: cards,
      );
      expect(_card(cards[4].id), findsOneWidget);
      expect(_card(cards[5].id), findsNothing);

      await pumpShape(
        tester,
        list,
        json: _aimed(list),
        cards: cards.take(3).toList(),
      );
      expect(all, findsNothing);
    });

    testWidgets('rings the read cards, every card, or none', (tester) async {
      Future<(bool, bool)> rings(String? mode) async {
        await pumpShape(
          tester,
          list,
          json: _aimed(list, {
            if (mode != null) 'style': {'rings': mode},
          }),
          cards: cards,
          read: {cards[0].id},
        );
        bool ringed(Pill p) =>
            find.byKey(ValueKey('shape-ring-${p.id}')).evaluate().isNotEmpty;
        return (ringed(cards[0]), ringed(cards[1]));
      }

      expect(await rings(null), (true, false));
      expect(await rings('read'), (true, false));
      expect(await rings('all'), (true, true));
      expect(await rings('none'), (false, false));
    });
  });

  testWidgets('something to try ticks its box once it is read', (tester) async {
    final ShapeBlock tryIt = shapeNamed('shape-try');
    final List<Pill> cards = _cards(tryIt, _aimed(tryIt), n: 4);
    await pumpShape(
      tester,
      tryIt,
      json: _aimed(tryIt),
      cards: cards,
      read: {cards[0].id},
    );
    Finder tick(Pill p) => find.descendant(
      of: find.byKey(ValueKey('shape-try-box-${p.id}')),
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(tick(cards[0]), findsOneWidget);
    expect(tick(cards[1]), findsNothing);
  });

  testWidgets('every shape ticks the cards the reader has read', (
    tester,
  ) async {
    for (final ShapeBlock block in shapeBlocks) {
      // Something to try ticks its box, a checklist rings its read cards:
      // both are tried above.
      if (block.name == 'shape-try' || block.name == 'shape-checklist') {
        continue;
      }
      final Map<String, Object?> json = _aimed(block);
      final List<Pill> cards = _cards(block, json);
      final List<String> order = _shown(
        await pumpShape(tester, block, json: json, cards: cards),
      );
      final Pumped run = await pumpShape(
        tester,
        block,
        json: json,
        cards: cards,
        read: {order.first},
      );
      expect(
        find.descendant(
          of: _card(order.first),
          matching: find.byType(ReadMark),
        ),
        findsWidgets,
        reason: block.name,
      );
      for (final String id in _shown(run).skip(1)) {
        expect(
          find.descendant(of: _card(id), matching: find.byType(ReadMark)),
          findsNothing,
          reason: '${block.name}, $id',
        );
      }
    }
  });

  group('a stamp', () {
    final ShapeBlock stamp = shapeNamed('shape-stamp');
    final List<Pill> europe = _cards(stamp, _aimed(stamp), n: 400);
    final List<Pill> known = europe
        .where((p) => stampCountry(p) != null)
        .toList();
    final Pill plain = europe.firstWhere((p) => stampCountry(p) == null);

    testWidgets('shows the cards whose country is known first', (tester) async {
      final Pumped run = await pumpShape(
        tester,
        stamp,
        json: _aimed(stamp),
        cards: [plain, known[0], known[1]],
      );
      expect(_shown(run), [known[0].id, known[1].id, plain.id]);
      expect(
        find.descendant(
          of: _card(known[0].id),
          matching: find.text(stampCountry(known[0])!),
        ),
        findsOneWidget,
      );
    });

    testWidgets('prints the country the section names for a card', (
      tester,
    ) async {
      final String code = stampCountry(known[0]) == 'IS' ? 'MT' : 'IS';
      final Pumped run = await pumpShape(
        tester,
        stamp,
        json: _aimed(stamp, {
          'codes': {plain.id: code},
        }),
        cards: [plain, known[0], known[1]],
      );
      expect(_shown(run).first, plain.id);
      expect(
        find.descendant(of: _card(plain.id), matching: find.text(code)),
        findsOneWidget,
      );
    });

    testWidgets('lies at an angle with the tilt style, and straight without', (
      tester,
    ) async {
      bool tilted(Pill p, double degrees) => tester
          .widgetList<Transform>(
            find.descendant(of: _card(p.id), matching: find.byType(Transform)),
          )
          .any(
            (t) =>
                (t.transform.storage[1] - math.sin(degrees * math.pi / 180))
                    .abs() <
                1e-6,
          );

      await pumpShape(
        tester,
        stamp,
        json: _aimed(stamp, {
          'style': {'tilt': true},
        }),
        cards: known.take(3).toList(),
      );
      expect(tilted(known[0], -3), isTrue);
      expect(tilted(known[1], 2.5), isTrue);

      await pumpShape(
        tester,
        stamp,
        json: _aimed(stamp),
        cards: known.take(3).toList(),
      );
      expect(tilted(known[0], -3), isFalse);
    });
  });

  group('a line of time', () {
    for (final String name in [
      'shape-timeline',
      'shape-years',
      'shape-ruler',
    ]) {
      final ShapeBlock block = shapeNamed(name);
      // Cards each set at a different time, given latest first.
      final List<Pill> distinct = [];
      for (final Pill p in _cards(block, _aimed(block), n: 400)) {
        if (distinct.every((q) => timeKey(q) != timeKey(p))) distinct.add(p);
        if (distinct.length == 4) break;
      }
      final List<Pill> given = [...distinct]
        ..sort((a, b) => timeKey(b).compareTo(timeKey(a)));

      testWidgets('$name lays its cards out in order of time', (tester) async {
        final Pumped run = await pumpShape(
          tester,
          block,
          json: _aimed(block),
          cards: given,
        );
        // A row builds the cards that scroll into view as they do.
        final List<String> shown = _shown(run);
        expect(shown.length, greaterThanOrEqualTo(3));
        expect(
          shown,
          [for (final Pill p in given.reversed) p.id].take(shown.length),
        );
      });

      testWidgets('$name keeps the order it was given when told to', (
        tester,
      ) async {
        final Pumped run = await pumpShape(
          tester,
          block,
          json: _aimed(block, {'order': 'given'}),
          cards: given,
        );
        final List<String> shown = _shown(run);
        expect(shown.length, greaterThanOrEqualTo(3));
        expect(shown, [for (final Pill p in given) p.id].take(shown.length));
      });

      testWidgets('$name shows first the cards that name a year', (
        tester,
      ) async {
        // As many cards of only an age as it shows, given before as many
        // that name a year: the years are the ones it keeps.
        final int n = block.words.limit;
        final List<Pill> kind = _cards(block, _aimed(block), n: 1000);
        final List<Pill> ages = kind
            .where((p) => !namesAYear(p))
            .take(n)
            .toList();
        final List<Pill> years = kind.where(namesAYear).take(n).toList();
        expect(ages, hasLength(n));
        expect(years, hasLength(n));
        final Pumped run = await pumpShape(
          tester,
          block,
          json: _aimed(block),
          cards: [...ages, ...years],
        );
        expect(_shown(run), isNotEmpty);
        for (final String id in _shown(run)) {
          expect(namesAYear(PillBank.byId(id)!), isTrue, reason: id);
        }

        // Told to keep the order it is given, it shows what it is given.
        final Pumped given = await pumpShape(
          tester,
          block,
          json: _aimed(block, {'order': 'given'}),
          cards: [...ages, ...years],
        );
        expect(_shown(given).first, ages.first.id);
      });
    }
  });

  group('slots of two sizes', () {
    /// [n] cards of [block]'s kind, each question a different length.
    List<Pill> lengths(ShapeBlock block, int n) {
      final List<Pill> out = [];
      for (final Pill p in _cards(block, _aimed(block), n: 400)) {
        if (out.every((q) => q.question.length != p.question.length)) {
          out.add(p);
        }
        if (out.length == n) break;
      }
      return out;
    }

    testWidgets('a bento puts the two shortest beside the first', (
      tester,
    ) async {
      final ShapeBlock bento = shapeNamed('shape-bento');
      final List<Pill> cards = lengths(bento, 6);
      final Pumped run = await pumpShape(
        tester,
        bento,
        json: _aimed(bento),
        cards: cards,
      );
      final List<Pill> rest = cards.skip(1).toList();
      final List<int> shortest =
          (rest.map((p) => p.question.length).toList()..sort())
              .take(2)
              .toList();
      expect(_shown(run), [
        cards.first.id,
        for (final Pill p in rest)
          if (shortest.contains(p.question.length)) p.id,
      ]);
    });

    testWidgets('a masonry puts the longest questions in the tall places', (
      tester,
    ) async {
      final ShapeBlock masonry = shapeNamed('shape-masonry');
      final List<Pill> cards = lengths(masonry, 4);
      await pumpShape(tester, masonry, json: _aimed(masonry), cards: cards);
      final List<Pill> byLength = [...cards]
        ..sort((a, b) => b.question.length.compareTo(a.question.length));
      double height(Pill p) => tester.getSize(_card(p.id)).height;
      final double shortestTall = math.min(
        height(byLength[0]),
        height(byLength[1]),
      );
      final double tallestShort = math.max(
        height(byLength[2]),
        height(byLength[3]),
      );
      expect(shortestTall, greaterThan(tallestShort));
    });
  });

  group('what the section says', () {
    testWidgets('a kind it names is the one it keeps to', (tester) async {
      final ShapeBlock fold = shapeNamed('shape-fold');
      final List<Pill> paradoxes = _cards(fold, {'kind': 'paradoxes'}, n: 6);
      final List<Pill> myths = _cards(fold, const {}, n: 6);
      final Pumped run = await pumpShape(
        tester,
        fold,
        json: {'kind': 'paradoxes'},
        cards: [...myths, ...paradoxes],
      );
      final l = _l(tester);
      expect(find.text(l.themeParadoxes), findsOneWidget);
      expect(find.text(l.themeMyths), findsNothing);
      expect(
        _shown(run).toSet().intersection({for (final p in myths) p.id}),
        isEmpty,
      );
      expect(_shown(run), isNotEmpty);
    });

    testWidgets('any kind of card goes under the section’s own name', (
      tester,
    ) async {
      final ShapeBlock fold = shapeNamed('shape-fold');
      final List<Pill> mixed = PillBank.cards.take(6).toList();
      const Map<String, Object?> json = {
        'kind': 'any',
        'title': {'en': 'From the server', 'it': 'Dal server'},
        'subtitle': {'en': 'Picked today'},
      };
      final Pumped run = await pumpShape(
        tester,
        fold,
        json: json,
        cards: mixed,
      );
      expect(run.drawn, isTrue);
      expect(find.text('From the server'), findsOneWidget);
      expect(find.text('Picked today'), findsOneWidget);
      expect(_shown(run).first, mixed.first.id);

      await pumpShape(
        tester,
        fold,
        json: json,
        cards: mixed,
        locale: const Locale('it'),
      );
      expect(find.text('Dal server'), findsOneWidget);
    });

    testWidgets('a form of the past it names is the one drawn', (tester) async {
      final ShapeBlock ruler = shapeNamed('shape-ruler');
      for (int variant = 0; variant < 3; variant++) {
        final Map<String, Object?> json = {'variant': variant};
        final Pumped run = await pumpShape(
          tester,
          ruler,
          json: json,
          cards: _cards(ruler, json),
        );
        final l = _l(tester);
        expect(run.drawn, isTrue, reason: '$variant');
        expect(
          find.text([l.themePast0, l.themePast1, l.themePast2][variant]),
          findsOneWidget,
        );
      }
    });

    testWidgets('a month’s subject it names is the one drawn', (tester) async {
      final ShapeBlock grid = shapeNamed('shape-grid');
      const Map<String, Object?> json = {'subject': 'space'};
      final List<Pill> space = _cards(grid, json);
      final Pumped run = await pumpShape(
        tester,
        grid,
        json: json,
        cards: [...PillBank.cards.take(4), ...space],
      );
      final l = _l(tester);
      expect(find.text(l.monthOf(l.subjectName('space'))), findsOneWidget);
      for (final String id in _shown(run)) {
        expect(PillBank.byId(id)!.topic, space.first.topic, reason: id);
      }
    });

    testWidgets('a grid of figures is a shelf of numbers', (tester) async {
      final ShapeBlock grid = shapeNamed('shape-grid');
      const Map<String, Object?> json = {'signature': 'figure'};
      final Pumped run = await pumpShape(
        tester,
        grid,
        json: json,
        cards: _cards(grid, json),
      );
      final l = _l(tester);
      expect(run.drawn, isTrue);
      expect(find.text(l.themeNumbers), findsOneWidget);
      expect(find.byType(FigureText), findsWidgets);
      for (final String id in _shown(run)) {
        expect(figureOf(PillBank.byId(id)!), isNotNull, reason: id);
      }
    });

    testWidgets('a limit is how many it shows, a min the fewest it draws', (
      tester,
    ) async {
      final ShapeBlock rows = shapeNamed('shape-rows');
      final List<Pill> cards = _cards(rows, const {}, n: 6);
      final Pumped two = await pumpShape(
        tester,
        rows,
        json: {'limit': 2},
        cards: cards,
      );
      expect(_shown(two), [cards[0].id, cards[1].id]);

      final Pumped few = await pumpShape(
        tester,
        rows,
        json: {'min': 3},
        cards: cards.take(2).toList(),
      );
      expect(few.drawn, isFalse);

      // A limit past the most it ever shows is the most.
      final Pumped most = await pumpShape(
        tester,
        rows,
        json: {'limit': 40},
        cards: _cards(rows, const {}, n: 20),
      );
      expect(_shown(most), hasLength(rows.words.most));
    });

    testWidgets('a size or signature it does not have is its own', (
      tester,
    ) async {
      final ShapeBlock quote = shapeNamed('shape-quote');
      final Map<String, Object?> json = _aimed(quote);
      final List<Pill> cards = _cards(quote, json);
      await pumpShape(tester, quote, json: json, cards: cards);
      final Size own = tester.getSize(_card(cards[0].id));
      await pumpShape(
        tester,
        quote,
        json: {...json, 'size': 'xl', 'signature': 'sunset'},
        cards: cards,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_card(cards[0].id)), own);
    });
  });

  test('the aim of a section falls back to the block’s own kind', () {
    final ExploreSection odd = ExploreSection.fromJson({
      'id': 'x',
      'block': 'shape-fold',
      'kind': 'legends',
      'variant': 7,
      'subject': 'thinking',
    });
    final ShapeAim aim = ShapeAim.of(odd, 'past', DateTime(2026, 10, 19));
    expect(aim.kind, 'past');
    expect(aim.variant, inInclusiveRange(0, 2));
    expect(kShapeKinds, contains(aim.kind));
  });
}
