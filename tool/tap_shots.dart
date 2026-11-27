// Photographs a pick being taken on a card in words, frame by frame, as the
// owner checks it on his phone: the finger on True, True taken, the step
// that asks how sure under it, the level taken, the card turning, its back.
// And the same card when it does not ask how sure, turning at once.
//
//   flutter test tool/tap_shots.dart --update-goldens \
//     --dart-define=TAP_DIR=/some/folder
//
// A camera, not a check: it lives outside test/ so CI never runs it. An
// Italian reader's iPhone at night, 390 by 844, three pixels a point.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

import '../test/explore/core_harness.dart' show loadFonts;

const String _dirGiven = String.fromEnvironment('TAP_DIR');
final String _dir = _dirGiven.isEmpty ? 'shots/gallery/tap' : _dirGiven;

const Size _phone = Size(390, 844);

/// A card of the bank, as the app reads it, asking how sure always ([sure]
/// null) or never (0).
Pill _card(String topic, String id, {double? sure}) {
  final Map<String, Object?> raw = (jsonDecode(
    File('tool/cards/bank/$topic/$id.json').readAsStringSync(),
  ) as Map).cast<String, Object?>();
  raw.remove('sure');
  if (sure != null) raw['sure'] = sure;
  return cardFromJson(raw);
}

Widget _host(Pill pill, Map<String, Answer> given) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    backgroundColor: Palette.dark.surface,
    body: Padding(
      // Where Today's head and its tabs leave the card.
      padding: const EdgeInsets.fromLTRB(kDeckMargin, 104, kDeckMargin, 118),
      child: PillCardStack(
        isSaved: (_) => false,
        onSave: (_) {},
        onShare: (_) {},
        deck: [pill],
        index: 0,
        onAdvance: () {},
        answerFor: (id) => given[id],
        reviewIds: const {},
        onAnswer: (id, response, confidence, reason) => given[id] = Answer(
          response,
          confidence: confidence,
          reason: reason,
        ),
      ),
    ),
  ),
);

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('$_dir/$name.png'));

void main() {
  setUpAll(loadFonts);

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = _phone * 3;
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  testWidgets('true or false, asking how sure', (tester) async {
    addTearDown(tester.view.reset);
    final Pill pill = _card('cinema', 'cinema-destroyed-4');
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    await _shot(tester, 'a1-fronte');

    final Finder yes = find.text('True');
    final TestGesture finger = await tester.startGesture(tester.getCenter(yes));
    await tester.pump(const Duration(milliseconds: 60));
    await _shot(tester, 'a2-dito-giu');
    await finger.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await _shot(tester, 'a3-preso');
    await tester.pump(const Duration(milliseconds: 160));
    await _shot(tester, 'a4-si-piega');
    await tester.pumpAndSettle();
    await _shot(tester, 'a5-quanto-sicuro');

    await tester.tap(find.text('70%'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await _shot(tester, 'a6-livello-preso');
    await tester.pump(const Duration(milliseconds: 110));
    await _shot(tester, 'a7-gira');
    await tester.pumpAndSettle();
    await _shot(tester, 'a8-retro');
  });

  testWidgets('true or false, turning at once', (tester) async {
    addTearDown(tester.view.reset);
    final Pill pill = _card('food', 'food-maillard-3', sure: 0);
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    await _shot(tester, 'b1-fronte');
    await tester.tap(find.text('False'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await _shot(tester, 'b2-preso-gira');
    await tester.pump(const Duration(milliseconds: 90));
    await _shot(tester, 'b3-gira');
    await tester.pumpAndSettle();
    await _shot(tester, 'b4-retro');
  });

  testWidgets('a side taken on a debate, then why', (tester) async {
    addTearDown(tester.view.reset);
    final Pill pill = _card('art', 'art-florence-4');
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    await _shot(tester, 'c1-fronte');
    final TakeASide side = pill.challenge as TakeASide;
    await tester.tap(find.text(side.positions.first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await _shot(tester, 'c2-preso');
    await tester.pumpAndSettle();
    await _shot(tester, 'c3-perche');
  });
}
