// Photographs the whole app the way the owner checks it before a build: an
// Italian reader's iPhone at night, 390 by 844 with its notch and home bar,
// on the real app and the real bank — the onboarding step by step, Today
// from the first card to the day sent, Explore top to bottom for every
// subject and for Economics, what opens inside Explore, Your journey, the
// profile with its settings and the fine-tuning of the mix, the paywall a
// free reader meets, and a level reached.
//
//   flutter test tool/tour_shots.dart --update-goldens \
//     --dart-define=TOUR_DIR=/some/folder [--plain-name today]
//
// A camera, not a check: it lives outside test/ so CI never runs it. Each
// area lands in a folder of its own under TOUR_DIR (tool/shots/gallery/tour
// when not given, which is not kept), its pictures numbered in the order
// they were taken, with captions.json beside them: an Italian caption for
// each picture, and where a finger is when one is down, for the contact
// sheets made from them to write above it and ring.
//
// What a phone does that a test cannot: a drawn card's page is a WebView,
// which a test has not got, so Today is dealt cards in words; the news is
// the fixture of 26 November 2026 (tool/news/paper.json); the server's
// shelves, Today's players and the film's frames are stand-ins, said where
// they are made. Nothing here asks the network, and measurement is never
// switched on: the intro's question about it is asked, and answered no.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/card_page_store_base.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/genre_names.dart';
import 'package:astuto/data/genres.dart';
import 'package:astuto/data/levels.dart';
import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/strand_names.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets/daily_deal.dart';
import 'package:astuto/explore/blocks/bets/deal.dart' show answerOf;
import 'package:astuto/explore/blocks/bets/three.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/state/journey_record.dart';
import 'package:astuto/sync/daily_crowd.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/level_up.dart' show levelStandingOf;
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/ui.dart' show PrimaryButton;
import 'package:astuto/widgets/video_card.dart' show VideoCardTile;
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/card_thumb.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_messages.dart';
import 'package:astuto/widgets/web/web_surface.dart';

import '../test/explore/core_harness.dart' show loadFonts;

/// Where the pictures go: a folder per area under it.
const String _dirGiven = String.fromEnvironment('TOUR_DIR');
final String _dir = _dirGiven.isEmpty ? 'shots/gallery/tour' : _dirGiven;

/// The phone: an iPhone of 390 by 844 points, three pixels a point, its
/// notch and its home bar.
const Size _phone = Size(390, 844);
const double _notch = 47;
const double _homeBar = 34;
const double _ratio = 3;

// ---------------------------------------------------------------------------
// The camera.

/// A roll of film for one area: the pictures numbered as they are taken,
/// each with its caption, kept beside them in captions.json.
class _Roll {
  _Roll(this.area, {this.prefix = ''});

  final String area;

  /// Put before each number, to keep two parts of one area apart (A01, B01).
  final String prefix;

  int _n = 0;

  static final Map<String, Map<String, Object>> _kept = {};

  File get _file => File('$_dir/$area/captions.json');

  Map<String, Object> get _captions => _kept.putIfAbsent(area, () {
    if (!_file.existsSync()) return {};
    return (jsonDecode(_file.readAsStringSync()) as Map).cast<String, Object>();
  });

  /// Photographs the app as it is now, as [slug], captioned [caption]; with
  /// [touch] the point a finger is on, in points, drawn on the sheet.
  Future<void> take(
    WidgetTester tester,
    String slug,
    String caption, {
    Offset? touch,
  }) async {
    await _decodeShown(tester);
    _n++;
    final String name = '$prefix${_n.toString().padLeft(2, '0')}-$slug';
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$_dir/$area/$name.png'),
    );
    _captions['$name.png'] = {
      'caption': caption,
      if (touch != null) 'touch': [touch.dx, touch.dy],
    };
    _file.parent.createSync(recursive: true);
    _file.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(
        Map.fromEntries(
          _captions.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
      ),
    );
  }
}

/// A picture of the bank's own, from the folder the site serves them from:
/// a card's from web/cards/thumbs/, a book's cover from web/cards/covers/,
/// a founder's photograph from web/cards/people/.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final int at = path.indexOf('cards');
  final String rel = (at < 0 ? path : path.sublist(at + 1)).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

/// A drawn card's page, which a phone shows in a WebView and a test cannot:
/// its photograph from the site (`web/cards/thumbs/<id>-front.webp`) in the
/// page's place, the page itself read from web/cards/pages/. The card's
/// back is the app's own, as on the phone.
class _InstantKit extends CardKit {
  @override
  Future<String> page(String html, PageEnv env) => Future.value(html);
}

final Map<String, ImageProvider> _pagePhotos = {};

Widget _pageFace(FakeWebSurface surface) {
  final String? id = RegExp(r'tour-page:([A-Za-z0-9_-]+)')
      .firstMatch(surface.html ?? '')
      ?.group(1);
  if (id == null) return const SizedBox.expand();
  final ImageProvider photo = _pagePhotos.putIfAbsent(id, () {
    final File file = File('web/cards/thumbs/$id-front.webp');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
  return Image(image: photo, fit: BoxFit.fill, gaplessPlayback: true);
}

void _drawnPagesAsPhotos() {
  CardKit.instance = _InstantKit();
  CardPages.instance = CardPages(
    fetch: (url) async {
      final String file = url.pathSegments.last;
      final String id = file.endsWith('.html')
          ? file.substring(0, file.length - 5)
          : file;
      final File page = File('web/cards/pages/$id.html');
      if (!page.existsSync()) return null;
      return '<!-- tour-page:$id -->${page.readAsStringSync()}';
    },
    store: MemoryPageStore(),
  );
  FakeWebSurface.reset();
  WebSurfaces.debugUse(() => FakeWebSurface(face: _pageFace));
}

/// [message] said by the live page of the drawn card [id], as the page would
/// say it when the reader taps it. False when no page of it is live.
bool _pageSays(String id, PageMessage message) {
  for (final FakeWebSurface s in FakeWebSurface.made.reversed) {
    if (!s.disposed && (s.html ?? '').contains('tour-page:$id ')) {
      s.say(message);
      return true;
    }
  }
  return false;
}

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture on screen, decoded before the photograph, in real time, as
/// a phone has them by the time a screen has come to rest.
Future<void> _decodeShown(WidgetTester tester) async {
  final Set<ImageProvider> shown = {
    for (final Image image in tester.widgetList<Image>(find.byType(Image)))
      image.image,
  };
  if (shown.isEmpty) return;
  final BuildContext context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final ImageProvider p in shown) {
      await precacheImage(
        p,
        context,
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 10), onTimeout: () {});
    }
  });
  for (int f = 0; f < 3; f++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// The phone in the hand: its size, its insets, Italian, at night, an
/// iPhone's controls.
void _hold(WidgetTester tester) {
  final view = tester.view;
  view.physicalSize = _phone * _ratio;
  view.devicePixelRatio = _ratio;
  view.padding = const FakeViewPadding(
    top: _notch * _ratio,
    bottom: _homeBar * _ratio,
  );
  view.viewPadding = view.padding;
  tester.platformDispatcher.localesTestValue = const [Locale('it')];
  tester.platformDispatcher.localeTestValue = const Locale('it');
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  addTearDown(() {
    view.reset();
    tester.platformDispatcher.clearLocalesTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}

/// Nothing asked of the reader over what is photographed: the sheets that
/// rise by themselves (a reminder, the widget, an account, a review, a goal,
/// where they live) have each had their turn.
const Map<String, Object> _quiet = {
  'knowit.pushAsked': true,
  'knowit.widgetAsked': true,
  'knowit.accountOffered': true,
  'knowit.reviewAsked': true,
  'knowit.goalAsked': true,
  'knowit.placeAsks': 9,
};

/// The app opened on [prefs], on the phone, until it is at rest.
Future<void> _open(WidgetTester tester, Map<String, Object> prefs) async {
  _hold(tester);
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(const AstutoApp());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await _settle(tester, 20);
}

Finder _keyed(String key) => find.byKey(ValueKey(key));

/// Back, as the edge swipe or the sheet pulled down does: the route that
/// holds [inside] goes, or the root navigator's top one.
Future<void> _back(WidgetTester tester, [Finder? inside]) async {
  final NavigatorState nav = inside != null && _has(inside)
      ? Navigator.of(tester.element(inside.first))
      : tester.state(find.byType(Navigator).first);
  await nav.maybePop();
  await _settle(tester, 12);
}

Finder _prefixed(String prefix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix),
);

bool _has(Finder f) {
  try {
    return f.evaluate().isNotEmpty;
  } on StateError {
    // A first or last of nothing.
    return false;
  }
}

/// The list that scrolls down the screen in front: the last one built.
Finder _down({bool first = false}) {
  final Finder all = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  return first ? all.first : all.last;
}

String _day(int back) {
  final DateTime now = DateTime.now();
  return dateKey(DateTime(now.year, now.month, now.day - back));
}

Pill _card(String id) => PillBank.byId(id)!;

/// What a card asks, in a word, for a caption.
String _kindOf(Pill p) => switch (p.challenge) {
  PickOne() => 'scelta',
  TypeNumber() => 'numero',
  Estimate() => 'stima',
  TakeASide() => 'da che parte stai',
  PageJudged() => 'pagina',
  NoChallenge() => p.scene != null ? 'da giocare' : 'da leggere',
};

// ---------------------------------------------------------------------------
// The readers.

/// The five Today is dealt for the tour, of five subjects and five kinds: a
/// pick with its idea said simply, a pick with its chart, a card that tells,
/// the two sides of a question, and a drawn card, its page.
const List<String> _todayFive = [
  'history-mongol-5',
  'economics-2008-3',
  'psychology-5',
  'art-florence-4',
  'space-apollo13-tank-fire',
];

/// A reader on the fourth day, on the free plan, today's five dealt and
/// [index] of them read: three days kept, a handful of answers behind them.
Map<String, Object> _fourDaysIn({int index = 0, bool plus = false}) {
  final List<Pill> before = [
    for (final Pill p in PillBank.cards)
      if (p.isGraded && p.web == null && !_todayFive.contains(p.id)) p,
  ].take(6).toList();
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    ..._quiet,
    'knowit.installedOn': _day(3),
    'knowit.todayDate': _day(0),
    'knowit.todayDeckIds': _todayFive,
    'knowit.todayIndex': index,
    'knowit.streak': 3,
    'knowit.bestStreak': 3,
    'knowit.lastCompletionDate': _day(1),
    'knowit.completedDates': [_day(3), _day(2), _day(1)],
    'knowit.seenIds': [
      ...before.map((p) => p.id),
      ...PillBank.cards
          .where((p) => !_todayFive.contains(p.id))
          .skip(300)
          .take(9)
          .map((p) => p.id),
    ],
    'knowit.judgements': jsonEncode([
      for (final (int i, Pill p) in before.indexed)
        {'c': 70, 'k': i != 2, 'p': p.id, 'd': _day(3 - i ~/ 2)},
    ]),
    LevelMemory.key: 0,
  };
}

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Explore's reader, shelves and paper.

/// This morning's paper: the fixture of 26 November 2026, the paper the
/// pipeline would have written from that day's real reports. Nothing is
/// asked of the server for another.
void _paperOfToday() {
  final Map<String, Object?> paper = jsonDecode(
    File('tool/news/paper.json').readAsStringSync(),
  ) as Map<String, Object?>;
  NewsPaper.reset();
  NewsPaper.call = () async => null;
  NewsPaper.adopt(paper['date'] as String?, paper['cards']! as List<Object?>);
}

List<Pill> _drawnOf(String topic, int n, {int skip = 0}) => PillBank.cards
    .where((p) => p.topic == topic && CardThumb.has(p, CardSide.front))
    .skip(skip)
    .take(n)
    .toList();

/// A reader two weeks in, on the free plan (tool/explore_tour_shots.dart's):
/// a streak, cards kept, liked and read, a city, answers come back to be
/// answered again; today's five dealt and not yet read.
Map<String, Object> _twoWeeksIn({bool plus = false}) {
  final List<Pill> saved = [
    ..._drawnOf('Space', 3),
    ..._drawnOf('History', 2),
    ..._drawnOf('Psychology', 2),
  ];
  final List<Pill> liked = [
    ..._drawnOf('Space', 4, skip: 3),
    ..._drawnOf('Art', 2),
  ];
  final List<Pill> due = PillBank.cards
      .where((p) => p.challenge is PickOne && p.topic == 'History')
      .take(4)
      .toList();
  final DateTime now = DateTime.now();
  return {
    'knowit.onboarded': true,
    ..._quiet,
    'knowit.plus': plus,
    'knowit.streak': 13,
    'knowit.installedOn': dateKey(now.subtract(const Duration(days: 14))),
    'knowit.completedDates': [
      for (var back = 1; back < 14; back++)
        dateKey(now.subtract(Duration(days: back))),
    ],
    'knowit.savedIds': [for (final p in saved) p.id],
    'knowit.likedIds': [for (final p in liked) p.id],
    'knowit.seenIds': {
      for (final p in [...saved, ...liked, ...due]) p.id,
      ...PillBank.cards.skip(200).take(60).map((p) => p.id),
    }.toList(),
    'knowit.topicWeights': jsonEncode({'space': 1.0, 'history': 0.8}),
    'knowit.place': jsonEncode({
      'country': 'IT',
      'region': 'IT-45',
      'city': 'Bologna',
      'lat': 44.494,
      'lon': 11.343,
    }),
    'knowit.answersJson': jsonEncode({
      for (int i = 0; i < due.length; i++)
        due[i].id: {'r': '0', 's': i.isEven ? 1 : 0, 'd': _day(1)},
    }),
    LevelMemory.key: 1,
  };
}

/// The server's shelves for that reader, as the phone kept them: made up
/// for the photograph from the bank's drawn cards, as the server would rank
/// them (tool/explore_tour_shots.dart's).
ServedExplore _servedShelves() {
  List<ServedRank> ranked(List<Pill> cards) => [
    for (int i = 0; i < cards.length; i++) ServedRank(cards[i], 90 - i * 7),
  ];
  final List<Pill> today = [
    for (final String topic in kTopicOrder.map((k) => kTopics[k]!.name))
      ..._drawnOf(topic, 2, skip: 5),
  ];
  return ServedExplore(
    day: dateKey(DateTime.now()),
    today: today,
    asking: askingPills(seed: 'served-asking', count: 40),
    topWeek: ranked([
      ..._drawnOf('Psychology', 3, skip: 3),
      ..._drawnOf('Space', 3, skip: 8),
    ]),
    topMonth: ranked([
      ..._drawnOf('History', 3, skip: 6),
      ..._drawnOf('Food', 3),
    ]),
    loved: ranked([
      ..._drawnOf('Art', 3, skip: 2),
      ..._drawnOf('Music', 3),
      ..._drawnOf('Cinema', 2),
    ]),
    bySubject: const {},
    because: 'space',
    mine: _drawnOf('Space', 10, skip: 10),
    forYou: [..._drawnOf('Nature', 4, skip: 2), ..._drawnOf('Technology', 4)],
    local: PillBank.placeCards
        .where((p) => p.place?.city == 'Bologna')
        .toList(),
  );
}

/// Explore's document as it is on [weekday] (1 Monday to 7 Sunday): the
/// sections kept for a weekday made true on that day and false on the others
/// (tool/explore_tour_shots.dart's).
void _adoptOnWeekday(int weekday) {
  final Map<String, Object?> parts = Map.of(Remote.embedded.parts);
  Object? fixed(Object? rule) {
    if (rule is Map) {
      return {
        for (final MapEntry<Object?, Object?> e in rule.entries)
          if (e.key == 'weekdays')
            'minBuild': (e.value as List).contains(weekday) ? 0 : 99999
          else
            '${e.key}': fixed(e.value),
      };
    }
    if (rule is List) return [for (final Object? r in rule) fixed(r)];
    return rule;
  }

  final Map<String, Object?> explore = Map.of(
    parts['explore']! as Map<String, Object?>,
  );
  explore['sections'] = [
    for (final Object? s in explore['sections']! as List)
      if (s is Map<String, Object?>)
        {...s, if (s['audience'] != null) 'audience': fixed(s['audience'])},
  ];
  parts['explore'] = explore;
  Remote.adopt(
    RemoteConfig(
      hash: 'tour-weekday-$weekday',
      schema: kRemoteSchema,
      parts: parts,
    ),
  );
}

/// Explore's sections by what a reader calls them, for the captions.
const Map<String, String> _sectionNames = {
  'three': 'Le cinque di oggi',
  'your-five': 'Le tue cinque di oggi',
  'continue': 'Continua',
  'cover': 'Copertina',
  'videos': 'Carte da guardare',
  'news-today': 'Ultime notizie',
  'line-of-day': 'La frase del giorno',
  'maths-daily': 'Il problema del giorno',
  'where-you-live': 'Dove vivi',
  'surprise-mon': 'Sorpresa del lunedì',
  'surprise-tue': 'Sorpresa del martedì',
  'surprise-wed': 'Grafici che ingannano',
  'surprise-thu': 'Sorpresa del giovedì',
  'surprise-fri': 'Sorpresa del venerdì',
  'surprise-sat': 'Sorpresa del sabato',
  'surprise-sun': 'Sorpresa della domenica',
  'paths': 'Percorsi da 10 carte',
  'quick-games': 'Sfide',
  'books': 'Libri in pillole',
  'founders': 'Cosa leggono i fondatori',
  'plus-offer': 'Offerta Astute+',
  'top': 'I più letti',
  'goal': 'Ti serve per',
  'feed': 'Continua a esplorare',
};

/// The sections a reader sees now, top to bottom: those with at least 40
/// points of themselves between the notch and the tab bar.
List<String> _sectionsOnScreen(WidgetTester tester) {
  final List<(double, String)> on = [];
  for (final Element e
      in find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                ((w.key! as ValueKey<String>).value.startsWith('section-') ||
                    (w.key! as ValueKey<String>).value.startsWith('watch-')) &&
                !(w.key! as ValueKey<String>).value.startsWith(
                  'section-page',
                ) &&
                !(w.key! as ValueKey<String>).value.startsWith(
                  'section-subject',
                ),
          )
          .evaluate()) {
    final RenderObject? box = e.renderObject;
    if (box is! RenderBox || !box.hasSize || !box.attached) continue;
    final Rect r = box.localToGlobal(Offset.zero) & box.size;
    final double seen =
        math.min(r.bottom, _phone.height - 90) - math.max(r.top, _notch);
    if (seen < 40) continue;
    final String key = (e.widget.key! as ValueKey<String>).value;
    final String id = key.substring(key.indexOf('-') + 1);
    final String name = _sectionNames[id] ?? id;
    if (on.any((s) => s.$2 == name)) continue;
    on.add((r.top, name));
  }
  on.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final s in on) s.$2];
}

/// Explore for the reader two weeks in, with today's paper and the
/// server's shelves, at its top.
Future<void> _openExplore(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  _paperOfToday();
  Served.useForTest(
    Served(
      storeOverride: MemoryServedStore()..shelves = _servedShelves(),
      uidOverride: 'reader',
    ),
  );
  ExplorePlay.resetForTest();
  BetsDay.resetForTest();
  ThreeDays.resetForTest();
  await _open(tester, {..._twoWeeksIn(), ...prefs});
  await tester.tap(_keyed('tab-Explore').first);
  await _settle(tester, 20);
}

/// The page in front, screen after screen from its top, each a little less
/// than a screen on from the last, as a thumb sends it; down to where the
/// endless feed has begun, and one screen into it.
Future<void> _scrollTour(WidgetTester tester, _Roll roll, String where) async {
  final ScrollableState list = tester.state(_down(first: true));
  final double step = _phone.height * 0.72;
  int inFeed = 0;
  for (int i = 0; i < 60; i++) {
    final List<String> on = _sectionsOnScreen(tester);
    await roll.take(
      tester,
      'schermata',
      '$where · ${i + 1}${on.isEmpty ? '' : ' · ${on.join(', ')}'}',
    );
    // The endless feed, by its head: once it has come up, two more.
    if (_has(find.text('Continua a esplorare'))) inFeed = math.max(inFeed, 1);
    if (inFeed > 0 && inFeed++ > 2) break;
    final double before = list.position.pixels;
    if (before >= list.position.maxScrollExtent - 1) break;
    await tester.dragFrom(
      Offset(_phone.width - 24, _phone.height * 0.8),
      Offset(0, -step),
    );
    await _settle(tester);
    if (list.position.pixels == before) break;
  }
}

/// Scrolls Explore until the section [id] is built, then brings its top to
/// [above] points under the top of the screen.
Future<bool> _reach(
  WidgetTester tester,
  String key, {
  double above = 110,
}) async {
  final Finder target = find.byKey(ValueKey(key), skipOffstage: false);
  final ScrollableState list = tester.state(_down(first: true));
  for (int i = 0; i < 80 && target.evaluate().isEmpty; i++) {
    if (list.position.pixels >= list.position.maxScrollExtent - 1) break;
    list.position.jumpTo(
      math.min(list.position.pixels + 400, list.position.maxScrollExtent),
    );
    await tester.pump();
  }
  if (target.evaluate().isEmpty) return false;
  await tester.pump();
  final double top = tester.getTopLeft(target.first).dy;
  list.position.jumpTo(
    (list.position.pixels + top - above).clamp(
      0.0,
      list.position.maxScrollExtent,
    ),
  );
  await _settle(tester);
  return true;
}

/// [target] scrolled into the middle of [list], from the list's top down
/// until it is built.
Future<void> _bringIntoView(
  WidgetTester tester,
  Finder target,
  Finder list,
) async {
  final ScrollableState s = tester.state(list.first);
  s.position.jumpTo(0);
  await tester.pump();
  for (int i = 0; i < 40 && !_has(target); i++) {
    if (s.position.pixels >= s.position.maxScrollExtent - 1) break;
    s.position.jumpTo(
      math.min(s.position.pixels + 300, s.position.maxScrollExtent),
    );
    await tester.pump();
  }
  await Scrollable.ensureVisible(tester.element(target.first), alignment: 0.4);
  await _settle(tester, 8);
}

/// The page in front scrolled by [by] points, as far as it goes; false when
/// it moved less than a line.
Future<bool> _scrollBy(WidgetTester tester, double by, {Finder? list}) async {
  final Finder f = list ?? _down();
  if (!_has(f)) return false;
  final ScrollableState s = tester.state(f.first);
  final double before = s.position.pixels;
  s.position.jumpTo(
    (before + by).clamp(s.position.minScrollExtent, s.position.maxScrollExtent),
  );
  await _settle(tester, 8);
  return (s.position.pixels - before).abs() > 40;
}

// ---------------------------------------------------------------------------
// Today's five: today's players, made up.

/// How the server judges an answer (functions/src/daily.ts).
({bool right, int points, int? pick, double? guess}) _judge(
  String id,
  String said,
) {
  final Pill p = PillBank.byId(id)!;
  final bool pick = p.challenge is PickOne;
  return (
    right: p.challenge.accepts(said),
    points: dailyPoints(p, said),
    pick: pick ? int.parse(said) : null,
    guess: pick ? null : double.parse(said),
  );
}

/// Today's players before the reader: about three hundred, by score, and on
/// each card a share right (tool/today_five_shots.dart's).
DailyCounts _crowd(List<Pill> cards, int max) {
  final int top = max ~/ 10;
  final List<int> scores = [
    for (int b = 0; b <= top; b++)
      (11 * math.exp(-math.pow((b - top * 0.58) / (top * 0.17), 2) / 2))
          .round(),
  ];
  final int players = scores.fold(0, (a, b) => a + b);
  final Map<String, DailyItemCounts> items = {};
  for (final (int i, Pill p) in cards.indexed) {
    final double share = [0.71, 0.38, 0.56, 0.83, 0.47][i % 5];
    final int right = (players * share).round();
    switch (p.challenge) {
      case PickOne(:final correct, :final options):
        final List<int> picks = List.filled(options.length, 0);
        picks[correct] = right;
        int left = players - right;
        for (int o = 0; o < options.length; o++) {
          if (o == correct) continue;
          final int some = o == options.length - 1 || left == 0
              ? left
              : (left * 0.6).round();
          picks[o] += some;
          left -= some;
        }
        items[p.id] = DailyItemCounts(n: players, right: right, picks: picks);
      default:
        final double truth = answerOf(p)?.value ?? 50;
        final double mean = (truth + 9).clamp(0, 100).toDouble();
        final List<int> guesses = List.filled(11, 0);
        guesses[(mean / 10).floor().clamp(0, 10)] = players;
        items[p.id] = DailyItemCounts(
          n: players,
          right: (players * 0.12).round(),
          guesses: guesses,
          sum: mean * players,
        );
    }
  }
  return DailyCounts(players: players, scores: scores, items: items);
}

void _todaysPlayers() {
  final DateTime now = DateTime.now();
  final MemoryDailyStore store = MemoryDailyStore(judge: _judge);
  final List<Pill> five = DailyDeal.five(now);
  store.put(
    DailyGame.five(dateKey(now)).keyFor([for (final p in five) p.id]),
    _crowd(five, 500),
  );
  DailyCrowd.useForTest(store);
}

// ---------------------------------------------------------------------------
// A film that plays nothing (tool/video_shots.dart's player): it shows the
// frame it is told, taken from the Italian film with ffmpeg into TOUR_FILM.

const String _filmGiven = String.fromEnvironment('TOUR_FILM');

class _Player extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _events = {};
  Duration position = Duration.zero;
  Uint8List? frame;
  int _next = 1;

  int get last => _next - 1;

  void end(int id) {
    position = const Duration(milliseconds: 52700);
    _events[id]!.add(VideoEvent(eventType: VideoEventType.completed));
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final int id = _next++;
    final StreamController<VideoEvent> events = StreamController();
    _events[id] = events;
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(milliseconds: 52700),
          size: const Size(1080, 2340),
        ),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async => _events[playerId]?.close();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration to) async => position = to;

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => frame == null
      ? const SizedBox.expand()
      : Image.memory(frame!, fit: BoxFit.fill, gaplessPlayback: true);

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool preventsDisplaySleepDuringVideoPlayback,
  ) async {}
}

// ---------------------------------------------------------------------------
// The reader of Your journey: twelve weeks in, on Astute+
// (tool/journey_shots.dart's).

DateTime get _journeyDay0 {
  final DateTime now = DateTime.now();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 85));
}

String _journeyKey(int d) => dateKey(_journeyDay0.add(Duration(days: d)));

const Set<int> _journeyOff = {
  3, 5, 8, 12, 17, 22, 26, 31, 35, 39, 59, 63, 67, 70, 73, //
};
const List<int> _journeyWeekly = [
  16,
  21,
  22,
  24,
  20,
  25,
  27,
  24,
  28,
  27,
  30,
  33,
  15,
];
const Map<String, int> _journeySubjects = {
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

({Map<String, Object> prefs, Map<String, List<int>> log}) _journeyReader() {
  final rand = math.Random(7);
  final perDay = List<int>.filled(86, 0);
  for (var w = 0; w < 13; w++) {
    final days = [
      for (var d = 0; d < 86; d++)
        if ((d + 1) ~/ 7 == w && !_journeyOff.contains(d)) d,
    ];
    final int base = _journeyWeekly[w] ~/ days.length;
    final int rem = _journeyWeekly[w] - base * days.length;
    final order = [...days]
      ..sort((a, b) => (a * 37 % 11).compareTo(b * 37 % 11));
    for (final d in days) {
      perDay[d] = base + (order.indexOf(d) < rem ? 1 : 0);
    }
  }
  final slots = <(double, String)>[];
  final ranked = _journeySubjects.keys.toList();
  for (var r = 0; r < ranked.length; r++) {
    final int c = _journeySubjects[ranked[r]]!;
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
      readDays.putIfAbsent(_journeyKey(d), () => []).add(card.id);
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
    final double off = 0.31 - 0.29 * t;
    var day = d;
    var right = rand.nextDouble() < (sure / 100 - off).clamp(0.05, 0.98);
    events.add((
      day,
      {'c': sure, 'k': right, 'p': card.id, 'd': _journeyKey(day)},
    ));
    const comeBack = [2, 7, 21];
    const keep = [1.08, 0.86, 0.52];
    var run = right ? 1 : 0;
    while (run < 3 && day + comeBack[run] <= 85) {
      day += comeBack[run];
      final double now = 0.31 - 0.29 * day / 85;
      right =
          rand.nextDouble() <
          ((sure / 100 - now) * keep[run]).clamp(0.05, 0.98);
      events.add((
        day,
        {'c': sure, 'k': right, 'p': card.id, 'd': _journeyKey(day)},
      ));
      run = right ? run + 1 : 0;
    }
    answers[card.id] = {
      'r': '${right ? pick.correct : (pick.correct + 1) % pick.options.length}',
      'c': sure,
      if (run != 0) 's': run,
      if (run < 3) 'd': _journeyKey(day + comeBack[run]),
    };
  }
  events.sort((a, b) => a.$1.compareTo(b.$1));
  final log = <String, List<int>>{};
  for (var d = 0; d < 86; d++) {
    if (perDay[d] == 0) continue;
    final parts = List<int>.filled(4, 0);
    for (var i = 0; i < perDay[d]; i++) {
      final int r = rand.nextInt(100);
      final int part = r < 44 ? 0 : (r < 56 ? 1 : (r < 92 ? 2 : 3));
      parts[part] += 1;
    }
    log[_journeyKey(d)] = [0, perDay[d] * (34 + 10 * d ~/ 85), ...parts];
  }
  final List<String> active = [
    for (var d = 0; d < 86; d++)
      if (perDay[d] > 0) _journeyKey(d),
  ];
  return (
    prefs: {
      'knowit.onboarded': true,
      ..._quiet,
      'knowit.plus': true,
      'knowit.streak': 12,
      'knowit.bestStreak': 19,
      'knowit.lastCompletionDate': _journeyKey(85),
      'knowit.completedDates': active,
      'knowit.seenIds': [for (final r in reads) r.$2.id],
      'knowit.readDays': jsonEncode(readDays),
      'knowit.judgements': jsonEncode([for (final e in events) e.$2]),
      'knowit.answersJson': jsonEncode(answers),
    },
    log: log,
  );
}

// ---------------------------------------------------------------------------
// The reader of the profile: three weeks in, on the free plan, halfway
// through today (tool/profile_shots.dart's), with a few cards liked.

Map<String, Object> _threeWeeksIn({bool plus = false}) {
  final rand = math.Random(11);
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String day(int back) => dateKey(today.subtract(Duration(days: back)));
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
    completed.add(day(back));
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
      final double chance = (hard ? 0.4 : 0.55) + 0.25 * t;
      judged.add({
        'c': 60 + 10 * rand.nextInt(4),
        'k': rand.nextDouble() < chance,
        'p': card.id,
        'd': day(back),
      });
    }
  }
  final List<String> deck = dealDay(date: now).cards
      .take(kPillsPerDay)
      .map((p) => p.id)
      .toList();
  final int readNow = plus ? kPillsPerDay : 3;
  for (final (int i, String id) in deck.take(readNow).indexed) {
    final Pill? card = PillBank.byId(id);
    if (card == null || !card.isGraded) continue;
    judged.add({'c': 70, 'k': i != 1, 'p': id, 'd': day(0)});
  }
  if (plus) completed.add(day(0));
  final List<String> liked = [
    ..._drawnOf('Space', 3),
    ..._drawnOf('Psychology', 2),
    ..._drawnOf('History', 2),
  ].map((p) => p.id).toList();
  return {
    'knowit.onboarded': true,
    ..._quiet,
    'knowit.plus': plus,
    'knowit.streak': plus ? 5 : 4,
    'knowit.bestStreak': 9,
    'knowit.lastCompletionDate': plus ? day(0) : day(1),
    'knowit.completedDates': completed,
    'knowit.seenIds': [...seen, ...deck.take(readNow), ...liked],
    'knowit.likedIds': liked,
    'knowit.savedIds': liked.take(4).toList(),
    'knowit.judgements': jsonEncode(judged),
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': readNow,
    'knowit.place': jsonEncode({
      'country': 'IT',
      'region': 'IT-45',
      'city': 'Bologna',
      'lat': 44.494,
      'lon': 11.343,
    }),
  };
}

void main() {
  setUpAll(() async {
    await loadFonts();
    // Nothing asks the network: the bank and the document are the ones the
    // build carries, the document as the server last said it.
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // A build of today's, which the document's newest sections are for.
    Remote.build = 99;
    CardThumb.image = _picture;
    _drawnPagesAsPhotos();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    Analytics.canAskForTest = null;
  });

  // -------------------------------------------------------------------------
  // 1. The onboarding, every step in order.
  testWidgets('onboarding', (tester) async {
    final _Roll roll = _Roll('onboarding');
    // A build with somewhere to send measurement, as the store's has: the
    // intro asks about it. Answered no below; nothing is ever sent.
    Analytics.canAskForTest = true;
    await _open(tester, const {});

    // The intro: five scenes, a tap for each.
    for (int scene = 0; scene < 5; scene++) {
      for (int f = 0; f < 16; f++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      await roll.take(
        tester,
        'intro-scena-${scene + 1}',
        scene == 0
            ? 'Intro, scena 1 di 5: il marchio, la domanda sulle statistiche d’uso'
            : 'Intro, scena ${scene + 1} di 5',
      );
      if (scene < 4) {
        await tester.tapAt(const Offset(195, 330));
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    // The question about measuring, answered no.
    final Finder no = find.text('No, grazie');
    if (_has(no)) {
      await tester.tap(no.first);
      await _settle(tester, 10);
      await roll.take(
        tester,
        'intro-dopo-il-no',
        'Intro dopo «No, grazie»: resta solo «Inizia a leggere»',
      );
    }
    await tester.tap(find.text('Inizia a leggere').first);
    await _settle(tester, 20);

    // The subjects: everything in, each turned down by dragging it left.
    await roll.take(
      tester,
      'materie',
      'Materie: tutte piene all’inizio, si trascinano a sinistra per averne meno',
    );
    Finder tile(String key) =>
        find.byWidgetPredicate((w) => w is MixTile && w.subject.key == key);
    // Drags [key]'s bar to [to] of its width, photographing it half way
    // when [midShot] says so.
    Future<void> drag(String key, double to, {String? midShot}) async {
      final Rect r = tester.getRect(tile(key));
      final Offset start = Offset(r.left + r.width * 0.94, r.center.dy);
      final Offset end = Offset(r.left + r.width * to, r.center.dy);
      final TestGesture finger = await tester.startGesture(start);
      const int steps = 12;
      for (int s = 1; s <= steps; s++) {
        await finger.moveTo(Offset.lerp(start, end, s / steps)!);
        await tester.pump(const Duration(milliseconds: 30));
        if (midShot != null && s == steps ~/ 2) {
          await tester.pump(const Duration(milliseconds: 120));
          await roll.take(
            tester,
            'materie-trascino',
            midShot,
            touch: Offset.lerp(start, end, 0.5),
          );
        }
      }
      await finger.up();
      await tester.pump(const Duration(milliseconds: 200));
    }

    await drag(
      'sport',
      0,
      midShot: 'Materie: Sport trascinata verso sinistra, a metà corsa',
    );
    await drag('pop_culture', 0);
    await drag('cinema', 0.3);
    await drag('music', 0.5);
    await drag('medicine', 0.7);
    await drag('weird_facts', 0.15);
    await _settle(tester, 8);
    await roll.take(
      tester,
      'materie-scelte',
      'Materie scelte: Sport e Cultura pop tolte, altre ridotte; il conto in fondo',
    );
    await tester.tap(find.text('Avanti').last);
    await _settle(tester, 20);

    // The genres: the subjects in the order the wheel left them, six genres
    // each, every one on.
    await roll.take(
      tester,
      'generi',
      'Generi: le materie nell’ordine del mix, sei generi ciascuna, tutti accesi',
    );
    final List<Genre> economics = kGenres['economics']!;
    final Finder second = find.text(themeName(economics[1], 'it')).first;
    await tester.tap(second);
    await _settle(tester, 6);
    await roll.take(
      tester,
      'generi-tocco',
      'Generi: un tocco spegne «${themeName(economics[1], 'it')}» (12 di 13)',
      touch: tester.getCenter(second),
    );

    // A hold on the first genre: what is inside it opens under the row.
    final Finder firstChip = find.text(themeName(economics.first, 'it')).first;
    final Offset at = tester.getCenter(firstChip);
    final TestGesture press = await tester.startGesture(at);
    await tester.pump(const Duration(milliseconds: 250));
    await roll.take(
      tester,
      'generi-pressione',
      'Generi: dito tenuto su «${themeName(economics.first, 'it')}» (prima che si apra)',
      touch: at,
    );
    // Past the hold's half second: it opens, and is caught opening.
    await tester.pump(const Duration(milliseconds: 300));
    int opened = 0;
    for (final int ms in const [40, 60, 70, 90]) {
      await tester.pump(Duration(milliseconds: ms));
      opened += ms;
      await roll.take(
        tester,
        'generi-si-apre-$opened',
        'Generi: i sotto-argomenti si aprono ($opened ms dopo la presa)',
        touch: at,
      );
    }
    await press.up();
    await _settle(tester, 8);
    await roll.take(
      tester,
      'generi-aperto',
      'Generi: «${themeName(economics.first, 'it')}» aperto, i suoi sotto-argomenti',
    );
    // One strand inside turned off.
    final Strand strand = economics.first.strands[1];
    final String strandName = kStrandNames['it']?[strand.id] ?? strand.label;
    final Finder strandRow = find.text(strandName);
    if (_has(strandRow)) {
      final Offset s = tester.getCenter(strandRow.first);
      await tester.tap(strandRow.first);
      await _settle(tester, 6);
      await roll.take(
        tester,
        'generi-sottoargomento-spento',
        'Generi: un sotto-argomento spento («$strandName»)',
        touch: s,
      );
    }
    // Down the list, to the subjects left out of the mix at its foot.
    final ScrollableState list = tester.state(_down());
    for (int i = 1; i < 12; i++) {
      final double before = list.position.pixels;
      list.position.jumpTo(
        math.min(list.position.pixels + 560, list.position.maxScrollExtent),
      );
      await _settle(tester, 6);
      if (list.position.pixels == before) break;
      await roll.take(tester, 'generi-giu-$i', 'Generi, più giù ($i)');
      if (list.position.pixels >= list.position.maxScrollExtent - 1) break;
    }
    await tester.tap(find.textContaining('Continua').last);
    await _settle(tester, 20);

    // The first day.
    final PillCardStack deck = tester.widget(find.byType(PillCardStack));
    final Pill top = deck.deck[deck.index];
    final String drawn = top.web != null
        ? ' (carta disegnata: qui la foto della sua pagina dal sito, in '
              'inglese; sul telefono la materia in cima è in italiano)'
        : '';
    await roll.take(
      tester,
      'primo-giorno',
      'Il primo giorno: la prima carta, subito dopo l’onboarding$drawn',
    );
    // Turned over, once the swipe hint of the first day has played: a
    // drawn card by its page, a card in words by a tap. Photographed only
    // if it turned.
    await _settle(tester, 40);
    if (top.web != null) {
      _pageSays(top.id, const PageTap());
    } else {
      await tester.tap(find.byType(PillCardStack), warnIfMissed: false);
    }
    await _settle(tester, 24);
    if (_has(_keyed('card-foot-${top.id}'))) {
      await roll.take(
        tester,
        'primo-giorno-retro',
        'Il primo giorno: la prima carta girata',
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // -------------------------------------------------------------------------
  // 2. Today: the first card, a card front and back, Go deeper, Why this
  // card, the day finished and sent.
  testWidgets('today', (tester) async {
    final _Roll roll = _Roll('today');
    await _open(tester, _fourDaysIn());
    final Finder stack = find.byType(PillCardStack);

    await roll.take(tester, 'prima-carta', 'Oggi: la prima carta (fronte)');

    // The first card, a pick: answered, how sure said, turned over.
    final Pill first = _card(_todayFive[0]);
    final PickOne pick = first.challenge as PickOne;
    final Finder option = find.text(pick.options[pick.correct]);
    final Offset optionAt = tester.getCenter(option.first);
    await tester.tap(option.first);
    await _settle(tester, 8);
    await roll.take(
      tester,
      'risposta-scelta',
      'Prima carta: risposta scelta, «quanto sei sicuro?»',
      touch: optionAt,
    );
    final Finder sure = find.text('70%');
    if (_has(sure)) {
      await tester.tap(sure.first);
      await _settle(tester, 20);
    }
    final Finder foot = _keyed('card-foot-${first.id}');
    if (!_has(foot)) {
      await tester.tap(stack, warnIfMissed: false);
      await _settle(tester, 20);
    }
    await roll.take(tester, 'retro', 'Prima carta: il retro, la risposta');

    // Go deeper, from the source on the back: its line starts with the
    // words, the source after them.
    final Finder deeper = find
        .textContaining('Approfondisci', findRichText: true)
        .hitTestable();
    if (_has(deeper)) {
      await tester.tapAt(tester.getTopLeft(deeper.first) + const Offset(24, 9));
    }
    await _settle(tester, 26);
    if (_has(_keyed('deeper-head'))) {
      await roll.take(tester, 'approfondisci', 'Approfondisci: come si apre');
      // Drawn up to its full height, as a thumb does, then read down.
      await tester.timedDrag(
        _keyed('deeper-head'),
        Offset(0, -_phone.height * 0.32),
        const Duration(milliseconds: 900),
      );
      await _settle(tester, 12);
      await roll.take(
        tester,
        'approfondisci-alzato',
        'Approfondisci, tirato su a tutta altezza',
      );
      for (final (String key, double at, String slug, String caption) in [
        (
          'deeper-source',
          0.35,
          'approfondisci-fonte',
          'Approfondisci: la fonte',
        ),
        (
          'deeper-report',
          0.9,
          'approfondisci-fondo',
          'Approfondisci: in fondo',
        ),
      ]) {
        if (!_has(_keyed(key))) continue;
        final ScrollPosition sheet = Scrollable.of(tester.element(_keyed(key)))
            .position;
        final double before = sheet.pixels;
        await Scrollable.ensureVisible(
          tester.element(_keyed(key)),
          alignment: at,
        );
        await _settle(tester, 10);
        // Only where the sheet moved: a sheet that holds all of itself has
        // nothing further down to show.
        if ((sheet.pixels - before).abs() > 40) {
          await roll.take(tester, slug, caption);
        }
      }
      await _back(tester, _keyed('deeper-head'));
    } else {
      await roll.take(
        tester,
        'approfondisci-non-aperto',
        'Approfondisci: il tocco sulla fonte non ha aperto nulla',
      );
    }

    // Why this card, beside it.
    final Finder why = _keyed('card-why-${first.id}');
    if (_has(why)) {
      await tester.tap(why.first, warnIfMissed: false);
    }
    await _settle(tester, 20);
    if (_has(_keyed('why-sheet'))) {
      await roll.take(tester, 'perche-questa-carta', 'Perché questa carta');
      await _back(tester, _keyed('why-sheet'));
    } else {
      await roll.take(
        tester,
        'perche-non-aperto',
        'Perché questa carta: il tocco non ha aperto nulla',
      );
    }

    // The other four: each front, then answered or turned, and thrown on.
    Future<void> throwOn() async {
      await tester.dragFrom(
        tester.getCenter(stack) + const Offset(60, 0),
        const Offset(-260, -20),
      );
      await _settle(tester, 16);
    }

    for (int i = 1; i < _todayFive.length; i++) {
      await throwOn();
      final Pill card = _card(_todayFive[i]);
      await roll.take(
        tester,
        'carta-${i + 1}-fronte',
        card.web != null
            ? 'Carta ${i + 1} di 5, disegnata: il fronte è la foto della sua '
                  'pagina dal sito (in inglese; sul telefono la materia è in '
                  'italiano)'
            : 'Carta ${i + 1} di 5 (${_kindOf(card)}): il fronte',
      );
      if (card.web != null) {
        // A drawn card: its page is tapped where nothing answers, and the
        // page has the card turned over.
        _pageSays(card.id, const PageTap());
        await _settle(tester, 20);
      } else {
        switch (card.challenge) {
          case PickOne(:final options, :final correct):
            await tester.tap(
              find.text(options[(correct + 1) % options.length]).first,
            );
            await _settle(tester, 8);
            final Finder s = find.text('60%');
            if (_has(s)) {
              await tester.tap(s.first);
              await _settle(tester, 20);
            }
          case TakeASide(:final positions):
            await tester.tap(find.text(positions.first).first);
            await _settle(tester, 20);
            await roll.take(
              tester,
              'carta-${i + 1}-parte-scelta',
              'Carta ${i + 1}: scelta una parte, chiede il perché in una riga',
            );
            final Finder skip = find.textContaining('mostramela');
            if (_has(skip)) {
              await tester.tap(skip.first);
              await _settle(tester, 20);
            }
          default:
            await tester.tap(stack, warnIfMissed: false);
            await _settle(tester, 20);
        }
      }
      if (!_has(_keyed('card-foot-${card.id}'))) {
        await tester.tap(stack, warnIfMissed: false);
        await _settle(tester, 20);
      }
      await roll.take(
        tester,
        'carta-${i + 1}-retro',
        'Carta ${i + 1} di 5: il retro',
      );
    }

    // After the fifth: the card after it, then the day finished.
    await throwOn();
    await roll.take(
      tester,
      'dopo-la-quinta',
      'Dopo la quinta: la carta che segue (piano gratuito)',
    );
    await throwOn();
    await _settle(tester, 20);
    await roll.take(tester, 'giornata-finita', 'La giornata finita');
    final Finder done = _down();
    if (_has(done)) {
      final ScrollableState page = tester.state(done);
      for (int i = 1; i < 6; i++) {
        final double before = page.position.pixels;
        page.position.jumpTo(
          math.min(before + 560, page.position.maxScrollExtent),
        );
        await _settle(tester, 8);
        if (page.position.pixels == before) break;
        await roll.take(
          tester,
          'giornata-finita-giu-$i',
          'La giornata finita, più giù ($i)',
        );
      }
      page.position.jumpTo(0);
      await _settle(tester, 8);
    }

    // The day sent.
    final Finder share = _keyed('shelf-share-day').hitTestable();
    if (_has(share)) {
      await tester.tap(share.first);
      await _settle(tester, 24);
      await roll.take(
        tester,
        'condividi',
        'Condividi la giornata: il foglio, «Copertina»',
      );
      for (final String layout in const ['Elenco', 'Storia']) {
        final Finder chip = find.text(layout).hitTestable();
        if (!_has(chip)) continue;
        await tester.tap(chip.first);
        await _settle(tester, 14);
        await roll.take(
          tester,
          'condividi-${layout.toLowerCase()}',
          'Condividi la giornata: «$layout»',
        );
      }
      final Finder sheetList = _down();
      if (_has(sheetList)) {
        final ScrollableState sheet = tester.state(sheetList);
        for (int i = 1; i < 4; i++) {
          final double before = sheet.position.pixels;
          sheet.position.jumpTo(
            math.min(before + 520, sheet.position.maxScrollExtent),
          );
          await _settle(tester, 8);
          if (sheet.position.pixels == before) break;
          await roll.take(
            tester,
            'condividi-giu-$i',
            'Condividi la giornata, più giù ($i)',
          );
        }
      }
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // -------------------------------------------------------------------------
  // 3. Explore, every subject, top to bottom; 4. a subject's own (Economics).
  testWidgets('explore-all', (tester) async {
    final _Roll roll = _Roll('explore-all');
    await _openExplore(tester);
    await _scrollTour(tester, roll, 'Esplora · Tutte');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('explore-subject', (tester) async {
    final _Roll roll = _Roll('explore-subject');
    await _openExplore(tester);
    final Finder chip = _keyed('subject-Economics-off');
    await tester.tap(chip.first, warnIfMissed: false);
    await _settle(tester, 20);
    await _scrollTour(tester, roll, 'Esplora · Economia');
    debugDefaultTargetPlatformOverride = null;
  });

  // -------------------------------------------------------------------------
  // 5. Inside Explore.

  // A. A challenge: In order, out of its tile, played to its end.
  testWidgets('inside: challenge', (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'A');
    await _openExplore(tester);
    if (!await _reach(tester, 'challenge-sixty', above: 160)) return;
    await roll.take(tester, 'sfide', 'Sfide: il blocco in Esplora, pagina 1');
    await tester.tap(_keyed('challenge-dot-2'));
    await _settle(tester);
    await roll.take(tester, 'sfide-pagina-3', 'Sfide: pagina 3');
    await tester.tap(_keyed('challenge-in-order'));
    await _settle(tester, 24);
    await roll.take(
      tester,
      'in-ordine-intro',
      'Sfida «In ordine»: la carta che la presenta',
    );
    await tester.tap(_keyed('in-order-play'));
    await _settle(tester);
    await roll.take(
      tester,
      'in-ordine-domanda',
      'In ordine: il primo turno, prima di toccare',
    );
    Future<void> order() async {
      final List<String> moments = [
        for (final Element e in _prefixed('in-order-card-').evaluate())
          (e.widget.key! as ValueKey<String>).value,
      ];
      for (final int i in const [2, 0, 3, 1]) {
        if (i < moments.length) {
          await tester.tap(_keyed(moments[i]), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 160));
        }
      }
      await _settle(tester, 8);
    }

    await order();
    await roll.take(
      tester,
      'in-ordine-messi',
      'In ordine: i momenti messi in fila',
    );
    if (_has(_keyed('in-order-check'))) {
      await tester.tap(_keyed('in-order-check'));
      for (int f = 0; f < 7; f++) {
        await tester.pump(const Duration(milliseconds: 90));
      }
      await roll.take(
        tester,
        'in-ordine-verificato',
        'In ordine: verificato, gli anni detti',
      );
    }
    for (int n = 1; n < 30; n++) {
      if (_has(_keyed('in-order-score'))) break;
      for (final String key in const [
        'in-order-next-card',
        'in-order-next',
        'in-order-check',
      ]) {
        if (_has(_keyed(key))) {
          await tester.tap(_keyed(key), warnIfMissed: false);
          break;
        }
      }
      await _settle(tester, 16);
      if (_has(_keyed('in-order-score'))) break;
      await order();
    }
    await _settle(tester, 20);
    await roll.take(tester, 'in-ordine-risultato', 'In ordine: il risultato');
    final Finder end = _keyed('in-order-end');
    if (_has(end)) {
      await tester.drag(end, Offset(0, -_phone.height * 0.55));
      await _settle(tester, 14);
      await roll.take(
        tester,
        'in-ordine-rivedi',
        'In ordine: il risultato, più giù',
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // B. Today's five, played through, and its result against today's players.
  testWidgets("inside: today's five", (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'B');
    _todaysPlayers();
    await _openExplore(tester);
    await tester.runAsync(BetsDay.instance.load);
    await tester.runAsync(ThreeDays.instance.load);
    await _settle(tester);
    await roll.take(
      tester,
      'cinque-di-oggi',
      'Le cinque di oggi, in cima a Esplora',
    );

    Future<void> tapKey(String key) async {
      final Finder f = _keyed(key);
      await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
      await _settle(tester);
      await tester.tap(f);
      await _settle(tester);
    }

    Future<void> bringUp(String key) async {
      final BuildContext at = tester.element(_keyed(key));
      final ScrollPosition p = Scrollable.of(at).position;
      await Scrollable.ensureVisible(at);
      p.jumpTo((p.pixels - 72).clamp(p.minScrollExtent, p.maxScrollExtent));
      await _settle(tester);
    }

    String onScreen() {
      final Finder lock = _prefixed('three-lock-');
      return (tester.widget(lock).key! as ValueKey<String>).value.substring(
        'three-lock-'.length,
      );
    }

    Future<String> answer({bool wrong = false}) async {
      final String id = onScreen();
      final Pill p = PillBank.byId(id)!;
      switch (p.challenge) {
        case PickOne(:final correct, :final options):
          final int pick = wrong ? (correct + 1) % options.length : correct;
          await tapKey('three-option-$id-$pick');
        default:
          BetsDay.instance.keepDraft(BetsDay.draftKey(kDailyBet, id), {
            'g': ((answerOf(p)?.value ?? 50) + 4).clamp(0, 100).roundToDouble(),
          });
          await _settle(tester);
      }
      return id;
    }

    final String first = await answer();
    await bringUp('three-card-$first');
    await roll.take(
      tester,
      'cinque-scelta',
      'Le cinque di oggi: una risposta scelta, prima di confermarla',
    );
    await tapKey('three-lock-$first');
    await bringUp('three-card-$first');
    await roll.take(
      tester,
      'cinque-confermata',
      'Le cinque di oggi: confermata, com’è andata e il perché',
    );
    await tapKey('three-next');
    for (int i = 1; i < 5; i++) {
      final String id = await answer(wrong: i == 2);
      if (PillBank.byId(id)!.challenge is! PickOne) {
        await bringUp('three-card-$id');
        await roll.take(
          tester,
          'cinque-stima-$i',
          'Le cinque di oggi: una stima sulla sua barra',
        );
      }
      await tapKey('three-lock-$id');
      await tapKey('three-next');
    }
    await bringUp('three-result');
    await roll.take(
      tester,
      'cinque-risultato',
      'Le cinque di oggi: il risultato, contro i giocatori di oggi',
    );
    if (await _scrollBy(tester, 520, list: _down(first: true))) {
      await roll.take(
        tester,
        'cinque-risultato-giu',
        'Le cinque di oggi: il risultato, più giù',
      );
    }
    if (await _scrollBy(tester, 520, list: _down(first: true))) {
      await roll.take(
        tester,
        'cinque-risultato-giu-2',
        'Le cinque di oggi: il risultato, ancora più giù',
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // C. A news story, opened from the latest news.
  testWidgets('inside: news', (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'C');
    await _openExplore(tester);
    if (!await _reach(tester, 'section-news-today', above: 100)) return;
    await roll.take(tester, 'notizie', 'Ultime notizie: il blocco in Esplora');
    final String lead = NewsPaper.front().first.id;
    final Finder tile = _keyed('explore-$lead');
    await tester.tap(tile.first, warnIfMissed: false);
    await _settle(tester, 18);
    await roll.take(tester, 'notizia', 'Una notizia aperta: la cima');
    final Finder story = _keyed('news-story-$lead');
    final Finder list = _has(story)
        ? find.descendant(of: story, matching: find.byType(Scrollable)).first
        : _down();
    for (int i = 1; i < 6; i++) {
      if (!await _scrollBy(tester, 620, list: list)) break;
      await roll.take(tester, 'notizia-giu-$i', 'La notizia, più giù ($i)');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // D. A book in pills: the book of the week, its page, its first idea.
  testWidgets('inside: book', (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'D');
    await _openExplore(tester);
    if (!await _reach(tester, 'section-books', above: 100)) return;
    await roll.take(tester, 'libri', 'Libri in pillole: il blocco in Esplora');
    final Finder week = _prefixed('book-week-');
    final Finder any = _has(week) ? week : _prefixed('book-');
    await tester.tap(any.first, warnIfMissed: false);
    await _settle(tester, 20);
    await roll.take(tester, 'libro', 'Un libro: la sua pagina');
    for (int i = 1; i < 4; i++) {
      if (!await _scrollBy(tester, 560)) break;
      await roll.take(tester, 'libro-giu-$i', 'Il libro, più giù ($i)');
    }
    final Finder idea = _keyed('book-idea-0');
    final Finder go = _keyed('book-go');
    if (_has(go) || _has(idea)) {
      final Finder start = _has(go) ? go : idea;
      await Scrollable.ensureVisible(
        tester.element(start.first),
        alignment: 0.5,
      );
      await _settle(tester);
      await tester.tap(start.first, warnIfMissed: false);
      await _settle(tester, 24);
      await roll.take(
        tester,
        'libro-prima-idea',
        'Il libro: la prima idea aperta',
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // E. What the founders read, and one founder's page.
  testWidgets('inside: founder', (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'E');
    await _openExplore(tester);
    if (!await _reach(tester, 'section-founders', above: 120)) return;
    await roll.take(
      tester,
      'fondatori',
      'Cosa leggono i fondatori: il blocco in Esplora',
    );
    await tester.tap(_prefixed('founder-').first, warnIfMissed: false);
    await _settle(tester, 22);
    await roll.take(tester, 'fondatore', 'La pagina di un fondatore: la cima');
    for (int i = 1; i < 8; i++) {
      if (!await _scrollBy(tester, 560)) break;
      await roll.take(tester, 'fondatore-giu-$i', 'Il fondatore, più giù ($i)');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // F. The charts that mislead, as Explore has them on a Wednesday.
  testWidgets('inside: unmask', (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'F');
    _adoptOnWeekday(3);
    addTearDown(Remote.reset);
    await _openExplore(tester);
    if (!await _reach(tester, 'mix-unmask', above: 130)) {
      await _reach(tester, 'section-surprise-wed', above: 110);
    }
    await roll.take(
      tester,
      'grafici',
      'Grafici che ingannano: il blocco in Esplora (il mercoledì)',
    );
    final Finder button = find.descendant(
      of: _keyed('mix-unmask'),
      matching: _prefixed('unmask-'),
    );
    if (_has(button)) {
      await tester.tap(button.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 900));
      await _settle(tester);
      await roll.take(
        tester,
        'grafici-svelato',
        'Grafici che ingannano: il trucco svelato',
      );
    }
    final Finder card = find.descendant(
      of: _keyed('mix-unmask'),
      matching: _prefixed('explore-'),
    );
    if (_has(card)) {
      await tester.tapAt(tester.getTopLeft(card.first) + const Offset(40, 40));
      await _settle(tester, 30);
      await roll.take(
        tester,
        'grafici-carta',
        'Grafici che ingannano: la carta aperta',
      );
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // G. The card to watch: its tile, and the film opened.
  testWidgets('inside: video', (tester) async {
    final _Roll roll = _Roll('inside-explore', prefix: 'G');
    final _Player player = _Player();
    VideoPlayerPlatform.instance = player;
    Uint8List? frameAt(String name) {
      final File f = File('$_filmGiven/$name.png');
      return f.existsSync() ? f.readAsBytesSync() : null;
    }

    await _openExplore(tester);
    if (!await _reach(tester, 'section-videos', above: 110)) return;
    await roll.take(tester, 'video', 'Carte da guardare: il blocco in Esplora');
    final Finder tile = find.byType(VideoCardTile);
    player.frame = frameAt('t04.00');
    await tester.tap(tile.first, warnIfMissed: false);
    await _settle(tester, 12);
    await roll.take(
      tester,
      'video-aperta',
      'La carta video aperta, al suo primo fotogramma',
    );
    for (final (String moment, String slug, String caption) in [
      ('t12.00', 'video-12s', 'La carta video, a 12 secondi'),
      ('t38.00', 'video-38s', 'La carta video, a 38 secondi'),
    ]) {
      player.frame = frameAt(moment);
      player.position = Duration(
        milliseconds: (double.parse(moment.substring(1)) * 1000).round(),
      );
      await _settle(tester, 6);
      await roll.take(tester, slug, caption);
    }
    player.frame = frameAt('t52.60');
    player.end(player.last);
    await _settle(tester, 8);
    await roll.take(tester, 'video-fine', 'La carta video, alla fine');
    debugDefaultTargetPlatformOverride = null;
  });

  // -------------------------------------------------------------------------
  // 6. Your journey, with the level reached as it opens; 8. a level-up.
  testWidgets('journey', (tester) async {
    final _Roll roll = _Roll('journey');
    final reader = _journeyReader();
    // What the phone would have written down as the days went: the score
    // each day ended on, worked out from the answers as the app does.
    SharedPreferences.setMockInitialValues(reader.prefs);
    final AppState probe = AppState();
    await probe.init();
    final JourneyRecord before = probe.record;
    final Map<String, List<int>> dayLog = {
      for (final e in reader.log.entries)
        e.key: [before.scoreOn(e.key), ...e.value.skip(1)],
    };
    // Its level not told yet: the one under it was.
    final int at = levelStandingOf(probe, null).at;
    await _open(tester, {
      ...reader.prefs,
      'knowit.dayLog': jsonEncode(dayLog),
      LevelMemory.key: math.max(0, at - 1),
    });
    await tester.tap(_keyed('tab-Profile').first);
    await _settle(tester, 16);
    await tester.tap(_keyed('profile-journey').first, warnIfMissed: false);
    // The level rises over the journey once it is at rest.
    for (int i = 0; i < 40 && !_has(_keyed('level-up')); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (_has(_keyed('level-up'))) {
      Future<void> at(int ms) async {
        for (var i = 0; i < ms ~/ 50; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await at(700);
      await roll.take(
        tester,
        'livello-1-conta',
        'Livello raggiunto: il punteggio che conta',
      );
      await at(900);
      await roll.take(
        tester,
        'livello-2-luce',
        'Livello raggiunto: la luce passa sul nome',
      );
      await at(2400);
      await roll.take(tester, 'livello-3-fermo', 'Livello raggiunto: a riposo');
      if (_has(_keyed('level-up-share'))) {
        await tester.tap(_keyed('level-up-share'));
        await _settle(tester, 20);
        await roll.take(
          tester,
          'livello-4-condividi',
          'Livello raggiunto: il foglio per condividerlo',
        );
        await _back(tester, _keyed('level-share'));
      }
      if (_has(_keyed('level-up-close'))) {
        await tester.tap(_keyed('level-up-close'));
        await _settle(tester, 20);
      }
    }
    await _settle(tester, 10);
    await roll.take(tester, 'viaggio', 'Il tuo viaggio: la cima');
    final Finder list = _down();
    for (int i = 1; i < 14; i++) {
      if (!await _scrollBy(tester, _phone.height * 0.72, list: list)) break;
      await roll.take(tester, 'viaggio-giu-$i', 'Il tuo viaggio, più giù ($i)');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // -------------------------------------------------------------------------
  // 7. The profile and its settings, the topics, and Regola il tuo mix.
  testWidgets('profile', (tester) async {
    final _Roll roll = _Roll('profile');
    await _open(tester, _threeWeeksIn());
    await tester.tap(_keyed('tab-Profile').first);
    await _settle(tester, 16);
    await roll.take(tester, 'profilo', 'Profilo: la cima');
    final Finder list = _down(first: true);
    for (int i = 1; i < 12; i++) {
      if (!await _scrollBy(tester, _phone.height * 0.72, list: list)) break;
      await roll.take(
        tester,
        'profilo-giu-$i',
        'Profilo e impostazioni, più giù ($i)',
      );
    }
    // Back up to the topics, and into them.
    final Finder topics = _keyed('profile-topics');
    await _bringIntoView(tester, topics, list);
    await tester.tap(topics);
    await _settle(tester, 20);
    await roll.take(tester, 'materie', 'Le tue materie (dal profilo)');
    if (_has(_keyed('topics-fine-tune'))) {
      await Scrollable.ensureVisible(
        tester.element(_keyed('topics-fine-tune')),
        alignment: 0.7,
      );
      await _settle(tester, 6);
      await roll.take(
        tester,
        'materie-giu',
        'Le tue materie: in fondo, la via per regolare il mix',
      );
      await tester.tap(_keyed('topics-fine-tune'));
      await _settle(tester, 20);
      await roll.take(tester, 'regola-mix', 'Regola il tuo mix: la cima');
      final Finder tune = _down(first: true);
      final ScrollableState tuneList = tester.state(tune);
      tuneList.position.jumpTo(420);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await roll.take(tester, 'regola-mix-giu', 'Regola il tuo mix, più giù');
      // Come to rest with the first subject's parts whole on screen: the
      // hint that holding a part opens it plays, once.
      tuneList.position.jumpTo(560);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      for (final (int ms, String slug, String caption) in [
        (
          450,
          'regola-mix-suggerimento-1',
          'Regola il tuo mix: il suggerimento, il dito preme',
        ),
        (
          1250,
          'regola-mix-suggerimento-2',
          'Regola il tuo mix: il suggerimento, si apre',
        ),
        (
          1450,
          'regola-mix-suggerimento-3',
          'Regola il tuo mix: il suggerimento, si richiude',
        ),
      ]) {
        await tester.pump(Duration(milliseconds: ms));
        await roll.take(tester, slug, caption);
      }
      await tester.pump(const Duration(milliseconds: 1500));
      for (int i = 1; i < 12; i++) {
        if (!await _scrollBy(tester, _phone.height * 0.72, list: tune)) break;
        await roll.take(
          tester,
          'regola-mix-giu-$i',
          'Regola il tuo mix, più giù ($i)',
        );
      }
    }
    debugDefaultTargetPlatformOverride = null;
  });

  // -------------------------------------------------------------------------
  // 9. The paywall, for a free reader: from the profile, and from the lock
  // on the finished day.
  testWidgets('paywall', (tester) async {
    final _Roll roll = _Roll('paywall');
    // The fifth card on top: thrown, the card after it offers Astute+.
    await _open(tester, _fourDaysIn(index: _todayFive.length - 1));
    await tester.dragFrom(
      tester.getCenter(find.byType(PillCardStack)) + const Offset(60, 0),
      const Offset(-260, -20),
    );
    await _settle(tester, 16);
    if (_has(_keyed('magic-card'))) {
      await roll.take(
        tester,
        'dopo-la-quinta',
        'Dopo la quinta carta: la carta che offre Astute+',
      );
      final Finder action = find.descendant(
        of: _keyed('magic-card'),
        matching: find.byType(PrimaryButton),
      );
      if (_has(action)) {
        await tester.tap(action.first);
        await _settle(tester, 24);
        await roll.take(
          tester,
          'da-dopo-la-quinta',
          'Paywall aperto dalla carta dopo la quinta',
        );
        await _back(tester, _keyed('paywall-buy'));
      }
      // Thrown, the day is finished.
      await tester.dragFrom(
        tester.getCenter(find.byType(PillCardStack)) + const Offset(60, 0),
        const Offset(-260, -20),
      );
      await _settle(tester, 20);
    }
    await roll.take(
      tester,
      'giornata-finita',
      'Giornata finita, piano gratuito: «Il tuo viaggio» col lucchetto',
    );
    final Finder journey = find.textContaining('Il tuo viaggio').hitTestable();
    if (_has(journey)) {
      await tester.tap(journey.first);
      await _settle(tester, 24);
      await roll.take(
        tester,
        'da-il-tuo-viaggio',
        'Paywall aperto da «Il tuo viaggio»',
      );
      await _back(tester, _keyed('paywall-buy'));
    }
    await tester.tap(_keyed('tab-Profile').first);
    await _settle(tester, 16);
    final Finder plans = find.text('VEDI I PIANI');
    if (_has(plans)) {
      await Scrollable.ensureVisible(
        tester.element(plans.first),
        alignment: 0.5,
      );
      await _settle(tester, 6);
      await roll.take(
        tester,
        'profilo-vedi-i-piani',
        'Profilo, piano gratuito: «Vedi i piani»',
      );
      await tester.tap(plans.first);
      await _settle(tester, 24);
      await roll.take(
        tester,
        'da-vedi-i-piani',
        'Paywall aperto da «Vedi i piani»',
      );
      final Finder scroll = _keyed('paywall-features-scroll');
      if (_has(scroll)) {
        final Finder inner = find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first;
        if (await _scrollBy(tester, 400, list: inner)) {
          await roll.take(
            tester,
            'da-vedi-i-piani-giu',
            'Paywall: le funzioni, più giù',
          );
        }
      }
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
