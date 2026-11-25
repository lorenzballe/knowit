// Photographs Go deeper (lib/widgets/deeper_sheet.dart): the sheet a tap on a
// card's source opens, on a small, a medium and a large phone, in the dark
// and on paper:
//
//   written   a card with its simple version, why it matters and its two
//             views written in its file, on Astute+ with the answers off, as
//             most readers see it: as it opens, the two views, the source
//   free      the same card on the free plan with the answers on: why and the
//             views frosted over, Claude's parts marked Astute+
//   answer    a card with nothing written, on Astute+ with the answers on:
//             the card said simply, a new case answered, the reader's idea
//             looked at, and one frame while an answer is coming
//   entrance  one frame as the sheet opens, the parts on their way in
//
//   flutter test tool/deeper_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
// SHOTS (a folder) and LANG_SHOT (a language, Italian by default) move it;
// PHONE (small, medium or large) and THEME (dark or light) narrow it.
// DEEPER_STYLE (playful, column, panels or magazine) sets the parts the way
// it names (deeper/editorial.dart); the `style` shots, two a phone and theme,
// show the head with the idea said simply, then both sides and the everyday
// example:
//
//   DEEPER_STYLE=magazine flutter test tool/deeper_shots.dart \
//     --plain-name style --update-goldens
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/card_ask.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/deeper/editorial.dart';
import 'package:astuto/widgets/deeper_sheet.dart';
import 'package:astuto/widgets/subject_icon.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

const Map<String, Size> _phones = {
  'small': Size(360, 740),
  'medium': Size(390, 844),
  'large': Size(430, 932),
};

/// What Claude says back, in the shots: in Italian, as it would answer an
/// Italian reader, the card itself being in English.
AskResult _answer(AskMode mode, String text) => AskAnswer(switch (mode) {
  AskMode.simple =>
    'Immagina 1.000 quadri all\'asta: 20 sono falsi, 980 veri. Il test ne '
        'segnala 19 dei falsi, ma anche 49 dei veri. Su 68 quadri segnalati, '
        'i falsi sono solo 19: meno di uno su tre.',
  AskMode.sides =>
    'Per il test: un falso su venti sfugge, e scoprirlo vale molto. Contro: '
        'quasi tre segnalati su quattro sono veri, e un sospetto costa caro '
        'a chi vende. A decidere è quanti falsi ci sono davvero.',
  AskMode.example =>
    'L\'antifurto del vicino suona di notte. Pensi ai ladri, ma quasi ogni '
        'allarme è un gatto o il vento: i ladri sono rari, i falsi allarmi '
        'no. La prossima volta chiediti prima quanto è comune la cosa.',
  AskMode.quiz =>
    'Q: Un\'app segnala il 90% delle email truffa e il 2% di quelle vere. '
        'Una email su cento è una truffa. Una email segnalata è…\n'
        'A) Quasi certamente una truffa\n'
        'B) Più spesso vera che truffa\n'
        'C) Una truffa nove volte su dieci\n'
        'RIGHT: B\n'
        'WHY: Su 1.000 email, 9 truffe segnalate contro 20 vere. Il 90% '
        'tenta perché descrive il test, non le email.',
  AskMode.take =>
    'Il punto forte: guardi a cosa fa il test, ed è giusto. Il passo '
        'debole: il 95% dice quanto spesso il test trova un falso, non '
        'quanto spesso un quadro segnalato è falso. Una domanda che lo mette '
        'alla prova: quanti quadri veri finiscono segnalati?',
  AskMode.ask =>
    'Perché i veri sono tanti di più: anche una piccola parte di molti '
        'supera una grande parte di pochi.',
});

Future<AppState> _app({required bool plus}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
  });
  final app = AppState();
  await app.init();
  return app;
}

/// The card behind the sheet, as the reader left it.
class _Behind extends StatelessWidget {
  const _Behind({required this.pill});

  final Pill pill;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: pill.color,
              borderRadius: BorderRadius.circular(34),
            ),
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CardMark(pill: pill, size: 16, ink: pill.ink),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.subjectOf(pill.topic).toUpperCase(),
                      style: AppText.label(
                        size: 11,
                        spacing: 1.4,
                        color: pill.ink.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  pill.question,
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w700,
                    height: 1.12,
                    color: pill.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final String lang = Platform.environment['LANG_SHOT'] ?? 'it';
  final String? onlyPhone = Platform.environment['PHONE'];
  final String? onlyTheme = Platform.environment['THEME'];
  final String style = Platform.environment['DEEPER_STYLE'] ?? 'magazine';
  deeperStyle = DeeperStyle.values.byName(style);

  // The card with all three written: the one bank card whose file holds
  // its simple version, why it matters and two views, an idea of a book.
  Pill written() => PillBank.live.firstWhere(
    (p) => p.simply.isNotEmpty && p.why.isNotEmpty && p.views.length == 2,
  );
  // A card with nothing written below what it shows, so Claude writes it
  // all.
  Pill bare() => PillBank.cards.firstWhere(
    (p) =>
        p.reference.isNotEmpty &&
        p.principle == Principle.baseRate &&
        p.question.toLowerCase().contains('test') &&
        !p.goesDeeper,
    orElse: () => PillBank.cards.firstWhere((p) => !p.goesDeeper),
  );

  for (final MapEntry<String, Size> phone in _phones.entries) {
    if (onlyPhone != null && onlyPhone != phone.key) continue;
    for (final Brightness b in [Brightness.dark, Brightness.light]) {
      final String theme = b == Brightness.dark ? 'dark' : 'light';
      if (onlyTheme != null && onlyTheme != theme) continue;
      final String tag = '${phone.key}-$theme';

      Future<void> open(
        WidgetTester tester,
        AppState app,
        Pill pill, {
        Duration settle = const Duration(milliseconds: 2200),
      }) async {
        tester.view.physicalSize = phone.value * 3;
        tester.view.devicePixelRatio = 3;
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        addTearDown(tester.view.reset);
        final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: nav,
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildAstutoTheme(b),
            debugShowCheckedModeBanner: false,
            home: _Behind(pill: pill),
          ),
        );
        await tester.pump();
        unawaited(showDeeperSheet(nav.currentContext!, app, pill));
        await tester.pump();
        for (Duration t = Duration.zero; t < settle; t += _frame) {
          await tester.pump(_frame);
        }
      }

      Future<void> shoot(WidgetTester tester, String name) => expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$out/$name-$tag.png'),
      );

      /// Draws the sheet up to its full height, as a reader's thumb does.
      Future<void> raise(WidgetTester tester) async {
        await tester.timedDrag(
          find.byKey(const ValueKey('deeper-head')),
          Offset(0, -phone.value.height * 0.3),
          const Duration(milliseconds: 900),
        );
        for (int i = 0; i < 8; i++) {
          await tester.pump(_frame);
        }
        // Whatever the thumb went past the top, back: the sheet at its
        // full height, its head in place.
        await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey('deeper-head'))),
        );
        for (int i = 0; i < 8; i++) {
          await tester.pump(_frame);
        }
      }

      /// Scrolls [key]'s part to [at] of the way down the sheet.
      Future<void> scrollTo(
        WidgetTester tester,
        Key key, {
        double at = 0.04,
      }) async {
        await Scrollable.ensureVisible(
          tester.element(find.byKey(key)),
          alignment: at,
        );
        for (int i = 0; i < 8; i++) {
          await tester.pump(_frame);
        }
      }

      Future<void> tapText(WidgetTester tester, String text) async {
        final Finder f = find.text(text).last;
        await tester.ensureVisible(f);
        await tester.pump();
        await tester.tap(f);
        for (int i = 0; i < 14; i++) {
          await tester.pump(_frame);
        }
      }

      testWidgets('written, $tag', (tester) async {
        debugToolsOn = false;
        final app = await _app(plus: true);
        await open(tester, app, written());
        await shoot(tester, 'written-1');
        await raise(tester);
        await scrollTo(tester, const ValueKey('deeper-why'));
        await shoot(tester, 'written-2');
        await scrollTo(tester, const ValueKey('deeper-views'));
        await shoot(tester, 'written-3');
        await scrollTo(tester, const ValueKey('deeper-source'), at: 0.7);
        await shoot(tester, 'written-4');
      });

      testWidgets('style, $tag', (tester) async {
        debugToolsOn = true;
        addTearDown(() => debugToolsOn = false);
        final app = await _app(plus: true);
        await open(tester, app, written());
        await raise(tester);
        await shoot(tester, 'style-$style-1');
        await scrollTo(tester, const ValueKey('deeper-views'));
        await shoot(tester, 'style-$style-2');
      });

      // The parts as an article: the lead, the debate, the buttons that
      // ask waiting, one answer coming, then answered, and the reader's own
      // idea looked at.
      testWidgets('article, $tag', (tester) async {
        debugToolsOn = true;
        addTearDown(() => debugToolsOn = false);
        final Completer<void> hold = Completer<void>();
        CardAsk.call = (card, mode, {text = '', required language}) async {
          if (mode == AskMode.example) await hold.future;
          return _answer(mode, text);
        };
        addTearDown(() {
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later);
        });
        final AppLocalizations l = await AppLocalizations.delegate.load(
          Locale(lang),
        );
        final app = await _app(plus: true);
        await open(tester, app, written());
        await raise(tester);
        await shoot(tester, 'article-1');
        await scrollTo(tester, const ValueKey('deeper-views'));
        await shoot(tester, 'article-2');
        await scrollTo(tester, const ValueKey('deeper-example-ai'));
        await shoot(tester, 'article-3');
        await tester.tap(find.text(l.deeperExampleGo));
        for (int i = 0; i < 17; i++) {
          await tester.pump(_frame);
        }
        await shoot(tester, 'article-4');
        hold.complete();
        for (int i = 0; i < 30; i++) {
          await tester.pump(_frame);
        }
        await scrollTo(tester, const ValueKey('deeper-example-ai'));
        await shoot(tester, 'article-5');
        await scrollTo(tester, const ValueKey('deeper-take'));
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('deeper-take')),
            matching: find.byType(TextField),
          ),
          'Secondo me il test sbaglia una volta su venti, quindi è quasi '
          'sempre giusto.',
        );
        await tester.pump();
        await tapText(tester, l.deeperAnalyse);
        for (int i = 0; i < 20; i++) {
          await tester.pump(_frame);
        }
        await scrollTo(tester, const ValueKey('deeper-take'));
        await shoot(tester, 'article-6');
      });

      testWidgets('entrance, $tag', (tester) async {
        debugToolsOn = false;
        final app = await _app(plus: true);
        // The sheet still rising, its head's words coming up into place;
        // then the first part landing, its picture drawing itself in.
        await open(
          tester,
          app,
          written(),
          settle: const Duration(milliseconds: 200),
        );
        await shoot(tester, 'entrance-1');
        for (int i = 0; i < 7; i++) {
          await tester.pump(_frame);
        }
        await shoot(tester, 'entrance-2');
      });

      testWidgets('free, $tag', (tester) async {
        debugToolsOn = true;
        addTearDown(() => debugToolsOn = false);
        final app = await _app(plus: false);
        await open(tester, app, written());
        await raise(tester);
        await scrollTo(tester, const ValueKey('deeper-why'));
        await shoot(tester, 'free-1');
        await scrollTo(tester, const ValueKey('deeper-example-ai'));
        await shoot(tester, 'free-2');
        await scrollTo(tester, const ValueKey('deeper-take'));
        await shoot(tester, 'free-3');
        await scrollTo(tester, const ValueKey('deeper-source'), at: 0.75);
        await shoot(tester, 'free-4');
      });

      // What a still cannot show, in stills: the head's lights at three
      // moments of their drift, and the head held back as the parts slide
      // up over it.
      if (phone.key == 'medium') {
        testWidgets('motion, $tag', (tester) async {
          debugToolsOn = false;
          final app = await _app(plus: true);
          await open(tester, app, written(), settle: Duration.zero);
          // At 1.2, 5.6 and 9.6 seconds of the sixteen the lights drift.
          int at = 0;
          for (final (String name, int ms) in [
            ('drift-1', 1200),
            ('drift-2', 5600),
            ('drift-3', 9600),
          ]) {
            while (at < ms) {
              final int step = (ms - at).clamp(0, 400);
              await tester.pump(Duration(milliseconds: step));
              at += step;
            }
            await shoot(tester, name);
          }
          await raise(tester);
          await tester.timedDrag(
            find.byKey(const ValueKey('deeper-simple')),
            const Offset(0, -150),
            const Duration(milliseconds: 700),
          );
          await tester.pump(_frame);
          await shoot(tester, 'parallax');
        });
      }

      // Each subject is its own world: the medium phone only, the sheet
      // drawn up, with Claude's parts on and waiting to be asked.
      if (phone.key == 'medium') {
        for (final String subject in _subjects) {
          testWidgets('subject $subject, $tag', (tester) async {
            debugToolsOn = true;
            addTearDown(() => debugToolsOn = false);
            final app = await _app(plus: true);
            final Pill pill = PillBank.cards.firstWhere(
              (p) => p.topic == subject && p.question.length < 90,
              orElse: () =>
                  PillBank.cards.firstWhere((p) => p.topic == subject),
            );
            await open(tester, app, pill);
            await raise(tester);
            await shoot(
              tester,
              'subject-${subject.toLowerCase().replaceAll(' ', '_')}',
            );
          });
        }
      }

      testWidgets('answer, $tag', (tester) async {
        debugToolsOn = true;
        addTearDown(() => debugToolsOn = false);
        // The example's answer waits until it is let go, for the frame
        // with the light crossing its button.
        final Completer<void> hold = Completer<void>();
        CardAsk.call = (card, mode, {text = '', required language}) async {
          if (mode == AskMode.example) await hold.future;
          return _answer(mode, text);
        };
        addTearDown(() {
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later);
        });
        final app = await _app(plus: true);
        await open(tester, app, bare());
        final AppLocalizations l = await AppLocalizations.delegate.load(
          Locale(lang),
        );
        // Asked where the sheet opens, without scrolling to it.
        await tester.tap(find.text(l.deeperSimpleGo));
        for (int i = 0; i < 24; i++) {
          await tester.pump(_frame);
        }
        await shoot(tester, 'answer-1');

        await raise(tester);
        await scrollTo(tester, const ValueKey('deeper-example-ai'));
        await tester.tap(find.text(l.deeperExampleGo));
        for (int i = 0; i < 15; i++) {
          await tester.pump(_frame);
        }
        await shoot(tester, 'answer-busy');
        hold.complete();
        for (int i = 0; i < 12; i++) {
          await tester.pump(_frame);
        }

        await scrollTo(tester, const ValueKey('deeper-quiz-ai'));
        await tapText(tester, l.deeperQuizGo);
        for (int i = 0; i < 6; i++) {
          await tester.pump(_frame);
        }
        // A wrong pick, to show the right one found and the wrong one marked.
        await tester.tap(find.byKey(const ValueKey('deeper-quiz-option-1')));
        for (int i = 0; i < 12; i++) {
          await tester.pump(_frame);
        }
        await scrollTo(tester, const ValueKey('deeper-quiz-ai'));
        await shoot(tester, 'answer-2');

        await scrollTo(tester, const ValueKey('deeper-take'));
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('deeper-take')),
            matching: find.byType(TextField),
          ),
          'Secondo me il test sbaglia una volta su venti, quindi è quasi '
          'sempre giusto.',
        );
        await tester.pump();
        await tapText(tester, l.deeperAnalyse);
        await scrollTo(tester, const ValueKey('deeper-take'));
        await shoot(tester, 'answer-3');
      });
    }
  }
}

const Duration _frame = Duration(milliseconds: 50);

/// The subjects shot on their own: Thinking's paper, the light colours
/// that carry black ink and the deep ones that carry white.
const List<String> _subjects = [
  'Thinking',
  'Economics',
  'Space',
  'Nature',
  'Psychology',
  'History',
  'Maths',
  'Life',
];
