import 'package:flutter/material.dart';

import '../../models/pill.dart';
import 'page_gestures.dart';
import 'page_messages.dart';
import 'web_card_page.dart';
import 'web_card_poster.dart';

/// A free card's front: its page, laid over its poster, filling the card.
///
/// The poster is there first and stays under the page; the page is shown,
/// with a short fade, only once it has drawn its first frame, so a card
/// never shows a blank or a half-made page. Until then a finger on the card
/// is the deck's, as on any card. The frame around it — the corners, the
/// edge, the shadow, the save and share — is the card's (PillCard), so a
/// free card sits in the deck as every other card does.
class WebCardFace extends StatefulWidget {
  const WebCardFace({
    super.key,
    required this.pill,
    this.page,
    this.onMessage,
    this.chip,
    this.note,
  });

  final Pill pill;

  /// The card's live page, when the deck keeps one for it. Without one the
  /// poster is the whole face.
  final WebCardPage? page;

  /// What the page asks of the deck, heard only on the card on top: a card
  /// waiting underneath is drawn, never answered.
  final ValueChanged<PageMessage>? onMessage;

  /// What the poster says beside the subject and under the head, as the
  /// page does.
  final String? chip;
  final String? note;

  @override
  State<WebCardFace> createState() => _WebCardFaceState();
}

class _WebCardFaceState extends State<WebCardFace> {
  @override
  void initState() {
    super.initState();
    _listen(null, widget.page);
  }

  @override
  void didUpdateWidget(covariant WebCardFace old) {
    super.didUpdateWidget(old);
    _listen(old.page, widget.page);
  }

  @override
  void dispose() {
    _listen(widget.page, null);
    super.dispose();
  }

  void _listen(WebCardPage? was, WebCardPage? now) {
    if (!identical(was, now)) {
      was?.removeListener(_changed);
      if (was != null && identical(was.listener, _heard)) was.listener = null;
      now?.addListener(_changed);
    }
    if (now == null) return;
    if (widget.onMessage != null) {
      now.listener = _heard;
    } else if (identical(now.listener, _heard)) {
      now.listener = null;
    }
  }

  void _heard(PageMessage message) => widget.onMessage?.call(message);

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final WebCardPage? page = widget.page;
    final bool live = page != null && !page.failed;
    final bool drawn = live && page.ready;
    final WebFace? web = widget.pill.web;
    return Semantics(
      container: true,
      label: widget.pill.question,
      hint: web == null || web.label.isEmpty ? null : web.label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebCardPoster(
            pill: widget.pill,
            fallback: !live,
            chip: widget.chip,
            note: widget.note,
          ),
          if (live)
            IgnorePointer(
              ignoring: !drawn || widget.onMessage == null,
              child: AnimatedOpacity(
                opacity: drawn ? 1 : 0,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: page.surface.view(
                  gestures: pageGestures(
                    web?.touch ?? WebTouch.taps,
                    zones: () => page.zones,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
