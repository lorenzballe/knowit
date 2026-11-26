// Your five from today: the small row near the top of Explore that opens the
// reader's own five again at full size once they are read, as "See again"
// over Today's shelf does. Drawn only once the day is read and never on a
// subject's page, whole on a small phone at large text, in the reader's
// language, and opening the five themselves from the first.
//
//   flutter test test/explore/your_five_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pills_repository.dart' show kPillsPerDay;
import 'package:astuto/explore/blocks/core/your_five_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/l10n/l10n.dart' show SubjectNames;
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';

import 'core_harness.dart';

/// Wednesday 11 November 2026, at ten in the morning.
DateTime _wednesday() => DateTime(2026, 11, 11, 10);

ExploreSection _section([Map<String, Object?> more = const {}]) =>
    ExploreSection.fromJson({'id': 'your-five', 'block': 'your-five', ...more});

/// What the app said, kept.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  List<Map<String, Object>> of(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

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

void main() {
  setUpAll(loadFonts);
  setUp(() => Served.useForTest(Served()));

  /// A reader on Wednesday, the day's five [read] or two of them.
  Future<CoreHost> host({
    bool read = true,
    String? subject,
    String language = 'en',
  }) async {
    final AppState app = await readyApp(const {}, _wednesday);
    app.todayIndex = read ? app.todaysDeck.length : 2;
    if (read) app.lastCompletionDate = '2026-11-11';
    return CoreHost(app, subject: subject, language: language);
  }

  testWidgets('once the five are read: named as the reader\'s own, their '
      'subjects under the name, and a tap opens the five themselves at full '
      'size, from the first', (tester) async {
    final _Said said = _Said();
    Analytics.useForTest(said);
    addTearDown(() => Analytics.useForTest(null));
    final CoreHost five = await host();
    await pumpSections(tester, five, [_section()]);

    expect(find.byKey(const ValueKey('your-five')), findsOneWidget);
    expect(find.text('Your five from today'), findsOneWidget);
    final Pill first = five.app.todaysDeck.first;
    expect(
      find.textContaining(lookupAppLocalizations(
        const Locale('en'),
      ).subjectOf(first.topic)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('your-five')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final DeckViewerScreen viewer = tester.widget(
      find.byType(DeckViewerScreen),
    );
    expect(
      viewer.deck.map((p) => p.id),
      orderedEquals(
        five.app.todaysDeck.take(kPillsPerDay).map((p) => p.id),
      ),
    );
    expect(viewer.initialIndex, 0);
    expect(viewer.title, 'Today');
    // Read back, not answered again.
    expect(viewer.answering, isFalse);
    expect(said.of('today seen again').single['from'], 'explore');
  });

  testWidgets('not there while the five are being read, nor on a subject\'s '
      'page', (tester) async {
    await pumpSections(tester, await host(read: false), [_section()]);
    expect(find.byKey(const ValueKey('your-five')), findsNothing);

    await pumpSections(tester, await host(subject: 'Space'), [
      _section({'subjectPages': true}),
    ]);
    expect(find.byKey(const ValueKey('your-five')), findsNothing);
  });

  testWidgets('in Italian, as the reader\'s own five', (tester) async {
    await pumpSections(
      tester,
      await host(language: 'it'),
      [_section()],
      locale: const Locale('it'),
    );
    expect(find.text('Le tue cinque di oggi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('your-five')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<DeckViewerScreen>(find.byType(DeckViewerScreen)).title,
      'Oggi',
    );
  });

  testWidgets('a section names it in its own words when it gives them', (
    tester,
  ) async {
    await pumpSections(tester, await host(), [
      _section({
        'title': {'en': 'Today, again'},
        'subtitle': {'en': 'The five you read'},
      }),
    ]);
    expect(find.text('Today, again'), findsOneWidget);
    expect(find.text('The five you read'), findsOneWidget);
  });

  for (final double text in [1.0, 2.0]) {
    for (final String language in ['de', 'ru']) {
      testWidgets('at ${text}x in $language, 375 wide: whole, its subjects '
          'never cut in the middle of one', (tester) async {
        await pumpSections(
          tester,
          await host(language: language),
          [_section()],
          text: text,
          locale: Locale(language),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(YourFiveRow), findsOneWidget);
      });
    }
  }
}
