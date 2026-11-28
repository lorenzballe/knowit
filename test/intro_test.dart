import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/first_days.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/how_screen.dart';
import 'package:astuto/screens/intro_screen.dart';
import 'package:astuto/theme.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The intro's first page shows a real card's question, not one written for
/// the page: the card that opens a reader's first day.
void main() {
  test('the first page\'s question is the bank\'s, word for word, from the '
      'card that opens the first day', () {
    final card = PillBank.byId(kIntroQuestionCard);
    expect(card, isNotNull, reason: 'the card left the bank');
    expect(card!.question, kIntroQuestion);
    expect(topicKeyForName(card.topic), kIntroQuestionSubject);
    expect(kTopics.containsKey(kIntroQuestionSubject), isTrue);
    // The opener of the first day, which is the first card a new reader
    // reads: the page promises nothing the day does not keep.
    final FirstCard opener = kFirstDays.first;
    expect(opener.id, kIntroQuestionCard);
    expect(opener.day, 1);
  });

  testWidgets('the first page is the question and the promise, and the '
      'second says how the cards are written, with the page that says more', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: IntroScreen(onContinue: () {}, onSignIn: (_) async => false),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const ValueKey('intro-question')), findsOneWidget);
    expect(find.text(kIntroQuestion), findsOneWidget);
    expect(find.text('Five cards a day, two minutes'), findsOneWidget);
    // Plain black: the colour comes in with the second scene.
    AnimatedOpacity ambient() => tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('intro-ambient')),
    );
    expect(ambient().opacity, 0);
    expect(find.byKey(const ValueKey('intro-how')), findsNothing);

    await tester.tapAt(const Offset(200, 120));
    await _settle(tester);
    expect(ambient().opacity, 1);
    // The cards are written with AI and checked, and the page says so.
    expect(
      find.text('Written with AI, then checked, and each one names its source.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('intro-how')));
    await _settle(tester);
    expect(find.byType(HowScreen), findsOneWidget);
  });
}
