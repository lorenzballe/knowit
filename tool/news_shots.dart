// Photographs Explore's latest news with a morning's paper: the paper the
// pipeline would have written on 26 November 2026 from that day's real
// reports (tool/news/paper.json, a fixture, never shipped), on a 390 by 844
// phone at night. Explore for every subject, one subject's page, and a
// story's page at its top and further down, each drawn by the real block
// through Explore's own engine, the story opened by the block's own tap.
//
//   flutter test tool/news_shots.dart --update-goldens
//
// NEWS_LANG (en by default) for another language's words around the story.
// A camera, not a check: it lives outside test/ so CI never runs it. The
// pictures land in tool/shots/news/, to be looked at and not kept.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/news_paper.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/explore_engine.dart';

import '../test/explore/core_harness.dart';

const String _lang = String.fromEnvironment('NEWS_LANG', defaultValue: 'en');

/// Half past eight in Rome on the paper's morning.
final DateTime _morning = DateTime.utc(2026, 11, 26, 7, 30);

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// A 390 by 844 phone: its status bar and its home bar.
void _phone(WidgetTester tester) {
  final view = tester.view;
  view.physicalSize = const Size(390, 844) * 3;
  view.devicePixelRatio = 3;
  view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  view.viewPadding = view.padding;
  addTearDown(view.reset);
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale(_lang),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  debugShowCheckedModeBanner: false,
  home: home,
);

/// Explore's page with [sections] on it, under the status bar.
Widget _page(ExploreHost host, List<ExploreSection> sections) => Builder(
  builder: (context) => Scaffold(
    body: CustomScrollView(
      key: const ValueKey('news-page'),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 16),
        ),
        ExploreSliver(
          host: host,
          slots: exploreSlots(
            context,
            host,
            sections,
            host.app.remoteContext(host.language),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    ),
  ),
);

void main() {
  late Map<String, Object?> paper;
  late List<ExploreSection> sections;
  late AppState app;

  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    paper = jsonDecode(
      File('tool/news/paper.json').readAsStringSync(),
    ) as Map<String, Object?>;
    // The section as the remote document gives it: its title and its line.
    final Map<String, Object?> config = jsonDecode(
      File('web/remote/config.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final List<Object?> all =
        (config['explore']! as Map<String, Object?>)['sections']! as List;
    sections = sectionsOf([
      for (final Object? s in all)
        if (s is Map<String, Object?> && s['id'] == 'news-today') s,
    ]);
  });

  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    NewsPaper.reset();
    NewsPaper.clock = () => _morning;
    NewsPaper.adopt(paper['date'] as String?, paper['cards']! as List<Object?>);
    app = await readyApp({'knowit.pushAsked': true});
  });

  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    NewsPaper.reset();
  });

  /// [body] on an iPhone: Apple's own controls where the app has them.
  Future<void> onIPhone(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Future<void> take(String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('shots/news/$_lang/$name.png'),
  );

  Future<void> scroll(WidgetTester tester, Finder list, double by) async {
    final ScrollableState state = tester.state(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    state.position.jumpTo(
      (state.position.pixels + by).clamp(0, state.position.maxScrollExtent),
    );
    await _settle(tester, 6);
  }

  testWidgets(
    'explore, every subject: the front page',
    (tester) => onIPhone(() async {
      _phone(tester);
      await tester.pumpWidget(_app(_page(CoreHost(app), sections)));
      await _settle(tester);
      await take('all');
      await scroll(tester, find.byKey(const ValueKey('news-page')), 560);
      await take('all-2');
    }),
  );

  testWidgets(
    "a subject's page: its own stories",
    (tester) => onIPhone(() async {
      _phone(tester);
      await tester.pumpWidget(
        _app(_page(CoreHost(app, subject: 'Space'), sections)),
      );
      await _settle(tester);
      await take('subject-space');
    }),
  );

  testWidgets(
    "a story's page, opened from the front",
    (tester) => onIPhone(() async {
      _phone(tester);
      await tester.pumpWidget(_app(_page(CoreHost(app), sections)));
      await _settle(tester);
      final String lead = NewsPaper.front().first.id;
      await tester.ensureVisible(find.byKey(ValueKey('explore-$lead')));
      await tester.tap(find.byKey(ValueKey('explore-$lead')));
      await _settle(tester, 14);
      final Finder story = find.byKey(ValueKey('news-story-$lead'));
      expect(story, findsOneWidget);
      await take('story-top');
      for (int i = 2; i <= 4; i++) {
        await scroll(tester, story, 640);
        await take('story-$i');
      }
    }),
  );

  testWidgets(
    'a story of the world desk, contested',
    (tester) => onIPhone(() async {
      _phone(tester);
      await tester.pumpWidget(_app(_page(CoreHost(app), sections)));
      await _settle(tester);
      final String id = NewsPaper.front().firstWhere(NewsPaper.isWorld).id;
      await tester.ensureVisible(find.byKey(ValueKey('explore-$id')));
      await _settle(tester, 4);
      await tester.tap(find.byKey(ValueKey('explore-$id')));
      await _settle(tester, 14);
      await take('world-top');
      await scroll(tester, find.byKey(ValueKey('news-story-$id')), 640);
      await take('world-2');
    }),
  );
}
