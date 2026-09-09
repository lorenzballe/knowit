import 'package:flutter/material.dart';

import '../data/pills_data.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'pill_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  final AppState app;
  final VoidCallback onBackToToday;

  const SavedScreen({
    super.key,
    required this.app,
    required this.onBackToToday,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  /// Which topic the shelf is narrowed to, by its key, or all of them.
  String? _topic;

  AppState get app => widget.app;

  /// Dropping a pill is undoable — the row comes back where it was.
  Future<void> _unsave(BuildContext context, Pill pill, int at) async {
    final messenger = ScaffoldMessenger.of(context);
    await app.toggleSaved(pill.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Removed from saved.'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => app.restoreSaved(pill.id, at),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Most recently kept first, rather than whatever order the pool happens
    // to be in.
    final byId = {for (final p in kPillPool) p.id: p};
    final all = [
      for (final id in app.savedIds)
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

    return SafeArea(
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
                BackCircle(onPressed: widget.onBackToToday),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Saved',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  onTap: () => requirePlus(
                    context,
                    app,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (routeContext) => ArchiveScreen(
                          app: app,
                          onBack: () => Navigator.of(routeContext).pop(),
                        ),
                      ),
                    ),
                  ),
                  child: Padding(
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
                          'Archive',
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: context.p.link,
                          ),
                        ),
                        PlusLock(locked: !app.isPlus),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              all.isEmpty
                  ? 'Nothing kept yet'
                  : _topic == null
                  ? '${all.length} card${all.length == 1 ? '' : 's'}'
                  : '${saved.length} in ${kTopics[_topic]!.name}',
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
                onPick: (key) => setState(() => _topic = key),
                keyPrefix: 'saved-filter',
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: all.isEmpty
                  ? _EmptyState(onBackToToday: widget.onBackToToday)
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: saved.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => RiseIn.staggered(
                        i,
                        child: _SavedRow(
                          pill: saved[i],
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
    );
  }
}

/// The dashed, fanned placeholder from the empty-state board.
class _EmptyState extends StatelessWidget {
  final VoidCallback onBackToToday;
  const _EmptyState({required this.onBackToToday});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DashedStack(),
              const SizedBox(height: 24),
              Text(
                "Keep the ones you'll actually use",
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
                'Tap the heart on any pill and it lands here — the ones that '
                'changed how you think, kept.',
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 14,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: "BACK TO TODAY'S FIVE",
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
  const _DashedStack();

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
                  Icons.favorite_border_rounded,
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
  final VoidCallback onUnsave;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  const _SavedRow({
    required this.pill,
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
            Column(
              children: [
                IconButton(
                  onPressed: onUnsave,
                  tooltip: 'Remove from saved',
                  icon: const Icon(Icons.favorite_rounded, size: 18),
                  color: pill.color,
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onShare,
                  tooltip: 'Share this pill',
                  icon: const Icon(Icons.ios_share_rounded, size: 17),
                  color: context.p.inkFaint,
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
