import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import 'package:astuto/data/skills.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/comeback_screen.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/screens/how_screen.dart';
import 'package:astuto/screens/intro_screen.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/loves_screen.dart';
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
import 'package:astuto/widgets/report_sheet.dart';
import 'package:astuto/widgets/skill_score.dart' show scoreBookOf;

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
    'knowit.todayDeckIds': dealDay(date: DateTime.now()).cards
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

      // Weeks of answers said how sure, so the journey has a line of weeks
      // to tap and points off to draw.
      final DateTime now = DateTime.now();
      String ago(int days) => dateKey(now.subtract(Duration(days: days)));
      final AppState measured = await appWith({
        ...done,
        'knowit.judgements': jsonEncode([
          for (var i = 0; i < 60; i++)
            {
              'c': 50 + (i % 5) * 10,
              'k': i % 3 != 0,
              'p': PillBank.cards[i].id,
              'd': ago(i < 30 ? 20 : 2),
            },
        ]),
      });

      // Astute+ with both shelves empty: the foot of the profile says the
      // days the archive keeps, the plan's name, and how each shelf fills.
      final AppState plusEmpty = await appWith({
        ...done,
        'knowit.plus': true,
        'knowit.likedIds': <String>[],
        'knowit.savedIds': <String>[],
      });

      final screens = <String, Widget>{
        'journey': JourneyScreen(app: app, onBack: () {}),
        'journey-measured': JourneyScreen(app: measured, onBack: () {}),
        'path': PathScreen(app: app, onBack: () {}),
        'week': WeekScreen(app: app, onBack: () {}),
        'paywall': PaywallScreen(app: app, source: 'audit'),
        'profile': ProfileScreen(
          app: app,
          account: account,
          onSignedOut: () {},
        ),
        'profile-plus-empty': ProfileScreen(
          app: plusEmpty,
          account: account,
          onSignedOut: () {},
        ),
        'saved': SavedScreen(app: app, onBackToToday: () {}),
        'liked': SavedScreen(
          app: app,
          onBackToToday: () {},
          shelf: Shelf.liked,
        ),
        'explore': ExploreScreen(app: app),
        'archive': ArchiveScreen(app: app, onBack: () {}),
        'how': const HowScreen(),
        'intro': IntroScreen(onContinue: () {}, onSignIn: (_) async => false),
        'mix': MixScreen(onDone: (_) {}),
        'genres': GenresScreen(app: app, onDone: (_, _) {}, onBack: () {}),
        'loves': LovesScreen(mix: const {}, onDone: (_) {}),
        'comeback': ComebackScreen(app: app, onContinue: () {}),
        'topics': TopicsScreen(initial: app.pickedTopics, onDone: (_) {}),
        'detail-debate': PillDetailScreen(pill: debate, app: app),
        'detail-pick': PillDetailScreen(pill: pick, app: app),
        'report': Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ReportSheet(pill: pick),
          ),
        ),
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
        // The profile, down to its foot: the shelves, the archive and where
        // the reader lives, the account, how cards are written, and the way
        // out, each row with its words and what is behind it.
        if (entry.key.startsWith('profile')) {
          for (var fold = 2; fold <= 7; fold++) {
            await tester.drag(scrollable.first, const Offset(0, -500));
            await settle(tester);
            note(locale, '${entry.key} ↓$fold', tester);
          }
        }
      }

      // The day itself, in the app: reading, the first day's celebration,
      // the sixth card, the shelf.
      tester.platformDispatcher.localeTestValue = locale;
      tester.platformDispatcher.localesTestValue = [locale];
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      await tester.pumpWidget(const AstutoApp());
      await settle(tester);
      note(locale, 'today', tester);
      for (var i = 0; i < 5; i++) {
        await tester.flingFrom(deckTop(tester), const Offset(-320, 0), 900);
        await settle(tester);
      }
      await settle(tester);
      note(locale, 'first day', tester);
      await tester.tap(find.byKey(const ValueKey('first-day-close')));
      await settle(tester);
      note(locale, 'sixth card', tester);
      await tester.flingFrom(deckTop(tester), const Offset(-320, 0), 900);
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

  // The journey's skills not picked, two to a row: beside a score of three
  // figures a name has little more than eighty points on a small phone, less
  // than some of its words need ("wetenschapper", "Wissenschaftlich"). Every
  // name whole in every language: not cut, and no word wider than its line,
  // which would break it in the middle while keeping to two lines.
  testWidgets("the journey's skills keep every name whole in every "
      'language', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // Weeks of answers, nearly all right: scores of three figures.
    final DateTime now = DateTime.now();
    String ago(int days) => dateKey(now.subtract(Duration(days: days)));
    final AppState app = await appWith({
      ...done,
      'knowit.judgements': jsonEncode([
        for (var i = 0; i < 90; i++)
          {
            'c': 70,
            'k': i % 9 != 0,
            'p': PillBank.cards.where((p) => p.isGraded).elementAt(i).id,
            'd': ago(40 - i ~/ 3),
          },
      ]),
    });
    final RegExp breaksAnywhere = RegExp(
      r'[\u1100-\u11ff\u2e80-\u9fff\uac00-\ud7af\uf900-\ufaff\uff00-\uffef]',
    );
    final Finder cells = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('training-other-'),
      skipOffstage: false,
    );

    final findings = <String>[];
    var widest = 0;
    for (final Locale locale in locales) {
      await tester.pumpWidget(
        host(locale, JourneyScreen(app: app, onBack: () {})),
      );
      await settle(tester);
      expect(cells, findsWidgets, reason: '[$locale] no skills below');
      for (final Element cell in cells.evaluate()) {
        final RenderParagraph name = tester.renderObject<RenderParagraph>(
          find
              .descendant(
                of: find.byWidget(cell.widget),
                matching: find.byType(RichText),
                skipOffstage: false,
              )
              .first,
        );
        final String said = name.text.toPlainText();
        if (name.didExceedMaxLines) findings.add('[$locale] "$said": cut');
        for (final String word in said.split(RegExp(r'\s+'))) {
          if (word.isEmpty || breaksAnywhere.hasMatch(word)) continue;
          final TextPainter alone = TextPainter(
            text: TextSpan(text: word, style: name.text.style),
            textDirection: name.textDirection,
            textScaler: name.textScaler,
            maxLines: 1,
          )..layout();
          if (alone.width > name.constraints.maxWidth + 0.5) {
            findings.add(
              '[$locale] "$said": "$word" broken, '
              '${alone.width.round()} in ${name.constraints.maxWidth.round()}',
            );
          }
          alone.dispose();
        }
      }
      // The scores beside the names: three figures, as the case is.
      for (final Skill s in Skill.values) {
        widest = math.max(widest, scoreBookOf(app).of(s).now);
      }
    }
    expect(
      widest,
      greaterThanOrEqualTo(100),
      reason: 'scores of three figures',
    );
    expect(findings, isEmpty, reason: findings.join('\n'));
  });

  // The line under the finished day's shelf ran onto a second line on the
  // owner's iPhone ("Tomorrow's five start with Weird facts, in 3h 50m")
  // and took the shelf's room. One line in every language, then, for every
  // subject, with the widest wait the clock gives — 23 h 59, half a minute
  // after midnight — and the widest mark: a card that thinks too carries
  // Thinking's lightbulb beside its own.
  testWidgets("tomorrow's line is one line in every language, for every "
      'subject', (tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final DateTime today = DateTime.now();
    final DateTime justAfterMidnight = DateTime(
      today.year,
      today.month,
      today.day,
      0,
      0,
      30,
    );
    final Pill thinker = PillBank.cards.firstWhere((p) => p.thinksToo);
    final List<Pill?> leads = [
      null,
      for (final String topic in kTopics.keys)
        cardFromJson({
          ...cardToJson(thinker),
          'id': 'tomorrow-$topic',
          'topic': topic,
        }),
    ];
    // The languages the app's own face sets. The others are set in the
    // phone's own faces for their scripts, which this machine does not
    // have, so how wide they come out here says little about a phone.
    const Set<String> ownFace = {
      'en',
      'de',
      'es',
      'fr',
      'it',
      'nl',
      'pl',
      'pt',
      'tr',
    };

    final findings = <String>[];
    for (final Locale locale in locales) {
      // The reader's own text size, the next one up, and the largest the
      // accessibility settings give.
      for (final double scale in const [1.0, 1.3, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        for (final Pill? lead in leads) {
          await tester.pumpWidget(
            host(
              locale,
              Scaffold(
                body: Center(
                  child: Padding(
                    // As the shelf sets it.
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TomorrowLine(lead: lead, now: justAfterMidnight),
                  ),
                ),
              ),
            ),
          );
          final RenderParagraph line = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(const ValueKey('shelf-tomorrow')),
              matching: find.byType(RichText),
            ),
          );
          final String said = line.text.toPlainText();
          final String where = '[$locale x$scale] "$said"';
          final TextPainter one = TextPainter(
            text: TextSpan(text: said, style: line.text.style),
            textDirection: line.textDirection,
            textScaler: line.textScaler,
            maxLines: 1,
          )..layout();
          final double oneLine = one.height;
          one.dispose();
          if (line.size.height > oneLine * 1.5) {
            findings.add('$where: more than one line');
          }
          final bool own = ownFace.contains(locale.languageCode);
          // Cut with three dots only at the largest sizes, the last resort.
          if (line.didExceedMaxLines && (scale == 1.0 || own && scale < 2)) {
            findings.add('$where: cut');
          }
          // Short enough to be said at its size, not set smaller to fit.
          final double size = line.text.style!.fontSize!;
          if (scale == 1.0 && own && size < 13.5) {
            findings.add('$where: set at $size to fit');
          }
        }
      }
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}

/// Where a reader throws a card from: the question, above any scene that
/// keeps its own gestures.
Offset deckTop(WidgetTester tester) {
  final deck = tester.getRect(find.byType(PillCardStack));
  return Offset(deck.center.dx, deck.top + 90);
}
