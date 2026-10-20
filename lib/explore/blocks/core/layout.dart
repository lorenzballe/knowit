/// How a section sits on the page, beyond what its block draws: the room
/// above it, and whether it is a shelf the reader looks at or a line between
/// them. Read by the engine (lib/widgets/explore/explore_engine.dart) of any
/// block; a block of another family that says nothing gets the defaults.
library;

import 'package:flutter/widgets.dart';

import '../../../widgets/balanced_text.dart';
import '../../../widgets/explore/first_shelves.dart';
import '../../../theme.dart';
import '../../explore_block.dart';

/// The room above a section that names none, as between every two shelves
/// Explore always had.
const double kSectionGap = 24;

/// What a block says about its sections' place on the page.
mixin SectionLayout on ExploreBlock {
  /// The room above a section of this block when the section names none
  /// with `gap`.
  double get gap => kSectionGap;

  /// Whether a section of this block is a shelf: watched for whether it is
  /// on screen, numbered among the shelves, and said as seen when the reader
  /// leaves. A line that says Explore is offline, a rule, a space, is not.
  bool get isShelf => true;
}

/// The room above [section], drawn by [block]: the section's own `gap`, in
/// points from 0 to 120, or its block's.
double sectionGap(ExploreSection section, ExploreBlock block) {
  final Object? own = section.json['gap'];
  if (own is num && own >= 0 && own <= 120) return own.toDouble();
  return block is SectionLayout ? block.gap : kSectionGap;
}

/// Whether [block]'s sections are shelves (see [SectionLayout.isShelf]).
bool sectionIsShelf(ExploreBlock block) =>
    block is! SectionLayout || block.isShelf;

/// A section's frame when its name and line are the section's to give and
/// either may be missing: the shelf's own frame when both are there, the one
/// that is there alone, or the cards alone when neither is.
class SectionFrame extends StatelessWidget {
  const SectionFrame({
    super.key,
    this.title,
    this.line,
    this.trailing,
    required this.child,
  });

  /// The section's name, if it has one.
  final String? title;

  /// The line under it, if it has one.
  final String? line;

  /// A control level with the name.
  final Widget? trailing;

  /// What the section shows, at the page's full width.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? name = title, why = line;
    if (name != null && why != null) {
      return ShelfFrame(
        title: name,
        line: why,
        trailing: trailing,
        child: child,
      );
    }
    if (name == null && why == null && trailing == null) return child;
    final Widget? head = name == null
        ? null
        : Text(
            name,
            style: AppText.body(
              size: 16,
              weight: FontWeight.w600,
              height: 1,
              spacing: -0.2,
              color: context.p.ink,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (head != null || trailing != null)
                Row(
                  children: [
                    Expanded(child: head ?? const SizedBox.shrink()),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              if (why != null) ...[
                if (head != null || trailing != null) const SizedBox(height: 3),
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
        child,
      ],
    );
  }
}
