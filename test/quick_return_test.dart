// The way back of a page that scrolls whole, as Instagram keeps its own
// (lib/widgets/quick_return.dart): part of the page going down, straight
// back going up, in its place at the top; still for whoever asked for less
// motion, and always there with a screen reader on.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/widgets/quick_return.dart';

/// A page as long as a journey under a way back and a small header, 56
/// points tall: 8 over the ring, 4 under it. A row of its own that
/// scrolls sideways comes under the title. The page stops at its ends
/// unless it [bounces], as on an iPhone, whose first points of a drag are
/// eased in. [lines] makes it as long as it is.
Widget _host({
  bool still = false,
  bool reader = false,
  bool bounces = false,
  int lines = 80,
  VoidCallback? onBack,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: still, accessibleNavigation: reader),
      child: Scaffold(
        body: QuickReturn(
          ground: Colors.black,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const ColoredBox(
                    key: ValueKey('back'),
                    color: Colors.white,
                    child: SizedBox(width: 44, height: 44),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('KICKER'),
              ],
            ),
          ),
          child: ListView(
            key: const ValueKey('page'),
            physics: bounces
                ? const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  )
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(top: 56 + 12),
            children: [
              const SizedBox(height: 40, child: Text('Title')),
              SizedBox(
                height: 80,
                child: ListView(
                  key: const ValueKey('row'),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < 20; i++)
                      SizedBox(width: 120, child: Text('tile $i')),
                  ],
                ),
              ),
              for (int i = 0; i < lines; i++)
                SizedBox(height: 60, child: Text('line $i')),
            ],
          ),
        ),
      ),
    ),
  ),
);

final Finder _back = find.byKey(const ValueKey('back'));
final Finder _page = find.byKey(const ValueKey('page'));

/// The header's height and what it shows under it: how far it goes up to
/// be gone.
const double _gone = 56 + QuickReturn.shade;

ScrollPosition _scrolled(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: _page, matching: find.byType(Scrollable)).first,
    )
    .position;

double _ground(WidgetTester tester) => tester
    .widget<Opacity>(find.byKey(const ValueKey('quick-return-ground')))
    .opacity;

Future<void> _phone(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(page);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('at the top it stands in its place; a little way down it goes '
      'up with the page, point for point; further down it is gone; a little '
      'way back up it comes straight back over the page, softly', (
    tester,
  ) async {
    var backs = 0;
    await _phone(tester, _host(onBack: () => backs++));
    const Offset place = Offset(20, 8);
    expect(tester.getTopLeft(_back), place);
    expect(_back.hitTestable(), findsOneWidget);
    expect(_ground(tester), 0);

    await tester.drag(_page, const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_back), place - const Offset(0, 30));
    // Part of the page: nothing laid behind it.
    expect(_ground(tester), 0);

    await tester.drag(_page, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(_scrolled(tester).pixels, closeTo(530, 0.5));
    expect(tester.getRect(_back).bottom, lessThanOrEqualTo(0));
    expect(_back.hitTestable(), findsNothing);

    // Scrolled back up less than a finger's width: straight back, softly,
    // the page hardly moved.
    await tester.drag(_page, const Offset(0, 20));
    await tester.pump();
    await tester.pump(QuickReturn.comeBack ~/ 3);
    final double halfway = tester.getTopLeft(_back).dy;
    expect(halfway, greaterThan(place.dy - _gone));
    expect(halfway, lessThan(place.dy - 1));
    await tester.pumpAndSettle();
    expect(_scrolled(tester).pixels, closeTo(510, 0.5));
    expect(tester.getTopLeft(_back), place);
    expect(_back.hitTestable(), findsOneWidget);
    // Over the page now: its colour laid behind it, so nothing runs through.
    expect(_ground(tester), 1);
    await tester.tap(_back);
    expect(backs, 1);

    // All the way back to the top, everything where it was.
    await tester.drag(_page, const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(_scrolled(tester).pixels, 0);
    expect(tester.getTopLeft(_back), place);
    expect(_ground(tester), 0);
  });

  testWidgets('left part of the way up when the page stops, it goes on out '
      'of sight; near the top it stays where the page has it', (tester) async {
    await _phone(tester, _host());
    await tester.drag(_page, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.drag(_page, const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_back).dy, 8);

    // A short way down from there, and let go: on, out of sight.
    await tester.drag(_page, const Offset(0, -20));
    await tester.pump();
    expect(tester.getTopLeft(_back).dy, closeTo(8 - 20, 0.5));
    await tester.pumpAndSettle();
    expect(tester.getRect(_back).bottom, lessThanOrEqualTo(0));

    // From the top, as far as the title has gone and no further.
    await tester.drag(_page, const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.drag(_page, const Offset(0, -24));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_back).dy, closeTo(8 - 24, 0.5));
  });

  testWidgets('the page settling back at its foot after a pull past it is '
      'not the reader going up: the way back stays gone', (tester) async {
    await _phone(tester, _host(bounces: true));
    final ScrollPosition page = _scrolled(tester);
    page.jumpTo(page.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(_back.hitTestable(), findsNothing);
    await tester.drag(_page, const Offset(0, -160));
    await tester.pump();
    expect(page.pixels, greaterThan(page.maxScrollExtent));
    await tester.pumpAndSettle();
    expect(page.pixels, closeTo(page.maxScrollExtent, 0.5));
    expect(tester.getRect(_back).bottom, lessThanOrEqualTo(0));
    expect(_back.hitTestable(), findsNothing);
  });

  testWidgets('on a page shorter than the screen, pulled up and let go, it '
      'goes up with the page and settles back with it', (tester) async {
    await _phone(tester, _host(bounces: true, lines: 2));
    final TestGesture finger = await tester.startGesture(
      tester.getCenter(_page),
    );
    for (int i = 0; i < 8; i++) {
      await finger.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final double pulled = _scrolled(tester).pixels;
    expect(pulled, greaterThan(10));
    expect(tester.getTopLeft(_back).dy, closeTo(8 - pulled, 0.5));
    await finger.up();
    // Settling, it comes down with the page, part of it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final double settling = _scrolled(tester).pixels;
    expect(settling, inExclusiveRange(0, pulled));
    expect(tester.getTopLeft(_back).dy, closeTo(8 - settling, 0.5));
    await tester.pumpAndSettle();
    expect(_scrolled(tester).pixels, 0);
    expect(tester.getTopLeft(_back), const Offset(20, 8));
    expect(_back.hitTestable(), findsOneWidget);
  });

  testWidgets('a row that scrolls sideways inside the page moves nothing', (
    tester,
  ) async {
    await _phone(tester, _host());
    // Down far enough for the way back to be gone, the row still on screen.
    await tester.drag(_page, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(tester.getRect(_back).bottom, lessThanOrEqualTo(0));
    final Finder row = find.byKey(const ValueKey('row'));
    await tester.drag(row, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.drag(row, const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(_back).bottom, lessThanOrEqualTo(0));
    expect(_back.hitTestable(), findsNothing);
  });

  testWidgets('for whoever asked for less motion it never slides: it fades '
      'out where it stands going down, and back in a little way back up', (
    tester,
  ) async {
    await _phone(tester, _host(still: true));
    double shown() => tester
        .widget<AnimatedOpacity>(
          find.byKey(const ValueKey('quick-return-fade')),
        )
        .opacity;
    const Offset place = Offset(20, 8);
    expect(shown(), 1);

    // A little way down it stands where it is, the page going on under it.
    await tester.drag(_page, const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_back), place);
    expect(shown(), 1);

    await tester.drag(_page, const Offset(0, -500));
    await tester.pump();
    expect(tester.getTopLeft(_back), place);
    expect(shown(), 0);
    expect(_back.hitTestable(), findsNothing);
    await tester.pumpAndSettle();

    await tester.drag(_page, const Offset(0, 20));
    await tester.pump();
    expect(tester.getTopLeft(_back), place);
    expect(shown(), 1);
    await tester.pumpAndSettle();
    expect(_back.hitTestable(), findsOneWidget);
  });

  testWidgets('with a screen reader on it stays where it is, always there to '
      'be found', (tester) async {
    await _phone(tester, _host(reader: true));
    await tester.drag(_page, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_back), const Offset(20, 8));
    expect(_back.hitTestable(), findsOneWidget);
    // Over the page, with its colour behind it.
    expect(_ground(tester), 1);
  });
}
