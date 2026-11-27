// The picture the day is sent as (lib/widgets/share_day.dart, and the new
// looks in lib/widgets/share_looks.dart), in every look — A as it was, B the
// cards, C light, which ships — and every layout — the cover, the list, the
// story: every one of the five questions is on it whole. None is cut with an
// ellipsis, none runs past its box or off the picture, nothing overflows; on
// the bank's longest questions, on a day in words, on a day the app dealt,
// in languages whose names and dates run long.
//
//   flutter test test/share_picture_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show kPillsPerDay;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/share_day.dart';

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

/// The days tried, by name.
Map<String, List<Pill> Function()> _days() => {
  // The bank's longest questions: its three longest drawn cards and two of
  // its longest in words.
  'longest': () => [
    for (final String id in const [
      'thinking-7',
      'cinema-cgi-7',
      'psychology-naming-feelings-2',
      'maths-st-petersburg',
      'history-kilogram-prefix',
    ])
      PillBank.byId(id)!,
  ],
  // Five in words, the longest 149 letters (the app's deal for 2 December).
  'words': () => dealDay(
    date: DateTime(2026, 12, 2),
    day: 30,
  ).cards.take(kPillsPerDay).toList(),
  // Three drawn and two in words (12 December).
  'dealt': () => dealDay(
    date: DateTime(2026, 12, 12),
    day: 30,
  ).cards.take(kPillsPerDay).toList(),
};

void main() {
  setUpAll(_loadRealFonts);

  const List<String> languages = ['en', 'de', 'ru', 'pt'];
  final DaySummary summary = DaySummary(
    edition: 103,
    squares: '',
    asked: 0,
    right: 0,
    sure: null,
    streak: 128,
  );

  test('C, light, is the picture that ships', () {
    expect(DebugLooks.sharePictureShips, SharePictureLook.c);
    expect(DebugLooks.sharePicturePicked, SharePictureLook.c);
    final DayPicture picture = DayPicture(
      summary: summary,
      five: const [],
      day: DateTime(2026),
    );
    expect(picture.look, SharePictureLook.c);
    // C draws no picture of a card, so none is waited for.
    expect(
      DayPicture.picturesOf(_days()['longest']!(), DayLayout.cover),
      isEmpty,
    );
  });

  for (final SharePictureLook look in SharePictureLook.values) {
    for (final DayLayout layout in DayLayout.values) {
      testWidgets('${look.name}, as a ${layout.name}: every question whole', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(402, 874) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        for (final MapEntry<String, List<Pill> Function()> day
            in _days().entries) {
          final List<Pill> five = day.value();
          expect(five, hasLength(kPillsPerDay));
          for (final String language in languages) {
            final String at =
                '${look.name} ${layout.name} ${day.key} $language';
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: buildAstutoTheme(Brightness.dark),
                home: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: DayPicture.width,
                    height: DayPicture.heightOf(layout),
                    child: Builder(
                      builder: (context) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaler: TextScaler.noScaling),
                        child: DayPicture(
                          summary: summary,
                          five: five,
                          day: DateTime(2026, 9, 30),
                          layout: layout,
                          look: look,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull, reason: at);
            final Rect picture = tester.getRect(find.byType(DayPicture));
            final Iterable<RenderParagraph> words = tester
                .renderObjectList<RenderParagraph>(
                  find.descendant(
                    of: find.byType(DayPicture),
                    matching: find.byType(RichText),
                  ),
                );
            for (final RenderParagraph p in words) {
              expect(
                p.text.toPlainText(),
                isNot(contains('…')),
                reason: '$at: something cut with an ellipsis',
              );
            }
            for (final Pill pill in five) {
              final List<RenderParagraph> set = [
                for (final RenderParagraph p in words)
                  if (p.text.toPlainText() == pill.question) p,
              ];
              expect(set, isNotEmpty, reason: '$at: ${pill.id} is missing');
              for (final RenderParagraph p in set) {
                expect(p.didExceedMaxLines, isFalse, reason: '$at ${pill.id}');
                // As tall as its lines at the width it was given: nothing
                // under the last line it was given room for.
                final TextPainter whole = TextPainter(
                  text: p.text,
                  textDirection: TextDirection.ltr,
                  textScaler: TextScaler.noScaling,
                  locale: Locale(language),
                )..layout(maxWidth: p.size.width + 0.5);
                expect(
                  p.size.height,
                  greaterThanOrEqualTo(whole.height - 0.5),
                  reason: '$at: ${pill.id} cut at its foot',
                );
                whole.dispose();
                final Rect box = MatrixUtils.transformRect(
                  p.getTransformTo(null),
                  Offset.zero & p.size,
                );
                expect(
                  picture.inflate(0.5).contains(box.topLeft) &&
                      picture.inflate(0.5).contains(box.bottomRight),
                  isTrue,
                  reason: '$at: ${pill.id} runs off the picture',
                );
                // Inside every box it is drawn in: no parent clips it.
                RenderObject? child = p;
                for (
                  RenderObject? up = p.parent;
                  up != null && up is! RenderView;
                  up = up.parent
                ) {
                  if (up is RenderBox && child is RenderBox) {
                    final Rect inUp = MatrixUtils.transformRect(
                      p.getTransformTo(up),
                      Offset.zero & p.size,
                    );
                    final bool clips =
                        up is RenderClipRect ||
                        up is RenderClipRRect ||
                        (up is RenderFlex && up.hasSize);
                    if (clips) {
                      expect(
                        (Offset.zero & up.size)
                                .inflate(0.5)
                                .contains(inUp.topLeft) &&
                            (Offset.zero & up.size)
                                .inflate(0.5)
                                .contains(inUp.bottomRight),
                        isTrue,
                        reason:
                            '$at: ${pill.id} runs out of a '
                            '${up.runtimeType}',
                      );
                    }
                  }
                  child = up;
                }
              }
            }
          }
        }
      });
    }
  }
}
