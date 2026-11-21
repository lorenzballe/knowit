import 'package:flutter/material.dart';

import '../../models/pill.dart';
import 'page_gestures.dart';
import 'page_messages.dart';
import 'web_card_page.dart';
import 'web_card_poster.dart';

/// How visible a page is while it is loading underneath its poster, and a
/// card while it is held for its page: as near nothing as the screen
/// allows, but above the 1/255 at which a layer is skipped and the WebView
/// or iframe in it never comes up.
const double kWaitingOpacity = 0.01;

/// A deck whose card in front is a free card, kept out of sight while that
/// card's page draws and brought in whole once it has (see
/// [WebCardPage.hold]): the card, its question and its drawing arrive
/// together, the way a post arrives with its picture, instead of a poster
/// arriving and the drawing landing on it after; and the cards behind it
/// with it, so none stands in its place meanwhile.
///
/// Out of sight is [kWaitingOpacity], never 0, for the page inside to come
/// up at all; and nothing out of sight can be touched.
class PageHold extends StatelessWidget {
  const PageHold({
    super.key,
    required this.page,
    this.waiting = false,
    required this.child,
  });

  /// The live page of the card in front, which says whether it waits.
  final WebCardPage? page;

  /// Whether to wait while that card has no page yet: a free card, in the
  /// frame before its page is made.
  final bool waiting;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final WebCardPage? page = this.page;
    // One shape with a page or without, so a card keeps its element when
    // its page is made and is not built again from nothing.
    return ListenableBuilder(
      listenable: page ?? const AlwaysStoppedAnimation<double>(0),
      builder: (context, card) {
        final bool held = page == null ? waiting : page.holding;
        return IgnorePointer(
          ignoring: held,
          child: AnimatedOpacity(
            opacity: held ? kWaitingOpacity : 1,
            // Out of sight at once, in with a short fade.
            duration: held || MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: card,
          ),
        );
      },
      child: child,
    );
  }
}

/// A free card's front: its page, laid over its poster, filling the card.
///
/// The poster is there first and stays under the page. While the card is
/// held for its page ([PageHold]) the page is at full strength inside a
/// card out of sight, so both come in together; past the hold the poster
/// is shown and the page comes over it, with a short fade, only once it has
/// drawn its first frame, so a card never shows a blank or a half-made
/// page. Until then a finger on the card is the deck's, as on any card. The
/// frame around it — the corners, the edge, the shadow, the save and share
/// — is the card's (PillCard), so a free card sits in the deck as every
/// other card does.
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
    // Held, the card around it is out of sight: the page inside is at full
    // strength, so it is all there when the card comes in. (Two near-zero
    // opacities, one in the other, would be nearer nothing than a layer
    // may be and still be drawn.)
    final bool held = live && page.holding;
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
                // Never quite 0 while it waits: a layer at opacity 0 is not painted, so
                // the platform view under it is never put on screen, the page never
                // loads, and it never says it is ready. Nearly 0 hides it all the same.
                opacity: drawn || held ? 1 : kWaitingOpacity,
                // A page that draws over a poster already shown fades in; a
                // card let out of its hold before its page drew shows its
                // poster at once, with no half-made page fading out over it.
                // A card waiting under the top one has its clock stopped
                // (only the top card moves), and a fade needs its ticks:
                // under there it would stand at its first frame, the page
                // nearly nothing, until the card rose. It shows at once.
                duration:
                    !drawn ||
                        !TickerMode.valuesOf(context).enabled ||
                        MediaQuery.disableAnimationsOf(context)
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
