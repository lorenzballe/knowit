/// The frame every shape is drawn in, and what every shape block does
/// before it lays its cards out.
library;

import 'package:flutter/material.dart';

import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/balanced_text.dart';
import '../../explore_block.dart';
import 'deal.dart';
import 'vocabulary.dart';

/// A shelf as Explore draws every one: its name, the line under it that says
/// why it exists, and the cards — the screen's own, at its margins and in
/// its type, so a shape sits among the app's shelves as one of them.
class ShapeShelf extends StatelessWidget {
  const ShapeShelf({
    super.key,
    required this.title,
    required this.line,
    required this.child,
  });

  /// The name; null for a section that has none, whose cards then stand on
  /// their own.
  final String? title;

  /// The line under it.
  final String? line;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? name = title;
    final String? why = line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (name != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w600,
                    height: 1,
                    spacing: -0.2,
                    color: context.p.ink,
                  ),
                ),
                if (why != null) ...[
                  const SizedBox(height: 3),
                  BalancedText(
                    why,
                    style: AppText.body(
                      size: 12,
                      height: 1.3,
                      color: context.p.ink.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 11),
        ],
        child,
      ],
    );
  }
}

/// A block of the shapes family: the words it reads, and how it lays its
/// cards out once they are dealt. Dealing, naming the shelf and telling
/// Explore it is on screen are the same for all of them, and done here.
abstract class ShapeBlock extends ExploreBlock {
  const ShapeBlock();

  /// What it reads from its section.
  ShapeVocabulary get words;

  /// The kind of card [section]'s shelf keeps to when it names none: the
  /// block's own, unless its signature makes it another shelf.
  String kindFor(ExploreSection section) =>
      words.kindWith(signatureOf(section));

  /// The cards it shows first when it has more than it needs, each lot in
  /// the order they came: none, unless a shape has a reason to prefer some.
  bool Function(Pill)? first(ExploreSection section) => null;

  /// The only cards it can draw, whatever its kind: all, unless a shape
  /// needs something of a card that not every card has.
  bool Function(Pill)? keep(ExploreSection section) => null;

  /// How many cards beyond those it shows it is dealt, to choose among for
  /// slots of different sizes.
  int get spare => 0;

  /// The size [section] asks for, or the canvas's own.
  String sizeOf(ExploreSection section) {
    final String? asked = section.size;
    return asked != null && kShapeSizes.contains(asked) ? asked : kShapeSize;
  }

  /// The signature [section] asks for, when the block can carry it, or the
  /// block's own.
  String signatureOf(ExploreSection section) {
    final String? asked = section.get<String>('signature');
    return asked != null && words.signatures.contains(asked)
        ? asked
        : words.signatures.first;
  }

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ShapeDeal? deal = ShapeDeal.of(
      host,
      section,
      words,
      kind: kindFor(section),
      first: first(section),
      keep: keep(section),
      spare: spare,
    );
    if (deal == null) return null;
    return host.watch(
      section,
      ShapeShelf(
        key: ValueKey('shape-${section.id}'),
        title: deal.title(context, host.language),
        line: deal.line(context, host.language),
        child: lay(context, host, deal),
      ),
    );
  }

  /// The cards of [deal], laid out.
  Widget lay(BuildContext context, ExploreHost host, ShapeDeal deal);
}
