import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/comeback_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

// The come-back screen opened on "You missed 3 days." and counted the cards
// that "went unread". It is glad the reader is here now, says what the lapse
// did not take, and offers to move a reminder only where there is one.

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// A reader whose thirteen days in a row lapsed three days ago, on a phone
/// that does or does not let the app notify them.
Future<AppState> _lapsed({
  required bool allowed,
  List<String> saved = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.streak': 13,
    'knowit.bestStreak': 13,
    'knowit.lastCompletionDate': _key(
      DateTime.now().subtract(const Duration(days: 3)),
    ),
    'knowit.savedIds': saved,
  });
  final app = AppState(
    hasPermission: () async => allowed,
    askPermission: () async => allowed,
    arm: (_) async {},
    disarm: () async {},
  );
  await app.init();
  await app.refreshDailyReminder();
  return app;
}

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: child,
);

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(375, 667) * 2;
    view.devicePixelRatio = 2;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  group('The come-back screen', () {
    testWidgets('is glad the reader is here, and sends no bill', (
      tester,
    ) async {
      final app = await _lapsed(allowed: false);
      await tester.pumpWidget(
        _host(ComebackScreen(app: app, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('WELCOME BACK'), findsOneWidget);
      expect(find.text('Good to see you again.'), findsOneWidget);
      expect(find.textContaining('missed'), findsNothing);
      expect(find.textContaining('unread'), findsNothing);
      // Nothing kept yet, so no card with nothing in it.
      expect(find.text('STILL YOURS'), findsNothing);
      // The system will not let the app reach this reader: there is no
      // reminder, so none to move.
      expect(find.textContaining('Move my reminder'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('says what the lapse did not take', (tester) async {
      final app = await _lapsed(
        allowed: false,
        saved: const ['space-a-1', 'space-b-2'],
      );
      await tester.pumpWidget(
        _host(ComebackScreen(app: app, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('STILL YOURS'), findsOneWidget);
      expect(find.text('Space is still your most kept topic'), findsOneWidget);
    });

    testWidgets('moves a reminder there is, at a time written as the phone '
        'writes one', (tester) async {
      final app = await _lapsed(allowed: true);
      await tester.pumpWidget(
        _host(ComebackScreen(app: app, onContinue: () {})),
      );
      await tester.pumpAndSettle();

      final Finder move = find.text('Move my reminder to 7:00 PM');
      expect(move, findsOneWidget);
      await tester.tap(move);
      await tester.pumpAndSettle();
      expect(app.notifyTime, '19:00');
      expect(find.text('Daily nudge moved to 7:00 PM.'), findsOneWidget);
    });
  });
}
