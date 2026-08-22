import 'package:flutter/material.dart';

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
          style: AppText.outfit(size: 19, color: AppColors.ink),
        ),
        content: Text(
          'This clears your streak, your saved pills and your topics on '
          'this device.',
          style: AppText.figtree(
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
              style: AppText.figtree(size: 14, color: AppColors.ink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sign out',
              style: AppText.figtree(
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
    final saved = app.savedIds.length;

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
                  style: AppText.outfit(
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
                      style: AppText.outfit(
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
                      style: AppText.figtree(
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
              _Stat(value: '$saved', label: 'saved'),
            ],
          ),
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
                        style: AppText.figtree(
                          size: 14.5,
                          weight: FontWeight.w500,
                          height: 1.2,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your 5 pills, before the first coffee.',
                        style: AppText.figtree(
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
                        behavior: SnackBarBehavior.floating,
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
                      style: AppText.figtree(
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
                  style: AppText.figtree(
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
                          style: AppText.outfit(
                            size: 17,
                            weight: FontWeight.w600,
                            color: AppColors.limeInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '5 extra pills a day, full archive.',
                          style: AppText.figtree(
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
                      style: AppText.figtree(
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
              style: AppText.outfit(
                size: 24,
                weight: FontWeight.w700,
                height: 1,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.figtree(
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
              style: AppText.figtree(
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
