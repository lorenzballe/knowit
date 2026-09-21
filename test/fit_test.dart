import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/comeback_screen.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/screens/friends_screen.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/screens/how_screen.dart';
import 'package:astuto/screens/intro_screen.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/screens/path_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/screens/topics_screen.dart';
import 'package:astuto/screens/week_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/pill_card_stack.dart';

/// Every screen, in every language, on a narrow phone: nothing cut.
///
/// A string is written in one language and fits the box it was designed
/// in; the other twelve are longer or shorter, and a box is not looked at
/// twelve more times. So this looks: it pumps each screen in each locale
/// at the width of a small phone, finds every paragraph on it, and asks
/// whether it was cut — by its own line limit, by a box too short for it,
/// or by a row that overflowed. What it finds is the list to fix, and
/// once the list is empty, this is what keeps it empty.
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

void main() {
  setUpAll(_loadRealFonts);

  const Size phone = Size(360, 780);
  final List<Locale> locales = AppLocalizations.supportedLocales;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // The words of the cards themselves. A list row shows the first line or
  // two of a question and ends it with three dots — the card is one tap
  // away — and that is a preview, not a cut. The interface's own strings
  // get no such allowance: a button, a title or a hint that ends in dots
  // is broken in that language.
  Iterable<String> strings(Object? v) sync* {
    if (v is String) {
      yield v;
    } else if (v is Map) {
      for (final x in v.values) {
        yield* strings(x);
      }
    } else if (v is List) {
      for (final x in v) {
        yield* strings(x);
      }
    }
  }

  final Set<String> content = {
    for (final p in PillBank.cards) ...strings(cardToJson(p)),
  };

  /// Every paragraph on screen that did not get all of its text out.
  List<String> cut(WidgetTester tester) {
    final out = <String>[];
    for (final element in find.byType(RichText).evaluate()) {
      final ro = element.renderObject;
      if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
      final String plain = ro.text.toPlainText();
      if (plain.trim().isEmpty || content.contains(plain)) continue;
      // A label faded all the way out — the tab bar keeps the words of
      // the tabs you are not on, at no width and no colour — is not on
      // the screen to be cut.
      final Color? colour = ro.text.style?.color;
      if (colour != null && colour.a == 0) continue;
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

  final Map<String, Object> done = {
    'knowit.onboarded': true,
    'knowit.todayDate': dateKey(DateTime.now()),
    'knowit.todayDeckIds': dealDay(date: DateTime.now())
        .map((p) => p.id)
        .toList(),
    'knowit.todayIndex': 5,
    'knowit.streak': 6,
    'knowit.bestStreak': 9,
    'knowit.completedDates': [
      for (var i = 6; i >= 0; i--)
        dateKey(DateTime.now().subtract(Duration(days: i))),
    ],
    'knowit.seenIds': PillBank.cards.take(45).map((p) => p.id).toList(),
    'knowit.answersJson': jsonEncode({
      for (final p in PillBank.cards.where((p) => p.isGraded).take(14))
        p.id: {'r': '0', 'c': 70, 'd': '2026-12-01', 's': 1},
    }),
    'knowit.judgements': jsonEncode([
      for (final p in PillBank.cards.where((p) => p.isGraded).take(14))
        {'c': 80, 'k': false, 'p': p.id, 'd': dateKey(DateTime.now())},
    ]),
    'knowit.rungDates': jsonEncode({
      'day_one': dateKey(DateTime.now().subtract(const Duration(days: 6))),
      'reading': dateKey(DateTime.now().subtract(const Duration(days: 3))),
    }),
    'knowit.likedIds': PillBank.cards.take(2).map((p) => p.id).toList(),
    'knowit.savedIds': PillBank.cards.skip(2).take(3).map((p) => p.id).toList(),
    'knowit.friendCodes': ['K7MP2X'],
  };

  Future<AppState> appWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final app = AppState();
    await app.init();
    return app;
  }

  Widget host(Locale locale, Widget screen) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: screen,
  );

  testWidgets('nothing is cut on any screen in any language', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final findings = <String>[];
    void note(Locale locale, String screen, WidgetTester tester) {
      final Object? error = tester.takeException();
      if (error != null) {
        findings.add(
          '[$locale] $screen: overflow — ${error.toString().split('\n').first}',
        );
      }
      for (final line in cut(tester)) {
        findings.add('[$locale] $screen: $line');
      }
    }

    for (final locale in locales) {
      final app = await appWith(done);
      final account = Account(
        uidOverride: 'me',
        boardsOverride: MemoryBoardStore(),
      );
      final Pill debate = PillBank.cards.firstWhere((p) => p.hasCounterpoint);
      final Pill pick = PillBank.cards.firstWhere(
        (p) => p.challenge is PickOne,
      );

      final screens = <String, Widget>{
        'journey': JourneyScreen(app: app, onBack: () {}),
        'path': PathScreen(app: app, onBack: () {}),
        'week': WeekScreen(app: app, onBack: () {}),
        'paywall': PaywallScreen(app: app, source: 'audit'),
        'profile': ProfileScreen(
          app: app,
          account: account,
          onSignedOut: () {},
        ),
        'friends': FriendsScreen(app: app, account: account, onBack: () {}),
        'saved': SavedScreen(app: app, onBackToToday: () {}),
        'liked': SavedScreen(
          app: app,
          onBackToToday: () {},
          shelf: Shelf.liked,
        ),
        'explore': ExploreScreen(app: app),
        'archive': ArchiveScreen(app: app, onBack: () {}),
        'how': const HowScreen(),
        'intro': IntroScreen(
          onContinue: () {},
          onApple: () async => false,
          onGoogle: () async => false,
          onNotConnected: (_) {},
        ),
        'mix': MixScreen(onDone: (_) {}, onSkip: () {}),
        'genres': GenresScreen(app: app, onDone: (_, _) {}, onSkip: () {}),
        'comeback': ComebackScreen(app: app, onContinue: () {}),
        'topics': TopicsScreen(initial: app.pickedTopics, onDone: (_) {}),
        'detail-debate': PillDetailScreen(pill: debate, app: app),
        'detail-pick': PillDetailScreen(pill: pick, app: app),
        'deck-viewer': DeckViewerScreen(
          app: app,
          deck: app.todaysDeck,
          title: 'Today',
        ),
      };
      for (final entry in screens.entries) {
        await tester.pumpWidget(host(locale, entry.value));
        await settle(tester);
        note(locale, entry.key, tester);
        // The intro is five scenes; the first is not the long one.
        if (entry.key == 'intro') {
          for (var scene = 2; scene <= 5; scene++) {
            await tester.fling(
              find.byType(IntroScreen),
              const Offset(-300, 0),
              900,
            );
            await settle(tester);
            note(locale, 'intro $scene', tester);
          }
        }
        // The fold: one screen further down, where the long lines live.
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -500));
          await settle(tester);
          note(locale, '${entry.key} ↓', tester);
        }
      }

      // The day itself, in the app: reading, the sixth card, the shelf.
      tester.platformDispatcher.localeTestValue = locale;
      tester.platformDispatcher.localesTestValue = [locale];
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      await tester.pumpWidget(const AstutoApp());
      await settle(tester);
      note(locale, 'today', tester);
      for (var i = 0; i < 5; i++) {
        await tester.fling(
          find.byType(PillCardStack),
          const Offset(-320, 0),
          900,
        );
        await settle(tester);
      }
      note(locale, 'sixth card', tester);
      await tester.fling(
        find.byType(PillCardStack),
        const Offset(-320, 0),
        900,
      );
      await settle(tester);
      note(locale, 'shelf', tester);
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(TodayDoneView), const Offset(-200, 0));
        await settle(tester);
      }
      note(locale, 'shelf sixth', tester);
      tester.platformDispatcher.clearLocaleTestValue();
      tester.platformDispatcher.clearLocalesTestValue();
    }

    if (findings.isNotEmpty) {
      // ignore: avoid_print
      print('CUT ${findings.length}\n${findings.join('\n')}');
    }
    expect(findings, isEmpty, reason: '${findings.length} places cut text');
  });
}
