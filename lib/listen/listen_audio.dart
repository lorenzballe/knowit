/// What plays the day's five aloud: one queue of sounds, walked through by
/// the phone itself (a question, the pause to think, the answer, a breath,
/// the next question), so it goes on with the screen locked, where the app
/// is not woken between one sound and the next.
///
/// The app plays through just_audio, with the phone told it is speech
/// (audio_session), as a podcast is: it keeps playing in the background
/// (iOS: the `audio` background mode in Info.plist), and music playing
/// before it pauses for it. A widget test swaps in a silent queue with
/// [ListenAudio.make].
library;

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// One sound in the queue.
sealed class ListenSound {
  const ListenSound();
}

/// A clip read by the voice, played from where the server keeps it.
class ListenClip extends ListenSound {
  const ListenClip(this.url);
  final Uri url;
}

/// One of the app's own sounds (assets/audio/, tool/media/listen_tones.py).
class ListenTone extends ListenSound {
  const ListenTone(this.asset);
  final String asset;

  /// The pause to think between a question and its answer: a soft tone and
  /// about four seconds.
  static const ListenTone think = ListenTone('assets/audio/listen_think.m4a');

  /// The breath between one card and the next.
  static const ListenTone turn = ListenTone('assets/audio/listen_turn.m4a');
}

/// Where the queue is: the sound playing, by its place, whether it plays,
/// how far into it, and whether the queue has played to its end.
@immutable
class ListenAudioState {
  const ListenAudioState({
    this.index,
    this.playing = false,
    this.position = Duration.zero,
    this.duration,
    this.ended = false,
    this.failed = false,
  });

  final int? index;
  final bool playing;
  final Duration position;
  final Duration? duration;
  final bool ended;

  /// A sound that would not load (the network, a clip gone).
  final bool failed;
}

/// The queue. The app's is [JustAudioListen].
abstract class ListenAudio {
  /// How a queue is made: the app's, unless a test says otherwise.
  static ListenAudio Function() make = JustAudioListen.new;

  /// Plays [sounds] from the first.
  Future<void> start(List<ListenSound> sounds);

  /// Adds [sounds] at the end of the queue, while it plays.
  Future<void> add(List<ListenSound> sounds);

  Future<void> play();
  Future<void> pause();

  /// Plays the sound at [index] from its start.
  Future<void> jump(int index);

  /// Where the queue is, as it changes.
  Stream<ListenAudioState> get states;

  /// Stops, and lets everything go.
  Future<void> dispose();
}

/// The queue on just_audio.
class JustAudioListen implements ListenAudio {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<ListenAudioState> _states =
      StreamController<ListenAudioState>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  bool _failed = false;

  JustAudioListen() {
    void say([Object? _]) {
      if (_states.isClosed) return;
      _states.add(
        ListenAudioState(
          index: _player.currentIndex,
          playing: _player.playing,
          position: _player.position,
          duration: _player.duration,
          ended: _player.processingState == ProcessingState.completed,
          failed: _failed,
        ),
      );
    }

    _subs
      ..add(_player.currentIndexStream.listen(say))
      ..add(_player.playingStream.listen(say))
      ..add(_player.processingStateStream.listen(say))
      ..add(
        _player
            .createPositionStream(
              minPeriod: const Duration(milliseconds: 200),
              maxPeriod: const Duration(milliseconds: 400),
            )
            .listen(say),
      )
      ..add(
        _player.errorStream.listen((_) {
          _failed = true;
          say();
        }),
      );
  }

  static AudioSource _source(ListenSound sound) => switch (sound) {
    ListenClip(:final Uri url) => AudioSource.uri(url),
    ListenTone(:final String asset) => AudioSource.asset(asset),
  };

  @override
  Future<void> start(List<ListenSound> sounds) async {
    try {
      // Speech: playback that goes on behind the lock screen, and pauses
      // for a call.
      final AudioSession session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      await _player.setAudioSources([for (final s in sounds) _source(s)]);
      unawaited(_player.play());
    } catch (_) {
      _failed = true;
      if (!_states.isClosed) {
        _states.add(const ListenAudioState(failed: true));
      }
    }
  }

  @override
  Future<void> add(List<ListenSound> sounds) async {
    try {
      final bool ended = _player.processingState == ProcessingState.completed;
      final int next = _player.sequence.length;
      await _player.addAudioSources([for (final s in sounds) _source(s)]);
      // A queue that ran dry while the next card was still coming starts
      // again where the new one begins.
      if (ended) {
        await _player.seek(Duration.zero, index: next);
        unawaited(_player.play());
      }
    } catch (_) {
      _failed = true;
    }
  }

  @override
  Future<void> play() async => unawaited(_player.play());

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> jump(int index) async {
    await _player.seek(Duration.zero, index: index);
    if (!_player.playing) unawaited(_player.play());
  }

  @override
  Stream<ListenAudioState> get states => _states.stream;

  @override
  Future<void> dispose() async {
    for (final StreamSubscription<Object?> s in _subs) {
      await s.cancel();
    }
    await _states.close();
    await _player.dispose();
  }
}
