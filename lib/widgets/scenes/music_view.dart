import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/scene.dart';
import '../../theme.dart';

/// Plays a [MusicScene]: build a sound and hear what changed.
///
/// Every mode has the same three layers. On top, what the ear gets as a
/// number: the chord's ratio, the pitch heard, the beat. In the middle, the
/// sound drawn: the summed wave with how often it repeats, or the loop's
/// step grid under a playhead. At the foot, the instrument: keys, harmonic
/// bars, tracks. A tap on the instrument changes the sound and plays it;
/// nothing plays unless a finger asks, and nothing is only heard: the
/// picture and the line under it always say what the speaker would.
///
/// The card is also tapped to turn, thrown to move on and long-pressed to
/// like. Every control here claims its pointer the moment it lands (see
/// [_MusicScenePress]), so a key held down, or a finger sliding off a key,
/// never likes, turns or throws the card; the bare picture between the
/// controls is left to the card.
class MusicSceneView extends StatelessWidget {
  final MusicScene scene;
  final Color ink;
  final Color ground;
  const MusicSceneView({
    super.key,
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) => switch (scene.mode) {
    MusicSceneMode.chord => _ChordView(scene: scene, ink: ink, ground: ground),
    MusicSceneMode.harmonics => _HarmonicsView(
      scene: scene,
      ink: ink,
      ground: ground,
    ),
    MusicSceneMode.layers => _LayersView(
      scene: scene,
      ink: ink,
      ground: ground,
    ),
  };
}

// ================================================================== sound

/// Where the scene's sound goes. The app plays through [audioplayers]; a
/// widget test swaps in a silent one with [MusicSceneAudio.speaker], so no
/// platform channel is ever reached.
abstract class MusicSceneSpeaker {
  /// Plays [wav] from [from], over and over when [loop].
  Future<void> play(
    Uint8List wav, {
    bool loop = false,
    Duration from = Duration.zero,
  });
  Future<void> stop();
  void dispose();
}

/// The speaker every music scene makes, on its first tap and not before.
abstract final class MusicSceneAudio {
  static MusicSceneSpeaker Function() speaker = _AudioplayersSpeaker.new;
}

class _AudioplayersSpeaker implements MusicSceneSpeaker {
  AudioPlayer? _player;

  // Calls run one after another, and a play overtaken by a newer one is
  // dropped: a fast run of taps sounds its last chord, not a pile-up.
  Future<void> _queue = Future.value();
  int _generation = 0;

  void _then(Future<void> Function(AudioPlayer p) job) {
    final mine = ++_generation;
    _queue = _queue.then((_) async {
      if (mine != _generation) return;
      try {
        await job(_player ??= AudioPlayer());
      } catch (_) {
        // No audio device, a plugin missing: the picture still says it.
      }
    });
  }

  @override
  Future<void> play(
    Uint8List wav, {
    bool loop = false,
    Duration from = Duration.zero,
  }) async => _then((p) async {
    await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    await p.play(
      BytesSource(wav, mimeType: 'audio/wav'),
      position: from > Duration.zero ? from : null,
    );
  });

  @override
  Future<void> stop() async => _then((p) => p.stop());

  @override
  void dispose() {
    ++_generation;
    final p = _player;
    _player = null;
    if (p != null) {
      _queue.then((_) => p.dispose()).catchError((_) {});
    }
  }
}

/// Sound made from numbers: sines and simple envelopes into 16-bit PCM,
/// wrapped as a WAV file.
abstract final class MusicSceneSynth {
  static const rate = 22050;

  /// A chord, struck like a soft organ-piano: each note with six
  /// harmonics, so two notes a semitone apart beat and sound rough as real
  /// instruments do, a light strum from the bottom up.
  static Float32List chord(List<double> hertz, {double seconds = 1.9}) {
    final n = (seconds * rate).round();
    final out = Float32List(n);
    for (var k = 0; k < hertz.length; k++) {
      final onset = (k * 0.018 * rate).round();
      for (var h = 1; h <= 6; h++) {
        final f = hertz[k] * h;
        if (f > rate / 2.5) break;
        final amp = 1 / math.pow(h, 1.4);
        final w = 2 * math.pi * f / rate;
        for (var i = onset; i < n; i++) {
          final t = (i - onset) / rate;
          out[i] += amp * _env(t, seconds - onset / rate, 0.012, 0.9) *
              math.sin(w * (i - onset));
        }
      }
    }
    return _normalize(out, 0.72);
  }

  /// One steady tone from harmonics of [fundamental]: [on] says which.
  static Float32List harmonics(
    double fundamental,
    Iterable<int> on, {
    double seconds = 1.7,
  }) {
    final n = (seconds * rate).round();
    final out = Float32List(n);
    for (final h in on) {
      final w = 2 * math.pi * fundamental * h / rate;
      final amp = MusicScene.amplitudeOf(h);
      for (var i = 0; i < n; i++) {
        out[i] += amp * _env(i / rate, seconds, 0.03, 0) * math.sin(w * i);
      }
    }
    return _normalize(out, 0.7);
  }

  /// One pass of a loop with the tracks in [on]. A note running past the
  /// end comes round to the start, so the loop joins without a click.
  static Float32List loop(MusicScene s, Set<int> on) {
    final n = (s.loopSeconds * rate).round();
    final out = Float32List(n);
    final noise = math.Random(7);
    for (final ti in on) {
      final track = s.tracks[ti];
      for (var step = 0; step < s.steps; step++) {
        final hit = track.steps[step];
        if (hit == null) continue;
        final start = (step * s.stepSeconds * rate).round();
        final gate = hit.length * s.stepSeconds;
        _voice(out, start, track.sound, hit, gate, noise);
      }
    }
    for (var i = 0; i < n; i++) {
      out[i] = _tanh(out[i] * 0.9) * 0.85;
    }
    return out;
  }

  static void _voice(
    Float32List out,
    int start,
    MusicSceneSound sound,
    MusicSceneHit hit,
    double gate,
    math.Random noise,
  ) {
    final n = out.length;
    final v = hit.velocity;
    void add(int i, double x) => out[(start + i) % n] += x;

    switch (sound) {
      case MusicSceneSound.kick:
        var phase = 0.0;
        final len = (0.38 * rate).round();
        for (var i = 0; i < len; i++) {
          final t = i / rate;
          phase += 2 * math.pi * (48 + 110 * math.exp(-t * 32)) / rate;
          add(i, 0.95 * v * math.exp(-t * 8) * math.sin(phase));
        }
      case MusicSceneSound.snare:
        final len = (0.22 * rate).round();
        for (var i = 0; i < len; i++) {
          final t = i / rate;
          add(
            i,
            v *
                (0.42 * math.exp(-t * 20) * (noise.nextDouble() * 2 - 1) +
                    0.32 * math.exp(-t * 28) * math.sin(2 * math.pi * 185 * t)),
          );
        }
      case MusicSceneSound.clap:
        final len = (0.25 * rate).round();
        for (var i = 0; i < len; i++) {
          final t = i / rate;
          // Three hands a hair apart, then the room.
          final burst = t < 0.03 ? (1 - (t % 0.01) / 0.01) : 0.0;
          final env = math.max(burst, math.exp(-(t - 0.02).abs() * 16));
          add(i, 0.42 * v * env * (noise.nextDouble() * 2 - 1));
        }
      case MusicSceneSound.hat:
        final len = (0.07 * rate).round();
        var prev = 0.0;
        for (var i = 0; i < len; i++) {
          final t = i / rate;
          final x = noise.nextDouble() * 2 - 1;
          // A first difference: white noise with its lows taken out.
          add(i, 0.2 * v * math.exp(-t * 55) * (x - prev));
          prev = x;
        }
      case MusicSceneSound.bass:
      case MusicSceneSound.keys:
      case MusicSceneSound.lead:
        final (parts, tilt, gain) = switch (sound) {
          MusicSceneSound.bass => (6, 1.0, 0.4),
          MusicSceneSound.keys => (4, 2.0, 0.16),
          _ => (3, 1.6, 0.3),
        };
        final len = ((gate + 0.12) * rate).round();
        for (final m in hit.midi) {
          final f = 440 * math.pow(2, (m - 69) / 12).toDouble();
          for (var h = 1; h <= parts; h++) {
            if (f * h > rate / 2.5) break;
            final amp = gain * v / math.pow(h, tilt);
            final w = 2 * math.pi * f * h / rate;
            for (var i = 0; i < len; i++) {
              final t = i / rate;
              final decay = sound == MusicSceneSound.keys
                  ? math.exp(-t * 1.6)
                  : 0.75 + 0.25 * math.exp(-t * 6);
              add(i, amp * _env(t, gate + 0.12, 0.006, 0) * decay *
                  math.sin(w * i));
            }
          }
        }
    }
  }

  /// Rises over [attack], decays at [decay] per second, and fades out over
  /// the last tenth of a second before [length].
  static double _env(double t, double length, double attack, double decay) {
    if (t < 0 || t >= length) return 0;
    final up = t < attack ? t / attack : 1.0;
    final tail = length - t < 0.12 ? (length - t) / 0.12 : 1.0;
    return up * tail * (decay > 0 ? math.exp(-t * decay) : 1);
  }

  static double _tanh(double x) {
    final e = math.exp(2 * x.clamp(-10.0, 10.0));
    return (e - 1) / (e + 1);
  }

  static Float32List _normalize(Float32List x, double peak) {
    var top = 0.0;
    for (final v in x) {
      top = math.max(top, v.abs());
    }
    if (top > 0) {
      final k = peak / top;
      for (var i = 0; i < x.length; i++) {
        x[i] *= k;
      }
    }
    return x;
  }

  /// Mono 16-bit PCM at [rate], with the 44-byte RIFF header in front.
  static Uint8List wav(Float32List pcm) {
    final data = pcm.length * 2;
    final b = ByteData(44 + data);
    void tag(int at, String s) {
      for (var i = 0; i < 4; i++) {
        b.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    b.setUint32(4, 36 + data, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little); // PCM
    b.setUint16(22, 1, Endian.little); // mono
    b.setUint32(24, rate, Endian.little);
    b.setUint32(28, rate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    b.setUint32(40, data, Endian.little);
    for (var i = 0; i < pcm.length; i++) {
      b.setInt16(
        44 + i * 2,
        (pcm[i].clamp(-1.0, 1.0) * 32767).round(),
        Endian.little,
      );
    }
    return b.buffer.asUint8List();
  }
}

/// What every mode shares: one speaker, made on the first tap; silence when
/// the card leaves the screen, the app goes to the background, or the
/// widget goes; and whether motion is wanted.
mixin _Sounding<T extends StatefulWidget> on State<T> {
  MusicSceneSpeaker? _speaker;
  late final AppLifecycleListener _life = AppLifecycleListener(
    onHide: silence,
  );

  bool get calm => MediaQuery.disableAnimationsOf(context);

  /// The play button follows the sound: Stop while it rings, Listen after.
  void _rang(AnimationStatus _) {
    if (mounted) setState(() {});
  }

  void sound(Uint8List wav, {bool loop = false, Duration from = Duration.zero}) {
    (_speaker ??= MusicSceneAudio.speaker()).play(wav, loop: loop, from: from);
  }

  /// Stops the speaker and whatever drew it.
  @mustCallSuper
  void silence() => _speaker?.stop();

  @override
  void initState() {
    super.initState();
    _life;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A card turned or thrown away stops ticking: its sound stops too.
    if (!TickerMode.valuesOf(context).enabled) silence();
  }

  @override
  void dispose() {
    _life.dispose();
    _speaker?.stop();
    _speaker?.dispose();
    super.dispose();
  }
}

// ================================================================== chord

class _ChordView extends StatefulWidget {
  final MusicScene scene;
  final Color ink;
  final Color ground;
  const _ChordView({
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<_ChordView> createState() => _ChordViewState();
}

class _ChordViewState extends State<_ChordView>
    with TickerProviderStateMixin, _Sounding {
  late Set<int> _on = {...widget.scene.start};

  /// The chord sounding: drives the wave from pale to ink and back.
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..addStatusListener(_rang);

  /// The key just struck, dipping under the finger.
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  int? _struck;

  @override
  void dispose() {
    _ring.dispose();
    _strike.dispose();
    super.dispose();
  }

  @override
  void silence() {
    super.silence();
    if (_ring.isAnimating) _ring.value = 1;
  }

  void _play() {
    if (_on.isEmpty) return;
    sound(
      MusicSceneSynth.wav(
        MusicSceneSynth.chord(widget.scene.hertzOf(_on)),
      ),
    );
    if (calm) {
      _ring.value = 0;
    } else {
      _ring.forward(from: 0);
    }
  }

  void _toggle(int midi) {
    final s = widget.scene;
    final was = s.momentFor(_on);
    setState(() {
      _on = {..._on};
      if (!_on.remove(midi)) {
        if (_on.length >= 6) return;
        _on.add(midi);
      }
      _struck = midi;
    });
    final now = s.momentFor(_on);
    if (now != null && now != was) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    if (!calm) _strike.forward(from: 0);
    if (_on.isEmpty) {
      silence();
      _ring.value = 1;
    } else {
      _play();
    }
  }

  void _listen() {
    HapticFeedback.selectionClick();
    if (_ring.isAnimating) {
      silence();
    } else {
      _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    final moment = s.momentFor(_on);
    final ratio = MusicScene.ratioOf(_on);
    final approx = s.tuning == MusicSceneTuning.equal ? '≈ ' : '';
    final value = switch (_on.length) {
      0 => '—',
      1 => '${s.hertzOf(_on).first.round()} Hz',
      _ => '$approx${ratio.join(' : ')}',
    };
    final spoken = switch (_on.length) {
      0 => '—',
      1 => value,
      _ => ratio.join(' to '),
    };
    final hertz = s.hertzOf(_on);
    final period = s.tuning == MusicSceneTuning.just ? s.periodOf(_on) : 0.0;
    final names = [
      for (final m in _on.toList()..sort()) s.noteOf(m).pitchClass,
    ].join(' ');

    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final compact = h < 360;
        final keysH = (h * 0.26).clamp(68.0, 128.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Head(
              label: s.readout,
              value: value,
              spoken: spoken,
              name: moment?.name.isNotEmpty == true ? moment!.name : names,
              listen: s.listen,
              stop: s.stop,
              playing: _ring.isAnimating,
              enabled: _on.isNotEmpty,
              onListen: _listen,
              height: h,
              ink: ink,
              ground: widget.ground,
              ring: _ring,
            ),
            SizedBox(height: compact ? 4 : 10),
            Expanded(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _WavePainter(
                      wave: _Wave(
                        [for (final f in hertz) (f, 1.0)],
                        window: 0.03,
                        period: period,
                      ),
                      ring: _ring,
                      flow: !calm,
                      ink: ink,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 4 : 10),
            _Caption(
              text: moment?.text ?? s.hint,
              lines: 3,
              ink: ink,
              calm: calm,
            ),
            SizedBox(height: compact ? 6 : 12),
            SizedBox(
              height: keysH,
              child: _Keyboard(
                scene: s,
                on: _on,
                struck: _struck,
                strike: _strike,
                onKey: _toggle,
                ink: ink,
                ground: widget.ground,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Where each key lies, shared by the painter and the finger: white keys
/// side by side, black keys narrower and shorter over the gaps.
class _KeyboardLayout {
  final List<(int, Rect)> whites;
  final List<(int, Rect)> blacks;
  const _KeyboardLayout(this.whites, this.blacks);

  factory _KeyboardLayout.of(List<MusicSceneNote> keys, Size size) {
    final whiteKeys = [for (final k in keys) if (!k.isBlack) k.midi];
    final w = size.width / whiteKeys.length;
    final whites = <(int, Rect)>[
      for (var i = 0; i < whiteKeys.length; i++)
        (whiteKeys[i], Rect.fromLTWH(i * w, 0, w, size.height)),
    ];
    final blacks = <(int, Rect)>[];
    for (final k in keys) {
      if (!k.isBlack) continue;
      // A black key sits on the line between the white keys either side.
      final left = whiteKeys.indexOf(k.midi - 1);
      if (left < 0) continue;
      final bw = w * 0.62;
      blacks.add((
        k.midi,
        Rect.fromLTWH((left + 1) * w - bw / 2, 0, bw, size.height * 0.6),
      ));
    }
    return _KeyboardLayout(whites, blacks);
  }

  /// The key under [p]: a black key wins where it covers a white one.
  int? keyAt(Offset p) {
    for (final (m, r) in blacks) {
      if (r.contains(p)) return m;
    }
    for (final (m, r) in whites) {
      if (r.contains(p)) return m;
    }
    return null;
  }
}

class _Keyboard extends StatelessWidget {
  final MusicScene scene;
  final Set<int> on;
  final int? struck;
  final Animation<double> strike;
  final ValueChanged<int> onKey;
  final Color ink;
  final Color ground;
  const _Keyboard({
    required this.scene,
    required this.on,
    required this.struck,
    required this.strike,
    required this.onKey,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final layout = _KeyboardLayout.of(scene.keys, size);
        Widget node(int m, Rect r) {
          final name = scene.noteOf(m).name;
          return Positioned.fromRect(
            rect: r,
            child: Semantics(
              button: true,
              toggled: on.contains(m),
              label: name,
              onTap: () => onKey(m),
              child: const SizedBox.expand(),
            ),
          );
        }

        return _MusicScenePress(
          onDown: (p) {
            final m = layout.keyAt(p);
            if (m != null) onKey(m);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _KeysPainter(
                        layout: layout,
                        scene: scene,
                        on: on,
                        struck: struck,
                        strike: strike,
                        ink: ink,
                        ground: ground,
                        textScaler: MediaQuery.textScalerOf(context),
                      ),
                    ),
                  ),
                ),
              ),
              for (final (m, r) in layout.whites) node(m, r),
              for (final (m, r) in layout.blacks) node(m, r),
            ],
          ),
        );
      },
    );
  }
}

/// The keys in the card's colours: white keys a shade off the card, black
/// keys in ink. A lit key turns solid (a white key to ink, a black one to
/// the card's colour inside an ink rim) and carries its name, so what is
/// on reads without colour.
class _KeysPainter extends CustomPainter {
  final _KeyboardLayout layout;
  final MusicScene scene;
  final Set<int> on;
  final int? struck;
  final Animation<double> strike;
  final Color ink;
  final Color ground;
  final TextScaler textScaler;
  _KeysPainter({
    required this.layout,
    required this.scene,
    required this.on,
    required this.struck,
    required this.strike,
    required this.ink,
    required this.ground,
    required this.textScaler,
  }) : super(repaint: strike);

  final Paint _fill = Paint();
  final Paint _line = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final dip = struck == null || strike.isDismissed
        ? 0.0
        : 1 - Curves.easeOut.transform(strike.value);
    const r = Radius.circular(7);

    for (final (m, rect) in layout.whites) {
      final lit = on.contains(m);
      final key = RRect.fromRectAndCorners(
        rect.deflate(1.5),
        bottomLeft: r,
        bottomRight: r,
      );
      _fill.color = lit
          ? ink
          : Color.lerp(ground, ink, 0.07 + (m == struck ? 0.12 * dip : 0))!;
      canvas.drawRRect(key, _fill);
      if (!lit) {
        _line
          ..color = ink.withValues(alpha: 0.38)
          ..strokeWidth = 1.4;
        canvas.drawRRect(key, _line);
      } else {
        _name(canvas, scene.noteOf(m).pitchClass, rect, ground, low: true);
      }
    }
    for (final (m, rect) in layout.blacks) {
      final lit = on.contains(m);
      final key = RRect.fromRectAndCorners(
        rect,
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      );
      _fill.color = lit
          ? ground
          : Color.lerp(ink, ground, m == struck ? 0.3 * dip : 0.12)!;
      canvas.drawRRect(key, _fill);
      if (lit) {
        _line
          ..color = ink
          ..strokeWidth = 2.5;
        canvas.drawRRect(key.deflate(1.25), _line);
        _name(canvas, scene.noteOf(m).pitchClass, rect, ink, low: false);
      }
    }
  }

  void _name(Canvas canvas, String text, Rect key, Color c, {required bool low}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: AppText.body(
          size: low ? 12 : 10.5,
          weight: FontWeight.w800,
          color: c,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final x = key.center.dx - tp.width / 2;
    final y = low ? key.bottom - tp.height - 8 : key.bottom - tp.height - 6;
    tp.paint(canvas, Offset(x, y));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_KeysPainter old) =>
      old.on != on ||
      old.struck != struck ||
      old.ink != ink ||
      old.ground != ground ||
      old.layout.whites.first.$2 != layout.whites.first.$2 ||
      old.textScaler != textScaler;
}

// ============================================================== harmonics

class _HarmonicsView extends StatefulWidget {
  final MusicScene scene;
  final Color ink;
  final Color ground;
  const _HarmonicsView({
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<_HarmonicsView> createState() => _HarmonicsViewState();
}

class _HarmonicsViewState extends State<_HarmonicsView>
    with TickerProviderStateMixin, _Sounding {
  late Set<int> _on = {...widget.scene.start};

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..addStatusListener(_rang);

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  void silence() {
    super.silence();
    if (_ring.isAnimating) _ring.value = 1;
  }

  void _play() {
    if (_on.isEmpty) return;
    sound(
      MusicSceneSynth.wav(
        MusicSceneSynth.harmonics(widget.scene.fundamental, _on),
      ),
    );
    if (calm) {
      _ring.value = 0;
    } else {
      _ring.forward(from: 0);
    }
  }

  void _toggle(int n) {
    final s = widget.scene;
    final was = s.momentFor(_on);
    setState(() {
      _on = {..._on};
      if (!_on.remove(n)) _on.add(n);
    });
    final now = s.momentFor(_on);
    if (now != null && now != was) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    if (_on.isEmpty) {
      silence();
      _ring.value = 1;
    } else {
      _play();
    }
  }

  void _listen() {
    HapticFeedback.selectionClick();
    if (_ring.isAnimating) {
      silence();
    } else {
      _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    final moment = s.momentFor(_on);
    final pitch = s.pitchOf(_on);
    final value = _on.isEmpty ? '—' : '${_hz(pitch)} Hz';
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final compact = h < 360;
        final barsH = (h * 0.27).clamp(74.0, 136.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Head(
              label: s.readout,
              value: value,
              spoken: value,
              name: moment?.name ?? '',
              listen: s.listen,
              stop: s.stop,
              playing: _ring.isAnimating,
              enabled: _on.isNotEmpty,
              onListen: _listen,
              height: h,
              ink: ink,
              ground: widget.ground,
              ring: _ring,
            ),
            SizedBox(height: compact ? 4 : 10),
            Expanded(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _WavePainter(
                      wave: _Wave(
                        [
                          for (final n in _on.toList()..sort())
                            (s.fundamental * n, MusicScene.amplitudeOf(n)),
                        ],
                        window: 3 / s.fundamental,
                        period: pitch > 0 ? 1 / pitch : 0,
                      ),
                      ring: _ring,
                      flow: !calm,
                      ink: ink,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 4 : 10),
            _Caption(
              text: moment?.text ?? s.hint,
              lines: 3,
              ink: ink,
              calm: calm,
            ),
            SizedBox(height: compact ? 6 : 12),
            SizedBox(
              height: barsH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var n = 1; n <= s.harmonics; n++)
                    Expanded(
                      child: _HarmonicBar(
                        n: n,
                        hertz: s.fundamental * n,
                        last: n == s.harmonics,
                        on: _on.contains(n),
                        onTap: () => _toggle(n),
                        ink: ink,
                        ground: widget.ground,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

String _hz(double v) => v.round().toString();

/// One harmonic: a bar as tall as it is loud, its frequency underneath.
/// Off, the bar is only an outline.
class _HarmonicBar extends StatelessWidget {
  final int n;
  final double hertz;
  final bool last;
  final bool on;
  final VoidCallback onTap;
  final Color ink;
  final Color ground;
  const _HarmonicBar({
    required this.n,
    required this.hertz,
    required this.last,
    required this.on,
    required this.onTap,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: '${_hz(hertz)} Hz',
      onTap: onTap,
      excludeSemantics: true,
      child: _MusicScenePress(
        onDown: (_) => onTap(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BarPainter(
                    level: MusicScene.amplitudeOf(n),
                    on: on,
                    ink: ink,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _hz(hertz),
                maxLines: 1,
                style: AppText.body(
                  size: 11,
                  weight: on ? FontWeight.w800 : FontWeight.w600,
                  color: ink.withValues(alpha: on ? 1 : 0.55),
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              Text(
                last ? 'Hz' : '',
                maxLines: 1,
                style: AppText.label(
                  size: 9.5,
                  color: ink.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double level;
  final bool on;
  final Color ink;
  _BarPainter({required this.level, required this.on, required this.ink});

  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = math.min(size.width, 34.0);
    final left = (size.width - w) / 2;
    final top = size.height * (1 - level);
    final bar = RRect.fromLTRBR(
      left,
      top,
      left + w,
      size.height,
      const Radius.circular(6),
    );
    // The whole column is a faint track, so a bar switched off still shows
    // where it would stand.
    _p
      ..style = PaintingStyle.fill
      ..color = ink.withValues(alpha: 0.06);
    canvas.drawRRect(
      RRect.fromLTRBR(left, 0, left + w, size.height, const Radius.circular(6)),
      _p,
    );
    if (on) {
      _p.color = ink;
      canvas.drawRRect(bar, _p);
    } else {
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = ink.withValues(alpha: 0.5);
      canvas.drawRRect(bar.deflate(0.8), _p);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.level != level || old.on != on || old.ink != ink;
}

// ================================================================= shared

/// The label, the big number with its name, and the play button.
class _Head extends StatelessWidget {
  final String label;
  final String value;
  final String spoken;
  final String name;
  final String listen;
  final String stop;
  final bool playing;
  final bool enabled;
  final VoidCallback onListen;
  final double height;
  final Color ink;
  final Color ground;
  final Animation<double> ring;
  const _Head({
    required this.label,
    required this.value,
    required this.spoken,
    required this.name,
    required this.listen,
    required this.stop,
    required this.playing,
    required this.enabled,
    required this.onListen,
    required this.height,
    required this.ink,
    required this.ground,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final big = (height * 0.12).clamp(32.0, 54.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(size: 10.5, color: ink.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: '$label: $spoken${name.isEmpty ? '' : '. $name'}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A ratio of six notes can run long: it shrinks as one
                    // piece rather than wrapping mid-number.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: AppText.display(
                          size: big,
                          weight: FontWeight.w800,
                          height: 1.05,
                          spacing: -big * 0.02,
                          color: ink,
                        ).copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        height: 1.3,
                        color: ink.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _Pill(
              label: playing ? stop : listen,
              icon: playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              filled: !playing,
              enabled: enabled,
              ink: ink,
              ground: ground,
              onTap: onListen,
            ),
          ],
        ),
      ],
    );
  }
}

/// The line under the picture, sliding in when it changes.
class _Caption extends StatelessWidget {
  final String text;
  final int lines;
  final Color ink;
  final bool calm;
  const _Caption({
    required this.text,
    required this.lines,
    required this.ink,
    required this.calm,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppText.body(
      size: 14,
      weight: FontWeight.w600,
      height: 1.32,
      color: ink.withValues(alpha: 0.92),
    );
    final lineH = MediaQuery.textScalerOf(context).scale(14) * 1.32;
    return SizedBox(
      height: lineH * lines + 2,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: calm ? Duration.zero : const Duration(milliseconds: 260),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .2),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: Semantics(
          key: ValueKey(text),
          liveRegion: true,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              text,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

/// A sum of sines over a stretch of time, and how often it repeats (0 when
/// it does not within reach).
@immutable
class _Wave {
  final List<(double, double)> parts; // (hertz, amplitude)
  final double window; // seconds across the width
  final double period; // seconds
  const _Wave(this.parts, {required this.window, required this.period});

  double at(double t) {
    var y = 0.0;
    for (final (f, a) in parts) {
      y += a * math.sin(2 * math.pi * f * t);
    }
    return y;
  }

  @override
  bool operator ==(Object other) =>
      other is _Wave &&
      other.window == window &&
      other.period == period &&
      other.parts.length == parts.length &&
      Iterable.generate(parts.length).every((i) => other.parts[i] == parts[i]);

  @override
  int get hashCode => Object.hash(window, period, Object.hashAll(parts));
}

/// The wave the speaker would play, drawn across the card. While it sounds
/// it is solid ink and flows; at rest it waits, paler. When it repeats
/// within the window, the repeats are marked and the first one measured:
/// a simple ratio is a short, steady repeat, a clash never settles.
class _WavePainter extends CustomPainter {
  final _Wave wave;
  final Animation<double> ring;
  final bool flow;
  final Color ink;
  final TextScaler textScaler;
  _WavePainter({
    required this.wave,
    required this.ring,
    required this.flow,
    required this.ink,
    required this.textScaler,
  }) : super(repaint: ring);

  final Paint _p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Path _path = Path();
  Float64List _ys = Float64List(0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < 16) return;
    final labelRoom = wave.period > 0 && wave.period <= wave.window * 0.55
        ? 22.0
        : 0.0;
    final mid = labelRoom + (size.height - labelRoom) / 2;
    final amp = (size.height - labelRoom) / 2 - 4;

    // The middle line: silence.
    _p
      ..color = ink.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), _p);

    final sounding = ring.isAnimating;
    final strength = sounding ? 1 - Curves.easeIn.transform(ring.value) : 0.0;

    if (labelRoom > 0) _repeats(canvas, size, labelRoom, mid, amp);
    if (wave.parts.isEmpty) return;

    final shift = flow && sounding ? ring.value * wave.window * 0.5 : 0.0;
    final n = (size.width / 1.5).ceil();
    if (_ys.length < n + 1) _ys = Float64List(n + 1);
    // Scaled to its own peak, so a wave of a few quiet harmonics is as
    // legible as the full one.
    var top = 1e-9;
    for (var i = 0; i <= n; i++) {
      _ys[i] = wave.at(shift + i / n * wave.window);
      top = math.max(top, _ys[i].abs());
    }
    _path.reset();
    for (var i = 0; i <= n; i++) {
      final x = i / n * size.width;
      final y = mid - _ys[i] / top * amp;
      if (i == 0) {
        _path.moveTo(x, y);
      } else {
        _path.lineTo(x, y);
      }
    }
    _p
      ..color = ink.withValues(alpha: 0.5 + 0.5 * strength)
      ..strokeWidth = 2.2 + 1.0 * strength;
    canvas.drawPath(_path, _p);
  }

  /// Dashed lines where the wave starts over, and the first stretch
  /// measured in milliseconds above it.
  void _repeats(Canvas canvas, Size size, double room, double mid, double amp) {
    final step = wave.period / wave.window * size.width;
    _p
      ..color = ink.withValues(alpha: 0.3)
      ..strokeWidth = 1.2;
    for (var x = 0.0; x <= size.width + 0.5; x += step) {
      for (var y = room; y < size.height; y += 7) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 3.5, size.height)),
          _p,
        );
      }
    }
    final ms = wave.period * 1000;
    final tp = TextPainter(
      text: TextSpan(
        text: '${ms < 10 ? ms.toStringAsFixed(1) : ms.round()} ms',
        style: AppText.body(size: 11.5, weight: FontWeight.w800, color: ink),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    // A bracket over the first repeat, the time written in its middle.
    final y = room / 2;
    _p
      ..color = ink
      ..strokeWidth = 1.6;
    final gap = tp.width / 2 + 6;
    final c = step / 2;
    if (c - gap > 4) {
      canvas.drawLine(Offset(1, y), Offset(c - gap, y), _p);
      canvas.drawLine(Offset(c + gap, y), Offset(step - 1, y), _p);
    }
    canvas.drawLine(Offset(1, y - 4), Offset(1, y + 4), _p);
    canvas.drawLine(Offset(step - 1, y - 4), Offset(step - 1, y + 4), _p);
    tp.paint(
      canvas,
      Offset(
        (c - tp.width / 2).clamp(0.0, math.max(0.0, size.width - tp.width)),
        y - tp.height / 2,
      ),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.wave != wave ||
      old.flow != flow ||
      old.ink != ink ||
      old.textScaler != textScaler;
}

/// A rounded, thumb-sized button in the card's own colours.
class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool enabled;
  final Color ink;
  final Color ground;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.icon,
    required this.filled,
    required this.enabled,
    required this.ink,
    required this.ground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? ground : ink;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: _MusicScenePress(
        onUp: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 160),
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
            decoration: BoxDecoration(
              color: filled ? ink : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: filled
                  ? null
                  : Border.all(color: ink.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A control that takes the pointer the moment it lands and keeps it.
class _MusicScenePress extends StatelessWidget {
  final ValueChanged<Offset>? onDown;
  final VoidCallback? onUp;
  final Widget child;
  const _MusicScenePress({this.onDown, this.onUp, required this.child});

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _ClaimRecognizer: GestureRecognizerFactoryWithHandlers<_ClaimRecognizer>(
        () => _ClaimRecognizer(debugOwner: this),
        (r) => r
          ..onDown = onDown
          ..onUp = onUp,
      ),
    },
    child: child,
  );
}

/// Accepting inside [addAllowedPointer] makes this the arena's eager
/// winner: when the arena closes at the end of the down event, the card's
/// tap, its pan and the long press that likes it are all turned away. A key
/// sounds on the way down, as a piano's does; a button acts on the way up,
/// and only if the finger lifts where it landed.
class _ClaimRecognizer extends OneSequenceGestureRecognizer {
  _ClaimRecognizer({super.debugOwner});

  ValueChanged<Offset>? onDown;
  VoidCallback? onUp;

  int? _pointer;
  Offset _origin = Offset.zero;
  bool _strayed = false;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      _pointer == null &&
      event.buttons == kPrimaryButton &&
      super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointer = event.pointer;
    _origin = event.position;
    _strayed = false;
    resolve(GestureDisposition.accepted);
    onDown?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent &&
        (event.position - _origin).distance > kTouchSlop) {
      _strayed = true;
    } else if (event is PointerUpEvent) {
      _pointer = null;
      stopTrackingPointer(event.pointer);
      if (!_strayed) onUp?.call();
    } else if (event is PointerCancelEvent) {
      _pointer = null;
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == _pointer) {
      _pointer = null;
      stopTrackingPointer(pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'music press';
}

// ================================================================= layers

class _LayersView extends StatefulWidget {
  final MusicScene scene;
  final Color ink;
  final Color ground;
  const _LayersView({
    required this.scene,
    required this.ink,
    required this.ground,
  });

  @override
  State<_LayersView> createState() => _LayersViewState();
}

/// How many times the loop goes round before it stops by itself: about
/// half a minute, enough to listen, never a card left droning.
const int _rounds = 8;

class _LayersViewState extends State<_LayersView>
    with TickerProviderStateMixin, _Sounding {
  late Set<int> _on = {
    for (var i = 0; i < widget.scene.tracks.length; i++)
      if (widget.scene.tracks[i].on) i,
  };

  /// The track switched last, whose line shows until another is.
  int? _last;

  /// One pass of the loop; repeats while it plays.
  late final AnimationController _loop =
      AnimationController(
        vsync: this,
        duration: Duration(
          microseconds: (widget.scene.loopSeconds * 1e6).round(),
        ),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) _stopLoop();
      });

  bool _playing = false;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  void silence() {
    super.silence();
    if (_playing) {
      _loop.stop();
      _loop.value = 0;
      if (mounted) setState(() => _playing = false);
    }
  }

  void _stopLoop() {
    super.silence();
    _loop.stop();
    _loop.value = 0;
    setState(() => _playing = false);
  }

  Duration get _position => Duration(
    microseconds: (_loop.value * widget.scene.loopSeconds * 1e6).round(),
  );

  void _start() {
    if (_on.isEmpty) return;
    sound(
      MusicSceneSynth.wav(MusicSceneSynth.loop(widget.scene, _on)),
      loop: true,
    );
    _loop.value = 0;
    _loop.repeat(count: _rounds);
    setState(() => _playing = true);
  }

  void _listen() {
    HapticFeedback.selectionClick();
    if (_playing) {
      _stopLoop();
    } else {
      _start();
    }
  }

  void _toggle(int i) {
    final s = widget.scene;
    final was = s.momentFor(_on);
    final adding = !_on.contains(i);
    setState(() {
      _on = {..._on};
      if (!_on.remove(i)) _on.add(i);
      _last = i;
    });
    final now = s.momentFor(_on);
    if (now != null && now != was) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    if (_on.isEmpty) {
      if (_playing) _stopLoop();
    } else if (_playing) {
      // The new mix picks up where the playhead is.
      sound(
        MusicSceneSynth.wav(MusicSceneSynth.loop(s, _on)),
        loop: true,
        from: _position,
      );
    } else if (adding) {
      _start();
    }
  }

  String get _line {
    final s = widget.scene;
    final m = s.momentFor(_on);
    if (m != null) return m.text;
    final last = _last;
    if (last != null && _on.contains(last) && s.tracks[last].text.isNotEmpty) {
      return s.tracks[last].text;
    }
    return s.hint;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;
    final ink = widget.ink;
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final compact = h < 360;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context, _) => _Beats(
                          beats: math.min(4, s.steps ~/ 4),
                          now: _playing
                              ? ((_loop.value * s.steps).floor() ~/ 4) %
                                    math.min(4, s.steps ~/ 4)
                              : null,
                          bpm: s.bpm,
                          ink: ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Pill(
                    label: _playing ? s.stop : s.listen,
                    icon: _playing
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    filled: !_playing,
                    enabled: _on.isNotEmpty,
                    ink: ink,
                    ground: widget.ground,
                    onTap: _listen,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 6 : 12),
            Expanded(
              child: _Grid(
                scene: s,
                on: _on,
                loop: _loop,
                playing: _playing,
                calm: calm,
                onTrack: _toggle,
                ink: ink,
                ground: widget.ground,
              ),
            ),
            SizedBox(height: compact ? 6 : 12),
            _Caption(
              text: _line,
              lines: 3,
              ink: ink,
              calm: calm,
            ),
          ],
        );
      },
    );
  }
}

/// The count, big: "1 2 3 4", the beat being played in ink, the others
/// faint, and the tempo beside them.
class _Beats extends StatelessWidget {
  final int beats;
  final int? now;
  final double bpm;
  final Color ink;
  const _Beats({
    required this.beats,
    required this.now,
    required this.bpm,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          for (var b = 0; b < beats; b++) ...[
            Text(
              '${b + 1}',
              style: AppText.display(
                size: 40,
                weight: FontWeight.w800,
                height: 1,
                color: ink.withValues(
                  alpha: now == null ? 0.85 : (now == b ? 1 : 0.22),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            '${bpm.round()} BPM',
            style: AppText.label(size: 10.5, color: ink.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

/// The tracks, one row each: a switch with the track's name, then its
/// pattern on the step grid. The whole row is the switch.
class _Grid extends StatelessWidget {
  final MusicScene scene;
  final Set<int> on;
  final Animation<double> loop;
  final bool playing;
  final bool calm;
  final ValueChanged<int> onTrack;
  final Color ink;
  final Color ground;
  const _Grid({
    required this.scene,
    required this.on,
    required this.loop,
    required this.playing,
    required this.calm,
    required this.onTrack,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final n = scene.tracks.length;
        final rowH = (box.maxHeight / n).clamp(0.0, 76.0);
        final chipW = (box.maxWidth * 0.3).clamp(78.0, 108.0);
        final chipH = math.min(rowH - 6, 40.0).clamp(24.0, 40.0);
        return Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < n; i++)
                  SizedBox(
                    height: rowH,
                    child: Semantics(
                      button: true,
                      toggled: on.contains(i),
                      label: scene.tracks[i].name,
                      onTap: () => onTrack(i),
                      excludeSemantics: true,
                      child: _MusicScenePress(
                        onUp: () => onTrack(i),
                        child: Row(
                          children: [
                            SizedBox(
                              width: chipW,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _Chip(
                                  name: scene.tracks[i].name,
                                  on: on.contains(i),
                                  height: chipH,
                                  ink: ink,
                                  ground: ground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: _TrackPainter(
                                    track: scene.tracks[i],
                                    steps: scene.steps,
                                    on: on.contains(i),
                                    loop: loop,
                                    playing: playing,
                                    smooth: !calm,
                                    ink: ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String name;
  final bool on;
  final double height;
  final Color ink;
  final Color ground;
  const _Chip({
    required this.name,
    required this.on,
    required this.height,
    required this.ink,
    required this.ground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = on ? ground : ink.withValues(alpha: 0.75);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: on ? ink : Colors.transparent,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: on ? ink : ink.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 15,
            color: fg,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 13, weight: FontWeight.w800, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// One track's steps: drums as blocks (an accent taller), notes as a piano
/// roll, higher notes higher. Beats are grouped in fours by a faint band;
/// the step being played is lit and the playhead runs through it.
class _TrackPainter extends CustomPainter {
  final MusicSceneTrack track;
  final int steps;
  final bool on;
  final Animation<double> loop;
  final bool playing;
  final bool smooth;
  final Color ink;
  _TrackPainter({
    required this.track,
    required this.steps,
    required this.on,
    required this.loop,
    required this.playing,
    required this.smooth,
    required this.ink,
  }) : super(repaint: loop);

  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / steps;
    final pad = math.min(2.0, w * 0.15);
    final top = size.height * 0.12, bottom = size.height * 0.88;
    final h = bottom - top;
    final now = playing ? (loop.value * steps).floor() : -1;

    // Every other beat a shade darker, so fours read at a glance.
    _p
      ..style = PaintingStyle.fill
      ..color = ink.withValues(alpha: 0.05);
    for (var b = 0; b < steps; b += 8) {
      canvas.drawRRect(
        RRect.fromLTRBR(b * w, top, (b + 4) * w, bottom, const Radius.circular(4)),
        _p,
      );
    }
    if (now >= 0) {
      _p.color = ink.withValues(alpha: 0.12);
      canvas.drawRRect(
        RRect.fromLTRBR(now * w, top - 2, (now + 1) * w, bottom + 2,
            const Radius.circular(3)),
        _p,
      );
    }

    final (lo, hi) = track.range;
    for (var i = 0; i < steps; i++) {
      final hit = track.steps[i];
      if (hit == null) {
        // An empty step is still a step: a dot on the floor of the row.
        if (!_held(i)) {
          _p
            ..style = PaintingStyle.fill
            ..color = ink.withValues(alpha: on ? 0.28 : 0.16);
          canvas.drawCircle(Offset((i + 0.5) * w, bottom - 1.5), 1.6, _p);
        }
        continue;
      }
      final played = now >= i && now < i + hit.length;
      if (track.sound.isDrum) {
        final bh = h * (hit.velocity >= 1 ? 1 : 0.62);
        final r = RRect.fromLTRBR(
          i * w + pad,
          bottom - bh,
          (i + 1) * w - pad,
          bottom,
          const Radius.circular(3),
        );
        _mark(canvas, r, played);
      } else {
        for (final m in hit.midi) {
          final y = hi == lo ? 0.5 : (m - lo) / (hi - lo);
          final nh = (h / 4).clamp(5.0, 10.0);
          final cy = bottom - nh / 2 - y * (h - nh);
          final r = RRect.fromLTRBR(
            i * w + pad,
            cy - nh / 2,
            (i + hit.length) * w - pad,
            cy + nh / 2,
            Radius.circular(nh / 2),
          );
          _mark(canvas, r, played);
        }
      }
    }

    if (playing && smooth) {
      final x = loop.value * size.width;
      _p
        ..style = PaintingStyle.fill
        ..color = ink;
      canvas.drawRect(Rect.fromLTWH(x - 1, 0, 2, size.height), _p);
    }
  }

  /// Whether step [i] is inside a note held from an earlier step.
  bool _held(int i) {
    for (var j = i - 1; j >= 0; j--) {
      final h = track.steps[j];
      if (h != null) return j + h.length > i;
    }
    return false;
  }

  void _mark(Canvas canvas, RRect r, bool played) {
    if (on) {
      _p
        ..style = PaintingStyle.fill
        ..color = ink.withValues(alpha: played ? 1 : 0.82);
      canvas.drawRRect(played ? r.inflate(1.5) : r, _p);
    } else {
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = ink.withValues(alpha: 0.35);
      canvas.drawRRect(r.deflate(0.65), _p);
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.track != track ||
      old.on != on ||
      old.playing != playing ||
      old.smooth != smooth ||
      old.ink != ink;
}
