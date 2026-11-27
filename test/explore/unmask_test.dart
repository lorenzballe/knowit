// Charts that mislead (lib/widgets/explore/unmask_chart.dart). The card asks
// before it tells; its button says the trick with the chart's own numbers
// and draws the same numbers fairly; the trick hides again and the question
// comes back. A section picks its look, and every chart, in every language,
// at the largest text, is said whole.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/explore_mix.dart' show canUnmask;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/unmask_chart.dart';

import 'core_harness.dart';

void main() {
  setUpAll(loadFonts);

  final List<Pill> charts = PillBank.cards.where(canUnmask).toList();
  TrickScene scene(Pill p) => p.scene as TrickScene;

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// [pill]'s card alone, in [look] and [locale], at [text] times the text
  /// size, with its motion or without; the words it is drawn in.
  Future<AppLocalizations> card(
    WidgetTester tester,
    Pill pill, {
    UnmaskLook look = UnmaskLook.recommended,
    Locale locale = const Locale('en'),
    double text = 1,
    bool calm = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(text),
              disableAnimations: calm,
            ),
            child: Scaffold(
              body: Center(
                child: UnmaskRow(
                  key: ValueKey('${look.id} ${pill.id} $locale $text'),
                  look: look,
                  pills: [pill],
                  onOpen: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return lookupAppLocalizations(locale);
  }

  /// To the end of the card's turn, and of its words changing over.
  Future<void> settle(WidgetTester tester) async {
    for (int f = 0; f < 12; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  /// [text] as the card sets it, its last two words held together by a
  /// no-break space so that a line never ends on one short word alone.
  Finder words(String text) => find.byWidgetPredicate(
    (w) =>
        w is Text && w.data?.replaceAll(' ', ' ') == text.replaceAll(' ', ' '),
  );

  testWidgets('before and after, the look a section gets: the question '
      'first, then the trick said with the chart\'s own numbers and the same '
      'numbers drawn fairly under the original; then the question again', (
    tester,
  ) async {
    phone(tester);
    expect(UnmaskLook.named(null), UnmaskLook.beforeAfter);
    final Pill p = charts.firstWhere(
      (p) => scene(p).trick == TrickSceneKind.truncated,
    );
    final TrickScene s = scene(p);
    final AppLocalizations l = await card(tester, p);
    final String said = unmaskTrickSaid(l, s);
    // Where the cut axis starts, as the mark on it says it: with the one
    // precision every mark on that axis has.
    expect(
      said,
      contains(
        unmaskFigure(
          s.shown.lo,
          unmaskAxisDecimals(s.shown.lo, s.shown.hi),
          s.unit,
          trim: false,
        ),
      ),
    );
    // The two charts' names, which show only once there are two charts.
    final Finder before = find.text(l.unmaskOriginal.toUpperCase());
    final Finder after = find.text(l.unmaskCorrected.toUpperCase());
    final Finder button = find.byKey(ValueKey('unmask-${p.id}'));

    expect(words(l.unmaskAsk), findsOneWidget);
    expect(words(said), findsNothing);
    expect(before.hitTestable(), findsNothing);
    expect(after.hitTestable(), findsNothing);
    expect(find.text(l.unmaskShowTrick), findsOneWidget);

    await tester.tap(button);
    await settle(tester);
    expect(words(said), findsOneWidget);
    expect(words(l.unmaskAsk), findsNothing);
    expect(before.hitTestable(), findsOneWidget);
    expect(after.hitTestable(), findsOneWidget);
    expect(find.text(l.unmaskHideTrick), findsOneWidget);

    await tester.tap(button);
    await settle(tester);
    expect(words(l.unmaskAsk), findsOneWidget);
    expect(words(said), findsNothing);
    expect(after.hitTestable(), findsNothing);
    expect(find.text(l.unmaskShowTrick), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in place: the chart turns fair where it stands, under its '
      'honest headline, and the switch goes back to the original without '
      'taking the trick back', (tester) async {
    phone(tester);
    final Pill p = charts.first;
    final TrickScene s = scene(p);
    final AppLocalizations l = await card(tester, p, look: UnmaskLook.inPlace);
    final String said = unmaskTrickSaid(l, s);
    final Finder original = find.byKey(ValueKey('unmask-${p.id}-original'));
    expect(words(s.headline), findsOneWidget);
    expect(original, findsNothing);

    await tester.tap(find.byKey(ValueKey('unmask-${p.id}')));
    await settle(tester);
    expect(words(said), findsOneWidget);
    expect(words(s.honest), findsOneWidget);

    await tester.tap(original);
    await settle(tester);
    expect(words(said), findsOneWidget);
    expect(words(s.headline), findsOneWidget);
    expect(find.byKey(ValueKey('unmask-${p.id}-corrected')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a section names its look; one that names none gets before '
      'and after; the first version keeps its own words', (tester) async {
    final CoreHost host = CoreHost(await readyApp());
    final AppLocalizations l = lookupAppLocalizations(const Locale('en'));
    for (final (String? look, String title, bool asks) in [
      (null, l.unmaskMisleadTitle, true),
      ('in-place', l.unmaskMisleadTitle, true),
      ('current', l.unmaskTitle, false),
    ]) {
      await pumpSections(
        tester,
        host,
        sectionsOf([
          {'id': 'unmask-${look ?? 'none'}', 'block': 'unmask', 'look': ?look},
        ]),
        size: const Size(402, 1200),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('mix-unmask')), findsOneWidget);
      expect(find.text(title), findsOneWidget, reason: look);
      expect(
        words(l.unmaskAsk),
        asks ? findsWidgets : findsNothing,
        reason: look,
      );
    }
  });

  testWidgets('every chart, in every language, at the largest text: the '
      'question, the trick said and the headlines whole, nothing cut', (
    tester,
  ) async {
    phone(tester);
    final List<String> problems = [];
    void check(String where, Pill p) {
      final Object? error = tester.takeException();
      if (error != null) {
        problems.add('$where: ${error.toString().split('\n').first}');
      }
      // Words too long for their box at their smallest scroll in it rather
      // than being cut: here, none has anywhere to scroll.
      for (final ScrollableState box in tester.stateList<ScrollableState>(
        find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      )) {
        if (box.position.maxScrollExtent <= 0.5) continue;
        final Iterable<Text> held = tester.widgetList<Text>(
          find.descendant(
            of: find.byWidget(box.widget),
            matching: find.byType(Text),
          ),
        );
        problems.add('$where: "${held.map((t) => t.data).join(' ')}" is cut');
      }
      // The button's words on their one line.
      for (final RenderParagraph label
          in tester.renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byKey(ValueKey('unmask-${p.id}')),
              matching: find.byType(RichText),
            ),
          )) {
        if (label.didExceedMaxLines) {
          problems.add('$where: "${label.text.toPlainText()}" is cut');
        }
      }
    }

    for (final Locale locale in AppLocalizations.supportedLocales) {
      for (final UnmaskLook look in [
        UnmaskLook.beforeAfter,
        UnmaskLook.inPlace,
      ]) {
        for (final Pill p in charts) {
          final String where = '$locale ${look.id} ${p.id}';
          await card(
            tester,
            p,
            look: look,
            locale: locale,
            text: 1.35,
            calm: true,
          );
          check('$where, asked', p);
          await tester.tap(find.byKey(ValueKey('unmask-${p.id}')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          check('$where, told', p);
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
