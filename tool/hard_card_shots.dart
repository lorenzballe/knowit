// Photographs hard cards in words in the app's own widget, as today and
// ringed (lib/widgets/hard_ring.dart, DebugLooks.hardCards): on the night
// paper and on the day one, the question and, once answered, the back. A
// pick of a deep subject and of a pale one, a number to type, a ruler to
// place it on.
//
//   flutter test tool/hard_card_shots.dart
//   CARDS=philosophy-socrates-8 flutter test tool/hard_card_shots.dart
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// pictures land in tool/shots/hard/, named
// <id>-<night|day>-<today|ringed>-<front|back>.png, to be looked at, not
// kept; SHOTS moves them. Each is the card on the deck's own size on a
// 390 by 844 phone, with the page round it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/form_shelves.dart' show SharpRow;
import 'package:astuto/widgets/pill_card.dart';

/// The cards photographed, unless CARDS names others: a pick in
/// Philosophy's deep blue, a pick in Economics' yellow, a number in Maths'
/// jade, and a ruler in Thinking's white.
const List<String> _cards = [
  'philosophy-socrates-8',
  'economics-hyperinflation-9',
  'maths-risk-8',
  'thinking-e2',
];

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

Pill _card(String id) {
  for (final dir in Directory(
    'tool/cards/bank',
  ).listSync().whereType<Directory>()) {
    final File f = File('${dir.path}/$id.json');
    if (f.existsSync()) {
      return cardFromJson(
        (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>(),
      );
    }
  }
  throw StateError('no card $id');
}

/// One card on the page, the deck's size on a 390 by 844 phone.
class _Frame extends StatefulWidget {
  const _Frame(this.pill, {required this.dark});

  final Pill pill;
  final bool dark;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  Answer? _given;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    final Brightness b = widget.dark ? Brightness.dark : Brightness.light;
    final Palette p = widget.dark ? Palette.dark : Palette.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(b),
      home: Scaffold(
        backgroundColor: p.surface,
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('shot'),
            child: ColoredBox(
              color: p.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 354,
                  height: 624,
                  child: GestureDetector(
                    onTap: widget.pill.asksSomething
                        ? null
                        : () => setState(() => _flipped = !_flipped),
                    child: PillCard(
                      pill: widget.pill,
                      flipped: _flipped,
                      given: _given,
                      onSave: () {},
                      onShare: () {},
                      onAnswer: (r, c, w) => setState(() {
                        _given = Answer(r, confidence: c, reason: w);
                        _flipped = true;
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _save(WidgetTester tester, String path) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(const ValueKey('shot')),
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
  final String out = Platform.environment['SHOTS'] ?? 'tool/shots/hard';
  final List<String> ids = Platform.environment['CARDS']?.split(',') ?? _cards;

  // What the ring is taken from: Explore's shelf of the hardest, the same
  // cards, on either paper (explore-night.png, explore-day.png).
  for (final bool dark in [true, false]) {
    testWidgets('Explore\'s shelf, ${dark ? 'night' : 'day'}', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final Palette p = dark ? Palette.dark : Palette.light;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
          home: Scaffold(
            backgroundColor: p.surface,
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: const ValueKey('shot'),
                child: ColoredBox(
                  color: p.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: 860,
                      child: SharpRow(
                        pills: [for (final String id in _cards) _card(id)],
                        isRead: (_) => false,
                        onOpen: (_, _) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await _save(tester, '$out/explore-${dark ? 'night' : 'day'}.png');
    });
  }

  for (final String id in ids) {
    for (final bool dark in [true, false]) {
      for (final HardCardLook look in HardCardLook.values) {
        final String name = '$id-${dark ? 'night' : 'day'}-${look.name}';
        testWidgets(name, (tester) async {
          debugToolsOn = true;
          DebugLooks.hardCards.value = look;
          addTearDown(() {
            debugToolsOn = false;
            DebugLooks.hardCards.value = HardCardLook.today;
          });
          tester.view.physicalSize = const Size(390, 844) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final Pill pill = _card(id);

          Future<void> settle() async {
            for (var f = 0; f < 16; f++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }

          await tester.pumpWidget(_Frame(pill, dark: dark));
          await settle();
          expect(tester.takeException(), isNull);
          await _save(tester, '$out/$name-front.png');

          // Played through as a reader would, to its back.
          final ruler = find.bySemanticsLabel('Your estimate');
          if (ruler.evaluate().isNotEmpty) {
            final Rect box = tester.getRect(ruler.first);
            await tester.dragFrom(
              box.centerLeft + const Offset(20, 0),
              Offset(box.width * 0.55, 0),
            );
            await settle();
            await tester.tap(find.text('Lock it in'));
            await settle();
          } else if (pill.challenge case PickOne(:final options)) {
            await tester.tap(find.text(options.first).first);
            await settle();
          } else if (pill.challenge case TypeNumber(:final answer)) {
            await tester.enterText(
              find.byType(TextField).first,
              '${answer * 2}',
            );
            await settle();
            await tester.tap(find.bySemanticsLabel('Check my answer'));
            await settle();
          } else if (pill.challenge is NoChallenge) {
            await tester.tap(find.byType(PillCard));
            await settle();
          }
          final sure = find.text('70%');
          if (sure.evaluate().isNotEmpty) {
            await tester.tap(sure.first);
            await settle();
          }
          expect(tester.takeException(), isNull);
          await _save(tester, '$out/$name-back.png');
        });
      }
    }
  }
}
