import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';
import 'place_finder.dart';

PlaceFinder devicePlaceFinder() => NativePlaceFinder();

/// Where the reader is, on a phone: the system's location, read once, and
/// the system's own geocoder to name it.
///
/// Only "while using the app" is ever asked for. iOS lets the reader give
/// the precise position or an approximate one, and Android is only asked
/// for the approximate one (ACCESS_COARSE_LOCATION): either is enough for a
/// city, and a phone that gives less is a phone asked for less.
class NativePlaceFinder implements PlaceFinder {
  NativePlaceFinder({bool? onPhone, DateTime Function()? clock})
    : onPhone = onPhone ?? (Platform.isIOS || Platform.isAndroid),
      _clock = clock ?? DateTime.now;

  /// Whether this is a phone. Everything else — the computer the tests run
  /// on, a desktop — has no place to give.
  final bool onPhone;

  final DateTime Function() _clock;

  /// How long a read may take before the app gives up on it: a fix from
  /// wifi and cell towers comes in a second or two, and a reader is not
  /// kept waiting for satellites over a city.
  static const Duration timeLimit = Duration(seconds: 10);

  /// Low accuracy: a kilometre on iOS, wifi and towers on Android. A city
  /// needs no more, and the battery is not spent on a street.
  static const LocationSettings settings = LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: timeLimit,
  );

  /// The language places are named in, whatever the phone's: so that
  /// Turin is Turin on an Italian phone and on a Japanese one, matches
  /// across readers, and matches PostHog's GeoIP names, which are English.
  ///
  /// This is what `setLocaleIdentifier('en_US')` did before geocoding 5,
  /// which deprecates it for a locale passed with each call. It is `en` and
  /// not `en_US` on purpose: the Android side builds its locale with
  /// `Locale.forLanguageTag`, which cannot read the underscore in "en_US"
  /// and falls back to no language at all.
  static const Locale namesIn = Locale('en');

  @override
  bool get canAsk => onPhone;

  @override
  Future<LocationAccess> access() async {
    if (!onPhone) return LocationAccess.unavailable;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.unavailable;
      }
      return _accessOf(await Geolocator.checkPermission(), asked: false);
    } catch (_) {
      return LocationAccess.unavailable;
    }
  }

  @override
  Future<LocationAccess> ask() async {
    if (!onPhone) return LocationAccess.unavailable;
    try {
      // With location switched off for the whole phone there is nothing a
      // prompt could give, and iOS would not show one.
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.unavailable;
      }
      return _accessOf(await Geolocator.requestPermission(), asked: true);
    } catch (_) {
      return LocationAccess.unavailable;
    }
  }

  /// The plugin's answer in the app's words. Its `denied` is "the prompt is
  /// still there to put" when only checked — on iOS it is the status
  /// nobody has decided yet — and "the reader said no" right after asking.
  static LocationAccess _accessOf(
    LocationPermission permission, {
    required bool asked,
  }) => switch (permission) {
    LocationPermission.whileInUse ||
    LocationPermission.always => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.deniedForever,
    LocationPermission.denied =>
      asked ? LocationAccess.denied : LocationAccess.notAsked,
    LocationPermission.unableToDetermine => LocationAccess.unavailable,
  };

  @override
  Future<bool?> precise() async {
    if (!onPhone) return null;
    try {
      return switch (await Geolocator.getLocationAccuracy()) {
        LocationAccuracyStatus.precise => true,
        LocationAccuracyStatus.reduced => false,
        LocationAccuracyStatus.unknown => null,
      };
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Place?> find() async {
    if (!onPhone) return null;
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
      } on TimeoutException {
        // No fresh fix in time: the last one the phone holds is still the
        // city it was in, which is all that is asked of it.
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return null;
      final List<Placemark> marks = await Geocoding()
          .placemarkFromCoordinates(
            position.latitude,
            position.longitude,
            locale: namesIn,
          )
          .timeout(timeLimit);
      final Placemark? mark = marks
          .where((m) => (m.isoCountryCode ?? '').trim().length == 2)
          .firstOrNull;
      if (mark == null) return null;
      // Rounded here, and the position goes out of scope with this call.
      return Place.fromPhone(
        isoCountry: mark.isoCountryCode!,
        adminArea: mark.administrativeArea,
        locality: mark.locality,
        lat: position.latitude,
        lon: position.longitude,
        at: _clock(),
      );
    } catch (_) {
      // Whatever went wrong may carry the position in its message, so it
      // is neither printed nor reported: the reader simply has no place
      // this time, and the app asks the phone again another day.
      return null;
    }
  }

  @override
  Future<bool> openSettings() async {
    if (!onPhone) return false;
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
