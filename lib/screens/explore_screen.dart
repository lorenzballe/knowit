import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/pills_repository.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../sync/served.dart';
import '../sync/tally.dart';
import '../sync/trace.dart';
import '../theme.dart';
import '../widgets/scaled_text.dart';
import '../widgets/subject_icon.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart';
import '../analytics.dart';

/// Cards nobody dealt you — artboard 72a.
///
/// What was here before was a leaderboard: a ranked list, two rows of chips
/// and every card reduced to a thin grey row. Nothing about it looked like
/// this app. The colour, the card as an object and the question are the
/// product, and a ranked list throws all three away — so this is shelves
/// instead, each with a reason for existing written under its name, and the
/// cards on them are cards.
///
/// The subject row across the top narrows every shelf at once. The search
/// button opens a field over the whole pool, which is the one thing a
/// ranked list was better at and the reason it is still here.
///
/// The one ranking that came back is the top of the week and of the month,
/// because it is the one with something true to rank by: what readers
/// liked, saved and said, counted across everyone. It is numbered, since a
/// top that does not say which is first is not one — but the cards stay
/// cards, each standing on its number.
class ExploreScreen extends StatefulWidget {
  final AppState app;

  const ExploreScreen({super.key, required this.app});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _shelves = ScrollController();

  /// The subject's display name, or null for all of them.
  String? _subject;

  bool _searching = false;
  String _query = '';

  /// The top list's window: the last seven days, or the last thirty.
  bool _topMonth = false;

  @override
  void initState() {
    super.initState();
    // Nothing to read before the reader is signed in; the call says so
    // itself, and main asks again once they are.
    Tallies.instance.refresh();
    Served.instance.explore();
    _shelves.addListener(_scrolled);
  }

  /// What the server found for the query being typed, and for which query,
  /// so a slow answer to an old query never lands under a new one.
  List<Pill>? _serverHits;
  String _serverHitsFor = '';

  /// A search is said once the reader stops typing, not at every letter —
  /// and only what shape it had: how long, and how much it found. What was
  /// typed stays on the phone.
  Timer? _searchSettle;

  void _typed(String q) {
    setState(() => _query = q);
    _searchSettle?.cancel();
    if (q.trim().isEmpty) return;
    // The phone answers at once from the bank it holds; the server, which
    // holds the newest bank, answers a moment after the typing stops, and
    // its answer replaces the phone's for the same query.
    _searchSettle = Timer(const Duration(milliseconds: 500), () async {
      final String asked = q.trim();
      final List<Pill>? hits = await Served.instance.search(asked);
      if (!mounted || _query.trim() != asked) return;
      if (hits != null) {
        setState(() {
          _serverHits = hits;
          _serverHitsFor = asked;
        });
      }
      if (!Analytics.ready) return;
      Analytics.capture('explore searched', {
        'query_length': asked.length,
        'words': asked.split(RegExp(r'\s+')).length,
        'results': (hits ?? searchPills(asked)).length,
      });
    });
  }

  @override
  void dispose() {
    _searchSettle?.cancel();
    _field.dispose();
    _focus.dispose();
    _shelves.dispose();
    super.dispose();
  }

  /// Puts the shelves back the way the tab opens: every subject, no search,
  /// scrolled to the top. The finished day's button promises today's best,
  /// and a tab still filtered to Cinema from last week would break it.
  void showBest() {
    _field.clear();
    _focus.unfocus();
    setState(() {
      _subject = null;
      _searching = false;
      _query = '';
    });
    if (_shelves.hasClients) _shelves.jumpTo(0);
  }

  List<Pill> _only(List<Pill> pills) => _subject == null
      ? pills
      : pills.where((p) => p.topic == _subject).toList();

  /// What the shelves put in front of the reader, once per card per shelf
  /// per visit: a card shown and not opened is a thing the dealer can learn
  /// from, the way a feed learns from what you scrolled past.
  final Set<String> _shown = {};

  /// How far down the shelves the reader went, in tenths, said once per
  /// tenth per visit: what a feed calls depth, and the difference between
  /// a reader who found the top list and one who never saw it.
  final Set<int> _depths = {};

  void _scrolled() {
    if (!_shelves.hasClients) return;
    final ScrollPosition pos = _shelves.position;
    if (pos.maxScrollExtent <= 0) return;
    final int tenth = (pos.pixels / pos.maxScrollExtent * 10)
        .clamp(0, 10)
        .round();
    if (!_depths.add(tenth)) return;
    Trace.instance.note('explore scrolled', {'depth': tenth * 10});
  }

  void _seen(String shelf, Pill pill) {
    if (!_shown.add('$shelf:${pill.id}')) return;
    Trace.instance.note('card shown', {'pill_id': pill.id, 'shelf': shelf});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _Head(
            searching: _searching,
            field: _field,
            focus: _focus,
            onOpenSearch: () {
              Analytics.capture('explore search opened');
              setState(() => _searching = true);
              _focus.requestFocus();
            },
            onCloseSearch: () {
              Analytics.capture('explore search closed', {
                'had_query': _query.trim().isNotEmpty,
              });
              _field.clear();
              setState(() {
                _searching = false;
                _query = '';
              });
            },
            onChanged: _typed,
          ),
        ),
        if (!_searching)
          _SubjectRow(
            selected: _subject,
            // A subject, All, or the lit subject again — the last two both
            // clear it, so the way back is whichever the finger finds first.
            onPick: (name) {
              final String? next = name == _subject ? null : name;
              Analytics.capture('explore filtered', {'subject': next ?? 'all'});
              setState(() => _subject = next);
            },
          ),
        Expanded(
          child: _searching
              ? _found(context)
              : ListenableBuilder(
                  // The counts, and what the reader has read: a card read
                  // here leaves the shelves for finding things as soon as
                  // the reader is back on them.
                  listenable: Listenable.merge([
                    Tallies.instance,
                    Served.instance,
                    widget.app,
                  ]),
                  builder: (context, _) => _shelfList(context),
                ),
        ),
      ],
    );
  }

  /// The shelves, and a fade where they run under the tab bar.
  Widget _shelfList(BuildContext context) {
    // Today's shelf is the same for everybody and changes at midnight —
    // which is what the canvas means by "written this morning". Nothing
    // here is dealt from the reader's own mix.
    // The shelves for finding things hold only cards the reader has not
    // read — a card already read is not a find. The top list is the one
    // shelf that keeps them, marked, because it is one list for everybody.
    bool unread(Pill p) => !widget.app.seenIds.contains(p.id);

    // Explore as the server assembled it, when it has: the same shelves,
    // from the newest bank, and one more that is the reader's own. Without
    // it — no account, the web preview, a project not yet on the plan —
    // the phone assembles the same shelves from the bank it holds.
    final ServedExplore? served = Served.instance.lastExplore;
    final String? subjectKey = _subject == null
        ? null
        : kTopics.entries
              .where((e) => e.value.name == _subject)
              .map((e) => e.key)
              .firstOrNull;
    List<(Pill, int)> resolve(List<(String, int)> ids) => [
      for (final (id, n) in ids)
        if (pillById(id) case final Pill p) (p, n),
    ];

    final List<Pill> fresh =
        (served != null
                ? _only(served.today)
                : _only(pickedPills(seed: daySeed(DateTime.now()), count: 60)))
            .where(unread)
            .take(8)
            .toList();

    final List<Pill> forYou = served == null
        ? const []
        : _only(served.forYou).where(unread).take(8).toList();

    // The canvas ranks this shelf by what everyone saved. Saves are counted
    // now, and they rank the top list above it; this shelf stays ranked by
    // what the cards ask, which is a different question and the order it
    // was always in.
    final List<Pill> asking =
        (served != null
                ? _only(served.asking)
                : _only(pickedPills(seed: allTimeSeed, count: 120)))
            .where(unread)
            .take(6)
            .toList();

    // The top list, narrowed by the subject row like every other shelf.
    // The shelf is always there: until the counts have been read — or
    // where they cannot be, offline or on the web preview — it shows its
    // places empty, with the line that says what puts a card on one. A
    // shelf that hid itself was a feature nobody could find.
    final Tallies tallies = Tallies.instance;
    final List<(Pill, int)> top = served != null
        ? (subjectKey == null
              ? [
                  for (final r
                      in (_topMonth ? served.topMonth : served.topWeek))
                    (r.pill, r.readers),
                ]
              : resolve(
                  _topMonth
                      ? served.bySubject[subjectKey]?.month ?? const []
                      : served.bySubject[subjectKey]?.week ?? const [],
                ))
        : [
            if (tallies.ready)
              for (final Ranked place in tallies.top(
                _topMonth ? Tallies.monthDays : Tallies.weekDays,
                where: (id) {
                  final Pill? pill = pillById(id);
                  return pill != null &&
                      (_subject == null || pill.topic == _subject);
                },
              ))
                (pillById(place.id)!, place.readers),
          ];

    // The third shelf is about the reader, and it is always there. An
    // install that never dragged the mix used to get two shelves and a
    // page with nowhere to scroll to, which is not this screen.
    final (String title, String line, String subject) = served?.because != null
        ? (
            context.l10n.becauseSitsAtFull(
              kTopics[served!.because]?.name ?? served.because!,
            ),
            context.l10n.olderFromTurnedUp,
            kTopics[served.because]?.name ?? served.because!,
          )
        : _thirdShelf();
    final List<Pill> mine =
        (served != null && served.mine.isNotEmpty
                ? _only(served.mine)
                : _only(
                    pickedPills(
                      seed: monthSeed(DateTime.now()),
                      count: 120,
                      topic: subject,
                    ),
                  ))
            .where(unread)
            .take(8)
            .toList();

    // Loved since the start, and not read yet: where somebody who arrived
    // late finds the best of what came before them, and somebody who has
    // been here two years still finds the next one they missed.
    final List<Pill> loved = served != null
        ? [
            for (final p
                in subjectKey == null
                    ? served.loved.map((r) => r.pill)
                    : resolve(served.bySubject[subjectKey]?.loved ?? const [])
                          .map((t) => t.$1))
              if (unread(p)) p,
          ].take(8).toList()
        : [
            if (tallies.ready)
              for (final Ranked place in tallies.allTime(
                where: (id) {
                  final Pill? pill = pillById(id);
                  return pill != null &&
                      unread(pill) &&
                      (_subject == null || pill.topic == _subject);
                },
                limit: 8,
              ))
                pillById(place.id)!,
          ];

    return Stack(
      children: [
        ListView(
          controller: _shelves,
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            if (fresh.isEmpty && asking.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Text(
                  context.l10n.nothingInYet(_subject ?? context.l10n.here),
                  style: AppText.body(size: 14, color: context.p.inkMuted),
                ),
              ),
            if (served?.fromCache == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  context.l10n.exploreOffline,
                  key: const ValueKey('explore-offline'),
                  style: AppText.body(size: 12.5, color: context.p.inkMuted),
                ),
              ),
            if (forYou.isNotEmpty) ...[
              _Shelf(
                title: context.l10n.forYouShelf,
                line: context.l10n.forYouLine,
                child: _SmallRow(
                  pills: forYou,
                  onOpen: _open,
                  onShown: (p) => _seen('foryou', p),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (fresh.isNotEmpty)
              _Shelf(
                title: context.l10n.todaysShelf,
                line: context.l10n.sameForEveryone,
                child: _BigRow(
                  pills: fresh,
                  onOpen: _open,
                  onShown: (p) => _seen('today', p),
                ),
              ),
            const SizedBox(height: 24),
            _Shelf(
              title: _subject != null
                  ? context.l10n.topIn(_subject!)
                  : _topMonth
                  ? context.l10n.topOfTheMonth
                  : context.l10n.topOfTheWeek,
              line: _topMonth
                  ? context.l10n.topLineMonth
                  : context.l10n.topLineWeek,
              trailing: _WindowSwitch(
                month: _topMonth,
                onPick: (month) {
                  Analytics.capture('explore top window', {
                    'window': month ? 'month' : 'week',
                    'subject': _subject ?? 'all',
                  });
                  setState(() => _topMonth = month);
                },
              ),
              child: top.isEmpty
                  ? const _TopGhost()
                  : _TopRow(
                      ranked: top,
                      isRead: (p) => !unread(p),
                      onShown: (p) => _seen('top', p),
                      onOpen: (i) {
                        Analytics.capture('explore top opened', {
                          'rank': i + 1,
                          'readers': top[i].$2,
                          'window': _topMonth ? 'month' : 'week',
                          'subject': _subject ?? 'all',
                        });
                        _open([for (final t in top) t.$1], top[i].$1);
                      },
                    ),
            ),
            if (loved.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Shelf(
                title: _subject != null
                    ? context.l10n.lovedIn(_subject!)
                    : context.l10n.lovedSinceTheStart,
                line: context.l10n.lovedLine,
                child: _SmallRow(
                  pills: loved,
                  onShown: (p) => _seen('loved', p),
                  onOpen: (shelf, pill) {
                    Analytics.capture('explore loved opened', {
                      'rank': shelf.indexOf(pill) + 1,
                      'subject': _subject ?? 'all',
                    });
                    _open(shelf, pill);
                  },
                ),
              ),
            ],
            if (asking.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Shelf(
                title: context.l10n.onesThatAskTheMost,
                line: context.l10n.acrossEveryone,
                child: _RowList(
                  pills: asking,
                  onOpen: _open,
                  onShown: (p) => _seen('asking', p),
                ),
              ),
            ],
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Shelf(
                title: title,
                line: line,
                child: _SmallRow(
                  pills: mine,
                  onOpen: _open,
                  onShown: (p) => _seen('mine', p),
                ),
              ),
            ],
          ],
        ),
        // The shelves run under the tab bar rather than stopping short of
        // it, so the last one has to say it is not the end.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 40,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.p.surface.withValues(alpha: 0),
                    context.p.surface,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The last shelf: what it is called, why, and whose cards are on it.
  ///
  /// Three answers, in the order of how much the app actually knows. The
  /// mix the reader dragged is the best of them and the canvas's own; what
  /// they have read most of is the next; and before either of those exists
  /// there is still a subject to put on a shelf, which beats a screen with
  /// a hole where a shelf was.
  (String, String, String) _thirdShelf() {
    final app = widget.app;

    final weights = app.topicWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (weights.isNotEmpty &&
        weights.first.value > 0 &&
        weights.first.value != weights.last.value) {
      final String name = kTopics[weights.first.key]?.name ?? '';
      if (name.isNotEmpty) {
        return (
          context.l10n.becauseSitsAtFull(name),
          context.l10n.olderFromTurnedUp,
          name,
        );
      }
    }

    final counted = <String, int>{};
    for (final pill in PillBank.cards) {
      if (app.seenIds.contains(pill.id)) {
        counted[pill.topic] = (counted[pill.topic] ?? 0) + 1;
      }
    }
    if (counted.isNotEmpty) {
      final String most =
          (counted.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
      return (context.l10n.moreOn(most), context.l10n.subjectReadMost, most);
    }

    // Nothing read and no mix: a subject of the month, so the shelf is
    // still a shelf on the morning somebody installs the app.
    final subjects =
        app.pickedTopics
            .map((key) => kTopics[key]?.name)
            .whereType<String>()
            .toList()
          ..sort();
    final String name = subjects.isEmpty
        ? kTopics['science']!.name
        : subjects[monthSeed(DateTime.now()).hashCode.abs() % subjects.length];
    return (context.l10n.monthOf(name), context.l10n.somewhereToStart, name);
  }

  Widget _found(BuildContext context) {
    final List<Pill> rows = _query.trim().isEmpty
        ? const []
        : _serverHitsFor == _query.trim() && _serverHits != null
        ? _serverHits!
        : searchPills(_query);
    if (_query.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Text(
          context.l10n.searchEveryCard,
          style: AppText.body(size: 13, color: context.p.inkMuted),
        ),
      );
    }
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Text(
          context.l10n.nothingForYet(_query.trim()),
          style: AppText.body(size: 13, color: context.p.inkMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            context.l10n.matching(rows.length),
            style: AppText.body(
              size: 12,
              color: context.p.ink.withValues(alpha: 0.42),
            ),
          ),
        ),
        for (final pill in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _CardRow(pill: pill, onTap: () => _open(rows, pill)),
          ),
      ],
    );
  }

  void _open(List<Pill> shelf, Pill pill) {
    openDeckViewer(
      context,
      widget.app,
      shelf,
      _subject ?? context.l10n.tabExplore,
      initialIndex: shelf.indexOf(pill),
      // Nothing here was dealt: a card read here is read.
      countsAsRead: true,
    );
  }
}

/// The title, and the way into the whole pool.
class _Head extends StatelessWidget {
  const _Head({
    required this.searching,
    required this.field,
    required this.focus,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onChanged,
  });

  final bool searching;
  final TextEditingController field;
  final FocusNode focus;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: context.p.ink.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: context.p.ink.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: field,
                      focusNode: focus,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: AppText.body(size: 14.5, color: context.p.ink),
                      cursorColor: context.p.ink,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: context.l10n.searchEveryCard,
                        hintStyle: AppText.body(
                          size: 14.5,
                          color: context.p.inkFaint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCloseSearch,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                context.l10n.cancel,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w500,
                  color: context.p.inkMuted,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.tabExplore,
          style: AppText.display(
            size: 27,
            weight: FontWeight.w600,
            height: 1,
            spacing: -0.8,
            color: context.p.ink,
          ),
        ),
        Semantics(
          key: const ValueKey('explore-search'),
          button: true,
          label: context.l10n.searchEveryCard,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenSearch,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.p.ink.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.search_rounded,
                size: 16,
                color: context.p.ink.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Every subject, across the top, narrowing every shelf at once.
///
/// The mark keeps the subject's colour even when the chip is not chosen,
/// which is what makes the row readable as a palette rather than as a row
/// of grey pills.
class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.selected, required this.onPick});

  final String? selected;

  /// Null clears the filter — the "All" at the head of the row.
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // "All" first, so the way back to everything is a chip and not
        // the knowledge that tapping the lit one again clears it.
        itemCount: kMixSubjects.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final MixSubject? subject = i == 0 ? null : kMixSubjects[i - 1];
          final bool on = subject == null
              ? selected == null
              : selected == subject.name;
          final Color ink = subject == null
              ? (on ? context.p.onInverse : context.p.ink)
              : (on ? inkOn(subject.color) : context.p.ink);
          return Semantics(
            // The key says which subject and whether it is chosen, so the
            // one thing this row does can be seen from outside it.
            key: ValueKey(
              'subject-${subject?.name ?? context.l10n.all}-${on ? 'on' : 'off'}',
            ),
            button: true,
            selected: on,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(subject?.name),
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: on
                        ? (subject?.color ?? context.p.inverse)
                        : context.p.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subject != null) ...[
                        SubjectIcon(
                          subject: subject.name,
                          size: 14,
                          ink: on ? ink : subject.color,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        subject?.name ?? 'All',
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: on
                              ? ink
                              : context.p.ink.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A shelf: what it holds, why it exists, and the cards — and, where the
/// shelf can be turned, the control that turns it, level with its name.
class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.title,
    required this.line,
    required this.child,
    this.trailing,
  });

  final String title;
  final String line;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget name = Text(
      title,
      style: AppText.body(
        size: 16,
        weight: FontWeight.w600,
        height: 1,
        spacing: -0.2,
        color: context.p.ink,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The control sits level with the name, and the line runs
              // under both, so a long one in any language keeps to a line.
              if (trailing == null)
                name
              else
                Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ),
              SizedBox(height: trailing == null ? 3 : 4),
              Text(
                line,
                style: AppText.body(
                  size: 12,
                  height: 1.3,
                  color: context.p.ink.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        child,
      ],
    );
  }
}

/// The top shelf: cards at a size you can read across the room.
class _BigRow extends StatelessWidget {
  const _BigRow({required this.pills, required this.onOpen, this.onShown});

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pill = pills[i];
          onShown?.call(pill);
          final Color sub = pill.ink.withValues(alpha: 0.66);
          return GestureDetector(
            key: ValueKey('explore-${pill.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(pills, pill),
            child: Container(
              width: 214,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: pill.color,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          pill.topic.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label(
                            size: 9,
                            weight: FontWeight.w700,
                            spacing: 1.2,
                            color: sub,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // The canvas was drawn around four-word questions and
                  // the pool is not written to that length. Set to the
                  // space rather than cut with an ellipsis: a question
                  // that stops mid-sentence is a card nobody taps.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ScaledText(
                        text: pill.question,
                        min: 12,
                        max: 19,
                        alignment: Alignment.centerLeft,
                        styleFor: (size) => AppText.display(
                          size: size,
                          weight: FontWeight.w600,
                          height: 1.14,
                          spacing: -0.6 * size / 19,
                          color: pill.ink,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    pill.barMove,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w500,
                      height: 1.3,
                      color: pill.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The middle shelf: rows, with the subject's colour carrying its mark.
class _RowList extends StatelessWidget {
  const _RowList({required this.pills, required this.onOpen, this.onShown});

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    // A column shows all of its rows at once.
    for (final pill in pills) {
      onShown?.call(pill);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (final pill in pills)
            Padding(
              padding: EdgeInsets.only(bottom: pill == pills.last ? 0 : 7),
              child: _CardRow(pill: pill, onTap: () => onOpen(pills, pill)),
            ),
        ],
      ),
    );
  }
}

/// One card as a row: a block of its colour with its mark on it, and the
/// question beside it.
class _CardRow extends StatelessWidget {
  const _CardRow({required this.pill, required this.onTap});

  final Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('explore-${pill.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ColoredBox(
          color: context.p.ink.withValues(alpha: 0.05),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 44,
                  color: pill.color,
                  alignment: Alignment.center,
                  child: SubjectIcon(
                    subject: pill.topic,
                    size: 16,
                    ink: pill.ink,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          pill.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 13.5,
                            weight: FontWeight.w600,
                            height: 1.26,
                            color: context.p.ink.withValues(alpha: 0.93),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pill.topic,
                          style: AppText.body(
                            size: 10.5,
                            weight: FontWeight.w500,
                            height: 1,
                            spacing: 0.3,
                            color: context.p.ink.withValues(alpha: 0.36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom shelf: smaller cards, because by here the reader is looking
/// rather than reading.
class _SmallRow extends StatelessWidget {
  const _SmallRow({required this.pills, required this.onOpen, this.onShown});

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pill = pills[i];
          onShown?.call(pill);
          return GestureDetector(
            key: ValueKey('explore-${pill.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(pills, pill),
            child: Container(
              width: 158,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pill.color,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      // From the top, whatever the length: a short question
                      // sitting at the bottom of its card next to a long one
                      // filling its own reads as two designs on one shelf.
                      child: ScaledText(
                        text: pill.question,
                        min: 10.5,
                        max: 15,
                        alignment: Alignment.topLeft,
                        styleFor: (size) => AppText.display(
                          size: size,
                          weight: FontWeight.w600,
                          height: 1.15,
                          spacing: -0.4 * size / 15,
                          color: pill.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// This week or this month, for the top list: two words, one lit — the
/// subject row's chip, made into a pair.
class _WindowSwitch extends StatelessWidget {
  const _WindowSwitch({required this.month, required this.onPick});

  final bool month;
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    Widget side(String label, bool isMonth) {
      final bool on = month == isMonth;
      return Semantics(
        key: ValueKey('top-${isMonth ? 'month' : 'week'}-${on ? 'on' : 'off'}'),
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on ? null : () => onPick(isMonth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? context.p.inverse
                  : context.p.inverse.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: AppText.body(
                size: 11.5,
                weight: FontWeight.w600,
                height: 1,
                color: on
                    ? context.p.onInverse
                    : context.p.ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          side(context.l10n.topWeek, false),
          side(context.l10n.topMonth, true),
        ],
      ),
    );
  }
}

/// The top list: each card standing on its place, the number behind it.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.ranked,
    required this.onOpen,
    required this.isRead,
    this.onShown,
  });

  final List<(Pill, int)> ranked;
  final ValueChanged<int> onOpen;
  final ValueChanged<Pill>? onShown;

  /// Whether the reader has read a card already. The list is the same for
  /// everybody, so a card read stays on its place, marked.
  final bool Function(Pill) isRead;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
        itemCount: ranked.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          onShown?.call(ranked[i].$1);
          return _Placed(
            rank: i + 1,
            pill: ranked[i].$1,
            readers: ranked[i].$2,
            read: isRead(ranked[i].$1),
            onTap: () => onOpen(i),
          );
        },
      ),
    );
  }
}

/// One place on the list: the number, and what stands in front of it,
/// over the number's last edge — so the card is still the thing, and the
/// number is what it stands on. A ring of the page's own colour runs round
/// the card where it meets the number, the way a magazine cuts a picture
/// out of the type behind it.
class _Place extends StatelessWidget {
  const _Place({required this.rank, required this.card, this.faint = false});

  final int rank;
  final Widget card;

  /// An empty place: the number there, but barely.
  final bool faint;

  static const double _card = 146;
  static const double _ring = 3;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final TextStyle numeral = AppText.display(
      size: 124,
      weight: FontWeight.w700,
      height: 1,
      spacing: -6,
      color: ink,
    );
    // Measured, because a 1 is half the width of a 2: a fixed gap would
    // leave the one adrift and bury the other.
    final TextPainter painter = TextPainter(
      text: TextSpan(text: '$rank', style: numeral),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    final double cardLeft = width - math.max(8, width * 0.14);
    final List<Color> fade = faint
        ? [ink.withValues(alpha: 0.24), ink.withValues(alpha: 0.06)]
        : [ink, ink.withValues(alpha: 0.42)];

    return SizedBox(
      width: cardLeft + _card + _ring * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: -13,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: fade,
              ).createShader(rect),
              child: Text(
                '$rank',
                textScaler: TextScaler.noScaling,
                style: numeral,
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: cardLeft,
            width: _card + _ring * 2,
            child: Container(
              padding: const EdgeInsets.all(_ring),
              decoration: BoxDecoration(
                color: context.p.surface,
                borderRadius: BorderRadius.circular(19 + _ring),
              ),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card on the list: its subject, its question, and how many readers
/// kept it.
class _Placed extends StatelessWidget {
  const _Placed({
    required this.rank,
    required this.pill,
    required this.readers,
    required this.onTap,
    this.read = false,
  });

  final int rank;
  final Pill pill;
  final int readers;
  final VoidCallback onTap;

  /// Read already: a tick by the subject, and the word under the count.
  final bool read;

  @override
  Widget build(BuildContext context) {
    final Color sub = pill.ink.withValues(alpha: 0.66);
    return GestureDetector(
      key: ValueKey('top-${pill.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Place(
        rank: rank,
        card: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
          decoration: BoxDecoration(
            color: pill.color,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SubjectIcon(subject: pill.topic, size: 14, ink: pill.ink),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      pill.topic.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 8.5,
                        weight: FontWeight.w700,
                        spacing: 1.1,
                        color: sub,
                      ),
                    ),
                  ),
                  if (read) ...[
                    const SizedBox(width: 6),
                    Semantics(
                      label: context.l10n.readMark,
                      child: Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('top-read-${pill.id}'),
                        size: 14,
                        color: pill.ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: ScaledText(
                    text: pill.question,
                    min: 10.5,
                    max: 15,
                    alignment: Alignment.topLeft,
                    styleFor: (size) => AppText.display(
                      size: size,
                      weight: FontWeight.w600,
                      height: 1.15,
                      spacing: -0.4 * size / 15,
                      color: pill.ink,
                    ),
                  ),
                ),
              ),
              Text(
                read
                    ? '${context.l10n.readMark} · ${context.l10n.topReaders(readers)}'
                    : context.l10n.topReaders(readers),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w600,
                  height: 1,
                  color: pill.ink.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The list with nothing on it yet: the first three places, numbered and
/// empty, and on the first of them what puts a card there. The same
/// height as the list, so nothing jumps when the cards arrive.
class _TopGhost extends StatelessWidget {
  const _TopGhost();

  @override
  Widget build(BuildContext context) {
    Widget slot({Widget? child}) => Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: context.p.ink.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: context.p.ink.withValues(alpha: 0.10)),
      ),
      child: child,
    );

    return SizedBox(
      key: const ValueKey('top-empty'),
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) => _Place(
          rank: i + 1,
          faint: true,
          card: slot(
            // Set to the space, like the cards: some languages take twice
            // the words to say it.
            child: i == 0
                ? ScaledText(
                    text: context.l10n.topEmpty,
                    min: 9.5,
                    max: 12,
                    alignment: Alignment.bottomLeft,
                    styleFor: (size) => AppText.body(
                      size: size,
                      weight: FontWeight.w500,
                      height: 1.4,
                      color: context.p.inkMuted,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
