import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../analytics.dart';
import '../measure/card_read.dart';
import '../models/pill.dart';
import '../models/place.dart';
import '../theme.dart';
import 'card_edge.dart';
import 'hold_to_keep.dart';
import 'motion.dart';
import 'place_it.dart';
import 'place_line.dart';
import 'scene_view.dart';
import 'reveal_body.dart';
import 'scaled_text.dart';
import 'subject_icon.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying the line to keep and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;

  /// Where this card sits in the set, or null when something else on screen
  /// already says. The bars above the deck and the viewer's own header both
  /// do, and printing it a second time on the card itself is chrome pretending
  /// to be content.
  final String? indexLabel;
  final bool flipped;

  /// What the reader committed to, and where to send a new commitment.
  /// Null while untouched.
  final Answer? given;
  final void Function(String response, int? confidence, String? reason)?
  onAnswer;

  /// True when this card is in today's deck because it came back.
  final bool isReview;

  /// True when this card was chosen for the reader on a day where the
  /// others came at random — the free day says which is which.
  final bool isOwn;

  /// Where the reader lives, for the line a card about a place carries on
  /// its front (see [placeLineOf]); null when they have not said.
  final Place? home;

  /// Why this card is in today's five, said on its front under its head
  /// the way a card about a place says so: on the reader's Sunday, the one
  /// more of their own. Null for nothing to say.
  final String? note;

  const PillCard({
    super.key,
    required this.pill,
    this.indexLabel,
    required this.flipped,
    this.given,
    this.onAnswer,
    this.isReview = false,
    this.isOwn = false,
    this.home,
    this.note,
    this.saved = false,
    this.onSave,
    this.liked = false,
    this.onLike,
    this.onShare,
  });

  /// Keeping and sharing act on this card, not on the screen, so they live on
  /// it. They used to sit in a row of their own under the deck, which put two
  /// rows of controls along the bottom edge with the tab bar.
  final bool saved;
  final VoidCallback? onSave;

  /// Liking is the whole card held down, not a button: a bookmark is a
  /// thing you go and press, a like is a thing you do without letting go.
  final bool liked;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final Widget card = Stack(
      children: [
        _face(context),
        // Each control is 44 square, its mark where the 38 one put it.
        if (onSave != null)
          Positioned(
            right: _CardControl.right,
            bottom: _CardControl.bottom,
            child: Row(
              children: [
                _CardControl(
                  label: saved
                      ? context.l10n.removeFromSaved
                      : context.l10n.saveThisPill,
                  icon: saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  ink: pill.ink,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onSave!.call();
                  },
                ),
                const SizedBox(width: 4),
                _CardControl(
                  label: context.l10n.shareThisPill,
                  icon: Icons.ios_share_rounded,
                  ink: pill.ink,
                  onTap: () => onShare?.call(),
                ),
              ],
            ),
          ),
      ],
    );
    // Held, the whole card is the button.
    if (onLike == null) return card;
    return HoldToKeep(
      saved: liked,
      ink: pill.ink,
      ground: pill.color,
      onToggle: onLike!,
      child: card,
    );
  }

  Widget _face(BuildContext context) {
    // Cut from the page with a hairline where its colour is the page's
    // own, and lifted by a shadow that stays under the card (card_edge.dart).
    return Container(
      decoration: cardFace(context, pill.color, radius: 34, lift: 1),
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // The subject's own mark beside its name, as on the shelf
                  // the card ends the day on: one card, drawn one way.
                  SubjectIcon(subject: pill.topic, size: 16, ink: pill.ink),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.subjectOf(pill.topic).toUpperCase(),
                    style: AppText.label(
                      size: 11,
                      spacing: 1.4,
                      color: pill.ink.withValues(alpha: 0.72),
                    ),
                  ),
                  if (isReview || isOwn) ...[
                    const SizedBox(width: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: pill.wash,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isReview
                            ? context.l10n.againChip
                            : context.l10n.forYouChip,
                        style: AppText.label(
                          size: 9.5,
                          spacing: 1,
                          color: pill.ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (indexLabel != null)
                Text(
                  indexLabel!,
                  style: AppText.label(
                    size: 11,
                    color: pill.ink.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          if (!flipped)
            if (placeLineOf(context, pill.place, home) case final String why)
              _WhyLine(
                key: const ValueKey('place-line'),
                icon: Icons.place_rounded,
                text: why,
                ink: pill.ink,
              ),
          if (!flipped && note != null)
            _WhyLine(
              key: const ValueKey('card-note'),
              icon: Icons.auto_awesome_rounded,
              text: note!,
              ink: pill.ink,
            ),
          Expanded(
            child: flipped
                ? _BackFace(
                    pill: pill,
                    given: given,
                    cornerRoom: onSave != null ? _CardControl.room : 0,
                  )
                // The challenge decides the front. A new kind of challenge
                // will not compile until it is given a face here.
                : switch (pill.challenge) {
                    NoChallenge() when pill.scene != null => _SceneFront(
                      pill: pill,
                    ),
                    NoChallenge() => _FrontFace(pill: pill),
                    PickOne(:final options) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      input: (commit) => _PickInput(
                        pill: pill,
                        options: options,
                        onAnswer: commit,
                        taken: int.tryParse(given?.response ?? ''),
                      ),
                    ),
                    TakeASide(:final positions) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      prompt: context.l10n.pickASideNoRightAnswer,
                      input: (commit) => _PickInput(
                        pill: pill,
                        options: positions,
                        onAnswer: commit,
                        taken: int.tryParse(given?.response ?? ''),
                      ),
                    ),
                    TypeNumber(:final unit) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      input: (commit) => _NumberInput(
                        pill: pill,
                        unit: unit,
                        onAnswer: commit,
                      ),
                    ),
                    // A feel for size is placed on a ruler, not typed.
                    final Estimate estimate => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      prompt: context.l10n.estimateCloseEnough,
                      input: (commit) => PlaceItInput(
                        pill: pill,
                        estimate: estimate,
                        onAnswer: commit,
                      ),
                    ),
                  },
          ),
        ],
      ),
    );
  }
}

/// Why a card is in front of the reader, under its subject: "Near you ·
/// Modena" on a card about a place, with a pin; "Sunday: one more chosen
/// for you" on Sunday's one more of the reader's own, with a spark. Quiet
/// on purpose — the card is the question, and this is the one fact about
/// it the reader did not choose — so it takes the subject row's ink at the
/// same strength, sentence case, a mark beside it, and wraps rather than
/// being cut in a language that runs long.
class _WhyLine extends StatelessWidget {
  const _WhyLine({
    super.key,
    required this.icon,
    required this.text,
    required this.ink,
  });

  final IconData icon;
  final String text;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final Color muted = ink.withValues(alpha: 0.66);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: ExcludeSemantics(child: Icon(icon, size: 13, color: muted)),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w500,
                height: 1.25,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  final Pill pill;
  const _FrontFace({required this.pill});

  @override
  Widget build(BuildContext context) {
    // Set to the space rather than to a fixed size, so a short question is
    // not a line floating in a field of colour — but inside an editorial
    // band, not a poster one. At sixty-four points a five-word question
    // shouted; the card is something you read, not a billboard.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ScaledText(
            text: pill.question,
            min: 21,
            max: 34,
            alignment: Alignment.centerLeft,
            styleFor: (size) => AppText.display(
              size: size,
              weight: FontWeight.w600,
              height: 1.08,
              // Tracking tightens as the type grows: what reads as generous
              // at 22pt reads as gappy at 54.
              spacing: -0.4 - size * 0.028,
              color: pill.ink,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.tapToReveal,
          style: AppText.body(
            size: 13,
            weight: FontWeight.w500,
            color: pill.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// A card with something to play with: the question on top, the scene
/// filling the middle, the way to the answer at the foot.
class _SceneFront extends StatelessWidget {
  final Pill pill;
  const _SceneFront({required this.pill});

  @override
  Widget build(BuildContext context) {
    TextStyle styleFor(double size) => AppText.display(
      size: size,
      weight: FontWeight.w600,
      height: 1.12,
      spacing: -0.3 - size * 0.018,
      color: pill.ink,
    );
    return LayoutBuilder(
      builder: (context, box) {
        // A share of the card, or what the question needs at its smallest
        // size when that is more: a question that has to scroll keeps the
        // card's vertical throw for itself, so less like this stops working.
        final needed =
            (TextPainter(
              text: TextSpan(text: pill.question, style: styleFor(16)),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: box.maxWidth)).height +
            2;
        final room = math.min(
          math.max(box.maxHeight * 0.27, needed),
          box.maxHeight * 0.42,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: room,
              child: ScaledText(
                text: pill.question,
                min: 16,
                max: 27,
                alignment: Alignment.topLeft,
                styleFor: styleFor,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SceneView(
                scene: pill.scene!,
                ink: pill.ink,
                ground: pill.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.tapToReveal,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: pill.ink.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackFace extends StatelessWidget {
  final Pill pill;
  final Answer? given;

  /// Room kept clear for the save and share buttons in the bottom corner.
  final double cornerRoom;
  const _BackFace({required this.pill, this.given, this.cornerRoom = 0});

  @override
  Widget build(BuildContext context) {
    final given = this.given;
    final Estimate? estimate = switch (pill.challenge) {
      final Estimate e when pill.isGraded => e,
      _ => null,
    };

    // What the reader committed to, said first: right or wrong on a card
    // that is marked, the line they took on one that is not.
    Widget? lead;
    double Function(double, TextScaler)? leadHeight;
    Widget? shortLead;
    double Function(double, TextScaler)? shortLeadHeight;
    Widget? leastLead;
    double Function(double, TextScaler)? leastLeadHeight;
    if (given != null && pill.isGraded) {
      final bool right = pill.challenge.accepts(given.response);
      _Verdict verdictOf(_Room room) => _Verdict(
        pill: pill,
        right: right,
        given: pill.challenge.describe(given.response),
        confidence: given.confidence,
        room: room,
      );
      Widget leadOf(_Verdict verdict) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PopIn(delay: const Duration(milliseconds: 260), child: verdict),
          if (estimate != null) ...[
            const SizedBox(height: 6),
            PlaceItReveal(
              pill: pill,
              estimate: estimate,
              response: given.response,
            ),
          ],
        ],
      );
      double Function(double, TextScaler) heightOf(_Verdict verdict) =>
          (width, scaler) =>
              verdict.heightIn(context, width, scaler) +
              (estimate != null ? 6 + PlaceItReveal.height : 0);
      final _Verdict verdict = verdictOf(_Room.all);
      lead = leadOf(verdict);
      leadHeight = heightOf(verdict);
      // On a back too full for the whole of it, how sure goes first: it
      // was said a moment ago, on the front.
      final _Verdict brief = verdictOf(_Room.withoutSure);
      shortLead = leadOf(brief);
      shortLeadHeight = heightOf(brief);
      // Then, on a wrong answer, what was said: the answer under it says
      // what it is. A right one has nothing said back to give up.
      if (!right) {
        final _Verdict bare = verdictOf(_Room.verdictOnly);
        leastLead = leadOf(bare);
        leastLeadHeight = heightOf(bare);
      }
    } else if (given != null) {
      lead = PopIn(
        delay: const Duration(milliseconds: 260),
        child: _YourLine(pill: pill, given: given),
      );
      leadHeight = (width, scaler) =>
          _YourLine.heightFor(context, pill, given, width, scaler);
      if (given.hasReason) {
        shortLead = PopIn(
          delay: const Duration(milliseconds: 260),
          child: _YourLine(pill: pill, given: given, short: true),
        );
        shortLeadHeight = (width, scaler) => _YourLine.heightFor(
          context,
          pill,
          given,
          width,
          scaler,
          short: true,
        );
      }
    }

    return CardReveal(
      pill: pill,
      lead: lead,
      leadHeight: leadHeight,
      shortLead: shortLead,
      shortLeadHeight: shortLeadHeight,
      leastLead: leastLead,
      leastLeadHeight: leastLeadHeight,
      cornerRoom: cornerRoom,
      // On a card that asked first, the scene waits for the answer: played
      // before, it would have given it away.
      scene: pill.scene != null && pill.asksSomething
          ? (height) => SizedBox(
              height: height,
              child: SceneView(
                scene: pill.scene!,
                ink: pill.ink,
                ground: pill.color,
              ),
            )
          : null,
    );
  }
}

/// The height [text] is set at in [width], the way a [Text] here sets it:
/// on the inherited style, which carries the theme's tracking.
double _measure(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
  TextScaler scaler,
) {
  final base = DefaultTextStyle.of(context);
  final p = TextPainter(
    text: TextSpan(text: text, style: base.style.merge(style)),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    textHeightBehavior: base.textHeightBehavior,
  )..layout(maxWidth: width);
  final h = p.height;
  p.dispose();
  return h;
}

double _measureSpan(
  BuildContext context,
  InlineSpan span,
  double width,
  TextScaler scaler,
) {
  final base = DefaultTextStyle.of(context);
  final p = TextPainter(
    text: TextSpan(style: base.style, children: [span]),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    textHeightBehavior: base.textHeightBehavior,
  )..layout(maxWidth: width);
  final h = p.height;
  p.dispose();
  return h;
}

/// How much of the verdict a back has room for, from all of it down: what
/// was said and how sure, what was said, the verdict alone.
enum _Room { all, withoutSure, verdictOnly }

/// Right or wrong, said plainly at the top of the reveal: the verdict in
/// the card's own voice, set large, running into what was said and how
/// sure, set small — a run-in head, as a paper sets one.
///
/// It used to be one line of eleven-point capitals, quieter than the
/// subject's name over the card. That is the wrong size for the moment the
/// app is built on, how sure against how right. Run in rather than stacked,
/// it takes about the room the old line took, so the back still fits the
/// card. A wrong answer is "Not quite.": said, and not rubbed in.
class _Verdict extends StatelessWidget {
  final Pill pill;
  final bool right;
  final String given;
  final int? confidence;

  /// How much of it the back has room for.
  final _Room room;
  const _Verdict({
    required this.pill,
    required this.right,
    required this.given,
    this.confidence,
    this.room = _Room.all,
  });

  /// The mark beside the words, and the gap after it.
  static const double _mark = 20;
  static const double _gap = 10;

  static TextStyle _headStyle(Color ink) => AppText.display(
    size: 20,
    weight: FontWeight.w600,
    height: 1.2,
    spacing: -0.4,
    color: ink,
  );

  static TextStyle _detailStyle(Color ink) => AppText.body(
    size: 13,
    weight: FontWeight.w500,
    height: 1.35,
    color: ink.withValues(alpha: 0.75),
  );

  /// The verdict itself.
  String _head(BuildContext context) => !right
      ? context.l10n.verdictWrong
      : pill.challenge is Estimate
      ? context.l10n.verdictClose
      : context.l10n.verdictRight;

  /// What was said, when it was not what the card says: the reader's
  /// answer, and the card's.
  String? _said(BuildContext context) {
    if (right) return null;
    return switch (pill.challenge) {
      Estimate(:final answerLabel, :final band) =>
        context.l10n.youSaidItIsCounted(given, answerLabel, band),
      TypeNumber(:final answerLabel) => context.l10n.youSaidItIs(
        given,
        answerLabel,
      ),
      // A wrong pick is said the way a wrong number is: what was picked,
      // and what it is. It used to be "almost everyone gets this wrong",
      // which is a claim about other readers that nothing on the phone can
      // back — how each card is answered is counted on the server, for the
      // tools that check cards (functions/src/scorecard.ts), and none of it
      // reaches a card's back.
      PickOne(:final correctOption) => context.l10n.youSaidItIs(
        given,
        correctOption,
      ),
      // Never marked, so never given a verdict: the back says the reader's
      // own line instead.
      NoChallenge() || TakeASide() => null,
    };
  }

  /// What runs on after the verdict: what was said, and how sure.
  String? _detail(BuildContext context) {
    if (room == _Room.verdictOnly) return null;
    final String? said = _said(context);
    final int? sure = room == _Room.all ? confidence : null;
    if (said == null) {
      return sure == null ? null : context.l10n.verdictSure(sure);
    }
    return sure == null ? said : context.l10n.lineYouSaidSure(said, sure);
  }

  InlineSpan _span(BuildContext context) {
    final String? detail = _detail(context);
    return TextSpan(
      children: [
        TextSpan(text: _head(context), style: _headStyle(pill.ink)),
        if (detail != null)
          TextSpan(text: '  $detail', style: _detailStyle(pill.ink)),
      ],
    );
  }

  /// The room the verdict takes at [width]: its words beside the mark.
  double heightIn(BuildContext context, double width, TextScaler scaler) {
    final double h = _measureSpan(
      context,
      _span(context),
      width - _mark - _gap,
      scaler,
    );
    return math.max(h, _mark + 3);
  }

  @override
  Widget build(BuildContext context) {
    // Said out loud when the back comes round, for a reader who cannot see
    // the mark or the size of the words.
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The words say right or wrong; the mark repeats it in shape.
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ExcludeSemantics(
              child: Icon(
                right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: _mark,
                color: pill.ink,
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(child: Text.rich(_span(context))),
        ],
      ),
    );
  }
}

/// A card that asks before it tells: the question, whatever input the
/// challenge needs, and an optional nudge for when the reader is stuck.
class _AskFace extends StatefulWidget {
  final Pill pill;

  /// Built with the callback that reports a raw response.
  final Widget Function(ValueChanged<String>? commit) input;
  final void Function(String response, int? confidence, String? reason)?
  onAnswer;

  /// Overrides the default line under the input, so a debate does not tell
  /// the reader to commit to a right answer that does not exist.
  final String? prompt;

  /// What this reader already committed, if anything. Only used to word the
  /// line under the input when the card cannot be answered here.
  final Answer? given;

  /// Whether the card's save and share sit in the bottom corner, which the
  /// face then keeps clear.
  final bool corner;

  const _AskFace({
    required this.pill,
    required this.input,
    required this.onAnswer,
    this.prompt,
    this.given,
    this.corner = false,
  });

  @override
  State<_AskFace> createState() => _AskFaceState();
}

class _AskFaceState extends State<_AskFace> {
  bool _hintOpen = false;

  /// Held between answering and saying how sure you are.
  String? _pending;

  void _commit(String response) {
    setState(() => _pending = response);
  }

  void _finish(int confidence) {
    final response = _pending;
    if (response == null) return;
    widget.onAnswer?.call(response, confidence, null);
  }

  /// The ungraded path. Nothing here can be scored, so what is asked for is
  /// the reason — written down before the other side is shown, so it cannot
  /// be quietly rewritten to agree with whatever comes next.
  void _finishReason(String reason) {
    final response = _pending;
    if (response == null) return;
    widget.onAnswer?.call(response, null, reason);
  }

  /// The gap above the line under the input, and the least room that line
  /// keeps at the foot when the card's save and share are in the corner:
  /// they reach 33 points up into the face (15 + 44 less its padding of
  /// 26), and the input stays four clear of them.
  static const double _footGap = 14;
  static const double _cornerClear = 37;

  /// The nudge's row, and the gap above it.
  static const double _hintGap = 4;
  static const double _hintRow = 44;

  static TextStyle _questionStyle(Pill pill, double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.14,
    spacing: -0.3 - size * 0.018,
    color: pill.ink,
  );

  static TextStyle _promptStyle(Pill pill) => AppText.body(
    size: 12.5,
    weight: FontWeight.w500,
    color: pill.ink.withValues(alpha: 0.55),
  );

  /// The line under the input.
  String _prompt(BuildContext context) {
    final pill = widget.pill;
    return _pending != null
        ? (pill.isGraded
              ? context.l10n.beingRightMattersLess
              : context.l10n.writeItBeforeTheirs)
        // Nowhere to commit means this is a re-read, and telling someone to
        // commit to a card they answered days ago is just wrong. It used to
        // also tell an unanswered one to go and answer it on Today — which
        // the cards sitting behind the top of today's own deck were saying,
        // on Today, about themselves.
        : widget.onAnswer == null && widget.given != null
        ? context.l10n.youAnsweredThisOne
        : widget.prompt ??
              context.l10n.commitBeforeYouTurn(
                context.l10n.difficultyLabel(pill.difficulty.name),
              );
  }

  /// How tall the input is, or the step that takes its place once the
  /// reader has answered, whichever is taller: the question is sized once,
  /// and does not jump when the step comes.
  double _inputHeight(BuildContext context, double width, TextScaler scaler) {
    final pill = widget.pill;
    final double input = switch (pill.challenge) {
      PickOne(:final options) => _PickInput.heightFor(
        context,
        options,
        width,
        scaler,
      ),
      TakeASide(:final positions) => _PickInput.heightFor(
        context,
        positions,
        width,
        scaler,
      ),
      TypeNumber() => 54,
      Estimate() => PlaceItInput.heightFor(scaler),
      NoChallenge() => 0,
    };
    final double step = pill.isGraded
        ? _ConfidenceStep.heightFor(context, width, scaler)
        : _ReasonStep.heightFor(scaler);
    return math.max(input, step);
  }

  /// The gap above the line under the input: wide enough, where the card's
  /// save and share are in the corner, that nothing above it reaches them.
  double _footGapFor(double promptHeight) => widget.corner
      ? math.max(_footGap, _cornerClear - promptHeight)
      : _footGap;

  /// How tall the question may be.
  ///
  /// Its share of the face, as it always was: a proportion keeps the same
  /// composition from card to card. Unless what goes under it needs the
  /// room. On a small phone a three-answer card gave its question 48% of
  /// the face and pushed the last answer under the card's save and share,
  /// where a tap on it saved the card. The question gives way first, down
  /// to what it needs at its smallest size, because a question set smaller
  /// is still read, and an answer under a button is not. A face shorter
  /// than 520 points starts from 40%.
  double _questionRoom(
    BuildContext context,
    BoxConstraints box,
    double promptHeight,
  ) {
    final double height = box.maxHeight;
    final double width = box.maxWidth;
    if (!height.isFinite || !width.isFinite) return 0;
    final pill = widget.pill;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double share = height * (height < 520 ? 0.40 : 0.48);
    double below =
        22 +
        _inputHeight(context, width, scaler) +
        _footGapFor(promptHeight) +
        promptHeight;
    if (pill.hasHint) below += _hintGap + _hintRow;
    // At its smallest, as drawn: ScaledText never sets it smaller.
    final double needed =
        _measure(
          context,
          pill.question,
          _questionStyle(pill, 18),
          width,
          TextScaler.noScaling,
        ) +
        2;
    return (height - below).clamp(math.min(needed, share), share);
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final TextScaler scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final String prompt = _prompt(context);
        final double promptHeight = _measure(
          context,
          prompt,
          _promptStyle(pill),
          constraints.maxWidth - (widget.corner ? _CardControl.room : 0),
          scaler,
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The question takes its share of the card, or what the
                // answers leave it (see [_questionRoom]), and is set as large
                // as that will hold.
                SizedBox(
                  height: _questionRoom(context, constraints, promptHeight),
                  child: ScaledText(
                    text: pill.question,
                    min: 18,
                    max: 28,
                    alignment: Alignment.bottomLeft,
                    styleFor: (size) => _questionStyle(pill, size),
                  ),
                ),
                const SizedBox(height: 22),
                if (_pending == null)
                  widget.input(widget.onAnswer == null ? null : _commit)
                else if (pill.isGraded)
                  _ConfidenceStep(pill: pill, onPick: _finish)
                else
                  _ReasonStep(pill: pill, onSubmit: _finishReason),
                if (_pending == null && pill.hasHint) ...[
                  const SizedBox(height: _hintGap),
                  if (_hintOpen)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                      decoration: BoxDecoration(
                        color: pill.wash,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HINT',
                            style: AppText.label(
                              size: 10.5,
                              spacing: 1.2,
                              color: pill.ink.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            pill.hint,
                            style: AppText.body(
                              size: 14,
                              height: 1.4,
                              color: pill.ink.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // The words are the size of the line under the input;
                    // the target round them is a finger's.
                    Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _hintOpen = true);
                          // Asked for help: a card that needed a hint sat
                          // above the reader, and the dealer can hear that.
                          Analytics.capture('hint shown', {
                            'pill_id': widget.pill.id,
                            'topic': widget.pill.topic,
                          });
                          CardRead.of(context)?.hinted();
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _hintRow,
                          ),
                          child: Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 15,
                                  color: pill.ink.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  context.l10n.giveMeANudge,
                                  style: AppText.body(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: pill.ink.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                SizedBox(height: _footGapFor(promptHeight)),
                // Kept clear of the corner where the card's save and share
                // sit, so the line wraps rather than running under them.
                Padding(
                  padding: EdgeInsets.only(
                    right: widget.corner ? _CardControl.room : 0,
                  ),
                  child: Text(prompt, style: _promptStyle(pill)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One tap per option — the answer is the option's index.
class _PickInput extends StatelessWidget {
  final Pill pill;
  final List<String> options;
  final ValueChanged<String>? onAnswer;

  /// Which option was taken, on a card being re-read rather than answered.
  final int? taken;

  const _PickInput({
    required this.pill,
    required this.options,
    required this.onAnswer,
    this.taken,
  });

  /// How tall the options set at [width], as [_ChoiceButton] lays them:
  /// each one's words, its padding and its edge, and the gap between.
  static double heightFor(
    BuildContext context,
    List<String> options,
    double width,
    TextScaler scaler,
  ) {
    double total = 0;
    for (int i = 0; i < options.length; i++) {
      total +=
          _measure(
            context,
            options[i],
            _ChoiceButton.labelStyle(const Color(0xFF000000), false),
            width - 34,
            scaler,
          ) +
          30;
      if (i > 0) total += 9;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == options.length - 1 ? 0 : 9),
          child: _ChoiceButton(
            label: options[i],
            ink: pill.ink,
            fill: pill.wash,
            edge: pill.washEdge,
            taken: onAnswer == null && taken == i,
            onTap: onAnswer == null ? null : () => onAnswer!('$i'),
          ),
        );
      }),
    );
  }
}

/// Type the number you worked out. Nothing is graded until you commit, and an
/// empty box will not commit.
class _NumberInput extends StatefulWidget {
  final Pill pill;
  final String unit;
  final ValueChanged<String>? onAnswer;

  const _NumberInput({
    required this.pill,
    required this.unit,
    required this.onAnswer,
  });

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  /// The least width the hint is shown in: what the longest of its
  /// translations takes at the hint's size, with a little over.
  static const double _hintRoom = 104;

  final _controller = TextEditingController();

  /// How long the typed answer was a keystroke ago.
  int _typed = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// What was typed, read the way the reader's language writes numbers.
  String? get _reading => TypeNumber.read(
    _controller.text,
    locale: Localizations.localeOf(context).toString(),
  );

  bool get _ready => _reading != null;

  /// Digits taken back are the reader changing their mind before they
  /// commit — counted, never read: what was typed stays here.
  void _edited(String text) {
    final CardRead? read = CardRead.of(context);
    read?.changeable();
    if (text.length < _typed) read?.changed();
    _typed = text.length;
    setState(() {});
  }

  /// Kept in plain form, so the answer is graded the same way whatever
  /// language the reader typed it in.
  void _submit() {
    final String? reading = _reading;
    if (reading == null || widget.onAnswer == null) return;
    widget.onAnswer!(reading);
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final unit = widget.unit;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: pill.wash,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pill.washEdge),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, room) => TextField(
                      controller: _controller,
                      onChanged: _edited,
                      onSubmitted: (_) => _submit(),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w600,
                        color: pill.ink,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        // A hint only where it fits. Beside a long unit on
                        // a narrow phone the field is a few digits wide,
                        // and a hint cut short says less than none — the
                        // unit beside it already says what to type.
                        hintText: room.maxWidth >= _hintRoom
                            ? context.l10n.yourAnswer
                            : null,
                        hintStyle: AppText.body(
                          size: 14,
                          color: pill.ink.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                if (unit.isNotEmpty)
                  // Capped, because the unit is written with the card and the
                  // row is not. Most are a word — "days", "codes" — but a
                  // Fermi estimate counts "million journeys", and at a large
                  // text size, in a wide face, or on a narrow phone that is a
                  // label long enough to push the field it labels off the
                  // card. It gives up its own tail first.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 84),
                    child: Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        color: pill.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: context.l10n.checkMyAnswer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submit,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _ready ? 1 : 0.35,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: pill.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: pill.color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Color ink;
  final Color fill;
  final Color edge;
  final VoidCallback? onTap;

  /// True on the option this reader took, when the card is being looked at
  /// again rather than answered. Coming back to a question you have already
  /// answered and not being shown your own answer is the whole of what makes
  /// a re-read feel broken.
  final bool taken;

  const _ChoiceButton({
    required this.label,
    required this.ink,
    required this.fill,
    required this.edge,
    required this.onTap,
    this.taken = false,
  });

  static TextStyle labelStyle(Color ink, bool taken) => AppText.body(
    size: 14.5,
    weight: taken ? FontWeight.w600 : FontWeight.w500,
    height: 1.35,
    color: ink,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: taken,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: taken ? ink.withValues(alpha: 0.55) : edge,
              width: taken ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: labelStyle(ink, taken))),
              if (taken) ...[
                const SizedBox(width: 10),
                Text(
                  'YOURS',
                  style: AppText.label(
                    size: 9,
                    spacing: 1,
                    color: ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The step between answering and finding out: how sure are you?
///
/// This is the part that makes the app worth keeping. Being right is a fact
/// about one card; knowing how often you are right is a fact about you.
class _ConfidenceStep extends StatelessWidget {
  final Pill pill;
  final ValueChanged<int> onPick;

  const _ConfidenceStep({required this.pill, required this.onPick});

  /// How tall the step sets at [width]: the question, and the levels as
  /// they wrap.
  static double heightFor(
    BuildContext context,
    double width,
    TextScaler scaler,
  ) {
    final TextStyle chip = AppText.body(size: 15, weight: FontWeight.w600);
    final double chipHeight =
        _measure(context, '90%', chip, width, scaler) + 28;
    double row = 0;
    int rows = 1;
    for (final int level in kConfidenceLevels) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: '$level%', style: chip),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final double w = p.width + 38;
      p.dispose();
      if (row > 0 && row + 9 + w > width) {
        rows++;
        row = w;
      } else {
        row += (row > 0 ? 9 : 0) + w;
      }
    }
    return _measure(
          context,
          context.l10n.howSureAreYou,
          AppText.display(size: 19, weight: FontWeight.w600, spacing: -0.4),
          width,
          scaler,
        ) +
        14 +
        rows * chipHeight +
        (rows - 1) * 9;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.howSureAreYou,
          style: AppText.display(
            size: 19,
            weight: FontWeight.w600,
            spacing: -0.4,
            color: pill.ink,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: kConfidenceLevels.map((level) {
            return Semantics(
              button: true,
              label: context.l10n.percentSure(level),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(level),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: pill.wash,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: pill.washEdge),
                  ),
                  child: Text(
                    '$level%',
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: pill.ink,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// The ungraded card's second step: one line saying why, before the other
/// side is shown.
///
/// Skipping is allowed. A reader who is made to type before they are allowed
/// to turn the card over stops turning cards over.
class _ReasonStep extends StatefulWidget {
  final Pill pill;
  final ValueChanged<String> onSubmit;

  const _ReasonStep({required this.pill, required this.onSubmit});

  /// About how tall the step sets: the line asking why, two lines to write
  /// in, and the button.
  static double heightFor(TextScaler scaler) =>
      scaler.scale(14.5) * 1.3 +
      10 +
      scaler.scale(14.5) * 1.35 * 2 +
      24 +
      10 +
      46;

  @override
  State<_ReasonStep> createState() => _ReasonStepState();
}

class _ReasonStepState extends State<_ReasonStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final ink = pill.ink;
    final written = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.inOneLineWhy,
          style: AppText.body(
            size: 14.5,
            weight: FontWeight.w600,
            color: ink.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          decoration: BoxDecoration(
            color: pill.wash,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.body(size: 14.5, height: 1.35, color: ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: context.l10n.because,
              hintStyle: AppText.body(
                size: 14.5,
                color: ink.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSubmit(_controller.text.trim()),
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              written
                  ? context.l10n.nowShowMeTheOtherSide
                  : context.l10n.skipShowMeAnyway,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: pill.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What the reader committed to on an ungraded card, held next to what they
/// are about to read. Nothing is marked right: the point is that the line
/// they wrote is still visible while the other side makes its case.
class _YourLine extends StatelessWidget {
  final Pill pill;
  final Answer given;

  /// The side and the reason run together in one paragraph, for a back
  /// short of room.
  final bool short;
  const _YourLine({
    required this.pill,
    required this.given,
    this.short = false,
  });

  /// Set off by a rule down its left edge rather than boxed: it is the
  /// reader's own voice quoted back, and the one box on the back belongs to
  /// the line to keep.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(13, 2, 0, 2);
  static const double _rule = 2;

  static TextStyle _label(Color ink) =>
      AppText.label(size: 10, spacing: 1.3, color: ink.withValues(alpha: 0.55));
  static TextStyle _took(Color ink) =>
      AppText.body(size: 15, weight: FontWeight.w600, height: 1.3, color: ink);
  static TextStyle _reason(Color ink) =>
      AppText.body(size: 13.5, height: 1.4, color: ink.withValues(alpha: 0.75));

  /// How far the reader leant to the side, when it was leant to on a shelf
  /// rather than tapped: "firmly", "all the way".
  static String? _how(BuildContext context, Pill pill, Answer given) {
    final int? level = pill.isGraded ? null : leanLevel(given);
    return level == null ? null : context.l10n.leanHow('$level');
  }

  /// The side taken, run in after its label: one line where two would
  /// say no more.
  static TextSpan _tookSpan(
    String caps,
    Pill pill,
    Answer given, {
    String? how,
    bool short = false,
  }) => TextSpan(
    children: [
      TextSpan(text: '$caps  ', style: _label(pill.ink)),
      TextSpan(
        text: how == null
            ? pill.challenge.describe(given.response)
            : '${pill.challenge.describe(given.response)} · $how',
        style: _took(pill.ink),
      ),
      if (short && given.hasReason)
        TextSpan(text: '  "${given.reason!.trim()}"', style: _reason(pill.ink)),
    ],
  );

  /// The room the line takes at [width].
  static double heightFor(
    BuildContext context,
    Pill pill,
    Answer given,
    double width,
    TextScaler scaler, {
    bool short = false,
  }) {
    final inner = width - _padding.horizontal - _rule;
    double h(String text, TextStyle style) =>
        _measure(context, text, style, inner, scaler);

    final took = _measureSpan(
      context,
      _tookSpan(
        context.l10n.youTookCaps,
        pill,
        given,
        how: _how(context, pill, given),
        short: short,
      ),
      inner,
      scaler,
    );
    var total = _padding.vertical + took;
    if (given.hasReason && !short) {
      total += 6 + h('"${given.reason!.trim()}"', _reason(pill.ink));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ink = pill.ink;
    return Container(
      width: double.infinity,
      padding: _padding,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ink.withValues(alpha: 0.45), width: _rule),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            _tookSpan(
              context.l10n.youTookCaps,
              pill,
              given,
              how: _how(context, pill, given),
              short: short,
            ),
          ),
          if (given.hasReason && !short) ...[
            const SizedBox(height: 6),
            Text('"${given.reason!.trim()}"', style: _reason(ink)),
          ],
        ],
      ),
    );
  }
}

/// A control drawn on the card, in the card's own ink.
class _CardControl extends StatelessWidget {
  const _CardControl({
    required this.label,
    required this.icon,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color ink;
  final VoidCallback onTap;

  /// Where the pair sits from the card's corner, and the room the line
  /// beside it keeps clear inside the face's padding: the pair reaches 81
  /// points into it (17 + 44 + 4 + 44, less the padding of 28).
  static const double right = 17;
  static const double bottom = 15;
  static const double size = 44;
  static const double room = 88;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Icon(icon, size: 20, color: ink.withValues(alpha: 0.62)),
          ),
        ),
      ),
    );
  }
}
