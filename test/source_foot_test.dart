// The foot of a card's back, being tried (lib/widgets/source_foot.dart): Go
// deeper leads it, the source follows without the word Source, the flag
// that reported the card is off its face, and a card of the day carries the
// way to Why this card beside Go deeper.
//
//   flutter test test/source_foot_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/deeper_sheet.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/source_foot.dart';
import 'package:astuto/widgets/web/page_messages.dart';

Pill _card() => cardFromJson({
  'id': 'thinking-foot',
  'topic': 'thinking',
  'kind': 'read',
  'difficulty': 'easy',
  'question': 'Why do rare illnesses fool good tests?',
  'answer': 'Because the illness is rare.',
  'move': 'Ask how common it is first.',
  'source': 'Geopop, “Il test perfetto” (YouTube, 2021)',
});

Widget _back(Pill pill, {VoidCallback? onWhy}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 354,
        height: 591,
        child: PillCard(
          pill: pill,
          flipped: true,
          onSave: () {},
          onShare: () {},
          onNote: onWhy,
        ),
      ),
    ),
  ),
);

void main() {
  tearDown(() => GoDeeper.open = null);

  testWidgets('Go deeper leads the foot, the source after it, and no flag on '
      'the face', (tester) async {
    final Pill pill = _card();
    Pill? opened;
    GoDeeper.open = (context, p) => opened = p;
    await tester.pumpWidget(_back(pill));
    await tester.pumpAndSettle();

    final Finder foot = find.byKey(ValueKey('card-foot-${pill.id}'));
    expect(foot, findsOneWidget);
    expect(
      find.descendant(
        of: foot,
        matching: find.textContaining('Go deeper', findRichText: true),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: foot,
        matching: find.textContaining(
          'Geopop · YouTube, 2021',
          findRichText: true,
        ),
      ),
      findsWidgets,
    );
    expect(find.textContaining('Source ·', findRichText: true), findsNothing);
    expect(find.byIcon(Icons.outlined_flag_rounded), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^Go deeper. Source: ')), findsOne);

    await tester.tap(foot);
    expect(opened, pill);
  });

  testWidgets('a card of the day carries Why this card beside Go deeper, or '
      'leaves it to its front', (tester) async {
    final Pill pill = _card();
    int why = 0;
    await tester.pumpWidget(_back(pill, onWhy: () => why++));
    await tester.pumpAndSettle();
    final Finder door = find.byKey(ValueKey('card-why-${pill.id}'));
    if (sourceFoot == SourceFoot.stack) {
      expect(door, findsNothing);
      return;
    }
    expect(door, findsOneWidget);
    await tester.tap(door);
    expect(why, 1);

    // A card that is not one of the day's has no Why this card to open.
    await tester.pumpWidget(_back(pill));
    await tester.pumpAndSettle();
    expect(door, findsNothing);
  });

  test('a page is told the foot, Go deeper and Why this card by name', () {
    const PageEnv env = PageEnv(
      foot: 'line',
      deeper: 'Approfondisci',
      why: 'Perché questa carta',
    );
    final Map<String, Object?> json = env.toJson();
    expect(json['foot'], 'line');
    expect(json['deeper'], 'Approfondisci');
    expect(json['why'], 'Perché questa carta');
    expect(env.copyWith(shown: true).toJson()['why'], 'Perché questa carta');
    expect(const PageEnv().toJson().containsKey('why'), isFalse);
  });
}
