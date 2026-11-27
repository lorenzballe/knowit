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
import 'package:astuto/widgets/pill_card_stack.dart';

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
