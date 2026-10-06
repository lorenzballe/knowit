import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../theme.dart';

/// A card that only asks "true or false?": a pick with exactly those two
/// options. These are answered with a stamp rather than a list of buttons.
extension TrueOrFalse on Pill {
  bool get isTrueOrFalse => switch (challenge) {
    PickOne(:final options) =>
      options.length == 2 &&
          options.map((o) => o.trim().toLowerCase()).toSet().containsAll(const {
            'true',
            'false',
          }),
    _ => false,
  };

  /// The claim itself, without the "True or false:" in front of it: the
  /// stamps already ask that.
  String get claim {
    final m = RegExp(
      r'^\s*true\s+or\s+false\s*[:,?.-]?\s*',
      caseSensitive: false,
    ).firstMatch(question);
    if (m == null || !isTrueOrFalse) return question;
    final rest = question.substring(m.end);
    return rest.isEmpty ? question : rest[0].toUpperCase() + rest.substring(1);
  }

  /// The option index that means "true".
  int get trueIndex => switch (challenge) {
    PickOne(:final options) => options.indexWhere(
      (o) => o.trim().toLowerCase() == 'true',
    ),
    _ => -1,
  };
}

/// A rubber stamp: a word in heavy capitals inside a double rule, set at an
/// angle, in the card's ink.
class Stamp extends StatelessWidget {
  const Stamp({
    super.key,
    required this.label,
    required this.ink,
    this.size = 22,
    this.angle = -0.14,
  });

  final String label;
  final Color ink;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.all(size * 0.14),
        decoration: BoxDecoration(
          border: Border.all(color: ink, width: size * 0.12),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.5,
            vertical: size * 0.12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: size * 0.05),
            borderRadius: BorderRadius.circular(size * 0.18),
          ),
          child: Text(
            label,
            style: AppText.display(
              size: size,
              weight: FontWeight.w900,
              height: 1.05,
              spacing: size * 0.06,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// True or false, answered by bringing a stamp down: two stamps side by
/// side; the one tapped presses in, lands at an angle, and the answer is in.
class StampInput extends StatefulWidget {
  const StampInput({
    super.key,
    required this.pill,
    required this.onAnswer,
    this.taken,
  });

  final Pill pill;
  final ValueChanged<String>? onAnswer;

  /// The option already taken, on a card being re-read.
  final int? taken;

  @override
  State<StampInput> createState() => _StampInputState();
}

class _StampInputState extends State<StampInput>
    with SingleTickerProviderStateMixin {
  int? _chosen;
  late final AnimationController _press =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 460),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && _chosen != null) {
          widget.onAnswer?.call('$_chosen');
        }
      });

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _pick(int index) {
    if (_chosen != null || widget.onAnswer == null) return;
    HapticFeedback.heavyImpact();
    setState(() => _chosen = index);
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onAnswer!('$index');
    } else {
      _press.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final t = pill.trueIndex;
    Widget one(int index, String label, double angle) {
      final chosen = _chosen == index || widget.taken == index;
      final other = (_chosen ?? widget.taken) != null && !chosen;
      return Expanded(
        child: Semantics(
          button: widget.onAnswer != null,
          selected: chosen,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pick(index),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: other ? 0.25 : 1,
              child: Container(
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pill.wash,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: pill.washEdge),
                ),
                child: AnimatedBuilder(
                  animation: _press,
                  builder: (context, child) {
                    // Lifted, then brought down hard: bigger and tilted
                    // further, settling to its angle with a small bounce.
                    final v = chosen && _chosen != null
                        ? Curves.easeOutBack.transform(_press.value)
                        : 1.0;
                    return Transform.scale(
                      scale: chosen && _chosen != null ? 1.5 - 0.5 * v : 1,
                      child: Opacity(
                        opacity:
                            (chosen && _chosen != null ? 0.4 + 0.6 * v : 1.0)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                        child: child,
                      ),
                    );
                  },
                  child: Stamp(
                    label: label,
                    ink: pill.ink,
                    size: 22,
                    angle: chosen ? angle : 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        one(t, 'TRUE', -0.16),
        const SizedBox(width: 12),
        one(1 - t, 'FALSE', 0.12),
      ],
    );
  }
}
