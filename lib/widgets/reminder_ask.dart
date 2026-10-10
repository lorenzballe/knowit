import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'ui.dart';

/// The times the sheet offers, in the order a day runs: before the first
/// coffee, at lunch, and the evening, when most days are read.
const List<String> kReminderTimes = ['08:30', '12:30', '19:00'];

/// Asks when to remind the reader, before the system asks whether it may.
///
/// iOS shows its notification prompt once, and a no there closes the one
/// channel that brings a reader back. So the app puts its own question first,
/// and a better one: not whether, but when — a time the reader chose, rather
/// than one they never saw. Returns that time as "HH:mm", or null for "Not
/// now", which spends nothing: the system's prompt is still unasked, and the
/// sheet comes back after another day.
///
/// A sheet swiped away is a "Not now" too: nobody chose a time.
Future<String?> showReminderAsk(BuildContext context, AppState app) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => ReminderAsk(app: app),
  );
}

/// The sheet: what the reminder is, three times of day and one of the
/// reader's own, and the two answers. Public so a test can lay it out in
/// every language.
class ReminderAsk extends StatefulWidget {
  final AppState app;
  const ReminderAsk({super.key, required this.app});

  @override
  State<ReminderAsk> createState() => _ReminderAskState();
}

class _ReminderAskState extends State<ReminderAsk> {
  /// The time chosen, starting on the one the reminder is already set to:
  /// what is armed should be what the sheet shows.
  late String _at = widget.app.notifyTime;

  /// A time of the reader's own, once there is one: picked on the clock, or
  /// already set to something other than the three.
  late String? _own = kReminderTimes.contains(_at) ? null : _at;

  static TimeOfDay _timeOf(String at) {
    final List<String> parts = at.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 30) : 30,
    );
  }

  static String _keyOf(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// A time as the phone writes one: 8:30 AM or 08:30, as the phone is set.
  String _shown(String at) => MaterialLocalizations.of(context).formatTimeOfDay(
    _timeOf(at),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );

  void _choose(String at) {
    if (at == _at) return;
    HapticFeedback.selectionClick();
    setState(() => _at = at);
  }

  /// The phone's own clock, for a time none of the three is. A time it
  /// lands on that is one of the three is that row, not a fourth.
  Future<void> _pickOwn() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOf(_own ?? _at),
    );
    if (picked == null || !mounted) return;
    final String at = _keyOf(picked);
    HapticFeedback.selectionClick();
    setState(() {
      _at = at;
      _own = kReminderTimes.contains(at) ? null : at;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final String? own = _own;
    final List<(String, String)> times = [
      (kReminderTimes[0], l.reminderAskMorning),
      (kReminderTimes[1], l.reminderAskLunch),
      (kReminderTimes[2], l.reminderAskEvening),
    ];
    return Container(
      key: const ValueKey('reminder-ask'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.reminderAskTitle,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.reminderAskLine,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            // Said only where it is true: a trial that will charge, with a
            // warning still to come for it (AppState.trialWarning).
            if (widget.app.warnsBeforeTrialEnds) ...[
              const SizedBox(height: 6),
              Text(
                l.reminderAskTrialLine,
                key: const ValueKey('reminder-ask-trial'),
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w500,
                  height: 1.4,
                  color: p.ink,
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (final (String at, String label) in times) ...[
              _Choice(
                key: ValueKey('reminder-at-$at'),
                label: label,
                time: _shown(at),
                chosen: _at == at,
                onTap: () => _choose(at),
              ),
              const SizedBox(height: 8),
            ],
            _Choice(
              key: const ValueKey('reminder-at-own'),
              label: l.reminderAskOther,
              time: own == null ? null : _shown(own),
              chosen: own != null && _at == own,
              onTap: own == null || _at == own ? _pickOwn : () => _choose(own),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              key: const ValueKey('reminder-yes'),
              label: l.reminderAskYes,
              height: 52,
              onPressed: () => Navigator.of(context).pop(_at),
            ),
            const SizedBox(height: 4),
            QuietButton(
              key: const ValueKey('reminder-not-now'),
              label: l.reminderAskNotNow,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One time of day, as a row to tap: a ring, filled once it is the one,
/// the name of the time, and the time itself at the far end.
class _Choice extends StatelessWidget {
  final String label;
  final String? time;
  final bool chosen;
  final VoidCallback onTap;

  const _Choice({
    super.key,
    required this.label,
    required this.time,
    required this.chosen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = chosen ? p.onInverse : p.ink;
    final String? time = this.time;
    return Semantics(
      button: true,
      selected: chosen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(
            color: chosen ? p.inverse : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: chosen ? p.inverse : p.line),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink.withValues(alpha: 0.6)),
                ),
                alignment: Alignment.center,
                child: chosen
                    ? Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ink,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w500,
                    height: 1.3,
                    color: ink,
                  ),
                ),
              ),
              if (time != null) ...[
                const SizedBox(width: 12),
                Text(
                  time,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: chosen ? ink : p.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
