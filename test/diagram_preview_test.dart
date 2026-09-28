// Renders cards' diagrams to PNG files for a person to look at: three
// moments of the animation side by side, on the card's own colour, in the
// app's own fonts. It is a tool, not a check, so it does nothing unless it
// is asked to:
//
//   flutter test test/diagram_preview_test.dart \
//     --dart-define=DIAGRAM_PREVIEW=/some/dir \
//     [--dart-define=DIAGRAM_SOURCE=cards.json] [--dart-define=DIAGRAM_ONLY=id1,id2]
//
// With a source, it draws the diagrams in that file (a JSON list of objects
// with `id` and `diagram`, the card's text taken from the bank); without
// one, every card in the bank that has a diagram.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:astuto/data/card_json.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/diagram_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = String.fromEnvironment('DIAGRAM_PREVIEW');
const _source = String.fromEnvironment('DIAGRAM_SOURCE');
const _only = String.fromEnvironment('DIAGRAM_ONLY');

Map<String, Object?>? _bankCard(String id) {
  for (final dir in Directory('tool/cards/bank').listSync().whereType<Directory>()) {
    final f = File('${dir.path}/$id.json');
    if (f.existsSync()) return (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
  }
  return null;
}

Iterable<Map<String, Object?>> _cards() sync* {
  if (_source.isNotEmpty) {
    for (final e in jsonDecode(File(_source).readAsStringSync()) as List) {
      final m = (e as Map).cast<String, Object?>();
      final card = _bankCard(m['id'] as String);
      if (card == null) continue;
      yield {...card, 'diagram': m['diagram']};
    }
    return;
  }
  for (final dir in Directory('tool/cards/bank').listSync().whereType<Directory>()) {
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final card = (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
      if (card['diagram'] != null) yield card;
    }
  }
}

Future<void> _loadFonts() async {
  for (final family in ['Fraunces', 'Figtree']) {
    final loader = FontLoader(family)..addFont(rootBundle.load('assets/fonts/$family.ttf'));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('diagram previews', () async {
    if (_out.isEmpty) return;
    await _loadFonts();
    Directory(_out).createSync(recursive: true);
    final only = _only.isEmpty ? null : _only.split(',').toSet();
    const width = 330.0;
    const margin = 22.0;
    const moments = [0.35, 0.65, 1.0];
    var drawn = 0;
    for (final raw in _cards()) {
      final id = raw['id'] as String;
      if (only != null && !only.contains(id)) continue;
      final Pill pill;
      try {
        pill = cardFromJson(raw);
      } on FormatException catch (e) {
        stderr.writeln('$id: $e');
        continue;
      }
      final d = pill.diagram;
      if (d == null) {
        stderr.writeln('$id: no diagram this app draws');
        continue;
      }
      final frames = <ui.Image>[];
      for (final at in moments) {
        frames.add(await renderDiagramStill(d, pill.ink, width, at: at, ground: pill.color, margin: margin));
      }
      final fw = frames.first.width.toDouble();
      final fh = frames.first.height.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (var i = 0; i < frames.length; i++) {
        canvas.drawImage(frames[i], ui.Offset(i * (fw + 8), 0), ui.Paint());
      }
      final sheet = await recorder.endRecording().toImage(
        (frames.length * (fw + 8) - 8).toInt(),
        fh.toInt(),
      );
      final png = await sheet.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$id.png').writeAsBytesSync(png!.buffer.asUint8List());
      drawn++;
    }
    stderr.writeln('drew $drawn diagrams into $_out');
  });
}
