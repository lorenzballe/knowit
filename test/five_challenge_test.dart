// "Challenge a friend" on today's five (lib/explore/blocks/bets/
// five_challenge.dart): the link, which carries the day and the score and
// nothing else, to a page the site writes and the app does not claim; the
// line it is sent with, in the reader's language; the share it is counted
// as; how many of today's five the reader got right, as the game kept each
// card; and the choice under the finished day's share, there only while the
// server says so (share.challenge). The end of the five on Explore, which
// sends it too, is in test/explore/three_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/five_challenge.dart';
import 'package:astuto/explore/blocks/bets/three.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/utils/share_link.dart';
import 'package:astuto/utils/share_text.dart';
import 'package:astuto/utils/widget_open.dart';
import 'package:astuto/widgets/share_day.dart';

final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

/// What the app said, kept, so a test can read its counting back.
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

int _docs = 0;

/// The server's document, saying [flags].
void _take(Map<String, Object?> flags) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'challenge-${_docs++}',
      'app': {'flags': flags},
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// Lays today's five as the game lays them (three.dart, lockIn): a bet of
/// the day's games on each card, right where [right] says.
void _played(
  List<Pill> five,
  bool Function(int i) right, {
  String game = 'five',
}) {
  for (final (int i, Pill p) in five.indexed) {
    BetsDay.instance.place(
      Bet(
        kind: kDailyBet,
        section: 'three',
        pill: p.id,
        said: '0',
        right: right(i),
        facts: {
          'pts': right(i) ? 100 : 0,
          'step': i + 1,
          'of': 5,
          'game': game,
        },
      ),
    );
  }
}

/// What the clipboard is handed.
List<String> _clipboard(WidgetTester tester) {
  final List<String> copied = [];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copied;
}

void main() {
  final String today = dateKey(DateTime.now());

  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    BetsDay.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Remote.reset();
    Analytics.useForTest(null);
    sendText = shareText;
  });

  group('the link', () {
    test('the day and the score, and nothing else', () {
      expect(
        fiveChallengeLink('2026-11-27', score: 4),
        'https://astutetheapp.com/sfida?d=2026-11-27&s=4',
      );
      for (final int s in [0, 5]) {
        expect(
          Uri.parse(fiveChallengeLink('2026-11-27', score: s)).queryParameters,
          {'d': '2026-11-27', 's': '$s'},
        );
      }
      // Before the reader has played, and a score no five can have.
      for (final int? s in [null, -1, 6]) {
        expect(
          fiveChallengeLink('2026-11-27', score: s),
          'https://astutetheapp.com/sfida?d=2026-11-27',
        );
      }
    });

    test('a page the site writes, which the app leaves to the browser', () {
      final Uri link = Uri.parse(fiveChallengeLink('2026-11-27', score: 4));
      expect(link.host, kSiteHost);
      expect(WidgetOpen.cardOfLink(link), isNull);
      // Neither phone hands it to the app: the two scores are compared on
      // the page, with or without the app.
      final String apple = File('site/.well-known/apple-app-site-association')
          .readAsStringSync();
      expect(apple, isNot(contains('sfida')));
      final String android = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(android, contains('android:pathPrefix="/c/"'));
      expect(android, isNot(contains('sfida')));
      // The page the deploy writes, at the path the link names.
      expect(
        File('tool/cards/sfida_page.py').readAsStringSync(),
        contains('PATH = "sfida"'),
      );
    });
  });

  group('the line', () {
    test('how many of today\'s five were right, a question to the friend, '
        'and the link under it', () {
      expect(
        fiveChallengeText(en, day: '2026-11-27', right: 4),
        "I got 4 of today's 5 on Astute. Can you beat me?\n"
        'https://astutetheapp.com/sfida?d=2026-11-27&s=4',
      );
      expect(
        fiveChallengeText(en, day: '2026-11-27', right: 5),
        "I got all of today's 5 on Astute. Can you match it?\n"
        'https://astutetheapp.com/sfida?d=2026-11-27&s=5',
      );
      // Before the reader has played them: the five alone.
      expect(fiveChallengeText(en, day: '2026-11-27').split('\n'), [
        en.fiveChallengeInvite,
        'https://astutetheapp.com/sfida?d=2026-11-27',
      ]);
    });

    test('in every language the app speaks, the score in it', () {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final AppLocalizations l = lookupAppLocalizations(locale);
        for (int right = 0; right <= 4; right++) {
          final List<String> lines = fiveChallengeText(
            l,
            day: '2026-11-27',
            right: right,
          ).split('\n');
          expect(lines, hasLength(2), reason: '$locale');
          expect(lines.first, contains('$right'), reason: '$locale');
          expect(lines.last, endsWith('&s=$right'), reason: '$locale');
        }
        expect(l.fiveChallengeAll, isNot(contains('{')), reason: '$locale');
        expect(l.fiveChallengeInvite, isNotEmpty, reason: '$locale');
      }
      final AppLocalizations it = lookupAppLocalizations(const Locale('it'));
      expect(
        it.fiveChallengeLine(4),
        'Ho indovinato 4 delle cinque di oggi su Astute. Riesci a battermi?',
      );
    });

    testWidgets('sent through the system\'s sheet, counted as a share; '
        'copied where there is no sheet', (tester) async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      final List<String> sent = [];
      sendText = (text) async {
        sent.add(text);
        return true;
      };
      final bool shared = await sendFiveChallenge(
        en,
        from: 'five result',
        day: '2026-11-27',
        right: 3,
      );
      expect(shared, isTrue);
      expect(sent.single, fiveChallengeText(en, day: '2026-11-27', right: 3));
      expect(said.of('five challenge shared').single, {
        'from': 'five result',
        'right': 3,
        'as': 'link',
      });

      final List<String> copied = _clipboard(tester);
      sendText = (text) async => false;
      expect(
        await sendFiveChallenge(en, from: 'done view', day: '2026-11-27'),
        isFalse,
      );
      expect(copied.single, fiveChallengeText(en, day: '2026-11-27'));
      // Not played: no score said.
      expect(said.of('five challenge shared').last, {
        'from': 'done view',
        'as': 'copied',
      });
    });
  });

  group('how many right', () {
    test('once all five are locked in today, as the game kept each', () async {
      await BetsDay.instance.load();
      final List<Pill> five = DailyDeal.five(BetsDay.instance.now);
      expect(fiveRightToday(), isNull);
      _played(five.take(4).toList(), (i) => i.isEven);
      expect(fiveRightToday(), isNull, reason: 'four of the five');
      _played(five.skip(4).toList(), (i) => true);
      // The first and third of the four, and the fifth.
      expect(fiveRightToday(), 3);
    });

    test('only the five\'s own bets count', () async {
      await BetsDay.instance.load();
      _played(
        DailyDeal.five(BetsDay.instance.now),
        (i) => true,
        game: 'three-science',
      );
      expect(fiveRightToday(), isNull);
    });

    test('the five the site has are the app\'s deal for the day, in its '
        'order', () {
      final DateTime day = DateTime(2026, 11, 27, 9);
      final List<Pill> five = DailyDeal.five(day);
      expect(isSitesFive(day, five), isTrue);
      expect(isSitesFive(day, five.reversed.toList()), isFalse);
      expect(isSitesFive(day, five.take(4).toList()), isFalse);
      expect(isSitesFive(DateTime(2026, 11, 28, 9), five), isFalse);
    });
  });

  group('under the finished day\'s share', () {
    /// A reader whose day is read, and the day's share open.
    Future<void> openSheet(WidgetTester tester) async {
      final List<String> deck = dealDay(date: DateTime.now()).cards
          .take(kPillsPerDay)
          .map((p) => p.id)
          .toList();
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.todayDate': today,
        'knowit.todayDeckIds': deck,
        'knowit.todayIndex': deck.length,
        'knowit.lastCompletionDate': today,
        'knowit.completedDates': [today],
        'knowit.seenIds': deck,
      });
      final AppState app = AppState();
      await tester.runAsync(app.init);
      await tester.runAsync(BetsDay.instance.load);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  key: const ValueKey('open'),
                  onPressed: () =>
                      ShareDay.send(context, app, from: 'done view'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(en.shareDayTitle), findsOneWidget);
    }

    final Finder challenge = find.byKey(const ValueKey('share-day-challenge'));

    testWidgets('not while the server has not said so', (tester) async {
      await openSheet(tester);
      expect(challenge, findsNothing);
    });

    testWidgets('while it has: the five alone before they are played, the '
        'score once they are', (tester) async {
      _take({'share.challenge': true});
      final _Said said = _Said();
      Analytics.useForTest(said);
      final List<String> sent = [];
      sendText = (text) async {
        sent.add(text);
        return true;
      };
      await openSheet(tester);
      expect(challenge, findsOneWidget);
      expect(
        find.descendant(of: challenge, matching: find.text(en.challengeFriend)),
        findsOneWidget,
      );
      // Under the day's own buttons, the whole width.
      final Rect send = tester.getRect(
        find.byKey(const ValueKey('share-day-send')),
      );
      final Rect button = tester.getRect(challenge);
      expect(button.top, greaterThan(send.bottom));
      expect(button.width, greaterThan(send.width));

      await tester.tap(challenge);
      await tester.runAsync(() async {});
      await tester.pump();
      expect(sent.single, fiveChallengeText(en, day: today));
      expect(said.of('five challenge shared').single, {
        'from': 'done view',
        'as': 'link',
      });

      _played(DailyDeal.five(BetsDay.instance.now), (i) => i != 2);
      await tester.tap(challenge);
      await tester.runAsync(() async {});
      await tester.pump();
      expect(sent.last, fiveChallengeText(en, day: today, right: 4));
      expect(sent.last, endsWith('/sfida?d=$today&s=4'));
      expect(said.of('five challenge shared').last['right'], 4);
    });
  });
}
