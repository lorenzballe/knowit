/// Commit first — the canvas's 133b.
///
/// A guess the reader commits to before the card opens stays with them
/// longer than one they only half made, which is why the cards ask before
/// they turn over (the ladder's third rung is exactly that). These shelves
/// ask on the shelf: true or false as two buttons, a debate as its two
/// sides, three amounts as three rows. The answer is recorded the way the
/// card itself records one, through the host, and the card says at once
/// whether it was right; the why, or the other side's case, is the card.
library;

import 'package:flutter/material.dart';

import '../../../data/explore_mix.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'kit.dart';

/// 133b's note over the shelves that ask first: a lock, and why.
class CommitNoteBlock extends ExploreBlock {
  const CommitNoteBlock();

  @override
  String get name => 'purpose.commit-note';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final String text = wordsOf(
      section,
      'text',
      host.language,
      context.l10n.purposeCommitNote,
    );
    return host.watch(section, CommitNote(text: text));
  }
}

/// The lock on its tile, and the line beside it.
class CommitNote extends StatelessWidget {
  const CommitNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: context.p.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.p.inverse,
                borderRadius: BorderRadius.circular(10),
              ),
              child: PurposeGlyph(
                Glyphs.lock,
                size: 16,
                color: context.p.onInverse,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w500,
                  height: 1.35,
                  color: context.p.ink.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What a commit shelf asks of its cards.
enum CommitKind {
  /// True or false, as two buttons.
  trueFalse('true-false'),

  /// A debate's two sides.
  side('side'),

  /// Three amounts, one under the other.
  pick('pick'),

  /// Each card as it asks.
  any('any');

  const CommitKind(this.word);

  /// The kind as a section names it.
  final String word;

  /// The kind [p] is answered as, or null when it asks nothing a shelf can
  /// take: a number to type, a scene to play.
  static CommitKind? of(Pill p) => switch (p.challenge) {
    PickOne() when isTrueOrFalse(p) => CommitKind.trueFalse,
    // Three amounts, the canvas's: options that are sentences want the
    // card's own room, not a shelf's.
    PickOne() when isNumberPick(p) => CommitKind.pick,
    TakeASide(:final positions) when positions.length >= 2 => CommitKind.side,
    _ => null,
  };
}

/// 133b: cards answered on the shelf, before they open.
class CommitBlock extends ExploreBlock {
  const CommitBlock();

  @override
  String get name => 'purpose.commit';

  /// Each kind's tile at each size; `m` is the canvas's.
  static const Map<String, Map<CommitKind, TileSize>> sizes = {
    's': {
      CommitKind.trueFalse: TileSize(180, 212),
      CommitKind.side: TileSize(250, 196),
      CommitKind.pick: TileSize(210, 252),
    },
    'm': {
      CommitKind.trueFalse: TileSize(206, 236),
      CommitKind.side: TileSize(290, 214),
      CommitKind.pick: TileSize(236, 268),
    },
    'l': {
      CommitKind.trueFalse: TileSize(236, 262),
      CommitKind.side: TileSize(320, 236),
      CommitKind.pick: TileSize(266, 296),
    },
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Object? asked = section.json['kind'];
    final CommitKind kind =
        CommitKind.values.where((k) => k.word == asked).firstOrNull ??
        CommitKind.any;
    final Set<String> said = PurposePlay.setOf('said');
    final List<Pill> cards = cardsOf(
      host,
      section,
      limit: 8,
      canDraw: (p) {
        final CommitKind? own = CommitKind.of(p);
        return own != null &&
            (kind == CommitKind.any || own == kind) &&
            askable(host, p, said);
      },
    );
    if (cards.isEmpty) return null;
    final l = context.l10n;
    final String lang = host.language;
    final (String title, String line) = switch (kind) {
      CommitKind.trueFalse => (l.themeTrueOrFalse, l.themeTrueOrFalseLine),
      CommitKind.side => (l.themeDebates, l.themeDebatesLine),
      CommitKind.pick => (l.themeWorkItOut, l.purposeInYourHeadLine),
      CommitKind.any => (l.purposeCommitTitle, l.purposeCommitLine),
    };
    final Map<CommitKind, TileSize> tiles = sizeOf(section, sizes);
    // One height for the row: a shelf of every kind keeps its foot level,
    // and a shelf of one kind is that kind's height.
    final double height = [
      for (final Pill p in cards) tiles[CommitKind.of(p)]!.height,
    ].reduce((a, b) => a > b ? a : b);
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? title,
        line: section.subtitle(lang) ?? line,
        child: SideRow(
          height: height + 4,
          count: cards.length,
          itemBuilder: (context, i) {
            final Pill p = cards[i];
            host.seen(section, p);
            final CommitKind own = CommitKind.of(p)!;
            return CommitTile(
              key: ValueKey('commit-${p.id}'),
              pill: p,
              kind: own,
              size: TileSize(tiles[own]!.width, height),
              read: host.isRead(p),
              given: host.app.answerFor(p.id)?.response,
              onOpen: () => host.open(section, cards, p),
              onCommit: (response) {
                PurposePlay.said(p.id);
                host.commit(p, response);
              },
            );
          },
        ),
      ),
    );
  }
}

/// One card answered on the shelf. What was said is kept here until the
/// app has it, so the card answers at once, even before Explore redraws.
class CommitTile extends StatefulWidget {
  const CommitTile({
    super.key,
    required this.pill,
    required this.kind,
    required this.size,
    required this.read,
    required this.given,
    required this.onOpen,
    required this.onCommit,
  });

  final Pill pill;
  final CommitKind kind;
  final TileSize size;
  final bool read;

  /// The answer the reader gave already, on a shelf or on the card.
  final String? given;
  final VoidCallback onOpen;
  final ValueChanged<String> onCommit;

  @override
  State<CommitTile> createState() => _CommitTileState();
}

class _CommitTileState extends State<CommitTile> {
  String? _said;

  String? get _answer => widget.given ?? _said;

  void _say(String response) {
    if (_answer != null) return;
    setState(() => _said = response);
    widget.onCommit(response);
  }

  @override
  Widget build(BuildContext context) {
    final Pill p = widget.pill;
    final l = context.l10n;
    final String? answer = _answer;
    final String? verdict = answer == null ? null : _verdict(l, answer);
    return CardTap(
      pill: p,
      onTap: widget.onOpen,
      child: Container(
        width: widget.size.width,
        height: widget.size.height,
        padding: const EdgeInsets.all(16),
        decoration: cardFace(context, p.color, radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PurposeHead(
              pill: p,
              trailing: widget.read ? ReadMark(pill: p) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: CardQuestion(
                  text: p.question,
                  color: p.ink,
                  min: 11,
                  max: widget.kind == CommitKind.side ? 19 : 18,
                  height: widget.kind == CommitKind.side ? 1.14 : 1.15,
                  tracking: widget.kind == CommitKind.side ? -0.03 : -0.027,
                ),
              ),
            ),
            if (verdict != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  verdict,
                  key: ValueKey('commit-verdict-${p.id}'),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w700,
                    height: 1.25,
                    color: p.ink,
                  ),
                ),
              ),
            switch (widget.kind) {
              CommitKind.pick => _options(answer),
              _ => _pair(answer),
            },
          ],
        ),
      ),
    );
  }

  /// What the answer came to, said on the card.
  String _verdict(AppLocalizations l, String answer) {
    final Pill p = widget.pill;
    switch (p.challenge) {
      case TakeASide(:final positions):
        final int i = (int.tryParse(answer) ?? 0).clamp(
          0,
          positions.length - 1,
        );
        return l.leanVerdict(l.leanTook(shortSide(positions[i])));
      case PickOne(:final options, :final correct):
        if (p.challenge.accepts(answer)) return l.tfRight;
        final String right = isTrueOrFalse(p)
            ? (trueOrFalseAnswer(p) ? l.sayTrue : l.sayFalse)
            : options[correct];
        return l.tfWrong(right);
      default:
        return '';
    }
  }

  /// True and False, or a debate's two sides, side by side.
  Widget _pair(String? answer) {
    final Pill p = widget.pill;
    final l = context.l10n;
    final List<(String, String)> sides = switch (p.challenge) {
      TakeASide(:final positions) => [
        (shortSide(positions[0]), '0'),
        (shortSide(positions[1]), '1'),
      ],
      _ => [
        (l.sayTrue, '${trueOrFalseIndex(p, true)}'),
        (l.sayFalse, '${trueOrFalseIndex(p, false)}'),
      ],
    };
    final bool graded = p.isGraded;
    final String? right = graded ? '${(p.challenge as PickOne).correct}' : null;
    // A side that runs to two lines makes both buttons as tall.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < sides.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _AnswerButton(
                key: ValueKey('commit-${p.id}-${sides[i].$2}'),
                pill: p,
                label: sides[i].$1,
                height: 40,
                radius: 12,
                size: 13,
                centred: true,
                solid: answer == sides[i].$2,
                struck: answer == sides[i].$2 && graded && answer != right,
                ringed:
                    answer != null &&
                    answer != sides[i].$2 &&
                    sides[i].$2 == right,
                faded:
                    answer != null &&
                    answer != sides[i].$2 &&
                    sides[i].$2 != right,
                onTap: answer == null ? () => _say(sides[i].$2) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// A pick-one card's options, one under the other.
  Widget _options(String? answer) {
    final Pill p = widget.pill;
    final PickOne c = p.challenge as PickOne;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int k = 0; k < c.options.length; k++) ...[
          if (k > 0) const SizedBox(height: 5),
          _AnswerButton(
            key: ValueKey('commit-${p.id}-$k'),
            pill: p,
            label: c.options[k],
            height: 32,
            radius: 10,
            size: 12.5,
            centred: false,
            solid: answer != null && k == c.correct,
            struck: answer == '$k' && k != c.correct,
            ringed: false,
            faded: answer != null && answer != '$k' && k != c.correct,
            tick: answer != null && k == c.correct,
            onTap: answer == null ? () => _say('$k') : null,
          ),
        ],
      ],
    );
  }
}

/// Whether [p] can still be answered first: neither read nor answered —
/// committing to an answer already seen commits to nothing — unless it was
/// answered on one of these shelves today, which keeps its verdict on the
/// shelf rather than taking the card away the moment it is answered.
bool askable(ExploreHost host, Pill p, Set<String> said) =>
    said.contains(p.id) ||
    (!host.isRead(p) && host.app.answerFor(p.id) == null);

/// "Yes, require the record" reads as Yes on a button: the word before the
/// comma when there is one and it is short, the whole side otherwise — as
/// the debate shelf above has it.
String shortSide(String side) {
  final String head = side.split(',').first.trim();
  return head.length <= 14 ? head : side;
}

/// One answer on the card: a fill of its ink until it is tapped. Then, as
/// the shelves above have it: of a pair, the side picked solid, struck
/// through when it was wrong, and the right one ringed; of a list, the
/// right one solid with a tick and a wrong pick struck through. The rest
/// are let go.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    super.key,
    required this.pill,
    required this.label,
    required this.height,
    required this.radius,
    required this.size,
    required this.centred,
    required this.solid,
    required this.struck,
    required this.ringed,
    required this.faded,
    required this.onTap,
    this.tick = false,
  });

  final Pill pill;
  final String label;

  /// How tall the button is with its label on one line.
  final double height;
  final double radius;
  final double size;
  final bool centred;
  final bool solid;
  final bool struck;
  final bool ringed;
  final bool faded;
  final bool tick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Pill p = pill;
    final Color fore = solid ? p.color : p.ink;
    // Never cut: a side or an amount longer than the button is wide runs
    // to a second line, and the button grows to hold it.
    final Widget text = Text(
      label,
      textAlign: centred ? TextAlign.center : TextAlign.start,
      style:
          AppText.body(
            size: size,
            weight: FontWeight.w700,
            height: 1.15,
            color: fore,
          ).copyWith(
            decoration: struck ? TextDecoration.lineThrough : null,
            decorationColor: fore,
            decorationThickness: 2,
          ),
    );
    return Semantics(
      button: onTap != null,
      selected: solid || struck,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: faded ? 0.4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            constraints: BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            alignment: centred ? Alignment.center : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: solid ? p.ink : fillOn(p),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: p.ink.withValues(alpha: ringed ? 1 : 0),
                width: 1.5,
              ),
            ),
            child: tick
                ? Row(
                    children: [
                      Expanded(child: text),
                      PurposeGlyph(Glyphs.check, size: 15, color: p.color),
                    ],
                  )
                : text,
          ),
        ),
      ),
    );
  }
}
