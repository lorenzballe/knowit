import 'package:flutter/material.dart';

import '../data/pills_data.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'pill_detail_screen.dart';

class SavedScreen extends StatelessWidget {
  final AppState app;
  final VoidCallback onBackToToday;

  const SavedScreen({
    super.key,
    required this.app,
    required this.onBackToToday,
  });

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
    final saved = [
      for (final id in app.savedIds)
        if (byId[id] != null) byId[id]!,
    ];

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (saved.isEmpty) ...[
              const Eyebrow('Nothing kept yet'),
              const SizedBox(height: 7),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'Saved',
                    style: AppText.display(
                      size: 33,
                      weight: FontWeight.w700,
                      height: 1.05,
                      spacing: -1.3,
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
                    padding: const EdgeInsets.only(bottom: 4),
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
            if (saved.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${saved.length} pill${saved.length == 1 ? '' : 's'}',
                style: AppText.body(size: 13, color: context.p.inkMuted),
              ),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: saved.isEmpty
                  ? _EmptyState(onBackToToday: onBackToToday)
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
                'Tap the heart on any pill and it lands here, ready for the '
                'next time the conversation stalls.',
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
