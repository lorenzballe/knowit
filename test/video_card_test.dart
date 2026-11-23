// Video cards (lib/data/video_cards.dart, lib/widgets/video_card.dart): a
// tap on the tile opens the card to the whole screen, a second tap plays its
// film, another pauses it, its end offers it again, a film that cannot be
// had says so and is tried again with a tap, and Explore shows the card on
// its page and on its subject's.
//
//   flutter test test/video_card_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:astuto/data/video_cards.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/video_card.dart';

import 'explore/core_harness.dart';

/// A player that plays nothing: it says it is ready, or that the film could
/// not be had, and keeps what it was asked.
class _Player extends VideoPlayerPlatform {
  final List<String> asked = [];
  final Map<int, StreamController<VideoEvent>> _events = {};
  Duration position = Duration.zero;
  bool offline = false;
  int _next = 1;

  void end(int id) {
    position = const Duration(milliseconds: 52700);
    _events[id]!.add(VideoEvent(eventType: VideoEventType.completed));
  }

  int get last => _next - 1;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final int id = _next++;
    final StreamController<VideoEvent> events = StreamController();
    _events[id] = events;
    asked.add('make ${options.dataSource.uri}');
    final bool fails = offline;
    scheduleMicrotask(() {
      if (fails) {
        events.addError(
          PlatformException(code: 'offline', message: 'no connection'),
        );
      } else {
        events.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(milliseconds: 52700),
            size: const Size(1080, 1920),
          ),
        );
      }
    });
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async {
    asked.add('dispose');
    await _events[playerId]?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async => asked.add('play');

  @override
  Future<void> pause(int playerId) async => asked.add('pause');

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration to) async {
    asked.add('seek ${to.inMilliseconds}');
    position = to;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(key: ValueKey('film'), color: Color(0xFF00AA00));

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}
}

void main() {
  setUpAll(loadFonts);
  late _Player player;
  setUp(() {
    player = _Player();
    VideoPlayerPlatform.instance = player;
  });

  final VideoCard card = kVideoCards.single;

  test('a card is told in English and Italian, the rest in English; its '
      'film is on the site and its first frame in the app', () {
    expect(card.languageFor('it'), 'it');
    expect(card.languageFor('de'), 'en');
    expect(
      card.filmFor('it').toString(),
      'https://astutetheapp.com/cards/video/eratosthenes-it.mp4',
    );
    expect(card.posterFor('ja'), 'assets/video/eratosthenes-en.webp');
    expect(card.titleFor('fr'), card.title['en']);
    expect(filmClock(card.length), '0:53');
  });

  Future<void> phone(
    WidgetTester tester, {
    Size size = const Size(402, 874),
    String language = 'it',
    EdgeInsets safe = const EdgeInsets.only(top: 62, bottom: 34),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(
      top: safe.top * 3,
      bottom: safe.bottom * 3,
    );
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: SizedBox(
                width: size.width - 40,
                height: (size.width - 40) * 5 / 4,
                child: VideoCardTile(
                  card: card,
                  language: language,
                  onOpen: () =>
                      openVideoCard(context, card, language: language),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Opens the card from its tile and waits for it to be up: not until
  /// nothing moves, since a film playing keeps its line of how far it has
  /// run moving.
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byType(VideoCardTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await settle(tester);
  }

  /// Where the film's picture stands on the screen.
  Rect pictureOn(WidgetTester tester) => tester.getRect(
    find.descendant(
      of: find.byType(VideoCardScreen),
      matching: find.byType(Image),
    ),
  );

  testWidgets('a tap on the tile opens the card to the whole screen, and it '
      'plays at once from the frame the tile shows; a tap pauses it, another '
      'goes on; at its end it is offered again; the cross puts it back', (
    tester,
  ) async {
    await phone(tester);
    final l = lookupAppLocalizations(const Locale('it'));
    expect(find.text('0:53'), findsOneWidget);
    await tester.tap(find.byType(VideoCardTile));
    // On its way up, the film is fetched and set on the tile's frame, and
    // waits for the card to be up.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      player.asked.first,
      'make https://astutetheapp.com/cards/video/eratosthenes-it.mp4',
    );
    expect(player.asked, contains('seek ${card.posterAt.inMilliseconds}'));
    expect(player.asked, isNot(contains('play')));
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(find.byType(VideoCardScreen), findsOneWidget);
    expect(player.asked.last, 'play');
    // The card is the screen: the film across it, standing on its foot, the
    // card's ground above it holding the row of controls. No way to play it
    // is asked for: it plays.
    final Rect place = pictureOn(tester);
    expect(place.width / place.height, closeTo(9 / 16, 0.01));
    expect(place.width, closeTo(402, 0.5));
    expect(place.bottom, closeTo(874, 0.5));
    expect(place.top, greaterThanOrEqualTo(62 + 48));
    expect(find.byKey(const ValueKey('video-play')), findsNothing);
    // Until it moves, the frame it starts on is the picture, and the line of
    // how far it has run says it is coming.
    expect(find.byKey(const ValueKey('film')), findsNothing);
    expect(find.byKey(const ValueKey('video-coming')), findsOneWidget);
    player.position = const Duration(seconds: 6);
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
    expect(find.byKey(const ValueKey('film')), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey('film'))), place);
    expect(find.byKey(const ValueKey('video-coming')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('video-card')));
    await settle(tester);
    expect(player.asked.last, 'pause');
    expect(find.byKey(const ValueKey('video-play')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('video-card')));
    await settle(tester);
    expect(player.asked.last, 'play');
    expect(find.byKey(const ValueKey('video-play')), findsNothing);
    player.end(player.last);
    await settle(tester);
    expect(find.byKey(const ValueKey('video-again')), findsOneWidget);
    expect(find.text(l.videoWatchAgain), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('video-again')));
    await settle(tester);
    expect(player.asked, containsAllInOrder(['seek 0', 'play']));

    await tester.tap(find.byKey(const ValueKey('video-close')));
    await tester.pumpAndSettle();
    expect(find.byType(VideoCardScreen), findsNothing);
    // The player is let go with the card.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    expect(player.asked, contains('dispose'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a film that cannot be had says it needs a connection, and a '
      'tap tries again and plays it', (tester) async {
    player.offline = true;
    await phone(tester, language: 'en');
    final l = lookupAppLocalizations(const Locale('en'));
    await open(tester);
    expect(find.text(l.videoOffline), findsOneWidget);
    expect(find.byKey(const ValueKey('video-coming')), findsNothing);
    player.offline = false;
    await tester.tap(find.byKey(const ValueKey('video-card')));
    await settle(tester);
    expect(find.text(l.videoOffline), findsNothing);
    expect(
      player.asked.where((a) => a.startsWith('make ')).toList(),
      hasLength(2),
    );
    expect(player.asked, contains('play'));
    await tester.tap(find.byKey(const ValueKey('video-close')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulled down far enough, the card goes back to its tile', (
    tester,
  ) async {
    await phone(tester);
    await open(tester);
    await tester.drag(
      find.byKey(const ValueKey('video-card')),
      const Offset(0, 60),
    );
    await settle(tester);
    expect(find.byType(VideoCardScreen), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('video-card')),
      const Offset(0, 240),
    );
    await settle(tester);
    expect(find.byType(VideoCardScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final (Size size, EdgeInsets safe) in [
    (const Size(320, 568), const EdgeInsets.only(top: 20)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(412, 915), const EdgeInsets.only(top: 24, bottom: 48)),
  ]) {
    for (final String language in ['en', 'it', 'de', 'ja']) {
      testWidgets('the card lays out on a ${size.width.round()} by '
          '${size.height.round()} phone in $language', (tester) async {
        await phone(tester, size: size, language: language, safe: safe);
        await open(tester);
        final Rect place = pictureOn(tester);
        expect(place.left, greaterThanOrEqualTo(0));
        expect(place.right, lessThanOrEqualTo(size.width + 0.01));
        expect(place.top, greaterThanOrEqualTo(safe.top + 48));
        // On a phone long enough, across it and on its foot, lifted only
        // above a foot taller than a home bar; else whole above the foot.
        if (size.height / size.width > 16 / 9 + 0.1) {
          expect(place.width, closeTo(size.width, 0.5));
          expect(
            place.bottom,
            closeTo(size.height - (safe.bottom - 34).clamp(0, 99), 0.5),
          );
        } else {
          expect(place.bottom, lessThanOrEqualTo(size.height - safe.bottom));
        }
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('video-close')));
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('Explore shows the card on its page and on its subject\'s, '
      'not on another subject\'s', (tester) async {
    final AppState app = await tester.runAsync(readyApp) as AppState;
    final sections = sectionsOf([
      {
        'id': 'videos',
        'block': 'video-cards',
        'title': {'en': 'Cards to watch'},
        'subtitle': {'en': 'About a minute each.'},
      },
    ]);
    const Key tile = ValueKey('video-tile-video-eratosthenes');
    await pumpSections(tester, CoreHost(app), sections);
    await tester.pumpAndSettle();
    expect(find.byKey(tile), findsOneWidget);
    expect(find.text('Cards to watch'), findsOneWidget);
    await pumpSections(tester, CoreHost(app, subject: 'History'), sections);
    await tester.pumpAndSettle();
    expect(find.byKey(tile), findsOneWidget);
    await pumpSections(tester, CoreHost(app, subject: 'Science'), sections);
    await tester.pumpAndSettle();
    expect(find.byKey(tile), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
