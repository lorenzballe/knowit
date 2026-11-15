import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/widget_ask.dart';

/// The home-screen widget, offered once: after the second finished day, to
/// a reader with none placed, on a phone that says what it has placed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> app(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      ...prefs,
    });
    final AppState state = AppState();
    await state.init();
    return state;
  }

  final DateTime now = DateTime.now();
  String daysAgo(int n) => dateKey(DateTime(now.year, now.month, now.day - n));

  test('due at the end of the second finished day, never the first, and '
      'once', () async {
    final AppState first = await app({
      'knowit.completedDates': [dateKey(now)],
      'knowit.lastCompletionDate': dateKey(now),
      'knowit.streak': 1,
    });
    expect(first.dayClosed, isTrue);
    expect(first.shouldAskForWidget, isFalse);

    final AppState second = await app({
      'knowit.completedDates': [daysAgo(1), dateKey(now)],
      'knowit.lastCompletionDate': dateKey(now),
      'knowit.streak': 2,
    });
    expect(second.shouldAskForWidget, isTrue);
    await second.notedWidgetAsked();
    expect(second.shouldAskForWidget, isFalse);
    final AppState again = AppState();
    await again.init();
    expect(again.widgetAsked, isTrue);
    expect(again.shouldAskForWidget, isFalse);

    // Two days read, today's still open: not yet.
    final AppState open = await app({
      'knowit.completedDates': [daysAgo(2), daysAgo(1)],
      'knowit.lastCompletionDate': daysAgo(1),
      'knowit.streak': 2,
    });
    expect(open.shouldAskForWidget, isFalse);
  });

  group('on a phone', () {
    const MethodChannel channel = MethodChannel('astut/widget');
    List<String> placed = const [];
    bool canPin = false;
    final List<String> calls = [];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            switch (call.method) {
              case 'installed':
                return placed;
              case 'canPin':
                return canPin;
              case 'pin':
                return true;
            }
            return null;
          });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<BuildContext> host(WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Builder(
            builder: (c) {
              context = c;
              return const Scaffold();
            },
          ),
        ),
      );
      return context;
    }

    testWidgets('a widget already placed: no sheet, and none later', (
      tester,
    ) async {
      placed = const ['card.home'];
      final AppState state = await app({});
      final BuildContext context = await host(tester);
      final bool shown = await offerWidget(context, state);
      await tester.pump();
      expect(shown, isFalse);
      expect(find.byType(WidgetAsk), findsNothing);
      expect(state.widgetAsked, isTrue);
    });

    testWidgets('none placed, a launcher that can: the button puts it there', (
      tester,
    ) async {
      placed = const [];
      canPin = true;
      final AppState state = await app({});
      final BuildContext context = await host(tester);
      final Future<bool> shown = offerWidget(context, state);
      await tester.pumpAndSettle();
      expect(find.byType(WidgetAsk), findsOneWidget);
      expect(find.text('Add to Home Screen'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('widget-yes')));
      await tester.pumpAndSettle();
      expect(await shown, isTrue);
      expect(calls, contains('pin'));
      expect(state.widgetAsked, isTrue);
    });

    testWidgets('nothing answering — a test, a desktop — shows nothing', (
      tester,
    ) async {
      // What a desktop answers: no widget behind the channel.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => throw MissingPluginException(),
          );
      final AppState state = await app({});
      final BuildContext context = await host(tester);
      expect(await offerWidget(context, state), isFalse);
      expect(state.widgetAsked, isFalse);
    });
  });

  testWidgets('the sheet fits in every language, on both phones, with a long '
      'question in the widget', (tester) async {
    await tester.runAsync(_loadRealFonts);
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final List<Pill> bank = [...PillBank.live];
    bank.sort((a, b) => b.question.length.compareTo(a.question.length));
    final Pill longest = bank.first;

    final List<String> findings = [];
    for (final Locale locale in AppLocalizations.supportedLocales) {
      for (final (bool apple, bool canPin) in [
        (true, false),
        (false, false),
        (false, true),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(Brightness.dark),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: WidgetAsk(card: longest, canPin: canPin, apple: apple),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        findings.addAll(
          _cut(tester).map((s) => '[$locale apple=$apple pin=$canPin] $s'),
        );
      }
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}

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

/// Every paragraph on screen that did not get all of its text out, and any
/// overflow the layout reported.
List<String> _cut(WidgetTester tester) {
  final out = <String>[];
  final Object? error = tester.takeException();
  if (error != null) out.add('overflow — ${'$error'.split('\n').first}');
  for (final element in find.byType(RichText).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
    final String plain = ro.text.toPlainText();
    if (plain.trim().isEmpty) continue;
    String? how;
    if (ro.didExceedMaxLines) how = 'lines';
    final painter = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      textScaler: ro.textScaler,
      textAlign: ro.textAlign,
      maxLines: ro.maxLines,
    )..layout(maxWidth: ro.softWrap ? ro.size.width : double.infinity);
    if (how == null && painter.height > ro.size.height + 0.5) how = 'height';
    if (how == null && !ro.softWrap && painter.width > ro.size.width + 0.5) {
      how = 'width';
    }
    painter.dispose();
    if (how != null) out.add('"$plain" ($how)');
  }
  return out;
}
