// The update gate: a build the server no longer lets run asks for an update
// from its first frame, offline and before its state is read; a pause
// closes the app with a way to try again; a newer build is suggested once,
// at a quiet moment. And the build number everything is measured by.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/build_number.dart';
import 'package:astuto/remote/gate.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/gate_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/store_links.dart';
import 'package:astuto/theme.dart';

int _docs = 0;

/// A document whose app part is [app], under a hash of its own.
RemoteConfig _doc(Map<String, Object?> app) => RemoteConfig.parse(
  jsonEncode({
    'schema': 1,
    'hash': 'gate-${_docs++}',
    'app': app,
    'strings': <String, Object?>{},
    'explore': null,
    'looks': null,
  }),
);

void _take(Map<String, Object?> gate) => Remote.adopt(_doc({'gate': gate}));

RemoteContext _at({
  String platform = 'ios',
  int build = 7,
  String language = 'it',
  bool plus = false,
  int days = 3,
}) => RemoteContext(
  platform: platform,
  build: build,
  language: language,
  plus: plus,
  daysSinceInstall: days,
  now: DateTime(2026, 10, 20, 10),
);

/// What the app said, kept.
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

Future<void> _settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A part of the app with a memory, to tell a part kept alive from one
/// built again.
class _Counter extends StatefulWidget {
  const _Counter({required this.built});

  final List<String> built;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  void initState() {
    super.initState();
    widget.built.add('built');
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: Text(
      'app $taps closed=${GateKeeper.closes(context)}',
      key: const ValueKey('the-app'),
    ),
  );
}

/// The keeper as main.dart places it, over a stand-in for the app.
Widget _kept(AppState app, Widget child, {Locale locale = const Locale('it')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.light),
    home: const SizedBox.shrink(),
    builder: (context, _) => GateKeeper(app: app, child: child),
  );
}

void main() {
  late _Said said;
  late List<Uri> opened;

  setUp(() {
    Remote.reset();
    // The app asks the server as it starts: here nothing answers unless a
    // test says what does.
    Remote.fetch = (url) async => null;
    Remote.seedForTest = 'seed-gate';
    Remote.build = 0;
    UpdateGate.resetForTest();
    said = _Said();
    Analytics.useForTest(said);
    opened = [];
    openOutside = (uri) async {
      opened.add(uri);
      return true;
    };
  });

  tearDown(() {
    Remote.reset();
    Remote.build = 0;
    UpdateGate.resetForTest();
    Analytics.useForTest(null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('the verdict', () {
    test('no gate, or none of it for this phone, is the app as it is', () {
      expect(UpdateGate.verdict(_at()), GateVerdict.open);
      _take({
        'minBuild': {'android': 9},
      });
      expect(UpdateGate.verdict(_at(platform: 'ios')).kind, GateKind.open);
      expect(UpdateGate.verdict(_at(platform: 'web')).kind, GateKind.open);
    });

    test(
      'a build below the floor, or one named blocked, is sent to update',
      () {
        _take({
          'minBuild': {'ios': 7, 'android': 7},
          'blocked': [5, 9],
        });
        expect(UpdateGate.verdict(_at(build: 6)).kind, GateKind.update);
        expect(UpdateGate.verdict(_at(build: 6)).reason, 'min build');
        expect(UpdateGate.verdict(_at(build: 7)).kind, GateKind.open);
        expect(UpdateGate.verdict(_at(build: 9)).reason, 'blocked');
        expect(UpdateGate.verdict(_at(build: 10)).kind, GateKind.open);
        _take({
          'blocked': {
            'android': [7],
          },
        });
        expect(
          UpdateGate.verdict(_at(platform: 'android')).kind,
          GateKind.update,
        );
        expect(UpdateGate.verdict(_at(platform: 'ios')).kind, GateKind.open);
      },
    );

    test('a phone whose build did not read is never sent to the store', () {
      _take({
        'minBuild': {'ios': 7},
        'blocked': [0],
      });
      expect(UpdateGate.verdict(_at(build: 0)).kind, GateKind.open);
    });

    test('a part written wrong is passed over, and the rest still holds', () {
      _take({
        'minBuild': {'ios': '9'},
        'blocked': [7],
      });
      expect(UpdateGate.verdict(_at(build: 7)).reason, 'blocked');
      _take({
        'minBuild': 'everyone',
        'pause': {'on': 'yes'},
      });
      expect(UpdateGate.verdict(_at()).kind, GateKind.open);
    });

    test('a pause for its audience, decided once the state that aims it is '
        'known', () {
      _take({
        'pause': {
          'on': true,
          'audience': {
            'platforms': ['android'],
          },
        },
      });
      expect(UpdateGate.verdict(_at(platform: 'android')).kind, GateKind.pause);
      expect(UpdateGate.verdict(_at(platform: 'ios')).kind, GateKind.open);
      // Before the state is read: a rule that does not ask about it holds
      // from the first frame.
      expect(
        UpdateGate.verdict(_at(platform: 'android'), stateKnown: false).kind,
        GateKind.pause,
      );
      _take({
        'pause': {
          'on': true,
          'audience': {
            'any': [
              {'plus': false},
            ],
          },
        },
      });
      expect(
        UpdateGate.verdict(_at(plus: true), stateKnown: false).kind,
        GateKind.open,
      );
      expect(UpdateGate.verdict(_at(plus: true)).kind, GateKind.open);
      expect(UpdateGate.verdict(_at()).kind, GateKind.pause);
      _take({
        'pause': {'on': false},
      });
      expect(UpdateGate.verdict(_at()).kind, GateKind.open);
    });

    test('an update goes before a pause: it is the one the reader can do', () {
      _take({
        'minBuild': {'ios': 8},
        'pause': {'on': true},
      });
      expect(UpdateGate.verdict(_at(build: 7)).kind, GateKind.update);
      expect(UpdateGate.verdict(_at(build: 8)).kind, GateKind.pause);
    });

    test('the server\'s own words, in the reader\'s language only', () {
      _take({
        'pause': {'on': true},
        'message': {
          'pause': {'it': ' Torniamo entro un\'ora. ', 'en': 'Back soon.'},
          'hard': {'it': 3},
        },
      });
      expect(UpdateGate.verdict(_at()).message, 'Torniamo entro un\'ora.');
      expect(UpdateGate.verdict(_at(language: 'de')).message, isNull);
      expect(UpdateGate.message('hard', 'it'), isNull);
    });
  });

  group('the suggestion', () {
    test('a newer build, once for each build suggested', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      UpdateGate.restore(prefs);
      _take({
        'suggestBuild': {'ios': 8},
      });
      expect(UpdateGate.suggestion(_at(build: 7)), 8);
      expect(UpdateGate.suggestion(_at(build: 8)), isNull);
      expect(UpdateGate.suggestion(_at(build: 0)), isNull);
      expect(UpdateGate.suggestion(_at(platform: 'android')), isNull);
      await UpdateGate.noteSuggested(8);
      expect(UpdateGate.suggestion(_at(build: 7)), isNull);
      expect(prefs.getInt('knowit.updateSuggested'), 8);
      // Kept across launches.
      UpdateGate.resetForTest();
      UpdateGate.restore(prefs);
      expect(UpdateGate.suggestion(_at(build: 7)), isNull);
      // A build newer still is worth saying again.
      _take({
        'suggestBuild': {'ios': 9},
      });
      expect(UpdateGate.suggestion(_at(build: 7)), 9);
    });

    test('never while the gate is closed', () {
      _take({
        'suggestBuild': {'ios': 9},
        'pause': {'on': true},
      });
      expect(UpdateGate.suggestion(_at(build: 7)), isNull);
    });
  });

  group('the build number', () {
    test('read from the platform, and 0 for anything it cannot say', () async {
      expect(await readBuildNumber(read: () async => '42'), 42);
      expect(await readBuildNumber(read: () async => ' 7\n'), 7);
      for (final String raw in ['', '1.0.0', '-3', '0']) {
        expect(await readBuildNumber(read: () async => raw), 0, reason: raw);
      }
      expect(
        await readBuildNumber(read: () async => throw StateError('no plugin')),
        0,
      );
      expect(
        await readBuildNumber(
          read: () => Completer<String>().future,
          wait: const Duration(milliseconds: 20),
        ),
        0,
      );
    });
  });

  group('the keeper', () {
    testWidgets('a gate closed from the launch keeps the app from being built '
        'at all, before the state is read', (tester) async {
      Remote.build = 6;
      _take({
        'minBuild': {'android': 7},
      });
      final built = <String>[];
      await tester.pumpWidget(_kept(AppState(), _Counter(built: built)));
      await _settle(tester);
      expect(built, isEmpty);
      expect(find.byType(GateScreen), findsOneWidget);
      expect(find.text('Aggiorna Astute'), findsOneWidget);
      expect(find.textContaining('su Google Play'), findsOneWidget);
      expect(said.of('update gate shown').single, {
        'kind': 'update',
        'reason': 'min build',
        'build': 6,
        'platform': 'android',
        'at_launch': true,
        'own_words': false,
        'remote_hash': Remote.config.hash,
      });

      await tester.tap(find.byKey(const ValueKey('gate-update')));
      await _settle(tester, frames: 2);
      expect(opened, [Uri.parse(kGooglePlayUrl)]);
      expect(said.of('update store opened').single['from'], 'gate');
    });

    testWidgets('the store is the App Store on an iPhone, in the server\'s '
        'words when it sent some', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      Remote.build = 3;
      _take({
        'blocked': [3],
        'message': {
          'hard': {
            'en': 'Build 3 lost a day of reading: the new one keeps it.',
          },
        },
      });
      await tester.pumpWidget(
        _kept(AppState(), const SizedBox(), locale: const Locale('en')),
      );
      await _settle(tester);
      expect(find.text('Update Astute'), findsOneWidget);
      expect(
        find.text('Build 3 lost a day of reading: the new one keeps it.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('gate-update')));
      await _settle(tester, frames: 2);
      expect(opened, [Uri.parse(kAppStoreUrl)]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a gate closing over a running app keeps it alive underneath, '
        'and tells it so', (tester) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final AppState app = AppState();
      await app.init();
      Remote.build = 6;
      final built = <String>[];
      await tester.pumpWidget(_kept(app, _Counter(built: built)));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('the-app')));
      await tester.pump();
      expect(find.text('app 1 closed=false'), findsOneWidget);

      _take({
        'minBuild': {'android': 7},
      });
      await tester.pumpWidget(_kept(app, _Counter(built: built)));
      await _settle(tester);
      expect(find.byType(GateScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('the-app')), findsNothing);
      expect(
        find.text('app 1 closed=true', skipOffstage: false),
        findsOneWidget,
      );
      expect(said.of('update gate shown').single['at_launch'], isFalse);

      _take({});
      await tester.pumpWidget(_kept(app, _Counter(built: built)));
      await _settle(tester);
      expect(find.byType(GateScreen), findsNothing);
      expect(find.text('app 1 closed=false'), findsOneWidget);
      expect(built, ['built'], reason: 'built once, kept through the gate');
    });

    testWidgets('a pause tries again, says when it is still on, and lifts '
        'when the server lifts it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      _take({
        'pause': {'on': true},
      });
      final String paused = Remote.config.hash;
      String note = paused;
      final asked = <String>[];
      Remote.fetch = (url) async {
        asked.add(url);
        if (url == kRemoteVersionUrl) return '{"schema": 1, "hash": "$note"}';
        return jsonEncode({
          'schema': 1,
          'hash': note,
          'app': {'gate': null},
          'strings': <String, Object?>{},
          'explore': null,
          'looks': null,
        });
      };
      final built = <String>[];
      await tester.pumpWidget(
        _kept(AppState(), _Counter(built: built), locale: const Locale('en')),
      );
      await _settle(tester);
      expect(find.text('Astute is taking a short break'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(
        find.text('Still on a break. Try again in a few minutes.'),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('gate-retry')));
      await _settle(tester, frames: 4);
      expect(asked, [kRemoteVersionUrl]);
      expect(
        find.text('Still on a break. Try again in a few minutes.'),
        findsOneWidget,
      );
      expect(said.of('pause retried').single, {
        'still_paused': true,
        'took_newer': false,
      });
      expect(built, isEmpty);

      note = 'lifted';
      await tester.tap(find.byKey(const ValueKey('gate-retry')));
      await _settle(tester, frames: 4);
      // The app's root redraws on a newer document (main.dart); this stand-in
      // is drawn again by hand.
      await tester.pumpWidget(
        _kept(AppState(), _Counter(built: built), locale: const Locale('en')),
      );
      await _settle(tester);
      expect(Remote.config.hash, 'lifted');
      expect(find.byType(GateScreen), findsNothing);
      expect(built, ['built']);
    });
  });

  group('in the app', () {
    void noWidgets(WidgetTester tester) {
      const channel = MethodChannel('astut/widget');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'installed' ? const <Object?>[] : null,
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }

    setUp(() {
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
    });

    testWidgets('a build the server no longer lets run shows nothing of '
        'itself', (tester) async {
      noWidgets(tester);
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      Remote.build = 4;
      _take({
        'minBuild': {'android': 5},
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      expect(find.byType(GateScreen), findsOneWidget);
      expect(find.byType(AstutoRoot, skipOffstage: false), findsNothing);
    });

    testWidgets('a newer build is suggested once, at a quiet moment, and '
        'nothing else is asked in its sitting', (tester) async {
      noWidgets(tester);
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final prefs = await SharedPreferences.getInstance();
      UpdateGate.restore(prefs);
      Remote.build = 7;
      _take({
        'suggestBuild': {'android': 8},
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester, frames: 30);
      expect(find.byType(UpdateSheet), findsOneWidget);
      expect(find.text('A new version of Astute is ready'), findsOneWidget);
      expect(said.of('update suggested').single, {
        'build': 7,
        'suggested_build': 8,
      });

      await tester.tap(find.byKey(const ValueKey('update-later')));
      await _settle(tester);
      expect(find.byType(UpdateSheet), findsNothing);
      expect(said.of('update suggestion answered').single['choice'], 'later');
      expect(opened, isEmpty);
      expect(prefs.getInt('knowit.updateSuggested'), 8);

      // Not again for that build, at the next launch either.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester, frames: 30);
      expect(find.byType(UpdateSheet), findsNothing);
    });

    testWidgets('Update opens the store', (tester) async {
      noWidgets(tester);
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      UpdateGate.restore(await SharedPreferences.getInstance());
      Remote.build = 7;
      _take({
        'suggestBuild': {'android': 8},
        'message': {
          'soft': {'en': 'This one reads the cards aloud.'},
        },
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester, frames: 30);
      expect(find.text('This one reads the cards aloud.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('update-yes')));
      await _settle(tester);
      expect(opened, [Uri.parse(kGooglePlayUrl)]);
      expect(said.of('update store opened').single['from'], 'sheet');
    });
  });
}
