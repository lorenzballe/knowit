// The Explore screen as the host every section is drawn for: a card opened
// from a section opens as from any shelf, a subject from a section narrows
// the page as its chip does, the offer opens the plans by its door, what a
// block notes is said once to the measurement and to the reader's own
// trace, and a card a block names while the engine only asks what it would
// draw is not counted as shown.
//
//   flutter test test/explore/host_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/catalogue.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/screens/explore_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/sync/trace.dart';
import 'package:astuto/theme.dart';

import 'core_harness.dart';

/// Keeps what the app measures, to be read back.
class _Events implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Map<String, Object>? last(String event) {
    for (final e in events.reversed) {
      if (e.$1 == event) return e.$2;
    }
    return null;
  }

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

/// A block that says the card it would draw was shown as soon as it is
/// asked to draw — which a block should not, and the host must survive.
class _Eager extends ExploreBlock {
  const _Eager();

  @override
  String get name => 'test-eager';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final Pill pill = PillBank.byId(section.json['card']! as String)!;
    host.seen(section, pill);
    return SizedBox(
      height: (section.json['height'] as num?)?.toDouble() ?? 120,
      child: Text(pill.question),
    );
  }
}

int _documents = 0;

void _adopt(Map<String, Object?> explore) => Remote.adopt(
  RemoteConfig(
    hash: 'host-${_documents++}',
    schema: kRemoteSchema,
    parts: {'explore': explore},
  ),
);

Future<void> _pumpScreen(
  WidgetTester tester,
  AppState app, {
  Size size = const Size(375, 667),
}) async {
  tester.view.physicalSize = size * 3;

  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      home: Scaffold(body: ExploreScreen(app: app)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late _Events sink;

  setUpAll(() => kExploreBlocks['test-eager'] = const _Eager());
  tearDownAll(() => kExploreBlocks.remove('test-eager'));
  setUp(() {
    sink = _Events();
    Analytics.useForTest(sink);
    Trace.useForTest(Trace());
    Served.useForTest(Served());
  });
  tearDown(() {
    Analytics.useForTest(null);
    Trace.useForTest(Trace());
    Remote.reset();
  });

  testWidgets('a card opened from a section opens among the section\'s '
      'cards, as from any shelf, and counts as read', (tester) async {
    final List<Pill> cards = PillBank.cards.sublist(10, 13);
    final AppState app = await readyApp();
    _adopt({
      'sections': [
        {
          'id': 'picked',
          'block': 'list',
          'source': {
            'ids': [for (final p in cards) p.id],
          },
        },
      ],
    });
    await _pumpScreen(tester, app);
    await tester.tap(find.byKey(ValueKey('explore-${cards[1].id}')));
    await tester.pumpAndSettle();
    final DeckViewerScreen viewer = tester.widget(
      find.byType(DeckViewerScreen),
    );
    expect([for (final p in viewer.deck) p.id], [for (final p in cards) p.id]);
    expect(viewer.initialIndex, 1);
    expect(viewer.countsAsRead, isTrue);
    expect(viewer.source, 'explore');
  });

  testWidgets('a subject from a section narrows Explore as its chip does, '
      'the page back at its top, and the lit one again clears it', (
    tester,
  ) async {
    final AppState app = await readyApp();
    _adopt({
      'sections': [
        {'id': 'room', 'block': 'spacer', 'height': 200},
        {
          'id': 'subjects',
          'block': 'subjects',
          'subjects': ['space', 'art'],
        },
        for (int i = 0; i < 6; i++)
          {
            'id': 'row-$i',
            'block': 'carousel',
            'source': {
              'query': {'seed': 'fixed', 'perSubject': 1 + i},
            },
          },
      ],
    });
    await _pumpScreen(tester, app);
    final ScrollPosition list = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ExploreScreen),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                ),
              )
              .first,
        )
        .position;
    list.jumpTo(120);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('section-subject-space-off')));
    await tester.pumpAndSettle();
    final ExploreScreenState screen = tester.state(find.byType(ExploreScreen));
    expect(screen.subject, 'Space');
    expect(find.byKey(const ValueKey('subject-All-off')), findsOneWidget);
    expect(list.pixels, 0);
    expect(sink.last('explore filtered'), {'subject': 'Space'});
    expect(
      Trace.instance.queued.where((e) => e['e'] == 'xf' && e['sub'] == 'Space'),
      hasLength(1),
    );

    await tester.tap(find.byKey(const ValueKey('section-subject-space-on')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('subject-All-on')), findsOneWidget);
  });

  testWidgets('the offer opens the plans through the door it names', (
    tester,
  ) async {
    final AppState app = await readyApp();
    _adopt({
      'sections': [
        {'id': 'offer', 'block': 'promo', 'from': 'explore promo'},
      ],
    });
    await _pumpScreen(tester, app, size: const Size(430, 932));
    await tester.tap(find.text('Get Astute+'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      tester.widget<PaywallScreen>(find.byType(PaywallScreen)).source,
      'explore promo',
    );
    expect(sink.last('plus gate reached')?['source'], 'explore promo');
  });

  testWidgets('what a block notes is said once for every block, to the '
      'measurement and, short, to the reader\'s own trace', (tester) async {
    final AppState app = await readyApp();
    _adopt({
      'sections': [
        {'id': 'words', 'block': 'text', 'text': 'Hello'},
      ],
    });
    await _pumpScreen(tester, app);
    final ExploreScreenState host = tester.state(find.byType(ExploreScreen));
    final ExploreSection section = ExploreSection.fromJson({
      'id': 'words',
      'block': 'text',
    });
    final Pill card = PillBank.cards.first;
    host.note(section, 'reacted', {'pill_id': card.id, 'how': 'surprised'});
    expect(sink.last('explore noted'), {
      'pill_id': card.id,
      'how': 'surprised',
      'shelf': 'words',
      'block': 'text',
      'noted': 'reacted',
    });
    final Map<String, Object?> traced = Trace.instance.queued.last;
    expect(traced['e'], 'xn');
    expect(traced['sh'], 'words');
    expect(traced['bk'], 'text');
    expect(traced['nd'], 'reacted');
    expect(traced['c'], card.id);
    expect(traced.containsKey('how'), isFalse);
  });

  testWidgets('a card a block names while the engine asks what it would '
      'draw is not counted as shown; one it draws on screen is', (
    tester,
  ) async {
    final List<Pill> cards = PillBank.cards.sublist(40, 42);
    _adopt({
      'sections': [
        {'id': 'near', 'block': 'test-eager', 'card': cards[0].id},
        {'id': 'room', 'block': 'spacer', 'height': 240},
        {'id': 'room-2', 'block': 'spacer', 'height': 240},
        for (int i = 0; i < 12; i++)
          {'id': 'room-${i + 3}', 'block': 'spacer', 'height': 240},
        {'id': 'far', 'block': 'test-eager', 'card': cards[1].id},
      ],
    });
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
    Remote.fetch = (_) async => null;
    await tester.pumpWidget(const AstutoApp());
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
    final List<Object?> shown = [
      for (final e in Trace.instance.queued)
        if (e['e'] == 'seen') e['c'],
    ];
    expect(shown, contains(cards[0].id));
    expect(shown, isNot(contains(cards[1].id)));
  });
}
