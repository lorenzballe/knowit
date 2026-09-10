import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/daily.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/friends_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/sync/reader_store.dart';

void main() {
  group('A friend code', () {
    test('is six letters nobody can misread, the same every time', () {
      final code = friendCodeOf('some-firebase-uid');
      expect(code, hasLength(6));
      expect(friendCodeOf('some-firebase-uid'), code);
      expect(friendCodeOf('another-uid'), isNot(code));
      for (final unit in code.codeUnits) {
        expect(kCodeAlphabet, contains(String.fromCharCode(unit)));
      }
      // Never a letter that looks like a digit, or a digit like a letter.
      expect(kCodeAlphabet, isNot(contains('O')));
      expect(kCodeAlphabet, isNot(contains('0')));
      expect(kCodeAlphabet, isNot(contains('I')));
      expect(kCodeAlphabet, isNot(contains('1')));
    });

    test('survives being typed badly', () {
      expect(parseFriendCode(' ab-cd ef '), 'ABCDEF');
      expect(parseFriendCode('ABCDE'), isNull, reason: 'too short');
      expect(parseFriendCode('ABCDE0'), isNull, reason: 'not in the alphabet');
    });
  });

  test('a board says the shape of the habit and nothing of the cards', () {
    const board = Board(
      uid: 'u',
      code: 'ABCDEF',
      name: 'Lena',
      streak: 12,
      weeks: 3,
      days: 4,
      gap: 8.4,
      edition: 40,
      squares: '⬜🟩⬜🟥⬜',
      right: 1,
      asked: 2,
      updated: '2026-10-10',
    );
    final back = Board.fromJson(board.toJson())!;
    expect(back.name, 'Lena');
    expect(back.streak, 12);
    expect(back.gap, 8.4);
    expect(back.squares, board.squares);
    expect(board.toJson().keys, isNot(contains('question')));
    expect(board.toJson().keys, isNot(contains('answers')));
  });

  test('backing up also publishes the board, squares only once done', () async {
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.name': 'Marco',
      'knowit.streak': 4,
      'knowit.lastCompletionDate': dateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
    });
    final app = AppState();
    await app.init();
    final boards = MemoryBoardStore();
    final account = Account(
      uidOverride: 'u1',
      storeOverride: MemoryReaderStore(),
      boardsOverride: boards,
    );

    await account.push(app);
    final Board mine = boards.boards[friendCodeOf('u1')]!;
    expect(mine.name, 'Marco');
    expect(mine.streak, 4);
    expect(mine.squares, isEmpty, reason: 'today is not done yet');
    expect(account.friendCode, friendCodeOf('u1'));

    for (var i = 0; i < kPillsPerDay; i++) {
      await app.advance();
    }
    await account.push(app);
    final Board done = boards.boards[friendCodeOf('u1')]!;
    expect(done.streak, 5);
    expect(done.squares.runes.length, kPillsPerDay);
    expect(done.edition, editionOf(DateTime.now()));
  });

  group('The friends screen', () {
    Widget host(AppState app, Account account) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FriendsScreen(app: app, account: account, onBack: () {}),
    );

    testWidgets('shows a friend as a habit, never as answers', (tester) async {
      final code = friendCodeOf('friend');
      SharedPreferences.setMockInitialValues({
        'knowit.onboarded': true,
        'knowit.friendCodes': <String>[code],
      });
      final app = AppState();
      await app.init();
      final boards = MemoryBoardStore({
        code: Board(
          uid: 'friend',
          code: code,
          name: 'Lena',
          streak: 12,
          weeks: 3,
          days: 4,
          gap: 8.4,
          edition: editionOf(DateTime.now()),
          squares: '⬜🟩⬜🟥⬜',
          right: 1,
          asked: 2,
          updated: dateKey(DateTime.now()),
        ),
      });
      final account = Account(uidOverride: 'me', boardsOverride: boards);

      await tester.pumpWidget(host(app, account));
      await tester.pumpAndSettle();

      expect(find.text(friendCodeOf('me')), findsOneWidget);
      expect(find.text('Lena'), findsWidgets);
      expect(find.text('🔥12 · 3 weeks kept · 8 points off'), findsOneWidget);
      expect(find.text('⬜🟩⬜🟥⬜'), findsOneWidget);
      // The week, by calibration: the friend is measured and the reader is
      // not, so the friend leads.
      expect(
        find.text('This week, by calibration'.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('You'), findsOneWidget);
      expect(find.text('not measured yet'), findsOneWidget);
    });

    testWidgets('a code typed badly still adds, and your own does not', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
      final app = AppState();
      await app.init();
      final account = Account(
        uidOverride: 'me',
        boardsOverride: MemoryBoardStore(),
      );
      await tester.pumpWidget(host(app, account));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nobody yet'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('friend-code')),
        friendCodeOf('me').toLowerCase(),
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text("That's your own code."), findsOneWidget);
      expect(app.friendCodes, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('friend-code')),
        'ab-cdef',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(app.friendCodes, ['ABCDEF']);
      expect(find.text('No reader with that code.'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('knowit.friendCodes'), ['ABCDEF']);
    });
  });
}
