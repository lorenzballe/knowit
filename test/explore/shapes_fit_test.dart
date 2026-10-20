// Every shape holds the longest questions of its kind on the narrowest
// phone, at every size and at the reader's larger text, and in every
// language the app speaks: nothing overflows, no question has to be
// scrolled inside its tile, and no label of the interface is cut short.
//
//   flutter test test/explore/shapes_fit_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/shapes/kinds.dart';
import 'package:astuto/explore/blocks/shapes/shelf.dart';
import 'package:astuto/explore/blocks/shapes/vocabulary.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/scaled_text.dart';

import 'shapes_harness.dart';

/// The section [block] is tried in: aimed as the canvas aimed it, so its
/// kind has cards in the bank, with the signature that asks most of a tile.
Map<String, Object?> _section(ShapeBlock block, String size, String signature) {
  final String kind = block.words.kindWith(signature);
  return {
    if (kind == 'past' || kind == 'place') 'variant': 2,
    if (kind == 'month') 'subject': 'pop_culture',
    'size': size,
    'signature': signature,
    // A checklist shows every card it has, and rings them all.
    if (block.name == 'shape-checklist') 'style': {'shown': 8, 'rings': 'all'},
  };
}

/// The longest questions of [block]'s kind, longest first: as many as it
/// is dealt.
List<Pill> _longest(ShapeBlock block, Map<String, Object?> json) {
  final ExploreSection section = ExploreSection.fromJson({
    'id': 'x',
    'block': block.name,
    ...json,
  });
  final ShapeAim aim = ShapeAim.of(
    section,
    block.kindFor(section),
    DateTime.now(),
  );
  final bool Function(Pill)? keep = block.keep(section);
  final List<Pill> all = [
    for (final Pill p in PillBank.cards)
      if (aim.fits(p) && (keep == null || keep(p))) p,
  ]..sort((a, b) => b.question.length.compareTo(a.question.length));
  return all.take(block.words.limit + block.spare).toList();
}

/// What is wrong with what is on screen now, each a line naming it.
List<String> _faults(WidgetTester tester, String where) {
  final List<String> faults = [];
  final Object? thrown = tester.takeException();
  if (thrown != null) {
    faults.add('$where: ${thrown.toString().split('\n').first}');
  }
  // A question that even at its smallest is taller than its tile scrolls
  // inside it: drawn whole, but not at a glance.
  for (final ScrollableState s in tester.stateList<ScrollableState>(
    find.descendant(
      of: find.byType(ScaledText),
      matching: find.byType(Scrollable),
    ),
  )) {
    final double over = s.position.maxScrollExtent;
    if (over > 0.5) {
      final ScaledText text = tester.widget<ScaledText>(
        find
            .ancestor(
              of: find.byWidget(s.widget),
              matching: find.byType(ScaledText),
            )
            .first,
      );
      faults.add(
        '$where: scrolls ${over.toStringAsFixed(1)}px: '
        '"${text.text.substring(0, 40.clamp(0, text.text.length))}…"',
      );
    }
  }
  // A label cut short, with an ellipsis or a line it could not have.
  for (final RenderParagraph p
      in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (p.didExceedMaxLines) {
      faults.add('$where: cut "${p.text.toPlainText()}"');
    }
  }
  return faults;
}

void main() {
  setUpAll(loadShapeFonts);

  for (final ShapeBlock block in shapeBlocks) {
    testWidgets('${block.name} holds its longest questions at 375', (
      tester,
    ) async {
      final List<String> faults = [];
      for (final String size in kShapeSizes) {
        for (final String signature in block.words.signatures) {
          final Map<String, Object?> json = _section(block, size, signature);
          final List<Pill> cards = _longest(block, json);
          for (final double scale in const [1.0, 1.3, 2.0]) {
            final Pumped run = await pumpShape(
              tester,
              block,
              json: json,
              cards: cards,
              read: {cards.first.id},
              scale: scale,
              height: 1400,
            );
            expect(run.drawn, isTrue);
            faults.addAll(_faults(tester, '$size $signature ×$scale'));
          }
        }
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });

    testWidgets('${block.name} holds the longest questions in the bank', (
      tester,
    ) async {
      // A section of any kind takes whatever its source gives, and a source
      // can give the longest questions there are.
      final List<String> faults = [];
      for (final String size in kShapeSizes) {
        final Map<String, Object?> json = {
          ..._section(block, size, block.words.signatures.first),
          'kind': 'any',
          'title': 'The longest',
        };
        final List<Pill> cards = _longest(block, json);
        for (final double scale in const [1.0, 2.0]) {
          final Pumped run = await pumpShape(
            tester,
            block,
            json: json,
            cards: cards,
            read: {cards.first.id},
            scale: scale,
            height: 1400,
          );
          expect(run.drawn, isTrue);
          faults.addAll(_faults(tester, '$size any ×$scale'));
        }
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });

    testWidgets('${block.name} says its words in every language', (
      tester,
    ) async {
      final List<String> faults = [];
      final Map<String, Object?> json = _section(
        block,
        kShapeSize,
        block.words.signatures.first,
      );
      final List<Pill> cards = _longest(block, json);
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final Pumped run = await pumpShape(
          tester,
          block,
          json: json,
          cards: cards,
          read: {cards.first.id},
          locale: locale,
          height: 1400,
        );
        expect(run.drawn, isTrue);
        faults.addAll(_faults(tester, '$locale'));
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });
  }
}
