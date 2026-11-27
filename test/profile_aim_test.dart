// Where the reader wants to see more clearly, on the profile for every
// reader (lib/widgets/aim_picker.dart): the six areas a card can be useful
// for, each in its colour, the reader's goal picked among them; a pick kept
// as the goal everything that leans to one reads, Explore's shelf of it
// first; the profile the one place it is picked; whole on the 320-wide
// phone in German at 1.6 times the text; and its colours read at night and
// on paper.
//
//   flutter test test/profile_aim_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/goals.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/goal_block.dart' show withAimShelf;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/journey_screen.dart' show coachStats;
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/aim_picker.dart';
import 'package:astuto/widgets/area_marks.dart';
import 'package:astuto/widgets/fit_text.dart';

import 'explore/core_harness.dart';

/// WCAG's contrast between two colours, 1 to 21.
double _contrast(Color a, Color b) {
  final double x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  setUp(PillBank.reset);

  /// A tap on the profile's row, and the sheet of the six up.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('profile-aim-open')));
    await tester.pumpAndSettle();
  }

  /// The section alone, as the profile lays it: a column [size] wide less
  /// the profile's gutters, at night or on paper, in [language], at [text]
  /// times the text.
  Future<void> show(
    WidgetTester tester,
    AppState app, {
    Size size = const Size(390, 844),
    String language = 'en',
    double text = 1,
    bool paper = false,
    bool open = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // A tree of its own each time, so a sheet left open never carries
        // over.
        key: UniqueKey(),
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(paper ? Brightness.light : Brightness.dark),
        // Over every route, as the phone's own text size is: the sheet the
        // row opens is a route of its own.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(text)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: ProfileAim(app: app),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (open) await openSheet(tester);
  }

  Finder row(Goal g) => find.byKey(ValueKey('profile-aim-${g.key}'));
  final Finder summary = find.byKey(const ValueKey('profile-aim-open'));
  final Finder sheet = find.byKey(const ValueKey('profile-aim-sheet'));
  Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
  Finder inSummary(Finder f) => find.descendant(of: summary, matching: f);

  /// The areas shown as picked.
  List<Goal> picked(WidgetTester tester) => [
    for (final Goal g in Goal.values)
      if (tester.widget<AimRow>(row(g)).on) g,
  ];

  testWidgets('shows the reader\'s goal: the one picked here, else the first '
      'area of the skills picked on What to learn, else none', (tester) async {
    final l = lookupAppLocalizations(const Locale('en'));
    final AppState said = await tester.runAsync(
      () => readyApp({
        'knowit.goals': ['people'],
      }),
    ) as AppState;
    // On the profile, the question and one row with the pick: the six
    // stay behind a tap.
    await show(tester, said, open: false);
    expect(find.text(l.aimTitle.toUpperCase()), findsOneWidget);
    expect(inSummary(find.text(goalName(l, Goal.people))), findsOneWidget);
    expect(inSummary(find.text(goalLine(l, Goal.people))), findsOneWidget);
    expect(sheet, findsNothing);
    for (final Goal g in Goal.values) {
      expect(row(g), findsNothing, reason: g.key);
    }
    // The tap brings up the sheet: the question, what a pick does, the six.
    await openSheet(tester);
    expect(inSheet(find.text(l.aimTitle)), findsOneWidget);
    expect(inSheet(find.text(l.aimLine)), findsOneWidget);
    for (final Goal g in Goal.values) {
      expect(row(g), findsOneWidget, reason: g.key);
      expect(inSheet(find.text(goalName(l, g))), findsOneWidget, reason: g.key);
      expect(inSheet(find.text(goalLine(l, g))), findsOneWidget, reason: g.key);
    }
    expect(picked(tester), [Goal.people]);

    final AppState skilled = await tester.runAsync(
      () => readyApp({
        'knowit.skills': ['critical', 'money'],
      }),
    ) as AppState;
    expect(skilled.goals, ['decide', 'money']);
    await show(tester, skilled);
    expect(picked(tester), [Goal.decide]);

    // Before a pick, the row is the way to make one.
    final AppState none = await tester.runAsync(readyApp) as AppState;
    await show(tester, none, open: false);
    expect(inSummary(find.text(l.aimPick)), findsOneWidget);
    expect(inSummary(find.text(l.aimNone)), findsOneWidget);
    await openSheet(tester);
    expect(picked(tester), isEmpty);

    // Asked in Turkish, its capitals keep the dot on the i.
    await show(tester, said, language: 'tr', open: false);
    expect(find.text('NEREDE DAHA NET GÖRMEK İSTERSİN?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pick is the goal, kept, and Explore\'s shelf and the coach '
      'follow at once; a tap on the one picked changes nothing', (
    tester,
  ) async {
    const List<ExploreSection> sections = [
      ExploreSection(id: 'three', block: 'three'),
      ExploreSection(id: 'your-five', block: 'your-five'),
      ExploreSection(id: 'continue', block: 'continue'),
      ExploreSection(id: 'news-today', block: 'news-today'),
    ];
    final l = lookupAppLocalizations(const Locale('en'));
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.goals': ['decide'],
      }),
    ) as AppState;
    await show(tester, app);
    await tester.tap(row(Goal.money));
    await tester.pumpAndSettle();
    expect(app.goals, ['money']);
    // The pick closes the sheet, and the row on the profile is the new one.
    expect(sheet, findsNothing);
    expect(inSummary(find.text(goalName(l, Goal.money))), findsOneWidget);
    await openSheet(tester);
    expect(picked(tester), [Goal.money]);
    final SharedPreferences prefs = await tester.runAsync(
      SharedPreferences.getInstance,
    ) as SharedPreferences;
    expect(prefs.getStringList('knowit.goals'), ['money']);

    // The coach is told it in the reader's words.
    final BuildContext context = tester.element(find.byType(ProfileAim));
    expect(coachStats(context, app)['goal'], l.goalMoney);

    // Explore puts its shelf after Today's five and what to continue, and
    // the shelf is of it.
    expect(
      [for (final s in withAimShelf(app, sections)) s.id],
      ['three', 'your-five', 'continue', 'goal', 'news-today'],
    );
    final List<ExploreSection> shelf = sectionsOf([
      {'id': 'goal', 'block': 'goal'},
    ]);
    await pumpSections(tester, CoreHost(app), shelf);
    expect(find.text(l.goalShelf(l.goalMoney)), findsOneWidget);
    expect(find.text(l.goalMoneyLine), findsOneWidget);

    // Picked again, the shelf follows.
    await show(tester, app);
    await tester.tap(row(Goal.health));
    await tester.pumpAndSettle();
    expect(app.goals, ['health']);
    await pumpSections(tester, CoreHost(app), shelf);
    expect(find.text(l.goalShelf(l.goalHealth)), findsOneWidget);
    expect(find.text(l.goalShelf(l.goalMoney)), findsNothing);

    // The one picked, tapped, is still the one, and nothing else: the
    // sheet goes down as it came.
    await show(tester, app);
    await tester.tap(row(Goal.health));
    await tester.pumpAndSettle();
    expect(app.goals, ['health']);
    expect(sheet, findsNothing);
    await openSheet(tester);
    expect(picked(tester), [Goal.health]);
    expect(tester.takeException(), isNull);
  });

  test('the profile is the one place the goal is picked: skills move the '
      'goals while they are the skills\' own, and never a goal picked '
      'here', () async {
    final AppState app = await readyApp({
      'knowit.skills': ['money'],
    });
    expect(app.goals, ['money']);
    await app.setSkills(['money', 'talk']);
    expect(app.goals, ['money', 'people']);
    // Picked on the profile.
    await app.setGoals(['health']);
    await app.setSkills(['money', 'talk', 'critical']);
    expect(app.goals, ['health']);
    expect(app.skills, ['money', 'talk', 'critical']);
    await app.setSkills(const []);
    expect(app.goals, ['health']);
  });

  testWidgets('whole on the 320-wide phone, in German, at 1.6 times the '
      'text: no row runs off, and no word breaks in two', (tester) async {
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.goals': ['decide'],
      }),
    ) as AppState;
    for (final double text in [1, 1.6]) {
      final TextScaler scaler = TextScaler.linear(text);
      // Each word of a name and of a line fits a line of its own in the
      // width it was laid out in: none is broken across two.
      void whole(Finder box, String what) {
        final Rect rect = tester.getRect(box);
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$what ×$text');
        expect(rect.right, lessThanOrEqualTo(320), reason: '$what ×$text');
        for (final Element e
            in find
                .descendant(of: box, matching: find.byType(Text))
                .evaluate()) {
          final Text t = e.widget as Text;
          final double width = e.size!.width;
          expect(
            FitText.wordsFit(
              t.data!,
              t.style!,
              scaler,
              TextDirection.ltr,
              width + 0.5,
            ),
            isTrue,
            reason: '$what: "${t.data}" at ×$text in $width',
          );
        }
      }

      // The row on the profile, with the longest name of the six picked.
      await show(
        tester,
        app,
        size: const Size(320, 568),
        language: 'de',
        text: text,
        open: false,
      );
      expect(tester.takeException(), isNull, reason: 'row ×$text');
      whole(summary, 'the row');
      // And the six it opens.
      await openSheet(tester);
      expect(tester.takeException(), isNull, reason: '×$text');
      for (final Goal g in Goal.values) {
        whole(row(g), g.key);
      }
    }
    // The one picked, whole, at ×1.6: in the row and in the sheet.
    final String decide = goalName(
      lookupAppLocalizations(const Locale('de')),
      Goal.decide,
    );
    expect(inSummary(find.text(decide)), findsOneWidget);
    expect(inSheet(find.text(decide)), findsOneWidget);
  });

  testWidgets('night and paper: each area\'s colour reads as a mark on its '
      'row, six colours apart, the row picked edged and ticked in its own', (
    tester,
  ) async {
    final AppState app = await tester.runAsync(
      () => readyApp({
        'knowit.goals': ['money'],
      }),
    ) as AppState;
    for (final bool paper in [false, true]) {
      final Palette p = paper ? Palette.light : Palette.dark;
      final String page = paper ? 'paper' : 'night';
      final Set<int> tones = {};
      for (final Goal g in Goal.values) {
        final Color tone = goalTone(g, p);
        tones.add(tone.toARGB32());
        // A mark is a picture that says something: 3 to 1 at least, on the
        // row it is drawn on, picked or not.
        expect(
          _contrast(tone, p.surfaceRaised),
          greaterThanOrEqualTo(3),
          reason: '${g.key} on $page',
        );
        expect(
          _contrast(
            tone,
            Color.alphaBlend(
              tone.withValues(alpha: paper ? 0.08 : 0.13),
              p.surfaceRaised,
            ),
          ),
          greaterThanOrEqualTo(3),
          reason: '${g.key} on $page, picked',
        );
      }
      expect(tones, hasLength(Goal.values.length), reason: page);
      // At night the subjects' own colours; on paper, deepened.
      expect(
        goalTone(Goal.money, p),
        paper ? isNot(goalHue(Goal.money)) : goalHue(Goal.money),
      );

      await show(tester, app, paper: paper);
      final Color money = goalTone(Goal.money, p);
      // The row on the profile wears the pick's colour too: its ring and
      // its glyph.
      expect(
        tester.widgetList<Icon>(inSummary(find.byType(Icon))).first.color,
        money,
        reason: page,
      );
      final Iterable<Icon> icons = tester.widgetList<Icon>(
        find.descendant(of: row(Goal.money), matching: find.byType(Icon)),
      );
      expect(icons.map((i) => i.color), contains(money), reason: page);
      final BoxDecoration edge =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: row(Goal.money),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(
        (edge.border! as Border).top.color,
        money.withValues(alpha: 0.85),
        reason: page,
      );
      final BoxDecoration plain =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: row(Goal.news),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect((plain.border! as Border).top.color, p.line, reason: page);
      expect(tester.takeException(), isNull);
    }
  });
}
