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

/// The shipped bank, with the cards of [ids] given a front and a back.
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
      else
        raw,
  ];
  return BankBundle.parse(jsonEncode({...doc, 'cards': cards}));
}

/// A picture that comes at once, from memory: one pixel of green.
final ImageProvider onePixel = MemoryImage(
  Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNg'
      'MPj/HwADhAJ/7Wc0bwAAAABJRU5ErkJggg==',
    ),
  ),
);
