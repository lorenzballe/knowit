// Listen: the day's five read aloud (lib/listen/). The entry on Today, the
// player's states as the queue plays, the free plan's one card and the
// paywall for the rest, what a card with nothing to hear and a server
// without a key or without credit come to, and the server's switch hiding
// all of it. No sound and no server: the queue is silent and walked by hand
// (test/listen/silent_audio.dart), and the function's answers are made up.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/listen/listen_audio.dart';
import 'package:astuto/listen/listen_session.dart';
import 'package:astuto/listen/listen_sheet.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/listen_client.dart';
import 'package:astuto/theme.dart';

import 'listen/silent_audio.dart';

int _docs = 0;

/// The server's switch `listen`, [on] or off.
void _listen({required bool on}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'listen-${_docs++}',
      'app': {
        'flags': {'listen': on},
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

/// Five plain cards, to read, none of them drawn.
final List<String> _five = PillBank.live
    .where(
      (p) => p.challenge is NoChallenge && p.scene == null && p.web == null,
    )
    .take(5)
    .map((p) => p.id)
    .toList();

/// A reader on the first card of today's five, on the free plan or Astute+.
Map<String, Object> _reading({bool plus = false}) {
  final DateTime now = DateTime.now();
  final String yesterday = dateKey(now.subtract(const Duration(days: 1)));
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.todayDate': dateKey(now),
    'knowit.todayDeckIds': _five,
    'knowit.todayIndex': 0,
    'knowit.streak': 3,
    'knowit.bestStreak': 3,
    'knowit.lastCompletionDate': yesterday,
    'knowit.completedDates': [yesterday],
    'knowit.seenIds': [..._five.take(1)],
    // Past the first card ever, so the swipe hint has had its morning.
    'knowit.pillsRead': 12,
  };
}

void main() {
  late SilentListenAudio audio;
  late List<String> asked;
  late Map<String, ListenReply> replies;
  late _Said said;

  setUp(() {
    audio = SilentListenAudio();
    ListenAudio.make = () => audio;
    asked = [];
    replies = {};
    ListenClient.resetForTest();
    ListenClient.reachable = () => true;
    ListenClient.call = (card, {required date, required tz}) async {
      asked.add(card);
      return replies[card] ??
          ListenClips(
            question: Uri.parse('https://clips.test/$card-q.mp3'),
            answer: Uri.parse('https://clips.test/$card-a.mp3'),
          );
    };
    said = _Said();
    Analytics.useForTest(said);
  });

  tearDown(() {
    Remote.reset();
    ListenClient.resetForTest();
    ListenAudio.make = JustAudioListen.new;
    Analytics.useForTest(null);
  });

  Future<void> settle(WidgetTester tester, [int frames = 10]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> openToday(WidgetTester tester, {bool plus = false}) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(_reading(plus: plus));
    await tester.pumpWidget(const AstutoApp());
    await settle(tester, 14);
  }

  Future<void> openPlayer(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('listen-entry')));
    await settle(tester);
    expect(find.byKey(const ValueKey('listen-sheet')), findsOneWidget);
  }

  Future<void> leavePaywall(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(PaywallScreen))).pop();
    await settle(tester);
  }

  bool lit(int k) =>
      find.byKey(ValueKey('listen-row-$k-lit')).evaluate().isNotEmpty;

  testWidgets('the entry is on Today while the server\'s switch is on, and '
      'nowhere while it is off or the server has no key', (tester) async {
    _listen(on: false);
    await openToday(tester);
    expect(find.byKey(const ValueKey('listen-entry')), findsNothing);

    _listen(on: true);
    await openToday(tester);
    expect(find.byKey(const ValueKey('listen-entry')), findsOneWidget);
    // Said whole to a screen reader, however short the row makes it.
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Listen to today\'s five'), findsOneWidget);
    semantics.dispose();

    ListenClient.unconfigured.value = true;
    await settle(tester);
    expect(find.byKey(const ValueKey('listen-entry')), findsNothing);
    expect(asked, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with Astute+ the five are read in turn: the question, the '
      'pause to think, the answer, then the next card', (tester) async {
    _listen(on: true);
    await openToday(tester, plus: true);
    await openPlayer(tester);

    expect(lit(0), isTrue);
    expect(find.textContaining('Question'), findsOneWidget);
    expect(find.text(PillBank.byId(_five[0])!.question), findsWidgets);
    // One card ahead of the one being read.
    expect(asked, [_five[0], _five[1]]);
    expect(find.byKey(const ValueKey('listen-free-note')), findsNothing);

    audio.finish();
    await settle(tester, 2);
    expect(find.textContaining('Think it over'), findsOneWidget);
    audio.finish();
    await settle(tester, 2);
    expect(find.textContaining('Answer'), findsOneWidget);
    audio.finish();
    audio.finish();
    await settle(tester, 2);
    expect(lit(1), isTrue);
    expect(asked, [_five[0], _five[1], _five[2]]);
    expect(said.of('listen card heard').single['pill_id'], _five[0]);
    expect(said.of('listen card heard').single['position'], 1);

    // Pause, and play on.
    await tester.tap(find.byKey(const ValueKey('listen-play')));
    await settle(tester, 2);
    expect(audio.playing, isFalse);
    await tester.tap(find.byKey(const ValueKey('listen-play')));
    await settle(tester, 2);
    expect(audio.playing, isTrue);

    // On to the next card without waiting for this one's answer.
    await tester.tap(find.byKey(const ValueKey('listen-next')));
    await settle(tester, 2);
    expect(lit(2), isTrue);

    for (int i = 0; i < 3; i++) {
      audio.finishCard();
      await settle(tester, 2);
    }
    expect(find.byKey(const ValueKey('listen-done')), findsOneWidget);
    expect(said.of('listen finished').single['heard'], 4);
    expect(said.of('listen started').single['is_plus'], true);

    // Closed after the end: nothing is said to have stopped.
    await tester.tap(find.byKey(const ValueKey('listen-close')));
    await settle(tester);
    expect(find.byKey(const ValueKey('listen-sheet')), findsNothing);
    expect(said.of('listen stopped'), isEmpty);
    expect(audio.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on the free plan the first card is free; the rest are '
      'Astute+\'s, and going on to them opens the paywall', (tester) async {
    _listen(on: true);
    await openToday(tester);
    await openPlayer(tester);

    expect(asked, [_five[0]]);
    expect(lit(0), isTrue);
    expect(find.byKey(const ValueKey('listen-free-note')), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(4));

    // Going on during the free card is the paywall.
    await tester.tap(find.byKey(const ValueKey('listen-next')));
    await settle(tester);
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      said.of('plus gate reached').map((e) => e['source']),
      contains('listen'),
    );
    await leavePaywall(tester);

    // Heard to its end, the player stops on the offer of the rest.
    audio.finishCard();
    await settle(tester);
    expect(find.byKey(const ValueKey('listen-offer')), findsOneWidget);
    expect(
      find.text('The rest of today\'s cards, read to you'),
      findsOneWidget,
    );
    expect(asked, [_five[0]]);
    expect(said.of('listen card heard').single['free'], true);

    await tester.tap(find.byKey(const ValueKey('listen-plus')));
    await settle(tester);
    expect(find.byType(PaywallScreen), findsOneWidget);
    await leavePaywall(tester);

    await tester.tap(find.byKey(const ValueKey('listen-close')));
    await settle(tester);
    final Map<String, Object> stopped = said.of('listen stopped').single;
    expect(stopped['phase'], 'offer');
    expect(stopped['heard'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card with nothing to hear is passed over, and said so', (
    tester,
  ) async {
    _listen(on: true);
    replies[_five[0]] = const ListenNone(ListenWhyNot.nothing);
    await openToday(tester);
    await openPlayer(tester);

    expect(asked, [_five[0], _five[1]]);
    expect(find.text('Science · Nothing to hear on this card'), findsNothing);
    expect(find.textContaining('Nothing to hear on this card'), findsOneWidget);
    // The free card is the first that can be heard.
    expect(lit(1), isTrue);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
  });

  testWidgets('a key with no credit behind it: listening is not available, '
      'said calmly, and nothing breaks', (tester) async {
    _listen(on: true);
    for (final String id in _five) {
      replies[id] = const ListenNone(
        ListenWhyNot.unavailable,
        detail: 'credit',
      );
    }
    await openToday(tester);
    await openPlayer(tester);

    expect(find.byKey(const ValueKey('listen-unavailable')), findsOneWidget);
    expect(
      find.text('Listening isn\'t available right now. Try again later.'),
      findsOneWidget,
    );
    expect(audio.queue, isEmpty);
    // The entry stays: a plan bought later is heard without a new build.
    expect(ListenClient.unconfigured.value, isFalse);

    // Tried again once the credit is there, it plays.
    replies.clear();
    await tester.tap(find.byKey(const ValueKey('listen-again')));
    await settle(tester);
    expect(lit(0), isTrue);

    await tester.tap(find.byKey(const ValueKey('listen-close')));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a server with no key: not available, and the entry goes for '
      'the sitting', (tester) async {
    _listen(on: true);
    replies[_five[0]] = const ListenNone(ListenWhyNot.notConfigured);
    await openToday(tester, plus: true);
    await openPlayer(tester);

    expect(find.byKey(const ValueKey('listen-unavailable')), findsOneWidget);
    expect(ListenClient.unconfigured.value, isTrue);
    await tester.tap(find.byKey(const ValueKey('listen-close')));
    await settle(tester);
    expect(find.byKey(const ValueKey('listen-entry')), findsNothing);
    expect(said.of('listen stopped').single['why'], 'not-configured');
    expect(tester.takeException(), isNull);
  });

  test('the session alone: the server is asked one card ahead on Astute+, '
      'never past the free card on the free plan', () async {
    final List<Pill> cards = [for (final id in _five) PillBank.byId(id)!];
    final SilentListenAudio quiet = SilentListenAudio();
    final List<String> calls = [];
    Future<ListenReply> call(String card, {required date, required tz}) async {
      calls.add(card);
      return ListenClips(
        question: Uri.parse('https://clips.test/q'),
        answer: Uri.parse('https://clips.test/a'),
      );
    }

    final ListenSession free = ListenSession(
      cards: cards,
      date: '2026-11-27',
      tz: 60,
      plus: false,
      audio: quiet,
      call: call,
    );
    await free.begin();
    expect(calls, [_five[0]]);
    expect(free.states.skip(1), everyElement(ListenCardState.locked));
    expect(free.nextIsLocked, isTrue);
    quiet.finishCard();
    expect(free.phase, ListenPhase.offer);
    // Astute+ taken from the offer: the rest follow.
    await free.unlock();
    await Future<void>.delayed(Duration.zero);
    // The next card, and the one after it, one ahead of the card being read.
    expect(calls, [_five[0], _five[1], _five[2]]);
    expect(free.phase, ListenPhase.question);
    expect(free.at, 1);
    await free.close();
  });

  testWidgets('the player fits in every language, on a small phone with the '
      'text set larger, reading and at the offer', (tester) async {
    tester.view.physicalSize = const Size(320, 568) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(_reading());
    final AppState app = AppState();
    await tester.runAsync(app.init);
    final List<Pill> cards = [for (final id in _five) PillBank.byId(id)!];
    for (final Locale locale in AppLocalizations.supportedLocales) {
      for (final bool plus in [true, false]) {
        final SilentListenAudio quiet = SilentListenAudio();
        final ListenSession session = ListenSession(
          cards: cards,
          date: '2026-11-27',
          tz: 60,
          plus: plus,
          audio: quiet,
          call: (card, {required date, required tz}) async => ListenClips(
            question: Uri.parse('https://clips.test/q'),
            answer: Uri.parse('https://clips.test/a'),
          ),
        );
        await session.begin();
        // On Astute+ the pause after the second question; on the free plan
        // the free card heard, and the rest offered.
        quiet.finishCard();
        if (plus) quiet.finish();
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.dark),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ListenSheet(app: app, session: session),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(ValueKey(plus ? 'listen-row-1-lit' : 'listen-offer')),
          findsOneWidget,
          reason: '$locale',
        );
        expect(tester.takeException(), isNull, reason: '$locale, plus $plus');
        await session.close();
      }
    }
  });
}
