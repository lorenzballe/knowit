import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'measure/install.dart' show isTestChannel;
import 'sync/trace.dart';
import 'utils/analytics_boot.dart';

/// The PostHog project key, and the one thing that decides whether the app is
/// measured at all.
///
/// Public on purpose, like the RevenueCat keys: a project key says which
/// project to write into and reads nothing back, which is why it ships inside
/// the binary. Passed in at build time so that turning measurement on, moving
/// it to another project, or rotating it is not a code change:
///
///     flutter build ipa --dart-define=POSTHOG_KEY=phc_xxx
///     flutter build appbundle --dart-define=POSTHOG_KEY=phc_xxx
///
/// Left out — which is what a fork, a checkout and every test gets — the app
/// is not measured. Not "measured into a project that does not exist": every
/// call below returns without doing anything, and nothing reaches the network.
const String kPostHogKey = String.fromEnvironment('POSTHOG_KEY');

/// Which PostHog region the project lives in.
///
/// EU by default because that is where the readers are, and because a project
/// created in the other region and pointed at from here silently accepts
/// nothing. A self-hosted instance goes here too.
const String kPostHogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://eu.i.posthog.com',
);

/// Whether sessions are recorded for replay. Off unless a build asks for it
/// with `--dart-define=REPLAY=true`, and no build in codemagic.yaml or the
/// GitHub workflows does: a recording of a reader's screen is more than a
/// count of what they did, and more than the consent they gave asks for.
/// A build that turns it on still records nothing before the reader has
/// said yes, and hides every word and every picture on the screen.
const bool kSessionReplay = bool.fromEnvironment('REPLAY');

/// Where an event goes once the app has decided to send it.
///
/// An interface rather than a direct call into PostHog, for the same reason
/// [Account] takes a store: a measurement that can only be checked by watching
/// the network is a measurement nobody checks. The tests put a list behind
/// this and read the events back.
abstract class AnalyticsSink {
  Future<void> capture(String event, Map<String, Object> properties);

  Future<void> screen(String name);

  Future<void> identify(String id, Map<String, Object> properties);

  /// Forgets who this was — a sign-out, not an opt-out.
  Future<void> reset();

  /// Properties stamped on every later event, so a funnel can be cut by plan
  /// or by how far up the ladder the reader stands without every call site
  /// having to remember.
  Future<void> register(String key, Object value);

  /// Stops or resumes collection. The reader's own switch.
  Future<void> setCollecting(bool on);

  /// The reader's profile: what it says now ([set]) and what it said the
  /// first time ([setOnce]).
  Future<void> setPerson(Map<String, Object> set, Map<String, Object> setOnce);

  /// An error the app caught and carried on from, for error tracking.
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  );
}

/// What the app measures, and the one place that decides whether it does.
///
/// Static, like [Cloud] and for the same reason: this is asked from inside the
/// state, from screens, and from the sync layer, and threading one object
/// through all of them would say the app could have two. It cannot — PostHog's
/// own API is a singleton underneath.
///
/// Three rules hold everywhere below.
///
/// **It never throws and never blocks.** Measurement is not a feature the
/// reader asked for, so it may not cost them a frame or a screen. Everything
/// is caught; nothing is awaited on a path the reader is waiting on.
///
/// **It is off until told otherwise.** No key, no measurement — which is what
/// keeps the widget tests honest, exactly as `Cloud.ready` does: they pump
/// AstutoApp without calling [start], so [ready] is false and no test reaches
/// the network.
///
/// **It waits for the reader's yes.** PostHog is not even set up until the
/// reader has said yes — on the intro, on the sheet that asks once after
/// the first finished day, or with the switch in Profile — so nothing is
/// captured, queued or sent before then, and nothing at all after a no.
/// What the app stamps on every event and who the reader is are kept on
/// the phone meanwhile, and said the moment a yes starts it.
///
/// **It carries no prose.** Ids, counts, durations and enums go out; the name
/// the reader typed, their email, their friend code, the reason they wrote on
/// a card and the text of any answer do not. A card is a pill id and a
/// subject. What a reader *said* is theirs.
class Analytics {
  const Analytics._();

  static AnalyticsSink? _sink;
  static String? _failure;

  /// The reader's answer to "may Astute measure how the app is used?":
  /// yes, no, or null while they have not said.
  static bool? _choice;

  /// Where the reader's own answer is kept, and whether it is one: on the
  /// phone, not in the account, because it is a decision about this
  /// install. `knowit.analytics` used to be the Profile switch alone, on by
  /// default, so without `knowit.analytics.asked` beside it only a false is
  /// taken as an answer — a reader who turned the switch off said no — and
  /// a true is a default nobody chose, which is asked again.
  static const String _kCollecting = 'knowit.analytics';
  static const String _kAsked = 'knowit.analytics.asked';

  /// Whether measurement is up. False on a build with no key, before the
  /// reader has said yes, after a no, on a build where PostHog would not
  /// start, and under every test that has not asked for a sink of its own.
  static bool get ready => _sink != null;

  /// Why it is not up, when it is not. Shown in the debug section, because
  /// "no events are arriving" is a bug report that takes a day to answer
  /// without it.
  static String? get failure => _failure;

  /// Whether the reader has said yes. False until they have, and after a no.
  static bool get collecting => _choice == true;

  /// Whether the reader has answered, either way.
  static bool get answered => _choice != null;

  /// Whether there is anything to ask about: a build with a project to send
  /// to. A build with no key measures nothing whatever the reader says, so
  /// it does not ask.
  static bool get canAsk => canAskForTest ?? kPostHogKey.isNotEmpty;

  /// Stands in for a key, for the tests that ask the question.
  @visibleForTesting
  static bool? canAskForTest;

  /// What sets measurement up once there is a yes: PostHog, or a test's
  /// own sink.
  static Future<AnalyticsSink> Function() _setUp = _setUpPostHog;

  /// Called once from main(), before the app is built. Reads the reader's
  /// answer and sets PostHog up only on a yes. Never throws: a
  /// misconfigured project, an offline phone or a platform PostHog has no
  /// plugin for must not stop the app opening.
  static Future<void> start() async {
    if (!canAsk) {
      _failure = 'No POSTHOG_KEY was built in, so nothing is measured.';
      return;
    }
    _choice = await _readChoice();
    if (_choice != true) {
      _failure = _choice == null
          ? 'The reader has not said yes or no yet, so nothing is measured.'
          : 'The reader said no, so nothing is measured.';
      return;
    }
    await _begin();
  }

  /// Sets measurement up, and says what was kept while it waited: what is
  /// stamped on every event, where the install came from, and who the
  /// reader is.
  static Future<void> _begin() async {
    if (_sink != null) return;
    try {
      _sink = await _setUp();
      _failure = null;
    } catch (error, stack) {
      _sink = null;
      _failure = '$error';
      debugPrint('PostHog did not start, carrying on unmeasured: $error');
      debugPrintStack(stackTrace: stack);
      return;
    }
    for (final MapEntry<String, Object> e in _registered.entries) {
      await _guard(() => _sink?.register(e.key, e.value));
    }
    final String? channel = _installChannel;
    if (channel != null) {
      for (final MapEntry<String, Object> e in _installFacts(channel).entries) {
        _personWaiting[e.key] = e.value;
      }
    }
    final identity = _identity;
    if (identity != null) {
      await identify(
        identity.uid,
        anonymous: identity.anonymous,
        method: identity.method,
      );
    } else {
      await flushPerson(force: true);
    }
    final List<VoidCallback> waiting = List.of(_whenStarted);
    _whenStarted.clear();
    for (final VoidCallback f in waiting) {
      try {
        f();
      } catch (_) {}
    }
  }

  static Future<AnalyticsSink> _setUpPostHog() async {
    final config = PostHogConfig(kPostHogKey)
      ..host = kPostHogHost
      // $app_opened, $app_backgrounded and the update events. The daily
      // loop below is what the app measures on purpose; these are what say
      // whether anyone came back to run it.
      ..captureApplicationLifecycleEvents = true
      // A person is only made once there is someone to be: an install that
      // never signs in stays an event with no profile attached to it.
      ..personProfiles = PostHogPersonProfiles.identifiedOnly
      // Not recorded, unless a build asks (kSessionReplay); and then with
      // every word and every picture on the screen hidden. The screen
      // carries the reader's own written reasons and the cards they kept,
      // and a recording of them is not worth any finding.
      ..sessionReplay = kSessionReplay
      ..debug = kDebugMode;
    config.sessionReplayConfig
      ..maskAllTexts = true
      ..maskAllImages = true
      ..captureTouches = true;
    // Every error the app does not catch, Dart's and the phone's own, goes
    // to error tracking with the steps that led to it.
    config.errorTrackingConfig
      ..captureFlutterErrors = true
      ..capturePlatformDispatcherErrors = true
      ..captureIsolateErrors = true
      ..captureNativeExceptions = true
      ..inAppIncludes.add('package:astuto');

    // The browser has no plugin to set up: posthog-js has to be on the page
    // first, and this is what puts it there. A no-op everywhere else.
    await bootAnalytics(key: kPostHogKey, host: kPostHogHost);

    await Posthog().setup(config);
    return const _PostHogSink();
  }

  static Future<bool?> _readChoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? kept = prefs.getBool(_kCollecting);
      if (prefs.getBool(_kAsked) == true) return kept ?? false;
      // The old switch, turned off: a no, and kept as one.
      return kept == false ? false : null;
    } catch (_) {
      // A phone whose stored state will not open is asked again, and
      // measured only on a yes.
      return null;
    }
  }

  /// The reader's answer: on the intro, on the sheet that asks once, or
  /// with the switch in Profile. Remembered, and applied at once — a yes
  /// sets measurement up there and then, a no stops it before anything
  /// else is sent; an answer that only takes effect next launch is not
  /// one.
  static Future<void> setCollecting(bool on) async {
    _choice = on;
    // Nothing waits to be said about a reader who has just said no; and one
    // who says yes again has their profile said whole, since what was held
    // back meanwhile never arrived.
    _personWaiting.clear();
    _personOnceWaiting.clear();
    if (on) _personSent.clear();
    await _keepChoice(on);
    if (!on) {
      _failure = 'The reader said no, so nothing is measured.';
      await _guard(() => _sink?.setCollecting(false));
      return;
    }
    if (_sink == null) {
      if (canAsk) await _begin();
      return;
    }
    await _guard(() => _sink?.setCollecting(true));
  }

  static Future<void> _keepChoice(bool on) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCollecting, on);
      await prefs.setBool(_kAsked, true);
    } catch (_) {
      // Not remembering the choice is bad; ignoring it now would be worse.
    }
  }

  /// Writes the answer back down after something wiped the phone.
  ///
  /// Signing out clears every key the app holds, these among them, and a
  /// reader who said no does not expect signing out to turn measurement
  /// back on — nor one who said yes to be asked again.
  static Future<void> persistChoice() async {
    final bool? choice = _choice;
    if (choice != null) await _keepChoice(choice);
  }

  /// Runs [f] once measurement is up: now, if it is, or the moment a yes
  /// starts it.
  static void whenStarted(VoidCallback f) {
    if (ready) {
      f();
    } else {
      _whenStarted.add(f);
    }
  }

  static final List<VoidCallback> _whenStarted = [];

  /// What every later event is stamped with, kept so that a yes given
  /// after launch stamps the events that follow it all the same.
  static final Map<String, Object> _registered = {};

  /// Who the reader is, as last said, kept for the same reason.
  static ({String uid, bool anonymous, String? method})? _identity;

  /// Measurement as a reader who has answered [yes] would find it at
  /// launch, with [sink] standing in for PostHog: for the tests of the
  /// question itself.
  @visibleForTesting
  static Future<void> startForTest(AnalyticsSink sink) async {
    useForTest(null);
    canAskForTest = true;
    _setUp = () async => sink;
    await start();
  }

  @visibleForTesting
  static void useForTest(AnalyticsSink? sink) {
    _sink = sink;
    _failure = sink == null ? 'No sink under test.' : null;
    // Measured, as every test that hands over a sink expects; the tests of
    // the question start from no answer (startForTest).
    _choice = sink == null ? null : true;
    canAskForTest = null;
    _setUp = _setUpPostHog;
    _registered.clear();
    _identity = null;
    _whenStarted.clear();
    currentScreen = null;
    _installChannel = null;
    _personWaiting.clear();
    _personOnceWaiting.clear();
    _personSent.clear();
    _personOnceSent.clear();
    _personOf = null;
    _personSentAt = -1;
    _personSince = -1;
    _personLoaded = false;
  }

  // ── Saying it ─────────────────────────────────────────────────────────

  /// The one road out. Takes nullable values because most call sites have a
  /// property that is sometimes there — a subject on a card that has one, a
  /// source on a paywall that was opened from somewhere nameable — and
  /// dropping them here beats an `if` at forty call sites.
  static Future<void> capture(
    String event, [
    Map<String, Object?> properties = const {},
  ]) {
    // The reader's own copy first, whether or not the app is measured: what
    // they did is what they are dealt from (see Trace). It keeps the
    // events it wants and drops the rest.
    try {
      Trace.instance.note(event, properties);
    } catch (_) {}
    return _guard(
      () => _sink?.capture(event, {
        for (final e in properties.entries)
          if (e.value != null) e.key: e.value!,
      }),
    );
  }

  /// Which screen the reader has arrived on, as PostHog's `$screen`.
  ///
  /// Sent by the screens themselves (lib/measure/screens.dart), once at the
  /// start of each visit, under the name each screen gives itself. Never
  /// taken from the route: the app's tabs and the steps of its first run are
  /// one route, so a navigator observer reporting names would see "/" over
  /// and over and call it a session.
  static Future<void> screen(String name) => _guard(() => _sink?.screen(name));

  /// The screen in front of the reader now, which every event is filed
  /// under in PostHog (`$screen_name`). Kept here rather than left to
  /// PostHog, which only knows the last `$screen` sent: back from a card
  /// opened in Explore, the events are Explore's again, though no new
  /// visit began.
  static String? currentScreen;

  /// Ties what this phone does to the account behind it.
  ///
  /// The id is the Firebase uid — the same one the backup is keyed by, which
  /// is what makes a reader on a new phone the same person here as there. The
  /// email and the name the reader typed are deliberately not sent.
  ///
  /// The profile held back so far goes with it: this is the first moment
  /// there is a person to write it to.
  static Future<void> identify(
    String uid, {
    bool anonymous = true,
    String? method,
  }) async {
    _identity = (uid: uid, anonymous: anonymous, method: method);
    await _guard(
      () => _sink?.identify(uid, {
        'anonymous': anonymous,
        'sign_in_method': ?method,
      }),
    );
    await _loadPerson();
    if (_personOf != uid) {
      // Somebody else's profile, or a first one: everything is said again.
      _personOf = uid;
      _personSent.clear();
      _personOnceSent.clear();
      _personSince = -1;
      final String? channel = _installChannel;
      if (channel != null) _personWaiting.addAll(_installFacts(channel));
    }
    await flushPerson(force: true);
  }

  /// Forgets the reader on a sign-out, so the next person on this phone is
  /// not counted as the last one.
  static Future<void> reset() async {
    _identity = null;
    _personWaiting.clear();
    _personOnceWaiting.clear();
    _personSent.clear();
    _personOnceSent.clear();
    _personOf = null;
    _personSentAt = -1;
    _personSince = -1;
    unawaited(_savePerson());
    await _guard(() => _sink?.reset());
  }

  /// Stamps a property on every later event. Used for the few things worth
  /// cutting the whole funnel by.
  static Future<void> register(String key, Object value) {
    _registered[key] = value;
    return _guard(() => _sink?.register(key, value));
  }

  // ── The reader's profile ──────────────────────────────────────────────

  /// What is waiting to be written to the profile, by `$set` and by
  /// `$set_once`.
  static final Map<String, Object> _personWaiting = {};
  static final Map<String, Object> _personOnceWaiting = {};

  /// What was last written, and for whom: a value written already is not
  /// written again. Kept on the phone, so an unchanged profile is not said
  /// again at every launch.
  static final Map<String, Object> _personSent = {};
  static final Set<String> _personOnceSent = {};
  static String? _personOf;

  /// When the profile was last written, and when what was written began to
  /// be remembered, in milliseconds since the epoch; -1 for never.
  static int _personSentAt = -1;
  static int _personSince = -1;
  static bool _personLoaded = false;

  static const String _kPerson = 'knowit.analytics.person';

  /// A profile is a description, not a stream: written at most this often
  /// when the app leaves the screen, unless something says it is urgent.
  static const Duration personEvery = Duration(hours: 6);

  /// What was written is said again in full after this long, so a profile
  /// lost on PostHog's side does not stay empty.
  static const Duration personForgetsAfter = Duration(days: 7);

  /// The reader's profile in PostHog: plan, streak, how far up the ladder,
  /// what they have set up — counts and enums, like everything else here.
  /// Null values are left out rather than sent as nothing.
  ///
  /// [set] is written with `$set`, as it is now; [setOnce] with `$set_once`,
  /// for what is true from the start and never changes, like the day the
  /// app was installed. Nothing goes out at once: the values wait, and are
  /// written together, only where they changed, when the reader is
  /// identified and when the app leaves the screen ([flushPerson]) — one
  /// `$set` where a stream of them used to go. [now] writes them at once,
  /// for the few facts a cohort must see without waiting: the plan, and
  /// where the install came from.
  static Future<void> person({
    Map<String, Object?> set = const {},
    Map<String, Object?> setOnce = const {},
    bool now = false,
  }) async {
    if (_sink == null) return;
    for (final MapEntry<String, Object?> e in set.entries) {
      if (e.value != null) _personWaiting[e.key] = e.value!;
    }
    for (final MapEntry<String, Object?> e in setOnce.entries) {
      final Object? value = e.value;
      if (value != null) _personOnceWaiting.putIfAbsent(e.key, () => value);
    }
    if (now) await flushPerson(force: true);
  }

  /// Takes [keys] off the reader's profile as far as the phone goes: a
  /// value still waiting is not written, and one written before is no
  /// longer remembered as written, so it goes out again if it comes back.
  /// PostHog's own copy is dropped by `$unset` on an event, which the
  /// caller sends (see AppState.clearPlace): this only keeps the phone from
  /// writing it back.
  static Future<void> forgetPerson(Iterable<String> keys) => _guard(() async {
    if (_sink == null) return;
    final List<String> gone = keys.toList();
    // At once, before anything is awaited: a flush already on its way must
    // not find them.
    for (final String key in gone) {
      _personWaiting.remove(key);
      _personOnceWaiting.remove(key);
    }
    await _loadPerson();
    for (final String key in gone) {
      _personSent.remove(key);
    }
    await _savePerson();
  });

  /// Writes what is waiting to the profile, leaving out what it already
  /// says. Without [force], at most once every [personEvery].
  static Future<void> flushPerson({bool force = false}) => _guard(() async {
    if (_sink == null ||
        (_personWaiting.isEmpty && _personOnceWaiting.isEmpty)) {
      return;
    }
    await _loadPerson();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (!force &&
        _personSentAt >= 0 &&
        now - _personSentAt < personEvery.inMilliseconds) {
      return;
    }
    if (_personSince < 0 ||
        now - _personSince > personForgetsAfter.inMilliseconds) {
      _personSent.clear();
      _personSince = now;
    }
    final Map<String, Object> set = {
      for (final MapEntry<String, Object> e in _personWaiting.entries)
        if (_personSent[e.key] != e.value) e.key: e.value,
    };
    final Map<String, Object> once = {
      for (final MapEntry<String, Object> e in _personOnceWaiting.entries)
        if (!_personOnceSent.contains(e.key)) e.key: e.value,
    };
    _personWaiting.clear();
    _personOnceWaiting.clear();
    if (set.isEmpty && once.isEmpty) return;
    await _sink?.setPerson(set, once);
    // A profile said to a reader who has said no went nowhere, so it is
    // not marked as written.
    if (!collecting) return;
    _personSent.addAll(set);
    _personOnceSent.addAll(once.keys);
    _personSentAt = now;
    await _savePerson();
  });

  static Future<void> _loadPerson() async {
    if (_personLoaded) return;
    _personLoaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_kPerson);
      if (raw == null) return;
      final Object? kept = jsonDecode(raw);
      if (kept is! Map) return;
      final Object? set = kept['set'];
      final Object? once = kept['once'];
      _personOf = kept['of'] is String ? kept['of'] as String : null;
      _personSentAt = kept['at'] is int ? kept['at'] as int : -1;
      _personSince = kept['since'] is int ? kept['since'] as int : -1;
      if (set is Map) {
        for (final MapEntry<Object?, Object?> e in set.entries) {
          final Object? value = e.value;
          if (value != null) _personSent.putIfAbsent('${e.key}', () => value);
        }
      }
      if (once is List) _personOnceSent.addAll(once.whereType<String>());
    } catch (_) {
      // A record that will not read is a profile written again: one event.
    }
  }

  static Future<void> _savePerson() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kPerson,
        jsonEncode({
          'of': _personOf,
          'at': _personSentAt,
          'since': _personSince,
          'set': _personSent,
          'once': _personOnceSent.toList(),
        }),
      );
    } catch (_) {}
  }

  // ── Where the install came from ───────────────────────────────────────

  static String? _installChannel;

  /// Stamps where this install came from (lib/measure/install.dart) on
  /// every later event and on the profile, before the first event goes: a
  /// robot or a reviewer's phone is then told apart from its first event,
  /// and PostHog's own filter for internal and test users catches the
  /// devices that are not readers at all.
  static Future<void> installedFrom(String channel) async {
    _installChannel = channel;
    await register('install_channel', channel);
    await person(set: _installFacts(channel), now: true);
  }

  static Map<String, Object> _installFacts(String channel) => {
    'install_channel': channel,
    if (isTestChannel(channel)) r'$internal_or_test_user': true,
  };

  /// An error the app caught and carried on from — a backup that failed, a
  /// store that would not answer — sent to error tracking with [where] it
  /// happened. Uncaught errors are sent by the SDK on its own.
  static Future<void> error(
    Object error,
    StackTrace? stack, {
    required String where,
    Map<String, Object?> properties = const {},
  }) => _guard(
    () => _sink?.error(error, stack, {
      'where': where,
      for (final e in properties.entries)
        if (e.value != null) e.key: e.value!,
    }),
  );

  // ── Timing ────────────────────────────────────────────────────────────

  static final Stopwatch _sinceLaunch = Stopwatch();

  /// Called first thing in main(), so the time to the first frame is the
  /// reader's wait and not the framework's.
  static void launched() => _sinceLaunch.start();

  /// Milliseconds since [launched].
  static int get msSinceLaunch => _sinceLaunch.elapsedMilliseconds;

  /// An error as a short line for a property: enough to group by, not a
  /// wall of text.
  static String short(Object error) {
    final String text = '$error'.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length <= 140 ? text : '${text.substring(0, 140)}…';
  }

  /// Nothing measurement does may reach the reader. Failures are swallowed
  /// here, once, rather than at every call site.
  static Future<void> _guard(Future<void>? Function() call) async {
    try {
      await call();
    } catch (error) {
      debugPrint('Astute: an event did not send: $error');
    }
  }
}

/// The real sink: PostHog.
class _PostHogSink implements AnalyticsSink {
  const _PostHogSink();

  @override
  Future<void> capture(String event, Map<String, Object> properties) {
    final String? screen = Analytics.currentScreen;
    return Posthog().capture(
      eventName: event,
      properties: {
        // Filed under the screen in front, which PostHog would otherwise
        // take from the last `$screen` — wrong after coming back from a
        // screen pushed over this one.
        r'$screen_name': ?screen,
        ...properties,
      },
    );
  }

  @override
  Future<void> screen(String name) => Posthog().screen(screenName: name);

  @override
  Future<void> identify(String id, Map<String, Object> properties) =>
      Posthog().identify(userId: id, userProperties: properties);

  @override
  Future<void> reset() => Posthog().reset();

  @override
  Future<void> register(String key, Object value) =>
      Posthog().register(key, value);

  @override
  Future<void> setCollecting(bool on) =>
      on ? Posthog().enable() : Posthog().disable();

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {
    if (set.isEmpty && setOnce.isEmpty) return;
    await Posthog().setPersonProperties(
      userPropertiesToSet: set.isEmpty ? null : set,
      userPropertiesToSetOnce: setOnce.isEmpty ? null : setOnce,
    );
  }

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) => Posthog().captureException(
    error: error,
    stackTrace: stack,
    properties: properties,
  );
}
