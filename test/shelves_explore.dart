// Explore as it was before the strategic Explore — every shelf it always
// had, in its order — for the tests of those shelves on the Explore screen.
//
// The build's own Explore (lib/explore/blocks/core/own_explore.dart) opens
// on the reader's day and keeps only four of the old shelves; the others
// are still blocks, placed from the server. The tests that play them where
// they stood draw the old list, kept as a document of its own
// (remote/examples/explore-shelves.json), as their baseline.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/remote/remote.dart';

/// Every test of the file calling this starts from a document whose
/// Explore is the old shelves, and the file leaves the baseline as it found
/// it.
void useShelvesExplore() {
  RemoteConfig? before;
  setUpAll(() {
    before = Remote.baseline;
    final Object? doc = jsonDecode(
      File('remote/examples/explore-shelves.json').readAsStringSync(),
    );
    Remote.baseline = RemoteConfig(
      hash: 'the-shelves',
      schema: kRemoteSchema,
      parts: {'explore': doc},
    );
    Remote.reset();
  });
  tearDownAll(() {
    Remote.baseline = before;
    Remote.reset();
  });
}
