// The outlets under a story, on one line: as many whole names as it holds
// and the rest counted, "7 outlets · BBC News, The Guardian +5". Measured as
// it is drawn, so the count is never what gives way to "…".
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/scene.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/news/news_parts.dart';

import 'core_harness.dart' show loadFonts;

void main() {
  testWidgets('never cut, on any phone from 300 to 430 points across', (
    tester,
  ) async {
    await tester.runAsync(loadFonts);
    final Map<String, Object?> paper =
        jsonDecode(File('tool/news/paper.json').readAsStringSync())
            as Map<String, Object?>;
    // ignore: invalid_use_of_visible_for_testing_member
    NewsPaper.reset();
    NewsPaper.call = () async => null;
    NewsPaper.adopt(paper['date'] as String?, paper['cards']! as List<Object?>);
    final List<NewsScene> scenes = [
      for (final p in NewsPaper.on(DateTime.parse(paper['date']! as String)))
        if (p.scene case final NewsScene s when s.outlets.length > 3) s,
    ];
    expect(scenes, isNotEmpty);

    for (final NewsScene scene in scenes.take(4)) {
      for (double width = 300; width <= 430; width += 10) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('it'),
            theme: buildAstutoTheme(Brightness.dark),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: NewsOutlets(scene: scene),
                ),
              ),
            ),
          ),
        );
        final RenderParagraph line = tester.renderObject(
          find.descendant(
            of: find.byType(NewsOutlets),
            matching: find.byType(RichText),
          ),
        );
        expect(
          line.didExceedMaxLines,
          isFalse,
          reason: '${scene.outlets.length} outlets at $width',
        );
      }
    }
  });
}
