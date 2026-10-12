import 'package:flutter/foundation.dart';

import '../models/place.dart';
import 'place_finder_native.dart'
    if (dart.library.js_interop) 'place_finder_web.dart'
    as device;

/// What the phone says about the app reading where the reader is.
///
/// Five answers, because each asks for something different of the app:
/// [notAsked] means the system's own prompt is still there to put, so the
/// app's sheet may lead to it; [granted] that the place can be read;
/// [denied] that the reader said no to the prompt just put; [deniedForever]
/// that the system will not ask again, so the only way back is the app's
/// page in the phone's settings; and [unavailable] that there is nothing to
/// ask here at all — the web, a phone with location services switched off.
enum LocationAccess {
  notAsked,
  granted,
  denied,
  deniedForever,
  unavailable;

  /// As an event carries it: `not_asked`, `denied_forever`.
  String get key => switch (this) {
    LocationAccess.notAsked => 'not_asked',
    LocationAccess.deniedForever => 'denied_forever',
    _ => name,
  };
}

/// Reads where the reader lives, once, and names it on the phone.
///
/// An interface, like the store and the trace, so the app can be driven in
/// a test without a phone, a permission prompt or a satellite. The one that
/// runs on a phone is in place_finder_native.dart; the web build has
/// nothing to read and says so (place_finder_web.dart).
///
/// The promise every implementation keeps: what comes back is a [Place],
/// built by [Place.fromPhone], which rounds the point to a tenth of a
/// degree. The position the phone gives is read, named and dropped inside
/// [find]. It is never returned, kept, logged, traced or sent, and an error
/// that might carry it is swallowed, not reported.
abstract class PlaceFinder {
  /// The app's one finder. Replaced under test, like the store's.
  static PlaceFinder instance = device.devicePlaceFinder();

  @visibleForTesting
  static void useForTest(PlaceFinder? finder) =>
      instance = finder ?? device.devicePlaceFinder();

  /// Whether this build can read a place at all: a phone. False on the web
  /// and on the computer the tests run on, so nothing leads a reader up to
  /// a question nobody can answer.
  bool get canAsk;

  /// The permission as the system holds it now, without asking anything.
  Future<LocationAccess> access();

  /// Puts the system's own prompt, for "while using the app" — never
  /// "always" — when it is still there to put, and says what came of it.
  /// Where it was answered before, it answers at once and shows nothing.
  Future<LocationAccess> ask();

  /// Whether the reader let the app have the precise position or only an
  /// approximate one; null where the system does not say. Either is enough
  /// for a city.
  Future<bool?> precise();

  /// Reads one position, at low accuracy and for no longer than about ten
  /// seconds, turns it into a place on the phone, and keeps only that.
  /// Null when there was no position, or no name for it.
  Future<Place?> find();

  /// Opens the app's page in the phone's settings, where a permission the
  /// system will no longer ask for can be given. False where it cannot.
  Future<bool> openSettings();
}
