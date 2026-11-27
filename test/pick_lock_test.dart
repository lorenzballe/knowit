// A pick on a card in words, taken: the option tapped fills and is ticked
// at once, the others dim and take no tap, and on a card that asks how sure
// before it turns, the option kept stays over the question while the others
// fold away; the level tapped turns the card at once. A card that does not
// ask turns with the option filled; a debate keeps its side over "why".
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/place_it.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

import 'explore/core_harness.dart' show loadFonts;

/// A card of the bank as the app reads it, asking how sure always ([sure]
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
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    backgroundColor: Palette.dark.surface,
    body: SizedBox(
      height: 640,
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

/// How far [text]'s option is faded: the opacity of the nearest fade over it.
double _opacity(WidgetTester tester, String text) => tester
    .widget<AnimatedOpacity>(
      find
          .ancestor(of: find.text(text), matching: find.byType(AnimatedOpacity))
          .first,
    )
    .opacity;

void main() {
  testWidgets('true or false, asking how sure: True stays taken over the '
      'question, False dims and folds away, nothing else is taken', (
    tester,
  ) async {
    final Pill pill = _card('cinema', 'cinema-destroyed-4');
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.text('True'));
    await tester.pump();
    // At once: ticked, the other dimmed, nothing recorded yet.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(_opacity(tester, 'False'), lessThan(0.5));
    expect(_opacity(tester, 'True'), 1);
    expect(given, isEmpty);
    // A second tap, on the other, takes nothing.
    await tester.tap(find.text('False'), warnIfMissed: false);
    await tester.pump();
    expect(given, isEmpty);

    await tester.pumpAndSettle();
    // How sure comes in under the option kept; the other has folded away.
    expect(find.text('How sure are you?'), findsOneWidget);
    expect(find.text('True'), findsOneWidget);
    expect(find.text('False'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    // The question stands above the option kept, the levels below it.
    expect(
      tester.getTopLeft(find.text('True')).dy,
      lessThan(tester.getTopLeft(find.text('How sure are you?')).dy),
    );

    await tester.tap(find.text('70%'));
    await tester.pump();
    expect(given[pill.id]?.response, '0');
    expect(given[pill.id]?.confidence, 70);
    // Another level, tapped while the card turns, changes nothing.
    await tester.tap(find.text('90%'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(given[pill.id]?.confidence, 70);
    expect(find.text('WHAT TO KEEP'), findsOneWidget);
  });

  testWidgets('the five levels stand in one row where they fit', (
    tester,
  ) async {
    final Pill pill = _card('cinema', 'cinema-destroyed-4');
    await tester.pumpWidget(_host(pill, {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text('True'));
    await tester.pumpAndSettle();
    final double row = tester.getCenter(find.text('50%')).dy;
    for (final String level in ['60%', '70%', '80%', '90%']) {
      expect(tester.getCenter(find.text(level)).dy, row, reason: level);
    }
  });

  testWidgets('on a 375-point phone the five still stand in one row; where '
      'they must wrap, at a larger text size, the step starts where the '
      'option kept starts', (tester) async {
    // The app's own type: whether five fit is a question of its widths.
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Pill pill = _card('cinema', 'cinema-destroyed-4');
    Widget phone() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDeckMargin),
      child: _host(pill, {}),
    );
    await tester.pumpWidget(phone());
    await tester.pumpAndSettle();
    await tester.tap(find.text('True'));
    await tester.pumpAndSettle();
    final double row = tester.getCenter(find.text('50%')).dy;
    for (final String level in ['60%', '70%', '80%', '90%']) {
      expect(tester.getCenter(find.text(level)).dy, row, reason: level);
    }

    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(phone());
    await tester.pumpAndSettle();
    await tester.tap(find.text('True'));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('90%')).dy,
      greaterThan(tester.getCenter(find.text('50%')).dy),
      reason: 'wrapped, at this size',
    );
    final double option = tester
        .getTopLeft(
          find
              .ancestor(of: find.text('True'), matching: find.byType(Container))
              .first,
        )
        .dx;
    expect(
      tester.getTopLeft(find.text('How sure are you?')).dx,
      moreOrLessEquals(option, epsilon: 1),
    );
  });

  testWidgets('a card that does not ask turns at once, the option filled', (
    tester,
  ) async {
    final Pill pill = _card('food', 'food-maillard-3', sure: 0);
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    await tester.tap(find.text('False'));
    await tester.pump();
    expect(given[pill.id]?.response, '1');
    expect(given[pill.id]?.confidence, isNull);
    // Turning, the option it turns on is the one ticked.
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('How sure are you?'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('WHAT TO KEEP'), findsOneWidget);
  });

  testWidgets('a number, asking how sure: the arrow pressed takes it at once, '
      'ticked, the field filled and typed in no more; how sure comes in '
      'under the number, which stays', (tester) async {
    final Pill pill = _card('art', 'art-darkroom-3');
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    // At once: ticked, locked, the keyboard's field read only, nothing
    // recorded until how sure is said.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(given, isEmpty);

    await tester.pumpAndSettle();
    expect(find.text('How sure are you?'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('12')).dy,
      lessThan(tester.getTopLeft(find.text('How sure are you?')).dy),
    );
    await tester.tap(find.text('70%'));
    await tester.pumpAndSettle();
    expect(given[pill.id]?.response, '12');
    expect(given[pill.id]?.confidence, 70);
  });

  testWidgets('a number on a card that does not ask turns at once, ticked', (
    tester,
  ) async {
    final Pill pill = _card('art', 'art-darkroom-3', sure: 0);
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    expect(given[pill.id]?.response, '8');
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('How sure are you?'), findsNothing);
  });

  testWidgets('a mark on the ruler, asking how sure: Lock in pressed takes '
      'it at once, ticked, and the ruler takes no more marks; then the '
      'ruler folds away under the figure kept', (tester) async {
    final Pill pill = _card('art', 'art-marble-3');
    final Map<String, Answer> given = {};
    await tester.pumpWidget(_host(pill, given));
    await tester.pumpAndSettle();
    final Finder ruler = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is RulerPainter,
    );
    final Rect r = tester.getRect(ruler);
    await tester.tapAt(Offset(r.left + r.width * 0.3, r.center.dy));
    await tester.pump();
    String figure() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(PlaceItInput),
            matching: find.byType(Text),
          ),
        )
        .first
        .data!;
    final String set = figure();

    await tester.tap(find.text('Lock it in'));
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
    expect(given, isEmpty);
    // A mark elsewhere, while it is taken, moves nothing.
    await tester.tapAt(Offset(r.left + r.width * 0.8, r.center.dy));
    await tester.pump();
    expect(figure(), set);

    await tester.pumpAndSettle();
    expect(ruler, findsNothing);
    expect(find.text(set), findsOneWidget);
    expect(find.text('How sure are you?'), findsOneWidget);
    await tester.tap(find.text('60%'));
    await tester.pumpAndSettle();
    expect(given[pill.id]?.confidence, 60);
  });

  testWidgets('a debate keeps the side taken over "why"', (tester) async {
    final Pill pill = _card('art', 'art-florence-4');
    final TakeASide side = pill.challenge as TakeASide;
    await tester.pumpWidget(_host(pill, {}));
    await tester.pumpAndSettle();
    await tester.tap(find.text(side.positions.first));
    await tester.pumpAndSettle();
    expect(find.text('In one line — why?'), findsOneWidget);
    expect(find.text(side.positions.first), findsOneWidget);
    expect(find.text(side.positions.last), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
