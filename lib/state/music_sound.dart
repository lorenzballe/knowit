import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';

/// Whether the music cards sound. Off until the reader turns it on, in
/// Profile or from a card's Listen: one setting for every card, kept. Off,
/// a card still draws and names every note it would have played.
abstract final class MusicSound {
  static const _key = 'knowit.musicSound';

  static final ValueNotifier<bool> on = ValueNotifier<bool>(false);

  static SharedPreferences? _prefs;

  /// Reads the setting kept on this phone; none kept is off.
  static void load(SharedPreferences prefs) {
    _prefs = prefs;
    on.value = prefs.getBool(_key) ?? false;
  }

  /// [from] is where it was switched: `profile` or `card`.
  static Future<void> set(bool value, {required String from}) async {
    if (on.value == value) return;
    on.value = value;
    Analytics.capture('music sound switched', {'on': value, 'from': from});
    await _prefs?.setBool(_key, value);
  }
}
