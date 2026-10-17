// Two things to do on Explore's shelves rather than only read: lean
// towards a side of a debate on a slider, and spot the false one of four
// claims.
//
//   flutter test test/explore_side_false_year_test.dart
//   flutter test test/explore_side_false_year_test.dart --update-goldens --dart-define=SHOTS=true
//
// With SHOTS the last test also photographs the two shelves, at rest and
// played, into tool/shots/gallery/explore-b/ (gitignored), to be looked at
// rather than kept.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/themed_shelves.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/spot_the_false.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/signature_shelves.dart';

const _shots = bool.fromEnvironment('SHOTS');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _keyed(bool Function(String) test) => find.byWidgetPredicate(
  (w) => w.key is ValueKey<String> && test((w.key! as ValueKey<String>).value),
);

String _keyOf(WidgetTester tester, Finder f) =>
    (tester.widget(f).key! as ValueKey<String>).value;

/// The handles of the debates on the shelf that can still be leant: each
/// keyed `lean-<card>`, beside the line it says things on and the answer
/// it settles into.
Finder _handles() => _keyed(
  (k) =>
      k.startsWith('lean-') &&
      !k.startsWith('lean-said-') &&
      !k.startsWith('lean-hint-') &&
      !k.startsWith('lean-kept-'),
);

/// Where a scroll starts: the margin beside the shelves, where a drag too
/// short to scroll lands on nothing rather than on a card, at half the
/// height of whichever phone this is, clear of the tab bar.
Offset _margin(WidgetTester tester) => Offset(
  8,
  tester.view.physicalSize.height / tester.view.devicePixelRatio / 2,
);

/// Scrolls the shelves by [dy].
Future<void> _scroll(WidgetTester tester, double dy) async {
  if (dy.abs() < 24) return;
  await tester.dragFrom(_margin(tester), Offset(0, dy));
  await _settle(tester);
}

/// Scrolls the shelves until [target] is built, then brings its top to
/// [top] on the screen.
Future<void> _reach(
  WidgetTester tester,
  Finder target, {
  double top = 260,
}) async {
  for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
    await tester.dragFrom(_margin(tester), const Offset(0, -240));
    await tester.pump();
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await _settle(tester);
  await _scroll(tester, top - tester.getTopLeft(target.first).dy);
}

/// Brings [target] to the middle of the screen, clear of the tab bar that
/// floats over the foot of the shelves, and taps it.
Future<void> _tapInView(WidgetTester tester, Finder target) async {
  await _scroll(tester, 420 - tester.getCenter(target).dy);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _openExplore(WidgetTester tester, {bool paper = false}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    if (paper) 'knowit.theme': 'light',
  });
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('tab-Explore')));
  await _settle(tester);
}

/// The app's state, as Explore holds it: under a card opened over it too.
AppState _app(WidgetTester tester) => tester
    .state<ExploreScreenState>(find.byType(ExploreScreen, skipOffstage: false))
    .widget
    .app;

/// The faces the app ships, and the icons, so a photograph is what a
/// reader sees.
Future<void> _loadRealFonts() async {
  final faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final face in faces.entries) {
    final file = File(face.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(face.key);
    final bytes = await file.readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

void main() {
  final List<Pill> bank = PillBank.cards;

  // Read from disk, which a widget test's own clock would never let finish.
  setUpAll(() async {
    if (_shots) await _loadRealFonts();
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

  // ── Pick a side ────────────────────────────────────────────────────────

  group('a lean', () {
    test('is kept as how sure of the side, on the app\'s own scale', () {
      expect(
        [for (var s = 1; s <= 4; s++) leanConfidence(s)],
        [60, 70, 80, 90],
      );
      expect(kConfidenceLevels, containsAll([60, 70, 80, 90]));
      for (var s = 1; s <= 4; s++) {
        expect(leanLevel(Answer('0', confidence: leanConfidence(s))), s);
      }
      // A side taken with a button says nothing of how far.
      expect(leanLevel(const Answer('1')), isNull);
    });
  });

  testWidgets('a side leant to on the shelf is the card answered, and how '
      'far is how sure', (tester) async {
    await _openExplore(tester);
    final Finder handles = _handles();
    await _reach(tester, find.byKey(const ValueKey('signature-debates')));
    expect(handles, findsWidgets);
    final String id = _keyOf(tester, handles.first).substring('lean-'.length);
    final Pill card = PillBank.byId(id)!;
    final List<String> sides = (card.challenge as TakeASide).positions;
    expect(find.byKey(ValueKey('lean-hint-$id')), findsOneWidget);

    // Four fifths of the way to the first side: the third step of four.
    final Rect grip = tester.getRect(handles.first);
    final double travel = (300 - 36) / 2 - (grip.width - 26) / 2;
    await tester.drag(handles.first, Offset(-travel * 0.8, 0));
    await _settle(tester);

    final AppState app = _app(tester);
    expect(app.answerFor(id)?.response, '0');
    expect(app.answerFor(id)?.confidence, 80);
    expect(app.seenIds, contains(id));
    final String side = sides.first.split(',').first.trim();
    expect(
      find.text('$side, firmly. Open it for the other side.'),
      findsOneWidget,
    );
    // An answer stands: the handle is no longer there to be moved.
    expect(find.byKey(ValueKey('lean-$id')), findsNothing);

    // And the card, opened, says the side and how far.
    final Rect face = tester.getRect(find.byKey(ValueKey('explore-$id')));
    await tester.tapAt(Offset(face.left + 60, face.top + 70));
    await _settle(tester);
    expect(find.byType(DeckViewerScreen), findsOneWidget);
    final Rect deck = tester.getRect(find.byType(PillCardStack));
    await tester.tapAt(Offset(deck.center.dx, deck.top + 90));
    await _settle(tester);
    expect(
      find.textContaining('${sides.first} · firmly', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('let go in the middle, a lean is nothing, and the rest of the '
      'card still opens it', (tester) async {
    await _openExplore(tester);
    final Finder handles = _handles();
    await _reach(tester, find.byKey(const ValueKey('signature-debates')));
    final String id = _keyOf(tester, handles.first).substring('lean-'.length);

    // Out past the slop and nearly back: the middle is no side.
    final TestGesture hand = await tester.startGesture(
      tester.getCenter(handles.first),
    );
    await hand.moveBy(const Offset(30, 0));
    await tester.pump();
    await hand.moveBy(const Offset(-26, 0));
    await tester.pump();
    await hand.up();
    await _settle(tester);
    expect(_app(tester).answerFor(id), isNull);
    expect(find.byKey(ValueKey('lean-hint-$id')), findsOneWidget);

    // The question is the card, and opens it.
    final Rect face = tester.getRect(find.byKey(ValueKey('explore-$id')));
    await tester.tapAt(Offset(face.left + 60, face.top + 70));
    await _settle(tester);
    expect(find.byType(DeckViewerScreen), findsOneWidget);
    expect(_app(tester).answerFor(id), isNull);
  });

  testWidgets('a lean is said on the card\'s own page too', (tester) async {
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    final AppState app = AppState();
    await app.init();
    final Pill debate = bank.firstWhere((p) => p.challenge is TakeASide);
    await app.recordAnswer(debate.id, '1', confidence: leanConfidence(4));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: PillDetailScreen(pill: debate, app: app),
      ),
    );
    await tester.pumpAndSettle();
    final String side = (debate.challenge as TakeASide).positions[1];
    expect(find.text('You took the side: $side · all the way'), findsOneWidget);
  });

  // ── Spot the false one ──────────────────────────────────────────────────

  group('spot the false one', () {
    test('is three true claims and one false, from four subjects', () {
      for (int day = 20730; day < 20750; day++) {
        final SpotTheFalse spot = spotTheFalse(bank, day: day)!;
        expect(spot.cards, hasLength(4));
        expect(spot.cards.every(isTrueOrFalse), isTrue);
        expect(spot.cards.where((p) => !trueOrFalseAnswer(p)), hasLength(1));
        expect(spot.cards.where(trueOrFalseAnswer), hasLength(3));
        expect(trueOrFalseAnswer(spot.falseOne), isFalse);
        expect(spot.cards.map((p) => p.id).toSet(), hasLength(4));
        expect(spot.cards.map((p) => p.topic).toSet(), hasLength(4));
      }
    });

    test('is dealt only from cards not read', () {
      final Set<String> read = {
        for (final p in bank.where(isTrueOrFalse).take(400)) p.id,
      };
      final List<Pill> unread = bank
          .where((p) => !read.contains(p.id))
          .toList();
      for (int day = 20730; day < 20740; day++) {
        final SpotTheFalse spot = spotTheFalse(unread, day: day)!;
        expect(spot.cards.where((p) => read.contains(p.id)), isEmpty);
      }
      final ExploreMix mix = dealExploreMix(
        bank: bank,
        pool: unread,
        day: 20735,
        on: DateTime(2026, 10, 9),
      );
      expect(mix.spot!.cards.where((p) => read.contains(p.id)), isEmpty);
    });

    test('is the same all day, whatever order the cards are in, and another '
        'set the next', () {
      final SpotTheFalse a = spotTheFalse(bank, day: 20735)!;
      final SpotTheFalse b = spotTheFalse(List.of(bank.reversed), day: 20735)!;
      expect(b.cards.map((p) => p.id), a.cards.map((p) => p.id));
      final SpotTheFalse next = spotTheFalse(bank, day: 20736)!;
      expect(next.cards.map((p) => p.id), isNot(a.cards.map((p) => p.id)));
    });

    test('hides the false one in a different place from day to day', () {
      final Set<int> places = {
        for (int day = 20700; day < 20730; day++)
          spotTheFalse(
            bank,
            day: day,
          )!.cards.indexWhere((p) => !trueOrFalseAnswer(p)),
      };
      expect(places.length, greaterThan(2));
    });

    test('shares no card with another shelf', () {
      final ExploreMix mix = dealExploreMix(
        bank: bank,
        pool: bank,
        day: 20735,
        on: DateTime(2026, 10, 9),
      );
      final Set<String> spot = {for (final p in mix.spot!.cards) p.id};
      final Set<String> elsewhere = {
        ...mix.month.map((p) => p.id),
        ...mix.sixty.map((p) => p.id),
        ...?mix.numbers?.pills.map((p) => p.id),
        ...?mix.trueFalse?.pills.map((p) => p.id),
        ...?mix.practical?.pills.map((p) => p.id),
        ...?mix.debates?.pills.map((p) => p.id),
        ...mix.work.cards.map((p) => p.id),
        ...?mix.stories?.pills.map((p) => p.id),
        ...?mix.sharpest?.pills.map((p) => p.id),
        ...mix.didYouKnow.map((p) => p.id),
        ...mix.compared.map((p) => p.id),
        ...mix.sampling.map((p) => p.id),
        ...mix.unmask.map((p) => p.id),
        for (final s in mix.series) ...s.cards.map((p) => p.id),
        ...?mix.origins?.pills.map((p) => p.id),
        ...mix.whatIf.map((p) => p.id),
        ...mix.howSure.map((p) => p.id),
      };
      expect(spot.intersection(elsewhere), isEmpty);
    });

    test('narrowed to one subject, it is that subject\'s or nothing', () {
      final List<Pill> space = bank.where((p) => p.topic == 'Space').toList();
      final SpotTheFalse? spot = spotTheFalse(space, day: 20735);
      if (spot != null) {
        expect(spot.cards.every((p) => p.topic == 'Space'), isTrue);
        expect(spot.cards.where((p) => !trueOrFalseAnswer(p)), hasLength(1));
      }
      // Without a false claim to find there is no game.
      expect(
        spotTheFalse(
          bank.where((p) => isTrueOrFalse(p) && trueOrFalseAnswer(p)),
          day: 20735,
        ),
        isNull,
      );
    });
  });

  testWidgets('a true claim picked as the false one is that card answered '
      'false, and the other three are left alone', (tester) async {
    await _openExplore(tester);
    await _reach(tester, find.byKey(const ValueKey('mix-spot-false')));
    final List<String> ids = [
      for (final e in _keyed((k) => k.startsWith('spot-')).evaluate())
        if (PillBank.byId(
              (e.widget.key! as ValueKey<String>).value.substring(5),
            )
            case final Pill p)
          p.id,
    ];
    expect(ids, hasLength(4));
    final List<Pill> four = [for (final id in ids) PillBank.byId(id)!];
    expect(four.where((p) => !trueOrFalseAnswer(p)), hasLength(1));
    final Pill lie = four.firstWhere((p) => !trueOrFalseAnswer(p));
    final Pill pick = four.firstWhere(trueOrFalseAnswer);

    // A tap is a choice, not yet an answer.
    expect(find.text('Tap the one you think is false'), findsOneWidget);
    await _tapInView(tester, find.byKey(ValueKey('spot-${pick.id}')));
    expect(_app(tester).answerFor(pick.id), isNull);
    await _tapInView(tester, find.byKey(const ValueKey('spot-confirm')));

    final AppState app = _app(tester);
    expect(
      app.answerFor(pick.id)?.response,
      '${trueOrFalseIndex(pick, false)}',
    );
    expect(pick.challenge.accepts(app.answerFor(pick.id)!.response), isFalse);
    expect(app.seenIds, contains(pick.id));
    // The other three are not answered, but the reveal told them, so they
    // count as read: the day must not deal a card whose answer was shown.
    for (final p in four.where((p) => p.id != pick.id)) {
      expect(app.answerFor(p.id), isNull, reason: p.id);
      expect(app.seenIds, contains(p.id), reason: p.id);
    }

    // Every claim says what it is, and the false one is told.
    expect(
      find.text("Not that one: it's true. The false one is struck out."),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('spot-${lie.id}-false')), findsOneWidget);
    for (final p in four.where(trueOrFalseAnswer)) {
      expect(find.byKey(ValueKey('spot-${p.id}-true')), findsOneWidget);
    }

    // And each is a tap from its card.
    await _tapInView(tester, find.byKey(ValueKey('spot-${lie.id}')));
    expect(find.byType(DeckViewerScreen), findsOneWidget);
  });

  testWidgets('the false claim found is said so, and stays found when the '
      'shelf comes back', (tester) async {
    await _openExplore(tester);
    await _reach(tester, find.byKey(const ValueKey('mix-spot-false')));
    final Pill lie = [
      for (final e in _keyed((k) => k.startsWith('spot-')).evaluate())
        if (PillBank.byId(
              (e.widget.key! as ValueKey<String>).value.substring(5),
            )
            case final Pill p)
          p,
    ].firstWhere((p) => !trueOrFalseAnswer(p));
    await _tapInView(tester, find.byKey(ValueKey('spot-${lie.id}')));
    await _tapInView(tester, find.byKey(const ValueKey('spot-confirm')));
    expect(find.text('Found it. The other three are true.'), findsOneWidget);
    expect(
      _app(tester).answerFor(lie.id)?.response,
      '${trueOrFalseIndex(lie, false)}',
    );
    expect(
      lie.challenge.accepts(_app(tester).answerFor(lie.id)!.response),
      isTrue,
    );

    // Scrolled far away and back, the answer is still on the shelf.
    await _scroll(tester, -4000);
    await _scroll(tester, 4000);
    await _reach(tester, find.byKey(const ValueKey('mix-spot-false')));
    expect(find.text('Found it. The other three are true.'), findsOneWidget);
  });

  // ── Every language, and a small phone ──────────────────────────────────

  testWidgets('the two fit in every language, on a small phone too', (
    tester,
  ) async {
    Pill debate(String id, List<String> sides) => Pill(
      id: id,
      topic: 'Philosophy',
      color: const Color(0xFF3D6BFF),
      ink: const Color(0xFFFFFFFF),
      tint: const Color(0xFF3D6BFF),
      question:
          'Should a sentence be cut when a brain disorder shaped the '
          'crime?',
      answer: 'It depends.',
      barMove: '',
      source: '',
      challenge: TakeASide(positions: sides),
    );
    Pill claim(String id, bool truth, String topic) => Pill(
      id: id,
      topic: topic,
      color: const Color(0xFF00E5A0),
      ink: const Color(0xFF10100C),
      tint: const Color(0xFF00E5A0),
      question:
          'True or false: a claim that runs to about the length most '
          'claims in the bank run to, ninety characters?',
      answer: truth ? 'True.' : 'False.',
      barMove: '',
      source: '',
      challenge: PickOne(
        options: const ['True', 'False'],
        correct: truth ? 0 : 1,
      ),
    );
    final List<Pill> debates = [
      debate('d-1', const ['Yes, cut it', 'No, keep it']),
      debate('d-2', const ['Institutions come first', 'Wealth comes first']),
    ];
    final SpotTheFalse spot = SpotTheFalse([
      claim('c-1', true, 'Science'),
      claim('c-2', false, 'History'),
      claim('c-3', true, 'Nature'),
      claim('c-4', true, 'Sport'),
    ]);

    for (final Size phone in const [Size(402, 874), Size(320, 568)]) {
      tester.view.physicalSize = phone * 3;
      tester.view.devicePixelRatio = 3;
      for (final Locale locale in AppLocalizations.supportedLocales) {
        ExplorePlay.resetForTest();
        final Map<String, Answer> said = {};
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.dark),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => ListView(
                  children: [
                    SignatureRow(
                      shelf: ThemedShelf(ShelfTheme.debates, 0, debates),
                      isRead: (p) => said.containsKey(p.id),
                      onOpen: (_, _) {},
                      answerOf: (p) => said[p.id],
                      onLean: (p, side, sure) => setState(
                        () => said[p.id] = Answer('$side', confidence: sure),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SpotTheFalseBlock(
                      spot: spot,
                      onOpen: (_, _) {},
                      onCommit: (p, response) =>
                          setState(() => said[p.id] = Answer(response)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final String where = '$locale on ${phone.width.round()}';

        // Lean the first debate most of the way, and let go.
        await tester.drag(
          find.byKey(const ValueKey('lean-d-1')),
          const Offset(-80, 0),
        );
        await tester.pumpAndSettle();
        expect(said['d-1']?.response, '0', reason: where);
        expect(find.byKey(const ValueKey('lean-kept-d-1')), findsOneWidget);

        // Scrolled to, laid out where it now is, and tapped.
        Future<void> tap(Finder target) async {
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        // Pick a claim and say it is meant.
        await tap(find.byKey(const ValueKey('spot-c-1')));
        await tap(find.byKey(const ValueKey('spot-confirm')));
        expect(said['c-1']?.response, '1', reason: where);
        expect(said.containsKey('c-2'), isFalse, reason: where);

        expect(tester.takeException(), isNull, reason: where);
      }
    }
  });

  // ── Photographs ────────────────────────────────────────────────────────

  testWidgets('photographs: the two shelves, at rest and played', (
    tester,
  ) async {
    Future<void> shoot(String name) => expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('../tool/shots/gallery/explore-b/$name.png'),
    );

    Future<void> play({required String tag, bool paper = false}) async {
      // A fresh app each time round: the same one pumped again would keep
      // its state, its theme and its place on the page.
      await tester.pumpWidget(const SizedBox());
      ExplorePlay.resetForTest();
      await _openExplore(tester, paper: paper);

      // Pick a side: at rest, held, let go.
      await _reach(
        tester,
        find.byKey(const ValueKey('signature-debates')),
        top: 250,
      );
      await tester.pump(const Duration(seconds: 3));
      await shoot('$tag-side-rest');
      final Finder handles = _handles();
      final TestGesture hand = await tester.startGesture(
        tester.getCenter(handles.first),
      );
      await hand.moveBy(const Offset(-40, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await hand.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await shoot('$tag-side-held');
      await hand.up();
      await _settle(tester);
      await shoot('$tag-side-leant');
      // The next card along, all the way to its second side: the row is
      // slid by the question of the card already answered, whose handle
      // has gone, so the next handle is the next card's.
      final Rect row = tester.getRect(find.byType(SignatureRow).first);
      await tester.dragFrom(
        Offset(row.left + 200, row.top + 70),
        const Offset(-310, 0),
      );
      await _settle(tester);
      await tester.dragFrom(
        tester.getCenter(handles.first),
        const Offset(160, 0),
      );
      await _settle(tester);
      await shoot('$tag-side-all-the-way');

      // Spot the false one: at rest, chosen, told.
      await _reach(
        tester,
        find.byKey(const ValueKey('mix-spot-false')),
        top: 150,
      );
      await shoot('$tag-spot-rest');
      final Finder rows = _keyed(
        (k) =>
            k.startsWith('spot-') &&
            PillBank.byId(k.substring(5)) != null &&
            trueOrFalseAnswer(PillBank.byId(k.substring(5))!),
      );
      await _tapInView(tester, rows.first);
      await _reach(
        tester,
        find.byKey(const ValueKey('mix-spot-false')),
        top: 150,
      );
      await shoot('$tag-spot-chosen');
      await _tapInView(tester, find.byKey(const ValueKey('spot-confirm')));
      await _reach(
        tester,
        find.byKey(const ValueKey('mix-spot-false')),
        top: 150,
      );
      await shoot('$tag-spot-told');
    }

    await play(tag: 'night');
    ExplorePlay.resetForTest();
    await play(tag: 'paper', paper: true);
    ExplorePlay.resetForTest();
    tester.platformDispatcher.localesTestValue = const [Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await play(tag: 'it');
  }, skip: !_shots);
}
