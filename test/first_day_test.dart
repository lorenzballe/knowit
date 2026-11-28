// The end of a reader's first day, celebrated (lib/widgets/first_day.dart):
// a screen of its own right after the fifth card, on the first finished day
// and never again; its numbers — the streak, the points the day earned, how
// sure against how right, with and without the cards' how-sure question;
// "Remind me tomorrow", which asks the reminder down the shell's own road,
// once, the shell asking nothing more that evening; Today's challenge, on
// Explore; the card after
// the fifth after it, never before, and none on Astute+; a level reached
// waiting for another evening; a friend's week after it, never over it; the
// developer tools' look that puts the end back as it was; and the screen
// whole on the smallest phone at a large text size, at night and on paper.
//
//   flutter test test/first_day_test.dart
import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/levels.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/explore/blocks/core/your_day_block.dart'
    show kStreakOrange;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/sync/invite.dart';
import 'package:astuto/sync/push.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/first_day.dart';
import 'package:astuto/widgets/level_up.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/skill_score.dart' show scoreBookOf;

import 'explore/core_harness.dart' show loadFonts, readyApp;

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));
final AppLocalizations _it = lookupAppLocalizations(const Locale('it'));

/// The system's notification prompt, there to be put, counted, and
/// answered yes.
class _Asker extends Push {
  int asked = 0;

  @override
  bool get canAsk => true;

  @override
  Future<String?> ask() async {
    asked++;
    return 'token-a';
  }

  @override
  Future<String?> refresh() async => null;
}

/// What the app said, kept.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  List<Map<String, Object>> of(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

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

/// The server, as invite.ts answers for a friend whose code waits on the
/// first day: the week given once the day is read.
class _InviteServer implements InviteServer {
  String redeemState = 'waiting';
  DateTime? until;
  bool givenNow = false;

  @override
  Future<Object?> state({required bool make}) async {
    final bool given = givenNow;
    givenNow = false;
    return {
      'code': null,
      'weeks': 0,
      'cap': 8,
      'friends': 0,
      'redeem': redeemState,
      'until': ?until?.millisecondsSinceEpoch,
      if (given) 'granted': true,
    };
  }

  @override
  Future<Object?> redeem(String code) async => {'state': 'waiting'};
}

int _docs = 0;

/// The server's document: the reminder sheet's experiment on the first
/// evening, as the server has it now (remote/app.json), and [flags].
void _serverSays({
  bool firstDayAsk = true,
  Map<String, Object?> flags = const {},
}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'first-day-${_docs++}',
      'app': {
        'flags': flags,
        'experiments': {
          if (firstDayAsk)
            'push.firstAsk': {
              'variants': ['firstDay'],
            },
        },
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

String _day(int back) {
  final DateTime now = DateTime.now();
  return dateKey(DateTime(now.year, now.month, now.day - back));
}

/// An install past the first run, on the free plan, with nothing finished.
Map<String, Object> _installed({bool plus = false}) => {
  'knowit.onboarded': true,
  'knowit.plus': plus,
};

/// A reader back for a second day: yesterday's five were read.
Map<String, Object> _readYesterday() => {
  'knowit.streak': 1,
  'knowit.bestStreak': 1,
  'knowit.lastCompletionDate': _day(1),
  'knowit.completedDates': [_day(1)],
};

/// Today's five, as the day deals them, dealt.
Map<String, Object> _five() => {
  'knowit.todayDate': _day(0),
  'knowit.todayDeckIds': dealDay(date: DateTime.now()).cards
      .take(kPillsPerDay)
      .map((p) => p.id)
      .toList(),
};

/// Judgements as kept, today: on each of [cards], right as [right] says,
/// said [sure] sure where given.
String _said(List<Pill> cards, List<bool> right, {List<int?>? sure}) =>
    jsonEncode([
      for (var i = 0; i < cards.length; i++)
        {
          'c': sure?[i],
          'k': right[i],
          'p': cards[i].id,
          'd': _day(0),
        },
    ]);

/// Graded cards of the bank, [n] of them, of [difficulty] when given, none
/// of them in today's five.
List<Pill> _graded(int n, {Difficulty? difficulty}) {
  final Set<String> today = {
    for (final Pill p in dealDay(date: DateTime.now()).cards) p.id,
  };
  return PillBank.cards
      .where((p) => p.isGraded && !today.contains(p.id))
      .where((p) => difficulty == null || p.difficulty == difficulty)
      .take(n)
      .toList();
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Long enough for a sheet's beat and its rise, frame by frame.
Future<void> _wait(WidgetTester tester, {int seconds = 3}) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _settle(tester);
}

/// Throws the card on top of the deck, from its question.
Future<void> _throw(WidgetTester tester) async {
  final Rect deck = tester.getRect(find.byType(PillCardStack));
  await tester.flingFrom(
    Offset(deck.center.dx, deck.top + 90),
    const Offset(-320, 0),
    900,
  );
  await _settle(tester);
}

/// The day's five, thrown one after another.
Future<void> _readFive(WidgetTester tester) async {
  for (var i = 0; i < kPillsPerDay; i++) {
    await _throw(tester);
  }
}

/// The home-screen widgets' channel, answered as a phone with none placed.
void _noWidgets(WidgetTester tester) {
  const channel = MethodChannel('astut/widget');
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    channel,
    (call) async => call.method == 'installed' ? const <Object?>[] : null,
  );
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

/// The app's state, read off the tabs, which may be under a pushed screen.
AppState _appOf(WidgetTester tester) => tester
    .widget<AstutoShell>(find.byType(AstutoShell, skipOffstage: false))
    .app;

final Finder _celebration = find.byType(FirstDayScreen);
final Finder _sheet = find.byKey(const ValueKey('reminder-ask'));
final Finder _offer = find.byKey(const ValueKey('magic-card'));
final Finder _remind = find.byKey(const ValueKey('first-day-remind'));
final Finder _challenge = find.byKey(const ValueKey('first-day-challenge'));
final Finder _close = find.byKey(const ValueKey('first-day-close'));

/// Explore's own list, the one that scrolls down the page.
ScrollPosition _exploreList(WidgetTester tester) => tester
    .stateList<ScrollableState>(
      find.descendant(
        of: find.byType(ExploreScreen),
        matching: find.byType(Scrollable),
      ),
    )
    .firstWhere((s) => s.position.axis == Axis.vertical)
    .position;

/// [child] in the app's own theme and language, as the screen is drawn.
Widget _host(Widget child, {String language = 'en', bool dark = true}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
      debugShowCheckedModeBanner: false,
      home: child,
    );

/// The screen's own words, as drawn.
String _textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  setUpAll(loadFonts);

  late _Asker asker;
  late _Said said;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    Remote.reset();
    asker = _Asker();
    Push.useForTest(asker);
    said = _Said();
    Analytics.useForTest(said);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
    Push.useForTest(Push());
    Analytics.useForTest(null);
    Remote.reset();
    DebugLooks.reset();
  });

  group('when', () {
    test('the first day finished, never one with a day finished before it, '
        'never twice, and not as before', () async {
      final AppState first = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(0)],
      });
      expect(firstDayDue(first), isTrue);

      // The frame before the day's close is written down is the first day
      // all the same.
      final AppState closing = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
      });
      expect(firstDayDue(closing), isTrue);

      final AppState second = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(1), _day(0)],
      });
      expect(firstDayDue(second), isFalse);

      // A day finished weeks ago, with days missed since, is a day before.
      final AppState back = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(20), _day(0)],
      });
      expect(firstDayDue(back), isFalse);

      // Not while the five are being read.
      final AppState reading = await readyApp({
        ..._five(),
        'knowit.todayIndex': 3,
      });
      expect(firstDayDue(reading), isFalse);

      await first.notedFirstDayCelebrated();
      expect(first.celebratedToday, isTrue);
      expect(firstDayDue(first), isFalse, reason: 'once');

      // As before, from the developer tools.
      final AppState again = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
      });
      final bool tools = debugToolsOn;
      addTearDown(() => debugToolsOn = tools);
      debugToolsOn = true;
      DebugLooks.firstDayEnd.value = FirstDayEndLook.asBefore;
      expect(firstDayDue(again), isFalse);
      DebugLooks.firstDayEnd.value = FirstDayEndLook.celebration;
      expect(firstDayDue(again), isTrue);
      // A look kept on a phone is never read by a build without the tools.
      DebugLooks.firstDayEnd.value = FirstDayEndLook.asBefore;
      debugToolsOn = false;
      expect(firstDayDue(again), isTrue);
    });

    testWidgets('it rises right after the fifth card of the first day, over '
        'the card that offers Astute+, which comes after it', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      for (var i = 0; i < kPillsPerDay - 1; i++) {
        await _throw(tester);
      }
      expect(_celebration, findsNothing, reason: 'not during the five');
      await _throw(tester);
      await _settle(tester);

      expect(_celebration, findsOneWidget);
      expect(_appOf(tester).dayClosed, isTrue);
      expect(_appOf(tester).firstDayCelebratedOn, _day(0));
      // The offer is on the table under it, unseen until it goes.
      expect(_offer, findsNothing);
      expect(find.byKey(const ValueKey('magic-card'), skipOffstage: false),
          findsOneWidget);
      expect(find.text(_en.firstDayTitle), findsOneWidget);
      expect(said.of('first day shown'), hasLength(1));

      await tester.tap(_close);
      await _settle(tester);
      expect(_celebration, findsNothing);
      expect(_offer, findsOneWidget, reason: 'the offer comes next');
      expect(said.of('first day closed').single['left_by'], 'close');

      // Thrown, the shelf; and nothing rises again.
      await _throw(tester);
      expect(find.byType(PillCardStack), findsNothing);
      await _wait(tester, seconds: 4);
      expect(_celebration, findsNothing);
      expect(said.of('first day shown'), hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('never on day two', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._readYesterday(),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _readFive(tester);
      await _wait(tester);
      expect(_celebration, findsNothing);
      expect(_offer, findsOneWidget, reason: 'the offer at once, as ever');
      expect(said.of('first day shown'), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('never on opening the app onto a first day already finished', (
      tester,
    ) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        'knowit.todayDate': _day(0),
        'knowit.todayDeckIds': dealDay(date: DateTime.now()).cards
            .map((p) => p.id)
            .toList(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.streak': 1,
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(0)],
      });
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(_celebration, findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('on Astute+, no offer after it: the shelf', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_installed(plus: true));
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _readFive(tester);
      expect(_celebration, findsOneWidget);
      expect(
        find.byKey(const ValueKey('magic-card'), skipOffstage: false),
        findsNothing,
      );
      expect(said.of('first day shown').single['is_plus'], isTrue);
      await tester.tap(_close);
      await _settle(tester);
      expect(_celebration, findsNothing);
      expect(_offer, findsNothing);
      expect(find.byType(PillCardStack), findsNothing, reason: 'the shelf');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the developer tools\' look as before: the offer at once, the '
        'reminder sheet over the shelf as it was', (tester) async {
      final bool tools = debugToolsOn;
      addTearDown(() => debugToolsOn = tools);
      debugToolsOn = true;
      _noWidgets(tester);
      _serverSays();
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        'knowit.debug.firstDayEnd': 'asBefore',
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      expect(DebugLooks.firstDayEnd.value, FirstDayEndLook.asBefore);
      await _readFive(tester);
      await _settle(tester);
      expect(_celebration, findsNothing);
      expect(_offer, findsOneWidget);
      expect(_appOf(tester).firstDayCelebratedOn, isNull);
      await _throw(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget, reason: 'the shell asks, as before');
      expect(said.of('push preprompt shown').single['reason'], 'day done');
      expect(said.of('push preprompt shown').single.containsKey('from'),
          isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the reminder', () {
    testWidgets('asked once, from the celebration, down the shell\'s road; the '
        'shell asks nothing more that evening', (tester) async {
      _noWidgets(tester);
      _serverSays();
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _readFive(tester);
      expect(_celebration, findsOneWidget);
      expect(said.of('first day shown').single['remind'], isTrue);
      // Nothing asked of the reader until they ask for it.
      await _wait(tester);
      expect(_sheet, findsNothing);
      expect(said.of('push preprompt shown'), isEmpty);

      expect(find.text(_en.firstDayRemind), findsOneWidget);
      await tester.tap(_remind);
      await _settle(tester);
      expect(_sheet, findsOneWidget, reason: 'over the celebration');
      expect(_celebration, findsOneWidget);
      expect(said.of('first day reminder tapped'), hasLength(1));
      final Map<String, Object> shown = said.of('push preprompt shown').single;
      expect(shown['reason'], 'day done');
      expect(shown['from'], 'celebration');

      await tester.tap(find.byKey(const ValueKey('reminder-at-19:00')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('reminder-yes')));
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(asker.asked, 1);
      expect(said.of('push preprompt answered'), [
        {'choice': '19:00'},
      ]);
      expect(said.of('push permission answered'), [
        {'granted': true},
      ]);
      // In the button's place, when it will come; the challenge stays.
      expect(_remind, findsNothing);
      expect(
        find.text(_en.firstDayReminded('7:00 PM')),
        findsOneWidget,
      );
      expect(_challenge, findsOneWidget);

      await tester.tap(_close);
      await _settle(tester);
      expect(said.of('first day closed').single, {
        'left_by': 'close',
        'ms_open': isA<int>(),
        'reminder': 'set',
      });
      await _throw(tester);
      await _wait(tester, seconds: 5);
      expect(_sheet, findsNothing);
      expect(asker.asked, 1);
      expect(said.of('push preprompt shown'), hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Not now" there spends nothing, and the shell does not ask '
        'again that evening', (tester) async {
      _noWidgets(tester);
      _serverSays();
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _readFive(tester);
      await tester.tap(_remind);
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('reminder-not-now')));
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(asker.asked, 0);
      expect(_appOf(tester).pushDeferrals, 1);
      // Asked: the button goes, and nothing stands in its place.
      expect(_remind, findsNothing);
      expect(find.byKey(const ValueKey('first-day-reminded')), findsNothing);
      await tester.tap(_close);
      await _settle(tester);
      expect(said.of('first day closed').single['reminder'], 'not set');
      await _throw(tester);
      await _wait(tester, seconds: 5);
      expect(_sheet, findsNothing);
      expect(said.of('push preprompt shown'), hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('passed over, it is not asked by the shell that evening '
        'either: it waits for a day finished later', (tester) async {
      _noWidgets(tester);
      _serverSays();
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _readFive(tester);
      expect(_remind, findsOneWidget);
      await tester.tap(_close);
      await _settle(tester);
      await _throw(tester);
      await _wait(tester, seconds: 5);
      expect(_sheet, findsNothing);
      expect(said.of('push preprompt shown'), isEmpty);
      expect(asker.asked, 0);
      final AppState app = _appOf(tester);
      // Nothing spent: the sheet is still due, on another evening.
      expect(app.pushDeferrals, 0);
      expect(app.pushAsked, isFalse);
      expect(app.shouldAskForPush, isTrue);
      expect(app.celebratedToday, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('not there where the shell would not ask: already asked, or '
        'the first evening the experiment leaves alone', (tester) async {
      for (final bool asked in [true, false]) {
        _noWidgets(tester);
        // Asked already; or not, but the server's experiment says the sheet
        // waits for a reader who came back.
        _serverSays(firstDayAsk: asked);
        SharedPreferences.setMockInitialValues({
          ..._installed(),
          if (asked) 'knowit.pushAsked': true,
        });
        await tester.pumpWidget(const AstutoApp());
        await _settle(tester);
        await _readFive(tester);
        expect(_celebration, findsOneWidget, reason: 'asked: $asked');
        expect(_remind, findsNothing, reason: 'asked: $asked');
        expect(said.of('first day shown').last['remind'], isFalse);
        // Today's challenge alone, as the first button.
        expect(_challenge, findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });

    testWidgets('not there where notifications are on already', (
      tester,
    ) async {
      _noWidgets(tester);
      _serverSays();
      SharedPreferences.setMockInitialValues(_installed());
      // The app as AstutoApp makes it, with a phone that lets it notify:
      // its state started once the root is there to hear it ready.
      final AppState app = AppState(
        hasPermission: () async => true,
        askPermission: () async => true,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await tester.pumpWidget(_host(AstutoRoot(app: app)));
      unawaited(app.init());
      await _settle(tester);
      expect(app.notificationsAllowed, isTrue);
      expect(app.pushAsked, isFalse);
      await _readFive(tester);
      expect(_celebration, findsOneWidget);
      expect(_remind, findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Today\'s challenge', () {
    testWidgets('goes to Explore put back the way it opens, the challenge at '
        'its top; the offer waits on Today\'s table', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      // Explore visited and left scrolled down, before the day is read.
      await tester.tap(find.byKey(const ValueKey('tab-Explore')));
      await _settle(tester, 20);
      await tester.drag(
        find.byType(ExploreScreen),
        const Offset(0, -900),
        warnIfMissed: false,
      );
      await _settle(tester);
      expect(_exploreList(tester).pixels, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('tab-Today')));
      await _settle(tester, 20);

      await _readFive(tester);
      await _settle(tester);
      expect(find.text(_en.fiveTitle), findsOneWidget, reason: 'its name');
      await tester.tap(_challenge);
      await _settle(tester, 20);
      expect(_celebration, findsNothing);
      expect(said.of('first day challenge tapped'), hasLength(1));
      expect(said.of('first day closed').single['left_by'], 'challenge');
      expect(
        said.of('tab opened').last,
        {'tab': 'explore', 'by': 'first day'},
      );
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(_exploreList(tester).pixels, 0, reason: 'at its top');
      // The challenge, there to be played: its name, as its head sets it,
      // and its first card.
      expect(
        find
            .descendant(
              of: find.byType(ExploreScreen),
              matching: find.text(_en.fiveTitle.toUpperCase()),
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('three-step-0')).hitTestable(),
        findsOneWidget,
      );
      expect(_offer, findsNothing, reason: 'Today is not in front');

      // Back on Today: the card after the fifth, still to be thrown.
      await tester.tap(find.byKey(const ValueKey('tab-Today')));
      await _settle(tester, 20);
      expect(_offer, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('what it says', () {
    test('the streak, the points the day earned, and the day\'s answers: '
        'right of total, and how sure where the cards asked', () async {
      final List<Pill> cards = _graded(3, difficulty: Difficulty.medium);
      expect(cards, hasLength(3));
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.streak': 1,
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(0)],
        'knowit.judgements': _said(
          cards,
          [true, false, true],
          sure: [70, 80, 60],
        ),
      });
      final FirstDayNumbers n = FirstDayNumbers.of(app);
      expect(n.streak, 1);
      expect(n.answered, 3);
      expect(n.right, 2);
      expect(n.sure, 70);
      expect(n.points, scoreBookOf(app).overall.today);
      expect(n.points, greaterThan(0));
      expect(n.line(_it), 'Eri sicuro al 70%, hai indovinato 2 su 3.');
      expect(n.line(_en), 'You were 70% sure, and got 2 of 3 right.');
    });

    test('one right answer on a card of middling difficulty, worth 1,050, '
        'is 14 points from nothing', () async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.judgements': _said(
          _graded(1, difficulty: Difficulty.medium),
          [true],
        ),
      });
      // 24 × (1 − 1/(1 + 10^(50/400))) = 13.7
      expect(FirstDayNumbers.of(app).points, 14);
    });

    test('without how sure: right of total alone', () async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.judgements': _said(_graded(5), [
          true,
          true,
          false,
          true,
          true,
        ]),
      });
      final FirstDayNumbers n = FirstDayNumbers.of(app);
      expect(n.sure, isNull);
      expect(n.line(_it), 'Hai indovinato 4 su 5.');
      expect(n.line(_en), 'You got 4 of 5 right.');
    });

    test('how sure is the average of what was said, over the answers that '
        'asked; right of total over them all; "all\'80%" in Italian', () async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.judgements': _said(
          _graded(3),
          [true, false, true],
          sure: [90, null, 70],
        ),
      });
      final FirstDayNumbers n = FirstDayNumbers.of(app);
      expect(n.sure, 80);
      expect(n.line(_it), 'Eri sicuro all’80%, hai indovinato 2 su 3.');
    });

    test('only today\'s answers, and none at all says nothing', () async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.judgements': jsonEncode([
          {'c': 90, 'k': true, 'p': _graded(1).single.id, 'd': _day(3)},
        ]),
      });
      final FirstDayNumbers n = FirstDayNumbers.of(app);
      expect(n.answered, 0);
      expect(n.points, 0, reason: 'nothing added today');
      expect(n.line(_en), isNull);
    });

    testWidgets('as drawn: the date, the headline, the flame and the one, the '
        'points, and the line', (tester) async {
      final List<Pill> cards = _graded(3, difficulty: Difficulty.medium);
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
        'knowit.streak': 1,
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(0)],
        'knowit.judgements': _said(
          cards,
          [true, false, true],
          sure: [70, 80, 60],
        ),
      });
      await tester.pumpWidget(
        _host(FirstDayScreen(app: app), language: 'it'),
      );
      await _settle(tester, 20);
      expect(find.text('Il tuo primo giorno è fatto'), findsOneWidget);
      expect(
        _textOf(tester, 'first-day-line'),
        'Eri sicuro al 70%, hai indovinato 2 su 3.',
      );
      expect(find.byKey(const ValueKey('first-day-flame')), findsOneWidget);
      expect(find.text('GIORNO DI FILA'), findsOneWidget);
      expect(find.text('PUNTEGGIO ASTUTE'), findsOneWidget);
      expect(
        _textOf(tester, 'first-day-points-figure'),
        '+${scoreBookOf(app).overall.today}',
      );
      // The date, as the day's: in capitals.
      expect(_textOf(tester, 'first-day-date'), contains(RegExp('[A-Z]')));
      // No reminder offered: Today's challenge alone.
      expect(_remind, findsNothing);
      expect(find.text('La sfida di oggi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with no answer that counted, the day\'s cards in the points\' '
        'place, and no line', (tester) async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
      });
      await tester.pumpWidget(_host(FirstDayScreen(app: app)));
      await _settle(tester, 20);
      expect(find.byKey(const ValueKey('first-day-points')), findsNothing);
      expect(find.byKey(const ValueKey('first-day-cards')), findsOneWidget);
      expect(find.text('CARDS READ'), findsOneWidget);
      expect(find.byKey(const ValueKey('first-day-line')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the evening around it', () {
    testWidgets('a level reached that evening is not put over it, nor after '
        'it: it waits for the next calm moment', (tester) async {
      _noWidgets(tester);
      // Ten answers right today before the five, on cards worth 1,050:
      // the score is past the second level's 25, with ten answers behind it.
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        'knowit.judgements': _said(
          _graded(12, difficulty: Difficulty.medium),
          List.filled(12, true),
        ),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      final AppState app = _appOf(tester);
      expect(levelStandingOf(app, null).at, greaterThan(0));
      await _readFive(tester);
      expect(_celebration, findsOneWidget);
      await tester.tap(_close);
      await _settle(tester);
      await _throw(tester);
      await _wait(tester, seconds: 4);
      expect(find.byType(LevelUpScreen), findsNothing);
      expect(await LevelMemory.roseOn(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('and as before, the level rises over the shelf: the evening '
        'had nothing else', (tester) async {
      final bool tools = debugToolsOn;
      addTearDown(() => debugToolsOn = tools);
      debugToolsOn = true;
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        'knowit.debug.firstDayEnd': 'asBefore',
        'knowit.judgements': _said(
          _graded(12, difficulty: Difficulty.medium),
          List.filled(12, true),
        ),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _readFive(tester);
      await _throw(tester);
      await _wait(tester, seconds: 3);
      expect(find.byType(LevelUpScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a friend\'s week, given on the first day: after the '
        'celebration, never over it, and no offer between them', (
      tester,
    ) async {
      _noWidgets(tester);
      final _InviteServer server = _InviteServer();
      Invites.useForTest(
        Invites(
          serverOverride: server,
          reachableOverride: true,
          planOverride: () async {},
        ),
      );
      addTearDown(() => Invites.useForTest(Invites()));
      _serverSays(flags: {'invite': true});
      SharedPreferences.setMockInitialValues(_installed());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await Invites.instance.refresh(force: true);
      expect(Invites.instance.waiting, isTrue);
      for (var i = 0; i < kPillsPerDay - 1; i++) {
        await _throw(tester);
      }
      // The day read, the server finds it and gives the week.
      server
        ..redeemState = 'granted'
        ..until = DateTime.now().add(const Duration(days: 7))
        ..givenNow = true;
      await _throw(tester);
      expect(_celebration, findsOneWidget);
      await _wait(tester, seconds: 3);
      expect(find.byType(PurchaseSuccessScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('magic-card'), skipOffstage: false),
        findsNothing,
        reason: 'the evening a week is given offers nothing',
      );
      await tester.tap(_close);
      await _wait(tester, seconds: 3);
      expect(_celebration, findsNothing);
      expect(find.byType(PurchaseSuccessScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the screen', () {
    testWidgets('whole on the 320 × 568 phone, in German at 1.6 × text, in '
        'every language, with the reminder offered and once it is set', (
      tester,
    ) async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
      });
      tester.view.physicalSize = const Size(320, 568) * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 20 * 3);
      tester.view.viewPadding = const FakeViewPadding(top: 20 * 3);
      final List<(String, double)> cases = [
        ('de', 1.6),
        for (final Locale l in AppLocalizations.supportedLocales)
          (l.languageCode, 1.0),
        ('ru', 1.6),
        ('fr', 1.6),
        ('it', 1.6),
      ];
      for (final (String language, double text) in cases) {
        for (final bool dark in [true, false]) {
          await tester.pumpWidget(
            _host(
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(text)),
                  child: FirstDayScreen(
                    app: app,
                    numbers: const FirstDayNumbers(
                      streak: 1,
                      points: 1284,
                      cards: 5,
                      answered: 5,
                      right: 4,
                      sure: 80,
                    ),
                    // A host that offers the reminder.
                    host: FirstDayHost(
                      mayRemind: () => true,
                      remind: () async => '21:45',
                      challenge: () {},
                    ),
                  ),
                ),
              ),
              language: language,
              dark: dark,
            ),
          );
          await _settle(tester, 20);
          final String why = '$language at $text, ${dark ? 'night' : 'paper'}';
          expect(tester.takeException(), isNull, reason: why);
          final AppLocalizations l = lookupAppLocalizations(Locale(language));
          expect(find.text(l.firstDayTitle), findsOneWidget, reason: why);
          for (final Finder button in [_remind, _challenge, _close]) {
            expect(button.hitTestable(), findsOneWidget, reason: why);
          }
          // Asked and set: the time where the button was, whole.
          await tester.tap(_remind);
          await _settle(tester, 4);
          expect(tester.takeException(), isNull, reason: '$why, set');
          expect(
            find.byKey(const ValueKey('first-day-reminded')).hitTestable(),
            findsOneWidget,
            reason: why,
          );
          // The words whole, scrolled to where they are cut by nothing.
          await tester.dragUntilVisible(
            find.byKey(const ValueKey('first-day-line')),
            find.byKey(const ValueKey('first-day-scroll')),
            const Offset(0, -80),
          );
          await _settle(tester, 2);
          expect(tester.takeException(), isNull, reason: why);
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('at night black and on paper, the flame in the streak\'s '
        'orange, deeper on paper', (tester) async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
      });
      for (final bool dark in [true, false]) {
        await tester.pumpWidget(
          _host(
            FirstDayScreen(app: app, numbers: FirstDayNumbers.sample),
            dark: dark,
          ),
        );
        await _settle(tester, 20);
        final Scaffold page = tester.widget<Scaffold>(
          find.byKey(const ValueKey('first-day')),
        );
        expect(
          page.backgroundColor,
          dark ? Palette.dark.surface : Palette.light.surface,
        );
        final Icon flame = tester.widget<Icon>(
          find.byKey(const ValueKey('first-day-flame')),
        );
        expect(
          flame.color,
          dark
              ? kStreakOrange
              : Color.lerp(kStreakOrange, const Color(0xFF000000), 0.12),
        );
        // Everything else in the page's own ink: the title.
        final RichText title = tester.widget<RichText>(
          find
              .descendant(
                of: find.byKey(const ValueKey('first-day-title')),
                matching: find.byType(RichText),
              )
              .first,
        );
        expect(
          title.text.style?.color,
          dark ? Palette.dark.ink : Palette.light.ink,
        );
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('for a reader who asked for less motion, everything where it '
        'ends at once', (tester) async {
      final AppState app = await readyApp({
        ..._five(),
        'knowit.todayIndex': kPillsPerDay,
      });
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: FirstDayScreen(app: app, numbers: FirstDayNumbers.sample),
          ),
        ),
      );
      await tester.pump();
      expect(_textOf(tester, 'first-day-points-figure'), '+38');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a preview, from the developer tools: counts nothing, keeps '
        'nothing', (tester) async {
      final AppState app = await readyApp({});
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  FirstDayScreen.route(
                    app,
                    numbers: FirstDayNumbers.sample,
                    preview: true,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester, 12);
      expect(_celebration, findsOneWidget);
      expect(
        _textOf(tester, 'first-day-line'),
        'You were 70% sure, and got 4 of 5 right.',
      );
      // Its reminder sheet rises, and keeps nothing.
      await tester.tap(_remind);
      await _settle(tester);
      expect(_sheet, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('reminder-yes')));
      await _settle(tester);
      expect(asker.asked, 0);
      expect(app.pushAsked, isFalse);
      expect(app.notifyTimeChosen, isFalse);
      await tester.tap(_close);
      await _settle(tester);
      expect(_celebration, findsNothing);
      expect(said.events.where((e) => e.$1.startsWith('first day')), isEmpty);
      expect(app.firstDayCelebratedOn, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
