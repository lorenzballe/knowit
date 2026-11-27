/// Invita un amico (functions/src/invite.ts): a reader sends a friend a link
/// with a code of their own, and the friend, on an account that is new and
/// has never held Astute+, uses it — from the link, which the phone hands to
/// the app (lib/utils/widget_open.dart), or typed in the profile. When the
/// friend finishes their first day, the five cards, each of the two is given
/// a week of Astute+ through RevenueCat; the app reads the customer again at
/// once, so Astute+ shows without waiting for the next launch.
///
/// Behind the server's switch `invite` ([AppState.kInviteFlag], off as
/// built), only where the app can take part at all ([Invites.reachable]: a
/// phone with Firebase and a store), and only while the server says
/// invitations are set up: without RevenueCat's key the functions answer
/// "not configured" and the invitation stays hidden.
///
/// The code is never measured and never written anywhere but the server:
/// the events say what happened, not with which code (docs/TRACKING.md).
library;

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import '../cloud.dart';
import 'served.dart' show kFunctionsRegion;
import 'subscription.dart';

/// What a code is drawn from (functions/src/invite.ts, CODE_ALPHABET): the
/// digits from 2 and the consonants but L, so no word and nothing that reads
/// as another.
const String kInviteAlphabet = '23456789BCDFGHJKMNPQRSTVWXYZ';

/// How long a code is.
const int kInviteCodeLength = 6;

/// [raw] as a code, the way a reader may type or paste it — any case, spaces
/// and dashes anywhere — or null when it is not one.
String? readInviteCode(String? raw) {
  if (raw == null || raw.length > 40) return null;
  final String code = raw.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '');
  if (code.length != kInviteCodeLength) return null;
  for (final String ch in code.split('')) {
    if (!kInviteAlphabet.contains(ch)) return null;
  }
  return code;
}

/// Whether a code of a friend's may still be used, or where the one used
/// stands: the server's word.
enum InviteRedeem {
  /// A new account that has used none: "Have a code?" is offered.
  open,

  /// Not any more: an account older than a week.
  closed,

  /// Taken; the week waits on the first day.
  waiting,

  /// Being given.
  granting,

  /// Given.
  granted,
}

/// Why a code was not taken.
enum InviteRefusal {
  /// No such code.
  unknown,

  /// The reader's own.
  own,

  /// The reader used one already.
  used,

  /// The account is more than a week old.
  late,

  /// The account has held Astute+.
  plus,
}

/// What the app knows of the reader's invitations.
@immutable
class InviteState {
  const InviteState({
    this.code,
    this.weeks = 0,
    this.cap = 8,
    this.friends = 0,
    this.redeem = InviteRedeem.closed,
    this.until,
    this.granted = false,
  });

  /// The reader's own code, once made.
  final String? code;

  /// The weeks friends earned the reader in the last 365 days, and the most
  /// there may be.
  final int weeks;
  final int cap;

  /// The friends who finished a first day with the code.
  final int friends;

  final InviteRedeem redeem;

  /// When the reader's own week from a friend's code ends, once given.
  final DateTime? until;

  /// Given by the very call that brought this.
  final bool granted;

  /// The year's weeks are all given: a friend still has theirs.
  bool get capped => weeks >= cap;

  /// What the server sent, read; null for anything else.
  static InviteState? read(Object? data) {
    if (data is! Map) return null;
    final Object? code = data['code'];
    final Object? until = data['until'];
    int count(Object? v, int fallback) => v is num ? v.toInt() : fallback;
    return InviteState(
      code: code is String ? readInviteCode(code) : null,
      weeks: count(data['weeks'], 0),
      cap: count(data['cap'], 8),
      friends: count(data['friends'], 0),
      redeem:
          InviteRedeem.values.asNameMap()[data['redeem']] ??
          InviteRedeem.closed,
      until: until is num
          ? DateTime.fromMillisecondsSinceEpoch(until.toInt())
          : null,
      granted: data['granted'] == true,
    );
  }
}

/// How a code used came out.
sealed class InviteAnswer {
  const InviteAnswer();
}

/// Taken: the week waiting on the first day, or given ([granted]) already.
final class InviteTaken extends InviteAnswer {
  const InviteTaken(this.redeem, {this.until, this.granted = false});
  final InviteRedeem redeem;
  final DateTime? until;
  final bool granted;
}

/// Not taken, and why.
final class InviteRefused extends InviteAnswer {
  const InviteRefused(this.why);
  final InviteRefusal why;
}

/// No answer: no network, a server that failed, or invitations not set up.
final class InviteNoAnswer extends InviteAnswer {
  const InviteNoAnswer();
}

/// The two functions, as the app calls them. A test brings its own.
abstract class InviteServer {
  /// The reader's invitations ([make]: their code made if they have none).
  /// Null when the server could not be reached.
  Future<Object?> state({required bool make});

  /// [code] used. Null when the server could not be reached.
  Future<Object?> redeem(String code);
}

/// The callable functions in europe-west1.
class FirebaseInviteServer implements InviteServer {
  const FirebaseInviteServer();

  Future<Object?> _call(String name, Map<String, Object?> data) async {
    try {
      final result =
          await FirebaseFunctions.instanceFor(region: kFunctionsRegion)
              .httpsCallable(
                name,
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 30),
                ),
              )
              .call<Object?>(data);
      return result.data;
    } catch (error) {
      debugPrint('Invitations: $name did not answer: $error');
      return null;
    }
  }

  @override
  Future<Object?> state({required bool make}) =>
      _call('inviteState', {'make': make});

  @override
  Future<Object?> redeem(String code) => _call('redeemInvite', {'code': code});
}

/// The reader's invitations: their code and their weeks, a friend's code
/// held from a link or used, and the week it brings once the first day is
/// done.
class Invites extends ChangeNotifier {
  Invites({this.serverOverride, this.reachableOverride, this.planOverride});

  /// The app's invitations; a test puts its own here.
  static Invites instance = Invites();

  @visibleForTesting
  static void useForTest(Invites value) => instance = value;

  /// Stand-ins for the tests: the server, whether the build can take part,
  /// and reading the plan again. Null in the app.
  final InviteServer? serverOverride;
  final bool? reachableOverride;
  final Future<void> Function()? planOverride;

  InviteServer get _ask => serverOverride ?? const FirebaseInviteServer();

  /// Whether this build can take part: a phone where Firebase started and a
  /// store is built in, so a week given shows as Astute+. The web app and a
  /// fork cannot.
  bool get reachable =>
      reachableOverride ?? (Cloud.ready && Subscription.instance.hasStore);

  /// The server said invitations are not set up (no RevenueCat key): hidden
  /// until the app starts again.
  bool get unconfigured => _unconfigured;
  bool _unconfigured = false;

  /// What the server last said; null before it has.
  InviteState? get state => _state;
  InviteState? _state;

  /// A code from a link, kept until it is used or refused.
  String? get held => _held;
  String? _held;

  /// A code taken whose week waits on the first day: asked again when a day
  /// is finished, and at the next launch.
  bool get waiting => _waiting;
  bool _waiting = false;

  /// The end of a week a friend's code gave, not yet shown to the reader:
  /// the moment rises once, at a quiet moment (showInviteWeekIfDue).
  DateTime? get unseen => _unseen;
  DateTime? _unseen;

  /// Weeks friends earned the reader since the profile last said so.
  int get newWeeks => _newWeeks;
  int _newWeeks = 0;

  /// The weeks already said, and whether the phone knows them: a phone that
  /// does not yet (a new install, a sign-in) takes the server's count as
  /// said rather than announce weeks long given.
  int _weeksSeen = 0;
  bool _weeksKnown = false;
  bool _restored = false;

  /// Before asking whether the first day is done: the backup written, so
  /// the server reads the day the phone just finished. Set by the app.
  Future<void> Function()? beforeSettle;

  static const String _kHeld = 'knowit.invite.held';
  static const String _kWaiting = 'knowit.invite.waiting';
  static const String _kUnseen = 'knowit.invite.unseen';
  static const String _kWeeksSeen = 'knowit.invite.weeksSeen';

  /// Picks up what the phone kept: a code held, a week waited for or not yet
  /// shown, the weeks already said.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _held = readInviteCode(prefs.getString(_kHeld)) ?? _held;
      _waiting = prefs.getBool(_kWaiting) ?? _waiting;
      final int? unseen = prefs.getInt(_kUnseen);
      if (unseen != null) {
        _unseen = DateTime.fromMillisecondsSinceEpoch(unseen);
      }
      final int? seen = prefs.getInt(_kWeeksSeen);
      if (seen != null) {
        _weeksSeen = seen;
        _weeksKnown = true;
      }
    } catch (_) {
      // Nothing kept, nothing waiting: the server says the rest.
    }
    notifyListeners();
  }

  Future<void> _keep() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? held = _held;
      held == null
          ? await prefs.remove(_kHeld)
          : await prefs.setString(_kHeld, held);
      await prefs.setBool(_kWaiting, _waiting);
      final DateTime? unseen = _unseen;
      unseen == null
          ? await prefs.remove(_kUnseen)
          : await prefs.setInt(_kUnseen, unseen.millisecondsSinceEpoch);
      await prefs.setInt(_kWeeksSeen, _weeksSeen);
    } catch (_) {}
  }

  /// A code from a link, kept until it is used: the link can come before
  /// the first run is over, or before there is an account to use it with.
  void hold(String? raw) {
    final String? code = readInviteCode(raw);
    if (code == null || code == _held) return;
    _held = code;
    unawaited(_keep());
    notifyListeners();
  }

  Future<InviteState?>? _asking;
  DateTime? _heard;

  /// How long an answer stands before the profile asks again: a box built
  /// again as the list scrolls is not a reason to call the server.
  static const Duration fresh = Duration(minutes: 2);

  /// Asks the server for the reader's invitations; [make] makes their code
  /// if they have none, and [force] asks even when the last answer is
  /// [fresh]. A week given by this very call, or by one whose answer was
  /// lost while the phone waited for it, is kept to be shown, and the
  /// customer read again so Astute+ shows at once; weeks friends earned the
  /// reader since the last ask are said the same way.
  Future<InviteState?> refresh({bool make = false, bool force = false}) {
    final DateTime? heard = _heard;
    if (!make &&
        !force &&
        _state != null &&
        heard != null &&
        DateTime.now().difference(heard) < fresh) {
      return Future<InviteState?>.value(_state);
    }
    if (!make && _asking != null) return _asking!;
    final Future<InviteState?> asking = _refresh(make);
    if (!make) {
      _asking = asking;
      asking.whenComplete(() => _asking = null);
    }
    return asking;
  }

  Future<InviteState?> _refresh(bool make) async {
    final Object? data = await _ask.state(make: make);
    _heard = DateTime.now();
    if (data is Map && data['none'] == 'unconfigured') {
      _unconfigured = true;
      notifyListeners();
      return null;
    }
    final InviteState? state = InviteState.read(data);
    if (state == null) return null;
    _unconfigured = false;
    final bool wasWaiting = _waiting;
    _state = state;
    if (state.redeem == InviteRedeem.waiting ||
        state.redeem == InviteRedeem.granting) {
      _waiting = true;
    } else if (state.redeem == InviteRedeem.granted &&
        (state.granted || wasWaiting)) {
      _waiting = false;
      await _given(state.until);
    } else {
      _waiting = false;
    }
    if (_weeksKnown && state.weeks > _weeksSeen && state.code != null) {
      final int more = state.weeks - _weeksSeen;
      _newWeeks += more;
      Analytics.capture('invite reward granted', {
        'side': 'inviter',
        'weeks': state.weeks,
        'new_weeks': more,
        'capped': state.capped,
      });
      await _plan();
    }
    _weeksSeen = state.weeks;
    _weeksKnown = true;
    await _keep();
    notifyListeners();
    return state;
  }

  /// The week a friend's code gave the reader: kept to be shown, and the
  /// plan read again.
  Future<void> _given(DateTime? until) async {
    _unseen = until ?? DateTime.now().add(const Duration(days: 7));
    Analytics.capture('invite reward granted', {'side': 'friend'});
    await _plan();
  }

  Future<void> _plan() async {
    try {
      await (planOverride?.call() ??
          Subscription.instance.refreshCustomerInfo());
    } catch (_) {}
  }

  Future<InviteState?>? _settling;

  /// After a finished day, while a code taken waits for one: the backup
  /// written, then the server asked, which gives the two weeks if the day is
  /// there. One ask at a time; a second caller gets the same answer.
  Future<InviteState?> settle() {
    if (!_waiting) return Future<InviteState?>.value(_state);
    return _settling ??= () async {
      try {
        await beforeSettle?.call();
      } catch (_) {}
      return refresh(force: true);
    }().whenComplete(() => _settling = null);
  }

  /// [raw] used, from a link or typed ([from]: `link`, `typed`): refused,
  /// with the reason, taken, or no answer. Never measured with the code.
  Future<InviteAnswer> redeem(String raw, {required String from}) async {
    final String? code = readInviteCode(raw);
    if (code == null) {
      _said(from, 'refused', reason: InviteRefusal.unknown.name);
      return const InviteRefused(InviteRefusal.unknown);
    }
    final Object? data = await _ask.redeem(code);
    if (data is Map && data['none'] == 'unconfigured') {
      _unconfigured = true;
      notifyListeners();
      _said(from, 'unavailable');
      return const InviteNoAnswer();
    }
    if (data is! Map) {
      _said(from, 'unavailable');
      return const InviteNoAnswer();
    }
    final InviteRefusal? why = InviteRefusal.values
        .asNameMap()[data['refused']];
    if (why != null) {
      // A code refused is let go, so it is not offered again.
      if (_held == code) _held = null;
      await _keep();
      notifyListeners();
      _said(from, 'refused', reason: why.name);
      return InviteRefused(why);
    }
    final InviteRedeem? state = InviteRedeem.values.asNameMap()[data['state']];
    if (state == null) {
      _said(from, 'unavailable');
      return const InviteNoAnswer();
    }
    final Object? until = data['until'];
    final DateTime? ends = until is num
        ? DateTime.fromMillisecondsSinceEpoch(until.toInt())
        : null;
    final bool granted = data['granted'] == true;
    _held = null;
    _waiting = state == InviteRedeem.waiting || state == InviteRedeem.granting;
    _state = InviteState(
      code: _state?.code,
      weeks: _state?.weeks ?? 0,
      cap: _state?.cap ?? 8,
      friends: _state?.friends ?? 0,
      redeem: state,
      until: ends,
      granted: granted,
    );
    _said(from, granted ? 'granted' : state.name);
    if (granted) await _given(ends);
    await _keep();
    notifyListeners();
    return InviteTaken(state, until: ends, granted: granted);
  }

  void _said(String from, String outcome, {String? reason}) {
    Analytics.capture('invite code redeemed', {
      'from': from,
      'outcome': outcome,
      'reason': reason,
    });
  }

  /// The week's moment has been shown: it does not rise again.
  Future<void> seen() async {
    _unseen = null;
    await _keep();
    notifyListeners();
  }

  /// The new weeks have been said on the profile.
  void saidNewWeeks() {
    if (_newWeeks == 0) return;
    _newWeeks = 0;
    notifyListeners();
  }

  /// A reader signing out: nothing of theirs stays on the phone.
  Future<void> reset() async {
    _state = null;
    _held = null;
    _waiting = false;
    _unseen = null;
    _newWeeks = 0;
    _weeksSeen = 0;
    _weeksKnown = false;
    _unconfigured = false;
    _heard = null;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (final String key in [_kHeld, _kWaiting, _kUnseen, _kWeeksSeen]) {
        await prefs.remove(key);
      }
    } catch (_) {}
    notifyListeners();
  }
}
