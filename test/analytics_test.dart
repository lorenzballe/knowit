import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/state/app_state.dart';

/// A sink that keeps what it was given, so what the app measures can be read
/// back in a test rather than watched on a network.
class _Recorder implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];
  final List<String> screens = [];
  final List<String> identified = [];
  final Map<String, Object> registered = {};
  int resets = 0;
  bool? collecting;

  /// The properties of the last event named [event], or null if it never came.
  Map<String, Object>? last(String event) {
    for (final e in events.reversed) {
      if (e.$1 == event) return e.$2;
    }
    return null;
  }

  List<String> get names => [for (final e in events) e.$1];

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async => screens.add(name);

  @override
  Future<void> identify(String id, Map<String, Object> properties) async =>
      identified.add(id);

  @override
  Future<void> reset() async => resets++;

  @override
  Future<void> register(String key, Object value) async =>
      registered[key] = value;

  @override
  Future<void> setCollecting(bool on) async => collecting = on;
}

/// An app past the first run, so a day can be read without the onboarding.
Future<AppState> _ready([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
  );
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Recorder sink;

  setUp(() {
    sink = _Recorder();
    Analytics.useForTest(sink);
  });

  tearDown(() => Analytics.useForTest(null));

  group('measurement is off until it is configured', () {
    test('a build with no key measures nothing', () async {
      Analytics.useForTest(null);
      SharedPreferences.setMockInitialValues({});

      // This is what every widget test in this suite runs under, and why
      // none of them reaches the network: start() finds no key and returns.
      await Analytics.start();

      expect(Analytics.ready, isFalse);
      expect(Analytics.failure, contains('POSTHOG_KEY'));
    });

    test('capturing without a sink is a no-op, not a crash', () async {
      Analytics.useForTest(null);
      await Analytics.capture('day completed', const {'streak_days': 3});
      await Analytics.screen('today');
      await Analytics.identify('uid');
      await Analytics.reset();
      expect(Analytics.ready, isFalse);
    });

    test('a sink that throws never reaches the caller', () async {
      Analytics.useForTest(_Exploding());
      // No expectation beyond this returning: an event that fails to send is
      // not the reader's problem, so it may not become an exception on the
      // path they are waiting on.
      await Analytics.capture('day completed');
      await Analytics.screen('today');
    });
  });

  group('the reader\'s own switch', () {
    test('an opt-out is remembered and applied at once', () async {
      SharedPreferences.setMockInitialValues({});

      await Analytics.setCollecting(false);

      expect(Analytics.collecting, isFalse);
      expect(sink.collecting, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.analytics'), isFalse);
    });

    test('signing out does not quietly turn measurement back on', () async {
      final app = await _ready();
      await Analytics.setCollecting(false);

      // Sign-out clears every key the app holds, this one among them.
      await app.signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.analytics'), isFalse);
      expect(Analytics.collecting, isFalse);
      // And the phone is no longer that reader.
      expect(sink.resets, 1);
    });
  });

  group('the day', () {
    test('a day dealt says how much of it is a re-asking', () async {
      await _ready();

      final day = sink.last('day started');
      expect(day, isNotNull);
      expect(day!['cards'], 5);
      expect(day['reviews'], 0);
      expect(day['own'], kOwnCardsFree);
      expect(day['is_plus'], false);
    });

    test('a card advanced carries its place in the five', () async {
      final app = await _ready();
      sink.events.clear();

      await app.advance();

      final card = sink.last('card advanced');
      expect(card, isNotNull);
      expect(card!['position'], 1);
      expect(card['of'], 5);
      expect(card['pill_id'], isA<String>());
      expect(card['topic'], isA<String>());
    });

    test('the finished day is counted once, with what it was worth', () async {
      final app = await _ready();
      sink.events.clear();

      for (var i = 0; i < 5; i++) {
        await app.advance();
      }

      final done = sink.last('day completed');
      expect(done, isNotNull);
      expect(done!['streak_days'], 1);
      expect(done['cards'], 5);
      expect(done['is_plus'], false);
      expect(
        sink.names.where((n) => n == 'day completed'),
        hasLength(1),
        reason: 'advancing past the last card ends the day exactly once',
      );
    });
  });

  group('what a card carries, and what it does not', () {
    test('an answer sends the confidence but never the reason', () async {
      final app = await _ready();
      final graded = app.todaysDeck.firstWhere((p) => p.isGraded);
      sink.events.clear();

      await app.recordAnswer(
        graded.id,
        'something the reader typed',
        confidence: 70,
        reason: 'because I read it somewhere',
      );

      final answer = sink.last('card answered');
      expect(answer, isNotNull);
      expect(answer!['confidence'], 70);
      expect(answer['gave_reason'], true);
      expect(answer['pill_id'], graded.id);

      // The prose stays on the phone. Neither the answer nor the reason may
      // appear anywhere in what was sent.
      final sent = sink.events.map((e) => '${e.$1} ${e.$2}').join(' ');
      expect(sent, isNot(contains('something the reader typed')));
      expect(sent, isNot(contains('because I read it somewhere')));
    });

    test('a shelf sends the id and the subject, and its size', () async {
      final app = await _ready();
      final pill = app.todaysDeck.first;
      sink.events.clear();

      await app.toggleSaved(pill.id);
      expect(sink.last('pill saved')!['shelf_size'], 1);

      await app.toggleSaved(pill.id);
      expect(sink.last('pill unsaved')!['shelf_size'], 0);

      await app.markSaid(pill.id);
      expect(sink.last('pill said')!['topic'], pill.topic);
    });

    test('a friend is a count, never a code', () async {
      final app = await _ready();
      sink.events.clear();

      await app.addFriend('ABC123');

      expect(sink.last('friend added'), {'friends': 1});
      expect(
        sink.events.map((e) => '${e.$2}').join(' '),
        isNot(contains('ABC123')),
      );
    });
  });

  group('the plan and the ladder are stamped on everything after them', () {
    test('the store answering registers the plan', () async {
      final app = await _ready();

      await app.applyEntitlement(true);

      expect(sink.last('plan changed'), {'is_plus': true});
      expect(sink.registered['is_plus'], true);
    });

    test('a rung is registered, and the first climb is not an event', () async {
      // A fresh install dates every rung under the reader at once. That is
      // an install, not five moments of progress.
      await _ready();

      expect(sink.names, isNot(contains('rung reached')));
      expect(sink.registered['rung'], isA<int>());
    });
  });
}

/// A sink where everything fails, which is the case the app must survive.
class _Exploding implements AnalyticsSink {
  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      throw StateError('no');

  @override
  Future<void> screen(String name) async => throw StateError('no');

  @override
  Future<void> identify(String id, Map<String, Object> properties) async =>
      throw StateError('no');

  @override
  Future<void> reset() async => throw StateError('no');

  @override
  Future<void> register(String key, Object value) async =>
      throw StateError('no');

  @override
  Future<void> setCollecting(bool on) async => throw StateError('no');
}
