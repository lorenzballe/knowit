// The light round the line of the day (widgets/glow_outline.dart): it moves
// only while someone can see it, and stands still for a reader who asked for
// less motion.
//
//   flutter test test/glow_outline_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/theme.dart';
import 'package:astuto/widgets/glow_outline.dart';

Widget _page(Widget child, {bool calm = false, bool paper = false}) =>
    MaterialApp(
      theme: buildAstutoTheme(paper ? Brightness.light : Brightness.dark),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: calm),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

Widget _card(GlowOutlineStyle style) =>
    GlowOutline(style: style, child: const SizedBox(width: 300, height: 200));

/// Whether anything still asks the clock for the next frame.
bool _moving(WidgetTester tester) => tester.binding.transientCallbackCount > 0;

Future<void> _frames(WidgetTester tester, int n) async {
  for (int f = 0; f < n; f++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  for (final GlowOutlineStyle style in GlowOutlineStyle.values) {
    testWidgets('${style.name}: moves while it is seen, stops asking for '
        'frames once it is not painted, and moves again when it is', (
      tester,
    ) async {
      bool hidden = false;
      late StateSetter set;
      await tester.pumpWidget(
        _page(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return Offstage(offstage: hidden, child: _card(style));
            },
          ),
        ),
      );
      await _frames(tester, 5);
      expect(_moving(tester), isTrue);

      set(() => hidden = true);
      await _frames(tester, 8);
      expect(_moving(tester), isFalse);

      set(() => hidden = false);
      await _frames(tester, 2);
      expect(_moving(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${style.name}: still for a reader who asked for less '
        'motion, at night and on paper', (tester) async {
      for (final bool paper in [false, true]) {
        // A fresh app each time: one whose theme changed would be busy
        // fading between the two.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(_page(_card(style), calm: true, paper: paper));
        await _frames(tester, 3);
        expect(_moving(tester), isFalse);
        expect(find.byType(GlowOutline), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scrolled out of sight, though still built, it asks for no '
      'frames; scrolled back, it moves again', (tester) async {
    final ScrollController list = ScrollController();
    addTearDown(list.dispose);
    await tester.pumpWidget(
      _page(
        ListView(
          controller: list,
          // Kept built off the screen, as a page's next shelves are.
          scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
          children: [
            _card(GlowOutlineStyle.sheen),
            const SizedBox(height: 1600),
          ],
        ),
      ),
    );
    await _frames(tester, 5);
    expect(_moving(tester), isTrue);

    list.jumpTo(800);
    await _frames(tester, 8);
    expect(find.byType(GlowOutline, skipOffstage: false), findsOneWidget);
    expect(_moving(tester), isFalse);

    list.jumpTo(0);
    await _frames(tester, 2);
    expect(_moving(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a page muted by TickerMode asks for no frames, and moves '
      'once it is shown', (tester) async {
    bool muted = true;
    late StateSetter set;
    await tester.pumpWidget(
      _page(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return TickerMode(
              enabled: !muted,
              child: _card(GlowOutlineStyle.sheen),
            );
          },
        ),
      ),
    );
    await _frames(tester, 3);
    expect(_moving(tester), isFalse);

    set(() => muted = false);
    await _frames(tester, 2);
    expect(_moving(tester), isTrue);
  });
}
