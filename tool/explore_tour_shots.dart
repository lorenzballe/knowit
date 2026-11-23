// Photographs Explore as the owner's iPhone shows it, top to bottom, one
// screenful at a time: the server's own document (remote/explore.json, as
// the build bundles it), the server's shelves for a reader two weeks in,
// the real pictures of the drawn cards, the glass tab bar of an iPhone, a
// 16 Pro's notch and home bar.
//
//   flutter test tool/explore_tour_shots.dart --update-goldens
//
// TOUR_PHONE (se, pro, max; pro by default), TOUR_LANG (it by default),
// TOUR_PAPER=true for the light theme, TOUR_PLUS=true for a reader with
// Astute+, TOUR_SUBJECT=Sport for one subject's Explore (Thinking,Sport for
// Thinking's chip lit beside Sport's), TOUR_FULL=true for
// the whole page in one picture, TOUR_LABEL to keep two runs apart (each a
// --dart-define). A camera, not a check: it lives outside
// test/ so CI never runs it. The pictures land in tool/shots/explore-tour/,
// to be looked at and not kept.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/core_harness.dart';

const String _phone = String.fromEnvironment('TOUR_PHONE', defaultValue: 'pro');
const String _lang = String.fromEnvironment('TOUR_LANG', defaultValue: 'it');
const bool _paper = bool.fromEnvironment('TOUR_PAPER');
const bool _plus = bool.fromEnvironment('TOUR_PLUS');
const String _label = String.fromEnvironment('TOUR_LABEL', defaultValue: 'now');

/// A subject to narrow Explore to before the photographs, by its chip
/// (`Sport`, `Nature`); none for every subject.
const String _subject = String.fromEnvironment('TOUR_SUBJECT');

/// The whole page in one picture, on a phone as tall as the page, with
/// where each section starts beside it; otherwise a screenful at a time.
const bool _full = bool.fromEnvironment('TOUR_FULL');

/// A day of the week to photograph Explore on, 1 Monday to 7 Sunday: the
/// shelves aimed at a weekday (the surprise of the day) as on that day.
/// 0 for today; 8 for every weekday's at once, to see them all.
const int _weekday = int.fromEnvironment('TOUR_WEEKDAY');

/// The phones, each with its insets.
const Map<String, (Size, EdgeInsets)> _phones = {
  'se': (Size(375, 667), EdgeInsets.only(top: 20)),
  'pro': (Size(402, 874), EdgeInsets.only(top: 62, bottom: 34)),
  'max': (Size(440, 956), EdgeInsets.only(top: 62, bottom: 34)),
};

/// A picture of the bank's own, from the folder the site serves them from:
/// small, shelf or large, as the address asks.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  // web/cards/thumbs/… for a card's pictures, web/cards/covers/… for a
  // book's.
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture on screen, decoded before the photograph, in real time.
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
  await _settle(tester, 5);
}

/// This morning's paper, as the server would have written it: three
/// stories, one per subject.
void _paperOfToday() {
  final String day = dateKey(DateTime.now());
  Map<String, Object?> story(
    String id,
    String topic,
    String headline,
    String outlet,
    String figure,
    String question,
    String answer,
  ) => {
    'id': 'news-$day-$id',
    'topic': topic,
    'kind': 'read',
    'difficulty': 'easy',
    'principle': 'none',
    'question': question,
    'answer': answer,
    'move': 'A small shortage makes a big price.',
    'keywords': [id],
    'era': 'recent',
    'region': 'world',
    'hook': 'mechanism',
    'mood': 'practical',
    'numeracy': 1,
    'abstraction': 'concrete',
    'shelf_life': 'months',
    'mature': false,
    'language': 'en',
    'figure': 'none',
    'scene': {
      'type': 'news',
      'headline': headline,
      'outlet': outlet,
      'reported': [outlet, 'The Guardian'],
      'date': day,
      'panels': [
        {'label': 'What happened', 'figure': figure, 'text': headline},
        {'label': 'Why', 'text': answer},
        {'label': 'What it means for you', 'text': question},
      ],
      'expires': '2099-12-31',
    },
    'source': outlet,
    'source_kind': 'news_archive',
    'reference': 'https://www.bbc.co.uk/news/articles/example',
    'written': day,
  };
  NewsPaper.adopt(day, [
    story(
      'eggs',
      'economics',
      'Egg prices hit a record as bird flu empties henhouses',
      'BBC News',
      r'$6.23',
      'Bird flu cost American farms a slice of their hens. Why did the price '
          'of eggs double?',
      'Because almost nobody stops buying eggs, so a shortfall of under a '
          'tenth was settled by price.',
    ),
    story(
      'heat',
      'nature',
      'Europe records its hottest October in a century',
      'Reuters',
      '+2.1 °C',
      'Why does a warm autumn mean a worse allergy spring?',
      'Plants that never stop growing make pollen for longer.',
    ),
    story(
      'probe',
      'space',
      'A probe launched in 1977 is still sending data home',
      'AP',
      '24 bn km',
      'How does Voyager 1 still talk to Earth with a 23-watt radio?',
      'Dishes 70 metres wide listen for it, and they are very patient.',
    ),
  ]);
}

/// A reader two weeks in: a streak, a day read, cards kept, liked and read,
/// a city, answers come back to be answered again.
Map<String, Object> _twoWeeksIn() {
  List<Pill> drawn(String topic, int n, {int skip = 0}) => PillBank.cards
      .where((p) => p.topic == topic && CardThumb.has(p, CardSide.front))
      .skip(skip)
      .take(n)
      .toList();
  final List<Pill> saved = [
    ...drawn('Space', 3),
    ...drawn('History', 2),
    ...drawn('Psychology', 2),
  ];
  final List<Pill> liked = [...drawn('Space', 4, skip: 3), ...drawn('Art', 2)];
  final List<Pill> due = PillBank.cards
      .where((p) => p.challenge is PickOne && p.topic == 'History')
      .take(4)
      .toList();
  final DateTime now = DateTime.now();
  final String yesterday = dateKey(now.subtract(const Duration(days: 1)));
  return {
    'knowit.onboarded': true,
    'knowit.pushAsked': true,
    if (_plus) 'knowit.plus': true,
    if (_paper) 'knowit.theme': 'light',
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
        due[i].id: {'r': '0', 's': i.isEven ? 1 : 0, 'd': yesterday},
    }),
  };
}

/// The server's shelves for that reader, as the phone kept them.
ServedExplore _servedShelves() {
  List<Pill> drawn(String topic, int n, {int skip = 0}) => PillBank.cards
      .where((p) => p.topic == topic && CardThumb.has(p, CardSide.front))
      .skip(skip)
      .take(n)
      .toList();
  List<ServedRank> ranked(List<Pill> cards) => [
    for (int i = 0; i < cards.length; i++) ServedRank(cards[i], 90 - i * 7),
  ];
  final List<Pill> today = [
    for (final String topic in kTopicOrder.map((k) => kTopics[k]!.name))
      ...drawn(topic, 2, skip: 5),
  ];
  return ServedExplore(
    day: dateKey(DateTime.now()),
    today: today,
    asking: askingPills(seed: 'served-asking', count: 40),
    topWeek: ranked([
      ...drawn('Psychology', 3, skip: 3),
      ...drawn('Space', 3, skip: 8),
    ]),
    topMonth: ranked([...drawn('History', 3, skip: 6), ...drawn('Food', 3)]),
    loved: ranked([
      ...drawn('Art', 3, skip: 2),
      ...drawn('Music', 3),
      ...drawn('Cinema', 2),
    ]),
    bySubject: const {},
    because: 'space',
    mine: drawn('Space', 10, skip: 10),
    forYou: [...drawn('Nature', 4, skip: 2), ...drawn('Technology', 4)],
    local: PillBank.placeCards
        .where((p) => p.place?.city == 'Bologna')
        .toList(),
  );
}

/// The document the build bundles, its Explore as it is on [weekday] (1
/// Monday to 7 Sunday), or with every weekday's shelves at once (8): a rule
/// of weekdays is made true for that day and false for the others.
void _adoptOnWeekday(int weekday) {
  final Map<String, Object?> parts = Map.of(Remote.embedded.parts);
  Object? fixed(Object? rule) {
    if (rule is Map) {
      return {
        for (final MapEntry<Object?, Object?> e in rule.entries)
          if (e.key == 'weekdays')
            'minBuild': weekday == 8 || (e.value as List).contains(weekday)
                ? 0
                : 99999
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

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    // The document the build bundles, which is the server's: Remote is left
    // on it, and nothing asks the network.
    Remote.fetch = (url) async => null;
    // A build of today's: the sections the document keeps for new builds
    // are on, the ones it keeps for old ones off.
    Remote.build = 99;
    CardThumb.image = _picture;
  });

  testWidgets('explore, top to bottom', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final (Size phone, EdgeInsets insets) = _phones[_phone]!;
    // The whole page: as tall as Explore runs before its endless feed, and
    // two pixels a point, so the picture stays a size a phone can open.
    final Size size = _full ? Size(phone.width, 16000) : phone;
    final double ratio = _full ? 2 : 3;
    final view = tester.view;
    view.physicalSize = size * ratio;
    view.devicePixelRatio = ratio;
    view.padding = FakeViewPadding(
      top: insets.top * ratio,
      bottom: insets.bottom * ratio,
    );
    view.viewPadding = view.padding;
    tester.platformDispatcher.localesTestValue = [const Locale(_lang)];
    tester.platformDispatcher.localeTestValue = const Locale(_lang);
    addTearDown(() {
      view.reset();
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearLocaleTestValue();
    });
    _paperOfToday();
    if (_weekday != 0) _adoptOnWeekday(_weekday);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(_twoWeeksIn());
    // ignore: invalid_use_of_visible_for_testing_member
    Served.useForTest(
      Served(
        storeOverride: MemoryServedStore()..shelves = _servedShelves(),
        uidOverride: 'reader',
      ),
    );
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 20);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')).first);
    await _settle(tester, 20);
    // One subject, or several to light together ("Thinking,Economics":
    // Thinking's chip beside a subject's).
    for (final String subject in _subject.split(',')) {
      if (subject.isEmpty) continue;
      await tester.tap(find.byKey(ValueKey('subject-$subject-off')));
      await _settle(tester, 20);
    }

    final String name =
        '$_phone-$_lang-${_paper ? 'light' : 'dark'}${_plus ? '-plus' : ''}'
        '${_subject.isEmpty ? '' : '-${_subject.toLowerCase().replaceAll(',', '+')}'}'
        '${_weekday == 0 ? '' : '-day$_weekday'}'
        '${_full ? '-full' : ''}';
    Future<void> take(String shot) async {
      await _decodeShown(tester);
      await expectLater(
        find.byType(MaterialApp).first,
        matchesGoldenFile('shots/explore-tour/$_label/$name-$shot.png'),
      );
    }

    if (_full) {
      // Where each section starts, top to bottom, in points.
      final Map<String, double> tops = {
        for (final Element e
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith('watch-'),
                )
                .evaluate())
          (e.widget.key! as ValueKey<String>).value.substring(6): tester
              .getTopLeft(find.byWidget(e.widget))
              .dy,
      };
      final File file = File(
        'tool/shots/explore-tour/$_label/$name-sections.json',
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(tops));
      await take('page');
      debugDefaultTargetPlatformOverride = null;
      return;
    }

    final Finder down = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    final ScrollableState list = tester.state(down);
    // A screenful and a little less each time, so nothing falls between
    // two pictures; dragged, so the head goes away as a finger sends it.
    final double step = size.height * 0.72;
    for (int i = 0; i < 70; i++) {
      await take(i.toString().padLeft(2, '0'));
      final double before = list.position.pixels;
      if (before >= list.position.maxScrollExtent - 1) break;
      await tester.dragFrom(
        Offset(size.width - 24, size.height * 0.8),
        Offset(0, -step),
      );
      await _settle(tester);
      if (list.position.pixels == before) break;
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
