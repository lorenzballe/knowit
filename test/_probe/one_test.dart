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
import 'package:astuto/widgets/reveal_body.dart';

void main() {
  setUpAll(() async {
    for (final f in {'Fraunces': 'assets/fonts/Fraunces.ttf','Figtree': 'assets/fonts/Figtree.ttf'}.entries) {
      final l = FontLoader(f.key); l.addFont(Future.value(ByteData.view(Uint8List.fromList(File(f.value).readAsBytesSync()).buffer))); await l.load();
    }
  });
  testWidgets('one', (tester) async {
    tester.view.physicalSize = const Size(360, 740); tester.view.devicePixelRatio = 1;
    final pill = PillBank.cards.firstWhere((p) => p.id == const String.fromEnvironment('ID', defaultValue: 'art-abstraction-4'));
    debugRevealBlocks = (b, h) => print('blocks $b sum ${b.fold(0.0,(a,c)=>a+c)} of $h');
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(body: Center(child: SizedBox(width: 324, height: 520, child: PillCard(pill: pill, flipped: true, given: pill.asksSomething ? const Answer('0', confidence: 70) : null, onSave: () {}))))));
    for (var i=0;i<10;i++) { await tester.pump(const Duration(milliseconds: 100)); }
    final col = find.descendant(of: find.byType(CardReveal), matching: find.byType(Column)).first;
    final ro = tester.renderObject(col) as RenderBox;
    ro.visitChildren((c) => print('child ${(c as RenderBox).size.height}'));
    tester.takeException();
  });
}
