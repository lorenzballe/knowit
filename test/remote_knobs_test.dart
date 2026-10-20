// The switches, numbers and experiments the server can set: each the
// build's own until the document says otherwise in a way this build can
// take, each read where it matters, and every one of them in the list the
// checker holds documents to.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/remote/knobs.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/widgets/reminder_ask.dart';

int _docs = 0;

void _take(Map<String, Object?> app) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'knobs-${_docs++}',
      'app': app,
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

RemoteContext _at({
  String platform = 'android',
  int build = 12,
  String language = 'en',
}) => RemoteContext(
  platform: platform,
  build: build,
  language: language,
  plus: false,
  daysSinceInstall: 3,
  now: DateTime(2026, 10, 20, 10),
);

/// Every knob the app declares, as the checker's list writes it. A knob
/// added to the code is added here and to tool/remote/parts/app_knobs.json,
/// or the tests below say which is missing.
final List<Object> _declared = [
  AppState.kPushAskFlag,
  AppState.kAccountOfferFlag,
  AppState.kPlaceAskFlag,
  AppState.kReviewAskFlag,
  AppState.kPushAskGapKnob,
  AppState.kPushDeferralsKnob,
  kReminderTimesKnob,
  AppState.kPlaceFirstAskKnob,
  AppState.kPlaceLastAskKnob,
  AppState.kReviewStreakKnob,
  AppState.kPushFirstAskExperiment,
];

Map<String, Object?> _asListed(List<Object> knobs) {
  final Map<String, Object?> flags = {}, tunables = {}, experiments = {};
  for (final Object knob in knobs) {
    switch (knob) {
      case RemoteFlag(:final String name, :final bool fallback):
        flags[name] = {'default': fallback};
      case RemoteNumber(
        :final String name,
        :final int fallback,
        :final int min,
        :final int max,
      ):
        tunables[name] = {
          'type': 'count',
          'default': fallback,
          'min': min,
          'max': max,
        };
      case RemoteTimes(
        :final String name,
        :final List<String> fallback,
        :final List<(String, String)> windows,
      ):
        tunables[name] = {
          'type': 'times',
          'default': fallback,
          'windows': [
            for (final (String, String) w in windows) [w.$1, w.$2],
          ],
        };
      case RemoteExperiment(
        :final String name,
        :final List<String> variants,
        :final String fallback,
      ):
        experiments[name] = {'variants': variants, 'default': fallback};
    }
  }
  return {'flags': flags, 'tunables': tunables, 'experiments': experiments};
}

/// The checker's list, without what is only the checker's: which number
/// must come after which, and the knobs no build reads any more.
Map<String, Object?> _listed() {
  final Map<String, Object?> raw = jsonDecode(
    File('tool/remote/parts/app_knobs.json').readAsStringSync(),
  ) as Map<String, Object?>;
  return {
    for (final MapEntry<String, Object?> kind in raw.entries)
      kind.key: {
        for (final MapEntry<String, Object?> knob
            in (kind.value as Map<String, Object?>).entries)
          if ((knob.value as Map)['retired'] != true)
            knob.key: {
              for (final MapEntry<Object?, Object?> e
                  in (knob.value as Map).entries)
                if (e.key != 'after') e.key: e.value,
            },
      },
  };
}

class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];
  final List<Map<String, Object>> person = [];
  final Map<String, Object> stamped = {};

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
  Future<void> register(String key, Object value) async => stamped[key] = value;

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async => person.add(set);

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

String _day(int fromToday) {
  final DateTime now = DateTime.now();
  return dateKey(DateTime(now.year, now.month, now.day + fromToday));
}

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final AppState state = AppState();
  await state.init();
  return state;
}

void main() {
  setUp(() {
    Remote.reset();
    // The app asks the server as it starts: here nothing answers, so the
    // document in use is the one each test takes up.
    Remote.fetch = (url) async => null;
    Remote.seedForTest = 'seed-knobs';
    Experiments.resetForTest();
  });

  tearDown(() {
    Remote.reset();
    Analytics.useForTest(null);
  });

  group('the list', () {
    test('every knob the app declares is the checker\'s, as it is', () {
      final Map<String, Object?> declared = _asListed(_declared);
      final Map<String, Object?> listed = _listed();
      for (final String kind in ['flags', 'tunables', 'experiments']) {
        expect(
          declared[kind],
          listed[kind],
          reason:
              '$kind: lib/ and tool/remote/parts/app_knobs.json must name the '
              'same knobs, with the same defaults and ranges',
        );
      }
    });

    test('and no knob is declared in lib/ that the list above leaves out', () {
      final RegExp declaration = RegExp(
        r"\b(?:RemoteFlag|RemoteNumber|RemoteTimes|RemoteExperiment)\(\s*'([^']+)'",
      );
      final Set<String> inCode = {
        for (final FileSystemEntity f in Directory(
          'lib',
        ).listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart'))
            for (final RegExpMatch m in declaration.allMatches(
              f.readAsStringSync(),
            ))
              m.group(1)!,
      };
      final Map<String, Object?> declared = _asListed(_declared);
      final Set<String> listed = {
        for (final Object? kind in declared.values)
          ...(kind as Map<String, Object?>).keys,
      };
      expect(inCode, listed);
    });
  });

  group('switches', () {
    const RemoteFlag on = RemoteFlag('push.ask', fallback: true);
    const RemoteFlag off = RemoteFlag('push.ask', fallback: false);

    test('the build\'s own, until the document says otherwise', () {
      expect(on.on(_at()), isTrue);
      expect(off.on(_at()), isFalse);
      _take({'flags': <String, Object?>{}});
      expect(on.on(_at()), isTrue);
      _take({
        'flags': {'push.ask': false},
      });
      expect(on.on(_at()), isFalse);
      _take({
        'flags': {
          'push.ask': {'on': true},
        },
      });
      expect(off.on(_at()), isTrue);
    });

    test('for the readers its audience allows, and the build\'s for the '
        'rest', () {
      _take({
        'flags': {
          'push.ask': {
            'on': false,
            'audience': {
              'platforms': ['ios'],
            },
          },
        },
      });
      expect(on.on(_at(platform: 'ios')), isFalse);
      expect(on.on(_at(platform: 'android')), isTrue);
      expect(off.on(_at(platform: 'android')), isFalse);
    });

    test('a switch written wrong is the build\'s own, and does not take the '
        'others with it', () {
      _take({
        'flags': {
          'push.ask': {'on': 'no'},
          'review.ask': false,
        },
      });
      expect(on.on(_at()), isTrue);
      expect(AppState.kReviewAskFlag.on(_at()), isFalse);
      _take({'flags': 'everything off'});
      expect(on.on(_at()), isTrue);
    });
  });

  group('numbers', () {
    test('within their range, whole when the build\'s is whole', () {
      _take({
        'tunables': {
          'a': 5,
          'b': 31,
          'c': 2.5,
          'd': '4',
          'e': true,
          'f': 4.0,
          'g': 0.25,
        },
      });
      expect(Tunables.number('a', 3, min: 1, max: 30), 5);
      expect(Tunables.number('b', 3, min: 1, max: 30), 3);
      expect(Tunables.number('c', 3, min: 1, max: 30), 3);
      expect(Tunables.number('d', 3, min: 1, max: 30), 3);
      expect(Tunables.number('e', 3, min: 1, max: 30), 3);
      expect(Tunables.number('f', 3, min: 1, max: 30), 4);
      expect(Tunables.number('f', 3, min: 1, max: 30), isA<int>());
      expect(Tunables.number('g', 0.5, min: 0.0, max: 1.0), 0.25);
      expect(Tunables.number('missing', 3), 3);
    });

    test('words and lists', () {
      _take({
        'tunables': {
          'tone': 'warm',
          'blank': ' ',
          'list': ['a', 'b'],
          'mixed': ['a', 1],
        },
      });
      expect(Tunables.string('tone', 'calm'), 'warm');
      expect(Tunables.string('tone', 'calm', oneOf: ['calm', 'bold']), 'calm');
      expect(Tunables.string('blank', 'calm'), 'calm');
      expect(Tunables.list('list', ['x']), ['a', 'b']);
      expect(Tunables.list('list', ['x'], maxLength: 1), ['x']);
      expect(Tunables.list('mixed', ['x']), ['x']);
      expect(
        Tunables.list('list', ['x'], valid: (items) => items.contains('z')),
        ['x'],
      );
    });

    test('the reminder times stay inside their parts of the day', () {
      expect(reminderTimes(), kReminderTimes);
      _take({
        'tunables': {
          'push.times': ['07:45', '13:00', '21:30'],
        },
      });
      expect(reminderTimes(), ['07:45', '13:00', '21:30']);
      // The habit is matched against the server's three.
      expect(reminderTimeFor(7 * 60 + 50), '07:45');
      expect(reminderTimeFor(21 * 60 + 40), '21:30');
      for (final List<String> bad in [
        ['08:30', '12:30'],
        ['08:30', '16:00', '19:00'],
        ['8:30', '12:30', '19:00'],
        ['08:30', '12:30', '23:00'],
      ]) {
        _take({
          'tunables': {'push.times': bad},
        });
        expect(reminderTimes(), kReminderTimes, reason: '$bad');
      }
    });
  });

  group('experiments', () {
    late _Said said;

    setUp(() {
      said = _Said();
      Analytics.useForTest(said);
    });

    test('a variant for every reader its audience allows, the same every '
        'time, said once a sitting', () async {
      SharedPreferences.setMockInitialValues({});
      const RemoteExperiment e = AppState.kPushFirstAskExperiment;
      expect(e.variant(_at()), 'cameBack');
      expect(said.events, isEmpty, reason: 'no experiment, nothing to say');
      _take({
        'experiments': {
          'push.firstAsk': {
            'variants': ['cameBack', 'firstDay'],
            'weights': [0, 1],
          },
        },
      });
      expect(e.variant(_at()), 'firstDay');
      expect(e.variant(_at()), 'firstDay');
      expect(said.of('experiment exposed').single, {
        'experiment': 'push.firstAsk',
        'variant': 'firstDay',
        'remote_hash': Remote.config.hash,
      });
      // On every later event, and on the profile, written with the rest of
      // it as the app leaves.
      expect(said.stamped, {'experiment_push_first_ask': 'firstDay'});
      expect(said.person, isEmpty);
      await Analytics.flushPerson(force: true);
      expect(said.person.single, {'experiment_push_first_ask': 'firstDay'});
      Experiments.sittingEnded();
      expect(e.variant(_at()), 'firstDay');
      expect(said.of('experiment exposed'), hasLength(2));
    });

    test('the split is the phone\'s, by weight', () {
      _take({
        'experiments': {
          'push.firstAsk': {
            'variants': ['cameBack', 'firstDay'],
          },
        },
      });
      final Map<String, int> given = {};
      for (int i = 0; i < 400; i++) {
        Remote.seedForTest = 'phone-$i';
        final String v = AppState.kPushFirstAskExperiment.variant(_at());
        given[v] = (given[v] ?? 0) + 1;
      }
      expect(given['cameBack']! + given['firstDay']!, 400);
      expect(given['firstDay']!, inInclusiveRange(150, 250));
    });

    test('outside its audience, or written wrong, a reader is in no '
        'experiment and nothing is said', () {
      for (final Object? experiment in [
        {
          'variants': ['cameBack', 'firstDay'],
          'audience': {
            'platforms': ['ios'],
          },
        },
        {
          'variants': ['cameBack', 'firstDay'],
          'weights': [1],
        },
        {
          'variants': ['cameBack', 'firstDay'],
          'weights': [0, 0],
        },
        {
          'variants': ['firstDay', 'firstDay'],
        },
        {'variants': <String>[]},
        {
          'variants': ['someNewWay'],
        },
        'firstDay',
      ]) {
        _take({
          'experiments': {'push.firstAsk': experiment},
        });
        expect(
          Experiments.variant(
            'push.firstAsk',
            _at(),
            known: AppState.kPushFirstAskExperiment.variants,
          ),
          isNull,
          reason: '$experiment',
        );
      }
      expect(said.of('experiment exposed'), isEmpty);
    });

    test('its profile property', () {
      expect(
        Experiments.personProperty('push.firstAsk'),
        'experiment_push_first_ask',
      );
      expect(Experiments.personProperty('a.b2C'), 'experiment_a_b2_c');
    });
  });

  group('where they are read', () {
    test(
      'the reminder sheet: held back, its wait, how often it asks',
      () async {
        // Back for a second day, which is finished: the sheet's moment.
        final Map<String, Object> back = {
          'knowit.lastCompletionDate': _day(0),
          'knowit.completedDates': [_day(-1), _day(0)],
        };
        expect((await _app(back)).shouldAskForPush, isTrue);
        _take({
          'flags': {'push.ask': false},
        });
        expect((await _app(back)).shouldAskForPush, isFalse);

        // "Not now" two days ago: the build waits three.
        final Map<String, Object> deferred = {
          ...back,
          'knowit.pushDeferrals': 1,
          'knowit.pushDeferredAfter': _day(-2),
        };
        _take({});
        expect((await _app(deferred)).shouldAskForPush, isFalse);
        _take({
          'tunables': {'push.askGapDays': 2},
        });
        expect((await _app(deferred)).shouldAskForPush, isTrue);

        // Asked three times: the build's last.
        final Map<String, Object> thrice = {
          ...back,
          'knowit.pushDeferrals': 3,
          'knowit.pushDeferredAfter': _day(-9),
        };
        _take({});
        expect((await _app(thrice)).shouldAskForPush, isFalse);
        _take({
          'tunables': {'push.deferralsAllowed': 4},
        });
        expect((await _app(thrice)).shouldAskForPush, isTrue);
      },
    );

    test('the reminder sheet on the very first evening, for the readers the '
        'experiment gives it to', () async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      final Map<String, Object> firstDay = {
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(0)],
      };
      expect((await _app(firstDay)).shouldAskForPush, isFalse);
      expect(said.of('experiment exposed'), isEmpty);
      _take({
        'experiments': {
          'push.firstAsk': {
            'variants': ['cameBack', 'firstDay'],
            'weights': [0, 1],
          },
        },
      });
      expect((await _app(firstDay)).shouldAskForPush, isTrue);
      expect(said.of('experiment exposed').single['variant'], 'firstDay');
      // Not read before the day is done, nor once the reader has come back:
      // the two part ways on the first evening only.
      Experiments.sittingEnded();
      said.events.clear();
      final AppState morning = await _app({
        'knowit.lastCompletionDate': _day(-1),
        'knowit.completedDates': [_day(-1)],
      });
      expect(morning.shouldAskForPush, isFalse);
      final AppState returned = await _app({
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(-1), _day(0)],
      });
      expect(returned.shouldAskForPush, isTrue);
      expect(said.of('experiment exposed'), isEmpty);
      _take({
        'experiments': {
          'push.firstAsk': {
            'variants': ['cameBack', 'firstDay'],
            'weights': [1, 0],
          },
        },
      });
      expect((await _app(firstDay)).shouldAskForPush, isFalse);
    });

    test('the rating prompt: its streak, and held back', () async {
      final Map<String, Object> five = {
        'knowit.streak': 5,
        'knowit.lastCompletionDate': _day(0),
        'knowit.pushAsked': true,
      };
      expect((await _app(five)).shouldAskForReview, isFalse);
      _take({
        'tunables': {'review.streakDays': 5},
      });
      expect((await _app(five)).shouldAskForReview, isTrue);
      _take({
        'tunables': {'review.streakDays': 5},
        'flags': {'review.ask': false},
      });
      expect((await _app(five)).shouldAskForReview, isFalse);
      // A question about notifications the server holds back is not one
      // the rating waits for.
      _take({
        'tunables': {'review.streakDays': 5},
        'flags': {'push.ask': false},
      });
      final AppState neverAsked = await _app({
        'knowit.streak': 5,
        'knowit.lastCompletionDate': _day(0),
      });
      expect(neverAsked.shouldAskForReview, isTrue);
    });

    test('the account\'s offer, held back', () async {
      final Map<String, Object> back = {
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(-1), _day(0)],
      };
      expect((await _app(back)).shouldOfferAccount, isTrue);
      _take({
        'flags': {'account.offer': false},
      });
      expect((await _app(back)).shouldOfferAccount, isFalse);
    });

    test('the place\'s sheet: its days, and held back', () async {
      final Map<String, Object> oneDay = {
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [_day(0)],
      };
      expect((await _app(oneDay)).shouldAskForPlace, isFalse);
      _take({
        'tunables': {'place.firstAskDay': 1},
      });
      expect((await _app(oneDay)).shouldAskForPlace, isTrue);
      _take({
        'tunables': {'place.firstAskDay': 1},
        'flags': {'place.ask': false},
      });
      expect((await _app(oneDay)).shouldAskForPlace, isFalse);

      // Said "Not now" once, five days finished since: the build waits for
      // a seventh.
      final Map<String, Object> five = {
        'knowit.lastCompletionDate': _day(0),
        'knowit.completedDates': [for (int i = -4; i <= 0; i++) _day(i)],
        'knowit.placeAsks': 1,
        'knowit.placeDeferredAfter': _day(-1),
      };
      _take({});
      expect((await _app(five)).shouldAskForPlace, isFalse);
      _take({
        'tunables': {'place.lastAskDay': 5},
      });
      expect((await _app(five)).shouldAskForPlace, isTrue);
    });
  });
}
