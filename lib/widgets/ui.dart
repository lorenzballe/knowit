import 'package:flutter/material.dart';

import '../theme.dart';

/// The full-width dark pill button used as the primary action on almost every
/// screen in the flow.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = AppColors.ink,
    this.foreground = Colors.white,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.999,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background,
            disabledForegroundColor: foreground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            label,
            style: AppText.figtree(
              size: 15,
              weight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
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
          style: AppText.figtree(
            size: 13,
            weight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.5),
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
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.12),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 17,
            color: dark ? Colors.white : AppColors.ink,
          ),
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
      style: AppText.mono(
        size: 11,
        spacing: 1.3,
        color: color ?? Colors.black.withValues(alpha: 0.42),
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
                  style: AppText.mono(size: 10, color: labelColor),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
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
            color: value ? AppColors.ink : Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
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
