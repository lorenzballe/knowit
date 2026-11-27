// The word before a number, said the way the number is read
// (lib/l10n/elision.dart): Italian's articles before 1, 8, 11, the
// eighties, eight hundred, eight thousand…, Spanish's "o" before a number
// read with an o; and the strings the app builds round a number, mended in
// Italian wherever they are built.
//
//   flutter test test/elision_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/l10n/elision.dart';

String it(String text) => elideBeforeNumbers(text, 'it');

void main() {
  group('Italian', () {
    test('the singular articles elide before a number read with a vowel', () {
      expect(
        it('Meglio del 89% dei giocatori'),
        'Meglio dell’89% dei giocatori',
      );
      expect(
        it('L’ha azzeccata il 83% dei lettori'),
        'L’ha azzeccata l’83% dei lettori',
      );
      expect(it('sicuro al 80%'), 'sicuro all’80%');
      expect(it('dal 8 dicembre'), 'dall’8 dicembre');
      expect(it('nel 800'), 'nell’800');
      expect(it('sul 11%'), 'sull’11%');
      expect(it('Il 8% dei lettori'), 'L’8% dei lettori');
      expect(it('DEL 80%'), 'DELL’80%');
    });

    test('the plural ones take another form and keep their space', () {
      expect(
        it('Meglio del 50% dei 8 giocatori'),
        'Meglio del 50% degli 8 giocatori',
      );
      expect(it('dei 11 giocatori'), 'degli 11 giocatori');
      expect(it('ai 80 lettori'), 'agli 80 lettori');
      expect(it('I 8 giocatori'), 'Gli 8 giocatori');
      expect(it('dei 234 giocatori'), 'dei 234 giocatori');
    });

    test('which numbers are read with a vowel', () {
      for (final int n in [
        8,
        11,
        80,
        81,
        85,
        89,
        800,
        812,
        899,
        8000,
        11000,
        80000,
        800000,
        8000000,
        11000000,
      ]) {
        expect(it('il $n'), 'l’$n', reason: '$n');
      }
      // 18 is diciotto; 1000 mille, 100 cento, a million "un milione".
      for (final int n in [
        0,
        2,
        7,
        9,
        10,
        12,
        18,
        19,
        20,
        79,
        90,
        100,
        108,
        180,
        1000,
        1008,
        1800,
        1000000,
        18000,
        100000,
      ]) {
        expect(it('il $n'), 'il $n', reason: '$n');
      }
      // Grouped as Italian groups them.
      expect(it('il 8.000'), 'l’8.000');
      expect(it('il 1.800'), 'il 1.800');
      expect(it('del 8,5%'), 'dell’8,5%');
      expect(it('del 0,8%'), 'del 0,8%');
    });

    test('1 is "uno" as a share, and "il primo" as a day', () {
      expect(
        it('Hai ragione il 1% delle volte'),
        'Hai ragione l’1% delle volte',
      );
      expect(it('del 1,5%'), 'dell’1,5%');
      expect(it('Si rinnova il 1 dic'), 'Si rinnova il 1 dic');
    });

    test('a space that does not break is a space; nothing else is touched', () {
      expect(it('sicuro al 80%'), 'sicuro all’80%');
      expect(it('Natale è il 25 dicembre'), 'Natale è il 25 dicembre');
      expect(it('Hai 8 carte'), 'Hai 8 carte');
      expect(it('Il tuo record'), 'Il tuo record');
      expect(it('«il 8»'), '«l’8»');
      expect(elideBeforeNumbers('il 8', 'fr'), 'il 8');
    });
  });

  group('Spanish', () {
    test('"o" is "u" before a number read with an o', () {
      String es(String text) => elideBeforeNumbers(text, 'es');
      expect(es('o 8 h de documentales'), 'u 8 h de documentales');
      expect(es('7 o 11'), '7 u 11');
      expect(es('o 80 h'), 'u 80 h');
      expect(es('O 800'), 'U 800');
      expect(es('o 18 h'), 'o 18 h');
      expect(es('o 1 h'), 'o 1 h');
      expect(es('o 1000'), 'o 1000');
      expect(es('foco 8'), 'foco 8');
    });
  });

  test(
    'the app\'s own strings, mended in Italian and left alone elsewhere',
    () {
      final AppLocalizations l = lookupAppLocalizations(const Locale('it'));
      expect(
        l.elided(l.dailyBetter(89, 234)),
        'Meglio dell’89% dei 234 giocatori di oggi.',
      );
      expect(
        l.elided(l.dailyBetter(50, 8)),
        'Meglio del 50% degli 8 giocatori di oggi.',
      );
      expect(
        l.elided(l.dailyItemRight(83)),
        'L’ha azzeccata l’83% dei giocatori di oggi',
      );
      expect(
        l.elided(l.crowdGotWrong(11)),
        'Anche l’11% dei lettori l’ha sbagliata',
      );
      expect(l.elided(l.verdictSure(80)), 'Eri sicuro all’80%.');
      expect(l.elided(l.verdictSure(70)), 'Eri sicuro al 70%.');
      final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
      expect(en.elided(en.dailyBetter(89, 234)), en.dailyBetter(89, 234));
      final AppLocalizations es = lookupAppLocalizations(const Locale('es'));
      expect(es.elided(es.journeyOrDocumentaries(8)), 'u 8 h de documentales');
    },
  );
}
