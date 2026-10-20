import 'package:flutter/widgets.dart';

import '../models/pill.dart';
import 'session.dart';

/// How one card was read, to the millisecond: from the moment it stood on
/// top of the deck with the reader looking at it, to the moment it left —
/// thrown on, or left standing when the reader went to another tab, a
/// pushed screen or the background.
///
/// Those stretches are a card's *stints*: a card left for the background
/// and come back to is read in two, and each is said once, by the event of
/// whatever ended it ('card advanced' on Today, 'card closed' everywhere
/// else). Its clocks only run while the card is in sight, so a phone left on
/// the kitchen table is not a card read for an hour.
///
/// Facts only: times, counts and which parts were opened. Never what the
/// reader typed or picked — the answer is the answer's event.
class CardRead {
  CardRead(this.pill, {this.reread = false, bool back = false}) {
    _onBack = back;
    (back ? _back : _front).start();
    Session.instance.cardSeen(pill.id);
  }

  final Pill pill;

  /// Whether the reader had this card in front of them before: read on an
  /// earlier day, or left mid-read and come back to.
  final bool reread;

  final Stopwatch _front = Stopwatch();
  final Stopwatch _back = Stopwatch();
  bool _onBack = false;
  bool _ended = false;

  int _flips = 0;
  int? _msToFlip;
  int? _msToFirstTouch;
  int? _msToHint;
  int _changes = 0;
  bool _changeable = false;
  double? _backSeen;
  final Set<String> _extras = {};

  /// How long the card has been in sight in this stint.
  int get msOn => _front.elapsedMilliseconds + _back.elapsedMilliseconds;

  bool get ended => _ended;

  /// The card was turned over, either way.
  void turned({required bool toBack}) {
    if (_ended || toBack == _onBack) return;
    _flips++;
    if (toBack) _msToFlip ??= msOn;
    _onBack = toBack;
    if (toBack) {
      _front.stop();
      _back.start();
    } else {
      _back.stop();
      _front.start();
    }
  }

  /// A finger came down on the card.
  void touched() => _msToFirstTouch ??= msOn;

  /// The hint was opened.
  void hinted() => _msToHint ??= msOn;

  /// The card's way of answering can be changed before it is committed: a
  /// mark on a ruler, digits typed. A card answered with a single tap — a
  /// choice, how sure — commits on that tap and has nothing to change.
  void changeable() => _changeable = true;

  /// The reader took back what they had put down: the mark moved again,
  /// digits deleted. The hesitation a single answer cannot show.
  void changed() {
    _changeable = true;
    _changes++;
  }

  /// The back is on screen. A back that fits is seen whole; one that has to
  /// scroll is seen as far as it has been scrolled.
  void backLaidOut({required bool scrolls}) {
    if (!scrolls) _backSeen = 100;
  }

  /// How much of a scrolling back has been in sight, 0 to 100.
  void backSeen(double share) {
    if (share > (_backSeen ?? -1)) _backSeen = share;
  }

  /// Something tucked behind a line on the back was opened: the working,
  /// the picture, the scene, the other side's case, the simpler telling.
  void opened(String part) => _extras.add(part);

  /// Ends the stint, and says what it came to.
  CardStint end(String exit) {
    _ended = true;
    _front.stop();
    _back.stop();
    final List<String> extras = _extras.toList()..sort();
    return CardStint(
      pill,
      msOn: msOn,
      exit: exit,
      facts: {
        'ms_front': _front.elapsedMilliseconds,
        'ms_back': _back.elapsedMilliseconds,
        'ms_to_flip': _msToFlip,
        'ms_to_first_touch': _msToFirstTouch,
        'flips': _flips,
        // Only on a card that offers a hint before it is answered.
        'hint_opened': pill.hasHint && pill.asksSomething
            ? _msToHint != null
            : null,
        'ms_to_hint': _msToHint,
        'options_changed': _changeable ? _changes : null,
        'back_scroll_pct': _backSeen?.round(),
        'extras_opened': extras.isEmpty ? null : extras.join(','),
        'reread': reread,
        'exit': exit,
      },
    );
  }

  /// The read of the card [context] belongs to, while it is the card on top
  /// being read; null for a card waiting under it, or anywhere else.
  static CardRead? of(BuildContext context) {
    final CardRead? read = context
        .getInheritedWidgetOfExactType<CardReadScope>()
        ?.read
        ?.call();
    return read == null || read.ended ? null : read;
  }
}

/// A card's stint, ended: the card, how long it was in sight, how it left,
/// and the facts of how it was read.
class CardStint {
  const CardStint(
    this.pill, {
    required this.msOn,
    required this.exit,
    required this.facts,
  });

  final Pill pill;
  final int msOn;
  final String exit;
  final Map<String, Object?> facts;

  /// Whether it ended by being thrown on, which moves the deck on: by the
  /// reader, or by a free card's page when it is done ('done').
  bool get thrown =>
      exit == 'thrown' ||
      exit == 'swiped' ||
      exit == 'thrown down' ||
      exit == 'done';
}

/// Hands the card's read to what is drawn on the card — the hint, the ruler,
/// the back — so each can say what the reader did with it.
class CardReadScope extends InheritedWidget {
  const CardReadScope({super.key, required this.read, required super.child});

  /// The read of the card on top, as it stands when asked; null for a card
  /// under it, which nobody is reading yet. Asked, not held: a card left
  /// and come back to is read anew without anything being rebuilt.
  final CardRead? Function()? read;

  // Looked up when the reader does something, never while building.
  @override
  bool updateShouldNotify(CardReadScope old) => false;
}

/// What a card asks the reader to do with it, as a word: `web` for a free
/// card, whose page can ask anything; the scene played on it (`slider`,
/// `count`, `draw`…); or else the way it is answered (`estimate`,
/// `pick_one`, `take_a_side`, `type_number`), or `read` for a card that only
/// tells.
String interactionOf(Pill pill) {
  if (pill.hasPage) return 'web';
  final Object? scene = pill.scene?.raw['type'];
  if (scene is String && scene.isNotEmpty) return scene;
  return switch (pill.challenge) {
    NoChallenge() => 'read',
    PickOne() => 'pick_one',
    TypeNumber() => 'type_number',
    Estimate() => 'estimate',
    TakeASide() => 'take_a_side',
    PageJudged() => 'on_page',
  };
}
