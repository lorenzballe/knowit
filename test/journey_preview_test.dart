// Your journey on the free plan, the preview (lib/screens/journey_preview.dart,
// `journey.preview`): the journey's doors open the plans while the server
// has it off, and the reader's own journey while it has it on; every
// chapter veiled under its clear name, a tap on any of them or on the one
// quiet line the journey's door to the plans; one figure in the clear a
// week, in turn, the week's own while it can be said and else the next
// that can, kept for the week; where none can be said, what it takes; on
// Astute+, or once a trial is taken from the door, the journey whole; and
// nothing the preview veils written down as seen.
//
//   flutter test test/journey_preview_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/l10n/l10n.dart' show SubjectNames;
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/journey_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/theme.dart';

/// A day in each week of the turn, at noon: the Mondays of 7, 14, 23 and 30
/// November and December 2026 come round to the blind spot, the strong
/// point, how sure against how right, and what stays.
final DateTime _blindWeek = DateTime(2026, 12, 9, 12);
final DateTime _strongWeek = DateTime(2026, 12, 16, 12);
final DateTime _sureWeek = DateTime(2026, 11, 25, 12);
final DateTime _memoryWeek = DateTime(2026, 12, 2, 12);

/// Cards that ask to pick one, of [topic], [n] of them after [skip].
List<Pill> _of(String topic, int n, {int skip = 0}) => [
  for (final Pill p in PillBank.live)
    if (p.topic == topic &&
        p.web == null &&
        !p.isAboutAPlace &&
        p.challenge is PickOne)
      p,
].skip(skip).take(n).toList();

/// Answers on [cards] on [on], [right] of them right, said [sure] sure.
List<Map<String, Object>> _answers(
  List<Pill> cards, {
  required String on,
  required int right,
  int? sure,
}) => [
  for (final (int i, Pill p) in cards.indexed)
    {'k': i < right, 'p': p.id, 'd': on, 'c': ?sure},
];

/// A reader who has everything the preview can show: History and Science
/// measured (seven answers each), fourteen answers said how sure, and three
/// cards back after a miss.
List<Map<String, Object>> _everything() {
  final List<Pill> history = _of('History', 7);
  final List<Pill> science = _of('Science', 7);
  return [
    ..._answers(history, on: '2026-11-02', right: 6, sure: 80),
    ..._answers(science, on: '2026-11-03', right: 2, sure: 90),
    // Missed, and back two days later: known now.
    ..._answers(science.take(3).toList(), on: '2026-11-05', right: 3),
  ];
}

int _docs = 0;

/// The server's word on the preview.
void _switch({required bool on}) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'journey-preview-${_docs++}',
      'app': {
        'flags': {'journey.preview': on},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

Future<AppState> _app({
  List<Map<String, Object>> judgements = const [],
  bool plus = false,
  DateTime? at,
  Map<String, Object> more = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.judgements': jsonEncode(judgements),
    'knowit.seenIds': [for (final j in judgements) j['p']! as String],
    // Every level told: the page, not a level rising over it.
    'knowit.levelTold': 99,
    ...more,
  });
  final AppState app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
    clock: at == null ? null : () => at,
  );
  await app.init();
  return app;
}

Widget _host(AppState app, Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: home,
);

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

void main() {
  setUp(() {
    Remote.reset();
    Remote.fetch = (url) async => null;
    PillBank.fetch = (url) async => null;
  });

  tearDown(Remote.reset);

  Future<void> pump(WidgetTester tester, AppState app) async {
    tester.view.physicalSize = const Size(402, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(app, JourneyScreen(app: app, onBack: () {})));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('the figure in the clear', () {
    test('the week\'s own in the turn, a week each: the blind spot, the '
        'strong point, how sure against how right, what stays', () async {
      _switch(on: true);
      for (final (DateTime at, ClearFigure figure) in [
        (_blindWeek, ClearFigure.blind),
        (_strongWeek, ClearFigure.strong),
        (_sureWeek, ClearFigure.sure),
        (_memoryWeek, ClearFigure.memory),
      ]) {
        final AppState app = await _app(judgements: _everything(), at: at);
        expect(clearFigureOf(app), (figure: figure, keep: true));
      }
    });

    test('while the week\'s own cannot be said yet, the first after it '
        'that can; with none, the week\'s own, and nothing kept', () async {
      _switch(on: true);
      // Two answers said 80% sure: only how sure against how right can be
      // said, from its first reading.
      final AppState early = await _app(
        judgements: _answers(
          _of('History', 2),
          on: '2026-12-08',
          right: 2,
          sure: 80,
        ),
        at: _blindWeek,
      );
      expect(clearFigureReady(early, ClearFigure.blind), isFalse);
      expect(clearFigureReady(early, ClearFigure.sure), isTrue);
      expect(clearFigureOf(early), (figure: ClearFigure.sure, keep: true));
      final AppState none = await _app(at: _blindWeek);
      expect(clearFigureOf(none), (figure: ClearFigure.blind, keep: false));
    });

    test('kept for the week once shown, whatever comes to be said after; '
        'a figure kept for another week is not this one\'s', () async {
      _switch(on: true);
      final AppState kept = await _app(
        judgements: _everything(),
        at: _blindWeek,
        more: {'knowit.journeyClear': '2026-12-07|sure'},
      );
      expect(clearFigureOf(kept), (figure: ClearFigure.sure, keep: false));
      final AppState old = await _app(
        judgements: _everything(),
        at: _blindWeek,
        more: {'knowit.journeyClear': '2026-11-30|sure'},
      );
      expect(clearFigureOf(old), (figure: ClearFigure.blind, keep: true));
    });
  });

  group('the page', () {
    testWidgets('on the free plan with the preview on: the figure in the '
        'clear, the quiet line, and every chapter veiled under its name', (
      tester,
    ) async {
      _switch(on: true);
      final AppState app = await _app(
        judgements: _everything(),
        at: _blindWeek,
      );
      await pump(tester, app);
      expect(find.byKey(const ValueKey('journey-clear-blind')), findsOneWidget);
      expect(
        find.text(_l.journeyClearBlind(_l.subjectOf('Science'))),
        findsOneWidget,
      );
      expect(find.text(_l.journeyPreviewDoor), findsOneWidget);
      // Each chapter's body behind its own veil, its name clear.
      expect(find.byType(ImageFiltered), findsAtLeastNWidgets(5));
      expect(
        find.textContaining(_l.trainingTitle.toUpperCase()),
        findsOneWidget,
      );
      // The figure, kept for the week as the page opened.
      expect(app.journeyClear, '2026-12-07|blind');
    });

    testWidgets('the quiet line and every veiled chapter are the journey\'s '
        'door to the plans', (tester) async {
      _switch(on: true);
      final AppState app = await _app(
        judgements: _everything(),
        at: _blindWeek,
      );
      await pump(tester, app);
      await tester.tap(find.byKey(const ValueKey('journey-preview-door')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(
        tester.widget<PaywallScreen>(find.byType(PaywallScreen)).source,
        'journey',
      );
      Navigator.of(tester.element(find.byType(PaywallScreen))).pop();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(PaywallScreen), findsNothing);
      await tester.tap(find.byType(ImageFiltered).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('where the week\'s figure cannot be said yet, what it '
        'takes, never a sample', (tester) async {
      _switch(on: true);
      Finder inCard(String text) => find.descendant(
        of: find.byKey(const ValueKey('journey-clear-blind')),
        matching: find.text(text),
      );
      final AppState none = await _app(at: _blindWeek);
      await pump(tester, none);
      expect(inCard(_l.readBlind), findsOneWidget);
      expect(inCard(_l.journeyClearBlindNotYet), findsOneWidget);
      // One subject measured: a second, and the blind spot is said.
      final AppState one = await _app(
        judgements: _answers(_of('History', 6), on: '2026-12-08', right: 4),
        at: _blindWeek,
        more: {'knowit.journeyClear': '2026-12-07|blind'},
      );
      await pump(tester, one);
      expect(inCard(_l.journeyMissedEmpty), findsOneWidget);
    });

    testWidgets('on Astute+, or with the preview off, no veil and no figure '
        'in the clear', (tester) async {
      _switch(on: true);
      final AppState plus = await _app(
        judgements: _everything(),
        plus: true,
        at: _blindWeek,
      );
      await pump(tester, plus);
      expect(find.byKey(const ValueKey('journey-preview-door')), findsNothing);
      expect(find.byKey(const ValueKey('journey-clear-blind')), findsNothing);
      _switch(on: false);
      final AppState free = await _app(
        judgements: _everything(),
        at: _blindWeek,
      );
      await pump(tester, free);
      expect(find.byKey(const ValueKey('journey-preview-door')), findsNothing);
      expect(find.byKey(const ValueKey('journey-clear-blind')), findsNothing);
    });

    testWidgets('a trial taken from the door opens the journey there and '
        'then; nothing the preview veiled was written down as seen', (
      tester,
    ) async {
      _switch(on: true);
      final AppState app = await _app(
        judgements: _everything(),
        at: _blindWeek,
      );
      await pump(tester, app);
      expect(
        find.byKey(const ValueKey('journey-preview-door')),
        findsOneWidget,
      );
      final ScrollPosition page = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      page.jumpTo(page.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 600));
      expect(app.journeySeen, isEmpty);
      expect(app.journeySeenOn, isNull);
      await app.applyEntitlement(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('journey-preview-door')), findsNothing);
      expect(find.byKey(const ValueKey('journey-clear-blind')), findsNothing);
    });
  });

  group('the doors', () {
    testWidgets('the profile\'s way in: the plans while the preview is off, '
        'the reader\'s own journey while it is on', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final bool on in [false, true]) {
        await tester.pumpWidget(const SizedBox.shrink());
        _switch(on: on);
        final AppState app = await _app(judgements: _everything());
        await tester.pumpWidget(
          _host(
            app,
            Scaffold(
              body: ProfileScreen(
                app: app,
                account: Account(
                  uidOverride: 'me',
                  boardsOverride: MemoryBoardStore(),
                ),
                onSignedOut: () {},
              ),
            ),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.byKey(const ValueKey('profile-journey')));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(PaywallScreen), on ? findsNothing : findsOneWidget);
        expect(find.byType(JourneyScreen), on ? findsOneWidget : findsNothing);
        if (on) {
          expect(
            find.byKey(const ValueKey('journey-preview-door')),
            findsOneWidget,
          );
        }
      }
    });
  });
}
