/// The day, closed and sent: two of the four ways drawn for the owner of
/// where sharing the day lives once the five are read, tried on a phone from
/// the developer tools (DebugLooks.shareDay; A and B are the row over the
/// shelf, lib/screens/today_done_view.dart).
///
/// [DayMoment] is C: a screen of its own, black whatever the app's theme,
/// that rises right after the five (TodayScreen) with the day's picture as
/// it will be sent, "Share your day", and "Later". The pattern a word game
/// made its name with: the day goes out at the moment it is finished, when
/// there is something to say. It never nags. Once a day at most; only on
/// the evening the day is finished on this phone, in this sitting, never on
/// opening the app onto a finished day; never over another screen; never on
/// an evening something else is asked at the finished day — a level
/// reached, which has its own way to send, the reminder, the store's rating
/// sheet; and no more once "Later" has been said three times running. The
/// sheets that come at the finished day wait for it to close, as they wait
/// for anything over the tabs. The shelf under it keeps the share's mark
/// alone. For a reader who asked for less motion, nothing moves.
///
/// [DayCard] is D: the same picture and the way to send it as a card of its
/// own after the five on the shelf, where the shelf lands the evening the
/// day is finished.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pills_repository.dart' show dateKey;
import '../l10n/l10n.dart';
import '../measure/screens.dart' show ScreenPresence;
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import 'card_edge.dart' show cardLift;
import 'fit_text.dart';
import 'motion.dart';
import 'share_day.dart';
import 'ui.dart';

/// What the phone keeps of the moment: the day it last rose, and how many
/// times running it was passed with "Later" rather than sent.
abstract final class DayMomentMemory {
  static const String _kRose = 'knowit.dayMomentOn';
  static const String _kLaters = 'knowit.dayMomentLaters';

  /// "Later" this many times running, and the moment rises no more.
  static const int restsAfter = 3;

  /// Whether the moment may rise on [today]: not yet that day, and not
  /// resting.
  static Future<bool> due(DateTime today) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRose) != dateKey(today) &&
        (prefs.getInt(_kLaters) ?? 0) < restsAfter;
  }

  /// Kept as risen on [today], as it rises: never twice in a day.
  static Future<void> rose(DateTime today) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRose, dateKey(today));
  }

  /// Passed once more, with "Later" or the way back.
  static Future<void> later() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLaters, (prefs.getInt(_kLaters) ?? 0) + 1);
  }

  /// The day sent from it: the count of "Later" starts again.
  static Future<void> sent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLaters);
  }

  /// As new, for the developer tools, as the moment is picked again: the
  /// owner trying it is not a reader who said "Later" three times.
  static Future<void> forget() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRose);
    await prefs.remove(_kLaters);
  }
}

/// Raises the day's moment over Today if it is due: where the developer
/// tools try it (C), on a finished day, once that day, and only while Today
/// is at rest and in front. True when it rose.
Future<bool> showDayMomentIfDue(BuildContext context, AppState app) async {
  if (DebugLooks.shareDayPicked != ShareDayPick.c) return false;
  if (!app.dayClosed || app.todaysDeck.isEmpty) return false;
  // One thing an evening: not on the evening the app asks the reader for
  // the reminder, nor on the one the store's rating sheet is put, which is
  // the phone's own and would come up over it.
  if (app.shouldAskForPush || app.shouldAskForReview) return false;
  if (app.reviewAskedOn == dateKey(app.today)) return false;
  if (!await DayMomentMemory.due(app.today)) return false;
  if (!context.mounted) return false;
  // Never over another screen, nor from a tab the reader has left.
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
  if (!(ScreenPresence.maybeOf(context)?.showing ?? true)) return false;
  await DayMomentMemory.rose(app.today);
  if (!context.mounted) return false;
  unawaited(
    Navigator.of(context, rootNavigator: true).push(DayMoment.route(app)),
  );
  return true;
}

/// The theme the moment is drawn in, whatever the app's: night, as the
/// picture is.
final ThemeData _night = buildAstutoTheme(Brightness.dark);

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// C: the day closed on a screen of its own. See the library's own words.
class DayMoment extends StatefulWidget {
  const DayMoment({super.key, required this.app, this.preview = false});

  final AppState app;

  /// Opened from the developer tools only to be looked at: nothing done on
  /// it is kept.
  final bool preview;

  /// The moment as it rises: a fade from the shelf; for a reader who asked
  /// for less motion, there at once.
  static Route<void> route(AppState app, {bool preview = false}) =>
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => DayMoment(app: app, preview: preview),
        transitionsBuilder: (context, animation, _, child) =>
            MediaQuery.disableAnimationsOf(context)
            ? child
            : FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.15, 1, curve: Curves.easeOut),
                  reverseCurve: Curves.easeIn,
                ),
                child: child,
              ),
      );

  @override
  State<DayMoment> createState() => _DayMomentState();
}

class _DayMomentState extends State<DayMoment> {
  final GlobalKey _picture = GlobalKey();
  bool _busy = false;

  /// Whether the day went out from here.
  bool _sent = false;

  @override
  void dispose() {
    // Passed rather than sent: "Later", or the way back.
    if (!_sent && !widget.preview) unawaited(DayMomentMemory.later());
    super.dispose();
  }

  Future<void> _send() async {
    final String copied = context.l10n.textCopiedInstead;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    setState(() => _busy = true);
    final String as = await ShareDay.sendPicture(
      context,
      widget.app,
      picture: _picture,
      layout: DayPicture.recommended,
      from: 'day moment',
    );
    _sent = true;
    unawaited(DayMomentMemory.sent());
    if (!mounted) return;
    // Sent, the moment has nothing left to do, and closes onto the shelf;
    // where no sheet took the picture, the words went, and the shelf says
    // so.
    await Navigator.of(context).maybePop();
    if (as == 'text') messenger?.showSnackBar(SnackBar(content: Text(copied)));
  }

  void _later() {
    HapticFeedback.selectionClick();
    Navigator.of(context).maybePop();
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
    final l = context.l10n;
    final AppState app = widget.app;
    return Scaffold(
      key: const ValueKey('day-moment'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The day and the picture together, in the middle of what the
              // buttons leave: on a tall phone the air falls above and
              // below them both, rather than between the line and the
              // picture it is about.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Which day, and that it is done: the name the shelf
                    // heads itself with, over a line in the display face.
                    RiseIn(
                      distance: 8,
                      child: Column(
                        children: [
                          Text(
                            _caps(context, l.dayTitle(app.dayNumber)),
                            key: const ValueKey('day-moment-day'),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: AppText.label(
                              size: 11.5,
                              weight: FontWeight.w700,
                              spacing: 2.6,
                              color: p.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Semantics(
                            header: true,
                            child: FitText(
                              l.dayMomentTitle,
                              key: const ValueKey('day-moment-title'),
                              maxLines: 2,
                              minSize: 22,
                              wholeWords: true,
                              textAlign: TextAlign.center,
                              style: AppText.display(
                                size: 34,
                                weight: FontWeight.w500,
                                height: 1.1,
                                spacing: -0.8,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // The picture as it will be sent, as large as the room
                    // allows: what a friend gets, before anything is sent.
                    Flexible(
                      child: RiseIn(
                        delay: const Duration(milliseconds: 120),
                        distance: 16,
                        child: DayPicturePreview(
                          key: const ValueKey('day-moment-picture'),
                          app: app,
                          picture: _picture,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                key: const ValueKey('day-moment-send'),
                label: _busy ? l.rendering : l.shareDayTitle,
                onPressed: _busy ? null : _send,
              ),
              const SizedBox(height: 4),
              QuietButton(
                key: const ValueKey('day-moment-later'),
                label: l.dayMomentLater,
                onPressed: _later,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// D: the day as a card on the shelf, after the five: its name, its picture
/// as it will be sent, and the way to send it, at the shelf's size and
/// scale, as the cards beside it are.
class DayCard extends StatefulWidget {
  const DayCard({
    super.key,
    required this.app,
    required this.width,
    required this.height,
  });

  final AppState app;
  final double width;
  final double height;

  /// The shelf's card on its artboard, which its measures scale from.
  static const double artWidth = 324;

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> {
  final GlobalKey _picture = GlobalKey();
  bool _busy = false;

  Future<void> _send() async {
    final String copied = context.l10n.textCopiedInstead;
    setState(() => _busy = true);
    try {
      final String as = await ShareDay.sendPicture(
        context,
        widget.app,
        picture: _picture,
        layout: DayPicture.recommended,
        from: 'day card',
      );
      if (as == 'text' && mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(copied)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final double s = widget.width / DayCard.artWidth;
    return Container(
      key: const ValueKey('shelf-day-card'),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        // The deck's corner at the shelf's scale, and a hairline: a card of
        // the page's own near-black would otherwise have no edge at night.
        borderRadius: BorderRadius.circular(34 * s),
        border: Border.all(color: p.line),
        boxShadow: cardLift(p),
      ),
      padding: EdgeInsets.fromLTRB(22 * s, 22 * s, 22 * s, 18 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Its name, where a card's subject stands; smaller where the
          // language or the reader's text size make it longer, never cut.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              _caps(context, l.yourDayCard),
              key: const ValueKey('shelf-day-card-name'),
              maxLines: 1,
              style: AppText.label(
                size: 10 * s,
                weight: FontWeight.w700,
                spacing: 1.4,
                color: p.ink.withValues(alpha: 0.6),
              ),
            ),
          ),
          SizedBox(height: 14 * s),
          Expanded(
            child: DayPicturePreview(
              app: widget.app,
              picture: _picture,
              radius: 16 * s,
            ),
          ),
          SizedBox(height: 16 * s),
          PrimaryButton(
            key: const ValueKey('shelf-day-send'),
            label: _busy ? l.rendering : l.share,
            height: math.max(46, 50 * s),
            onPressed: _busy ? null : _send,
          ),
        ],
      ),
    );
  }
}
