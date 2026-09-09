import 'package:flutter/material.dart';

import '../data/pills_repository.dart';
import '../data/pills_data.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/scaled_text.dart';
import '../widgets/subject_icon.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart';

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

  @override
  void dispose() {
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
              setState(() => _searching = true);
              _focus.requestFocus();
            },
            onCloseSearch: () {
              _field.clear();
              setState(() {
                _searching = false;
                _query = '';
              });
            },
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        if (!_searching)
          _SubjectRow(
            selected: _subject,
            // A subject, All, or the lit subject again — the last two both
            // clear it, so the way back is whichever the finger finds first.
            onPick: (name) =>
                setState(() => _subject = name == _subject ? null : name),
          ),
        Expanded(child: _searching ? _found(context) : _shelfList(context)),
      ],
    );
  }

  /// The shelves, and a fade where they run under the tab bar.
  Widget _shelfList(BuildContext context) {
    // Today's shelf is the same for everybody and changes at midnight —
    // which is what the canvas means by "written this morning". Nothing
    // here is dealt from the reader's own mix.
    final List<Pill> fresh = _only(
      pickedPills(seed: daySeed(DateTime.now()), count: 24),
    ).take(8).toList();

    // The canvas ranks this shelf by what everyone saved. Nothing counts
    // saves yet — there is no server to count them on — so it is ranked by
    // what the cards ask instead, which is the same order the shelf was
    // always in and a claim the app can stand behind.
    final List<Pill> asking = _only(pickedPills(seed: allTimeSeed, count: 40))
        .take(6)
        .toList();

    // The third shelf is about the reader, and it is always there. An
    // install that never dragged the mix used to get two shelves and a
    // page with nowhere to scroll to, which is not this screen.
    final (String title, String line, String subject) = _thirdShelf();
    final List<Pill> mine = _only(
      pickedPills(seed: monthSeed(DateTime.now()), count: 40, topic: subject),
    ).take(8).toList();

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
                  'Nothing in ${_subject ?? 'here'} yet.',
                  style: AppText.body(size: 14, color: context.p.inkMuted),
                ),
              ),
            if (fresh.isNotEmpty)
              _Shelf(
                title: "Today's shelf",
                line: 'The same for everyone, and only today',
                child: _BigRow(pills: fresh, onOpen: _open),
              ),
            if (asking.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Shelf(
                title: 'The ones that ask the most',
                line: 'Across everyone, not just your mix',
                child: _RowList(pills: asking, onOpen: _open),
              ),
            ],
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Shelf(
                title: title,
                line: line,
                child: _SmallRow(pills: mine, onOpen: _open),
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
          'Because $name sits at full',
          'Older cards from the subjects you turned up',
          name,
        );
      }
    }

    final counted = <String, int>{};
    for (final pill in kPillPool) {
      if (app.seenIds.contains(pill.id)) {
        counted[pill.topic] = (counted[pill.topic] ?? 0) + 1;
      }
    }
    if (counted.isNotEmpty) {
      final String most =
          (counted.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
      return ('More on $most', 'The subject you have read most of', most);
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
    return ('A month of $name', 'Somewhere to start that is not today', name);
  }

  Widget _found(BuildContext context) {
    final List<Pill> rows = _query.trim().isEmpty
        ? const []
        : searchPills(_query);
    if (_query.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Text(
          'Search every card.',
          style: AppText.body(size: 13, color: context.p.inkMuted),
        ),
      );
    }
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Text(
          'Nothing for "${_query.trim()}" yet.',
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
            '${rows.length} matching',
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
      _subject ?? 'Explore',
      initialIndex: shelf.indexOf(pill),
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
                        hintText: 'Search every card',
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
                'Cancel',
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
          'Explore',
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
              'subject-${subject?.name ?? 'All'}-${on ? 'on' : 'off'}',
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

/// A shelf: what it holds, why it exists, and the cards.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.line, required this.child});

  final String title;
  final String line;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -0.2,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 3),
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
  const _BigRow({required this.pills, required this.onOpen});

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;

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
  const _RowList({required this.pills, required this.onOpen});

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;

  @override
  Widget build(BuildContext context) {
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
  const _SmallRow({required this.pills, required this.onOpen});

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;

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
