// A free card shown outside the deck by its picture: the whole card, with
// its drawing, on the day's shelf (front, then back once turned), on the
// reader's own shelves (the back, small), and in Explore's feed (the front
// only, in the boxes that show it) — and drawn as before where it has no
// picture, or its picture will not come. Nothing overflows on a 375-point
// phone, at the standard text size or twice it.
//
//   flutter test test/web/card_thumb_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';
import 'package:astuto/widgets/subject_icon.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../explore/core_harness.dart';
import '../flutter_test_config.dart' show NoPicture;
import 'thumbs_harness.dart';

const Map<String, Object?> _feed = {
  'id': 'feed',
  'block': 'feed',
  'title': 'Keep exploring',
};

/// [child] as the app shows a screen, on a phone of [size] at [text] times
/// the text size, at night.
/// A card's picture on the shelf: the one taken at the shelf's proportion or
/// the one at the deck's, whichever is nearer the card's shape.
Finder _picture(String id, String side) => find.byWidgetPredicate(
  (w) =>
      w.key == ValueKey('card-thumb-$id-$side-shelf') ||
      w.key == ValueKey('card-thumb-$id-$side-large'),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(375, 667),
  double text = 1,
}) async {
  tester.view.physicalSize = size * 3;
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
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets the pictures on screen come: decoded for real, as a phone does, then
/// faded in. Until they have, a card shows its outline in grey and nothing
/// on it.
Future<void> _arrive(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final Element e in find.byType(Image).evaluate().toList()) {
      await precacheImage((e.widget as Image).image, e, onError: (_, _) {});
    }
  });
  await tester.pump();
  await tester.pump(CardThumb.fade);
  await tester.pump(const Duration(milliseconds: 50));
}

/// A reader whose day is done, its five [five], with [saved] kept.
Future<AppState> _dayDone(List<Pill> five, {List<String> saved = const []}) {
  final String today = dateKey(DateTime.now());
  final List<String> ids = [for (final Pill p in five) p.id];
  return readyApp({
    'knowit.pushAsked': true,
    'knowit.todayDate': today,
    'knowit.todayDeckIds': ids,
    'knowit.todayIndex': ids.length,
    'knowit.streak': 1,
    'knowit.bestStreak': 1,
    'knowit.lastCompletionDate': today,
    'knowit.completedDates': [today],
    'knowit.seenIds': ids,
    'knowit.savedIds': saved,
    'knowit.likedIds': saved,
  });
}

void main() {
  setUpAll(loadFonts);
  setUp(() => Served.useForTest(Served()));
  tearDown(() {
    PillBank.reset();
    CardThumb.image = NoPicture.new;
  });

  group('the bank names them', () {
    final Map<String, Object?> web = {
      'page': 'pages/maths-x.html?v=abcdef12',
      'thumbs': {
        'front': 'thumbs/maths-x-front.webp?v=abcdef12',
        'back': 'thumbs/maths-x-back.webp?v=abcdef12',
      },
    };

    test('read from the card\'s face, and written back as read', () {
      final WebFace face = webFromJson(web)!;
      expect(face.thumbs!.front, 'thumbs/maths-x-front.webp?v=abcdef12');
      expect(face.thumbs!.back, 'thumbs/maths-x-back.webp?v=abcdef12');
      final Map<String, Object?> out = webToJson(
        face,
        challenge: const NoChallenge(),
      );
      expect(out['thumbs'], web['thumbs']);
      expect(webFromJson(out)!.thumbs, face.thumbs);
    });

    test('absent, or naming anything but a picture of the bank\'s, none', () {
      expect(webFromJson({'page': web['page']})!.thumbs, isNull);
      expect(
        webToJson(
          webFromJson({'page': web['page']})!,
          challenge: const NoChallenge(),
        ).containsKey('thumbs'),
        isFalse,
      );
      final WebFace odd = webFromJson({
        'page': web['page'],
        'thumbs': {
          'front': 'https://elsewhere.example/x.webp',
          'back': 'thumbs/maths-x-back.webp?v=abcdef12',
        },
      })!;
      expect(odd.thumbs!.front, isNull);
      expect(odd.thumbs!.back, 'thumbs/maths-x-back.webp?v=abcdef12');
      expect(
        webFromJson({
          'page': web['page'],
          'thumbs': {'front': 'thumbs/../x.png'},
        })!.thumbs,
        isNull,
      );
    });
  });

  group('a picture', () {
    testWidgets('fetched from beside the bank, with what goes over it', (
      tester,
    ) async {
      final Pill card = pagedCards().first;
      PillBank.adopt(bankWithPictures({card.id}));
      final Pill pill = PillBank.byId(card.id)!;
      final List<Uri> asked = [];
      CardThumb.image = (url) {
        asked.add(url);
        return onePixel;
      };
      await _pump(
        tester,
        SizedBox(
          width: 120,
          height: 200,
          child: CardThumb(
            pill: pill,
            side: CardSide.front,
            fallback: const Text('words'),
            foreground: const Text('over'),
          ),
        ),
      );
      expect(asked.single.toString(), startsWith(kCardsBase));
      expect(
        asked.single.path,
        endsWith('/cards/thumbs/${card.id}-front.webp'),
      );
      expect(find.byKey(ValueKey('card-thumb-${card.id}-front')), findsOne);
      expect(find.text('over'), findsOneWidget);
      expect(find.text('words'), findsNothing);
    });

    testWidgets('none, or one that will not come: the fallback', (
      tester,
    ) async {
      final Pill card = pagedCards().first;
      await _pump(
        tester,
        CardThumb(
          pill: card,
          side: CardSide.front,
          fallback: const Text('words'),
        ),
      );
      expect(find.text('words'), findsOneWidget);

      PillBank.adopt(bankWithPictures({card.id}));
      await _pump(
        tester,
        CardThumb(
          pill: PillBank.byId(card.id)!,
          side: CardSide.back,
          fallback: const Text('words'),
          foreground: const Text('over'),
        ),
      );
      expect(find.text('words'), findsOneWidget);
      expect(find.text('over'), findsNothing);
    });
  });

  group('the day\'s shelf', () {
    for (final double text in [1.0, 2.0]) {
      testWidgets('a card with pictures shows its front, its question, then '
          'turned its back, with its save and share; at ${text}x', (
        tester,
      ) async {
        final List<Pill> five = pagedCards().take(5).toList();
        PillBank.adopt(bankWithPictures({five.first.id}));
        CardThumb.image = (url) => onePixel;
        final AppState app = await _dayDone([
          for (final Pill p in five) PillBank.byId(p.id)!,
        ]);
        await _pump(
          tester,
          TodayDoneView(app: app, at: 0, onPick: (_) {}),
          text: text,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('shelf-picture')), findsWidgets);
        expect(_picture(five.first.id, 'front'), findsOneWidget);
        await _arrive(tester);
        expect(find.bySemanticsLabel('Save this card'), findsWidgets);

        await tester.tapAt(tester.getCenter(find.byType(TodayDoneView)));
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(_picture(five.first.id, 'back'), findsOneWidget);
      });

      testWidgets('a card without stays as it was; at ${text}x', (
        tester,
      ) async {
        PillBank.adopt(bankWithPictures({}));
        final List<Pill> five = [
          for (final Pill p in pagedCards().take(5)) PillBank.byId(p.id)!,
        ];
        final AppState app = await _dayDone(five);
        await _pump(
          tester,
          TodayDoneView(app: app, at: 0, onPick: (_) {}),
          text: text,
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('shelf-picture')), findsNothing);
        expect(find.byType(Image), findsNothing);
        expect(find.text(five.first.question), findsOneWidget);
      });
    }

    testWidgets('on a phone of the owner\'s size the card shows the picture '
        'taken at the shelf\'s proportion, side to side', (tester) async {
      final List<Pill> five = pagedCards().take(5).toList();
      PillBank.adopt(bankWithPictures({five.first.id}));
      CardThumb.image = (url) => onePixel;
      final AppState app = await _dayDone([
        for (final Pill p in five) PillBank.byId(p.id)!,
      ]);
      await _pump(
        tester,
        TodayDoneView(app: app, at: 0, onPick: (_) {}),
        // The room the shelf has between Today's head and its foot on that
        // phone: about 345 by 488 for the card.
        size: const Size(393, 600),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(ValueKey('card-thumb-${five.first.id}-front-shelf')),
        findsOneWidget,
      );
    });

    testWidgets('a picture that will not come: the card in words', (
      tester,
    ) async {
      final List<Pill> five = pagedCards().take(5).toList();
      PillBank.adopt(bankWithPictures({five.first.id}));
      final AppState app = await _dayDone([
        for (final Pill p in five) PillBank.byId(p.id)!,
      ]);
      await _pump(tester, TodayDoneView(app: app, at: 0, onPick: (_) {}));
      expect(tester.takeException(), isNull);
      expect(find.text(five.first.question), findsOneWidget);
    });
  });

  group('the reader\'s shelves', () {
    for (final Shelf shelf in Shelf.values) {
      for (final double text in [1.0, 2.0]) {
        testWidgets('${shelf.name}: every kept card is the card in small, '
            'its back where it has one; at ${text}x', (tester) async {
          final List<Pill> cards = pagedCards().take(3).toList();
          PillBank.adopt(bankWithPictures({cards[0].id, cards[2].id}));
          final List<String> ids = [for (final Pill p in cards) p.id];
          CardThumb.image = (url) => onePixel;
          final AppState app = await _dayDone(
            cards.take(1).toList(),
            saved: ids,
          );
          await _pump(
            tester,
            SavedScreen(app: app, onBackToToday: () {}, shelf: shelf),
            size: const Size(375, 1100),
            text: text,
          );
          expect(tester.takeException(), isNull);
          // A wall of cards, three across, each in the card's proportion,
          // whatever the text size: a picture does not grow with the text.
          for (final String id in ids) {
            final Finder tile = find.byKey(ValueKey('kept-$id'));
            expect(tile, findsOneWidget);
            final Size size = tester.getSize(tile);
            expect(size.width / size.height, closeTo(366 / 606, 0.01));
            expect(size.width, lessThan(375 / 3));
          }
          for (final int i in [0, 2]) {
            expect(
              find.byKey(ValueKey('card-thumb-${ids[i]}-back')),
              findsOneWidget,
            );
          }
          // The one with no picture is the card in small anyway: its mark
          // and its question on its colour.
          final Finder plain = find.byKey(ValueKey('kept-${ids[1]}'));
          expect(
            find.descendant(of: plain, matching: find.byType(SubjectIcon)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: plain, matching: find.text(cards[1].question)),
            findsOneWidget,
          );
          // Nothing of the front, which is the card unanswered.
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.endsWith('-front'),
            ),
            findsNothing,
          );
        });
      }
    }

    testWidgets('a picture that will not come leaves the card in small', (
      tester,
    ) async {
      final Pill card = pagedCards().first;
      PillBank.adopt(bankWithPictures({card.id}));
      final AppState app = await _dayDone([card], saved: [card.id]);
      await _pump(tester, SavedScreen(app: app, onBackToToday: () {}));
      expect(tester.takeException(), isNull);
      final Finder slot = find.byKey(ValueKey('kept-${card.id}'));
      expect(slot, findsOneWidget);
      // Its subject's mark on its colour, where the picture would be.
      expect(
        find.descendant(of: slot, matching: find.byType(SubjectIcon)),
        findsOneWidget,
      );
    });

    testWidgets('all of the shelf is in the order it was kept; a subject '
        'picked is its cards under its mark', (tester) async {
      final Map<String, Pill> bySubject = {};
      for (final Pill p in pagedCards()) {
        bySubject.putIfAbsent(p.topic, () => p);
        if (bySubject.length == 3) break;
      }
      final List<Pill> kept = bySubject.values.toList();
      PillBank.adopt(bankWithPictures({for (final p in kept) p.id}));
      CardThumb.image = (url) => onePixel;
      final AppState app = await _dayDone(
        kept.take(1).toList(),
        saved: [for (final p in kept) p.id],
      );
      await _pump(
        tester,
        SavedScreen(app: app, onBackToToday: () {}),
        size: const Size(375, 1400),
      );
      expect(tester.takeException(), isNull);
      // All: one wall, no heads, the cards in the shelf's own order.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('kept-block-'),
        ),
        findsNothing,
      );
      final List<double> lefts = [
        for (final String id in app.savedIds)
          tester.getTopLeft(find.byKey(ValueKey('kept-$id'))).dx,
      ];
      expect(lefts, orderedEquals([...lefts]..sort()));

      // A subject picked: its head, its mark, its cards.
      final String key = kTopics.entries
          .firstWhere((e) => e.value.name == kept[1].topic)
          .key;
      await tester.tap(find.byKey(ValueKey('saved-filter-$key')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(ValueKey('kept-block-$key')), findsOneWidget);
      expect(find.byKey(ValueKey('kept-${kept[1].id}')), findsOneWidget);
      expect(find.byKey(ValueKey('kept-${kept[0].id}')), findsNothing);
      expect(find.byType(SubjectBadge), findsWidgets);
    });
  });

  group('the feed', () {
    for (final double text in [1.0, 2.0]) {
      testWidgets('every card in words, a drawn one too, with its picture in '
          'the bank: the drawing is for the card opened; at ${text}x', (
        tester,
      ) async {
        PillBank.adopt(
          bankWithPictures({for (final Pill p in pagedCards()) p.id}),
        );
        CardThumb.image = (url) => onePixel;
        final CoreHost host = CoreHost(await readyApp());
        await pumpSections(tester, host, sectionsOf([_feed]), text: text);
        final ScrollPosition list = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        int tiles = 0;
        for (int i = 0; i < 12; i++) {
          expect(tester.takeException(), isNull);
          tiles += find.byType(BoxTile).evaluate().length;
          expect(find.byType(CardThumb), findsNothing);
          list.jumpTo(list.pixels + 500);
          await tester.pump();
        }
        expect(tiles, greaterThan(10));
      });
    }

    testWidgets('with no pictures in the bank, every tile in words', (
      tester,
    ) async {
      PillBank.adopt(bankWithPictures({}));
      final CoreHost host = CoreHost(await readyApp());
      await pumpSections(tester, host, sectionsOf([_feed]));
      expect(find.byType(BoxTile), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('tile-picture-'),
        ),
        findsNothing,
      );
    });

    test('a wide box takes a card without a picture first', () {
      expect(pictureFits(const Size(163, 163)), isTrue);
      expect(pictureFits(const Size(163, 334)), isTrue);
      expect(pictureFits(const Size(334, 163)), isFalse);
    });
  });
}
