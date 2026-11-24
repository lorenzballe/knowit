/// The parts every challenge's screen is drawn with, in the drawn cards'
/// manner — a face of paper or colour, a line of ink round it, an edge of
/// ink it sinks into under the finger: the buttons, the chips, the bars of
/// how far along, the squares of how it went, the next challenge, the
/// cards again, the burst of paper, the way out.
///
/// One kit, so the twelve screens are one family: whatever the game, Play
/// is the same button, a right answer the same green, the next challenge
/// the same card.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../analytics.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart' show kConfidenceLevels;
import '../../theme.dart';
import '../../utils/share_link.dart';
import '../card_edge.dart' show colourContrast;
import '../glass_round.dart';
import 'challenge_art.dart';
import 'challenges.dart';
import 'parts.dart' show upper;

/// The green a right answer is told in, and the coral of a wrong one: the
/// drawn cards' own.
const Color kGameRight = Color(0xFF2BD67B);
const Color kGameWrong = Color(0xFFFF5A4E);

/// A challenge's screen, opened over Explore out of its tile: the screen's
/// ground is the tile's, grown. With motion reduced it is there at once.
Route<void> challengeRoute(Widget screen, {bool calm = false}) =>
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: calm
          ? Duration.zero
          : const Duration(milliseconds: 480),
      reverseTransitionDuration: calm
          ? Duration.zero
          : const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => screen,
    );

/// Where things stand on a challenge's screen: under the status bar, the
/// head the close and the picture share, and above the home bar.
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
  double get foot => math.max(safe.bottom, 16.0) + 14;

  /// Where the picture sits once the game is under way: in the head, on
  /// the left, beside what the game says there.
  Rect get emblem => Rect.fromLTWH(8, top - 2, 56 * kArtAspect, 56);
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

/// A card of paper with a line of ink round it: what a claim, a figure or
/// a moment is set on.
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
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: colour,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kArtInk, width: line),
    ),
    child: child,
  );
}

/// The way out, as the app's controls are drawn: Apple's own glass on iOS
/// 26 and later, and elsewhere a round button of paper and ink, as the
/// game's cards are.
class GameClose extends StatelessWidget {
  const GameClose({super.key, required this.id, required this.onTap});

  /// The game's keys' prefix: `sixty`, whose close is `sixty-close`.
  final String id;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const Color ink = kArtInk;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kArtCream,
                  border: Border.all(color: ink, width: 2.4),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close_rounded, size: 21, color: ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button with a thickness to it, drawn as the pictures are: a face with
/// a line of ink round it, on an edge of ink it sinks into under the finger
/// (the app's chunky buttons, lib/widgets/chunky.dart, in the drawn cards'
/// manner). With no [onTap] it stands flat and faded: not yet.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.face,
    required this.ink,
    required this.onTap,
    this.icon,
    this.height = 64,
    this.size = 19,
    this.semantics,
    this.selected,
    this.radius = 20,
    this.fade = true,
  });

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

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  static const double _depth = 5;

  void _press(bool down) {
    if (widget.onTap == null) return;
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool calm = MediaQuery.disableAnimationsOf(context);
    final bool on = widget.onTap != null;
    final double sink = !on ? _depth : (_down ? _depth : 0);
    final BorderRadius round = BorderRadius.circular(widget.radius);
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
        child: Opacity(
          opacity: on || !widget.fade ? 1 : 0.45,
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                Positioned.fill(
                  top: _depth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kArtInk,
                      borderRadius: round,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: calm
                      ? Duration.zero
                      : const Duration(milliseconds: 70),
                  left: 0,
                  right: 0,
                  top: sink,
                  bottom: _depth - sink,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.face,
                      borderRadius: round,
                      border: Border.all(color: kArtInk, width: 3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: widget.size + 7,
                              color: widget.ink,
                            ),
                            if (widget.label.isNotEmpty)
                              const SizedBox(width: 8),
                          ],
                          if (widget.label.isNotEmpty)
                            Text(
                              widget.label,
                              maxLines: 1,
                              style: AppText.body(
                                size: widget.size,
                                weight: FontWeight.w800,
                                height: 1,
                                spacing: 0.2,
                                color: widget.ink,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pill with a mark and a few words: a record, a score, how a game
/// counts.
class GameChip extends StatelessWidget {
  const GameChip({
    super.key,
    required this.icon,
    required this.label,
    required this.ink,
    required this.ground,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final Color ground;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.fromLTRB(11, 8, 14, 8),
    decoration: BoxDecoration(
      color: ground,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: kArtInk, width: 2.4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: ink),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w700,
              height: 1.2,
              color: ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// How far along: one bar a card, the ones done green or coral for right or
/// wrong, the one in front open, the rest to come.
class GameSegments extends StatelessWidget {
  const GameSegments({
    super.key,
    required this.id,
    required this.marks,
    required this.at,
    required this.ink,
    this.ground,
  });

  /// The game's keys' prefix.
  final String id;

  /// Each card's verdict, or null while it has none.
  final List<bool?> marks;

  /// The card in front.
  final int at;
  final Color ink;

  /// The game's colour: on a green of its own, a right answer is told in
  /// ink, so it still shows.
  final Color? ground;

  @override
  Widget build(BuildContext context) {
    final int n = marks.length;
    final Color? g = ground;
    final Color right = g != null && colourContrast(kGameRight, g) < 1.3
        ? kArtInk
        : kGameRight;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < n; i++) ...[
            if (i > 0) SizedBox(width: n > 8 ? 4 : 5),
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
                duration: const Duration(milliseconds: 200),
                height: 12,
                decoration: BoxDecoration(
                  color: switch (marks[i]) {
                    true => right,
                    false => kGameWrong,
                    // Done with, told nothing: placed, or answered before.
                    null when i < at => kArtInk,
                    null => i == at ? kArtCream : Colors.transparent,
                  },
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: marks[i] == null && i > at
                        ? ink.withValues(alpha: 0.35)
                        : kArtInk,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A round as squares, one a card: green right, coral wrong, open not
/// answered. What the score is sent as, too.
class GameSquares extends StatelessWidget {
  const GameSquares({super.key, required this.marks});

  final List<bool?> marks;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < marks.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 48),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: switch (marks[i]) {
                        true => kGameRight,
                        false => kGameWrong,
                        null => kArtCream,
                      },
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: kArtInk, width: 2.4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      switch (marks[i]) {
                        true => Icons.check_rounded,
                        false => Icons.close_rounded,
                        null => Icons.remove_rounded,
                      },
                      size: 20,
                      color: marks[i] == null ? kArtInk : kArtCream,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A round badge of right or wrong, stamped on a card as it is told:
/// [scale] grows it in.
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
    return Transform.scale(
      scale: scale,
      child: Semantics(
        label: right ? l.gameRight : l.gameWrong,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: right ? kGameRight : kGameWrong,
            shape: BoxShape.circle,
            border: Border.all(color: kArtInk, width: size / 27),
          ),
          alignment: Alignment.center,
          child: Icon(
            right ? Icons.check_rounded : Icons.close_rounded,
            size: size * 0.64,
            color: kArtCream,
          ),
        ),
      ),
    );
  }
}

/// The challenge after this one: its colour, its picture, its name, a tap
/// away.
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
    final Color ink = look.ink;
    // Half as large again at most: the card shares its row with a picture
    // and an arrow.
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
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: look.colour,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kArtInk, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SizedBox(
                  width: 104,
                  height: 78,
                  child: ChallengeArtView(art: look.art, ground: look.colour),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One line, smaller where it must be: a label broken
                      // in two reads as two words.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          upper(context, l.gameNext),
                          maxLines: 1,
                          textScaler: scaler,
                          style: AppText.label(
                            size: 11,
                            weight: FontWeight.w800,
                            spacing: 1.2,
                            // Small: near full ink, to read on any game's
                            // colour.
                            color: ink.withValues(alpha: 0.86),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        look.title,
                        textScaler: scaler,
                        style: AppText.display(
                          size: 21,
                          weight: FontWeight.w700,
                          height: 1.05,
                          spacing: -0.4,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: kArtInk,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: look.colour,
                  ),
                ),
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

  /// Whether the tag is ink with paper words, rather than paper with ink.
  final bool tagDark;

  /// A line under the words: what the reader said, by how much they were off.
  final String? detail;

  /// Opens the card, where the why is.
  final VoidCallback? onTap;
}

/// The cards of a round again, on a card of paper: each as it went, a tap
/// from its card.
class GameReview extends StatelessWidget {
  const GameReview({super.key, required this.items});

  final List<GameReviewItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kArtCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kArtInk, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1.5,
                color: kArtInk.withValues(alpha: 0.12),
              ),
            _row(context, items[i]),
          ],
        ],
      ),
    );
  }

  /// A tag longer than this goes under the words, not beside them: a
  /// whole amount ("About 5% of the time") would leave the words a
  /// column of one word a line.
  static const int _tagBeside = 9;

  Widget _tag(BuildContext context, String tag, bool dark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: dark ? kArtInk : kArtCream,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: kArtInk, width: 1.8),
    ),
    child: Text(
      upper(context, tag),
      style: AppText.label(
        size: 10.5,
        weight: FontWeight.w800,
        spacing: 0.8,
        height: 1.1,
        color: dark ? kArtCream : kArtInk,
      ),
    ),
  );

  Widget _row(BuildContext context, GameReviewItem item) {
    final bool? right = item.mark;
    final String? said = item.tag;
    final bool under = said != null && said.length > _tagBeside;
    final String? tag = under ? null : said;
    return Semantics(
      button: item.onTap != null,
      label: item.semantics,
      excludeSemantics: true,
      onTap: item.onTap,
      child: InkWell(
        key: item.key,
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: switch (right) {
                    true => kGameRight,
                    false => kGameWrong,
                    null => kArtCream,
                  },
                  shape: BoxShape.circle,
                  border: Border.all(color: kArtInk, width: 2.2),
                ),
                child: Icon(
                  switch (right) {
                    true => Icons.check_rounded,
                    false => Icons.close_rounded,
                    null => Icons.remove_rounded,
                  },
                  size: 17,
                  color: right == null ? kArtInk : kArtCream,
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
                        size: 14.5,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: kArtInk,
                      ),
                    ),
                    if (under) ...[
                      const SizedBox(height: 6),
                      _tag(context, said, item.tagDark),
                    ],
                    if (item.detail case final String detail) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.3,
                          color: kArtInk.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tag != null) ...[
                const SizedBox(width: 10),
                _tag(context, tag, item.tagDark),
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
      radius: 16,
      onTap: () {
        HapticFeedback.mediumImpact();
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
            weight: FontWeight.w700,
            height: 1.15,
            spacing: -0.4,
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

/// A burst of paper from the score, once, for a new record or a round all
/// right: the pictures' own flat colours and line, falling away in a
/// second and a half.
class GameConfetti extends StatefulWidget {
  const GameConfetti({super.key, required this.from});

  /// Where the burst starts, on the screen.
  final Offset from;

  @override
  State<GameConfetti> createState() => _GameConfettiState();
}

class _GameConfettiState extends State<GameConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _run,
    builder: (context, _) => _run.isCompleted
        ? const SizedBox.shrink()
        : CustomPaint(
            painter: _ConfettiPainter(t: _run.value, from: widget.from),
            size: Size.infinite,
          ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.from});

  final double t;
  final Offset from;

  static const List<Color> _colours = [
    kGameRight,
    kGameWrong,
    kArtCream,
    Color(0xFF2F7FE0),
    Color(0xFFFF5A1F),
    Color(0xFFFF8FB4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // The same burst every time: the pieces are drawn from a fixed seed.
    final math.Random r = math.Random(7);
    final Paint line = Paint()
      ..color = kArtInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final double fade = t < 0.75 ? 1 : 1 - (t - 0.75) / 0.25;
    for (int i = 0; i < 34; i++) {
      final double angle = -math.pi * (0.08 + 0.84 * r.nextDouble());
      final double speed = 340 + 520 * r.nextDouble();
      final double spin = (r.nextDouble() - 0.5) * 14;
      final Color colour = _colours[i % _colours.length];
      final double s = 7 + 6 * r.nextDouble();
      final double secs = t * 1.5;
      // Out fast, slowed by the air, pulled down.
      final double drag = (1 - math.exp(-2.6 * secs)) / 2.6;
      final Offset at =
          from +
          Offset(math.cos(angle), math.sin(angle)) * speed * drag +
          Offset(0, 420 * secs * secs);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(spin * secs);
      final Paint fill = Paint()..color = colour.withValues(alpha: fade);
      line.color = kArtInk.withValues(alpha: fade);
      final Rect piece = Rect.fromCenter(
        center: Offset.zero,
        width: s,
        height: i.isEven ? s * 0.55 : s,
      );
      if (i % 3 == 0) {
        canvas.drawOval(piece, fill);
        canvas.drawOval(piece, line);
      } else {
        final RRect rr = RRect.fromRectAndRadius(
          piece,
          const Radius.circular(2),
        );
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, line);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.from != from;
}
