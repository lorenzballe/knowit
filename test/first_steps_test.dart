// The first run's four steps, counted on our own server with nothing that
// says whose (lib/measure/first_steps.dart, functions/src/steps.ts): each
// once per phone, only on a phone new to the app, only from a phone the
// stores installed, and sent as the step and the day and nothing else.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart' show resetCalendar;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/legal.dart';
import 'package:astuto/measure/first_steps.dart';
import 'package:astuto/state/app_state.dart';

Future<AppState> _launch(DateTime Function() clock) async {
  final AppState app = AppState(
    clock: clock,
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
  );
  await app.init();
  return app;
}

Future<void> _finish(AppState app) async {
  for (var i = 0; i < 12 && !app.todayCompleted; i++) {
    await app.advance();
  }
}

/// Lets the sends the app does not wait for land.
Future<void> _land() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryStepSink sink;

  setUp(() {
    PillBank.reset();
    resetCalendar();
    sink = MemoryStepSink();
    FirstSteps.instance = FirstSteps()..sink = sink;
  });

  tearDown(() {
    FirstSteps.instance = FirstSteps();
    Analytics.useForTest(null);
  });

  List<String> sent() => [for (final (s, d) in sink.sent) '${s.wire} $d'];

  test('a new phone counts its four steps, each once, on the day each was '
      'taken', () async {
    DateTime now = DateTime(2026, 11, 28, 9);
    SharedPreferences.setMockInitialValues({});
    final AppState app = await _launch(() => now);
    await _land();
    expect(sent(), ['first_open 2026-11-28']);

    // Opened again the same day, before the first run is over: nothing.
    await _launch(() => now);
    await _land();
    expect(sent(), ['first_open 2026-11-28']);

    await app.setTopicMix({'space': 1, 'history': 1, 'science': 1});
    await app.completeOnboarding();
    await _finish(app);
    await _land();
    expect(sent(), [
      'first_open 2026-11-28',
      'first_run_done 2026-11-28',
      'first_day_done 2026-11-28',
    ]);

    // The next morning, in memory overnight: back the next day.
    now = DateTime(2026, 11, 29, 8);
    expect(await app.turnDayIfDue(), isTrue);
    await _land();
    // And a second day finished is no first day.
    await _finish(app);
    await _land();
    expect(sent(), [
      'first_open 2026-11-28',
      'first_run_done 2026-11-28',
      'first_day_done 2026-11-28',
      'next_day 2026-11-29',
    ]);

    // Opened again later that day, and the day after: nothing more.
    await _launch(() => now);
    now = DateTime(2026, 11, 30, 8);
    await _launch(() => now);
    await _land();
    expect(sink.sent, hasLength(4));
  });

  test('a return two days after the first open is not the next day', () async {
    DateTime now = DateTime(2026, 11, 28, 9);
    SharedPreferences.setMockInitialValues({});
    await _launch(() => now);
    now = DateTime(2026, 11, 30, 9);
    await _launch(() => now);
    await _land();
    expect(sent(), ['first_open 2026-11-28']);
  });

  test('a phone that had the app before counts nothing, ever', () async {
    DateTime now = DateTime(2026, 11, 28, 9);
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.installedOn': '2026-11-20',
      'knowit.completedDates': ['2026-11-20'],
    });
    final AppState app = await _launch(() => now);
    await _finish(app);
    now = DateTime(2026, 11, 29, 9);
    await app.turnDayIfDue();
    await _launch(() => now);
    await _land();
    expect(sink.sent, isEmpty);
    // Nor one that never finished its first run but installed days ago.
    SharedPreferences.setMockInitialValues({
      'knowit.installedOn': '2026-11-20',
    });
    FirstSteps.instance = FirstSteps()..sink = sink;
    await _launch(() => now);
    await _land();
    expect(sink.sent, isEmpty);
  });

  test('a step that could not be sent goes at the next launch, with the day '
      'it was taken', () async {
    DateTime now = DateTime(2026, 11, 28, 9);
    SharedPreferences.setMockInitialValues({});
    sink.failing = true;
    final AppState app = await _launch(() => now);
    await app.completeOnboarding();
    await _land();
    expect(sink.sent, isEmpty);

    sink.failing = false;
    now = DateTime(2026, 11, 29, 9);
    FirstSteps.instance = FirstSteps()..sink = sink;
    await _launch(() => now);
    await _land();
    expect(sent(), [
      'first_open 2026-11-28',
      'first_run_done 2026-11-28',
      'next_day 2026-11-29',
    ]);
  });

  test('a sign-out keeps what the phone counted: the first run again is not '
      'a new phone', () async {
    final DateTime now = DateTime(2026, 11, 28, 9);
    SharedPreferences.setMockInitialValues({});
    final AppState app = await _launch(() => now);
    await app.completeOnboarding();
    await _land();
    await app.signOut();
    expect(app.onboarded, isFalse);
    await app.completeOnboarding();
    FirstSteps.instance = FirstSteps()..sink = sink;
    await _launch(() => now);
    await _land();
    expect(sent(), ['first_open 2026-11-28', 'first_run_done 2026-11-28']);
  });

  group('only a phone the stores installed sends', () {
    for (final String channel in const ['app_store', 'play']) {
      test(channel, () async {
        final FirstSteps steps = FirstSteps();
        SharedPreferences.setMockInitialValues({});
        await steps.load(await SharedPreferences.getInstance());
        await steps.opened(
          onboarded: false,
          installedOn: '2026-11-28',
          today: DateTime(2026, 11, 28, 9),
        );
        await steps.start(Future.value(channel), sink);
        expect(sent(), ['first_open 2026-11-28']);
      });
    }
    for (final String channel in const [
      'debug',
      'testflight',
      'test_lab',
      'sideload',
      'web',
      'other',
    ]) {
      test('not $channel', () async {
        final FirstSteps steps = FirstSteps();
        SharedPreferences.setMockInitialValues({});
        await steps.load(await SharedPreferences.getInstance());
        await steps.start(Future.value(channel), sink);
        await steps.opened(
          onboarded: false,
          installedOn: '2026-11-28',
          today: DateTime(2026, 11, 28, 9),
        );
        expect(steps.sink, isNull);
        expect(sink.sent, isEmpty);
        // Noted all the same, so a phone that was never counted stays so.
        expect(steps.taken(FirstStep.firstOpen), isTrue);
      });
    }
  });

  test('what goes to the server is the step and the day, and nothing that '
      'says whose', () async {
    final List<http.Request> asked = [];
    final HttpStepSink out = HttpStepSink(
      client: MockClient((request) async {
        asked.add(request);
        return http.Response('', 204);
      }),
    );
    expect(await out.send(FirstStep.firstDayDone, '2026-11-28'), isTrue);
    final http.Request r = asked.single;
    expect(r.method, 'POST');
    expect(
      r.url.toString(),
      'https://europe-west1-astuto-3d398.cloudfunctions.net/countStep',
    );
    expect(jsonDecode(r.body), {'step': 'first_day_done', 'day': '2026-11-28'});
    // No account's token, no cookie, nothing of the phone: the one header
    // there is says what the body is.
    expect(r.headers.keys.map((k) => k.toLowerCase()).toSet(), {
      'content-type',
    });
  });

  test('a refusal is final; a server out of reach is tried again', () async {
    for (final (int status, bool done) in const [
      (204, true),
      (400, true),
      (405, true),
      (500, false),
      (503, false),
    ]) {
      final HttpStepSink out = HttpStepSink(
        client: MockClient((_) async => http.Response('', status)),
      );
      expect(
        await out.send(FirstStep.firstOpen, '2026-11-28'),
        done,
        reason: '$status',
      );
    }
    final HttpStepSink offline = HttpStepSink(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await offline.send(FirstStep.firstOpen, '2026-11-28'), isFalse);
  });

  test('the names are the server\'s four, and the privacy policy\'s', () {
    final List<String> wire = [for (final s in FirstStep.values) s.wire];
    expect(wire, ['first_open', 'first_run_done', 'first_day_done', 'next_day']);
    // The server's allow-list, read off its source: the same four, in the
    // same order.
    final String server = File('functions/src/steps.ts').readAsStringSync();
    final RegExpMatch? list = RegExp(
      r'export const STEPS = \[([^\]]*)\]',
    ).firstMatch(server);
    expect(list, isNotNull);
    expect(
      RegExp(r"'([a-z_]+)'").allMatches(list!.group(1)!).map((m) => m[1]),
      wire,
    );
    // And the policy names four, sent as the step and the date alone.
    expect(kFirstStepsPolicy['en'], contains('counts four steps'));
    expect(
      kFirstStepsPolicy['en'],
      contains('the name of the step and the date, and nothing else'),
    );
    expect(kFirstStepsPolicy['it'], contains('conta quattro passi'));
    expect(FirstSteps.counted, {'app_store', 'play'});
    expect(
      kFirstStepsPolicy['en'],
      contains('only an app installed from the App Store or Google Play'),
    );
  });
}
