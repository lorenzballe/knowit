/// Explore as a list of sections: which ones the reader is shown, and the
/// slivers that draw them.
///
/// The list is the remote document's (its `explore` part, docs/REMOTE.md),
/// or, when the document has none, the build's own
/// (lib/explore/blocks/core/own_explore.dart) — the same list, drawn by the
/// same code, so the floor and any document the server sends are never two
/// Explores. Each section is kept item by item: one this build cannot read,
/// aimed at somebody else, drawn by a block it does not know, or with
/// nothing to show is passed over, and the rest of the list stands.
///
/// What is drawn is drawn lazily. Which sections have anything to show is
/// asked of every block on each build — cheap, since a block only returns
/// the description of what it would draw — so the shelves can be numbered
/// in the order the reader meets them; the sections themselves are built,
/// laid out and painted only as they come near the screen.
library;

import 'package:flutter/widgets.dart';

import '../../explore/blocks/core/layout.dart';
import '../../explore/blocks/core/own_explore.dart';
import '../../explore/catalogue.dart';
import '../../explore/explore_block.dart';
import '../../remote/remote.dart';

/// The sections of [config]'s `explore` part, in order, or the build's own
/// when the part is missing, null, or has no list of sections. A section
/// that cannot be read, or whose id an earlier one already took, is left
/// out; the others stand.
List<ExploreSection> exploreSections(RemoteConfig config) {
  if (identical(config, _readFrom)) return _read;
  _readFrom = config;
  return _read = _sectionsOf(config.part('explore'));
}

RemoteConfig? _readFrom;
List<ExploreSection> _read = const [];

List<ExploreSection> _sectionsOf(Map<String, Object?> part) {
  final Object? list = part['sections'];
  if (list is! List) return kOwnExplore;
  final Set<String> ids = {};
  return List.unmodifiable([
    for (final Object? raw in list)
      if (raw is Map<String, Object?>)
        if (_sectionOf(raw) case final ExploreSection section
            when ids.add(section.id))
          section,
  ]);
}

ExploreSection? _sectionOf(Map<String, Object?> json) {
  try {
    return ExploreSection.fromJson(json);
  } on FormatException {
    return null;
  }
}

/// One section as Explore draws it: its block, the room above it, and its
/// place among the shelves.
@immutable
class ExploreSlot {
  const ExploreSlot({
    required this.section,
    required this.block,
    required this.gap,
    this.position,
  });

  /// The section.
  final ExploreSection section;

  /// The block that draws it.
  final ExploreBlock block;

  /// The room above it, in points.
  final double gap;

  /// Its place among the shelves, 1 for the first; null for a section that
  /// is not a shelf (see [SectionLayout.isShelf]).
  final int? position;
}

/// What [host] draws of [sections] for the reader [who] is: the sections
/// aimed at them (`audience`, split by the section's own id), of a block
/// this build knows, that have something to show now — in order, each
/// shelf numbered as the reader meets it.
///
/// Every block is asked to draw its section once here and the answer is
/// thrown away: the section is drawn again as it comes into view, so a
/// block that says what it showed as it draws says it then. A block that
/// fails is left out and the failure reported; the page goes on.
List<ExploreSlot> exploreSlots(
  BuildContext context,
  ExploreHost host,
  List<ExploreSection> sections,
  RemoteContext who,
) {
  final List<ExploreSlot> out = [];
  int shelves = 0;
  for (final ExploreSection section in sections) {
    if (!Audience.allows(section.audience, who, salt: section.id)) continue;
    final ExploreBlock? block = kExploreBlocks[section.block];
    if (block == null) continue;
    if (_drawn(context, host, block, section) == null) continue;
    final bool shelf = sectionIsShelf(block);
    out.add(
      ExploreSlot(
        section: section,
        block: block,
        gap: sectionGap(section, block),
        position: shelf ? ++shelves : null,
      ),
    );
  }
  return out;
}

Widget? _drawn(
  BuildContext context,
  ExploreHost host,
  ExploreBlock block,
  ExploreSection section,
) {
  try {
    return block.build(context, host, section);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'explore',
        context: ErrorDescription(
          'while drawing the section ${section.id} (${section.block})',
        ),
      ),
    );
    return null;
  }
}

/// The sections, as a sliver: each built as it comes near the screen, kept
/// by its id, so a newer list — the same sections moved, one added above —
/// finds the ones already on screen where they were and leaves them there.
class ExploreSliver extends StatelessWidget {
  const ExploreSliver({super.key, required this.host, required this.slots});

  /// What the sections are drawn for, and with.
  final ExploreHost host;

  /// The sections to draw, as [exploreSlots] gave them.
  final List<ExploreSlot> slots;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> at = {
      for (int i = 0; i < slots.length; i++) slots[i].section.id: i,
    };
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _Slot(
          key: ValueKey('section-${slots[i].section.id}'),
          host: host,
          slot: slots[i],
        ),
        childCount: slots.length,
        findChildIndexCallback: (Key key) {
          if (key is! ValueKey<String>) return null;
          return at[key.value.substring('section-'.length)];
        },
      ),
    );
  }
}

/// One section on the page: the room above it, and what its block draws,
/// watched for whether it is on screen when it is a shelf.
class _Slot extends StatelessWidget {
  const _Slot({super.key, required this.host, required this.slot});

  final ExploreHost host;
  final ExploreSlot slot;

  @override
  Widget build(BuildContext context) {
    final Widget? drawn = _drawn(context, host, slot.block, slot.section);
    if (drawn == null) return const SizedBox.shrink();
    final Widget watched = sectionIsShelf(slot.block)
        ? host.watch(slot.section, drawn)
        : drawn;
    if (slot.gap <= 0) return watched;
    return Padding(
      padding: EdgeInsets.only(top: slot.gap),
      child: watched,
    );
  }
}
