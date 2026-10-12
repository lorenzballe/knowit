import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/sync/reader_store.dart';
import 'package:astuto/theme.dart';

/// Friends came out before the launch. What these check is that nothing of
/// them is left to find, and that the one thing still owed to a reader who
/// used them — their board taken down with their account — is still done.
void main() {
  Map<String, Object> marco() => {
    'knowit.onboarded': true,
    'knowit.name': 'Marco',
    'knowit.streak': 4,
    'knowit.lastCompletionDate': dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    ),
    // Added on a build that still had friends.
    'knowit.friendCodes': <String>['K7MP2X'],
  };

  test('a board was filed under six letters nobody can misread', () {
    // Still worked out, because deleting an account finds the board an
    // older build published by it.
    final code = friendCodeOf('some-firebase-uid');
    expect(code, hasLength(6));
    expect(friendCodeOf('some-firebase-uid'), code);
    expect(friendCodeOf('another-uid'), isNot(code));
    for (final unit in code.codeUnits) {
      expect(kCodeAlphabet, contains(String.fromCharCode(unit)));
    }
  });

  test('backing up writes the backup and publishes no board', () async {
    SharedPreferences.setMockInitialValues(marco());
    final app = AppState();
    await app.init();
    final readers = MemoryReaderStore();
    final boards = MemoryBoardStore();
    final account = Account(
      uidOverride: 'u1',
      storeOverride: readers,
      boardsOverride: boards,
    );

    await account.push(app);
    expect((await readers.read('u1'))?.name, 'Marco');
    expect(boards.boards, isEmpty);
    // The codes are not shown anywhere, and the backup carries them as it
    // found them.
    expect((await readers.read('u1'))?.friendCodes, ['K7MP2X']);
  });

  test(
    'deleting the account takes the backup, an old board and the phone',
    () async {
      SharedPreferences.setMockInitialValues(marco());
      final app = AppState();
      await app.init();
      final readers = MemoryReaderStore();
      final String code = friendCodeOf('u1');
      // What a build that still had friends left behind.
      final boards = MemoryBoardStore({
        code: Board(
          uid: 'u1',
          code: code,
          name: 'Marco',
          streak: 4,
          weeks: 1,
          days: 3,
          gap: 12,
          edition: 40,
          squares: '',
          right: 0,
          asked: 0,
          updated: dateKey(DateTime.now()),
        ),
      });
      final account = Account(
        uidOverride: 'u1',
        storeOverride: readers,
        boardsOverride: boards,
      );
      await account.push(app);
      expect(await readers.read('u1'), isNotNull);

      // Apple asks for this inside the app, for any app that makes accounts.
      final DeleteOutcome outcome = await account.deleteAccount(app);
      expect(outcome, DeleteOutcome.deleted);
      expect(account.deleting, isFalse);

      // Nothing of the reader is left where it was kept, or on this phone.
      expect(await readers.read('u1'), isNull);
      expect(boards.boards[code], isNull);
      expect(app.name, 'You');
      expect(app.streak, 0);
      expect(app.onboarded, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.name'), isNull);
      expect(prefs.getStringList('knowit.friendCodes'), isNull);
    },
  );

  test('a board that cannot be deleted is emptied of the reader', () {
    const Board empty = Board.empty(uid: 'u1', code: 'ABCDEF');
    expect(empty.name, isEmpty);
    expect(empty.streak, 0);
    expect(empty.squares, isEmpty);
    expect(empty.gap, isNull);
    // Still the owner's, or the rules would refuse the write that empties it.
    expect(empty.toJson()['uid'], 'u1');
  });

  testWidgets('the profile has no way to friends, even for a reader who had '
      'some', (tester) async {
    // Tall enough that every row of the profile is built at once.
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(marco());
    final app = AppState();
    await app.init();
    final account = Account(
      uidOverride: 'me',
      boardsOverride: MemoryBoardStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(
          body: ProfileScreen(app: app, account: account, onSignedOut: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The rows either side of where the friends were are there.
    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
    expect(find.textContaining('Friend'), findsNothing);
    expect(find.textContaining('friend'), findsNothing);
  });
}
