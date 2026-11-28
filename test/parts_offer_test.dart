import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/widgets/ui.dart' show BackCircle;

/// Keeps what would have been sent, to be read back.
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Long enough for the shelf's beat and anything rising over it.
Future<void> _wait(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _settle(tester);
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

String _key(int daysFromToday) =>
    dateKey(DateTime.now().add(Duration(days: daysFromToday)));

/// A reader whose [days]th day is finished, today's five read on an earlier
/// launch, with History the subject asked for most: the app opens on the
/// finished day's shelf. The sheets a later evening can raise over it — the
/// reminder, the account, the home-screen widget — have had their turn.
Map<String, Object> _finished(int days) => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  'knowit.pushAsked': true,
  'knowit.accountOffered': true,
  'knowit.widgetAsked': true,
  'knowit.topics': ['history', 'science'],
  'knowit.topicWeights': jsonEncode({'history': 1.0, 'science': 0.5}),
  'knowit.todayDate': _key(0),
  'knowit.todayDeckIds': dealDay(
    date: DateTime.now(),
  ).cards.map((p) => p.id).toList(),
  'knowit.todayIndex': 5,
  'knowit.lastCompletionDate': _key(0),
  'knowit.completedDates': [for (int d = days - 1; d >= 0; d--) _key(-d)],
  'knowit.streak': days,
};

final Finder _offer = find.byKey(const ValueKey('parts-offer'));

/// The app's state, read off the tabs.
AppState _appOf(WidgetTester tester) => tester
    .widget<AstutoShell>(find.byType(AstutoShell, skipOffstage: false))
    .app;

/// Which parts used to be the first run's third question, before a single
/// card. It is offered instead on the finished day's shelf from the third
/// finished day, once and quietly, with a line of why; and it is always in
/// the fine-tuning of the mix besides (test/tune_test.dart).
void main() {
  late _Said said;

  setUp(() {
    said = _Said();
    // Measured, as a reader who said yes long ago: the question about
    // usage data is answered and not on the shelf.
    Analytics.useForTest(said);
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    Analytics.useForTest(null);
    Remote.reset();
  });

  Future<void> open(
    WidgetTester tester,
    int days, [
    Map<String, Object> prefs = const {},
  ]) async {
    _noWidgets(tester);
    SharedPreferences.setMockInitialValues({..._finished(days), ...prefs});
    await tester.pumpWidget(const AstutoApp());
    await _wait(tester);
  }

  testWidgets('not on the first two finished days', (tester) async {
    for (final int days in const [1, 2]) {
      await tester.pumpWidget(const SizedBox());
      await open(tester, days);
      expect(find.byType(TodayDoneView), findsOneWidget, reason: '$days');
      expect(_offer, findsNothing, reason: 'day $days');
    }
    expect(said.of('parts offer shown'), isEmpty);
  });

  testWidgets('on the third, a card on the shelf with a line of why; the way '
      'in opens Which parts, and what is chosen there is kept', (
    tester,
  ) async {
    await open(tester, 3);
    expect(_offer, findsOneWidget);
    expect(
      find.ancestor(of: _offer, matching: find.byType(TodayDoneView)),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Which parts?'), findsOneWidget);
    expect(
      find.text(
        'A few days in, you know the cards. Inside each subject, keep the '
        'parts you want and leave the rest.',
      ),
      findsOneWidget,
    );
    expect(said.of('parts offer shown'), [
      {'days_completed': 3},
    ]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('knowit.partsOffer'), _key(0));

    await tester.tap(find.byKey(const ValueKey('parts-offer-choose')));
    await _settle(tester);
    expect(find.byType(GenresScreen), findsOneWidget);
    expect(said.of('parts offer answered'), [
      {'choice': 'choose'},
    ]);

    // Ancient Rome left out, and kept.
    await tester.tap(find.text('Ancient Rome'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('genres-done')));
    await _settle(tester);
    expect(find.byType(GenresScreen), findsNothing);
    expect(_appOf(tester).genresOff, contains('history.ancient_rome'));
    expect(prefs.getStringList('knowit.genresOff'), [
      'history.ancient_rome',
    ]);
    // Answered: the shelf is as on any evening.
    expect(_offer, findsNothing);
    expect(prefs.getString('knowit.partsOffer'), 'done');
  });

  testWidgets('the page can be left without choosing, and the shelf is as '
      'it was', (tester) async {
    await open(tester, 3);
    await tester.tap(find.byKey(const ValueKey('parts-offer-choose')));
    await _settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(GenresScreen),
        matching: find.byType(BackCircle),
      ),
    );
    await _settle(tester);
    expect(find.byType(GenresScreen), findsNothing);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(_appOf(tester).genresOff, isEmpty);
    expect(_offer, findsNothing);
  });

  testWidgets('"Not now" lets it go for good', (tester) async {
    await open(tester, 3);
    await tester.tap(find.byKey(const ValueKey('parts-offer-not-now')));
    await _settle(tester);
    expect(_offer, findsNothing);
    expect(said.of('parts offer answered'), [
      {'choice': 'not now'},
    ]);
    // The next launch, and a day finished later: not again.
    await tester.pumpWidget(const SizedBox());
    await open(tester, 4, {'knowit.partsOffer': 'done'});
    expect(_offer, findsNothing);
  });

  testWidgets('left unanswered, it stays that evening, and is not put on '
      'another', (tester) async {
    await open(tester, 3);
    expect(_offer, findsOneWidget);
    // The same evening, the app opened again.
    await tester.pumpWidget(const SizedBox());
    await open(tester, 3, {'knowit.partsOffer': _key(0)});
    expect(_offer, findsOneWidget);
    // The next finished day: it had its evening.
    await tester.pumpWidget(const SizedBox());
    await open(tester, 4, {'knowit.partsOffer': _key(-1)});
    expect(_offer, findsNothing);
    expect(said.of('parts offer shown'), hasLength(1));
  });

  testWidgets('a reader who has chosen parts already is not offered them', (
    tester,
  ) async {
    await open(tester, 5, {
      'knowit.genresOff': ['history.ancient_rome'],
    });
    expect(_offer, findsNothing);
  });

  testWidgets('a later first evening is offered it too', (tester) async {
    await open(tester, 9);
    expect(_offer, findsOneWidget);
  });

  testWidgets('waits for the question about usage data, and takes no '
      'evening from it: never both on one shelf', (tester) async {
    // A reader who never answered: the question about usage data is the
    // shelf's, and Which parts waits.
    await Analytics.startForTest(said);
    await open(tester, 3);
    expect(find.byKey(const ValueKey('consent-card')), findsOneWidget);
    expect(_offer, findsNothing);
    await tester.tap(find.byKey(const ValueKey('consent-no')));
    await _wait(tester);
    // Answered: it folds away, and nothing rises in its place.
    expect(find.byKey(const ValueKey('consent-card')), findsNothing);
    expect(_offer, findsNothing);
    // The shelf opened again: now it is Which parts' turn.
    await Analytics.startForTest(said);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const AstutoApp());
    await _wait(tester);
    expect(_offer, findsOneWidget);
  });

  testWidgets('the server can hold it back, or move it later', (tester) async {
    Remote.adopt(
      RemoteConfig.parse(
        jsonEncode({
          'schema': 1,
          'hash': 'no-parts',
          'app': {
            'flags': {'parts.offer': false},
          },
          'strings': <String, Object?>{},
          'explore': null,
          'looks': null,
        }),
      ),
    );
    await open(tester, 3);
    expect(_offer, findsNothing);

    Remote.adopt(
      RemoteConfig.parse(
        jsonEncode({
          'schema': 1,
          'hash': 'parts-later',
          'app': {
            'tunables': {'parts.offerDay': 5},
          },
          'strings': <String, Object?>{},
          'explore': null,
          'looks': null,
        }),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await open(tester, 4);
    expect(_offer, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await open(tester, 5);
    expect(_offer, findsOneWidget);
  });
}
