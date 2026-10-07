import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../analytics.dart';
import '../models/pill.dart';
import '../theme.dart';
import 'hold_to_keep.dart';
import 'motion.dart';
import 'place_it.dart';
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

  const PillCard({
    super.key,
    required this.pill,
    this.indexLabel,
    required this.flipped,
    this.given,
    this.onAnswer,
    this.isReview = false,
    this.isOwn = false,
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
        if (onSave != null)
          Positioned(
            right: 20,
            bottom: 18,
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
    return Container(
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 60,
            offset: Offset(0, 24),
          ),
        ],
      ),
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
                    pill.topic.toUpperCase(),
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
          Expanded(
            child: flipped
                ? _BackFace(
                    pill: pill,
                    given: given,
                    cornerRoom: onSave != null ? 88 : 0,
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
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: box.maxHeight * 0.27,
            child: ScaledText(
              text: pill.question,
              min: 18,
              max: 27,
              alignment: Alignment.topLeft,
              styleFor: (size) => AppText.display(
                size: size,
                weight: FontWeight.w600,
                height: 1.12,
                spacing: -0.3 - size * 0.018,
                color: pill.ink,
              ),
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
      ),
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
    if (given != null && pill.isGraded) {
      final verdict = _Verdict(
        pill: pill,
        right: pill.challenge.accepts(given.response),
        given: pill.challenge.describe(given.response),
        confidence: given.confidence,
      );
      final line = verdict.text(context);
      lead = Column(
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
      leadHeight = (width, scaler) =>
          _Verdict.heightFor(context, line, pill.ink, width, scaler) +
          (estimate != null ? 6 + PlaceItReveal.height : 0);
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

/// Right or wrong, said plainly at the top of the reveal.
class _Verdict extends StatelessWidget {
  final Pill pill;
  final bool right;
  final String given;
  final int? confidence;
  const _Verdict({
    required this.pill,
    required this.right,
    required this.given,
    this.confidence,
  });

  static TextStyle _style(Color ink) =>
      AppText.label(size: 11, spacing: 1.2, color: ink.withValues(alpha: 0.85));

  /// The verdict as it is printed, confidence and all.
  String text(BuildContext context) => confidence == null
      ? _line(context)
      : context.l10n.lineYouSaidSure(_line(context), confidence!);

  /// The room the verdict takes at [width]: its words beside the mark.
  static double heightFor(
    BuildContext context,
    String text,
    Color ink,
    double width,
    TextScaler scaler,
  ) {
    final h = _measure(context, text, _style(ink), width - 26, scaler);
    return h > 18 ? h : 18;
  }

  String _line(BuildContext context) {
    return switch (pill.challenge) {
      Estimate(:final answerLabel, :final band) =>
        right
            ? context.l10n.closeEnoughItIs(answerLabel)
            : context.l10n.youSaidItIsCounted(given, answerLabel, band),
      // A wrong number is a slip; a wrong pick is usually the trap working.
      TypeNumber(:final answerLabel) =>
        right
            ? context.l10n.youGotIt
            : context.l10n.youSaidItIs(given, answerLabel),
      _ =>
        right
            ? context.l10n.youGotIt
            : context.l10n.almostEveryoneGetsThisWrong,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The words say right or wrong; the mark repeats it in shape.
        ExcludeSemantics(
          child: Icon(
            right ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: pill.ink,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(text(context), style: _style(pill.ink))),
      ],
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

  const _AskFace({
    required this.pill,
    required this.input,
    required this.onAnswer,
    this.prompt,
    this.given,
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

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The question takes a fixed share of the card and is set as
              // large as that share will hold. A share rather than whatever
              // the options leave over, because the leftover needs their
              // intrinsic height — which a LayoutBuilder cannot give — and
              // because a proportion keeps the same composition across every
              // card instead of inventing one per question length.
              SizedBox(
                height: constraints.maxHeight * 0.48,
                child: ScaledText(
                  text: pill.question,
                  min: 18,
                  max: 28,
                  alignment: Alignment.bottomLeft,
                  styleFor: (size) => AppText.display(
                    size: size,
                    weight: FontWeight.w600,
                    height: 1.14,
                    spacing: -0.3 - size * 0.018,
                    color: pill.ink,
                  ),
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
                const SizedBox(height: 12),
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _hintOpen = true);
                      // Asked for help: a card that needed a hint sat
                      // above the reader, and the dealer can hear that.
                      Analytics.capture('hint shown', {
                        'pill_id': widget.pill.id,
                        'topic': widget.pill.topic,
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                          color: pill.ink.withValues(alpha: 0.65),
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
              ],
              const SizedBox(height: 14),
              Text(
                _pending != null
                    ? (pill.isGraded
                          ? context.l10n.beingRightMattersLess
                          : context.l10n.writeItBeforeTheirs)
                    // Nowhere to commit means this is a re-read, and telling
                    // someone to commit to a card they answered days ago is
                    // just wrong. It used to also tell an unanswered one to
                    // go and answer it on Today — which the cards sitting
                    // behind the top of today's own deck were saying, on
                    // Today, about themselves.
                    : widget.onAnswer == null && widget.given != null
                    ? context.l10n.youAnsweredThisOne
                    : widget.prompt ??
                          context.l10n.commitBeforeYouTurn(
                            context.l10n.difficultyLabel(pill.difficulty.name),
                          ),
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: pill.ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _ready => TypeNumber.parse(_controller.text) != null;

  void _submit() {
    if (!_ready || widget.onAnswer == null) return;
    widget.onAnswer!(_controller.text.trim());
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
                      onChanged: (_) => setState(() {}),
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
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    size: 14.5,
                    weight: taken ? FontWeight.w600 : FontWeight.w500,
                    height: 1.35,
                    color: ink,
                  ),
                ),
              ),
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

  /// The side taken, run in after its label: one line where two would
  /// say no more.
  static TextSpan _tookSpan(
    String caps,
    Pill pill,
    Answer given, {
    bool short = false,
  }) => TextSpan(
    children: [
      TextSpan(text: '$caps  ', style: _label(pill.ink)),
      TextSpan(
        text: pill.challenge.describe(given.response),
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
      _tookSpan(context.l10n.youTookCaps, pill, given, short: short),
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
            _tookSpan(context.l10n.youTookCaps, pill, given, short: short),
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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: ink.withValues(alpha: 0.62)),
        ),
      ),
    );
  }
}
