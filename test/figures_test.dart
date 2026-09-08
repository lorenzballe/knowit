import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// The figures a card can carry, checked against the app that has to draw
/// them.
///
/// They are produced outside this repo's language — `tool/illustrations`
/// is Python, and the card generator will run there — so nothing in the
/// Dart build would notice if a figure came back as a black slab, an empty
/// document, or a file the renderer cannot parse. All three have already
/// happened once each while the drawing rules were being worked out. This
/// is where they stop being possible.
void main() {
  final Directory folder = Directory('tool/illustrations/examples');
  final List<File> figures =
      folder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('there are figures to check', () {
    expect(figures, isNotEmpty, reason: 'run tool/illustrations/render.py');
  });

  group('Every figure', () {
    for (final file in figures) {
      final String name = file.uri.pathSegments.last;
      final String svg = file.readAsStringSync();

      test('$name draws something the app can render', () async {
        // The renderer the app uses, doing the work it would do on a card.
        // A file it cannot parse throws here; a file it parses into
        // nothing compiles to a header and little else.
        final ByteData bytes = await SvgStringLoader(svg).loadBytes(null);
        expect(
          bytes.lengthInBytes,
          greaterThan(200),
          reason: '$name compiles to almost nothing — it is probably empty',
        );
      });

      test('$name takes the card\'s colour and the card\'s size', () {
        // One colour, named the one way the app can repaint. A figure that
        // names a colour of its own is a figure that fights the card.
        expect(
          RegExp(r'(fill|stroke)\s*[:=]\s*"?#(?!000")[0-9a-fA-F]{3,8}')
              .hasMatch(svg),
          isFalse,
          reason: '$name carries a colour of its own',
        );
        // No fixed size: a figure takes the slot it is given.
        expect(
          RegExp(r'<svg[^>]*\swidth=').hasMatch(svg),
          isFalse,
          reason: '$name is a fixed size',
        );
        expect(svg, contains('viewBox='));
      });

      test('$name has no page under it', () {
        // The app paints every pixel that is not transparent, so a white
        // page arrives as a slab of ink over the whole card. This is the
        // one failure that looks like the app is broken rather than like
        // the figure is wrong.
        expect(
          RegExp(
            r'(fill\s*[:=]\s*"?\s*(#fff|#ffffff|white))',
            caseSensitive: false,
          ).hasMatch(svg),
          isFalse,
          reason: '$name paints a background',
        );
      });
    }
  });

  testWidgets('a figure sits on a card in the card\'s ink', (tester) async {
    final String svg = figures.first.readAsStringSync();
    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: const Color(0xFF00E5A0),
          child: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: SvgPicture.string(
                svg,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF10100C),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
