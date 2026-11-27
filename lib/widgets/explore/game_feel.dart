/// What a challenge feels like under the finger, the same in all twelve.
///
/// A tap is a light click, once however many parts of the screen answer
/// the same tap: a control of the kit clicks after its game has had its
/// say, and stays quiet when the game has just been felt (a verdict, a bet
/// laid). An answer told is a light tap when it is right and a firmer one
/// when it is wrong; never a jolt, which the owner found the games too
/// loud for. iOS plays them; elsewhere they are nothing.
library;

import 'package:flutter/services.dart';

abstract final class GameFeel {
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Felt within this of another: the same tap.
  static const Duration _same = Duration(milliseconds: 90);

  static bool get _justFelt => DateTime.now().difference(_last) < _same;

  /// A choice made, a button pressed, a step passed.
  static void tick() {
    if (_justFelt) return;
    _last = DateTime.now();
    HapticFeedback.selectionClick();
  }

  /// Something committed: a bet laid, a number locked, a pick said.
  static void commit() {
    _last = DateTime.now();
    HapticFeedback.mediumImpact();
  }

  /// An answer told: right, a light tap; wrong, a firmer one.
  static void verdict(bool right) {
    _last = DateTime.now();
    if (right) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }
}
