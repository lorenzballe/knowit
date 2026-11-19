// Explore's Continue: a path opened and read partway, a book stopped at an
// idea, the latest first, each a tap from the card where the reader stopped;
// locked past what the free plan opens; nothing for a reader who started
// nothing; and a tile that fits a small phone at a large text size.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/books.dart';
import 'package:astuto/data/genres.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/continue_block.dart';
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/screens/card_path_screen.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/reading_log.dart';

import 'core_harness.dart';

final DateTime _day = DateTime(2026, 11, 19, 9);

/// A theme with a path of ten, and its first part.
(Genre, String, CardPath) _theme() {
  for (final MapEntry<String, List<Genre>> s in kGenres.entries) {
    for (final Genre g in s.value) {
      final List<CardPath> parts = partsOf(g, s.key, PillBank.live);
      if (parts.isNotEmpty) return (g, s.key, parts.first);
    }
  }
  throw StateError('no theme of ten cards');
}

/// A theme of exactly [parts] parts, or, with [atLeast], of that many or
/// more.
(Genre, String, List<CardPath>) _themeOf(int parts, {bool atLeast = false}) {
  for (final MapEntry<String, List<Genre>> s in kGenres.entries) {
    for (final Genre g in s.value) {
      final List<CardPath> all = partsOf(g, s.key, PillBank.live);
      if (atLeast ? all.length >= parts : all.length == parts) {
        return (g, s.key, all);
      }
    }
  }
  throw StateError('no theme of $parts parts');
}

ExploreSection get _section =>
    ExploreSection.fromJson({'id': 'continue', 'block': 'continue'});

Future<AppState> _app(WidgetTester? tester, {bool plus = false}) async {
  Future<AppState> make() => readyApp({'knowit.plus': plus}, () => _day);
  if (tester == null) return make();
  return await tester.runAsync(make) as AppState;
}

void main() {
  setUp(PillBank.reset);

  test('nothing started, nothing to go on with', () async {
    final AppState app = await _app(null);
    expect(startedOf(app), isEmpty);
    // Opened and never read is not started either.
    final (Genre g, String key, CardPath _) = _theme();
    await app.notePathOpened(g.id, key, 1);
    expect(startedOf(app), isEmpty);
  });

  test('a path opened keeps the latest six, each once', () async {
    final AppState app = await _app(null);
    final (Genre g, String key, CardPath _) = _theme();
    await app.notePathOpened(g.id, key, 1);
    await app.notePathOpened(g.id, key, 1);
    expect(app.pathsOpened, hasLength(1));
    for (int i = 2; i <= 8; i++) {
      await app.notePathOpened('${g.id}$i', key, 1);
    }
    expect(app.pathsOpened, hasLength(6));
    expect(app.pathsOpened.first, startsWith('${g.id}8|'));
  });

  test('a path read partway goes on at its first card not read, and is '
      'gone once read whole', () async {
    final AppState app = await _app(null, plus: true);
    final (Genre g, String key, List<CardPath> parts) = _themeOf(1);
    final CardPath path = parts.single;
    await app.notePathOpened(g.id, key, 1);
    app.seenIds.addAll([path.cards[0].id, path.cards[1].id, path.cards[3].id]);
    final List<Started> started = startedOf(app);
    expect(started, hasLength(1));
    expect(started.single.path!.genre.id, g.id);
    expect(started.single.read, 3);
    expect(started.single.next, 2);
    app.seenIds.addAll(path.cards.map((c) => c.id));
    expect(startedOf(app), isEmpty);
  });

  test('a part read whole hands on to the next part, deeper', () async {
    final AppState app = await _app(null, plus: true);
    final (Genre g, String key, List<CardPath> parts) = _themeOf(
      2,
      atLeast: true,
    );
    await app.notePathOpened(g.id, key, 1);
    app.seenIds.addAll(parts[0].cards.map((c) => c.id));
    final List<Started> started = startedOf(app);
    expect(started, hasLength(1));
    expect(started.single.path!.part, 2);
    expect(started.single.read, 0);
    expect(started.single.next, 0);
    // The next part opened from there and read whole too: the third,
    // where the theme has one.
    await app.notePathOpened(g.id, key, 2);
    app.seenIds.addAll(parts[1].cards.map((c) => c.id));
    expect(
      startedOf(app).map((s) => s.path!.part),
      parts.length > 2 ? [3] : isEmpty,
    );
  });

  test(
    'a book stopped at an idea is there; the latest read comes first',
    () async {
      final AppState app = await _app(null, plus: true);
      final (Genre g, String key, CardPath path) = _theme();
      final CardBook book = booksOf(PillBank.live, today: _day).first;
      await app.notePathOpened(g.id, key, 1);
      app.seenIds.addAll([path.cards[0].id, book.cards[0].id]);
      // The book was read after the path was opened.
      final int later = _day.millisecondsSinceEpoch ~/ 1000 + 600;
      app.readingLog = [
        CardReadEntry(
          id: book.cards[0].id,
          at: later,
          msFront: 4000,
          msBack: 3000,
        ),
      ];
      final List<Started> started = startedOf(app);
      expect(started.map((s) => s.book?.id ?? s.path!.genre.id), [
        book.id,
        g.id,
      ]);
      expect(started.first.next, 1);
      // Narrowed to another subject, neither.
      expect(startedOf(app, subject: 'No such subject'), isEmpty);
    },
  );

  testWidgets('a tap goes on at the card where the reader stopped', (
    tester,
  ) async {
    final AppState app = await _app(tester, plus: true);
    final (Genre g, String key, CardPath path) = _theme();
    await tester.runAsync(() => app.notePathOpened(g.id, key, 1));
    app.seenIds.addAll(path.cards.take(4).map((c) => c.id));
    final CoreHost host = CoreHost(app);
    await pumpSections(tester, host, [_section]);
    expect(find.byType(StartedTile), findsOneWidget);
    await tester.tap(find.byType(StartedTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final DeckViewerScreen deck = tester.widget(find.byType(DeckViewerScreen));
    expect(deck.initialIndex, 4);
  });

  testWidgets('on the free plan, past the free cards, the tile is locked '
      'and opens the path\'s own page', (tester) async {
    final AppState app = await _app(tester);
    final (Genre g, String key, CardPath path) = _theme();
    await tester.runAsync(() => app.notePathOpened(g.id, key, 1));
    app.seenIds.addAll(path.cards.take(kPathFree).map((c) => c.id));
    final CoreHost host = CoreHost(app);
    await pumpSections(tester, host, [_section]);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    await tester.tap(find.byType(StartedTile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CardPathScreen), findsOneWidget);
  });

  testWidgets('nothing started, no section', (tester) async {
    final AppState app = await _app(tester);
    final CoreHost host = CoreHost(app);
    await pumpSections(tester, host, [_section]);
    expect(find.byType(StartedTile), findsNothing);
  });

  for (final String language in ['en', 'it', 'de', 'ru', 'ja']) {
    testWidgets('fits 320 wide at twice the text size, in $language', (
      tester,
    ) async {
      final AppState app = await _app(tester);
      final (Genre g, String key, CardPath path) = _theme();
      final CardBook book = booksOf(PillBank.live, today: _day).first;
      await tester.runAsync(() => app.notePathOpened(g.id, key, 1));
      app.seenIds.addAll([path.cards[0].id, book.cards[0].id]);
      final CoreHost host = CoreHost(app, language: language);
      await pumpSections(
        tester,
        host,
        [_section],
        size: const Size(320, 640),
        text: 2,
        locale: Locale(language),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(StartedTile), findsNWidgets(2));
    });
  }
}
