import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pills_repository.dart' show dateKey;
import '../sync/served.dart' show kFunctionsRegion;

/// The first run's four steps, in the order a reader takes them.
///
/// Whether the first run works is told by four numbers: how many phones
/// opened the app for the first time, how many of them finished the first
/// run, how many finished a first day, and how many came back the day after
/// they first opened it. All four come before the question about usage
/// data, which waits for the end of the first day (lib/widgets/
/// consent_card.dart), so PostHog never sees them for a reader who has not
/// said yes. They are counted instead on our own server, as Today's five is
/// (functions/src/steps.ts): the step's name and the day, and nothing that
/// says whose — no account, no token, no identifier of the phone. The server
/// keeps a total per step per day and nothing beside it.
enum FirstStep {
  firstOpen('first_open'),
  firstRunDone('first_run_done'),
  firstDayDone('first_day_done'),
  nextDay('next_day');

  const FirstStep(this.wire);

  /// The step's name on the server, one of the only four it counts.
  final String wire;
}

/// Where a step goes once the phone has taken it.
abstract class StepSink {
  /// Counts [step], taken on [day] (the phone's calendar, `yyyy-mm-dd`).
  /// True once the server has it, or has refused it for good, so it is not
  /// sent again; false to try again at the next launch.
  Future<bool> send(FirstStep step, String day);
}

/// The server's: a plain POST to `countStep`, with the step and the day in
/// its body and nothing else in it or around it — not the account's token
/// a callable would carry, nor anything of the phone.
class HttpStepSink implements StepSink {
  HttpStepSink({http.Client? client, Uri? url})
    : _client = client ?? http.Client(),
      url = url ?? kStepsUrl;

  final http.Client _client;

  /// Where the steps are counted.
  final Uri url;

  /// How long a count may take: a cold function and one write.
  static const Duration wait = Duration(seconds: 10);

  @override
  Future<bool> send(FirstStep step, String day) async {
    try {
      final http.Response r = await _client
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'step': step.wire, 'day': day}),
          )
          .timeout(wait);
      // Taken; or refused as no step or a day too old to count, which no
      // second try mends.
      return r.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}

/// The function that counts the steps, in the project's region.
final Uri kStepsUrl = Uri.parse(
  'https://$kFunctionsRegion-astuto-3d398.cloudfunctions.net/countStep',
);

/// Counts each of the four steps once per phone.
///
/// A step is noted on the phone the moment it is taken — the step and the
/// day — and that note is the flag that keeps it from being counted again,
/// on this phone, ever: it outlives a sign-out (AppState.signOut writes it
/// back, as it writes back the answer about usage data), so a reader who
/// signs out and runs the first run again is not a new phone. A step that
/// could not be sent is sent again at the next launch, with the day it was
/// taken on.
///
/// Only a phone whose first open was counted here counts the three steps
/// after it: a reader who had the app before this build is no first run, and
/// counting their next day would count them in the middle of a funnel they
/// never entered. And only a phone the stores installed sends anything
/// ([start]): a developer's build, TestFlight and App Review's copy,
/// Google's robots and a sideload keep their notes and send nothing.
class FirstSteps {
  FirstSteps();

  /// The app's. Tests make their own.
  static FirstSteps instance = FirstSteps();

  /// Where the steps go. Null — in a test, in the web preview, and until
  /// [start] has heard where the phone was installed from — sends nothing.
  StepSink? sink;

  static const String _kKept = 'knowit.firstSteps';

  SharedPreferences? _prefs;

  /// What has been noted, by step: the day it was taken, and whether the
  /// server has it.
  final Map<FirstStep, ({String day, bool sent})> _taken = {};

  /// The channels whose phones count: the stores'. See
  /// lib/measure/install.dart.
  static const Set<String> counted = {'app_store', 'play'};

  /// Sends from now on, through [sink], if [channel] is one of the stores'
  /// ([counted]); and sends what was noted and not yet sent.
  Future<void> start(Future<String> channel, StepSink sink) async {
    final String said = await channel;
    if (!counted.contains(said)) return;
    this.sink = sink;
    await _flush();
  }

  /// Reads what this phone has noted. Called once the phone's stored state
  /// is open, before any step can be taken.
  Future<void> load(SharedPreferences prefs) async {
    _prefs = prefs;
    _taken.clear();
    try {
      final Object? kept = jsonDecode(prefs.getString(_kKept) ?? '{}');
      if (kept is Map) {
        for (final FirstStep step in FirstStep.values) {
          final Object? one = kept[step.wire];
          if (one is Map && one['day'] is String) {
            _taken[step] = (
              day: one['day'] as String,
              sent: one['sent'] == true,
            );
          }
        }
      }
    } catch (_) {
      // Notes that will not read are no notes: at worst a step counted
      // twice, which is a number off by one, never a reader found out.
    }
  }

  /// Whether [step] has been taken on this phone.
  bool taken(FirstStep step) => _taken.containsKey(step);

  /// The day [step] was taken, or null.
  String? dayOf(FirstStep step) => _taken[step]?.day;

  /// The app open on [today]. On a phone new to the app — still in its first
  /// run, installed today — the first open; on the day after the first open,
  /// the return. Asked at every launch and every return to the app.
  Future<void> opened({
    required bool onboarded,
    required String installedOn,
    required DateTime today,
  }) async {
    // What could not be sent before goes first, in the order it was taken.
    await _flush();
    final String day = dateKey(today);
    if (!taken(FirstStep.firstOpen) && !onboarded && installedOn == day) {
      await note(FirstStep.firstOpen, today);
    }
    final String? first = dayOf(FirstStep.firstOpen);
    if (first != null) {
      final DateTime? from = DateTime.tryParse(first);
      if (from != null &&
          dateKey(DateTime(from.year, from.month, from.day + 1)) == day) {
        await note(FirstStep.nextDay, today);
      }
    }
  }

  /// [step], taken on [today]: noted, once, and sent. Nothing for a step
  /// already taken, nor, but for the first open, on a phone whose first open
  /// was not counted here.
  Future<void> note(FirstStep step, DateTime today) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null || taken(step)) return;
    if (step != FirstStep.firstOpen && !taken(FirstStep.firstOpen)) return;
    _taken[step] = (day: dateKey(today), sent: false);
    await _save();
    await _send(step);
  }

  /// Writes the notes back down after something wiped the phone: they are
  /// the phone's, not the reader's (AppState.signOut).
  Future<void> keep() => _save();

  Future<void> _flush() async {
    for (final FirstStep step in FirstStep.values) {
      if (_taken[step] case (day: _, sent: false)) await _send(step);
    }
  }

  /// Steps on their way, so a launch and a return that overlap send once.
  final Set<FirstStep> _sending = {};

  Future<void> _send(FirstStep step) async {
    final StepSink? out = sink;
    final ({String day, bool sent})? was = _taken[step];
    if (out == null || was == null || was.sent || !_sending.add(step)) return;
    try {
      if (!await out.send(step, was.day)) return;
      _taken[step] = (day: was.day, sent: true);
      await _save();
    } finally {
      _sending.remove(step);
    }
  }

  Future<void> _save() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(
        _kKept,
        jsonEncode({
          for (final MapEntry<FirstStep, ({String day, bool sent})> e
              in _taken.entries)
            e.key.wire: {'day': e.value.day, 'sent': e.value.sent},
        }),
      );
    } catch (_) {}
  }
}

/// The steps kept in memory, for tests: what was sent, in order.
class MemoryStepSink implements StepSink {
  /// Every step sent, with its day.
  final List<(FirstStep, String)> sent = [];

  /// Whether the next sends fail, as a server out of reach does.
  bool failing = false;

  @override
  Future<bool> send(FirstStep step, String day) async {
    if (failing) return false;
    sent.add((step, day));
    return true;
  }
}
