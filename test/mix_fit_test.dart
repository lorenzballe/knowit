import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/theme.dart';

/// The mix is one screen seen at once: twenty tiles in ten rows, a heading
/// over them and a button under them, and nothing to scroll. On a 375 by
/// 667 phone with the text set to twice its size it still has to fit, in
/// every language, every subject's name on its tile.
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

void main() {
  setUpAll(_loadRealFonts);

  testWidgets('the mix fits a small phone at double text, in every language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final List<String> problems = [];
    for (final Locale locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: MixScreen(onDone: (_) {}, onSkip: () {}),
        ),
      );
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final Object? error = tester.takeException();
      if (error != null) {
        problems.add('[$locale] ${error.toString().split('\n').first}');
      }
      final AppLocalizations l = lookupAppLocalizations(locale);
      for (final MixSubject s in kMixSubjects) {
        // Each tile carries its subject's name in the reader's language.
        final String shown = l.subjectOf(s.name);
        final Finder name = find.text(shown);
        if (name.evaluate().isEmpty) {
          problems.add('[$locale] no tile named $shown');
          continue;
        }
        // The whole name, on one line, inside its tile.
        final RenderParagraph p = tester.renderObject(name);
        if (p.didExceedMaxLines) problems.add('[$locale] $shown is cut');
      }
    }
    expect(problems, isEmpty);
    expect(kMixSubjects.map((s) => s.key), contains('maths'));
    expect(kTopics.keys, contains('maths'));
  });
}
