// Photographs the app for its Google Play listing: the five screens the
// listing shows, as an Android phone shows them — 402 by 830 points, the
// 18.5:9 of many Android phones, with Android's status bar, the camera's
// hole in it and the gesture bar — at night, in the language LANG_SHOT
// names (English when it names none).
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test --no-pub tool/store_shots.dart --update-goldens
//   python3 store/compose_shots.py /some/folder it
//
// The second line sets each screen in its frame under its caption, as the
// store's 1080 by 1920 pictures, in store/play/<language>/. A camera, not a
// check: it lives outside test/ so CI never runs it.
//
// The five, in the order the listing shows them: Today on its first card,
// Etna's flank about to fall into the sea (the card the first morning opens
// on); a drawn card played through, the MRI counted in Earths; a card in
// words answered at 80% and turned over; Your journey; Explore at its top.
//
// The drawn cards are pages, which a test cannot run. Each is shown as its
// own photograph, taken at the card's size on this phone by
// tool/cards/card_check.cjs with BARE=1 and the same language, so the
// subject's name and the foot are in the reader's words as the app sends
// them; the cards themselves are in English, as they are in the app. FACES
// is the folder those photographs are in: without it, the pictures the app
// ships (web/cards/thumbs/large/) stand in, in English.
//
// Nothing in them is made up about other readers: no crowd's counts and no
// top list. The reader is made up, and only their own numbers are shown.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_page_store_base.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/levels.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/journey_record.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/level_up.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/card_thumb.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_messages.dart';
import 'package:astuto/widgets/web/web_surface.dart';

import '../test/explore/core_harness.dart';

/// The phone: its size in points, and the room Android's status bar and
/// gesture bar take. At this height the card on Today is the 366 by 606 a
/// 402-wide phone gives it, the size the drawn cards are photographed at.
const Size _phone = Size(402, 830);
const EdgeInsets _insets = EdgeInsets.only(top: 32, bottom: 20);
const double _ratio = 3;

/// The phone's language.
final Locale _locale = Locale(Platform.environment['LANG_SHOT'] ?? 'en');

/// The day the pictures are of.
final DateTime _now = DateTime.now();
String _back(int days) =>
    dateKey(DateTime(_now.year, _now.month, _now.day - days));

/// The first card of a new reader's first morning (lib/data/first_days.dart):
/// half of Etna's flank about to fall into the sea.
const String _first = 'nature-half-mountain-tsunami';

/// A drawn card played through: an MRI's field counted in Earths, ten more
/// at every tap, to a hundred thousand.
const String _played = 'medicine-mri-field-strength';

/// A card in words, answered at 80% and turned over: what a 30% chance of
/// rain is a chance of.
const String _words = 'nature-forecasting-3';

/// A morning's five, each of another subject.
const List<String> _five = [
  _first,
  _words,
  'food-estimated-weight-mark',
  'space-bones-in-orbit',
  'history-weighing-the-air',
];

/// The drawn cards shown played through: their page's end, as its picture.
final Set<String> _turned = {};

/// The photograph standing in for a drawn card's page: its own, taken in
/// the phone's language, where FACES has one; else the app's own picture.
ImageProvider? _face(String id, {required bool end}) {
  final String? faces = Platform.environment['FACES'];
  if (faces != null) {
    final File own = File('$faces/$id-medium-${end ? 'end' : 'start'}.png');
    if (own.existsSync()) return MemoryImage(own.readAsBytesSync());
  }
  final File shipped = File(
    'web/cards/thumbs/large/$id-${end ? 'back' : 'front'}.webp',
  );
  return shipped.existsSync() ? MemoryImage(shipped.readAsBytesSync()) : null;
}

/// A picture of the bank's own, from the folder the site serves them from.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

/// The kit, put together at once: a page is a photograph here.
class _InstantKit extends CardKit {
  @override
  Future<String> page(String html, PageEnv env) => Future.value(html);
}

/// Every drawn card's page in its place as its photograph, filling the
/// card's own box, which is said once so the photographs can be checked
/// against it.
void _drawnPages() {
  CardKit.instance = _InstantKit();
  CardPages.instance = CardPages(
    fetch: (url) async {
      final String id = url.pathSegments.last.replaceAll('.html', '');
      return '<!-- store-shot $id -->\n'
          '${File('web/cards/pages/$id.html').readAsStringSync()}';
    },
    store: MemoryPageStore(),
  );
  FakeWebSurface.reset();
  WebSurfaces.debugUse(
    () => FakeWebSurface(
      face: (surface) {
        final String? id = RegExp(r'<!-- store-shot ([^ ]+) -->')
            .firstMatch(surface.html ?? '')
            ?.group(1);
        final ImageProvider? face = id == null
            ? null
            : _face(id, end: _turned.contains(id));
        if (face == null) return const SizedBox();
        return LayoutBuilder(
          builder: (context, box) {
            debugPrint('store-shot $id: the card is ${box.biggest}');
            return Image(image: face, fit: BoxFit.fill);
          },
        );
      },
    ),
  );
}

/// What an Android phone draws over the app: the clock on the left, the
/// camera's hole in the middle, signal, wifi and battery on the right, and
/// the gesture bar at the foot.
class _AndroidOver extends StatelessWidget {
  const _AndroidOver();

  @override
  Widget build(BuildContext context) {
    const Color ink = Color(0xFFF7F6F2);
    final double mid = _insets.top / 2;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: mid - 9,
            left: 22,
            child: const Text(
              '8:30',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ink,
                height: 1.25,
              ),
            ),
          ),
          Positioned(
            top: mid - 6,
            left: _phone.width / 2 - 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF000000),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: mid - 8,
            right: 20,
            child: Row(
              children: [
                const Icon(Icons.signal_cellular_alt_rounded, size: 16, color: ink),
                const SizedBox(width: 3),
                const Icon(Icons.wifi_rounded, size: 16, color: ink),
                const SizedBox(width: 5),
                // The battery as Android draws it now: a short pill, nearly
                // full, with its nub.
                Container(
                  width: 21,
                  height: 11,
                  padding: const EdgeInsets.all(1.4),
                  decoration: BoxDecoration(
                    border: Border.all(color: ink.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(3.5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.86,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.6,
                  height: 4,
                  margin: const EdgeInsets.only(left: 1),
                  color: ink.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 108,
                height: 4,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [app] on the phone, with the phone's own bars over it.
Widget _onPhone(Widget app) => Directionality(
  textDirection: TextDirection.ltr,
  child: Stack(
    key: const ValueKey('store-phone'),
    children: [
      app,
      const Positioned.fill(child: _AndroidOver()),
    ],
  ),
);

/// A screen of the app's own, alone, as a page pushed over it is.
Widget _page(Widget home) => MaterialApp(
  locale: _locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  debugShowCheckedModeBanner: false,
  home: home,
);

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture on screen, decoded before the photograph, in real time.
Future<void> _decodeShown(WidgetTester tester) async {
  for (int round = 0; round < 2; round++) {
    final Set<ImageProvider> shown = {
      for (final Image image in tester.widgetList<Image>(find.byType(Image)))
        image.image,
    };
    if (shown.isEmpty) return;
    final BuildContext context = tester.element(
      find.byKey(const ValueKey('store-phone')),
    );
    await tester.runAsync(() async {
      for (final ImageProvider p in shown) {
        await precacheImage(
          p,
          context,
          onError: (_, _) {},
        ).timeout(const Duration(seconds: 10), onTimeout: () {});
      }
    });
    await _settle(tester, 5);
  }
}

/// The phone, held for [tester]: its size, its bars, Android, and the
/// language asked for.
void _hold(WidgetTester tester) {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // Shadows blurred, as on a phone, while the pictures are taken.
  debugDisableShadows = false;
  final view = tester.view;
  view.physicalSize = _phone * _ratio;
  view.devicePixelRatio = _ratio;
  view.padding = FakeViewPadding(
    top: _insets.top * _ratio,
    bottom: _insets.bottom * _ratio,
  );
  view.viewPadding = view.padding;
  tester.platformDispatcher.localesTestValue = [_locale];
  tester.platformDispatcher.localeTestValue = _locale;
  tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
  addTearDown(() {
    view.reset();
    tester.platformDispatcher.clearLocalesTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearAlwaysUse24HourTestValue();
    debugDefaultTargetPlatformOverride = null;
    debugDisableShadows = true;
  });
}

/// Nothing asked of the reader over what is photographed.
const Map<String, Object> _quiet = {
  'knowit.onboarded': true,
  'knowit.pushAsked': true,
  'knowit.widgetAsked': true,
  'knowit.accountOffered': true,
  'knowit.reviewAsked': true,
  'knowit.goalAsked': true,
  'knowit.placeAsks': 9,
};

/// A reader a week in, on the free plan, with [deck] dealt today and
/// [read] of it read.
Map<String, Object> _day(List<String> deck, {int read = 0}) => {
  ..._quiet,
  'knowit.plus': false,
  'knowit.todayDate': _back(0),
  'knowit.todayDeckIds': deck,
  'knowit.todayIndex': read,
  'knowit.streak': 6,
  // Past the first card ever read, so the card does not lean aside to
  // show how it is thrown.
  'knowit.pillsRead': 30,
  'knowit.bestStreak': 6,
  'knowit.lastCompletionDate': _back(1),
  'knowit.completedDates': [for (int d = 6; d >= 1; d--) _back(d)],
  'knowit.seenIds': [
    ...PillBank.cards.skip(300).take(30).map((p) => p.id),
    ...deck.take(read),
  ],
};

/// A reader twelve weeks in, on Astute+, as tool/site_shots.dart has them:
/// what the phone would have written down, and each day's log.
({Map<String, Object> prefs, Map<String, List<int>> log}) _twelveWeeks() {
  final rand = math.Random(7);
  final DateTime day0 = DateTime.utc(
    _now.year,
    _now.month,
    _now.day,
  ).subtract(const Duration(days: 85));
  String key(int d) => dateKey(day0.add(Duration(days: d)));
  const Set<int> off = {3, 5, 8, 12, 17, 22, 26, 31, 35, 39, 59, 63, 67, 70};
  const List<int> weekly = [16, 21, 22, 24, 20, 25, 27, 24, 28, 27, 30, 33, 15];
  const Map<String, int> bySubject = {
    'space': 40,
    'history': 36,
    'psychology': 32,
    'economics': 27,
    'human_body': 24,
    'nature': 22,
    'technology': 19,
    'thinking': 18,
    'pop_culture': 14,
    'medicine': 12,
    'cinema': 11,
    'philosophy': 10,
    'food': 9,
    'science': 8,
    'art': 7,
    'language': 6,
    'music': 5,
    'weird_facts': 5,
    'sport': 4,
    'life': 3,
  };
  final perDay = List<int>.filled(86, 0);
  for (var w = 0; w < 13; w++) {
    final days = [
      for (var d = 0; d < 86; d++)
        if ((d + 1) ~/ 7 == w && !off.contains(d)) d,
    ];
    final int base = weekly[w] ~/ days.length;
    final int rem = weekly[w] - base * days.length;
    final order = [...days]
      ..sort((a, b) => (a * 37 % 11).compareTo(b * 37 % 11));
    for (final d in days) {
      perDay[d] = base + (order.indexOf(d) < rem ? 1 : 0);
    }
  }
  final slots = <(double, String)>[];
  final ranked = bySubject.keys.toList();
  for (var r = 0; r < ranked.length; r++) {
    final int c = bySubject[ranked[r]]!;
    final double from = 0.6 * r / (ranked.length - 1);
    for (var j = 0; j < c; j++) {
      slots.add((from + (j + 0.5) / c * (1 - from), ranked[r]));
    }
  }
  slots.sort((a, b) => a.$1.compareTo(b.$1));
  final used = <String>{};
  Pill pick(String subject, double t) {
    final String name = kTopics[subject]!.name;
    final Difficulty want = t < 0.35
        ? Difficulty.easy
        : t < 0.75
        ? Difficulty.medium
        : (rand.nextBool() ? Difficulty.hard : Difficulty.medium);
    final pool = PillBank.cards.where(
      (p) => p.topic == name && !used.contains(p.id),
    );
    final Pill card =
        pool
            .where((p) => p.difficulty == want && p.challenge is PickOne)
            .firstOrNull ??
        pool.where((p) => p.difficulty == want).firstOrNull ??
        pool.first;
    used.add(card.id);
    return card;
  }

  final readDays = <String, List<String>>{};
  final reads = <(int, Pill, double)>[];
  var slot = 0;
  for (var d = 0; d < 86; d++) {
    for (var i = 0; i < perDay[d]; i++) {
      final (double t, String subject) = slots[slot++];
      final Pill card = pick(subject, t);
      readDays.putIfAbsent(key(d), () => []).add(card.id);
      reads.add((d, card, d / 85));
    }
  }
  final events = <(int, Map<String, Object>)>[];
  final answers = <String, Map<String, Object>>{};
  const levels = [50, 60, 70, 80, 90];
  for (final (int d, Pill card, double t) in reads) {
    if (card.challenge is! PickOne || rand.nextDouble() > 0.75) continue;
    final pick = card.challenge as PickOne;
    final List<int> weights = t < 0.4 ? [1, 2, 3, 4, 4] : [2, 3, 4, 3, 2];
    var roll = rand.nextInt(weights.reduce((a, b) => a + b));
    var c = 0;
    while (roll >= weights[c]) {
      roll -= weights[c++];
    }
    final int sure = levels[c];
    final double offBy = 0.31 - 0.29 * t;
    var day = d;
    var right = rand.nextDouble() < (sure / 100 - offBy).clamp(0.05, 0.98);
    events.add((day, {'c': sure, 'k': right, 'p': card.id, 'd': key(day)}));
    const comeBack = [2, 7, 21];
    const keep = [1.08, 0.86, 0.52];
    var run = right ? 1 : 0;
    while (run < 3 && day + comeBack[run] <= 85) {
      day += comeBack[run];
      final double now = 0.31 - 0.29 * day / 85;
      right =
          rand.nextDouble() <
          ((sure / 100 - now) * keep[run]).clamp(0.05, 0.98);
      events.add((day, {'c': sure, 'k': right, 'p': card.id, 'd': key(day)}));
      run = right ? run + 1 : 0;
    }
    answers[card.id] = {
      'r': '${right ? pick.correct : (pick.correct + 1) % pick.options.length}',
      'c': sure,
      if (run != 0) 's': run,
      if (run < 3) 'd': key(day + comeBack[run]),
    };
  }
  events.sort((a, b) => a.$1.compareTo(b.$1));
  final log = <String, List<int>>{};
  for (var d = 0; d < 86; d++) {
    if (perDay[d] == 0) continue;
    final parts = List<int>.filled(4, 0);
    for (var i = 0; i < perDay[d]; i++) {
      final int r = rand.nextInt(100);
      parts[r < 44 ? 0 : (r < 56 ? 1 : (r < 92 ? 2 : 3))] += 1;
    }
    log[key(d)] = [0, perDay[d] * (34 + 10 * d ~/ 85), ...parts];
  }
  return (
    prefs: {
      ..._quiet,
      'knowit.plus': true,
      'knowit.streak': 12,
      'knowit.bestStreak': 19,
      'knowit.lastCompletionDate': key(85),
      'knowit.completedDates': [
        for (var d = 0; d < 86; d++)
          if (perDay[d] > 0) key(d),
      ],
      'knowit.seenIds': [for (final r in reads) r.$2.id],
      'knowit.readDays': jsonEncode(readDays),
      'knowit.judgements': jsonEncode([for (final e in events) e.$2]),
      'knowit.answersJson': jsonEncode(answers),
    },
    log: log,
  );
}

void main() {
  final String out = Platform.environment['SHOTS'] ?? 'shots/store';

  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // A build of today's: the sections the document keeps for new builds
    // are on, the ones it keeps for old ones off.
    Remote.build = 99;
    CardThumb.image = _picture;
  });

  tearDown(() {
    WebSurfaces.debugUse(null);
    CardKit.instance = CardKit();
  });

  Future<void> shoot(WidgetTester tester, String name) async {
    await _decodeShown(tester);
    await expectLater(
      find.byKey(const ValueKey('store-phone')),
      matchesGoldenFile('$out/$name.png'),
    );
  }

  /// The app as a reader opens it, with [prefs] stored.
  Future<void> open(WidgetTester tester, Map<String, Object> prefs) async {
    _hold(tester);
    _drawnPages();
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(_onPhone(const AstutoApp()));
    await _settle(tester, 20);
  }

  testWidgets('1: today, on the first card', (tester) async {
    await open(tester, _day(_five));
    await _settle(tester, 10);
    await shoot(tester, 'play-1-today');
  });

  testWidgets('2: a drawn card, played through', (tester) async {
    _turned.add(_played);
    addTearDown(_turned.clear);
    await open(tester, _day([_played, ..._five.skip(1)]));
    await _settle(tester, 10);
    await shoot(tester, 'play-2-drawn');
  });

  testWidgets('3: a card in words, answered at 80% and turned', (
    tester,
  ) async {
    await open(tester, _day([_words, ..._five.where((id) => id != _words)]));
    final Pill pill = PillBank.byId(_words)!;
    final PickOne asked = pill.challenge as PickOne;
    await tester.tap(find.text(asked.options[asked.correct]));
    await _settle(tester, 8);
    final Finder sure = find.text('80%');
    expect(sure, findsWidgets);
    await tester.tap(sure.first);
    await _settle(tester, 20);
    final Finder foot = find.byKey(ValueKey('card-foot-${pill.id}'));
    if (foot.evaluate().isEmpty) {
      await tester.tap(find.byType(PillCard).last);
      await _settle(tester, 20);
    }
    await _settle(tester, 20);
    await shoot(tester, 'play-3-answer');
  });

  testWidgets('4: your journey', (tester) async {
    _hold(tester);
    final reader = _twelveWeeks();
    final AppState app = await readyApp(reader.prefs);
    final JourneyRecord before = app.record;
    app.dayLog = {
      for (final e in reader.log.entries)
        e.key: [before.scoreOn(e.key), ...e.value.skip(1)],
    };
    // Told already: the journey opens on itself, not on a new level.
    await LevelMemory.keep(levelStandingOf(app, null).reached);
    await tester.pumpWidget(
      _onPhone(_page(JourneyScreen(app: app, onBack: () {}))),
    );
    for (int f = 0; f < 40; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await shoot(tester, 'play-4-journey');
  });

  testWidgets('5: explore, at its top', (tester) async {
    await open(tester, _day(_five, read: 2));
    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 24);
    await shoot(tester, 'play-5-explore');
  });
}
