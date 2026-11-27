// A silent queue for Listen (lib/listen/listen_audio.dart): no platform
// channel, no sound; the test walks through it by hand with [finish].
// Shared with the camera (tool/listen_shots.dart).
import 'dart:async';

import 'package:astuto/listen/listen_audio.dart';

class SilentListenAudio implements ListenAudio {
  final StreamController<ListenAudioState> _states =
      StreamController<ListenAudioState>.broadcast(sync: true);

  /// Everything queued, in order.
  final List<ListenSound> queue = [];
  int? index;
  bool playing = false;
  bool ended = false;
  bool disposed = false;

  /// How far into the sound playing, for the progress line.
  Duration position = const Duration(seconds: 1);

  void _say() {
    if (_states.isClosed) return;
    _states.add(
      ListenAudioState(
        index: index,
        playing: playing,
        ended: ended,
        duration: const Duration(seconds: 4),
        position: position,
      ),
    );
  }

  /// The sound playing ends, and the next begins (or the queue does).
  void finish() {
    final int? i = index;
    if (i == null) return;
    if (i + 1 < queue.length) {
      index = i + 1;
    } else {
      ended = true;
      playing = false;
    }
    _say();
  }

  /// Plays on to the end of the card being read: its question, the pause,
  /// its answer and the breath after it.
  void finishCard() {
    final int? i = index;
    if (i == null) return;
    final int end = (i ~/ 4) * 4 + 4;
    while ((index ?? end) < end && !ended) {
      finish();
    }
  }

  @override
  Future<void> start(List<ListenSound> sounds) async {
    queue
      ..clear()
      ..addAll(sounds);
    index = 0;
    playing = true;
    ended = false;
    _say();
  }

  @override
  Future<void> add(List<ListenSound> sounds) async {
    final bool wasEnded = ended;
    final int first = queue.length;
    queue.addAll(sounds);
    if (wasEnded) {
      ended = false;
      index = first;
      playing = true;
      _say();
    }
  }

  @override
  Future<void> play() async {
    playing = true;
    _say();
  }

  @override
  Future<void> pause() async {
    playing = false;
    _say();
  }

  @override
  Future<void> jump(int index) async {
    this.index = index;
    ended = false;
    playing = true;
    _say();
  }

  @override
  Stream<ListenAudioState> get states => _states.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _states.close();
  }
}
