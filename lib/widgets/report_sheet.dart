import 'package:flutter/material.dart';

import '../data/pill_bank.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../sync/reports.dart';
import '../theme.dart';
import 'ui.dart';

/// Opens "what's wrong with this card?" for [pill]. True when a report
/// was sent.
Future<bool?> showReportSheet(BuildContext context, Pill pill) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => ReportSheet(pill: pill),
  );
}

/// The sheet: a reason from a short list, a line if the reader wants to
/// add one, and Send. Public so the fit test can lay it out in every
/// language.
class ReportSheet extends StatefulWidget {
  final Pill pill;
  const ReportSheet({super.key, required this.pill});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final TextEditingController _note = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _label(BuildContext context, ReportReason reason) {
    final l = context.l10n;
    return switch (reason) {
      ReportReason.fact => l.reportFact,
      ReportReason.answer => l.reportAnswer,
      ReportReason.source => l.reportSource,
      ReportReason.unclear => l.reportUnclear,
      ReportReason.typo => l.reportTypo,
      ReportReason.other => l.reportOther,
    };
  }

  void _send() {
    final ReportReason? reason = _reason;
    if (reason == null) return;
    // Filed and marked at once; the write goes when the network lets it.
    Reports.instance.send(
      CardReport(card: widget.pill.id, reason: reason, note: _note.text),
      topic: widget.pill.topic,
      locale: Localizations.localeOf(context).toLanguageTag(),
      bank: PillBank.version,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    // The reasons that apply: "the answer marked right" only on a card
    // that marks one.
    final List<ReportReason> reasons = [
      for (final ReportReason r in ReportReason.values)
        if (r != ReportReason.answer || widget.pill.isGraded) r,
    ];
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom +
            MediaQuery.viewInsetsOf(context).bottom +
            22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.reportTitle,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.reportLead,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 16),
            for (final ReportReason r in reasons) ...[
              _Reason(
                key: ValueKey('report-reason-${r.wire}'),
                label: _label(context, r),
                chosen: _reason == r,
                onTap: () => setState(() => _reason = r),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('report-note'),
              controller: _note,
              maxLength: CardReport.noteLimit,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.body(size: 15, height: 1.35, color: p.ink),
              decoration: InputDecoration(
                hintText: l.reportNoteHint,
                hintStyle: AppText.body(size: 15, color: p.inkFaint),
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: p.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: p.line),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const ValueKey('report-send'),
              label: l.reportSend,
              height: 52,
              onPressed: _reason == null ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// One reason, as a row to tap: a ring, filled once it is the one.
class _Reason extends StatelessWidget {
  final String label;
  final bool chosen;
  final VoidCallback onTap;

  const _Reason({
    super.key,
    required this.label,
    required this.chosen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = chosen ? p.onInverse : p.ink;
    return Semantics(
      button: true,
      selected: chosen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: chosen ? p.inverse : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: chosen ? p.inverse : p.line),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink.withValues(alpha: 0.6)),
                ),
                alignment: Alignment.center,
                child: chosen
                    ? Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ink,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w500,
                    height: 1.3,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
