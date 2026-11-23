import 'dart:math' as math;
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
import 'web/card_thumb.dart';
import 'glass_round.dart';

/// The day, sent to a friend: a picture of the five cards that came out, and
/// a line under it.
///
/// It used to be five emoji squares and a score, the way a word game is
/// sent. But the day is not a match: most cards are read or argued rather
/// than got right, and a score in a chat says "look how I did" when what
/// makes a friend open the app is the cards themselves. So the picture is
/// the five — each card in small with its drawing, and its question, never
/// its answer — under the day's date, with how to get the app. The streak
/// stays, small: it says the habit, not a result.
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
  /// go: the edition and its five questions, and the address. The edition
  /// rather than the reader's day count, because the date is the thing two
  /// readers have in common.
  static String text(BuildContext context, AppState app) {
    final l = context.l10n;
    final d = app.daySummary;
    return [
      'Astute #${d.edition} · ${l.shareDayHeadline}',
      for (final Pill pill in app.todaysDeck.take(kPillsPerDay))
        '· ${pill.question}',
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

  /// The tall shape, for a story, rather than the one for a chat or a feed.
  bool _story = false;

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
    'format': _story ? 'story' : 'post',
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
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    // Never taller than the screen, with some of the page left in sight
    // above it to tap away on: a story's tall picture shrinks into the room
    // left between the shapes and the buttons. Taller than the screen, the
    // sheet used to scroll where it should have closed, with nothing above
    // it to tap — a story was a sheet with no way out.
    final double most = MediaQuery.sizeOf(context).height - safe.top - 24;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: most),
      child: Container(
        decoration: BoxDecoration(
          color: context.p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.fromLTRB(22, 14, 22, safe.bottom + 24),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.shareDayTitle,
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w600,
                      spacing: -0.6,
                      color: context.p.ink,
                    ),
                  ),
                ),
                _Close(onTap: () => Navigator.of(context).maybePop()),
              ],
            ),
            const SizedBox(height: 12),
            // The two shapes a day goes out in: a chat or a feed's, and a
            // story's.
            Row(
              children: [
                for (final bool story in const [false, true]) ...[
                  if (story) const SizedBox(width: 8),
                  _Shape(
                    key: ValueKey('share-day-${story ? 'story' : 'post'}'),
                    label: story ? l.shareFormatStory : l.shareFormatPost,
                    tall: story,
                    on: _story == story,
                    onTap: () => setState(() => _story = story),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            // The picture is laid out at one size on every phone, so it is
            // the same picture wherever it is made, and shown shrunk to the
            // room there is.
            Flexible(
              child: LayoutBuilder(
                builder: (context, box) {
                  const double w = DayPicture.width;
                  final double h = w / (_story ? 9 / 16 : 4 / 5);
                  final double fit = math.min(
                    box.maxWidth / w,
                    box.maxHeight / h,
                  );
                  // As tall as the picture, not as the room: the sheet ends
                  // under the post's square as it does under the story.
                  return Center(
                    heightFactor: 1,
                    child: SizedBox(
                      width: w * fit,
                      height: h * fit,
                      child: FittedBox(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: RepaintBoundary(
                            key: _picture,
                            // A picture, not a screen: set at one size
                            // whatever the reader's text size, or a large
                            // setting would crop it for somebody else.
                            child: MediaQuery(
                              data: MediaQuery.of(context)
                                  .copyWith(textScaler: TextScaler.noScaling),
                              child: DayPicture(
                                summary: app.daySummary,
                                five: app.todaysDeck
                                    .take(kPillsPerDay)
                                    .toList(),
                                day: app.today,
                                story: _story,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
                  label: l.shareCopyLink,
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

/// The way out of the sheet, always in sight beside its title.
class _Close extends StatelessWidget {
  const _Close({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return GlassRound(
      symbol: GlassRound.close,
      label: MaterialLocalizations.of(context).closeButtonLabel,
      onPressed: onTap,
      size: 36,
      iconSize: 15,
      fallback: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).closeButtonLabel,
        child: GestureDetector(
          key: const ValueKey('share-day-close'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: p.line),
            ),
            child: Icon(Icons.close_rounded, size: 18, color: p.inkMuted),
          ),
        ),
      ),
    );
  }
}

/// The picture of the day: four by five, the shape a chat and a story both
/// show without cropping.
///
/// The five cards that came out, each in small with its drawing beside its
/// question, in the order they were dealt: a friend reads five questions and
/// wants the answers, which is the reason to send it. No answers, and no
/// score. Over them the day's name and date; under them the streak, the line
/// that says what this is, and where to get it.
class DayPicture extends StatelessWidget {
  const DayPicture({
    super.key,
    required this.summary,
    required this.five,
    required this.day,
    this.story = false,
  });

  final DaySummary summary;
  final List<Pill> five;
  final DateTime day;

  /// Nine by sixteen, for a story, instead of four by five: the same
  /// picture with the room a phone held upright gives it — the cards in
  /// small taller, the type larger.
  final bool story;

  static const Color _ground = Color(0xFF0C0C0E);
  static const Color _ink = Color(0xFFF4F2EC);
  static const Color _flame = Color(0xFFFF7A1A);

  /// The width the picture is laid out at on every phone; it is made at
  /// three times this, 1080 across, and shown shrunk to the room there is.
  static const double width = 360;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String date = DateFormat(
      'EEEE d MMMM',
      Localizations.localeOf(context).toString(),
    ).format(day);
    // The day's own colours: the first card's light from the top corner, the
    // last card's from the bottom one, so no two days' pictures are alike.
    final Color first = five.isEmpty ? _flame : five.first.color;
    final Color last = five.length < 2 ? first : five.last.color;
    final double k = story ? 1.18 : 1.0;
    return AspectRatio(
      aspectRatio: story ? 9 / 16 : 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _ground,
            gradient: RadialGradient(
              center: const Alignment(1.0, -1.0),
              radius: 1.2,
              colors: [first.withValues(alpha: 0.32), _ground.withAlpha(0)],
            ),
          ),
          position: DecorationPosition.background,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.0, 1.0),
                radius: 1.1,
                colors: [last.withValues(alpha: 0.24), _ground.withAlpha(0)],
              ),
            ),
            child: Padding(
              padding: story
                  ? const EdgeInsets.fromLTRB(22, 40, 22, 34)
                  : const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Astute',
                        style: AppText.display(
                          size: 19,
                          weight: FontWeight.w700,
                          spacing: -0.5,
                          color: _ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${summary.edition}',
                        style: AppText.label(
                          size: 11,
                          weight: FontWeight.w700,
                          spacing: 1.1,
                          color: _ink.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.shareDayHeadline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(
                      size: 28 * k,
                      weight: FontWeight.w700,
                      height: 1.0,
                      spacing: -1,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: _ink.withValues(alpha: 0.55),
                    ),
                  ),
                  SizedBox(height: story ? 24 : 12),
                  for (int i = 0; i < five.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 6 * k),
                        child: _Row(pill: five[i], scale: k),
                      ),
                    ),
                  SizedBox(height: story ? 22 : 12),
                  // In a story the line has a row of its own, larger: there
                  // is the room, and it is what the story asks of whoever
                  // sees it.
                  if (story) ...[
                    Text(
                      l.shareDayTurn,
                      style: AppText.display(
                        size: 19,
                        weight: FontWeight.w600,
                        spacing: -0.4,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      if (summary.streak > 0) ...[
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: _flame,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l.streakDays(summary.streak),
                          style: AppText.body(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: _ink.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: story
                            ? const SizedBox.shrink()
                            : Text(
                                l.shareDayTurn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  size: 11.5,
                                  weight: FontWeight.w600,
                                  color: _ink.withValues(alpha: 0.8),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'astutetheapp.com',
                        style: AppText.label(
                          size: 10.5,
                          weight: FontWeight.w700,
                          spacing: 0.3,
                          color: _ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the five: the card in small — its front, with its drawing, or its
/// colour and mark where it has no picture — and its question beside it.
class _Row extends StatelessWidget {
  const _Row({required this.pill, this.scale = 1});

  final Pill pill;

  /// Larger in a story, where each row has more room.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final Widget plain = ColoredBox(
      color: pill.color,
      child: Center(
        child: CardMark(pill: pill, size: 16, ink: pill.ink),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
      decoration: BoxDecoration(
        color: DayPicture._ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: WebThumbs.aspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CardThumb.has(pill, CardSide.front)
                  ? CardThumb(pill: pill, side: CardSide.front, fallback: plain)
                  : plain,
            ),
          ),
          const SizedBox(width: 10),
          // The question alone: the card in small beside it already says
          // the subject, by its colour and its mark.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pill.question,
                maxLines: scale > 1 ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(
                  size: 13 * scale,
                  weight: FontWeight.w600,
                  height: 1.16,
                  spacing: -0.2,
                  color: DayPicture._ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the two shapes the day goes out in.
class _Shape extends StatelessWidget {
  const _Shape({
    super.key,
    required this.label,
    required this.tall,
    required this.on,
    required this.onTap,
  });

  final String label;

  /// The story's shape, nine by sixteen, rather than the post's four by
  /// five.
  final bool tall;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(11, 0, 14, 0),
          decoration: BoxDecoration(
            color: on ? p.inverse : p.surfaceRaised,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? Colors.transparent : p.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The shape the picture goes out in, drawn as a frame in its
              // own proportions: a crop icon at this size read as a stray
              // mark rather than as either shape.
              Container(
                width: tall ? 9 : 12.8,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.5),
                  border: Border.all(
                    color: on ? p.onInverse : p.inkMuted,
                    width: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: on ? p.onInverse : p.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
