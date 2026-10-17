import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/consent.dart';

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

/// Long enough for a sheet's beat and its rise, frame by frame.
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

/// Today's five, already read, on an install past the first run whose
/// reminder sheet has had its turn: the app opens on the finished day.
Map<String, Object> _dayDone() => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  'knowit.pushAsked': true,
  'knowit.todayDate': dateKey(DateTime.now()),
  'knowit.todayDeckIds': dealDay(date: DateTime.now()).cards
      .map((p) => p.id)
      .toList(),
  'knowit.todayIndex': 5,
  'knowit.lastCompletionDate': dateKey(DateTime.now()),
  'knowit.completedDates': [dateKey(DateTime.now())],
};

final Finder _question = find.byKey(const ValueKey('consent'));
final Finder _sheet = find.byKey(const ValueKey('consent-sheet'));
final Finder _yes = find.byKey(const ValueKey('consent-yes'));
final Finder _no = find.byKey(const ValueKey('consent-no'));

/// Nothing is measured before the reader says yes: the intro asks, a reader
/// who started without answering is asked once more after a finished day,
/// and the two answers weigh the same.
void main() {
  late _Said said;

  setUp(() => said = _Said());
  tearDown(() => Analytics.useForTest(null));

  group('the intro asks', () {
    Future<void> firstLaunch(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': false});
      await Analytics.startForTest(said);
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
    }

    testWidgets('on the foot of a first launch, two answers of one size, and '
        'nothing measured meanwhile', (tester) async {
      await firstLaunch(tester);
      expect(_question, findsOneWidget);
      expect(
        find.text('Help make Astute better?', findRichText: true),
        findsNothing,
        reason: 'one text with its line, not two',
      );
      expect(
        find.textContaining('Help make Astute better?', findRichText: true),
        findsOneWidget,
      );
      expect(tester.getSize(_no), tester.getSize(_yes));
      expect(tester.getSize(_yes).height, greaterThanOrEqualTo(44));
      // Turning the scenes is measured by the intro — once there is a yes.
      await tester.tapAt(const Offset(200, 200));
      await _settle(tester);
      expect(Analytics.ready, isFalse);
      expect(said.events, isEmpty);
    });

    testWidgets('a yes starts measurement there and then, and its first '
        'event is that yes', (tester) async {
      await firstLaunch(tester);
      await tester.tap(_yes);
      await _settle(tester);
      expect(_question, findsNothing);
      expect(Analytics.ready, isTrue);
      expect(Analytics.collecting, isTrue);
      expect(said.events.first.$1, 'usage sharing answered');
      expect(said.of('usage sharing answered'), [
        {'on': true, 'from': 'intro'},
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.analytics'), isTrue);
    });

    testWidgets('a no is kept, the question goes, and nothing is sent', (
      tester,
    ) async {
      await firstLaunch(tester);
      await tester.tap(_no);
      await _settle(tester);
      expect(_question, findsNothing);
      expect(Analytics.answered, isTrue);
      expect(Analytics.ready, isFalse);
      // The intro goes on as before, unmeasured.
      await tester.tap(find.text('Start reading'));
      await _settle(tester);
      expect(find.byType(MixScreen), findsOneWidget);
      expect(said.events, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.analytics'), isFalse);
      expect(prefs.getBool('knowit.analytics.asked'), isTrue);
    });

    testWidgets('it is not in the way: starting without an answer starts, '
        'and measures nothing', (tester) async {
      await firstLaunch(tester);
      await tester.tap(find.text('Start reading'));
      await _settle(tester);
      expect(find.byType(MixScreen), findsOneWidget);
      expect(Analytics.answered, isFalse);
      expect(Analytics.ready, isFalse);
      expect(said.events, isEmpty);
    });

    testWidgets('a build with nowhere to send it does not ask', (tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': false});
      Analytics.useForTest(null);
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      expect(find.text('Start reading'), findsOneWidget);
      expect(_question, findsNothing);
    });
  });

  group('a reader past the first run who never answered', () {
    testWidgets('is asked once, as a sheet, on a finished day; a yes '
        'measures from then on', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_dayDone());
      await Analytics.startForTest(said);
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(said.events, isEmpty);
      // It waits for an answer: a tap beside it is not one.
      await tester.tapAt(const Offset(20, 40));
      await _settle(tester);
      expect(_sheet, findsOneWidget);
      await tester.tap(_yes);
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(Analytics.collecting, isTrue);
      expect(said.of('usage sharing answered'), [
        {'on': true, 'from': 'sheet'},
      ]);
    });

    testWidgets('a no is kept, and not asked again at the next launch', (
      tester,
    ) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_dayDone());
      await Analytics.startForTest(said);
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      await tester.tap(_no);
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(Analytics.answered, isTrue);
      expect(said.events, isEmpty);

      // The next launch, on the same phone.
      await Analytics.startForTest(said);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(_sheet, findsNothing);
      expect(Analytics.ready, isFalse);
    });
  });

  testWidgets('the sheet holds whole in every language, on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    for (final Locale locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.light),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ConsentSheet(),
            ),
          ),
        ),
      );
      await tester.pump();
      final l = lookupAppLocalizations(locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      // What it measures, word for word as Profile's switch says it.
      expect(find.text(l.anonymousUsageLine), findsOneWidget);
      expect(tester.getSize(_no), tester.getSize(_yes), reason: '$locale');
      expect(tester.getRect(_yes).bottom, lessThanOrEqualTo(667));
    }
  });
}
