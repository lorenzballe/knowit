import 'package:cloud_firestore/cloud_firestore.dart';

/// What a reader shows a friend: the streak, the weeks, how far off their
/// confidence runs, and today's five as squares. Never a question and never
/// an answer — two friends comparing boards are comparing habits, not
/// copying homework.
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
  };

  static Board? fromJson(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final uid = raw['uid'];
    if (uid is! String) return null;
    int n(String key) => raw[key] is num ? (raw[key] as num).round() : 0;
    String s(String key) => raw[key] is String ? raw[key] as String : '';
    return Board(
      uid: uid,
      code: s('code'),
      name: s('name'),
      streak: n('streak'),
      weeks: n('weeks'),
      days: n('days'),
      gap: raw['gap'] is num ? (raw['gap'] as num).toDouble() : null,
      edition: n('edition'),
      squares: s('squares'),
      right: n('right'),
      asked: n('asked'),
      updated: s('updated'),
    );
  }
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

/// Tidies what somebody typed into the shape a code has, or null if it
/// cannot be one.
String? parseFriendCode(String typed) {
  final cleaned = typed.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  if (cleaned.length != 6) return null;
  for (final unit in cleaned.codeUnits) {
    if (!kCodeAlphabet.contains(String.fromCharCode(unit))) return null;
  }
  return cleaned;
}

/// Where boards live. An interface so the friends screen can be driven in a
/// test without a project or a network.
abstract class BoardStore {
  Future<void> publish(Board board);

  Future<Board?> read(String code);
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

  @override
  Future<Board?> read(String code) async {
    final snap = await _doc(code).get();
    if (!snap.exists) return null;
    return Board.fromJson(snap.data());
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
  Future<Board?> read(String code) async => boards[code];
}
