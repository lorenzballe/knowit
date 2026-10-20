/// The shelves Explore had before it came from the server, each a block of
/// its own name, drawn and behaving exactly as the screen drew them: today's
/// shelf, the top list, loved since the start, a question from every
/// subject, the reader's own, where they live, and the mix under them — the
/// month, numbers, a side to pick, the sharpest, origins, true stories, true
/// or false, what came back, the two moves, working it out, a chart
/// unmasked, how sure, what if, a few cards, sixty seconds, your minutes,
/// did you know, surprise me and something to use before tonight. Two lines
/// that are not shelves come with them: nothing here yet, and offline.
///
/// What each holds is the shelves' own reckoning ([ExploreShelves]); a
/// section can give any of them its own `title` and `subtitle`.
library;

import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/explore_mix.dart';
import '../../../data/themed_shelves.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../widgets/explore/card_tiles.dart';
import '../../../widgets/explore/did_you_know.dart';
import '../../../widgets/explore/first_shelves.dart';
import '../../../widgets/explore/form_shelves.dart';
import '../../../widgets/explore/month_shelf.dart';
import '../../../widgets/explore/mood_minutes.dart';
import '../../../widgets/explore/series_shelf.dart';
import '../../../widgets/explore/sixty_seconds.dart';
import '../../../widgets/explore/spot_the_false.dart';
import '../../../widgets/explore/surprise_me.dart';
import '../../../widgets/explore/unmask_chart.dart';
import '../../../widgets/explore/where_you_live.dart';
import '../../../widgets/explore/work_it_out.dart';
import '../../../widgets/place_ask.dart';
import '../../../widgets/signature_shelves.dart';
import '../../explore_block.dart';
import 'layout.dart';
import 'shelves.dart';

/// The shelves' blocks, in the order Explore always showed them.
const List<ExploreBlock> shelfBlocks = [
  NothingHereBlock(),
  OfflineBlock(),
  TodayBlock(),
  TopBlock(),
  LovedBlock(),
  AskingBlock(),
  MineBlock(),
  WhereYouLiveBlock(),
  MonthBlock(),
  SignatureBlock.numbers(),
  SignatureBlock.debates(),
  ThemeBlock.sharpest(),
  ThemeBlock.origins(),
  ThemeBlock.stories(),
  TrueFalseBlock(),
  SpotFalseBlock(),
  CameBackBlock(),
  MoveBlock.sampling(),
  MoveBlock.compared(),
  WorkBlock(),
  UnmaskBlock(),
  HowSureBlock(),
  WhatIfBlock(),
  SeriesBlock(),
  SixtyBlock(),
  MoodBlock(),
  DidYouKnowBlock(),
  SurpriseBlock(),
  ThemeBlock.practical(),
];

/// The section's own words for [field], or [fallback].
String _words(
  ExploreSection section,
  ExploreHost host,
  String field,
  String fallback,
) => section.text(field, host.language) ?? fallback;

/// Opens [pill] from [section], with the rest of [shelf] a swipe away.
void Function(List<Pill>, Pill) _opener(
  ExploreHost host,
  ExploreSection section,
) =>
    (shelf, pill) => host.open(section, shelf, pill);

/// Says [pill] was shown on [section].
ValueChanged<Pill> _shower(ExploreHost host, ExploreSection section) =>
    (pill) => host.seen(section, pill);

// ── Two lines that are not shelves ──────────────────────────────────────

/// "Nothing in Cinema yet": said at the top when today's shelf and the
/// question from every subject have nothing for the reader, as they have
/// not for a subject whose cards are all read.
class NothingHereBlock extends ExploreBlock with SectionLayout {
  const NothingHereBlock();

  @override
  String get name => 'nothing-here';

  @override
  double get gap => 0;

  @override
  bool get isShelf => false;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreShelves shelves = ExploreShelves.of(host);
    if (shelves.today.isNotEmpty || shelves.asking.isNotEmpty) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Text(
        context.l10n.nothingInYet(host.subject ?? context.l10n.here),
        style: AppText.body(size: 14, color: context.p.inkMuted),
      ),
    );
  }
}

/// Said while Explore is the copy the phone kept from the last time it had
/// signal.
class OfflineBlock extends ExploreBlock with SectionLayout {
  const OfflineBlock();

  @override
  String get name => 'offline';

  @override
  double get gap => 0;

  @override
  bool get isShelf => false;

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    if (!ExploreShelves.of(host).offline) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Text(
        context.l10n.exploreOffline,
        key: const ValueKey('explore-offline'),
        style: AppText.body(size: 12.5, color: context.p.inkMuted),
      ),
    );
  }
}

// ── The shelves that were always there ──────────────────────────────────

/// Today's shelf: the same for everybody and only today, at a size you can
/// read across the room. `limit` shows more of it than eight.
class TodayBlock extends ExploreBlock with SectionLayout {
  const TodayBlock();

  @override
  String get name => 'today';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> cards = ExploreShelves.of(host).todayAll
        .take(section.limit ?? 8)
        .toList();
    if (cards.isEmpty) return null;
    final l = context.l10n;
    return ShelfFrame(
      title: _words(section, host, 'title', l.todaysShelf),
      line: _words(section, host, 'subtitle', l.sameForEveryone),
      child: TileRow(
        size: TileSize.l,
        pills: cards,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// The readers' top list: what readers liked, saved and said, counted
/// across everyone, each card standing on its number — this week or this
/// month, as the reader switches it. The shelf is always there: until the
/// counts have been read it shows its places empty, with the line that says
/// what puts a card on one.
class TopBlock extends ExploreBlock with SectionLayout {
  const TopBlock();

  @override
  String get name => 'top';

  @override
  Widget build(BuildContext context, ExploreHost host, ExploreSection section) {
    final ExploreShelves shelves = ExploreShelves.of(host);
    return ValueListenableBuilder<bool>(
      valueListenable: shelves.topMonth,
      builder: (context, month, _) {
        final l = context.l10n;
        final String? subject = host.subject;
        final List<(Pill, int)> top = shelves.top(month: month);
        return ShelfFrame(
          title: _words(
            section,
            host,
            'title',
            subject != null
                ? l.topIn(subject)
                : month
                ? l.topOfTheMonth
                : l.topOfTheWeek,
          ),
          line: _words(
            section,
            host,
            'subtitle',
            month ? l.topLineMonth : l.topLineWeek,
          ),
          trailing: WindowSwitch(
            month: month,
            onPick: (month) {
              Analytics.capture('explore top window', {
                'window': month ? 'month' : 'week',
                'subject': subject ?? 'all',
              });
              shelves.topMonth.value = month;
            },
          ),
          child: top.isEmpty
              ? const TopGhost()
              : TopRow(
                  ranked: top,
                  isRead: host.isRead,
                  onShown: _shower(host, section),
                  onOpen: (i) {
                    Analytics.capture('explore top opened', {
                      'rank': i + 1,
                      'readers': top[i].$2,
                      'window': month ? 'month' : 'week',
                      'subject': subject ?? 'all',
                    });
                    host.open(section, [for (final t in top) t.$1], top[i].$1);
                  },
                ),
        );
      },
    );
  }
}

/// Loved since the start, and not read yet.
class LovedBlock extends ExploreBlock with SectionLayout {
  const LovedBlock();

  @override
  String get name => 'loved';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> loved = ExploreShelves.of(host).loved;
    if (loved.isEmpty) return null;
    final l = context.l10n;
    final String? subject = host.subject;
    return ShelfFrame(
      title: _words(
        section,
        host,
        'title',
        subject != null ? l.lovedIn(subject) : l.lovedSinceTheStart,
      ),
      line: _words(section, host, 'subtitle', l.lovedLine),
      child: TileRow(
        size: TileSize.m,
        pills: loved,
        isRead: host.isRead,
        onShown: _shower(host, section),
        onOpen: (shelf, pill) {
          Analytics.capture('explore loved opened', {
            'rank': shelf.indexOf(pill) + 1,
            'subject': subject ?? 'all',
          });
          host.open(section, shelf, pill);
        },
      ),
    );
  }
}

/// A question from every subject, as rows.
class AskingBlock extends ExploreBlock with SectionLayout {
  const AskingBlock();

  @override
  String get name => 'asking';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<Pill> asking = ExploreShelves.of(host).askingAll
        .take(section.limit ?? 6)
        .toList();
    if (asking.isEmpty) return null;
    final l = context.l10n;
    final String? subject = host.subject;
    return ShelfFrame(
      key: const ValueKey('shelf-asking'),
      title: _words(
        section,
        host,
        'title',
        subject != null ? l.askingIn(subject) : l.askingTitle,
      ),
      line: _words(section, host, 'subtitle', l.askingLine),
      child: RowList(
        pills: asking,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// The reader's own shelf: the subject they pushed up, or the one they have
/// read most of. Before either exists there is no such shelf.
class MineBlock extends ExploreBlock with SectionLayout {
  const MineBlock();

  @override
  String get name => 'mine';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreShelves shelves = ExploreShelves.of(host);
    final (MineReason, String)? third = shelves.third;
    final List<Pill> mine = shelves.mine;
    if (third == null || mine.isEmpty) return null;
    final l = context.l10n;
    final (MineReason why, String subject) = third;
    return ShelfFrame(
      title: _words(
        section,
        host,
        'title',
        why == MineReason.because
            ? l.becauseSitsAtFull(subject)
            : l.moreOn(subject),
      ),
      line: _words(
        section,
        host,
        'subtitle',
        why == MineReason.because ? l.olderFromTurnedUp : l.subjectReadMost,
      ),
      child: TileRow(
        size: TileSize.m,
        pills: mine,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// Where you live: the cards about the reader's place, nearest first.
/// Without a place the shelf is one tile that offers to switch it on, on
/// the whole of Explore only; with a place nobody has written about yet, it
/// is not there.
class WhereYouLiveBlock extends ExploreBlock with SectionLayout {
  const WhereYouLiveBlock();

  @override
  String get name => 'where-you-live';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String title = _words(section, host, 'title', l.whereYouLive);
    final String line = _words(section, host, 'subtitle', l.whereYouLiveLine);
    if (host.app.place == null && host.subject == null) {
      return ShelfFrame(
        key: const ValueKey('shelf-where-you-live'),
        title: title,
        line: line,
        child: WhereYouLiveAsk(
          // The place capture's own sheet, as from Profile: the system's
          // prompt only after a yes on it.
          onSwitchOn: () => askForPlace(context, host.app, from: 'explore'),
        ),
      );
    }
    final List<Pill> local = ExploreShelves.of(host).local;
    if (local.isEmpty) return null;
    return ShelfFrame(
      key: const ValueKey('shelf-where-you-live'),
      title: title,
      line: line,
      child: TileRow(
        size: TileSize.m,
        pills: local,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

// ── The mix ─────────────────────────────────────────────────────────────

/// A month of one subject, round every subject one month at a time.
class MonthBlock extends ExploreBlock with SectionLayout {
  const MonthBlock();

  @override
  String get name => 'month';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.month.length < 3) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-month'),
      title: _words(
        section,
        host,
        'title',
        l.monthOf(kTopics[mix.monthSubjectKey]?.name ?? ''),
      ),
      line: _words(section, host, 'subtitle', l.monthShelfLine),
      child: MonthShelf(
        pills: mix.month,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// A shelf with one drawing for its kind (132): numbers that surprise, the
/// figure itself set large; pick a side, two halves and the "or" to slide.
class SignatureBlock extends ExploreBlock with SectionLayout {
  const SignatureBlock.numbers() : theme = ShelfTheme.numbers;
  const SignatureBlock.debates() : theme = ShelfTheme.debates;

  /// Which of the two.
  final ShelfTheme theme;

  @override
  String get name => theme == ShelfTheme.numbers ? 'numbers' : 'debates';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    final ThemedShelf? t = theme == ShelfTheme.numbers
        ? mix.numbers
        : mix.debates;
    if (t == null) return null;
    return ShelfFrame(
      key: ValueKey('signature-${t.theme.name}'),
      title: _words(section, host, 'title', themeTitle(context, t)),
      line: _words(section, host, 'subtitle', themeLine(context, t)),
      child: SignatureRow(
        shelf: t,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        answerOf: (p) => host.app.answerFor(p.id),
        onLean: host.lean,
        onShown: _shower(host, section),
      ),
    );
  }
}

/// A themed shelf of the mix with a form of its own: the sharpest, where it
/// came from, true stories played a beat at a time, something to use before
/// tonight.
class ThemeBlock extends ExploreBlock with SectionLayout {
  const ThemeBlock.sharpest() : theme = ShelfTheme.sharpest;
  const ThemeBlock.origins() : theme = ShelfTheme.origins;
  const ThemeBlock.stories() : theme = ShelfTheme.stories;
  const ThemeBlock.practical() : theme = ShelfTheme.practical;

  /// Which shelf.
  final ShelfTheme theme;

  @override
  String get name => switch (theme) {
    ShelfTheme.sharpest => 'sharpest',
    ShelfTheme.origins => 'origins',
    ShelfTheme.stories => 'stories',
    _ => 'practical',
  };

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    final ThemedShelf? t = switch (theme) {
      ShelfTheme.sharpest => mix.sharpest,
      ShelfTheme.origins => mix.origins,
      ShelfTheme.stories => mix.stories,
      _ => mix.practical,
    };
    if (t == null) return null;
    final void Function(List<Pill>, Pill) open = _opener(host, section);
    final ValueChanged<Pill> shown = _shower(host, section);
    return ShelfFrame(
      key: ValueKey('theme-${t.key}'),
      title: _words(section, host, 'title', themeTitle(context, t)),
      line: _words(section, host, 'subtitle', themeLine(context, t)),
      child: switch (theme) {
        ShelfTheme.sharpest => SharpRow(
          pills: t.pills,
          isRead: host.isRead,
          onOpen: open,
          onShown: shown,
        ),
        ShelfTheme.origins => OriginRow(
          pills: t.pills,
          isRead: host.isRead,
          onOpen: open,
          onShown: shown,
        ),
        ShelfTheme.stories => StoryRow(
          pills: t.pills,
          isRead: host.isRead,
          onPlay: (shelf, pill, from) =>
              host.playStory(section, shelf, pill, from),
          onShown: shown,
        ),
        _ => UseTodayList(
          pills: t.pills,
          isRead: host.isRead,
          onOpen: open,
          onShown: shown,
        ),
      },
    );
  }
}

/// The game of three true claims and a false one, played as a set: under
/// the true-or-false row, or anywhere as its own section.
Widget _spot(
  ExploreHost host,
  ExploreSection section,
  SpotTheFalse spot,
) => SpotTheFalseBlock(
  spot: spot,
  onOpen: _opener(host, section),
  // The pick is the one answer given; the reveal tells all four, so all four
  // count as read and the day never deals one whose answer was shown.
  onCommit: (pill, response) async {
    await host.commit(pill, response);
    for (final Pill other in spot.cards) {
      if (other.id != pill.id) await host.app.markReadElsewhere(other.id);
    }
  },
  onShown: (p) => host is ExploreShelfHost
      ? host.seenAs(section, 'spot-false', p)
      : host.seen(section, p),
);

/// True or false: decided before the card is turned, on the shelf itself,
/// with the game of spotting the false one under the row (`spot`: false
/// leaves it out).
class TrueFalseBlock extends ExploreBlock with SectionLayout {
  const TrueFalseBlock();

  @override
  String get name => 'true-false';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    final ThemedShelf? t = mix.trueFalse;
    if (t == null) return null;
    final bool withSpot = section.json['spot'] != false;
    return ShelfFrame(
      key: ValueKey('theme-${t.key}'),
      title: _words(section, host, 'title', themeTitle(context, t)),
      line: _words(section, host, 'subtitle', themeLine(context, t)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrueFalseRow(
            pills: t.pills,
            isRead: host.isRead,
            onOpen: _opener(host, section),
            answerOf: (p) => host.app.answerFor(p.id)?.response,
            onCommit: host.commit,
            onShown: _shower(host, section),
          ),
          // Three true and one false, under the row: the same kind of card,
          // played as a set.
          if (withSpot)
            if (mix.spot case final SpotTheFalse spot) ...[
              const SizedBox(height: 16),
              _spot(host, section, spot),
            ],
        ],
      ),
    );
  }
}

/// Spot the false one, on its own: four claims, three true.
class SpotFalseBlock extends ExploreBlock with SectionLayout {
  const SpotFalseBlock();

  @override
  String get name => 'spot-false';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final SpotTheFalse? spot = ExploreShelves.of(host).mix.spot;
    if (spot == null) return null;
    return _spot(host, section, spot);
  }
}

/// The cards that came back, to be answered again.
class CameBackBlock extends ExploreBlock with SectionLayout {
  const CameBackBlock();

  @override
  String get name => 'came-back';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final List<CameBackCard> cameBack = ExploreShelves.of(host).cameBack;
    if (cameBack.isEmpty) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-came-back'),
      title: _words(section, host, 'title', l.cameBack),
      line: _words(section, host, 'subtitle', l.cardsCameBack(cameBack.length)),
      child: CameBackRow(
        cards: cameBack,
        onOpen: (shelf, pill) => host is ExploreShelfHost
            ? host.openDue(section, shelf, pill)
            : host.open(section, shelf, pill),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// One of two questions to ask of a number, each named like any other
/// shelf, with what the reader has done with the move beside it.
class MoveBlock extends ExploreBlock with SectionLayout {
  const MoveBlock.sampling() : principle = Principle.sampling;
  const MoveBlock.compared() : principle = Principle.counterfactual;

  /// The move.
  final Principle principle;

  @override
  String get name =>
      principle == Principle.sampling ? 'move-sampling' : 'move-compared';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    final bool sampling = principle == Principle.sampling;
    final List<Pill> cards = sampling ? mix.sampling : mix.compared;
    if (cards.length < 3) return null;
    final l = context.l10n;
    final int met = host.app.masteryOf(principle).met;
    return ShelfFrame(
      key: ValueKey(sampling ? 'mix-move-sampling' : 'mix-move-compared'),
      title: _words(
        section,
        host,
        'title',
        sampling ? l.moveSampling : l.moveComparedToWhat,
      ),
      line: _words(
        section,
        host,
        'subtitle',
        sampling ? l.moveSamplingLine : l.moveComparedToWhatLine,
      ),
      trailing: MoveBadge(
        label: met > 0 ? l.inYourMoves(met) : l.newMove,
        lit: met > 0,
      ),
      child: MoveRow(
        pills: cards,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// Work it out: one row of every way to play a number, with the points left
/// to bet beside the name.
class WorkBlock extends ExploreBlock with SectionLayout {
  const WorkBlock();

  @override
  String get name => 'work';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.work.isEmpty) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-work'),
      title: _words(section, host, 'title', l.themeWorkItOut),
      line: _words(section, host, 'subtitle', l.themeWorkItOutLine),
      trailing: const WorkWallet(),
      child: WorkItOut(
        deal: mix.work,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        answerOf: (p) => host.app.answerFor(p.id)?.response,
        onCommit: host.commit,
        onShown: _shower(host, section),
      ),
    );
  }
}

/// Unmask the chart: the honest view of a chart that lies in its drawing.
class UnmaskBlock extends ExploreBlock with SectionLayout {
  const UnmaskBlock();

  @override
  String get name => 'unmask';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.unmask.isEmpty) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-unmask'),
      title: _words(section, host, 'title', l.unmaskTitle),
      line: _words(section, host, 'subtitle', l.unmaskLine),
      child: UnmaskRow(
        pills: mix.unmask,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// How sure am I, and why: the cards about how a mind gets to a belief, in
/// a frame of their own.
class HowSureBlock extends ExploreBlock with SectionLayout {
  const HowSureBlock();

  @override
  String get name => 'how-sure';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.howSure.length < 3) return null;
    return HowSureShelf(
      key: const ValueKey('mix-how-sure'),
      pills: mix.howSure,
      isRead: host.isRead,
      onOpen: _opener(host, section),
      onShown: _shower(host, section),
    );
  }
}

/// What if it's true: ideas that keep working after the card is closed.
class WhatIfBlock extends ExploreBlock with SectionLayout {
  const WhatIfBlock();

  @override
  String get name => 'what-if';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.whatIf.length < 3) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-what-if'),
      title: _words(section, host, 'title', l.whatIfTrue),
      line: _words(section, host, 'subtitle', l.whatIfTrueLine),
      child: WhatIfRow(
        pills: mix.whatIf,
        isRead: host.isRead,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// A few cards that only make the point together, easiest first.
class SeriesBlock extends ExploreBlock with SectionLayout {
  const SeriesBlock();

  @override
  String get name => 'series';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.series.isEmpty) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-series'),
      title: _words(section, host, 'title', l.fewCards),
      line: _words(section, host, 'subtitle', l.fewCardsLine),
      child: SeriesRow(
        series: mix.series,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// Sixty seconds: eight claims against the clock.
class SixtyBlock extends ExploreBlock with SectionLayout {
  const SixtyBlock();

  @override
  String get name => 'sixty';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.sixty.length != 8) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-sixty'),
      title: _words(section, host, 'title', l.sixtyTitle),
      line: _words(section, host, 'subtitle', l.sixtyLine),
      child: SixtySeconds(
        pills: mix.sixty,
        onOpen: _opener(host, section),
        onShown: _shower(host, section),
      ),
    );
  }
}

/// Your mood, your minutes: cards for the tone and the time there is, in a
/// frame of its own.
class MoodBlock extends ExploreBlock with SectionLayout {
  const MoodBlock();

  @override
  String get name => 'mood';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreShelves shelves = ExploreShelves.of(host);
    final ExploreMix mix = shelves.mix;
    if (mix.moodPool.isEmpty) return null;
    final int day = shelves.mixDay;
    return MoodMinutes(
      key: const ValueKey('mix-mood'),
      cardsFor: (tone, minutes) => shelves.moodMemo.putIfAbsent(
        '${tone.name}-$minutes',
        () => forTheTime(mix.moodPool, tone: tone, minutes: minutes, day: day),
      ),
      isRead: host.isRead,
      onOpen: _opener(host, section),
      onShown: _shower(host, section),
    );
  }
}

/// Did you know: facts met one at a time and judged new or known, in a
/// frame of their own. Judging one reads it.
class DidYouKnowBlock extends ExploreBlock with SectionLayout {
  const DidYouKnowBlock();

  @override
  String get name => 'did-you-know';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.didYouKnow.length < 4) return null;
    return DidYouKnow(
      key: const ValueKey('mix-did-you-know'),
      pills: mix.didYouKnow,
      onOpen: _opener(host, section),
      onRead: (p) => host.app.markReadElsewhere(p.id),
      onShown: _shower(host, section),
    );
  }
}

/// Not sure where to start: one card from anywhere, at a tap.
class SurpriseBlock extends ExploreBlock with SectionLayout {
  const SurpriseBlock();

  @override
  String get name => 'surprise';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ExploreMix mix = ExploreShelves.of(host).mix;
    if (mix.surprise.isEmpty) return null;
    final l = context.l10n;
    return ShelfFrame(
      key: const ValueKey('mix-surprise'),
      title: _words(section, host, 'title', l.notSureTitle),
      line: _words(section, host, 'subtitle', l.notSureLine),
      child: SurpriseMe(pool: mix.surprise, onOpen: _opener(host, section)),
    );
  }
}

/// A themed shelf's name, in the reader's language.
String themeTitle(BuildContext context, ThemedShelf t) {
  final l = context.l10n;
  return switch (t.theme) {
    ShelfTheme.myths => l.themeMyths,
    ShelfTheme.paradoxes => l.themeParadoxes,
    ShelfTheme.numbers => l.themeNumbers,
    ShelfTheme.practical => l.themePractical,
    ShelfTheme.origins => l.themeOrigins,
    ShelfTheme.stories => l.themeStories,
    ShelfTheme.debates => l.themeDebates,
    ShelfTheme.workItOut => l.themeWorkItOut,
    ShelfTheme.seen => l.themeSeen,
    ShelfTheme.sharpest => l.themeSharpest,
    ShelfTheme.puzzles => l.themePuzzles,
    ShelfTheme.howItWorks => l.themeHowItWorks,
    ShelfTheme.moving => l.themeMoving,
    ShelfTheme.curious => l.themeCurious,
    ShelfTheme.ideas => l.themeIdeas,
    ShelfTheme.reasoning => l.themeReasoning,
    ShelfTheme.trueOrFalse => l.themeTrueOrFalse,
    ShelfTheme.past => [l.themePast0, l.themePast1, l.themePast2][t.variant],
    ShelfTheme.place => [
      l.themePlace0,
      l.themePlace1,
      l.themePlace2,
    ][t.variant],
  };
}

/// The line under a themed shelf's name.
String themeLine(BuildContext context, ThemedShelf t) {
  final l = context.l10n;
  return switch (t.theme) {
    ShelfTheme.myths => l.themeMythsLine,
    ShelfTheme.paradoxes => l.themeParadoxesLine,
    ShelfTheme.numbers => l.themeNumbersLine,
    ShelfTheme.practical => l.themePracticalLine,
    ShelfTheme.origins => l.themeOriginsLine,
    ShelfTheme.stories => l.themeStoriesLine,
    ShelfTheme.debates => l.themeDebatesLine,
    ShelfTheme.workItOut => l.themeWorkItOutLine,
    ShelfTheme.seen => l.themeSeenLine,
    ShelfTheme.sharpest => l.themeSharpestLine,
    ShelfTheme.puzzles => l.themePuzzlesLine,
    ShelfTheme.howItWorks => l.themeHowItWorksLine,
    ShelfTheme.moving => l.themeMovingLine,
    ShelfTheme.curious => l.themeCuriousLine,
    ShelfTheme.ideas => l.themeIdeasLine,
    ShelfTheme.reasoning => l.themeReasoningLine,
    ShelfTheme.trueOrFalse => l.themeTrueOrFalseLine,
    ShelfTheme.past => l.themePastLine,
    ShelfTheme.place => l.themePlaceLine,
  };
}
