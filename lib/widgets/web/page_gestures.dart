/// How a page and the deck share the finger.
///
/// A platform view takes a touch only when one of its own recognisers wins
/// it in Flutter's gesture arena; every touch it does not win stays with
/// the widgets around it — here, the deck, which throws the card on a drag,
/// turns it on a tap and keeps it on a long hold. So what a page is given
/// is said with recognisers:
///
/// * a tap, always: buttons, choices and anything else on the page that is
///   pressed is the page's. A tap the page does nothing with comes back as
///   [PageTap], and turns the card over as a tap on any card does.
/// * on a card that holds the finger itself ([WebTouch.drags]), every touch
///   that starts on a part the page marked as its own (`data-drag`, or
///   `touch-action: none`: a slider, a canvas to draw on, a game), taken at
///   once, before the deck could see it as the start of a throw.
///
/// Everything else is the deck's: a drag that starts anywhere else on the
/// card throws it, as on every card; a hold keeps it. That is the native
/// affordance a game card moves on by: the card is still a card everywhere
/// the page is not playing, its head and its words and its foot, and the
/// page can also send it on itself ([PageDone]) when it is over.
library;

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../../models/pill.dart';

/// Wins at once every touch that starts inside one of [zones], in the
/// page's own pixels; leaves every other touch alone.
class PageZoneRecognizer extends OneSequenceGestureRecognizer {
  PageZoneRecognizer({required this.zones, super.debugOwner});

  /// Where the page holds the finger, as it last said.
  final List<Rect> Function() zones;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      super.isPointerAllowed(event) &&
      zones().any((zone) => zone.contains(event.localPosition));

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {}

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'page zone';
}

/// The recognisers a page is drawn with: taps always, and on a card that
/// holds the finger, the touches that start in its [zones].
///
/// The tap has something to do, though the page does the doing: a tap
/// recogniser with no callback never enters the arena, and could not win
/// the tap for the page.
Set<Factory<OneSequenceGestureRecognizer>> pageGestures(
  WebTouch touch, {
  required List<Rect> Function() zones,
}) => {
  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()..onTap = _page),
  if (touch == WebTouch.drags)
    Factory<PageZoneRecognizer>(() => PageZoneRecognizer(zones: zones)),
};

void _page() {}
