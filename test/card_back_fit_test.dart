import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

/// The back of every card in the bank, on the smallest phone we design for,
/// fits the card: nothing overflows, nothing has to be scrolled to.
///
/// The rule is the owner's (docs/cards/STILE.md, "Niente scroll"): the card
/// is the screen, and a reveal whose last lines sit below the fold is a
/// reveal whose lesson most readers never reach. The card here is the size
/// the Today deck gives it on a 360×740 phone with ordinary system bars —
/// measured from the app, not guessed — and the fonts are the real ones,
/// because the test font's metrics are nothing like Fraunces'.
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
};

/// The Today deck's card on a 360×740 phone with 24-point system bars.
const Size _phone = Size(360, 740);
const Size _card = Size(324, 520);

void main() {
  setUpAll(_loadRealFonts);

  Future<void> pumpBack(WidgetTester tester, Pill pill, {double scale = 1}) {
    return tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: MediaQuery(
          data: MediaQueryData(
            size: _phone,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: SizedBox.fromSize(
                size: _card,
                child: PillCard(
                  key: ValueKey(pill.id),
                  pill: pill,
                  flipped: true,
                  given: _answerFor(pill),
                  onSave: () {},
                  onShare: () {},
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
    for (final e in find
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

  testWidgets('the back of every card fits a small phone without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final findings = <String>[];
    for (final pill in PillBank.cards) {
      await pumpBack(tester, pill);
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
        await tester.tap(all);
        await settle(tester);
        note('all steps');
      }
    }

    if (findings.isNotEmpty) {
      // ignore: avoid_print
      print('BACKS ${findings.length}\n${findings.join('\n')}');
    }
    expect(findings, isEmpty, reason: '${findings.length} backs do not fit');
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
