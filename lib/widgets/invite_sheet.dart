/// Invita un amico, as the reader meets it (lib/sync/invite.dart): the sheet
/// that sends a friend the reader's code, the sheet where a friend's code is
/// typed — or arrives from its link — and the moment a week is given, on the
/// screen a purchase ends on, saying plainly that nothing was bought.
///
/// Calm, as the profile is: a title in the display face, one line under it,
/// the code large on its own card, one button. Free time and nothing else:
/// no price, no money, nothing asked of the reader but to read a day.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../screens/purchase_success_screen.dart';
import '../state/app_state.dart';
import '../sync/invite.dart';
import '../theme.dart';
import '../utils/share_link.dart';
import 'balanced_text.dart';
import 'ui.dart';

/// Whether the invitation shows at all: the server's switch on, a build
/// that can take part, and invitations set up on the server.
bool inviteShown(AppState app) {
  final Invites invites = Invites.instance;
  return app.inviteOn && invites.reachable && !invites.unconfigured;
}

/// The message a friend is sent: a line in the reader's language and the
/// link with the code on a line of its own. Once the reader's weeks for the
/// year are all given ([capped]) it promises the friend's week alone.
String inviteMessage(AppLocalizations l, String code, {bool capped = false}) {
  final String link = inviteLink(code);
  return capped
      ? l.inviteMessageCapped(code, link)
      : l.inviteMessage(code, link);
}

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: builder,
    );

/// The sheet's own ground: the page's colour, rounded at the top, with the
/// handle, and the keyboard's room under it.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          MediaQuery.paddingOf(context).bottom + 18,
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
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _title(BuildContext context) => AppText.display(
  size: 22,
  weight: FontWeight.w600,
  height: 1.15,
  spacing: -0.6,
  color: context.p.ink,
);

TextStyle _line(BuildContext context) =>
    AppText.body(size: 14, height: 1.45, color: context.p.inkMuted);

// ── Sending the reader's code ────────────────────────────────────────────

/// The reader's code and the way to send it: made on the server the first
/// time it is asked for.
Future<void> showInviteSheet(BuildContext context, AppState app) =>
    _sheet<void>(context, (_) => InviteSheet(app: app));

/// The sheet: the week for the two of them, how, the code, the year's weeks
/// so far, and Send. Public so a test can lay it out.
class InviteSheet extends StatefulWidget {
  const InviteSheet({super.key, required this.app});

  final AppState app;

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  bool _asking = true;
  bool _failed = false;

  /// The code was copied: said beside it, in the sheet, where it is seen.
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _asking = true;
      _failed = false;
    });
    final InviteState? state = await Invites.instance.refresh(make: true);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _failed = state?.code == null;
    });
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _copied = true);
  }

  Future<void> _send(InviteState state) async {
    final String? code = state.code;
    if (code == null) return;
    final AppLocalizations l = context.l10n;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    final String text = inviteMessage(l, code, capped: state.capped);
    final bool shared = await sendText(text);
    Analytics.capture('invite sent', {
      'as': shared ? 'link' : 'copied',
      'weeks': state.weeks,
      'friends': state.friends,
      'capped': state.capped,
    });
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      messenger?.showSnackBar(SnackBar(content: Text(l.copiedToClipboard)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final Palette p = context.p;
    return ListenableBuilder(
      listenable: Invites.instance,
      builder: (context, _) {
        final InviteState? state = Invites.instance.state;
        final String? code = state?.code;
        return _SheetFrame(
          key: const ValueKey('invite-sheet'),
          children: [
            BalancedText(l.inviteRowLine, style: _title(context)),
            const SizedBox(height: 8),
            Text(l.inviteSheetLine, style: _line(context)),
            const SizedBox(height: 18),
            _CodeCard(
              label: l.inviteYourCode,
              code: code,
              asking: _asking && code == null,
              failed: _failed && code == null,
              onRetry: _load,
              trailing: code == null
                  ? null
                  : _TextAction(
                      key: const ValueKey('invite-copy'),
                      label: l.inviteCopy,
                      done: _copied,
                      onTap: () => _copy(code),
                    ),
            ),
            if (state != null && state.weeks > 0) ...[
              const SizedBox(height: 12),
              Text(
                l.inviteWeeksSoFar(state.weeks, state.cap),
                key: const ValueKey('invite-weeks'),
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w600,
                  height: 1.35,
                  color: p.ink,
                ),
              ),
            ],
            if (state != null && state.capped) ...[
              const SizedBox(height: 4),
              Text(
                l.inviteCapped(state.cap),
                style: AppText.body(size: 13, height: 1.4, color: p.inkMuted),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              key: const ValueKey('invite-send'),
              label: l.inviteSend,
              height: 52,
              onPressed: code == null ? null : () => _send(state!),
            ),
            const SizedBox(height: 12),
            Text(
              l.inviteRules(state?.cap ?? 8),
              style: AppText.body(size: 12, height: 1.45, color: p.inkFaint),
            ),
          ],
        );
      },
    );
  }
}

/// A code on a card of its own, large, in the display face, spaced so each
/// character stands alone; while it is asked for, a quiet wheel; when the
/// server could not be reached, the line that says so, and Try again.
class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.label,
    required this.code,
    this.asking = false,
    this.failed = false,
    this.onRetry,
    this.trailing,
  });

  final String label;
  final String? code;
  final bool asking;
  final bool failed;
  final VoidCallback? onRetry;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String? code = this.code;
    final Widget body;
    if (code != null) {
      body = Text(
        code,
        key: const ValueKey('invite-code'),
        style: AppText.display(
          size: 34,
          weight: FontWeight.w600,
          height: 1.1,
          spacing: 5,
          color: p.ink,
        ),
      );
    } else if (failed) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRetry,
        child: Text.rich(
          TextSpan(
            text: '${context.l10n.deeperTryAgain} ',
            children: [
              TextSpan(
                text: context.l10n.tryAgain,
                style: TextStyle(
                  color: p.link,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
        ),
      );
    } else {
      body = SizedBox(
        height: 37,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: asking ? p.inkMuted : p.inkFaint,
            ),
          ),
        ),
      );
    }
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 16),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Eyebrow(label), const SizedBox(height: 8), body],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// A word that does something, beside the code: underlined, the link's
/// colour, with a finger's room around it.
class _TextAction extends StatelessWidget {
  const _TextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.done = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Done once: a tick before the word.
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.link;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 2, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(Icons.check_rounded, size: 17, color: ink),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── A friend's code ──────────────────────────────────────────────────────

/// Where a friend's code is used: typed, or brought by its link ([code],
/// [from] `link`). A code that gives the week at once — the first day
/// already read — closes the sheet on the week's moment.
Future<void> showInviteCodeSheet(
  BuildContext context,
  AppState app, {
  String? code,
  required String from,
}) async {
  final InviteTaken? taken = await _sheet<InviteTaken>(
    context,
    (_) => InviteCodeSheet(app: app, code: code, from: from),
  );
  if (taken != null && taken.granted && context.mounted) {
    await showInviteWeekIfDue(context, app, settle: false);
  }
}

/// The sheet: the field, the button, the server's answer under it; once a
/// code is taken and waits on the first day, what happens next. Public so a
/// test can lay it out.
class InviteCodeSheet extends StatefulWidget {
  const InviteCodeSheet({
    super.key,
    required this.app,
    this.code,
    required this.from,
  });

  final AppState app;
  final String? code;
  final String from;

  @override
  State<InviteCodeSheet> createState() => _InviteCodeSheetState();
}

class _InviteCodeSheetState extends State<InviteCodeSheet> {
  late final TextEditingController _field = TextEditingController(
    text: readInviteCode(widget.code) ?? '',
  );
  bool _asking = false;
  String? _said;
  bool _accepted = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String? _refusal(AppLocalizations l, InviteRefusal why) => switch (why) {
    InviteRefusal.unknown => l.inviteRefusedUnknown,
    InviteRefusal.own => l.inviteRefusedOwn,
    InviteRefusal.used => l.inviteRefusedUsed,
    InviteRefusal.late => l.inviteRefusedLate,
    InviteRefusal.plus => l.inviteRefusedPlus,
  };

  Future<void> _use() async {
    final String? code = readInviteCode(_field.text);
    if (code == null || _asking) return;
    final AppLocalizations l = context.l10n;
    setState(() {
      _asking = true;
      _said = null;
    });
    final InviteAnswer answer = await Invites.instance.redeem(
      code,
      from: widget.from,
    );
    if (!mounted) return;
    switch (answer) {
      case InviteTaken(granted: true):
        Navigator.of(context).pop(answer);
      case InviteTaken():
        HapticFeedback.mediumImpact();
        setState(() {
          _asking = false;
          _accepted = true;
        });
      case InviteRefused(:final InviteRefusal why):
        setState(() {
          _asking = false;
          _said = _refusal(l, why);
        });
      case InviteNoAnswer():
        setState(() {
          _asking = false;
          _said = l.deeperTryAgain;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final Palette p = context.p;
    if (_accepted) {
      return _SheetFrame(
        key: const ValueKey('invite-code-accepted'),
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.inverse, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.check_rounded, color: p.onInverse, size: 26),
          ),
          const SizedBox(height: 16),
          BalancedText(l.inviteCodeAccepted, style: _title(context)),
          const SizedBox(height: 8),
          Text(l.inviteCodeWaitingLine, style: _line(context)),
          const SizedBox(height: 22),
          PrimaryButton(
            key: const ValueKey('invite-code-done'),
            label: l.widgetAskGotIt,
            height: 52,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }
    final bool ready = readInviteCode(_field.text) != null;
    return _SheetFrame(
      key: const ValueKey('invite-code-sheet'),
      children: [
        BalancedText(l.inviteCodeTitle, style: _title(context)),
        const SizedBox(height: 8),
        Text(l.inviteCodeLine, style: _line(context)),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('invite-code-field'),
          controller: _field,
          autofocus: widget.code == null,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.go,
          inputFormatters: [_CodeFormatter()],
          onChanged: (_) => setState(() => _said = null),
          onSubmitted: (_) => _use(),
          cursorColor: p.ink,
          style: AppText.display(
            size: 32,
            weight: FontWeight.w600,
            height: 1.2,
            spacing: 6,
            color: p.ink,
          ),
          decoration: InputDecoration(
            hintText: '······',
            hintStyle: AppText.display(
              size: 32,
              weight: FontWeight.w400,
              spacing: 6,
              color: p.inkFaint,
            ),
            filled: true,
            fillColor: p.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: p.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: p.ink, width: 1.4),
            ),
          ),
        ),
        if (_said case final String said) ...[
          const SizedBox(height: 10),
          Text(
            said,
            key: const ValueKey('invite-code-said'),
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.4,
              color: p.alert,
            ),
          ),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          key: const ValueKey('invite-code-use'),
          label: _asking ? l.oneMoment : l.inviteCodeUse,
          height: 52,
          onPressed: ready && !_asking ? _use : null,
        ),
      ],
    );
  }
}

/// What the field takes: the code's own characters, in capitals, six at
/// most. A pasted code with spaces or a dash is taken without them, and a
/// pasted message keeps only what could be the code.
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String kept = newValue.text
        .toUpperCase()
        .split('')
        .where(kInviteAlphabet.contains)
        .take(kInviteCodeLength)
        .join();
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }
}

// ── The week, given ──────────────────────────────────────────────────────

/// A week a friend's code gave, not yet shown, shown now on the screen a
/// purchase ends on — its own words: given, until when, nothing to pay or
/// to cancel. With [settle], a code taken that waited on the first day is
/// asked about first (Today's evening, once the five are read). True when
/// it rose.
Future<bool> showInviteWeekIfDue(
  BuildContext context,
  AppState app, {
  bool settle = true,
}) async {
  final Invites invites = Invites.instance;
  if (!app.inviteOn || !invites.reachable) return false;
  if (settle && invites.waiting) {
    await invites.settle().timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }
  final DateTime? until = invites.unseen;
  if (until == null || !context.mounted) return false;
  if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
  await invites.seen();
  if (!context.mounted) return false;
  await showInviteSuccess(context, app, until: until);
  return true;
}

/// The screen a purchase ends on, for a week a friend's code gave.
Future<void> showInviteSuccess(
  BuildContext context,
  AppState app, {
  required DateTime until,
}) async {
  final AppLocalizations l = context.l10n;
  final String locale = Localizations.localeOf(context).toString();
  final String name = app.name.trim();
  final String? first = name.isEmpty || name == 'You'
      ? null
      : name.split(RegExp(r'\s+')).first;
  // Today's five are the reader's own from now on — unless today's are read,
  // which is when a week waiting on the first day is given.
  final bool tomorrow = app.dayClosed;
  final String welcome = switch (first) {
    null when tomorrow => l.successWelcomeTomorrow,
    null => l.successWelcome,
    final String n when tomorrow => l.successWelcomeTomorrowNamed(n),
    final String n => l.successWelcomeNamed(n),
  };
  unawaited(PurchaseSuccessScreen.precache());
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, _) => PurchaseSuccessScreen(
        title: l.inviteSuccessTitle,
        welcome: welcome,
        planName: l.inviteSuccessPlan,
        planLine: l.inviteSuccessUntil(DateFormat.MMMMd(locale).format(until)),
        foot: l.inviteSuccessFoot,
        screenName: 'invite week',
      ),
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
