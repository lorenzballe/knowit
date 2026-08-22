import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';

const _weekLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class ProfileScreen extends StatelessWidget {
  final AppState app;
  const ProfileScreen({super.key, required this.app});

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what is coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final week = app.weekCompletion();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          Text(
            'Profile',
            style: AppText.outfit(
              size: 33,
              weight: FontWeight.w700,
              height: 1.05,
              spacing: -1.3,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'KW',
                  style: AppText.outfit(
                    size: 16,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${app.streak} day streak',
                    style: AppText.figtree(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${app.completedDates.length} days completed total',
                    style: AppText.figtree(
                      size: 12.5,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 30,
                        decoration: BoxDecoration(
                          color: week[i]
                              ? AppColors.ink
                              : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _weekLetters[i],
                        style: AppText.mono(
                          size: 10,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 26),
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
                          color: const Color(0xFF17200A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 extra pills a day, full archive.',
                        style: AppText.figtree(
                          size: 12.5,
                          color: const Color(0xFF17200A)
                              .withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _comingSoon(context, 'Knowit+'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF17200A),
                    foregroundColor: const Color(0xFFE9FFC4),
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
          const SizedBox(height: 26),
          _SettingsGroup(
            children: [
              _SettingsRow(
                label: 'Topics',
                onTap: () => _comingSoon(context, 'Topic picking'),
              ),
              _SettingsRow(
                label: 'Daily notification',
                onTap: () => _comingSoon(context, 'Notifications'),
              ),
              _SettingsRow(
                label: 'About Knowit',
                onTap: () => _comingSoon(context, 'About'),
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLast;
  const _SettingsRow({
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.figtree(
                  size: 15,
                  weight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
