// Books read and heard (lib/books/): a book's summary on its page, "Read in
// 15 minutes"; the reader, which keeps its place; the paywall at a locked
// part; the player's states as its queue plays, the free part and the offer
// of the rest, a server with no key or no credit; the small player over the
// app, and stopping cleanly; the switch `bookAudio` hiding the listening and
// never the reading; and all of it on a 320 by 568 phone in German at 1.6
// times the text, at night and on paper. No sound and no server: the queue is
// silent and walked by hand (test/listen/silent_audio.dart), and the
// function's answers are made up.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/books/book_player.dart';
import 'package:astuto/books/book_player_view.dart';
import 'package:astuto/books/summary_reader.dart';
import 'package:astuto/data/book_summaries.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/books_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/listen/listen_audio.dart';
import 'package:astuto/models/book_summary.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/book_audio_client.dart';
import 'package:astuto/theme.dart';

import 'explore/core_harness.dart';
import 'listen/silent_audio.dart';

/// The books whose summaries ship with the app.
const List<String> _summarised = [
  'business-adventures',
  'guns-germs-and-steel',
  'influence',
  'sapiens',
  'the-structure-of-scientific-revolutions',
];

int _docs = 0;

/// The server's switch `bookAudio`, [on] or off.
void _bookAudio({required bool on}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'book-audio-${_docs++}',
      'app': {
        'flags': {'bookAudio': on},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Iterable<Map<String, Object>> of(String event) =>
      events.where((e) => e.$1 == event).map((e) => e.$2);

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

CardBook _book(AppState app, String id) =>
    booksOf(PillBank.live, today: app.today).firstWhere((b) => b.id == id);

BookSummary _summaryOf(String id) =>
    BookSummaries.instance.inHand(PillBank.summaryOf(id)!)!;

/// A summarised book that is not this week's free one.
String _notWeekly(AppState app) {
  final String? weekly = bookOfTheWeek(PillBank.live, app.today);
  return _summarised.firstWhere((b) => b != weekly);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  late SilentListenAudio audio;
  late List<int> asked;
  late Map<int, BookAudioReply> replies;
  late _Said said;

  setUp(() {
    // A queue of its own for every sitting, as the app makes one; [audio]
    // is the latest.
    audio = SilentListenAudio();
    ListenAudio.make = () => audio = SilentListenAudio();
    asked = [];
    replies = {};
    BookAudioClient.resetForTest();
    BookAudioClient.reachable = () => true;
    BookAudioClient.call = (book, part, {required date, required tz}) async {
      asked.add(part);
      return replies[part] ??
          BookAudioClip(url: Uri.parse('https://clips.test/$book-$part.mp3'));
    };
    BookPlayerRoom.reset();
    said = _Said();
    Analytics.useForTest(said);
  });

  tearDown(() async {
    await BookPlayer.stopAll();
    Remote.reset();
    BookAudioClient.resetForTest();
    ListenAudio.make = JustAudioListen.new;
    BookPlayerRoom.reset();
    Analytics.useForTest(null);
  });

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// The app's frame around [home]: the small player's host and routes, as
  /// main.dart has them, in [locale] and [brightness].
  Widget frame(
    AppState app,
    Widget home, {
    Locale locale = const Locale('en'),
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(brightness),
    debugShowCheckedModeBanner: false,
    navigatorKey: BookPlayerRoom.navigator,
    navigatorObservers: [BookPlayerRoom.routes],
    builder: (context, child) =>
        BookPlayerHost(app: app, child: child ?? const SizedBox.shrink()),
    home: home,
  );

  Future<void> bookPage(
    WidgetTester tester,
    AppState app,
    CardBook book, {
    String? weekly,
    Size size = const Size(420, 2200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      frame(app, BookScreen(app: app, book: book, weekly: weekly)),
    );
    await settle(tester, 5);
  }

  /// A player on [book], whole or not, from its first part.
  Future<BookPlayer> play(
    AppState app,
    String book, {
    bool whole = true,
    int at = 0,
  }) async {
    final BookPlayer player = BookPlayer(
      book: _book(app, book),
      summary: _summaryOf(book),
      date: '2026-11-27',
      tz: 60,
      whole: whole,
      shelf: app.summaries,
    );
    await BookPlayer.play(player, at: at);
    return player;
  }

  test('the bank names five summaries, each built into the app, each of the '
      'book its cards name, in five to eight parts', () {
    for (final String id in _summarised) {
      final SummaryRef? ref = PillBank.summaryOf(id);
      expect(ref, isNotNull, reason: id);
      expect(ref!.minutes, 15, reason: id);
      final BookSummary s = _summaryOf(id);
      expect(s.book, id);
      expect(s.parts.length, inInclusiveRange(5, 8));
      expect(s.parts.length, ref.parts);
      expect(s.words, inInclusiveRange(2000, 2500));
      expect(s.sources.first, contains('ISBN'));
      final CardBook book = booksOf(
        PillBank.live,
        today: DateTime(2026, 11, 27),
      ).firstWhere((b) => b.id == id);
      expect(s.title, book.book.title);
      expect(s.author, book.book.author);
    }
    // The minutes left are the published minutes, scaled by the words.
    final BookSummary kuhn = _summaryOf(
      'the-structure-of-scientific-revolutions',
    );
    expect(kuhn.minutesLeft(0, 0), 15);
    expect(kuhn.minutesLeft(kuhn.parts.length - 1, 1), 0);
    expect(kuhn.progress(3, 0.5), inExclusiveRange(0.3, 0.7));
    expect(
      typeset('He said "so" and it\'s done.'),
      'He said “so” and it’s done.',
    );
  });

  testWidgets('a book\'s page: "Read in 15 minutes", the summary\'s parts and '
      'the cards under it; listening hidden while the switch is off', (
    tester,
  ) async {
    _bookAudio(on: false);
    final AppState app = await readyApp();
    final String id = _notWeekly(app);
    await bookPage(tester, app, _book(app, id));
    expect(find.byKey(const ValueKey('summary-read')), findsOneWidget);
    expect(find.text('Read in 15 minutes'), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-listen')), findsNothing);
    final int parts = _summaryOf(id).parts.length;
    for (int i = 0; i < parts; i++) {
      expect(find.byKey(ValueKey('summary-part-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('summary-free-note')), findsOneWidget);
    // Its cards, as they were: the button and every idea.
    expect(find.byKey(const ValueKey('book-go')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-idea-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the switch on: listening on the page; a server with no key '
      'hides it again, and the reading stays', (tester) async {
    _bookAudio(on: true);
    final AppState app = await readyApp();
    await bookPage(tester, app, _book(app, _notWeekly(app)));
    expect(find.byKey(const ValueKey('summary-listen')), findsOneWidget);
    expect(find.text('Listen · 15 min'), findsOneWidget);

    BookAudioClient.unconfigured.value = true;
    await settle(tester, 3);
    expect(find.byKey(const ValueKey('summary-listen')), findsNothing);
    expect(find.byKey(const ValueKey('summary-read')), findsOneWidget);

    // And where Firebase is not up to ask (the web preview, a test), none.
    BookAudioClient.unconfigured.value = false;
    BookAudioClient.reachable = () => false;
    await bookPage(tester, app, _book(app, _notWeekly(app)));
    expect(find.byKey(const ValueKey('summary-listen')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the reader keeps its place: the part, how far down, the parts '
      'read; the next opening goes straight back there', (tester) async {
    final AppState app = await readyApp({'knowit.plus': true});
    const String id = 'sapiens';
    final CardBook book = _book(app, id);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      frame(app, BookScreen(app: app, book: book, weekly: null)),
    );
    await settle(tester, 4);
    await tester.tap(find.byKey(const ValueKey('summary-read')));
    await settle(tester);
    expect(find.byKey(const ValueKey('summary-reader')), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-page-0')), findsOneWidget);
    expect(said.of('summary opened').single['resumed'], false);

    // Down to the foot of the first part, and on to the next twice.
    for (int part = 0; part < 2; part++) {
      final Finder next = find.byKey(const ValueKey('summary-next'));
      await tester.scrollUntilVisible(
        next,
        400,
        scrollable: find.descendant(
          of: find.byKey(ValueKey('summary-page-$part')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(next);
      await settle(tester);
    }
    expect(find.byKey(const ValueKey('summary-page-2')), findsOneWidget);
    // A little way down the third.
    await tester.drag(
      find.byKey(const ValueKey('summary-page-2')),
      const Offset(0, -300),
    );
    await settle(tester);
    final SummaryPlace place = app.summaries.placeOf(id)!;
    expect(place.part, 2);
    expect(place.through, greaterThan(0));
    expect(place.read, containsAll(<int>[0, 1]));
    expect([for (final e in said.of('summary part read')) e['part']], [1, 2]);

    // Closed, and opened again: straight back to the third part.
    Navigator.of(tester.element(find.byType(SummaryReaderScreen))).pop();
    await settle(tester);
    expect(find.text('Continue reading'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('summary-read')));
    await settle(tester);
    expect(find.byKey(const ValueKey('summary-page-2')), findsOneWidget);
    expect(said.of('summary opened').last['resumed'], true);
    expect(said.of('summary opened').last['part'], 3);

    // Kept on the phone: a new start reads the same place.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SummaryShelf later = SummaryShelf()..restore(prefs);
    expect(later.placeOf(id)!.part, 2);
    expect(later.placeOf(id)!.read, containsAll(<int>[0, 1]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a locked part on the free plan: its title, a few faded lines '
      'and the offer; the plans open with the source "book summary"', (
    tester,
  ) async {
    final AppState app = await readyApp();
    final String id = _notWeekly(app);
    final CardBook book = _book(app, id);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      frame(app, BookScreen(app: app, book: book, weekly: null)),
    );
    await settle(tester, 4);
    await tester.tap(find.byKey(const ValueKey('summary-read')));
    await settle(tester);
    final Finder next = find.byKey(const ValueKey('summary-next'));
    await tester.scrollUntilVisible(
      next,
      400,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('summary-page-0')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(next);
    await settle(tester);
    expect(find.byKey(const ValueKey('summary-gate-1')), findsOneWidget);
    expect(find.text(_summaryOf(id).parts[1].title), findsWidgets);
    await tester.ensureVisible(find.byKey(const ValueKey('summary-plus')));
    await tester.tap(find.byKey(const ValueKey('summary-plus')));
    await settle(tester);
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      tester.widget<PaywallScreen>(find.byType(PaywallScreen)).source,
      'book summary',
    );
    expect(said.of('plus gate reached').single['source'], 'book summary');
    // A locked part never counts as read.
    expect(app.summaries.placeOf(id)!.read.contains(1), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the week\'s free book reads whole on the free plan: no lock, '
      'no offer', (tester) async {
    final AppState app = await readyApp();
    const String id = 'influence';
    await bookPage(tester, app, _book(app, id), weekly: id);
    expect(find.byKey(const ValueKey('summary-free-note')), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the player reads a part a clip, one ahead of the voice: back '
      'fifteen seconds, the part lit, on to the end', (tester) async {
    final AppState app = await readyApp({'knowit.plus': true});
    const String id = 'influence';
    final BookPlayer player = await play(app, id);
    await tester.pump();
    final int n = _summaryOf(id).parts.length;
    expect(player.phase, BookPlayerPhase.playing);
    expect(player.at, 0);
    expect(asked, [0, 1]);
    expect(audio.queue.length, 4);
    expect(said.of('book audio played').single['part'], 1);

    // Back fifteen seconds from twenty in.
    await audio.seek(const Duration(seconds: 20));
    await player.back();
    expect(audio.position, const Duration(seconds: 5));
    await player.back();
    expect(audio.position, Duration.zero);

    // The first part read, its breath, and the second begins: the third is
    // asked for.
    audio.finish();
    expect(player.states[0], BookPartState.heard);
    audio.finish();
    await tester.pump();
    expect(player.at, 1);
    expect(asked, [0, 1, 2]);
    expect(app.summaries.placeOf(id)!.part, 1);
    expect(app.summaries.placeOf(id)!.read, contains(0));

    // Pause and play.
    await player.toggle();
    expect(audio.playing, isFalse);
    await player.toggle();
    expect(audio.playing, isTrue);

    // Straight to the last part, and through it.
    await player.jumpTo(n - 1);
    await tester.pump();
    expect(player.at, n - 1);
    audio.finish();
    audio.finish();
    await tester.pump();
    expect(player.phase, BookPlayerPhase.done);
    expect(said.of('book audio finished').single['of'], n);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on the free plan the first part, then the offer of the rest; '
      'Astute+ taken there plays on', (tester) async {
    final AppState app = await readyApp();
    final BookPlayer player = await play(app, 'sapiens', whole: false);
    await tester.pump();
    expect(asked, [0]);
    expect(player.states[1], BookPartState.locked);
    expect(player.nextIsLocked, isTrue);
    audio.finish();
    audio.finish();
    await tester.pump();
    expect(player.phase, BookPlayerPhase.offer);
    expect(audio.playing, isFalse);

    await player.unlock();
    await tester.pump();
    expect(player.whole, isTrue);
    expect(player.at, 1);
    expect(player.phase, BookPlayerPhase.playing);
    expect(asked, [0, 1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the server says "Astute+ only" for a part: the offer, never a '
      'crash', (tester) async {
    final AppState app = await readyApp();
    replies[1] = const BookAudioNone(BookAudioWhyNot.plus);
    final BookPlayer player = await play(app, 'sapiens');
    await tester.pump();
    audio.finish();
    audio.finish();
    await tester.pump();
    expect(player.phase, BookPlayerPhase.offer);
    expect(player.whole, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no key: listening says so and hides itself; no credit: '
      'calmly unavailable, and trying again asks again', (tester) async {
    final AppState app = await readyApp({'knowit.plus': true});
    replies[0] = const BookAudioNone(BookAudioWhyNot.notConfigured);
    final BookPlayer none = await play(app, 'sapiens');
    expect(none.phase, BookPlayerPhase.unavailable);
    expect(BookAudioClient.unconfigured.value, isTrue);
    expect(bookAudioOffered(app), isFalse);
    await none.stop();

    BookAudioClient.unconfigured.value = false;
    asked.clear();
    replies[0] = const BookAudioNone(
      BookAudioWhyNot.unavailable,
      detail: 'credit',
    );
    final BookPlayer poor = await play(app, 'sapiens');
    expect(poor.phase, BookPlayerPhase.unavailable);
    expect(poor.whyUnavailable, 'credit');
    expect(BookAudioClient.unconfigured.value, isFalse);
    replies.remove(0);
    await poor.toggle();
    await tester.pump();
    expect(poor.phase, BookPlayerPhase.playing);
    expect(asked.where((p) => p == 0).length, 2);

    // The sheet says it calmly, with the way to try again.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    replies[0] = const BookAudioNone(BookAudioWhyNot.unavailable);
    final BookPlayer again = await play(app, 'influence');
    await tester.pumpWidget(
      frame(
        app,
        Scaffold(
          body: BookPlayerSheet(app: app, player: again),
        ),
      ),
    );
    await settle(tester, 3);
    expect(
      find.byKey(const ValueKey('book-player-unavailable')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a page under the host makes room for the small player as a '
      'book starts, and gives it back when it stops', (tester) async {
    final AppState app = await readyApp({'knowit.plus': true});
    final List<double> rooms = [];
    await tester.pumpWidget(
      frame(
        app,
        Scaffold(
          body: Builder(
            builder: (context) {
              rooms.add(bookPlayerRoom(context));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(rooms.last, 0);
    final BookPlayer player = await play(app, 'sapiens');
    await settle(tester, 3);
    expect(rooms.last, MiniBookPlayer.height + 18);
    await player.stop();
    await settle(tester, 3);
    expect(rooms.last, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Listen, on the page of a book its player cannot play: the '
      'player opens and says so; nothing is asked behind the reader\'s back', (
    tester,
  ) async {
    _bookAudio(on: true);
    final AppState app = await readyApp({'knowit.plus': true});
    replies[0] = const BookAudioNone(BookAudioWhyNot.unavailable);
    final BookPlayer poor = await play(app, 'sapiens');
    expect(poor.phase, BookPlayerPhase.unavailable);
    await bookPage(tester, app, _book(app, 'sapiens'));
    // Not "Resume": there is nothing under way to resume.
    expect(find.text('Listen · 15 min'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('summary-listen')));
    await settle(tester, 8);
    expect(find.byKey(const ValueKey('book-player')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('book-player-unavailable')),
      findsOneWidget,
    );
    expect(asked, [0]);
    expect(poor.phase, BookPlayerPhase.unavailable);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the small player stays over the app while a book plays, steps '
      'aside for cards and sheets, and stops cleanly', (tester) async {
    final AppState app = await readyApp({'knowit.plus': true});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      frame(app, const Scaffold(body: Center(child: Text('Explore')))),
    );
    await settle(tester, 3);
    expect(find.byKey(const ValueKey('book-mini-player')), findsNothing);

    final BookPlayer player = await play(app, 'sapiens');
    await settle(tester, 4);
    expect(find.byKey(const ValueKey('book-mini-player')), findsOneWidget);
    expect(find.text('Sapiens'), findsWidgets);

    // Another page: still there.
    BookPlayerRoom.navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('A page'))),
      ),
    );
    await settle(tester, 8);
    expect(find.text('A page'), findsOneWidget);
    bool shown() =>
        tester
            .widget<IgnorePointer>(
              find
                  .ancestor(
                    of: find.byKey(const ValueKey('book-mini-player')),
                    matching: find.byType(IgnorePointer),
                  )
                  .first,
            )
            .ignoring ==
        false;
    expect(shown(), isTrue);

    // Cards on the screen: out of their way.
    BookPlayerRoom.cardsOpened();
    await settle(tester, 4);
    expect(shown(), isFalse);
    BookPlayerRoom.cardsClosed();
    await settle(tester, 4);
    expect(shown(), isTrue);

    // A tap opens the whole player, and the small one steps aside under it.
    await tester.tap(find.byKey(const ValueKey('book-mini-open')));
    await settle(tester, 8);
    expect(find.byKey(const ValueKey('book-player')), findsOneWidget);
    expect(shown(), isFalse);
    Navigator.of(tester.element(find.byKey(const ValueKey('book-player'))))
        .pop();
    await settle(tester, 8);
    expect(shown(), isTrue);

    // Pause from the small player, then stop: it goes, and the sound with it.
    await tester.tap(find.byKey(const ValueKey('book-mini-play')));
    await settle(tester, 2);
    expect(audio.playing, isFalse);
    await tester.tap(find.byKey(const ValueKey('book-mini-stop')));
    await settle(tester, 4);
    expect(find.byKey(const ValueKey('book-mini-player')), findsNothing);
    expect(BookPlayer.current.value, isNull);
    expect(player.closed, isTrue);
    expect(audio.disposed, isTrue);
    expect(said.of('book audio stopped').single['book'], 'sapiens');
    expect(tester.takeException(), isNull);
  });

  for (final Brightness brightness in Brightness.values) {
    final String look = brightness == Brightness.dark ? 'night' : 'paper';
    testWidgets('a 320 by 568 phone in German at 1.6 times the text, $look: '
        'the book\'s page, the reader, its locked part, the player and the '
        'small player hold', (tester) async {
      _bookAudio(on: true);
      tester.view.physicalSize = const Size(320, 568) * 2;
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final AppState app = await readyApp();
      final String id = _notWeekly(app);
      final CardBook book = _book(app, id);
      final BookPlayer player = await play(app, id, whole: false);
      await tester.pump();

      Future<void> show(Widget home) async {
        await tester.pumpWidget(
          frame(app, home, locale: const Locale('de'), brightness: brightness),
        );
        await settle(tester, 5);
        expect(tester.takeException(), isNull);
      }

      // The book's page, the part being read lit, scrolled through.
      await show(BookScreen(app: app, book: book, weekly: null));
      final Finder page = find.byType(Scrollable).first;
      bool sawRead = false, sawParts = false;
      for (int i = 0; i < 12; i++) {
        await tester.drag(page, const Offset(0, -300));
        await settle(tester, 2);
        expect(tester.takeException(), isNull);
        sawRead |= find
            .byKey(const ValueKey('summary-read'))
            .evaluate()
            .isNotEmpty;
        sawParts |= find
            .byKey(const ValueKey('summary-part-0'))
            .evaluate()
            .isNotEmpty;
      }
      expect(sawRead, isTrue);
      expect(sawParts, isTrue);

      // The reader, at its first part and at a locked one.
      await show(
        SummaryReaderScreen(
          app: app,
          book: book,
          summaryRef: PillBank.summaryOf(id)!,
          at: 0,
        ),
      );
      expect(find.byKey(const ValueKey('summary-page-0')), findsOneWidget);
      await show(
        SummaryReaderScreen(
          key: const ValueKey('reader-at-1'),
          app: app,
          book: book,
          summaryRef: PillBank.summaryOf(id)!,
          at: 1,
        ),
      );
      expect(find.byKey(const ValueKey('summary-gate-1')), findsOneWidget);

      // The player, as a sheet over a page, and on the offer of the rest.
      await show(
        Scaffold(
          body: BookPlayerSheet(app: app, player: player),
        ),
      );
      expect(find.byKey(const ValueKey('book-part-0-lit')), findsOneWidget);
      audio.finish();
      audio.finish();
      await settle(tester, 3);
      expect(find.byKey(const ValueKey('book-player-offer')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The small player, over a page.
      await show(const Scaffold(body: SizedBox.expand()));
      expect(find.byKey(const ValueKey('book-mini-player')), findsOneWidget);
    });
  }
}
