import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../models/pill.dart';
import '../sync/reports.dart';
import '../theme.dart';
import 'diagram_view.dart';
import 'motion.dart';
import 'report_sheet.dart';

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

  /// A worked solution one step at a time, the first time it is turned
  /// over; whole, when it is looked at again from the archive.
  final bool stepByStep;

  const RevealBody({
    super.key,
    required this.pill,
    required this.ink,
    required this.wash,
    required this.washEdge,
    this.stepByStep = false,
  });

  /// The version that sits on a coloured card.
  factory RevealBody.onCard(Pill pill, {Key? key}) => RevealBody(
    key: key,
    pill: pill,
    ink: pill.ink,
    wash: pill.wash,
    washEdge: pill.washEdge,
    stepByStep: true,
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
          _Steps(pill: pill, ink: widget.ink, stepByStep: widget.stepByStep)
        else
          Text(
            pill.answer,
            style: AppText.body(
              size: 16,
              height: 1.5,
              color: widget.ink.withValues(alpha: 0.92),
            ),
          ),
        // The picture comes right after the words it illustrates, and is
        // drawn while they are being read.
        if (pill.diagram != null) ...[
          const SizedBox(height: 18),
          DiagramView(diagram: pill.diagram!, ink: widget.ink),
        ],
        if (pill.hasSimply) ...[
          const SizedBox(height: 14),
          if (_simplyOpen)
            _Panel(
              label: context.l10n.putSimplyCaps,
              body: pill.simply,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.child_care_rounded,
              label: context.l10n.explainLikeImThree,
              onTap: () => setState(() => _simplyOpen = true),
            ),
        ],
        if (pill.hasCounterpoint) ...[
          const SizedBox(height: 14),
          if (_counterOpen)
            _Panel(
              label: context.l10n.whatTheOtherSideSaysCaps,
              body: pill.counterpoint,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.swap_horiz_rounded,
              label: context.l10n.whatTheOtherSideSays,
              onTap: () => setState(() => _counterOpen = true),
            ),
        ],
        if (pill.asksSomething && pill.trap.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.theTrap(pill.trap),
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
          label: context.l10n.barMoveCaps,
          body: pill.barMove,
          ink: widget.ink,
          wash: widget.wash,
        ),
        // What the card is for: the lesson turned into a question about the
        // reader's own life, to carry through the day.
        if (pill.ask.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Panel(
            label: context.l10n.askYourselfCaps,
            body: pill.ask,
            ink: widget.ink,
            wash: widget.wash,
          ),
        ],
        const SizedBox(height: 13),
        Text(
          context.l10n.sourceLabel(pill.source),
          style: AppText.body(
            size: 11.5,
            color: widget.ink.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        _ReportLine(pill: pill, ink: widget.ink),
      ],
    );
  }
}

/// "Report a problem", under the source it would be checked against; once
/// this phone has reported the card, a quiet line saying so instead.
class _ReportLine extends StatefulWidget {
  final Pill pill;
  final Color ink;
  const _ReportLine({required this.pill, required this.ink});

  @override
  State<_ReportLine> createState() => _ReportLineState();
}

class _ReportLineState extends State<_ReportLine> {
  @override
  void initState() {
    super.initState();
    Reports.instance.load();
  }

  Future<void> _open() async {
    final bool? sent = await showReportSheet(context, widget.pill);
    if (sent != true || !mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.reportSentToast),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = widget.pill.id;
    return ListenableBuilder(
      listenable: Reports.instance,
      builder: (context, _) {
        if (!Reports.instance.has(id)) {
          return _TextAction(
            key: ValueKey('report-$id'),
            ink: widget.ink,
            icon: Icons.outlined_flag_rounded,
            label: context.l10n.reportProblem,
            onTap: _open,
          );
        }
        return Row(
          key: ValueKey('reported-$id'),
          children: [
            Icon(
              Icons.check_rounded,
              size: 16,
              color: widget.ink.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                context.l10n.reportedThanks,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: widget.ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The solution, one move at a time: the first step is shown, and each tap
/// brings the next one in under it, joined by a line, so a derivation is
/// followed rather than skimmed. "Show all" is there for the reader who
/// would rather see it whole.
class _Steps extends StatefulWidget {
  final Pill pill;
  final Color ink;
  final bool stepByStep;
  const _Steps({
    required this.pill,
    required this.ink,
    required this.stepByStep,
  });

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  late int _shown = widget.stepByStep ? 1 : widget.pill.steps.length;

  @override
  Widget build(BuildContext context) {
    final steps = widget.pill.steps;
    final ink = widget.ink;
    final all = _shown >= steps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _shown && i < steps.length; i++)
          RiseIn(
            key: ValueKey('step-$i'),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == _shown - 1 && !all
                                ? ink
                                : ink.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AppText.label(
                              size: 10.5,
                              spacing: 0,
                              color: i == _shown - 1 && !all
                                  ? widget.pill.color
                                  : ink.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        if (i < _shown - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: ink.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 1,
                        bottom: i == _shown - 1 ? 0 : 14,
                      ),
                      child: Text(
                        steps[i],
                        style: AppText.body(
                          size: 15,
                          height: 1.45,
                          color: ink.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!all) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                button: true,
                child: GestureDetector(
                  key: const ValueKey('next-step'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _shown++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${context.l10n.nextStep}  ${_shown + 1}/${steps.length}',
                      style: AppText.body(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: widget.pill.color,
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _shown = steps.length),
                  child: Text(
                    context.l10n.showAllSteps,
                    style: AppText.body(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: ink.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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
    super.key,
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
