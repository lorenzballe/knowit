import 'package:flutter/material.dart';

import '../data/topics.dart';
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
      backgroundColor: AppColors.paper,
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
                          color: i < 2
                              ? AppColors.ink
                              : Colors.black.withValues(alpha: 0.12),
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
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Five pills a day, written fresh each morning. Pick the '
                'topics you want in the mix — you can change them later.',
                style: AppText.body(
                  size: 15,
                  height: 1.5,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: kTopicOrder.map((key) {
                      final style = kTopics[key]!;
                      final on = _picked.contains(key);
                      return _TopicChip(
                        label: style.name,
                        on: on,
                        color: style.color,
                        onColor: style.ink,
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
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  '${_picked.length} of ${kTopicOrder.length} selected',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 12.5,
                    color: Colors.black.withValues(alpha: 0.42),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _enough
                    ? (widget.isOnboarding
                          ? 'Start with ${_picked.length} topics'
                          : 'Save ${_picked.length} topics')
                    : 'Pick at least $_minTopics',
                background: _enough
                    ? AppColors.ink
                    : Colors.black.withValues(alpha: 0.12),
                foreground: _enough
                    ? Colors.white
                    : Colors.black.withValues(alpha: 0.35),
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
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: on ? color : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.12),
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
                color: on ? onColor : Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
