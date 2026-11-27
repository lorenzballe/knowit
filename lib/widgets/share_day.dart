import 'dart:async';
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
import '../utils/share_origin.dart';
import 'balanced_text.dart';
import 'card_edge.dart' show cardHairline;
import 'glass_round.dart';
import 'subject_icon.dart';
import 'ui.dart';
import 'web/card_thumb.dart';
import 'web/web_card_page.dart' show groundOf;

/// The day, sent to a friend: a picture of the five cards that came out, and
/// a line under it.
///
/// It used to be five emoji squares and a score, the way a word game is
/// sent. But the day is not a match: most cards are read or argued rather
/// than got right, and a score in a chat says "look how I did" when what
/// makes a friend open the app is the cards themselves. So the picture is
/// the five — each card's drawing, and its question whole, never its answer
/// — under the day's date, with how to get the app. The streak stays,
/// small: it says the habit, not a result.
class ShareDay extends StatelessWidget {
  const ShareDay({super.key, required this.app, required this.from});

  final AppState app;

  /// Where the day was sent from — the journey, or the finished day itself
  /// — so the numbers can say which of the two readers actually use.
  final String from;

  /// How the picture is handed over: the platform's sheet, pointing from
  /// [origin]. Under a test, which has no sheet, whatever the test puts
  /// here.
  @visibleForTesting
  static Future<bool> Function(
    Uint8List bytes,
    String name,
    String text,
    Rect? origin,
  )
  shareImage = _shareImage;

  static Future<bool> _shareImage(
    Uint8List bytes,
    String name,
    String text,
    Rect? origin,
  ) => shareCardImage(bytes, name, text, origin: origin);

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

  /// Counts the day sent, as [as] (`image`, `text` when the words went
  /// instead, `copied`), from [from], laid out as [layout].
  static void counted(
    AppState app, {
    required String as,
    required String from,
    required DayLayout layout,
  }) => Analytics.capture('day shared', {
    'streak_days': app.streak,
    'edition': app.daySummary.edition,
    'as': as,
    'from': from,
    'format': layout == DayLayout.story ? 'story' : 'post',
    'layout': layout.name,
  });

  /// Sends the day's picture as it is drawn under [picture] (a
  /// [DayPicturePreview]'s), laid out as [layout], with its words: through
  /// the platform's sheet, or, where nothing takes a picture — a browser, a
  /// desktop — the words alone, on the clipboard, one paste from the same
  /// chat. Counted from [from]. Says how it went: `image`, or `text` for
  /// the words copied instead, which the caller says over its own screen.
  ///
  /// The one way the day's picture leaves: from the sheet, and, where the
  /// developer tools try them, from the day's own moment and its card.
  static Future<String> sendPicture(
    BuildContext context,
    AppState app, {
    required GlobalKey picture,
    required DayLayout layout,
    required String from,
  }) async {
    final String words = text(context, app);
    final List<Pill> five = app.todaysDeck.take(kPillsPerDay).toList();
    final Uint8List? bytes = await _capture(context, picture, five, layout);
    final bool shared =
        bytes != null &&
        await shareImage(
          bytes,
          'astute-${app.daySummary.edition}.png',
          words,
          // The system sheet points from this one, as a card's does.
          context.mounted ? shareOrigin(context) : null,
        );
    // A share that fell back to the words is counted apart from a copy
    // asked for, as a card's is: both used to be "copied", and the numbers
    // could not say whether the sheet had failed.
    final String as = shared ? 'image' : 'text';
    counted(app, as: as, from: from, layout: layout);
    if (!shared) await Clipboard.setData(ClipboardData(text: words));
    return as;
  }

  /// Every picture [layout] draws of [five], come — or given up on — and
  /// drawn, before the picture is made: a card still on its way would
  /// otherwise leave as its colour alone.
  static Future<void> _ready(
    BuildContext context,
    List<Pill> five,
    DayLayout layout,
  ) async {
    final List<Future<void>> coming = [
      for (final ImageProvider p in DayPicture.picturesOf(five, layout))
        precacheImage(p, context, onError: (_, _) {}),
    ];
    await Future.wait(coming)
        .timeout(const Duration(seconds: 4), onTimeout: () => const []);
    if (!context.mounted) return;
    await WidgetsBinding.instance.endOfFrame;
  }

  /// The picture under [picture] at three times its size: 1080 across, a
  /// chat's or a story's own width.
  static Future<Uint8List?> _capture(
    BuildContext context,
    GlobalKey picture,
    List<Pill> five,
    DayLayout layout,
  ) async {
    await _ready(context, five, layout);
    final boundary =
        picture.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
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

  /// How the picture is laid out, and so its shape.
  DayLayout _layout = DayPicture.recommended;

  /// Whether the words were copied a moment ago: the copy button says so
  /// with a tick, beside the note over the sheet.
  bool _copied = false;

  /// A word over the sheet — the words copied — and when it goes. It used
  /// to be a snack bar, which a sheet covers: it was never seen while the
  /// sheet was up, and came out on the finished day once the sheet was
  /// closed, as if sending the day had only copied it.
  OverlayEntry? _note;
  Timer? _noteGoes;

  bool _warmed = false;

  AppState get app => widget.app;

  List<Pill> get _five => app.todaysDeck.take(kPillsPerDay).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    // Every picture each shape draws, fetched now: switching shape, or
    // sending at once, finds them come.
    for (final DayLayout layout in DayLayout.values) {
      for (final ImageProvider picture in DayPicture.picturesOf(
        _five,
        layout,
      )) {
        precacheImage(picture, context, onError: (_, _) {});
      }
    }
  }

  @override
  void dispose() {
    _noteGoes?.cancel();
    _note?.remove();
    _note = null;
    super.dispose();
  }

  /// Says [message] over the sheet, where it is seen, for two seconds.
  void _say(String message) {
    _noteGoes?.cancel();
    _note?.remove();
    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    // Over the picture's foot, just above the buttons: not on them.
    final double bottom = MediaQuery.paddingOf(context).bottom + 24 + 52 + 14;
    _note = OverlayEntry(
      builder: (context) => Positioned(
        left: 22,
        right: 22,
        bottom: bottom,
        child: IgnorePointer(
          child: Center(child: _Note(message: message)),
        ),
      ),
    );
    overlay.insert(_note!);
    if (MediaQuery.supportsAnnounceOf(context)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    }
    setState(() => _copied = true);
    _noteGoes = Timer(const Duration(seconds: 2), () {
      _note?.remove();
      _note = null;
      if (mounted) setState(() => _copied = false);
    });
  }

  void _counted(String as) =>
      ShareDay.counted(app, as: as, from: widget.from, layout: _layout);

  Future<void> _share() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final String as = await ShareDay.sendPicture(
        context,
        app,
        picture: _picture,
        layout: _layout,
        from: widget.from,
      );
      if (as == 'text' && mounted) _say(l.textCopiedInstead);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: ShareDay.text(context, app)));
    _counted('copied');
    if (mounted) _say(l.copiedToClipboard);
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
            // The three ways the day goes out: one card large over the
            // other four, the five in a list, and a story's tall shape.
            // Where the three are wider than the sheet — a long word on a
            // small phone — they come down together, all at one size: each
            // shrunk on its own, the longest word was the smallest.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final DayLayout layout in DayLayout.values) ...[
                    if (layout.index > 0) const SizedBox(width: 8),
                    _Shape(
                      key: ValueKey('share-day-${layout.name}'),
                      label: _nameOf(l, layout),
                      layout: layout,
                      on: _layout == layout,
                      onTap: () => setState(() => _layout = layout),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // The picture is laid out at one size on every phone, so it is
            // the same picture wherever it is made, and shown shrunk to the
            // room there is.
            Flexible(
              child: DayPicturePreview(
                app: app,
                picture: _picture,
                layout: _layout,
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
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
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

  static String _nameOf(AppLocalizations l, DayLayout layout) =>
      switch (layout) {
        DayLayout.cover => l.shareFormatCover,
        DayLayout.list => l.shareFormatList,
        DayLayout.story => l.shareFormatStory,
      };
}

/// The day's picture as a screen shows it, in the room it is given: laid
/// out at its one size whatever the phone, as it is sent, and shrunk to fit.
/// As tall as the picture, not as the room, so what is under it follows it.
/// [picture] keys what [ShareDay.sendPicture] makes it from.
class DayPicturePreview extends StatelessWidget {
  const DayPicturePreview({
    super.key,
    required this.app,
    required this.picture,
    this.layout = DayPicture.recommended,
    this.radius = 20,
  });

  final AppState app;
  final GlobalKey picture;
  final DayLayout layout;

  /// Its corners on the screen; it is sent square.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const double w = DayPicture.width;
        final double h = DayPicture.heightOf(layout);
        final double fit = math.min(box.maxWidth / w, box.maxHeight / h);
        return Center(
          heightFactor: 1,
          child: Container(
            width: w * fit,
            height: h * fit,
            // On the night page, black on black, the picture had no edge:
            // a hairline says where what is sent ends. Drawn on the screen,
            // never on the picture.
            foregroundDecoration: context.p.isDark
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: context.p.line),
                  )
                : null,
            // Rounded here, on the screen, and square as it is sent: a
            // chat rounds a picture itself, and corners cut out of the
            // picture showed as the chat's own white round a black card.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: FittedBox(
                child: SizedBox(
                  width: w,
                  height: h,
                  child: RepaintBoundary(
                    key: picture,
                    // A picture, not a screen: set at one size whatever the
                    // reader's text size, or a large setting would crop it
                    // for somebody else.
                    child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.noScaling),
                      child: DayPicture(
                        summary: app.daySummary,
                        five: app.todaysDeck.take(kPillsPerDay).toList(),
                        day: app.today,
                        layout: layout,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A word laid over the sheet for a moment, drawn as the app's snack bars
/// are: the palette turned over, rounded.
class _Note extends StatelessWidget {
  const _Note({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    // Its own Material: laid on the overlay, over the sheet's, the words
    // took the bare app's style and came out underlined twice in yellow.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: const ValueKey('share-day-note'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: p.inverse,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.body(size: 13.5, height: 1.35, color: p.onInverse),
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

/// The three ways the day's picture is laid out, each on the shape it is
/// for.
enum DayLayout {
  /// One card large — the day's first drawing, where it has one, with its
  /// question beside it — over the other four in a list. Four by five, 1080
  /// by 1350: the shape a chat shows whole, at the size it shows a photo.
  cover(4 / 5),

  /// The five alike in a list, each its drawing and its question. Four by
  /// five.
  list(4 / 5),

  /// The cover's arrangement on a story's shape, nine by sixteen, 1080 by
  /// 1920: the card large, the type larger, room left at the top for the
  /// name a story puts over it.
  story(9 / 16);

  const DayLayout(this.aspect);

  /// Width to height.
  final double aspect;
}

/// The picture of the day.
///
/// The five cards that came out, in the order they were dealt, each as its
/// drawing — the card's own picture, cut down to the drawing under its
/// question — or, on a card in words, its colour and its subject's mark;
/// and each with its question whole, never its answer: a friend reads five
/// questions and wants the answers, which is the reason to send it. No
/// score. Over them the day's name and date; under them what this is, where
/// to get it, and the streak, small.
///
/// Nothing is ever cut with an ellipsis. The type is set as large as the
/// room allows and comes down, a step at a time, to a size still read with
/// ease on a phone; the drawings give up room before the words go below
/// that. Lines are broken evenly, so a question never ends on a word alone.
class DayPicture extends StatelessWidget {
  const DayPicture({
    super.key,
    required this.summary,
    required this.five,
    required this.day,
    this.layout = DayPicture.recommended,
  });

  final DaySummary summary;
  final List<Pill> five;
  final DateTime day;
  final DayLayout layout;

  /// The shape the sheet opens on: the cover, whose drawing is the largest
  /// a chat shows, and which a chat shows whole.
  static const DayLayout recommended = DayLayout.cover;

  /// The width the picture is laid out at on every phone; it is made at
  /// three times this, 1080 across, and shown shrunk to the room there is.
  static const double width = 360;

  /// The height [layout] is laid out at.
  static double heightOf(DayLayout layout) => width / layout.aspect;

  /// The black the picture is set on: the app's own, at night. Opaque, so
  /// the picture is black in a light chat too — the ground used to be left
  /// to a gradient that faded to nothing, and the picture arrived grey,
  /// its white words on the chat's white.
  static const Color ground = Color(0xFF000000);
  static const Color _ink = Color(0xFFF2F1EC);
  static const Color _muted = Color(0xFF9E9EA6);
  static const Color _flame = Color(0xFFFF7A1A);

  /// The card [layout] sets large: the first with a drawing, or the first.
  static Pill? heroOf(List<Pill> five) {
    if (five.isEmpty) return null;
    for (final Pill pill in five) {
      if (CardThumb.has(pill, CardSide.front)) return pill;
    }
    return five.first;
  }

  /// The pictures [layout] draws of [five]: each drawn card's front, and the
  /// large one of the card set large.
  static List<ImageProvider> picturesOf(List<Pill> five, DayLayout layout) {
    final Pill? hero = layout == DayLayout.list ? null : heroOf(five);
    return [
      for (final Pill pill in five)
        if (CardThumb.refOf(pill, CardSide.front) case final String ref) ...[
          CardThumb.image(CardThumb.urlOf(ref)),
          if (identical(pill, hero))
            CardThumb.image(CardThumb.urlOf(CardThumb.largeOf(ref))),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    String date;
    try {
      date = DateFormat('EEEE d MMMM', locale).format(day);
    } catch (_) {
      date = DateFormat('EEEE d MMMM', 'en').format(day);
    }
    final bool tall = layout == DayLayout.story;
    final _Head head = _Head(date: date, edition: summary.edition, tall: tall);
    final _Foot foot = _Foot(streak: summary.streak, tall: tall);
    final Widget body = switch (layout) {
      DayLayout.list => _ListBody(five: five),
      DayLayout.cover || DayLayout.story => _CoverBody(five: five, tall: tall),
    };
    return AspectRatio(
      aspectRatio: layout.aspect,
      child: ColoredBox(
        color: ground,
        // Every style below says its size, height and spacing; this is only
        // what nothing says, the same for the type and its measure.
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'Figtree',
            color: _ink,
            fontSize: 14,
            height: 1.2,
            letterSpacing: 0,
            decoration: TextDecoration.none,
          ),
          child: Padding(
            // A story leaves its top to the name and the bars a story app
            // lays over it.
            padding: tall
                ? const EdgeInsets.fromLTRB(24, 58, 24, 40)
                : const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                SizedBox(height: tall ? 22 : 14),
                Expanded(child: body),
                SizedBox(height: tall ? 22 : 14),
                foot,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The day's name, its date and edition, and the app's: the head of the
/// picture.
class _Head extends StatelessWidget {
  const _Head({required this.date, required this.edition, required this.tall});

  final String date;
  final int edition;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final double big = tall ? 34 : 24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tall) ...[
          const Row(children: [_Brand(size: 16)]),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(
              child: _OneLine(
                l.shareDayHeadline,
                style: AppText.display(
                  size: big,
                  weight: FontWeight.w700,
                  height: 1.08,
                  spacing: -0.03 * big,
                  color: DayPicture._ink,
                ),
              ),
            ),
            if (!tall) ...[const SizedBox(width: 12), const _Brand(size: 14)],
          ],
        ),
        SizedBox(height: tall ? 6 : 4),
        _OneLine(
          '$date  ·  #$edition',
          style: AppText.body(
            size: tall ? 14 : 12,
            weight: FontWeight.w500,
            height: 1.25,
            spacing: 0,
            color: DayPicture._muted,
          ),
        ),
      ],
    );
  }
}

/// The app's mark and name, as its icon is on a phone.
class _Brand extends StatelessWidget {
  const _Brand({required this.size});

  /// The name's size; the mark is a little larger.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/mark-dark.png',
          width: size + 6,
          height: size + 6,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
        SizedBox(width: size * 0.4),
        Text(
          'Astute',
          style: AppText.display(
            size: size,
            weight: FontWeight.w700,
            height: 1.1,
            spacing: -0.02 * size,
            color: DayPicture._ink,
          ),
        ),
      ],
    );
  }
}

/// What this is and where to get it, and the streak, small: the foot.
class _Foot extends StatelessWidget {
  const _Foot({required this.streak, required this.tall});

  final int streak;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Widget address = _OneLine(
      kSiteHost,
      style: AppText.body(
        size: tall ? 13 : 11,
        weight: FontWeight.w600,
        height: 1.25,
        spacing: 0.2,
        color: DayPicture._muted,
      ),
    );
    final Widget days = streak > 0
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: tall ? 16 : 14,
                color: DayPicture._flame,
              ),
              const SizedBox(width: 3),
              Text(
                l.streakDays(streak),
                style: AppText.body(
                  size: tall ? 13 : 11.5,
                  weight: FontWeight.w700,
                  height: 1.25,
                  spacing: 0,
                  color: DayPicture._ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
    if (tall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OneLine(
            l.shareDayTurn,
            style: AppText.display(
              size: 21,
              weight: FontWeight.w600,
              height: 1.15,
              spacing: -0.4,
              color: DayPicture._ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: address),
              const SizedBox(width: 12),
              days,
            ],
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OneLine(
                l.shareDayTurn,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w700,
                  height: 1.25,
                  spacing: 0,
                  color: DayPicture._ink.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 1),
              address,
            ],
          ),
        ),
        const SizedBox(width: 12),
        days,
      ],
    );
  }
}

/// A line that stays one line: smaller where the language makes it longer
/// than the room, never cut.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, maxLines: 1, softWrap: false, style: style),
    );
  }
}

/// A question as the picture sets it, at [size].
TextStyle _questionStyle(double size) => AppText.display(
  size: size,
  weight: FontWeight.w600,
  height: 1.18,
  spacing: -0.012 * size,
  color: DayPicture._ink,
);

/// A subject's name over the card set large, in the subject's colour where
/// that colour reads on black.
TextStyle _subjectStyle(Color colour) => AppText.label(
  size: 10,
  weight: FontWeight.w700,
  spacing: 1.4,
  height: 1.2,
  color: colour.computeLuminance() < 0.12
      ? Color.lerp(colour, Colors.white, 0.45)
      : colour,
);

/// Type measured as the picture sets it: at its own size whatever the
/// reader's, in the language around it, on the same default style, so that
/// what is measured to fit is what is drawn.
class _Measure {
  _Measure(BuildContext context)
    : _base = DefaultTextStyle.of(context).style,
      _direction = Directionality.of(context),
      _locale = Localizations.maybeLocaleOf(context);

  final TextStyle _base;
  final TextDirection _direction;
  final Locale? _locale;

  /// Kept between pictures: the sheet lays out the same five again as the
  /// reader switches shapes.
  static final Map<String, double> _kept = {};

  double height(String text, TextStyle style, double width) {
    final String key =
        '${style.fontFamily}|${style.fontSize}|${style.fontWeight?.value}|'
        '${style.height}|${style.letterSpacing}|'
        '${width.toStringAsFixed(2)}|$_locale|$text';
    final double? known = _kept[key];
    if (known != null) return known;
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: _base.merge(style)),
      textDirection: _direction,
      locale: _locale,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: width);
    final double h = painter.height;
    painter.dispose();
    if (_kept.length > 4000) _kept.clear();
    return _kept[key] = h;
  }
}

/// How a list of cards is set: the bounds its drawings and its type move in.
class _ListSpec {
  const _ListSpec({
    required this.tileMax,
    required this.tileMin,
    required this.sizeMax,
    required this.sizeGood,
    required this.sizeMin,
    required this.gapMin,
    required this.gapMax,
  });

  /// The drawings' side, largest and smallest.
  final double tileMax;
  final double tileMin;

  /// The questions' size: the largest; the one a drawing gives up room to
  /// keep; and the floor, under which the type goes only when nothing else
  /// is left to give — and never so far as to be cut.
  final double sizeMax;
  final double sizeGood;
  final double sizeMin;

  /// The room between two cards, least and most.
  final double gapMin;
  final double gapMax;

  /// The room between a drawing and its question.
  static const double tileGap = 12;
}

/// Where a list of cards falls in the room it has: each card's drawing and
/// row, one size of type for all, and the room between them.
class _ListPlan {
  const _ListPlan({
    required this.tile,
    required this.size,
    required this.rows,
    required this.gap,
  });

  final double tile;
  final double size;
  final List<double> rows;
  final double gap;

  /// The height it takes.
  double get height =>
      rows.fold(0.0, (a, b) => a + b) + gap * math.max(0, rows.length - 1);

  static const double _step = 0.25;

  /// The rows of [pills] with drawings [tile] across and questions at
  /// [size], in [width].
  static List<double> _rows(
    _Measure m,
    List<Pill> pills,
    double width,
    double tile,
    double size,
  ) {
    final double words = width - tile - _ListSpec.tileGap;
    return [
      for (final Pill pill in pills)
        math.max(
          tile,
          m.height(pill.question, _questionStyle(size), words) + 1,
        ),
    ];
  }

  /// The largest size, on the step, from [floor] up, at which [pills] fit
  /// [room] with drawings [tile] across; null when not even [floor] does.
  static double? _largest(
    _Measure m,
    List<Pill> pills,
    double width,
    double room,
    double tile,
    double floor,
    _ListSpec s,
  ) {
    bool fits(double size) {
      final List<double> rows = _rows(m, pills, width, tile, size);
      return rows.fold(0.0, (a, b) => a + b) + s.gapMin * (pills.length - 1) <=
          room;
    }

    if (!fits(floor)) return null;
    int lo = 0;
    int hi = ((s.sizeMax - floor) / _step).floor();
    if (hi <= 0 || fits(floor + hi * _step)) {
      return floor + math.max(hi, 0) * _step;
    }
    while (hi - lo > 1) {
      final int mid = (lo + hi) ~/ 2;
      if (fits(floor + mid * _step)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return floor + lo * _step;
  }

  /// The plan for [pills] in [room], with type no smaller than [floor]: the
  /// largest drawings at which the questions keep [floor], and the largest
  /// type at those. Null when nothing fits at [floor].
  static _ListPlan? tryFit(
    _Measure m,
    List<Pill> pills,
    double width,
    double room,
    _ListSpec s,
    double floor,
  ) {
    if (pills.isEmpty) {
      return const _ListPlan(tile: 0, size: 0, rows: [], gap: 0);
    }
    for (double tile = s.tileMax; tile >= s.tileMin; tile -= 2) {
      final double? size = _largest(m, pills, width, room, tile, floor, s);
      if (size != null) {
        return _ListPlan(
          tile: tile,
          size: size,
          rows: _rows(m, pills, width, tile, size),
          gap: s.gapMin,
        );
      }
    }
    return null;
  }

  /// The plan for [pills] in [room]: at a comfortable size where the room
  /// allows, at the floor where it does not, and under it, smallest
  /// drawings, only where even that would cut a question.
  static _ListPlan fit(
    _Measure m,
    List<Pill> pills,
    double width,
    double room,
    _ListSpec s,
  ) {
    for (final double floor in [s.sizeGood, s.sizeMin]) {
      final _ListPlan? plan = tryFit(m, pills, width, room, s, floor);
      if (plan != null) return plan;
    }
    double size = s.sizeMin - _step;
    while (size > 6 &&
        _largest(m, pills, width, room, s.tileMin, size, s) == null) {
      size -= _step;
    }
    return _ListPlan(
      tile: s.tileMin,
      size: size,
      rows: _rows(m, pills, width, s.tileMin, size),
      gap: s.gapMin,
    );
  }

  /// This plan, its gaps opened up to [s]'s most by up to [extra].
  _ListPlan opened(double extra, _ListSpec s) {
    if (rows.length < 2 || extra <= 0) return this;
    final double more = math.min(extra / (rows.length - 1), s.gapMax - gap);
    return _ListPlan(tile: tile, size: size, rows: rows, gap: gap + more);
  }
}

/// The five in a list: the [DayLayout.list] body.
class _ListBody extends StatelessWidget {
  const _ListBody({required this.five});

  final List<Pill> five;

  static const _ListSpec _spec = _ListSpec(
    tileMax: 66,
    tileMin: 44,
    sizeMax: 14.5,
    sizeGood: 12,
    sizeMin: 10.5,
    gapMin: 8,
    gapMax: 16,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final _Measure m = _Measure(context);
        _ListPlan plan = _ListPlan.fit(
          m,
          five,
          box.maxWidth,
          box.maxHeight,
          _spec,
        );
        plan = plan.opened(box.maxHeight - plan.height, _spec);
        return Center(
          child: _Rows(pills: five, plan: plan),
        );
      },
    );
  }
}

/// Cards in a list, as [plan] sets them.
class _Rows extends StatelessWidget {
  const _Rows({required this.pills, required this.plan});

  final List<Pill> pills;
  final _ListPlan plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < pills.length; i++) ...[
          if (i > 0) SizedBox(height: plan.gap),
          SizedBox(
            height: plan.rows[i],
            child: Row(
              children: [
                _Tile(pill: pills[i], size: plan.tile),
                const SizedBox(width: _ListSpec.tileGap),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalancedText(
                        pills[i].question,
                        style: _questionStyle(plan.size),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One card large and the rest in a list under it: the [DayLayout.cover]
/// body, and the story's.
class _CoverBody extends StatelessWidget {
  const _CoverBody({required this.five, required this.tall});

  final List<Pill> five;
  final bool tall;

  static const _ListSpec _rest = _ListSpec(
    tileMax: 48,
    tileMin: 34,
    sizeMax: 13,
    sizeGood: 11.5,
    sizeMin: 10.5,
    gapMin: 7,
    gapMax: 12,
  );

  static const _ListSpec _restTall = _ListSpec(
    tileMax: 60,
    tileMin: 40,
    sizeMax: 15,
    sizeGood: 12.5,
    sizeMin: 11,
    gapMin: 9,
    gapMax: 16,
  );

  /// The card set large: its drawing's side, largest and smallest.
  double get _heroMax => tall ? 180 : 156;
  double get _heroMin => tall ? 120 : 100;

  /// Its question's size, largest and smallest.
  double get _heroSizeMax => tall ? 20 : 17;
  double get _heroSizeMin => tall ? 14 : 12.5;

  /// The room beside its drawing, and under it, least and most.
  static const double _beside = 16;
  double get _underMin => tall ? 20 : 16;
  double get _underMax => tall ? 34 : 24;

  @override
  Widget build(BuildContext context) {
    final Pill? hero = DayPicture.heroOf(five);
    if (hero == null) return const SizedBox.shrink();
    final List<Pill> rest = [
      for (final Pill pill in five)
        if (!identical(pill, hero)) pill,
    ];
    final String subject = context.l10n.subjectOf(hero.topic).toUpperCase();
    final _ListSpec spec = tall ? _restTall : _rest;
    return LayoutBuilder(
      builder: (context, box) {
        final _Measure m = _Measure(context);
        final double width = box.maxWidth;
        final double room = box.maxHeight;
        final TextStyle label = _subjectStyle(hero.color);

        // The question beside a drawing [tile] across: the largest size it
        // fits there at, and the height it takes.
        (double, double) heroWords(double tile) {
          final double words = width - tile - _beside;
          final double head = m.height(subject, label, words) + 6;
          double size = _heroSizeMax;
          while (size > _heroSizeMin &&
              head + m.height(hero.question, _questionStyle(size), words) >
                  tile) {
            size -= 0.25;
          }
          return (
            size,
            head + m.height(hero.question, _questionStyle(size), words) + 1,
          );
        }

        (double, double, double, _ListPlan)? plan;
        for (final double floor in [spec.sizeGood, spec.sizeMin]) {
          for (double tile = _heroMax; tile >= _heroMin; tile -= 4) {
            final (double size, double words) = heroWords(tile);
            final double top = math.max(tile, words);
            final _ListPlan? list = _ListPlan.tryFit(
              m,
              rest,
              width,
              room - top - _underMin,
              spec,
              floor,
            );
            if (list != null) {
              plan = (tile, size, top, list);
              break;
            }
          }
          if (plan != null) break;
        }
        if (plan == null) {
          final (double size, double words) = heroWords(_heroMin);
          final double top = math.max(_heroMin, words);
          plan = (
            _heroMin,
            size,
            top,
            _ListPlan.fit(m, rest, width, room - top - _underMin, spec),
          );
        }
        final (double tile, double size, double top, _ListPlan first) = plan;
        // What is left opens the list a little, then the room under the
        // card set large; the rest is shared above and below.
        double left = room - top - _underMin - first.height;
        final _ListPlan list = first.opened(left, spec);
        left -= list.height - first.height;
        final double under =
            _underMin + math.max(0.0, math.min(left, _underMax - _underMin));
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: top,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tile(pill: hero, size: tile, sharp: true),
                    const SizedBox(width: _beside),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subject, style: label),
                          const SizedBox(height: 6),
                          BalancedText(
                            hero.question,
                            style: _questionStyle(size),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (rest.isNotEmpty) ...[
                SizedBox(height: under),
                _Rows(pills: rest, plan: list),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A card in small: its drawing, where it has one — its own picture, cut
/// down to what is under its question, since the question is set beside it
/// — or its colour and its subject's mark.
class _Tile extends StatelessWidget {
  const _Tile({required this.pill, required this.size, this.sharp = false});

  final Pill pill;
  final double size;

  /// Drawn from the large picture, for a tile set large: the small one,
  /// blown up, was soft. The small one stays under it until it comes.
  final bool sharp;

  /// The card's size as its pictures are taken (tool/cards/thumbs.cjs).
  static const double _cardWidth = 366;
  static const double _cardHeight = 606;

  /// The square of the card a tile shows, in the card's points: a little
  /// in from its sides, so the drawing fills more of the tile.
  static const double _window = 330;

  /// Where each drawn card's drawing begins, by id.
  static final Map<String, double> _tops = {};

  /// Where the drawing begins on [pill]'s front, in the card's points: under
  /// its question, measured as the page sets it (docs/cards/kit/
  /// astute-card.css, `.kit-app`: 26 points from the top, the head's 16, a
  /// gap of 2.1% of the card's height, then the question at 3.4% of it, its
  /// lines 1.13 apart, across all but 28 points a side), and a line's room
  /// more, for a page that breaks the question a line later than measured
  /// here or sets something over it.
  static double topOf(Pill pill) => _tops.putIfAbsent(pill.id, () {
    const double type = 0.034 * _cardHeight;
    const double gap = 0.021 * _cardHeight;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: pill.question,
        style: AppText.display(
          size: type,
          weight: FontWeight.w800,
          height: 1.13,
          spacing: -0.012 * type,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: _cardWidth - 56);
    final int lines = math.max(1, painter.computeLineMetrics().length);
    painter.dispose();
    final double question = 26 + 16 + gap + lines * 1.13 * type;
    return math.min(question + 28, _cardHeight - _window);
  });

  @override
  Widget build(BuildContext context) {
    final String? ref = CardThumb.refOf(pill, CardSide.front);
    final Color colour = ref == null ? pill.color : groundOf(pill);
    final BorderRadius round = BorderRadius.circular(size * 0.14);
    // The card in words: its colour and mark. Under a drawing too, until the
    // drawing comes, and in its place where it will not.
    final Widget plain = ColoredBox(
      color: pill.color,
      child: Center(
        child: CardMark(pill: pill, size: size * 0.36, ink: pill.ink),
      ),
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colour, borderRadius: round),
      foregroundDecoration: BoxDecoration(
        borderRadius: round,
        border: cardHairline(colour, DayPicture.ground),
      ),
      child: ref == null ? plain : _drawing(ref, plain),
    );
  }

  Widget _drawing(String ref, Widget plain) {
    final double k = size / _window;
    final double top = topOf(pill);
    Widget picture(String at) => Positioned(
      left: -(_cardWidth - _window) / 2 * k,
      top: -top * k,
      width: _cardWidth * k,
      height: _cardHeight * k,
      child: Image(
        image: CardThumb.image(CardThumb.urlOf(at)),
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(child: plain),
        picture(ref),
        if (sharp) picture(CardThumb.largeOf(ref)),
      ],
    );
  }
}

/// One of the three ways the day goes out.
class _Shape extends StatelessWidget {
  const _Shape({
    super.key,
    required this.label,
    required this.layout,
    required this.on,
    required this.onTap,
  });

  final String label;
  final DayLayout layout;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color ink = on ? p.onInverse : p.inkMuted;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
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
              // own proportions, with what is in it: a crop icon at this
              // size read as a stray mark rather than as any shape.
              CustomPaint(
                size: Size(layout == DayLayout.story ? 9 : 12.8, 16),
                painter: _ShapeMark(layout: layout, ink: ink),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: AppText.body(
                  size: 13,
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

/// A frame in a layout's proportions, with its arrangement in small: one
/// block over lines for the cover, blocks beside lines for the list.
class _ShapeMark extends CustomPainter {
  const _ShapeMark({required this.layout, required this.ink});

  final DayLayout layout;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final Paint fill = Paint()..color = ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.8),
        const Radius.circular(2.5),
      ),
      line,
    );
    final double x = 3.2, w = size.width - 6.4;
    switch (layout) {
      case DayLayout.cover || DayLayout.story:
        canvas.drawRect(Rect.fromLTWH(x, 3.2, w * 0.55, w * 0.55), fill);
        for (final double y in [size.height - 6, size.height - 4]) {
          canvas.drawRect(Rect.fromLTWH(x, y, w, 0.9), fill);
        }
      case DayLayout.list:
        for (final double y in [3.2, 7.0, 10.8]) {
          canvas.drawRect(Rect.fromLTWH(x, y, 2.2, 2.2), fill);
          canvas.drawRect(Rect.fromLTWH(x + 3.2, y + 0.7, w - 3.2, 0.9), fill);
        }
    }
  }

  @override
  bool shouldRepaint(_ShapeMark old) => old.layout != layout || old.ink != ink;
}
