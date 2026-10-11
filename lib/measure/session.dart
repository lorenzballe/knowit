import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../analytics.dart';
import 'screens.dart';

/// One time the app was in front of the reader, from opening or coming back
/// to leaving, said once as it ends — with 'app paused', which is when it
/// ends (see main.dart).
///
/// Counts only. Which screens, cards and shelves those were is said by their
/// own events; this is the shape of the sitting: how long, how much, how it
/// began, at what hour, and whether the phone kept up.
class Session {
  Session._();

  static final Session instance = Session._();

  /// Since this session began. The first one began when main() did.
  final Stopwatch _clock = Stopwatch()..start();

  /// Whether this is the session the app started with.
  bool _cold = true;

  /// How it began: `cold start`, `warm resume`, or what brought the reader
  /// in — a `notification` or a `widget`.
  String _entry = 'cold start';

  /// What brought the app forward, when it was said before the session
  /// began: a reminder's tap can arrive a moment ahead of the resume.
  String? _waitingEntry;
  final Stopwatch _sinceWaiting = Stopwatch();

  DateTime _began = DateTime.now();

  int _screens = 0;
  int _answered = 0;
  int _exploreVisits = 0;
  int _exploreOpens = 0;
  final Set<String> _cards = {};
  final FrameMeter frames = FrameMeter();

  /// A reminder's or a widget's tap that is still recent enough to be what
  /// opened the session.
  static const Duration _entryWindow = Duration(seconds: 10);

  /// Whether this session is the one the app was started into.
  bool get isCold => _cold;

  /// Starts the session clock from main(), so the first session is timed
  /// from the moment the app began rather than from whenever this was first
  /// asked about.
  void launched() {
    _clock
      ..reset()
      ..start();
    _began = DateTime.now();
  }

  /// The app came back to the screen: a new session, until it leaves again.
  void begin() {
    _cold = false;
    _clock
      ..reset()
      ..start();
    _began = DateTime.now();
    _entry = 'warm resume';
    if (_waitingEntry != null && _sinceWaiting.elapsed < _entryWindow) {
      _entry = _waitingEntry!;
    }
    _waitingEntry = null;
    _screens = 0;
    _answered = 0;
    _exploreVisits = 0;
    _exploreOpens = 0;
    _cards.clear();
    frames.reset();
    Screens.instance.foreground();
  }

  /// What brought the reader in: a `notification` or a `widget`. Heard
  /// within the first seconds of a session, it is how that session began;
  /// heard just before one begins, it is kept for it.
  void cameFrom(String how) {
    if (_clock.elapsed < _entryWindow) _entry = how;
    _waitingEntry = how;
    _sinceWaiting
      ..reset()
      ..start();
  }

  void screenBegun(String name) {
    _screens++;
    if (name == 'explore') _exploreVisits++;
  }

  void cardSeen(String id) => _cards.add(id);

  void answered() => _answered++;

  void exploreOpened() => _exploreOpens++;

  /// Ends the session: every screen visit ends with it, and what it came
  /// to is returned for 'app paused' to carry.
  Map<String, Object?> end() {
    Screens.instance.background();
    _clock.stop();
    final Map<String, Object?> said = {
      // How long the app was in front this time — this session, not the
      // whole life of the process, which a phone keeps for days.
      'ms_in_app': _clock.elapsedMilliseconds,
      'entry': _entry,
      'screens': _screens,
      'cards_seen': _cards.length,
      'cards_answered': _answered,
      'explore_visits': _exploreVisits,
      'explore_opens': _exploreOpens,
      'hour_local': _began.hour,
      'weekday': _began.weekday,
      ...frames.said(),
    };
    return said;
  }

  @visibleForTesting
  void resetForTest() {
    _cold = true;
    _entry = 'cold start';
    _waitingEntry = null;
    _screens = 0;
    _answered = 0;
    _exploreVisits = 0;
    _exploreOpens = 0;
    _cards.clear();
    frames.reset();
    launched();
    FirstCard._said = false;
  }
}

/// The frames the phone drew in a session, and how many came late.
///
/// Read from the engine's own frame timings, which it hands over in batches
/// about once a second; nothing is measured per frame here beyond two
/// comparisons. A frame is late — janky — when building it or drawing it
/// took longer than the screen's refresh allows: 16.7ms at 60Hz, 8.3ms at
/// 120Hz. In a debug build every frame is slow, so only release builds'
/// numbers mean anything.
class FrameMeter {
  int _frames = 0;
  int _janky = 0;
  int _worst = 0;

  /// The time a frame may take on this screen, in microseconds.
  int budgetMicros = 16667;

  void add(List<FrameTiming> timings) {
    for (final FrameTiming t in timings) {
      _frames++;
      final int build = t.buildDuration.inMicroseconds;
      final int raster = t.rasterDuration.inMicroseconds;
      final int longest = build > raster ? build : raster;
      if (longest > budgetMicros) _janky++;
      if (longest > _worst) _worst = longest;
    }
  }

  void reset() {
    _frames = 0;
    _janky = 0;
    _worst = 0;
  }

  /// What a session's summary carries: nothing at all where no frame was
  /// reported, which is a test, or a phone that drew nothing.
  Map<String, Object?> said() => _frames == 0
      ? const {}
      : {
          'frames': _frames,
          'janky_frames': _janky,
          'ms_worst_frame': (_worst / 1000).round(),
        };

  /// Starts listening to the engine. Once, from main(), and only where the
  /// app is measured.
  void listen() {
    try {
      final double rate =
          SchedulerBinding
              .instance
              .platformDispatcher
              .views
              .firstOrNull
              ?.display
              .refreshRate ??
          60;
      if (rate >= 30) budgetMicros = (1000000 / rate).round();
    } catch (_) {
      // A display that will not say: sixty frames a second.
    }
    SchedulerBinding.instance.addTimingsCallback(
      (timings) => Session.instance.frames.add(timings),
    );
  }
}

/// How long the reader waited, from tapping the app to the first card of
/// the day standing on screen, said once per start — and only when that is
/// what the start was: not after the first run, the come-back screen or a
/// card opened from a widget, any of which would be timing the reader.
class FirstCard {
  static bool _said = false;

  /// Told by the deck on Today when a card first stands on top with the
  /// reader looking at it.
  static void shown(Map<String, Object?> facts) {
    if (_said) return;
    _said = true;
    if (!Session.instance.isCold || Screens.instance.begun != 1) return;
    if (Screens.instance.current != 'today') return;
    Analytics.capture('first card shown', {
      'ms_to_first_card': Analytics.msSinceLaunch,
      ...facts,
    });
  }
}
