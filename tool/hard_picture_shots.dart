// Photographs hard cards as the app ships them, ringed
// (lib/widgets/hard_ring.dart), in the app's own screens, on the night paper
// and the day one: Today's deck with a hard card in words on top, its front
// and, once answered, its back; the finished day's shelf with a hard drawn
// card at the front, shown by the picture taken of it ringed, front and
// turned; the saved shelf; and the card's own page.
//
//   flutter test tool/hard_picture_shots.dart
//   SHOTS=/some/dir flutter test tool/hard_picture_shots.dart
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// pictures are the real ones, read from web/cards/thumbs/ (take them with
// tool/cards/thumbs.cjs first); the shots land in tool/shots/hard-pictures/
// unless SHOTS names another folder, named <what>-<night|day>.png, to be
// looked at, not kept.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';

/// The hard card in words on top of the deck, and the hard drawn card at the
/// front of the finished day, unless WORDS and DRAWN name others.
final String _words = Platform.environment['WORDS'] ?? 'philosophy-socrates-8';
final String _drawn = Platform.environment['DRAWN'] ?? 'economics-slot-payback';

final String _out = Platform.environment['SHOTS'] ?? 'tool/shots/hard-pictures';

/// A picture of the bank's own, from the folder the site serves them from,
/// at the size asked (thumbs/, thumbs/large/, thumbs/shelf/), read once.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(
    rel,
    () => MemoryImage(File('web/cards/$rel').readAsBytesSync()),
  );
}

/// Waits for the pictures on screen to come, as a phone would: each as the
/// screen asks for it, decoded at the size it is shown, so the shot is
/// taken once the screen is up (the finished day's shelf comes after the
/// app has read its day) and once a card is turned.
Future<void> _pictured(WidgetTester tester) async {
  for (int round = 0; round < 3; round++) {
    await tester.runAsync(() async {
      for (final Element e in find.byType(Image).evaluate().toList()) {
        await precacheImage(
          (e.widget as Image).image,
          e,
          onError: (_, _) {},
        ).timeout(const Duration(seconds: 20), onTimeout: () {});
      }
    });
    await _settle(tester, 6);
  }
}

Future<void> _settle(WidgetTester tester, [int frames = 18]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(const ValueKey('shot')),
  );
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// Five cards for a day: [first], then four of other subjects that ask
/// something, in words.
List<Pill> _five(Pill first) {
  final List<Pill> out = [first];
  for (final Pill p in PillBank.cards) {
    if (out.length == 5) break;
    if (p.difficulty == Difficulty.hard || p.hasPage || !p.isGraded) continue;
    if (out.any((q) => q.topic == p.topic)) continue;
    out.add(p);
  }
  return out;
}

Map<String, Object> _prefs(
  List<Pill> deck, {
  required bool dark,
  required int read,
}) {
  final DateTime now = DateTime.now();
  return {
    'knowit.onboarded': true,
    'knowit.pushAsked': true,
    'knowit.theme': dark ? 'dark' : 'light',
    'knowit.streak': 6,
    'knowit.todayDate': dateKey(now),
    'knowit.todayDeckIds': [for (final p in deck) p.id],
    'knowit.todayIndex': read,
    'knowit.seenIds': [for (final p in deck) p.id],
    'knowit.savedIds': [for (final p in deck) p.id],
    if (read == deck.length) ...{
      'knowit.lastCompletionDate': dateKey(now),
      'knowit.completedDates': [dateKey(now)],
    },
  };
}

Widget _framed(Widget child) =>
    RepaintBoundary(key: const ValueKey('shot'), child: child);

Widget _page(Widget child, {required bool dark}) => _framed(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
    home: Scaffold(body: child),
  ),
);

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // The camera lives outside test/, so the analyzer does not count it
    // as one; these two are the test hooks it needs.
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.baseline = const RemoteConfig(
      hash: 'the-build-own',
      schema: kRemoteSchema,
      parts: {},
    );
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
    CardThumb.image = _picture;
  });

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  for (final bool dark in [true, false]) {
    final String paper = dark ? 'night' : 'day';

    testWidgets('Today\'s deck, a hard card in words on top, $paper', (
      tester,
    ) async {
      final Pill words = PillBank.byId(_words)!;
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(
        _prefs(_five(words), dark: dark, read: 0),
      );
      await tester.pumpWidget(_framed(const AstutoApp()));
      await _settle(tester, 30);
      expect(tester.takeException(), isNull);
      await _save(tester, 'deck-front-$paper');

      // Answered as a reader would, to its back.
      if (words.challenge case PickOne(:final options)) {
        await tester.tap(find.text(options.first).first);
        await _settle(tester);
      }
      final Finder sure = find.text('70%');
      if (sure.evaluate().isNotEmpty) {
        await tester.tap(sure.first);
        await _settle(tester, 30);
      }
      expect(tester.takeException(), isNull);
      await _save(tester, 'deck-back-$paper');
    });

    testWidgets('the finished day\'s shelf, a hard drawn card at the front, '
        '$paper', (tester) async {
      final Pill drawn = PillBank.byId(_drawn)!;
      final List<Pill> five = _five(drawn);
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(
        _prefs(five, dark: dark, read: five.length),
      );
      await tester.pumpWidget(_framed(const AstutoApp()));
      await _settle(tester, 30);
      await _pictured(tester);
      expect(tester.takeException(), isNull);
      await _save(tester, 'shelf-front-$paper');

      // Turned over, as a tap on the card at the front turns it.
      await tester.tap(find.byKey(ValueKey('shelf-face-${drawn.id}-front')));
      await _settle(tester, 20);
      await _pictured(tester);
      expect(tester.takeException(), isNull);
      await _save(tester, 'shelf-back-$paper');
    });

    testWidgets('the saved shelf and the card\'s page, $paper', (tester) async {
      final Pill drawn = PillBank.byId(_drawn)!;
      final List<Pill> kept = [
        drawn,
        ...PillBank.cards
            .where(
              (p) =>
                  p.id != drawn.id &&
                  p.hasPage &&
                  CardThumb.has(p, CardSide.back),
            )
            .where((p) => p.difficulty == Difficulty.hard)
            .take(2),
        ...PillBank.cards
            .where(
              (p) =>
                  p.hasPage &&
                  p.difficulty != Difficulty.hard &&
                  CardThumb.has(p, CardSide.back),
            )
            .take(3),
      ];
      final AppState app = await readyApp({
        'knowit.savedIds': [for (final p in kept) p.id],
        'knowit.likedIds': [for (final p in kept) p.id],
        'knowit.seenIds': [for (final p in kept) p.id],
      });
      await tester.pumpWidget(
        _page(
          SavedScreen(app: app, onBackToToday: () {}),
          dark: dark,
        ),
      );
      await _settle(tester);
      await _pictured(tester);
      expect(tester.takeException(), isNull);
      await _save(tester, 'saved-$paper');

      await tester.pumpWidget(
        _page(
          PillDetailScreen(pill: drawn, app: app),
          dark: dark,
        ),
      );
      await _settle(tester);
      await _pictured(tester);
      expect(tester.takeException(), isNull);
      await _save(tester, 'detail-$paper');
    });
  }
}
