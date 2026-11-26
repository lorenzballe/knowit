// Photographs Explore under the shelves that were always there: the month,
// the round against the clock, the six ways to work a number out, the pile
// of facts, the charts unmasked, one card from anywhere and something to
// use today at the end — each at rest and each played.
//
//   flutter test tool/explore_shots.dart --update-goldens
//
// A camera, not a check, so it lives outside test/ like the other shots.
// The pictures land in tool/shots/explore/; the challenges' (the last
// group) in the gallery, or wherever CHALLENGES_DIR says.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart' show trueOrFalseAnswer;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/sync/served.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

const Size _phone = Size(402, 874);

void _store({bool paper = false}) {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    if (paper) 'knowit.theme': 'light',
  });
}

void main() {
  setUpAll(_loadFonts);

  void size(Size logical, double ratio) {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = logical * ratio;
    view.devicePixelRatio = ratio;
  }

  setUp(() {
    size(_phone, 3);
    // ignore: invalid_use_of_visible_for_testing_member
    ExplorePlay.resetForTest();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> settle(WidgetTester tester) async {
    for (int f = 0; f < 14; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('shots/explore/$name.png'),
  );

  Finder down() => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;

  Future<void> open(WidgetTester tester, {bool paper = false}) async {
    _store(paper: paper);
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);
  }

  /// Scrolls until [key] is on screen, then brings its top near the top.
  Future<void> reach(
    WidgetTester tester,
    String key, {
    double above = 90,
  }) async {
    final Finder target = find.byKey(ValueKey(key), skipOffstage: false);
    for (int i = 0; i < 80 && target.evaluate().isEmpty; i++) {
      await tester.drag(down(), const Offset(0, -500));
      await tester.pump();
    }
    await tester.ensureVisible(target);
    await settle(tester);
    final double top = tester.getTopLeft(target).dy;
    await tester.drag(down(), Offset(0, -(top - above)));
    await settle(tester);
  }

  // Today's Explore on the three phones, at night and on paper: every
  // screenful from the top, and the whole page in one picture at one pixel
  // a point, which is what two runs are compared by. Into the gallery,
  // which is not kept, under the label given:
  //
  //   flutter test tool/explore_shots.dart --plain-name "three phones" \
  //     --update-goldens --dart-define=EXPLORE_LABEL=before
  const String label = String.fromEnvironment(
    'EXPLORE_LABEL',
    defaultValue: 'now',
  );
  const Map<String, Size> phones = {
    '375': Size(375, 667),
    '402': Size(402, 874),
    '430': Size(430, 932),
  };
  for (final MapEntry<String, Size> phone in phones.entries) {
    for (final bool paper in [false, true]) {
      final String name = '${phone.key}-${paper ? 'light' : 'dark'}';
      testWidgets('today on three phones: $name', (tester) async {
        Future<void> take(String shot) => expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('shots/gallery/explore/today/$label/$shot.png'),
        );
        size(phone.value, 3);
        await open(tester, paper: paper);
        final ScrollableState list = tester.state(down());
        final double step = phone.value.height * 0.75;
        for (int i = 0; i < 60; i++) {
          await take('$name-${i.toString().padLeft(2, '0')}');
          final double before = list.position.pixels;
          list.position.jumpTo(
            (before + step).clamp(0, list.position.maxScrollExtent),
          );
          await settle(tester);
          if (list.position.pixels == before) break;
        }
        // The app again from nothing, on a phone as tall as the page.
        await tester.pumpWidget(const SizedBox());
        size(Size(phone.value.width, 16000), 1);
        await open(tester, paper: paper);
        await take('$name-full');
      });
    }
  }

  // Today's Explore for a reader with a past: the server's Explore, as the
  // phone kept it the last time it had signal, with the top list, loved
  // since the start and the reader's own subject on it; a place with cards
  // written about it; answers come back to be answered again; and every
  // card of Economics read, so that subject has nothing left to find. The
  // whole page, then the page narrowed to Economics.
  Future<void> openAsReader(WidgetTester tester, {bool paper = false}) async {
    final List<Pill> bank = PillBank.cards;
    List<Pill> of(String topic, int n) =>
        bank.where((p) => p.topic == topic).take(n).toList();
    final List<Pill> due = bank
        .where((p) => p.challenge is PickOne && p.topic == 'History')
        .take(4)
        .toList();
    final String yesterday = dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      if (paper) 'knowit.theme': 'light',
      'knowit.seenIds': [
        for (final p in bank)
          if (p.topic == 'Economics') p.id,
        for (final p in of('Nature', 6)) p.id,
      ],
      'knowit.topicWeights': jsonEncode({'space': 1.0, 'history': 0.4}),
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
    });
    List<ServedRank> ranked(List<Pill> cards) => [
      for (int i = 0; i < cards.length; i++) ServedRank(cards[i], 90 - i * 7),
    ];
    final ServedExplore served = ServedExplore(
      day: dateKey(DateTime.now()),
      today: pickedPills(seed: 'served-today', count: 24),
      asking: askingPills(seed: 'served-asking', count: 40),
      topWeek: ranked([...of('Psychology', 3), ...of('Space', 3)]),
      topMonth: ranked([...of('History', 3), ...of('Food', 3)]),
      loved: ranked([...of('Art', 3), ...of('Music', 3), ...of('Cinema', 2)]),
      bySubject: const {},
      because: 'space',
      mine: of('Space', 10),
      local: PillBank.placeCards
          .where((p) => p.place?.city == 'Bologna')
          .toList(),
      fromCache: true,
    );
    // ignore: invalid_use_of_visible_for_testing_member
    Served.useForTest(
      Served(
        storeOverride: MemoryServedStore()..shelves = served,
        uidOverride: 'reader',
      ),
    );
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await settle(tester);
  }

  for (final MapEntry<String, Size> phone in phones.entries) {
    for (final bool paper in [false, true]) {
      final String name = '${phone.key}-${paper ? 'light' : 'dark'}';
      testWidgets('today for a reader: $name', (tester) async {
        Future<void> take(String shot) => expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('shots/gallery/explore/reader/$label/$shot.png'),
        );
        // ignore: invalid_use_of_visible_for_testing_member
        addTearDown(() => Served.useForTest(Served()));
        size(Size(phone.value.width, 16000), 1);
        await openAsReader(tester, paper: paper);
        await take('$name-full');
        await tester.tap(find.byKey(const ValueKey('subject-Economics-off')));
        await settle(tester);
        await take('$name-economics');
      });
    }
  }

  // remote/examples/explore-gallery.json, taken up as the remote document
  // would be: every core block at every size, on the three phones, at night
  // and on paper, and on the small phone at a large text size. The whole
  // page at one pixel a point, into the gallery under the label given:
  //
  //   flutter test tool/explore_shots.dart --plain-name "gallery" \
  //     --update-goldens --dart-define=EXPLORE_LABEL=now
  final Map<String, Object?> gallery = jsonDecode(
    File('remote/examples/explore-gallery.json').readAsStringSync(),
  ) as Map<String, Object?>;
  for (final MapEntry<String, Size> phone in phones.entries) {
    for (final (bool paper, double text) in [
      (false, 1.0),
      (true, 1.0),
      if (phone.key == '375') (false, 1.35),
    ]) {
      final String name =
          '${phone.key}-${paper ? 'light' : 'dark'}'
          '${text == 1 ? '' : '-text${(text * 100).round()}'}';
      testWidgets('gallery: $name', (tester) async {
        Remote.adopt(
          RemoteConfig(
            hash: 'gallery',
            schema: kRemoteSchema,
            parts: {'explore': gallery},
          ),
        );
        // ignore: invalid_use_of_visible_for_testing_member
        addTearDown(Remote.reset);
        tester.platformDispatcher.textScaleFactorTestValue = text;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        size(Size(phone.value.width, 26000), 1);
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({
          'knowit.onboarded': true,
          if (paper) 'knowit.theme': 'light',
          'knowit.savedIds': [
            for (final p in PillBank.cards.take(400))
              if (p.topic == 'Art') p.id,
          ],
        });
        await tester.pumpWidget(const AstutoApp());
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('tab-Explore')));
        await settle(tester);
        await expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('shots/gallery/explore/core/$label/$name.png'),
        );
      });
    }
  }

  testWidgets('Explore, top to bottom', (tester) async {
    await open(tester);
    await shoot(tester, '00-top');
    final ScrollableState list = tester.state(down());
    for (int i = 1; i < 40; i++) {
      final double before = list.position.pixels;
      await tester.drag(down(), const Offset(0, -640));
      await settle(tester);
      if (list.position.pixels == before) break;
      await shoot(tester, i.toString().padLeft(2, '0'));
    }
  });

  testWidgets('Explore, the whole page in one picture', (tester) async {
    size(const Size(402, 15000), 1);
    await open(tester);
    await shoot(tester, 'full-page');
  });

  testWidgets('Explore on paper', (tester) async {
    await open(tester, paper: true);
    await reach(tester, 'mix-month');
    await shoot(tester, 'paper-month');
    await reach(tester, 'mix-work');
    await shoot(tester, 'paper-work');
    await reach(tester, 'front-page', above: 60);
    await shoot(tester, 'paper-front');
    await reach(tester, 'mix-surprise', above: 60);
    await shoot(tester, 'paper-surprise');
  });

  testWidgets('played: true or false, the round, the deck', (tester) async {
    await open(tester);
    await reach(tester, 'theme-trueOrFalse-0');
    final Finder sides = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('tf-') &&
          (w.key! as ValueKey<String>).value.endsWith('-true'),
    );
    if (sides.evaluate().isNotEmpty) {
      await tester.tap(sides.first);
      await settle(tester);
    }
    await shoot(tester, 'play-true-false');

    await reach(tester, 'mix-sixty');
    await tester.tap(find.byKey(const ValueKey('sixty-start')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sixty-true')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('sixty-false')));
    await settle(tester);
    await shoot(tester, 'play-sixty-running');
    for (int i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const ValueKey('sixty-true')));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await settle(tester);
    await shoot(tester, 'play-sixty-end');
  });

  testWidgets('played: the six ways to work it out', (tester) async {
    await open(tester);
    await reach(tester, 'mix-work');
    await shoot(tester, 'work-row');
    // One row of every way, in the day's order: bring the first card of each
    // way to the front, by the row's own position, and play it there.
    final ScrollPosition row = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const ValueKey('mix-work')),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.right,
                ),
              )
              .first,
        )
        .position;
    Finder keyed(bool Function(String) test) => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> && test((w.key! as ValueKey<String>).value),
    );
    for (final mode in [
      'pick',
      'slide',
      'closer',
      'bigger',
      'range',
      'stake',
    ]) {
      final Finder card = find.byKey(ValueKey('work-$mode-0'));
      row.jumpTo(0);
      await settle(tester);
      for (int i = 0; i < 40 && card.evaluate().isEmpty; i++) {
        row.jumpTo(row.pixels + 150);
        await settle(tester);
      }
      if (card.evaluate().isEmpty) continue;
      row.jumpTo(
        (row.pixels + tester.getTopLeft(card).dx - 20).clamp(
          0,
          row.maxScrollExtent,
        ),
      );
      await settle(tester);
      await shoot(tester, 'work-$mode');
      Finder inCard(String pattern) => find.descendant(
        of: card,
        matching: keyed((k) => RegExp(pattern).hasMatch(k)),
      );
      final List<String> taps = switch (mode) {
        'pick' => [r'^pick-.*-0$'],
        'slide' => [r'^slide-check-'],
        'closer' => [
          r'^closer-.*-more$',
          r'^closer-.*-less$',
          r'^closer-.*-more$',
        ],
        'bigger' => [r'^bigger-'],
        'range' => [r'^range-bet-'],
        _ => [r'^stake-.*-o1$', r'^stake-bet-'],
      };
      for (final pattern in taps) {
        final Finder target = inCard(pattern);
        if (target.evaluate().isEmpty) break;
        await tester.tap(target.first);
        await settle(tester);
      }
      await shoot(tester, 'work-$mode-done');
    }
  });

  testWidgets('played: did you know, a year, the chart', (tester) async {
    await open(tester);
    // In the page's order: the chart is among the cards to play, a year
    // and the pile among the ways in by time.
    await reach(tester, 'mix-unmask');
    final Finder unmask = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('unmask-'),
    );
    await shoot(tester, 'play-unmask-before');
    if (unmask.evaluate().isNotEmpty) {
      await tester.tap(unmask.first);
      await tester.pump(const Duration(milliseconds: 900));
      await settle(tester);
    }
    await shoot(tester, 'play-unmask-after');

    await reach(tester, 'mix-did-you-know');
    final Finder pile = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('dyk-') &&
          (w.key! as ValueKey<String>).value != 'dyk-new' &&
          (w.key! as ValueKey<String>).value != 'dyk-knew',
    );
    if (pile.evaluate().isNotEmpty) {
      await tester.tap(pile.first);
      await settle(tester);
    }
    await shoot(tester, 'play-did-you-know');

    await reach(tester, 'mix-surprise');
    await tester.tap(find.byKey(const ValueKey('surprise-me')));
    await settle(tester);
    await shoot(tester, 'play-surprise');
  });

  // The challenges, on three phones at night and on paper: the section as
  // Explore shows it, page by page; then Sixty seconds opened out of its
  // tile — the flight caught early, what it is, an answer just told, the
  // round in play, how it went and the eight claims again. Into the
  // gallery, which is not kept, or into CHALLENGES_DIR:
  //
  //   flutter test tool/explore_shots.dart --plain-name "challenges" \
  //     --update-goldens --dart-define=CHALLENGES_DIR=/somewhere/else
  const String challengesDir = String.fromEnvironment(
    'CHALLENGES_DIR',
    defaultValue: 'shots/gallery/challenges/$label',
  );
  // Each phone with the room its status bar and its home bar take.
  const Map<String, (Size, EdgeInsets)> challengePhones = {
    '360x740': (Size(360, 740), EdgeInsets.only(top: 24, bottom: 16)),
    '390x844': (Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
    '430x932': (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34)),
  };
  for (final MapEntry<String, (Size, EdgeInsets)> phone
      in challengePhones.entries) {
    for (final bool paper in [false, true]) {
      final String name = '${phone.key}-${paper ? 'light' : 'dark'}';
      testWidgets('challenges: $name', (tester) async {
        Future<void> take(String shot) => expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('$challengesDir/$name-$shot.png'),
        );
        final (Size logical, EdgeInsets safe) = phone.value;
        size(logical, 3);
        tester.view.padding = FakeViewPadding(
          top: safe.top * 3,
          bottom: safe.bottom * 3,
        );
        tester.view.viewPadding = FakeViewPadding(
          top: safe.top * 3,
          bottom: safe.bottom * 3,
        );
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({
          'knowit.onboarded': true,
          if (paper) 'knowit.theme': 'light',
          'knowit.sixtyBest': 5,
        });
        await tester.pumpWidget(const AstutoApp());
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('tab-Explore')));
        await settle(tester);
        await reach(tester, 'challenge-sixty', above: 150);
        await take('challenges');
        // The second page and the third, by a swipe each, and back by the
        // first dot.
        final Finder sixty = find.byKey(const ValueKey('challenge-sixty'));
        await tester.drag(sixty, Offset(-logical.width * 0.7, 0));
        await settle(tester);
        await take('challenges-2');
        await tester.drag(
          find.byKey(const ValueKey('challenge-bets-closer')),
          Offset(-logical.width * 0.7, 0),
        );
        await settle(tester);
        await take('challenges-3');
        await tester.tap(find.byKey(const ValueKey('challenge-dot-0')));
        await settle(tester);
        // Sixty seconds, out of its tile.
        await tester.tap(sixty);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 90));
        await take('sixty-flight');
        await settle(tester);
        await take('sixty-intro');
        await tester.tap(find.byKey(const ValueKey('sixty-play')));
        await settle(tester);
        // Said right or wrong, as the camera asks: the claim in front is
        // the last one keyed on the deck.
        Future<void> say({required bool right}) async {
          final Finder claims = find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('sixty-claim-'),
          );
          final String id =
              (tester.widget(claims.last).key! as ValueKey<String>).value
                  .substring('sixty-claim-'.length);
          final bool truth = trueOrFalseAnswer(PillBank.byId(id)!);
          await tester.tap(
            find.byKey(ValueKey(truth == right ? 'sixty-true' : 'sixty-false')),
          );
          await tester.pump(const Duration(milliseconds: 400));
        }

        await say(right: true);
        await say(right: false);
        // The answer just told, in its calm colour and its word: a frame
        // more, for the word to have come in.
        await tester.pump(const Duration(milliseconds: 250));
        await take('sixty-told');
        await tester.pump(const Duration(seconds: 3));
        await take('sixty-play');
        for (int i = 0; i < 6; i++) {
          await say(right: i != 2);
        }
        await settle(tester);
        await take('sixty-result');
        await tester.drag(
          find.byKey(const ValueKey('sixty-end')),
          Offset(0, -logical.height * 0.5),
        );
        await settle(tester);
        await take('sixty-result-review');
      });
    }
  }

  // Every other challenge on its screen, on the same three phones at night
  // and on paper: what it is, the round in play, and how it went — each
  // game out of its own tile, played through as a reader plays it.
  //
  //   flutter test tool/explore_shots.dart --plain-name "challenge:" \
  //     --update-goldens --dart-define=CHALLENGES_DIR=/somewhere/else
  Finder prefixed(String prefix) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(prefix),
  );
  Finder matching(RegExp pattern) => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        pattern.hasMatch((w.key! as ValueKey<String>).value),
  );
  bool has(Finder f) => f.evaluate().isNotEmpty;

  // Each game by its tile, the prefix of its screen's keys, and the page
  // of the challenges its tile is on.
  final Map<String, (String, int)> games = {
    'spot-false': ('spot', 0),
    'true-false': ('tf', 0),
    'bets-bigger': ('bigger', 0),
    'bets-closer': ('closer', 1),
    'bets-magnitude': ('magnitude', 1),
    'bets-range': ('range', 1),
    'bets-stake': ('stake', 1),
    'bets-number': ('number', 2),
    'in-order': ('in-order', 2),
    'what-year': ('what-year', 2),
    'before-after': ('before-after', 2),
  };

  /// One move of [id]'s round: a tap or two, as a reader makes them.
  Future<void> move(WidgetTester tester, String id, int n) async {
    Future<void> tap(Finder f, [int at = 0]) async {
      if (!has(f)) return;
      final int count = f.evaluate().length;
      await tester.tap(f.at(at % count), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 160));
    }

    switch (id) {
      case 'spot':
        await tap(prefixed('spot-claim-'), 1);
      case 'tf':
        await tap(find.byKey(ValueKey(n.isEven ? 'tf-true' : 'tf-false')));
      case 'bigger':
        await tap(prefixed('bigger-half-'), n);
      case 'closer':
        await tap(prefixed(n.isEven ? 'closer-more-' : 'closer-less-'));
      case 'magnitude':
        await tap(matching(RegExp(r'^magnitude-(?!round-|seg-).+-\d$')), 2 + n);
        await tap(find.byKey(const ValueKey('magnitude-sure-70')));
      case 'range':
        final Finder track = prefixed('range-track-');
        if (has(track)) {
          final Rect r = tester.getRect(track.first);
          await tester.tapAt(
            Offset(r.left + r.width * (0.3 + 0.2 * (n % 3)), r.center.dy),
          );
          await tester.pump(const Duration(milliseconds: 160));
        }
        await tap(matching(RegExp(r'^range-.+-w\d$')), n);
        await tap(prefixed('range-bet-'));
      case 'stake':
        await tap(matching(RegExp(r'^stake-.+-o\d$')), n);
        await tap(prefixed('stake-bet-'));
        await tap(find.byKey(const ValueKey('stake-sure-80')));
      case 'number':
        await tap(matching(RegExp(r'^number-(?!round-|seg-).+-[0-9.]+$')), 2);
        await tap(matching(RegExp(r'^number-(?!round-|seg-).+-[0-9.]+$')), 3);
        await tap(prefixed('number-lock-'));
        await tap(find.byKey(const ValueKey('number-sure-60')));
      case 'in-order':
        final List<String> moments = [
          for (final Element e in prefixed('in-order-card-').evaluate())
            (e.widget.key! as ValueKey<String>).value,
        ];
        for (final int i in const [2, 0, 3, 1]) {
          if (i < moments.length) {
            await tester.tap(
              find.byKey(ValueKey(moments[i])),
              warnIfMissed: false,
            );
            await tester.pump(const Duration(milliseconds: 160));
          }
        }
      case 'what-year':
        final Finder dial = find.byKey(const ValueKey('what-year-dial'));
        if (has(dial)) {
          await tester.drag(dial, Offset(n.isEven ? 230.0 : -150.0, 0));
          await tester.pump(const Duration(milliseconds: 300));
        }
        await tap(find.byKey(const ValueKey('what-year-step-1')));
        await tap(find.byKey(const ValueKey('what-year-lock')));
      case 'before-after':
        await tap(
          find.byKey(
            ValueKey(n.isEven ? 'before-after-after' : 'before-after-before'),
          ),
        );
    }
    for (int f = 0; f < 8; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  /// The way on once a round is told, or the check that ends it.
  Future<void> onward(WidgetTester tester, String id) async {
    for (final String key in [
      '$id-next-card',
      '$id-next',
      'spot-confirm',
      'in-order-check',
    ]) {
      final Finder f = find.byKey(ValueKey(key));
      if (has(f)) {
        await tester.tap(f, warnIfMissed: false);
        break;
      }
    }
    for (int f = 0; f < 16; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  for (final MapEntry<String, (Size, EdgeInsets)> phone
      in challengePhones.entries) {
    for (final bool paper in [false, true]) {
      final String name = '${phone.key}-${paper ? 'light' : 'dark'}';
      for (final MapEntry<String, (String, int)> game in games.entries) {
        final (String id, int page) = game.value;
        testWidgets('challenge: ${game.key} $name', (tester) async {
          Future<void> take(String shot) => expectLater(
            find.byType(MaterialApp).first,
            matchesGoldenFile('$challengesDir/$name-$id-$shot.png'),
          );
          final (Size logical, EdgeInsets safe) = phone.value;
          size(logical, 3);
          tester.view.padding = FakeViewPadding(
            top: safe.top * 3,
            bottom: safe.bottom * 3,
          );
          tester.view.viewPadding = FakeViewPadding(
            top: safe.top * 3,
            bottom: safe.bottom * 3,
          );
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);
          // ignore: invalid_use_of_visible_for_testing_member
          BetsDay.resetForTest();
          // ignore: invalid_use_of_visible_for_testing_member
          SharedPreferences.setMockInitialValues({
            'knowit.onboarded': true,
            if (paper) 'knowit.theme': 'light',
          });
          await tester.pumpWidget(const AstutoApp());
          await settle(tester);
          await tester.tap(find.byKey(const ValueKey('tab-Explore')));
          await settle(tester);
          await reach(tester, 'challenge-sixty', above: 150);
          if (page > 0) {
            await tester.tap(find.byKey(ValueKey('challenge-dot-$page')));
            await settle(tester);
          }
          await tester.tap(find.byKey(ValueKey('challenge-${game.key}')));
          await settle(tester);
          await settle(tester);
          await take('intro');
          await tester.tap(find.byKey(ValueKey('$id-play')));
          await settle(tester);
          // The round asked, before any move.
          await take('ask');
          // The round in play, a move or two in.
          await move(tester, id, 0);
          if (id == 'closer' || id == 'tf') await move(tester, id, 1);
          await take('play');
          // Spot the false one, its pick said: the four told.
          if (id == 'spot') {
            await tester.tap(find.byKey(const ValueKey('spot-confirm')));
            for (int f = 0; f < 12; f++) {
              await tester.pump(const Duration(milliseconds: 90));
            }
            await take('told');
          }
          // Closer, closer, its last step taken: told on its card.
          if (id == 'closer') {
            await move(tester, id, 2);
            await take('told');
          }
          // In order, checked: the moments in their true order, their years
          // told, before the report.
          if (id == 'in-order') {
            await tester.tap(find.byKey(const ValueKey('in-order-check')));
            for (int f = 0; f < 7; f++) {
              await tester.pump(const Duration(milliseconds: 90));
            }
            await take('told');
          }
          // The rest of the round, to its end.
          for (int n = 1; n < 40; n++) {
            if (has(find.byKey(ValueKey('$id-score')))) break;
            await onward(tester, id);
            if (has(find.byKey(ValueKey('$id-score')))) break;
            await move(tester, id, n);
          }
          await settle(tester);
          await settle(tester);
          await take('result');
          final Finder end = find.byKey(ValueKey('$id-end'));
          if (has(end)) {
            await tester.drag(end, Offset(0, -logical.height * 0.55));
            await settle(tester);
            await take('result-review');
          }
        });
      }
    }
  }
}
