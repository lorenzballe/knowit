import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../analytics.dart';
import '../data/pills_repository.dart' show kPillsPerDay;
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/share_image.dart';
import '../utils/share_link.dart';
import 'subject_icon.dart';
import 'ui.dart';

/// The day, sent to a friend: a picture of the five, and a line under it.
///
/// It used to be five emoji squares and a line of text, the way a word game
/// is sent, which in a chat looked like every other app's. Now it is a
/// picture made for the chat it lands in — the five as the cards they were,
/// each in its subject's colour with its mark, and how each went; the score,
/// the streak, and how to get the app. Nothing in it spoils a card: which
/// subjects, and how they went, never what they asked.
class ShareDay extends StatelessWidget {
  const ShareDay({super.key, required this.app, required this.from});

  final AppState app;

  /// Where the day was sent from — the journey, or the finished day itself
  /// — so the numbers can say which of the two readers actually use.
  final String from;

  /// How the picture is handed over: the platform's sheet. Under a test,
  /// which has no sheet, whatever the test puts here.
  @visibleForTesting
  static Future<bool> Function(Uint8List bytes, String name, String text)
  shareImage = _shareImage;

  static Future<bool> _shareImage(Uint8List bytes, String name, String text) =>
      shareCardImage(bytes, name, text);

  /// The words that go with the picture, and alone where a picture cannot
  /// go: the edition, the streak, how the questions went, and the address.
  /// The edition rather than the reader's day count, because the date is the
  /// thing two readers have in common.
  static String text(BuildContext context, AppState app) {
    final l = context.l10n;
    final d = app.daySummary;
    final verdict = [
      if (d.asked > 0) l.rightOfAsked(d.right, d.asked),
      if (d.sure != null) l.saidSure(d.sure!.round()),
    ].join(' · ');
    return [
      'Astute #${d.edition}${d.streak > 0 ? ' · ${l.streakDays(d.streak)}' : ''}',
      if (verdict.isNotEmpty) verdict,
      l.shareDayTurn,
      ShareRef.day.link,
    ].join('\n');
  }

  /// Opens the sheet that sends the day, from [from].
  static Future<void> send(
    BuildContext context,
    AppState app, {
    required String from,
  }) {
    HapticFeedback.lightImpact();
    Analytics.capture('share sheet opened', {'kind': 'day', 'from': from});
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: (_) => _ShareDaySheet(app: app, from: from),
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

class _ShareDaySheet extends StatefulWidget {
  const _ShareDaySheet({required this.app, required this.from});

  final AppState app;
  final String from;

  @override
  State<_ShareDaySheet> createState() => _ShareDaySheetState();
}

class _ShareDaySheetState extends State<_ShareDaySheet> {
  final GlobalKey _picture = GlobalKey();
  bool _busy = false;

  AppState get app => widget.app;

  void _toast(ScaffoldMessengerState messenger, String message) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _counted(String as) => Analytics.capture('day shared', {
    'streak_days': app.streak,
    'edition': app.daySummary.edition,
    'as': as,
    'from': widget.from,
  });

  /// The picture at three times its size, so it is sharp at a story's.
  Future<Uint8List?> _capture() async {
    final boundary =
        _picture.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _share() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String words = ShareDay.text(context, app);
    setState(() => _busy = true);
    try {
      final Uint8List? bytes = await _capture();
      final bool shared =
          bytes != null &&
          await ShareDay.shareImage(
            bytes,
            'astute-${app.daySummary.edition}.png',
            words,
          );
      _counted(shared ? 'image' : 'copied');
      if (!shared) {
        // No sheet to take the picture — a browser, a desktop — so the
        // words go on the clipboard, one paste from the same chat.
        await Clipboard.setData(ClipboardData(text: words));
        _toast(messenger, l.textCopiedInstead);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: ShareDay.text(context, app)));
    _counted('copied');
    _toast(messenger, l.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: context.p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.shareDayTitle,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 18),
            RepaintBoundary(
              key: _picture,
              // A picture, not a screen: set at one size whatever the
              // reader's text size, or a large setting would crop it for
              // somebody else.
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: DayPicture(
                  summary: app.daySummary,
                  five: app.todaysDeck.take(kPillsPerDay).toList(),
                  day: app.today,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    key: const ValueKey('share-day-send'),
                    label: _busy ? l.rendering : l.share,
                    height: 52,
                    onPressed: _busy ? null : _share,
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: l.copiedToClipboard,
                  child: GestureDetector(
                    key: const ValueKey('share-day-copy'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _copy,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.p.lineStrong),
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: context.p.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The picture of the day: four by five, the shape a chat and a story both
/// show without cropping.
///
/// The score leads, because a number is what makes a friend answer; the five
/// stand under it as the cards they were — each subject's colour and mark,
/// and how it went in a disc at its corner; the streak and how sure sit
/// beside the score; the foot says what this is and where to get it.
class DayPicture extends StatelessWidget {
  const DayPicture({
    super.key,
    required this.summary,
    required this.five,
    required this.day,
  });

  final DaySummary summary;
  final List<Pill> five;
  final DateTime day;

  static const Color _ground = Color(0xFF0C0C0E);
  static const Color _ink = Color(0xFFF4F2EC);
  static const Color _right = Color(0xFF2BD16B);
  static const Color _wrong = Color(0xFFFF4D4F);
  static const Color _flame = Color(0xFFFF7A1A);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String date = DateFormat(
      'd MMM',
      Localizations.localeOf(context).toString(),
    ).format(day).replaceAll('.', '');
    final Color glow = five.isEmpty ? _flame : five.first.color;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _ground,
            gradient: RadialGradient(
              center: const Alignment(0.9, -1.0),
              radius: 1.3,
              colors: [glow.withValues(alpha: 0.30), _ground],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Astute',
                      style: AppText.display(
                        size: 21,
                        weight: FontWeight.w700,
                        spacing: -0.6,
                        color: _ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${summary.edition} · $date',
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w700,
                        spacing: 1.1,
                        color: _ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Text(
                  summary.asked > 0
                      ? l.rightOfAsked(summary.right, summary.asked)
                      : l.shareDayRead,
                  maxLines: 2,
                  style: AppText.display(
                    size: 40,
                    weight: FontWeight.w700,
                    height: 1.0,
                    spacing: -1.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (summary.streak > 0)
                      _Chip(
                        icon: Icons.local_fire_department_rounded,
                        iconColour: _flame,
                        label: l.streakDays(summary.streak),
                      ),
                    if (summary.sure != null)
                      _Chip(label: l.shareDaySure(summary.sure!.round())),
                  ],
                ),
                const Spacer(flex: 2),
                Row(
                  children: [
                    for (int i = 0; i < five.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _Tile(
                          pill: five[i],
                          mark: i < summary.marks.length
                              ? summary.marks[i]
                              : DayMark.read,
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(flex: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        l.shareDayTurn,
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          height: 1.25,
                          color: _ink.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'astutetheapp.com',
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w700,
                        spacing: 0.4,
                        color: _ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A fact beside the score: the streak, how sure.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.iconColour});

  final String label;
  final IconData? icon;
  final Color? iconColour;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 9, 0, 12, 0),
      decoration: BoxDecoration(
        color: DayPicture._ink.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColour),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: DayPicture._ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the five: its subject's colour and mark, its subject's name, and
/// how it went in a disc at its corner.
class _Tile extends StatelessWidget {
  const _Tile({required this.pill, required this.mark});

  final Pill pill;
  final DayMark mark;

  @override
  Widget build(BuildContext context) {
    final (IconData? icon, Color disc) = switch (mark) {
      DayMark.right => (Icons.check_rounded, DayPicture._right),
      DayMark.wrong => (Icons.close_rounded, DayPicture._wrong),
      DayMark.sided => (Icons.balance_rounded, const Color(0xFFFFC23D)),
      DayMark.passed => (Icons.remove_rounded, const Color(0xFF6B6B70)),
      DayMark.read => (null, Colors.transparent),
    };
    return AspectRatio(
      aspectRatio: 0.62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: pill.color,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
              child: Column(
                children: [
                  const Spacer(),
                  SubjectIcon(subject: pill.topic, size: 24, ink: pill.ink),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.l10n.subjectOf(pill.topic),
                      maxLines: 1,
                      style: AppText.body(
                        size: 9.5,
                        weight: FontWeight.w700,
                        color: pill.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (icon != null)
            Positioned(
              top: -7,
              right: -7,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: disc,
                  shape: BoxShape.circle,
                  border: Border.all(color: DayPicture._ground, width: 2.5),
                ),
                child: Icon(icon, size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
