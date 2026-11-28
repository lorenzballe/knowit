import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'consent_card.dart';
import 'parts_offer.dart';

/// What the finished day's shelf asks of the reader, one thing at a time
/// and never as a sheet over it: the question about usage data until it is
/// answered (lib/widgets/consent_card.dart), then, once, Which parts from
/// the third finished day (lib/widgets/parts_offer.dart). Nothing at all on
/// most evenings.
///
/// One a sitting: a card answered folds away and leaves the shelf as it is
/// on any evening, and the other waits for the next time the shelf is
/// opened rather than rise in its place.
class ShelfAsk extends StatefulWidget {
  const ShelfAsk({
    super.key,
    required this.app,
    this.padding = EdgeInsets.zero,
  });

  final AppState app;

  /// Around the card, when there is one: none when there is not.
  final EdgeInsets padding;

  /// Whether the shelf asks anything this evening.
  static bool any(AppState app) =>
      ConsentCard.due(app) || PartsOfferCard.due(app);

  /// The least height of screen, in points at the reader's text size, that
  /// leaves the shelf's own cards room enough beside a card asking: an SE
  /// has (667), a 568-point phone has not, nor any phone at twice the text,
  /// and the cards of the day squeezed to thumbnails would be the price.
  /// Nothing is asked there; Profile's Usage data and the fine-tuning's
  /// parts are there all the same.
  static const double leastRoom = 580;

  @override
  State<ShelfAsk> createState() => _ShelfAskState();
}

enum _Asked { consent, parts }

class _ShelfAskState extends State<ShelfAsk> {
  /// The card this shelf has put up, kept in place once it has been: it
  /// folds itself away when answered, and nothing takes its place.
  _Asked? _asked;

  @override
  Widget build(BuildContext context) {
    final AppState app = widget.app;
    // Whenever there is no room: the text made larger, or the phone turned,
    // with a card already up, puts it away too.
    if (MediaQuery.sizeOf(context).height /
            MediaQuery.textScalerOf(context).scale(1) <
        ShelfAsk.leastRoom) {
      return const SizedBox.shrink();
    }
    if (_asked == null) {
      if (ConsentCard.due(app)) {
        _asked = _Asked.consent;
      } else if (PartsOfferCard.due(app)) {
        _asked = _Asked.parts;
      }
    }
    return switch (_asked) {
      _Asked.consent => ConsentCard(
        key: const ValueKey('shelf-ask-consent'),
        app: app,
        padding: widget.padding,
      ),
      _Asked.parts => PartsOfferCard(
        key: const ValueKey('shelf-ask-parts'),
        app: app,
        padding: widget.padding,
      ),
      null => const SizedBox.shrink(),
    };
  }
}
