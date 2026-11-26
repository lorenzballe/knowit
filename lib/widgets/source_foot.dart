/// The foot of a card's back — the way into Go deeper, with where the card's
/// facts come from after it — where "Report a problem" lives once it is off
/// the card's face, and the way back to Why this card.
///
/// Being tried (November 2026), three ways, for the owner to choose between.
/// The foot read "Source · Geopop · YouTube, 2021", underlined in dots, and
/// nobody could tell that a tap on it opened Go deeper. Each way here leads
/// with the sheet's own name, Go deeper, in a firmer weight and with a
/// chevron, and says where the facts come from after it, quieter, without
/// the word Source: what follows is plainly the origin. None of them reaches
/// into the corner the save and share sit in.
///
/// The flag that reported a card rode at the end of that line, on the card's
/// face, and a drawn card had none. Each way puts reporting where a reader
/// goes looking for it instead, in the app's own sheets, which a drawn card
/// reaches exactly as a card in words does: its page says `deeper` when its
/// source is tapped (lib/widgets/web/page_messages.dart, PageDeeper), and its
/// save and share are the app's. Holding a card was not used: a hold is
/// already the card's like (hold_to_keep.dart).
///
/// Why this card (why_sheet.dart) had one door, the line under a card's
/// head, and since the line was kept for the reasons that say something (a
/// move the reader misses, a card back for another go, their goal, chance),
/// most cards had no way to it. Each way brings it back on every card of
/// the day: beside Go deeper on the back, as a line or as a second pill, or
/// on the front, as the line under the head that every card carries again.
///
/// A drawn card's page draws the same three, once the kit has them (tried on
/// a scratch copy of docs/cards/kit/astute-card.js, not on the kit the app
/// ships): the app tells the page which, and Go deeper's and Why this card's
/// names in the reader's language, through [PageEnv]'s `foot`, `deeper` and
/// `why`; the page says `deeper` or `why` when they are tapped.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../sync/reports.dart';
import '../theme.dart';
import 'report_sheet.dart';

/// The three ways of setting the foot.
enum SourceFoot {
  /// "Go deeper ›" in a firmer weight and the source after it, one line
  /// that wraps like a sentence, the card's whole width; "Why this card ›"
  /// under it, beside the save and share. To report: the foot of Go deeper,
  /// under the source the card would be checked against.
  line,

  /// "Go deeper ›" on a line of its own, a size up, and the source under
  /// it; Why this card on the front, the line under the head every card of
  /// the day carries again. To report: the share sheet, where a feed keeps
  /// it.
  stack,

  /// "Go deeper ›" in a small pill of the card's own wash, "Why this card ›"
  /// in an outlined one beside it, the source under them beside the save
  /// and share. To report: a flag in Go deeper's head, beside the sheet's
  /// name, seen the moment it opens.
  pill,
}

/// The way being tried. `line` unless the build names another
/// (`--dart-define=SOURCE_FOOT=stack` or `pill`), which is how the camera,
/// tool/source_shots.dart, photographs all three; changing the default
/// here changes it for good.
const String _sourceFootName = String.fromEnvironment(
  'SOURCE_FOOT',
  defaultValue: 'line',
);
const SourceFoot sourceFoot = _sourceFootName == 'stack'
    ? SourceFoot.stack
    : _sourceFootName == 'pill'
    ? SourceFoot.pill
    : SourceFoot.line;

/// Opens "what's wrong with this card?" for [pill], and says it went:
/// with a word at the foot of the screen when the sheet it was asked from
/// is closed for it ([closing]), and otherwise by the line or the flag that
/// asked, which now says it was reported.
Future<void> reportFrom(
  BuildContext context,
  Pill pill, {
  bool closing = false,
}) async {
  HapticFeedback.selectionClick();
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String thanks = context.l10n.reportSentToast;
  final bool? sent = await showReportSheet(context, pill);
  if (sent != true || !closing || !context.mounted) return;
  Navigator.of(context).pop();
  messenger?.showSnackBar(
    SnackBar(content: Text(thanks), duration: const Duration(seconds: 2)),
  );
}

/// "Report a problem" as a quiet line in one of the app's sheets — the foot
/// of Go deeper, the share sheet — and, once this phone has reported the
/// card, "Reported. Thank you." in its place.
class ReportLine extends StatefulWidget {
  const ReportLine({
    super.key,
    required this.pill,
    this.closing = false,
    this.centred = false,
  });

  final Pill pill;

  /// Whether the sheet it sits in closes once the report has gone.
  final bool closing;

  /// Set in the middle of its sheet, as the share sheet's last line is.
  final bool centred;

  @override
  State<ReportLine> createState() => _ReportLineState();
}

class _ReportLineState extends State<ReportLine> {
  @override
  void initState() {
    super.initState();
    Reports.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String id = widget.pill.id;
    return ListenableBuilder(
      listenable: Reports.instance,
      builder: (context, _) {
        final bool done = Reports.instance.has(id);
        final Color colour = done ? p.inkFaint : p.inkMuted;
        final Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_rounded : Icons.outlined_flag_rounded,
              size: 16,
              color: colour,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                done ? context.l10n.reportedThanks : context.l10n.reportProblem,
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: colour,
                ),
              ),
            ),
          ],
        );
        final Widget line = Align(
          alignment: widget.centred
              ? Alignment.center
              : AlignmentDirectional.centerStart,
          child: done
              ? Semantics(
                  key: ValueKey('reported-line-$id'),
                  label: context.l10n.reportedThanks,
                  child: ExcludeSemantics(child: row),
                )
              : Semantics(
                  button: true,
                  label: context.l10n.reportProblem,
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      key: ValueKey('report-line-$id'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => reportFrom(
                        context,
                        widget.pill,
                        closing: widget.closing,
                      ),
                      // The words are small; the target round them is a
                      // finger's.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: row,
                      ),
                    ),
                  ),
                ),
        );
        return done
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: line,
              )
            : line;
      },
    );
  }
}

/// "Report a problem" as a small flag in Go deeper's head, beside the
/// sheet's name, in the head's own ink; a tick once this phone has
/// reported the card.
class ReportFlag extends StatefulWidget {
  const ReportFlag({super.key, required this.pill, required this.ink});

  final Pill pill;
  final Color ink;

  /// How wide and tall the flag's round is; its target is a finger's.
  static const double round = 30;

  @override
  State<ReportFlag> createState() => _ReportFlagState();
}

class _ReportFlagState extends State<ReportFlag> {
  @override
  void initState() {
    super.initState();
    Reports.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final String id = widget.pill.id;
    final Color ink = widget.ink;
    return ListenableBuilder(
      listenable: Reports.instance,
      builder: (context, _) {
        final bool done = Reports.instance.has(id);
        final Widget mark = Container(
          width: ReportFlag.round,
          height: ReportFlag.round,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ink.withValues(alpha: done ? 0.08 : 0.12),
          ),
          alignment: Alignment.center,
          child: Icon(
            done ? Icons.check_rounded : Icons.outlined_flag_rounded,
            size: 17,
            color: ink.withValues(alpha: done ? 0.55 : 0.82),
          ),
        );
        if (done) {
          return Semantics(
            key: ValueKey('reported-flag-$id'),
            label: context.l10n.reportedThanks,
            child: ExcludeSemantics(child: mark),
          );
        }
        return Semantics(
          button: true,
          label: context.l10n.reportProblem,
          child: ExcludeSemantics(
            child: Tooltip(
              message: context.l10n.reportProblem,
              child: GestureDetector(
                key: ValueKey('report-flag-$id'),
                behavior: HitTestBehavior.opaque,
                onTap: () => reportFrom(context, widget.pill),
                child: Padding(padding: const EdgeInsets.all(7), child: mark),
              ),
            ),
          ),
        );
      },
    );
  }
}
