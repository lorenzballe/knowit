import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/topics.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/subject_icon.dart';
import 'mix_screen.dart';

/// The one question after the mix: of the subjects you pushed up, how much
/// do you already know?
///
/// The mix says how much of a subject a day should hold. This says what
/// kind of card it should hold: somebody solid on a subject should be
/// asked, somebody new to it should be told. Three answers, no more —
/// "curious", "some", "solid" — because a finer scale is a form, and the
/// reader is one tap from their first cards.
///
/// It is also the first thing the app knows about the reader that the
/// reader said in words rather than showed, and the thing a writer of
/// cards would most want to be told.
class KnowScreen extends StatefulWidget {
  const KnowScreen({
    super.key,
    required this.app,
    required this.onDone,
    this.onSkip,
    this.onBack,
  });

  final AppState app;
  final ValueChanged<Map<String, int>> onDone;

  /// Onboarding offers a way past; editing later does not need one.
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  /// At most this many subjects are asked about — the ones pushed highest.
  static const int asked = 8;

  /// The levels a reader can claim, in order.
  static const List<String> levels = ['Curious', 'Some', 'Solid'];

  @override
  State<KnowScreen> createState() => _KnowScreenState();
}

class _KnowScreenState extends State<KnowScreen> {
  late final List<MixSubject> _subjects = _pick();
  late final Map<String, int> _level = {
    for (final s in _subjects) s.key: widget.app.topicLevels[s.key] ?? 1,
  };

  /// The subjects pushed highest in the mix, canvas order breaking ties —
  /// so a reader who left everything up is asked about the first eight
  /// rather than about all eighteen.
  List<MixSubject> _pick() {
    final weights = widget.app.topicWeights;
    final inMix = weights.isEmpty
        ? kMixSubjects.toList()
        : kMixSubjects.where((s) => (weights[s.key] ?? 0) > 0).toList();
    final order = {
      for (var i = 0; i < kMixSubjects.length; i++) kMixSubjects[i].key: i,
    };
    inMix.sort((a, b) {
      final int byWeight = (weights[b.key] ?? 0).compareTo(weights[a.key] ?? 0);
      return byWeight != 0 ? byWeight : order[a.key]!.compareTo(order[b.key]!);
    });
    return inMix.take(KnowScreen.asked).toList();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final bool onboarding = widget.onSkip != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          safe.top > 54 ? safe.top : 54,
          18,
          22 + (safe.bottom > 34 ? safe.bottom - 34 : 0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onBack != null) ...[
              // This screen is black in either theme, like the mix it
              // follows, so the arrow is drawn white here rather than in
              // the palette's ink.
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Back',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // A Wrap, not a Row: the last word can drop to a second line
            // on a narrow screen or a wide font rather than run off the
            // edge.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  context.l10n.whatYouAlready,
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w600,
                    height: 1.04,
                    spacing: -1,
                    color: Colors.white,
                  ),
                ),
                SpectrumWord(context.l10n.know),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              context.l10n.knowIntro,
              style: AppText.body(
                size: 13.5,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.48),
              ),
            ),
            const SizedBox(height: 18),
            // Eight rows fit a phone without moving; the scroll view is
            // the net for anything shorter, and on a phone it never scrolls.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final subject in _subjects) ...[
                      _Row(
                        subject: subject,
                        level: _level[subject.key]!,
                        onPick: (v) => setState(() => _level[subject.key] = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            _Button(
              label: onboarding
                  ? context.l10n.startWithMyFirstCards
                  : context.l10n.save,
              onTap: () => widget.onDone(_level),
            ),
            if (onboarding) ...[
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onSkip,
                child: Text(
                  context.l10n.skipForNow,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One subject, and the three things you can say about it.
class _Row extends StatelessWidget {
  const _Row({
    required this.subject,
    required this.level,
    required this.onPick,
  });

  final MixSubject subject;
  final int level;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SubjectIcon(subject: subject.name, size: 15, ink: subject.color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            subject.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < KnowScreen.levels.length; i++)
                Semantics(
                  key: ValueKey('know-${subject.key}-$i'),
                  button: true,
                  selected: level == i,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onPick(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: level == i ? subject.color : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        switch (i) {
                          0 => context.l10n.levelCurious,
                          1 => context.l10n.levelSome,
                          _ => context.l10n.levelSolid,
                        },
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: level == i
                              ? inkOn(subject.color)
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Button extends StatefulWidget {
  const _Button({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            widget.label,
            style: AppText.body(
              size: 16,
              weight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
