import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/card_ask.dart';
import 'package:astuto/theme.dart';
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

Future<void> _open(WidgetTester tester, AppState app, Pill pill) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.light),
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

    await tester.tap(find.text('Explain it simply').last);
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
    expect(
      CardAsk.read('nonsense'),
      isA<AskNone>().having((n) => n.why, 'why', AskWhyNot.later),
    );
  });

  test('a page says its source was tapped', () {
    expect(PageMessage.parse('{"t":"deeper"}'), isA<PageDeeper>());
  });
}
