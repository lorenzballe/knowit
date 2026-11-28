// Photographs books read and heard (lib/books/), for the owner, with the
// server's switch on (`bookAudio`): a book's page with "Leggi in 15 minuti"
// and "Ascolta"; the reader at a part; the player while it reads; the small
// player over Explore; and the Astute+ moment at a locked part. In Italian,
// at night (PAPER=1 on paper), on a 390 by 844 phone. No sound and no
// server: the queue is silent and the clips made up.
//
//   SHOTS=/some/folder flutter test tool/book_audio_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/books/book_player.dart';
import 'package:astuto/books/book_player_view.dart';
import 'package:astuto/books/summary_reader.dart';
import 'package:astuto/data/book_summaries.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/listen/listen_audio.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/book_summary.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/book_audio_client.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';
import '../test/listen/silent_audio.dart';

/// The server's switch, on.
void _bookAudioOn() => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'book-audio-shots',
      'app': {
        'flags': {'bookAudio': true},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// A picture of the bank's own, from the folder the site serves it from.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture on screen, decoded before the photograph, in real time.
Future<void> _decodeShown(WidgetTester tester) async {
  final Set<ImageProvider> shown = {
    for (final Image image in tester.widgetList<Image>(find.byType(Image)))
      image.image,
  };
  if (shown.isEmpty) return;
  final BuildContext context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final ImageProvider p in shown) {
      await precacheImage(
        p,
        context,
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 10), onTimeout: () {});
    }
  });
  await _settle(tester, 5);
}

void _phone(WidgetTester tester) {
  const double ratio = 3;
  tester.view.physicalSize = const Size(390, 844) * ratio;
  tester.view.devicePixelRatio = ratio;
  const FakeViewPadding padding = FakeViewPadding(
    top: 47 * ratio,
    bottom: 34 * ratio,
  );
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
}

void main() {
  late SilentListenAudio audio;
  final String out = Platform.environment['SHOTS'] ?? 'tool/shots/books';
  final bool paper = Platform.environment['PAPER'] == '1';
  const Locale locale = Locale('it');
  const String weekly = 'the-structure-of-scientific-revolutions';

  setUpAll(() async {
    await loadFonts();
    CardThumb.image = _picture;
  });

  setUp(() {
    _bookAudioOn();
    audio = SilentListenAudio();
    ListenAudio.make = () => audio;
    // ignore: invalid_use_of_visible_for_testing_member
    BookAudioClient.resetForTest();
    BookAudioClient.reachable = () => true;
    BookAudioClient.call = (book, part, {required date, required tz}) async =>
        BookAudioClip(url: Uri.parse('https://clips.test/$book-$part.mp3'));
    // ignore: invalid_use_of_visible_for_testing_member
    BookPlayerRoom.reset();
  });

  tearDown(() async {
    await BookPlayer.stopAll();
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
    // ignore: invalid_use_of_visible_for_testing_member
    BookAudioClient.resetForTest();
    ListenAudio.make = JustAudioListen.new;
    // ignore: invalid_use_of_visible_for_testing_member
    BookPlayerRoom.reset();
    debugDefaultTargetPlatformOverride = null;
  });

  Widget frame(AppState app, Widget home) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(paper ? Brightness.light : Brightness.dark),
    debugShowCheckedModeBanner: false,
    navigatorKey: BookPlayerRoom.navigator,
    navigatorObservers: [BookPlayerRoom.routes],
    builder: (context, child) =>
        BookPlayerHost(app: app, child: child ?? const SizedBox.shrink()),
    home: home,
  );

  CardBook bookOf(AppState app, String id) =>
      booksOf(PillBank.live, today: app.today).firstWhere((b) => b.id == id);

  Future<void> take(WidgetTester tester, String name) async {
    await _decodeShown(tester);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$out/$name.png'),
    );
  }

  testWidgets('the book\'s page, with Leggi in 15 minuti', (tester) async {
    _phone(tester);
    final AppState app = await readyApp();
    final BookSummary kuhn = BookSummaries.instance.inHand(
      PillBank.summaryOf(weekly)!,
    )!;
    await tester.pumpWidget(
      frame(
        app,
        BookScreen(app: app, book: bookOf(app, weekly), weekly: weekly),
      ),
    );
    await _settle(tester);
    expect(kuhn.parts.length, greaterThan(4));
    await take(tester, '1-pagina');
  });

  testWidgets('the reader, at a part', (tester) async {
    _phone(tester);
    final AppState app = await readyApp();
    await tester.pumpWidget(
      frame(
        app,
        SummaryReaderScreen(
          app: app,
          book: bookOf(app, weekly),
          summaryRef: PillBank.summaryOf(weekly)!,
          weekly: weekly,
          at: 3,
        ),
      ),
    );
    await _settle(tester);
    await take(tester, '2-lettore');
  });

  testWidgets('the player while it reads', (tester) async {
    _phone(tester);
    final AppState app = await readyApp();
    final CardBook book = bookOf(app, weekly);
    await tester.pumpWidget(
      frame(app, BookScreen(app: app, book: book, weekly: weekly)),
    );
    await _settle(tester);
    final BookPlayer player = BookPlayer(
      book: book,
      summary: BookSummaries.instance.inHand(PillBank.summaryOf(weekly)!)!,
      date: dateKey(app.today),
      tz: 60,
      whole: true,
      shelf: app.summaries,
    );
    await BookPlayer.play(player);
    // Two parts heard, the third under way.
    for (int i = 0; i < 4; i++) {
      await tester.pump();
      audio.finish();
    }
    await tester.pump();
    audio.duration = const Duration(minutes: 3, seconds: 12);
    audio.position = const Duration(minutes: 1, seconds: 24);
    audio.play();
    await _settle(tester, 4);
    showBookPlayer(tester.element(find.byType(BookScreen)), app, player);
    await _settle(tester, 14);
    await take(tester, '3-player');
  });

  testWidgets('the small player over Explore', (tester) async {
    _phone(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.pushAsked': true,
      'knowit.widgetAsked': true,
      'knowit.accountOffered': true,
      'knowit.reviewAsked': true,
      'knowit.goalAsked': true,
      'knowit.placeAsks': 9,
      if (paper) 'knowit.theme': 'light',
    });
    await tester.pumpWidget(const AstutoApp());
    _bookAudioOn();
    await _settle(tester, 20);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 20);
    final CardBook book = booksOf(
      PillBank.live,
      today: DateTime.now(),
    ).firstWhere((b) => b.id == 'sapiens');
    final BookPlayer player = BookPlayer(
      book: book,
      summary: BookSummaries.instance.inHand(PillBank.summaryOf('sapiens')!)!,
      date: dateKey(DateTime.now()),
      tz: 60,
      whole: true,
    );
    await BookPlayer.play(player, at: 1);
    audio.duration = const Duration(minutes: 3, seconds: 30);
    audio.position = const Duration(minutes: 2, seconds: 5);
    audio.play();
    await _settle(tester, 10);
    expect(find.byKey(const ValueKey('book-mini-player')), findsOneWidget);
    await take(tester, '4-mini');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the Astute+ moment, at a locked part', (tester) async {
    _phone(tester);
    final AppState app = await readyApp();
    const String id = 'sapiens';
    await tester.pumpWidget(
      frame(
        app,
        SummaryReaderScreen(
          app: app,
          book: bookOf(app, id),
          summaryRef: PillBank.summaryOf(id)!,
          weekly: weekly,
          at: 1,
        ),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('summary-gate')), findsOneWidget);
    await take(tester, '5-astute-plus');
  });
}
