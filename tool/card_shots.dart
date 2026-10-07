// Photographs single cards in the app's own widget, on three phones, before
// and after they are answered — the Flutter twin of tool/cards/card_check.cjs.
//
//   flutter test tool/card_shots.dart --update-goldens \
//     [--dart-define=CARDS=id1,id2] [--dart-define=CARDS_SOURCE=extra.json]
//
// Without CARDS it takes one card of every kind from the bank. With a
// source, cards in that JSON list (whole cards, or `{id, scene}` patches on
// bank cards) are photographed instead, so a new format can be looked at
// before it is in the bank. Pictures land in tool/shots/cards/.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card.dart';

const _only = String.fromEnvironment('CARDS');
const _source = String.fromEnvironment('CARDS_SOURCE');

const _phones = {
  'small': Size(360, 740),
  'medium': Size(390, 844),
  'large': Size(430, 932),
};

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

Map<String, Map<String, Object?>> _bank() {
  final out = <String, Map<String, Object?>>{};
  for (final dir in Directory(
    'tool/cards/bank',
  ).listSync().whereType<Directory>()) {
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final card = (jsonDecode(f.readAsStringSync()) as Map)
          .cast<String, Object?>();
      if (card['disabled'] == true) continue;
      out[card['id'] as String] = card;
    }
  }
  return out;
}

List<Pill> _cards() {
  final bank = _bank();
  if (_source.isNotEmpty) {
    return [
      for (final e in jsonDecode(File(_source).readAsStringSync()) as List)
        cardFromJson({
          ...?bank[(e as Map)['id']],
          ...e.cast<String, Object?>(),
        }),
    ];
  }
  if (_only.isNotEmpty) {
    return [for (final id in _only.split(',')) cardFromJson(bank[id]!)];
  }
  final seen = <String>{};
  return [
    for (final c in bank.values)
      if (seen.add('${c['kind']}${c['diagram'] != null}')) cardFromJson(c),
  ];
}

/// One card on the black ground, sized as the deck sizes it: the Today deck
/// leaves 220 points of the screen's height to the bars and the header and
/// 18 a side, so a 360×740 phone gets a 324×520 card.
class _Frame extends StatefulWidget {
  final Pill pill;
  const _Frame(this.pill);

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  Answer? _given;
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 116, 18, 104),
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
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final pill in _cards()) {
    for (final phone in _phones.entries) {
      testWidgets('${pill.id} on ${phone.key}', (tester) async {
        final view = tester.view;
        view.physicalSize = phone.value * 3;
        view.devicePixelRatio = 3;
        addTearDown(view.resetPhysicalSize);
        addTearDown(view.resetDevicePixelRatio);

        Future<void> settle() async {
          for (var f = 0; f < 16; f++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        Future<void> shoot(String stage) => expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('shots/cards/${pill.id}-${phone.key}-$stage.png'),
        );

        await tester.pumpWidget(_Frame(pill));
        await settle();
        await shoot('start');

        // Play it through the way a reader would.
        final ruler = find.bySemanticsLabel('Your estimate');
        if (ruler.evaluate().isNotEmpty) {
          final box = tester.getRect(ruler.first);
          await tester.dragFrom(
            box.centerLeft + const Offset(20, 0),
            Offset(box.width * 0.55, 0),
          );
          await settle();
          await shoot('placed');
          await tester.tap(find.text('LOCK IT IN'));
          await settle();
        } else if (pill.challenge is PickOne || pill.challenge is TakeASide) {
          final options = switch (pill.challenge) {
            PickOne(:final options) => options,
            TakeASide(:final positions) => positions,
            _ => const <String>[],
          };
          await tester.tap(find.text(options.first).first);
          await settle();
        } else if (pill.challenge is NoChallenge) {
          await tester.tap(find.byType(PillCard));
          await settle();
          await shoot('end');
          return;
        } else if (pill.challenge case TypeNumber(:final answer)) {
          // A wrong number, so the verdict is the longer line.
          await tester.enterText(find.byType(TextField).first, '${answer * 2}');
          await settle();
          await tester.tap(find.bySemanticsLabel('Check my answer'));
          await settle();
        } else {
          return;
        }
        await shoot('asked');
        // The confidence step, then the reveal.
        final sure = find.text('70%');
        if (sure.evaluate().isNotEmpty) {
          await tester.tap(sure.first);
          await settle();
        }
        // A debate asks why before it shows the other side: one line, as a
        // reader would write it.
        final why = find.byType(TextField);
        if (pill.challenge is TakeASide && why.evaluate().isNotEmpty) {
          await tester.enterText(
            why.first,
            'Because the cost lands on people who had no say in it.',
          );
          await settle();
          await tester.tap(find.text('Now show me the other side'));
          await settle();
        }
        await shoot('end');
        // Whatever waits behind a line on a back short of room, opened.
        for (final kind in ['picture', 'scene', 'working']) {
          final open = find.byKey(ValueKey('$kind-toggle'));
          if (open.evaluate().isEmpty) continue;
          await tester.tap(open);
          await settle();
          await shoot(kind);
          if (kind != 'working') {
            await tester.tap(find.byKey(const ValueKey('back-to-answer')));
            await settle();
          }
        }
        // A worked solution, walked two steps further.
        final next = find.byKey(const ValueKey('next-step'));
        if (next.evaluate().isNotEmpty) {
          for (var k = 0; k < 2 && next.evaluate().isNotEmpty; k++) {
            await tester.tap(next);
            await settle();
          }
          await shoot('steps');
        }
      });
    }
  }
}
