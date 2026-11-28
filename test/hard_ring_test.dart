// A hard card, seen as hard (lib/widgets/hard_ring.dart): ringed, as the app
// ships (DebugLooks.hardCardsShips), a hard card in words is dark, ringed in
// its subject's colour, its subject's name in it, with HARD in its head,
// front and back; on the day paper a pale colour takes its darker tone, as
// Explore's shelf of the hardest does. As today, picked in the developer
// tools, or on a card that is not hard, none of it; without the tools, the
// look that ships whatever the phone kept. A drawn card's page is told the
// ringed colours only when ringed, its ink one that small words read in.
//
//   flutter test test/hard_ring_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/card_edge.dart' show colourContrast;
import 'package:astuto/widgets/hard_ring.dart';
import 'package:astuto/widgets/pill_card.dart';

Future<void> _loadRealFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

final Finder _ring = find.byKey(const ValueKey('hard-ring'));
final Finder _tag = find.byKey(const ValueKey('hard-tag'));

/// [pill], front or back, on the deck's size on a 390 by 844 phone.
Widget _card(Pill pill, {bool back = false, bool dark = true}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 354,
        height: 624,
        child: PillCard(
          pill: pill,
          flipped: back,
          given: back ? const Answer('0', confidence: 70) : null,
          onSave: () {},
          onShare: () {},
        ),
      ),
    ),
  ),
);

/// The colour the card's name in its head is set in.
Color? _nameInk(WidgetTester tester, Pill pill) {
  final Text name = tester.widget<Text>(
    find.text(pill.topic.toUpperCase()).first,
  );
  return name.style?.color;
}

void main() {
  setUpAll(_loadRealFonts);

  late bool tools;
  setUp(() => tools = debugToolsOn);
  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
  });

  // A pick in Philosophy's deep blue, and one in Economics' pale yellow,
  // both hard, both in words; and a card that is not hard.
  final Pill deep = PillBank.byId('philosophy-socrates-8')!;
  final Pill pale = PillBank.byId('economics-hyperinflation-9')!;
  final Pill easy = PillBank.cards.firstWhere(
    (p) =>
        p.difficulty != Difficulty.hard &&
        p.web == null &&
        p.challenge is PickOne,
  );

  test('the cards tried are what they say', () {
    expect(deep.difficulty, Difficulty.hard);
    expect(pale.difficulty, Difficulty.hard);
    expect(deep.web, isNull);
    expect(pale.web, isNull);
  });

  test('ringed is the look that ships', () {
    expect(DebugLooks.hardCardsShips, HardCardLook.ringed);
    expect(DebugLooks.hardCards.value, HardCardLook.ringed);
    debugToolsOn = false;
    expect(DebugLooks.hardCardsPicked, HardCardLook.ringed);
    expect(HardRing.on(deep), isTrue);
    expect(HardRing.on(easy), isFalse);
  });

  testWidgets('as today, a hard card is like any other: no ring, no HARD', (
    tester,
  ) async {
    debugToolsOn = true;
    DebugLooks.hardCards.value = HardCardLook.today;
    for (final bool back in [false, true]) {
      await tester.pumpWidget(_card(deep, back: back));
      await tester.pump();
      expect(_ring, findsNothing);
      expect(_tag, findsNothing);
      expect(_nameInk(tester, deep), deep.ink.withValues(alpha: 0.72));
    }
  });

  testWidgets('ringed: dark, ringed in its colour, its name in it, HARD in its '
      'head, front and back', (tester) async {
    debugToolsOn = true;
    DebugLooks.hardCards.value = HardCardLook.ringed;
    for (final bool back in [false, true]) {
      await tester.pumpWidget(_card(deep, back: back));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_ring, findsOneWidget, reason: back ? 'back' : 'front');
      expect(_tag, findsOneWidget, reason: back ? 'back' : 'front');
      expect(find.text('HARD'), findsOneWidget);
      final BoxBorder? ring =
          (tester.widget<DecoratedBox>(_ring).decoration as BoxDecoration)
              .border;
      expect((ring! as Border).top.color, deep.color);
      expect(_nameInk(tester, deep), deep.color);
      // The card itself on the night ground, its ink the page's.
      final PillCard drawn = tester.widget<PillCard>(
        find.byType(PillCard).last,
      );
      expect(drawn.pill.color, const Color(0xFF0B0B0D));
      expect(drawn.pill.ink, Palette.dark.ink);
      expect(drawn.pill.question, deep.question);
      expect(drawn.pill.challenge, same(deep.challenge));
    }
  });

  testWidgets('ringed on the day paper: a pale colour takes its darker tone, '
      'on the raised paper', (tester) async {
    debugToolsOn = true;
    DebugLooks.hardCards.value = HardCardLook.ringed;
    await tester.pumpWidget(_card(pale, dark: false));
    await tester.pump();
    expect(_ring, findsOneWidget);
    expect(_tag, findsOneWidget);
    final Color accent = HardRing.accentOf(pale, Palette.light);
    expect(accent, isNot(pale.color));
    expect(accent.computeLuminance(), lessThan(pale.color.computeLuminance()));
    expect(_nameInk(tester, pale), accent);
    final PillCard drawn = tester.widget<PillCard>(find.byType(PillCard).last);
    expect(drawn.pill.color, Palette.light.surfaceRaised);
    expect(drawn.pill.ink, Palette.light.ink);
    // A deep colour keeps its own.
    expect(HardRing.accentOf(deep, Palette.light), deep.color);
  });

  testWidgets('a card that is not hard is never ringed', (tester) async {
    debugToolsOn = true;
    DebugLooks.hardCards.value = HardCardLook.ringed;
    await tester.pumpWidget(_card(easy));
    await tester.pump();
    expect(_ring, findsNothing);
    expect(_tag, findsNothing);
  });

  testWidgets('without the tools, a look kept on the phone is never read: '
      'ringed, as it ships', (tester) async {
    debugToolsOn = false;
    DebugLooks.hardCards.value = HardCardLook.today;
    await tester.pumpWidget(_card(deep));
    await tester.pump();
    expect(_ring, findsOneWidget);
    expect(_tag, findsOneWidget);
  });

  testWidgets('a drawn page is told the ringed colours only when ringed', (
    tester,
  ) async {
    final Pill drawn = PillBank.cards.firstWhere(
      (p) => p.difficulty == Difficulty.hard && p.web != null,
    );
    debugToolsOn = true;
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    DebugLooks.hardCards.value = HardCardLook.today;
    expect(HardRing.pageOf(context, drawn), isNull);
    DebugLooks.hardCards.value = HardCardLook.ringed;
    final Map<String, Object?> hard = HardRing.pageOf(context, drawn)!.toJson();
    expect(hard['c'], '#0b0b0d');
    expect(hard['q'], '#f2f1ec');
    expect(hard['label'], 'HARD');
    expect(HardRing.pageOf(context, easy), isNull);
  });

  // The ink a ringed page draws its drawing and its small labels in, as
  // tool/cards/hard_env.cjs gives the checker and the camera the same.
  test('a ringed page\'s ink reads on its ground, at night and on paper', () {
    for (final MapEntry<String, Color> subject in {
      'economics': const Color(0xFFFFE600),
      'history': const Color(0xFFFFB000),
      'maths': const Color(0xFF0E9A70),
      'medicine': const Color(0xFFFF3B30),
      'science': const Color(0xFF00E5A0),
      'space': const Color(0xFF2B5CFF),
      'technology': const Color(0xFF00A6FF),
      'cinema': const Color(0xFF6E3AFF),
      'thinking': const Color(0xFFF2F1EC),
      'food': const Color(0xFFFF7A1A),
    }.entries) {
      for (final Palette p in [Palette.dark, Palette.light]) {
        final Pill pill = deep.withColours(color: subject.value, ink: p.ink);
        final Color ink = HardRing.inkOf(HardRing.accentOf(pill, p), p);
        expect(
          colourContrast(ink, HardRing.groundOf(p)),
          greaterThanOrEqualTo(HardRing.reads),
          reason: '${subject.key} on the ${p.isDark ? 'night' : 'day'} paper',
        );
      }
    }
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
    Color inkFor(Color colour, Palette p) => HardRing.inkOf(
      HardRing.accentOf(deep.withColours(color: colour, ink: p.ink), p),
      p,
    );
    // The same as hard_env.cjs: a deep colour lifted at night, a light one
    // taken down by day; one that reads already kept.
    expect(hex(inkFor(const Color(0xFF2B5CFF), Palette.dark)), '#809dff');
    expect(hex(inkFor(const Color(0xFF00A6FF), Palette.light)), '#007bbd');
    expect(hex(inkFor(const Color(0xFFFFE600), Palette.light)), '#827500');
    expect(hex(inkFor(const Color(0xFFFFB000), Palette.light)), '#9e6d00');
    expect(hex(inkFor(const Color(0xFFFF3B30), Palette.dark)), '#ff3b30');
  });
}
