// The bank with pictures: the shipped bank, with some of its free cards
// given the two pictures tool/cards/bundle.py names once a page has been
// photographed, and a picture that comes without the network.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import 'package:astuto/data/embedded_bank.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';

/// The free cards of the shipped bank that name their page, in its order.
List<Pill> pagedCards() => [
  for (final Pill p in PillBank.embedded.cards)
    if (p.web?.page != null && p.hasPage) p,
];

/// The shipped bank, with the cards of [ids] given a front and a back, and
/// every other card none.
BankBundle bankWithPictures(Set<String> ids) {
  final Map<String, Object?> doc =
      jsonDecode(kEmbeddedBank) as Map<String, Object?>;
  final List<Object?> cards = [
    for (final Object? raw in doc['cards'] as List)
      if (raw is Map && ids.contains(raw['id']) && raw['web'] is Map)
        {
          ...raw,
          'web': {
            ...raw['web'] as Map,
            'thumbs': {
              'front': 'thumbs/${raw['id']}-front.webp?v=0123456789ab',
              'back': 'thumbs/${raw['id']}-back.webp?v=0123456789ab',
            },
          },
        }
      // The shipped bank names pictures for every free card it has them for;
      // the cards not in [ids] are put back to none, so a test chooses.
      else if (raw is Map && raw['web'] is Map)
        {
          ...raw,
          'web': {...raw['web'] as Map}..remove('thumbs'),
        }
      else
        raw,
  ];
  return BankBundle.parse(jsonEncode({...doc, 'cards': cards}));
}

/// A picture that comes at once, from memory: one pixel of green.
///
/// A real PNG, that decodes. The one here before had a broken data stream:
/// a test that never let it finish decoding drew it as loading, one that
/// did drew the card's fallback instead, and the same test passed on one
/// machine and failed on another.
final ImageProvider onePixel = MemoryImage(
  Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNg'
      'OFHxHwAETAJAXeAKlwAAAABJRU5ErkJggg==',
    ),
  ),
);
