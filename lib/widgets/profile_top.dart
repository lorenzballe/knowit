/// The top of the profile: the number it opens on, the way into Your
/// journey, and the tile that goes back to Today's five.
///
/// It used to open on the streak, "Your record · 4 days", and then say the
/// streak again in the panel under it, beside "Today: 5 of 5 read · all
/// read". A reader on the free plan saw no score anywhere, and a button
/// lower down into a journey they could not picture. Three answers were
/// drawn side by side for the owner ([ProfileTop]), and he chose one for
/// each plan ([profileTopFor]): the score on the free plan, the board on
/// Astute+, its days in a row lit as the streak they are. The developer
/// tools show any of the three on either plan (DebugLooks).
///
/// The score is read exactly as Your journey reads it — [scoreBookOf], its
/// overall score, [scoreNumber], [ScoreWeek] and [ScoreSpark] — so the two
/// never say different numbers, however the score comes to be counted.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/pills_repository.dart' show dateKey, dayShift, kPillsPerDay;
import '../data/skill_scores.dart' show SkillScore;
import '../explore/blocks/core/your_day_block.dart'
    show StreakChip, kStreakOrange, weekOf;
import '../l10n/l10n.dart';
import '../screens/journey_screen.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import 'premium.dart';
import 'skill_score.dart';
import 'ui.dart' show Eyebrow;

/// The three tops the profile can open on: A, B and C, as the owner knows
/// them.
enum ProfileTop {
  /// A. The Astute score, large, with how far it moved this week and its
  /// line over the month; under it the way into Your journey; then the
  /// week, a day to a dot, today's dot filling card by card, the streak at
  /// its end.
  score,

  /// B. What the last seven days added to the score, large, with a bar for
  /// each day; the score itself under it; Today's five as one slim row.
  week,

  /// C. Three numbers in one panel, the score first, the days in a row,
  /// lit while they run, and the cards read beside it, with Today's five
  /// at its foot.
  board,
}

/// The top each plan opens on: on the free plan the score, the one number
/// about the reader, over the way into the journey that holds the rest of
/// it; on Astute+, with the journey already theirs, the board, where the
/// score stands beside the streak and the cards read.
ProfileTop profileTopFor({required bool plus}) =>
    plus ? ProfileTop.board : ProfileTop.score;

/// The top the profile opens on for [app]'s reader: the camera's, when it
/// photographs them; the one picked in the developer tools; else their
/// plan's own.
ProfileTop profileTopOf(AppState app) =>
    profileTopForShots ??
    switch (DebugLooks.profileTopPicked) {
      ProfileTopPick.auto => profileTopFor(plus: app.isPlus),
      ProfileTopPick.a => ProfileTop.score,
      ProfileTopPick.b => ProfileTop.week,
      ProfileTopPick.c => ProfileTop.board,
    };

/// The top the camera photographs instead (tool/profile_shots.dart), so
/// all three can be seen in the real app. Null everywhere else.
@visibleForTesting
ProfileTop? profileTopForShots;

/// How many of today's five are read: all of them once the day is closed,
/// however many more a second set dealt after them.
int _readToday(AppState app) =>
    app.dayClosed ? kPillsPerDay : app.todayIndex.clamp(0, kPillsPerDay);

/// Opens Your journey: on the free plan, the plans, on the journey's own
/// door, and straight through to the journey if a trial is taken there.
void _openJourney(BuildContext context, AppState app) => requirePlus(
  context,
  app,
  () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (routeContext) => JourneyScreen(
        app: app,
        onBack: () => Navigator.of(routeContext).pop(),
      ),
    ),
  ),
  source: 'journey',
);

/// The top, as [profileTopOf] has it for the reader.
class ProfileTopView extends StatelessWidget {
  const ProfileTopView({super.key, required this.app, this.onToday});

  final AppState app;

  /// Takes the reader to Today, told where the tile tapped for it is on
  /// the screen, so Today can open out of it.
  final ValueChanged<Rect?>? onToday;

  @override
  Widget build(BuildContext context) {
    // A top picked in the developer tools shows at once. A change of plan
    // redraws the whole app, and this with it.
    return ValueListenableBuilder<ProfileTopPick>(
      valueListenable: DebugLooks.profileTop,
      builder: (context, _, _) {
        final SkillScore score = scoreBookOf(app).overall;
        return switch (profileTopOf(app)) {
          ProfileTop.score => _ScoreTop(
            app: app,
            score: score,
            onToday: onToday,
          ),
          ProfileTop.week => _WeekTop(app: app, score: score, onToday: onToday),
          ProfileTop.board => _BoardTop(
            app: app,
            score: score,
            onToday: onToday,
          ),
        };
      },
    );
  }
}

// ── A · The score ─────────────────────────────────────────────────────────

/// The Astute score first: the one number about the reader rather than
/// about the app's counter, and the one every answer moves. Then the way
/// into the journey, which holds the rest of it, and the week.
class _ScoreTop extends StatelessWidget {
  const _ScoreTop({required this.app, required this.score, this.onToday});

  final AppState app;
  final SkillScore score;
  final ValueChanged<Rect?>? onToday;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    return Column(
      key: const ValueKey('profile-top-score'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.scoreTitle),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: '${l.scoreTitle}, ${scoreNumber(context, score.now)}',
          child: _Hero(
            number: scoreNumber(context, score.now),
            numberKey: const ValueKey('profile-score'),
            colour: p.ink,
            note: ScoreWeek(score: score, size: 14),
          ),
        ),
        const SizedBox(height: 12),
        // The month, as the journey draws it; before a first answer, what
        // moves the number, where a level line would say nothing.
        if (score.answers > 0)
          ExcludeSemantics(
            child: ScoreSpark(values: score.days, colour: p.ink, height: 44),
          )
        else
          Text(
            l.trainingLine,
            style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
          ),
        const SizedBox(height: 18),
        _JourneyRow(app: app),
        const SizedBox(height: 18),
        _WeekTile(app: app, onToday: onToday),
      ],
    );
  }
}

/// The week as Today's way in: the five's state at the head, then the
/// seven days, a dot each, today's filling a fifth at a time, and the
/// streak at the end, where it belongs to the week rather than heading the
/// page.
class _WeekTile extends StatelessWidget {
  const _WeekTile({required this.app, this.onToday});

  final AppState app;
  final ValueChanged<Rect?>? onToday;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final int read = _readToday(app);
    final int streak = app.liveStreak;
    return _TodayTap(
      app: app,
      onToday: onToday,
      radius: 20,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TodayHead(app: app),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Week(app: app, read: read),
                ),
                if (streak > 0) ...[
                  const SizedBox(width: 8),
                  StreakChip(
                    key: const ValueKey('profile-streak'),
                    streak: streak,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── B · The week ──────────────────────────────────────────────────────────

/// What the last seven days added to the score, first: a change reads on
/// the first day, where a score of a thousand and something only reads
/// once you know the scale, and it is the week the app counts in already.
/// The bars are those seven days, so the habit is drawn there and needs no
/// number of its own.
class _WeekTop extends StatelessWidget {
  const _WeekTop({required this.app, required this.score, this.onToday});

  final AppState app;
  final SkillScore score;
  final ValueChanged<Rect?>? onToday;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final int week = score.answers == 0 ? 0 : score.week;
    final int streak = app.liveStreak;
    return Column(
      key: const ValueKey('profile-top-week'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Eyebrow(l.profileWeekTitle)),
            if (streak > 0)
              StreakChip(
                key: const ValueKey('profile-streak'),
                streak: streak,
                height: 26,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          label: l.scoreWeek(signedNumber(context, week)),
          excludeSemantics: true,
          child: _Hero(
            number: signedNumber(context, week),
            numberKey: const ValueKey('profile-week-points'),
            colour: week > 0 ? scoreUp(context) : p.ink,
            note: Text(
              l.profileWeekPoints(week.abs()),
              style: AppText.body(
                size: 16,
                weight: FontWeight.w500,
                color: p.inkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          key: const ValueKey('profile-score'),
          TextSpan(
            children: [
              TextSpan(text: '${l.scoreTitle}  '),
              TextSpan(
                text: scoreNumber(context, score.now),
                style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
              ),
              if (score.answers == 0) TextSpan(text: '  ·  ${l.scoreStart}'),
            ],
          ),
          style: AppText.body(size: 14, height: 1.35, color: p.inkMuted),
        ),
        const SizedBox(height: 18),
        _DayBars(app: app, score: score),
        const SizedBox(height: 18),
        _JourneyRow(app: app),
        const SizedBox(height: 16),
        _TodayTap(
          app: app,
          onToday: onToday,
          radius: 18,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line),
            ),
            child: _TodayHead(app: app, bars: true),
          ),
        ),
      ],
    );
  }
}

/// The last seven days, a bar each for what the day added to the score,
/// today's at the right end, under each the letter of its day. A day read
/// that moved nothing is a stub, a day not read a dot; a day that cost
/// points hangs below the line.
class _DayBars extends StatelessWidget {
  const _DayBars({required this.app, required this.score});

  final AppState app;
  final SkillScore score;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final List<int> days = score.days;
    final Set<String> done = app.completedDates.toSet();
    final String todayKey = dateKey(app.today);
    final bool readSome = _readToday(app) > 0;
    final DateFormat letter = DateFormat(
      'EEEEE',
      Localizations.localeOf(context).toLanguageTag(),
    );
    final List<({DateTime day, int? moved, bool today})> bars = [
      for (int back = 6; back >= 0; back--)
        () {
          final DateTime day = dayShift(app.today, -back);
          final int at = days.length - 1 - back;
          final bool isToday = back == 0;
          final bool read = isToday
              ? readSome || done.contains(todayKey)
              : done.contains(dateKey(day));
          final int moved = at >= 1 ? days[at] - days[at - 1] : 0;
          return (
            day: day,
            moved: read || moved != 0 ? moved : null,
            today: isToday,
          );
        }(),
    ];
    final int most = bars.fold<int>(
      1,
      (m, b) => math.max(m, (b.moved ?? 0).abs()),
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (int i, b) in bars.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _BarPainter(
                        moved: b.moved,
                        most: most,
                        ink: b.today ? p.ink : p.ink.withValues(alpha: 0.3),
                        faint: p.ink.withValues(alpha: 0.14),
                        up: b.today ? scoreUp(context) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    letter.format(b.day),
                    maxLines: 1,
                    style: AppText.label(
                      size: 10,
                      spacing: 0.4,
                      color: b.today ? p.ink : p.ink.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.moved,
    required this.most,
    required this.ink,
    required this.faint,
    this.up,
  });

  /// What the day added, or null for a day not read.
  final int? moved;
  final int most;
  final Color ink;
  final Color faint;

  /// Today's rise, in the colour of a rise.
  final Color? up;

  @override
  void paint(Canvas canvas, Size size) {
    // The line sits low: rises are what the bars are for, and a fall hangs
    // a short way under it.
    final double base = size.height - 12;
    final double room = base - 2;
    final Paint line = Paint()..color = faint;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, base - 0.5, size.width, 1),
        const Radius.circular(1),
      ),
      line,
    );
    final int? m = moved;
    if (m == null) {
      canvas.drawCircle(Offset(size.width / 2, base), 2.2, line);
      return;
    }
    // Narrow, with a rounded top, as a phone's own week of bars is drawn.
    const double w = 16;
    final double left = (size.width - w) / 2;
    if (m >= 0) {
      final double h = math.max(4, room * m / most);
      final Radius top = Radius.circular(math.min(w / 2, h / 2));
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, base - h, w, h),
          topLeft: top,
          topRight: top,
          bottomLeft: const Radius.circular(1.5),
          bottomRight: const Radius.circular(1.5),
        ),
        Paint()..color = m > 0 && up != null ? up! : ink,
      );
    } else {
      // A day that cost points: short, under the line, quieter than a rise.
      final double h = math.max(4, 9 * -m / most);
      final Radius foot = Radius.circular(math.min(w / 2, h / 2));
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, base + 2, w, h),
          topLeft: const Radius.circular(1.5),
          topRight: const Radius.circular(1.5),
          bottomLeft: foot,
          bottomRight: foot,
        ),
        Paint()..color = ink.withValues(alpha: ink.a * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.moved != moved ||
      old.most != most ||
      old.ink != ink ||
      old.faint != faint ||
      old.up != up;
}

// ── C · The board ─────────────────────────────────────────────────────────

/// Three numbers in a row, as a dashboard keeps them: the score first,
/// how steady, how much. Only the streak is lit, while it runs; Today's
/// five is the panel's foot, and the journey a row of its own under it.
class _BoardTop extends StatelessWidget {
  const _BoardTop({required this.app, required this.score, this.onToday});

  final AppState app;
  final SkillScore score;
  final ValueChanged<Rect?>? onToday;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final int streak = app.liveStreak;
    final int read = app.seenIds.length;
    Widget divider() => Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: p.line,
    );
    return Column(
      key: const ValueKey('profile-top-board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(l.yourRecord),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _Stat(
                          key: const ValueKey('profile-score'),
                          number: scoreNumber(context, score.now),
                          label: l.scoreTitle,
                          foot: ScoreWeek(score: score, size: 12),
                        ),
                      ),
                      divider(),
                      Expanded(
                        flex: 4,
                        child: _Stat(
                          key: const ValueKey('profile-streak'),
                          number: scoreNumber(context, streak),
                          label: l.profileInARowLabel(streak),
                          lit: streak > 0,
                        ),
                      ),
                      divider(),
                      Expanded(
                        flex: 4,
                        child: _Stat(
                          number: scoreNumber(context, read),
                          label: l.pillReadWord(read),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: 1, color: p.line),
              _TodayTap(
                app: app,
                onToday: onToday,
                radius: 22,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 15),
                  child: _TodayHead(app: app, bars: true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _JourneyRow(app: app, boxed: true),
      ],
    );
  }
}

/// One number of the board: the number, what it counts, and under the
/// score how far it moved.
class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.number,
    required this.label,
    this.foot,
    this.lit = false,
  });

  final String number;
  final String label;
  final Widget? foot;

  /// The days in a row while they run: the number lit in the streak's
  /// orange with its flame before it, as the week's finished days and the
  /// streak's own chip are lit ([_Lit]).
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final TextStyle style = AppText.display(
      size: 34,
      weight: FontWeight.w600,
      height: 1.05,
      spacing: -1,
      color: p.ink,
    );
    return Semantics(
      container: true,
      label: '$label, $number',
      excludeSemantics: foot == null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: lit
                ? _Lit(number: number, style: style)
                : Text(number, maxLines: 1, style: style),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w500,
              height: 1.25,
              color: p.inkMuted,
            ),
          ),
          if (foot != null) ...[const SizedBox(height: 4), foot!],
        ],
      ),
    );
  }
}

/// The streak's number, lit: the flame and the number in the streak's
/// orange — a shade deeper on paper, where the orange itself is too pale to
/// read at this size — and on the night paper a soft glow of it, as an
/// ember gives off. One colour and one mark at the board's own size:
/// nothing bounces, nothing burns.
class _Lit extends StatelessWidget {
  const _Lit({required this.number, required this.style});

  final String number;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final bool dark = context.p.isDark;
    final Color fire = dark
        ? kStreakOrange
        : Color.lerp(kStreakOrange, const Color(0xFF000000), 0.12)!;
    final List<Shadow> warmth = [
      if (dark)
        Shadow(color: kStreakOrange.withValues(alpha: 0.42), blurRadius: 18),
    ];
    return Row(
      key: const ValueKey('profile-streak-lit'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // On the digits' middle rather than the line's, which sits higher
        // for the room an accent over a capital would take.
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(
            Icons.local_fire_department_rounded,
            key: const ValueKey('profile-streak-flame'),
            size: 26,
            color: fire,
            shadows: warmth,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          number,
          maxLines: 1,
          style: style.copyWith(color: fire, shadows: warmth),
        ),
      ],
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────

/// A number set large, with a note on its baseline beside it — or under it,
/// where the two do not fit on one line: a narrow phone, a long language, a
/// larger text size. Never cut, and never wrapped through the middle.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.number,
    required this.colour,
    required this.note,
    this.numberKey,
  });

  final String number;
  final Color colour;
  final Widget note;
  final Key? numberKey;

  /// The least room the note is given beside the number before it goes
  /// under it instead.
  static const double _noteRoom = 92;
  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppText.display(
      size: 64,
      weight: FontWeight.w600,
      height: 1.05,
      spacing: -2.4,
      color: colour,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final TextPainter big = TextPainter(
          text: TextSpan(text: number, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final double wide = big.width;
        big.dispose();
        if (wide + _gap + _noteRoom <= box.maxWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(number, key: numberKey, maxLines: 1, style: style),
              const SizedBox(width: _gap),
              Flexible(child: note),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(number, key: numberKey, maxLines: 1, style: style),
            ),
            const SizedBox(height: 2),
            note,
          ],
        );
      },
    );
  }
}

/// The way into Your journey, under the score it holds the rest of: what is
/// in it, said as the reader's own scores. On the free plan it carries the
/// Astute+ mark, so the plans it opens are no surprise — but no lock: the
/// score above it is the reader's, whole, and the row is more of it.
class _JourneyRow extends StatelessWidget {
  const _JourneyRow({required this.app, this.boxed = false});

  final AppState app;

  /// A panel of its own, rather than a row between two hairlines.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final bool locked = !app.isPlus;
    final Widget row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l.yourJourney,
                      style: AppText.body(
                        size: 15.5,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (locked) ...[
                    const SizedBox(width: 8),
                    const _PlusTag(key: ValueKey('profile-journey-plus')),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                l.profileJourneyScores,
                style: AppText.body(size: 13, height: 1.3, color: p.inkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.chevron_right_rounded, size: 22, color: p.inkFaint),
      ],
    );
    return Semantics(
      button: true,
      label: [
        l.yourJourney,
        l.profileJourneyScores,
        if (locked) l.plusName,
      ].join('. '),
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('profile-journey'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openJourney(context, app),
        child: Container(
          padding: boxed
              ? const EdgeInsets.fromLTRB(16, 14, 12, 14)
              : const EdgeInsets.symmetric(vertical: 13),
          decoration: boxed
              ? BoxDecoration(
                  color: p.surfaceRaised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.line),
                )
              : BoxDecoration(
                  border: Border(
                    top: BorderSide(color: p.line),
                    bottom: BorderSide(color: p.line),
                  ),
                ),
          child: row,
        ),
      ),
    );
  }
}

/// The plan's name, small, in the colour the app marks Astute+ with.
class _PlusTag extends StatelessWidget {
  const _PlusTag({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: p.link.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.plusName,
        style: AppText.label(
          size: 9.5,
          weight: FontWeight.w700,
          spacing: 0.6,
          color: p.link,
        ),
      ),
    );
  }
}

/// Whatever goes to Today: tapped, it says where it is on the screen, so
/// Today can open out of it.
class _TodayTap extends StatelessWidget {
  const _TodayTap({
    required this.app,
    required this.child,
    required this.radius,
    this.onToday,
  });

  final AppState app;
  final Widget child;

  /// Its corners, which Today's opening starts from.
  final double radius;
  final ValueChanged<Rect?>? onToday;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final int read = _readToday(app);
    return Semantics(
      button: true,
      label: [
        l.profileTodayFive,
        if (app.todaysDeck.isNotEmpty)
          read >= kPillsPerDay
              ? l.exploreDayDone
              : l.profileTodayOf(read, kPillsPerDay),
      ].join(', '),
      hint: l.exploreDayOpen,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('profile-today'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          final RenderObject? box = context.findRenderObject();
          onToday?.call(
            box is RenderBox && box.hasSize
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          );
        },
        child: child,
      ),
    );
  }
}

/// Today's five at the head of what goes to them, and where the day is:
/// how many read of five, how many to read before any, and once all five
/// are read nothing more about it. The tile is the way back to them, its
/// chevron says so; a "See again" beside it said it twice (the owner,
/// November 2026). With [bars], the five as five short bars before it.
class _TodayHead extends StatelessWidget {
  const _TodayHead({required this.app, this.bars = false});

  final AppState app;
  final bool bars;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final l = context.l10n;
    final int read = _readToday(app);
    final bool dealt = app.todaysDeck.isNotEmpty;
    final bool done = read >= kPillsPerDay;
    final TextStyle side = AppText.body(
      size: 13.5,
      weight: FontWeight.w600,
      color: p.inkMuted,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            l.profileTodayFive,
            style: AppText.body(
              size: 15.5,
              weight: FontWeight.w600,
              height: 1.2,
              color: p.ink,
            ),
          ),
        ),
        if (bars && dealt) ...[
          const SizedBox(width: 10),
          _Five(read: read),
          const SizedBox(width: 12),
        ] else
          const SizedBox(width: 10),
        if (dealt && !done)
          Text(
            read == 0
                ? l.profileTodayToRead(kPillsPerDay)
                : l.profileTodayOf(read, kPillsPerDay),
            key: const ValueKey('profile-today-count'),
            style: side,
          ),
        Icon(Icons.chevron_right_rounded, size: 22, color: p.inkFaint),
      ],
    );
  }
}

/// The five as five short bars, the read ones lit, as Today's own head
/// draws them.
class _Five extends StatelessWidget {
  const _Five({required this.read});

  final int read;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < kPillsPerDay; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 11,
            height: 4,
            decoration: BoxDecoration(
              color: i < read ? ink : ink.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}

/// Monday to Sunday, a dot a day, as Explore's panel draws them: lit orange
/// once finished; today, until it is, a ring of five that fills as the
/// cards are read; the days to come faint.
class _Week extends StatelessWidget {
  const _Week({required this.app, required this.read});

  final AppState app;
  final int read;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat letter = DateFormat('EEEEE', locale);
    final DateTime today = app.today;
    final String todayKey = dateKey(today);
    final Color ink = p.ink;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (:day, :done) in weekOf(app, today))
            Expanded(
              child: Builder(
                builder: (context) {
                  final bool isToday = dateKey(day) == todayKey;
                  final bool ahead = !isToday && day.isAfter(today);
                  final bool lit = done || (isToday && read >= kPillsPerDay);
                  return Column(
                    key: ValueKey(
                      'profile-day-${day.weekday}-${lit ? 'done' : 'open'}'
                      '${isToday ? '-today' : ''}',
                    ),
                    children: [
                      SizedBox.square(
                        dimension: 24,
                        child: lit
                            ? Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kStreakOrange,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF1A0B00),
                                ),
                              )
                            : isToday
                            ? CustomPaint(
                                painter: _TodayRing(
                                  read: read,
                                  lit: ink,
                                  unlit: ink.withValues(alpha: 0.16),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ink.withValues(
                                    alpha: ahead ? 0.04 : 0.08,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        letter.format(day),
                        maxLines: 1,
                        style: AppText.label(
                          size: 10,
                          spacing: 0.4,
                          color: isToday
                              ? ink
                              : ink.withValues(alpha: ahead ? 0.3 : 0.5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Today's dot while the day is under way: a ring of five arcs, one a card,
/// the read ones lit.
class _TodayRing extends CustomPainter {
  _TodayRing({required this.read, required this.lit, required this.unlit});

  final int read;
  final Color lit;
  final Color unlit;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 2.6;
    final Rect ring = (Offset.zero & size).deflate(stroke / 2);
    const double gap = 0.32;
    const double each = 2 * math.pi / kPillsPerDay;
    for (int i = 0; i < kPillsPerDay; i++) {
      canvas.drawArc(
        ring,
        -math.pi / 2 + i * each + gap / 2,
        each - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = i < read ? lit : unlit,
      );
    }
  }

  @override
  bool shouldRepaint(_TodayRing old) =>
      old.read != read || old.lit != lit || old.unlit != unlit;
}
