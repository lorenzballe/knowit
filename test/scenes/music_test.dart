import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/scene_view.dart';
import 'package:astuto/widgets/scenes/music_view.dart';

/// `music`: build a sound, hear what changed, see it drawn.

/// Photographs only on request: `--dart-define=SHOTS=true --update-goldens`.
const _shots = bool.fromEnvironment('SHOTS');

/// A speaker that hears everything and plays nothing: no platform channel
/// is touched, and the test can tell exactly when sound was asked for.
class _Ears implements MusicSceneSpeaker {
  final plays = <({Uint8List wav, bool loop, Duration from})>[];
  int stops = 0;

  @override
  Future<void> play(
    Uint8List wav, {
    bool loop = false,
    Duration from = Duration.zero,
  }) async => plays.add((wav: wav, loop: loop, from: from));

  @override
  Future<void> stop() async => stops++;

  @override
  void dispose() {}
}

List<Map<String, Object?>> _samples() => [
  for (final c
      in jsonDecode(File('tool/cards/samples/music.json').readAsStringSync())
          as List)
    (c as Map).cast<String, Object?>(),
];

Map<String, Object?> _scene(int i) =>
    (_samples()[i]['scene'] as Map).cast<String, Object?>();

void main() {
  late _Ears ears;

  setUpAll(() async {
    final fonts = {
      'Fraunces': 'assets/fonts/Fraunces.ttf',
      'Figtree': 'assets/fonts/Figtree.ttf',
      'MaterialIcons':
          '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
          '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    };
    for (final e in fonts.entries) {
      final bytes = File(e.value).readAsBytesSync();
      await (FontLoader(
        e.key,
      )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  setUp(() {
    ears = _Ears();
    MusicSceneAudio.speaker = () => ears;
  });

  MusicScene parse(Map<String, Object?> m) =>
      Scene.fromJson(m, id: 't') as MusicScene;

  // ---------------------------------------------------------------- parse

  group('parse', () {
    test('a chord: keys, spellings, start, moments, tuning', () {
      final s = parse(_scene(0));
      expect(s.mode, MusicSceneMode.chord);
      expect(s.readout, 'Frequency ratio');
      expect(s.keys.first.name, 'C4');
      expect(s.keys.last.name, 'E5');
      expect(s.keys.where((k) => !k.isBlack), hasLength(10));
      // Spelled as the card spells them, the rest the usual way.
      expect(s.noteOf(63).name, 'Eb4');
      expect(s.noteOf(61).name, 'Db4');
      expect(s.noteOf(66).name, 'F#4');
      expect(s.noteOf(70).name, 'Bb4');
      expect(s.start, {60, 67});
      expect(s.tuning, MusicSceneTuning.just);
      expect(s.moments, hasLength(6));
      expect(s.momentFor({60, 64, 67})!.name, 'Major chord');
      expect(s.momentFor({60, 64}), isNull);
      expect((s.listen, s.stop), ('Listen', 'Stop'));
    });

    test('ratios are the whole numbers of just intervals', () {
      expect(MusicScene.ratioOf([60, 67]), [2, 3]);
      expect(MusicScene.ratioOf([60, 64, 67]), [4, 5, 6]);
      expect(MusicScene.ratioOf([60, 63, 67]), [10, 12, 15]);
      expect(MusicScene.ratioOf([60, 61]), [15, 16]);
      expect(MusicScene.ratioOf([60, 66]), [32, 45]);
      expect(MusicScene.ratioOf([60, 72]), [1, 2]);
      expect(MusicScene.ratioOf([60, 64, 67, 72]), [4, 5, 6, 8]);
      expect(MusicScene.ratioOf([60]), isEmpty);
      // A major triad in just tuning repeats every 4 cycles of C4.
      final s = parse(_scene(0));
      expect(s.periodOf({60, 64, 67}) * 1000, closeTo(15.29, 0.01));
      expect(s.hertzOf({60, 67})[1] / s.hertzOf({60, 67})[0], 1.5);
    });

    test('harmonics: the pitch is the rate the wave repeats at', () {
      final s = parse(_scene(1));
      expect(s.mode, MusicSceneMode.harmonics);
      expect((s.fundamental, s.harmonics), (110, 8));
      expect(s.start, {1, 2, 3, 4, 5, 6, 7, 8});
      expect(s.pitchOf({2, 3, 4, 5}), 110);
      expect(s.pitchOf({2, 4, 6, 8}), 220);
      expect(s.pitchOf({3, 6}), 330);
      expect(s.pitchOf({}), 0);
    });

    test('layers: tracks, steps, holds and chords', () {
      final s = parse(_scene(2));
      expect(s.mode, MusicSceneMode.layers);
      expect((s.bpm, s.steps), (104, 16));
      expect(s.loopSeconds, closeTo(16 * 15 / 104, 1e-9));
      expect(s.tracks.map((t) => t.name), ['Kick', 'Hat', 'Clap', 'Bass']);
      expect(s.tracks.map((t) => t.on), [true, false, false, false]);
      final kick = s.tracks[0];
      expect(kick.steps[0]!.velocity, 1);
      expect(kick.steps[4]!.velocity, lessThan(1));
      final bass = s.tracks[3];
      expect(bass.steps[6]!.midi, [45]); // A2
      expect(bass.steps[6]!.length, 2);
      expect(bass.steps[7], isNull);
      expect(bass.range, (31, 45)); // G1 to A2
      expect(s.momentFor({0, 1, 2, 3}), isNotNull);
      final chords = parse({
        'type': 'music',
        'mode': 'layers',
        'bpm': 90,
        'steps': 8,
        'hint': 'h',
        'tracks': [
          {'name': 'K', 'sound': 'kick', 'pattern': 'x . . . x . . .'},
          {'name': 'P', 'sound': 'keys', 'pattern': 'A3+C4+E4 - - - . . . .'},
        ],
      });
      expect(chords.tracks[1].steps[0]!.midi, [57, 60, 64]);
      expect(chords.tracks[1].steps[0]!.length, 4);
    });

    const chord = {
      'type': 'music',
      'mode': 'chord',
      'readout': 'R',
      'keys': ['C4', 'C5'],
      'start': ['C4'],
      'hint': 'h',
    };
    const layers = {
      'type': 'music',
      'mode': 'layers',
      'bpm': 100,
      'steps': 8,
      'hint': 'h',
      'tracks': [
        {'name': 'K', 'sound': 'kick', 'pattern': 'x . . . x . . .'},
        {'name': 'B', 'sound': 'bass', 'pattern': 'A1 - . . . . . .'},
      ],
    };
    for (final (why, bad) in <(String, Map<String, Object?>)>[
      ('no mode', {...chord}..remove('mode')),
      ('an unknown mode', {...chord, 'mode': 'opera'}),
      ('no hint', {...chord}..remove('hint')),
      ('a hint too long', {...chord, 'hint': 'x' * 91}),
      ('a key that is not a note', {...chord, 'keys': ['C4', 'H5']}),
      ('a keyboard ending on a black key', {...chord, 'keys': ['C4', 'C#5']}),
      ('a keyboard of four white keys', {...chord, 'keys': ['C4', 'F4']}),
      ('a keyboard of eleven white keys', {...chord, 'keys': ['C4', 'F5']}),
      ('a start note off the keyboard', {...chord, 'start': ['D5']}),
      ('seven start notes', {
        ...chord,
        'start': ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4'],
      }),
      ('an unknown tuning', {...chord, 'tuning': 'pythagorean'}),
      ('a moment without text', {
        ...chord,
        'moments': [
          {'notes': ['C4']},
        ],
      }),
      ('harmonics out of range', {
        'type': 'music',
        'mode': 'harmonics',
        'readout': 'R',
        'hint': 'h',
        'fundamental': 110,
        'harmonics': 9,
        'start': [1],
      }),
      ('a harmonic past the last', {
        'type': 'music',
        'mode': 'harmonics',
        'readout': 'R',
        'hint': 'h',
        'fundamental': 110,
        'harmonics': 4,
        'start': [5],
      }),
      ('a fundamental too low', {
        'type': 'music',
        'mode': 'harmonics',
        'readout': 'R',
        'hint': 'h',
        'fundamental': 20,
        'harmonics': 4,
        'start': [1],
      }),
      ('steps not a multiple of four', {...layers, 'steps': 10}),
      ('a loop over eight seconds', {...layers, 'bpm': 60, 'steps': 32}),
      ('one track', {
        ...layers,
        'tracks': [(layers['tracks'] as List).first],
      }),
      ('a pattern of the wrong length', {
        ...layers,
        'tracks': [
          {'name': 'K', 'sound': 'kick', 'pattern': 'x . . .'},
          {'name': 'B', 'sound': 'bass', 'pattern': 'A1 - . . . . . .'},
        ],
      }),
      ('a note in a drum track', {
        ...layers,
        'tracks': [
          {'name': 'K', 'sound': 'kick', 'pattern': 'C2 . . . x . . .'},
          {'name': 'B', 'sound': 'bass', 'pattern': 'A1 - . . . . . .'},
        ],
      }),
      ('a hold with nothing to hold', {
        ...layers,
        'tracks': [
          {'name': 'K', 'sound': 'kick', 'pattern': 'x . . . x . . .'},
          {'name': 'B', 'sound': 'bass', 'pattern': '- . . . . . . .'},
        ],
      }),
      ('an unknown sound', {
        ...layers,
        'tracks': [
          {'name': 'K', 'sound': 'cowbell', 'pattern': 'x . . . x . . .'},
          {'name': 'B', 'sound': 'bass', 'pattern': 'A1 - . . . . . .'},
        ],
      }),
      ('two tracks of one name', {
        ...layers,
        'tracks': [
          {'name': 'K', 'sound': 'kick', 'pattern': 'x . . . x . . .'},
          {'name': 'K', 'sound': 'bass', 'pattern': 'A1 - . . . . . .'},
        ],
      }),
      ('a moment naming no track', {
        ...layers,
        'moments': [
          {
            'on': ['Drums'],
            'text': 't',
          },
        ],
      }),
    ]) {
      test('refuses $why', () {
        expect(() => parse(bad), throwsFormatException);
      });
    }

    test('the samples parse as whole cards', () {
      final cards = _samples();
      expect(cards, hasLength(3));
      expect(
        [for (final c in cards) parse((c['scene'] as Map).cast()).mode],
        [MusicSceneMode.chord, MusicSceneMode.harmonics, MusicSceneMode.layers],
      );
      for (final c in cards) {
        expect(cardFromJson(c).scene, isA<MusicScene>());
      }
    });
  });

  // ---------------------------------------------------------------- sound

  group('the synth', () {
    test('writes a mono 16-bit WAV at 22.05 kHz', () {
      final pcm = MusicSceneSynth.chord([261.63, 392]);
      final wav = MusicSceneSynth.wav(pcm);
      final b = ByteData.sublistView(wav);
      String tag(int at) => String.fromCharCodes(wav.sublist(at, at + 4));
      expect(tag(0), 'RIFF');
      expect(tag(8), 'WAVE');
      expect(tag(36), 'data');
      expect(b.getUint16(22, Endian.little), 1);
      expect(b.getUint32(24, Endian.little), 22050);
      expect(b.getUint16(34, Endian.little), 16);
      expect(b.getUint32(40, Endian.little), pcm.length * 2);
      expect(wav.length, 44 + pcm.length * 2);
      expect(pcm.length, (1.9 * 22050).round());
      final peak = pcm.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
      expect(peak, closeTo(0.72, 1e-6));
    });

    test('a loop is exactly one pass and never clips', () {
      final s = parse(_scene(2));
      final pcm = MusicSceneSynth.loop(s, {0, 1, 2, 3});
      expect(pcm.length, (s.loopSeconds * 22050).round());
      expect(pcm.every((v) => v.abs() <= 0.85 + 1e-6), isTrue);
      expect(pcm.any((v) => v.abs() > 0.1), isTrue);
    });

    test('taking away the fundamental keeps the wave\'s period', () {
      // The sum of harmonics 2..8 of 110 Hz still repeats every 1/110 s.
      final pcm = MusicSceneSynth.harmonics(110, [2, 3, 4, 5, 6, 7, 8]);
      final period = (22050 / 110).round(); // 200.45 samples: close enough
      const at = 11025;
      var diff = 0.0, size = 0.0;
      for (var i = at; i < at + 400; i++) {
        diff += (pcm[i] - pcm[i + period]).abs();
        size += pcm[i].abs();
      }
      expect(diff / size, lessThan(0.15));
    });
  });

  // ------------------------------------------------------------- the scene

  Widget alone(Map<String, Object?> json, Size box, {bool dark = false}) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          backgroundColor: dark
              ? const Color(0xFF3D1E99)
              : const Color(0xFFFFD84D),
          body: Center(
            child: SizedBox(
              width: box.width,
              height: box.height,
              child: SceneView(
                scene: Scene.fromJson(json)!,
                ink: dark ? Colors.white : const Color(0xFF141414),
                ground: dark
                    ? const Color(0xFF3D1E99)
                    : const Color(0xFFFFD84D),
              ),
            ),
          ),
        ),
      );

  Future<void> shoot(WidgetTester tester, String name) async {
    if (!_shots) return;
    await expectLater(
      find.byType(SceneView),
      matchesGoldenFile('../../tool/shots/cards/$name.png'),
    );
  }

  /// Presses the key named [note] (found by its screen-reader label, so the
  /// finger lands on the key actually drawn there).
  Future<void> key(WidgetTester tester, String note) async {
    await tester.tapAt(tester.getCenter(find.bySemanticsLabel(note)));
    await tester.pump();
  }

  final phones = [
    ('small phone', const Size(360, 740), const Size(276, 330)),
    ('large phone', const Size(430, 932), const Size(346, 520)),
    ('card back', const Size(360, 740), const Size(276, 270)),
  ];

  for (final (name, phone, box) in phones) {
    for (final dark in [false, true]) {
      final tag = '${name.replaceAll(' ', '_')}_${dark ? 'white' : 'dark'}';

      testWidgets('chord on a $name (${dark ? 'white' : 'dark'} ink): '
          'notes added one by one turn the ratio and the sound', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(alone(_scene(0), box, dark: dark));
        await tester.pumpAndSettle();

        // Arrives silent, already drawn: a fifth, 3 : 2.
        expect(ears.plays, isEmpty, reason: 'nothing plays by itself');
        expect(find.text('FREQUENCY RATIO'), findsOneWidget);
        expect(find.text('2 : 3'), findsOneWidget);
        expect(find.text('Fifth'), findsOneWidget);
        expect(find.textContaining('every 7.6 ms'), findsOneWidget);
        await shoot(tester, 'music_chord_start_$tag');

        // E: a major chord, 4 : 5 : 6, and it sounds.
        await key(tester, 'E4');
        expect(ears.plays, hasLength(1));
        expect(find.text('4 : 5 : 6'), findsOneWidget);
        expect(find.text('Major chord'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 500));
        await shoot(tester, 'music_chord_major_$tag');
        await tester.pumpAndSettle();

        // E down to E♭: minor.
        await key(tester, 'E4');
        await key(tester, 'Eb4');
        expect(find.text('10 : 12 : 15'), findsOneWidget);
        expect(find.text('Minor chord'), findsOneWidget);

        // Down to C and D♭: a semitone, rough.
        await key(tester, 'Eb4');
        await key(tester, 'G4');
        await key(tester, 'Db4');
        expect(find.text('15 : 16'), findsOneWidget);
        expect(find.text('Semitone'), findsOneWidget);
        expect(ears.plays, hasLength(6));
        await tester.pumpAndSettle();
        await shoot(tester, 'music_chord_semitone_$tag');

        // C alone reads in hertz; nothing at all is silence.
        await key(tester, 'Db4');
        expect(find.text('262 Hz'), findsOneWidget);
        await key(tester, 'C4');
        expect(find.text('—'), findsOneWidget);
        expect(ears.plays, hasLength(7), reason: 'an empty chord is silent');
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        semantics.dispose();
      });

      testWidgets('harmonics on a $name (${dark ? 'white' : 'dark'} ink): '
          'the lowest goes and the pitch stays', (tester) async {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(alone(_scene(1), box, dark: dark));
        await tester.pumpAndSettle();

        expect(ears.plays, isEmpty);
        expect(find.text('PITCH YOU HEAR'), findsOneWidget);
        expect(find.text('110 Hz'), findsOneWidget);
        expect(find.textContaining('A bass A'), findsOneWidget);
        // The repeat is measured over the wave: 1/110 s.
        await shoot(tester, 'music_harmonics_start_$tag');

        await tester.tap(find.text('110'));
        await tester.pump();
        expect(ears.plays, hasLength(1));
        expect(find.text('110 Hz'), findsOneWidget);
        expect(find.text('No 110 Hz in it'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 400));
        await shoot(tester, 'music_harmonics_missing_$tag');
        await tester.pumpAndSettle();

        // Odd harmonics away too: an octave up.
        for (final hz in ['330', '550', '770']) {
          await tester.tap(find.text(hz));
          await tester.pump();
        }
        expect(find.text('220 Hz'), findsOneWidget);
        expect(find.text('Evens only'), findsOneWidget);
        expect(ears.plays, hasLength(4));
        expect(find.text('Stop'), findsOneWidget, reason: 'it is sounding');
        await tester.pumpAndSettle();

        // Listen plays it again; Stop cuts it.
        await tester.tap(find.text('Listen'));
        await tester.pump();
        expect(ears.plays, hasLength(5));
        expect(find.text('Stop'), findsOneWidget);
        await tester.tap(find.text('Stop'));
        await tester.pump();
        expect(ears.stops, greaterThan(0));
        expect(find.text('Listen'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
      });

      testWidgets('layers on a $name (${dark ? 'white' : 'dark'} ink): '
          'tracks join a playing loop', (tester) async {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(alone(_scene(2), box, dark: dark));
        await tester.pumpAndSettle();

        expect(ears.plays, isEmpty);
        expect(find.text('104 BPM'), findsOneWidget);
        for (final t in ['Kick', 'Hat', 'Clap', 'Bass']) {
          expect(find.text(t), findsOneWidget);
        }
        expect(find.textContaining('Tap a track'), findsOneWidget);
        await shoot(tester, 'music_layers_start_$tag');

        // Listen: the kick alone, looping.
        await tester.tap(find.text('Listen'));
        await tester.pump();
        expect(ears.plays.single.loop, isTrue);
        await tester.pump(const Duration(milliseconds: 1200));

        // The hat joins where the playhead is.
        await tester.tap(find.text('Hat'));
        await tester.pump();
        expect(ears.plays, hasLength(2));
        expect(ears.plays.last.from, greaterThan(Duration.zero));
        expect(find.textContaining('The hats tick'), findsOneWidget);

        await tester.tap(find.text('Clap'));
        await tester.pump();
        await tester.tap(find.text('Bass'));
        await tester.pump();
        expect(find.textContaining('middle amount'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 700));
        await shoot(tester, 'music_layers_full_$tag');

        // Stop: silence, and the grid comes to rest.
        await tester.tap(find.text('Stop'));
        await tester.pump();
        expect(ears.stops, greaterThan(0));
        await tester.pumpAndSettle();
        expect(find.text('Listen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a loop left playing stops by itself', (tester) async {
    await tester.pumpWidget(alone(_scene(2), const Size(276, 330)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listen'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Listen'), findsOneWidget);
    expect(ears.stops, greaterThan(0));
  });

  testWidgets('switching every track off stops the loop', (tester) async {
    await tester.pumpWidget(alone(_scene(2), const Size(276, 330)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kick'));
    await tester.pump();
    expect(ears.plays, isEmpty, reason: 'switching off never plays');
    await tester.tap(find.text('Bass'));
    await tester.pump();
    expect(ears.plays, hasLength(1), reason: 'switching on starts the loop');
    await tester.tap(find.text('Bass'));
    await tester.pump();
    expect(find.text('Listen'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('with animations off it ends in the same place', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: alone(_scene(1), const Size(276, 330)),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('110'));
    await tester.pump();
    expect(find.text('No 110 Hz in it'), findsOneWidget);
    expect(find.text('110 Hz'), findsOneWidget);
    expect(ears.plays, hasLength(1));
  });

  testWidgets('a screen reader plays the keys and hears the ratio', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(alone(_scene(0), const Size(276, 330)));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('E4')),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        hasToggledState: true,
        isToggled: false,
        label: 'E4',
      ),
    );
    expect(
      find.bySemanticsLabel('Frequency ratio: 2 to 3. Fifth'),
      findsOneWidget,
    );
    tester.semantics.tap(find.semantics.byLabel('E4'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Frequency ratio: 4 to 5 to 6. Major chord'),
      findsOneWidget,
    );
    expect(ears.plays, hasLength(1));
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  // ------------------------------------------------- on the card, in the deck

  group('in the deck', () {
    final base = PillBank.cards.firstWhere((p) => p.challenge is NoChallenge);
    late Set<String> liked;
    late int advanced;

    Widget deck(Pill pill) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          height: 700,
          child: StatefulBuilder(
            builder: (context, set) => PillCardStack(
              isSaved: (_) => false,
              onSave: (_) {},
              onShare: (_) {},
              isLiked: liked.contains,
              onLike: (p) => set(() {
                if (!liked.remove(p.id)) liked.add(p.id);
              }),
              deck: [pill, base],
              index: 0,
              onAdvance: () => advanced++,
              answerFor: (_) => null,
              reviewIds: const {},
              onAnswer: (_, _, _, _) {},
            ),
          ),
        ),
      ),
    );

    setUp(() {
      liked = {};
      advanced = 0;
    });

    testWidgets('a key held long sounds once and does not like the card', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(deck(cardFromJson(_samples()[0])));
      await tester.pumpAndSettle();
      final g = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('E4')),
      );
      for (var f = 0; f < 12; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(liked, isEmpty);
      expect(ears.plays, hasLength(1));
      expect(find.text('4 : 5 : 6'), findsOneWidget);
      expect(find.text('WHAT TO KEEP'), findsNothing, reason: 'not turned');
      semantics.dispose();
    });

    testWidgets('a drag across the keys stays in the scene', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(deck(cardFromJson(_samples()[0])));
      await tester.pumpAndSettle();
      final g = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('A4')),
      );
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(-40, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(advanced, 0, reason: 'a drag in the scene must not advance');
      expect(liked, isEmpty);
      expect(find.text('WHAT TO KEEP'), findsNothing);
      semantics.dispose();
    });

    testWidgets('a drag across the tracks stays in the scene', (tester) async {
      await tester.pumpWidget(deck(cardFromJson(_samples()[2])));
      await tester.pumpAndSettle();
      final g = await tester.startGesture(tester.getCenter(find.text('Clap')));
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(-40, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(advanced, 0);
      expect(ears.plays, isEmpty, reason: 'a drag is not a tap');
    });

    testWidgets('outside the scene the card still likes, turns and moves on', (
      tester,
    ) async {
      final card = cardFromJson(_samples()[1]);
      await tester.pumpWidget(deck(card));
      await tester.pumpAndSettle();
      final question = find.textContaining("A phone's tiny speaker");

      final g = await tester.startGesture(tester.getCenter(question));
      for (var f = 0; f < 9; f++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(liked, contains(card.id));

      await tester.tap(question);
      await tester.pumpAndSettle();
      expect(find.text('WHAT TO KEEP'), findsOneWidget);

      await tester.fling(question, const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(advanced, 1);
      expect(ears.plays, isEmpty, reason: 'nothing played on its own');
    });
  });
}
