import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/skill_scores.dart';
import 'package:astuto/data/skills.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/source_foot.dart';

/// The back of every card in the bank, on the smallest phone we design for,
/// fits the card: nothing overflows, nothing has to be scrolled to.
///
/// The rule is the owner's (docs/cards/STILE.md, "Niente scroll"): the card
/// is the screen, and a reveal whose last lines sit below the fold is a
/// reveal whose lesson most readers never reach. The card here is the size
/// the Today deck gives it on a 360×740 phone with ordinary system bars —
/// measured from the app, not guessed — and the fonts are the real ones,
/// because the test font's metrics are nothing like Fraunces'.
///
/// The foot is set the way the build says (lib/widgets/source_foot.dart),
/// so each way being tried that carries Why this card on the back is held
/// to this in a run of its own:
///
///   flutter test test/card_back_fit_test.dart
///   flutter test test/card_back_fit_test.dart --dart-define=SOURCE_FOOT=pill
///   flutter test test/card_back_fit_test.dart --dart-define=SOURCE_FOOT=links
Future<void> _loadRealFonts() async {
  final faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final face in faces.entries) {
    final file = File(face.value);
    if (!file.existsSync()) continue;
    final loader = FontLoader(face.key);
    final bytes = await file.readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// A plausible answer for the card, so the verdict or the reader's own line
/// is on the back as it is after a real answer. A wrong pick, because the
/// wrong verdict is the longer line.
Answer? _answerFor(Pill pill) => switch (pill.challenge) {
  NoChallenge() => null,
  PickOne(:final correct, :final options) => Answer(
    '${(correct + 1) % options.length}',
    confidence: 70,
  ),
  TakeASide() => const Answer(
    '0',
    reason: 'Because the cost lands on the people who had no say in it.',
  ),
  TypeNumber(:final answer) => Answer('${answer * 2 + 1}', confidence: 70),
  Estimate(:final answer) => Answer('${answer * 10}', confidence: 70),
  PageJudged(:final graded) => Answer(
    PageJudged.encode('mid-July', graded ? false : null),
    confidence: graded ? 70 : null,
  ),
};

/// The Today deck's card on each phone we design for, with 24-point system
/// bars: the deck keeps 18 points a side and 220 of the height for the
/// header, the progress and the tab bar (measured in the app).
const Map<String, (Size, Size)> _phones = {
  'small': (Size(360, 740), Size(324, 520)),
  'medium': (Size(390, 844), Size(354, 624)),
  'large': (Size(430, 932), Size(394, 712)),
};

/// The score an answer moved, beside the verdict of every graded back, as
/// wide as it comes: an answer moves a score by 24 at most.
const ScoreMove _move = ScoreMove(
  before: 24,
  after: 0,
  skill: Skill.money,
  on: '',
);

const Size _phone = Size(360, 740);
const Size _card = Size(324, 520);

/// The two smallest phones a reader still carries, with the card the Today
/// deck gives each, measured in the app: a 375×667 phone with its 20-point
/// status bar and no home bar, and the 320-wide phone the same way.
const Map<String, (Size, Size)> _smallest = {
  'a 375×667 phone': (Size(375, 667), Size(339, 475)),
  'the 320-wide phone': (Size(320, 568), Size(284, 376)),
};

/// What a back says, in letters: the answer, the working, the boxes at its
/// foot and the source.
int _letters(Pill p) =>
    p.answer.length +
    p.steps.join().length +
    (p.showsMove ? p.barMove.length : 0) +
    (p.showsAsk ? p.ask.length : 0) +
    p.sourceShort.length;

/// The longer of the two cases a back can open.
int _opened(Pill p) => p.counterpoint.length > p.simply.length
    ? p.counterpoint.length
    : p.simply.length;

/// The cards drawn by the app with the most to say on their backs: the
/// longest as turned, and the longest once a case is opened.
final List<Pill> _fullest = () {
  final List<Pill> native = [
    for (final p in PillBank.cards)
      if (p.web == null) p,
  ];
  final List<Pill> turned = [...native]
    ..sort((a, b) => _letters(b).compareTo(_letters(a)));
  final List<Pill> opened = [...native]
    ..sort(
      (a, b) => (_letters(b) + _opened(b)).compareTo(_letters(a) + _opened(a)),
    );
  return {...turned.take(160), ...opened.take(60)}.toList();
}();

void main() {
  setUpAll(_loadRealFonts);

  Future<void> pumpBack(
    WidgetTester tester,
    Pill pill, {
    double scale = 1,
    Size phone = _phone,
    Size card = _card,
    Locale locale = const Locale('en'),
    bool why = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: MediaQuery(
          data: MediaQueryData(
            size: phone,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: SizedBox.fromSize(
                size: card,
                child: PillCard(
                  // A card laid out again without Why this card starts
                  // turned, not in whatever its last look left open.
                  key: ValueKey((pill.id, why)),
                  pill: pill,
                  flipped: true,
                  given: _answerFor(pill),
                  move: pill.isGraded ? _move : null,
                  onSave: () {},
                  onShare: () {},
                  // As a card of the day has it: Why this card, where the
                  // way being tried puts it on the back (source_foot.dart),
                  // is counted with the rest of the foot.
                  onNote: why ? () {} : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// How far the back would have to scroll, summed over every scrollable on
  /// the card. Zero is the only right answer.
  double scrollNeeded(WidgetTester tester) {
    var total = 0.0;
    for (final e
        in find
            .descendant(
              of: find.byType(PillCard),
              matching: find.byType(Scrollable),
            )
            .evaluate()) {
      final state = (e as StatefulElement).state as ScrollableState;
      final p = state.position;
      if (p.hasContentDimensions && p.axis == Axis.vertical) {
        total += p.maxScrollExtent;
      }
    }
    return total;
  }

  /// Every paragraph on the card that did not get all of its text out.
  List<String> cut(WidgetTester tester) {
    final out = <String>[];
    for (final element
        in find
            .descendant(
              of: find.byType(PillCard),
              matching: find.byType(RichText),
            )
            .evaluate()) {
      final ro = element.renderObject;
      if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
      if (ro.didExceedMaxLines) out.add(ro.text.toPlainText());
    }
    return out;
  }

  /// Anything drawn past the card's bottom edge or the save and share
  /// controls in the corner.
  List<String> collisions(WidgetTester tester) {
    final out = <String>[];
    final Rect card = tester.getRect(find.byType(PillCard));
    final controls = find.descendant(
      of: find.byType(PillCard),
      matching: find.byIcon(Icons.bookmark_border_rounded),
    );
    final Rect? corner = controls.evaluate().isEmpty
        ? null
        : tester.getRect(controls.first).inflate(9);
    for (final element
        in find
            .descendant(
              of: find.byType(PillCard),
              matching: find.byType(RichText),
            )
            .evaluate()) {
      final ro = element.renderObject;
      if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
      final String plain = ro.text.toPlainText();
      if (plain.trim().isEmpty) continue;
      // Icons are paragraphs too; the controls themselves are not a clash.
      if (plain.runes.length == 1 && plain.runes.first > 0xE000) continue;
      final Rect r = ro.localToGlobal(Offset.zero) & ro.size;
      if (r.bottom > card.bottom - 18 + 0.5) {
        out.add('"${_short(plain)}" runs past the card');
      }
      if (corner != null) {
        // The space the lines actually take, not the whole box: a short
        // last line stops well left of the corner.
        for (final box in ro.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: plain.length),
        )) {
          final Rect line = box.toRect().shift(ro.localToGlobal(Offset.zero));
          if (line.overlaps(corner)) {
            out.add('"${_short(plain)}" sits under the save button');
            break;
          }
        }
      }
    }
    return out;
  }

  /// A tap on what may have been set below the fold of a back that
  /// scrolls: it is brought into view first, as a reader would scroll to it.
  Future<void> press(WidgetTester tester, Finder what) async {
    await tester.ensureVisible(what);
    await tester.pump();
    await tester.tap(what, warnIfMissed: false);
    await settle(tester);
  }

  /// Turns [pill] over on [card] and opens everything its back can open,
  /// noting each state that scrolls, cuts a line or runs into the corner.
  Future<void> check(
    WidgetTester tester,
    Pill pill,
    List<String> findings, {
    required Size phone,
    required Size card,
    Locale locale = const Locale('en'),
    bool why = true,
  }) async {
    final AppLocalizations l = lookupAppLocalizations(locale);
    await pumpBack(
      tester,
      pill,
      phone: phone,
      card: card,
      locale: locale,
      why: why,
    );
    await settle(tester);
    void note(String stage) {
      final Object? error = tester.takeException();
      if (error != null) {
        findings.add(
          '${pill.id} ($stage): ${error.toString().split('\n').first}',
        );
      }
      final double scroll = scrollNeeded(tester);
      if (scroll > 0.5) {
        findings.add(
          '${pill.id} ($stage): scrolls ${scroll.toStringAsFixed(0)}',
        );
      }
      for (final line in cut(tester)) {
        findings.add('${pill.id} ($stage): cut "${_short(line)}"');
      }
      for (final line in collisions(tester)) {
        findings.add('${pill.id} ($stage): $line');
      }
    }

    note('turned');
    // A worked solution, every step out.
    final all = find.byKey(const ValueKey('all-steps'));
    if (all.evaluate().isNotEmpty) {
      await press(tester, all);
      note('all steps');
    }
    // The picture, where it waits behind a line, swapped in.
    for (final kind in ['picture', 'scene', 'working']) {
      final open = find.byKey(ValueKey('$kind-toggle'));
      if (open.evaluate().isEmpty) continue;
      await press(tester, open);
      note(kind);
      final whole = find.byKey(const ValueKey('all-steps'));
      if (whole.evaluate().isNotEmpty) {
        await press(tester, whole);
        note('$kind, all steps');
      }
      final back = find.byKey(const ValueKey('back-to-answer'));
      if (back.evaluate().isNotEmpty) await press(tester, back);
    }
    // The other side's case, opened.
    final other = find.text(l.whatTheOtherSideSays);
    if (other.evaluate().isNotEmpty) {
      await press(tester, other);
      note('other side');
    }
    final simply = find.text(l.explainLikeImThree);
    if (simply.evaluate().isNotEmpty) {
      await press(tester, simply);
      note('simply');
    }
  }

  void report(List<String> findings) {
    if (findings.isNotEmpty) {
      // ignore: avoid_print
      print('BACKS ${findings.length}\n${findings.join('\n')}');
    }
  }

  for (final MapEntry(key: name, value: (phone, card)) in _phones.entries) {
    testWidgets('the back of every card fits a $name phone without scrolling', (
      tester,
    ) async {
      tester.view.physicalSize = phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final findings = <String>[];
      for (final pill in PillBank.cards) {
        await check(tester, pill, findings, phone: phone, card: card);
        // With D the foot of a card that is not one of the day's, with no
        // Why this card to open, is of another shape: Go deeper on a line of
        // its own and the source under it, as B sets them. Its back is held
        // to the same.
        if (sourceFoot == SourceFoot.links) {
          final without = <String>[];
          await check(
            tester,
            pill,
            without,
            phone: phone,
            card: card,
            why: false,
          );
          findings.addAll([for (final f in without) 'without Why: $f']);
        }
      }
      report(findings);
      expect(findings, isEmpty, reason: '${findings.length} backs do not fit');
    });
  }

  // The fullest backs on Today, on the two smallest phones a reader still
  // carries, in two of the longer languages: the cards drawn by the app with
  // the most to say, the foot's words in Italian and German. Not every one
  // of them fits there: the longest say more than a card 475 points high
  // holds at the smallest type a back is set in, and the 320-wide phone's
  // card, 376 high, holds few of the fullest. What is held to here is the
  // foot: Why this card costs no back its fit. Whatever a back opens that
  // fits without it fits with it, the foot giving up its row, then the
  // source's words, as the back runs short.
  for (final MapEntry(key: name, value: (phone, card)) in _smallest.entries) {
    for (final Locale locale in const [Locale('it'), Locale('de')]) {
      testWidgets('Why this card costs none of the fullest backs its fit on '
          '$name in ${locale.languageCode}', (tester) async {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // The states a finding is about: "turned", "other side", ...
        Set<String> stages(List<String> findings) => {
          for (final f in findings)
            if (RegExp(r'\(([^)]*)\)').firstMatch(f) case final m?) m.group(1)!,
        };

        final costs = <String>[];
        final long = <String>[];
        for (final pill in _fullest) {
          final withWhy = <String>[];
          await check(
            tester,
            pill,
            withWhy,
            phone: phone,
            card: card,
            locale: locale,
          );
          if (withWhy.isEmpty) continue;
          final without = <String>[];
          await check(
            tester,
            pill,
            without,
            phone: phone,
            card: card,
            locale: locale,
            why: false,
          );
          final Set<String> own = stages(without);
          final List<String> cost = [
            for (final f in withWhy)
              if (!own.contains(stages([f]).first)) f,
          ];
          costs.addAll(cost);
          if (without.isNotEmpty) long.add(pill.id);
        }
        // ignore: avoid_print
        print(
          'FULLEST $name, ${locale.languageCode}: ${long.length} of '
          '${_fullest.length} do not fit with or without Why this card'
          '${long.isEmpty ? '' : ': ${long.join(' ')}'}',
        );
        report(costs);
        expect(
          costs,
          isEmpty,
          reason: 'Why this card costs ${costs.length} backs their fit',
        );
      });
    }
  }

  testWidgets('the back ends on one box unless the card asks for both', (
    tester,
  ) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final Map<String, Object?> json = cardToJson(
      PillBank.cards.firstWhere((p) => p.ask.isNotEmpty && !p.asksSomething),
    );
    Future<void> show(Map<String, Object?> raw) async {
      await pumpBack(tester, cardFromJson(raw));
      await settle(tester);
    }

    // What to keep, and nothing else.
    await show(json);
    expect(find.text('WHAT TO KEEP'), findsOneWidget);
    expect(find.text('ASK YOURSELF'), findsNothing);

    // The question to ask yourself, only in its place.
    await show({...json, 'move': ''});
    expect(find.text('WHAT TO KEEP'), findsNothing);
    expect(find.text('ASK YOURSELF'), findsOneWidget);

    // Both, on a card that opts in — and the flag survives the round trip.
    final both = {...json, 'both': true};
    expect(cardFromJson(both).both, isTrue);
    expect(cardToJson(cardFromJson(both))['both'], isTrue);
    expect(cardToJson(cardFromJson(json)).containsKey('both'), isFalse);
    await show(both);
    expect(find.text('WHAT TO KEEP'), findsOneWidget);
    expect(find.text('ASK YOURSELF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('at the largest text size the back still reaches every line', (
    tester,
  ) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The longest back in the bank, at twice the size. It cannot fit, and
    // it must not be shrunk back down to make it: it scrolls instead.
    final pill = PillBank.cards.reduce(
      (a, b) =>
          (a.answer.length + a.steps.join().length + a.ask.length) >=
              (b.answer.length + b.steps.join().length + b.ask.length)
          ? a
          : b,
    );
    await pumpBack(tester, pill, scale: 2);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(scrollNeeded(tester), greaterThan(0));
    final source = find.textContaining(pill.source, findRichText: true);
    expect(source, findsWidgets);
  });
}

String _short(String s) => s.length > 48 ? '${s.substring(0, 48)}…' : s;
