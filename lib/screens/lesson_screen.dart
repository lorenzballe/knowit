import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/motion.dart';
import '../widgets/reveal_body.dart';
import '../widgets/scaled_text.dart';
import '../widgets/ui.dart';

/// One run through a handful of cards.
///
/// The deck used to be a stack you flipped: you turned a card over and the
/// answer was simply there, with nothing between committing and knowing. That
/// reads as a reference book with a nice animation. A lesson instead answers
/// every commitment immediately and loudly — the bar comes up green or red,
/// says why, and the only way on is through it.
///
/// The confidence step is where this app differs from the game it borrows
/// from, and it is not a detour: the chips are the check button. Picking how
/// sure you are is what submits the answer, so the one thing worth measuring
/// gets measured on every card without adding a tap.
class LessonScreen extends StatefulWidget {
  final AppState app;
  final List<Pill> cards;
  final String title;

  const LessonScreen({
    super.key,
    required this.app,
    required this.cards,
    required this.title,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;

  /// The raw response for the card on screen, before it is submitted.
  String? _picked;
  final _typed = TextEditingController();
  final _reason = TextEditingController();

  /// Set once the card has been answered and the bar is up.
  bool _checked = false;
  bool _right = false;

  /// Facts have nothing to answer, so they just open.
  bool _factOpen = false;

  int _rightCount = 0;
  int _answered = 0;

  @override
  void dispose() {
    _typed.dispose();
    _reason.dispose();
    super.dispose();
  }

  Pill get _pill => widget.cards[_index];
  bool get _isLast => _index == widget.cards.length - 1;

  void _submit(int? confidence) {
    final pill = _pill;
    final response = pill.challenge is TypeNumber || pill.challenge is Estimate
        ? _typed.text.trim()
        : (_picked ?? '');
    if (response.isEmpty) return;

    final right = pill.isGraded && pill.challenge.accepts(response);
    widget.app.recordAnswer(
      pill.id,
      response,
      confidence: confidence,
      reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
    );

    if (right) {
      HapticFeedback.mediumImpact();
    } else if (pill.isGraded) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _checked = true;
      _right = right;
      if (pill.isGraded) {
        _answered++;
        if (right) _rightCount++;
      }
    });
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _LessonDone(
            app: widget.app,
            right: _rightCount,
            answered: _answered,
            cards: widget.cards.length,
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _picked = null;
      _checked = false;
      _right = false;
      _factOpen = false;
      _typed.clear();
      _reason.clear();
    });
  }

  Future<void> _confirmQuit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.p.surfaceRaised,
        title: Text(
          'Leave the lesson?',
          style: AppText.display(
            size: 19,
            weight: FontWeight.w700,
            color: context.p.ink,
          ),
        ),
        content: Text(
          'The cards you have already answered are kept.',
          style: AppText.body(size: 14, height: 1.4, color: context.p.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Stay',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: context.p.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Leave',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: context.p.alert,
              ),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pill = _pill;
    final done = (_index + (_checked ? 1 : 0)) / widget.cards.length;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Leave the lesson',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _confirmQuit,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 24,
                          color: context.p.inkFaint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _Bar(value: done)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: _CardBody(
                  key: ValueKey(pill.id),
                  pill: pill,
                  picked: _picked,
                  checked: _checked,
                  factOpen: _factOpen,
                  typed: _typed,
                  reason: _reason,
                  onPick: (v) => setState(() => _picked = v),
                  onTypedChanged: () => setState(() {}),
                ),
              ),
            ),
            _Footer(
              pill: pill,
              picked: _picked,
              typed: _typed.text.trim(),
              checked: _checked,
              right: _right,
              factOpen: _factOpen,
              isLast: _isLast,
              onOpenFact: () => setState(() => _factOpen = true),
              onSubmit: _submit,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

/// The thin bar that fills as the lesson goes by.
class _Bar extends StatelessWidget {
  final double value;
  const _Bar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 14,
          backgroundColor: context.p.line,
          valueColor: const AlwaysStoppedAnimation(AppColors.lime),
        ),
      ),
    );
  }
}

/// Everything above the footer: the question, and whatever it asks for.
class _CardBody extends StatelessWidget {
  final Pill pill;
  final String? picked;
  final bool checked;
  final bool factOpen;
  final TextEditingController typed;
  final TextEditingController reason;
  final ValueChanged<String> onPick;
  final VoidCallback onTypedChanged;

  const _CardBody({
    super.key,
    required this.pill,
    required this.picked,
    required this.checked,
    required this.factOpen,
    required this.typed,
    required this.reason,
    required this.onPick,
    required this.onTypedChanged,
  });

  @override
  Widget build(BuildContext context) {
    // A fact has nothing to answer, so it reads as a page.
    if (!pill.asksSomething) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('WORTH KNOWING'),
            const SizedBox(height: 12),
            Text(
              pill.question,
              style: AppText.display(
                size: 27,
                weight: FontWeight.w700,
                height: 1.15,
                spacing: -1,
                color: context.p.ink,
              ),
            ),
            if (factOpen) ...[
              const SizedBox(height: 18),
              RiseIn(child: RevealBody.onPage(pill, context.p)),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: ScaledText(
            text: pill.question,
            min: 17,
            max: 27,
            alignment: Alignment.topLeft,
            styleFor: (size) => AppText.display(
              size: size,
              weight: FontWeight.w700,
              height: 1.18,
              spacing: -0.5,
              color: context.p.ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            child: switch (pill.challenge) {
              PickOne(:final options) => _Options(
                labels: options,
                correct: (pill.challenge as PickOne).correct,
                picked: picked,
                checked: checked,
                graded: true,
                onPick: onPick,
              ),
              TakeASide(:final positions) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Options(
                    labels: positions,
                    correct: -1,
                    picked: picked,
                    checked: checked,
                    graded: false,
                    onPick: onPick,
                  ),
                  if (picked != null && !checked) ...[
                    const SizedBox(height: 4),
                    Text(
                      'In one line — why? (optional)',
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: context.p.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Field(
                      controller: reason,
                      hint: 'Because…',
                      lines: 2,
                      onChanged: onTypedChanged,
                    ),
                  ],
                ],
              ),
              TypeNumber(:final unit) || Estimate(:final unit) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                    controller: typed,
                    hint: 'Your answer',
                    suffix: unit,
                    number: true,
                    enabled: !checked,
                    onChanged: onTypedChanged,
                  ),
                  if (pill.hasHint && !checked) ...[
                    const SizedBox(height: 14),
                    _Hint(text: pill.hint),
                  ],
                ],
              ),
              NoChallenge() => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    );
  }
}

class _Options extends StatelessWidget {
  final List<String> labels;
  final int correct;
  final String? picked;
  final bool checked;
  final bool graded;
  final ValueChanged<String> onPick;

  const _Options({
    required this.labels,
    required this.correct,
    required this.picked,
    required this.checked,
    required this.graded,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(labels.length, (i) {
        final mine = picked == '$i';
        final state = !checked
            ? (mine ? ChoiceState.picked : ChoiceState.idle)
            : !graded
            ? (mine ? ChoiceState.picked : ChoiceState.idle)
            : i == correct
            ? ChoiceState.right
            : (mine ? ChoiceState.wrong : ChoiceState.idle);

        return ChunkyOption(
          label: labels[i],
          state: state,
          onTap: checked ? null : () => onPick('$i'),
        );
      }),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final bool number;
  final bool enabled;
  final int lines;
  final VoidCallback onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.suffix,
    this.number = false,
    this.enabled = true,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.p.lineStrong, width: 1.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: (_) => onChanged(),
              minLines: lines,
              maxLines: lines,
              keyboardType: number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              style: AppText.body(
                size: 16,
                weight: FontWeight.w600,
                height: 1.35,
                color: context.p.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hint,
                hintStyle: AppText.body(size: 16, color: context.p.inkFaint),
              ),
            ),
          ),
          if (suffix != null && suffix!.isNotEmpty)
            Text(
              suffix!,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: context.p.inkFaint,
              ),
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatefulWidget {
  final String text;
  const _Hint({required this.text});

  @override
  State<_Hint> createState() => _HintState();
}

class _HintState extends State<_Hint> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _open = true),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 17,
              color: context.p.inkMuted,
            ),
            const SizedBox(width: 7),
            Text(
              'Give me a nudge',
              style: AppText.body(
                size: 13.5,
                weight: FontWeight.w600,
                color: context.p.inkMuted,
              ),
            ),
          ],
        ),
      );
    }
    return RiseIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
        decoration: BoxDecoration(
          color: context.p.line,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          widget.text,
          style: AppText.body(size: 14, height: 1.45, color: context.p.ink),
        ),
      ),
    );
  }
}

/// The bottom of the screen, which is where the lesson actually happens.
///
/// Three things live here in turn: the ask, the confidence chips that submit
/// it, and the verdict. Keeping them in one place means the reader's thumb
/// never moves and the screen never jumps.
class _Footer extends StatelessWidget {
  final Pill pill;
  final String? picked;
  final String typed;
  final bool checked;
  final bool right;
  final bool factOpen;
  final bool isLast;
  final VoidCallback onOpenFact;
  final void Function(int? confidence) onSubmit;
  final VoidCallback onNext;

  const _Footer({
    required this.pill,
    required this.picked,
    required this.typed,
    required this.checked,
    required this.right,
    required this.factOpen,
    required this.isLast,
    required this.onOpenFact,
    required this.onSubmit,
    required this.onNext,
  });

  bool get _hasResponse =>
      pill.challenge is TypeNumber || pill.challenge is Estimate
      ? typed.isNotEmpty
      : picked != null;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: checked
          ? _Verdict(pill: pill, right: right, isLast: isLast, onNext: onNext)
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.p.line)),
              ),
              child: _ask(context),
            ),
    );
  }

  Widget _ask(BuildContext context) {
    if (!pill.asksSomething) {
      return ChunkyButton(
        label: factOpen ? (isLast ? 'FINISH' : 'CONTINUE') : 'SHOW ME',
        fill: AppColors.lime,
        ink: AppColors.limeInk,
        onPressed: factOpen ? onNext : onOpenFact,
      );
    }

    // An opinion cannot be right, so there is nothing to be sure about: it
    // goes straight through.
    if (!pill.isGraded) {
      return ChunkyButton(
        label: 'SEE THE OTHER SIDE',
        fill: AppColors.lime,
        ink: AppColors.limeInk,
        onPressed: _hasResponse ? () => onSubmit(null) : null,
      );
    }

    if (!_hasResponse) {
      return ChunkyButton(
        label: 'CHECK',
        fill: AppColors.lime,
        ink: AppColors.limeInk,
        onPressed: null,
      );
    }

    // Committed to an answer — now the only thing left is how sure, and
    // saying so is what submits it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How sure are you?',
          style: AppText.body(
            size: 13.5,
            weight: FontWeight.w700,
            spacing: 0.3,
            color: context.p.inkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final level in kConfidenceLevels) ...[
              Expanded(
                child: ChunkyButton(
                  label: '$level%',
                  height: 50,
                  radius: 13,
                  fill: context.p.surfaceRaised,
                  edge: context.p.lineStrong,
                  ink: context.p.ink,
                  onPressed: () => onSubmit(level),
                ),
              ),
              if (level != kConfidenceLevels.last) const SizedBox(width: 7),
            ],
          ],
        ),
      ],
    );
  }
}

/// The bar that comes up the moment an answer lands.
class _Verdict extends StatelessWidget {
  final Pill pill;
  final bool right;
  final bool isLast;
  final VoidCallback onNext;

  const _Verdict({
    required this.pill,
    required this.right,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final v = VerdictColours.of(context);
    final graded = pill.isGraded;
    final fill = !graded
        ? context.p.surfaceRaised
        : right
        ? v.rightFill
        : v.wrongFill;
    final ink = !graded
        ? context.p.ink
        : right
        ? v.rightInk
        : v.wrongInk;

    return RiseIn(
      distance: 26,
      duration: const Duration(milliseconds: 260),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        color: fill,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PopIn(
                  child: Icon(
                    !graded
                        ? Icons.forum_rounded
                        : right
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 26,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    !graded
                        ? 'You took a side'
                        : right
                        ? 'Got it.'
                        : 'Not this time.',
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w700,
                      spacing: -0.4,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 210),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (graded && !right && pill.hasTrap) ...[
                      Text(
                        pill.trap,
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.w600,
                          height: 1.4,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    RevealBody(
                      pill: pill,
                      ink: ink,
                      wash: ink.withValues(alpha: 0.08),
                      washEdge: ink.withValues(alpha: 0.18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ChunkyButton(
              label: isLast ? 'FINISH' : 'CONTINUE',
              fill: !graded || right ? AppColors.lime : ink,
              ink: !graded || right ? AppColors.limeInk : fill,
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

/// The end of a lesson. A run that stops on the last card and drops you back
/// where you started gives nothing to have finished.
class _LessonDone extends StatelessWidget {
  final AppState app;
  final int right;
  final int answered;
  final int cards;

  const _LessonDone({
    required this.app,
    required this.right,
    required this.answered,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = answered == 0 ? 0 : (right * 100 / answered).round();
    final xp = cards * 10 + right * 5;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              PopIn(
                child: Text(
                  'Lesson complete',
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    size: 32,
                    weight: FontWeight.w700,
                    height: 1.05,
                    spacing: -1.2,
                    color: context.p.ink,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      label: 'XP EARNED',
                      fill: AppColors.lime,
                      ink: AppColors.limeInk,
                      child: CountUp(
                        value: xp,
                        style: AppText.display(
                          size: 30,
                          weight: FontWeight.w700,
                          color: AppColors.limeInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Tile(
                      label: 'RIGHT',
                      fill: context.p.surfaceRaised,
                      ink: context.p.ink,
                      child: Text(
                        answered == 0 ? '—' : '$accuracy%',
                        style: AppText.display(
                          size: 30,
                          weight: FontWeight.w700,
                          color: context.p.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                answered == 0
                    ? 'Nothing to score on this one.'
                    : 'Being right is a fact about the card. How often you '
                          'are right is a fact about you — the profile keeps '
                          'that.',
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 13.5,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const Spacer(),
              ChunkyButton(
                label: 'DONE',
                fill: AppColors.lime,
                ink: AppColors.limeInk,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final Widget child;
  final Color fill;
  final Color ink;

  const _Tile({
    required this.label,
    required this.child,
    required this.fill,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: chunkyEdge(fill, 0.08), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppText.label(
              size: 10,
              spacing: 1.3,
              color: ink.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
