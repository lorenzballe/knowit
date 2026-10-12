import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The one way up the app is held.
///
/// Astute is read upright, a card at a time, on a phone held in one hand;
/// none of its screens is better on its side, and a card turned sideways
/// mid-read lost its place. The iPhone's Info.plist and Android's manifest
/// already say so before the first frame; this says it again to Flutter,
/// so that nothing it builds asks to turn either. An iPad is left alone:
/// iPadOS sizes every app's window itself, whatever the app asks.
const List<DeviceOrientation> kUpright = [DeviceOrientation.portraitUp];

/// Holds the app upright. Never throws: a host with no orientation to set —
/// a browser, a desktop, a test — simply has nothing to hold.
Future<void> holdUpright() async {
  if (kIsWeb) return;
  try {
    await SystemChrome.setPreferredOrientations(kUpright);
  } catch (_) {}
}
