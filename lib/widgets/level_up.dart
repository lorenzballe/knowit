/// A level of the Astute score reached (lib/data/levels.dart), told once, on
/// a screen of its own, black, whatever the app's theme: the level's name in
/// the app's display face, the score counting up to where it now stands, and
/// one line on what got the reader there. A light comes up behind the name
/// and passes once across it, and the phone gives one firm tap as it lands.
/// Nothing else moves; for a reader who asked for less motion, nothing moves
/// at all. No confetti, no badge: the name is the award.
///
/// It rises only at a calm moment, never in the middle of a card
/// ([showLevelUpIfDue]): once the day's cards are done and what they trained
/// has been put away (TodayScreen), and as Your journey opens
/// (JourneyScreen), each time over a screen at rest, and only while that
/// screen is the one in front.
///
/// Small, in Your journey, [LevelLine] says the level reached and how far the
/// next one is. The level goes out as a picture the way the day does
/// (lib/widgets/share_day.dart): [LevelPicture], from a sheet with the same
/// two ways out.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../data/levels.dart';
import '../data/skills.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import '../utils/share_image.dart';
import '../utils/share_link.dart';
import '../utils/share_origin.dart';
import 'fit_text.dart';
import 'glass_round.dart';
import 'skill_score.dart' show scoreBookOf, scoreNumber, scoreUp, signedNumber;
import 'training.dart' show pickedSkills;
import 'ui.dart' show PrimaryButton;

/// Where [app]'s reader stands on the levels, with [told] the highest level
/// kept as told.
LevelStanding levelStandingOf(AppState app, int? told) => LevelStanding.of(
  scoreBookOf(app),
  told: told,
  newReader: isNewReader(app.judgements, app.today),
);

/// True while a level's moment is being worked out: one at a time.
bool _looking = false;

/// Tells the level the reader's score has reached since one was last told,
/// if it has: the screen rises over [context]'s route once that route has
/// come to rest, and only while it is the one in front. True when it rose.
///
/// For the calm moments only: the end of the day, once what the day trained
/// has been put away, and Your journey as it opens. A level the score
/// crosses in the middle of a card waits for the next of them. The level is
/// kept as told as it rises, so it never rises twice.
Future<bool> showLevelUpIfDue(BuildContext context, AppState app) async {
  await _atRest(context);
  if (!context.mounted || _looking) return false;
  _looking = true;
  try {
    final int? told = await LevelMemory.read();
    if (!context.mounted) return false;
    final LevelStanding standing = levelStandingOf(app, told);
    final int? due = standing.due;
    if (due == null || !(ModalRoute.of(context)?.isCurrent ?? true)) {
      // The first look starts the memory, with what counts as told.
      if (told == null) await LevelMemory.keep(standing.told);
      return false;
    }
    await LevelMemory.keep(due);
    if (!context.mounted) return false;
    final LevelMoment found = LevelMoment.of(
      scoreBookOf(app),
      due,
      picked: pickedSkills(app),
    );
    // In the looks of What to learn with no skills to show (A and B,
    // lib/widgets/learn_looks.dart), the level says the answers behind it,
    // not a skill the reader never sees.
    final LevelMoment moment = switch (DebugLooks.learnPicked) {
      LearnLook.score || LearnLook.aim => LevelMoment(
        level: found.level,
        score: found.score,
        from: found.from,
        answers: found.answers,
      ),
      LearnLook.today || LearnLook.profile => found,
    };
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).push(LevelUpScreen.route(moment)),
    );
    return true;
  } finally {
    _looking = false;
  }
}

/// Waits for the route [context] is in to finish coming in: the level rises
/// over a screen at rest, never over one still sliding in.
Future<void> _atRest(BuildContext context) {
  final Animation<double>? coming = ModalRoute.of(context)?.animation;
  if (coming == null || coming.isCompleted) return Future<void>.value();
  final Completer<void> done = Completer<void>();
  void heard(AnimationStatus status) {
    if (status.isAnimating) return;
    coming.removeStatusListener(heard);
    if (!done.isCompleted) done.complete();
  }

  coming.addStatusListener(heard);
  return done.future;
}

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// The theme the screen is drawn in, whatever the app's: it is always night.
final ThemeData _night = buildAstutoTheme(Brightness.dark);

/// The screen.
class LevelUpScreen extends StatefulWidget {
  const LevelUpScreen({super.key, required this.moment});

  final LevelMoment moment;

  /// How long the take lasts, from the light coming up to the last line.
  static const Duration take = Duration(milliseconds: 3200);

  /// The screen as it rises: a fade from what was in front, after a beat for
  /// whatever was put away (the day's sheet) to go.
  static Route<void> route(LevelMoment moment) => PageRouteBuilder<void>(
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => LevelUpScreen(moment: moment),
    transitionsBuilder: (context, animation, _, child) =>
        MediaQuery.disableAnimationsOf(context)
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1, curve: Curves.easeOut),
              reverseCurve: Curves.easeIn,
            ),
            child: child,
          ),
  );

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

/// When each part of the take happens, as parts of [LevelUpScreen.take].
abstract final class _Beat {
  /// The light behind the name coming up.
  static const Interval light = Interval(0, 0.62, curve: Curves.easeInOut);

  /// "New level", over where the name will be.
  static const Interval eyebrow = Interval(0.10, 0.24, curve: Curves.easeOut);

  /// The score: in, then counting up to where it stands.
  static const Interval scoreIn = Interval(0.12, 0.22, curve: Curves.easeOut);
  static const Interval count = Interval(
    0.14,
    0.58,
    curve: Curves.easeOutCubic,
  );

  /// The name: in, unlit, then lit by the light passing across it; the tap
  /// as the light reaches its middle.
  static const Interval nameIn = Interval(0.34, 0.46, curve: Curves.easeOut);
  static const Interval sweep = Interval(0.38, 0.76, curve: Curves.easeInOut);
  static const double land = 0.56;

  /// The ladder's new step filling.
  static const Interval step = Interval(0.52, 0.74, curve: Curves.easeOutCubic);

  /// What got the reader there, then the way to send it.
  static const Interval line = Interval(0.66, 0.84, curve: Curves.easeOut);
  static const Interval foot = Interval(0.78, 0.96, curve: Curves.easeOut);
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _take = AnimationController(
    vsync: this,
    duration: LevelUpScreen.take,
  );
  bool _started = false;
  bool _landed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Everything where it ends; the tap all the same.
      _take.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _land());
    } else {
      _take.addListener(_watch);
      _take.forward();
    }
  }

  void _watch() {
    if (_take.value >= _Beat.land) _land();
  }

  void _land() {
    if (_landed || !mounted) return;
    _landed = true;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _take.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  Future<void> _share() {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: (_) => LevelShareSheet(moment: widget.moment),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: _night,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Builder(builder: _page),
    ),
  );

  Widget _page(BuildContext context) {
    final Palette p = context.p;
    return Scaffold(
      key: const ValueKey('level-up'),
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _take,
        builder: (context, _) {
          final double t = _take.value;
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _Light(_Beat.light.transform(t), p.ink),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
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
                        builder: (context, box) => Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: box.maxWidth - 48,
                              child: _middle(context, t),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
                      child: Column(
                        children: [
                          Opacity(
                            opacity: _Beat.line.transform(t),
                            child: _GainLine(moment: widget.moment),
                          ),
                          const SizedBox(height: 26),
                          Opacity(
                            opacity: _Beat.foot.transform(t),
                            child: IgnorePointer(
                              ignoring: t < _Beat.foot.begin,
                              child: _SharePill(onTap: _share),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The eyebrow, the name, the ladder and the score, one above the other.
  Widget _middle(BuildContext context, double t) {
    final Palette p = context.p;
    final l = context.l10n;
    final LevelMoment m = widget.moment;
    final String name = l.scoreLevel(kScoreLevels[m.level].id);
    final double nameIn = _Beat.nameIn.transform(t);
    final int counted = (m.from + (m.score - m.from) * _Beat.count.transform(t))
        .round();
    return Semantics(
      container: true,
      label: [
        l.levelUpTitle,
        name,
        '${l.scoreTitle}: ${scoreNumber(context, m.score)}',
      ].join('. '),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: _Beat.eyebrow.transform(t),
            child: Text(
              _caps(context, l.levelUpTitle),
              textAlign: TextAlign.center,
              style: AppText.label(
                size: 11.5,
                weight: FontWeight.w700,
                spacing: 2.6,
                color: p.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Opacity(
            opacity: nameIn,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - nameIn)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect r) =>
                      _lit(r, _Beat.sweep.transform(t), p.ink),
                  child: Text(
                    name,
                    key: const ValueKey('level-up-name'),
                    maxLines: 1,
                    softWrap: false,
                    style: AppText.display(
                      size: 58,
                      weight: FontWeight.w500,
                      height: 1.08,
                      spacing: -1.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Opacity(
            opacity: _Beat.eyebrow.transform(t),
            child: LevelSteps(
              reached: m.level,
              newest: _Beat.step.transform(t),
              ink: p.ink,
              step: 24,
              gap: 7,
            ),
          ),
          const SizedBox(height: 54),
          Opacity(
            opacity: _Beat.scoreIn.transform(t),
            child: Column(
              children: [
                Text(
                  scoreNumber(context, counted),
                  key: const ValueKey('level-up-score'),
                  style:
                      AppText.display(
                        size: 42,
                        weight: FontWeight.w500,
                        height: 1,
                        spacing: -0.8,
                        color: p.ink,
                      ).copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  _caps(context, l.scoreTitle),
                  style: AppText.label(
                    size: 10.5,
                    weight: FontWeight.w700,
                    spacing: 1.8,
                    color: p.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The name as the light has reached it, [s] of the way across: lit behind
/// the light, brightest under it, unlit ahead of it. Lit all through once it
/// has passed.
Shader _lit(Rect rect, double s, Color ink) {
  const double half = 0.22;
  final double at = -half + (1 + 2 * half) * s;
  double c(double v) => v.clamp(0.0, 1.0);
  final Color unlit = ink.withValues(alpha: 0.16);
  return LinearGradient(
    colors: [ink, ink, Colors.white, unlit, unlit],
    stops: [0, c(at - half), c(at), c(at + half), 1],
  ).createShader(rect);
}

/// The light behind the name: a pool of the page's own ink, very faint,
/// widening as it comes up.
class _Light extends CustomPainter {
  _Light(this.t, this.ink);

  final double t;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final Offset centre = Offset(size.width / 2, size.height * 0.4);
    final double radius = size.width * (0.62 + 0.42 * t);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          radius,
          [
            ink.withValues(alpha: 0.12 * t),
            ink.withValues(alpha: 0.045 * t),
            ink.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_Light old) => old.t != t || old.ink != ink;
}

/// The ladder past its first step, one short bar a level: lit up to the
/// level [reached], the newest lit [newest] of the way, and the one after it
/// [toward] of the way. Bars of [step] wide, or sharing the width there is.
class LevelSteps extends StatelessWidget {
  const LevelSteps({
    super.key,
    required this.reached,
    required this.ink,
    this.newest = 1,
    this.toward = 0,
    this.step,
    this.gap = 5,
    this.height = 3,
  });

  final int reached;
  final Color ink;
  final double newest;
  final double toward;
  final double? step;
  final double gap;
  final double height;

  double _lit(int level) {
    if (level < reached) return 1;
    if (level == reached) return newest;
    if (level == reached + 1) return toward;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    Widget bar(int level) => SizedBox(
      width: step,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(height),
        ),
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: _lit(level).clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
    return Row(
      mainAxisSize: step == null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var level = 1; level < kScoreLevels.length; level++) ...[
          if (level > 1) SizedBox(width: gap),
          step == null ? Expanded(child: bar(level)) : bar(level),
        ],
      ],
    );
  }
}

/// What got the reader there: the skill that rose most this week and by
/// how much, its name in the page's ink and the points in the green of a
/// rise; or, with none risen, how many answers the score stands on.
class _GainLine extends StatelessWidget {
  const _GainLine({required this.moment});

  final LevelMoment moment;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final TextStyle base = AppText.body(
      size: 15,
      height: 1.45,
      color: p.ink.withValues(alpha: 0.62),
    );
    final Skill? skill = moment.skill;
    if (skill == null) {
      return Text(
        l.levelUpAnswers(moment.answers),
        key: const ValueKey('level-up-line'),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    // The sentence as the language words it, the two values marked, so each
    // can take its own weight wherever the language puts it.
    const String skillMark = '\u0001', pointsMark = '\u0002';
    final String marked = l.levelUpGain(skillMark, pointsMark);
    final List<InlineSpan> spans = [];
    var rest = marked;
    while (rest.isNotEmpty) {
      final int a = rest.indexOf(skillMark), b = rest.indexOf(pointsMark);
      final int next = a < 0 ? b : (b < 0 ? a : (a < b ? a : b));
      if (next < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (next > 0) spans.add(TextSpan(text: rest.substring(0, next)));
      spans.add(
        rest[next] == skillMark
            ? TextSpan(
                // Kept on one line: "Numbers and / statistics" read as two.
                text: l.skillName(skill.name).replaceAll(' ', ' '),
                style: TextStyle(color: p.ink, fontWeight: FontWeight.w600),
              )
            : TextSpan(
                text: signedNumber(context, moment.gain),
                style: TextStyle(
                  color: scoreUp(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
      );
      rest = rest.substring(next + 1);
    }
    return Text.rich(
      TextSpan(children: spans),
      key: const ValueKey('level-up-line'),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: base,
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
          key: const ValueKey('level-up-close'),
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

/// The way to send the level, small and last: the day's own button
/// (ShareDay), its mark and the word.
class _SharePill extends StatelessWidget {
  const _SharePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String label = context.l10n.share;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('level-up-share'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ios_share_rounded, size: 16, color: p.ink),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Your journey's word on the levels, small: the level reached, how far the
/// next one is, and the ladder, the way to the next filling. In a faint
/// panel of its own, as the journey's are, unless [framed] is false, for a
/// place inside one.
class LevelLine extends StatefulWidget {
  const LevelLine({super.key, required this.app, this.framed = true});

  final AppState app;
  final bool framed;

  @override
  State<LevelLine> createState() => _LevelLineState();
}

/// Whether [text], set in [style], keeps to [lines] lines in [width].
bool _fitsIn(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
  int lines,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    maxLines: lines,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: width);
  final bool fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits;
}

class _LevelLineState extends State<LevelLine> {
  /// The highest level told, once read: until then, the score's own.
  int? _told;

  @override
  void initState() {
    super.initState();
    LevelMemory.read().then((int? told) {
      if (mounted && told != _told) setState(() => _told = told);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final LevelStanding s = levelStandingOf(widget.app, _told);
    final String name = l.scoreLevel(s.level.id);
    final ScoreLevel? next = s.next;
    final String toGo = next == null
        ? l.levelTop
        : s.answersShort > 0
        ? l.levelAnswersTo(s.answersShort, l.scoreLevel(next.id))
        : l.levelPointsTo(s.pointsShort!, l.scoreLevel(next.id));
    final TextStyle nameStyle = AppText.display(
      size: 20,
      weight: FontWeight.w600,
      height: 1.1,
      spacing: -0.3,
      color: p.ink,
    );
    final TextStyle toGoStyle = AppText.body(
      size: 12.5,
      weight: FontWeight.w600,
      height: 1.3,
      color: p.ink.withValues(alpha: 0.55),
    );
    final Widget label = Text(
      _caps(context, l.levelLabel),
      style: AppText.body(
        size: 9.5,
        weight: FontWeight.w700,
        spacing: 1.3,
        color: p.ink.withValues(alpha: 0.45),
      ),
    );
    final Widget steps = LevelSteps(
      reached: s.reached,
      toward: s.toNext,
      ink: p.ink,
      gap: 4,
      height: 4,
    );
    final Widget inside = LayoutBuilder(
      builder: (context, box) {
        // Side by side where the name keeps to one line in its half and the
        // way to the next level to two in the other; one over the other,
        // each the whole width, where they do not: a long name
        // ("Nieuwsgierigheid", "Любознательность") or a long way to say it
        // ("25 punktów do poziomu Spostrzegawczość") is not cut to fit half
        // a small phone.
        final double half = (box.maxWidth - 12) / 2;
        final bool side =
            _fitsIn(context, name, nameStyle, half, 1) &&
            _fitsIn(context, toGo, toGoStyle, half, 2);
        if (side) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        label,
                        const SizedBox(height: 5),
                        Text(name, maxLines: 1, style: nameStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        toGo,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        style: toGoStyle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              steps,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label,
            const SizedBox(height: 5),
            FitText(name, maxLines: 1, minSize: 15, style: nameStyle),
            const SizedBox(height: 4),
            Text(toGo, style: toGoStyle),
            const SizedBox(height: 12),
            steps,
          ],
        );
      },
    );
    return Semantics(
      container: true,
      label: '${l.levelLabel}: $name. $toGo',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('level-line'),
        padding: widget.framed
            ? const EdgeInsets.fromLTRB(16, 14, 16, 16)
            : EdgeInsets.zero,
        decoration: widget.framed
            ? BoxDecoration(
                color: p.ink.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
              )
            : null,
        child: inside,
      ),
    );
  }
}

/// The sheet that sends a level: the picture, and the two ways out the
/// day's sheet has — the system's sheet with the picture, and the words
/// copied.
class LevelShareSheet extends StatefulWidget {
  const LevelShareSheet({super.key, required this.moment, this.day});

  final LevelMoment moment;

  /// The day it is dated, today when not given.
  final DateTime? day;

  /// How the picture is handed over: the platform's sheet. Under a test,
  /// which has no sheet, whatever the test puts here.
  @visibleForTesting
  static Future<bool> Function(
    Uint8List bytes,
    String name,
    String text, {
    Rect? origin,
  })
  shareImage = shareCardImage;

  /// The words that go with the picture, and alone where it cannot go.
  static String text(BuildContext context, LevelMoment moment) {
    final l = context.l10n;
    return [
      'Astute · ${l.levelUpTitle}: '
          '${l.scoreLevel(kScoreLevels[moment.level].id)}',
      '${l.scoreTitle} ${scoreNumber(context, moment.score)}',
      ShareRef.level.link,
    ].join('\n');
  }

  @override
  State<LevelShareSheet> createState() => _LevelShareSheetState();
}

class _LevelShareSheetState extends State<LevelShareSheet> {
  final GlobalKey _picture = GlobalKey();
  bool _busy = false;

  void _toast(ScaffoldMessengerState messenger, String message) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<Uint8List?> _capture() async {
    final RenderRepaintBoundary? boundary =
        _picture.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return data?.buffer.asUint8List();
  }

  Future<void> _send() async {
    final l = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String words = LevelShareSheet.text(context, widget.moment);
    final Rect origin = shareOrigin(context);
    setState(() => _busy = true);
    try {
      final Uint8List? bytes = await _capture();
      final bool shared =
          bytes != null &&
          await LevelShareSheet.shareImage(
            bytes,
            'astute-${kScoreLevels[widget.moment.level].id}.png',
            words,
            origin: origin,
          );
      if (!shared) {
        // No sheet to take the picture: the words go on the clipboard.
        await Clipboard.setData(ClipboardData(text: words));
        _toast(messenger, l.textCopiedInstead);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: LevelShareSheet.text(context, widget.moment)),
    );
    _toast(messenger, l.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double most = MediaQuery.sizeOf(context).height - safe.top - 24;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: most),
      child: Container(
        key: const ValueKey('level-share'),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.fromLTRB(22, 14, 22, safe.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.levelShareTitle,
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w600,
                      spacing: -0.6,
                      color: p.ink,
                    ),
                  ),
                ),
                _Close(onTap: () => Navigator.of(context).maybePop()),
              ],
            ),
            const SizedBox(height: 14),
            // Laid out at one size on every phone, so it is the same picture
            // wherever it is made, and shown shrunk to the room there is.
            Flexible(
              child: LayoutBuilder(
                builder: (context, box) {
                  const double w = LevelPicture.width;
                  const double h = w * 5 / 4;
                  final double fit = [
                    box.maxWidth / w,
                    box.maxHeight / h,
                  ].reduce((a, b) => a < b ? a : b);
                  return Center(
                    heightFactor: 1,
                    // A hairline round the picture, outside it: its black
                    // would otherwise melt into the sheet's.
                    child: Container(
                      width: w * fit,
                      height: h * fit,
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26 * fit),
                        border: Border.all(color: p.lineStrong),
                      ),
                      child: FittedBox(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: RepaintBoundary(
                            key: _picture,
                            // A picture, not a screen: one size whatever the
                            // reader's text size.
                            child: MediaQuery(
                              data: MediaQuery.of(context)
                                  .copyWith(textScaler: TextScaler.noScaling),
                              child: LevelPicture(
                                moment: widget.moment,
                                day: widget.day ?? DateTime.now(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    key: const ValueKey('level-share-send'),
                    label: _busy ? l.rendering : l.share,
                    height: 52,
                    onPressed: _busy ? null : _send,
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: l.shareCopyLink,
                  child: GestureDetector(
                    key: const ValueKey('level-share-copy'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _copy,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.lineStrong),
                      ),
                      child: Icon(Icons.copy_rounded, size: 20, color: p.ink),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The picture of a level reached, four by five as the day's: the name, the
/// ladder with it lit, the score, the day, and where to get the app. Fixed
/// colours, the screen's own black: it leaves the app as an image, and
/// should not arrive in someone's chat wearing that reader's theme.
class LevelPicture extends StatelessWidget {
  const LevelPicture({super.key, required this.moment, required this.day});

  final LevelMoment moment;
  final DateTime day;

  /// The width it is laid out at on every phone; it is made at three times
  /// this, 1080 across.
  static const double width = 360;

  static const Color _ground = Color(0xFF0A0A0C);
  static const Color _ink = Color(0xFFF2F1EC);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String date = DateFormat(
      'd MMMM y',
      Localizations.localeOf(context).toString(),
    ).format(day);
    final TextStyle faint = AppText.label(
      size: 11,
      weight: FontWeight.w700,
      spacing: 1.6,
      color: _ink.withValues(alpha: 0.55),
    );
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _ground,
            gradient: RadialGradient(
              center: const Alignment(0, -0.25),
              radius: 0.95,
              colors: [_ink.withValues(alpha: 0.11), _ground.withAlpha(0)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Astute',
                      style: AppText.display(
                        size: 19,
                        weight: FontWeight.w700,
                        spacing: -0.5,
                        color: _ink,
                      ),
                    ),
                    const Spacer(),
                    Text(_caps(context, date), style: faint),
                  ],
                ),
                const Spacer(flex: 3),
                Text(_caps(context, l.levelUpTitle), style: faint),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l.scoreLevel(kScoreLevels[moment.level].id),
                    maxLines: 1,
                    style: AppText.display(
                      size: 54,
                      weight: FontWeight.w500,
                      height: 1.05,
                      spacing: -1.6,
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LevelSteps(
                    reached: moment.level,
                    ink: _ink,
                    step: 22,
                    gap: 6,
                  ),
                ),
                const Spacer(flex: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      scoreNumber(context, moment.score),
                      style: AppText.display(
                        size: 34,
                        weight: FontWeight.w500,
                        spacing: -0.6,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _caps(context, l.scoreTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: faint,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Container(height: 1, color: _ink.withValues(alpha: 0.14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.shareDayTurn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 11.5,
                          weight: FontWeight.w600,
                          color: _ink.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kSiteHost,
                      style: AppText.label(
                        size: 10.5,
                        weight: FontWeight.w700,
                        spacing: 0.3,
                        color: _ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
