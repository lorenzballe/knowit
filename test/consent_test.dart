import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/screens/intro_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/push.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/consent_card.dart';

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

/// Stands in for the system's prompt about notifications: a phone where it
/// can still be put, so the app's own reminder sheet comes first.
class _Asker extends Push {
  @override
  bool get canAsk => true;

  @override
  Future<String?> ask() async => null;

  @override
  Future<String?> refresh() async => null;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Long enough for the shelf's beat and anything rising over it, frame by
/// frame.
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

/// The reader's first day, its five read on an earlier launch and its
/// reminder question settled: the app opens on the finished day's shelf.
Map<String, Object> _firstDayDone() => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  'knowit.pushAsked': true,
  'knowit.todayDate': _key(0),
  'knowit.todayDeckIds': dealDay(
    date: DateTime.now(),
  ).cards.map((p) => p.id).toList(),
  'knowit.todayIndex': 5,
  'knowit.lastCompletionDate': _key(0),
  'knowit.completedDates': [_key(0)],
};

final Finder _card = find.byKey(const ValueKey('consent-card'));
final Finder _yes = find.byKey(const ValueKey('consent-yes'));
final Finder _no = find.byKey(const ValueKey('consent-no'));

/// Nothing is measured before the reader says yes, and the question is not
/// the first thing the app asks: it is a calm card on the finished day's
/// shelf, from the end of the first day — after the day's own moment and
/// the reminder's question — and it stays there until it is answered. The
/// two answers weigh the same.
void main() {
  late _Said said;

  setUp(() {
    said = _Said();
    // A phone, so the shelf is laid out as it is in a hand.
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
    Push.useForTest(Push());
  });

  group('the first run', () {
    testWidgets('asks nothing about usage data, and measures nothing', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': false});
      await Analytics.startForTest(said);
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(_yes, findsNothing);
      expect(_no, findsNothing);
      expect(find.text('Help make Astute better?'), findsNothing);
      // Turning the scenes and starting: measured by the intro only once
      // there is a yes, and there is none.
      await tester.tapAt(const Offset(200, 200));
      await _settle(tester);
      await tester.tap(find.text('Start reading'));
      await _settle(tester);
      expect(find.byType(MixScreen), findsOneWidget);
      expect(_yes, findsNothing);
      expect(Analytics.answered, isFalse);
      expect(Analytics.ready, isFalse);
      expect(said.events, isEmpty);
    });
  });

  group('the finished day\'s shelf', () {
    Future<void> openOnShelf(
      WidgetTester tester, [
      Map<String, Object> prefs = const {},
    ]) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues({..._firstDayDone(), ...prefs});
      await Analytics.startForTest(said);
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
    }

    testWidgets('asks at the end of the first day, as a card among the '
        'shelf\'s, two answers of one size, and nothing measured meanwhile', (
      tester,
    ) async {
      await openOnShelf(tester);
      expect(_card, findsOneWidget);
      // On the shelf, not over it: a card of the finished day's own.
      expect(
        find.ancestor(of: _card, matching: find.byType(TodayDoneView)),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Help make Astute better?'), findsOneWidget);
      expect(
        find.text(
          'We count how the app is used, with no advertising and never your '
          'name.',
        ),
        findsOneWidget,
      );
      expect(tester.getSize(_no), tester.getSize(_yes));
      expect(tester.getSize(_yes).height, greaterThanOrEqualTo(44));
      expect(Analytics.ready, isFalse);
      expect(said.events, isEmpty);
    });

    testWidgets('does not stand in the way: the tabs work around it, and it '
        'is still there to answer', (tester) async {
      await openOnShelf(tester);
      expect(_card, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('tab-Today')));
      await _settle(tester);
      expect(_card, findsOneWidget);
      expect(Analytics.answered, isFalse);
      expect(said.events, isEmpty);
    });

    testWidgets('a yes starts measurement there and then, and its first '
        'event is that yes', (tester) async {
      await openOnShelf(tester);
      await tester.tap(_yes);
      await _settle(tester);
      expect(_card, findsNothing);
      expect(Analytics.ready, isTrue);
      expect(Analytics.collecting, isTrue);
      expect(said.events.first.$1, 'usage sharing answered');
      expect(said.of('usage sharing answered'), [
        {'on': true, 'from': 'shelf'},
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.analytics'), isTrue);
    });

    testWidgets('a no is kept, nothing is sent, and it is not asked again at '
        'the next launch', (tester) async {
      await openOnShelf(tester);
      await tester.tap(_no);
      await _settle(tester);
      expect(_card, findsNothing);
      expect(Analytics.answered, isTrue);
      expect(Analytics.ready, isFalse);
      expect(said.events, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.analytics'), isFalse);
      expect(prefs.getBool('knowit.analytics.asked'), isTrue);

      // The next launch, on the same phone.
      await Analytics.startForTest(said);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(find.byType(TodayDoneView), findsOneWidget);
      expect(_card, findsNothing);
      expect(Analytics.ready, isFalse);
      expect(said.events, isEmpty);
    });

    testWidgets('unanswered, it stays: there again at the next launch, and on '
        'a day finished later', (tester) async {
      await openOnShelf(tester);
      expect(_card, findsOneWidget);

      await Analytics.startForTest(said);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(_card, findsOneWidget);

      // A later day, finished: the shelf asks again.
      await tester.pumpWidget(const SizedBox());
      await openOnShelf(tester, {
        'knowit.completedDates': [_key(-1), _key(0)],
        'knowit.streak': 2,
      });
      expect(_card, findsOneWidget);
      expect(said.events, isEmpty);
    });

    testWidgets('waits for the reminder\'s question, which goes first, and '
        'comes once it is answered', (tester) async {
      // Back for a second day, on a phone where the system's prompt is
      // unspent: the evening's reminder sheet rises over the shelf.
      Push.useForTest(_Asker());
      await openOnShelf(tester, {
        'knowit.pushAsked': false,
        'knowit.completedDates': [_key(-1), _key(0)],
        'knowit.streak': 2,
      });
      expect(find.byKey(const ValueKey('reminder-ask')), findsOneWidget);
      expect(_card, findsNothing);
      await tester.tap(find.byKey(const ValueKey('reminder-not-now')));
      await _wait(tester);
      expect(find.byKey(const ValueKey('reminder-ask')), findsNothing);
      expect(_card, findsOneWidget);
    });

    testWidgets('is not on a day still being read', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues({
        ..._firstDayDone(),
        'knowit.todayIndex': 2,
        'knowit.lastCompletionDate': _key(-1),
        'knowit.completedDates': [_key(-1)],
      });
      await Analytics.startForTest(said);
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(_card, findsNothing);
    });

    testWidgets('a build with nowhere to send it does not ask', (tester) async {
      _noWidgets(tester);
      SharedPreferences.setMockInitialValues(_firstDayDone());
      Analytics.useForTest(null);
      await tester.pumpWidget(const AstutoApp());
      await _wait(tester);
      expect(find.byType(TodayDoneView), findsOneWidget);
      expect(_card, findsNothing);
    });
  });

  testWidgets('the card holds whole in every language, on a small phone and '
      'at a larger text size', (tester) async {
    SharedPreferences.setMockInitialValues(_firstDayDone());
    await Analytics.startForTest(said);
    final AppState app = AppState(
      hasPermission: () async => false,
      askPermission: () async => false,
      arm: (_) async {},
      disarm: () async {},
      pushWidget: (_) async {},
    );
    await tester.runAsync(app.init);
    expect(ConsentCard.due(app), isTrue);
    tester.view.physicalSize = const Size(320, 568) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    for (final double scale in const [1.0, 1.5]) {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.light),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 568),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConsentCard(app: app),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final String where = '$locale at ${scale}x';
        final l = lookupAppLocalizations(locale);
        expect(tester.takeException(), isNull, reason: where);
        expect(find.text(l.consentTitle), findsOneWidget, reason: where);
        expect(find.text(l.consentCardLine), findsOneWidget, reason: where);
        expect(tester.getSize(_no), tester.getSize(_yes), reason: where);
        expect(tester.getRect(_card).top, greaterThan(0), reason: where);
        expect(
          tester.getRect(_yes).bottom,
          lessThanOrEqualTo(568),
          reason: where,
        );
      }
    }
  });

  testWidgets('the intro\'s small print links the terms and the privacy '
      'policy, in every language', (tester) async {
    Analytics.useForTest(said);
    for (final Locale locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: IntroScreen(onContinue: () {}, onSignIn: (_) async => false),
        ),
      );
      await tester.pump();
      final l = lookupAppLocalizations(locale);
      final RichText line = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(const ValueKey('intro-terms')),
          matching: find.byType(RichText),
        ),
      );
      final List<TextSpan> links = [];
      line.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer != null) links.add(span);
        return true;
      });
      expect(links.map((s) => s.text), [
        l.termsLineTerms,
        l.termsLinePrivacy,
      ], reason: '$locale');
      // The marks the sentence was asked with are all gone.
      expect(line.text.toPlainText(), isNot(contains('\u0001')));
      expect(line.text.toPlainText(), isNot(contains('\u0002')));
      if (locale.languageCode == 'en') {
        for (final TextSpan link in links) {
          (link.recognizer! as TapGestureRecognizer).onTap!();
        }
      }
    }
    expect(said.of('legal page opened'), [
      {'page': 'terms', 'from': 'intro'},
      {'page': 'privacy', 'from': 'intro'},
    ]);
  });
}
