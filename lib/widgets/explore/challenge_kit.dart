/// The parts every challenge's screen is drawn with, on the app's own page:
/// precise controls with a hairline round them, the challenge's tone kept
/// for its primary button, figures in tabular figures, verdicts told in a
/// calm colour and a short phrase — the way a serious learning tool sets
/// a test, not the way a game dresses up.
///
/// One kit, so the twelve screens are one family: whatever the challenge,
/// Begin is the same button, a right answer the same calm green, the next
/// challenge the same card.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart' show kConfidenceLevels;
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../card_edge.dart' show colourContrast;
import '../glass_round.dart';
import 'challenge_marks.dart';
import 'challenges.dart';
import 'parts.dart' show upper;

/// The drawn cards' ink and paper: what the challenges whose rounds are
/// still set on cards of paper draw them in.
const Color kArtInk = Color(0xFF10100C);
const Color kArtCream = Color(0xFFFFFBF0);

/// The green a right answer is told in on a card of paper, and the coral
/// of a wrong one.
const Color kGameRight = Color(0xFF2BD67B);
const Color kGameWrong = Color(0xFFFF5A4E);

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
    return DateFormat.MMMd(locale).format(DateTime.now());
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

/// What a claim, a figure or a moment is set on: a card of the
/// challenge's colour, as the app's cards are of their subject's (on a
/// screen with no challenge, a card of paper). Its words are the cards'
/// ink, which every colour of the wheel carries.
class GamePaper extends StatelessWidget {
  const GamePaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.radius = 26,
    this.colour = kArtCream,
    this.line = 3,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color colour;
  final double line;

  @override
  Widget build(BuildContext context) {
    final ChallengeTone? tone = ChallengeToneScope.maybeOf(context);
    if (tone == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: kArtInk, width: line),
        ),
        child: child,
      );
    }
    final Color face = gameFace(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            face,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.1), face),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// The face of a card a round is set on: the challenge's colour, or the
/// drawn cards' paper on a screen with no challenge.
Color gameFace(BuildContext context) {
  final ChallengeTone? tone = ChallengeToneScope.maybeOf(context);
  if (tone == null) return kArtCream;
  // The cards' words are dark: a colour that carries white is lightened
  // until they read on it.
  return tone.ink == Colors.white
      ? Color.lerp(tone.vivid, Colors.white, 0.42)!
      : tone.vivid;
}

/// The line of ink round such a card: none on a challenge's screen, where
/// the cards are the app's own.
Border? gameBorder(BuildContext context, {double width = 3}) =>
    ChallengeToneScope.maybeOf(context) == null
    ? Border.all(color: kArtInk, width: width)
    : null;

/// The way out, as the app's controls are drawn: Apple's own glass on iOS
/// 26 and later, and elsewhere a hairline circle round a cross.
class GameClose extends StatelessWidget {
  const GameClose({super.key, required this.id, required this.onTap});

  /// The game's keys' prefix: `sixty`, whose close is `sixty-close`.
  final String id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return GlassRound(
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
            dimension: 48,
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
  }
}

/// A button, flat and precise: a face, a hairline round it where the face
/// alone would not show on the page, the label in the app's sans. It dims
/// a little under the finger. With no [onTap] it stands faded: not yet.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.face,
    required this.ink,
    required this.onTap,
    this.icon,
    this.height = 56,
    this.size = 16,
    this.semantics,
    this.selected,
    this.radius = 12,
    this.fade = true,
    this.border,
  });

  /// The challenge's primary button: its face the challenge's [tone].
  factory GameButton.primary({
    Key? key,
    required BuildContext context,
    required String label,
    required ChallengeTone tone,
    required VoidCallback? onTap,
    double height = 56,
    String? semantics,
  }) {
    final Palette p = context.p;
    return GameButton(
      key: key,
      label: label,
      face: p.inverse,
      ink: p.onInverse,
      border: p.inverse,
      onTap: onTap,
      height: height,
      radius: 999,
      size: 15.5,
      semantics: semantics,
    );
  }

  /// A plain button: the page's own ground, a hairline round it, ink.
  factory GameButton.plain({
    Key? key,
    required BuildContext context,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    double height = 56,
    double size = 15.5,
    String? semantics,
  }) {
    final Palette p = context.p;
    return GameButton(
      key: key,
      label: label,
      icon: icon,
      face: p.isDark ? const Color(0xFF1A1A1E) : Colors.white,
      ink: p.ink,
      border: p.isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
      onTap: onTap,
      height: height,
      radius: 999,
      size: size,
      semantics: semantics,
    );
  }

  final String label;
  final IconData? icon;
  final Color face;
  final Color ink;
  final VoidCallback? onTap;
  final double height;

  /// How large the label is set.
  final double size;

  /// What a screen reader says, when not the label.
  final String? semantics;

  /// Whether it is the one chosen, where it is one of a set.
  final bool? selected;

  final double radius;

  /// Whether it fades with no [onTap]: not yet. One told — the right amount
  /// lit green — stands as it is.
  final bool fade;

  /// The hairline round it; by default one only where the face does not
  /// show on the page by itself.
  final Color? border;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onTap == null) return;
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final bool on = widget.onTap != null;
    // The drawn cards' paper and ink, as the challenges' rounds still ask
    // for them: the app's raised button and its inverse one.
    final (Color face, Color ink) = switch (widget.face) {
      kArtCream => (p.isDark ? const Color(0xFF1A1A1E) : Colors.white, p.ink),
      kArtInk => (p.inverse, p.onInverse),
      final Color f => (f, widget.ink),
    };
    final bool legacy = widget.face == kArtCream || widget.face == kArtInk;
    final bool lifted = face == p.inverse && on;
    final Color line =
        widget.border ??
        (face.a < 1 || colourContrast(face, p.surface) < 1.6
            ? p.lineStrong
            : face);
    return Semantics(
      button: true,
      enabled: on,
      selected: widget.selected,
      label: widget.semantics ?? widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: !on && widget.fade ? 0.5 : (_down ? 0.8 : 1),
          duration: calm ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(legacy ? 999 : widget.radius),
              border: Border.all(
                color: widget.face == kArtCream
                    ? (p.isDark
                          ? const Color(0x1AFFFFFF)
                          : const Color(0x14000000))
                    : legacy
                    ? face
                    : line,
                width: 0.8,
              ),
              boxShadow: lifted
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: p.isDark ? 0.35 : 0.16,
                        ),
                        blurRadius: 14,
                        spreadRadius: -4,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: widget.size + 3, color: widget.ink),
                    if (widget.label.isNotEmpty) const SizedBox(width: 8),
                  ],
                  if (widget.label.isNotEmpty)
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
    );
  }
}

/// A mark and a few quiet words: a record, the points, how a challenge
/// counts.
class GameChip extends StatelessWidget {
  const GameChip({
    super.key,
    required this.icon,
    required this.label,
    required this.ink,
    this.ground,
  });

  final IconData icon;
  final String label;
  final Color ink;

  /// What it stands on. Unused on the page, which is its ground.
  final Color? ground;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.p.inkMuted),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: AppText.body(
            size: 13.5,
            weight: FontWeight.w500,
            height: 1.3,
            color: ink,
          ),
        ),
      ),
    ],
  );
}

/// A challenge on a card of its colour, as a card of the day is on its
/// subject's: deepening a little to its corner, its mark large and faint
/// off that corner.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.tone,
    required this.mark,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 22),
    this.faint = true,
    this.big = false,
  });

  /// Whether the faint mark is the card's size, for a card that is the
  /// screen's.
  final bool big;

  final ChallengeTone tone;
  final ChallengeMark mark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Whether the mark lies large and faint in its corner.
  final bool faint;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.vivid,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.14), tone.vivid),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (faint)
            Positioned(
              right: big ? -40 : -24,
              top: big ? 34 : null,
              bottom: big ? null : -24,
              child: ChallengeMarkView(
                mark: mark,
                colour: tone.ink.withValues(alpha: big ? 0.09 : 0.1),
                size: big ? 260 : 170,
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    ),
  );
}

/// A challenge card's head, as a card's carries its subject: the mark and
/// the skill it trains, in small capitals.
class ChallengeCardHead extends StatelessWidget {
  const ChallengeCardHead({super.key, required this.look, this.label});

  final ChallengeLook look;

  /// What the head says instead of the skill.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Color ink = look.tone.ink;
    return Row(
      children: [
        ChallengeMarkView(mark: look.mark, colour: ink, size: 15),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            upper(context, label ?? look.skill),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(
              size: 9.5,
              weight: FontWeight.w700,
              spacing: 1.2,
              color: ink.withValues(alpha: 0.78),
            ),
          ),
        ),
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

  /// Its name, small, beside a dot of the challenge's colour, as Go
  /// deeper names its parts.
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
                ChallengeDotLabel(text: name, colour: p.ink),
                const SizedBox(height: 10),
                Flexible(child: child),
              ],
            ),
    );
  }
}

/// A card's name in small capitals, as the app's cards carry theirs.
/// [colour] is kept for the callers; the label is the page's muted ink.
class ChallengeDotLabel extends StatelessWidget {
  const ChallengeDotLabel({
    super.key,
    required this.text,
    required this.colour,
  });

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(
          upper(context, text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w700,
            spacing: 1.2,
            height: 1.3,
            color: context.p.inkMuted,
          ),
        ),
      ),
    ],
  );
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
                height: 5,
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
class GameSquares extends StatelessWidget {
  const GameSquares({super.key, required this.marks});

  final List<bool?> marks;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < marks.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
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
          ],
        ],
      ),
    );
  }
}

/// Right or wrong, on a card of paper as it is told: a thin ring round a
/// thin mark, in a calm colour. [scale] grows it in.
class GameStamp extends StatelessWidget {
  const GameStamp({
    super.key,
    required this.right,
    this.scale = 1,
    this.size = 96,
  });

  final bool right;
  final double scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Color colour = right
        ? challengeRight(Palette.light)
        : challengeWrong(Palette.light);
    return Transform.scale(
      scale: scale.clamp(0.0, 1.0),
      child: Semantics(
        label: right ? l.gameRight : l.gameWrong,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kArtCream,
            shape: BoxShape.circle,
            border: Border.all(color: colour, width: 1.5),
          ),
          alignment: Alignment.center,
          child: GameVerdictGlyph(
            right: right,
            colour: colour,
            size: size * 0.42,
          ),
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

/// The challenge after this one, as its tile is: its colour, its head, its
/// name and what it asks — a tap away.
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
    final Color ink = look.tone.ink;
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
        child: ChallengeCard(
          tone: look.tone,
          mark: look.mark,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChallengeCardHead(look: look),
                    const SizedBox(height: 14),
                    Text(
                      look.title,
                      textScaler: scaler,
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w600,
                        height: 1.08,
                        spacing: -0.4,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      look.line,
                      textScaler: scaler,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w500,
                        height: 1.3,
                        color: ink.withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, size: 20, color: ink),
              ),
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

  /// Whether the tag is set strongly, in the challenge's colour, rather
  /// than quietly.
  final bool tagDark;

  /// A line under the words: what the reader said, by how much they were off.
  final String? detail;

  /// Opens the card, where the why is.
  final VoidCallback? onTap;
}

/// The cards of a round again, on a card of the page's own, as the shelf's
/// round sets them: each its verdict, its words, what it is in a tag of
/// the challenge's colour — a tap from its card.
class GameReview extends StatelessWidget {
  const GameReview({
    super.key,
    required this.items,
    this.tone,
    this.spread = false,
    this.label,
  });

  final List<GameReviewItem> items;

  /// The card's name, over its rows.
  final String? label;

  /// Whether the rows spread down a card taller than they need.
  final bool spread;

  /// The challenge's colour, for the tags.
  final ChallengeTone? tone;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return ChallengePanel(
      label: label,
      padding: label == null
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: 2)
          : const EdgeInsets.fromLTRB(18, 18, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: spread
            ? MainAxisAlignment.spaceEvenly
            : MainAxisAlignment.start,
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

  Widget _tag(BuildContext context, Palette p, String tag, bool strong) {
    final ChallengeTone? t = tone;
    final Color face = strong && t != null
        ? t.vivid
        : p.ink.withValues(alpha: 0.08);
    final Color ink = strong && t != null ? t.ink : p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        upper(context, tag),
        style: AppText.label(
          size: 10,
          weight: FontWeight.w800,
          spacing: 0.8,
          height: 1.1,
          color: ink,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }

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

/// How sure, asked large: the card's own levels, each a button, so a bet
/// laid on the screen counts towards how sure against how right like an
/// answer given on the card.
class GameSure extends StatelessWidget {
  const GameSure({
    super.key,
    required this.id,
    required this.ink,
    required this.onPick,
  });

  /// The keys' prefix: each level is `<id>-sure-<pct>`.
  final String id;
  final Color ink;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    Widget level(int pct) => GameButton(
      key: ValueKey('$id-sure-$pct'),
      label: '$pct%',
      semantics: l.percentSure(pct),
      face: pct >= 80 ? kArtInk : kArtCream,
      ink: pct >= 80 ? kArtCream : kArtInk,
      height: 58,
      size: 17,
      radius: 12,
      onTap: () {
        HapticFeedback.selectionClick();
        onPick(pct);
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.howSureAreYou,
          textAlign: TextAlign.center,
          style: AppText.display(
            size: 22,
            weight: FontWeight.w500,
            height: 1.15,
            spacing: -0.3,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
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
            alignment: WrapAlignment.center,
            children: [
              for (final int pct in kConfidenceLevels)
                SizedBox(width: 96, child: level(pct)),
            ],
          ),
      ],
    );
  }
}
