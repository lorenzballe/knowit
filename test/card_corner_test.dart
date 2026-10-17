import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

/// On a 375 by 667 phone, half the multiple-choice cards put their last
/// answer under the card's save and share, where a tap on it saved the
/// card instead of answering it. Every answer now ends above them.
void main() {
  setUpAll(() async {
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
  });

  /// The deck's card on a 375 by 667 phone: 339 wide, 475 high.
  const Size card = Size(339, 475);

  Future<void> front(WidgetTester tester, Pill pill) async {
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
                pill: pill,
                flipped: false,
                onAnswer: (_, _, _) {},
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

  testWidgets('every answer ends above the save and share, on a small phone', (
    tester,
  ) async {
    final List<Pill> picks = PillBank.live
        .where(
          (p) =>
              p.challenge is PickOne && p.scene == null && p.diagram == null,
        )
        .toList();
    // economics-rent-9 is the card the audit caught; the rest a spread.
    final List<Pill> sample = [
      PillBank.byId('economics-rent-9')!,
      for (int i = 0; i < picks.length; i += picks.length ~/ 40) picks[i],
    ];
    final List<String> under = [];
    for (final Pill pill in sample) {
      await front(tester, pill);
      final List<String> options = (pill.challenge as PickOne).options;
      final Rect last = tester.getRect(
        find
            .ancestor(
              of: find.text(options.last),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      final Rect save = tester.getRect(find.bySemanticsLabel('Save this card'));
      if (last.bottom > save.top) under.add('${pill.id} by ${last.bottom - save.top}');
    }
    expect(under, isEmpty);
  });
}
