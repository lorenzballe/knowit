/// The end of a reader's first day, celebrated: a screen of its own that
/// rises right after the fifth card is thrown, the first time a day is
/// finished by a reader with no day finished before it (TodayScreen). The
/// day comes first and the sale after it: on the free plan the card after
/// the fifth waits on the table under this screen, and is there when it
/// goes.
///
/// Black at night and paper by day, as the app is, and as the first week's
/// page is, which this is the first of. The day's date over the headline,
/// "Your first day is done", in the display face; under it, between
/// hairlines, the streak — its flame and its one, the screen's one colour,
/// in the streak's own orange — and what the day's answers added to the
/// Astute score; then one plain line, how sure the reader said they were
/// against how many they got right. At the foot "Remind me tomorrow", which
/// raises the reminder sheet down the shell's own road (main.dart), so it
/// is asked once and counted once, and Today's challenge, the five
/// questions everyone gets that day, at the top of Explore: the part of
/// the app most worth sending to a friend, which the day's end used never
/// to lead to. The way out quietly in the corner, as on a level reached
/// (lib/widgets/level_up.dart).
///
/// Nothing bounces and nothing falls from the sky: the lines rise into
/// place one after another and the points count up from nothing; for a
/// reader who asked for less motion everything is where it ends.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../analytics.dart';
import '../books/book_player_view.dart' show bookPlayerRoom;
import '../data/pills_repository.dart' show dateKey;
import '../explore/blocks/core/your_day_block.dart' show kStreakOrange;
import '../l10n/dates.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import 'chunky.dart';
import 'fit_text.dart';
import 'glass_round.dart';
import 'motion.dart';
import 'reminder_ask.dart' show showReminderAsk;
import 'skill_score.dart' show scoreBookOf, scoreNumber, signedNumber;
import 'ui.dart' show ScreenView, clockTime;

/// What the shell lends the celebration: whether the reminder may be asked
/// from it, the way to ask it — the shell's own, so that it is asked once,
/// counted once, and never asked again by the shell that evening — and the
/// way to Today's challenge.
class FirstDayHost {
  const FirstDayHost({
    required this.mayRemind,
    required this.remind,
    required this.challenge,
  });

  /// Whether "Remind me tomorrow" is there, asked once as the screen rises:
  /// never when the reminder was already asked or notifications are
  /// already on, and only where the shell would ask it this evening.
  final bool Function() mayRemind;

  /// Raises the reminder sheet as the shell does at the end of a first day,
  /// and the system's prompt behind it: the time the reminder will come at,
  /// once one was chosen and the phone allowed it; null otherwise.
  final Future<String?> Function() remind;

  /// Goes to Today's challenge: the Explore tab, put back the way it opens,
  /// the challenge at its top.
  final VoidCallback challenge;

  /// A host that offers no reminder and goes nowhere: a screen opened
  /// outside the tabs.
  static const FirstDayHost none = FirstDayHost(
    mayRemind: _never,
    remind: _nothing,
    challenge: _nowhere,
  );

  static bool _never() => false;
  static Future<String?> _nothing() async => null;
  static void _nowhere() {}
}

/// Whether the day just finished is to be celebrated: the reader's first,
/// with no day finished before today, never celebrated before on this
/// phone — and as it ships, unless the developer tools put the first day's
/// end back as it was (DebugLooks.firstDayEnd). Asked by Today the moment
/// the day is finished in this sitting; opening the app onto a finished day
/// is no moment to celebrate it.
bool firstDayDue(AppState app) {
  if (DebugLooks.firstDayEndPicked != FirstDayEndLook.celebration) {
    return false;
  }
  if (app.firstDayCelebratedOn != null || !app.todayCompleted) return false;
  final String today = dateKey(app.today);
  return app.completedDates.every((d) => d == today);
}

/// What the celebration says, read off the reader's own record.
class FirstDayNumbers {
  const FirstDayNumbers({
    required this.streak,
    required this.points,
    required this.cards,
    required this.answered,
    required this.right,
    this.sure,
  });

  /// The reader's, as they stand now. The day's answers are every graded
  /// answer given today — the five's, and any card answered before them,
  /// which the score counts too — so the points and the answers are said
  /// of the same day.
  factory FirstDayNumbers.of(AppState app) {
    final String day = dateKey(app.today);
    final List<Judgement> todays = [
      for (final Judgement j in app.judgements)
        if (j.on == day) j,
    ];
    final List<int> said = [
      for (final Judgement j in todays) ?j.confidence,
    ];
    return FirstDayNumbers(
      // A first day finished is a streak of one, by what a streak is: said
      // as one even in the frame before the day's close is written down.
      streak: math.max(1, app.liveStreak),
      points: math.max(0, scoreBookOf(app).overall.today),
      cards: app.todaysDeck.length,
      answered: todays.length,
      right: todays.where((j) => j.correct).length,
      sure: said.isEmpty
          ? null
          : (said.reduce((a, b) => a + b) / said.length).round(),
    );
  }

  /// A first day as the developer tools' preview shows it.
  static const FirstDayNumbers sample = FirstDayNumbers(
    streak: 1,
    points: 38,
    cards: 5,
    answered: 5,
    right: 4,
    sure: 70,
  );

  /// The days in a row: one, on a first day.
  final int streak;

  /// What today's answers added to the Astute score (lib/data/
  /// skill_scores.dart) as the reader sees it, from where it stood at the
  /// end of yesterday; never under nothing.
  final int points;

  /// The day's cards.
  final int cards;

  /// Today's graded answers, and how many of them were right.
  final int answered;
  final int right;

  /// How sure the reader said they were, on average over today's answers
  /// that asked them, in percent; null when no card asked that day.
  final int? sure;

  /// The one plain line, how sure against how right: with the average
  /// certainty where the reader said how sure they were, right of total
  /// alone where they never were asked; null with no answer to speak of.
  String? line(AppLocalizations l) {
    if (answered == 0) return null;
    final int? said = sure;
    return l.elided(
      said == null
          ? l.firstDayRight(right, answered)
          : l.firstDaySureRight(said, right, answered),
    );
  }
}

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// [day] as the phone's language writes a date with its weekday.
String _dateline(BuildContext context, DateTime day) {
  final String locale = Localizations.localeOf(context).toString();
  try {
    return formatDay(DateFormat.MMMMEEEEd(locale), day);
  } catch (_) {
    return DateFormat.MMMMEEEEd('en').format(day);
  }
}

/// The screen.
class FirstDayScreen extends StatefulWidget {
  const FirstDayScreen({
    super.key,
    required this.app,
    this.host = FirstDayHost.none,
    this.numbers,
    this.preview = false,
  });

  final AppState app;
  final FirstDayHost host;

  /// What it says: the reader's own numbers when null, a preview's sample
  /// otherwise.
  final FirstDayNumbers? numbers;

  /// Opened from the developer tools only to be looked at: it counts
  /// nothing, and the reminder sheet it raises keeps nothing.
  final bool preview;

  /// The screen as it rises: a fade over the card the fifth left on the
  /// table, a beat after the throw; for a reader who asked for less motion,
  /// there at once.
  static Route<void> route(
    AppState app, {
    FirstDayHost host = FirstDayHost.none,
    FirstDayNumbers? numbers,
    bool preview = false,
  }) => PageRouteBuilder<void>(
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 700),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => FirstDayScreen(
      app: app,
      host: host,
      numbers: numbers,
      preview: preview,
    ),
    transitionsBuilder: (context, animation, _, child) =>
        MediaQuery.disableAnimationsOf(context)
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 1, curve: Curves.easeOut),
              reverseCurve: Curves.easeIn,
            ),
            child: child,
          ),
  );

  @override
  State<FirstDayScreen> createState() => _FirstDayScreenState();
}

class _FirstDayScreenState extends State<FirstDayScreen> {
  /// How long the screen was up.
  final Stopwatch _open = Stopwatch()..start();

  /// Whether "Remind me tomorrow" is offered, decided as the screen rises
  /// and kept: a button does not come and go under the reader's eyes.
  late final bool _offersReminder =
      widget.preview || widget.host.mayRemind();

  /// True while the reminder sheet, and the system's prompt behind it, are
  /// up; and once the reminder was asked from here, whatever the answer.
  bool _asking = false;
  bool _asked = false;

  /// When the first reminder comes, once one will.
  String? _remindAt;

  /// How the screen went: the corner, the challenge, or the way back.
  String _leftBy = 'back';
  bool _leaving = false;

  FirstDayNumbers get _numbers =>
      widget.numbers ?? FirstDayNumbers.of(widget.app);

  @override
  void initState() {
    super.initState();
    if (widget.preview) return;
    final FirstDayNumbers n = _numbers;
    // What the screen said, as counts: never a card or an answer.
    Analytics.capture('first day shown', {
      'streak_days': n.streak,
      'points': n.points,
      'answered': n.answered,
      'right': n.right,
      'sure': n.sure,
      'remind': _offersReminder,
      'is_plus': widget.app.isPlus,
    });
  }

  @override
  void dispose() {
    if (!widget.preview) {
      Analytics.capture('first day closed', {
        'left_by': _leftBy,
        'ms_open': _open.elapsedMilliseconds,
        'reminder': !_asked
            ? null
            : _remindAt == null
            ? 'not set'
            : 'set',
      });
    }
    super.dispose();
  }

  void _leave(String how) {
    if (_leaving || !mounted) return;
    _leaving = true;
    _leftBy = how;
    Navigator.of(context).maybePop();
  }

  void _close() {
    HapticFeedback.selectionClick();
    _leave('close');
  }

  /// The reminder sheet, through the shell; in a preview the sheet alone,
  /// which keeps nothing and asks the system nothing.
  Future<void> _remind() async {
    if (_asking || _asked || _leaving) return;
    setState(() => _asking = true);
    String? at;
    if (widget.preview) {
      at = await showReminderAsk(context, widget.app);
    } else {
      Analytics.capture('first day reminder tapped', {
        'ms_open': _open.elapsedMilliseconds,
      });
      at = await widget.host.remind();
    }
    if (!mounted) return;
    setState(() {
      _asking = false;
      _asked = true;
      _remindAt = at;
    });
  }

  /// Today's challenge: the screen goes, and the tabs go to Explore under
  /// it, the challenge at its top. The card after the fifth stays on
  /// Today's table, where it comes next.
  void _challenge() {
    if (_leaving || _asking) return;
    if (!widget.preview) {
      Analytics.capture('first day challenge tapped', {
        'ms_open': _open.elapsedMilliseconds,
      });
    }
    _leave('challenge');
    if (!widget.preview) widget.host.challenge();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    // The day's close can be written down a frame after the screen rises:
    // the numbers follow it.
    final Widget page = AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ListenableBuilder(
        listenable: widget.app,
        builder: (context, _) => _page(context),
      ),
    );
    return widget.preview ? page : ScreenView(name: 'first day', child: page);
  }

  Widget _page(BuildContext context) {
    final Palette p = context.p;
    final FirstDayNumbers n = _numbers;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final bool short = MediaQuery.sizeOf(context).height - safe.vertical < 640;
    return Scaffold(
      key: const ValueKey('first-day'),
      backgroundColor: p.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _Close(onTap: _close),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, room) => _FadeFoot(
                  child: SingleChildScrollView(
                    key: const ValueKey('first-day-scroll'),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: room.maxHeight),
                      // In the middle of the room there is, and from the
                      // top where the words need more of it than there is.
                      child: Center(child: _body(context, n, short)),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              // Clear of the small player of a book read aloud, where one
              // plays (lib/books/book_player_view.dart).
              padding: EdgeInsets.fromLTRB(
                24,
                short ? 8 : 12,
                24,
                (safe.bottom > 0 ? 6 : 16) + bookPlayerRoom(context),
              ),
              child: RiseIn(
                delay: const Duration(milliseconds: 560),
                child: _foot(context, short),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The date, the headline, the streak and the points, and the line.
  Widget _body(BuildContext context, FirstDayNumbers n, bool short) {
    final Palette p = context.p;
    final l = context.l10n;
    final String? line = n.line(l);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: short ? 8 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiseIn(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _caps(context, _dateline(context, widget.app.today)),
                key: const ValueKey('first-day-date'),
                maxLines: 1,
                style: AppText.label(
                  size: 11,
                  weight: FontWeight.w700,
                  spacing: 2.4,
                  color: p.inkMuted,
                ),
              ),
            ),
          ),
          SizedBox(height: short ? 8 : 12),
          RiseIn(
            delay: const Duration(milliseconds: 90),
            child: Semantics(
              header: true,
              child: FitText(
                l.firstDayTitle,
                key: const ValueKey('first-day-title'),
                maxLines: 3,
                minSize: 26,
                wholeWords: true,
                style: AppText.display(
                  size: short ? 36 : 44,
                  weight: FontWeight.w500,
                  height: 1.04,
                  spacing: short ? -1 : -1.3,
                  color: p.ink,
                ),
              ),
            ),
          ),
          SizedBox(height: short ? 22 : 36),
          RiseIn(
            delay: const Duration(milliseconds: 260),
            child: _Figures(numbers: n, short: short),
          ),
          if (line != null) ...[
            SizedBox(height: short ? 14 : 20),
            RiseIn(
              delay: const Duration(milliseconds: 420),
              child: Text(
                line,
                key: const ValueKey('first-day-line'),
                style: AppText.body(
                  size: short ? 15 : 16.5,
                  height: 1.42,
                  color: p.ink.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "Remind me tomorrow", or when it will come once it is set; then
  /// Today's challenge, which takes the first button's colour when it
  /// stands alone.
  Widget _foot(BuildContext context, bool short) {
    final Palette p = context.p;
    final l = context.l10n;
    final bool dark = p.isDark;
    final double height = short ? 52 : 58;
    final bool remind = _offersReminder && !_asked;
    final String? at = _remindAt;
    final bool lone = !remind;
    ChunkyButton button({
      required Key key,
      required String label,
      required bool first,
      required VoidCallback onPressed,
    }) => ChunkyButton(
      key: key,
      label: label,
      height: height,
      depth: 5,
      radius: 22,
      labelSize: 16.5,
      labelSpacing: 0.3,
      fill: first ? p.inverse : p.surfaceRaised,
      ink: first ? p.onInverse : p.ink,
      edge: first ? (dark ? const Color(0xFFA8A59D) : null) : p.lineStrong,
      shadow: first
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.45 : 0.15),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ]
          : null,
      onPressed: onPressed,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (remind)
          button(
            key: const ValueKey('first-day-remind'),
            label: l.firstDayRemind,
            first: true,
            onPressed: _remind,
          )
        else if (at != null)
          SizedBox(
            height: height,
            child: _Reminded(text: l.firstDayReminded(clockTime(context, at))),
          ),
        if (remind || at != null) SizedBox(height: short ? 8 : 10),
        button(
          key: const ValueKey('first-day-challenge'),
          label: l.fiveTitle,
          first: lone,
          onPressed: _challenge,
        ),
      ],
    );
  }
}

/// The foot of the words fades into the buttons where they scroll, so what
/// goes on under them is seen to go on rather than to stop at a line.
class _FadeFoot extends StatelessWidget {
  const _FadeFoot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (r) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Colors.white, Colors.white, Colors.transparent],
      stops: [0, 1 - (18 / r.height).clamp(0.0, 1.0), 1],
    ).createShader(r),
    child: child,
  );
}

/// The streak and the points, side by side between two hairlines: each a
/// figure in the display face over what it is, in small capitals. The
/// streak's flame and number are lit in its orange, the one colour on the
/// screen; the points count up from nothing. With nothing added to the
/// score — no answer that counted — the day's cards stand in their place.
class _Figures extends StatelessWidget {
  const _Figures({required this.numbers, required this.short});

  final FirstDayNumbers numbers;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final FirstDayNumbers n = numbers;
    final BorderSide rule = BorderSide(color: p.line);
    final double size = short ? 34 : 40;
    final TextStyle figure = AppText.display(
      size: size,
      weight: FontWeight.w500,
      height: 1.05,
      spacing: -1,
      color: p.ink,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Container(
      key: const ValueKey('first-day-figures'),
      padding: EdgeInsets.symmetric(vertical: short ? 14 : 18),
      decoration: BoxDecoration(border: Border(top: rule, bottom: rule)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Figure(
              key: const ValueKey('first-day-streak'),
              label: l.profileInARowLabel(n.streak),
              semantics: '${scoreNumber(context, n.streak)} '
                  '${l.profileInARowLabel(n.streak)}',
              // The flame grows with the reader's text size, as the
              // number beside it does.
              child: _Lit(
                number: scoreNumber(context, n.streak),
                style: figure,
                flame: MediaQuery.textScalerOf(context).scale(size * 0.74),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: n.points > 0
                ? _Figure(
                    key: const ValueKey('first-day-points'),
                    label: l.scoreTitle,
                    semantics:
                        '${l.scoreTitle}: ${signedNumber(context, n.points)}',
                    child: _Count(value: n.points, style: figure),
                  )
                : _Figure(
                    key: const ValueKey('first-day-cards'),
                    label: l.pillReadWord(n.cards),
                    semantics:
                        '${scoreNumber(context, n.cards)} '
                        '${l.pillReadWord(n.cards)}',
                    child: Text(
                      scoreNumber(context, n.cards),
                      maxLines: 1,
                      style: figure,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A figure and what it is.
class _Figure extends StatelessWidget {
  const _Figure({
    super.key,
    required this.child,
    required this.label,
    required this.semantics,
  });

  final Widget child;
  final String label;
  final String semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semantics,
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: child,
        ),
        const SizedBox(height: 8),
        Text(
          _caps(context, label),
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w700,
            spacing: 1.6,
            height: 1.25,
            color: context.p.inkMuted,
          ),
        ),
      ],
    ),
  );
}

/// The streak's number, lit: the flame and the number in the streak's
/// orange, as the profile lights them — a shade deeper on paper, where the
/// orange itself is too pale to read at this size, and at night a soft glow
/// of it, as an ember gives off.
class _Lit extends StatelessWidget {
  const _Lit({required this.number, required this.style, required this.flame});

  final String number;
  final TextStyle style;
  final double flame;

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
      mainAxisSize: MainAxisSize.min,
      children: [
        // On the digits' middle rather than the line's.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.local_fire_department_rounded,
            key: const ValueKey('first-day-flame'),
            size: flame,
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

/// The points with their sign, counted up from nothing as the figures rise;
/// at once for a reader who asked for less motion.
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? value.toDouble() : 0, end: value.toDouble()),
      duration: Duration(milliseconds: still ? 0 : 1300),
      curve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      builder: (context, v, _) => Text(
        signedNumber(context, v.round()),
        key: const ValueKey('first-day-points-figure'),
        maxLines: 1,
        style: style,
      ),
    );
  }
}

/// When the first reminder comes, in place of the button that asked for
/// it: a tick and the words, quiet.
class _Reminded extends StatelessWidget {
  const _Reminded({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Center(
      key: const ValueKey('first-day-reminded'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 18, color: p.ink),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 14.5,
                weight: FontWeight.w600,
                height: 1.3,
                color: p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The way out, in the corner where a screen like this keeps it: Apple's
/// glass on iOS 26, the app's own round button elsewhere.
class _Close extends StatelessWidget {
  const _Close({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String label = MaterialLocalizations.of(context).closeButtonLabel;
    return GlassRound(
      symbol: GlassRound.close,
      label: label,
      onPressed: onTap,
      size: 44,
      iconSize: 15,
      fallback: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          key: const ValueKey('first-day-close'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.line),
                ),
                child: Icon(Icons.close_rounded, size: 18, color: p.inkMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
