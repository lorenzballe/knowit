// Photographs the picture the day is sent as (lib/widgets/share_day.dart,
// lib/widgets/share_looks.dart), in each of its looks and layouts, at the
// size it leaves the phone: laid out 360 across and made at three times
// that, 1080 pixels wide, as the sheet makes it.
//
//   flutter test tool/share_day_shots.dart
//   LOOKS=bc DAYS=dec12 flutter test tool/share_day_shots.dart
//
// A camera, not a check, like the other shots: it lives outside test/ so CI
// never runs it. The pictures land in tool/shots/shareday/, named
// <look>-<day>-<layout>.png, to be looked at, not kept; SHOTS (a folder),
// LANG_SHOT (a language), LOOKS (letters, all three where none) and DAYS
// (names, all where none) move them. The cards are drawn with their real
// pictures, from web/cards/thumbs/. The days are three the app really
// dealt (a reader's thirtieth day, so not the first week's drawn lean),
// and three put together to try the picture: an ordinary day, the bank's
// longest questions, and a day in words.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:astuto/widgets/web/card_thumb.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// A picture of the bank's own, from the folder the site serves them from:
/// small, shelf or large, as the address asks.
final Map<String, ImageProvider> _pictures = {};
ImageProvider _picture(Uri url) {
  final List<String> path = url.pathSegments;
  final String rel = path.sublist(path.indexOf('cards') + 1).join('/');
  return _pictures.putIfAbsent(rel, () {
    final File file = File('web/cards/$rel');
    return MemoryImage(
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
    );
  });
}

/// The days the app dealt, by name: the date, for a reader on their
/// thirtieth day. December 12: three drawn and two in words, short and long
/// questions. December 4: Thinking's white beside Philosophy's deep blue and
/// Economics' yellow, two drawn. December 2: five in words, the longest
/// question 149 letters.
final Map<String, DateTime> _dealt = {
  'dec12': DateTime(2026, 12, 12),
  'dec04': DateTime(2026, 12, 4),
  'dec02': DateTime(2026, 12, 2),
};

/// The days put together, by name: five cards each, in the order dealt.
const Map<String, List<String>> _days = {
  // An ordinary day: three drawn cards and two in words, their questions
  // of the length the bank's usually are, each of another subject.
  'typical': [
    'history-greenland-compact',
    'art-darkroom-8',
    'human_body-acetaldehyde-liver',
    'life-death-penalty-homosexuality',
    'cinema-budgets-6',
  ],
  // The longest questions the bank deals: its three longest drawn cards,
  // with their pictures, and two of its longest in words, each of a subject
  // of its own.
  'long': [
    'thinking-7',
    'cinema-cgi-7',
    'psychology-naming-feelings-2',
    'maths-st-petersburg',
    'history-kilogram-prefix',
  ],
  // A day with no drawing at all: five cards in words, a little longer
  // than most, so the cover's large card is a card in words too.
  'words': [
    'art-edited-photos-3',
    'cinema-flops-2',
    'economics-bundles-3',
    'food-portion-sizes-2',
    'human_body-calories-burned-3',
  ],
};

/// The picture as the sheet makes it (ShareDay's _capture): its boundary at
/// three times its size, as a PNG.
Future<void> _save(WidgetTester tester, String path) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(const ValueKey('picture')),
  );
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_loadFonts);
  final String out = Platform.environment['SHOTS'] ?? 'tool/shots/shareday';
  final String looks = Platform.environment['LOOKS'] ?? 'abc';
  final Set<String>? only = Platform.environment['DAYS']?.split(',').toSet();
  final Map<String, (DateTime, List<Pill> Function())> days = {
    for (final MapEntry<String, DateTime> d in _dealt.entries)
      d.key: (
        d.value,
        () => dealDay(date: d.value, day: 30).cards.take(kPillsPerDay).toList(),
      ),
    for (final MapEntry<String, List<String>> d in _days.entries)
      d.key: (
        DateTime(2026, 11, 25),
        () => [for (final String id in d.value) PillBank.byId(id)!],
      ),
  };

  for (final SharePictureLook look in SharePictureLook.values) {
    if (!looks.contains(look.name)) continue;
    for (final MapEntry<String, (DateTime, List<Pill> Function())> d
        in days.entries) {
      if (only != null && !only.contains(d.key)) continue;
      final DateTime day = d.value.$1;
      for (final DayLayout layout in DayLayout.values) {
        testWidgets('${look.name}: ${d.key} as a ${layout.name}', (
          tester,
        ) async {
          CardThumb.image = _picture;
          final was = FlutterError.onError;
          FlutterError.onError = (d) {
            debugPrint(d.toString());
            was?.call(d);
          };
          addTearDown(() => FlutterError.onError = was);
          tester.view.physicalSize = const Size(402, 874) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final List<Pill> five = d.value.$2();
          final DaySummary summary = DaySummary(
            edition: editionOf(day),
            squares: '',
            asked: 0,
            right: 0,
            sure: null,
            streak: 12,
          );
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: Locale(Platform.environment['LANG_SHOT'] ?? 'en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAstutoTheme(Brightness.dark),
              home: Scaffold(
                backgroundColor: Colors.transparent,
                body: Align(
                  alignment: Alignment.topLeft,
                  // As the sheet lays it out: one size on every phone, and the
                  // reader's text size left out of it.
                  child: SizedBox(
                    width: DayPicture.width,
                    height: DayPicture.heightOf(layout),
                    child: RepaintBoundary(
                      key: const ValueKey('picture'),
                      child: Builder(
                        builder: (context) => MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(textScaler: TextScaler.noScaling),
                          child: DayPicture(
                            summary: summary,
                            five: five,
                            day: day,
                            layout: layout,
                            look: look,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          // Every picture on it decoded before the photograph.
          await tester.runAsync(() async {
            final BuildContext context = tester.element(
              find.byType(DayPicture),
            );
            for (final ImageProvider picture in DayPicture.picturesOf(
              five,
              layout,
              look: look,
            )) {
              await precacheImage(
                picture,
                context,
                onError: (_, _) {},
              ).timeout(const Duration(seconds: 10), onTimeout: () {});
            }
          });
          for (int f = 0; f < 10; f++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          final Object? broke = tester.takeException();
          if (broke is FlutterError) debugPrint(broke.toStringDeep());
          expect(broke, isNull);
          await _save(tester, '$out/${look.name}-${d.key}-${layout.name}.png');
        });
      }
    }
  }
}
