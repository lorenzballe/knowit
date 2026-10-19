import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/local_cards.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart' show inkOn;
import '../explore/blocks/core/shelves.dart';
import '../explore/explore_block.dart';
import '../models/pill.dart';
import '../remote/remote.dart';
import '../state/app_state.dart';
import '../state/explore_play.dart';
import '../sync/served.dart';
import '../sync/tally.dart';
import '../sync/trace.dart';
import '../theme.dart';
import '../widgets/explore/explore_engine.dart';
import '../widgets/explore/first_shelves.dart' show CardRow;
import '../widgets/explore/story_player.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/subject_icon.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart';
import '../analytics.dart';
import '../measure/screens.dart';
import '../measure/shelves.dart';

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
///
/// Which shelves there are, in what order, called what and for whom is the
/// server's to say: the page is a list of sections, each drawn by a block
/// (lib/explore/), read from the remote document's `explore` part, and the
/// build's own list when the document says nothing — the shelves above, as
/// they always were. The screen is what every block is handed to do what a
/// shelf does ([ExploreHost]): open a card, record an answer, count what
/// was shown.
class ExploreScreen extends StatefulWidget {
  final AppState app;

  const ExploreScreen({super.key, required this.app});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

/// The Explore screen, and the host every section on it is drawn for.
class ExploreScreenState extends State<ExploreScreen>
    implements ExploreShelfHost {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _list = ScrollController();

  /// The subject's display name, or null for all of them.
  String? _subject;

  bool _searching = false;
  String _query = '';

  /// What the shelves put in front of the reader in each stay on the tab.
  final ShelfSight _sight = ShelfSight();
  late final ShelfStay _stay = ShelfStay(
    _sight,
    // A new stay: the shelves built already are built again, so what is on
    // them is counted for this stay too.
    onArrive: () {
      if (mounted) setState(() {});
    },
  );

  /// The shelves' places on the page, by section, as last numbered.
  Map<String, int> _positions = const {};

  /// True while the engine asks every block what it would draw: a card a
  /// block names then is not on screen, and is not counted as shown.
  bool _probing = false;

  @override
  late final ExploreShelves shelves = ExploreShelves(widget.app);

  @override
  void initState() {
    super.initState();
    // Nothing to read before the reader is signed in; the call says so
    // itself, and main asks again once they are.
    Tallies.instance.refresh();
    Served.instance.explore();
    // What was played on the shelves earlier today: the points left, the
    // bets laid, the guesses set.
    ExplorePlay.instance.load();
    _list.addListener(_scrolled);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stay.watch(ScreenPresence.maybeOf(context));
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
        'results': (hits ?? searchPills(asked, home: widget.app.place)).length,
      });
    });
  }

  @override
  void dispose() {
    _stay.dispose();
    _searchSettle?.cancel();
    _field.dispose();
    _focus.dispose();
    _list.dispose();
    shelves.topMonth.dispose();
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
    if (_list.hasClients) _list.jumpTo(0);
  }

  /// A card of today's shelf, tapped on the home screen: the shelves put
  /// back the way the tab opens, and the card opened among the shelf it
  /// came from, exactly as a tap on it here opens it. The widget's shelf
  /// can be a step ahead of this one — it leaves out what was read since
  /// this morning, and a widget that has not heard from the app since
  /// midnight picked its own — so a card that is not on the shelf here
  /// opens first, with the shelf after it.
  void openFromWidget(String pillId) {
    _sight.forgetTouch();
    showBest();
    shelves.begin(subject: _subject);
    final List<Pill> shelf = shelves.today;
    final int at = shelf.indexWhere((p) => p.id == pillId);
    final Pill? card = at >= 0
        ? shelf[at]
        : Served.instance.lastExplore?.today
                  .where((p) => p.id == pillId)
                  .firstOrNull ??
              pillById(pillId);
    if (card == null) return;
    _open(at >= 0 ? shelf : [card, ...shelf], card);
  }

  /// What the shelves put in front of the reader, once per card per shelf
  /// for as long as the tab lives: a card shown and not opened is a thing
  /// the dealer can learn from, the way a feed learns from what you
  /// scrolled past. Only while the reader is looking: the tab is built
  /// beside Today before anyone opens it, and a card on a shelf nobody had
  /// looked at was being counted as passed over.
  final Set<String> _shown = {};

  /// How far down the shelves the reader went, in tenths, said once per
  /// tenth per visit: what a feed calls depth, and the difference between
  /// a reader who found the top list and one who never saw it.
  final Set<int> _depths = {};

  void _scrolled() {
    if (!_list.hasClients) return;
    final ScrollPosition pos = _list.position;
    if (pos.maxScrollExtent <= 0) return;
    final int tenth = (pos.pixels / pos.maxScrollExtent * 10)
        .clamp(0, 10)
        .round();
    if (!_depths.add(tenth)) return;
    Trace.instance.note('explore scrolled', {'depth': tenth * 10});
  }

  /// A card a shelf built, which is a card it showed. [on] is the shelf it
  /// sits on, where that is not the name it is noted under.
  void _seen(String shelf, Pill pill, {String? on}) {
    if (_probing || !_sight.looking) return;
    _sight.tile(on ?? shelf, pill.id);
    if (!_shown.add('$shelf:${pill.id}')) return;
    Trace.instance.note('card shown', {'pill_id': pill.id, 'shelf': shelf});
  }

  // ── What a section may do ─────────────────────────────────────────────

  @override
  AppState get app => widget.app;

  @override
  String get language => Localizations.localeOf(context).languageCode;

  @override
  String? get subject => _subject;

  @override
  List<Pill> cardsFor(ExploreSection section, {int? limit}) =>
      shelves.cardsFor(section, limit: limit);

  @override
  bool isRead(Pill pill) => widget.app.seenIds.contains(pill.id);

  @override
  void open(ExploreSection section, List<Pill> shelf, Pill pill) =>
      _open(shelf, pill);

  @override
  void openDue(ExploreSection section, List<Pill> shelf, Pill pill) =>
      _openDue(shelf, pill);

  @override
  void playStory(
    ExploreSection section,
    List<Pill> shelf,
    Pill pill,
    Rect? from,
  ) => _playStory(shelf, pill, from);

  @override
  Future<void> commit(Pill pill, String response) => _commit(pill, response);

  @override
  Future<void> lean(Pill pill, int side, int confidence) =>
      _lean(pill, side, confidence);

  @override
  void seen(ExploreSection section, Pill pill) => _seen(section.id, pill);

  @override
  void seenAs(ExploreSection section, String shelf, Pill pill) =>
      _seen(shelf, pill, on: section.id);

  /// One shelf, watched for whether it is on screen: noted under its
  /// section's id, the name its cards are noted under, and numbered as the
  /// reader meets it on the page.
  @override
  Widget watch(ExploreSection section, Widget child) => ShelfWatch(
    key: ValueKey('watch-${section.id}'),
    sight: _sight,
    shelf: section.id,
    position: _positions[section.id] ?? 0,
    child: child,
  );

  /// The plans, through the same door every locked thing opens: it says
  /// which door it was, and a reader who has Astute+ already goes nowhere.
  @override
  void openPlans(String from) =>
      requirePlus(context, widget.app, () {}, source: from);

  /// A subject chosen from a section, as its chip at the top chooses it —
  /// the lit one again clears it — and the page taken back to its top,
  /// where the narrowed shelves begin.
  @override
  void openSubject(String subject) {
    final String? next = subject == _subject ? null : subject;
    Analytics.capture('explore filtered', {'subject': next ?? 'all'});
    setState(() => _subject = next);
    if (_list.hasClients) {
      _list.animateTo(
        0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Something done in a section that nothing else records — a reaction, a
  /// bet, a stance — said as one event for every block, named by what the
  /// block calls it.
  @override
  void note(ExploreSection section, String event, Map<String, Object?> facts) =>
      Analytics.capture('explore noted', {
        ...facts,
        'shelf': section.id,
        'block': section.block,
        'noted': event,
      });

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
              // What is opened from the search was not opened from a shelf.
              _sight.forgetTouch();
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
                  // The counts, what the reader has read — a card read here
                  // is marked where it sits as soon as the reader is back on
                  // its shelf — and a newer remote document, whose sections
                  // are drawn the moment it is taken up.
                  listenable: Listenable.merge([
                    Tallies.instance,
                    Served.instance,
                    widget.app,
                    Remote.revision,
                  ]),
                  builder: (context, _) => _sections(context),
                ),
        ),
      ],
    );
  }

  /// The sections, and a fade where they run under the tab bar.
  Widget _sections(BuildContext context) {
    // Every shelf is worked out afresh for this build, and looked at again
    // once laid out: counts arriving can move every one of them.
    shelves.begin(subject: _subject);
    _sight.measureSoon();
    final List<ExploreSlot> slots;
    _probing = true;
    try {
      slots = exploreSlots(
        context,
        this,
        exploreSections(Remote.config),
        widget.app.remoteContext(language),
      );
    } finally {
      _probing = false;
    }
    _positions = {
      for (final ExploreSlot slot in slots)
        if (slot.position case final int position) slot.section.id: position,
    };

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _sight.scrolled,
          child: CustomScrollView(
            controller: _list,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 30),
                sliver: ExploreSliver(host: this, slots: slots),
              ),
            ],
          ),
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

  /// A commitment made on a shelf: the card's answer, recorded the way the
  /// card itself takes one, and the card counted as read, since its answer
  /// is a tap away and the day should never deal it again.
  Future<void> _commit(Pill pill, String response) async {
    Analytics.capture('explore answered', {
      'pill_id': pill.id,
      'right': pill.challenge.accepts(response),
    });
    await widget.app.recordAnswer(pill.id, response);
    await widget.app.markReadElsewhere(pill.id);
  }

  /// The cards that came back open to be answered again, as they do from
  /// the finished day.
  void _openDue(List<Pill> shelf, Pill pill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckViewerScreen(
          app: widget.app,
          deck: shelf,
          title: context.l10n.cameBack,
          initialIndex: shelf.indexOf(pill),
          answering: true,
          source: 'came back',
        ),
      ),
    );
  }

  /// A side leant to on the Pick a side shelf: the card's answer, the side
  /// as the card's own buttons record it and how sure as the card asks it
  /// of a question with a right answer, and the card counted as read, like
  /// any answer given on a shelf.
  Future<void> _lean(Pill pill, int side, int confidence) async {
    Analytics.capture('explore leaned', {
      'pill_id': pill.id,
      'side': side,
      'confidence': confidence,
    });
    await widget.app.recordAnswer(pill.id, '$side', confidence: confidence);
    await widget.app.markReadElsewhere(pill.id);
  }

  Widget _found(BuildContext context) {
    final List<Pill> rows = _query.trim().isEmpty
        ? const []
        : _serverHitsFor == _query.trim() && _serverHits != null
        // What the server found, less a card about a place this reader no
        // longer lives in: the server knows the place their backup holds,
        // and the phone the one they have now.
        ? [
            for (final Pill p in _serverHits!)
              if (reachesReader(p, widget.app.place)) p,
          ]
        : searchPills(_query, home: widget.app.place);
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
            child: CardRow(pill: pill, onTap: () => _open(rows, pill)),
          ),
      ],
    );
  }

  /// A true story, played full screen out of the tile it was opened from.
  /// Opening it is reading the card, as opening a card from any shelf is,
  /// and its last screen opens the card itself, in the story's place.
  void _playStory(List<Pill> shelf, Pill pill, Rect? from) {
    _sight.opened();
    final AppState app = widget.app;
    final String title = _subject ?? context.l10n.tabExplore;
    app.markReadElsewhere(pill.id);
    Navigator.of(context).push(
      StoryRoute(
        builder: (context) => ListenableBuilder(
          listenable: app,
          builder: (context, _) => StoryPlayer(
            pill: pill,
            from: from,
            rank: shelf.indexOf(pill) + 1,
            facts: app.cardFacts(pill.id),
            saved: app.isSaved(pill.id),
            onSave: () => app.toggleSaved(pill.id),
            onShare: () => showShareSheet(context, pill),
            onOpenCard: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => DeckViewerScreen(
                  app: app,
                  deck: [pill],
                  title: title,
                  countsAsRead: true,
                  source: 'story',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(List<Pill> shelf, Pill pill) {
    // Opened from the shelf a finger was last on, which the shelf counts.
    _sight.opened();
    openDeckViewer(
      context,
      widget.app,
      shelf,
      _subject ?? context.l10n.tabExplore,
      initialIndex: shelf.indexOf(pill),
      // Nothing here was dealt: a card read here is read.
      countsAsRead: true,
      source: 'explore',
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
          // A 38 tile in a 44 target, its right edge on the margin.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenSearch,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
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
                  constraints: const BoxConstraints(minWidth: 44),
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
                        subject?.name ?? context.l10n.all,
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
