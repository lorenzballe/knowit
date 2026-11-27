// A video card is a card on Explore like any other (lib/data/video_cards.dart,
// videoPills): dealt in the feed, where the day's film opens it until it is
// watched, and on the shelves that lay any card as a tile, never by a query
// of kinds of question nor by a block that would draw it as a card to read;
// its tile has its subject's colour and a play mark; a tap plays the film
// on the whole screen out of its tile, never opens it as a card, and counts
// it read, as any card opened from Explore is.
//
//   flutter test test/explore/films_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/data/video_cards.dart';
import 'package:astuto/explore/blocks/core/shelves.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';
import 'package:astuto/widgets/video_card.dart';

import 'core_harness.dart';

/// A player that plays nothing, and says it is ready.
class _Player extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events = {};
  int _next = 1;

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
          size: kFilmFrame,
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
  Future<void> seekTo(int playerId, Duration to) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Color(0xFF00AA00));

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}
}

const String _film = 'video-eratosthenes';

ExploreSection _section(String block, {Object? source, String id = 's'}) =>
    ExploreSection.fromJson({'id': id, 'block': block, 'source': ?source});

List<String> _ids(List<Pill> cards) => [for (final p in cards) p.id];

void main() {
  setUpAll(loadFonts);
  setUp(() => Served.useForTest(Served()));

  test('a film as a card: its subject, its colour, its question in the '
      "reader's language, English where it is not told in theirs", () {
    final Pill it = videoPills('it').single;
    final TopicStyle history = kTopics['history']!;
    expect(it.id, _film);
    expect(it.topic, history.name);
    expect(it.color, history.color);
    expect(it.question, 'Come si misura la Terra con un bastone?');
    expect(it.language, 'it');
    expect(videoPills('de').single.question, kVideoCards.single.title['en']);
    expect(videoCardOf(it), same(kVideoCards.single));
    expect(videoCardOf(PillBank.cards.first), isNull);
    // Never a card of the bank: the day's five, search and the server deal
    // the bank's.
    expect(PillBank.byId(_film), isNull);
  });

  test("the feed opens on the day's film while it is not watched; watched, "
      'it is a card read, where its lot puts it', () async {
    final ExploreShelves shelves = ExploreShelves(await readyApp())
      ..begin(language: 'it');
    final List<Pill> pool = shelves.cardsFor(_section('feed', id: 'feed'));
    expect(pool.first.id, _film);
    expect(pool.first.question, 'Come si misura la Terra con un bastone?');
    expect(_ids(pool).where((id) => id == _film), hasLength(1));
    expect(pool, hasLength(PillBank.cards.length + 1));

    final ExploreShelves watched = ExploreShelves(
      await readyApp({
        'knowit.seenIds': [_film],
      }),
    )..begin(language: 'it');
    final List<Pill> after = watched.cardsFor(_section('feed', id: 'feed'));
    expect(after.first.id, isNot(_film));
    expect(_ids(after), contains(_film));

    // Another subject's feed has no film; its own has.
    final ExploreShelves space = ExploreShelves(await readyApp())
      ..begin(subject: 'Space', language: 'it');
    expect(
      _ids(space.cardsFor(_section('feed', id: 'feed'))),
      isNot(contains(_film)),
    );
    final ExploreShelves history = ExploreShelves(await readyApp())
      ..begin(subject: 'History', language: 'it');
    expect(history.cardsFor(_section('feed', id: 'feed')).first.id, _film);
  });

  test('a shelf of tiles deals a film like any card of its subject; a query '
      'of kinds of question, a block that draws a card to read, and a section '
      'with no source but the feed never do', () async {
    final ExploreShelves shelves = ExploreShelves(await readyApp())
      ..begin(language: 'it');
    const Map<String, Object> history = {
      'query': {
        'subjects': ['history'],
        'limit': 1000,
      },
    };
    for (final String block in kFilmBlocks.difference({'feed'})) {
      expect(
        _ids(shelves.cardsFor(_section(block, source: history, id: block))),
        contains(_film),
        reason: block,
      );
    }
    expect(
      _ids(
        shelves.cardsFor(
          _section(
            'carousel',
            id: 'reads',
            source: const {
              'query': {
                'subjects': ['history'],
                'formats': ['read'],
                'limit': 1000,
              },
            },
          ),
        ),
      ),
      isNot(contains(_film)),
    );
    expect(
      _ids(shelves.cardsFor(_section('single', source: history, id: 'one'))),
      isNot(contains(_film)),
    );
    expect(
      _ids(shelves.cardsFor(_section('carousel', id: 'whole'))),
      isNot(contains(_film)),
    );
  });

  testWidgets("a film's tile has its subject's colour and a play mark, and "
      'how long it runs where the tile has a foot or words in its head', (
    tester,
  ) async {
    final Pill film = videoPills('it').single;
    Future<void> tile(Size box) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: BoxTile(pill: film, box: box),
            ),
          ),
        ),
      );
    }

    // Large: the mark in the head, how long it runs in the foot.
    await tile(const Size(300, 260));
    expect(find.byKey(const ValueKey('film-mark')), findsOneWidget);
    expect(find.text('0:53'), findsOneWidget);
    expect(find.text('STORIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // A box with words in its head and no foot: both in the head.
    await tile(const Size(171, 150));
    expect(find.byKey(const ValueKey('film-mark')), findsOneWidget);
    expect(find.text('0:53'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // The smallest: the mark alone.
    await tile(const Size(120, 140));
    expect(find.byKey(const ValueKey('film-mark')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      questionFits(
        tester.element(find.byType(BoxTile)),
        film,
        const Size(171, 150),
        TileLook.forBox(const Size(171, 150)),
      ),
      isTrue,
    );
  });

  testWidgets("where the subject's name and how long the film runs do not "
      'both fit in the head, the length gives way: the name is never cut '
      '("GESCHICH…" on a small phone in German)', (tester) async {
    await tester.runAsync(loadFonts);
    Future<RenderParagraph> tile(String language) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              // A tile of the feed's two columns on a 375-point phone.
              child: BoxTile(
                pill: videoPills(language).single,
                box: const Size(163, 150),
              ),
            ),
          ),
        ),
      );
      final String name = lookupAppLocalizations(
        Locale(language),
      ).subjectOf(videoPills(language).single.topic).toUpperCase();
      return tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(name), matching: find.byType(RichText)),
      );
    }

    // German: GESCHICHTE whole, the play mark alone beside it.
    expect((await tile('de')).didExceedMaxLines, isFalse);
    expect(find.byKey(const ValueKey('film-mark')), findsOneWidget);
    expect(find.text('0:53'), findsNothing);
    // Italian: STORIA and 0:53 both fit, and both are there.
    expect((await tile('it')).didExceedMaxLines, isFalse);
    expect(find.text('0:53'), findsOneWidget);
  });

  testWidgets('on Explore a tap on a film plays it out of its box, never as a '
      'card, and counts it read; a card beside it opens among the cards, the '
      'film left out', (tester) async {
    VideoPlayerPlatform.instance = _Player();
    final AppState app = await tester.runAsync(readyApp) as AppState;
    Remote.adopt(
      RemoteConfig(
        hash: 'films',
        schema: kRemoteSchema,
        parts: {
          'explore': {
            'sections': [
              {'id': 'feed', 'block': 'feed'},
            ],
          },
        },
      ),
    );
    addTearDown(Remote.reset);
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(body: ExploreScreen(app: app)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final Finder film = find.byKey(const ValueKey('explore-$_film'));
    expect(film, findsOneWidget);
    expect(
      find.descendant(of: film, matching: find.byType(VideoCardHero)),
      findsOneWidget,
    );
    expect(
      find.text('Come si misura la Terra con un bastone?'),
      findsOneWidget,
    );

    // The card beside it opens among the feed's cards, the film not one.
    // A card's tile, not the head, the search or the refresh, which carry
    // the same prefix.
    final Finder other = find.byWidgetPredicate((w) {
      final Key? key = w.key;
      if (key is! ValueKey<String>) return false;
      final String k = key.value;
      return k.startsWith('explore-') &&
          k != 'explore-$_film' &&
          PillBank.byId(k.substring('explore-'.length)) != null;
    });
    // Which card sits beside the film depends on the day's deal, and some
    // days the film's band fills the screen: scroll the feed to the first
    // card that can be touched.
    final Finder page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    for (int i = 0; i < 12 && other.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(page, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.tap(other.hitTestable().first);
    await tester.pumpAndSettle();
    final DeckViewerScreen viewer = tester.widget(
      find.byType(DeckViewerScreen),
    );
    expect(_ids(viewer.deck), isNot(contains(_film)));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    // Back to the top, where the film is.
    await tester.drag(page, const Offset(0, 6000));
    await tester.pumpAndSettle();

    await tester.tap(film);
    await tester.pump();
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VideoCardScreen), findsOneWidget);
    expect(find.byType(DeckViewerScreen), findsNothing);
    expect(app.seenIds, contains(_film));
  });
}
