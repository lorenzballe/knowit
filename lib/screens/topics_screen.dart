import 'package:flutter/material.dart';

import '../data/topics.dart';
import 'mix_screen.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// The topic picker. Doubles as onboarding step two and as the "Edit" sheet
/// reached from the profile — [isOnboarding] only changes the chrome.
class TopicsScreen extends StatefulWidget {
  final Set<String> initial;
  final ValueChanged<Set<String>> onDone;
  final VoidCallback? onBack;
  final bool isOnboarding;

  const TopicsScreen({
    super.key,
    required this.initial,
    required this.onDone,
    this.onBack,
    this.isOnboarding = true,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  late final Set<String> _picked = {...widget.initial};

  static const _minTopics = 3;

  bool get _enough => _picked.length >= _minTopics;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isOnboarding)
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i < 2 ? context.p.ink : context.p.line,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    );
                  }),
                )
              else if (widget.onBack != null)
                BackCircle(onPressed: widget.onBack!),
              const SizedBox(height: 22),
              Text(
                'What should we talk about?',
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
                'Five pills a day, written fresh each morning. Pick the '
                'topics you want in the mix — you can change them later.',
                style: AppText.body(
                  size: 15,
                  height: 1.5,
                  color: context.p.inkMuted,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    // Every subject the onboarding offers, in its order —
                    // including the ones with no cards behind them yet, which
                    // simply cannot be switched on. Editing a mix while being
                    // shown a shorter list than the one you were first given
                    // is how a setting starts feeling like it lost something.
                    children: kMixSubjects.map((subject) {
                      final key = subject.key;
                      final servable = key != null;
                      final on = servable && _picked.contains(key);
                      return _TopicChip(
                        label: subject.name,
                        on: on,
                        color: subject.color,
                        onColor: inkOn(subject.color),
                        enabled: servable,
                        onTap: !servable
                            ? null
                            : () => setState(() {
                                if (on) {
                                  _picked.remove(key);
                                } else {
                                  _picked.add(key);
                                }
                              }),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  '${_picked.length} selected',
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 12.5, color: context.p.inkFaint),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _enough
                    ? (widget.isOnboarding
                          ? 'Start with ${_picked.length} topics'
                          : 'Save ${_picked.length} topics')
                    : 'Pick at least $_minTopics',
                background: _enough ? context.p.ink : context.p.line,
                foreground: _enough ? null : context.p.inkFaint,
                onPressed: _enough ? () => widget.onDone(_picked) : null,
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
  final bool on;
  final Color color;
  final Color onColor;

  /// Null for a subject that has no cards behind it yet: it is shown, so the
  /// list is the one the onboarding gave, but there is nothing to switch on.
  final VoidCallback? onTap;
  final bool enabled;

  const _TopicChip({
    required this.label,
    required this.on,
    required this.color,
    required this.onColor,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: on ? color : context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on
                ? Colors.transparent
                : context.p.line.withValues(alpha: enabled ? 1 : 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: on ? 1 : 0,
              child: Icon(Icons.check_rounded, size: 13, color: onColor),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w500,
                color: on
                    ? onColor
                    : context.p.inkMuted.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ),
            // A control that does nothing when pressed and gives no reason is
            // worse than one that is absent. These subjects are coming; the
            // chip says so rather than leaving the reader to work out why
            // their tap did nothing.
            if (!enabled) ...[
              const SizedBox(width: 7),
              Text(
                'soon',
                style: AppText.label(
                  size: 9.5,
                  spacing: 0.8,
                  color: context.p.inkFaint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
