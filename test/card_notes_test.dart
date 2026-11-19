// Notes on cards: written on a card's own page, kept on the phone and in the
// backup, the later word winning a merge (a note taken away included), all
// of them on a page of their own, and every part fitting a small phone at a
// large text size.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/notes_screen.dart';
import 'package:astuto/screens/pill_detail_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/card_notes.dart';
import 'package:astuto/sync/reader_snapshot.dart';
import 'package:astuto/theme.dart';

DateTime _now = DateTime(2026, 11, 19, 9);

Future<AppState> _app([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true, ...prefs});
  final AppState app = AppState(clock: () => _now);
  await app.init();
  return app;
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Locale locale = const Locale('en'),
  Size phone = const Size(390, 844),
  double text = 1,
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: child!,
      ),
      home: page,
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  setUp(() {
    PillBank.reset();
    _now = DateTime(2026, 11, 19, 9);
  });

  test(
    'a note is kept, trimmed and cut, and taken away when emptied',
    () async {
      final AppState app = await _app();
      final Pill card = PillBank.live.first;
      expect(app.noteOn(card.id), isNull);
      await app.setNote(card.id, '  Remember the base rate.  ');
      expect(app.noteOn(card.id), 'Remember the base rate.');
      expect(app.notedIds, [card.id]);
      await app.setNote(card.id, 'x' * (CardNotes.maxLength + 40));
      expect(app.noteOn(card.id)!.length, CardNotes.maxLength);
      await app.setNote(card.id, '   ');
      expect(app.noteOn(card.id), isNull);
      expect(app.notedIds, isEmpty);
      // Taken away, but remembered as taken away, for a merge.
      expect(app.notes[card.id]!.isEmpty, isTrue);
    },
  );

  test('notes survive a restart and come back from a backup', () async {
    final AppState app = await _app();
    final Pill card = PillBank.live.first;
    await app.setNote(card.id, 'Two lines of mine.');
    final ReaderSnapshot snap = ReaderSnapshot.fromJson(
      app.snapshot().toJson(),
    );
    expect(snap.notes[card.id]!.text, 'Two lines of mine.');
    final AppState fresh = await _app();
    await fresh.adopt(snap);
    expect(fresh.noteOn(card.id), 'Two lines of mine.');
  });

  test('a merge keeps the later word on each card, a removal included', () {
    final ReaderSnapshot phone = ReaderSnapshot(
      notes: {
        'a': const CardNote('mine, later', 200),
        'b': const CardNote('', 300),
      },
    );
    final ReaderSnapshot cloud = ReaderSnapshot(
      notes: {
        'a': const CardNote('older', 100),
        'b': const CardNote('kept on the other phone', 250),
        'c': const CardNote('only there', 50),
      },
    );
    final ReaderSnapshot both = mergeSnapshots(phone, cloud);
    expect(both.notes['a']!.text, 'mine, later');
    expect(both.notes['b']!.isEmpty, isTrue);
    expect(both.notes['c']!.text, 'only there');
  });

  testWidgets('written on a card\'s own page, and found on the notes page', (
    tester,
  ) async {
    final AppState app = await tester.runAsync(_app) as AppState;
    final Pill card = PillBank.live.first;
    await _pump(tester, PillDetailScreen(pill: card, app: app));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('note-add')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('note-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-field')),
      'Ask what the base rate is.',
    );
    await tester.tap(find.byKey(const ValueKey('note-save')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(app.noteOn(card.id), 'Ask what the base rate is.');
    expect(find.byKey(const ValueKey('note-text')), findsOneWidget);

    await _pump(tester, NotesScreen(app: app));
    expect(find.byKey(ValueKey('note-row-${card.id}')), findsOneWidget);
    expect(find.text('Ask what the base rate is.'), findsOneWidget);
  });

  testWidgets('no notes yet says how to write one', (tester) async {
    final AppState app = await tester.runAsync(_app) as AppState;
    await _pump(tester, NotesScreen(app: app));
    expect(find.byKey(const ValueKey('notes-empty')), findsOneWidget);
  });

  for (final String language in ['en', 'it', 'de', 'ru', 'ja']) {
    testWidgets('the notes page and a note fit 320 wide at twice the text, '
        'in $language', (tester) async {
      final AppState app = await tester.runAsync(_app) as AppState;
      final Pill card = PillBank.live.first;
      await tester.runAsync(
        () => app.setNote(
          card.id,
          'A longer note, of the kind a reader writes when a card has '
          'changed their mind about something they were sure of.',
        ),
      );
      await _pump(
        tester,
        NotesScreen(app: app),
        locale: Locale(language),
        phone: const Size(320, 640),
        text: 2,
      );
      expect(tester.takeException(), isNull);
      await _pump(
        tester,
        PillDetailScreen(pill: card, app: app),
        locale: Locale(language),
        phone: const Size(320, 640),
        text: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
