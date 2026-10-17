// Where a reader lives, asked the app's way: a sheet of its own after the
// second finished day, the system's prompt only after a yes on it, a place
// read and named on the phone with nothing finer than a city kept — backed
// up, read again once a week, removable — and never a coordinate in what
// the app measures.
//
//   flutter test test/place_capture_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show DebugPrintCallback;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as pi;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/legal.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/place.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/sync/place_finder.dart';
import 'package:astuto/sync/place_finder_native.dart';
import 'package:astuto/sync/place_finder_web.dart';
import 'package:astuto/sync/push.dart';
import 'package:astuto/sync/reader_snapshot.dart';
import 'package:astuto/sync/reader_store.dart';
import 'package:astuto/sync/trace.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/place_ask.dart';

/// Where the phone is, as precisely as a phone says it: the Ghirlandina's
/// own square, to five decimals.
const double _lat = 44.64712;
const double _lon = 10.92541;

/// Stands in for the phone: what the system holds, what its prompt is
/// answered, and the place it names — from a raw position, through
/// Place.fromPhone, as the one on a phone does.
class _Phone implements PlaceFinder {
  _Phone();

  bool asks = true;

  /// The permission as the system holds it now.
  LocationAccess system = LocationAccess.notAsked;

  /// What the reader answers the system's prompt.
  LocationAccess answer = LocationAccess.granted;

  bool? isPrecise = true;

  double lat = _lat;
  double lon = _lon;
  String city = 'Modena';
  String region = 'Emilia-Romagna';

  /// No fix, or no name for it.
  bool fails = false;

  /// Holds a read until it completes, for what happens meanwhile.
  Completer<void>? hold;

  int checks = 0;
  int prompts = 0;
  int finds = 0;
  int settings = 0;

  @override
  bool get canAsk => asks;

  @override
  Future<LocationAccess> access() async {
    checks++;
    return system;
  }

  @override
  Future<LocationAccess> ask() async {
    if (system != LocationAccess.notAsked) return system;
    prompts++;
    // A no on Android can be asked again; iOS says its no is final.
    system = answer == LocationAccess.denied ? LocationAccess.notAsked : answer;
    return answer;
  }

  @override
  Future<bool?> precise() async => isPrecise;

  @override
  Future<Place?> find() async {
    finds++;
    await hold?.future;
    if (fails) return null;
    return Place.fromPhone(
      isoCountry: 'it',
      adminArea: region,
      locality: city,
      lat: lat,
      lon: lon,
      at: DateTime.now(),
    );
  }

  @override
  Future<bool> openSettings() async {
    settings++;
    return true;
  }
}

/// What the app said to measurement, kept, so a test can read it back:
/// every event, every write to the profile, every property stamped.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];
  final List<(Map<String, Object>, Map<String, Object>)> writes = [];
  final Map<String, Object> registered = {};
  final List<Map<String, Object>> identified = [];

  Iterable<Map<String, Object>> of(String event) =>
      events.where((e) => e.$1 == event).map((e) => e.$2);

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async =>
      identified.add(properties);

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async =>
      registered[key] = value;

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async => writes.add((Map.of(set), Map.of(setOnce)));

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

/// Stands in for the system's notification prompt, as the reminder's tests
/// do: it can be asked, and says yes.
class _Asker extends Push {
  @override
  bool get canAsk => true;

  @override
  Future<String?> ask() async => 'token-a';

  @override
  Future<String?> refresh() async => null;
}

final Finder _sheet = find.byKey(const ValueKey('place-ask'));
final Finder _reminderSheet = find.byKey(const ValueKey('reminder-ask'));

String _key(DateTime d) => dateKey(d);

DateTime _day(int offset) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day + offset);
}

/// An install past the first run, on the free plan, that has answered the
/// question about notifications and been asked for its stars: the evening is
/// the place sheet's own.
Map<String, Object> _installed() => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  'knowit.pushAsked': true,
  'knowit.reviewAsked': true,
};

/// [days] finished days, the last of them today, with today's five read: the
/// app opens on the finished day, at rest.
Map<String, Object> _finished(int days) => {
  'knowit.todayDate': _key(DateTime.now()),
  'knowit.todayDeckIds': dealDay(date: DateTime.now()).cards
      .map((p) => p.id)
      .toList(),
  'knowit.todayIndex': 5,
  'knowit.streak': days,
  'knowit.lastCompletionDate': _key(DateTime.now()),
  'knowit.completedDates': [for (var i = days - 1; i >= 0; i--) _key(_day(-i))],
};

Place _modena({DateTime? at}) => Place.fromPhone(
  isoCountry: 'IT',
  adminArea: 'Emilia-Romagna',
  locality: 'Modena',
  lat: _lat,
  lon: _lon,
  at: at ?? DateTime.utc(2026, 10, 1, 9),
);

Place _milan({DateTime? at}) => Place.fromPhone(
  isoCountry: 'IT',
  adminArea: 'Lombardy',
  locality: 'Milan',
  lat: 45.46427,
  lon: 9.18951,
  at: at ?? DateTime.utc(2026, 9, 1, 9),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
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

/// Out of the app and back, as the phone walks it: a sitting ends, and a new
/// one begins.
void _background(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void _foreground(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

AppState _appOf(WidgetTester tester) => tester
    .widget<AstutoShell>(find.byType(AstutoShell, skipOffstage: false))
    .app;

/// A screen to put [child] on, in [locale].
Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(body: child),
);

/// Profile, rebuilt whenever the state moves, as the app rebuilds it; on a
/// screen tall enough that its whole list is laid out.
Widget _profile(AppState app) => _host(
  ListenableBuilder(
    listenable: app,
    builder: (context, _) => ProfileScreen(
      app: app,
      account: Account(uidOverride: 'me', boardsOverride: MemoryBoardStore()),
      onSignedOut: () {},
    ),
  ),
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(402, 2600) * 3;
  tester.view.devicePixelRatio = 3;
}

/// A button that opens the sheet the way Explore's shelf does.
Widget _shelf(AppState app, {String from = 'explore'}) => _host(
  Builder(
    builder: (context) => Center(
      child: TextButton(
        key: const ValueKey('switch-it-on'),
        onPressed: () => askForPlace(context, app, from: from),
        child: const Text('Switch it on'),
      ),
    ),
  ),
);

/// An app past its launch, from [prefs]: what the launch set going — the
/// weekly read — has run. Under a widget test the clock is the tester's,
/// which runs no timer by itself, so it is pumped instead.
Future<AppState> _state(
  Map<String, Object> prefs, {
  WidgetTester? tester,
}) async {
  SharedPreferences.setMockInitialValues({..._installed(), ...prefs});
  final AppState app = AppState();
  await app.init();
  if (tester == null) {
    await pumpEventQueue();
  } else {
    await tester.pump();
  }
  return app;
}

/// Every key and every value in [sent], however deep.
Iterable<Object?> _everything(Object? sent) sync* {
  yield sent;
  if (sent is Map) {
    for (final MapEntry<Object?, Object?> e in sent.entries) {
      yield e.key;
      yield* _everything(e.value);
    }
  } else if (sent is Iterable) {
    for (final Object? v in sent) {
      yield* _everything(v);
    }
  }
}

/// Fails if anything in [sent] is a coordinate, or names one: a field
/// called lat or lon by any spelling, the phone's raw position, or the
/// point as the backup keeps it, rounded.
void _noPoint(Object? sent, {required String where}) {
  const Set<String> names = {'lat', 'lon', 'lng', 'latitude', 'longitude'};
  const List<double> points = [_lat, _lon, 44.6, 10.9];
  for (final Object? v in _everything(sent)) {
    if (v is String) {
      expect(names.contains(v.toLowerCase()), isFalse, reason: '$where: $v');
      expect(v, isNot(contains('44.6')), reason: where);
      expect(v, isNot(contains('10.9')), reason: where);
    } else if (v is num) {
      for (final double point in points) {
        expect((v - point).abs() < 1e-9, isFalse, reason: '$where: $v');
      }
    }
  }
}

void main() {
  late _Phone phone;
  late _Said said;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    phone = _Phone();
    PlaceFinder.useForTest(phone);
    said = _Said();
    Analytics.useForTest(said);
    // A trace of its own, with nowhere to write: what it keeps stays in
    // memory to be read back, and no timer is left behind.
    Trace.useForTest(Trace());
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    PlaceFinder.useForTest(null);
    Analytics.useForTest(null);
    Push.useForTest(Push());
    Trace.useForTest(Trace());
  });

  group('when the sheet comes', () {
    testWidgets('after the second finished day — not over the card after the '
        'fifth, nor over the paywall it opens; once it is thrown, the sheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        'knowit.streak': 1,
        'knowit.lastCompletionDate': _key(_day(-1)),
        'knowit.completedDates': [_key(_day(-1))],
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      for (var i = 0; i < 5; i++) {
        await _throw(tester);
      }
      expect(_appOf(tester).completedDates, hasLength(2));
      expect(find.byKey(const ValueKey('magic-card')), findsOneWidget);
      await _wait(tester);
      expect(_sheet, findsNothing, reason: 'the sixth card is on the table');

      await tester.tap(find.text('Try 14 days free'));
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsOneWidget);
      await _wait(tester);
      expect(_sheet, findsNothing, reason: 'never over a paywall');
      await tester.tap(
        find.descendant(
          of: find.byType(PaywallScreen),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await _wait(tester);
      expect(_sheet, findsNothing, reason: 'the card is back on the table');

      await _throw(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text('Cards about where you live'), findsOneWidget);
      expect(find.text('Near you · Modena'), findsOneWidget);
      expect(find.text('The Ghirlandina leans. By how much?'), findsOneWidget);
      expect(
        find.text('Only your city is kept, never your exact position.'),
        findsOneWidget,
      );
      expect(find.text('Use my location'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(said.of('place asked'), [
        {'from': 'day done', 'nth': 1},
      ]);
      expect(phone.prompts, 0, reason: 'nothing of the system\'s is asked');
    });

    testWidgets('never after the first', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(1),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester, seconds: 6);
      expect(_sheet, findsNothing);
      expect(_appOf(tester).shouldAskForPlace, isFalse);
    });

    testWidgets('not in the sitting the reminder sheet was put in, but in the '
        'next', (tester) async {
      Push.useForTest(_Asker());
      // The reminder's "Not now" was said yesterday: it is due again
      // tonight, on the same evening the place sheet is first due.
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.plus': false,
        'knowit.reviewAsked': true,
        ..._finished(2),
        'knowit.pushDeferrals': 1,
        'knowit.pushDeferredAfter': _key(_day(-1)),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      expect(_reminderSheet, findsOneWidget, reason: 'the reminder goes first');
      expect(_sheet, findsNothing);
      await tester.tap(find.byKey(const ValueKey('reminder-not-now')));
      await _settle(tester);
      await _wait(tester, seconds: 6);
      expect(_sheet, findsNothing, reason: 'one question a sitting');

      _background(tester);
      await _settle(tester);
      _foreground(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(_reminderSheet, findsNothing);
    });

    testWidgets('not in the sitting the system\'s prompt was put in', (
      tester,
    ) async {
      // A build whose reminder has no sheet of its own asks the system
      // straight away, on the evening the place sheet is due.
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.plus': false,
        'knowit.reviewAsked': true,
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester, seconds: 6);
      expect(said.of('push permission asked'), hasLength(1));
      expect(_sheet, findsNothing);

      // The next sitting, here the next launch: the prompt's own flow goes
      // on to re-arm the reminders, and on this test's clock the
      // notification centre it asks never answers, so the app that put the
      // prompt is still busy with it. A sitting after a pause is the
      // reminder test's above.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(said.of('push permission asked'), hasLength(1));
    });

    testWidgets('"Not now" spends nothing, waits for the seventh day, asks '
        'once more, and then never', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('place-not-now')));
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(phone.prompts, 0);
      expect(phone.finds, 0);
      expect(said.of('place answered'), [
        {'choice': 'not_now'},
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('knowit.placeAsks'), 1);
      expect(
        prefs.getString('knowit.placeDeferredAfter'),
        _key(DateTime.now()),
      );
      expect(prefs.getString('knowit.locationPermission'), isNull);
      expect(_appOf(tester).place, isNull);
      await _wait(tester, seconds: 6);
      expect(_sheet, findsNothing, reason: 'not again tonight');

      // The seventh finished day, a few days after "Not now": once more.
      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(7),
        'knowit.placeAsks': 1,
        'knowit.placeDeferredAfter': _key(_day(-3)),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      expect(_sheet, findsOneWidget);
      expect(said.of('place asked').last, {'from': 'day done', 'nth': 2});
      await tester.tap(find.byKey(const ValueKey('place-not-now')));
      await _settle(tester);

      // And that was the last time it asked of its own accord.
      expect(_appOf(tester).shouldAskForPlace, isFalse);
      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(9),
        'knowit.placeAsks': 2,
        'knowit.placeDeferredAfter': _key(_day(-1)),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester, seconds: 6);
      expect(_sheet, findsNothing);
    });

    test('the schedule, day by day', () async {
      final String today = _key(DateTime.now());
      final String yesterday = _key(_day(-1));
      Future<bool> due(Map<String, Object> prefs) async =>
          (await _state(prefs)).shouldAskForPlace;

      expect(await due(_finished(1)), isFalse, reason: 'one day');
      expect(await due(_finished(2)), isTrue, reason: 'two days');
      expect(await due(_finished(30)), isTrue, reason: 'never asked yet');
      // "Not now" once: the seventh day, and a day finished since.
      final Map<String, Object> once = {
        'knowit.placeAsks': 1,
        'knowit.placeDeferredAfter': yesterday,
      };
      expect(await due({..._finished(6), ...once}), isFalse);
      expect(await due({..._finished(7), ...once}), isTrue);
      expect(
        await due({
          ..._finished(9),
          'knowit.placeAsks': 1,
          'knowit.placeDeferredAfter': today,
        }),
        isFalse,
        reason: 'said today: not until another day is finished',
      );
      expect(
        await due({..._finished(9), 'knowit.placeAsks': 2}),
        isFalse,
        reason: 'twice is all',
      );
      // Anyone who has answered the system, removed the place, or keeps one
      // is not asked by the sheet at all: Profile has the switch.
      for (final String word in ['granted', 'denied', 'off']) {
        expect(
          await due({..._finished(3), 'knowit.locationPermission': word}),
          isFalse,
          reason: word,
        );
      }
      expect(
        await due({
          ..._finished(3),
          'knowit.place': jsonEncode(_modena().toJson()),
        }),
        isFalse,
      );
    });

    testWidgets('not on a phone that has nothing to read, nor where the '
        'system will no longer ask', (tester) async {
      phone.asks = false;
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester, seconds: 4);
      expect(_sheet, findsNothing);
      expect(phone.checks, 0);

      // The system refused before anyone asked (the reader switched it off
      // in the phone's settings): the evening's sheet would lead nowhere,
      // and nothing is pushed at them instead.
      await tester.pumpWidget(const SizedBox());
      phone
        ..asks = true
        ..system = LocationAccess.deniedForever;
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester, seconds: 4);
      expect(_sheet, findsNothing);
      expect(find.byKey(const ValueKey('place-settings')), findsNothing);
      expect(said.of('place asked'), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.locationPermission'), isNull);
    });
  });

  group('the answers', () {
    testWidgets('yes: the system is asked, the place is read, and only the '
        'city and a rounded point are kept', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      await tester.tap(find.byKey(const ValueKey('place-yes')));
      await _settle(tester);

      expect(_sheet, findsNothing);
      expect(phone.prompts, 1);
      expect(phone.finds, 1);
      final AppState app = _appOf(tester);
      expect(app.locationPermission, 'granted');
      expect(app.place!.city, 'Modena');
      expect(app.place!.region, 'IT-45');
      expect(app.place!.lat, 44.6);
      expect(app.place!.lon, 10.9);
      expect(said.of('place answered'), [
        {'choice': 'yes'},
      ]);
      expect(said.of('location permission answered'), [
        {'granted': true, 'precise': true},
      ]);
      expect(said.of('place set'), [
        {
          'country': 'IT',
          'region': 'IT-45',
          'city': 'Modena',
          'changed': true,
          'from': 'day done',
        },
      ]);
      expect(find.text('Where you live: Modena'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.locationPermission'), 'granted');
      expect(jsonDecode(prefs.getString('knowit.place')!), {
        'country': 'IT',
        'region': 'IT-45',
        'regionName': 'Emilia-Romagna',
        'city': 'Modena',
        'lat': 44.6,
        'lon': 10.9,
        'at': isA<String>(),
      });
      // Asked is asked.
      expect(app.shouldAskForPlace, isFalse);
    });

    testWidgets('no to the system: taken as said, and Profile named', (
      tester,
    ) async {
      phone.answer = LocationAccess.denied;
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      await tester.tap(find.byKey(const ValueKey('place-yes')));
      await _settle(tester);

      final AppState app = _appOf(tester);
      expect(phone.prompts, 1);
      expect(phone.finds, 0);
      expect(app.place, isNull);
      expect(app.locationPermission, 'denied');
      expect(said.of('location permission answered'), [
        {'granted': false},
      ]);
      expect(said.of('place set'), isEmpty);
      expect(
        find.text(
          'No problem. You can switch it on in Profile whenever you like.',
        ),
        findsOneWidget,
      );
      expect(app.shouldAskForPlace, isFalse);
    });

    testWidgets('a final no, as iOS gives it, is not answered with the '
        'phone\'s settings', (tester) async {
      phone.answer = LocationAccess.deniedForever;
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      await tester.tap(find.byKey(const ValueKey('place-yes')));
      await _settle(tester);

      expect(_appOf(tester).locationPermission, 'denied');
      expect(find.byKey(const ValueKey('place-settings')), findsNothing);
      expect(phone.settings, 0);
      expect(
        find.text(
          'No problem. You can switch it on in Profile whenever you like.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('denied for good, then asked for from Profile: the phone\'s '
        'settings, and the place once it is allowed there', (tester) async {
      phone.system = LocationAccess.deniedForever;
      final AppState app = await _state({
        ..._finished(3),
        'knowit.locationPermission': 'denied',
      }, tester: tester);
      _tall(tester);
      await tester.pumpWidget(_profile(app));
      await _settle(tester);
      // Off, as the row's value: what switching it on means is the sheet's
      // to say.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('place-row')),
          matching: find.text('Off'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('place-row')));
      await _settle(tester);
      expect(_sheet, findsNothing, reason: 'a sheet that leads nowhere');
      expect(find.byKey(const ValueKey('place-settings')), findsOneWidget);
      expect(find.text('Location is off for Astute'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('place-open-settings')));
      await _settle(tester);
      expect(phone.settings, 1);
      expect(phone.prompts, 0);
      expect(app.locationPermission, 'denied');

      // Allowed there, and back: the place is read on the way in.
      phone.system = LocationAccess.granted;
      await app.refreshPlaceIfDue();
      expect(app.locationPermission, 'granted');
      expect(app.place!.city, 'Modena');
      expect(said.of('place set').single['from'], 'settings');
      await _settle(tester);
      expect(find.text('Modena'), findsOneWidget);
    });

    testWidgets('from Explore\'s shelf, the same sheet, said as from there', (
      tester,
    ) async {
      final AppState app = await _state(_finished(1), tester: tester);
      await tester.pumpWidget(_shelf(app));
      await tester.tap(find.byKey(const ValueKey('switch-it-on')));
      await _settle(tester);
      expect(_sheet, findsOneWidget);
      expect(said.of('place asked').single, {'from': 'explore', 'nth': 1});
      await tester.tap(find.byKey(const ValueKey('place-yes')));
      await _settle(tester);
      expect(app.place!.city, 'Modena');
      expect(said.of('place set').single['from'], 'explore');
    });

    testWidgets('a phone that could not say where it is: nothing kept, and '
        'a word that it will try again', (tester) async {
      phone.fails = true;
      final AppState app = await _state(_finished(1), tester: tester);
      await tester.pumpWidget(_shelf(app));
      await tester.tap(find.byKey(const ValueKey('switch-it-on')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('place-yes')));
      await _settle(tester);
      expect(app.place, isNull);
      expect(app.locationPermission, 'granted');
      expect(app.placeCheckedAt, isNotNull);
      expect(said.of('place set'), isEmpty);
      expect(
        find.text(
          'Couldn’t find where you are just now. Astute will try again '
          'another day.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('where nothing can be read, it says so and asks nothing', (
      tester,
    ) async {
      final AppState app = await _state(_finished(1), tester: tester);
      PlaceFinder.useForTest(const WebPlaceFinder());
      await tester.pumpWidget(_shelf(app));
      await tester.tap(find.byKey(const ValueKey('switch-it-on')));
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(find.text('This device can’t say where you are.'), findsOneWidget);
      expect(said.of('place asked'), isEmpty);

      // And with location switched off for the whole phone.
      PlaceFinder.useForTest(phone..system = LocationAccess.unavailable);
      await tester.tap(find.byKey(const ValueKey('switch-it-on')));
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(
        find.text(
          'Location is off on this phone. Switch it on in Settings, then '
          'try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('kept, backed up, and taken back', () {
    test('a place set survives a restart', () async {
      final AppState app = await _state(const {});
      await app.notedLocationPermission(AppState.kLocationGranted);
      await app.setPlace(_modena(), from: 'profile');

      // Nothing to read at the second launch, so what comes back is only
      // what was kept.
      phone.asks = false;
      final AppState again = AppState();
      await again.init();
      expect(again.place!.samePlaceAs(_modena()), isTrue);
      expect(again.place!.lat, 44.6);
      expect(again.place!.lon, 10.9);
      expect(again.place!.at, _modena().at);
      expect(again.locationPermission, 'granted');
    });

    test('travels with the backup, as the server reads it, and through '
        'JSON', () async {
      final AppState app = await _state(const {});
      await app.setPlace(_modena(), from: 'profile');
      final MemoryReaderStore readers = MemoryReaderStore();
      final Account account = Account(
        uidOverride: 'u1',
        storeOverride: readers,
        boardsOverride: MemoryBoardStore(),
      );
      await account.push(app);

      final Map<String, dynamic> doc = (await readers.read('u1'))!.toJson();
      expect(doc['place'], {
        'country': 'IT',
        'region': 'IT-45',
        'regionName': 'Emilia-Romagna',
        'city': 'Modena',
        'lat': 44.6,
        'lon': 10.9,
        'at': '2026-10-01T09:00:00.000Z',
      });
      final ReaderSnapshot back = ReaderSnapshot.fromJson(
        jsonDecode(jsonEncode(doc)) as Map<String, dynamic>,
      );
      expect(back.place!.samePlaceAs(_modena()), isTrue);
      expect(back.place!.at, _modena().at);

      // Removed: the next write leaves no place in the document at all —
      // a write replaces the whole of it — and says when it went.
      await app.clearPlace();
      await account.push(app);
      final Map<String, dynamic> after = (await readers.read('u1'))!.toJson();
      expect(after.containsKey('place'), isFalse);
      expect(after['placeRemovedAt'], isA<String>());
    });

    test('a new phone brings it back from the account', () async {
      final MemoryReaderStore readers = MemoryReaderStore({
        'u1': ReaderSnapshot(
          completedDates: [_key(_day(-1))],
          place: _modena(),
        ),
      });
      final AppState app = await _state(const {});
      await Account(
        uidOverride: 'u1',
        storeOverride: readers,
        boardsOverride: MemoryBoardStore(),
      ).foldInto(app, 'u1');
      expect(app.place!.city, 'Modena');
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('knowit.place')!)['city'], 'Modena');
      // This phone was never asked, and is not asked now: the reader said
      // where they live on the other one.
      expect(app.locationPermission, 'not_asked');
      expect(app.shouldAskForPlace, isFalse);
    });

    test('two phones: the newer word wins, a removal included', () {
      final Place older = _milan(at: DateTime.utc(2026, 9, 1));
      final Place newer = _modena(at: DateTime.utc(2026, 10, 1));
      String? city(ReaderSnapshot local, ReaderSnapshot remote) =>
          mergeSnapshots(local, remote).place?.city;

      expect(
        city(ReaderSnapshot(place: older), ReaderSnapshot(place: newer)),
        'Modena',
      );
      expect(
        city(ReaderSnapshot(place: newer), ReaderSnapshot(place: older)),
        'Modena',
      );
      expect(
        city(const ReaderSnapshot(), ReaderSnapshot(place: older)),
        'Milan',
      );
      expect(
        city(ReaderSnapshot(place: older), const ReaderSnapshot()),
        'Milan',
      );
      expect(city(const ReaderSnapshot(), const ReaderSnapshot()), isNull);

      // Removed on one phone after the other last read it: removed.
      final ReaderSnapshot removed = ReaderSnapshot(
        placeRemovedAt: DateTime.utc(2026, 10, 5),
      );
      for (final ReaderSnapshot merged in [
        mergeSnapshots(removed, ReaderSnapshot(place: newer)),
        mergeSnapshots(ReaderSnapshot(place: newer), removed),
      ]) {
        expect(merged.place, isNull);
        expect(merged.placeRemovedAt, DateTime.utc(2026, 10, 5));
        final Map<String, dynamic> json = merged.toJson();
        expect(json.containsKey('place'), isFalse);
        expect(ReaderSnapshot.fromJson(json).placeRemovedAt, isNotNull);
      }
      // Set again after the removal: set.
      final ReaderSnapshot early = ReaderSnapshot(
        placeRemovedAt: DateTime.utc(2026, 9, 15),
      );
      expect(city(early, ReaderSnapshot(place: newer)), 'Modena');
      expect(
        mergeSnapshots(early, ReaderSnapshot(place: newer)).placeRemovedAt,
        isNull,
      );
    });

    test('a removal adopted from the account stops this phone reading; a '
        'place set since undoes this phone\'s removal', () async {
      final AppState reading = await _state({
        'knowit.locationPermission': 'granted',
        'knowit.place': jsonEncode(_milan().toJson()),
      });
      await reading.adopt(
        ReaderSnapshot(placeRemovedAt: DateTime.utc(2026, 10, 5)),
      );
      expect(reading.place, isNull);
      expect(reading.locationPermission, 'off');
      phone.finds = 0;
      await reading.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(days: 30)),
      );
      expect(phone.finds, 0);

      final AppState removedHere = await _state({
        'knowit.locationPermission': 'off',
        'knowit.placeRemovedAt': '2026-09-15T00:00:00.000Z',
      });
      await removedHere.adopt(ReaderSnapshot(place: _modena()));
      expect(removedHere.place!.city, 'Modena');
      expect(removedHere.locationPermission, 'not_asked');
    });

    testWidgets('removed from Profile: gone from the phone, from the next '
        'backup, and from PostHog\'s profile', (tester) async {
      phone.system = LocationAccess.granted;
      final AppState app = await _state({
        'knowit.locationPermission': 'granted',
      }, tester: tester);
      await app.setPlace(_modena(), from: 'day done');
      await Analytics.flushPerson(force: true);
      expect(said.writes.last.$1, containsPair('place_city', 'Modena'));
      expect(said.writes.last.$1, containsPair('place_region', 'IT-45'));
      expect(said.writes.last.$1, containsPair('place_country', 'IT'));
      expect(
        said.writes.last.$1,
        containsPair('location_permission', 'granted'),
      );

      _tall(tester);
      await tester.pumpWidget(_profile(app));
      await _settle(tester);
      expect(find.text('Modena'), findsOneWidget);
      // The promise is the sheet's, where the choice is made, and no longer
      // a line under the row.
      const String promise =
          'Only your city is kept, never your exact position.';
      expect(find.text(promise), findsNothing);
      await tester.tap(find.byKey(const ValueKey('place-row')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('place-options')), findsOneWidget);
      expect(find.text('Modena · Emilia-Romagna'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('place-options')),
          matching: find.text(promise),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('place-remove')));
      await _settle(tester);

      expect(app.place, isNull);
      expect(app.locationPermission, 'off');
      expect(app.placeRemovedAt, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.place'), isNull);
      expect(prefs.getString('knowit.locationPermission'), 'off');
      expect(app.snapshot().toJson().containsKey('place'), isFalse);
      expect(said.of('place removed').single, {
        r'$unset': ['place_country', 'place_region', 'place_city'],
      });
      expect(
        find.text('Removed. Astute no longer keeps where you live.'),
        findsOneWidget,
      );
      await Analytics.flushPerson(force: true);
      final Map<String, Object> written = said.writes.last.$1;
      expect(written['location_permission'], 'off');
      for (final String key in AppState.kPlaceProfileKeys) {
        expect(written.containsKey(key), isFalse, reason: key);
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('place-row')),
          matching: find.text('Off'),
        ),
        findsOneWidget,
      );

      // Nor is the phone asked again until the reader switches it back on.
      final int finds = phone.finds;
      await app.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(days: 30)),
      );
      expect(phone.finds, finds);
    });

    test('removed while the phone was still looking: stays removed', () async {
      final AppState app = await _state(const {});
      phone.hold = Completer<void>();
      final Future<Place?> reading = app.readPlace(from: 'profile');
      await app.clearPlace();
      phone.hold!.complete();
      expect(await reading, isNull);
      expect(app.place, isNull);
      expect(said.of('place set'), isEmpty);
    });

    test('deleting the account takes it from PostHog\'s profile too', () async {
      final AppState app = await _state(const {});
      await app.setPlace(_modena(), from: 'day done');
      final MemoryReaderStore readers = MemoryReaderStore();
      final Account account = Account(
        uidOverride: 'u1',
        storeOverride: readers,
        boardsOverride: MemoryBoardStore(),
      );
      await account.push(app);
      expect(await account.deleteAccount(app), DeleteOutcome.deleted);
      expect(await readers.read('u1'), isNull);
      expect(app.place, isNull);
      expect(said.of('place removed').single, {
        r'$unset': ['place_country', 'place_region', 'place_city'],
      });
    });
  });

  group('read again', () {
    String ago(Duration d) =>
        DateTime.now().subtract(d).toUtc().toIso8601String();

    setUp(() => phone.system = LocationAccess.granted);

    test('at launch, once a week, and quietly when nothing moved', () async {
      final AppState app = await _state({
        'knowit.locationPermission': 'granted',
        'knowit.place': jsonEncode(_modena().toJson()),
        'knowit.placeCheckedAt': ago(const Duration(days: 8)),
      });
      expect(phone.finds, 1);
      expect(app.place!.city, 'Modena');
      expect(
        app.place!.at!.isAfter(_modena().at!),
        isTrue,
        reason: 'heard again',
      );
      expect(said.of('place set'), isEmpty, reason: 'no news');
      expect(DateTime.now().difference(app.placeCheckedAt!).inMinutes, 0);

      // Not again for a week.
      await app.refreshPlaceIfDue();
      await app.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(days: 6)),
      );
      expect(phone.finds, 1);
      await app.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(days: 7, minutes: 1)),
      );
      expect(phone.finds, 2);
      expect(phone.prompts, 0, reason: 'it never prompts');
    });

    test('a move is noticed, and said', () async {
      final AppState app = await _state({
        'knowit.locationPermission': 'granted',
        'knowit.place': jsonEncode(_milan().toJson()),
        'knowit.placeCheckedAt': ago(const Duration(days: 9)),
      });
      expect(app.place!.city, 'Modena');
      expect(said.of('place set'), [
        {
          'country': 'IT',
          'region': 'IT-45',
          'city': 'Modena',
          'changed': true,
          'from': 'refresh',
        },
      ]);
    });

    test('not within the week', () async {
      await _state({
        'knowit.locationPermission': 'granted',
        'knowit.place': jsonEncode(_modena().toJson()),
        'knowit.placeCheckedAt': ago(const Duration(days: 3)),
      });
      expect(phone.finds, 0);
    });

    test('a read that found nothing is tried again a day later', () async {
      phone.fails = true;
      final AppState app = await _state({
        'knowit.locationPermission': 'granted',
        'knowit.placeCheckedAt': ago(const Duration(days: 2)),
      });
      expect(phone.finds, 1);
      expect(app.place, isNull);
      await app.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(hours: 12)),
      );
      expect(phone.finds, 1);
      phone.fails = false;
      await app.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(hours: 25)),
      );
      expect(phone.finds, 2);
      expect(app.place!.city, 'Modena');
    });

    test('taken back in the phone\'s settings: the reading stops, and the '
        'place stays until the reader removes it', () async {
      phone.system = LocationAccess.deniedForever;
      final AppState app = await _state({
        'knowit.locationPermission': 'granted',
        'knowit.place': jsonEncode(_modena().toJson()),
        'knowit.placeCheckedAt': ago(const Duration(days: 30)),
      });
      expect(app.locationPermission, 'denied');
      expect(app.place!.city, 'Modena');
      expect(phone.finds, 0);
    });

    test(
      'location off for the whole phone: next time, and nothing changed',
      () async {
        phone.system = LocationAccess.unavailable;
        final AppState app = await _state({
          'knowit.locationPermission': 'granted',
          'knowit.placeCheckedAt': ago(const Duration(days: 30)),
        });
        expect(app.locationPermission, 'granted');
        expect(phone.finds, 0);
      },
    );

    test('never for a reader who did not say yes, or removed it', () async {
      phone.system = LocationAccess.granted;
      for (final String word in ['not_asked', 'off']) {
        await _state({
          'knowit.locationPermission': word,
          'knowit.placeCheckedAt': ago(const Duration(days: 30)),
        });
      }
      expect(phone.checks, 0);
      expect(phone.finds, 0);
    });

    testWidgets('on the way back into the app, without a prompt', (
      tester,
    ) async {
      // Said yes on the sheet, no to the system, then allowed it in the
      // phone's settings while the app was away.
      phone.system = LocationAccess.deniedForever;
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(3),
        'knowit.locationPermission': 'denied',
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      expect(phone.finds, 0);

      _background(tester);
      await _settle(tester);
      phone.system = LocationAccess.granted;
      _foreground(tester);
      await _wait(tester);
      final AppState app = _appOf(tester);
      expect(phone.finds, 1);
      expect(phone.prompts, 0);
      expect(app.place!.city, 'Modena');
      expect(app.locationPermission, 'granted');
      expect(_sheet, findsNothing, reason: 'nothing to ask: they said yes');

      // And again only once it is due.
      _background(tester);
      await _settle(tester);
      _foreground(tester);
      await _wait(tester);
      expect(phone.finds, 1);
    });
  });

  group('never a coordinate', () {
    testWidgets('nothing the app measures or traces carries the point: not '
        'the phone\'s, not the rounded one', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._installed(),
        ..._finished(2),
      });
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _wait(tester);
      // The whole life of a place: asked, allowed, read, written to the
      // profile, read again after a move, removed.
      await tester.tap(find.byKey(const ValueKey('place-yes')));
      await _settle(tester);
      final AppState app = _appOf(tester);
      expect(app.place, isNotNull);
      await Analytics.flushPerson(force: true);
      phone
        ..city = 'Bologna'
        ..lat = 44.49381
        ..lon = 11.33875;
      await app.refreshPlaceIfDue(
        now: DateTime.now().add(const Duration(days: 8)),
      );
      expect(app.place!.city, 'Bologna');
      await Analytics.flushPerson(force: true);
      await app.clearPlace();
      _background(tester);
      await _settle(tester);
      await Analytics.flushPerson(force: true);

      expect(said.of('place set'), hasLength(2));
      expect(said.of('place removed'), hasLength(1));
      expect(
        said.writes.any((w) => w.$1['place_city'] == 'Modena'),
        isTrue,
        reason: 'the profile was told the city',
      );
      _noPoint([for (final e in said.events) e.$1], where: 'event names');
      for (final (String name, Map<String, Object> properties) in said.events) {
        _noPoint(properties, where: name);
      }
      for (final (Map<String, Object> set, Map<String, Object> once)
          in said.writes) {
        _noPoint(set, where: r'$set');
        _noPoint(once, where: r'$set_once');
      }
      _noPoint(said.registered, where: 'super properties');
      _noPoint(said.identified, where: r'$identify');
      final List<Map<String, Object?>> trace = Trace.instance.queued;
      expect(trace.where((e) => e['e'] == 'place'), hasLength(2));
      expect(trace.where((e) => e['e'] == 'unplace'), hasLength(1));
      _noPoint(trace, where: 'the trace');

      // The scan is not blind: a point anywhere in what is sent is found.
      expect(
        () => _noPoint({'lat': 1}, where: 'test'),
        throwsA(isA<TestFailure>()),
      );
      expect(
        () => _noPoint([
          {'x': 44.6},
        ], where: 'test'),
        throwsA(isA<TestFailure>()),
      );
    });

    test('the trace keeps the place to the city, under its own names, and '
        'a card\'s region tag stays out of it', () {
      final Trace trace = Trace(clock: () => DateTime.utc(2026, 10, 12, 9));
      trace.note('place set', {
        'country': 'IT',
        'region': 'IT-45',
        'city': 'Modena',
        'changed': true,
        'from': 'day done',
        // Never sent, and dropped even if it were.
        'lat': 44.6,
        'lon': 10.9,
        'latitude': _lat,
      });
      trace.note('place removed', {r'$unset': AppState.kPlaceProfileKeys});
      trace.note('card viewed', {
        'pill_id': 'history-3',
        'region': 'Europe',
        'position': 1,
      });
      expect(trace.queued[0], {
        't': DateTime.utc(2026, 10, 12, 9).millisecondsSinceEpoch,
        'e': 'place',
        'co': 'IT',
        'rg': 'IT-45',
        'ci': 'Modena',
      });
      expect(trace.queued[1].keys, unorderedEquals(['t', 'e']));
      expect(trace.queued[1]['e'], 'unplace');
      expect(trace.queued[2].containsKey('rg'), isFalse);
      expect(trace.queued[2]['c'], 'history-3');
    });

    test('the policy promises what the code keeps', () {
      // The point is kept to a tenth of a degree — about 11 km north to
      // south, as the policy says "about 10 km" — and PostHog's profile
      // holds the city at most.
      expect(Place.roundCoordinate(_lat), 44.6);
      expect(distanceKm(_lat, _lon, 44.6, 10.9), lessThan(8));
      expect(kPlacePolicy['en'], contains('a point rounded to about 10 km'));
      expect(
        kPlacePolicy['en'],
        contains('PostHog receives your city at most, never a coordinate'),
      );
      for (final String key in AppState.kPlaceProfileKeys) {
        expect(key, isNot(anyOf(contains('lat'), contains('lon'))));
      }
    });
  });

  group('on a phone', () {
    late _Gps gps;
    late _Names names;
    late GeolocatorPlatform before;

    setUp(() {
      before = GeolocatorPlatform.instance;
      gps = _Gps();
      GeolocatorPlatform.instance = gps;
      names = _Names();
      pi.GeocodingPlatformFactory.instance = names;
    });

    tearDown(() => GeolocatorPlatform.instance = before);

    NativePlaceFinder finder() => NativePlaceFinder(
      onPhone: true,
      clock: () => DateTime.utc(2026, 10, 12, 9),
    );

    test('reads once, at low accuracy and for ten seconds at most, names the '
        'place in English, and keeps it to a tenth of a degree', () async {
      final Place? place = await finder().find();
      expect(gps.settings?.accuracy, LocationAccuracy.low);
      expect(gps.settings?.timeLimit, const Duration(seconds: 10));
      // English, as a tag Android's Locale.forLanguageTag can read: "en_US"
      // would reach it as no language at all.
      expect(names.locale, const Locale('en'));
      expect(names.locale.toString(), 'en');
      // The phone's own geocoder is the one thing the position is given to.
      expect(names.point, (_lat, _lon));
      expect(place!.country, 'IT');
      expect(place.region, 'IT-45');
      expect(place.regionName, 'Emilia-Romagna');
      expect(place.city, 'Modena');
      expect(place.lat, 44.6);
      expect(place.lon, 10.9);
      expect(place.at, DateTime.utc(2026, 10, 12, 9));
      expect(gps.requests, 0, reason: 'reading asks nothing');
    });

    test('with no fix in time, the last one the phone holds', () async {
      gps
        ..slow = true
        ..last = _position(45.07049, 7.68682);
      names.marks = const [
        pi.Placemark(
          isoCountryCode: 'IT',
          administrativeArea: 'Piedmont',
          locality: 'Turin',
        ),
      ];
      final Place? place = await finder().find();
      expect(place!.city, 'Turin');
      expect(place.region, 'IT-21');
      expect(place.lat, 45.1);
      expect(place.lon, 7.7);
    });

    test('with no position or no name, nothing — and nothing printed that '
        'could carry the point', () async {
      final List<String?> printed = [];
      final DebugPrintCallback was = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => printed.add(message);
      addTearDown(() => debugPrint = was);

      gps
        ..slow = true
        ..last = null;
      expect(await finder().find(), isNull);

      gps.slow = false;
      names.fails = Exception('No address found for $_lat, $_lon');
      expect(await finder().find(), isNull);

      names
        ..fails = null
        ..marks = const [pi.Placemark(locality: 'Somewhere')];
      expect(await finder().find(), isNull, reason: 'no country, no place');

      gps.fails = true;
      expect(await finder().find(), isNull);
      expect(printed.join('\n'), isNot(contains('44.6')));
      expect(printed.join('\n'), isNot(contains('10.9')));
    });

    test('asks only while in use, and says what the system said', () async {
      final NativePlaceFinder f = finder();
      expect(f.canAsk, isTrue);
      gps.permission = LocationPermission.denied;
      expect(await f.access(), LocationAccess.notAsked);
      expect(gps.requests, 0);

      gps.answer = LocationPermission.denied;
      expect(await f.ask(), LocationAccess.denied);
      gps.answer = LocationPermission.deniedForever;
      expect(await f.ask(), LocationAccess.deniedForever);
      expect(await f.access(), LocationAccess.deniedForever);
      gps.answer = LocationPermission.whileInUse;
      expect(await f.ask(), LocationAccess.granted);
      expect(await f.access(), LocationAccess.granted);
      expect(gps.requests, 3);

      gps.servicesOn = false;
      expect(await f.access(), LocationAccess.unavailable);
      expect(await f.ask(), LocationAccess.unavailable);
      expect(gps.requests, 3, reason: 'no prompt with location off');

      gps.accuracy = LocationAccuracyStatus.reduced;
      expect(await f.precise(), isFalse);
      gps.accuracy = LocationAccuracyStatus.precise;
      expect(await f.precise(), isTrue);
      expect(await f.openSettings(), isTrue);
      expect(gps.settingsOpened, 1);
    });

    test('anywhere but a phone, nothing is read or asked', () async {
      final NativePlaceFinder desk = NativePlaceFinder(onPhone: false);
      expect(desk.canAsk, isFalse);
      expect(await desk.access(), LocationAccess.unavailable);
      expect(await desk.ask(), LocationAccess.unavailable);
      expect(await desk.find(), isNull);
      expect(gps.requests + gps.reads, 0);
      // The computer the tests run on is not a phone.
      expect(NativePlaceFinder().canAsk, Platform.isIOS || Platform.isAndroid);

      const WebPlaceFinder web = WebPlaceFinder();
      expect(web.canAsk, isFalse);
      expect(await web.access(), LocationAccess.unavailable);
      expect(await web.find(), isNull);
      expect(await web.openSettings(), isFalse);
    });
  });

  testWidgets('the sheet, the options and the row fit in every language', (
    tester,
  ) async {
    await tester.runAsync(_loadRealFonts);
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final AppState on = await _state({
      'knowit.locationPermission': 'granted',
      'knowit.place': jsonEncode(
        Place.fromPhone(
          isoCountry: 'IT',
          adminArea: 'Friuli-Venezia Giulia',
          locality: 'San Giorgio di Nogaro',
          lat: 45.83,
          lon: 13.21,
        ).toJson(),
      ),
    }, tester: tester);
    final findings = <String>[];
    for (final Locale locale in AppLocalizations.supportedLocales) {
      Future<void> lay(Widget child, String what) async {
        await tester.pumpWidget(_host(child, locale: locale));
        await _settle(tester);
        findings.addAll(_cut(tester).map((s) => '[$locale] $what: $s'));
      }

      await lay(
        const Align(alignment: Alignment.bottomCenter, child: PlaceAsk()),
        'sheet',
      );
      await lay(
        Align(
          alignment: Alignment.bottomCenter,
          child: PlaceOptions(app: on),
        ),
        'options',
      );
      on.place = null;
      tester.view.physicalSize = const Size(360, 2600);
      await lay(
        ProfileScreen(
          app: on,
          account: Account(
            uidOverride: 'me',
            boardsOverride: MemoryBoardStore(),
          ),
          onSignedOut: () {},
        ),
        'profile, off',
      );
      expect(find.byKey(const ValueKey('place-row')), findsOneWidget);
      tester.view.physicalSize = const Size(360, 780);
      on.place = Place.fromPhone(
        isoCountry: 'IT',
        adminArea: 'Friuli-Venezia Giulia',
        locality: 'San Giorgio di Nogaro',
      );
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}

/// Stands in for the system's location, on a phone.
class _Gps extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission answer = LocationPermission.whileInUse;
  LocationAccuracyStatus accuracy = LocationAccuracyStatus.reduced;
  bool servicesOn = true;

  /// No fix within the time limit.
  bool slow = false;

  /// No position at all.
  bool fails = false;
  Position? last;

  LocationSettings? settings;
  int requests = 0;
  int reads = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => servicesOn;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission = answer;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    reads++;
    settings = locationSettings;
    if (fails) throw const LocationServiceDisabledException();
    if (slow) throw TimeoutException('no fix', locationSettings?.timeLimit);
    return _position(_lat, _lon);
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => last;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async => accuracy;

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }
}

Position _position(double lat, double lon) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: DateTime.utc(2026, 10, 12, 9),
  accuracy: 900,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// Stands in for the system's geocoder: what it was asked, in which
/// language, and what it names.
class _Names extends pi.GeocodingPlatformFactory {
  Locale? locale;
  (double, double)? point;
  Object? fails;
  List<pi.Placemark> marks = const [
    pi.Placemark(
      isoCountryCode: 'IT',
      country: 'Italy',
      administrativeArea: 'Emilia-Romagna',
      subAdministrativeArea: 'Province of Modena',
      locality: 'Modena',
      street: 'Piazza Grande',
    ),
  ];

  @override
  pi.Geocoding createGeocoding(pi.GeocodingCreationParams params) =>
      _Geocoder(params, this);
}

class _Geocoder extends pi.Geocoding {
  _Geocoder(super.params, this.names) : super.implementation();

  final _Names names;

  @override
  Future<List<pi.Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    Locale? locale,
  }) async {
    names
      ..locale = locale
      ..point = (latitude, longitude);
    final Object? fails = names.fails;
    if (fails != null) throw fails;
    return names.marks;
  }
}

/// The faces the app ships, so a layout is measured in the text a reader
/// sees.
Future<void> _loadRealFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// Every paragraph on screen that did not get all of its text out, and any
/// overflow the layout reported.
List<String> _cut(WidgetTester tester) {
  final out = <String>[];
  final Object? error = tester.takeException();
  if (error != null) out.add('overflow — ${'$error'.split('\n').first}');
  for (final element in find.byType(RichText).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
    final String plain = ro.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    final Color? colour = ro.text.style?.color;
    if (colour != null && colour.a == 0) continue;
    String? how;
    if (ro.didExceedMaxLines) how = 'lines';
    final painter = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      textScaler: ro.textScaler,
      textAlign: ro.textAlign,
      maxLines: ro.maxLines,
    )..layout(maxWidth: ro.softWrap ? ro.size.width : double.infinity);
    if (how == null && painter.height > ro.size.height + 0.5) how = 'height';
    if (how == null && !ro.softWrap && painter.width > ro.size.width + 0.5) {
      how = 'width';
    }
    painter.dispose();
    if (how != null) out.add('"$plain" ($how)');
  }
  return out;
}
