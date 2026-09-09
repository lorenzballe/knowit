import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../data/pills_data.dart';
import '../data/pills_repository.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';
import 'pill_detail_screen.dart';

/// Everything ever dealt — artboard 70e, with the search that was already
/// here kept over it.
///
/// Left alone it is the days: every one the reader has finished, most
/// recent first, five cards each, and today at the top already open. Ask
/// it something — type, or pick a subject — and it becomes the list of
/// what matched. A search field over an empty screen is a question with
/// no reason to be asked; the days give it one.
class ArchiveScreen extends StatefulWidget {
  final AppState app;
  final VoidCallback onBack;

  const ArchiveScreen({super.key, required this.app, required this.onBack});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  String? _topicFilter;

  /// The field is behind the lens, as it is on the canvas. A field sitting
  /// open over a screen that already has something on it is a prompt to
  /// type where nothing needs typing.
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Pill> get _results {
    var found = searchPills(_query);
    if (_topicFilter != null) {
      final name = kTopics[_topicFilter]!.name;
      found = found.where((p) => p.topic == name).toList();
    }
    return found;
  }

  /// Which day is open, as a date key. Today, until something else is
  /// asked for.
  String? _openDay;

  /// The days there are to show: today, then every day finished before it.
  ///
  /// Only days the reader was actually here for. A run of empty rows going
  /// back to the launch date would be a longer list saying less.
  List<DateTime> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seen = <String>{dateKey(today)};
    final out = <DateTime>[today];
    for (final key in widget.app.completedDates.reversed) {
      if (!seen.add(key)) continue;
      final parts = key.split('-').map(int.tryParse).toList();
      if (parts.length != 3 || parts.contains(null)) continue;
      out.add(DateTime(parts[0]!, parts[1]!, parts[2]!));
    }
    return out;
  }

  /// What that day held.
  ///
  /// Today's is the real deck. An earlier day is dealt again from the same
  /// date the dealer used, which is deterministic — the app has never
  /// stored a finished day's cards, and dealing it again is closer to the
  /// truth than showing nothing.
  List<Pill> _deckOf(DateTime day) {
    if (dateKey(day) == dateKey(widget.app.today)) return widget.app.todaysDeck;
    return pillsForDate(
      day,
      topics: widget.app.pickedTopics,
      weights: widget.app.topicWeights,
      levels: widget.app.topicLevels,
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final bool asking = _query.trim().isNotEmpty || _topicFilter != null;

    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Head(
                    searching: _searching,
                    controller: _controller,
                    focus: _focus,
                    onBack: widget.onBack,
                    onOpenSearch: () {
                      setState(() => _searching = true);
                      _focus.requestFocus();
                    },
                    onCloseSearch: () {
                      _controller.clear();
                      setState(() {
                        _searching = false;
                        _query = '';
                      });
                    },
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    asking
                        ? context.l10n.results(results.length)
                        : context.l10n.cardsTapADay(kPillPool.length),
                    style: AppText.body(
                      size: 12.5,
                      height: 1.35,
                      color: context.p.ink.withValues(alpha: 0.42),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TopicFilterRow(
                    topics: kTopicOrder,
                    picked: _topicFilter,
                    onPick: (key) => setState(() => _topicFilter = key),
                    keyPrefix: 'archive-filter',
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              child: asking
                  ? (results.isEmpty
                        ? _NoResults(query: _query)
                        : ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
                            itemCount: results.length,
                            itemBuilder: (context, i) => RiseIn.staggered(
                              i,
                              step: const Duration(milliseconds: 34),
                              child: _ResultRow(
                                pill: results[i],
                                saved: widget.app.isSaved(results[i].id),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PillDetailScreen(
                                      pill: results[i],
                                      app: widget.app,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      children: [
                        // What has been read, by subject, above the days it was read on.
                        // It sat in the profile, where it read as a score; here it is what
                        // it actually is, the map of the archive.
                        if (widget.app.seenIds.isNotEmpty) ...[
                          Eyebrow(context.l10n.whatYouHaveCovered),
                          const SizedBox(height: 11),
                          _Coverage(app: widget.app),
                          const SizedBox(height: 22),
                        ],
                        for (final day in _days)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _Day(
                              day: day,
                              cards: _deckOf(day),
                              open:
                                  (_openDay ?? dateKey(_days.first)) ==
                                  dateKey(day),
                              onToggle: () => setState(() {
                                _openDay =
                                    (_openDay ?? dateKey(_days.first)) ==
                                        dateKey(day)
                                    ? ''
                                    : dateKey(day);
                              }),
                              onOpen: (pill) => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PillDetailScreen(
                                    pill: pill,
                                    app: widget.app,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The way back, the name of the screen, and the lens — artboard 70e, plus
/// the arrow it had no need for. The archive is reached from the profile,
/// so it needs a way back; beside the title is where a way back goes, and
/// it costs the title nothing.
class _Head extends StatelessWidget {
  const _Head({
    required this.searching,
    required this.controller,
    required this.focus,
    required this.onBack,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onChanged,
  });

  final bool searching;
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onBack;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackCircle(onPressed: onBack),
        const SizedBox(width: 12),
        if (searching) ...[
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
                      controller: controller,
                      focusNode: focus,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: AppText.body(size: 14.5, color: context.p.ink),
                      cursorColor: context.p.ink,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: context.l10n.searchNCards(kPillPool.length),
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
        ] else ...[
          Expanded(
            child: Text(
              context.l10n.theArchive,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: 27,
                weight: FontWeight.w600,
                height: 1,
                spacing: -0.8,
                color: context.p.ink,
              ),
            ),
          ),
          Semantics(
            key: const ValueKey('archive-search'),
            button: true,
            label: 'Search every card',
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
      ],
    );
  }
}

/// One day in the archive: its name, the five colours it held, and — when
/// it is the open one — the cards themselves.
class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.cards,
    required this.open,
    required this.onToggle,
    required this.onOpen,
  });

  final DateTime day;
  final List<Pill> cards;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<Pill> onOpen;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final gap = today.difference(DateTime(day.year, day.month, day.day)).inDays;
    if (gap == 0) return 'Today';
    if (gap == 1) return 'Yesterday';
    return '${_weekdays[day.weekday - 1]} ${day.day} '
        '${_months[day.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: open
            ? context.p.ink.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          size: 14.5,
                          weight: FontWeight.w600,
                          height: 1,
                          spacing: -0.2,
                          color: context.p.ink,
                        ),
                      ),
                    ),
                    // The day's colours, which is what a day is at a
                    // glance: five subjects, in the order they came.
                    for (final pill in cards.take(5))
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: pill.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        context.l10n.nCards(cards.length),
                        textAlign: TextAlign.right,
                        style: AppText.body(
                          size: 11,
                          weight: FontWeight.w500,
                          height: 1,
                          color: context.p.ink.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 14),
              child: Column(
                children: [
                  for (final pill in cards)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: pill == cards.last ? 0 : 7,
                      ),
                      child: RiseIn(
                        duration: const Duration(milliseconds: 300),
                        distance: 8,
                        child: _DayCard(pill: pill, onTap: () => onOpen(pill)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A card inside an open day: a bar of its colour, and the question.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.pill, required this.onTap});

  final Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: context.p.ink.withValues(alpha: 0.05),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: pill.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pill.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            height: 1.28,
                            color: context.p.ink.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pill.topic,
                          style: AppText.body(
                            size: 10.5,
                            weight: FontWeight.w500,
                            height: 1,
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

class _ResultRow extends StatelessWidget {
  final Pill pill;
  final VoidCallback onTap;
  final bool saved;
  const _ResultRow({
    required this.pill,
    required this.onTap,
    required this.saved,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.p.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: TopicDot(pill.color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.question,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w500,
                      height: 1.32,
                      color: context.p.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pill.topic} · ${pill.source}',
                    style: AppText.body(size: 11.5, color: context.p.inkFaint),
                  ),
                ],
              ),
            ),
            if (saved)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 3),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: pill.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          query.isEmpty
              ? context.l10n.noPillsMatchFilter
              : context.l10n.nothingForTryTopic(query),
          textAlign: TextAlign.center,
          style: AppText.body(size: 14, height: 1.5, color: context.p.inkMuted),
        ),
      ),
    );
  }
}

class _Coverage extends StatelessWidget {
  final AppState app;
  const _Coverage({required this.app});

  @override
  Widget build(BuildContext context) {
    final byTopic = <String, int>{};
    final seenByTopic = <String, int>{};
    for (final pill in kPillPool) {
      byTopic[pill.topic] = (byTopic[pill.topic] ?? 0) + 1;
      if (app.seenIds.contains(pill.id)) {
        seenByTopic[pill.topic] = (seenByTopic[pill.topic] ?? 0) + 1;
      }
    }

    final rows = kTopicOrder
        .where(app.pickedTopics.contains)
        .map((key) => kTopics[key]!)
        .where((style) => (byTopic[style.name] ?? 0) > 0)
        .toList();

    // The most any one subject has been read. The bars are drawn against
    // this, not against how many cards exist: the pool is written to keep
    // growing, so a total would be a number that quietly stops being true —
    // and one that says "you have read 3% of Astut", which is nobody's idea
    // of progress.
    final int busiest = rows
        .map((style) => seenByTopic[style.name] ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows.map((style) {
            final seen = seenByTopic[style.name] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // The subject's own colour, present before any of it
                      // has been read. An empty bar is the same grey for
                      // every topic, which loses the one thing that tells
                      // them apart at a glance.
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(right: 9),
                        decoration: BoxDecoration(
                          color: style.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          style.name,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w500,
                            color: context.p.ink,
                          ),
                        ),
                      ),
                      Text(
                        '$seen',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w500,
                          color: context.p.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: busiest == 0 ? 0 : seen / busiest,
                      minHeight: 5,
                      backgroundColor: context.p.line,
                      valueColor: AlwaysStoppedAnimation(style.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
