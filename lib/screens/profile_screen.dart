import 'package:flutter/material.dart';

import '../data/pills_data.dart';
import '../data/topics.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/premium.dart';
import '../widgets/ui.dart';
import 'archive_screen.dart';
import 'how_screen.dart';
import 'paywall_screen.dart';
import 'topics_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppState app;
  final VoidCallback onSignedOut;

  const ProfileScreen({
    super.key,
    required this.app,
    required this.onSignedOut,
  });

  Future<void> _editTopics(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => TopicsScreen(
          initial: app.pickedTopics,
          isOnboarding: false,
          onBack: () => Navigator.of(routeContext).pop(),
          onDone: (picked) async {
            await app.setTopics(picked);
            if (routeContext.mounted) Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(
          'Sign out?',
          style: AppText.display(size: 19, color: AppColors.ink),
        ),
        content: Text(
          'This clears your streak, your saved pills and your topics on '
          'this device.',
          style: AppText.body(
            size: 14,
            height: 1.45,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppText.body(size: 14, color: AppColors.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sign out',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await app.signOut();
      onSignedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  app.initials,
                  style: AppText.display(
                    size: 18,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w700,
                        height: 1.1,
                        spacing: -0.7,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.isPlus
                          ? 'Knowit+ · ${app.pickedTopics.length} topics'
                          : 'Free plan · ${app.pickedTopics.length} topics',
                      style: AppText.body(
                        size: 12.5,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(value: '${app.liveStreak}', label: 'day streak'),
              const SizedBox(width: 10),
              _Stat(value: '${app.pillsRead}', label: 'pills read'),
              const SizedBox(width: 10),
              _Stat(
                value: app.puzzlesAnswered == 0
                    ? '—'
                    : '${app.puzzlesRight}/${app.puzzlesAnswered}',
                label: 'puzzles right',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Eyebrow('What you have covered'),
          const SizedBox(height: 11),
          _Coverage(app: app),
          const SizedBox(height: 22),
          const Eyebrow('Daily nudge'),
          const SizedBox(height: 11),
          PaperCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            radius: 18,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Every day at ${app.notifyTime}',
                        style: AppText.body(
                          size: 14.5,
                          weight: FontWeight.w500,
                          height: 1.2,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your 5 pills, before the first coffee.',
                        style: AppText.body(
                          size: 12,
                          height: 1.3,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                NudgeSwitch(
                  value: app.notificationsOn,
                  onChanged: (v) async {
                    await app.setNotifications(v);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v
                              ? 'Nudge on. Delivery needs the mobile build.'
                              : 'Nudge off.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Eyebrow('Your topics'),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    requirePlus(context, app, () => _editTopics(context)),
                child: Row(
                  children: [
                    Text(
                      'Edit',
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: AppColors.blue,
                      ),
                    ),
                    PlusLock(locked: !app.isPlus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kTopicOrder.where(app.pickedTopics.contains).map((key) {
              final style = kTopics[key]!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  style.name,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: style.ink,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          if (!app.isPlus)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lime, AppColors.limeDark],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Knowit+',
                          style: AppText.display(
                            size: 17,
                            weight: FontWeight.w600,
                            color: AppColors.limeInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 extra pills a day, full archive.',
                          style: AppText.body(
                            size: 12.5,
                            color: AppColors.limeInk.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PaywallScreen(app: app),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.limeInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Upgrade',
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFFE9FFC4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _LinkRow(
            label: 'Archive',
            locked: !app.isPlus,
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
          ),
          _LinkRow(
            label: 'Manage subscription',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => PaywallScreen(app: app))),
          ),
          _LinkRow(
            label: 'How pills are written',
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const HowScreen())),
          ),
          _LinkRow(
            label: 'Sign out',
            muted: true,
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PaperCard(
        padding: const EdgeInsets.all(16),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppText.display(
                size: 24,
                weight: FontWeight.w700,
                height: 1,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.body(
                size: 11.5,
                height: 1.3,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool muted;
  final bool locked;

  const _LinkRow({
    required this.label,
    required this.onTap,
    this.muted = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: muted
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.ink,
              ),
            ),
            PlusLock(locked: locked),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

/// The collection, topic by topic. A daily app needs somewhere to be going,
/// and a bar that fills is the cheapest honest version of that.
class _Coverage extends StatelessWidget {
  final AppState app;
  const _Coverage({required this.app});

  @override
  Widget build(BuildContext context) {
    final byTopic = <String, int>{};
    final seenByTopic = <String, int>{};
    for (final pill in kPillPool) {
      byTopic[pill.topic] = (byTopic[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        seenByTopic[pill.topic] = (seenByTopic[pill.topic] ?? 0) + 1;
      }
    }

    final rows = kTopicOrder
        .where(app.pickedTopics.contains)
        .map((key) => kTopics[key]!)
        .where((style) => (byTopic[style.name] ?? 0) > 0)
        .toList();

    final seenTotal = app.seenIds.length;
    final poolTotal = kPillPool.length;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$seenTotal of $poolTotal pills',
            style: AppText.display(
              size: 20,
              weight: FontWeight.w600,
              spacing: -0.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.map((style) {
            final total = byTopic[style.name] ?? 0;
            final seen = seenByTopic[style.name] ?? 0;
            final complete = seen >= total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          style.name,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        complete ? 'complete' : '$seen/$total',
                        style: AppText.body(
                          size: 12,
                          weight: complete ? FontWeight.w600 : FontWeight.w400,
                          color: complete
                              ? style.color
                              : Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : seen / total,
                      minHeight: 5,
                      backgroundColor: Colors.black.withValues(alpha: 0.07),
                      valueColor: AlwaysStoppedAnimation(style.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
