import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

/// Runs before every test file in this directory.
///
/// The bank refreshes itself over HTTP at start-up. Under test that is a
/// request nobody wants: the harness would answer it with a 400 and move
/// on, quietly, which is exactly the kind of silence that hides a hang
/// when it stops being quiet. So the fetcher is a stub here, and a test
/// that wants a download provides its own. The same goes for the remote
/// document, which every launch and every return to the app asks for.
///
/// Every test starts from the build's own document, not from the one the
/// build embeds: that one is whatever the server said when the build was
/// made — an Explore of the week, words of the day — and a test that rested
/// on it would stop the next one from being published.
///
/// A free card's picture is fetched like any picture in a feed. Under test
/// none comes, so the card is drawn as it is without one; a test about the
/// pictures gives its own.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CardThumb.image = NoPicture.new;
  PillBank.fetch = (url) async => null;
  Remote.fetch = (url) async => null;
  Remote.baseline = const RemoteConfig(
    hash: 'the-build-own',
    schema: kRemoteSchema,
    parts: {},
  );
  Remote.reset();
  await testMain();
}

/// A picture that never comes: it fails at once, as one from a site out of
/// reach does. Never kept in the image cache, which outlives a test: a
/// failure kept from one would never reach the next.
class NoPicture extends ImageProvider<NoPicture> {
  const NoPicture([this.url]);

  /// The address it stands in for.
  final Uri? url;

  @override
  Future<NoPicture> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<NoPicture>(this);

  @override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    NoPicture key,
    ImageErrorListener handleError,
  ) => stream.setCompleter(_failed());

  @override
  ImageStreamCompleter loadImage(NoPicture key, ImageDecoderCallback decode) =>
      _failed();

  ImageStreamCompleter _failed() => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('no picture under test')),
  );

  @override
  bool operator ==(Object other) => other is NoPicture && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
