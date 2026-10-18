import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

/// A number typed the way the reader's language writes it is the number
/// they meant: "9,455" in English is nine thousand and more, not nine.
void main() {
  group('a typed number, read in its language', () {
    test('English groups thousands with a comma', () {
      expect(TypeNumber.read('9,455', locale: 'en'), '9455');
      expect(TypeNumber.read('1,250', locale: 'en'), '1250');
      expect(TypeNumber.read('1,250,000', locale: 'en'), '1250000');
      expect(TypeNumber.read('-4,000', locale: 'en'), '-4000');
      expect(TypeNumber.read('1,250.5', locale: 'en'), '1250.5');
      expect(TypeNumber.read('9.455', locale: 'en'), '9.455');
      expect(TypeNumber.read('2.5', locale: 'en'), '2.5');
    });

    test('a comma that cannot be a thousands mark is a decimal one', () {
      expect(TypeNumber.read('0,5', locale: 'en'), '0.5');
      expect(TypeNumber.read('12,34', locale: 'en'), '12.34');
    });

    test('Italian and German group with a point and decimal with a comma', () {
      expect(TypeNumber.read('9.455', locale: 'it'), '9455');
      expect(TypeNumber.read('9,455', locale: 'it'), '9.455');
      expect(TypeNumber.read('2,5', locale: 'it'), '2.5');
      expect(TypeNumber.read('1.250,5', locale: 'it'), '1250.5');
      expect(TypeNumber.read('1.000.000', locale: 'de'), '1000000');
      expect(TypeNumber.read('12.5', locale: 'de'), '12.5');
    });

    test('French and Russian group with a space of any width', () {
      expect(TypeNumber.read('9 455', locale: 'fr'), '9455');
      expect(TypeNumber.read('9 455', locale: 'fr'), '9455');
      expect(TypeNumber.read('9 455,5', locale: 'ru'), '9455.5');
    });

    test('the languages that write a point read like English', () {
      for (final locale in ['ja', 'ko', 'zh']) {
        expect(
          TypeNumber.read('9,455', locale: locale),
          '9455',
          reason: locale,
        );
      }
    });

    test('what is not a number is not read as one', () {
      for (final typed in ['', '  ', ',', '-', '1,2,3', '12a', '1.2.3,4']) {
        expect(TypeNumber.read(typed, locale: 'en'), isNull, reason: typed);
      }
    });

    test('the plain form is what the card grades', () {
      const TypeNumber card = TypeNumber(answer: 9455);
      expect(card.accepts(TypeNumber.read('9,455', locale: 'en')!), isTrue);
      expect(card.accepts(TypeNumber.read('9.455', locale: 'it')!), isTrue);
      expect(card.accepts(TypeNumber.read('9,455', locale: 'it')!), isFalse);
    });
  });

  testWidgets('a number typed with a thousands comma is kept as the number', (
    tester,
  ) async {
    final Pill pill = PillBank.byId('economics-real-or-nominal-3')!;
    expect((pill.challenge as TypeNumber).answer, 9455);
    String? kept;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 700,
            child: PillCard(
              pill: pill,
              flipped: false,
              onAnswer: (response, confidence, reason) => kept = response,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '9,455');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    await tester.tap(find.text('70%'));
    await tester.pump();
    expect(kept, '9455');
    expect(pill.challenge.accepts(kept!), isTrue);
  });
}
