// Words from the server in place of the build's own: read as gen-l10n reads
// the arb files and formatted as its code formats them — so the build's own
// words, sent back from the server, read exactly as the build reads them, in
// every language — refused one string at a time, and reaching every screen,
// and the notifications, as soon as a newer document is taken up.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/l10n/remote_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/remote/remote_strings.dart';
import 'package:astuto/state/app_state.dart';

int _docs = 0;

void _take(Map<String, Object?> strings) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'words-${_docs++}',
      'app': <String, Object?>{},
      'strings': strings,
      'explore': null,
      'looks': null,
    }),
  ),
);

Map<String, Object?> _arb(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
        as Map<String, Object?>;

/// The counts every plural rule of the thirteen languages parts at.
const List<int> _counts = [0, 1, 2, 3, 4, 5, 11, 12, 14, 21, 22, 25, 101, 5000];

void main() {
  setUp(() {
    Remote.reset();
    Remote.fetch = (url) async => null;
  });

  tearDown(Remote.reset);

  group('a message', () {
    test('reads text, placeholders, plurals and selects', () {
      final RemoteMessage? m = RemoteMessage.parse(
        '{n, plural, =1{One card} other{{n} cards}} for {who}',
      );
      expect(m, isNotNull);
      expect(m!.names, {'n', 'who'});
      expect(
        m.render('en', {'n': 1, 'who': 'you'}, const {}),
        'One card for you',
      );
      expect(
        m.render('en', {'n': 4, 'who': 'you'}, const {}),
        '4 cards for you',
      );
      expect(
        m.render('en', {'n': 5000, 'who': 'you'}, {'n': '5,000'}),
        '5,000 cards for you',
      );
      final RemoteMessage nested = RemoteMessage.parse(
        '{plan, select, year{{n, plural, =1{a year} other{{n} years}}} '
        'other{a month}}',
      )!;
      expect(
        nested.render('en', {'plan': 'year', 'n': 2}, const {}),
        '2 years',
      );
      expect(
        nested.render('en', {'plan': 'week', 'n': 2}, const {}),
        'a month',
      );
    });

    test('refuses what gen-l10n would refuse, and what the app does not '
        'format', () {
      for (final String bad in [
        'Unclosed {name',
        'A } alone',
        '{n, plural, =1{one}}',
        '{n, plural, =3{three} other{many}}',
        '{s, select, a{x}}',
        '{when, date, ::yMd}',
        '{}',
      ]) {
        expect(RemoteMessage.parse(bad), isNull, reason: bad);
      }
    });

    test('a placeholder of the wrong kind is no message', () {
      final RemoteMessage m = RemoteMessage.parse(
        '{n, plural, =1{one} other{{n}}}',
      )!;
      expect(m.render('en', {'n': 'three'}, const {}), isNull);
      expect(m.render('en', const {}, const {}), isNull);
      final RemoteMessage s = RemoteMessage.parse(
        '{s, select, a{A} other{B}}',
      )!;
      expect(s.render('en', {'s': 3}, const {}), isNull);
    });
  });

  group('the build\'s own words, sent back from the server', () {
    // Every construct the arb files use — a getter, a String, plurals with
    // =0, =1, one, few and many, a select on numbers' names, a select in
    // the middle of a sentence, a number gen-l10n formats — said through
    // the wrapper and through the build, in all thirteen languages.
    const List<String> keys = [
      'appName',
      'couldNotSignInCarryOn',
      'streakDays',
      'sixtyScore',
      'nCards',
      'results',
      'dayWord',
      'nWeeksKept',
      'journeyDays',
      'moodMeta',
      'journeyYears',
      'countWord',
      'rungName',
      'trialCharge',
      'deleteAccountBody',
      'journeyRecallWeeks',
      'gateUpdateLine',
      'gateSoftLine',
    ];

    for (final Locale locale in AppLocalizations.supportedLocales) {
      test('in ${locale.languageCode}', () {
        final String language = locale.languageCode;
        final Map<String, Object?> arb = _arb(language);
        _take({
          language: {for (final String k in keys) k: arb[k]},
        });
        final AppLocalizations build = lookupAppLocalizations(locale);
        final AppLocalizations words = withRemoteWords(build);
        expect(words, isA<RemoteLocalizations>());
        expect(words.localeName, build.localeName);
        expect(words.appName, build.appName);
        expect(
          words.couldNotSignInCarryOn('Apple'),
          build.couldNotSignInCarryOn('Apple'),
        );
        for (final int n in _counts) {
          expect(
            words.streakDays(n),
            build.streakDays(n),
            reason: 'streakDays $n',
          );
          expect(
            words.sixtyScore(n),
            build.sixtyScore(n),
            reason: 'sixtyScore $n',
          );
          expect(words.nCards(n), build.nCards(n), reason: 'nCards $n');
          expect(words.results(n), build.results(n), reason: 'results $n');
          expect(words.dayWord(n), build.dayWord(n), reason: 'dayWord $n');
          expect(
            words.nWeeksKept(n),
            build.nWeeksKept(n),
            reason: 'nWeeksKept $n',
          );
          expect(
            words.journeyDays(n),
            build.journeyDays(n),
            reason: 'journeyDays $n',
          );
          expect(
            words.moodMeta(n, 7),
            build.moodMeta(n, 7),
            reason: 'moodMeta $n',
          );
          expect(
            words.journeyYears(n),
            build.journeyYears(n),
            reason: 'journeyYears $n',
          );
          expect(
            words.journeyRecallWeeks(n, n + 2, n % 5),
            build.journeyRecallWeeks(n, n + 2, n % 5),
            reason: 'journeyRecallWeeks $n',
          );
        }
        for (final String n in ['1', '7', '10', '12', 'many']) {
          expect(
            words.countWord(n),
            build.countWord(n),
            reason: 'countWord $n',
          );
        }
        for (final String id in ['day_one', 'sharp', 'unheard_of']) {
          expect(words.rungName(id), build.rungName(id), reason: id);
        }
        for (final String plan in ['year', 'month']) {
          expect(
            words.trialCharge(14, '€29,99', plan),
            build.trialCharge(14, '€29,99', plan),
          );
        }
        for (final String store in ['apple', 'google', 'other']) {
          expect(
            words.deleteAccountBody(store),
            build.deleteAccountBody(store),
          );
          expect(words.gateUpdateLine(store), build.gateUpdateLine(store));
          expect(words.gateSoftLine(store), build.gateSoftLine(store));
        }
      });
    }
  });

  group('the server\'s words', () {
    test('take the place of the build\'s, one string at a time', () {
      _take({
        'it': {
          'tabToday': 'Adesso',
          'streakDays':
              '{n, plural, =1{un giorno di fila} other{{n} giorni di fila}}',
          'couldNotSignInCarryOn': 'Con {label} non è andata. Continua pure.',
          // Each of these does not read, and only it is the build's.
          'tabExplore': 'Esplora {tutto}',
          'nCards': '{n, plural, =1{una carta}}',
          'results': '{n, plural, =1{uno} other{{count}}}',
          'tabProfile': '',
        },
      });
      final AppLocalizations build = lookupAppLocalizations(const Locale('it'));
      final AppLocalizations words = withRemoteWords(build);
      expect(words.tabToday, 'Adesso');
      expect(words.streakDays(1), 'un giorno di fila');
      expect(words.streakDays(9), '9 giorni di fila');
      expect(
        words.couldNotSignInCarryOn('Google'),
        'Con Google non è andata. Continua pure.',
      );
      expect(words.tabExplore, build.tabExplore);
      expect(words.nCards(3), build.nCards(3));
      expect(words.results(3), build.results(3));
      expect(words.tabProfile, build.tabProfile);
      // Another language has none: the build's own strings, untouched.
      final AppLocalizations de = lookupAppLocalizations(const Locale('de'));
      expect(withRemoteWords(de), same(de));
    });

    test('one wrapper per document and language', () {
      _take({
        'en': {'tabToday': 'Now'},
      });
      final AppLocalizations build = lookupAppLocalizations(const Locale('en'));
      final AppLocalizations first = withRemoteWords(build);
      expect(
        withRemoteWords(lookupAppLocalizations(const Locale('en'))),
        same(first),
      );
      expect(withRemoteWords(first), same(first));
      _take({
        'en': {'tabToday': 'Today, now'},
      });
      final AppLocalizations next = withRemoteWords(build);
      expect(next, isNot(same(first)));
      expect(next.tabToday, 'Today, now');
      _take(const {});
      expect(withRemoteWords(build), same(build));
    });

    testWidgets('reach the screen the moment a newer document is taken up', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => RemoteWordsScope(child: child!),
          // A const screen: nothing above it is built again, and it is told
          // all the same.
          home: const _Tab(),
        ),
      );
      expect(find.text('Today'), findsOneWidget);
      _take({
        'en': {'tabToday': 'This morning'},
      });
      await tester.pump();
      expect(find.text('This morning'), findsOneWidget);
      _take(const {});
      await tester.pump();
      expect(find.text('Today'), findsOneWidget);
    });

    test('reach what is said with no screen: the reminders', () async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final AppState app = AppState(
        hasPermission: () async => true,
        arm: (plan) async {},
        disarm: () async {},
      );
      await app.init();
      final AppLocalizations build = lookupAppLocalizations(const Locale('en'));
      expect(app.reminderPlan().first.title, build.nudgeTitle);
      _take({
        'en': {'nudgeTitle': 'Five new cards are waiting'},
      });
      expect(app.reminderPlan().first.title, 'Five new cards are waiting');
    });
  });
}

class _Tab extends StatelessWidget {
  const _Tab();

  @override
  Widget build(BuildContext context) =>
      Material(child: Text(context.l10n.tabToday));
}
