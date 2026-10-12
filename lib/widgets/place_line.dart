import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import '../models/place.dart';

/// Why a card about a place is in front of the reader, as the small line on
/// its front says it: "Near you · Modena", "Your region · Emilia-Romagna",
/// "Your country · Italy". Null on a card for everybody.
///
/// The names are the card's own place, in English for now like the cards
/// themselves: the city as the card names it, the region from its ISO code
/// ([regionDisplayName]), the country from its ([countryDisplayName]).
///
/// The claim is made only when it is true. A card that reached the reader
/// some other way — kept from before they moved, or sent by a friend who
/// lives there — names its place and says nothing about the reader's.
String? placeLineOf(BuildContext context, CardPlace? card, Place? home) {
  if (card == null) return null;
  final String? region = card.region == null
      ? null
      : regionDisplayName(card.region!) ?? card.region;
  final String country = countryDisplayName(card.country);
  final l = context.l10n;
  return switch (placeFit(card, home)) {
    PlaceFit.city => l.placeNearYou(card.city ?? country),
    PlaceFit.region => l.placeYourRegion(region ?? country),
    PlaceFit.country => l.placeYourCountry(country),
    PlaceFit.none => card.city ?? region ?? country,
  };
}
