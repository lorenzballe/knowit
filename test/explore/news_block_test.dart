// The news, reasoned (lib/data/news_paper.dart, explore/blocks/core/
// news_block.dart, widgets/news/): the morning's paper from the server, kept
// on the phone, found by id like a bank card, and shown on Explore as a front
// page: the world's most important stories for every subject, a subject's own
// stories on its page, each a tap from its story's page.
//
//   flutter test test/explore/news_block_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/utils/share_link.dart';
import 'package:astuto/widgets/news/news_story_page.dart';

import 'core_harness.dart';

/// A story's page as the paper writes it (functions/src/news.ts).
const Map<String, Object?> _page = {
  'summary':
      'A dozen cost a record \$6.23 in March. Farms lost tens of '
      'millions of hens.',
  'points': [
    'The average dozen of eggs in US cities reached a record \$6.23.',
    'When one bird tests positive, the whole flock is culled.',
    'Tens of millions of laying hens were culled in early 2025.',
    42,
  ],
  'sides': [
    {
      'who': 'Egg farmers',
      'view':
          'Culling whole flocks is the only way to stop the disease spreading.',
    },
    {
      'who': 'Shoppers',
      'view': 'Prices doubled in a year for something nobody can do without.',
    },
  ],
  'sources': [
    {
      'outlet': 'BBC News',
      'title': 'Egg prices hit a record as bird flu empties henhouses',
      'link': 'https://www.bbc.co.uk/news/articles/eggs',
    },
    {
      'outlet': 'The Guardian',
      'title': 'Why eggs cost twice what they did',
      'link': 'https://www.theguardian.com/business/eggs',
    },
    {'outlet': 'Nowhere', 'title': 'Not a page', 'link': 'javascript:alert(1)'},
  ],
  'at': '2026-11-16T05:00:00Z',
};

Map<String, Object?> _card(
  String id, {
  required String date,
  required String expires,
  String topic = 'economics',
  String headline = 'Egg prices hit a record as bird flu empties henhouses',
  bool world = false,
  int rank = 0,
  Map<String, Object?> page = const {},
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
    'headline': headline,
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
    'world': world,
    'rank': rank,
    ...page,
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
  world: true,
  rank: 1,
  page: _page,
);
final Map<String, Object?> _stale = _card(
  'news-2026-01-01-old',
  date: '2026-01-01',
  expires: '2026-01-04',
);

/// The morning of the paper of 16 November.
DateTime _morning() => DateTime(2026, 11, 16, 9);

Future<AppState> _app(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final app = AppState();
  await app.init();
  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    NewsPaper.reset();
    NewsPaper.clock = _morning;
  });
  tearDown(NewsPaper.reset);

  final sections = sectionsOf([
    {
      'id': 'news-today',
      'block': 'news-today',
      'title': {'en': 'Latest news'},
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
      'https://$kSiteHost/c/economics-1?ref=${ShareRef.card.ref}',
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

  test("a story's page is read with its card: its lines, points, sides, "
      'reports, place and time; what is malformed is left out, and a card '
      'without a page is still read', () {
    NewsPaper.adopt('2026-11-16', [_fresh, _stale]);
    final NewsScene s =
        PillBank.byId('news-2026-11-16-eggs')!.scene! as NewsScene;
    expect(s.summary, startsWith('A dozen cost'));
    // A point that is not words is no point.
    expect(s.points, hasLength(3));
    expect([for (final side in s.sides) side.who], ['Egg farmers', 'Shoppers']);
    // A report with no page on the web is no report.
    expect([for (final r in s.sources) r.outlet], ['BBC News', 'The Guardian']);
    expect(s.sources.first.link.host, 'www.bbc.co.uk');
    expect(s.rank, 1);
    expect(s.world, isTrue);
    expect(s.at, DateTime.utc(2026, 11, 16, 5));
    expect(s.outlets, ['BBC News', 'The Guardian', 'DW']);

    final NewsScene old =
        PillBank.byId('news-2026-01-01-old')!.scene! as NewsScene;
    expect(old.summary, isEmpty);
    expect(old.points, isEmpty);
    expect(old.sides, isEmpty);
    expect(old.sources, isEmpty);
    expect(old.rank, 0);
    expect(old.world, isFalse);
    expect(old.at, isNull);
  });

  test('the front page is the newest paper\'s world stories in its order, '
      'five at most, a story of no subject read as one; a paper with no '
      'front page gives its stories; nothing once it is two days old', () {
    final List<Map<String, Object?>> paper = [
      for (int i = 1; i <= 7; i++)
        _card(
          'news-2026-11-16-s$i',
          date: '2026-11-16',
          expires: '2026-11-19',
          headline: 'Story $i',
          // The front page is the paper's first six, one of them of no subject.
          world: i <= 6,
          topic: i == 2 ? NewsPaper.worldDesk : 'economics',
          rank: 8 - i,
        ),
      _card(
        'news-2026-11-15-yesterday',
        date: '2026-11-15',
        expires: '2026-11-18',
        world: true,
        rank: 1,
      ),
    ];
    NewsPaper.adopt('2026-11-16', paper);
    expect(
      [for (final p in NewsPaper.front()) p.id],
      [
        for (final i in [6, 5, 4, 3, 2]) 'news-2026-11-16-s$i',
      ],
    );
    // Filed under the world desk: read, under no subject.
    final Pill world = PillBank.byId('news-2026-11-16-s2')!;
    expect(NewsPaper.isWorld(world), isTrue);
    expect(NewsPaper.isWorld(PillBank.byId('news-2026-11-16-s3')!), isFalse);

    // A paper made before there was a front page: its stories, in order.
    NewsPaper.adopt('2026-11-16', [
      _card('news-2026-11-16-a', date: '2026-11-16', expires: '2026-11-19'),
      _card('news-2026-11-16-b', date: '2026-11-16', expires: '2026-11-19'),
    ]);
    expect(
      [for (final p in NewsPaper.front()) p.id],
      ['news-2026-11-16-a', 'news-2026-11-16-b'],
    );
    // Yesterday's paper still makes the morning's front page; the day
    // before yesterday's does not.
    NewsPaper.clock = () => DateTime(2026, 11, 17, 5);
    expect(NewsPaper.front(), hasLength(2));
    NewsPaper.clock = () => DateTime(2026, 11, 18, 9);
    expect(NewsPaper.front(), isEmpty);
  });

  test("a subject's page has its own stories of the week, the newest paper "
      "first; the world desk's are on no subject's page", () {
    NewsPaper.adopt('2026-11-16', [
      _card(
        'news-2026-11-16-b',
        date: '2026-11-16',
        expires: '2026-11-19',
        rank: 2,
      ),
      _card(
        'news-2026-11-16-a',
        date: '2026-11-16',
        expires: '2026-11-19',
        rank: 1,
      ),
      _card('news-2026-11-12-c', date: '2026-11-12', expires: '2026-11-15'),
      _card('news-2026-11-08-old', date: '2026-11-08', expires: '2026-11-11'),
      _card(
        'news-2026-11-16-space',
        date: '2026-11-16',
        expires: '2026-11-19',
        topic: 'space',
      ),
      _card(
        'news-2026-11-16-world',
        date: '2026-11-16',
        expires: '2026-11-19',
        topic: NewsPaper.worldDesk,
        world: true,
      ),
    ]);
    final String economics = kTopics['economics']!.name;
    expect(
      [for (final p in NewsPaper.ofSubject(economics)) p.id],
      ['news-2026-11-16-a', 'news-2026-11-16-b', 'news-2026-11-12-c'],
    );
    expect(
      [for (final p in NewsPaper.ofSubject(kTopics['space']!.name)) p.id],
      ['news-2026-11-16-space'],
    );
    // The stand-in a world story is read under is no page of its own.
    expect(NewsPaper.ofSubject(kTopics['thinking']!.name), isEmpty);
  });

  testWidgets('on Explore the paper is a front page, each story with its '
      'outlets counted; a tap opens its page and counts it read; a '
      "subject's page has its own, another subject none", (tester) async {
    final app = await _app({});
    NewsPaper.adopt('2026-11-16', [
      _fresh,
      _card(
        'news-2026-11-16-rates',
        date: '2026-11-16',
        expires: '2026-11-19',
        headline: 'Freedonia cuts its interest rate to 2%',
        world: true,
        rank: 2,
      ),
    ]);
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('Latest news'), findsOneWidget);
    expect(
      find.text('Egg prices hit a record as bird flu empties henhouses'),
      findsOneWidget,
    );
    expect(find.text('Freedonia cuts its interest rate to 2%'), findsOneWidget);
    expect(find.textContaining('3 outlets'), findsNWidgets(2));
    // The lead's own lines; a story with none says its first step.
    expect(find.textContaining('A dozen cost a record'), findsOneWidget);
    expect(find.textContaining('The average dozen of eggs'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('explore-news-2026-11-16-eggs')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NewsStoryPage), findsOneWidget);
    expect(app.seenIds, contains('news-2026-11-16-eggs'));

    // Explore again from nothing, the story's page gone with it.
    await tester.pumpWidget(const SizedBox());
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['economics']!.name),
      sections,
    );
    expect(find.text('Latest news'), findsOneWidget);
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['space']!.name),
      sections,
    );
    expect(find.text('Latest news'), findsNothing);
  });

  testWidgets("a story's page: the points, the why, both sides, what to "
      'keep and its reports, each opened in the browser', (tester) async {
    NewsPaper.adopt('2026-11-16', [_fresh]);
    final List<Uri> opened = [];
    tester.view.physicalSize = const Size(390, 2400) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: NewsStoryPage(
          pill: PillBank.byId('news-2026-11-16-eggs')!,
          openLink: (link) async => opened.add(link),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ECONOMICS'), findsNothing);
    expect(find.textContaining('ECONOMICS'), findsOneWidget);
    expect(find.text('KEY POINTS'), findsOneWidget);
    expect(find.text('BEHIND THE NEWS'), findsOneWidget);
    expect(find.textContaining('Bird flu cost American farms'), findsOneWidget);
    expect(find.text('BOTH SIDES'), findsOneWidget);
    expect(find.text('Egg farmers'), findsOneWidget);
    expect(find.text('WHAT IT MEANS FOR YOU'), findsOneWidget);
    expect(find.text('WHAT TO KEEP'), findsOneWidget);
    // The number the story turns on, large: not a story of the world desk.
    expect(find.text(r'$6.23'), findsOneWidget);
    expect(find.text('SOURCES'), findsOneWidget);
    await tester.ensureVisible(find.text('Why eggs cost twice what they did'));
    await tester.tap(find.text('Why eggs cost twice what they did'));
    expect(opened, [Uri.parse('https://www.theguardian.com/business/eggs')]);
  });

  testWidgets('a story read is set back; a paper past its days, or none, is '
      'no section', (tester) async {
    final app = await _app({
      'knowit.seenIds': ['news-2026-11-16-eggs'],
    });
    NewsPaper.adopt('2026-11-16', [_fresh]);
    await pumpSections(tester, CoreHost(app), sections);
    final Text headline = tester.widget<Text>(
      find.text('Egg prices hit a record as bird flu empties henhouses'),
    );
    expect(headline.style?.color, Palette.dark.inkMuted);

    NewsPaper.adopt('2026-01-01', [_stale]);
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('Latest news'), findsNothing);
    NewsPaper.reset();
    await pumpSections(tester, CoreHost(app), sections);
    expect(find.text('Latest news'), findsNothing);
  });

  /// The paper of 16 November with four stories of the world, ranked.
  List<Map<String, Object?>> four() => [
    _fresh,
    for (final (int rank, String slug, String headline) in const [
      (2, 'rates', 'Freedonia cuts its interest rate to 2%'),
      (3, 'bridge', 'A bridge opens across the Firth after ten years'),
      (4, 'vote', 'Sylvania votes on a new constitution'),
    ])
      _card(
        'news-2026-11-16-$slug',
        date: '2026-11-16',
        expires: '2099-12-31',
        headline: headline,
        world: true,
        rank: rank,
      ),
  ];

  List<ExploreSection> looking(String look) => sectionsOf([
    {
      'id': 'news-today',
      'block': 'news-today',
      'title': {'en': 'Latest news'},
      'look': look,
    },
  ]);

  testWidgets('as a lead: one story large, why it matters and its outlets, '
      'then two more as rows, each a tap from its page', (tester) async {
    final app = await _app({});
    NewsPaper.adopt('2026-11-16', four());
    await pumpSections(
      tester,
      CoreHost(app),
      looking('lead'),
      size: const Size(390, 1400),
    );
    expect(find.text('Latest news'), findsOneWidget);
    expect(
      find.text('Egg prices hit a record as bird flu empties henhouses'),
      findsOneWidget,
    );
    // Why it matters is the story's own step of what it means.
    expect(find.text('WHY IT MATTERS'), findsOneWidget);
    expect(
      find.text(
        "When buyers can't cut back, a small shortage doubles the price.",
      ),
      findsOneWidget,
    );
    expect(find.textContaining('3 outlets'), findsWidgets);
    // Two rows under it, the fourth story left to the front page.
    expect(find.text('Freedonia cuts its interest rate to 2%'), findsOneWidget);
    expect(
      find.text('A bridge opens across the Firth after ten years'),
      findsOneWidget,
    );
    expect(find.text('Sylvania votes on a new constitution'), findsNothing);
    // The lead's two lines are the front page's, not the lead's.
    expect(find.textContaining('A dozen cost a record'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('explore-news-2026-11-16-rates')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NewsStoryPage), findsOneWidget);
    expect(app.seenIds, contains('news-2026-11-16-rates'));
  });

  testWidgets('as a pager: a story to a card across the page, every card as '
      'tall as the tallest, the next a swipe away, dots under them', (
    tester,
  ) async {
    final app = await _app({});
    NewsPaper.adopt('2026-11-16', four());
    await pumpSections(
      tester,
      CoreHost(app),
      looking('pager'),
      size: const Size(390, 1400),
    );
    final Finder first = find.byKey(
      const ValueKey('explore-news-2026-11-16-eggs'),
    );
    final Finder second = find.byKey(
      const ValueKey('explore-news-2026-11-16-rates'),
    );
    expect(first.hitTestable(), findsOneWidget);
    expect(find.textContaining('A dozen cost a record'), findsWidgets);
    expect(find.text('WHY IT MATTERS'), findsWidgets);
    expect(find.byKey(const ValueKey('news-dots')), findsOneWidget);
    for (int i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('news-dot-$i')), findsOneWidget);
    }
    final double height = tester.getSize(first).height;

    await tester.drag(first, const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(second.hitTestable(), findsOneWidget);
    expect(tester.getSize(second).height, height);

    await tester.tap(find.byKey(const ValueKey('news-dot-3')));
    await tester.pumpAndSettle();
    final Finder last = find.byKey(
      const ValueKey('explore-news-2026-11-16-vote'),
    );
    expect(last.hitTestable(), findsOneWidget);
    await tester.tap(last);
    await tester.pumpAndSettle();
    expect(find.byType(NewsStoryPage), findsOneWidget);
    expect(app.seenIds, contains('news-2026-11-16-vote'));
  });

  testWidgets('a look the block does not know is the front page', (
    tester,
  ) async {
    final app = await _app({});
    NewsPaper.adopt('2026-11-16', four());
    await pumpSections(
      tester,
      CoreHost(app),
      looking('magazine'),
      size: const Size(390, 1600),
    );
    expect(find.text('Sylvania votes on a new constitution'), findsOneWidget);
    expect(find.text('WHY IT MATTERS'), findsNothing);
    expect(find.textContaining('A dozen cost a record'), findsOneWidget);
  });
}
