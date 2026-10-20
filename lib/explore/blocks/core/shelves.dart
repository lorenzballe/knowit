/// What Explore's shelves hold for the reader on this phone, worked out once
/// for every block that draws one: the shelves Explore always had, and the
/// cards any section asks for through its `source`.
///
/// It is the screen's own reckoning, moved here so that a block reads it
/// rather than the screen. The server's Explore when it has answered, the
/// phone's own from the bank it carries before it; narrowed to the subject
/// chip in view; and dealt once a day, from what the reader had not read by
/// then, so a card read from a shelf stays where it is, marked, until the
/// next day deals the shelves again.
library;

import 'package:flutter/foundation.dart';

import '../../../data/explore_mix.dart';
import '../../../data/local_cards.dart';
import '../../../data/pill_bank.dart';
import '../../../data/pills_repository.dart';
import '../../../data/themed_shelves.dart';
import '../../../data/topics.dart';
import '../../../models/pill.dart';
import '../../../models/place.dart';
import '../../../state/app_state.dart';
import '../../../sync/served.dart';
import '../../../sync/tally.dart';
import '../../../widgets/explore/form_shelves.dart' show CameBackCard;
import '../../explore_block.dart';

/// What a block of the core family may ask of the screen beyond
/// [ExploreHost]: the shelves themselves, and the two things only Explore's
/// own shelves do. A host that is not one — a test's, a camera's — still
/// draws every core block: [ExploreShelves.of] works the shelves out for it,
/// and a card that came back opens as any card does.
abstract interface class ExploreShelfHost implements ExploreHost {
  /// The shelves, as the screen holds them across its builds.
  ExploreShelves get shelves;

  /// A card that came back, opened to be answered again, as from the
  /// finished day.
  void openDue(ExploreSection section, List<Pill> shelf, Pill pill);

  /// A card [section] showed, noted under [shelf] rather than the section's
  /// own name: the game under the true-or-false shelf is said as its own,
  /// and counted on the shelf it sits in.
  void seenAs(ExploreSection section, String shelf, Pill pill);
}

/// Which of the reader's own shelves, the third from the top, and why it is
/// theirs.
enum MineReason {
  /// The subject the reader pushed furthest up, or the one the server says
  /// is theirs.
  because,

  /// The subject the reader has read most of.
  readMost,
}

/// The shelves for one reader, kept across the screen's builds.
class ExploreShelves {
  ExploreShelves(this.app, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The reader.
  final AppState app;

  final DateTime Function() _clock;

  /// The shelves of [host]: the screen's own, or worked out once for a host
  /// that keeps none, narrowed to its subject.
  static ExploreShelves of(ExploreHost host) {
    if (host is ExploreShelfHost) return host.shelves;
    final ExploreShelves shelves = _kept[host] ??= ExploreShelves(host.app);
    if (!shelves._begun || shelves.subject != host.subject) {
      shelves.begin(subject: host.subject);
    }
    return shelves;
  }

  static final Expando<ExploreShelves> _kept = Expando('shelves');

  bool _begun = false;

  /// The subject chip in view, by the name cards carry, or null for all.
  String? get subject => _subject;
  String? _subject;

  /// The top list's window, the week or the month: the reader's to switch,
  /// kept as long as the screen is.
  final ValueNotifier<bool> topMonth = ValueNotifier<bool>(false);

  /// Starts a build: the subject in view, the server's Explore as last
  /// read, and every shelf worked out afresh when it is next asked for. The
  /// mix, the cards that came back and the cards a source dealt stay dealt
  /// for as long as what they were dealt from does.
  void begin({String? subject}) {
    _begun = true;
    _subject = subject;
    _dealToday();
    _served = Served.instance.lastExplore;
    _todayAll = null;
    _askingAll = null;
    _top.clear();
    _third = null;
    _thirdKnown = false;
    _mine = null;
    _local = null;
    _loved = null;
    _cards.clear();
  }

  ServedExplore? _served;

  /// The server's Explore, as last read, or null before it has answered.
  ServedExplore? get served => _served;

  /// Explore is the copy kept from the last time the phone had signal.
  bool get offline => _served?.fromCache == true;

  // ── The day's deal ──────────────────────────────────────────────────

  /// What the reader had read when the shelves were dealt, and the day they
  /// were dealt on. The shelves for finding things leave those cards out; a
  /// card read since stays where it is, marked, until the next day deals
  /// them again. Taken off the moment it was read, it went from under the
  /// reader's thumb: back from the card, the row had closed up over it.
  Set<String> _readWhenDealt = const {};
  String? _dealtOn;

  /// The day the shelves were dealt on, as a seed.
  String? get dealtOn => _dealtOn;

  void _dealToday() {
    final String today = daySeed(_clock());
    if (_dealtOn != today) {
      _dealtOn = today;
      _readWhenDealt = {...app.seenIds};
    }
  }

  /// Whether [pill] was not read when the shelves were dealt: a find.
  bool unread(Pill pill) => !_readWhenDealt.contains(pill.id);

  /// Whether the reader has read [pill], by now.
  bool isRead(Pill pill) => app.seenIds.contains(pill.id);

  /// [pills] narrowed to the subject in view.
  List<Pill> only(Iterable<Pill> pills) => _subject == null
      ? pills.toList()
      : pills.where((p) => p.topic == _subject).toList();

  /// The subject in view by its key, `economics`, or null for all.
  String? get subjectKey => _subject == null
      ? null
      : kTopics.entries
            .where((e) => e.value.name == _subject)
            .map((e) => e.key)
            .firstOrNull;

  // ── The shelves that were always there ──────────────────────────────

  List<Pill>? _todayAll;

  /// Today's shelf, the same for everybody and changed at midnight — what
  /// the canvas means by "written this morning": the server's when it has
  /// answered, the phone's own pick before it, narrowed by the subject
  /// row, and less what was read when it was dealt. Eight of them.
  List<Pill> get today => todayAll.take(8).toList();

  /// Today's shelf whole, for a section that shows more of it than eight.
  List<Pill> get todayAll => _todayAll ??= [
    for (final Pill p
        in _served != null
            ? only(_served!.today)
            : only(pickedPills(seed: daySeed(_clock()), count: 60)))
      if (unread(p)) p,
  ];

  List<Pill>? _askingAll;

  /// A question from every subject: cards with an answer to give, one
  /// subject after another, in an order that never turns over. Only cards
  /// with a right answer, whoever dealt them, so the line under it is true
  /// of every row. Six of them.
  List<Pill> get asking => askingAll.take(6).toList();

  /// The question from every subject whole.
  List<Pill> get askingAll => _askingAll ??= [
    for (final Pill p
        in _served != null
            ? only(_served!.asking)
            : only(askingPills(seed: allTimeSeed, count: 120)))
      if (unread(p) && p.isGraded) p,
  ];

  final Map<bool, List<(Pill, int)>> _top = {};

  /// The top of the week, or of the [month], narrowed by the subject row
  /// like every other shelf, each card with how many readers kept it. Until
  /// the counts have been read — or where they cannot be, offline or on the
  /// web preview — empty, and the shelf shows its places empty.
  List<(Pill, int)> top({required bool month}) =>
      _top[month] ??= _topOf(month: month);

  List<(Pill, int)> _topOf({required bool month}) {
    final ServedExplore? served = _served;
    final String? key = subjectKey;
    if (served != null) {
      if (key == null) {
        return [
          for (final r in (month ? served.topMonth : served.topWeek))
            (r.pill, r.readers),
        ];
      }
      return _resolve(
        month
            ? served.bySubject[key]?.month ?? const []
            : served.bySubject[key]?.week ?? const [],
      );
    }
    final Tallies tallies = Tallies.instance;
    if (!tallies.ready) return const [];
    return [
      for (final Ranked place in tallies.top(
        month ? Tallies.monthDays : Tallies.weekDays,
        where: (id) {
          final Pill? pill = pillById(id);
          return pill != null &&
              !pill.isAboutAPlace &&
              (_subject == null || pill.topic == _subject);
        },
      ))
        (pillById(place.id)!, place.readers),
    ];
  }

  /// A card about a place is counted when the readers who live there keep
  /// it, and the counts are everybody's: no list here ever shows one.
  List<(Pill, int)> _resolve(List<(String, int)> ids) => [
    for (final (id, n) in ids)
      if (pillById(id) case final Pill p when !p.isAboutAPlace) (p, n),
  ];

  List<Pill>? _loved;

  /// Loved since the start, and not read yet: where somebody who arrived
  /// late finds the best of what came before them, and somebody who has
  /// been here two years still finds the next one they missed.
  List<Pill> get loved => _loved ??= _lovedOf();

  List<Pill> _lovedOf() {
    final ServedExplore? served = _served;
    final String? key = subjectKey;
    if (served != null) {
      return [
        for (final p
            in key == null
                ? served.loved.map((r) => r.pill)
                : _resolve(served.bySubject[key]?.loved ?? const [])
                      .map((t) => t.$1))
          if (unread(p)) p,
      ].take(8).toList();
    }
    final Tallies tallies = Tallies.instance;
    if (!tallies.ready) return const [];
    return [
      for (final Ranked place in tallies.allTime(
        where: (id) {
          final Pill? pill = pillById(id);
          return pill != null &&
              !pill.isAboutAPlace &&
              unread(pill) &&
              (_subject == null || pill.topic == _subject);
        },
        limit: 8,
      ))
        pillById(place.id)!,
    ];
  }

  (MineReason, String)? _third;
  bool _thirdKnown = false;

  /// The third shelf is about the reader: why it is theirs, and the subject
  /// it holds, by its name. Two answers, in the order of how much the app
  /// actually knows: the server's, or the mix the reader dragged, then what
  /// they have read most of. Before either exists, null, and there is no
  /// such shelf: the subject of the month further down is somewhere to
  /// start.
  (MineReason, String)? get third {
    if (_thirdKnown) return _third;
    _thirdKnown = true;
    final String? because = _served?.because;
    if (because != null) {
      return _third = (MineReason.because, kTopics[because]?.name ?? because);
    }
    final weights = app.topicWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (weights.isNotEmpty &&
        weights.first.value > 0 &&
        weights.first.value != weights.last.value) {
      final String name = kTopics[weights.first.key]?.name ?? '';
      if (name.isNotEmpty) return _third = (MineReason.because, name);
    }
    // What was read when the shelves were dealt, not what has been read
    // since: a card answered on a shelf further down must not slide a new
    // shelf in above the reader and push the page from under their thumb.
    final counted = <String, int>{};
    for (final pill in PillBank.cards) {
      if (_readWhenDealt.contains(pill.id)) {
        counted[pill.topic] = (counted[pill.topic] ?? 0) + 1;
      }
    }
    if (counted.isNotEmpty) {
      final String most =
          (counted.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
      return _third = (MineReason.readMost, most);
    }
    return _third = null;
  }

  List<Pill>? _mine;

  /// The reader's own shelf: the cards of [third]'s subject they have not
  /// read, the server's when it has them, in the month's order.
  List<Pill> get mine => _mine ??= _mineOf();

  List<Pill> _mineOf() {
    final (MineReason, String)? third = this.third;
    if (third == null) return const [];
    final ServedExplore? served = _served;
    return [
      for (final Pill p
          in served != null && served.mine.isNotEmpty
              ? only(served.mine)
              : only(
                  pickedPills(
                    seed: monthSeed(_clock()),
                    count: 120,
                    topic: third.$2,
                  ),
                ))
        if (unread(p)) p,
    ].take(8).toList();
  }

  List<Pill>? _local;

  /// Where you live: the cards about the reader's place, nearest first —
  /// the server's, from the place their backup holds, or the phone's own
  /// from the bank it carries — and only ever ones about where they live
  /// now. Read ones stay on it, marked: it is their home, not a list of
  /// finds. Empty without a place, and with a place nobody has written
  /// about yet.
  List<Pill> get local => _local ??= _localOf();

  List<Pill> _localOf() {
    final Place? home = app.place;
    if (home == null) return const [];
    final ServedExplore? served = _served;
    return [
      for (final Pill p
          in served != null && served.local.isNotEmpty
              ? served.local
              : whereYouLive(
                  home,
                  read: _readWhenDealt,
                  seed: monthSeed(_clock()),
                ))
        if (reachesReader(p, home) && (_subject == null || p.topic == _subject))
          p,
    ];
  }

  // ── The mix ─────────────────────────────────────────────────────────

  /// The mix, dealt once for a day and a subject and kept for the rest of
  /// it, like the shelves above: a card answered on a shelf, or read from
  /// one, stays where it is, marked, rather than the whole page being dealt
  /// again under the reader's thumb. Dealing it is also a pass over the
  /// whole bank, and the screen rebuilds on every count that arrives.
  ExploreMix? _mix;
  String _mixKey = '';

  /// What "your mood, your minutes" dealt for each tone and time, for the
  /// mix in force.
  final Map<String, List<Pill>> moodMemo = {};

  /// Everything under the shelves that were always there: one form per
  /// kind of card, dealt for the day from what the reader has not read,
  /// each card on one shelf only. Today's shelf, the question from every
  /// subject and the reader's own keep their cards, so nothing down here
  /// was just scrolled past.
  ExploreMix get mix {
    final int day = themeDay(_clock());
    // Today's shelf comes from the server when it has answered, and from
    // the phone before: the mix follows it once, when it arrives.
    final String source = _served == null ? 'phone' : 'served';
    final String key =
        '$day|${_subject ?? ''}|$_dealtOn|${PillBank.version}|$source';
    if (_mix != null && key == _mixKey) return _mix!;
    _mixKey = key;
    moodMemo.clear();
    final Set<String> above = {
      for (final p in today) p.id,
      for (final p in asking) p.id,
      for (final p in mine) p.id,
    };
    return _mix = dealExploreMix(
      bank: only(PillBank.cards),
      pool: only(PillBank.cards)
          .where((p) => unread(p) && !above.contains(p.id))
          .toList(),
      day: day,
      on: _clock(),
    );
  }

  /// The day of the mix, for the shelves that deal again from it.
  int get mixDay => themeDay(_clock());

  /// The cards that came back and wait to be answered again, narrowed by
  /// the subject row: worked out again only when an answer is given or the
  /// day turns, because it walks every answer the reader ever gave.
  List<CameBackCard> _cameBackCards = const [];
  String _cameBackKey = '';

  /// The cards that came back, each with how long ago it was answered and
  /// whether it was answered right.
  List<CameBackCard> get cameBack {
    final String key =
        '${dateKey(app.today)}|${app.answers.length}|'
        '${app.todaysDeck.length}|${_subject ?? ''}|${_dueCount(app)}';
    if (key == _cameBackKey) return _cameBackCards;
    _cameBackKey = key;
    return _cameBackCards = [
      for (final r in app.reviewsWaitingWithAnswers)
        if (_subject == null || r.card.topic == _subject)
          CameBackCard(
            r.card,
            days:
                kReviewLadder[r.last.stage.clamp(0, kReviewLadder.length - 1)],
            right: r.last.stage > 0,
          ),
    ];
  }

  /// How many answers are due today: what changes when a card that came
  /// back is answered again, which the count of answers does not.
  static int _dueCount(AppState app) {
    final String today = dateKey(app.today);
    int n = 0;
    for (final a in app.answers.values) {
      if (a.dueOn != null && a.dueOn!.compareTo(today) <= 0) n++;
    }
    return n;
  }

  // ── Sources ─────────────────────────────────────────────────────────

  final Map<String, List<Pill>> _cards = {};
  final Map<String, List<Pill>> _queries = {};

  /// The cards [section] asks for through its `source`, in order, at most
  /// [limit] — or the section's own `limit`, or what the source holds by
  /// its nature — narrowed to the subject in view. Empty for a source this
  /// build does not know, or one with nothing in it for this reader.
  ///
  /// * `{"shelf": name}` — a shelf of the server's Explore, as Explore
  ///   deals it: `today`, `asking`, `topWeek`, `topMonth`, `loved`, `mine`,
  ///   `forYou`, `local`. The phone's own before the server has answered,
  ///   except `forYou`, which only the server knows how to fill.
  /// * `{"ids": [...]}` — those cards, in that order: from the bank, or from
  ///   the server's Explore for one the bank on this phone has not got yet.
  /// * `{"query": {...}}` — cards from the bank: `subjects` (keys),
  ///   `formats` (see [isFormat]), `difficulty`, `unread`, `perSubject`,
  ///   `limit`, and `seed`, `day` (the default), `week` or `fixed`, which
  ///   decides when the pick turns over. The same pick on every phone for
  ///   the same seed, apart from what each reader has read.
  /// * `{"mine": "saved" | "liked" | "due"}` — the reader's own: what they
  ///   saved and liked, newest first, and what came back to be answered.
  List<Pill> cardsFor(ExploreSection section, {int? limit}) {
    final Object? source = section.source;
    final int? most = limit ?? section.limit;
    final String key = '${section.id}|$most|${_keyOf(source)}';
    return _cards[key] ??= _sourced(section, source, most);
  }

  static String _keyOf(Object? value) => switch (value) {
    final Map map =>
      '{${[for (final e in map.entries) '${e.key}:${_keyOf(e.value)}'].join(',')}}',
    final List list => '[${list.map(_keyOf).join(',')}]',
    _ => '$value',
  };

  List<Pill> _sourced(ExploreSection section, Object? source, int? most) {
    if (source == null) {
      // A section that names no source draws from the whole bank, the
      // same for every reader and turning with the day. The families'
      // blocks pick from it what they need — numbers for a bet, debates
      // for two halves, a theme for a set — and a section that wants
      // other cards says which.
      final String key =
          '${section.id}|*|${_subject ?? ''}|$_dealtOn|${PillBank.version}';
      if (_queries.length > 200) _queries.clear();
      final List<Pill> pool = _queries[key] ??= _pool(section);
      return pool.take(most ?? pool.length).toList();
    }
    if (source is! Map) return const [];
    final List<Pill> found;
    final int natural;
    if (source['shelf'] case final String shelf) {
      (found, natural) = _shelf(shelf);
    } else if (source['ids'] case final List ids) {
      found = _ids(ids);
      natural = found.length;
    } else if (source['query'] case final Map query) {
      // A pass over the whole bank, the same until the subject, the day's
      // deal or the bank changes: kept across builds, where the other
      // sources are worked out again on every one.
      final String key =
          '${section.id}|${_keyOf(query)}|${_subject ?? ''}|$_dealtOn|'
          '${PillBank.version}';
      if (_queries.length > 200) _queries.clear();
      found = _queries[key] ??= _query(section, query);
      final Object? own = query['limit'];
      natural = own is num && own > 0 ? own.toInt() : 12;
    } else if (source['mine'] case final String mine) {
      found = _readers(mine);
      natural = 20;
    } else {
      return const [];
    }
    return found.take(most ?? natural).toList();
  }

  (List<Pill>, int) _shelf(String name) => switch (name) {
    'today' => (todayAll, 8),
    'asking' => (askingAll, 6),
    'topWeek' => ([for (final (p, _) in top(month: false)) p], 10),
    'topMonth' => ([for (final (p, _) in top(month: true)) p], 10),
    'loved' => (loved, 8),
    'mine' => (mine, 8),
    'forYou' => (
      [
        for (final Pill p in only(_served?.forYou ?? const []))
          if (unread(p)) p,
      ],
      8,
    ),
    'local' => (local, 12),
    _ => (const <Pill>[], 0),
  };

  List<Pill> _ids(List ids) {
    final Map<String, Pill> served = {
      for (final Pill p in [
        ...?_served?.today,
        ...?_served?.asking,
        ...?_served?.mine,
        ...?_served?.forYou,
        for (final r in [...?_served?.topWeek, ...?_served?.topMonth]) r.pill,
        for (final r in [...?_served?.loved]) r.pill,
      ])
        p.id: p,
    };
    final Set<String> live = _liveIds();
    final List<Pill> out = [];
    final Set<String> taken = {};
    for (final Object? id in ids) {
      if (id is! String || !taken.add(id)) continue;
      final Pill? fromBank = live.contains(id) ? PillBank.byId(id) : null;
      final Pill? pill = fromBank ?? served[id];
      if (pill == null || !reachesReader(pill, app.place)) continue;
      out.add(pill);
    }
    return only(out);
  }

  Set<String>? _live;
  int _liveVersion = -1;

  Set<String> _liveIds() {
    if (_live == null || _liveVersion != PillBank.version) {
      _liveVersion = PillBank.version;
      _live = {for (final Pill p in PillBank.live) p.id};
    }
    return _live!;
  }

  /// Every card the dealer may hand anybody, narrowed to the subject in
  /// view, in an order that turns with the day and is the same on every
  /// phone that day.
  List<Pill> _pool(ExploreSection section) {
    final String salt = 'pool:${section.id}:${themeDay(_clock())}';
    final List<Pill> cards = only(PillBank.cards).toList();
    final Map<String, int> rank = {
      for (final Pill p in cards) p.id: shelfHash('$salt:${p.id}'),
    };
    return cards..sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
  }

  List<Pill> _query(ExploreSection section, Map query) {
    Set<String>? strings(String key) {
      final Object? raw = query[key];
      return raw is List ? raw.whereType<String>().toSet() : null;
    }

    final Set<String>? subjects = strings('subjects');
    final Set<String>? formats = strings('formats');
    final Set<String>? difficulty = strings('difficulty');
    final bool unreadOnly = query['unread'] == true;
    final Object? per = query['perSubject'];
    final int perSubject = per is num && per > 0 ? per.toInt() : 2;
    final DateTime now = _clock();
    final int turn = switch (query['seed']) {
      'week' => int.tryParse(weekSeed(now).split('-w').last) ?? 0,
      'fixed' => 0,
      _ => themeDay(now),
    };
    final String salt = switch (query['seed']) {
      'week' => 'week:${now.year}:${section.id}',
      'fixed' => 'fixed:${section.id}',
      _ => 'day:${section.id}',
    };
    final Iterable<Pill> fits = only(PillBank.cards).where(
      (p) =>
          (subjects == null || subjects.contains(subjectKeyOf(p))) &&
          (formats == null || formats.any((f) => isFormat(p, f))) &&
          (difficulty == null || difficulty.contains(p.difficulty.name)) &&
          (!unreadOnly || unread(p)),
    );
    final Object? own = query['limit'];
    return dealCards(
      fits,
      salt: salt,
      day: turn,
      count: own is num && own > 0 ? own.toInt() : 120,
      perTopic: perSubject,
    );
  }

  List<Pill> _readers(String which) {
    final List<Pill> cards = switch (which) {
      'saved' => [for (final id in app.savedIds) ?pillById(id)],
      'liked' => [for (final id in app.likedIds) ?pillById(id)],
      'due' => [for (final r in app.reviewsWaitingWithAnswers) r.card],
      _ => const <Pill>[],
    };
    return only([
      for (final Pill p in cards)
        if (reachesReader(p, app.place)) p,
    ]);
  }
}

/// Whether [pill] is of [format]: a kind of question — `read`, `pickOne`,
/// `number`, `estimate`, `debate`, and `trueOrFalse` among the ones to pick
/// — `diagram` for a card that carries one, or the kind of scene the reader
/// plays with on it (`slider`, `story`, `trick` …).
bool isFormat(Pill pill, String format) => switch (format) {
  'read' => pill.challenge is NoChallenge,
  'pickOne' => pill.challenge is PickOne,
  'number' => pill.challenge is TypeNumber,
  'estimate' => pill.challenge is Estimate,
  'debate' => pill.challenge is TakeASide,
  'trueOrFalse' => isTrueOrFalse(pill),
  'diagram' => pill.diagram != null,
  _ => pill.scene?.raw['type'] == format,
};
