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

/// The question side of the cards that ask, on every phone we design for:
/// nothing to scroll, the answers clear of the card's save and share, and
/// no empty band left between the question and its answers.
///
/// The owner's phone showed both faults on cards read again. The question
/// stopped at 28 points and left a band of empty colour above the answers;
/// and the answer a reader took, set beside the word that marks it theirs,
/// wrapped where it had been counted on one line, which pushed the answers
/// down under the save and share and the line under them off the card.
///
///   flutter test test/card_front_fit_test.dart
///   FULL=1 flutter test test/card_front_fit_test.dart   # every card
Future<void> _loadRealFonts() async {
  for (final face in {
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

/// The Today deck's card on each phone we design for (card_back_fit_test).
const Map<String, (Size, Size)> _phones = {
  'small': (Size(360, 740), Size(324, 520)),
  'medium': (Size(390, 844), Size(354, 624)),
  'large': (Size(430, 932), Size(394, 712)),
};

void main() {
  setUpAll(_loadRealFonts);

  /// The cards that ask on their own face, a spread of them unless FULL.
  List<Pill> asking() {
    final List<Pill> all = PillBank.cards
        .where(
          (p) =>
              p.web == null &&
              p.scene == null &&
              p.diagram == null &&
              (p.challenge is PickOne || p.challenge is TakeASide),
        )
        .toList();
    if (Platform.environment['FULL'] == '1') return all;
    return [
      // The two from the owner's phone.
      PillBank.byId('psychology-sleep-debt-1')!,
      PillBank.byId('science-insulation-7')!,
      for (int i = 0; i < all.length; i += all.length ~/ 60) all[i],
    ];
  }

  Future<void> pumpFront(
    WidgetTester tester,
    Pill pill, {
    required Size phone,
    required Size card,
    required bool reread,
  }) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: SizedBox.fromSize(
              size: card,
              child: PillCard(
                key: ValueKey('${pill.id}-$reread'),
                pill: pill,
                flipped: false,
                // Read again: answered, the first answer theirs, and
                // nothing to commit here.
                given: reread ? const Answer('0', confidence: 70) : null,
                onAnswer: reread ? null : (_, _, _) {},
                onSave: () {},
                onShare: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// How far the face would have to scroll.
  double scrollNeeded(WidgetTester tester) {
    var total = 0.0;
    for (final e
        in find
            .descendant(
              of: find.byType(PillCard),
              matching: find.byType(Scrollable),
            )
            .evaluate()) {
      final p = ((e as StatefulElement).state as ScrollableState).position;
      if (p.hasContentDimensions && p.axis == Axis.vertical) {
        total += p.maxScrollExtent;
      }
    }
    return total;
  }

  List<String> options(Pill pill) => switch (pill.challenge) {
    PickOne(:final options) => options,
    TakeASide(:final positions) => positions,
    _ => const [],
  };

  for (final MapEntry(key: name, value: (phone, card)) in _phones.entries) {
    testWidgets('every question side fits a $name phone, answering and read '
        'again: nothing to scroll, the answers clear of the save and share, '
        'no empty band above them', (tester) async {
      addTearDown(tester.view.reset);
      final List<String> findings = [];
      for (final Pill pill in asking()) {
        for (final bool reread in [false, true]) {
          await pumpFront(
            tester,
            pill,
            phone: phone,
            card: card,
            reread: reread,
          );
          final String at = '${pill.id}${reread ? ' (read again)' : ''}';
          final Object? error = tester.takeException();
          if (error != null) findings.add('$at: $error');
          final double scroll = scrollNeeded(tester);
          if (scroll > 0.5) findings.add('$at scrolls by $scroll');
          final List<String> answers = options(pill);
          final Rect first = tester.getRect(
            find
                .ancestor(
                  of: find.text(answers.first),
                  matching: find.byType(GestureDetector),
                )
                .first,
          );
          final Rect last = tester.getRect(
            find
                .ancestor(
                  of: find.text(answers.last),
                  matching: find.byType(GestureDetector),
                )
                .first,
          );
          final Rect save = tester.getRect(
            find.bySemanticsLabel('Save this card'),
          );
          if (last.bottom > save.top) {
            findings.add(
              '$at: last answer under the save by '
              '${(last.bottom - save.top).toStringAsFixed(1)}',
            );
          }
          // The question's last line, and the room between it and the
          // first answer: a short question may leave some, never a band.
          final Rect question = tester.getRect(
            find.textContaining(pill.question, findRichText: true).first,
          );
          final RenderParagraph? words = tester.renderObject(
            find.textContaining(pill.question, findRichText: true).first,
          ) as RenderParagraph?;
          final double drawn = words == null
              ? question.height
              : words
                    .getBoxesForSelection(
                      TextSelection(
                        baseOffset: 0,
                        extentOffset: pill.question.length,
                      ),
                    )
                    .fold<double>(0, (h, b) => b.bottom > h ? b.bottom : h);
          final double band = first.top - (question.top + drawn);
          final double most = card.height * 0.24;
          if (band > most) {
            findings.add(
              '$at: ${band.toStringAsFixed(0)} empty above the '
              'answers',
            );
          }
        }
      }
      expect(findings, isEmpty, reason: findings.join('\n'));
    });
  }
}
