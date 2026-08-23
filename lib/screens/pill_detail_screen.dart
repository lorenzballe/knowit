import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/ui.dart';

/// A single pill opened out of the archive or the saved list: the whole thing
/// at once, no flip needed.
class PillDetailScreen extends StatefulWidget {
  final Pill pill;
  final AppState app;

  const PillDetailScreen({super.key, required this.pill, required this.app});

  @override
  State<PillDetailScreen> createState() => _PillDetailScreenState();
}

class _PillDetailScreenState extends State<PillDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final saved = widget.app.isSaved(pill.id);
    final onCard = pill.ink;

    return Scaffold(
      backgroundColor: pill.tint,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BackCircle(onPressed: () => Navigator.of(context).pop()),
                Row(
                  children: [
                    _RoundAction(
                      label: saved ? 'Remove from saved' : 'Save this pill',
                      icon: saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: saved ? pill.color : AppColors.ink,
                      onTap: () async {
                        await widget.app.toggleSaved(pill.id);
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _RoundAction(
                      label: 'Share this pill',
                      icon: Icons.ios_share_rounded,
                      color: AppColors.ink,
                      onTap: () => requirePlus(
                        context,
                        widget.app,
                        () => showShareSheet(context, pill),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: pill.color,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 36,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.topic.toUpperCase(),
                    style: AppText.mono(
                      size: 10.5,
                      spacing: 1.4,
                      color: onCard.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    pill.question,
                    style: AppText.outfit(
                      size: 26,
                      weight: FontWeight.w600,
                      height: 1.16,
                      spacing: -0.9,
                      color: onCard,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SelectableText(
              pill.answer,
              style: AppText.figtree(
                size: 16,
                height: 1.55,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 22),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Bar move'),
                  const SizedBox(height: 8),
                  Text(
                    pill.barMove,
                    style: AppText.figtree(
                      size: 14.5,
                      weight: FontWeight.w500,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TopicDot(pill.color, size: 7),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pill.source,
                    style: AppText.figtree(
                      size: 12,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}
