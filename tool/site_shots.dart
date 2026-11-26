// Photographs the app for the site: the phone pictures astutetheapp.com
// shows (site/assets/app-*.webp), as an iPhone 16 Pro shows the app — 402
// by 874 points, its status bar, its glass tab bar and its home bar — in
// English, at night, with cards from the bank and their own pictures.
//
//   SHOTS=/some/folder flutter test tool/site_shots.dart --update-goldens
//   python3 tool/site/shots.py /some/folder
//
// The second line makes them the site's WebPs, 840 by 1826, under the names
// the pages use (tool/site/shots.py says which is which). A camera, not a
// check: it lives outside test/ so CI never runs it, and its pictures land
// in tool/shots/site/ unless SHOTS says otherwise, to be looked at and not
// kept.
//
// Nothing in them is made up about other readers: no crowd's counts, no top
// list (Explore shows Astute's own picks, as it does until real readers make
// a list), and no news but the fixture written from one morning's real
// reports (tool/news/paper.json). The reader is made up, and only their own
// numbers are shown: a streak, a score, a level.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_page_store_base.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/levels.dart';
import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/journey_record.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/deeper_sheet.dart' show GoDeeper;
import 'package:astuto/widgets/level_up.dart';
import 'package:astuto/widgets/news/news_story_page.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/share_day.dart';
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/card_thumb.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_messages.dart';
import 'package:astuto/widgets/web/web_surface.dart';

import '../test/explore/core_harness.dart';

/// An iPhone 16 Pro: its size in points, and the room its status bar and
/// home bar take.
const Size _phone = Size(402, 874);
const EdgeInsets _insets = EdgeInsets.only(top: 62, bottom: 34);
const double _ratio = 3;

/// The day the pictures are of.
final DateTime _now = DateTime.now();
String _back(int days) =>
    dateKey(DateTime(_now.year, _now.month, _now.day - days));

/// The first of a day's five, drawn: the dam poured as blocks.
const String _drawn = 'technology-hoover-dam-blocks';

/// A card in words, to be answered and turned over: what a 30% chance of
/// rain is a chance of.
const String _words = 'nature-forecasting-3';

/// A morning's five, drawn and in words, each of another subject.
const List<String> _five = [
  _drawn,
  _words,
  'food-estimated-weight-mark',
  'space-bones-in-orbit',
  'history-weighing-the-air',
];

/// The five of a day already read, the first a drawing of the sea at a
/// sunken town.
const List<String> _readFive = [
  'science-bradyseism-breathing-ground',
  'psychology-stroop-other-way',
  'maths-knot-tricolorability',
  _words,
  'nature-half-mountain-tsunami',
];

/// A card whose Go deeper is written in full: its idea said simply and why
/// it matters, from Books in pills.
const String _deeper = 'maths-book-how-not-to-be-wrong-2';

/// The story of the news fixture photographed: a probe's close-ups of the
/// asteroid NASA hit in 2022.
const String _story = 'news-2026-11-26-asteroid-hit-by-nasa-in-2022';

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

/// Every drawn card's page in its place as its own photograph, taken at the
/// card's size on this phone (web/cards/thumbs/large/), its front.
void _drawnPages() {
  CardKit.instance = _InstantKit();
  CardPages.instance = CardPages(
    fetch: (url) async {
      final String id = url.pathSegments.last.replaceAll('.html', '');
      return '<!-- site-shot $id -->\n'
          '${File('web/cards/pages/$id.html').readAsStringSync()}';
    },
    store: MemoryPageStore(),
  );
  FakeWebSurface.reset();
  WebSurfaces.debugUse(
    () => FakeWebSurface(
      face: (surface) {
        final String? id = RegExp(
          r'<!-- site-shot ([^ ]+) -->',
        ).firstMatch(surface.html ?? '')?.group(1);
        final File front = File('web/cards/thumbs/large/$id-front.webp');
        if (id == null || !front.existsSync()) return const SizedBox();
        return Image(
          image: _picture(Uri.parse('/cards/thumbs/large/$id-front.webp')),
          fit: BoxFit.fill,
        );
      },
    ),
  );
}

/// What the phone draws over the app: the status bar and the home bar. The
/// island is the site's own, drawn on its frame.
class _PhoneOver extends StatelessWidget {
  const _PhoneOver();

  @override
  Widget build(BuildContext context) {
    const Color ink = Color(0xFFF7F6F2);
    const double mid = 30;
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned(
            top: mid - 11,
            left: 46,
            child: Text(
              '9:41',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ink,
                height: 1.2,
              ),
            ),
          ),
          Positioned(
            top: mid - 7,
            right: 34,
            child: Row(
              children: [
                for (final double h in [4.5, 6.5, 9, 11.5])
                  Container(
                    width: 3.2,
                    height: h,
                    margin: EdgeInsets.only(right: 1.8, top: 11.5 - h),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                const SizedBox(width: 5),
                const Icon(Icons.wifi_rounded, size: 16, color: ink),
                const SizedBox(width: 5),
                Container(
                  width: 25,
                  height: 12,
                  padding: const EdgeInsets.all(1.6),
                  decoration: BoxDecoration(
                    border: Border.all(color: ink.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
                width: 140,
                height: 5,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [app] on the phone, with the phone's own bars over it. No boundary of
/// its own: the picture is the whole view's, at the phone's three pixels a
/// point.
Widget _onPhone(Widget app) => Directionality(
  textDirection: TextDirection.ltr,
  child: Stack(
    key: const ValueKey('site-phone'),
    children: [
      app,
      const Positioned.fill(child: _PhoneOver()),
    ],
  ),
);

/// A screen of the app's own, alone, as a page pushed over it is.
Widget _page(Widget home) => MaterialApp(
  locale: const Locale('en'),
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
      find.byKey(const ValueKey('site-phone')),
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

/// The phone, held for [tester]: an iPhone's size, insets and platform,
/// and English.
void _hold(WidgetTester tester) {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  final view = tester.view;
  view.physicalSize = _phone * _ratio;
  view.devicePixelRatio = _ratio;
  view.padding = FakeViewPadding(
    top: _insets.top * _ratio,
    bottom: _insets.bottom * _ratio,
  );
  view.viewPadding = view.padding;
  tester.platformDispatcher.localesTestValue = const [Locale('en')];
  tester.platformDispatcher.localeTestValue = const Locale('en');
  addTearDown(() {
    view.reset();
    tester.platformDispatcher.clearLocalesTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    debugDefaultTargetPlatformOverride = null;
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

/// A reader twelve days in, on the free plan, with [deck] dealt today and
/// [read] of it read.
Map<String, Object> _day(List<String> deck, {int read = 0}) => {
  ..._quiet,
  'knowit.plus': false,
  'knowit.todayDate': _back(0),
  'knowit.todayDeckIds': deck,
  'knowit.todayIndex': read,
  'knowit.streak': read == deck.length ? 12 : 11,
  // Past the first card ever read, so the card does not lean aside to
  // show how it is thrown.
  'knowit.pillsRead': 60,
  'knowit.bestStreak': 12,
  'knowit.lastCompletionDate': read == deck.length ? _back(0) : _back(1),
  'knowit.completedDates': [
    for (int d = 11; d >= (read == deck.length ? 0 : 1); d--) _back(d),
  ],
  'knowit.seenIds': [
    ...PillBank.cards.skip(300).take(60).map((p) => p.id),
    ...deck.take(read),
  ],
};

/// A reader three weeks in, as tool/profile_shots.dart has them: most days
/// read, a few missed, answers that start a little over half right and end
/// three in four, today three cards in.
Map<String, Object> _threeWeeks() {
  final rand = math.Random(11);
  const Set<int> missed = {5, 11, 16};
  const int first = 21;
  List<Pill> asking(Difficulty d) => [
    for (final Pill p in PillBank.cards)
      if (p.isGraded && p.difficulty == d) p,
  ];
  final List<Pill> medium = asking(Difficulty.medium);
  final List<Pill> hardest = asking(Difficulty.hard);
  final List<Pill> told = [
    for (final Pill p in PillBank.cards)
      if (!p.isGraded) p,
  ];
  final List<String> seen = [];
  final List<String> completed = [];
  final List<Map<String, Object>> judged = [];
  var m = 0, h = 0, r = 0;
  for (int back = first; back >= 1; back--) {
    if (missed.contains(back)) continue;
    completed.add(_back(back));
    final double t = (first - back) / first;
    for (int i = 0; i < kPillsPerDay; i++) {
      if (i >= 3) {
        seen.add(told[r++ % told.length].id);
        continue;
      }
      final bool hard = rand.nextDouble() < 0.2 + 0.4 * t;
      final Pill card = hard
          ? hardest[h++ % hardest.length]
          : medium[m++ % medium.length];
      seen.add(card.id);
      judged.add({
        'c': 60 + 10 * rand.nextInt(4),
        'k': rand.nextDouble() < (hard ? 0.4 : 0.55) + 0.25 * t,
        'p': card.id,
        'd': _back(back),
      });
    }
  }
  const List<String> deck = _five;
  for (final (int i, String id) in deck.take(3).indexed) {
    final Pill? card = PillBank.byId(id);
    if (card == null || !card.isGraded) continue;
    judged.add({'c': 70, 'k': i != 1, 'p': id, 'd': _back(0)});
  }
  return {
    ..._quiet,
    'knowit.plus': false,
    'knowit.streak': 4,
    'knowit.bestStreak': 9,
    'knowit.lastCompletionDate': _back(1),
    'knowit.completedDates': completed,
    'knowit.seenIds': [...seen, ...deck.take(3)],
    'knowit.judgements': jsonEncode(judged),
    'knowit.todayDate': _back(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': 3,
  };
}

/// A reader twelve weeks in, on Astute+, as tool/journey_shots.dart has
/// them: what the phone would have written down, and each day's log.
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
  final String out = Platform.environment['SHOTS'] ?? 'shots/site';

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
    NewsPaper.reset();
  });

  Future<void> shoot(WidgetTester tester, String name) async {
    await _decodeShown(tester);
    await expectLater(
      find.byKey(const ValueKey('site-phone')),
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

  testWidgets('today: the first of five, drawn', (tester) async {
    await open(tester, _day(_five));
    await _settle(tester, 10);
    await shoot(tester, 'today');
  });

  testWidgets('the answer: a card in words, answered and turned', (
    tester,
  ) async {
    await open(tester, _day([_words, ..._five.where((id) => id != _words)]));
    final Pill pill = PillBank.byId(_words)!;
    final PickOne asked = pill.challenge as PickOne;
    await tester.tap(find.text(asked.options[asked.correct]));
    await _settle(tester, 8);
    final Finder sure = find.text('80%');
    if (sure.evaluate().isNotEmpty) {
      await tester.tap(sure.first);
      await _settle(tester, 20);
    }
    final Finder foot = find.byKey(ValueKey('card-foot-${pill.id}'));
    if (foot.evaluate().isEmpty) {
      await tester.tap(find.byType(PillCard).last);
      await _settle(tester, 20);
    }
    await _settle(tester, 20);
    await shoot(tester, 'answer');
  });

  testWidgets('go deeper: what is below the card', (tester) async {
    await open(tester, _day(_five));
    GoDeeper.open!(
      tester.element(find.byType(PillCard).first),
      PillBank.byId(_deeper)!,
    );
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
    await shoot(tester, 'deeper');
  });

  testWidgets('the day done', (tester) async {
    await open(tester, _day(_readFive, read: _readFive.length));
    await _settle(tester, 10);
    await shoot(tester, 'done');
  });

  testWidgets('explore, at its top: today\'s five', (tester) async {
    await open(tester, _day(_five, read: 2));
    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 24);
    await shoot(tester, 'explore');
  });

  testWidgets('explore, at the challenges', (tester) async {
    await open(tester, _day(_five, read: 2));
    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 24);
    final Finder title = find.text('Challenges');
    final Finder down = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.scrollUntilVisible(title, 500, scrollable: down);
    await _settle(tester, 6);
    // The paths above, the challenges' first page under them.
    await tester.drag(down, Offset(0, 360 - tester.getTopLeft(title).dy));
    await _settle(tester, 20);
    await shoot(tester, 'challenges');
  });

  testWidgets('the news: a story\'s page', (tester) async {
    _hold(tester);
    final Map<String, Object?> paper =
        jsonDecode(File('tool/news/paper.json').readAsStringSync())
            as Map<String, Object?>;
    NewsPaper.clock = () => DateTime.utc(2026, 11, 26, 7, 30);
    NewsPaper.adopt(paper['date'] as String?, paper['cards']! as List<Object?>);
    final Pill story = NewsPaper.byId(_story)!;
    await tester.pumpWidget(
      _onPhone(_page(NewsStoryPage(pill: story, openLink: (_) async {}))),
    );
    await _settle(tester, 20);
    await shoot(tester, 'news');
  });

  testWidgets('your journey', (tester) async {
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
    await shoot(tester, 'journey');
  });

  testWidgets('a new level', (tester) async {
    _hold(tester);
    await tester.pumpWidget(
      _onPhone(
        _page(
          const LevelUpScreen(
            moment: LevelMoment(
              level: 3,
              score: 158,
              from: 141,
              answers: 186,
              skill: Skill.numbers,
              gain: 34,
            ),
          ),
        ),
      ),
    );
    for (int f = 0; f < 80; f++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await shoot(tester, 'level');
  });

  testWidgets('the profile, on the free plan', (tester) async {
    await open(tester, _threeWeeks());
    await tester.tap(find.byKey(const ValueKey('tab-Profile')).first);
    await _settle(tester, 24);
    await shoot(tester, 'profile');
  });

  // The day as it is sent: the picture the share sheet makes, at three
  // times its size, 1080 pixels across.
  testWidgets('the day, as a picture to send', (tester) async {
    tester.view.physicalSize = _phone * _ratio;
    tester.view.devicePixelRatio = _ratio;
    addTearDown(tester.view.reset);
    final List<Pill> five = [
      for (final String id in _readFive) PillBank.byId(id)!,
    ];
    final DateTime day = DateTime(_now.year, _now.month, _now.day);
    final DaySummary summary = DaySummary(
      edition: editionOf(day),
      squares: '',
      asked: 0,
      right: 0,
      sure: null,
      streak: 12,
    );
    const DayLayout layout = DayLayout.cover;
    await tester.pumpWidget(
      _page(
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: DayPicture.width,
              height: DayPicture.heightOf(layout),
              child: RepaintBoundary(
                key: const ValueKey('picture'),
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.noScaling),
                    child: DayPicture(
                      summary: summary,
                      five: five,
                      day: day,
                      layout: layout,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final BuildContext context = tester.element(find.byType(DayPicture));
      for (final ImageProvider picture in DayPicture.picturesOf(
        five,
        layout,
      )) {
        await precacheImage(
          picture,
          context,
          onError: (_, _) {},
        ).timeout(const Duration(seconds: 10), onTimeout: () {});
      }
    });
    for (int f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final RenderRepaintBoundary boundary = tester.renderObject(
      find.byKey(const ValueKey('picture')),
    );
    final String path = out.startsWith('/')
        ? '$out/share-day.png'
        : 'tool/$out/share-day.png';
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
