// The door to a card's path, under the card when it is read from Explore
// (prototype A5): there for a card in a path, nowhere else; a tap goes on
// at the path's next card, or to its page past what the free plan opens;
// and it fits a small phone at a large text size.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/genres.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/paths_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/card_path_screen.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/path_door.dart';

final DateTime _day = DateTime(2026, 11, 20, 9);

Future<AppState> _app({bool plus = false}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
  });
  final AppState app = AppState(clock: () => _day);
  await app.init();
  return app;
}

/// The first part of the first theme with a path.
CardPath _path() {
  for (final MapEntry<String, List<Genre>> s in kGenres.entries) {
    for (final Genre g in s.value) {
      final List<CardPath> parts = partsOf(g, s.key, PillBank.live);
      if (parts.isNotEmpty) return parts.first;
    }
  }
  throw StateError('no path');
}

/// A card of a theme that has no path.
Pill _pathless() =>
    PillBank.live.firstWhere((p) => p.book == null && pathOfCard(p) == null);

Future<void> _viewer(
  WidgetTester tester,
  AppState app,
  List<Pill> deck, {
  String source = 'explore',
  Locale locale = const Locale('en'),
  Size phone = const Size(390, 844),
  double text = 1,
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: child!,
      ),
      home: DeckViewerScreen(
        app: app,
        deck: deck,
        title: 'Explore',
        source: source,
        countsAsRead: true,
      ),
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  setUp(PillBank.reset);

  test('a card in a path knows its part and its place; one in none, '
      'nothing', () {
    final CardPath path = _path();
    final ({CardPath path, int at})? where = pathOfCard(path.cards[3]);
    expect(where, isNotNull);
    expect(where!.path.genre.id, path.genre.id);
    expect(where.path.part, path.part);
    expect(where.at, 3);
    expect(pathOfCard(_pathless()), isNull);
  });

  testWidgets('under a card of a path read from Explore, and nowhere else', (
    tester,
  ) async {
    final AppState app = await tester.runAsync(_app) as AppState;
    final CardPath path = _path();
    await _viewer(tester, app, [path.cards[3]]);
    expect(find.byType(PathDoor), findsOneWidget);
    expect(find.textContaining('4/${path.cards.length}'), findsOneWidget);

    await _viewer(tester, app, [path.cards[3]], source: 'path');
    expect(find.byType(PathDoor), findsNothing);

    await _viewer(tester, app, [_pathless()]);
    expect(find.byType(PathDoor), findsNothing);
  });

  testWidgets('on Astute+, a tap goes on at the path\'s next card not read', (
    tester,
  ) async {
    final AppState app =
        await tester.runAsync(() => _app(plus: true)) as AppState;
    final CardPath path = _path();
    app.seenIds.add(path.cards[4].id);
    await _viewer(tester, app, [path.cards[3]]);
    await tester.tap(find.byType(PathDoor));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final DeckViewerScreen opened = tester
        .widgetList<DeckViewerScreen>(find.byType(DeckViewerScreen))
        .last;
    expect(opened.source, 'path');
    // Card 5 is read: the way on is card 6.
    expect(opened.initialIndex, 5);
  });

  testWidgets('on the free plan, past the free cards, a tap opens the '
      'path\'s own page', (tester) async {
    final AppState app = await tester.runAsync(_app) as AppState;
    final CardPath path = _path();
    await _viewer(tester, app, [path.cards[3]]);
    await tester.tap(find.byType(PathDoor));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CardPathScreen), findsOneWidget);
  });

  for (final String language in ['en', 'it', 'de', 'ru', 'ja']) {
    testWidgets('fits 320 wide at twice the text size, in $language', (
      tester,
    ) async {
      final AppState app = await tester.runAsync(_app) as AppState;
      final CardPath path = _path();
      await _viewer(
        tester,
        app,
        [path.cards[3]],
        locale: Locale(language),
        phone: const Size(320, 640),
        text: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(PathDoor), findsOneWidget);
    });
  }
}
