// The shelves on Explore that did not say what they were, each saying it
// now in the form every shelf has: a name, a line under it, the cards. And
// Work it out, one row of every way to play a number instead of six rows
// behind a row of chips.
//
//   flutter test test/explore_shelves_test.dart
//   flutter test test/explore_shelves_test.dart --update-goldens --dart-define=SHOTS=true
//
// With SHOTS the tests also photograph each shelf, at night and on paper,
// into tool/shots/gallery/explore/ (gitignored), to be looked at rather
// than kept.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/widgets/explore/work_it_out.dart';

const _shots = bool.fromEnvironment('SHOTS');

/// Every way Work it out plays a number, by the name its places are keyed
/// with.
const List<String> _kinds = [
  'pick',
  'slide',
  'closer',
  'bigger',
  'range',
  'stake',
];

/// The faces the app ships, and the icons, so a photograph shows what a
/// reader sees rather than the test font's boxes.
Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final face in fonts.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

Finder _keyed(bool Function(String) test) => find.byWidgetPredicate(
  (w) => w.key is ValueKey<String> && test((w.key! as ValueKey<String>).value),
);

/// The shelves' own list: the first scroll that runs down inside Explore,
/// and not a card's on the Today page kept alive beside it.
Finder _down() => find
    .descendant(
      of: find.byType(ExploreScreen),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    )
    .first;

/// Work it out's row, by its own position.
ScrollPosition _row(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('mix-work')),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
            ),
          )
          .first,
    )
    .position;

/// Answers given a while ago and due again today, so the shelf of cards
/// that came back has something on it.
Map<String, Object> _due() {
  final String yesterday = dateKey(
    DateTime.now().subtract(const Duration(days: 1)),
  );
  final picks = PillBank.cards
      .where((p) => p.challenge is PickOne && p.topic != 'Thinking')
      .take(5)
      .toList();
  return {
    'knowit.answersJson': jsonEncode({
      for (int i = 0; i < picks.length; i++)
        picks[i].id: {'r': '0', 's': i.isEven ? 1 : 0, 'd': yesterday},
    }),
  };
}

Future<void> _open(
  WidgetTester tester, {
  bool paper = false,
  Map<String, Object> extra = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    if (paper) 'knowit.theme': 'light',
    ...extra,
  });
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('tab-Explore')));
  await _settle(tester);
}

/// Scrolls the shelves until [target] is built, then brings its top up
/// under the subject row. Moved by the list's own position rather than by a
/// finger: a drag that comes out shorter than a touch's slop is a tap, and a
/// tap on a shelf opens the card under it.
Future<void> _reach(WidgetTester tester, Finder target) async {
  final ScrollPosition list = tester.state<ScrollableState>(_down()).position;
  for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
    list.jumpTo(math.min(list.pixels + 500, list.maxScrollExtent));
    await tester.pump();
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await _settle(tester);
  final double listTop = tester.getTopLeft(_down()).dy;
  final double top = tester.getTopLeft(target.first).dy;
  list.jumpTo(
    (list.pixels + top - listTop - 14).clamp(0, list.maxScrollExtent),
  );
  await _settle(tester);
}

/// Walks Work it out's row from end to end, and says where each of its
/// places sits on it, by key.
Future<Map<String, Rect>> _places(WidgetTester tester) async {
  final ScrollPosition row = _row(tester);
  final places = <String, Rect>{};
  final RegExp place = RegExp(
    r'^work-(pick|slide|closer|bigger|range|stake)-\d+$',
  );
  row.jumpTo(0);
  await _settle(tester);
  while (true) {
    for (final e in _keyed(place.hasMatch).evaluate()) {
      final String key = (e.widget.key! as ValueKey<String>).value;
      final Rect r = tester.getRect(find.byKey(ValueKey(key)));
      places[key] = r.shift(Offset(row.pixels, 0));
    }
    if (row.pixels >= row.maxScrollExtent) break;
    row.jumpTo(math.min(row.pixels + 300, row.maxScrollExtent));
    await _settle(tester);
  }
  return places;
}

/// Plays [card] the way its game is played.
Future<void> _play(WidgetTester tester, String kind, Finder card) async {
  Finder inCard(bool Function(String) test) =>
      find.descendant(of: card, matching: _keyed(test));
  Future<void> tap(Finder f) async {
    await tester.tap(f.first);
    await _settle(tester);
  }

  switch (kind) {
    case 'pick':
      await tap(inCard((k) => RegExp(r'^pick-.*-1$').hasMatch(k)));
    case 'slide':
      await tap(inCard((k) => k.startsWith('slide-check-')));
    case 'closer':
      for (final side in ['more', 'less', 'more']) {
        await tap(
          inCard((k) => k.startsWith('closer-') && k.endsWith('-$side')),
        );
      }
    case 'bigger':
      await tap(inCard((k) => k.startsWith('bigger-')));
    case 'range':
      await tap(inCard((k) => k.startsWith('range-bet-')));
    case 'stake':
      await tap(inCard((k) => RegExp(r'^stake-.*-o0$').hasMatch(k)));
      await tap(inCard((k) => k.startsWith('stake-bet-')));
  }
}

Future<void> _shoot(String name) async {
  if (!_shots) return;
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('../tool/shots/gallery/explore/$name.png'),
  );
}

void main() {
  // Outside the test body: FontLoader needs real asynchrony.
  setUpAll(() async {
    if (_shots) await _loadFonts();
  });

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    ExplorePlay.resetForTest();
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  group('a question from every subject', () {
    test('holds questions with an answer, a subject at a time', () {
      final List<Pill> asking = askingPills(seed: allTimeSeed, count: 40);
      expect(asking, hasLength(40));
      expect(asking.every((p) => p.isGraded), isTrue);
      // A round of every subject before any subject comes back.
      final int subjects = PillBank.cards.map((p) => p.topic).toSet().length;
      expect(
        asking.take(subjects).map((p) => p.topic).toSet(),
        hasLength(subjects),
      );
      // Not the hardest first: that is For the sharpest, further down.
      expect(
        asking.where((p) => p.difficulty != Difficulty.hard).length,
        greaterThan(asking.length ~/ 2),
      );
    });

    test('never turns over: the same rows until they are read', () {
      expect(
        askingPills(seed: allTimeSeed, count: 12).map((p) => p.id),
        askingPills(seed: allTimeSeed, count: 12).map((p) => p.id),
      );
    });
  });

  for (final paper in [false, true]) {
    final String tone = paper ? '-light' : '';

    testWidgets('each shelf says what it is, named like every shelf$tone', (
      tester,
    ) async {
      await _open(tester, paper: paper, extra: _due());

      // The rows under today's shelf: a question from every subject, and
      // not the hardest cards a second time.
      await _reach(tester, find.byKey(const ValueKey('shelf-asking')));
      expect(find.text('A question from every subject'), findsOneWidget);
      expect(
        find.text('The same for everyone. Answer first, then see why'),
        findsOneWidget,
      );
      await _shoot('asking$tone');

      // Use it today: the thing to try, and nothing beside it to puzzle
      // over.
      await _reach(tester, find.byKey(const ValueKey('theme-practical-0')));
      expect(
        find.text(
          'Something to try, or to drop into a conversation, before tonight',
        ),
        findsOneWidget,
      );
      expect(_keyed((k) => k.startsWith('tried-')), findsNothing);
      await _shoot('use-today$tone');

      // What came back says what it is and why it is here.
      await _reach(tester, find.byKey(const ValueKey('mix-came-back')));
      final Finder remember = find.text('Do you still remember?');
      expect(remember, findsOneWidget);
      expect(find.textContaining('you answered days ago'), findsOneWidget);
      // Every shelf's name is set like this one's.
      final TextStyle? named = tester.widget<Text>(remember).style;
      await _shoot('came-back$tone');

      // The two questions to ask of a number, named at the size every
      // shelf is named at, and no box round them.
      await _reach(tester, find.byKey(const ValueKey('mix-move-sampling')));
      for (final title in ['Who got counted?', 'Compared to what?']) {
        final Finder name = find.text(title, skipOffstage: false);
        expect(name, findsOneWidget);
        expect(tester.widget<Text>(name).style, named, reason: title);
      }
      expect(
        find.text('Who ends up in a study decides what it can tell you'),
        findsOneWidget,
      );
      await _shoot('sampling$tone');
      await _reach(tester, find.byKey(const ValueKey('mix-move-compared')));
      expect(
        find.text(
          'A change means nothing without something to compare it with',
        ),
        findsOneWidget,
      );
      await _shoot('compared$tone');

      // Work it out, named like the rest.
      await _reach(tester, find.byKey(const ValueKey('mix-work')));
      expect(
        find.text('Guess the number before the card tells you'),
        findsOneWidget,
      );
      expect(tester.widget<Text>(find.text('Work it out')).style, named);
      await _shoot('work$tone');
      final ScrollPosition row = _row(tester);
      row.jumpTo(math.min(620, row.maxScrollExtent));
      await _settle(tester);
      await _shoot('work-further$tone');
    });

    testWidgets('work it out, played$tone', (tester) async {
      await _open(tester, paper: paper);
      await _reach(tester, find.byKey(const ValueKey('mix-work')));
      final Map<String, Rect> places = await _places(tester);
      final ScrollPosition row = _row(tester);
      // One of each way, brought to the front of the row and played there.
      for (final kind in _kinds) {
        final String key = places.keys.firstWhere(
          (k) => k.startsWith('work-$kind-'),
        );
        row.jumpTo(math.min(places[key]!.left - 20, row.maxScrollExtent));
        await _settle(tester);
        await _shoot('work-$kind$tone');
        await _play(tester, kind, find.byKey(ValueKey(key)));
        await _shoot('work-$kind-played$tone');
      }
      // A stake is paid from the day's hundred points, and a range that
      // was hit pays into them.
      expect(ExplorePlay.instance.points, isNot(ExplorePlay.dailyPoints));
    });
  }

  testWidgets('work it out: one row, every way in it, every card one size', (
    tester,
  ) async {
    await _open(tester);
    await _reach(tester, find.byKey(const ValueKey('mix-work')));
    // No chips to choose a way with first: the row is the shelf.
    expect(
      _keyed((k) => RegExp(r'^work-[a-z]+-(on|off)$').hasMatch(k)),
      findsNothing,
    );
    final Map<String, Rect> places = await _places(tester);
    final List<String> order = places.keys.toList()
      ..sort((a, b) => places[a]!.left.compareTo(places[b]!.left));
    String kindOf(String key) => key.split('-')[1];

    // Every way of playing is on it, twice, and the first six places are
    // six different ways: whatever the day draws, the row opens on all of
    // them.
    expect(order, hasLength(12));
    expect(order.map(kindOf).toSet(), _kinds.toSet());
    expect(order.take(6).map(kindOf).toSet(), hasLength(6));
    for (var i = 1; i < order.length; i++) {
      expect(kindOf(order[i]), isNot(kindOf(order[i - 1])), reason: '$order');
    }
    // One size for every card on it.
    for (final key in order) {
      expect(
        places[key]!.size,
        const Size(kWorkCardWidth, kWorkCardHeight),
        reason: key,
      );
    }
  });

  testWidgets('in French, where the names run longest, nothing runs over', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _open(tester, extra: _due());
    await _reach(tester, find.byKey(const ValueKey('mix-came-back')));
    expect(find.text('Tu t\'en souviens encore ?'), findsOneWidget);
    await _shoot('fr-came-back');
    await _reach(tester, find.byKey(const ValueKey('mix-move-sampling')));
    expect(find.text('Qui a été compté ?'), findsOneWidget);
    await _shoot('fr-sampling');
    await _reach(tester, find.byKey(const ValueKey('mix-work')));
    final ScrollPosition row = _row(tester);
    final games = <String>{};
    for (var at = 0.0; ; at += 310) {
      row.jumpTo(math.min(at, row.maxScrollExtent));
      await _settle(tester);
      for (final e in _keyed((k) => k.startsWith('work-game-')).evaluate()) {
        games.add(((e.widget as Container).child! as Text).data!);
      }
      if (_shots && at % 620 == 0) await _shoot('fr-work-${at ~/ 620}');
      if (row.pixels >= row.maxScrollExtent) break;
    }
    expect(games, contains('PARIE SUR UNE FOURCHETTE'));
    expect(games, contains('LEQUEL EST PLUS GRAND ?'));
  });

  testWidgets('every card on the row says which game it is', (tester) async {
    await _open(tester);
    await _reach(tester, find.byKey(const ValueKey('mix-work')));
    final ScrollPosition row = _row(tester);
    final labels = <String>{};
    final games = <String>{};
    while (true) {
      for (final e in _keyed((k) => k.startsWith('work-game-')).evaluate()) {
        labels.add((e.widget.key! as ValueKey<String>).value);
        final Text text = (e.widget as Container).child! as Text;
        games.add(text.data!);
      }
      if (row.pixels >= row.maxScrollExtent) break;
      row.jumpTo(math.min(row.pixels + 300, row.maxScrollExtent));
      await _settle(tester);
    }
    // One label to a card, the comparison's on its upper half.
    expect(labels, hasLength(12));
    expect(games, {
      'PICK ONE',
      'MOVE IT',
      'CLOSER, CLOSER',
      'WHICH IS BIGGER?',
      'BET A RANGE',
      'PLACE YOUR BET',
    });
  });
}
