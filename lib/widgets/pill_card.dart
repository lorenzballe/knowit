import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../theme.dart';
import 'motion.dart';
import 'reveal_body.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying a Bar move line and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;
  final String indexLabel;
  final bool flipped;

  /// What the reader committed to, and where to send a new commitment.
  /// Null while untouched.
  final Answer? given;
  final void Function(String response, int? confidence, String? reason)?
  onAnswer;

  /// True when this card is in today's deck because it came back.
  final bool isReview;

  const PillCard({
    super.key,
    required this.pill,
    required this.indexLabel,
    required this.flipped,
    this.given,
    this.onAnswer,
    this.isReview = false,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    pill.topic.toUpperCase(),
                    style: AppText.label(
                      size: 11,
                      spacing: 1.4,
                      color: pill.ink.withValues(alpha: 0.72),
                    ),
                  ),
                  if (isReview) ...[
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
                        'AGAIN',
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
              Text(
                indexLabel,
                style: AppText.label(
                  size: 11,
                  color: pill.ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          Expanded(
            child: flipped
                ? _BackFace(pill: pill, given: given)
                // The challenge decides the front. A new kind of challenge
                // will not compile until it is given a face here.
                : switch (pill.challenge) {
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
                      prompt: 'Pick a side. There is no right answer.',
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
                    Estimate(:final unit) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      prompt: 'Estimate. Close enough counts.',
                      input: (commit) => _NumberInput(
                        pill: pill,
                        unit: unit,
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
    // A long question on a narrow card wraps to many lines, so the type steps
    // down on short cards and the whole face scrolls rather than overflowing.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tall = constraints.maxHeight;
        final size = tall < 260
            ? 24.0
            : tall < 340
            ? 28.0
            : tall < 460
            ? 34.0
            : 37.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tall),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pill.question,
                  style: AppText.display(
                    size: size,
                    weight: FontWeight.w600,
                    height: 1.12,
                    spacing: -1.0,
                    color: pill.ink,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap to reveal',
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    color: pill.ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackFace extends StatelessWidget {
  final Pill pill;
  final Answer? given;
  const _BackFace({required this.pill, this.given});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pill.isGraded && given != null) ...[
                PopIn(
                  delay: const Duration(milliseconds: 260),
                  child: _Verdict(
                    pill: pill,
                    right: pill.challenge.accepts(given!.response),
                    given: pill.challenge.describe(given!.response),
                    confidence: given!.confidence,
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (!pill.isGraded && given != null) ...[
                PopIn(
                  delay: const Duration(milliseconds: 260),
                  child: _YourLine(pill: pill, given: given!),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                pill.question,
                style: AppText.display(
                  size: pill.asksSomething ? 18 : 20,
                  weight: FontWeight.w600,
                  height: 1.28,
                  spacing: -0.4,
                  color: pill.ink,
                ),
              ),
              const SizedBox(height: 16),
              RevealBody.onCard(pill),
            ],
          ),
        ),
      ),
    );
  }
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

  String get _line {
    return switch (pill.challenge) {
      Estimate(:final answerLabel, :final band) =>
        right
            ? 'Close enough · it is $answerLabel'
            : 'You said $given · it is $answerLabel, and $band counted',
      // A wrong number is a slip; a wrong pick is usually the trap working.
      TypeNumber(:final answerLabel) =>
        right ? 'You got it' : 'You said $given · it is $answerLabel',
      _ => right ? 'You got it' : 'Almost everyone gets this wrong',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          right ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: pill.ink,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            confidence == null ? _line : '$_line · you said $confidence% sure',
            style: AppText.label(
              size: 11,
              spacing: 1.2,
              color: pill.ink.withValues(alpha: 0.85),
            ),
          ),
        ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pill.question,
                style: AppText.display(
                  size: constraints.maxHeight < 420 ? 21 : 25,
                  weight: FontWeight.w600,
                  height: 1.2,
                  spacing: -0.7,
                  color: pill.ink,
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
                    onTap: () => setState(() => _hintOpen = true),
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
                            'Give me a nudge',
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
                          ? 'Being right matters less than knowing how often '
                                'you are.'
                          : 'Write it before you read theirs.')
                    // Nowhere to commit means this is a re-read, and telling
                    // someone to commit to a card they answered days ago is
                    // just wrong.
                    : widget.onAnswer == null
                    ? (widget.given != null
                          ? 'You answered this one.'
                          : 'Answer this one on Today first.')
                    : widget.prompt ??
                          '${pill.difficulty.label} · commit before you turn '
                              'it over.',
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
                  child: TextField(
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
                      hintText: 'Your answer',
                      hintStyle: AppText.body(
                        size: 15,
                        color: pill.ink.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: AppText.body(
                      size: 14,
                      color: pill.ink.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Check my answer',
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
          'How sure are you?',
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
              label: '$level percent sure',
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
          'In one line — why?',
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
              hintText: 'Because…',
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
              written ? 'Now show me the other side' : 'Skip — show me anyway',
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
  const _YourLine({required this.pill, required this.given});

  @override
  Widget build(BuildContext context) {
    final ink = pill.ink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
      decoration: BoxDecoration(
        color: pill.wash,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pill.washEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOU TOOK',
            style: AppText.label(
              size: 10,
              spacing: 1.3,
              color: ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            pill.challenge.describe(given.response),
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              height: 1.3,
              color: ink,
            ),
          ),
          if (given.hasReason) ...[
            const SizedBox(height: 8),
            Text(
              '"${given.reason!.trim()}"',
              style: AppText.body(
                size: 13.5,
                height: 1.4,
                color: ink.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
