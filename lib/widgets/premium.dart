import 'package:flutter/material.dart';

import '../screens/paywall_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// The three Knowit+ perks the paywall sells. Anything gated behind one of
/// these opens the paywall for readers on the free plan.
///
/// Runs [action] when the reader has Knowit+, otherwise pushes the paywall.
Future<void> requirePlus(
  BuildContext context,
  AppState app,
  VoidCallback action,
) async {
  if (app.isPlus) {
    action();
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => PaywallScreen(app: app)));
  // Coming back with the trial started, go straight through to what they
  // were reaching for.
  if (app.isPlus && context.mounted) action();
}

/// Small lock chip that marks a gated entry point on the free plan.
class PlusLock extends StatelessWidget {
  final bool locked;
  const PlusLock({super.key, required this.locked});

  @override
  Widget build(BuildContext context) {
    if (!locked) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.p.link.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: context.p.link),
          const SizedBox(width: 4),
          Text(
            'Knowit+',
            style: AppText.label(
              size: 9,
              weight: FontWeight.w600,
              spacing: 0.6,
              color: context.p.link,
            ),
          ),
        ],
      ),
    );
  }
}
