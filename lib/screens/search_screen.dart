import 'package:flutter/material.dart';

import '../data/pills_repository.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart';

/// How far back a shelf reaches.
enum _Range {
  today('Today', 'TOP TODAY'),
  week('This week', 'TOP THIS WEEK'),
  month('This month', 'TOP THIS MONTH'),
  ever('All time', 'TOP ALL TIME');

  const _Range(this.label, this.badge);
  final String label;
  final String badge;
}

/// Cards nobody dealt you — artboard 52a.
///
/// One card held up at the top of a ranked list, a range across the middle
/// and the subjects under it. These are everyone's cards rather than your
/// mix, and the screen says so, because a shelf that quietly matched your
/// taste would only ever hand back what you already asked for.
class SearchScreen extends StatefulWidget {
  final AppState app;

  const SearchScreen({super.key, required this.app});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  _Range _range = _Range.today;

  /// The subject's display name, or null for all of them.
  String? _topic;

  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _seed => switch (_range) {
    _Range.today => daySeed(DateTime.now()),
    _Range.week => weekSeed(DateTime.now()),
    _Range.month => monthSeed(DateTime.now()),
    _Range.ever => allTimeSeed,
  };

  void _open(List<Pill> shelf, int at) {
    openDeckViewer(context, widget.app, shelf, _range.label, initialIndex: at);
  }

  @override
  Widget build(BuildContext context) {
    final List<Pill> rows = _query.trim().isEmpty
        ? pickedPills(seed: _seed, count: 12, topic: _topic)
        : searchPills(_query)
              .where((p) => _topic == null || p.topic == _topic)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Head(
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
              const SizedBox(height: 12),
              Text(
                // The canvas says "what everyone is saving". Nothing collects
                // that yet, so this says the part that is true: the shelf is
                // the same for everybody and it is not your mix.
                _query.trim().isEmpty
                    ? "Everyone's cards, not your mix. The ones that ask the "
                          'most, first.'
                    : '${rows.length} matching',
                style: AppText.body(
                  size: 13,
                  height: 1.4,
                  color: context.p.ink.withValues(alpha: 0.45),
                ),
              ),
              if (_query.trim().isEmpty) ...[
                const SizedBox(height: 12),
                _Ranges(
                  selected: _range,
                  onPick: (r) => setState(() => _range = r),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _TopicStrip(
          selected: _topic,
          onPick: (name) => setState(() => _topic = name),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'Nothing here yet.',
                    style: AppText.body(size: 14, color: context.p.inkMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  itemCount: rows.length,
                  itemBuilder: (context, i) => i == 0
                      ? _Hero(
                          pill: rows.first,
                          badge: _query.trim().isEmpty
                              ? _range.badge
                              : 'BEST MATCH',
                          onTap: () => _open(rows, 0),
                        )
                      : _RankRow(
                          pill: rows[i],
                          rank: i + 1,
                          onTap: () => _open(rows, i),
                        ),
                ),
        ),
      ],
    );
  }
}

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
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: context.p.ink.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: context.p.ink.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: field,
                      focusNode: focus,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      style: AppText.body(size: 15, color: context.p.ink),
                      cursorColor: context.p.ink,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search every card',
                        hintStyle: AppText.body(
                          size: 15,
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
        Row(
          children: [
            Text(
              'Best ',
              style: AppText.display(
                size: 30,
                weight: FontWeight.w600,
                height: 1.04,
                spacing: -1,
                color: context.p.ink,
              ),
            ),
            const SpectrumWord('cards', size: 30),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenSearch,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.p.ink.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.search_rounded,
              size: 18,
              color: context.p.ink.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _Ranges extends StatelessWidget {
  const _Ranges({required this.selected, required this.onPick});

  final _Range selected;
  final ValueChanged<_Range> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final range in _Range.values) ...[
          if (range != _Range.values.first) const SizedBox(width: 7),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: range == selected
                      ? context.p.inverse
                      : context.p.ink.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  range.label,
                  maxLines: 1,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: range == selected
                        ? context.p.onInverse
                        : context.p.ink.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TopicStrip extends StatelessWidget {
  const _TopicStrip({required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _chip(context, 'All', null, selected == null, () => onPick(null)),
          for (final subject in kMixSubjects)
            _chip(
              context,
              subject.name,
              subject.color,
              selected == subject.name,
              () => onPick(selected == subject.name ? null : subject.name),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    Color? colour,
    bool on,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.p.ink.withValues(alpha: on ? 0.13 : 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (colour != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colour,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: on
                      ? context.p.ink
                      : context.p.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card held up at the top of the list, in its own colour.
class _Hero extends StatelessWidget {
  const _Hero({required this.pill, required this.badge, required this.onTap});

  final Pill pill;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = pill.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    pill.topic.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(
                      size: 10.5,
                      spacing: 1.5,
                      color: ink.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: AppText.label(
                      size: 10.5,
                      spacing: 0.6,
                      color: ink.withValues(alpha: 0.66),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              pill.question,
              style: AppText.body(
                size: 25,
                weight: FontWeight.w600,
                height: 1.14,
                spacing: -0.7,
                color: ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              // The canvas prints a save count here. Nothing counts saves
              // yet, so this says what is actually true of the card.
              pill.difficulty.label,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w600,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.pill, required this.rank, required this.onTap});

  final Pill pill;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        decoration: BoxDecoration(
          color: context.p.ink.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 18,
                child: Center(
                  child: Text(
                    rank.toString().padLeft(2, '0'),
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: context.p.ink.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: pill.color,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: pill.color.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        height: 1.28,
                        weight: FontWeight.w600,
                        color: context.p.ink.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${pill.topic} · ${pill.difficulty.label}',
                      style: AppText.body(
                        size: 11,
                        weight: FontWeight.w500,
                        color: context.p.ink.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
