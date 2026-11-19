import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../models/pill.dart';
import '../theme.dart';
import '../utils/share_image.dart';
import '../utils/share_link.dart';
import '../utils/share_origin.dart';
import 'ui.dart';
import 'scaled_text.dart';

/// Opens the share sheet for [pill]: the card as it leaves, and the ways it
/// can go.
///
/// A card leaves as a line and a link, never as its answer. It used to go
/// as a picture with the whole answer under it — the worked steps, the other
/// side, the bar move and the source — which in a chat is a wall of words
/// that spoils the one thing worth sending: the question. Now the message is
/// the question and the card's page (tool/cards/challenge_pages.py), where
/// the friend answers first and the answer comes on a tap, and where a chat
/// draws its preview from: the card's drawing, or its subject's picture.
/// The picture is still there, as a second way, for a story or a feed.
Future<void> showShareSheet(BuildContext context, Pill pill) {
  Analytics.capture('share sheet opened', {
    'kind': 'pill',
    'pill_id': pill.id,
    'topic': pill.topic,
  });
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => _ShareSheet(pill: pill),
  );
}

class _ShareSheet extends StatefulWidget {
  final Pill pill;
  const _ShareSheet({required this.pill});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  /// What the card leaves as: a line that says what is asked of the friend
  /// — answering it, taking a side, or nothing more than the question for a
  /// card that tells — its question, and its page. Short enough for a chat,
  /// and nothing in it gives the answer away.
  String get _message {
    final Pill pill = widget.pill;
    final l = context.l10n;
    final String? ask = pill.challenge is TakeASide
        ? l.shareWhichSide
        : pill.asksSomething
        ? l.challengeLine
        : null;
    return [?ask, pill.question, cardLink(pill.id)].join('\n');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Rasterises the preview card at 3x so the export is usable at story size.
  Future<Uint8List?> _capture() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast(l.couldNotRenderCard);
        return;
      }
      final name = 'astuto-${widget.pill.id}.png'.replaceAll(
        RegExp(r'[^\w.-]'),
        '-',
      );
      // On a phone this opens the system share sheet with the image in it;
      // in a browser it downloads. It used to copy the text on a phone and
      // say the image was "web-only", which meant the one thing this sheet
      // is for did not work on the one device anybody uses it on.
      final shared = await shareCardImage(
        bytes,
        name,
        _message,
        origin: mounted ? shareOrigin(context) : null,
      );
      Analytics.capture('pill shared', {
        'pill_id': widget.pill.id,
        'topic': widget.pill.topic,
        // Whether the image reached the system sheet, or the app fell back
        // to putting the words on the clipboard.
        'as': shared ? 'image' : 'text',
      });
      if (!shared) {
        await Clipboard.setData(ClipboardData(text: _message));
        _toast(l.textCopiedInstead);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The message, to the system sheet: a chat shows it with the card's
  /// preview under it. Where there is no sheet it is copied instead.
  Future<void> _send() async {
    final l = context.l10n;
    final String text = _message;
    final bool shared = await sendText(text);
    Analytics.capture('pill shared', {
      'pill_id': widget.pill.id,
      'topic': widget.pill.topic,
      'as': shared ? 'link' : 'copied',
      'has_page': widget.pill.hasPage,
    });
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      _toast(l.copiedToClipboard);
    }
  }

  /// The card's page alone, for wherever the reader wants to put it.
  Future<void> _copyLink() async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: cardLink(widget.pill.id)));
    Analytics.capture('pill shared', {
      'pill_id': widget.pill.id,
      'topic': widget.pill.topic,
      'as': 'link copied',
      'has_page': widget.pill.hasPage,
    });
    _toast(l.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return Container(
      decoration: BoxDecoration(
        color: context.p.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).padding.bottom + 24,
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
                  color: context.p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.shareThisCard,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _cardKey,
              // An image, not a screen: set at one size whatever the
              // reader's text size, or a large setting crops the question
              // off a picture somebody else will see at theirs.
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: _ShareCard(pill: pill),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              key: const ValueKey('share-send'),
              label: context.l10n.shareSendCard,
              height: 52,
              onPressed: _busy ? null : _send,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    key: const ValueKey('share-image'),
                    icon: Icons.image_outlined,
                    label: _busy
                        ? context.l10n.rendering
                        : context.l10n.shareAsImage,
                    onTap: _busy ? null : _shareImage,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineAction(
                    key: const ValueKey('share-copy-link'),
                    icon: Icons.link_rounded,
                    label: context.l10n.shareCopyLink,
                    onTap: _copyLink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.shareAnswerNote,
              key: const ValueKey('share-note'),
              textAlign: TextAlign.center,
              // The palette's, not black: on the night sheet black was not
              // there to read.
              style: AppText.body(
                size: 12,
                height: 1.4,
                color: context.p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card that leaves — four by five, the shape a phone screen and a feed
/// both take without cropping.
///
/// It is the question, because that is what makes somebody stop, and what
/// is asked of them; the answer is on the card's page, a tap away, never on
/// the picture. The subject and the mark are small: a card in someone
/// else's chat is the only free distribution this app has, and it should
/// look like a thought, not an advertisement.
class _ShareCard extends StatelessWidget {
  final Pill pill;
  const _ShareCard({required this.pill});

  @override
  Widget build(BuildContext context) {
    final onCard = pill.ink;
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.subjectOf(pill.topic).toUpperCase(),
              style: AppText.label(
                size: 10.5,
                spacing: 1.5,
                color: onCard.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 18),
            // Set as large as the space above the bar move will take: the
            // card is four by five whatever the question's length, so a long
            // question comes down in size rather than running off the foot.
            Expanded(
              child: ScaledText(
                text: pill.question,
                min: 16,
                max: 40,
                alignment: Alignment.topLeft,
                styleFor: (size) => AppText.display(
                  size: size,
                  weight: FontWeight.w600,
                  height: 1.14,
                  spacing: -0.9 * size / 27,
                  color: onCard,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // What is asked, and nothing of the answer: a picture in a feed
            // is a question to stop on, and the answer is a tap away on
            // the card's page.
            if (pill.asksSomething)
              Text(
                pill.challenge is TakeASide
                    ? context.l10n.shareWhichSide
                    : context.l10n.challengeLine,
                style: AppText.body(
                  size: 14.5,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: onCard.withValues(alpha: 0.85),
                ),
              ),
            const SizedBox(height: 16),
            // The name, and where to find it: a picture in a chat or a
            // story loses the link that went with it, so the address is
            // on the picture itself.
            Row(
              children: [
                Text(
                  'Astute',
                  style: AppText.display(
                    size: 14,
                    weight: FontWeight.w600,
                    color: onCard.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  kSiteHost,
                  style: AppText.body(
                    size: 10.5,
                    weight: FontWeight.w600,
                    spacing: 0.2,
                    color: onCard.withValues(alpha: 0.55),
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

/// A button with a line round it, its icon beside its word: the two ways a
/// card leaves besides the message.
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.p.lineStrong),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: context.p.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w700,
                    color: context.p.ink,
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
