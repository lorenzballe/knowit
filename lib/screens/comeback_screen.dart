import 'package:flutter/material.dart';

import '../data/topics.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Shown once when a streak has lapsed: what was missed, and the way back in.
class ComebackScreen extends StatelessWidget {
  final AppState app;
  final VoidCallback onContinue;

  const ComebackScreen({
    super.key,
    required this.app,
    required this.onContinue,
  });

  String _spell(int n) {
    const words = [
      'zero',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
    ];
    return n < words.length ? words[n] : '$n';
  }

  /// The topic the reader has kept the most pills from — the one they will
  /// miss noticing.
  String? get _favouriteTopic {
    if (app.savedIds.isEmpty) return null;
    final counts = <String, int>{};
    for (final id in app.savedIds) {
      final key = id.split('-').first;
      final style = kTopics[key];
      if (style != null) {
        counts[style.name] = (counts[style.name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.key;
  }

  @override
  Widget build(BuildContext context) {
    final missed = app.missedDays;
    final unread = missed * 5;
    final favourite = _favouriteTopic;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: FlexPage(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow('Streak reset', color: context.p.alert),
              const SizedBox(height: 11),
              Text(
                missed == 1
                    ? 'You missed\na day.'
                    : 'You missed\n${_spell(missed)} days.',
                style: AppText.display(
                  size: 38,
                  weight: FontWeight.w700,
                  height: 1.05,
                  spacing: -1.5,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                '${_spell(app.bestStreak)[0].toUpperCase()}'
                '${_spell(app.bestStreak).substring(1)} '
                '${app.bestStreak == 1 ? 'day is' : 'days is'} still your '
                "record. Read today's five and the counter starts again "
                'from one.',
                style: AppText.body(
                  size: 15,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              WeekStrip(
                week: app.weekCompletion(),
                onColor: context.p.inverse,
                offColor: context.p.line,
              ),
              const SizedBox(height: 24),
              PaperCard(
                padding: const EdgeInsets.all(20),
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('While you were away'),
                    const SizedBox(height: 14),
                    _MissedLine(
                      color: context.p.alert,
                      text: '$unread pill${unread == 1 ? '' : 's'} went unread',
                    ),
                    if (favourite != null) ...[
                      const SizedBox(height: 11),
                      _MissedLine(
                        color: context.p.link,
                        text: '$favourite is still your most kept topic',
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: "Start again with today's five",
                onPressed: onContinue,
              ),
              const SizedBox(height: 4),
              QuietButton(
                label: app.notifyTime == '19:00'
                    ? 'Move my reminder to 08:30'
                    : 'Move my reminder to 19:00',
                onPressed: () async {
                  final next = app.notifyTime == '19:00' ? '08:30' : '19:00';
                  await app.setNotifyTime(next);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Daily nudge moved to $next.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissedLine extends StatelessWidget {
  final Color color;
  final String text;
  const _MissedLine({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TopicDot(color, size: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: context.p.ink,
            ),
          ),
        ),
      ],
    );
  }
}
