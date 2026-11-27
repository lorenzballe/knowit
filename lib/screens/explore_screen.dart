import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

import '../data/card_pages.dart';
import '../data/local_cards.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart' show inkOn, kThinkingWhite;
import '../data/video_cards.dart';
import '../explore/blocks/bets/bet_host.dart';
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
import '../widgets/explore/search_start.dart';
import '../widgets/explore/section_page.dart';
import '../widgets/explore/story_player.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/subject_icon.dart';
import 'area_screen.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart';
import '../analytics.dart';
import '../measure/screens.dart';
import '../measure/shelves.dart';
import '../widgets/hand_glass.dart';
import '../widgets/top_edge.dart';
import '../widgets/video_card.dart' show openVideoCard, videoHeroTag;

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

  /// Takes the reader to the Today tab: the streak by the title, and the
  /// panel of the day at the top of the page, send a tap there.
  final VoidCallback? onToday;

  const ExploreScreen({super.key, required this.app, this.onToday});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

/// The Explore screen, and the host every section on it is drawn for.
class ExploreScreenState extends State<ExploreScreen>
    implements ExploreShelfHost, BetHost {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _list = ScrollController();

  /// The subject's display name, or null for all of them.
  String? _subject;

  /// Whether the head has gone all the way up, the cards running under the
  /// status bar: the soft edge there then reaches a little below it, as it
  /// cannot while the subjects' row is in view, which it would blur.

  bool _searching = false;
  String _query = '';

  /// A kind of card picked under the empty search field: its cards are
  /// listed until something is typed or the kind is let go.
  CardKind? _kind;

  /// Each scroll of the shelves, for the shelves watched on screen. The
  /// head is the list's first row: it goes up with the cards and is there
  /// again only at the top, where a tap on Explore's tab brings the list
  /// back ([toTop]).
  bool _headFollows(ScrollNotification n) => _sight.scrolled(n);

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

  /// Explore read again from the server, whatever its age: the pull at
  /// the top of the page.
  Future<void> _reload() async {
    // The tick a pull-to-refresh lands with, as a feed's does: the pull was
    // far enough, and the page is coming again.
    HapticFeedback.mediumImpact();
    final Set<String> shownBefore = {
      for (final String s in _shown) s.substring(s.indexOf(':') + 1),
    };
    await Future.wait([
      Served.instance.explore(force: true),
      Tallies.instance.refresh(force: true),
    ]);
    if (!mounted) return;
    // A new round: the shelves that turn with the day turn again, and the
    // feed is laid in another order, what was read left out.
    shelves.nextRound();
    final int fresh = _freshInFeed(shownBefore);
    Analytics.capture('explore refreshed', {
      'round': shelves.round,
      'fresh': fresh,
    });
    setState(() {});
    // New cards are seen at the top: they need no line saying so (the
    // owner). Only a pull that brings nothing new is told, or it would look
    // as if it had not worked.
    if (fresh > 0) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('explore-fresh'),
          content: Text(context.l10n.exploreUpToDate),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// How many of the first cards the feed now lays were not on screen
  /// before the pull: what the reader will find new at the top of it. Said,
  /// not invented: a reader who has seen them all is told so.
  int _freshInFeed(Set<String> shownBefore) {
    final ExploreSection? feed = exploreSections(Remote.config)
        .where((s) => s.block == 'feed')
        .firstOrNull;
    if (feed == null) return 0;
    shelves.begin(subject: _subject, language: language);
    return shelves
        .cardsFor(feed)
        .where((p) => !isRead(p) && reachesReader(p, widget.app.place))
        .take(12)
        .where((p) => !shownBefore.contains(p.id))
        .length;
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
    setState(() {
      _query = q;
      if (q.trim().isNotEmpty) _kind = null;
    });
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

  /// Back to the top of the shelves, where the head is: Explore's tab
  /// tapped again, as an app's tab does on iOS.
  void toTop() {
    if (!_list.hasClients || _list.offset <= 0) return;
    _list.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
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
      _kind = null;
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
    shelves.begin(subject: _subject, language: language);
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
    // A free card on a shelf has its page fetched the first time its tile
    // is in sight, so the card opens whole, as a deck's next card does.
    if (pill.hasPage) CardPages.instance.warm([pill]);
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

  /// A card opened from a shelf; a film played out of its tile on the
  /// shelf it was tapped on.
  @override
  void open(ExploreSection section, List<Pill> shelf, Pill pill) {
    final VideoCard? film = videoCardOf(pill);
    if (film != null) {
      _playFilm(film, pill, from: videoHeroTag(film, section.id));
      return;
    }
    _open(shelf, pill);
  }

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

  /// A bet laid on a shelf, with how sure the reader said they were: the
  /// card's answer, recorded as the card records one with its step of how
  /// sure, so a bet counts towards how sure against how right.
  @override
  Future<void> commitSure(Pill pill, String response, int confidence) =>
      _commit(pill, response, confidence: confidence);

  /// A card's answer shown on a shelf without being given — two figures
  /// compared, a number closed in on — is read: the day must never deal it
  /// with its answer already known.
  @override
  void revealed(ExploreSection section, Pill pill) =>
      widget.app.markReadElsewhere(pill.id);

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

  /// The Today tab, from the panel of the day or the streak by the title.
  @override
  void openToday() {
    Analytics.capture('explore today opened');
    widget.onToday?.call();
  }

  /// A section on a page of its own, drawn for this same host: a game from
  /// the quick games, opened from the shelf a finger was last on.
  @override
  void openSection(ExploreSection section) {
    _sight.opened();
    Analytics.capture('explore section opened', {
      'shelf': section.id,
      'block': section.block,
    });
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExploreSectionPage(host: this, section: section),
      ),
    );
  }

  /// A screen a section draws for itself — Sixty seconds on the whole
  /// screen, out of its tile — counted and said as a page a section opens
  /// is, under the same names, so the numbers of the two stay one series.
  @override
  void openScreen(ExploreSection section, Route<void> route) {
    _sight.opened();
    Analytics.capture('explore section opened', {
      'shelf': section.id,
      'block': section.block,
    });
    Navigator.of(context).push(route);
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
    // The status bar's room, at least 12 where there is none (a browser).
    // The head stands in it at the top of the shelves; scrolled down, it
    // goes up with the cards, and they run on under the time and the
    // battery to the top of the screen, as Instagram's Explore does.
    final double top = math.max(MediaQuery.paddingOf(context).top, 12);
    if (_searching) {
      // Searching, the head stays: the field is what the reader is using.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: top),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _Head(
              field: _field,
              focus: _focus,
              onCloseSearch: () {
                Analytics.capture('explore search closed', {
                  'had_query': _query.trim().isNotEmpty,
                });
                _field.clear();
                setState(() {
                  _searching = false;
                  _query = '';
                  _kind = null;
                });
              },
              onChanged: _typed,
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _found(context),
            ),
          ),
        ],
      );
    }
    return ListenableBuilder(
      // The counts, what the reader has read — a card read here is marked
      // where it sits as soon as the reader is back on its shelf — and a
      // newer remote document, whose sections are drawn the moment it is
      // taken up.
      listenable: Listenable.merge([
        Tallies.instance,
        Served.instance,
        widget.app,
        Remote.revision,
      ]),
      builder: (context, _) => _sections(
        context,
        top: top,
        // One row, as Instagram's Explore is: the lens that opens the
        // search, then the subjects. The tab says where this is; a title
        // said it again.
        head: _SubjectRow(
          selected: _subject,
          onSearch: () {
            Analytics.capture('explore search opened');
            // What is opened from the search was not opened from a shelf.
            _sight.forgetTouch();
            setState(() => _searching = true);
            _focus.requestFocus();
          },
          // A subject, All, or the lit subject again — the last two both
          // clear it, so the way back is whichever the finger finds first.
          onPick: (name) {
            final String? next = name == _subject ? null : name;
            Analytics.capture('explore filtered', {'subject': next ?? 'all'});
            setState(() => _subject = next);
          },
        ),
      ),
    );
  }

  /// The sections under their [head], a fade where they run under the tab
  /// bar, and one under the status bar, [top] tall, where they run under the
  /// time and the battery, so both are read over a card as over the page.
  Widget _sections(
    BuildContext context, {
    required double top,
    required Widget head,
  }) {
    // Every shelf is worked out afresh for this build, and looked at again
    // once laid out: counts arriving can move every one of them.
    shelves.begin(subject: _subject, language: language);
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
          onNotification: _headFollows,
          // Pulled down from its top, Explore is read again from the
          // server, as a feed is: the shelves the server assembled since,
          // and the tallies under them.
          child: RefreshIndicator(
            key: const ValueKey('explore-refresh'),
            color: context.p.ink,
            backgroundColor: context.p.surfaceRaised,
            onRefresh: _reload,
            // Below the status bar, where the head stands.
            edgeOffset: top,
            child: CustomScrollView(
              controller: _list,
              // Always pullable, however short the page.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ColoredBox(
                    key: const ValueKey('explore-head'),
                    color: context.p.surface,
                    child: Padding(
                      padding: EdgeInsets.only(top: top),
                      child: SizedBox(height: _headRow, child: head),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom:
                        30 +
                        (barGlass ? MediaQuery.paddingOf(context).bottom : 0),
                  ),
                  sliver: ExploreSliver(host: this, slots: slots),
                ),
              ],
            ),
          ),
        ),
        // The shelves run under the tab bar rather than stopping short of
        // it, so the last one has to say it is not the end: under a solid
        // bar. Under glass they show through it, and say it themselves.
        if (!barGlass)
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
        // Under the status bar, where the cards run under the time and the
        // battery: they go soft and dissolve into the page towards the top
        // of the screen, strongest at its edge, as a list under a bar is
        // drawn on iOS 26. Exactly the status bar's room and no more: it
        // never reaches over the row of subjects or the cards below the
        // bar's line. Over the head, which is the page's colour, it is not
        // seen.
        Positioned(
          key: const ValueKey('explore-top-edge'),
          left: 0,
          right: 0,
          top: 0,
          height: top,
          child: IgnorePointer(child: TopEdge(ground: context.p.surface)),
        ),
      ],
    );
  }

  /// A commitment made on a shelf: the card's answer, recorded the way the
  /// card itself takes one, and the card counted as read, since its answer
  /// is a tap away and the day should never deal it again.
  Future<void> _commit(Pill pill, String response, {int? confidence}) async {
    // A side taken on a debate is a lean on whichever shelf it was taken,
    // two buttons or a slider: nothing about it is right or wrong.
    if (pill.challenge is TakeASide) {
      Analytics.capture('explore leaned', {
        'pill_id': pill.id,
        'side': int.tryParse(response) ?? response,
        'confidence': ?confidence,
      });
    } else {
      Analytics.capture('explore answered', {
        'pill_id': pill.id,
        'right': ?(pill.challenge.isGraded
            ? pill.challenge.accepts(response)
            : null),
        'confidence': ?confidence,
      });
    }
    await widget.app.recordAnswer(pill.id, response, confidence: confidence);
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
      if (_kind case final CardKind kind) return _ofKind(context, kind);
      // Before anything is typed: words to try, the areas by need, and
      // the cards by kind (prototype A7).
      return SearchStart(
        day: widget.app.today,
        onTry: (word) {
          Analytics.capture('explore search tried', {'word': word});
          _field.value = TextEditingValue(
            text: word,
            selection: TextSelection.collapsed(offset: word.length),
          );
          _typed(word);
        },
        onArea: (area) =>
            AreaScreen.open(context, widget.app, area, from: 'search'),
        onKind: (kind) {
          Analytics.capture('explore search kind', {'kind': kind.name});
          _focus.unfocus();
          setState(() => _kind = kind);
        },
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

  /// The cards of [kind], under the empty search field: unread first, with
  /// the kind's name, how many, and the way back to the start.
  Widget _ofKind(BuildContext context, CardKind kind) {
    final l = context.l10n;
    final Palette p = context.p;
    final List<Pill> rows = cardsOfKind(
      kind,
      day: widget.app.today,
      home: widget.app.place,
      read: widget.app.seenIds,
    );
    return ListView(
      key: ValueKey('search-kind-list-${kind.name}'),
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kindName(l, kind),
                style: AppText.display(
                  size: 22,
                  weight: FontWeight.w600,
                  spacing: -0.5,
                  color: p.ink,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('search-kind-clear'),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => setState(() => _kind = null),
              icon: Icon(Icons.close_rounded, color: p.inkMuted),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l.kindCards(rows.length),
            style: AppText.body(size: 12, color: p.ink.withValues(alpha: 0.42)),
          ),
        ),
        for (final Pill pill in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: CardRow(
              pill: pill,
              read: widget.app.seenIds.contains(pill.id),
              onTap: () => _open(rows, pill),
            ),
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

  /// A video card, played on the whole screen: out of its tile where the
  /// tile is one a film grows from ([from], videoHeroTag), as it always
  /// was. Watching it is reading the card, as opening a card from any shelf
  /// is: its tile is ticked, and the feed deals it no more.
  void _playFilm(VideoCard film, Pill pill, {Object? from}) {
    _sight.opened();
    widget.app.markReadElsewhere(pill.id);
    openVideoCard(context, film, language: language, heroTag: from);
  }

  void _open(List<Pill> shelf, Pill pill) {
    final VideoCard? film = videoCardOf(pill);
    if (film != null) {
      _playFilm(film, pill);
      return;
    }
    // Opened from the shelf a finger was last on, which the shelf counts.
    _sight.opened();
    // A film among the cards is played from its tile, never swiped to as
    // a card with nothing on it.
    final List<Pill> cards = [
      for (final Pill p in shelf)
        if (videoCardOf(p) == null) p,
    ];
    openDeckViewer(
      context,
      widget.app,
      cards,
      _subject ?? context.l10n.tabExplore,
      initialIndex: cards.indexOf(pill),
      // Nothing here was dealt: a card read here is read.
      countsAsRead: true,
      source: 'explore',
    );
  }
}

/// The search, open: the field over every card, and the way out of it.
class _Head extends StatelessWidget {
  const _Head({
    required this.field,
    required this.focus,
    required this.onCloseSearch,
    required this.onChanged,
  });

  final TextEditingController field;
  final FocusNode focus;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: context.p.ink.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(19),
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
}

/// How tall the row of the lens and the subjects is.
const double _headRow = 50;

/// Every subject, across the top, narrowing every shelf at once.
///
/// The mark keeps the subject's colour even when the chip is not chosen,
/// which is what makes the row readable as a palette rather than as a row
/// of grey pills.
class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.selected,
    required this.onPick,
    required this.onSearch,
  });

  final String? selected;

  /// The lens at the head of the row: the search over every card.
  final VoidCallback onSearch;

  /// Null clears the filter — the "All" at the head of the row.
  final ValueChanged<String?> onPick;

  /// The row's subjects: Thinking first, then the mix's. Thinking is no
  /// subject of the mix, which can never turn it off, but more than half
  /// the deck is its cards, and a reader looking for them has a chip for
  /// them like any subject's. Its card is white, so its chip is lit in the
  /// page's inverse and its mark is drawn in the ink.
  static const List<MixSubject> subjects = [
    MixSubject('thinking', 'Thinking', kThinkingWhite),
    ...kMixSubjects,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // "All" first, so the way back to everything is a chip and not
        // the knowledge that tapping the lit one again clears it.
        itemCount: subjects.length + 2,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          if (i == 0) return _Lens(onTap: onSearch);
          i -= 1;
          final MixSubject? subject = i == 0 ? null : subjects[i - 1];
          final bool on = subject == null
              ? selected == null
              : selected == subject.name;
          // Thinking's white would vanish on paper: lit, it takes the
          // page's inverse, and its mark the ink.
          final bool white = subject?.key == 'thinking';
          final Color lit = subject == null || white
              ? context.p.inverse
              : subject.color;
          final Color ink = subject == null
              ? (on ? context.p.onInverse : context.p.ink)
              : (on ? inkOn(lit) : context.p.ink);
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
                    color: on ? lit : context.p.ink.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subject != null) ...[
                        SubjectIcon(
                          subject: subject.name,
                          size: 14,
                          ink: on
                              ? ink
                              : (white ? context.p.ink : subject.color),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        // In the reader's language: the name is the key,
                        // never the label.
                        subject == null
                            ? context.l10n.all
                            : context.l10n.subjectOf(subject.name),
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

/// The lens at the head of the subjects' row: the search over every card,
/// drawn as a chip of the row, the same height, corners and ground, and set
/// at the top of the row as the chips are, so the row reads as one line.
class _Lens extends StatelessWidget {
  const _Lens({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('explore-search'),
      button: true,
      label: context.l10n.searchEveryCard,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 44,
            height: 36,
            decoration: BoxDecoration(
              color: context.p.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.search_rounded,
              size: 18,
              color: context.p.ink.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
