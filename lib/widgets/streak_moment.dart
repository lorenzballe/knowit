/// The streak reaching two days in a row, three, or seven, told once, small,
/// as a level is (lib/widgets/level_up.dart): a screen of its own, black
/// whatever the app's theme, "In a row" over the number in the app's
/// display face, the day before's number giving way to today's, and one
/// line: that a missed day is covered and how many freezes the reader
/// holds, or, at seven on the free plan, the one more card of their own
/// the week has earned for tomorrow. One firm tap as the number lands.
/// Nothing else moves, and for a reader who asked for less motion nothing
/// moves at all. A tap anywhere closes it.
///
/// It rises only at the calm moment after the five (TodayScreen), and only
/// when the day was finished there: never on the evening a level rose or
/// the first week's page did, one full-screen moment an evening; once for
/// each of those streaks on the phone (`streak.told`). The first day's own
/// moment is the end of the first five.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Raises the streak's moment over [context]'s route if it is due
/// ([AppState.streakMomentDue]) and that route is in front. True when it
/// rose.
Future<bool> showStreakMomentIfDue(BuildContext context, AppState app) async {
  if (!app.streakMomentDue || app.firstOfferRoseToday) return false;
  // The shell's own asks at the finished day (the reminder, the place, the
  // rating, the widget, the account) have the evening first: the week is
  // said on the shelf all the same, and the moment never takes their place.
  if (app.shouldAskForPush ||
      app.shouldAskForPlace ||
      app.shouldAskForReview ||
      app.shouldAskForWidget ||
      app.shouldOfferAccount) {
    return false;
  }
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
  final int days = app.liveStreak;
  final int freezes = app.freezes;
  final bool plus = app.isPlus;
  await app.noteStreakTold();
  if (!context.mounted) return false;
  unawaited(
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(StreakMomentScreen.route(days: days, freezes: freezes, plus: plus)),
  );
  return true;
}

/// The theme the screen is drawn in, whatever the app's: it is always night.
final ThemeData _night = buildAstutoTheme(Brightness.dark);

/// The screen.
class StreakMomentScreen extends StatefulWidget {
  const StreakMomentScreen({
    super.key,
    required this.days,
    required this.freezes,
    required this.plus,
  });

  /// The streak reached: two, three or seven.
  final int days;

  /// The freezes the reader holds, as the moment rises.
  final int freezes;

  /// Whether the reader is on Astute+, whose five are all their own already.
  final bool plus;

  /// How long the take lasts, from the eyebrow to the line.
  static const Duration take = Duration(milliseconds: 1700);

  /// The screen as it rises: a fade from the finished day.
  static Route<void> route({
    required int days,
    required int freezes,
    required bool plus,
  }) => PageRouteBuilder<void>(
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) =>
        StreakMomentScreen(days: days, freezes: freezes, plus: plus),
    transitionsBuilder: (context, animation, _, child) =>
        MediaQuery.disableAnimationsOf(context)
        ? child
        : FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
            child: child,
          ),
  );

  /// The one line under the number.
  static String lineOf(
    BuildContext context, {
    required int days,
    required int freezes,
    required bool plus,
  }) {
    final l = context.l10n;
    if (days == 7 && !plus) return l.streakMomentWeek;
    if (freezes > 0) return l.freezeCoversLine(freezes);
    return l.streakMomentNext(days + 1);
  }

  @override
  State<StreakMomentScreen> createState() => _StreakMomentScreenState();
}

/// When each part of the take happens, as parts of [StreakMomentScreen.take].
abstract final class _Beat {
  static const Interval eyebrow = Interval(0, 0.22, curve: Curves.easeOut);

  /// The day before's number, there from the start, then giving way.
  static const Interval out = Interval(0.28, 0.5, curve: Curves.easeIn);

  /// Today's number rising into its place, and the tap as it lands.
  static const Interval inn = Interval(0.36, 0.62, curve: Curves.easeOutCubic);
  static const double land = 0.6;
  static const Interval unit = Interval(0.5, 0.72, curve: Curves.easeOut);
  static const Interval line = Interval(0.7, 0.96, curve: Curves.easeOut);
}

class _StreakMomentScreenState extends State<StreakMomentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _take = AnimationController(
    vsync: this,
    duration: StreakMomentScreen.take,
  );
  bool _started = false;
  bool _landed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
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
    final l = context.l10n;
    final String line = StreakMomentScreen.lineOf(
      context,
      days: widget.days,
      freezes: widget.freezes,
      plus: widget.plus,
    );
    return Scaffold(
      key: const ValueKey('streak-moment'),
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _take,
            builder: (context, _) {
              final double t = _take.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        tooltip: l.closeLabel,
                        onPressed: _close,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: p.inkMuted,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      container: true,
                      label: [
                        l.streakMomentEyebrow,
                        '${widget.days} ${l.streakMomentUnit(widget.days)}',
                        line,
                      ].join('. '),
                      excludeSemantics: true,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: _Beat.eyebrow.transform(t),
                                child: Text(
                                  _caps(context, l.streakMomentEyebrow),
                                  textAlign: TextAlign.center,
                                  style: AppText.label(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    spacing: 2.6,
                                    color: p.inkMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _Number(
                                from: widget.days - 1,
                                to: widget.days,
                                out: _Beat.out.transform(t),
                                inn: _Beat.inn.transform(t),
                              ),
                              Opacity(
                                opacity: _Beat.unit.transform(t),
                                child: Text(
                                  l.streakMomentUnit(widget.days),
                                  textAlign: TextAlign.center,
                                  style: AppText.display(
                                    size: 30,
                                    weight: FontWeight.w400,
                                    height: 1.1,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 34),
                              Opacity(
                                opacity: _Beat.line.transform(t),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  child: Text(
                                    line,
                                    key: const ValueKey('streak-moment-line'),
                                    textAlign: TextAlign.center,
                                    style: AppText.body(
                                      size: 15.5,
                                      height: 1.45,
                                      color: p.inkMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 72),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// The streak's number: the day before's giving way upwards as today's
/// rises into its place, in one box the size of the larger.
class _Number extends StatelessWidget {
  const _Number({
    required this.from,
    required this.to,
    required this.out,
    required this.inn,
  });

  final int from;
  final int to;

  /// How far the day before's number has gone, 0 to 1.
  final double out;

  /// How far today's has come, 0 to 1.
  final double inn;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppText.display(
      size: 132,
      weight: FontWeight.w500,
      height: 1,
      spacing: -4,
      color: Colors.white,
    );
    return ClipRect(
      child: SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (out < 1)
              Opacity(
                opacity: (1 - out) * 0.5,
                child: Transform.translate(
                  offset: Offset(0, -40 * out),
                  child: Text('$from', style: style),
                ),
              ),
            Opacity(
              opacity: inn,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - inn)),
                child: Text(
                  '$to',
                  key: const ValueKey('streak-moment-number'),
                  style: style,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
