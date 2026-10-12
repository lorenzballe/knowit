import 'package:cloud_firestore/cloud_firestore.dart';

/// What a reader showed a friend while the app had friends: the streak, the
/// weeks, how far off their confidence ran, and the day's five as squares.
/// Never a question and never an answer.
///
/// Friends came out before the launch, and nothing publishes a board any
/// more. What is left is the one a build that still had them published,
/// which deleting the account takes down with the rest.
class Board {
  const Board({
    required this.uid,
    required this.code,
    required this.name,
    required this.streak,
    required this.weeks,
    required this.days,
    required this.gap,
    required this.edition,
    required this.squares,
    required this.right,
    required this.asked,
    required this.updated,
    this.questionRight,
    this.questionSure,
  });

  final String uid;
  final String code;
  final String name;
  final int streak;

  /// Weeks kept in a row, and days kept this week.
  final int weeks;
  final int days;

  /// How far off the reader's confidence is, in points, or null until
  /// there is enough of a record.
  final double? gap;

  /// The last edition finished, as squares — empty when today is not done.
  final int edition;
  final String squares;
  final int right;
  final int asked;
  final String updated;

  /// How the question of the day went, and how sure they said they were:
  /// published by builds that still dealt it. Null until answered.
  final bool? questionRight;
  final int? questionSure;

  /// A board with nothing on it: what is left at a code whose reader has
  /// deleted their account, where the board could not be deleted outright.
  const Board.empty({required this.uid, required this.code})
    : name = '',
      streak = 0,
      weeks = 0,
      days = 0,
      gap = null,
      edition = 0,
      squares = '',
      right = 0,
      asked = 0,
      updated = '',
      questionRight = null,
      questionSure = null;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'code': code,
    'name': name,
    'streak': streak,
    'weeks': weeks,
    'days': days,
    'gap': gap,
    'edition': edition,
    'squares': squares,
    'right': right,
    'asked': asked,
    'updated': updated,
    'questionRight': questionRight,
    'questionSure': questionSure,
  };
}

/// The letters a code is made of: no O and no 0, no I and no 1, so a code
/// read out loud or typed from a screenshot survives the trip.
const String kCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Six letters for a reader, from the account id — the same six on every
/// phone the account is on, and nothing anybody can work the id back from.
String friendCodeOf(String uid) {
  var hash = 0x811c9dc5;
  for (final unit in uid.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // Six times five bits. The top two bits fold in so nothing is wasted.
  var bits = hash ^ (hash >> 30);
  final out = StringBuffer();
  for (var i = 0; i < 6; i++) {
    out.write(kCodeAlphabet[bits & 31]);
    bits >>= 5;
  }
  return out.toString();
}

/// Where boards live. An interface so deleting an account can be driven in
/// a test without a project or a network.
abstract class BoardStore {
  Future<void> publish(Board board);

  /// Takes a reader's board down, when they delete their account.
  Future<void> remove(String code, String uid);
}

/// One document per reader at boards/{code}, readable by anyone signed in
/// and written only by its owner — see firestore.rules.
class FirestoreBoardStore implements BoardStore {
  FirestoreBoardStore([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String code) =>
      _db.collection('boards').doc(code);

  @override
  Future<void> publish(Board board) => _doc(board.code).set(board.toJson());

  /// Deleted where the rules allow its owner to; where the rules deployed
  /// are older and do not, emptied instead — the name and every number
  /// gone, so nothing of the reader is left for a friend to read.
  @override
  Future<void> remove(String code, String uid) async {
    try {
      await _doc(code).delete();
    } on FirebaseException {
      await publish(Board.empty(uid: uid, code: code));
    }
  }
}

/// Keeps boards in memory. Used by the tests, and by nothing else.
class MemoryBoardStore implements BoardStore {
  MemoryBoardStore([Map<String, Board> seed = const {}])
    : boards = Map<String, Board>.from(seed);

  final Map<String, Board> boards;

  @override
  Future<void> publish(Board board) async => boards[board.code] = board;

  @override
  Future<void> remove(String code, String uid) async => boards.remove(code);
}
