import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../measure/card_read.dart';
import '../measure/session.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/debug_looks.dart';
import '../theme.dart';
import '../data/skill_levels.dart';
import '../data/why.dart';
import '../listen/listen_sheet.dart';
import '../sync/listen_client.dart';
import '../widgets/sixth_card.dart';
import '../data/pills_repository.dart';
import '../widgets/pill_card_stack.dart';
import '../widgets/premium.dart';
import '../widgets/share_sheet.dart';
import '../widgets/skill_mark.dart';
import '../widgets/skill_score.dart' show todayMoveOf;
import '../sync/invite.dart';
import '../widgets/invite_sheet.dart' show showInviteWeekIfDue;
import '../widgets/level_up.dart' show showLevelUpIfDue;
import '../widgets/streak_moment.dart' show showStreakMomentIfDue;
import '../widgets/today_line.dart';
import '../widgets/day_moment.dart' show showDayMomentIfDue;
import '../widgets/first_day.dart';
import '../widgets/web/card_thumb.dart';
import '../widgets/ui.dart';
import '../widgets/why_sheet.dart';
import '../widgets/learn_looks.dart'
    show goalUnsaid, markedSkills, scoredSkills;
import 'paywall_screen.dart'
    show giftEndMayBeDue, showFirstOfferIfDue, showGiftEndWhenDue;
import 'today_done_view.dart';

/// The card is the screen: dark chrome, and the deck filling everything
/// between the progress bars and the tab bar.
///
/// Two screens live here, and they are deliberately not the same one with a
/// different middle. While the five are unread this is the trainer — "Today"
/// at the top, the bars, the deck, and nothing else to do. Once they are
/// read it becomes the shelf from artboard 66a, which is a place to look
/// back rather than a place to work.
class TodayScreen extends StatefulWidget {
  final AppState app;

  /// Set when this is opened as its own screen off the path, so the way back
  /// sits in the header rather than stacked above it.
  final VoidCallback? onBack;

  /// True while a card is under the finger. The tab bar steps aside for the
  /// gesture: a card being thrown towards the bottom of the screen should
  /// not be thrown at a row of buttons.
  final ValueChanged<bool>? onCardMotion;

  /// True while there is a deck on the table — the five, or the card after
  /// them — and false once the shelf is up. The shell locks the tabs while
  /// it is true, so a throw is never taken for a swipe to the next tab.
  /// The day being finished is not the same thing: the sixth card is on
  /// the table after the fifth is thrown, and it is thrown too.
  final ValueChanged<bool>? onDeckOnTable;

  /// What the shell lends the celebration of a reader's first finished day
  /// (lib/widgets/first_day.dart): the reminder, asked down its own road,
  /// and the way to Today's challenge on Explore. Opened as a screen of its
  /// own, off the path, Today has no shell behind it, and nothing to lend.
  final FirstDayHost firstDay;

  const TodayScreen({
    super.key,
    required this.app,
    this.onBack,
    this.onCardMotion,
    this.onDeckOnTable,
    this.firstDay = FirstDayHost.none,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  /// Whether the day was done at the last build — null before the first,
  /// so opening the app onto a finished day is not mistaken for finishing it.
  bool? _wasDone;

  /// Whether the card after the fifth is still on the table. It is dealt
  /// only when the day is finished *here*, in this session — opening the
  /// app onto a day already done goes straight to the shelf — and only on
  /// the free plan, where there is something to offer: all five cards,
  /// the reader's own. It leaves the way every card leaves: thrown.
  ///
  /// No sheet of scores rises over the finished day. One of every score the
  /// day's cards moved used to, and the owner did not want the day's close
  /// to be a table of numbers: the day closes on its own shelf, and the
  /// scores count up where he goes to see them, in Your journey, from
  /// where he last saw them (lib/screens/journey_screen.dart).
  bool _magic = false;

  /// Whether a level the day's answers reached is still to be told: set
  /// when the day is finished here, in this session, and spent the first
  /// time the shelf is up. The one thing that rises over the finished day,
  /// and only when there is a level to tell.
  bool _levelDue = false;

  /// Whether the day's own moment may rise once the shelf is up, where the
  /// developer tools try it (C, lib/widgets/day_moment.dart): set, like the
  /// level, only when the day is finished here, in this session, so that
  /// opening the app onto a finished day never raises it.
  bool _momentDue = false;

  /// Whether the shelf lands on the day's own card, where the developer
  /// tools try one after the five (D): the evening the day is finished
  /// here, once; on any other opening it starts from the first card.
  bool _landOnDay = false;

  /// Whether the page after the new reader's gift has been looked for on
  /// this day's Today (lib/screens/gift_pages.dart): once a day at most.
  bool _giftEndLooked = false;

  /// True from the moment the reader's first finished day is to be
  /// celebrated (firstDayDue) until the screen that celebrates it has gone:
  /// it rises right after the fifth card, before anything else the
  /// evening has, and the shelf's own moments wait for it.
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    // Where the day is sent from changes the shelf's count and its glow at
    // once, from the debug section, with this Today kept alive beside it;
    // What to learn's look, the mark on a card and the line under its head;
    // the card's foot, whether a card says Why this card on its front
    // (cardNote).
    DebugLooks.shareDay.addListener(_looksChanged);
    DebugLooks.learn.addListener(_looksChanged);
    DebugLooks.cardFoot.addListener(_looksChanged);
  }

  void _looksChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DebugLooks.shareDay.removeListener(_looksChanged);
    DebugLooks.learn.removeListener(_looksChanged);
    DebugLooks.cardFoot.removeListener(_looksChanged);
    super.dispose();
  }

  /// The day whose pictures were last fetched ahead, by its cards.
  String? _warmed;

  /// Fetches the pictures the finished day's shelf will show, once a day,
  /// after the frame: while the reader reads the five, so the shelf has them
  /// the moment it comes up (the owner's phone: a card of its colour, empty,
  /// for two seconds while its picture came).
  void _warmDay(AppState app) {
    final String day = [for (final Pill p in app.todaysDeck) p.id].join(',');
    // A hard card's pictures are the ones taken on the reader's paper.
    final bool dark = context.p.isDark;
    if (day.isEmpty || '$day $dark' == _warmed) return;
    _warmed = '$day $dark';
    final List<Pill> deck = List.of(app.todaysDeck);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => CardThumb.warmDay(deck, dark: dark),
    );
  }

  /// Which of the finished day's cards is at the front of the shelf. Held
  /// here rather than in the shelf because the header's dot and the glow
  /// behind the whole tab take that card's colour.
  int _shelfAt = 0;
  List<Pill>? _shelfDeck;

  /// Finishing the day is the one moment worth marking. Fired after the frame
  /// so the feedback is a side effect of the state, not of painting.
  void _markCompletion(bool completed) {
    final bool? before = _wasDone;
    _wasDone = completed;
    if (before == null || before == completed) return;
    if (!completed) {
      // A new day: the table is a deck again, and nothing is on offer yet.
      _magic = false;
      _momentDue = false;
      _landOnDay = false;
      _giftEndLooked = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
    });
    // The reader's first finished day: celebrated first, on a screen of its
    // own, before the card after the fifth and before anything the shelf
    // has. Raised after this frame, and ahead of the word to the shell that
    // the deck has left the table, so the shell finds the evening already
    // the celebration's.
    if (firstDayDue(widget.app)) {
      _celebrating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }
    // A friend's code taken, its week waiting on this very day: the server
    // is asked now, and the card after the fifth does not offer Astute+ on
    // the evening a week of it is being given.
    final bool inviteWeek = widget.app.inviteOn && Invites.instance.waiting;
    if (inviteWeek) Invites.instance.settle();
    if (!widget.app.isPlus && !inviteWeek) {
      _magic = true;
      // Dealt after the five, it is not dealt again on the shelf today.
      widget.app.noteSixthDealt();
    }
    _levelDue = true;
    _momentDue = true;
    _landOnDay = true;
  }

  /// The celebration of the reader's first finished day, over the card the
  /// fifth left on the table (lib/widgets/first_day.dart). Noted as it
  /// rises, so it rises once whatever happens next. Once it has gone, the
  /// card after the fifth is there to be thrown — or, on Astute+, the shelf
  /// — and the shelf's moments come as on any evening but one: the level.
  Future<void> _celebrate() async {
    if (!mounted) return;
    // Noted before the shell hears the deck has left the table: on this
    // evening the reminder is the celebration's to ask, and the shell's
    // own sheet does not rise for it.
    unawaited(widget.app.notedFirstDayCelebrated());
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(FirstDayScreen.route(widget.app, host: widget.firstDay));
    if (!mounted) return;
    setState(() => _celebrating = false);
  }

  /// Once the shelf has landed, the day at rest: a level its answers
  /// reached rises over it, once (lib/widgets/level_up.dart). Pushed over
  /// the tabs, so the shell's own asks at the finished day (the reminder,
  /// the account, the place) wait for it.
  ///
  /// Where the developer tools try the day's own moment (C), it rises then
  /// instead, if it is due: never on the evening a level rises, which has
  /// that evening and its own way to send (lib/widgets/day_moment.dart).
  ///
  /// The evening the first day was celebrated has had its moment: a week a
  /// friend's code gave still rises, after the celebration and never over
  /// it, since it is given on that very evening; a level reached is not
  /// folded into the celebration but waits for the next calm moment, the
  /// next day finished or Your journey opened; the day's own moment waits
  /// for another evening.
  void _riseLevel() {
    _levelDue = false;
    final bool moment = _momentDue;
    _momentDue = false;
    Future<void>.delayed(const Duration(milliseconds: 650), () async {
      if (!mounted || !widget.app.todayCompleted || _magic) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      // A week a friend's code gave, once this first day is read: the
      // evening is its own (lib/widgets/invite_sheet.dart).
      if (await showInviteWeekIfDue(context, widget.app)) return;
      if (!mounted || widget.app.celebratedToday) return;
      final bool rose = await showLevelUpIfDue(context, widget.app);
      if (rose || !mounted) return;
      // The first week's page or the first month's, when one is due
      // (lib/state/first_offers.dart): a level reached wins the evening.
      if (await showFirstOfferIfDue(context, widget.app)) return;
      // The streak reaching two days, three or seven, small and once
      // (lib/widgets/streak_moment.dart): never on an evening that had
      // its moment already.
      if (!mounted) return;
      if (await showStreakMomentIfDue(context, widget.app)) return;
      if (!moment || !mounted) return;
      await showDayMomentIfDue(context, widget.app);
    });
  }

  /// What the shell was last told about the table.
  bool? _toldOnTable;

  /// Tells the shell whether a deck is on the table, once per change and
  /// after the frame, so it is a side effect of the state and not of
  /// painting.
  void _tellShell(bool onTable) {
    if (onTable == _toldOnTable) return;
    _toldOnTable = onTable;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDeckOnTable?.call(onTable);
    });
  }

  /// How the card just thrown was read, until the day moves past it.
  CardStint? _thrown;

  /// The first of the day's own cards, on a Sunday that has one more of
  /// them than other days; null on any other day.
  static String? _sundaysOwn(AppState app) {
    if (!app.sundayExtraToday) return null;
    for (final Pill p in app.todaysDeck) {
      if (app.ownIdsToday.contains(p.id)) return p.id;
    }
    return null;
  }

  /// The card after the fifth, thrown.
  void _throwMagic() {
    if (!mounted || !_magic) return;
    setState(() => _magic = false);
  }

  /// The offer: the paywall. Coming back without the trial, the card is
  /// still on the table, to be thrown like any other; with it, tomorrow's
  /// five are all the reader's own, and the card says so.
  Future<void> _offer(BuildContext context) =>
      requirePlus(context, widget.app, () {}, source: 'sixth card');

  /// Less like this — said once, quietly, with the way back.
  void _dislike(BuildContext context, Pill pill) {
    final app = widget.app;
    app.dislike(pill.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        // A snack bar with an action stays until it is dismissed, unless
        // it is told otherwise: this one goes by itself, as it always did.
        persist: false,
        content: Text(context.l10n.lessLikeThis),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => app.undislike(pill.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final bool done = app.todayCompleted;
    _markCompletion(done);
    _warmDay(app);
    // The morning after the new reader's gift, before the five: what its
    // days came to and what goes back to free, once.
    if (!_giftEndLooked && giftEndMayBeDue(app)) {
      _giftEndLooked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showGiftEndWhenDue(context, app);
      });
    }
    // Bought from the card itself: the offer has nothing left to offer and
    // leaves the table, so the shelf comes up. It used to stay "on the
    // table" with no card on it — the deck drops the card after the fifth
    // on Astute+ — and Today was a blank page for the reader who had just
    // paid.
    if (_magic && app.isPlus) _magic = false;

    // The sixth card keeps the deck on the table after the fifth is gone:
    // the shelf comes up when it, too, has been thrown.
    final bool onTable = !done || _magic;
    _tellShell(onTable);
    // Not while the first day's celebration is up: what rises over the
    // shelf rises once it has gone.
    if (!onTable && _levelDue && !_celebrating) _riseLevel();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      child: onTable
          ? _reading(context, key: const ValueKey('deck'))
          : _shelf(context, key: const ValueKey('shelf')),
    );
  }

  /// Why each of the day's cards is here (lib/data/why.dart), by id: the
  /// line each says under its head, and the sheet the line opens.
  Map<String, CardWhy> _whys(AppState app) {
    final String? sunday = _sundaysOwn(app);
    return {
      for (final Pill p in app.todaysDeck)
        p.id: whyOf(app, p, sunday: p.id == sunday),
    };
  }

  /// The day, being read. Unchanged from the screen this app has always
  /// opened on: the word Today, the streak beside it, the bars, the deck.
  Widget _reading(BuildContext context, {required Key key}) {
    final app = widget.app;
    final Map<String, CardWhy> whys = _whys(app);
    return Padding(
      key: key,
      // The sides come from the deck's own constant, so Today and the
      // re-read cannot drift apart again.
      padding: const EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<bool>(
            // The server's word that it has no key takes Listen away at
            // once (lib/listen/listen_sheet.dart).
            valueListenable: ListenClient.unconfigured,
            builder: (context, _, _) => _ReadingHeader(
              streak: app.liveStreak,
              frozen: app.streakWasFrozen,
              onBack: widget.onBack,
              // Said beside the day's name — the one place on the screen
              // with room to spare on a first morning, which has no streak
              // to show there — so the deck below never moves to make room
              // for it. From the first card's arrival: said only once the
              // card had leaned, seconds after its back, it came late, and
              // never on a drawn card, whose back is its own and never tells
              // the deck it came round.
              hint: app.pillsRead == 0 ? context.l10n.swipeForTheNextOne : null,
              // The day's five read aloud, quietly at the end of the same
              // row, near the cards and costing the deck nothing; the swipe
              // hint has the place on the one morning it is said.
              onListen: listenOffered(app)
                  ? () => showListenSheet(context, app)
                  : null,
            ),
          ),
          // What the morning has to say before its first card: the day
          // missed that a freeze covered, or, on a new reader's second
          // and third days, how the day before went and what is new
          // (lib/widgets/today_line.dart). All day, so the deck below
          // keeps one size.
          if (todayLineOf(context, app) case (
            lead: final String? lead,
            text: final String text,
          )) ...[
            const SizedBox(height: 10),
            TodayLine(lead: lead, text: text),
          ],
          const SizedBox(height: 16),
          _ProgressBars(total: app.todaysDeck.length, index: app.todayIndex),
          const SizedBox(height: 16),
          // The deck takes every pixel that is left.
          Expanded(
            child: PillCardStack(
              deck: app.todaysDeck,
              index: app.todayIndex,
              // After the last pill, on the free plan, the card that offers
              // the whole day: one true thing about the reader's own day,
              // and what Astute+ would have done with it
              // (lib/widgets/sixth_card.dart). It is thrown like the rest,
              // and it says where the reader's week has got to.
              trailing: app.isPlus
                  ? null
                  : SixthCard(
                      key: const ValueKey('magic-card'),
                      app: app,
                      onAction: () => _offer(context),
                    ),
              // How each card was read: a card thrown on is said with the
              // day moving on past it ('card advanced'); one left standing
              // for another tab or the background is said as it is left.
              onRead: (stint) {
                if (stint.thrown) {
                  _thrown = stint;
                } else {
                  app.cardClosed(stint, where: 'today');
                }
              },
              // The first card of a start standing on screen: how long the
              // reader waited for it.
              onStand: (_) => FirstCard.shown(app.firstCardFacts),
              onAdvance: () {
                final CardStint? thrown = _thrown;
                _thrown = null;
                if (app.todayIndex >= app.todaysDeck.length) {
                  _throwMagic();
                  return null;
                }
                return app.advance(read: thrown?.facts ?? const {});
              },
              isSaved: app.isSaved,
              onSave: (pill) => app.toggleSaved(pill.id),
              isLiked: app.isLiked,
              onLike: (pill) => app.toggleLiked(pill.id),
              onDislike: (pill) => _dislike(context, pill),
              onShare: (pill) => showShareSheet(context, pill),
              onMotion: widget.onCardMotion,
              // The card about where the reader lives says so on its front.
              home: app.place,
              // Beside the words in the header, the first card shows how card
              // two is reached, once, to a reader who has never sent a card on.
              swipeHint: app.pillsRead == 0,
              reviewIds: app.reviewIdsToday,
              // Which cards are the reader's own, on the day that has
              // others: Astute+ has no others to tell them from.
              ownIds: app.isPlus ? const {} : app.ownIdsToday,
              // Every card says why it is here under its head, where a
              // card about a place says so: the move it trains and the
              // reader keeps missing, their goal, their level, the one more
              // of their own on their Sunday, or chance. A tap on the line
              // opens what the deal knew, and more or less like it.
              // One word for one thing: a card for the reader's goal that
              // carries the mark of a skill they picked says so by the mark
              // alone, not by the mark and a line saying it again.
              // Most cards have no line now; every one reaches the sheet all
              // the same, from its back's foot or, with the foot being tried
              // that says it on the front, from a line there (cardNote).
              notes: {
                for (final MapEntry<String, CardWhy> e in whys.entries)
                  if (cardNote(
                        context.l10n,
                        e.value,
                        marked: goalUnsaid(
                          app,
                          marked:
                              skillMarkOf(e.value.pill, markedSkills(app)) !=
                              null,
                        ),
                      )
                      case (final String line, _))
                    e.key: line,
              },
              noteIcons: {
                for (final MapEntry<String, CardWhy> e in whys.entries)
                  e.key:
                      cardNote(
                        context.l10n,
                        e.value,
                        marked: goalUnsaid(
                          app,
                          marked:
                              skillMarkOf(e.value.pill, markedSkills(app)) !=
                              null,
                        ),
                      )?.$2 ??
                      whyIcon(e.value.kind),
              },
              onNote: (pill) => showWhySheet(
                context,
                app,
                pill,
                sunday: pill.id == _sundaysOwn(app),
              ),
              // A card that trains a skill the reader put in focus carries
              // its small mark beside the heart; a tap says what it means.
              skillOf: (pill) => skillMarkOf(pill, markedSkills(app)),
              // The score the answer moved, beside its verdict.
              moveOf: (pill) =>
                  todayMoveOf(app, pill, skillMarkOf(pill, scoredSkills(app))),
              onSkill: (pill, skill) =>
                  showSkillMarkSheet(context, app, skill, cardId: pill.id),
              answerFor: app.answerFor,
              onAnswer: (id, response, confidence, reason) => app.recordAnswer(
                id,
                response,
                confidence: confidence,
                reason: reason,
              ),
              onReact: app.react,
            ),
          ),
        ],
      ),
    );
  }

  /// The day, done — artboard 66a, down to its margins.
  Widget _shelf(BuildContext context, {required Key key}) {
    final app = widget.app;
    final deck = app.todaysDeck;
    if (deck.isEmpty) return SizedBox.shrink(key: key);

    // A new deck — the next day, or the second set dealt — starts the shelf
    // from its first card.
    if (!identical(_shelfDeck, deck)) {
      _shelfDeck = deck;
      _shelfAt = 0;
    }
    // Where the day is a card of its own after the five (D), the evening it
    // is finished here the shelf lands on that card, once.
    if (_landOnDay) {
      _landOnDay = false;
      if (TodayDoneView.dayCardOn) _shelfAt = deck.length;
    }
    // On the free plan the shelf ends on the card that offers the rest of
    // the day; that card has no subject, so the tab takes the spectrum's
    // violet behind it rather than the last card's colour. The day's own
    // card, where there is one, takes the colour of the card its picture
    // sets large.
    final int count = TodayDoneView.countOf(app);
    final int at = _shelfAt.clamp(0, count - 1);
    final Color colour = TodayDoneView.glowOf(app, at);

    return Stack(
      key: key,
      children: [
        Positioned.fill(child: _Glow(colour: colour)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TodayDoneView(
                app: app,
                at: at,
                onPick: (k) => setState(() => _shelfAt = k),
                // Which day this is, on the shelf's own first row: that
                // the five were read is what the shelf under it shows.
                heading: (
                  line: context.l10n.dayTitle(app.dayNumber),
                  aside: _shelfAside(context, app),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The header while the day is being read.
/// Today before its day has come: the same screen in the same places, the
/// word Today and the bars, with the deck in grey where the cards will
/// stand. The app opens on it at once, as a feed opens on the outline of its
/// posts, and the day lands in the room it kept.
class TodaySkeleton extends StatelessWidget {
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // The padding, the header and the gaps of [_TodayScreenState._reading].
    return const Padding(
      padding: EdgeInsets.fromLTRB(kDeckMargin, 10, kDeckMargin, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadingHeader(streak: 0),
          SizedBox(height: 16),
          // None lit yet: nothing of the day has been read, and the first
          // lights as its card lands.
          _ProgressBars(total: kPillsPerDay, index: -1),
          SizedBox(height: 16),
          Expanded(child: DeckSkeleton()),
        ],
      ),
    );
  }
}

class _ReadingHeader extends StatelessWidget {
  final int streak;
  final bool frozen;
  final VoidCallback? onBack;

  /// How the card is sent on, once, at the far end of the row.
  final String? hint;

  /// Opens Listen, from its entry at the far end of the row; null where
  /// Listen is not offered.
  final VoidCallback? onListen;
  const _ReadingHeader({
    required this.streak,
    this.frozen = false,
    this.onBack,
    this.hint,
    this.onListen,
  });

  @override
  Widget build(BuildContext context) {
    // A long date and a streak badge do not both fit on a narrow handset.
    // The date gives way by a point or two rather than being clipped, or
    // overflowing, which is what it did.
    final Widget title = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        context.l10n.tabToday,
        maxLines: 1,
        style: AppText.display(
          size: 20,
          weight: FontWeight.w600,
          spacing: -0.4,
          color: context.p.ink,
        ),
      ),
    );
    // Nothing until there is something. A badge reading "0 days" on the
    // morning somebody installs the app is a worse first impression than no
    // badge at all.
    final Widget? badge = streak <= 0
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: frozen
                  ? context.p.link.withValues(alpha: 0.22)
                  : context.p.line,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: frozen ? context.p.link : context.p.inverse,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.streakDays(streak),
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: context.p.ink,
                  ),
                ),
              ],
            ),
          );
    final List<Widget> back = [
      if (onBack != null) ...[
        BackCircle(onPressed: onBack!),
        const SizedBox(width: 12),
      ],
    ];
    // Listen, at the far end of the row: the day's name and its badge as
    // wide as they are (at most three fifths of the row, past which the name
    // gives way), and everything after them the entry's, which says all its
    // words where they fit and one where they do not.
    if (hint == null && onListen != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              ...back,
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: title),
                    const SizedBox(width: 10),
                    ?badge,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ListenEntry(onPressed: onListen!),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          ...back,
          Flexible(flex: 2, child: title),
          const SizedBox(width: 10),
          ?badge,
          if (hint != null) ...[
            const SizedBox(width: 12),
            // Three parts of the row's room to the day's name's two: the
            // name keeps its size in every language, and the hint, which
            // gives way, rarely has to.
            Expanded(
              flex: 3,
              child: SizedBox(
                // While Listen is offered the row keeps its entry's height,
                // so the hint taking its place moves nothing below.
                height: onListen == null ? null : ListenEntry.height,
                child: _SwipeHint(text: hint!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// How a card is sent on, said once: a hand's mark and a few words, quiet,
/// flush to the far end of the header, in the muted ink a line meant to be
/// read takes (the faint one was missed). It comes in with the first card
/// and goes as the first card does. One line, given way by a point or two
/// rather than wrapped, so the header never grows under it.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Color ink = context.p.inkMuted;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('swipe-hint'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: still ? 0 : 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(10 * (1 - t), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(Icons.swipe_left_rounded, size: 16, color: ink),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                maxLines: 1,
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The header once the day is done: a dot in the front card's colour, which
/// day this was, and at the far end what was kept. One line, because the
/// screen under it is the subject and a header should say where you are
/// rather than take a third of the room saying it.
/// Two pools of the front card's colour thrown on the ground, one high
/// behind the card and a fainter one low behind the controls — the
/// artboard's two blurred circles, at its positions but at a third of its
/// strength. At the canvas's 30% and 16% the page reads as a coloured
/// filter laid over the app; at nothing at all the card lights a room that
/// does not answer. This is the room answering quietly. The colour crosses
/// over when the front card changes rather than snapping.
class _Glow extends StatelessWidget {
  const _Glow({required this.colour});

  final Color colour;

  /// Where the artboard puts them, less the 56 points of status bar its
  /// frame draws above the page.
  static const double _statusBar = 56;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: still ? 0 : 550);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: w / 2 - 320,
                top: 150 - _statusBar,
                child: _Pool(
                  colour: colour,
                  strength: 0.12,
                  size: 640,
                  duration: duration,
                ),
              ),
              Positioned(
                left: w / 2 - 260,
                top: 420 - _statusBar,
                child: _Pool(
                  colour: colour,
                  strength: 0.06,
                  size: 520,
                  height: 420,
                  duration: duration,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pool extends StatelessWidget {
  const _Pool({
    required this.colour,
    required this.strength,
    required this.size,
    required this.duration,
    this.height,
  });

  final Color colour;
  final double strength;
  final double size;
  final double? height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // The canvas draws a hard-edged circle and blurs it by 130. A blur
        // that wide is a Gaussian, so the same shape is cheaper as a
        // gradient: most of the colour in the middle third, and gone well
        // before the edge.
        gradient: RadialGradient(
          colors: [
            colour.withValues(alpha: strength),
            colour.withValues(alpha: strength * 0.72),
            colour.withValues(alpha: strength * 0.30),
            colour.withValues(alpha: strength * 0.08),
            colour.withValues(alpha: 0),
          ],
          stops: const [0, 0.28, 0.55, 0.78, 1],
        ),
      ),
    );
  }
}

/// The small line under the finished day's, which is where the streak is
/// shown: the freeze, first on the day it was spent. Then, where the streak
/// is told (`streak.told`) and there is a streak of two days or more to
/// keep, that a missed day is covered and how many freezes the reader
/// holds: first in the first week, when the reader is learning the app,
/// and after the gesture that likes a card later on. That gesture is said
/// until the reader has liked a card, the first evening's line: from then
/// on a liked card says so itself with the heart in its corner.
String? _shelfAside(BuildContext context, AppState app) {
  if (app.streakWasFrozen) return context.l10n.freezeKeptStreak;
  // The new reader's gift, in its last two days: the one quiet line that
  // says it is ending (lib/state/gift.dart).
  if (app.giftDaysLeft case final int left) {
    return context.l10n.giftEndsSoon(left);
  }
  final String? covered =
      app.streakToldOn && app.liveStreak > 1 && app.freezes > 0
      ? context.l10n.freezeCoversLine(app.freezes)
      : null;
  if (covered != null && app.completedDates.length <= 7) return covered;
  if (app.likedIds.isEmpty) return context.l10n.holdACardYouLike;
  return covered;
}

class _ProgressBars extends StatelessWidget {
  final int total;
  final int index;
  const _ProgressBars({required this.total, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The bars are the only thing that says where in the day you are, now
      // that the card has stopped repeating it. The key names what they
      // draw, so it can be read without a caption existing for its own sake.
      key: ValueKey('progress-${index + 1}-of-$total'),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: List.generate(total, (i) {
          final filled = i <= index;
          return Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 260 + i * 40),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
              height: 3,
              decoration: BoxDecoration(
                color: filled ? context.p.ink : context.p.line,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          );
        }),
      ),
    );
  }
}
