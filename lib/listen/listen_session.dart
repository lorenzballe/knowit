/// The day's five read aloud, as one sitting: which card is being read and
/// how far into it, what each card came to, and what the reader may hear.
///
/// Each card is asked of the server as it is needed, one ahead of the card
/// being read (lib/sync/listen_client.dart), and goes into the queue as four
/// sounds: its question, the pause to think, its answer, a breath. On the
/// free plan the first card that can be heard is the reader's, and the
/// sitting stops after it on the offer of the rest ([ListenPhase.offer]);
/// with Astute+, all five. A card with nothing to hear is passed over and
/// said so; one that cannot be had right now is passed over too, and if
/// none can, the sitting says, calmly, that listening is not available.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics.dart';
import '../models/pill.dart';
import '../sync/listen_client.dart';
import 'listen_audio.dart';

/// Where the sitting is.
enum ListenPhase {
  /// Asking for the first card.
  preparing,

  /// A card's question is being read.
  question,

  /// The pause to think, after the question.
  think,

  /// Its answer, and why.
  answer,

  /// The breath before the next card.
  turn,

  /// The next card is still coming (a slow network).
  waiting,

  /// The day's free card is heard, and the rest are Astute+'s.
  offer,

  /// Every card that could be heard was.
  done,

  /// Nothing can be heard right now.
  unavailable,
}

/// What a card of the five came to.
enum ListenCardState {
  /// Not yet read.
  waiting,

  /// Read through to the end of its answer.
  heard,

  /// Nothing sensible to read aloud: passed over.
  nothing,

  /// Not available right now: passed over.
  unavailable,

  /// Astute+'s: the free plan heard its card for the day.
  locked,
}

/// The four sounds of a card, in the order they are heard.
enum _Part { question, think, answer, turn }

class ListenSession extends ChangeNotifier {
  ListenSession({
    required List<Pill> cards,
    required this.date,
    required this.tz,
    required bool plus,
    this.facts,
    this.from = 'today',
    ListenAudio? audio,
    ListenCall? call,
    DateTime Function()? clock,
  }) : cards = List.unmodifiable(cards),
       _hasPlus = plus,
       _audio = audio ?? ListenAudio.make(),
       _call = call ?? ListenClient.call,
       _clock = clock ?? DateTime.now,
       states = List.filled(cards.length, ListenCardState.waiting);

  /// The day's cards, in the day's order.
  final List<Pill> cards;

  /// The reader's day, as the server files the free card under it.
  final String date;

  /// The phone's clock, in minutes from UTC.
  final int tz;

  /// A card's facts for what is measured (AppState.cardFacts).
  final Map<String, Object?> Function(String id)? facts;

  /// Where the sitting was opened from, for what is measured.
  final String from;

  final ListenAudio _audio;
  final ListenCall _call;
  final DateTime Function() _clock;

  /// What each card came to, by its place in [cards].
  final List<ListenCardState> states;

  bool _hasPlus;

  /// Whether the reader holds Astute+: all five, rather than the first.
  bool get plus => _hasPlus;

  ListenPhase _phase = ListenPhase.preparing;
  ListenPhase get phase => _phase;

  /// The card being read, by its place; -1 before the first.
  int get at => _at;
  int _at = -1;

  bool _playing = false;

  /// Whether a sound is playing (and not paused).
  bool get playing => _playing;

  /// Why nothing could be heard, when [phase] is unavailable: what the
  /// server said, for the logs and the developer tools.
  String? get whyUnavailable => _whyUnavailable;
  String? _whyUnavailable;

  // The queue: for each sound in it, its card and which of the four it is.
  final List<(int, _Part)> _queue = [];
  bool _started = false;
  int _next = 0;
  bool _fetching = false;
  int? _free;
  int? _skipTo;
  Duration _position = Duration.zero;
  Duration? _duration;
  StreamSubscription<ListenAudioState>? _sub;
  DateTime? _startedAt;
  bool _finished = false;
  bool _closed = false;

  /// The card on the free plan that was the reader's for the day.
  int? get freeCard => _free;

  /// How many cards were read through.
  int get heard => states.where((s) => s == ListenCardState.heard).length;

  /// How far the card at [k] has been read, from 0 to 1: the question is the
  /// first third of it, the pause the next sliver, the answer the rest.
  double progressOf(int k) {
    if (states[k] == ListenCardState.heard) return 1;
    if (k != _at || _queue.isEmpty) return 0;
    final Duration? whole = _duration;
    final double f = whole == null || whole.inMilliseconds <= 0
        ? 0
        : (_position.inMilliseconds / whole.inMilliseconds).clamp(0.0, 1.0);
    return switch (_part) {
      _Part.question => 0.32 * f,
      _Part.think => 0.32 + 0.14 * f,
      _Part.answer => 0.46 + 0.54 * f,
      _Part.turn => 1,
      null => 0,
    };
  }

  _Part? _part;

  /// Whether the card after the one being read is Astute+'s, so going on
  /// is the offer, not the next card.
  bool get nextIsLocked =>
      !_hasPlus &&
      states.contains(ListenCardState.locked) &&
      _phase != ListenPhase.done;

  /// Starts: asks for the first card, and plays it as soon as it comes.
  Future<void> begin() async {
    _startedAt = _clock();
    Analytics.capture('listen started', {
      'cards': cards.length,
      'is_plus': _hasPlus,
      'from': from,
    });
    _sub = _audio.states.listen(_onAudio);
    await _fetchMore();
  }

  /// Play, or pause; once everything is heard, from the start again.
  Future<void> toggle() async {
    if (_closed) return;
    if (_phase == ListenPhase.done && _queue.isNotEmpty) {
      _finished = false;
      await _audio.jump(0);
      return;
    }
    if (_phase == ListenPhase.unavailable && !_started) {
      _phase = ListenPhase.preparing;
      _whyUnavailable = null;
      _next = 0;
      for (int k = 0; k < states.length; k++) {
        if (states[k] == ListenCardState.unavailable) {
          states[k] = ListenCardState.waiting;
        }
      }
      notifyListeners();
      await _fetchMore();
      return;
    }
    if (_playing) {
      await _audio.pause();
    } else if (_started) {
      await _audio.play();
    }
  }

  /// On to the next card's question; past the last, the end.
  Future<void> next() async {
    if (_closed || !_started) return;
    final int k = _at < 0 ? 0 : _at + 1;
    final int index = _queue.indexWhere(
      (e) => e.$1 >= k && e.$2 == _Part.question,
    );
    if (index >= 0) {
      await _audio.jump(index);
      return;
    }
    if (nextIsLocked) {
      await _audio.pause();
      _setPhase(ListenPhase.offer);
      return;
    }
    if (_next < cards.length) {
      // Still coming: wait for it, then go straight to it.
      _skipTo = k;
      await _audio.pause();
      _setPhase(ListenPhase.waiting);
      await _fetchMore();
      return;
    }
    await _audio.pause();
    _finish();
  }

  /// The reader took Astute+ from the offer: the rest of the five follow.
  Future<void> unlock() async {
    if (_closed || _hasPlus) return;
    _hasPlus = true;
    for (int k = 0; k < states.length; k++) {
      if (states[k] == ListenCardState.locked) {
        states[k] = ListenCardState.waiting;
      }
    }
    _setPhase(ListenPhase.waiting);
    await _fetchMore();
  }

  /// The sheet is closed: what was heard is said, and the sound stops.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_finished && _startedAt != null) {
      Analytics.capture('listen stopped', {
        'heard': heard,
        'at': _at + 1,
        'of': cards.length,
        'phase': _phase.name,
        'is_plus': _hasPlus,
        'ms_listening': _clock().difference(_startedAt!).inMilliseconds,
        'why': _whyUnavailable,
      });
    }
    // Let go without waiting on the subscription: the queue is stopped
    // whatever it says on its way out.
    final StreamSubscription<ListenAudioState>? sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    await _audio.dispose();
  }

  /// Nothing is said to a sheet that has gone.
  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }

  // ── The queue ──────────────────────────────────────────────────────────

  /// Asks for the next card that can be heard and puts it in the queue: one
  /// ahead of the card being read, and never past the free plan's one.
  Future<void> _fetchMore() async {
    if (_closed) return;
    if (_fetching) {
      // Asked again while asking (a card began as the last one came): once
      // this ask is over, the next.
      _again = true;
      return;
    }
    _fetching = true;
    try {
      while (_next < cards.length) {
        final int k = _next;
        if (!_hasPlus && _free != null) {
          _lockFrom(k);
          break;
        }
        final ListenReply reply = await _call(cards[k].id, date: date, tz: tz);
        if (_closed) return;
        switch (reply) {
          case ListenClips(:final Uri question, :final Uri answer):
            _next = k + 1;
            if (!_hasPlus) {
              // The day's one card on the free plan: the rest are Astute+'s.
              _free = k;
              _lockFrom(k + 1);
            }
            await _enqueue(k, question, answer);
            return;
          case ListenNone(why: ListenWhyNot.nothing):
            _next = k + 1;
            states[k] = ListenCardState.nothing;
            notifyListeners();
          case ListenNone(why: ListenWhyNot.notConfigured):
            ListenClient.unconfigured.value = true;
            _unavailable('not-configured');
            return;
          case ListenNone(why: ListenWhyNot.plus):
            // The server counts this reader's free card as heard already
            // today: the rest is Astute+'s.
            _next = cards.length;
            _lockFrom(k);
            if (!_started) _setPhase(ListenPhase.offer);
            return;
          case ListenNone(:final String? detail):
            _next = k + 1;
            states[k] = ListenCardState.unavailable;
            _whyUnavailable = detail ?? 'later';
            notifyListeners();
            // On the free plan the one card is the day's: there is no
            // other to try. With Astute+ the next may have been made.
            if (!_hasPlus) {
              if (!_started) _unavailable(_whyUnavailable!);
              return;
            }
        }
      }
      // Nothing more to ask for: a queue that already ran dry is the end.
      if (_started && _audioEnded) _arrive();
      if (!_started && _phase != ListenPhase.offer) {
        _unavailable(_whyUnavailable ?? 'nothing');
      }
    } finally {
      _fetching = false;
      if (_again) {
        _again = false;
        if (_hasPlus) scheduleMicrotask(_fetchMore);
      }
    }
  }

  bool _again = false;
  bool _audioEnded = false;

  Future<void> _enqueue(int k, Uri question, Uri answer) async {
    final List<ListenSound> sounds = [
      ListenClip(question),
      ListenTone.think,
      ListenClip(answer),
      ListenTone.turn,
    ];
    final int first = _queue.length;
    _queue.addAll([for (final _Part p in _Part.values) (k, p)]);
    if (!_started) {
      _started = true;
      await _audio.start(sounds);
    } else {
      await _audio.add(sounds);
      if (_skipTo != null && k >= _skipTo!) {
        _skipTo = null;
        await _audio.jump(first);
      }
    }
  }

  void _lockFrom(int k) {
    for (int i = k; i < states.length; i++) {
      if (states[i] == ListenCardState.waiting) {
        states[i] = ListenCardState.locked;
      }
    }
    notifyListeners();
  }

  void _unavailable(String why) {
    _whyUnavailable = why;
    _setPhase(ListenPhase.unavailable);
  }

  void _setPhase(ListenPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }

  void _onAudio(ListenAudioState s) {
    if (_closed) return;
    _playing = s.playing && !s.ended;
    _position = s.position;
    _duration = s.duration;
    _audioEnded = s.ended;
    if (s.failed && !s.playing) {
      // A clip that would not load: the network, most likely.
      _unavailable('audio');
      return;
    }
    final int? index = s.index;
    if (index != null && index < _queue.length) {
      final (int k, _Part part) = _queue[index];
      if (k != _at) {
        _at = k;
        // One card ahead of the one being read.
        if (_hasPlus) unawaited(_fetchMore());
      }
      _part = part;
      if (part == _Part.turn) _heard(k);
      if (!s.ended) {
        _setPhase(switch (part) {
          _Part.question => ListenPhase.question,
          _Part.think => ListenPhase.think,
          _Part.answer => ListenPhase.answer,
          _Part.turn => ListenPhase.turn,
        });
      }
    }
    if (s.ended) _arrive();
    notifyListeners();
  }

  /// The queue ran to its end: the offer, more to come, or the end.
  void _arrive() {
    if (_at >= 0) _heard(_at);
    if (states.contains(ListenCardState.locked)) {
      if (_hasPlus) {
        _finish();
      } else {
        _setPhase(ListenPhase.offer);
      }
    } else if (_fetching || _next < cards.length) {
      _setPhase(ListenPhase.waiting);
    } else {
      _finish();
    }
  }

  void _heard(int k) {
    if (states[k] == ListenCardState.heard) return;
    states[k] = ListenCardState.heard;
    Analytics.capture('listen card heard', {
      ...?facts?.call(cards[k].id),
      'position': k + 1,
      'of': cards.length,
      'free': !_hasPlus,
    });
  }

  void _finish() {
    if (!_finished) {
      _finished = true;
      Analytics.capture('listen finished', {
        'heard': heard,
        'nothing': states.where((s) => s == ListenCardState.nothing).length,
        'unavailable': states
            .where((s) => s == ListenCardState.unavailable)
            .length,
        'is_plus': _hasPlus,
        'ms_listening': _startedAt == null
            ? null
            : _clock().difference(_startedAt!).inMilliseconds,
      });
    }
    _setPhase(ListenPhase.done);
  }
}
