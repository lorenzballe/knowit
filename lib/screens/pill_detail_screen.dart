import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/reveal_body.dart';
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
    final answered = widget.app.answerFor(pill.id);

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
                      onTap: () => showShareSheet(context, pill),
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
                    style: AppText.label(
                      size: 10.5,
                      spacing: 1.4,
                      color: onCard.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    pill.question,
                    style: AppText.display(
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
            if (answered != null) ...[
              _AnsweredLine(pill: pill, given: answered),
              const SizedBox(height: 16),
            ],
            // The same reveal the card shows. This used to print pill.answer
            // alone, which on a worked problem is the last line of the
            // solution and on a debate is one side of it.
            RevealBody.onPaper(pill),
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

/// What the reader said when they met this card, and how it went.
class _AnsweredLine extends StatelessWidget {
  final Pill pill;
  final Answer given;
  const _AnsweredLine({required this.pill, required this.given});

  @override
  Widget build(BuildContext context) {
    if (!pill.isGraded) {
      return Text(
        'You took the side: ${pill.challenge.describe(given.response)}',
        style: AppText.body(
          size: 13,
          weight: FontWeight.w500,
          color: Colors.black.withValues(alpha: 0.55),
        ),
      );
    }

    final right = pill.challenge.accepts(given.response);
    final sure = given.confidence == null
        ? ''
        : ' at ${given.confidence}% sure';
    return Row(
      children: [
        Icon(
          right ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: right ? AppColors.ink : AppColors.red,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            right
                ? 'You got this one$sure'
                : 'You said ${pill.challenge.describe(given.response)}$sure',
            style: AppText.body(
              size: 13,
              weight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
