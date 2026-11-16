// A card opened on its own page — from Saved, Liked, the archive or a week
// of the journey — has the card at its head. A card with a drawing shows the
// picture of its front, whole, and plays again at full size; one whose
// picture will not come shows its words, never a hole. A card in words shows
// its question on its colour, as the page always did, and opens the same
// way, to be turned over again. Opened among others — a shelf, a day — the
// cards beside it are a swipe away. Nothing overflows on a 375-point phone,
// at the standard text size or twice it.
//
//   flutter test test/pill_detail_card_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import 'explore/core_harness.dart';
import 'flutter_test_config.dart' show NoPicture;
import 'web/thumbs_harness.dart';

/// [pill]'s own page, on a 375-point phone at [text] times the text size.
Future<void> _open(
  WidgetTester tester,
  AppState app,
  Pill pill, {
  double text = 1,
  List<Pill> among = const [],
}) async {
  tester.view.physicalSize = const Size(375, 667) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(text)),
          child: PillDetailScreen(pill: pill, app: app, among: among),
        ),
      ),
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The picture a test's card shows: one pixel, through a provider of its
/// own (a fresh copy of the bytes), so nothing a test before left in the
/// image cache half decoded is what this one draws.
ImageProvider _freshPixel() =>
    MemoryImage(Uint8List.fromList((onePixel as MemoryImage).bytes));

/// Waits, in real time, until [picture] is decoded, then lets the page draw
/// it: whether a picture has come is not left to how fast the machine is.
Future<void> _decoded(WidgetTester tester, ImageProvider picture) async {
  await tester.runAsync(
    () => precacheImage(
      picture,
      tester.element(find.byType(PillDetailScreen)),
    ).timeout(const Duration(seconds: 10), onTimeout: () {}),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(loadFonts);
  setUp(() {
    Served.useForTest(Served());
    // A picture still being decoded when the test before ended is not left
    // for this one to find.
    imageCache.clear();
    imageCache.clearLiveImages();
  });
  tearDown(() {
    PillBank.reset();
    CardThumb.image = NoPicture.new;
  });

  for (final double text in [1.0, 2.0]) {
    testWidgets('a card with a drawing: its picture at the head, and played '
        'again at full size; at ${text}x', (tester) async {
      final Pill first = pagedCards().first;
      PillBank.adopt(bankWithPictures({first.id}));
      final ImageProvider picture = _freshPixel();
      CardThumb.image = (url) => picture;
      final Pill pill = PillBank.byId(first.id)!;
      final AppState app = await readyApp({
        'knowit.savedIds': [pill.id],
      });
      await _open(tester, app, pill, text: text);
      await _decoded(tester, picture);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(ValueKey('card-thumb-${pill.id}-front')),
        findsOneWidget,
      );
      // The question is on the picture, not printed over it again.
      expect(find.text(pill.question), findsNothing);
      expect(find.text('Play the card'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('detail-play')));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      final DeckViewerScreen viewer = tester.widget(
        find.byType(DeckViewerScreen),
      );
      expect(viewer.deck.single.id, pill.id);
      expect(viewer.source, 'detail');
    });
  }

  testWidgets('the picture itself plays the card too', (tester) async {
    final Pill first = pagedCards().first;
    PillBank.adopt(bankWithPictures({first.id}));
    final ImageProvider picture = _freshPixel();
    CardThumb.image = (url) => picture;
    final Pill pill = PillBank.byId(first.id)!;
    await _open(tester, await readyApp(), pill);

    await tester.tap(find.byKey(const ValueKey('detail-open-card')));
    await _settle(tester);
    expect(find.byType(DeckViewerScreen), findsOneWidget);
  });

  for (final double text in [1.0, 2.0]) {
    testWidgets('a drawing whose picture will not come: its words, within '
        'the card, and still the way to play it; at ${text}x', (tester) async {
      // The longest question among the drawn cards: the one most likely to
      // run past the card's foot at twice the text size.
      final Pill longest = pagedCards().reduce(
        (a, b) => a.question.length >= b.question.length ? a : b,
      );
      PillBank.adopt(bankWithPictures({longest.id}));
      final Pill pill = PillBank.byId(longest.id)!;
      // NoPicture: every picture fails, as with no network.
      await _open(tester, await readyApp(), pill, text: text);

      expect(tester.takeException(), isNull);
      expect(find.text(pill.question), findsOneWidget);
      expect(find.text('Play the card'), findsOneWidget);
    });
  }

  for (final double text in [1.0, 2.0]) {
    testWidgets('a card in words: its question, opened to be turned over '
        'again; at ${text}x', (tester) async {
      final Pill pill = PillBank.cards.firstWhere(
        (p) => !p.hasPage && p.isGraded,
      );
      await _open(tester, await readyApp(), pill, text: text);

      expect(tester.takeException(), isNull);
      expect(find.text(pill.question), findsOneWidget);
      expect(find.text('Open the card'), findsOneWidget);
      expect(find.text('Play the card'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('detail-open-card')));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      final DeckViewerScreen viewer = tester.widget(
        find.byType(DeckViewerScreen),
      );
      expect(viewer.deck.single.id, pill.id);
    });
  }

  testWidgets('opened among others, the cards beside it are a swipe away, '
      'in the order shown', (tester) async {
    final List<Pill> shelf = PillBank.cards
        .where((p) => !p.hasPage && p.isGraded)
        .take(3)
        .toList();
    await _open(tester, await readyApp(), shelf[1], among: shelf);

    expect(tester.takeException(), isNull);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text(shelf[1].question), findsOneWidget);

    await tester.fling(
      find.byKey(const ValueKey('detail-pages')),
      const Offset(-300, 0),
      1500,
    );
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text(shelf[2].question), findsOneWidget);

    // Played from there, it is the card now open that plays.
    await tester.tap(find.text('Open the card'));
    await _settle(tester);
    final DeckViewerScreen viewer = tester.widget(
      find.byType(DeckViewerScreen),
    );
    expect(viewer.deck.single.id, shelf[2].id);
  });

  testWidgets('opened alone, or among cards it is not one of: the one card, '
      'no count', (tester) async {
    final List<Pill> words = PillBank.cards
        .where((p) => !p.hasPage && p.isGraded)
        .take(3)
        .toList();
    await _open(tester, await readyApp(), words[0]);
    expect(find.byKey(const ValueKey('detail-position')), findsNothing);
    expect(find.byKey(const ValueKey('detail-pages')), findsNothing);

    await _open(tester, await readyApp(), words[0], among: words.sublist(1));
    expect(find.byKey(const ValueKey('detail-position')), findsNothing);
    expect(find.text(words[0].question), findsOneWidget);
  });
}
