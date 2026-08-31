import 'package:flutter/material.dart';

import '../data/taste.dart';
import '../models/pill.dart';
import '../theme.dart';
import 'motion.dart';

/// Everything a card says once it is turned over: the reasoning, the trap,
/// the plain-words retelling and the other side of a debate.
///
/// This lives on its own because it is needed twice — on the back of a card
/// and on the detail screen reached from the archive — and the two drifted
/// apart. The detail screen was showing only `pill.answer`, which on a worked
/// problem is the last line of the solution and on a debate is one side of it.
class RevealBody extends StatefulWidget {
  final Pill pill;

  /// Text colour on whatever this is sitting on: the card's ink on a card,
  /// the app's ink on paper.
  final Color ink;

  /// Panel fill and edge to match.
  final Color wash;
  final Color washEdge;

  /// Called when the reader asks for more of the explanation than the card
  /// gave them. Wanting the longer version is about the closest thing to a
  /// stated preference the app gets without asking for one.
  final void Function(Signal)? onSignal;

  const RevealBody({
    super.key,
    required this.pill,
    required this.ink,
    required this.wash,
    required this.washEdge,
    this.onSignal,
  });

  /// The version that sits on a coloured card.
  factory RevealBody.onCard(
    Pill pill, {
    Key? key,
    void Function(Signal)? onSignal,
  }) => RevealBody(
    key: key,
    pill: pill,
    ink: pill.ink,
    wash: pill.wash,
    washEdge: pill.washEdge,
    onSignal: onSignal,
  );

  /// The version that sits on the page rather than on a card, so it takes
  /// its colours from the palette in force.
  factory RevealBody.onPage(Pill pill, Palette palette, {Key? key}) =>
      RevealBody(
        key: key,
        pill: pill,
        ink: palette.ink,
        wash: palette.line,
        washEdge: palette.lineStrong,
      );

  @override
  State<RevealBody> createState() => _RevealBodyState();
}

class _RevealBodyState extends State<RevealBody> {
  bool _simplyOpen = false;
  bool _counterOpen = false;

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pill.hasSteps)
          _Steps(pill: pill, ink: widget.ink)
        else
          Text(
            pill.answer,
            style: AppText.body(
              size: 16,
              height: 1.5,
              color: widget.ink.withValues(alpha: 0.92),
            ),
          ),
        if (pill.hasSimply) ...[
          const SizedBox(height: 14),
          if (_simplyOpen)
            _Panel(
              label: 'PUT SIMPLY',
              body: pill.simply,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.child_care_rounded,
              label: 'Explain it like I am three',
              onTap: () {
              setState(() => _simplyOpen = true);
              widget.onSignal?.call(Signal.explained);
            },
            ),
        ],
        if (pill.hasCounterpoint) ...[
          const SizedBox(height: 14),
          if (_counterOpen)
            _Panel(
              label: 'WHAT THE OTHER SIDE SAYS',
              body: pill.counterpoint,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.swap_horiz_rounded,
              label: 'What the other side says',
              onTap: () {
              setState(() => _counterOpen = true);
              widget.onSignal?.call(Signal.explained);
            },
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
              color: widget.ink.withValues(alpha: 0.75),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // The bar move is the reason to open the app at all, so it gets its
        // own panel rather than a line under a rule.
        _Panel(
          label: 'BAR MOVE',
          body: pill.barMove,
          ink: widget.ink,
          wash: widget.wash,
        ),
        const SizedBox(height: 13),
        Text(
          'Source · ${pill.source}',
          style: AppText.body(
            size: 11.5,
            color: widget.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// The solution, one move per line, so a long derivation stays followable.
class _Steps extends StatelessWidget {
  final Pill pill;
  final Color ink;
  const _Steps({required this.pill, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(pill.steps.length, (i) {
        // A derivation is read in order, so it lands in order. The delay is
        // an interval inside one controller rather than a timer, and it
        // defers to reduce-motion like everything else — see RiseIn.
        return RiseIn.staggered(
          i,
          step: const Duration(milliseconds: 90),
          child: Padding(
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
                    color: ink.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  pill.steps[i],
                  style: AppText.body(
                    size: 15,
                    height: 1.45,
                    color: ink.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      }),
    );
  }
}

/// A labelled panel — the shape the bar move, a retelling and a counterpoint
/// all take.
class _Panel extends StatelessWidget {
  final String label;
  final String body;
  final Color ink;
  final Color wash;

  const _Panel({
    required this.label,
    required this.body,
    required this.ink,
    required this.wash,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: wash,
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
              color: ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppText.body(
              size: 14,
              height: 1.45,
              color: ink.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// The closed state of one of those panels: an icon and a line to tap.
class _TextAction extends StatelessWidget {
  final Color ink;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TextAction({
    required this.ink,
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
            Icon(icon, size: 16, color: ink.withValues(alpha: 0.65)),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: ink.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
