// Photographs Your journey for a reader on the free plan, before and after
// the preview (`journey.preview`): before, the plans the journey's door
// opened on, with nothing of the journey shown; after, the reader's own
// journey behind its veil, one figure in the clear. For a reader of two
// days and one of ten, at night and on paper. Then the first reading of
// how sure against how right on the profile (`calibration.early`), Sunday's
// week over the finished day (`week.sunday`) with its one blurred figure
// and its line for the account, the sign-in sheet that line opens, and the
// preview, the week and the profile in German on the 320-wide phone.
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/journey_preview_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// real screens on a 390 × 844 phone at three pixels a point, with an
// iPhone's notch and home bar, and their shadows soft as a phone draws
// them. The readers are made of real cards from the bank; every figure on
// the pages is worked out from their answers, as on a phone.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/today_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/progress.dart' show mondayOf;
import 'package:astuto/state/your_week.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/sign_in_sheet.dart';
import 'package:astuto/widgets/your_week_sheet.dart';

import '../test/explore/core_harness.dart' show loadFonts;

final String _out = Platform.environment['SHOTS'] ?? 'shots/journey-preview';
final Locale _locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');

const Size _phone = Size(390, 844);
const Size _small = Size(320, 568);

DateTime get _today {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// The date key [d] days before today.
String _ago(int d) =>
    dateKey(DateTime(_today.year, _today.month, _today.day - d));

/// Cards in words of [topic] that ask to pick one, not long of question,
/// [n] of them after the first [skip].
List<Pill> _of(String topic, int n, {int skip = 0}) {
  final List<Pill> out = [
    for (final Pill p in PillBank.live)
      if (p.topic == topic &&
          p.web == null &&
          !p.isAboutAPlace &&
          p.challenge is PickOne)
        p,
  ];
  if (out.length < n + skip) throw StateError('too few cards of $topic');
  return out.skip(skip).take(n).toList();
}

/// A reader's record, built up a day at a time: the cards read on each day,
/// and the answers given on them, said how sure or not, in order.
class _Reader {
  final Map<String, List<String>> readDays = {};
  final Map<String, Map<String, Object>> answers = {};
  final List<(String, Map<String, Object>)> judgements = [];

  void read(int daysAgo, Pill p) =>
      readDays.putIfAbsent(_ago(daysAgo), () => []).add(p.id);

  void answer(
    Pill p,
    int daysAgo, {
    required bool right,
    int? sure,
    int? stage,
  }) {
    final PickOne pick = p.challenge as PickOne;
    final int r = right
        ? pick.correct
        : (pick.correct + 1) % pick.options.length;
    final int climbed = stage ?? (right ? 1 : 0);
    answers[p.id] = {
      'r': '$r',
      'c': ?sure,
      's': climbed,
      'd': _ago(daysAgo - (right ? 7 : 2)),
    };
    judgements.add((
      _ago(daysAgo),
      {'c': ?sure, 'k': right, 'p': p.id, 'd': _ago(daysAgo)},
    ));
  }

  Map<String, Object> prefs({
    required bool plus,
    required int streak,
    required List<String> today,
    Map<String, Object> more = const {},
  }) {
    final List<String> days = readDays.keys.toList()..sort();
    final List<Map<String, Object>> said = [
      for (final (String, Map<String, Object>) j
          in judgements.toList()..sort((a, b) => a.$1.compareTo(b.$1)))
        j.$2,
    ];
    return {
      'knowit.onboarded': true,
      'knowit.plus': plus,
      'knowit.streak': streak,
      'knowit.bestStreak': streak,
      'knowit.lastCompletionDate': _ago(0),
      'knowit.completedDates': days,
      'knowit.seenIds': [for (final d in days) ...readDays[d]!],
      'knowit.readDays': jsonEncode(readDays),
      'knowit.deckHistory': jsonEncode(readDays),
      'knowit.answersJson': jsonEncode(answers),
      'knowit.judgements': jsonEncode(said),
      'knowit.dayLog': jsonEncode({
        for (final String d in days)
          d: [0, 70 * readDays[d]!.length, readDays[d]!.length, 0, 0, 0],
      }),
      'knowit.todayDate': _ago(0),
      'knowit.todayDeckIds': today,
      'knowit.todayIndex': today.length,
      // Every level told, and every sheet the finished day can raise put
      // already: the camera photographs what it opens, not what rises.
      'knowit.levelTold': 99,
      'knowit.pushAsked': true,
      'knowit.widgetAsked': true,
      'knowit.accountOffered': true,
      'knowit.reviewAsked': true,
      'knowit.reviewAsks': 1,
      'knowit.goalAsked': true,
      'knowit.placeAsks': 9,
      ...more,
    };
  }
}

/// A reader of two days: yesterday and today, five cards each; four of each
/// day's answered, one of them said 80% sure, and right, each day.
Map<String, Object> _twoDays({Map<String, Object> more = const {}}) {
  final _Reader r = _Reader();
  final List<Pill> cards = [
    ..._of('History', 3),
    ..._of('Science', 3),
    ..._of('Psychology', 2),
    ..._of('Life', 2),
  ];
  for (var i = 0; i < 10; i++) {
    r.read(i < 5 ? 1 : 0, cards[i]);
  }
  for (final (int i, Pill p) in cards.indexed) {
    if (i % 5 == 4) continue;
    final int day = i < 5 ? 1 : 0;
    final bool sure = i == 1 || i == 6;
    r.answer(p, day, right: sure || i % 3 != 0, sure: sure ? 80 : null);
  }
  return r.prefs(
    plus: false,
    streak: 2,
    today: [for (final p in cards.skip(5)) p.id],
    more: more,
  );
}

/// A reader of ten days, five cards a day: History their strongest, Life
/// the one they miss most and are surest of, fourteen answers said how
/// sure, cards come back after two days and after a week, two held.
Map<String, Object> _tenDays({
  bool plus = false,
  Map<String, Object> more = const {},
}) {
  final _Reader r = _Reader();
  final List<Pill> history = _of('History', 10);
  final List<Pill> life = _of('Life', 9);
  final List<Pill> science = _of('Science', 8);
  final List<Pill> psychology = _of('Psychology', 8);
  final List<Pill> economics = _of('Economics', 8);
  final List<Pill> space = _of('Space', 7);
  final List<List<Pill>> by = [
    history,
    life,
    science,
    psychology,
    economics,
    space,
  ];
  final List<Pill> all = [];
  for (var i = 0; all.length < 50; i++) {
    for (final List<Pill> s in by) {
      if (i < s.length && all.length < 50) all.add(s[i]);
    }
  }
  for (var i = 0; i < 50; i++) {
    r.read(9 - i ~/ 5, all[i]);
  }
  int dayOf(Pill p) => 9 - all.indexOf(p) ~/ 5;
  // History: eight answered, seven right, the last four said 80% sure.
  for (final (int i, Pill p) in history.take(8).indexed) {
    r.answer(p, dayOf(p), right: i != 5, sure: i >= 4 ? 80 : null);
  }
  // Life: seven answered, two right, six of them said 80% or 90% sure.
  for (final (int i, Pill p) in life.take(7).indexed) {
    r.answer(
      p,
      dayOf(p),
      right: i == 2 || i == 6,
      sure: i < 6 ? (i.isEven ? 90 : 80) : null,
    );
  }
  // Science: six answered, four right, the last four said 60% sure.
  for (final (int i, Pill p) in science.take(6).indexed) {
    r.answer(p, dayOf(p), right: i % 3 != 0, sure: i >= 2 ? 60 : null);
  }
  // A few more, not enough to measure a subject.
  for (final Pill p in [
    ...psychology.take(3),
    ...economics.take(3),
    ...space.take(2),
  ]) {
    r.answer(p, dayOf(p), right: p.id.length.isEven);
  }
  // Back after two days: four cards missed, three of them known then.
  for (final (int i, Pill p)
      in life.take(5).where((p) => p != life[2]).indexed) {
    final int day = math.max(0, dayOf(p) - 2);
    r.answer(p, day, right: i != 3);
  }
  // Back after a week: three History cards right the first time, right
  // again, two of them held now.
  for (final (int i, Pill p) in history.take(3).indexed) {
    final int day = math.max(0, dayOf(p) - 7);
    r.answer(p, day, right: true, stage: i < 2 ? 2 : 1);
  }
  return r.prefs(
    plus: plus,
    streak: 10,
    today: [for (final p in all.skip(45)) p.id],
    more: more,
  );
}

int _docs = 0;

/// The server's word on the three switches: all on.
void _switchOn() => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'journey-preview-${_docs++}',
      'app': {
        'flags': {
          'journey.preview': true,
          'week.sunday': true,
          'calibration.early': true,
        },
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// The plans as the owner sets them, as the App Store writes their prices.
Offering _onSale() {
  final bool it = _locale.languageCode == 'it';
  const context = PresentedOfferingContext('default', null, null);
  final year = Package(
    r'$rc_annual',
    PackageType.annual,
    StoreProduct(
      'com.astuto.app.plus.yearly',
      'Astute+',
      'Astute+',
      29.99,
      it ? '29,99 €' : '€29.99',
      'EUR',
      introductoryPrice: IntroductoryPrice(
        0,
        it ? '0,00 €' : '€0.00',
        'P2W',
        1,
        PeriodUnit.week,
        2,
      ),
    ),
    context,
  );
  final month = Package(
    r'$rc_monthly',
    PackageType.monthly,
    StoreProduct(
      'com.astuto.app.plus.monthly',
      'Astute+',
      'Astute+',
      3.99,
      it ? '3,99 €' : '€3.99',
      'EUR',
    ),
    context,
  );
  return Offering(
    'default',
    '',
    const {},
    [year, month],
    annual: year,
    monthly: month,
  );
}

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
  });

  final Subscription before = Subscription.instance;

  /// The phone, [size] points at three pixels a point, in [locale]: an
  /// iPhone's notch and home bar on the large one, a status bar alone on
  /// the small one; the store with its plans on sale.
  void phone(WidgetTester tester, {Size size = _phone, Locale? locale}) {
    final Locale l = locale ?? _locale;
    final bool small = size == _small;
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(
      top: (small ? 20 : 47) * 3,
      bottom: small ? 0 : 34 * 3,
    );
    tester.view.viewPadding = tester.view.padding;
    tester.platformDispatcher.localeTestValue = l;
    tester.platformDispatcher.localesTestValue = [l];
    debugDisableShadows = false;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearLocaleTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
      Subscription.useForTest(before);
      Remote.reset();
      debugDisableShadows = true;
    });
    Subscription.useForTest(
      Subscription(keyOverride: '')
        ..answerForTest(offering: _onSale())
        ..holdForTest(null),
    );
  }

  Future<AppState> reader(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final AppState app = AppState(
      hasPermission: () async => true,
      askPermission: () async => true,
      arm: (_) async {},
      disarm: () async {},
      pushWidget: (_) async {},
    );
    await app.init();
    return app;
  }

  Widget host(
    AppState app,
    Widget home, {
    Brightness light = Brightness.dark,
    Locale? locale,
  }) => MaterialApp(
    locale: locale ?? _locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(light),
    debugShowCheckedModeBanner: false,
    home: home,
  );

  Future<void> shoot(String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$_out/$name.png'),
  );

  String tone(Brightness b) => b == Brightness.dark ? 'notte' : 'carta';

  /// The journey's page scrolled down by [by] points.
  Future<void> scrollJourney(WidgetTester tester, double by) async {
    final ScrollPosition page = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('journey-page')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    page.jumpTo(math.min(by, page.maxScrollExtent));
    await _settle(tester);
  }

  // Before: the journey's door opened the plans, nothing of the journey
  // shown. After: the reader's own journey, veiled, one figure clear.
  for (final (String who, Map<String, Object> Function() prefs) in [
    ('2g', () => _twoDays()),
    ('10g', () => _tenDays()),
  ]) {
    testWidgets('prima-$who', (tester) async {
      phone(tester);
      final AppState app = await reader(prefs());
      await tester.pumpWidget(
        host(app, PaywallScreen(app: app, source: 'journey')),
      );
      await _settle(tester, 24);
      await shoot('prima-$who');
      await tester.pumpWidget(const SizedBox());
    });

    for (final Brightness light in Brightness.values) {
      testWidgets('dopo-$who-${tone(light)}', (tester) async {
        phone(tester);
        _switchOn();
        final AppState app = await reader(prefs());
        await tester.pumpWidget(
          host(
            app,
            JourneyScreen(app: app, onBack: () {}),
            light: light,
          ),
        );
        await _settle(tester, 20);
        await shoot('dopo-$who-${tone(light)}');
        if (light == Brightness.dark) {
          await scrollJourney(tester, 620);
          await shoot('dopo-$who-giu');
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  // The other figures in the clear, each the reader's own, in the weeks
  // they come round: the blind spot and what stays, for the reader of ten
  // days; and for the reader of two, the blind spot's week, when it cannot
  // be said yet.
  for (final (String name, Map<String, Object> Function(String) prefs) in [
    (
      'dopo-10g-cieco',
      (String w) => _tenDays(more: {'knowit.journeyClear': '$w|blind'}),
    ),
    (
      'dopo-10g-ricordi',
      (String w) => _tenDays(more: {'knowit.journeyClear': '$w|memory'}),
    ),
    (
      'dopo-2g-cieco',
      (String w) => _twoDays(more: {'knowit.journeyClear': '$w|blind'}),
    ),
  ]) {
    testWidgets(name, (tester) async {
      phone(tester);
      _switchOn();
      final AppState app = await reader(prefs(dateKey(mondayOf(_today))));
      await tester.pumpWidget(
        host(app, JourneyScreen(app: app, onBack: () {})),
      );
      await _settle(tester, 20);
      await shoot(name);
      await tester.pumpWidget(const SizedBox());
    });
  }

  /// The profile scrolled to how well the reader knows themselves.
  Future<void> toCalibration(WidgetTester tester) async {
    final Finder list = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    final Finder card = find.byKey(const ValueKey('calibration-early'));
    await tester.scrollUntilVisible(card, 300, scrollable: list);
    await _settle(tester, 4);
    await tester.drag(list, Offset(0, 240 - tester.getTopLeft(card).dy));
    await _settle(tester, 8);
  }

  // The first reading, on the profile: said 80% twice, right twice.
  for (final Brightness light in Brightness.values) {
    testWidgets('lettura-${tone(light)}', (tester) async {
      phone(tester);
      _switchOn();
      final AppState app = await reader(_twoDays());
      await tester.pumpWidget(
        host(
          app,
          Scaffold(
            body: ProfileScreen(
              app: app,
              account: Account(
                uidOverride: 'me',
                boardsOverride: MemoryBoardStore(),
              ),
              onSignedOut: () {},
            ),
          ),
          light: light,
        ),
      );
      await _settle(tester, 20);
      await toCalibration(tester);
      await shoot('lettura-${tone(light)}');
      await tester.pumpWidget(const SizedBox());
    });
  }

  /// The app open on the finished day, Sunday's week risen over it as the
  /// shell raises it on Sunday, with the account's line.
  Future<AppState> week(WidgetTester tester, {String theme = 'dark'}) async {
    _switchOn();
    SharedPreferences.setMockInitialValues(
      _tenDays(more: {'knowit.theme': theme}),
    );
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 30);
    final AppState app = tester
        .widget<TodayScreen>(find.byType(TodayScreen))
        .app;
    final DateTime monday = mondayOf(app.today);
    showModalBottomSheet<WeekLeft>(
      context: tester.element(find.byType(TodayScreen)),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: (context) => YourWeekSheet(
        app: app,
        week: YourWeek.of(app, monday),
        plus: weekPlusFigure(context, app),
        account: true,
      ),
    );
    await _settle(tester, 20);
    // Google's mark on the account's line, read off the disk for real,
    // which the test's clock alone never finishes.
    final Element sheet = tester.element(
      find.byKey(const ValueKey('your-week')),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/google-g.png'),
        sheet,
      ).timeout(const Duration(seconds: 10), onTimeout: () {}),
    );
    await _settle(tester, 4);
    return app;
  }

  for (final String theme in ['dark', 'light']) {
    final String name = 'settimana-${theme == 'dark' ? 'notte' : 'carta'}';
    testWidgets(name, (tester) async {
      phone(tester);
      await week(tester, theme: theme);
      await shoot(name);
      await tester.pumpWidget(const SizedBox());
    });
  }

  // The sheet the account's line opens, Apple and Google.
  testWidgets('settimana-accesso', (tester) async {
    phone(tester);
    final AppState app = await reader(_tenDays());
    await tester.pumpWidget(
      host(
        app,
        Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.p.surface,
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    showModalBottomSheet<bool>(
      context: tester.element(find.byType(Scaffold)),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: (_) => SignInSheet(
        account: Account(uidOverride: 'me', boardsOverride: MemoryBoardStore()),
        app: app,
        door: SignInDoor.week,
      ),
    );
    await _settle(tester, 16);
    await shoot('settimana-accesso');
    await tester.pumpWidget(const SizedBox());
  });

  // The 320-wide phone, in German: the preview, the week, the first
  // reading.
  const Locale de = Locale('de');
  testWidgets('de-320-percorso', (tester) async {
    phone(tester, size: _small, locale: de);
    _switchOn();
    final AppState app = await reader(_tenDays());
    await tester.pumpWidget(
      host(
        app,
        JourneyScreen(app: app, onBack: () {}),
        locale: de,
      ),
    );
    await _settle(tester, 20);
    await shoot('de-320-percorso');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('de-320-cieco', (tester) async {
    phone(tester, size: _small, locale: de);
    _switchOn();
    final AppState app = await reader(
      _twoDays(
        more: {'knowit.journeyClear': '${dateKey(mondayOf(_today))}|blind'},
      ),
    );
    await tester.pumpWidget(
      host(
        app,
        JourneyScreen(app: app, onBack: () {}),
        locale: de,
      ),
    );
    await _settle(tester, 20);
    await shoot('de-320-cieco');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('de-320-settimana', (tester) async {
    phone(tester, size: _small, locale: de);
    await week(tester);
    await shoot('de-320-settimana');
    final ScrollPosition sheet = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('your-week')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    sheet.jumpTo(sheet.maxScrollExtent);
    await _settle(tester);
    await shoot('de-320-settimana-fine');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('de-320-lettura', (tester) async {
    phone(tester, size: _small, locale: de);
    _switchOn();
    final AppState app = await reader(_twoDays());
    await tester.pumpWidget(
      host(
        app,
        Scaffold(
          body: ProfileScreen(
            app: app,
            account: Account(
              uidOverride: 'me',
              boardsOverride: MemoryBoardStore(),
            ),
            onSignedOut: () {},
          ),
        ),
        locale: de,
      ),
    );
    await _settle(tester, 20);
    await toCalibration(tester);
    await shoot('de-320-lettura');
    await tester.pumpWidget(const SizedBox());
  });
}
