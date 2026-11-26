// The line after a card's verdict, on its back (lib/widgets/pill_card.dart):
// what the reader said and how sure, each said once, the card's words
// quoted, the reader's own language around them, and a number never parted
// from its words across a line.
//
//   flutter test test/verdict_line_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

const String nb = ' ';

/// A card in words with options, its back after [given].
Future<void> back(
  WidgetTester tester,
  Pill pill,
  Answer given,
  Locale locale,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 800,
          child: PillCard(pill: pill, flipped: true, given: given),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// The words of the verdict, after its head.
String detailOf(WidgetTester tester, String head) {
  for (final RichText r in tester.widgetList<RichText>(find.byType(RichText))) {
    final String all = r.text.toPlainText();
    if (all.startsWith(head)) return all.substring(all.indexOf('  ') + 2);
  }
  fail('no verdict that starts "$head"');
}

void main() {
  final Pill pick = PillBank.cards.firstWhere(
    (p) => p.challenge is PickOne && !p.hasPage && p.web == null,
  );
  final PickOne options = pick.challenge as PickOne;
  final String wrong = options.options[(options.correct + 1) % 2];
  final AppLocalizations it = lookupAppLocalizations(const Locale('it'));

  testWidgets('wrong, in Italian: what was said, quoted, how sure, and the '
      'right answer, quoted; "hai detto" once', (tester) async {
    await back(
      tester,
      pick,
      Answer('${(options.correct + 1) % 2}', confidence: 60),
      const Locale('it'),
    );
    final String detail = detailOf(tester, it.verdictWrong);
    expect(
      detail,
      'Hai detto «$wrong», sicuro${nb}al${nb}60%$nb· '
      'Giusta: «${options.correctOption}»',
    );
    expect('hai detto'.allMatches(detail.toLowerCase()), hasLength(1));
    expect(detail, isNot(contains(' è ')));
  });

  testWidgets('right, in Italian: how sure, the number held to its words', (
    tester,
  ) async {
    await back(
      tester,
      pick,
      Answer('${options.correct}', confidence: 80),
      const Locale('it'),
    );
    // "all’80%": the article as the number is read.
    expect(detailOf(tester, it.verdictRight), 'Eri sicuro${nb}all’80%.');
  });

  testWidgets('wrong, in English: the same, in English quotes', (tester) async {
    await back(
      tester,
      pick,
      Answer('${(options.correct + 1) % 2}', confidence: 60),
      const Locale('en'),
    );
    expect(
      detailOf(tester, 'Not quite.'),
      'You said “$wrong”, 60%${nb}sure$nb· Right: “${options.correctOption}”',
    );
  });

  testWidgets('wrong without saying how sure: no sureness said', (
    tester,
  ) async {
    await back(
      tester,
      pick,
      Answer('${(options.correct + 1) % 2}'),
      const Locale('it'),
    );
    expect(
      detailOf(tester, it.verdictWrong),
      'Hai detto «$wrong»$nb· Giusta: «${options.correctOption}»',
    );
  });
}
