// The foot of a card's back, being tried (lib/widgets/source_foot.dart): Go
// deeper leads it, the source follows without the word Source, the flag
// that reported the card is off its face, and a card of the day carries the
// way to Why this card beside Go deeper.
//
//   flutter test test/source_foot_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
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

/// A card with more to say than a short phone's card holds at ease.
Pill _long() => cardFromJson({
  'id': 'thinking-foot-long',
  'topic': 'thinking',
  'kind': 'read',
  'difficulty': 'easy',
  'question': 'Why do rare illnesses fool good tests?',
  'answer':
      'Because the illness is rare. A test that is right ninety-nine times '
      'in a hundred still flags one healthy person in a hundred, and when '
      'only one person in ten thousand is ill, the healthy people it flags '
      'outnumber the ill ones about a hundred to one. So a positive result '
      'on its own says less than it seems: the base rate decides how much '
      'it is worth, and a second, independent test is what settles it.',
  'move': 'Ask how common it is first, then how good the test is.',
  'source': 'Geopop, “Il test perfetto” (YouTube, 2021)',
});

Widget _back(
  Pill pill, {
  VoidCallback? onWhy,
  double width = 354,
  double height = 591,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: height,
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

/// The app's own faces: how many lines a foot takes, and when a back runs
/// short of room for it, is a matter of the real letters' widths.
Future<void> _loadRealFonts() async {
  for (final face in const {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  }.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// Where [words] are set in the paragraph [of], as a finger would find them.
Offset wordsAt(WidgetTester tester, Finder of, String words) {
  final RenderParagraph paragraph = tester.renderObject(
    find.descendant(of: of, matching: find.byType(RichText)).first,
  );
  final String plain = paragraph.text.toPlainText(
    includeSemanticsLabels: false,
  );
  final int at = plain.indexOf(words);
  expect(at, isNonNegative, reason: '"$words" in "$plain"');
  final TextBox box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: at, extentOffset: at + words.length),
      )
      .first;
  return paragraph.localToGlobal(box.toRect().center);
}

void main() {
  setUpAll(_loadRealFonts);
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

  testWidgets('a back short of room keeps Why this card: on Go deeper\'s '
      'line, then the two doors alone, never a scroll', (tester) async {
    if (sourceFoot == SourceFoot.stack) return;
    final Pill pill = _long();
    int why = 0;
    Pill? opened;
    GoDeeper.open = (context, p) => opened = p;
    final Finder foot = find.byKey(ValueKey('card-foot-${pill.id}'));
    Finder inFoot(String text) => find.descendant(
      of: foot,
      matching: find.textContaining(text, findRichText: true),
    );
    // The card of a 320-wide phone, made shorter two points at a time: the
    // foot gives its row, then the source's words, and the back never
    // scrolls while the rest of it still fits.
    final Set<String> seen = {};
    for (double height = 560; height >= 260; height -= 2) {
      await tester.pumpWidget(
        _back(pill, onWhy: () => why++, width: 284, height: height),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      final bool scrolls = find
          .descendant(
            of: find.byType(PillCard),
            matching: find.byType(Scrollable),
          )
          .evaluate()
          .any((e) {
            final p =
                ((e as StatefulElement).state as ScrollableState).position;
            return p.axis == Axis.vertical &&
                p.hasContentDimensions &&
                p.maxScrollExtent > 0.5;
          });
      if (scrolls) break;
      // Its row (the source above it), Go deeper's line, or the two doors
      // alone, the source's words gone.
      final String form =
          find
              .byKey(ValueKey('card-foot-line-${pill.id}'))
              .evaluate()
              .isNotEmpty
          ? 'line'
          : inFoot('Geopop').evaluate().isEmpty
          ? 'doors'
          : 'rows';
      if (!seen.add(form)) continue;
      expect(inFoot('Why this card'), findsWidgets, reason: form);
      if (form == 'line') {
        // One paragraph: the source between the two doors, each door
        // opening what it names.
        final Finder line = find.byKey(ValueKey('card-foot-line-${pill.id}'));
        await tester.tapAt(wordsAt(tester, line, 'Why'));
        expect(why, 1);
        await tester.tapAt(wordsAt(tester, line, 'Geopop'));
        expect(opened, pill);
      }
      if (form == 'doors') {
        // The source's words give way; Go deeper opens on them.
        expect(inFoot('Geopop'), findsNothing);
        opened = null;
        await tester.tap(inFoot('Go deeper').first);
        expect(opened, pill);
      }
      // Read out, each door is one, and does what it says.
      if (form != 'rows') {
        expect(
          find.semantics.byLabel(RegExp('^Go deeper. Source: ')),
          findsOne,
        );
        opened = null;
        tester.semantics.tap(find.semantics.byLabel(RegExp('^Go deeper. ')));
        expect(opened, pill);
        final int before = why;
        tester.semantics.tap(find.semantics.byLabel('Why this card'));
        expect(why, before + 1);
      }
    }
    expect(seen, containsAll(['rows', 'line', 'doors']));
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
