import 'package:flutter/material.dart';

import '../theme.dart';
import 'chunky.dart';

/// The app's primary action.
///
/// This is now a thin naming over [ChunkyButton]. Screens built before the
/// lesson existed called this, and the lesson calls the chunky one, so the
/// app was pressing two different kinds of button depending on which week a
/// screen was written in — which is exactly the sort of thing that reads as
/// unfinished without anybody being able to say why. Rewriting the shared
/// widget rather than every call site means no screen can be left behind.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  /// Defaults to the palette's reversed pair, so the primary action is dark
  /// on a light page and light on a dark one without every caller saying so.
  final Color? background;
  final Color? foreground;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      label: label,
      height: height,
      fill: background ?? context.p.inverse,
      ink: foreground ?? context.p.onInverse,
      onPressed: onPressed,
    );
  }
}

/// Text-only secondary action, centred under the primary button.
class QuietButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const QuietButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppText.body(
            size: 13,
            weight: FontWeight.w500,
            color: context.p.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Circular back chevron in a hairline ring, top-left of the sub-screens.
class BackCircle extends StatelessWidget {
  final VoidCallback onPressed;
  final bool dark;
  const BackCircle({super.key, required this.onPressed, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.p.line),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.arrow_back_rounded, size: 17, color: context.p.ink),
        ),
      ),
    );
  }
}

/// Small uppercase monospace label used as a section eyebrow.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.label(
        size: 11,
        spacing: 1.3,
        color: color ?? context.p.inkFaint,
      ),
    );
  }
}

/// The 7-day streak strip shown on the recap, the profile and the come-back
/// screen.
class WeekStrip extends StatelessWidget {
  final List<bool> week;
  final Color onColor;
  final Color offColor;
  final Color labelColor;
  final double barHeight;

  const WeekStrip({
    super.key,
    required this.week,
    this.onColor = AppColors.lime,
    this.offColor = const Color(0x14000000),
    this.labelColor = const Color(0x59000000),
    this.barHeight = 38,
  });

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    // The strip always ends on today, so line the letters up with real days.
    final todayWeekday = DateTime.now().weekday; // 1 = Monday
    return Row(
      children: List.generate(7, (i) {
        final weekdayIndex = (todayWeekday - 1 - (6 - i)) % 7;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 6),
            child: Column(
              children: [
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: week[i] ? onColor : offColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _letters[weekdayIndex < 0 ? weekdayIndex + 7 : weekdayIndex],
                  style: AppText.label(size: 10, color: labelColor),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// White rounded card with a hairline border — the default surface on paper.
class PaperCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.p.line),
      ),
      child: child,
    );
  }
}

/// Rounded square colour swatch that stands in for a topic.
class TopicDot extends StatelessWidget {
  final Color color;
  final double size;
  const TopicDot(this.color, {super.key, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// The iOS-style switch used by the daily nudge row.
class NudgeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const NudgeSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Daily nudge',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? context.p.ink : context.p.lineStrong,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: context.p.surfaceRaised,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// A page body that behaves like a full-height Column — `Spacer` and friends
/// still work — but scrolls instead of overflowing once the viewport gets
/// shorter than the content.
class FlexPage extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const FlexPage({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight - padding.vertical;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: available > 0 ? available : 0,
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
