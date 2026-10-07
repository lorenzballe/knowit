import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/sync/reports.dart';
import 'package:astuto/sync/trace.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/reveal_body.dart';

/// What the app measured, kept to be read back.
class _Recorder implements AnalyticsSink {
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

void main() {
  late _Recorder recorder;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recorder = _Recorder();
    Analytics.useForTest(recorder);
    Trace.useForTest(Trace());
  });

  tearDown(() {
    Analytics.useForTest(null);
    Reports.useForTest(Reports());
    Trace.useForTest(Trace());
  });

  group('a report', () {
    test('is marked at once, written with the account, and measured '
        'without what the reader wrote', () async {
      final MemoryReportStore store = MemoryReportStore();
      final Reports reports = Reports(storeOverride: store, uidOverride: 'me');
      expect(reports.has('science-1'), isFalse);

      await reports.send(
        const CardReport(
          card: 'science-1',
          reason: ReportReason.fact,
          note: '  The boiling point is wrong at altitude.  ',
        ),
        topic: 'Science',
        locale: 'it',
        bank: 42,
      );

      expect(reports.has('science-1'), isTrue);
      expect(reports.waiting, 0);
      final Map<String, Object?> written = store.sent['me']!['science-1']!;
      expect(written['card'], 'science-1');
      expect(written['reason'], 'fact');
      expect(written['note'], 'The boiling point is wrong at altitude.');
      expect(written['locale'], 'it');
      expect(written['bank'], 42);
      expect(written.keys.toSet(), {
        'card',
        'reason',
        'note',
        'locale',
        'bank',
        'os',
      });

      final Map<String, Object>? measured = recorder.last('card reported');
      expect(measured, isNotNull);
      expect(measured!['pill_id'], 'science-1');
      expect(measured['report_reason'], 'fact');
      expect(measured['with_note'], isTrue);
      expect(
        measured.values.whereType<String>().any((v) => v.contains('boiling')),
        isFalse,
        reason: 'what the reader wrote is never measured',
      );
    });

    test(
      'waits when it cannot be written, and goes with the next try',
      () async {
        final MemoryReportStore store = MemoryReportStore()..refusing = true;
        final Reports reports = Reports(
          storeOverride: store,
          uidOverride: 'me',
        );
        await reports.send(
          const CardReport(card: 'thinking-d14', reason: ReportReason.unclear),
        );
        expect(reports.has('thinking-d14'), isTrue);
        expect(reports.waiting, 1);
        expect(store.sent, isEmpty);

        // A new launch finds it where the last one left it.
        final Reports relaunched = Reports(
          storeOverride: store,
          uidOverride: 'me',
        );
        await relaunched.load();
        expect(relaunched.has('thinking-d14'), isTrue);
        expect(relaunched.waiting, 1);

        store.refusing = false;
        await relaunched.flush();
        expect(relaunched.waiting, 0);
        expect(store.sent['me']!['thinking-d14']!['reason'], 'unclear');
      },
    );

    test('says one thing about a card: the last thing, and no more than '
        'the rules take', () async {
      final MemoryReportStore store = MemoryReportStore()..refusing = true;
      final Reports reports = Reports(storeOverride: store, uidOverride: 'me');
      await reports.send(
        const CardReport(card: 'science-1', reason: ReportReason.typo),
      );
      await reports.send(
        CardReport(
          card: 'science-1',
          reason: ReportReason.answer,
          note: 'x' * 900,
        ),
      );
      expect(reports.waiting, 1);
      store.refusing = false;
      await reports.flush();
      final Map<String, Object?> written = store.sent['me']!['science-1']!;
      expect(written['reason'], 'answer');
      expect((written['note']! as String).length, CardReport.noteLimit);
    });

    test('goes into the reader\'s trace as a card id and a reason', () async {
      final MemoryTraceStore store = MemoryTraceStore();
      final Trace trace = Trace(storeOverride: store, uidOverride: 'me');
      trace.note('card reported', {
        'pill_id': 'science-1',
        'topic': 'Science',
        'report_reason': 'answer',
        'with_note': true,
      });
      await trace.flush();
      final List<Map<String, Object?>> events = store.days['me']!.values
          .expand((e) => e)
          .toList();
      expect(events, hasLength(1));
      expect(events.single..remove('t'), {
        'e': 'rep',
        'c': 'science-1',
        'rr': 'answer',
        'nt': true,
      });
    });

    test('is forgotten on sign-out', () async {
      final Reports reports = Reports(
        storeOverride: MemoryReportStore(),
        uidOverride: 'me',
      );
      await reports.send(
        const CardReport(card: 'science-1', reason: ReportReason.other),
      );
      await reports.reset();
      expect(reports.has('science-1'), isFalse);
      final Reports relaunched = Reports(uidOverride: 'me');
      await relaunched.load();
      expect(relaunched.has('science-1'), isFalse);
    });

    test('names its reasons as the rules and the server know them', () {
      expect(
        [for (final r in ReportReason.values) r.wire],
        ['fact', 'answer', 'source', 'unclear', 'typo', 'other'],
      );
      expect(
        [
          for (final r in ReportReason.values)
            if (r.factual) r.wire,
        ],
        ['fact', 'answer', 'source'],
      );
      expect(ReportReason.fromWire('source'), ReportReason.source);
      expect(ReportReason.fromWire('nonsense'), isNull);
    });
  });

  group('on the back of a card', () {
    Widget host(Pill pill) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: RevealBody.onPage(pill, context.p),
          ),
        ),
      ),
    );

    testWidgets('"Report a problem" takes a reason and a line, and the card '
        'then says it was reported', (tester) async {
      final MemoryReportStore store = MemoryReportStore();
      Reports.useForTest(Reports(storeOverride: store, uidOverride: 'me'));
      final Pill pill = PillBank.cards.firstWhere(
        (p) => p.challenge is PickOne,
      );

      await tester.pumpWidget(host(pill));
      await tester.pumpAndSettle();
      final Finder link = find.byKey(ValueKey('report-${pill.id}'));
      await tester.ensureVisible(link);
      expect(find.text('Report a problem'), findsOneWidget);
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.text("What's wrong with this card?"), findsOneWidget);
      // Nothing to send until a reason is picked.
      await tester.tap(find.byKey(const ValueKey('report-send')));
      await tester.pumpAndSettle();
      expect(find.text("What's wrong with this card?"), findsOneWidget);
      expect(store.sent, isEmpty);

      await tester.tap(find.byKey(const ValueKey('report-reason-answer')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('report-note')),
        'The second option is the right one.',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('report-send')));
      await tester.tap(find.byKey(const ValueKey('report-send')));
      await tester.pumpAndSettle();

      expect(find.text("What's wrong with this card?"), findsNothing);
      expect(find.text("Thanks. We'll check it."), findsOneWidget);
      expect(find.byKey(ValueKey('reported-${pill.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('report-${pill.id}')), findsNothing);
      final Map<String, Object?> written = store.sent['me']![pill.id]!;
      expect(written['reason'], 'answer');
      expect(written['note'], 'The second option is the right one.');
      expect(written['bank'], PillBank.version);
      expect(written['locale'], 'en');
      expect(recorder.last('card reported')!['pill_id'], pill.id);
    });

    testWidgets('a card that marks no answer is not asked about one', (
      tester,
    ) async {
      Reports.useForTest(
        Reports(storeOverride: MemoryReportStore(), uidOverride: 'me'),
      );
      final Pill fact = PillBank.cards.firstWhere((p) => !p.isGraded);
      await tester.pumpWidget(host(fact));
      await tester.pumpAndSettle();
      final Finder link = find.byKey(ValueKey('report-${fact.id}'));
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-reason-fact')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-reason-answer')), findsNothing);
    });
  });
}
