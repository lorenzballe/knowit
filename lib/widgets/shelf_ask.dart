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
