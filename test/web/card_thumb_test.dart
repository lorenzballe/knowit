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
import 'package:astuto/widgets/ui.dart' show TopicDot;
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
      testWidgets('a card with pictures shows its front, then turned its '
          'back, with its save and share; at ${text}x', (tester) async {
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
        expect(
          find.byKey(ValueKey('card-thumb-${five.first.id}-front')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Save this card'), findsWidgets);

        await tester.tapAt(tester.getCenter(find.byType(TodayDoneView)));
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(ValueKey('card-thumb-${five.first.id}-back')),
          findsOneWidget,
        );
      });

      testWidgets('a card without stays as it was; at ${text}x', (
        tester,
      ) async {
        final List<Pill> five = pagedCards().take(5).toList();
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
        testWidgets('${shelf.name}: a card with pictures leads with its back, '
            'small; one without with its dot; at ${text}x', (tester) async {
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
            // Tall enough for the three rows at twice the text size.
            size: const Size(375, 1100),
            text: text,
          );
          expect(tester.takeException(), isNull);
          for (final int i in [0, 2]) {
            final Finder picture = find.byKey(
              ValueKey('saved-picture-${ids[i]}'),
            );
            expect(picture, findsOneWidget);
            final Size size = tester.getSize(picture);
            expect(size.width / size.height, closeTo(366 / 606, 0.01));
            expect(
              find.byKey(ValueKey('card-thumb-${ids[i]}-back')),
              findsOneWidget,
            );
          }
          expect(find.byKey(ValueKey('saved-picture-${ids[1]}')), findsNothing);
          expect(find.byType(TopicDot), findsOneWidget);
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

    testWidgets('a picture that will not come keeps the row in line', (
      tester,
    ) async {
      final Pill card = pagedCards().first;
      PillBank.adopt(bankWithPictures({card.id}));
      final AppState app = await _dayDone([card], saved: [card.id]);
      await _pump(tester, SavedScreen(app: app, onBackToToday: () {}));
      expect(tester.takeException(), isNull);
      final Finder slot = find.byKey(ValueKey('saved-picture-${card.id}'));
      expect(slot, findsOneWidget);
      // The card in small, its subject's mark on its colour, where the
      // picture would be.
      expect(
        find.descendant(of: slot, matching: find.byType(SubjectIcon)),
        findsOneWidget,
      );
    });
  });

  group('the feed', () {
    for (final double text in [1.0, 2.0]) {
      testWidgets('free cards by their fronts, in the boxes that show them, '
          'never a back; at ${text}x', (tester) async {
        PillBank.adopt(
          bankWithPictures({for (final Pill p in pagedCards()) p.id}),
        );
        CardThumb.image = (url) => onePixel;
        final CoreHost host = CoreHost(await readyApp());
        await pumpSections(tester, host, sectionsOf([_feed]), text: text);
        final ScrollPosition list = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        int pictures = 0;
        int wideInWords = 0;
        for (int i = 0; i < 12; i++) {
          expect(tester.takeException(), isNull);
          for (final Element e in find.byType(BoxTile).evaluate()) {
            final BoxTile tile = e.widget as BoxTile;
            final bool shown = find
                .descendant(
                  of: find.byWidget(tile),
                  matching: find.byKey(
                    ValueKey('tile-picture-${tile.pill.id}'),
                  ),
                )
                .evaluate()
                .isNotEmpty;
            if (shown) {
              pictures++;
              expect(pictureFits(tile.box), isTrue);
            } else if (!pictureFits(tile.box)) {
              wideInWords++;
            }
          }
          list.jumpTo(list.pixels + 500);
          await tester.pump();
        }
        expect(pictures, greaterThan(10));
        expect(wideInWords, greaterThan(0));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('card-thumb-') &&
                (w.key! as ValueKey<String>).value.endsWith('-back'),
          ),
          findsNothing,
        );
      });
    }

    testWidgets('with no pictures in the bank, every tile in words', (
      tester,
    ) async {
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
