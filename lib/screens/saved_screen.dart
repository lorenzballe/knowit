import 'package:flutter/material.dart';

import '../data/pills_data.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';

class SavedScreen extends StatelessWidget {
  final AppState app;
  const SavedScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final saved = kPillPool.where((p) => app.isSaved(p.id)).toList();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved',
              style: AppText.outfit(
                size: 33,
                weight: FontWeight.w700,
                height: 1.05,
                spacing: -1.3,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              saved.isEmpty
                  ? 'Nothing yet'
                  : '${saved.length} pill${saved.length == 1 ? '' : 's'}',
              style: AppText.figtree(
                size: 13,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: saved.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: saved.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _SavedRow(
                        pill: saved[i],
                        onUnsave: () => app.toggleSaved(saved[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 34,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the heart on a pill to keep it here for later.',
              textAlign: TextAlign.center,
              style: AppText.figtree(
                size: 14,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  final Pill pill;
  final VoidCallback onUnsave;
  const _SavedRow({required this.pill, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: pill.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.topic.toUpperCase(),
                  style: AppText.mono(
                    size: 10.5,
                    spacing: 1.2,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pill.question,
                  style: AppText.figtree(
                    size: 15,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onUnsave,
            icon: const Icon(Icons.favorite_rounded, size: 18),
            color: pill.color,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
