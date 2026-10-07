/// `music`: build a sound and hear what changed.
///
/// A sentence can say that a major chord is the ratio 4 : 5 : 6, and nobody
/// hears anything. Tap the keys yourself, hear the chord turn smooth or
/// rough as one note moves, and watch the wave repeat or fall apart under
/// it: the ratio stops being a fact and becomes the reason. The sound is
/// made in the app from these few fields; nothing is recorded, and nothing
/// plays until the reader taps. What is heard is always drawn too, so the
/// card works with the sound off.
///
/// Three modes, chosen by `mode`:
///
/// - `chord`: a small keyboard. Each tap adds or removes a note and plays
///   the chord; the big readout is the chord's frequency ratio in whole
///   numbers (one note alone reads in hertz), and the wave of the notes
///   summed is drawn above the keys, with how often it repeats.
/// - `harmonics`: one tone built from its harmonics, each a bar the reader
///   switches on and off. The readout is the pitch the ear hears, which is
///   the repetition rate of the wave: take the lowest harmonic away and it
///   stays put (the missing fundamental).
/// - `layers`: two to five tracks of a short loop (drums, bass, chords, a
///   tune) on a step grid. Each track is switched on and off while the loop
///   plays under a playhead, so the reader hears the groove build.
///
/// Fields common to every mode:
///
/// - `type`: `"music"`. `mode`: `"chord"`, `"harmonics"` or `"layers"`.
///   Required.
/// - `hint` (string, up to 90 characters): the line under the picture
///   until a moment is reached. Required.
/// - `listen`, `stop` (strings, optional, up to 14 characters): the play
///   button's two faces. Default "Listen" and "Stop".
/// - `moments` (list, optional, up to 8): sets that matter, each with a
///   line. When what is on equals a moment's set exactly, its `name` (up to
///   24 characters, optional) joins the readout and its `text` (up to 90
///   characters) replaces the hint. The set is `notes` (note names) in
///   `chord`, `on` (harmonic numbers) in `harmonics`, `on` (track names) in
///   `layers`.
///
/// `chord`:
///
/// - `readout` (string, up to 34 characters): the small label over the big
///   number ("Frequency ratio"). Required.
/// - `keys` ([from, to], note names such as "C4", "Eb4", "F#4"): the
///   keyboard's first and last key, both white keys, 5 to 10 white keys in
///   all. Required.
/// - `start` (list of 1 to 6 note names on the keyboard): lit when the card
///   arrives. Required.
/// - `tuning` (optional): `"just"` plays and draws every note at the whole
///   number ratio the readout shows, counted from the lowest note; `"equal"`
///   (the default) plays a piano's tuning, and the readout is then marked
///   "≈" since the piano only comes close.
///
/// `harmonics`:
///
/// - `readout` (string, up to 34 characters): the label over the pitch
///   ("You hear"). Required.
/// - `fundamental` (number, 55 to 600): the lowest harmonic, in Hz.
///   Required.
/// - `harmonics` (integer, 2 to 8): how many bars. Required.
/// - `start` (list of harmonic numbers, 1 to `harmonics`): on when the card
///   arrives. Required.
///
/// `layers`:
///
/// - `bpm` (number, 60 to 180) and `steps` (integer, 8 to 32, a multiple of
///   4): the loop's tempo and length in sixteenth notes; the loop lasts
///   at most 8 seconds. Required.
/// - `tracks` (list of 2 to 5): each `{name, sound, pattern, on, text}`.
///   `name` up to 10 characters; `sound` one of `kick`, `snare`, `clap`,
///   `hat`, `bass`, `keys`, `lead`; `pattern` one token per step, separated
///   by spaces: `.` rest, and for the drums `x` a hit or `X` an accented
///   one, for the others a note ("A2"), a chord ("A3+C4+E4") or `-` to hold
///   the note before. `on` (optional, default false) whether it plays from
///   the start; `text` (optional, up to 90 characters) the line shown when
///   it is switched on.
///
/// A full example:
///
/// ```json
/// {
///   "type": "music",
///   "mode": "chord",
///   "readout": "Frequency ratio",
///   "keys": ["C4", "E5"],
///   "start": ["C4", "G4"],
///   "tuning": "just",
///   "hint": "Tap keys to add or take away notes. Every tap plays the chord.",
///   "moments": [
///     {"notes": ["C4", "G4"], "name": "Fifth",
///      "text": "G shakes 3 times for every 2 of C. The wave repeats fast."},
///     {"notes": ["C4", "Db4"], "name": "Semitone",
///      "text": "15 : 16. Two tones this close beat: the ear hears rough."}
///   ]
/// }
/// ```
library;

import 'dart:math' as math;

import '../scene.dart';

enum MusicSceneMode { chord, harmonics, layers }

enum MusicSceneTuning { equal, just }

/// What a track sounds like: four drums and three pitched voices.
enum MusicSceneSound {
  kick,
  snare,
  clap,
  hat,
  bass,
  keys,
  lead;

  bool get isDrum => index <= hat.index;
}

/// A note on the keyboard: its MIDI number and how the card spells it.
class MusicSceneNote {
  final int midi;
  final String name; // "Eb4"
  const MusicSceneNote(this.midi, this.name);

  /// Equal-tempered frequency, A4 = 440 Hz.
  double get hertz => 440 * math.pow(2, (midi - 69) / 12).toDouble();

  /// The letter and accidental without the octave ("Eb").
  String get pitchClass => name.replaceAll(RegExp(r'-?\d+$'), '');

  bool get isBlack => const {1, 3, 6, 8, 10}.contains(midi % 12);

  /// "C4", "Eb4", "F#3", "Bb2" or "B♭2" → a note; null when it is not one.
  static MusicSceneNote? tryParse(String s) {
    final m = RegExp(r'^([A-G])([#b♯♭]?)(-?\d)$').firstMatch(s.trim());
    if (m == null) return null;
    const base = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    final acc = switch (m[2]) {
      '#' || '♯' => 1,
      'b' || '♭' => -1,
      _ => 0,
    };
    final midi = 12 * (int.parse(m[3]!) + 1) + base[m[1]]! + acc;
    // Written the way chord charts write them, "Eb" and "F#": the card's
    // two faces carry no music glyphs.
    final sign = acc == 1 ? '#' : (acc == -1 ? 'b' : '');
    return MusicSceneNote(midi, '${m[1]}$sign${m[3]}');
  }

  /// The usual spelling of a key nobody named: sharps for C# and F#, flats
  /// for the other three black keys.
  static MusicSceneNote ofMidi(int midi) {
    const names = [
      'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', //
    ];
    return MusicSceneNote(midi, '${names[midi % 12]}${midi ~/ 12 - 1}');
  }
}

/// A set that matters and what to say when the reader reaches it.
class MusicSceneMoment {
  /// MIDI numbers (chord), harmonic numbers (harmonics) or track indexes
  /// (layers): what must be on, exactly.
  final Set<int> set;
  final String name;
  final String text;
  const MusicSceneMoment(this.set, this.name, this.text);
}

/// One sound on one step of a loop: the notes it starts (none for a drum
/// hit), how loud, and for how many steps it lasts.
class MusicSceneHit {
  final List<int> midi;
  final double velocity;
  final int length;
  const MusicSceneHit(this.midi, this.velocity, this.length);
}

class MusicSceneTrack {
  final String name;
  final MusicSceneSound sound;

  /// One entry per step: what starts there, or null.
  final List<MusicSceneHit?> steps;
  final bool on;
  final String text;
  const MusicSceneTrack({
    required this.name,
    required this.sound,
    required this.steps,
    required this.on,
    required this.text,
  });

  /// Lowest and highest note it plays, for drawing it as a piano roll.
  (int, int) get range {
    var lo = 999, hi = -999;
    for (final h in steps) {
      for (final m in h?.midi ?? const <int>[]) {
        lo = math.min(lo, m);
        hi = math.max(hi, m);
      }
    }
    return lo > hi ? (60, 60) : (lo, hi);
  }
}

/// Build a sound and hear what changed.
class MusicScene extends Scene {
  final MusicSceneMode mode;
  final String hint;
  final String listen;
  final String stop;
  final List<MusicSceneMoment> moments;

  /// Small label over the big readout (chord, harmonics).
  final String readout;

  // chord
  final List<MusicSceneNote> keys;
  final Set<int> start;
  final MusicSceneTuning tuning;

  // harmonics
  final double fundamental;
  final int harmonics;

  // layers
  final double bpm;
  final int steps;
  final List<MusicSceneTrack> tracks;

  const MusicScene(
    super.raw, {
    required this.mode,
    required this.hint,
    required this.listen,
    required this.stop,
    required this.moments,
    this.readout = '',
    this.keys = const [],
    this.start = const {},
    this.tuning = MusicSceneTuning.equal,
    this.fundamental = 0,
    this.harmonics = 0,
    this.bpm = 0,
    this.steps = 0,
    this.tracks = const [],
  });

  /// One step of the loop, a sixteenth note, in seconds.
  double get stepSeconds => 60 / bpm / 4;
  double get loopSeconds => stepSeconds * steps;

  /// The moment whose set is exactly [on], if any.
  MusicSceneMoment? momentFor(Set<int> on) {
    for (final m in moments) {
      if (m.set.length == on.length && m.set.containsAll(on)) return m;
    }
    return null;
  }

  /// How a key is spelled on this card: as the card wrote it anywhere,
  /// otherwise the usual way.
  MusicSceneNote noteOf(int midi) => keys.firstWhere(
    (k) => k.midi == midi,
    orElse: () => MusicSceneNote.ofMidi(midi),
  );

  // ------------------------------------------------------------- chords

  /// The chord as whole numbers ([4, 5, 6] for C E G), counted from its
  /// lowest note with the simple ratio each interval stands for. Empty for
  /// fewer than two notes.
  static List<int> ratioOf(Iterable<int> midi) {
    final notes = midi.toSet().toList()..sort();
    if (notes.length < 2) return const [];
    // The just interval each number of semitones within an octave stands
    // for: the unison, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3,
    // 9/5, 15/8.
    const just = [
      (1, 1), (16, 15), (9, 8), (6, 5), (5, 4), (4, 3), //
      (45, 32), (3, 2), (8, 5), (5, 3), (9, 5), (15, 8),
    ];
    final fr = <(int, int)>[];
    for (final m in notes) {
      final d = m - notes.first;
      final (n, q) = just[d % 12];
      fr.add((n * (1 << (d ~/ 12)), q));
    }
    var lcm = 1;
    for (final (_, q) in fr) {
      lcm = lcm ~/ _gcd(lcm, q) * q;
    }
    final ints = [for (final (n, q) in fr) n * (lcm ~/ q)];
    final g = ints.reduce(_gcd);
    return [for (final i in ints) i ~/ g];
  }

  /// The frequency each lit key sounds at under this card's tuning.
  List<double> hertzOf(Iterable<int> midi) {
    final notes = midi.toSet().toList()..sort();
    if (notes.isEmpty) return const [];
    if (tuning == MusicSceneTuning.equal || notes.length < 2) {
      return [for (final m in notes) MusicSceneNote.ofMidi(m).hertz];
    }
    final r = ratioOf(notes);
    final f0 = MusicSceneNote.ofMidi(notes.first).hertz / r.first;
    return [for (final x in r) f0 * x];
  }

  /// How often the summed wave of a just chord repeats, in seconds: one
  /// cycle of the tone all its notes are whole multiples of.
  double periodOf(Iterable<int> midi) {
    final notes = midi.toSet().toList()..sort();
    if (notes.isEmpty) return 0;
    final f = MusicSceneNote.ofMidi(notes.first).hertz;
    if (notes.length < 2) return 1 / f;
    return ratioOf(notes).first / f;
  }

  // ---------------------------------------------------------- harmonics

  /// The pitch the ear hears from these harmonics: the rate the wave
  /// repeats at, the fundamental times their greatest common divisor.
  double pitchOf(Set<int> on) =>
      on.isEmpty ? 0 : fundamental * on.reduce(_gcd);

  /// How loud each harmonic is drawn and played: softer as they climb, as
  /// in most instruments.
  static double amplitudeOf(int n) => 1 / math.sqrt(n);

  // -------------------------------------------------------------- parse

  static MusicScene parse(Map<String, Object?> raw, Object? id) {
    Never bad(String why) => throw FormatException('scene.$why', id);

    String text(String k, int max, {String? or}) {
      final v = raw[k];
      if (v == null && or != null) return or;
      if (v is! String || v.trim().isEmpty) bad('$k must be a string');
      if (v.length > max) bad('$k is over $max characters');
      return v;
    }

    double number(Object? v, String k, double min, double max) {
      if (v is! num || !v.isFinite) bad('$k must be a number');
      if (v < min || v > max) bad('$k must be between $min and $max');
      return v.toDouble();
    }

    final mode = MusicSceneMode.values
        .where((m) => m.name == raw['mode'])
        .firstOrNull;
    if (mode == null) bad('mode must be chord, harmonics or layers');
    final hint = text('hint', 90);
    final listen = text('listen', 14, or: 'Listen');
    final stop = text('stop', 14, or: 'Stop');

    final list = raw['moments'] ?? const [];
    if (list is! List || list.length > 8) bad('moments: a list of up to 8');
    final rawMoments = <(List<Object?>, String, String)>[];
    final setKey = mode == MusicSceneMode.chord ? 'notes' : 'on';
    for (final m in list) {
      if (m is! Map || m[setKey] is! List || m['text'] is! String) {
        bad('moments: each is {$setKey, name, text}');
      }
      final name = m['name'] ?? '';
      if (name is! String || name.length > 24) {
        bad('moments: a name is a string of up to 24 characters');
      }
      final t = m['text'] as String;
      if (t.trim().isEmpty || t.length > 90) {
        bad('moments: a text is 1 to 90 characters');
      }
      rawMoments.add(((m[setKey] as List).cast<Object?>(), name, t));
    }

    switch (mode) {
      case MusicSceneMode.chord:
        final readout = text('readout', 34);
        final range = raw['keys'];
        if (range is! List || range.length != 2) {
          bad('keys must be [from, to]');
        }
        final from = range[0] is String
            ? MusicSceneNote.tryParse(range[0] as String)
            : null;
        final to = range[1] is String
            ? MusicSceneNote.tryParse(range[1] as String)
            : null;
        if (from == null || to == null) bad('keys must be note names');
        if (from.isBlack || to.isBlack) bad('keys must start and end white');
        final whites = [
          for (var m = from.midi; m <= to.midi; m++)
            if (!MusicSceneNote.ofMidi(m).isBlack) m,
        ];
        if (whites.length < 5 || whites.length > 10) {
          bad('keys must span 5 to 10 white keys');
        }

        // Every spelling the card uses, so a key reads as the writer wrote.
        final spelled = <int, String>{};
        MusicSceneNote note(Object? v, String where) {
          final n = v is String ? MusicSceneNote.tryParse(v) : null;
          if (n == null) bad('$where: $v is not a note name');
          if (n.midi < from.midi || n.midi > to.midi) {
            bad('$where: $v is not on the keyboard');
          }
          spelled[n.midi] = n.name;
          return n;
        }

        final startList = raw['start'];
        if (startList is! List || startList.isEmpty || startList.length > 6) {
          bad('start: 1 to 6 notes');
        }
        final start = {for (final v in startList) note(v, 'start').midi};
        final moments = <MusicSceneMoment>[];
        for (final (set, name, t) in rawMoments) {
          if (set.isEmpty || set.length > 6) bad('moments: 1 to 6 notes');
          moments.add(
            MusicSceneMoment({
              for (final v in set) note(v, 'moments').midi,
            }, name, t),
          );
        }
        final tuning = MusicSceneTuning.values
            .where((t) => t.name == (raw['tuning'] ?? 'equal'))
            .firstOrNull;
        if (tuning == null) bad('tuning must be equal or just');
        return MusicScene(
          raw,
          mode: mode,
          hint: hint,
          listen: listen,
          stop: stop,
          moments: moments,
          readout: readout,
          keys: [
            for (var m = from.midi; m <= to.midi; m++)
              spelled.containsKey(m)
                  ? MusicSceneNote(m, spelled[m]!)
                  : MusicSceneNote.ofMidi(m),
          ],
          start: start,
          tuning: tuning,
        );

      case MusicSceneMode.harmonics:
        final readout = text('readout', 34);
        final f0 = number(raw['fundamental'], 'fundamental', 55, 600);
        final n = raw['harmonics'];
        if (n is! int || n < 2 || n > 8) bad('harmonics must be 2 to 8');
        int harmonic(Object? v, String where) {
          if (v is! int || v < 1 || v > n) bad('$where: 1 to $n');
          return v;
        }

        final startList = raw['start'];
        if (startList is! List || startList.isEmpty) {
          bad('start: a list of harmonic numbers');
        }
        return MusicScene(
          raw,
          mode: mode,
          hint: hint,
          listen: listen,
          stop: stop,
          moments: [
            for (final (set, name, t) in rawMoments)
              MusicSceneMoment({
                for (final v in set) harmonic(v, 'moments'),
              }, name, t),
          ],
          readout: readout,
          fundamental: f0,
          harmonics: n,
          start: {for (final v in startList) harmonic(v, 'start')},
        );

      case MusicSceneMode.layers:
        final bpm = number(raw['bpm'], 'bpm', 60, 180);
        final steps = raw['steps'];
        if (steps is! int || steps < 8 || steps > 32 || steps % 4 != 0) {
          bad('steps must be 8 to 32, a multiple of 4');
        }
        if (steps * 15 / bpm > 8.0001) bad('the loop is over 8 seconds');
        final rawTracks = raw['tracks'];
        if (rawTracks is! List || rawTracks.length < 2 || rawTracks.length > 5) {
          bad('tracks: 2 to 5');
        }
        final tracks = <MusicSceneTrack>[];
        for (final t in rawTracks) {
          if (t is! Map) bad('tracks: each is {name, sound, pattern}');
          final name = t['name'];
          if (name is! String || name.trim().isEmpty || name.length > 10) {
            bad('tracks: a name is 1 to 10 characters');
          }
          final sound = MusicSceneSound.values
              .where((s) => s.name == t['sound'])
              .firstOrNull;
          if (sound == null) bad('tracks: $name has an unknown sound');
          final on = t['on'] ?? false;
          if (on is! bool) bad('tracks: on is true or false');
          final line = t['text'] ?? '';
          if (line is! String || line.length > 90) {
            bad('tracks: a text is up to 90 characters');
          }
          final pattern = t['pattern'];
          if (pattern is! String) bad('tracks: $name needs a pattern');
          tracks.add(
            MusicSceneTrack(
              name: name,
              sound: sound,
              steps: _pattern(pattern, steps, sound, name, id),
              on: on,
              text: line,
            ),
          );
        }
        final names = [for (final t in tracks) t.name];
        if (names.toSet().length != names.length) bad('tracks: a name twice');
        return MusicScene(
          raw,
          mode: mode,
          hint: hint,
          listen: listen,
          stop: stop,
          moments: [
            for (final (set, name, t) in rawMoments)
              MusicSceneMoment({
                for (final v in set)
                  names.contains(v)
                      ? names.indexOf(v as String)
                      : bad('moments: $v is not a track'),
              }, name, t),
          ],
          bpm: bpm,
          steps: steps,
          tracks: tracks,
        );
    }
  }

  /// "x . X ." or "A2 - . C3+E3 -" → one hit or nothing per step.
  static List<MusicSceneHit?> _pattern(
    String pattern,
    int steps,
    MusicSceneSound sound,
    String name,
    Object? id,
  ) {
    final tokens = pattern.trim().split(RegExp(r'\s+'));
    if (tokens.length != steps) {
      throw FormatException(
        'scene.tracks: $name has ${tokens.length} steps, not $steps',
        id,
      );
    }
    final out = List<MusicSceneHit?>.filled(steps, null);
    int? last;
    for (var i = 0; i < steps; i++) {
      final tok = tokens[i];
      if (tok == '.') {
        last = null;
        continue;
      }
      if (sound.isDrum) {
        if (tok != 'x' && tok != 'X') {
          throw FormatException('scene.tracks: $name: drums are x, X or .', id);
        }
        out[i] = MusicSceneHit(const [], tok == 'X' ? 1 : 0.62, 1);
        continue;
      }
      if (tok == '-') {
        if (last == null) {
          throw FormatException('scene.tracks: $name holds nothing', id);
        }
        final h = out[last]!;
        out[last] = MusicSceneHit(h.midi, h.velocity, h.length + 1);
        continue;
      }
      final notes = <int>[];
      for (final part in tok.split('+')) {
        final n = MusicSceneNote.tryParse(part);
        if (n == null || n.midi < 21 || n.midi > 96) {
          throw FormatException('scene.tracks: $name: $part is not a note', id);
        }
        notes.add(n.midi);
      }
      out[i] = MusicSceneHit(notes, 0.8, 1);
      last = i;
    }
    return out;
  }
}

int _gcd(int a, int b) => b == 0 ? a.abs() : _gcd(b, a % b);
