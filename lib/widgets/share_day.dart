import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/share_text.dart';

/// The day as five squares and a line, for a chat. Nothing in it that
/// spoils a card: which ones asked and how those went, never what.
class ShareDay extends StatelessWidget {
  const ShareDay({super.key, required this.app});

  final AppState app;

  /// How the text is handed over. The platform's sheet in the app; under a
  /// test, which has no sheet and where the desktop stand-in never
  /// returns, whatever the test puts here.
  @visibleForTesting
  static Future<bool> Function(String text) share = shareText;

  /// What goes into the chat. The edition rather than the reader's day
  /// count, because the edition is the thing two readers have in common.
  static String text(BuildContext context, AppState app) {
    final l = context.l10n;
    final d = app.daySummary;
    // The question of the day on its own line: it is the one card the
    // reader and the friend have in common, so it is the one line that
    // can be compared.
    final String? question = questionLine(l, d.questionRight, d.questionSure);
    final verdict = [
      if (d.asked > 0) l.rightOfAsked(d.right, d.asked),
      if (d.sure != null) l.saidSure(d.sure!.round()),
    ].join(' · ');
    return [
      'Astut #${d.edition}${d.streak > 0 ? ' · \u{1f525}${d.streak}' : ''}',
      d.squares,
      if (question != null) '${l.todaysQuestion}: $question',
      if (verdict.isNotEmpty) verdict,
      'lorenzballe.github.io/knowit',
    ].join('\n');
  }

  /// "right, 80% sure" — or null when the question was not answered.
  static String? questionLine(AppLocalizations l, bool? right, int? sure) {
    if (right == null) return null;
    if (sure == null) return right ? l.right : l.wrong;
    return right ? l.rightAtSure(sure) : l.wrongAtSure(sure);
  }

  Future<void> _share(BuildContext context) async {
    HapticFeedback.lightImpact();
    final String line = text(context, app);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final bool shared = await share(line);
    if (shared) return;
    // No sheet to hand it to — a browser, a desktop — so it is copied,
    // which is one paste away from the same chat.
    await Clipboard.setData(ClipboardData(text: line));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.copiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.shareMyDay,
      child: GestureDetector(
        key: const ValueKey('share-day'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _share(context),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: context.p.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ios_share_rounded, size: 15, color: context.p.ink),
              const SizedBox(width: 7),
              Text(
                context.l10n.shareMyDay,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: context.p.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
