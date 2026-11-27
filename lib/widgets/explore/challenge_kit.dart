/// The parts every challenge's screen is drawn with, on the app's own page.
///
/// One rule for colour, the app's own: a card of a round is its subject's
/// card, as it is everywhere else in the app — the subject's colour and
/// ink, and at its head the subject's mark and name, as on a card of the
/// day ([SubjectCard]). Everything else is the page's: the controls the
/// app's own raised and inverse pills, the figures in its ink, and a
/// verdict told in its calm green or its alert, with a mark and a word.
/// The challenge's own colour stays on its tile among Explore's
/// challenges, and nowhere on its screen.
///
/// One kit, so the twelve screens are one family: whatever the challenge,
/// Begin is the same button, a right answer the same green, a card the
/// same card.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart' show Pill, kConfidenceLevels;
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../card_edge.dart' show cardFace, cardHairline;
import '../glass_round.dart';
import '../scaled_text.dart';
import '../subject_icon.dart' show CardMark, SubjectIcon;
import 'challenge_marks.dart';
import 'challenges.dart';
import 'game_feel.dart';
import 'parts.dart' show upper;
import '../../l10n/dates.dart';

/// A challenge's screen, opened over Explore out of its tile: the page
/// grows out of the tile's panel. With motion reduced it is there at once.
Route<void> challengeRoute(Widget screen, {bool calm = false}) =>
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: calm
          ? Duration.zero
          : const Duration(milliseconds: 320),
      reverseTransitionDuration: calm
          ? Duration.zero
          : const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => screen,
    );

/// Where things stand on a challenge's screen: under the status bar, the
/// head the close shares with the running head, and above the home bar.
@immutable
class ChallengeRoom {
  const ChallengeRoom(this.size, this.safe);

  final Size size;
  final EdgeInsets safe;

  /// The top of the head, under the status bar.
  double get top => safe.top + 6;

  /// The bottom of the head.
  double get head => top + 52;

  /// The room kept under the last thing on the screen.
  double get foot => math.max(safe.bottom, 16.0) + 12;
}

/// Says [message] to a screen reader, where the platform has one to tell.
void announceGame(BuildContext context, String message) {
  if (!MediaQuery.supportsAnnounceOf(context)) return;
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

/// Today, as a score sent on says it: "24 Nov".
String gameDate(BuildContext context) {
  final String locale = Localizations.localeOf(context).toString();
  try {
    return formatDay(DateFormat.MMMd(locale), DateTime.now());
  } catch (_) {
    return DateFormat.MMMd('en').format(DateTime.now());
  }
}

/// [part] of [whole] as a percentage, as the reader's language writes one:
/// "75%", "75 %", "%75".
String gamePercent(BuildContext context, int part, int whole) {
  final double share = whole <= 0 ? 0 : part / whole;
  final String locale = Localizations.localeOf(context).toString();
  try {
    return NumberFormat.percentPattern(locale).format(share);
  } catch (_) {
    return NumberFormat.percentPattern('en').format(share);
  }
}

/// A round read against chance: above what guessing alone averages —
/// [chance] right of [of] — level with it, or below it.
String challengeChance(
  AppLocalizations l, {
  required int right,
  required int chance,
  required int of,
}) => right > chance
    ? l.challengeAboveChance(chance, of)
    : right == chance
    ? l.challengeAtChance(chance, of)
    : l.challengeBelowChance(chance, of);

/// A round as squares, one a card: 🟩 right, 🟥 wrong, ⬜ not answered.
String gameSquares(Iterable<bool?> marks) => [
  for (final bool? m in marks)
    switch (m) {
      true => '🟩',
      false => '🟥',
      null => '⬜',
    },
].join();

/// Sends [text] on, or copies it where nothing can send it, and notes it as
/// [event] with [facts] and how it went.
Future<void> shareGame(
  BuildContext context, {
  required String text,
  required String event,
  Map<String, Object> facts = const {},
}) async {
  final l = context.l10n;
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String copied = l.copiedToClipboard;
  final bool shared = await sendText(text);
  Analytics.capture(event, {...facts, 'as': shared ? 'link' : 'copied'});
  if (!shared) {
    await Clipboard.setData(ClipboardData(text: text));
    messenger?.showSnackBar(
      SnackBar(content: Text(copied), duration: const Duration(seconds: 2)),
    );
  }
}

// ── The cards ───────────────────────────────────────────────────────────

/// A card of a round, as the app's cards are wherever they turn up: the
/// face its subject's colour, lifted and cut from the page as a card of
/// the day is ([cardFace]); its subject's mark and name at its head
/// ([SubjectHead]), with [trailing] at the head's end; under the head,
/// [child], in the card's ink.
///
/// [small] for the cards a screen shows several of at once. [picked] rings
/// it in the page's ink: the one chosen. [quiet] draws it back a little,
/// for a card the round has done with.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.pill,
    this.child,
    this.trailing,
    this.small = false,
    this.picked = false,
    this.quiet = false,
  });

  final Pill pill;

  /// What the card says, under its head. None: a card of the deck still to
  /// come, its face alone.
  final Widget? child;
  final Widget? trailing;
  final bool small;
  final bool picked;
  final bool quiet;

  /// The corners of a card the screen's, and of one of several.
  static const double radius = 28;
  static const double smallRadius = 22;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final double r = small ? smallRadius : radius;
    final Widget? words = child;
    Widget card = Container(
      decoration: cardFace(context, pill.color, radius: r, lift: 1),
      padding: words == null
          ? EdgeInsets.zero
          : small
          ? const EdgeInsets.fromLTRB(16, 13, 16, 14)
          : const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: words == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubjectHead(pill: pill, trailing: trailing, small: small),
                SizedBox(height: small ? 8 : 14),
                Expanded(child: words),
              ],
            ),
    );
    if (quiet) card = Opacity(opacity: 0.62, child: card);
    final bool calm = MediaQuery.disableAnimationsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: card),
        // The ring of the one picked, round the card and clear of it, in the
        // page's ink: on any colour of the wheel, it reads.
        Positioned(
          left: -5,
          top: -5,
          right: -5,
          bottom: -5,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: picked ? 1 : 0,
              duration: calm
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r + 5),
                  border: Border.all(color: p.ink, width: 2.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A card's head, as a card of the day carries it: its subject's mark and
/// its name in small capitals, in the card's ink, and [trailing] at its
/// end — what the card turned out to be, its year, its place.
class SubjectHead extends StatelessWidget {
  const SubjectHead({
    super.key,
    required this.pill,
    this.trailing,
    this.small = false,
  });

  final Pill pill;
  final Widget? trailing;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final Widget? end = trailing;
    return Row(
      children: [
        CardMark(pill: pill, size: small ? 14 : 16, ink: pill.ink),
        SizedBox(width: small ? 7 : 8),
        Expanded(
          child: Text(
            upper(context, context.l10n.subjectOf(pill.topic)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.4),
            style: AppText.label(
              size: small ? 10 : 11,
              spacing: small ? 1.2 : 1.4,
              color: pill.ink.withValues(alpha: 0.72),
            ),
          ),
        ),
        if (end != null) ...[const SizedBox(width: 8), end],
      ],
    );
  }
}

/// A few words at a card's head, at its end, in small capitals of the
/// card's ink: "TRUE", "BIGGER", a year.
class SubjectTag extends StatelessWidget {
  const SubjectTag({super.key, required this.pill, required this.text});

  final Pill pill;
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    upper(context, text),
    maxLines: 1,
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
    style: AppText.label(
      size: 11,
      weight: FontWeight.w800,
      spacing: 1.2,
      color: pill.ink,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
  );
}

/// A card's words — a question, a claim, a moment — set as a card of the
/// day sets its question: in the app's serif, as large as the room takes,
/// up to a poster's line on a card that is the screen's ([max] unset),
/// so a short one fills its card rather than floating in a band of
/// colour.
class SubjectWords extends StatelessWidget {
  const SubjectWords({
    super.key,
    required this.text,
    required this.ink,
    this.min = 18,
    this.max,
    this.struck = false,
    this.alignment = const Alignment(-1, -0.3),
  });

  final String text;
  final Color ink;
  final double min;

  /// The largest it is set: by default, as a card of the day with its
  /// answers under it sets its question.
  final double? max;

  /// Struck through, once it is told to be false.
  final bool struck;
  final Alignment alignment;

  /// The largest a question is set on a card [width] wide: the app's own.
  static double maxFor(double width) => (width * 0.16).clamp(40.0, 56.0);

  static TextStyle style(double size, Color ink) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.14,
    spacing: -0.3 - size * 0.018,
    color: ink,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ScaledText(
      text: text,
      min: min,
      max: max ?? maxFor(box.maxWidth),
      alignment: alignment,
      styleFor: (size) {
        final TextStyle s = style(size, ink);
        return struck
            ? s.copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: ink,
                decorationThickness: 2,
              )
            : s;
      },
    ),
  );
}

/// A card once its round is told, as the back of a card of the day: the
/// question, smaller; under a hairline, what it came to; why, as much of
/// it as the card holds; and at its foot, where the card has one, what to
/// keep, in its box as the card's own back sets it.
class SubjectTold extends StatelessWidget {
  const SubjectTold({
    super.key,
    required this.pill,
    required this.question,
    required this.verdict,
    required this.why,
  });

  final Pill pill;
  final String question;
  final String verdict;
  final String why;

  /// [answer] without the word it opens on where that word only says again
  /// what the verdict says: "False. Nielsen's figures…" told as false.
  static String withoutVerdict(BuildContext context, String answer) {
    final l = context.l10n;
    final String text = answer.trim();
    for (final String word in {l.sayTrue, l.sayFalse, 'True', 'False'}) {
      final Match? m = RegExp(
        '^${RegExp.escape(word)}[.,:;!]\\s+',
        caseSensitive: false,
      ).firstMatch(text);
      if (m != null) {
        final String rest = text.substring(m.end);
        if (rest.isEmpty) return text;
        return rest[0].toUpperCase() + rest.substring(1);
      }
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final Color ink = pill.ink;
    final String keep = pill.barMove.trim();
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.4);
    final TextStyle asked = AppText.display(
      size: 18,
      weight: FontWeight.w600,
      height: 1.2,
      spacing: -0.3,
      color: ink.withValues(alpha: 0.74),
    );
    final TextStyle said = AppText.display(
      size: 23,
      weight: FontWeight.w700,
      height: 1.16,
      spacing: -0.4,
      color: ink,
    );
    final TextStyle kept = AppText.body(
      size: 15,
      weight: FontWeight.w600,
      height: 1.38,
      color: ink.withValues(alpha: 0.94),
    );
    final TextStyle keptLabel = AppText.label(
      size: 10.5,
      spacing: 1.2,
      color: ink.withValues(alpha: 0.6),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final TextDirection direction = Directionality.of(context);
        double tall(String text, TextStyle style, double width, [int? lines]) {
          final TextPainter painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
            maxLines: lines,
            ellipsis: lines == null ? null : '…',
          )..layout(maxWidth: width);
          final double h = painter.height;
          painter.dispose();
          return h;
        }

        // What to keep goes at the foot only where it leaves why three
        // lines at least: on a card short of room, why comes first.
        final double above =
            tall(question, asked, box.maxWidth, 4) +
            25 +
            tall(verdict, said, box.maxWidth) +
            10;
        final double keepBox = keep.isEmpty
            ? 0
            : 12 +
                  25 +
                  tall('A', keptLabel, 100) +
                  6 +
                  tall(keep, kept, box.maxWidth - 30, 4);
        final double whyLine = scaler.scale(14.5) * 1.42;
        final bool keeps =
            keep.isNotEmpty && box.maxHeight - above - keepBox >= whyLine * 3;
        // A card too short for even two lines of why under its question and
        // its verdict, on a small phone: all of it, scrolled, rather than
        // any of it cut.
        if (box.maxHeight - above < whyLine * 2) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textScaler: scaler,
                  style: asked,
                ),
                const SizedBox(height: 10),
                Container(height: 1, color: ink.withValues(alpha: 0.22)),
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(verdict, textScaler: scaler, style: said),
                ),
                const SizedBox(height: 8),
                Text(
                  why.trim(),
                  textScaler: scaler,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w500,
                    height: 1.42,
                    color: ink.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textScaler: scaler,
              style: asked,
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: ink.withValues(alpha: 0.22)),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(verdict, textScaler: scaler, style: said),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _WhyFit(
                text: why.trim(),
                styleFor: (size) => AppText.body(
                  size: size,
                  weight: FontWeight.w500,
                  height: 1.42,
                  color: ink.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (keeps) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
                decoration: BoxDecoration(
                  color: pill.wash,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.barMoveCaps,
                      textScaler: scaler,
                      style: keptLabel,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      keep,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textScaler: scaler,
                      style: kept,
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
}

/// Why, on a card told: as large as its room takes, between [least] and
/// [most]; where even the least is taller than the room — a long why on a
/// small phone, in a long language — at the least, as many lines as the
/// room holds and an ellipsis after them, rather than shrunk past reading
/// and cut at the card's foot. The whole why is a tap away, on the card
/// itself, from the report.
class _WhyFit extends StatelessWidget {
  const _WhyFit({required this.text, required this.styleFor});

  final String text;
  final TextStyle Function(double size) styleFor;

  static const double least = 13.5, most = 20;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final TextDirection direction = Directionality.of(context);
      final TextStyle inherited = DefaultTextStyle.of(context).style;
      TextPainter laid(double size) => TextPainter(
        text: TextSpan(text: text, style: inherited.merge(styleFor(size))),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: box.maxWidth);
      bool fits(double size) {
        final TextPainter t = laid(size);
        final bool ok = t.height <= box.maxHeight;
        t.dispose();
        return ok;
      }

      if (!box.hasBoundedHeight || fits(most)) {
        return Text(text, style: styleFor(most), textScaler: scaler);
      }
      if (fits(least)) {
        double lo = least, hi = most;
        while (hi - lo > 0.25) {
          final double mid = (lo + hi) / 2;
          if (fits(mid)) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return Text(text, style: styleFor(lo), textScaler: scaler);
      }
      final TextPainter t = laid(least);
      final double line = t.preferredLineHeight;
      t.dispose();
      final int lines = (box.maxHeight / line).floor();
      if (lines < 1) return const SizedBox.shrink();
      return Text(
        text,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
        textScaler: scaler,
        style: styleFor(least),
      );
    },
  );
}

// ── The page's own controls ─────────────────────────────────────────────

/// The way out, as the app's controls are drawn: Apple's own glass on iOS
/// 26 and later, and elsewhere a hairline circle round a cross.
class GameClose extends StatelessWidget {
  const GameClose({super.key, required this.id, required this.onTap});

  /// The game's keys' prefix: `sixty`, whose close is `sixty-close`.
  final String id;
  final VoidCallback onTap;

  /// The square it stands in, the same on every screen: its centre level
  /// with the middle of the head's line.
  static const double box = 48;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final Widget round = GlassRound(
      symbol: GlassRound.close,
      label: l.closeLabel,
      onPressed: onTap,
      fallback: Semantics(
        button: true,
        label: l.closeLabel,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          key: ValueKey('$id-close'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: box,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surfaceRaised,
                  border: p.isDark ? null : Border.all(color: p.line),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.close_rounded, size: 18, color: p.ink),
              ),
            ),
          ),
        ),
      ),
    );
    // Apple's glass is 44 across, the app's own target 48: either stands
    // in the same square, so the cross is in the same place on every
    // screen and every phone.
    return SizedBox.square(
      dimension: box,
      child: Center(child: round),
    );
  }
}

/// The page's plain face for a control: a shade off the night's black, or
/// white on the day's paper, with a hairline round it.
Color _plainFace(Palette p) =>
    p.isDark ? const Color(0xFF1A1A1E) : Colors.white;
Color _plainLine(Palette p) =>
    p.isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000);

/// One of the app's pill buttons: [primary], the inverse one — Begin, Next,
/// Bet, Lock in — or plain, the page's own with a hairline — an answer,
/// the score sent on. Under the finger it gives a little and dims, at
/// once, and the tap is felt ([GameFeel]); with no [onTap] it stands
/// faded: not yet.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.icon,
    this.height = 56,
    this.size = 15.5,
    this.semantics,
  });

  /// The way on: the inverse pill.
  factory GameButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    double height = 56,
    String? semantics,
  }) => GameButton(
    key: key,
    label: label,
    onTap: onTap,
    primary: true,
    height: height,
    semantics: semantics,
  );

  /// An answer, or a way aside: the page's own pill.
  factory GameButton.plain({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double height = 56,
    double size = 15.5,
    String? semantics,
  }) => GameButton(
    key: key,
    label: label,
    onTap: onTap,
    icon: icon,
    height: height,
    size: size,
    semantics: semantics,
  );

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  final double height;

  /// How large the label is set.
  final double size;

  /// What a screen reader says, when not the label.
  final String? semantics;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onTap == null) return;
    if (_down != down) setState(() => _down = down);
  }

  void _tap() {
    final VoidCallback? onTap = widget.onTap;
    if (onTap == null) return;
    onTap();
    GameFeel.tick();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final bool on = widget.onTap != null;
    final Color face = widget.primary ? p.inverse : _plainFace(p);
    final Color ink = widget.primary ? p.onInverse : p.ink;
    return Semantics(
      button: true,
      enabled: on,
      label: widget.semantics ?? widget.label,
      excludeSemantics: true,
      onTap: on ? _tap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: on ? _tap : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: calm ? Duration.zero : const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: !on ? 0.42 : (_down ? 0.82 : 1),
            duration: calm ? Duration.zero : const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(999),
                border: widget.primary
                    ? null
                    : Border.all(color: _plainLine(p), width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: widget.size + 2, color: ink),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      maxLines: 1,
                      style: AppText.body(
                        size: widget.size,
                        weight: FontWeight.w700,
                        height: 1,
                        spacing: 0.1,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of a set to choose from — a size, an amount, a stake, a width, a
/// step — on the page: plain; [selected], the inverse; once told, the one
/// that was right in the calm green with a tick, the one picked wrong in
/// the alert with a cross ([verdict]), and the rest faded.
class GameOption extends StatefulWidget {
  const GameOption({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.verdict,
    this.height = 52,
    this.size = 15,
    this.semantics,
    this.fade = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;

  /// True for the answer, once told; false for a pick that was not it.
  final bool? verdict;
  final double height;
  final double size;
  final String? semantics;

  /// Whether it fades with nothing to do and nothing to tell.
  final bool fade;

  @override
  State<GameOption> createState() => _GameOptionState();
}

class _GameOptionState extends State<GameOption> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onTap == null) return;
    if (_down != down) setState(() => _down = down);
  }

  void _tap() {
    final VoidCallback? onTap = widget.onTap;
    if (onTap == null) return;
    onTap();
    GameFeel.tick();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final bool on = widget.onTap != null;
    final bool? v = widget.verdict;
    final Color? told = switch (v) {
      true => challengeRight(p),
      false => challengeWrong(p),
      null => null,
    };
    final Color face = told != null
        ? Color.alphaBlend(told.withValues(alpha: 0.14), p.surface)
        : widget.selected
        ? p.inverse
        : _plainFace(p);
    final Color ink = told ?? (widget.selected ? p.onInverse : p.ink);
    final bool quiet = !on && !widget.selected && v == null && widget.fade;
    return Semantics(
      button: true,
      enabled: on,
      selected: widget.selected,
      label: widget.semantics ?? widget.label,
      excludeSemantics: true,
      onTap: on ? _tap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: on ? _tap : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: calm ? Duration.zero : const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: quiet ? 0.45 : (_down ? 0.82 : 1),
            duration: calm ? Duration.zero : const Duration(milliseconds: 110),
            child: AnimatedContainer(
              duration: calm
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              height: widget.height,
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: told != null
                      ? told.withValues(alpha: 0.6)
                      : widget.selected
                      ? p.inverse
                      : _plainLine(p),
                  width: told != null ? 1.2 : 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (context, box) {
                  // A narrow option keeps its figure's size once told: its
                  // mark goes to the corner, not beside the figure.
                  final bool narrow = box.maxWidth < 64;
                  final bool corner = v != null && narrow;
                  final Widget label = Padding(
                    padding: EdgeInsets.symmetric(horizontal: narrow ? 2 : 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (v != null && !corner) ...[
                            GameVerdictGlyph(right: v, colour: ink, size: 13),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            widget.label,
                            maxLines: 1,
                            style:
                                AppText.body(
                                  size: widget.size,
                                  weight: FontWeight.w700,
                                  height: 1,
                                  color: ink,
                                ).copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (!corner) return label;
                  return SizedBox(
                    width: box.maxWidth,
                    height: box.maxHeight,
                    child: Stack(
                      children: [
                        Center(child: label),
                        Positioned(
                          top: 6,
                          right: 2,
                          child: GameVerdictGlyph(
                            right: v,
                            colour: ink,
                            size: 9,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a round says over its cards, in the app's serif: what to do, the
/// question the round asks, or — with [verdict] — how the answer went,
/// with its mark in the calm green or the alert.
class GameStatus extends StatelessWidget {
  const GameStatus(this.text, {super.key, this.verdict});

  final String text;
  final bool? verdict;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool? v = verdict;
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.4);
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final Widget line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (v != null) ...[
          Padding(
            padding: EdgeInsets.only(top: scaler.scale(4)),
            child: GameVerdictGlyph(
              right: v,
              colour: v ? challengeRight(p) : challengeWrong(p),
              size: scaler.scale(15),
            ),
          ),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textScaler: scaler,
            style: AppText.display(
              size: 19,
              weight: FontWeight.w600,
              height: 1.2,
              spacing: -0.25,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      liveRegion: v != null,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$text|$v'),
        tween: Tween(begin: calm ? 1 : 0, end: 1),
        duration: calm ? Duration.zero : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 5),
            child: child,
          ),
        ),
        child: line,
      ),
    );
  }
}

/// A name over a figure or a control, in small capitals of the page's
/// muted ink, as the app's cards name their parts.
class GameLabel extends StatelessWidget {
  const GameLabel(this.text, {super.key, this.colour});

  final String text;
  final Color? colour;

  @override
  Widget build(BuildContext context) => Text(
    upper(context, text),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
    style: AppText.label(
      size: 10.5,
      weight: FontWeight.w700,
      spacing: 1.2,
      height: 1.3,
      color: colour ?? context.p.inkMuted,
    ),
  );
}

/// One figure of a told round: its name, the figure, and its unit.
typedef GameFigure = ({String label, String value, String? unit, bool answer});

/// Figures side by side, each its name over it: what the answer was and
/// what the reader said, the answer in the calm green.
class GameFigureRow extends StatelessWidget {
  const GameFigureRow({super.key, required this.figures});

  final List<GameFigure> figures;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < figures.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameLabel(figures[i].label),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    figures[i].value,
                    maxLines: 1,
                    textScaler: scaler,
                    style:
                        AppText.display(
                          size: 34,
                          weight: FontWeight.w600,
                          height: 1.05,
                          spacing: -0.8,
                          color: figures[i].answer ? challengeRight(p) : p.ink,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
                if (figures[i].unit case final String unit when unit.isNotEmpty)
                  Text(
                    unit,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textScaler: scaler,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      height: 1.25,
                      color: p.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A card of the page's own, as Your journey sets its parts on.
class ChallengePanel extends StatelessWidget {
  const ChallengePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.label,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Its name, small, over it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String? name = label;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: p.isDark ? null : Border.all(color: p.line),
      ),
      child: name == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                GameLabel(name),
                const SizedBox(height: 10),
                Flexible(child: child),
              ],
            ),
    );
  }
}

/// The reader's figures: each a row, what it is on the left and the
/// figure on the right, on a card of the page's own — or [bare], inside
/// one.
class ChallengeFigures extends StatelessWidget {
  const ChallengeFigures({super.key, required this.rows, this.bare = false});

  final List<ChallengeFigure> rows;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Widget list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0 || bare) Container(height: 1, color: p.line),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: p.inkMuted,
                    ),
                  ),
                ),
                if (rows[i].value.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Text(
                    rows[i].value,
                    style:
                        AppText.body(
                          size: 15,
                          weight: FontWeight.w800,
                          height: 1.3,
                          color: p.ink,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
    if (bare) return list;
    return ChallengePanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      child: list,
    );
  }
}

/// The day's round as a list, before it is played: a row a turn, each
/// card's subject on a tile of its colour — its mark on it where the round
/// is short enough for rows of a good height — and its name, and a turn
/// already taken its verdict.
class ChallengeDeck extends StatelessWidget {
  const ChallengeDeck({
    super.key,
    required this.rounds,
    this.marks = const [],
    this.row,
  });

  final List<List<Pill>> rounds;
  final List<bool?> marks;

  /// Each row's height, where the page has measured it; else the round's
  /// own.
  final double? row;

  /// The size a round of [n] names its subjects at: larger where there are
  /// few of them.
  static double textSize(int n) => n <= 4
      ? 16
      : n <= 6
      ? 15.5
      : 15;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.5);
    // A short round's rows are a finger's height, each subject's mark on
    // its tile; a long one's are closer, the tile a square of colour.
    final int n = rounds.length;
    final double tile = n <= 3
        ? 38
        : n <= 4
        ? 32
        : n <= 6
        ? 26
        : 14;
    final double pad = n <= 3
        ? 15
        : n <= 4
        ? 10
        : n <= 6
        ? 8
        : 8.5;
    final double? row = this.row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rounds.length; i++) ...[
          Container(height: 1, color: p.line),
          Container(
            constraints: row == null ? null : BoxConstraints(minHeight: row),
            alignment: AlignmentDirectional.centerStart,
            padding: row == null
                ? EdgeInsets.symmetric(vertical: pad)
                : EdgeInsets.zero,
            child: Row(
              children: [
                SizedBox(
                  width: scaler.scale(22),
                  child: Text(
                    '${i + 1}',
                    textScaler: scaler,
                    style:
                        AppText.body(
                          size: 13,
                          weight: FontWeight.w700,
                          height: 1.2,
                          color: p.inkMuted,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
                for (final Pill pill in rounds[i]) ...[
                  Container(
                    width: tile,
                    height: tile,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pill.color,
                      borderRadius: BorderRadius.circular(tile > 20 ? 8 : 3.5),
                      border: cardHairline(pill.color, p.surface),
                    ),
                    child: tile > 20
                        ? SubjectIcon(
                            subject: pill.topic,
                            size: tile * 0.5,
                            ink: pill.ink,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                ],
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [for (final Pill pill in rounds[i]) l.subjectOf(pill.topic)]
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: scaler,
                    style: AppText.body(
                      size: textSize(n),
                      weight: FontWeight.w600,
                      height: 1.25,
                      color: p.ink,
                    ),
                  ),
                ),
                if (i < marks.length && marks[i] != null) ...[
                  const SizedBox(width: 8),
                  GameVerdictGlyph(
                    right: marks[i],
                    colour: marks[i]! ? challengeRight(p) : challengeWrong(p),
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// How far along: one short rule a card, the ones done in the calm green
/// or red of right or wrong, the one in front in ink, the rest faint.
class GameSegments extends StatelessWidget {
  const GameSegments({
    super.key,
    required this.id,
    required this.marks,
    required this.at,
  });

  /// The game's keys' prefix.
  final String id;

  /// Each card's verdict, or null while it has none.
  final List<bool?> marks;

  /// The card in front.
  final int at;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final int n = marks.length;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < n; i++) ...[
            if (i > 0) SizedBox(width: n > 8 ? 3 : 4),
            Expanded(
              child: AnimatedContainer(
                key: ValueKey(
                  '$id-seg-$i-${switch (marks[i]) {
                    true => 'right',
                    false => 'wrong',
                    null when i < at => 'done',
                    null => i == at ? 'now' : 'next',
                  }}',
                ),
                duration: calm
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 4,
                decoration: BoxDecoration(
                  color: switch (marks[i]) {
                    true => challengeRight(p),
                    false => challengeWrong(p),
                    // Done with, told nothing: placed, or answered before.
                    null when i < at => p.inkMuted,
                    null => i == at ? p.ink : p.lineStrong,
                  },
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A round as small squares, one a card: the calm green right, the calm
/// red wrong, an empty one not answered. What the score is sent as, too.
/// They come in one after another, as the round was played; at once for a
/// reader who asked for less motion.
class GameSquares extends StatefulWidget {
  const GameSquares({super.key, required this.marks});

  final List<bool?> marks;

  @override
  State<GameSquares> createState() => _GameSquaresState();
}

class _GameSquaresState extends State<GameSquares>
    with SingleTickerProviderStateMixin {
  /// After the score has counted, a square each this far apart.
  static const int _wait = 280, _each = 55, _one = 220;

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: _wait + _each * widget.marks.length + _one,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
    } else if (_in.value == 0 && !_in.isAnimating) {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final List<bool?> marks = widget.marks;
    final double total = (_in.duration?.inMilliseconds ?? 1).toDouble();
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _in,
        builder: (context, _) => Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (int i = 0; i < marks.length; i++)
              Opacity(
                opacity: Curves.easeOut.transform(
                  ((_in.value * total - _wait - _each * i) / _one).clamp(
                    0.0,
                    1.0,
                  ),
                ),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: switch (marks[i]) {
                      true => challengeRight(p),
                      false => challengeWrong(p),
                      null => Colors.transparent,
                    },
                    borderRadius: BorderRadius.circular(3),
                    border: marks[i] == null
                        ? Border.all(color: p.lineStrong)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A verdict as a mark, drawn in a hairline: a tick for right, a cross for
/// wrong, a dash for no answer.
class GameVerdictGlyph extends StatelessWidget {
  const GameVerdictGlyph({
    super.key,
    required this.right,
    required this.colour,
    this.size = 14,
  });

  final bool? right;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _VerdictPainter(right, colour)),
    ),
  );
}

class _VerdictPainter extends CustomPainter {
  const _VerdictPainter(this.right, this.colour);

  final bool? right;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Paint pen = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s / 9).clamp(1.3, 2.4)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final Path path = switch (right) {
      true =>
        Path()
          ..moveTo(s * 0.12, s * 0.54)
          ..lineTo(s * 0.4, s * 0.8)
          ..lineTo(s * 0.88, s * 0.22),
      false =>
        Path()
          ..moveTo(s * 0.2, s * 0.2)
          ..lineTo(s * 0.8, s * 0.8)
          ..moveTo(s * 0.8, s * 0.2)
          ..lineTo(s * 0.2, s * 0.8),
      null =>
        Path()
          ..moveTo(s * 0.22, s * 0.5)
          ..lineTo(s * 0.78, s * 0.5),
    };
    canvas.drawPath(path, pen);
  }

  @override
  bool shouldRepaint(_VerdictPainter old) =>
      old.right != right || old.colour != colour;
}

/// The challenge after this one, on a card of the page's own: its mark and
/// the skill it trains, its name and what it asks — a tap away.
class GameNextCard extends StatelessWidget {
  const GameNextCard({
    super.key,
    required this.id,
    required this.look,
    required this.onTap,
  });

  /// The game's keys' prefix: the card is `<id>-next`.
  final String id;
  final ChallengeLook look;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TextScaler scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: 1.5);
    return Semantics(
      button: true,
      label: '${l.gameNext}: ${look.title}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: ValueKey('$id-next'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ChallengePanel(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ChallengeMarkView(
                          mark: look.mark,
                          colour: p.inkMuted,
                          size: 14,
                        ),
                        const SizedBox(width: 7),
                        Expanded(child: GameLabel(look.skill)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      look.title,
                      textScaler: scaler,
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w600,
                        height: 1.08,
                        spacing: -0.4,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      look.line,
                      textScaler: scaler,
                      style: AppText.body(
                        size: 13.5,
                        weight: FontWeight.w500,
                        height: 1.3,
                        color: p.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 20, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// One card of a round, again: what it said, how it went, and what it is.
@immutable
class GameReviewItem {
  const GameReviewItem({
    required this.key,
    required this.text,
    required this.semantics,
    this.mark,
    this.tag,
    this.tagDark = false,
    this.detail,
    this.onTap,
  });

  final Key key;

  /// The card's words, as the game showed them.
  final String text;

  /// What a screen reader says for the whole row.
  final String semantics;

  /// Right, wrong, or neither.
  final bool? mark;

  /// What it is, in a tag on the right: "TRUE", "1962", "42%".
  final String? tag;

  /// Whether the tag is set strongly, in the page's inverse, rather than
  /// quietly.
  final bool tagDark;

  /// A line under the words: what the reader said, by how much they were off.
  final String? detail;

  /// Opens the card, where the why is.
  final VoidCallback? onTap;
}

/// The cards of a round again: each its verdict, its words, what it is in
/// a tag — a tap from its card. On a card of the page's own, or [bare], on
/// the page itself, a hairline over each row, as the report sets it.
class GameReview extends StatelessWidget {
  const GameReview({
    super.key,
    required this.items,
    this.label,
    this.bare = false,
  });

  final List<GameReviewItem> items;

  /// The card's name, over its rows.
  final String? label;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String? name = label;
    if (bare) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name != null) ...[GameLabel(name), const SizedBox(height: 8)],
          for (final GameReviewItem item in items) ...[
            Container(height: 1, color: p.line),
            _row(context, p, item),
          ],
        ],
      );
    }
    return ChallengePanel(
      label: label,
      padding: label == null
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: 2)
          : const EdgeInsets.fromLTRB(18, 18, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i + 1 < items.length
                    ? Border(bottom: BorderSide(color: p.line))
                    : null,
              ),
              child: _row(context, p, items[i]),
            ),
        ],
      ),
    );
  }

  /// A tag longer than this goes under the words, not beside them.
  static const int _tagBeside = 9;

  Widget _tag(BuildContext context, Palette p, String tag, bool strong) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: strong ? p.inverse : p.ink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          upper(context, tag),
          style: AppText.label(
            size: 10,
            weight: FontWeight.w800,
            spacing: 0.8,
            height: 1.1,
            color: strong ? p.onInverse : p.ink,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      );

  Widget _row(BuildContext context, Palette p, GameReviewItem item) {
    final bool? right = item.mark;
    final String? said = item.tag;
    final bool under = said != null && said.length > _tagBeside;
    final String? tag = under || (said?.isEmpty ?? true) ? null : said;
    return Semantics(
      button: item.onTap != null,
      label: item.semantics,
      excludeSemantics: true,
      onTap: item.onTap,
      child: GestureDetector(
        key: item.key,
        behavior: HitTestBehavior.opaque,
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: GameVerdictGlyph(
                  right: right,
                  colour: switch (right) {
                    true => challengeRight(p),
                    false => challengeWrong(p),
                    null => p.inkFaint,
                  },
                  size: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.32,
                        color: p.ink,
                      ),
                    ),
                    if (under) ...[
                      const SizedBox(height: 6),
                      _tag(context, p, said, item.tagDark),
                    ],
                    if (item.detail case final String detail) ...[
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w500,
                          height: 1.3,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 12),
                _tag(context, p, tag, item.tagDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// How sure, asked on the page: the card's own levels, each an option, so
/// a bet laid on the screen counts towards how sure against how right like
/// an answer given on the card.
class GameSure extends StatelessWidget {
  const GameSure({super.key, required this.id, required this.onPick});

  /// The keys' prefix: each level is `<id>-sure-<pct>`.
  final String id;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    Widget level(int pct) => GameOption(
      key: ValueKey('$id-sure-$pct'),
      label: gamePercent(context, pct, 100),
      semantics: l.percentSure(pct),
      height: 52,
      size: 15,
      onTap: () {
        GameFeel.tick();
        onPick(pct);
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameStatus(l.howSureAreYou),
        const SizedBox(height: 10),
        if (scale <= 1.3)
          Row(
            children: [
              for (int i = 0; i < kConfidenceLevels.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: level(kConfidenceLevels[i])),
              ],
            ],
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (final int pct in kConfidenceLevels)
                SizedBox(width: 96, child: level(pct)),
            ],
          ),
      ],
    );
  }
}
