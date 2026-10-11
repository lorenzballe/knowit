import 'package:astuto/utils/share_origin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The share sheet's anchor. On iPhone since iOS 26 share_plus throws when
/// the anchor is empty or reaches past the screen, and the sheet never
/// opens; these hold the two promises that keep it opening.
void main() {
  Future<BuildContext> place(
    WidgetTester tester, {
    required Offset at,
    required Size size,
  }) async {
    late BuildContext boxContext;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              width: size.width,
              height: size.height,
              child: Builder(
                builder: (context) {
                  boxContext = context;
                  return const ColoredBox(color: Color(0xFF000000));
                },
              ),
            ),
          ],
        ),
      ),
    );
    return boxContext;
  }

  Size screenOf(WidgetTester tester) =>
      tester.view.physicalSize / tester.view.devicePixelRatio;

  testWidgets('points from the box that opened it', (tester) async {
    final context = await place(
      tester,
      at: const Offset(24, 300),
      size: const Size(120, 44),
    );
    expect(shareOrigin(context), const Rect.fromLTWH(24, 300, 120, 44));
  });

  testWidgets('a box reaching past the edge is cut to the screen', (
    tester,
  ) async {
    final Size screen = screenOf(tester);
    final context = await place(
      tester,
      at: Offset(-40, screen.height - 20),
      size: const Size(100, 60),
    );
    final Rect origin = shareOrigin(context);
    expect(origin, Rect.fromLTWH(0, screen.height - 20, 60, 20));
    expect((Offset.zero & screen).intersect(origin), origin);
  });

  testWidgets('a box wholly off the screen falls back to the middle', (
    tester,
  ) async {
    final Size screen = screenOf(tester);
    final context = await place(
      tester,
      at: Offset(screen.width + 10, 0),
      size: const Size(50, 50),
    );
    final Rect origin = shareOrigin(context);
    expect(origin.center, (Offset.zero & screen).center);
    expect(origin.isEmpty, isFalse);
  });

  testWidgets('with nothing to point from, the middle of the screen', (
    tester,
  ) async {
    final Size screen = screenOf(tester);
    final Rect origin = shareOrigin();
    expect(origin.size, const Size(1, 1));
    expect(origin.center, (Offset.zero & screen).center);
    expect((Offset.zero & screen).intersect(origin), origin);
  });
}
