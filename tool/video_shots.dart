// Photographs a video card opened on phones, at moments of its film, and its
// tile in Explore: the look of lib/widgets/video_card.dart over a film, with
// the phone's own status bar, island or notch and home bar drawn in.
//
//   flutter test tool/video_shots.dart --update-goldens \
//     --dart-define=FRAMES=/abs/dir [--dart-define=LANGUAGE=it]
//
// FRAMES holds the film's frames as PNGs, named by their moment: t01.00.png
// (one second in), t52.60.png and so on; the frame at the card's posterAt is
// its poster, shown from the app's assets as the card shows it. Pictures land
// in tool/shots/video/.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:astuto/data/video_cards.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/video_card.dart';

import '../test/explore/core_harness.dart';

const String _frames = String.fromEnvironment('FRAMES');
const String _language = String.fromEnvironment('LANGUAGE', defaultValue: 'en');

/// The phones: their size, their insets, and whether the top holds an
/// island (or else a notch, or nothing on a phone with a home button).
const _phones = <String, (Size, EdgeInsets, String)>{
  '390x844': (Size(390, 844), EdgeInsets.only(top: 47, bottom: 34), 'notch'),
  '393x852': (Size(393, 852), EdgeInsets.only(top: 59, bottom: 34), 'island'),
  '430x932': (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34), 'island'),
  '375x667': (Size(375, 667), EdgeInsets.only(top: 20), 'button'),
};

/// A player that plays nothing and shows the frame it is told.
class _Player extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events = {};
  Duration position = Duration.zero;
  Uint8List? frame;
  int _next = 1;

  int get last => _next - 1;

  void end(int id) {
    position = const Duration(milliseconds: 52700);
    _events[id]!.add(VideoEvent(eventType: VideoEventType.completed));
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final int id = _next++;
    final StreamController<VideoEvent> events = StreamController();
    _events[id] = events;
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(milliseconds: 52700),
          size: const Size(1080, 2340),
        ),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async => _events[playerId]?.close();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration to) async => position = to;

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => frame == null
      ? const SizedBox.expand()
      : Image.memory(frame!, fit: BoxFit.fill, gaplessPlayback: true);

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}
}

/// What the phone draws over the app: the status bar, the island or the
/// notch, and the home bar.
class _PhoneOver extends StatelessWidget {
  const _PhoneOver({required this.kind, required this.safe});

  final String kind;
  final EdgeInsets safe;

  @override
  Widget build(BuildContext context) {
    const Color ink = Color(0xFF10100C);
    final double barMid = kind == 'button' ? 10 : safe.top / 2 + 2;
    return IgnorePointer(
      child: Stack(
        children: [
          if (kind == 'island')
            Positioned(
              top: 11,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 125,
                  height: 37,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
              ),
            ),
          if (kind == 'notch')
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 162,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: barMid - 10,
            left: kind == 'button' ? 8 : 40,
            child: Text(
              '9:41',
              style: AppText.body(
                size: kind == 'button' ? 13 : 16,
                weight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          Positioned(
            top: barMid - 7,
            right: kind == 'button' ? 8 : 30,
            child: Row(
              children: [
                for (final double h in [5.0, 7.5, 10, 12.5])
                  Container(
                    width: 3.5,
                    height: h,
                    margin: const EdgeInsets.only(right: 2, top: 1),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                const SizedBox(width: 5),
                const Icon(Icons.wifi_rounded, size: 16, color: ink),
                const SizedBox(width: 5),
                Container(
                  width: 25,
                  height: 12.5,
                  padding: const EdgeInsets.all(1.6),
                  decoration: BoxDecoration(
                    border: Border.all(color: ink.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (safe.bottom > 0)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadFonts);
  final VideoCard card = kVideoCards.single;
  late _Player player;
  setUp(() {
    player = _Player();
    VideoPlayerPlatform.instance = player;
  });

  Uint8List frameAt(String name) =>
      File('$_frames/$name.png').readAsBytesSync();

  /// The card opened on [phone], showing the film's frame [moment] (none:
  /// the poster, as the card opens), ended when [ended].
  Future<void> shoot(
    WidgetTester tester,
    String phone,
    String shot, {
    String? moment,
    bool ended = false,
  }) async {
    final (Size size, EdgeInsets safe, String kind) = _phones[phone]!;
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(
      top: safe.top * 3,
      bottom: safe.bottom * 3,
    );
    addTearDown(tester.view.reset);
    final Uint8List? frame = moment == null ? null : frameAt(moment);
    player.frame = frame;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale(_language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        builder: (context, child) => Stack(
          children: [
            child!,
            Positioned.fill(
              child: _PhoneOver(kind: kind, safe: safe),
            ),
          ],
        ),
        home: VideoCardScreen(card: card, language: _language),
      ),
    );
    final BuildContext context = tester.element(find.byType(VideoCardScreen));
    await tester.runAsync(
      () => Future.wait([
        precacheImage(AssetImage(card.posterFor(_language)), context),
        if (frame != null) precacheImage(MemoryImage(frame), context),
      ]),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (moment != null) {
      // The film moves off the frame it started on, and is shown.
      final double at = double.parse(moment.substring(1));
      player.position = Duration(milliseconds: (at * 1000).round());
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    if (ended) {
      player.end(player.last);
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await tester.runAsync(() async {
      if (frame != null) await precacheImage(MemoryImage(frame), context);
    });
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/video/$_language-$phone-$shot.png'),
    );
  }

  for (final String phone in _phones.keys) {
    testWidgets('$phone at one second', (tester) async {
      await shoot(tester, phone, '1-t01', moment: 't01.00');
    });
    testWidgets('$phone opened, at its poster', (tester) async {
      await shoot(tester, phone, '2-t04');
    });
    testWidgets('$phone at its end', (tester) async {
      await shoot(tester, phone, '3-end', moment: 't52.60', ended: true);
    });
  }

  testWidgets('its tile in Explore', (tester) async {
    final app = await tester.runAsync(readyApp);
    final sections = sectionsOf([
      {
        'id': 'videos',
        'block': 'video-cards',
        'title': {'en': 'Cards to watch', 'it': 'Carte da guardare'},
        'subtitle': {
          'en': 'About a minute each.',
          'it': 'Circa un minuto ciascuna.',
        },
      },
    ]);
    await pumpSections(
      tester,
      CoreHost(app!, language: _language),
      sections,
      size: const Size(393, 852),
      locale: const Locale(_language),
    );
    final BuildContext context = tester.element(find.byType(VideoCardTile));
    await tester.runAsync(
      () => precacheImage(AssetImage(card.posterFor(_language)), context),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('shots/video/$_language-explore-tile.png'),
    );
  });
}
