import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/card_edge.dart';
import '../widgets/motion.dart';
import '../widgets/subject_icon.dart';
import '../widgets/web/card_thumb.dart';
import '../widgets/web/web_card_page.dart' show groundOf;
import '../widgets/share_sheet.dart';
import '../widgets/fit_text.dart';
import '../widgets/top_edge.dart' show SoftTop;
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'pill_detail_screen.dart';
import '../analytics.dart';

/// Which of the reader's two shelves this is: the cards they bookmarked
/// to find again, or the cards they held down because they liked them.
enum Shelf { saved, liked }

class SavedScreen extends StatefulWidget {
  final AppState app;

  /// The empty shelf's way on: the Today tab, where cards are kept from.
  final VoidCallback onBackToToday;

  /// The way back to the screen this was opened over. Left null, the
  /// screen is popped.
  final VoidCallback? onBack;
  final Shelf shelf;

  const SavedScreen({
    super.key,
    required this.app,
    required this.onBackToToday,
    this.onBack,
    this.shelf = Shelf.saved,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  /// Which topic the shelf is narrowed to, by its key, or all of them.
  String? _topic;

  AppState get app => widget.app;
  bool get _liked => widget.shelf == Shelf.liked;

  /// Dropping a pill is undoable — the card comes back where it was, in the
  /// shelf as a whole and not only in the part of it on screen.
  Future<void> _unsave(BuildContext context, Pill pill) async {
    final int at = (_liked ? app.likedIds : app.savedIds).indexOf(pill.id);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    if (_liked) {
      await app.toggleLiked(pill.id);
    } else {
      await app.toggleSaved(pill.id);
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_liked ? l.removedFromLiked : l.removedFromSaved),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () => _liked
              ? app.restoreLiked(pill.id, at)
              : app.restoreSaved(pill.id, at),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Most recently kept first, rather than whatever order the pool happens
    // to be in.
    final byId = {for (final p in PillBank.live) p.id: p};
    final all = [
      for (final id in _liked ? app.likedIds : app.savedIds)
        if (byId[id] != null) byId[id]!,
    ];
    // Only the topics actually on the shelf: a filter offering twenty
    // subjects to a reader who has kept four cards is a list of things
    // that do not exist. In the blocks' order, the subject kept from most
    // recently first, so a chip and its block are in the same place.
    final keyOf = {for (final e in kTopics.entries) e.value.name: e.key};
    final List<String> present = [];
    for (final pill in all) {
      final String? key = keyOf[pill.topic];
      if (key != null && !present.contains(key)) present.add(key);
    }
    if (_topic != null && !present.contains(_topic)) _topic = null;
    final saved = _topic == null
        ? all
        : all.where((p) => p.topic == kTopics[_topic]!.name).toList();

    return ScreenView(
      // The two shelves of the reader's own are two screens: what they kept
      // to find again, and what they held to like.
      name: _liked ? 'liked' : 'saved',
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // The way back. This screen is pushed over the profile and
                  // had nothing but the phone's own gesture to leave it.
                  BackCircle(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // One line, at whatever size one line takes: "Saved"
                    // is five letters and "Сохранённые" is eleven.
                    child: FitText(
                      _liked ? context.l10n.liked : context.l10n.saved,
                      maxLines: 1,
                      minSize: 20,
                      style: AppText.display(
                        size: 27,
                        weight: FontWeight.w600,
                        height: 1,
                        spacing: -0.8,
                        color: context.p.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // The archive, on either plan: the free plan's week, and
                    // inside it the lock on the days before.
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (routeContext) => ArchiveScreen(
                          app: app,
                          onBack: () => Navigator.of(routeContext).pop(),
                        ),
                      ),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: context.p.link,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.l10n.archive,
                            style: AppText.body(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: context.p.link,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                all.isEmpty
                    ? (_liked
                          ? context.l10n.nothingLikedYet
                          : context.l10n.nothingKeptYet)
                    // The shelf's whole count, picked subject or not: the
                    // subject's own count is in its head, over its cards.
                    : context.l10n.nCards(all.length),
                style: AppText.body(
                  size: 12.5,
                  height: 1.35,
                  color: context.p.ink.withValues(alpha: 0.42),
                ),
              ),
              if (present.length > 1) ...[
                const SizedBox(height: 14),
                TopicFilterRow(
                  topics: present,
                  picked: _topic,
                  onPick: (key) {
                    Analytics.capture('shelf filtered', {
                      'subject': key ?? 'all',
                    });
                    setState(() => _topic = key);
                  },
                  keyPrefix: 'saved-filter',
                ),
              ],
              const SizedBox(height: 6),
              Expanded(
                child: all.isEmpty
                    ? _EmptyState(
                        onBackToToday: widget.onBackToToday,
                        liked: _liked,
                      )
                    : _shelf(context, all, saved, present),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [pill] on its own page, the rest of the shelf as shown — [shown] —
  /// a swipe either side of it.
  void _open(BuildContext context, Pill pill, List<Pill> shown) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PillDetailScreen(pill: pill, app: app, among: shown),
        ),
      );

  /// Held, a kept card offers what its row used to carry at its end:
  /// letting it go, and sending it.
  Future<void> _actions(BuildContext context, Pill pill) async {
    HapticFeedback.mediumImpact();
    final l = context.l10n;
    final String? chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.p.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Text(
                  pill.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: sheet.p.inkMuted,
                  ),
                ),
              ),
              ListTile(
                key: const ValueKey('kept-remove'),
                leading: Icon(
                  _liked ? Icons.favorite_rounded : Icons.bookmark_rounded,
                  color: sheet.p.ink,
                ),
                title: Text(
                  _liked ? l.removeFromLiked : l.removeFromSaved,
                  style: AppText.body(size: 15, color: sheet.p.ink),
                ),
                onTap: () => Navigator.of(sheet).pop('remove'),
              ),
              ListTile(
                key: const ValueKey('kept-share'),
                leading: Icon(Icons.ios_share_rounded, color: sheet.p.ink),
                title: Text(
                  l.shareThisPill,
                  style: AppText.body(size: 15, color: sheet.p.ink),
                ),
                onTap: () => Navigator.of(sheet).pop('share'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (chosen == 'remove') await _unsave(context, pill);
    if (chosen == 'share' && context.mounted) showShareSheet(context, pill);
  }

  /// The shelf as a wall of the cards themselves, small, with their
  /// drawings — the way a feed's saved posts are a grid, not a list. All of
  /// it is the order the reader kept them in, the newest first: a shelf is
  /// a record of what was kept when. Narrowed to a subject, the subject's
  /// mark and name head its cards.
  Widget _shelf(
    BuildContext context,
    List<Pill> all,
    List<Pill> shown,
    List<String> present,
  ) {
    final String? topic = _topic;
    return SoftTop(
      child: CustomScrollView(
        slivers: [
          if (topic == null)
            const SliverToBoxAdapter(child: SizedBox(height: 10))
          else
            SliverToBoxAdapter(
              child: _BlockHead(topicKey: topic, count: shown.length),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 28),
            sliver: _grid(context, shown),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List<Pill> cards) => SliverGrid(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: WebThumbs.aspect,
    ),
    delegate: SliverChildBuilderDelegate(
      (context, i) => RiseIn.staggered(
        i,
        child: _KeptTile(
          pill: cards[i],
          onOpen: () => _open(context, cards[i], cards),
          onHold: () => _actions(context, cards[i]),
        ),
      ),
      childCount: cards.length,
    ),
  );
}

/// The head of a subject's cards on the shelf: its mark on its colour, its
/// name in the reader's language, and how many of its cards are kept.
class _BlockHead extends StatelessWidget {
  const _BlockHead({required this.topicKey, required this.count});

  final String topicKey;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = kTopics[topicKey]!;
    return Semantics(
      header: true,
      child: Padding(
        key: ValueKey('kept-block-$topicKey'),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: Row(
          children: [
            SubjectBadge(
              subject: style.name,
              color: style.color,
              ink: style.ink,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.subjectOf(style.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 15.5,
                  weight: FontWeight.w700,
                  spacing: -0.2,
                  color: context.p.ink,
                ),
              ),
            ),
            Text(
              context.l10n.nCards(count),
              style: AppText.body(
                size: 12,
                weight: FontWeight.w500,
                color: context.p.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed, fanned placeholder from the empty-state board.
class _EmptyState extends StatelessWidget {
  final VoidCallback onBackToToday;
  final bool liked;
  const _EmptyState({required this.onBackToToday, required this.liked});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DashedStack(liked: liked),
              const SizedBox(height: 24),
              Text(
                liked
                    ? context.l10n.whatYouLikedLandsHere
                    : context.l10n.keepTheOnesYoullUse,
                textAlign: TextAlign.center,
                style: AppText.display(
                  size: 21,
                  weight: FontWeight.w600,
                  height: 1.22,
                  spacing: -0.6,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                liked
                    ? context.l10n.holdToLikeLandsHere
                    : context.l10n.tapTheBookmarkLandsHere,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 14,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.l10n.backToTodaysFive,
                height: 52,
                onPressed: onBackToToday,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedStack extends StatelessWidget {
  const _DashedStack({required this.liked});

  final bool liked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 120,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Transform.rotate(
              angle: -0.14,
              child: CustomPaint(
                size: const Size(double.infinity, 92),
                painter: _DashedBorderPainter(
                  radius: 20,
                  ink: context.p.inkFaint,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 6,
            child: Transform.rotate(
              angle: 0.087,
              child: CustomPaint(
                size: const Size(double.infinity, 100),
                painter: _DashedBorderPainter(
                  radius: 22,
                  ink: context.p.inkFaint,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                radius: 24,
                ink: context.p.inkMuted,
              ),
              child: Center(
                child: Icon(
                  liked
                      ? Icons.favorite_border_rounded
                      : Icons.bookmark_border_rounded,
                  size: 26,
                  color: context.p.inkFaint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;
  final Color ink;
  const _DashedBorderPainter({required this.radius, required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ink;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    // Walk the outline and stroke every other segment to fake a dashed border.
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.radius != radius || old.ink != ink;
}

/// A kept card in small: the picture of its back, since it was read — the
/// whole card with its drawing — tapped to open, held for what can be done
/// with it. A card with no picture is the same card in small anyway, its
/// subject's colour, mark and question, so the wall stays a wall of cards.
class _KeptTile extends StatelessWidget {
  const _KeptTile({
    required this.pill,
    required this.onOpen,
    required this.onHold,
  });

  final Pill pill;
  final VoidCallback onOpen;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) {
    final Widget face = _MiniFace(pill: pill);
    return Semantics(
      button: true,
      label: pill.question,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('kept-${pill.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        onLongPress: onHold,
        child: Container(
          decoration: cardFace(context, groundOf(pill), radius: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CardThumb.has(pill, CardSide.back)
                ? CardThumb(pill: pill, side: CardSide.back, fallback: face)
                : face,
          ),
        ),
      ),
    );
  }
}

/// The card in small without a picture: its colour, its mark, its question.
class _MiniFace extends StatelessWidget {
  const _MiniFace({required this.pill});

  final Pill pill;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: pill.color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 10, 9, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardMark(pill: pill, size: 13, ink: pill.ink),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                pill.question,
                overflow: TextOverflow.fade,
                style: AppText.display(
                  size: 11.5,
                  weight: FontWeight.w700,
                  height: 1.15,
                  spacing: -0.2,
                  color: pill.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
