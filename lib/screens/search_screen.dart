import 'package:flutter/material.dart';

import '../data/pills_repository.dart';
import '../data/topics.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'deck_viewer_screen.dart';
import 'mix_screen.dart';

/// A shelf of cards nobody dealt you.
///
/// Not a second archive and not a feed. Today's five are chosen for you and
/// the archive is what you have already read; this is the third thing — a
/// handful picked for the day and for the month, the same handful for
/// everybody, so there is somewhere to go when you have finished and still
/// want to look. Deliberately not personalised: a shelf that already knows
/// your taste cannot show you anything you did not ask for.
class SearchScreen extends StatefulWidget {
  final AppState app;

  const SearchScreen({super.key, required this.app});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _field = TextEditingController();
  String _query = '';

  /// The subject's display name, or null for all of them.
  String? _topic;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _open(List<Pill> shelf, int at, String title) {
    openDeckViewer(context, widget.app, shelf, title, initialIndex: at);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool searching = _query.trim().isNotEmpty;

    final List<Pill> results = searching
        ? searchPills(_query)
              .where((p) => _topic == null || p.topic == _topic)
              .toList()
        : const [];
    final List<Pill> today = pickedPills(
      seed: daySeed(now),
      count: 6,
      topic: _topic,
    );
    final List<Pill> month = pickedPills(
      seed: monthSeed(now),
      count: 14,
      topic: _topic,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            controller: _field,
            onChanged: (q) => setState(() => _query = q),
            onClear: () {
              _field.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: 14),
          _TopicStrip(
            selected: _topic,
            onPick: (name) => setState(() => _topic = name),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: searching
                ? _Shelf(
                    // The count, not a word: a reader scanning results wants
                    // to know how many there are before reading any of them.
                    title: results.length == 1
                        ? '1 card'
                        : '${results.length} cards',
                    pills: results,
                    onOpen: (i) => _open(results, i, 'Search'),
                    empty: 'Nothing matches that yet.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      _Shelf(
                        title: _topic == null ? 'Today' : 'Today in $_topic',
                        pills: today,
                        onOpen: (i) => _open(today, i, 'Today'),
                        inline: true,
                      ),
                      const SizedBox(height: 22),
                      _Shelf(
                        title: _topic == null
                            ? 'This month'
                            : 'This month in $_topic',
                        pills: month,
                        onOpen: (i) => _open(month, i, 'This month'),
                        inline: true,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.p.line),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: context.p.inkFaint),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppText.body(size: 15, color: context.p.ink),
              cursorColor: context.p.ink,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search every card',
                hintStyle: AppText.body(size: 15, color: context.p.inkFaint),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.p.inkFaint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The subjects, along the top, in the onboarding's own order.
class _TopicStrip extends StatelessWidget {
  const _TopicStrip({required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _chip(
            context,
            label: 'All',
            colour: null,
            on: selected == null,
            onTap: () => onPick(null),
          ),
          for (final subject in kMixSubjects)
            _chip(
              context,
              label: subject.name,
              colour: subject.color,
              on: selected == subject.name,
              onTap: () =>
                  onPick(selected == subject.name ? null : subject.name),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color? colour,
    required bool on,
    required VoidCallback onTap,
  }) {
    final Color fill = colour ?? context.p.inverse;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: on ? fill : context.p.surfaceRaised,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? Colors.transparent : context.p.line),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              color: on
                  ? (colour == null ? context.p.onInverse : inkOn(colour))
                  : context.p.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({
    required this.title,
    required this.pills,
    required this.onOpen,
    this.empty,
    this.inline = false,
  });

  final String title;
  final List<Pill> pills;
  final ValueChanged<int> onOpen;
  final String? empty;

  /// True when this shelf is already inside a scroll view.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
        child: Text(
          title,
          style: AppText.display(
            size: 17,
            weight: FontWeight.w600,
            spacing: -0.3,
            color: context.p.ink,
          ),
        ),
      ),
      if (pills.isEmpty && empty != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 22, 2, 0),
          child: Text(
            empty!,
            style: AppText.body(size: 14, color: context.p.inkMuted),
          ),
        ),
      for (int i = 0; i < pills.length; i++)
        _CardRow(pill: pills[i], onTap: () => onOpen(i)),
    ];

    if (inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    }
    return ListView(padding: const EdgeInsets.only(bottom: 8), children: rows);
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.pill, required this.onTap});

  final Pill pill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
        decoration: BoxDecoration(
          color: context.p.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 4, right: 11),
              decoration: BoxDecoration(
                color: pill.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 14.5,
                      weight: FontWeight.w500,
                      height: 1.3,
                      color: context.p.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pill.topic,
                    style: AppText.label(
                      size: 10,
                      spacing: 1.1,
                      color: context.p.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.p.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}
