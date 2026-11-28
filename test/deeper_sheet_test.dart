import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ShaderMaskLayer;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/card_ask.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/deeper/app_style.dart' show TopDissolve;
import 'package:astuto/widgets/deeper/editorial.dart' show deeperEditorial;
import 'package:astuto/widgets/deeper/look.dart';
import 'package:astuto/widgets/deeper/pieces.dart' show splitView;
import 'package:astuto/widgets/deeper_sheet.dart';
import 'package:astuto/widgets/web/page_messages.dart';

Pill _card({bool full = true}) => cardFromJson({
  'id': 'thinking-deeper',
  'topic': 'thinking',
  'kind': 'read',
  'difficulty': 'easy',
  'question': 'Why do rare illnesses fool good tests?',
  'answer': 'Because the illness is rare.',
  'move': 'Ask how common it is first.',
  'source': 'Kahneman, Thinking, Fast and Slow, 2011',
  'reference': 'doi:10.1000/xyz',
  if (full) ...{
    'simply': 'A tiny crowd of ill people hides in a huge crowd of well ones.',
    'why': 'It changes how you read every screening result.',
    'views': [
      'Screen everyone: it finds cases early.',
      'Screen few: it saves false alarms.',
    ],
  },
});

Future<AppState> _app({required bool plus}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
  });
  final app = AppState();
  await app.init();
  return app;
}

Future<void> _open(
  WidgetTester tester,
  AppState app,
  Pill pill, {
  Brightness theme = Brightness.light,
  Size size = const Size(420, 1400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(theme),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showDeeperSheet(context, app, pill),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    debugToolsOn = false;
  });

  test('a card carries the link to its source, a DOI made one', () {
    expect(_card().reference, 'https://doi.org/10.1000/xyz');
    // A reference in words keeps its words and carries its link at the end.
    expect(
      referenceLink(
        'Hole, Hirsch, Ball & Meads, Music as an aid for postoperative '
        'recovery in adults, The Lancet, 2015, '
        'doi:10.1016/S0140-6736(15)60169-6',
      ),
      'https://doi.org/10.1016/S0140-6736(15)60169-6',
    );
    expect(
      referenceLink('WHO, Malaria fact sheet, 2023, https://www.who.int/x.'),
      'https://www.who.int/x',
    );
    expect(referenceLink('Kahneman, Thinking, Fast and Slow, 2011'), '');
    expect(
      referenceLink('https://example.org/page'),
      'https://example.org/page',
    );
  });

  testWidgets('on Astute+, everything the card file adds, and the way to '
      'the original; no answers asked for while they are off', (tester) async {
    await _open(tester, await _app(plus: true), _card());
    expect(find.byKey(const ValueKey('deeper-simple')), findsOneWidget);
    expect(
      find.text('It changes how you read every screening result.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('deeper-views')), findsOneWidget);
    expect(find.byKey(const ValueKey('deeper-open-source')), findsOneWidget);
    expect(find.byKey(const ValueKey('deeper-take')), findsNothing);
    expect(find.text('With Astute+'), findsNothing);
  });

  test('a card keeps its video beside its source, read and written with it, '
      'and only a secure address with a maker counts', () {
    Pill withWatch(Object? watch) => cardFromJson({
      'id': 'nature-watch',
      'topic': 'nature',
      'kind': 'read',
      'difficulty': 'easy',
      'question': 'Could half a mountain fall into the sea?',
      'answer': 'Yes.',
      'move': 'Look at the flank.',
      'source': 'Urlaub et al., Science Advances, 2018',
      'reference': 'doi:10.1126/sciadv.aat9700',
      'watch': watch,
    });
    final Pill pill = withWatch({
      'url': 'https://www.youtube.com/watch?v=cwdZkSbbYhw',
      'by': 'Geopop (YouTube, 2018)',
    });
    expect(pill.watch?.by, 'Geopop (YouTube, 2018)');
    expect(pill.reference, 'https://doi.org/10.1126/sciadv.aat9700');
    expect(cardToJson(pill)['watch'], {
      'url': 'https://www.youtube.com/watch?v=cwdZkSbbYhw',
      'by': 'Geopop (YouTube, 2018)',
    });
    expect(cardFromJson(cardToJson(pill)).watch?.url, pill.watch?.url);
    // Today's five are kept on the phone this way: a day opened again keeps
    // the way to the original, not only its words.
    expect(
      cardFromJson(cardToJson(pill)).reference,
      'https://doi.org/10.1126/sciadv.aat9700',
    );
    expect(withWatch(null).watch, isNull);
    expect(cardToJson(withWatch(null)).containsKey('watch'), isFalse);
    expect(withWatch({'url': 'http://x.org/v', 'by': 'X'}).watch, isNull);
    expect(withWatch({'url': 'https://x.org/v', 'by': ' '}).watch, isNull);
  });

  testWidgets('a card with a video offers it as Watch more under the source, '
      'named with who made it', (tester) async {
    final Pill pill = cardFromJson({
      ...cardToJson(_card()),
      'watch': {
        'url': 'https://www.youtube.com/watch?v=cwdZkSbbYhw',
        'by': 'Geopop (YouTube, 2018)',
      },
    });
    await _open(tester, await _app(plus: false), pill);
    expect(find.byKey(const ValueKey('deeper-open-source')), findsOneWidget);
    final Finder watch = find.byKey(const ValueKey('deeper-watch'));
    expect(watch, findsOneWidget);
    expect(
      find.descendant(
        of: watch,
        matching: find.textContaining(
          'Watch more  ·  Geopop (YouTube, 2018)',
          findRichText: true,
        ),
      ),
      findsOneWidget,
    );
    // Under the source's own way out, never in its place.
    expect(
      tester.getTopLeft(watch).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('deeper-open-source'))).dy,
      ),
    );
  });

  testWidgets('a card without a video shows no Watch more', (tester) async {
    await _open(tester, await _app(plus: true), _card());
    expect(find.byKey(const ValueKey('deeper-watch')), findsNothing);
  });

  testWidgets('on the free plan, why it matters and the two views wait '
      'behind glass with the way through', (tester) async {
    await _open(tester, await _app(plus: false), _card());
    expect(find.text('With Astute+'), findsNWidgets(2));
    // The simple version and the source are for everybody.
    expect(find.byKey(const ValueKey('deeper-simple')), findsOneWidget);
    expect(find.byKey(const ValueKey('deeper-open-source')), findsOneWidget);
  });

  testWidgets('with the answers on: the card said simply on request, and '
      'the reader\'s own reasoning looked at', (tester) async {
    debugToolsOn = true;
    final List<(AskMode, String)> asked = [];
    CardAsk.call = (card, mode, {text = '', required language}) async {
      asked.add((mode, text));
      return AskAnswer('Answer for ${mode.name}.');
    };
    addTearDown(
      () =>
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later),
    );
    await _open(tester, await _app(plus: true), _card(full: false));

    // The part says what it is; its button, what it does.
    expect(_name('Explain it simply'), findsOneWidget);
    await tester.tap(find.text('Explain it'));
    await tester.pumpAndSettle();
    expect(find.text('Answer for simple.'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('deeper-take')),
        matching: find.byType(TextField),
      ),
      'I think the test is wrong half the time.',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Look at it'));
    await tester.tap(find.text('Look at it'));
    await tester.pumpAndSettle();
    expect(find.text('Answer for take.'), findsOneWidget);
    expect(asked.last, (
      AskMode.take,
      'I think the test is wrong half the time.',
    ));
  });

  testWidgets('a new case to answer on the spot: the question, three options, '
      'and after a pick the verdict and why', (tester) async {
    debugToolsOn = true;
    CardAsk.call = (card, mode, {text = '', required language}) async =>
        mode == AskMode.quiz
        ? const AskAnswer(
            'Q: A shop says 9 in 10 buyers love its blender. What do you ask?\n'
            'A) How many buyers it asked\n'
            'B) Which colour it comes in\n'
            'C) Nothing: 9 in 10 is plenty\n'
            'RIGHT: A\n'
            'WHY: Ten buyers or ten thousand make a different claim. The big '
            'number tempts because it sounds settled.',
          )
        : const AskNone(AskWhyNot.later);
    addTearDown(
      () =>
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later),
    );
    await _open(tester, await _app(plus: true), _card(full: false));

    final Finder button = find.text('Test me');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'A shop says 9 in 10 buyers love its blender. What do you ask?',
      ),
      findsOneWidget,
    );
    // A wrong pick: not quite, and why.
    await tester.ensureVisible(find.text('Nothing: 9 in 10 is plenty'));
    await tester.tap(find.text('Nothing: 9 in 10 is plenty'));
    await tester.pumpAndSettle();
    expect(find.text('Not quite.'), findsOneWidget);
    expect(find.textContaining('Ten buyers or ten thousand'), findsOneWidget);
    // Answered once: another tap changes nothing.
    await tester.tap(find.text('How many buyers it asked'));
    await tester.pumpAndSettle();
    expect(find.text('Right.'), findsNothing);
  });

  test('a quiz is read from the one shape the server writes, and nothing '
      'else is one', () {
    final CardQuiz? quiz = CardQuiz.parse(
      '**Q:** Why?\nA) x\nB)  y \nC) z\nRIGHT: C\nWHY: because.',
    );
    expect(quiz?.question, 'Why?');
    expect(quiz?.options, ['x', 'y', 'z']);
    expect(quiz?.right, 2);
    expect(quiz?.why, 'because.');
    expect(CardQuiz.parse('Q: Why?\nA) x\nB) y\nWHY: because'), isNull);
    expect(CardQuiz.parse('Some words about the card.'), isNull);
  });

  testWidgets('an idea of a book with no link of its own leads to the book '
      'in the open library catalogue', (tester) async {
    final Pill idea = cardFromJson({
      'id': 'thinking-book-x-1',
      'topic': 'thinking',
      'kind': 'read',
      'difficulty': 'easy',
      'question': 'Why do we trust the first number we hear?',
      'answer': 'Because it anchors.',
      'move': 'Name your own number first.',
      'source': 'Daniel Kahneman, Thinking, Fast and Slow, 2011',
      'reference': 'Daniel Kahneman, Thinking, Fast and Slow (2011), ch. 11',
      'book': {
        'id': 'x',
        'title': 'Thinking, Fast and Slow',
        'author': 'Daniel Kahneman',
        'year': 2011,
        'part': 1,
        'isbn': '9780374533557',
        'badge': 'By a Nobel laureate in economics',
      },
    });
    expect(idea.reference, isEmpty);
    await _open(tester, await _app(plus: false), idea);
    expect(find.byKey(const ValueKey('deeper-open-source')), findsOneWidget);
  });

  test('what the server says back, read', () {
    expect(CardAsk.read({'text': ' Yes. '}), isA<AskAnswer>());
    expect(
      CardAsk.read({'none': 'declined'}),
      isA<AskNone>().having((n) => n.why, 'why', AskWhyNot.declined),
    );
    // What the AI may spend is spent (functions/src/limits.ts): not available
    // right now, said politely, with nothing to try again.
    expect(
      CardAsk.read({'none': 'unavailable'}),
      isA<AskNone>().having((n) => n.why, 'why', AskWhyNot.unavailable),
    );
    expect(
      CardAsk.read('nonsense'),
      isA<AskNone>().having((n) => n.why, 'why', AskWhyNot.later),
    );
  });

  test('a page says its source was tapped', () {
    expect(PageMessage.parse('{"t":"deeper"}'), isA<PageDeeper>());
  });

  testWidgets('the two views face each other, each under its own label', (
    tester,
  ) async {
    await _open(tester, await _app(plus: true), _card());
    expect(find.text('Screen everyone'), findsOneWidget);
    expect(find.text('it finds cases early.'), findsOneWidget);
    expect(find.text('Screen few'), findsOneWidget);
    expect(find.text('it saves false alarms.'), findsOneWidget);
    // Set editorially, the views stand under their labels with no VS.
    expect(find.text('VS'), deeperEditorial ? findsNothing : findsOneWidget);
  });

  test('a view is split into its label and its words; one with no label '
      'of its own is given one', () {
    expect(splitView('Screen everyone: it finds cases early.', 'One side'), (
      'Screen everyone',
      'it finds cases early.',
    ));
    expect(splitView('Nobody labelled this view.', 'One side'), (
      'One side',
      'Nobody labelled this view.',
    ));
  });

  testWidgets('on the free plan with the answers on, every part Claude '
      'writes is marked, and asking opens the paywall instead', (tester) async {
    debugToolsOn = true;
    int asked = 0;
    CardAsk.call = (card, mode, {text = '', required language}) async {
      asked++;
      return const AskAnswer('Never shown.');
    };
    addTearDown(
      () =>
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later),
    );
    await _open(tester, await _app(plus: false), _card());
    // Why and the views behind glass, as before; the example, the new
    // case, the reader's idea and their question marked.
    expect(find.text('With Astute+'), findsNWidgets(2));
    expect(find.text('ASTUTE+'), findsNWidgets(4));
    final Finder example = find.text('Give me an example');
    await tester.ensureVisible(example);
    await tester.tap(example);
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(asked, 0);
  });

  testWidgets('while the answer comes the button says so over lines where '
      'it will be, and then it unfolds in their place', (tester) async {
    debugToolsOn = true;
    final Completer<AskResult> answer = Completer<AskResult>();
    CardAsk.call = (card, mode, {text = '', required language}) =>
        answer.future;
    addTearDown(
      () =>
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later),
    );
    await _open(tester, await _app(plus: true), _card(full: false));
    await tester.tap(find.text('Explain it'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Thinking…'), findsOneWidget);
    answer.complete(const AskAnswer('A small crowd in a big one.'));
    await tester.pumpAndSettle();
    expect(find.text('Thinking…'), findsNothing);
    expect(find.text('A small crowd in a big one.'), findsOneWidget);
  });

  testWidgets('the reader\'s words go up into the conversation; an answer '
      'that did not come says so, and asking again sends the same words', (
    tester,
  ) async {
    debugToolsOn = true;
    final List<(AskMode, String)> asked = [];
    CardAsk.call = (card, mode, {text = '', required language}) async {
      asked.add((mode, text));
      return asked.length == 1
          ? const AskNone(AskWhyNot.later)
          : const AskAnswer('Strong start; the weak step is the rate.');
    };
    addTearDown(
      () =>
          CardAsk.call = (c, m, {text = '', required language}) async =>
              const AskNone(AskWhyNot.later),
    );
    await _open(tester, await _app(plus: true), _card(full: false));
    const String words = 'The test is right nineteen times in twenty.';
    final Finder box = find.descendant(
      of: find.byKey(const ValueKey('deeper-take')),
      matching: find.byType(TextField),
    );
    await tester.enterText(box, words);
    await tester.pump();
    await tester.ensureVisible(find.text('Look at it'));
    await tester.tap(find.text('Look at it'));
    await tester.pumpAndSettle();
    // Theirs, as a sent message; the box empty for the next words.
    expect(find.text(words), findsOneWidget);
    expect(tester.widget<TextField>(box).controller!.text, isEmpty);
    expect(
      find.text('It didn\'t come through. Try again in a moment.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(asked, [(AskMode.take, words), (AskMode.take, words)]);
    expect(
      find.text('Strong start; the weak step is the rate.'),
      findsOneWidget,
    );
  });

  testWidgets('for a reader who asked for less motion, nothing moves: the '
      'parts are there at once and the head\'s lights are still', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final AppState app = await _app(plus: true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: DeeperSheet(app: app, pill: _card()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    final Opacity first = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('deeper-simple')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(first.opacity, 1);
  });

  for (final Brightness theme in Brightness.values) {
    testWidgets('at twice the text size on a small phone, in the '
        '${theme.name}, every part and every answer lays out', (tester) async {
      debugToolsOn = true;
      CardAsk.call = (card, mode, {text = '', required language}) async =>
          AskAnswer(switch (mode) {
            AskMode.quiz =>
              'Q: Which number do you ask for first?\n'
                  'A) How common it is\nB) How sure the test is\n'
                  'C) How many were tested\nRIGHT: A\n'
                  'WHY: The base rate sets the odds before the test speaks.',
            _ =>
              'An answer long enough to wrap over several lines at a '
                  'large size, with a word like Wahrscheinlichkeitsrechnung.',
          });
      addTearDown(
        () =>
            CardAsk.call = (c, m, {text = '', required language}) async =>
                const AskNone(AskWhyNot.later),
      );
      final AppState app = await _app(plus: true);
      await _open(
        tester,
        app,
        _card(full: false),
        theme: theme,
        size: const Size(360, 740),
        textScale: 2,
      );
      for (final String go in ['Explain it', 'Show me both sides', 'Test me']) {
        await tester.ensureVisible(find.text(go));
        await tester.tap(find.text(go));
        await tester.pumpAndSettle();
      }
      final Finder pick = find.byKey(const ValueKey('deeper-quiz-option-0'));
      await tester.ensureVisible(pick);
      await tester.tap(pick);
      await tester.pumpAndSettle();
      for (final (String key, String send) in [
        ('deeper-take', 'Look at it'),
        ('deeper-ask', 'Ask'),
      ]) {
        final Finder box = find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(box);
        await tester.enterText(box, 'My own words about the card.');
        await tester.pump();
        await tester.ensureVisible(find.text(send).last);
        await tester.tap(find.text(send).last);
        await tester.pumpAndSettle();
      }
      expect(find.text('My own words about the card.'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  test('every subject\'s sheet reads, in the dark and on paper: names on '
      'their parts, words on their colours, the question on its head', () {
    for (final TopicStyle subject in kTopics.values) {
      for (final bool dark in [true, false]) {
        final Palette p = dark ? Palette.dark : Palette.light;
        final DeeperLook look = DeeperLook.of(subject.color, dark: dark);
        final String where = '${subject.name}, ${dark ? 'dark' : 'light'}';
        for (final DeeperPart part in DeeperPart.values) {
          final DeeperTone tone = look.tone(part);
          for (final Color ground in [tone.tile, tone.wash]) {
            expect(
              contrastOf(tone.title, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$where, ${part.name}: its name',
            );
            expect(
              contrastOf(p.ink, ground),
              greaterThanOrEqualTo(7),
              reason: '$where, ${part.name}: its words',
            );
            expect(
              contrastOf(p.inkMuted, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$where, ${part.name}: the line under its name',
            );
          }
          expect(
            contrastOf(tone.accent, tone.field),
            greaterThanOrEqualTo(3),
            reason: '$where, ${part.name}: its marks',
          );
          expect(
            contrastOf(p.ink, tone.field),
            greaterThanOrEqualTo(7),
            reason: '$where, ${part.name}: words in its box',
          );
          for (final Color fill in [tone.vivid.fill, tone.vivid.deep]) {
            expect(
              contrastOf(tone.vivid.ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$where, ${part.name}: its button',
            );
          }
        }
        for (final DeeperVivid side in [look.sideA, look.sideB]) {
          for (final Color fill in [side.fill, side.deep]) {
            expect(
              contrastOf(side.ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$where: a view on its half',
            );
          }
        }
        // The question is large, so three to one is the bar for it; on a
        // light card, where the ink is dark, four and a half. No light
        // drifting over the head may read worse than the card itself.
        final double need = subject.ink.computeLuminance() < 0.5
            ? 4.5
            : contrastOf(subject.color, subject.ink).clamp(0, 3) - 0.05;
        for (final Color light in [look.world, ...look.glow]) {
          expect(
            contrastOf(look.worldInk, light),
            greaterThanOrEqualTo(need),
            reason: '$where: the question on its head',
          );
        }
      }
    }
  });

  testWidgets('to a screen reader: the question and every part\'s name are '
      'headings, the asking is a button named for what it does, and the '
      'drawings and the VS stay out of the way', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    debugToolsOn = true;
    await _open(tester, await _app(plus: true), _card());
    expect(
      tester.getSemantics(find.text('Why do rare illnesses fool good tests?')),
      containsSemantics(isHeader: true),
    );
    expect(
      tester.getSemantics(_name('Why it matters')),
      containsSemantics(isHeader: true),
    );
    expect(
      tester.getSemantics(find.text('Give me an example')),
      containsSemantics(
        label: 'Give me an example',
        isButton: true,
        isEnabled: true,
      ),
    );
    expect(find.bySemanticsLabel('VS'), findsNothing);
    semantics.dispose();
  });

  group('scrolled on a phone', () {
    Future<ScrollableState> raised(WidgetTester tester) async {
      debugToolsOn = true;
      await _open(
        tester,
        await _app(plus: true),
        _card(full: false),
        theme: Brightness.dark,
        size: const Size(390, 844),
      );
      // Drawn up to its full height by the reader's thumb.
      await tester.dragFrom(const Offset(195, 700), const Offset(0, -400));
      await tester.pumpAndSettle();
      return tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(DeeperSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
    }

    testWidgets('the parts never run over the question as they go up', (
      tester,
    ) async {
      final ScrollableState list = await raised(tester);
      for (final double at in [0, 40, 80, 120, 160, 200, 240]) {
        list.position.jumpTo(at);
        await tester.pump();
        final double question = tester
            .getBottomLeft(find.text('Why do rare illnesses fool good tests?'))
            .dy;
        final double part = tester
            .getTopLeft(find.byKey(const ValueKey('deeper-simple-ai')))
            .dy;
        expect(question, lessThan(part), reason: 'scrolled $at');
      }
    });

    testWidgets('what scrolls dissolves under the top edge, and only once '
        'it moves; nothing blurs what lies behind a part', (tester) async {
      final ScrollableState list = await raised(tester);
      final RenderObject edge = tester.renderObject(find.byType(TopDissolve));
      list.position.jumpTo(0);
      await tester.pump();
      expect(edge.debugLayer, isNull, reason: 'at rest, whole');
      list.position.jumpTo(120);
      await tester.pump();
      expect(edge.debugLayer, isA<ShaderMaskLayer>());
      // A blur under every part, redone each frame, made the sheet stutter.
      expect(
        find.descendant(
          of: find.byType(DeeperSheet),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });
  });
}

/// A part's name, as it is set: as written, or in small capitals.
Finder _name(String name) => find.textContaining(
  RegExp('^${RegExp.escape(name)}\$', caseSensitive: false),
);
