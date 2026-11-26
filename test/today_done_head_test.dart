// The finished day's head (lib/screens/today_done_view.dart): "See again"
// beside the day sent, as a small pill, ▶ and its word; and with no top row,
// at the two ends of the dots. On a narrow phone at a large text size, in
// the long languages, nothing overflows and the day's name is never cut for
// the pill: the pill keeps its mark alone instead.
//
//   flutter test test/today_done_head_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

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

/// A reader twelve days in, today's five read.
Future<AppState> _finished(WidgetTester tester) async {
  final DateTime now = DateTime.now();
  String day(int back) => dateKey(now.subtract(Duration(days: back)));
  final List<String> deck = dealDay(date: now).cards
      .take(kPillsPerDay)
      .map((p) => p.id)
      .toList();
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': deck.length,
    'knowit.streak': 12,
    'knowit.lastCompletionDate': day(0),
    'knowit.completedDates': [for (int back = 11; back >= 0; back--) day(back)],
    'knowit.seenIds': deck,
  });
  final AppState app = AppState();
  await app.init();
  await tester.pump();
  return app;
}

Widget _host(AppState app, Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: Scaffold(
    body: SafeArea(
      child: Builder(
        builder: (context) => TodayDoneView(
          app: app,
          at: 0,
          onPick: (_) {},
          heading: (line: context.l10n.dayTitle(app.dayNumber), aside: null),
        ),
      ),
    ),
  ),
);

/// How many lines the text under [finder] takes at the width it was given:
/// a line that wrapped would be cut by the row's height, not overflow it.
int _lines(WidgetTester tester, Finder finder) {
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)),
  );
  final TextPainter painter = TextPainter(
    text: paragraph.text,
    textDirection: TextDirection.ltr,
    textScaler: paragraph.textScaler,
  )..layout(maxWidth: paragraph.constraints.maxWidth);
  final int lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

/// Whether the pill shows its word.
bool _worded(WidgetTester tester, Locale locale) => find
    .descendant(
      of: find.byKey(const ValueKey('shelf-see-again')),
      matching: find.text(lookupAppLocalizations(locale).todaySeeAgain),
    )
    .evaluate()
    .isNotEmpty;

void main() {
  setUpAll(_loadRealFonts);

  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    TodayDoneView.headForShots = null;
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  testWidgets('in every language on an everyday phone: See again whole, '
      'beside the day sent, the day\'s name at its size', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final AppState app = await _finished(tester);
    for (final Locale locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(_host(app, locale));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(_worded(tester, locale), isTrue, reason: '$locale');
      final Rect again = tester.getRect(
        find.byKey(const ValueKey('shelf-see-again')),
      );
      final Rect send = tester.getRect(
        find.byKey(const ValueKey('shelf-share-day')),
      );
      final Rect name = tester.getRect(find.byKey(const ValueKey('shelf-day')));
      expect(again.right, lessThanOrEqualTo(send.left), reason: '$locale');
      expect(again.left, greaterThan(name.right), reason: '$locale');
      expect(again.center.dy, closeTo(send.center.dy, 0.5), reason: '$locale');
    }
  });

  for (final DoneHead head in [DoneHead.title, DoneHead.none]) {
    testWidgets('${head.name}: narrow and large, nothing overflows and the '
        'day\'s name stays on its line', (tester) async {
      // ignore: invalid_use_of_visible_for_testing_member
      TodayDoneView.headForShots = head;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final AppState app = await _finished(tester);
      var compact = 0;
      for (final Size phone in const [Size(390, 844), Size(320, 640)]) {
        tester.view.physicalSize = phone;
        for (final double text in const [1.0, 1.3, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = text;
          for (final String language in ['en', 'it', 'de', 'ru', 'fr', 'ja']) {
            final Locale locale = Locale(language);
            await tester.pumpWidget(_host(app, locale));
            await tester.pump(const Duration(milliseconds: 300));
            final String at = '${phone.width} ${text}x $language';
            expect(tester.takeException(), isNull, reason: at);
            final Finder again = find.byKey(const ValueKey('shelf-see-again'));
            expect(again, findsOneWidget, reason: at);
            if (!_worded(tester, locale)) compact++;
            if (head == DoneHead.title) {
              final Finder name = find.byKey(const ValueKey('shelf-day'));
              expect(
                _lines(tester, name),
                1,
                reason: '$at: the name on one line',
              );
              expect(
                tester.getRect(again).left,
                greaterThanOrEqualTo(tester.getRect(name).right),
                reason: at,
              );
            } else {
              expect(find.byKey(const ValueKey('shelf-day')), findsNothing);
            }
          }
        }
      }
      // Somewhere in all that, the pill kept its mark alone.
      expect(compact, greaterThan(0));
    });
  }
}
