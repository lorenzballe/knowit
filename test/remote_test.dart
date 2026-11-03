// The remote document: what the server says about the app, kept on the
// phone and taken up the moment a newer one arrives — and the one rule every
// part aims things with.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/remote/remote.dart';

String _doc(String hash, {int schema = 1, String app = '{}'}) =>
    '{"schema": $schema, "hash": "$hash", "app": $app, "strings": {}, '
    '"explore": null, "looks": null}';

RemoteContext _at({
  String platform = 'ios',
  int build = 12,
  String language = 'it',
  bool plus = false,
  int days = 3,
  DateTime? now,
}) => RemoteContext(
  platform: platform,
  build: build,
  language: language,
  plus: plus,
  daysSinceInstall: days,
  now: now ?? DateTime(2026, 10, 20, 21, 30),
);

void main() {
  // These tests are of the document the build embeds, and start from it.
  final RemoteConfig? baseline = Remote.baseline;
  setUpAll(() => Remote.baseline = null);
  tearDownAll(() => Remote.baseline = baseline);

  setUp(() {
    Remote.reset();
    Remote.seedForTest = 'seed-a';
  });

  group('the document', () {
    test('the one built in reads, and is the one in use at first', () {
      expect(Remote.embedded.schema, kRemoteSchema);
      expect(Remote.embedded.hash, isNotEmpty);
      expect(Remote.config.hash, Remote.embedded.hash);
      expect(Remote.config.part('app'), isA<Map<String, Object?>>());
    });

    test('a document is refused whole when it is not one this build reads', () {
      expect(() => RemoteConfig.parse('[]'), throwsFormatException);
      expect(
        () => RemoteConfig.parse('{"schema": 1, "app": {}}'),
        throwsFormatException,
        reason: 'no hash',
      );
      expect(
        () => RemoteConfig.parse(_doc('h', schema: kRemoteSchema + 1)),
        throwsFormatException,
        reason: 'a later schema',
      );
      final RemoteConfig ok = RemoteConfig.parse(_doc('h1', app: '{"a": 1}'));
      expect(ok.part('app'), {'a': 1});
      expect(ok['explore'], isNull);
      expect(ok.part('missing'), isEmpty);
    });
  });

  group('kept and taken up', () {
    test('restored from the phone, with a seed of its own', () async {
      SharedPreferences.setMockInitialValues({'knowit.remote': _doc('kept')});
      final prefs = await SharedPreferences.getInstance();
      final int before = Remote.revision.value;
      Remote.restore(prefs);
      expect(Remote.config.hash, 'kept');
      expect(Remote.revision.value, before + 1);
      expect(prefs.getString('knowit.remoteSeed'), hasLength(16));
      expect(Remote.seed, prefs.getString('knowit.remoteSeed'));
    });

    test('a stored document that no longer reads is forgotten', () async {
      SharedPreferences.setMockInitialValues({'knowit.remote': '{"nope": 1}'});
      final prefs = await SharedPreferences.getInstance();
      Remote.restore(prefs);
      expect(Remote.config.hash, Remote.embedded.hash);
      expect(prefs.getString('knowit.remote'), isNull);
    });

    test('the note first; the document only when it names another', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final asked = <String>[];
      Remote.fetch = (url) async {
        asked.add(url);
        return url == kRemoteVersionUrl
            ? '{"schema": 1, "hash": "${Remote.embedded.hash}"}'
            : _doc('never');
      };
      expect(await Remote.refresh(prefs, force: true), isFalse);
      expect(asked, [kRemoteVersionUrl]);

      asked.clear();
      Remote.fetch = (url) async {
        asked.add(url);
        return url == kRemoteVersionUrl
            ? '{"schema": 1, "hash": "next"}'
            : _doc('next', app: '{"flags": {"x": true}}');
      };
      final int before = Remote.revision.value;
      expect(await Remote.refresh(prefs, force: true), isTrue);
      expect(asked, [kRemoteVersionUrl, kRemoteUrl]);
      expect(Remote.config.hash, 'next');
      expect(Remote.config.part('app')['flags'], {'x': true});
      expect(Remote.revision.value, before + 1);
      expect(
        RemoteConfig.parse(prefs.getString('knowit.remote')!).hash,
        'next',
      );
    });

    test(
      'no answer, a broken document or a later schema change nothing',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        for (final String? body in [
          null,
          '{"schema": 1',
          _doc('later', schema: kRemoteSchema + 1),
        ]) {
          Remote.fetch = (url) async => url == kRemoteVersionUrl ? null : body;
          expect(await Remote.refresh(prefs, force: true), isFalse);
          expect(Remote.config.hash, Remote.embedded.hash);
          expect(prefs.getString('knowit.remote'), isNull);
        }
        Remote.fetch = (url) async => throw Exception('offline');
        expect(await Remote.refresh(prefs, force: true), isFalse);
      },
    );

    test('asked at most twice a minute, unless forced', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      int asks = 0;
      Remote.fetch = (url) async {
        asks++;
        return '{"schema": 1, "hash": "${Remote.embedded.hash}"}';
      };
      await Remote.refresh(prefs);
      await Remote.refresh(prefs);
      expect(asks, 1);
      await Remote.refresh(prefs, force: true);
      expect(asks, 2);
    });
  });

  group('who a thing is for', () {
    test('no rule is everybody; a rule that is not an object is nobody', () {
      expect(Audience.allows(null, _at()), isTrue);
      expect(Audience.allows(const <String, Object?>{}, _at()), isTrue);
      expect(Audience.allows('everyone', _at()), isFalse);
    });

    test('platform, build, language, plan and days', () {
      expect(
        Audience.allows({
          'platforms': ['ios'],
        }, _at()),
        isTrue,
      );
      expect(
        Audience.allows({
          'platforms': ['android'],
        }, _at()),
        isFalse,
      );
      expect(Audience.allows({'minBuild': 12}, _at()), isTrue);
      expect(Audience.allows({'minBuild': 13}, _at()), isFalse);
      expect(Audience.allows({'maxBuild': 11}, _at()), isFalse);
      expect(
        Audience.allows({
          'languages': ['it', 'es'],
        }, _at()),
        isTrue,
      );
      expect(
        Audience.allows({
          'languages': ['en'],
        }, _at()),
        isFalse,
      );
      expect(Audience.allows({'plus': true}, _at(plus: true)), isTrue);
      expect(Audience.allows({'plus': true}, _at()), isFalse);
      expect(Audience.allows({'plus': false}, _at()), isTrue);
      expect(Audience.allows({'minDays': 2, 'maxDays': 7}, _at()), isTrue);
      expect(Audience.allows({'minDays': 4}, _at()), isFalse);
    });

    test('dates, weekdays and hours, on the phone\'s calendar', () {
      final DateTime tuesdayEvening = DateTime(2026, 10, 20, 21, 30);
      final RemoteContext at = _at(now: tuesdayEvening);
      expect(
        Audience.allows({'from': '2026-10-20', 'until': '2026-10-20'}, at),
        isTrue,
      );
      expect(Audience.allows({'from': '2026-10-21'}, at), isFalse);
      expect(Audience.allows({'until': '2026-10-19'}, at), isFalse);
      expect(Audience.allows({'from': 'tomorrow'}, at), isFalse);
      expect(
        Audience.allows({
          'weekdays': [2],
        }, at),
        isTrue,
      );
      expect(
        Audience.allows({
          'weekdays': [6, 7],
        }, at),
        isFalse,
      );
      expect(
        Audience.allows({
          'hours': [18, 23],
        }, at),
        isTrue,
      );
      expect(
        Audience.allows({
          'hours': [6, 12],
        }, at),
        isFalse,
      );
      expect(
        Audience.allows({
          'hours': [22, 3],
        }, at),
        isFalse,
      );
      expect(
        Audience.allows({
          'hours': [22, 3],
        }, _at(now: DateTime(2026, 10, 21, 1))),
        isTrue,
        reason: 'across midnight',
      );
    });

    test('all, any and not', () {
      expect(
        Audience.allows({
          'any': [
            {
              'languages': ['en'],
            },
            {'plus': false},
          ],
        }, _at()),
        isTrue,
      );
      expect(
        Audience.allows({
          'all': [
            {
              'languages': ['it'],
            },
            {'plus': true},
          ],
        }, _at()),
        isFalse,
      );
      expect(
        Audience.allows({
          'not': {
            'platforms': ['web'],
          },
        }, _at()),
        isTrue,
      );
    });

    test('a key this build does not know keeps the thing from it', () {
      expect(Audience.allows({'country': 'IT'}, _at()), isFalse);
      expect(
        Audience.allows({
          'languages': ['it'],
          'moonPhase': 'full',
        }, _at()),
        isFalse,
      );
    });

    test('a rollout is a share of phones, the same phone every time', () {
      int inside = 0;
      for (int i = 0; i < 2000; i++) {
        Remote.seedForTest = 'phone-$i';
        if (Audience.allows({'rollout': 25}, _at(), salt: 'new-explore')) {
          inside++;
        }
      }
      expect(inside, inInclusiveRange(400, 600));
      Remote.seedForTest = 'phone-7';
      final bool first = Audience.allows({'rollout': 50}, _at(), salt: 'x');
      for (int i = 0; i < 5; i++) {
        expect(Audience.allows({'rollout': 50}, _at(), salt: 'x'), first);
      }
      expect(Audience.allows({'rollout': 0}, _at(), salt: 'x'), isFalse);
      expect(Audience.allows({'rollout': 100}, _at(), salt: 'x'), isTrue);
    });

    test('an experiment gives each phone one variant, by weight', () {
      final counts = <String, int>{'a': 0, 'b': 0};
      for (int i = 0; i < 3000; i++) {
        Remote.seedForTest = 'phone-$i';
        final String v = Audience.variantOf('paywall-copy', ['a', 'b'], [1, 3]);
        counts[v] = counts[v]! + 1;
      }
      expect(counts['a'], inInclusiveRange(600, 900));
      Remote.seedForTest = 'phone-3';
      final String once = Audience.variantOf('paywall-copy', ['a', 'b']);
      expect(Audience.variantOf('paywall-copy', ['a', 'b']), once);
      expect(Audience.variantOf('x', const []), '');
    });
  });
}
