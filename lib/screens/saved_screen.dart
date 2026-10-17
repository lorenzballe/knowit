import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/share_sheet.dart';
import '../widgets/fit_text.dart';
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

  /// Dropping a pill is undoable — the row comes back where it was.
  Future<void> _unsave(BuildContext context, Pill pill, int at) async {
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
    // that do not exist.
    final present = kTopicOrder
        .where((key) => all.any((p) => p.topic == kTopics[key]!.name))
        .toList();
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
                    : _topic == null
                    ? context.l10n.nCards(all.length)
                    : context.l10n.nInTopic(
                        saved.length,
                        kTopics[_topic]!.name,
                      ),
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
              const SizedBox(height: 16),
              Expanded(
                child: all.isEmpty
                    ? _EmptyState(
                        onBackToToday: widget.onBackToToday,
                        liked: _liked,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: saved.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => RiseIn.staggered(
                          i,
                          child: _SavedRow(
                            pill: saved[i],
                            liked: _liked,
                            onUnsave: () => _unsave(context, saved[i], i),
                            onShare: () => showShareSheet(context, saved[i]),
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PillDetailScreen(pill: saved[i], app: app),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
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

class _SavedRow extends StatelessWidget {
  final Pill pill;
  final bool liked;
  final VoidCallback onUnsave;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  const _SavedRow({
    required this.pill,
    required this.liked,
    required this.onUnsave,
    required this.onShare,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: PaperCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TopicDot(pill.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.topic.toUpperCase(),
                    style: AppText.label(
                      size: 10.5,
                      spacing: 1.2,
                      color: context.p.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pill.question,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: context.p.ink,
                    ),
                  ),
                ],
              ),
            ),
            // In ink, not the subject's colour: yellow and lime on a white
            // row were 1.3 to 1 against it, under the 3 to 1 a mark that
            // means something needs. The subject's colour is the dot.
            Column(
              children: [
                _RowAction(
                  label: liked
                      ? context.l10n.removeFromLiked
                      : context.l10n.removeFromSaved,
                  icon: liked ? Icons.favorite_rounded : Icons.bookmark_rounded,
                  size: 18,
                  color: context.p.ink,
                  onTap: onUnsave,
                ),
                _RowAction(
                  label: context.l10n.shareThisPill,
                  icon: Icons.ios_share_rounded,
                  size: 17,
                  color: context.p.inkMuted,
                  onTap: onShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A mark at the end of a kept card's row, in a target a finger finds.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.label,
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(icon, size: size, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
