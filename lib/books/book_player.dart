/// A book's summary heard, as one sitting: which part is being read and how
/// far into it, what each part came to, and what the reader may hear.
///
/// Each part is one clip, asked of the server as it is needed, one ahead of
/// the part being read (lib/sync/book_audio_client.dart), and goes into the
/// queue Listen plays through (lib/listen/listen_audio.dart) with a breath
/// after it, so the book goes on with the screen locked: the phone walks
/// the queue itself. On the free plan the first part of any book is heard,
/// and the week's book whole; past them the sitting stops on the offer of
/// the rest ([BookPlayerPhase.offer]), and with Astute+ taken there it goes
/// straight on. A part that cannot be had right now stops the sitting with
/// a calm word; a server with no key hides listening for the sitting.
///
/// One book plays at a time: [BookPlayer.current] is the sitting the small
/// player over every screen shows (lib/books/book_player_view.dart), and
/// starting another book stops the one before.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics.dart';
import '../data/book_summaries.dart';
import '../data/books.dart';
import '../listen/listen_audio.dart';
import '../models/book_summary.dart';
import '../sync/book_audio_client.dart';

/// Where the sitting is.
enum BookPlayerPhase {
  /// Asking for the first part.
  preparing,

  /// A part is being read, or paused in.
  playing,

  /// The next part is still coming (a slow network).
  waiting,

  /// The free parts are heard, and the rest is Astute+'s.
  offer,

  /// Every part that could be heard was.
  done,

  /// Nothing can be heard right now.
  unavailable,
}

/// What a part of the summary came to.
enum BookPartState {
  /// Not yet heard.
  waiting,

  /// Heard through to its end.
  heard,

  /// Astute+'s, on the free plan.
  locked,

  /// Not available right now.
  unavailable,
}

class BookPlayer extends ChangeNotifier {
  BookPlayer({
    required this.book,
    required this.summary,
    required this.date,
    required this.tz,
    required this._whole,
    this.shelf,
    this.from = 'book',
    ListenAudio? audio,
    BookAudioCall? call,
    DateTime Function()? clock,
  }) : _audio = audio ?? ListenAudio.make(),
       _call = call ?? BookAudioClient.call,
       _clock = clock ?? DateTime.now,
       states = List.filled(summary.parts.length, BookPartState.waiting);

  /// The sitting playing, if any: what the small player over every screen
  /// shows. Null when nothing plays.
  static final ValueNotifier<BookPlayer?> current = ValueNotifier<BookPlayer?>(
    null,
  );

  /// Starts [player] at part [at], stopping whatever book played before.
  static Future<void> play(BookPlayer player, {int at = 0}) async {
    final BookPlayer? before = current.value;
    if (before != null && !identical(before, player)) await before.stop();
    current.value = player;
    await player.begin(at: at);
  }

  /// Stops whatever plays: a sign-out, a test's end.
  static Future<void> stopAll() async {
    await current.value?.stop();
    current.value = null;
  }

  /// The book, as its cards name it: its cover, title and author.
  final CardBook book;

  /// What is read aloud, a part a clip.
  final BookSummary summary;

  /// The reader's day, which the server works the week's book out from.
  final String date;

  /// The phone's clock, in minutes from UTC.
  final int tz;

  /// Where the reader's place is kept: a part heard is a part read.
  final SummaryShelf? shelf;

  /// Where the sitting was opened from, for what is measured.
  final String from;

  final ListenAudio _audio;
  final BookAudioCall _call;
  final DateTime Function() _clock;

  /// What each part came to, by its place in the summary.
  final List<BookPartState> states;

  bool _whole;

  /// Whether the reader may hear every part: Astute+, or the week's book.
  bool get whole => _whole;

  BookPlayerPhase _phase = BookPlayerPhase.preparing;
  BookPlayerPhase get phase => _phase;

  /// The part being read, by its place; -1 before the first.
  int get at => _at;
  int _at = -1;

  bool _playing = false;

  /// Whether a sound is playing (and not paused).
  bool get playing => _playing;

  /// Why nothing could be heard, when [phase] is unavailable: what the
  /// server said, for the logs and the developer tools.
  String? get whyUnavailable => _why;
  String? _why;

  Duration _position = Duration.zero;
  Duration? _duration;

  /// How far into the part being read, and how long it is, as the player
  /// says (null before it knows).
  Duration get position => _position;
  Duration? get duration => _duration;

  // The queue: for each sound in it, its part and whether it is the breath
  // after it. Always one run of parts, the first where playing began.
  final List<(int, bool)> _queue = [];
  final Map<int, Uri> _urls = {};
  final Set<int> _asking = {};
  int? _wanted;
  int _start = 0;
  bool _started = false;
  bool _audioEnded = false;
  StreamSubscription<ListenAudioState>? _sub;
  DateTime? _startedAt;
  bool _finished = false;
  bool _closed = false;

  /// Whether the sitting has been stopped.
  bool get closed => _closed;

  /// How many parts were heard through.
  int get heard => states.where((s) => s == BookPartState.heard).length;

  /// How far the part at [k] has been heard, from 0 to 1.
  double progressOf(int k) {
    if (states[k] == BookPartState.heard) return 1;
    if (k != _at) return 0;
    return _through;
  }

  double get _through {
    final Duration? whole = _duration;
    if (whole == null || whole.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / whole.inMilliseconds).clamp(0.0, 1.0);
  }

  /// How far through the whole summary the voice is, by words.
  double get overall =>
      _at < 0 ? 0 : summary.progress(_at, _through).clamp(0.0, 1.0);

  /// About how many minutes are left to hear.
  int get minutesLeft => summary.minutesLeft(_at < 0 ? 0 : _at, _through);

  /// Whether the part after the one being read is Astute+'s, so going on is
  /// the offer, not the next part.
  bool get nextIsLocked => _at + 1 < summary.parts.length && !_may(_at + 1);

  bool _may(int k) => _whole || k == 0;

  /// Starts at part [at]: asks for it, and plays it as soon as it comes.
  Future<void> begin({int at = 0}) async {
    _startedAt = _clock();
    Analytics.capture('book audio played', {
      'book': book.id,
      'part': at + 1,
      'of': summary.parts.length,
      'whole': _whole,
      'from': from,
    });
    _sub = _audio.states.listen(_onAudio);
    for (int k = 0; k < states.length; k++) {
      if (!_may(k)) states[k] = BookPartState.locked;
    }
    await _startAt(at.clamp(0, summary.parts.length - 1));
  }

  /// Play, or pause; once everything is heard, from the start again; after
  /// a part that could not be had, that part again.
  Future<void> toggle() async {
    if (_closed) return;
    switch (_phase) {
      case BookPlayerPhase.done:
        _finished = false;
        await _startAt(0);
        return;
      case BookPlayerPhase.unavailable:
        _why = null;
        for (int k = 0; k < states.length; k++) {
          if (states[k] == BookPartState.unavailable) {
            states[k] = BookPartState.waiting;
          }
        }
        await _startAt(_wanted ?? (_at < 0 ? 0 : _at));
        return;
      case BookPlayerPhase.offer:
      case BookPlayerPhase.preparing:
        return;
      case BookPlayerPhase.waiting:
      case BookPlayerPhase.playing:
        break;
    }
    if (_playing) {
      await _audio.pause();
    } else if (_started) {
      await _audio.play();
    }
  }

  /// Back fifteen seconds in the part being read.
  Future<void> back() async {
    if (_closed || !_started) return;
    await _audio.seek(_position - const Duration(seconds: 15));
  }

  /// On to the next part; past the free ones, the offer; past the last, the
  /// end.
  Future<void> next() async {
    if (_closed) return;
    final int k = _at + 1;
    if (k >= summary.parts.length) {
      await _audio.pause();
      if (_at >= 0) _heard(_at);
      _finish();
      return;
    }
    await jumpTo(k);
  }

  /// Plays part [k] from its start, asking for it if it has not come. A
  /// part that is Astute+'s is the offer.
  Future<void> jumpTo(int k) async {
    if (_closed || k < 0 || k >= summary.parts.length) return;
    if (!_may(k)) {
      await _audio.pause();
      _lockFrom(k);
      _setPhase(BookPlayerPhase.offer);
      return;
    }
    final int index = _queue.indexWhere((e) => e.$1 == k && !e.$2);
    if (index >= 0) {
      await _audio.jump(index);
      return;
    }
    if (_started) await _audio.pause();
    await _startAt(k);
  }

  /// The reader took Astute+ from the offer: the rest of the book follows.
  Future<void> unlock() async {
    if (_closed || _whole) return;
    _whole = true;
    for (int k = 0; k < states.length; k++) {
      if (states[k] == BookPartState.locked) states[k] = BookPartState.waiting;
    }
    if (_phase == BookPlayerPhase.offer) {
      await _startAt((_at + 1).clamp(0, summary.parts.length - 1));
    } else {
      notifyListeners();
      unawaited(_prefetch(_at + 1));
    }
  }

  /// Stops: what was heard is said, the sound stops, and the small player
  /// goes.
  Future<void> stop() async {
    if (_closed) return;
    _closed = true;
    if (!_finished && _startedAt != null) {
      Analytics.capture('book audio stopped', {
        'book': book.id,
        'heard': heard,
        'at': _at + 1,
        'of': summary.parts.length,
        'phase': _phase.name,
        'whole': _whole,
        'ms_listening': _clock().difference(_startedAt!).inMilliseconds,
        'why': _why,
      });
    }
    if (identical(current.value, this)) current.value = null;
    final StreamSubscription<ListenAudioState>? sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    await _audio.dispose();
    super.notifyListeners();
  }

  /// Nothing is said once the sitting has stopped.
  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  // ── The queue ──────────────────────────────────────────────────────────

  /// Plays from part [k]: a queue of its own, which the next parts join as
  /// they come.
  Future<void> _startAt(int k) async {
    if (_closed) return;
    if (!_may(k)) {
      _lockFrom(k);
      _setPhase(BookPlayerPhase.offer);
      return;
    }
    _wanted = k;
    _setPhase(_started ? BookPlayerPhase.waiting : BookPlayerPhase.preparing);
    final Uri? url = await _urlOf(k);
    if (_closed || _wanted != k) return;
    if (url == null) return;
    _wanted = null;
    _queue
      ..clear()
      ..addAll([(k, false), (k, true)]);
    _start = k;
    _at = k;
    _audioEnded = false;
    _started = true;
    _keepPlace(k);
    _setPhase(BookPlayerPhase.playing);
    // A queue of its own, from this part: the first, or one a jump made.
    await _audio.start([ListenClip(url), ListenTone.turn]);
    unawaited(_prefetch(k + 1));
  }

  /// The address of part [k]'s clip: the one asked for already, or the
  /// server's. Null when it cannot be had, the sitting told why.
  Future<Uri?> _urlOf(int k) async {
    final Uri? had = _urls[k];
    if (had != null) return had;
    final BookAudioReply reply = await _call(book.id, k, date: date, tz: tz);
    if (_closed) return null;
    switch (reply) {
      case BookAudioClip(:final Uri url):
        _urls[k] = url;
        return url;
      case BookAudioNone(why: BookAudioWhyNot.notConfigured):
        BookAudioClient.unconfigured.value = true;
        _unavailable('not-configured');
        return null;
      case BookAudioNone(why: BookAudioWhyNot.plus):
        // The server counts this part Astute+'s: so is the rest.
        _whole = false;
        _lockFrom(k);
        if (!_started || _audioEnded || _wanted == k) {
          _setPhase(BookPlayerPhase.offer);
        }
        return null;
      case BookAudioNone(:final String? detail, :final BookAudioWhyNot why):
        states[k] = BookPartState.unavailable;
        _why = detail ?? why.name;
        if (!_started || _audioEnded || _wanted == k) _unavailable(_why!);
        notifyListeners();
        return null;
    }
  }

  /// Asks for part [k] ahead of the voice, and adds it to the queue when it
  /// follows the last part in it.
  Future<void> _prefetch(int k) async {
    if (_closed || k >= summary.parts.length || _asking.contains(k)) return;
    if (!_may(k)) {
      _lockFrom(k);
      return;
    }
    if (_queue.any((e) => e.$1 == k)) return;
    _asking.add(k);
    try {
      final Uri? url = await _urlOf(k);
      if (url == null || _closed) return;
      if (_queue.isEmpty || _queue.last.$1 != k - 1) return;
      _queue.addAll([(k, false), (k, true)]);
      await _audio.add([ListenClip(url), ListenTone.turn]);
    } finally {
      _asking.remove(k);
    }
  }

  void _lockFrom(int k) {
    for (int i = k; i < states.length; i++) {
      if (states[i] == BookPartState.waiting) states[i] = BookPartState.locked;
    }
    notifyListeners();
  }

  void _unavailable(String why) {
    _why = why;
    _setPhase(BookPlayerPhase.unavailable);
  }

  void _setPhase(BookPlayerPhase phase) {
    if (_phase == phase) return;
    _phase = phase;
    notifyListeners();
  }

  void _keepPlace(int k) {
    final SummaryShelf? s = shelf;
    if (s == null) return;
    final SummaryPlace place = s.placeOf(book.id) ?? const SummaryPlace();
    if (place.part == k && place.through == 0) return;
    unawaited(s.keep(book.id, place.copyWith(part: k, through: 0)));
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
      final (int k, bool breath) = _queue[index];
      if (k != _at) {
        _at = k;
        _keepPlace(k);
        unawaited(_prefetch(k + 1));
      }
      if (breath) _heard(k);
      if (!s.ended && _phase != BookPlayerPhase.offer) {
        _setPhase(BookPlayerPhase.playing);
      }
    }
    if (s.ended) _arrive();
    notifyListeners();
  }

  /// The queue ran to its end: the next part still coming, the offer, or
  /// the end.
  void _arrive() {
    if (_at >= 0) _heard(_at);
    final int next = _at + 1;
    if (next >= summary.parts.length) {
      _finish();
    } else if (!_may(next)) {
      _lockFrom(next);
      _setPhase(BookPlayerPhase.offer);
    } else if (states[next] == BookPartState.unavailable) {
      _wanted = next;
      _unavailable(_why ?? 'later');
    } else {
      _setPhase(BookPlayerPhase.waiting);
      unawaited(_prefetch(next));
    }
  }

  void _heard(int k) {
    if (states[k] == BookPartState.heard) return;
    states[k] = BookPartState.heard;
    unawaited(shelf?.markRead(book.id, k));
  }

  void _finish() {
    if (!_finished) {
      _finished = true;
      Analytics.capture('book audio finished', {
        'book': book.id,
        'heard': heard,
        'of': summary.parts.length,
        'whole': _whole,
        'ms_listening': _startedAt == null
            ? 0
            : _clock().difference(_startedAt!).inMilliseconds,
      });
      if (heard == summary.parts.length) unawaited(shelf?.finish(book.id));
    }
    _setPhase(BookPlayerPhase.done);
  }

  /// The first part of the queue playing now: for a test's eyes.
  @visibleForTesting
  int get queueStart => _start;
}
