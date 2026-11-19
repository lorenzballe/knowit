// The news, reasoned (lib/data/news_paper.dart, explore/blocks/core/
// news_block.dart): the morning's paper from the server, kept on the phone,
// found by id like a bank card, and shown on Explore as a shelf of cards
// like every other, each a tap from its card.
//
//   flutter test test/explore/news_block_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/utils/share_link.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';

import 'core_harness.dart';

Map<String, Object?> _card(
  String id, {
  required String date,
  required String expires,
  String topic = 'economics',
}) => {
  'id': id,
  'topic': topic,
  'kind': 'read',
  'difficulty': 'easy',
  'principle': 'none',
  'question': 'Bird flu cost American farms a slice of their hens. Why did the price of eggs double?',
  'answer': 'Because almost nobody stops buying eggs. When one bird in a barn tests positive, the whole flock is culled. Demand barely moved, so a shortfall of under a tenth was settled by price.',
  'move': "When people can't do without something, a small shortage makes a big price.",
  'ask': 'What do I buy whatever it costs?',
  'keywords': ['egg prices', 'bird flu'],
  'era': 'recent',
  'region': 'americas',
  'hook': 'mechanism',
  'mood': 'practical',
  'numeracy': 1,
  'abstraction': 'concrete',
  'shelf_life': 'months',
  'mature': false,
  'language': 'en',
  'figure': 'none',
  'scene': {
    'type': 'news',
    'headline': 'Egg prices hit a record as bird flu empties henhouses',
    'outlet': 'BBC News',
    'reported': ['BBC News', 'The Guardian', 'DW'],
    'date': date,
    'panels': [
      {
        'label': 'What happened',
        'figure': r'$6.23',
        'text': 'The average dozen of eggs in US cities in March, a record.',
      },
      {
        'label': 'Why',
        'text': 'When one hen tests positive for bird flu, the whole barn is culled.',
      },
      {
        'label': 'What it means for you',
        'text':
            "When buyers can't cut back, a small shortage doubles the price.",
      },
    ],
    'expires': expires,
  },
  'source': 'BBC News',
  'source_kind': 'news_archive',
  'reference': 'https://www.bbc.co.uk/news/articles/example',
  'written': date,
};

final Map<String, Object?> _fresh = _card(
  'news-2026-11-16-eggs',
  date: '2026-11-16',
  expires: '2099-12-31',
);
final Map<String, Object?> _stale = _card(
  'news-2026-01-01-old',
  date: '2026-01-01',
  expires: '2026-01-04',
);

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(NewsPaper.reset);
  tearDown(NewsPaper.reset);

  final sections = sectionsOf([
    {
      'id': 'news-today',
      'block': 'news-today',
      'title': {'en': 'The news, reasoned'},
      'subtitle': {'en': "Today's stories, and the why behind each."},
    },
  ]);

  test('the paper is asked for, kept, and found by id; a card past its day '
      'is kept out, and so is one this build cannot read', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var asked = 0;
    NewsPaper.call = () async {
      asked++;
      return {
        'date': '2026-11-16',
        'cards': [
          _fresh,
          _stale,
          {'id': 'broken'},
        ],
      };
    };
    final DateTime morning = DateTime(2026, 11, 16, 7);
    expect(await NewsPaper.refresh(prefs, now: morning), isTrue);
    expect(NewsPaper.date, '2026-11-16');
    expect(
      [for (final p in NewsPaper.on(morning)) p.id],
      ['news-2026-11-16-eggs'],
    );
    expect(
      PillBank.byId('news-2026-11-16-eggs')?.question,
      startsWith('Bird flu'),
    );
    expect(PillBank.byId('news-2026-01-01-old'), isNotNull);
    expect(PillBank.byId('broken'), isNull);
    // Sent to a friend, a card of the paper is the site: it has no page.
    expect(cardLink('news-2026-11-16-eggs'), ShareRef.card.link);
    expect(
      cardLink('economics-1'),
      'https://$kSiteHost/c/economics-1.html?ref=${ShareRef.card.ref}',
    );

    // Asked again within the two hours: not asked.
    expect(
      await NewsPaper.refresh(
        prefs,
        now: morning.add(const Duration(hours: 1)),
      ),
      isFalse,
    );
    expect(asked, 1);
    // Asked again later, the same paper: nothing changed.
    expect(
      await NewsPaper.refresh(
        prefs,
        now: morning.add(const Duration(hours: 3)),
      ),
      isFalse,
    );
    expect(asked, 2);

    // The next start has it from the phone, before asking.
    NewsPaper.reset();
    expect(NewsPaper.on(morning), isEmpty);
    NewsPaper.restore(prefs);
    expect(NewsPaper.date, '2026-11-16');
    expect(NewsPaper.on(morning).single.id, 'news-2026-11-16-eggs');

    // A server that does not answer leaves the paper as it was.
    NewsPaper.call = () async => null;
    expect(await NewsPaper.refresh(prefs, now: morning, force: true), isFalse);
    expect(NewsPaper.on(morning), hasLength(1));
  });

  testWidgets('on Explore the paper is a shelf of cards like any other, '
      "each a tap from its card; on a subject's page only its own stories", (
    tester,
  ) async {
    final app = await _app({});
    NewsPaper.adopt('2026-11-16', [_fresh]);
    final host = CoreHost(app);
    await pumpSections(tester, host, sections);
    expect(find.text('The news, reasoned'), findsOneWidget);
    // A card, as on every shelf: its question on its colour, no clipping.
    expect(find.byType(CardTile), findsOneWidget);
    expect(find.text(_fresh['question']! as String), findsOneWidget);
    expect(
      find.text('Egg prices hit a record as bird flu empties henhouses'),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('explore-news-2026-11-16-eggs')),
    );
    expect(host.opened.single, ('news-today', 'news-2026-11-16-eggs'));

    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['economics']!.name),
      sections,
    );
    expect(find.text('The news, reasoned'), findsOneWidget);
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['space']!.name),
      sections,
    );
    expect(find.text('The news, reasoned'), findsNothing);
  });

  testWidgets('a story read is ticked as on every shelf; a paper of expired '
      'cards, or none, is no section', (tester) async {
    final app = await _app({
      'knowit.seenIds': ['news-2026-11-16-eggs'],
    });
    NewsPaper.adopt('2026-11-16', [_fresh]);
    await pumpSections(tester, CoreHost(app), sections);
    expect(tester.widget<CardTile>(find.byType(CardTile)).read, isTrue);

    NewsPaper.adopt('2026-01-01', [_stale]);
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('The news, reasoned'), findsNothing);
    NewsPaper.reset();
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('The news, reasoned'), findsNothing);
  });
}
