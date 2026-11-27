import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/topics.dart';
import 'mix_screen.dart';
import '../theme.dart';
import '../widgets/subject_icon.dart';
import '../widgets/top_edge.dart' show SoftTop;
import '../widgets/ui.dart';

/// The topic picker. Doubles as onboarding step two and as the "Edit" sheet
/// reached from the profile — [isOnboarding] only changes the chrome.
class TopicsScreen extends StatefulWidget {
  final Set<String> initial;
  final ValueChanged<Set<String>> onDone;
  final VoidCallback? onBack;
  final bool isOnboarding;

  /// Opens the fine-tuning under the editor ([TuneScreen]) from the chips as
  /// they stand, and answers with the subjects in the mix once it is saved
  /// there — null if the reader came back without saving. Left null, the
  /// editor has no fine-tuning (the first run asks those on screens of
  /// their own).
  final Future<Set<String>?> Function(Set<String> picked)? onFineTune;

  const TopicsScreen({
    super.key,
    required this.initial,
    required this.onDone,
    this.onBack,
    this.isOnboarding = true,
    this.onFineTune,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  late Set<String> _picked = {...widget.initial};

  static const _minTopics = 3;

  /// The subjects on the grid that are picked. Thinking rides along in the
  /// set, never on the grid and never off the deck, and is not one of the
  /// reader's choices to count: twenty chips read "21 selected".
  int get _count =>
      kMixSubjects.where((subject) => _picked.contains(subject.key)).length;

  bool get _enough => _count >= _minTopics;

  Future<void> _fineTune() async {
    final Set<String>? after = await widget.onFineTune!({..._picked});
    if (after != null && mounted) setState(() => _picked = {...after});
  }

  /// Whether the page has a way back of its own: everywhere but the first
  /// run, which has its steps instead.
  bool get _backBar => !widget.isOnboarding && widget.onBack != null;

  @override
  Widget build(BuildContext context) {
    return ScreenView(
      name: 'topics',
      child: Scaffold(
        backgroundColor: context.p.surface,
        body: SafeArea(
          child: Column(
            children: [
              // The way back stays put above what scrolls: on iOS 26 it is
              // Apple's own glass button, a native view, and one inside a
              // scrolling page is drawn away from its place.
              if (_backBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BackCircle(onPressed: widget.onBack!),
                  ),
                ),
              // One page, scrolled whole: the title, the subjects, the way
              // into fine-tuning and the count, with only the button kept at
              // the foot. The subjects used to scroll in a box of their own
              // between a fixed title and a fixed row under them, and once
              // that row came the box was shorter than the subjects: a chip
              // was cut at its top or its foot on an ordinary phone.
              Expanded(
                child: Stack(
                  children: [
                    SoftTop(
                      child: SingleChildScrollView(
                        key: const ValueKey('topics-page'),
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isOnboarding)
                              Row(
                                children: List.generate(3, (i) {
                                  return Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        right: i == 2 ? 0 : 8,
                                      ),
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: i < 2
                                            ? context.p.ink
                                            : context.p.line,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            SizedBox(height: _backBar ? 10 : 22),
                            Text(
                              context.l10n.whatShouldWeTalkAbout,
                              style: AppText.display(
                                size: 33,
                                weight: FontWeight.w700,
                                height: 1.06,
                                spacing: -1.3,
                                color: context.p.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.l10n.fivePillsADayPick,
                              style: AppText.body(
                                size: 15,
                                height: 1.5,
                                color: context.p.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              // Every subject the onboarding offers, in its
                              // order, and every one of them switchable. Editing
                              // a mix while being shown a shorter list than the
                              // one you were first given is how a setting starts
                              // feeling like it lost something.
                              children: kMixSubjects.map((subject) {
                                final key = subject.key;
                                final on = _picked.contains(key);
                                return _TopicChip(
                                  label: context.l10n.subjectOf(subject.name),
                                  subject: subject.name,
                                  on: on,
                                  color: subject.color,
                                  onColor: inkOn(subject.color),
                                  onTap: () => setState(() {
                                    if (on) {
                                      _picked.remove(key);
                                    } else {
                                      _picked.add(key);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                            if (widget.onFineTune != null) ...[
                              const SizedBox(height: 18),
                              _FineTuneRow(onTap: _fineTune),
                            ],
                            // The count is said once, on the button.
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    // What runs on under the button fades into the page
                    // rather than stopping at a line.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 22,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                context.p.surface.withValues(alpha: 0),
                                context.p.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 20),
                child: PrimaryButton(
                  label: _enough
                      ? (widget.isOnboarding
                            ? context.l10n.startWithNTopics(_count)
                            : context.l10n.saveNTopics(_count))
                      : context.l10n.pickAtLeastN(_minTopics),
                  background: _enough ? context.p.ink : context.p.line,
                  foreground: _enough ? null : context.p.inkFaint,
                  onPressed: _enough ? () => widget.onDone(_picked) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;

  /// The subject's name as the cards carry it, for its mark.
  final String subject;
  final bool on;
  final Color color;
  final Color onColor;

  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.subject,
    required this.on,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        decoration: BoxDecoration(
          color: on ? color : context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? Colors.transparent : context.p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The subject's own mark, on or off, where a tick used to come
            // and go. Every chip carried the same tick, which said a chip
            // was on and nothing about what it was; on or off is the fill.
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SubjectIcon(
                subject: subject,
                size: 14,
                ink: on ? onColor : context.p.inkMuted,
              ),
            ),
            Text(
              label,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: on ? onColor : context.p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The way into the fine-tuning: how much of each subject, and which parts.
///
/// Under the chips, where the editor's question ends: the chips say which
/// subjects, this says how much and what of them — the two screens of the
/// first run after the one this page already is.
class _FineTuneRow extends StatelessWidget {
  const _FineTuneRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('topics-fine-tune'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: Row(
            children: [
              // Three bars at three lengths: the page it opens, in small.
              SizedBox(
                width: 34,
                height: 34,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (int i, double w) in const [
                      (0, 1.0),
                      (1, 0.62),
                      (2, 0.82),
                    ]) ...[
                      if (i > 0) const SizedBox(height: 4),
                      FractionallySizedBox(
                        widthFactor: w,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: kMixSubjects[i * 7].color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tuneTitle,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tuneEntryLine,
                      style: AppText.body(
                        size: 12.5,
                        height: 1.3,
                        color: p.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 22, color: p.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
