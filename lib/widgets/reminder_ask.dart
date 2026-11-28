/// The reminder sheet: when to remind the reader, asked before the system
/// asks whether it may.
///
/// At its head, the notification itself, drawn as the phone will show it at
/// the time picked: the app's icon and name, that time where the phone
/// writes "now", the nudge's title and the question from the reader's cards
/// it will carry — on a ground of the time's own colour, under the words
/// "every day at" that time. A reader says yes to a reminder they can see.
/// Under it the question, and the four times as tiles, in the language of
/// the goal's sheet (lib/widgets/aim_picker.dart): each with its glyph on a
/// disc of its colour and edged in it, the one picked edged in it whole,
/// lit by it from under and ticked. Then the two answers, always in view.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pills_repository.dart' show dateKey;
import '../data/topics.dart' show inkOn, kSpectrum;
import '../l10n/l10n.dart';
import '../remote/knobs.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'brand_mark.dart';
import 'fit_text.dart';
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

/// The four answers the sheet offers, each a time of day with a glyph and a
/// colour of its own: the warm amber of the morning, the bright yellow of
/// midday and the deep violet of the evening, three of the subjects' own
/// hues (kSpectrum); and for a time of the reader's own no hue at all, the
/// page's ink.
enum ReminderMoment {
  morning,
  lunch,
  evening,
  other;

  /// Its glyph: the sun on the horizon, the sun high, the moon, a clock.
  IconData get glyph => switch (this) {
    morning => Icons.wb_twilight_rounded,
    lunch => Icons.light_mode_rounded,
    evening => Icons.dark_mode_rounded,
    other => Icons.schedule_rounded,
  };

  /// Its colour as a mark on [p]'s page: the disc its glyph sits on, its
  /// tile's edge and the light under the tile picked. At night the hour's
  /// own; on paper the two yellows deepened through amber, never olive, so
  /// that their edge still draws a line on white; the violet reads on both
  /// as it is. A time of the reader's own is in the page's ink.
  Color tone(Palette p) => switch (this) {
    morning => p.isDark ? kSpectrum[17] : const Color(0xFFB86200),
    lunch => p.isDark ? kSpectrum[0] : const Color(0xFF9E7200),
    evening => kSpectrum[8],
    other => p.ink,
  };

  /// The ground the notification is drawn on at the head of the sheet, the
  /// same at night and on paper, as a card's colour is: the hour's colour
  /// whole, and graphite for a time of the reader's own.
  Color get ground => switch (this) {
    morning => kSpectrum[17],
    lunch => kSpectrum[0],
    evening => kSpectrum[8],
    other => const Color(0xFF2A2A30),
  };

  /// [ground] as it is laid: lit at the top left, the colour itself, and
  /// deeper at the bottom right. The yellows deepen through orange and
  /// amber, as the sun does, where black would have turned them olive.
  List<Color> get shades => [
    Color.lerp(ground, Colors.white, 0.14)!,
    ground,
    switch (this) {
      morning => Color.lerp(ground, kSpectrum[16], 0.42)!,
      lunch => Color.lerp(ground, kSpectrum[17], 0.45)!,
      evening => Color.lerp(ground, Colors.black, 0.18)!,
      other => Color.lerp(ground, Colors.black, 0.45)!,
    },
  ];
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
    // Never up under the clock and the notch: on a small phone at a large
    // text size the sheet is the height of the screen.
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => ReminderAsk(app: app),
  );
}

/// The sheet: the notification as it will come, the question, three times
/// of day and one of the reader's own, and the two answers. Public so a test
/// can lay it out in every language.
class ReminderAsk extends StatefulWidget {
  final AppState app;
  const ReminderAsk({super.key, required this.app});

  @override
  State<ReminderAsk> createState() => _ReminderAskState();
}

class _ReminderAskState extends State<ReminderAsk> {
  /// The three times this sheet offers, read once as it rises: a newer
  /// document does not move a tile under the reader's finger.
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

  /// The question the notification carries on each day it may first land
  /// on, worked out the first time that day is asked about: a pick moves
  /// the time, and only now and then the day.
  final Map<String, String> _questions = {};

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

  /// Which of the four the time chosen is.
  ReminderMoment get _moment {
    final int i = _times.take(3).toList().indexOf(_at);
    return i < 0 ? ReminderMoment.other : ReminderMoment.values[i];
  }

  /// What the nudge will say when it first lands at [at]: the question of
  /// the card that morning opens on, as the plan words it on an ordinary
  /// day (AppState.reminderPlan). A Monday's nudge names the week's book
  /// instead, and a lapse's says something of its own; the sheet promises
  /// a question from the cards, and shows the one that is coming.
  String _questionAt(String at) {
    final DateTime lands = widget.app.firstNudgeAt(at);
    return _questions.putIfAbsent(
      dateKey(lands),
      () => widget.app.leadOn(lands).question,
    );
  }

  void _choose(String at) {
    if (at == _at) return;
    HapticFeedback.selectionClick();
    setState(() => _at = at);
  }

  /// The phone's own clock, for a time none of the three is. A time it
  /// lands on that is one of the three is that tile, not a fourth.
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
    final List<String> names = [
      l.reminderAskMorning,
      l.reminderAskLunch,
      l.reminderAskEvening,
    ];
    final List<ReminderChoice> choices = [
      for (final (int i, String at) in _times.take(3).indexed)
        ReminderChoice(
          key: ValueKey('reminder-at-$at'),
          moment: ReminderMoment.values[i],
          name: names[i],
          time: _shown(at),
          note: at == _usual ? l.reminderAskUsual : null,
          on: _at == at,
          onTap: () => _choose(at),
        ),
      ReminderChoice(
        key: const ValueKey('reminder-at-own'),
        moment: ReminderMoment.other,
        name: l.reminderAskOther,
        time: own == null ? null : _shown(own),
        note: own != null && own == _usual ? l.reminderAskUsual : null,
        on: own != null && _at == own,
        onTap: own == null || _at == own ? _pickOwn : () => _choose(own),
      ),
    ];
    return Container(
      key: const ValueKey('reminder-ask'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: p.inkMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Everything above the answers scrolls, the answers stay: on the
          // smallest phone at the largest text the sheet is taller than the
          // screen, and "Remind me" is never the part that is out of view.
          Flexible(
            child: Stack(
              children: [
                SingleChildScrollView(
                  // The sides inside the scrolling, so that the light under
                  // the ground and under a tile is not cut at the gutter.
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReminderPreview(
                        moment: _moment,
                        time: _shown(_at),
                        title: l.nudgeTitle,
                        question: _questionAt(_at),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          l.reminderAskTitle,
                          style: AppText.display(
                            size: 22,
                            weight: FontWeight.w600,
                            height: 1.15,
                            spacing: -0.3,
                            color: p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.reminderAskLine,
                        style: AppText.body(
                          size: 13.5,
                          height: 1.4,
                          color: p.inkMuted,
                        ),
                      ),
                      // Said only where it is true: a trial that will
                      // charge, with a warning still to come for it
                      // (AppState.trialWarning).
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
                      ReminderTiles(choices: choices),
                    ],
                  ),
                ),
                // What scrolls fades into the page above the answers rather
                // than being cut at a line.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 16,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [p.surface.withValues(alpha: 0), p.surface],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
        ],
      ),
    );
  }
}

/// The notification the reminder will be, at the head of the sheet: drawn
/// as the phone draws one — the app's icon and name, the time picked where
/// the phone writes "now", the nudge's title and the question it carries —
/// shaped as iOS draws its notifications on an iPhone and as Android does
/// on an Android phone. It lies on a ground of the time's own colour, under
/// the words "every day at" that time, and is set in the app's own type: a
/// picture of the notification, never one that passes for the system's.
class ReminderPreview extends StatelessWidget {
  const ReminderPreview({
    super.key,
    required this.moment,
    required this.time,
    required this.title,
    required this.question,
  });

  /// Which of the four times is picked: the colour of the ground and the
  /// glyph over the notification.
  final ReminderMoment moment;

  /// The time picked, as the phone writes it.
  final String time;

  /// The nudge's title, and the question it carries.
  final String title;
  final String question;

  static const Duration _turn = Duration(milliseconds: 260);

  /// The most the phone's text size enlarges the picture by. It is a
  /// picture of the notification, and the choice is under it: at the
  /// largest text on the smallest phone, the picture whole at the phone's
  /// size would be all the sheet showed.
  static const double largestText = 1.3;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Color hue = moment.ground;
    final Color on = inkOn(hue);
    final bool apple = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: largestText,
      // Read out as one thing, as a notification is.
      child: MergeSemantics(
        child: AnimatedContainer(
          key: const ValueKey('reminder-preview'),
          duration: _turn,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(12, 15, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: moment.shades,
              stops: const [0, 0.55, 1],
            ),
            // Lit from under in its colour, as the goal's card is.
            boxShadow: [
              BoxShadow(
                color: hue.withValues(alpha: p.isDark ? 0.26 : 0.24),
                blurRadius: 32,
                spreadRadius: -6,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Icon(moment.glyph, size: 17, color: on),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.everyDayAt(time).toUpperCase(),
                        key: const ValueKey('reminder-preview-every'),
                        style: AppText.label(
                          size: 11,
                          weight: FontWeight.w700,
                          spacing: 1.3,
                          height: 1.3,
                          color: on.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              apple
                  ? _AppleNotification(
                      time: time,
                      title: title,
                      question: question,
                    )
                  : _AndroidNotification(
                      time: time,
                      title: title,
                      question: question,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The words on the notification: dark on its light glass whatever the
/// page, as the phone sets them.
const Color _glassInk = Color(0xFF131316);

/// The notification as iOS draws one: frosted glass, rounded, the app's
/// icon at the left, its name over the title with the time at the far end,
/// and the question under them.
class _AppleNotification extends StatelessWidget {
  const _AppleNotification({
    required this.time,
    required this.title,
    required this.question,
  });

  final String time;
  final String title;
  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Glass: the ground shows through, faintly, under a milk that is
        // thicker at the foot; the edge catches the light.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const _AppIcon(size: 38, round: false),
          const SizedBox(width: 10),
          Expanded(
            child: _NotificationWords(
              time: time,
              title: title,
              question: question,
              apple: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// The notification as Android draws one: a rounded card, the app's icon
/// in a circle at the left, its name and the time over the title, and the
/// question under it.
class _AndroidNotification extends StatelessWidget {
  const _AndroidNotification({
    required this.time,
    required this.title,
    required this.question,
  });

  final String time;
  final String title;
  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AppIcon(size: 36, round: true),
          const SizedBox(width: 12),
          Expanded(
            child: _NotificationWords(
              time: time,
              title: title,
              question: question,
              apple: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// The app's icon as the phone puts it on a notification: its rounded
/// square on an iPhone, cut to a circle on Android. The one that suits the
/// page, as on the phone's home screen.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.size, required this.round});

  final double size;
  final bool round;

  @override
  Widget build(BuildContext context) {
    final Widget mark = BrandMark(size: size);
    return ExcludeSemantics(
      child: round
          ? ClipOval(child: mark)
          : DecoratedBox(
              // A breath of shadow, so the cream icon of the day keeps its
              // edge on the milk of the glass.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 1.5,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
              child: mark,
            ),
    );
  }
}

/// The notification's words: the app's name and the time, the title, the
/// question. Each word of the title and of the question fits a line of its
/// own, the size coming down where one would not.
class _NotificationWords extends StatelessWidget {
  const _NotificationWords({
    required this.time,
    required this.title,
    required this.question,
    required this.apple,
  });

  final String time;
  final String title;
  final String question;
  final bool apple;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final TextStyle meta = AppText.body(
      size: apple ? 13 : 12.5,
      height: 1.3,
      color: _glassInk.withValues(alpha: 0.55),
    );
    final Widget clock = Text(
      time,
      key: const ValueKey('reminder-preview-time'),
      style: meta.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
    // The name and the time on one line, the time at the far end on an
    // iPhone and after a dot on Android; where the two do not fit beside
    // each other, the time goes under the name rather than squeezing it.
    final Widget head = apple
        ? SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              children: [
                Text(
                  l.appName,
                  style: meta.copyWith(
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                    color: _glassInk.withValues(alpha: 0.82),
                  ),
                ),
                clock,
              ],
            ),
          )
        : Wrap(
            children: [
              Text(l.appName, style: meta),
              Text('  ·  ', style: meta),
              clock,
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        head,
        SizedBox(height: apple ? 1 : 3),
        FitText(
          title,
          style: AppText.body(
            size: 14.5,
            weight: FontWeight.w600,
            height: 1.28,
            color: _glassInk,
          ),
          maxLines: 3,
          minSize: 9,
          wholeWords: true,
        ),
        FitText(
          question,
          key: const ValueKey('reminder-preview-question'),
          style: AppText.body(
            size: 14.5,
            height: 1.3,
            color: _glassInk.withValues(alpha: 0.86),
          ),
          maxLines: 8,
          minSize: 9,
          wholeWords: true,
        ),
      ],
    );
  }
}

/// One of the four answers: what it says, and what a tap on it does.
class ReminderChoice {
  const ReminderChoice({
    required this.key,
    required this.moment,
    required this.name,
    required this.time,
    required this.note,
    required this.on,
    required this.onTap,
  });

  final Key key;
  final ReminderMoment moment;
  final String name;

  /// The time, as the phone writes it; null for a time of the reader's own
  /// not yet picked.
  final String? time;

  /// Why the sheet started on it, under the time: "When you usually read".
  final String? note;

  /// Whether it is the one picked.
  final bool on;
  final VoidCallback onTap;
}

/// The four, two to a row where their words fit there: their names at one
/// size, the largest, down from the tile's own, at which every word of the
/// four fits a line of its own, so that no name reads louder than the one
/// beside it and none breaks in two. Where two to a row would take the
/// names below four fifths of that, or a word of a time or a note would
/// not fit, one to a row, each across the sheet: the glyph, the words and
/// the ring side by side.
class ReminderTiles extends StatelessWidget {
  const ReminderTiles({super.key, required this.choices});

  final List<ReminderChoice> choices;

  static const double gap = 10;

  /// [ambient] is the text style the tiles' words are drawn over, which
  /// they take what they do not say from — the page's letter spacing among
  /// it — so that they are measured as they are drawn.
  static ({int columns, double name}) _layout(
    List<ReminderChoice> choices,
    String pick,
    TextStyle ambient,
    double width,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final List<String> names = [for (final ReminderChoice c in choices) c.name];
    double? name(double room, double least) => FitText.oneSize(
      names,
      (size) => ambient.merge(ReminderTile.nameStyle(size)),
      room,
      from: ReminderTile.largestName,
      least: least,
      scaler: scaler,
      direction: direction,
    );
    bool restFits(double room) => choices.every(
      (c) =>
          FitText.wordsFit(
            c.time ?? pick,
            ambient.merge(
              c.time == null ? ReminderTile.pickStyle : ReminderTile.timeStyle,
            ),
            scaler,
            direction,
            room,
          ) &&
          (c.note == null ||
              FitText.wordsFit(
                c.note!,
                ambient.merge(ReminderTile.noteStyle),
                scaler,
                direction,
                room,
              )),
    );
    final double half = (width - gap) / 2 - 2 * ReminderTile.inset;
    final double? halfName = name(half, ReminderTile.largestName * 0.8);
    if (halfName != null && restFits(half)) {
      return (columns: 2, name: halfName);
    }
    return (columns: 1, name: name(width - ReminderTile.aroundRow, 8) ?? 8);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final ({int columns, double name}) layout = _layout(
        choices,
        context.l10n.reminderAskPick,
        DefaultTextStyle.of(context).style,
        box.maxWidth,
        MediaQuery.textScalerOf(context),
        Directionality.of(context),
      );
      Widget tile(ReminderChoice c) => ReminderTile(
        key: c.key,
        choice: c,
        nameSize: layout.name,
        across: layout.columns == 1,
      );
      if (layout.columns == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (int i, ReminderChoice c) in choices.indexed) ...[
              if (i > 0) const SizedBox(height: gap),
              tile(c),
            ],
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < choices.length; i += 2) ...[
            if (i > 0) const SizedBox(height: gap),
            // Two of a row as tall as the taller.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(choices[i])),
                  const SizedBox(width: gap),
                  Expanded(
                    child: i + 1 < choices.length
                        ? tile(choices[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// One time of day to pick: its glyph on a disc of its colour and the ring
/// over the corner, its name in the display face, the time — or, for a time
/// of the reader's own not yet picked, "You choose" — and the note on why
/// the sheet started on it. Edged in its colour; picked, edged in it
/// whole, lit by it from under, and ticked, as a goal's tile is.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.choice,
    this.nameSize = largestName,
    this.across = false,
  });

  final ReminderChoice choice;

  /// The name's size, as [ReminderTiles] sets the four.
  final double nameSize;

  /// Laid across the sheet, the words between the disc and the ring, as
  /// [ReminderTiles] lays the four one to a row.
  final bool across;

  static const double largestName = 17;

  /// The edge and the room inside it, the same whether the edge is the
  /// hairline or the picked one's: picked, the words do not move.
  static const double inset = 14;

  static const double _disc = 34;
  static const double _ring = 22;

  /// The room a tile laid across keeps around its words: its edge and
  /// inset on both sides, the disc and the gap after it, the gap before
  /// the ring and the ring.
  static const double aroundRow = 2 * inset + _disc + 12 + 10 + _ring;

  static TextStyle nameStyle(double size) =>
      AppText.display(size: size, weight: FontWeight.w600, height: 1.14);

  static final TextStyle timeStyle = AppText.body(
    size: 14,
    weight: FontWeight.w600,
    height: 1.3,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Where a time of the reader's own goes until one is picked: "You
  /// choose", quieter than a time.
  static final TextStyle pickStyle = AppText.body(
    size: 14,
    weight: FontWeight.w500,
    height: 1.3,
  );

  static final TextStyle noteStyle = AppText.body(size: 12, height: 1.3);

  static const Duration _turn = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final ReminderChoice c = choice;
    final Color tone = c.moment.tone(p);
    final bool on = c.on;
    final double edge = on ? 1.6 : 1;
    final String? time = c.time;
    final String? note = c.note;
    final String pick = context.l10n.reminderAskPick;
    final Widget ring = AnimatedContainer(
      duration: _turn,
      width: _ring,
      height: _ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? tone : Colors.transparent,
        border: Border.all(color: on ? tone : p.lineStrong, width: 1.5),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: 15, color: inkOn(tone))
          : null,
    );
    final Widget words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(c.name, style: nameStyle(nameSize).copyWith(color: p.ink)),
        const SizedBox(height: 3),
        Text(
          time ?? pick,
          style: time == null
              ? pickStyle.copyWith(color: p.ink.withValues(alpha: 0.45))
              : timeStyle.copyWith(color: p.ink.withValues(alpha: 0.62)),
        ),
        if (note != null) ...[
          const SizedBox(height: 5),
          Text(
            note,
            style: noteStyle.copyWith(color: p.ink.withValues(alpha: 0.55)),
          ),
        ],
      ],
    );
    return Semantics(
      button: true,
      selected: on,
      inMutuallyExclusiveGroup: true,
      label: [c.name, time ?? pick, ?note].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: c.onTap,
        child: AnimatedContainer(
          duration: _turn,
          padding: EdgeInsets.all(inset - edge),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? tone : tone.withValues(alpha: p.isDark ? 0.34 : 0.4),
              width: edge,
            ),
            // Lit from under in its colour rather than washed in it: a
            // yellow laid faint on the night is olive, a glow of it is
            // still yellow.
            boxShadow: [
              BoxShadow(
                color: tone.withValues(
                  alpha: on ? (p.isDark ? 0.34 : 0.26) : 0,
                ),
                blurRadius: 20,
                spreadRadius: -3,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: across
              ? Row(
                  children: [
                    ReminderDisc(moment: c.moment, size: _disc),
                    const SizedBox(width: 12),
                    Expanded(child: words),
                    const SizedBox(width: 10),
                    ring,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ReminderDisc(moment: c.moment, size: _disc),
                        const Spacer(),
                        ring,
                      ],
                    ),
                    const SizedBox(height: 12),
                    words,
                  ],
                ),
        ),
      ),
    );
  }
}

/// A time of day's glyph on a disc of its colour, the glyph in the ink that
/// reads on it.
class ReminderDisc extends StatelessWidget {
  const ReminderDisc({super.key, required this.moment, this.size = 34});

  final ReminderMoment moment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color tone = moment.tone(context.p);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
      alignment: Alignment.center,
      child: Icon(moment.glyph, size: size * 0.5, color: inkOn(tone)),
    );
  }
}
