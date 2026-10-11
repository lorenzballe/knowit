import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/share_link.dart';
import '../utils/share_text.dart';

/// The day as five squares and a line, for a chat. Nothing in it that
/// spoils a card: which ones asked and how those went, never what.
class ShareDay extends StatelessWidget {
  const ShareDay({super.key, required this.app, required this.from});

  final AppState app;

  /// Where the day was sent from — the journey, or the finished day itself
  /// — so the numbers can say which of the two readers actually use.
  final String from;

  /// How the text is handed over. The platform's sheet in the app; under a
  /// test, which has no sheet and where the desktop stand-in never
  /// returns, whatever the test puts here.
  @visibleForTesting
  static Future<bool> Function(String text) share = shareText;

  /// What goes into the chat: the squares, how the questions went and how
  /// sure the reader was. The edition rather than the reader's day count,
  /// because the date is the thing two readers have in common.
  static String text(BuildContext context, AppState app) {
    final l = context.l10n;
    final d = app.daySummary;
    final verdict = [
      if (d.asked > 0) l.rightOfAsked(d.right, d.asked),
      if (d.sure != null) l.saidSure(d.sure!.round()),
    ].join(' · ');
    return [
      'Astute #${d.edition}${d.streak > 0 ? ' · \u{1f525}${d.streak}' : ''}',
      d.squares,
      if (verdict.isNotEmpty) verdict,
      ShareRef.day.link,
    ].join('\n');
  }

  /// Sends the day, from [from]: the platform's sheet, or the clipboard
  /// where there is none. The finished day has a button of its own, drawn
  /// the way the buttons on that screen are, and sends through this.
  static Future<void> send(
    BuildContext context,
    AppState app, {
    required String from,
  }) async {
    HapticFeedback.lightImpact();
    final String line = text(context, app);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final bool shared = await share(line);
    Analytics.capture('day shared', {
      'streak_days': app.streak,
      'edition': app.daySummary.edition,
      'as': shared ? 'sheet' : 'copied',
      'from': from,
    });
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
        onTap: () => send(context, app, from: from),
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
