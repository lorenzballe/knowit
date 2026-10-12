import '../models/place.dart';
import 'place_finder.dart';

PlaceFinder devicePlaceFinder() => const WebPlaceFinder();

/// Where the reader is, in a browser: nowhere the app asks about.
///
/// A browser could be asked, but the place is a phone's question — the
/// reader's home, read where they read every day — and the site build is a
/// window onto the app rather than the app. So the web says it has nothing
/// to give, and every screen that would offer the question stays quiet.
class WebPlaceFinder implements PlaceFinder {
  const WebPlaceFinder();

  @override
  bool get canAsk => false;

  @override
  Future<LocationAccess> access() async => LocationAccess.unavailable;

  @override
  Future<LocationAccess> ask() async => LocationAccess.unavailable;

  @override
  Future<bool?> precise() async => null;

  @override
  Future<Place?> find() async => null;

  @override
  Future<bool> openSettings() async => false;
}
