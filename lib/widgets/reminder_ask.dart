import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../remote/knobs.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'ui.dart';

/// The times the sheet offers, in the order a day runs: before the first
/// coffee, at lunch, and the evening, when most days are read.
const List<String> kReminderTimes = ['08:30', '12:30', '19:00'];

/// The three, as the server may move them (`push.times`): each within the
/// part of the day its word names — the morning before eleven, lunchtime
/// before three, the evening from five to eleven — so "Morning" never
/// stands beside a time in the afternoon.
const RemoteTimes kReminderTimesKnob = RemoteTimes(
  'push.times',
  fallback: kReminderTimes,
  windows: [('05:00', '11:00'), ('11:00', '15:00'), ('17:00', '23:00')],
);

/// The times the sheet offers now: [kReminderTimes], or the server's.
List<String> reminderTimes() => kReminderTimesKnob.value;

/// The reminder that suits a reader who starts reading [minute] minutes
/// after midnight, as "HH:mm": one of the three, when it falls in the hour
/// before that or a quarter of an hour after it; otherwise that time itself,
/// to the quarter hour before. A nudge is worth most just as the reader
/// would open the app anyway, and least once they have gone to bed.
String reminderTimeFor(int minute) {
  for (final String at in reminderTimes()) {
    final int ahead = minute - _minuteOf(at);
    if (ahead >= -15 && ahead <= 60) return at;
  }
  final int at = minute - minute % 15;
  return '${(at ~/ 60).toString().padLeft(2, '0')}:'
      '${(at % 60).toString().padLeft(2, '0')}';
}

/// The time the reader's habit points to ([AppState.usualReadMinute]), as
/// a reminder would fall for it, while they have not picked one of their
/// own; null once they have, or before there is a card to go by. Where the
/// sheet starts, and what it says it started on.
String? habitReminderTime(AppState app) {
  if (app.notifyTimeChosen) return null;
  final int? minute = app.usualReadMinute;
  return minute == null ? null : reminderTimeFor(minute);
}

int _minuteOf(String at) {
  final List<String> parts = at.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// Asks when to remind the reader, before the system asks whether it may.
///
/// iOS shows its notification prompt once, and a no there closes the one
/// channel that brings a reader back. So the app puts its own question first,
/// and a better one: not whether, but when — a time the reader chose, rather
/// than one they never saw. Returns that time as "HH:mm", or null for "Not
/// now", which spends nothing: the system's prompt is still unasked, and the
/// sheet comes back three days later.
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
  /// The three times this sheet offers, read once as it rises: a newer
  /// document does not move a row under the reader's finger.
  late final List<String> _times = reminderTimes();

  /// The time the reader has been starting to read at, as a reminder would
  /// fall for it, until they pick one of their own ([habitReminderTime]).
  late final String? _usual = habitReminderTime(widget.app);

  /// The time chosen, starting on the reader's habit, or on the time the
  /// reminder is already set to once they have picked one: what is armed
  /// should be what the sheet shows.
  late String _at = _usual ?? widget.app.notifyTime;

  /// A time of the reader's own, once there is one: picked on the clock, or
  /// already set to something other than the three.
  late String? _own = _times.contains(_at) ? null : _at;

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
      _own = _times.contains(at) ? null : at;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final String? own = _own;
    final List<(String, String)> times = [
      (_times[0], l.reminderAskMorning),
      (_times[1], l.reminderAskLunch),
      (_times[2], l.reminderAskEvening),
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
                note: at == _usual ? l.reminderAskUsual : null,
                time: _shown(at),
                chosen: _at == at,
                onTap: () => _choose(at),
              ),
              const SizedBox(height: 8),
            ],
            _Choice(
              key: const ValueKey('reminder-at-own'),
              label: l.reminderAskOther,
              note: own != null && own == _usual ? l.reminderAskUsual : null,
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
/// the name of the time, and the time itself at the far end. [note], under
/// the name, says why the sheet started on it.
class _Choice extends StatelessWidget {
  final String label;
  final String? note;
  final String? time;
  final bool chosen;
  final VoidCallback onTap;

  const _Choice({
    super.key,
    required this.label,
    this.note,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.body(
                        size: 14.5,
                        weight: FontWeight.w500,
                        height: 1.3,
                        color: ink,
                      ),
                    ),
                    if (note case final String note)
                      Text(
                        note,
                        style: AppText.body(
                          size: 12,
                          height: 1.3,
                          color: ink.withValues(alpha: 0.66),
                        ),
                      ),
                  ],
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
