import 'package:flutter/material.dart';

import '../models/pill.dart';
import '../theme.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying a Bar move line and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;
  final String indexLabel;
  final bool flipped;

  /// What the reader committed to, and where to send a new commitment.
  /// Null while untouched.
  final String? given;
  final ValueChanged<String>? onAnswer;

  const PillCard({
    super.key,
    required this.pill,
    required this.indexLabel,
    required this.flipped,
    this.given,
    this.onAnswer,
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
              Text(
                pill.topic.toUpperCase(),
                style: AppText.label(
                  size: 11,
                  spacing: 1.4,
                  color: pill.ink.withValues(alpha: 0.72),
                ),
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
                      input: _PickInput(
                        pill: pill,
                        options: options,
                        onAnswer: onAnswer,
                      ),
                    ),
                    TakeASide(:final positions) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      prompt: 'Pick a side. There is no right answer.',
                      input: _PickInput(
                        pill: pill,
                        options: positions,
                        onAnswer: onAnswer,
                      ),
                    ),
                    TypeNumber(:final unit) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      input: _NumberInput(
                        pill: pill,
                        unit: unit,
                        onAnswer: onAnswer,
                      ),
                    ),
                    Estimate(:final unit) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      prompt: 'Estimate. Close enough counts.',
                      input: _NumberInput(
                        pill: pill,
                        unit: unit,
                        onAnswer: onAnswer,
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

class _BackFace extends StatefulWidget {
  final Pill pill;
  final String? given;
  const _BackFace({required this.pill, this.given});

  @override
  State<_BackFace> createState() => _BackFaceState();
}

class _BackFaceState extends State<_BackFace> {
  bool _simplyOpen = false;
  bool _counterOpen = false;

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final given = widget.given;

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
                _Verdict(
                  pill: pill,
                  right: pill.challenge.accepts(given),
                  given: pill.challenge.describe(given),
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
              if (pill.hasSteps)
                _Steps(pill: pill)
              else
                Text(
                  pill.answer,
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w400,
                    height: 1.5,
                    color: pill.ink.withValues(alpha: 0.92),
                  ),
                ),
              if (pill.hasSimply) ...[
                const SizedBox(height: 14),
                if (_simplyOpen)
                  _Panel(pill: pill, label: 'PUT SIMPLY', body: pill.simply)
                else
                  _TextAction(
                    pill: pill,
                    icon: Icons.child_care_rounded,
                    label: 'Explain it like I am three',
                    onTap: () => setState(() => _simplyOpen = true),
                  ),
              ],
              if (pill.hasCounterpoint) ...[
                const SizedBox(height: 14),
                if (_counterOpen)
                  _Panel(
                    pill: pill,
                    label: 'WHAT THE OTHER SIDE SAYS',
                    body: pill.counterpoint,
                  )
                else
                  _TextAction(
                    pill: pill,
                    icon: Icons.swap_horiz_rounded,
                    label: 'What the other side says',
                    onTap: () => setState(() => _counterOpen = true),
                  ),
              ],
              if (pill.asksSomething && pill.trap.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'The trap: ${pill.trap}',
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w500,
                    height: 1.45,
                    color: pill.ink.withValues(alpha: 0.75),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // The bar move is the reason to open the app at all, so it gets
              // its own panel rather than a line under a rule.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                decoration: BoxDecoration(
                  color: pill.wash,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BAR MOVE',
                      style: AppText.label(
                        size: 10.5,
                        spacing: 1.2,
                        color: pill.ink.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      pill.barMove,
                      style: AppText.body(
                        size: 14.5,
                        weight: FontWeight.w500,
                        height: 1.4,
                        color: pill.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Source · ${pill.source}',
                style: AppText.body(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: pill.ink.withValues(alpha: 0.6),
                ),
              ),
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
  const _Verdict({
    required this.pill,
    required this.right,
    required this.given,
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
            _line,
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

/// The solution, one move per line, so a long derivation stays followable.
class _Steps extends StatelessWidget {
  final Pill pill;
  const _Steps({required this.pill});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(pill.steps.length, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == pill.steps.length - 1 ? 0 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '${i + 1}',
                  style: AppText.label(
                    size: 11,
                    height: 1.55,
                    color: pill.ink.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  pill.steps[i],
                  style: AppText.body(
                    size: 15,
                    height: 1.45,
                    color: pill.ink.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// A card that asks before it tells: the question, whatever input the
/// challenge needs, and an optional nudge for when the reader is stuck.
class _AskFace extends StatefulWidget {
  final Pill pill;
  final Widget input;
  final ValueChanged<String>? onAnswer;

  /// Overrides the default line under the input, so a debate does not tell
  /// the reader to commit to a right answer that does not exist.
  final String? prompt;

  const _AskFace({
    required this.pill,
    required this.input,
    required this.onAnswer,
    this.prompt,
  });

  @override
  State<_AskFace> createState() => _AskFaceState();
}

class _AskFaceState extends State<_AskFace> {
  bool _hintOpen = false;

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
              widget.input,
              if (pill.hasHint) ...[
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
                widget.prompt ??
                    '${pill.difficulty.label} · commit before you turn it over.',
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

  const _PickInput({
    required this.pill,
    required this.options,
    required this.onAnswer,
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

  const _ChoiceButton({
    required this.label,
    required this.ink,
    required this.fill,
    required this.edge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: edge),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 14.5,
              weight: FontWeight.w500,
              height: 1.35,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled panel on the card — the shape a hint, a plain-words retelling
/// and a counterpoint all take.
class _Panel extends StatelessWidget {
  final Pill pill;
  final String label;
  final String body;

  const _Panel({required this.pill, required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: pill.wash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label(
              size: 10.5,
              spacing: 1.2,
              color: pill.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.body(
              size: 14,
              height: 1.45,
              color: pill.ink.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// The closed state of one of those panels: an icon and a line to tap.
class _TextAction extends StatelessWidget {
  final Pill pill;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TextAction({
    required this.pill,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 16, color: pill.ink.withValues(alpha: 0.65)),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
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
    );
  }
}
