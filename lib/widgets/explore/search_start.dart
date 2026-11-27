/// Search, before anything is typed (prototype A7): a few words to try,
/// the areas by need, and the cards by kind. A search field alone asks the
/// reader to know what they are looking for; this is somewhere to go
/// without knowing.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/goals.dart';
import '../../data/pill_bank.dart';
import '../../data/pills_repository.dart' show dateKey;
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../models/place.dart';
import '../../theme.dart';
import '../area_marks.dart';
import '../fit_text.dart';

/// A kind of card, to look through by: how it is played, not what it is
/// about.
enum CardKind {
  /// Drawn as a page: a game, a slider, a drawing, a scene.
  play,

  /// One of a few answers to pick.
  quiz,

  /// A number to put on something.
  estimate,

  /// A side to take, with no answer counted right.
  debate,

  /// Read in a breath: nothing asked, nothing drawn.
  quick;

  bool fits(Pill p) => switch (this) {
    CardKind.play => p.hasPage,
    CardKind.quiz => p.challenge is PickOne,
    CardKind.estimate => p.challenge is Estimate || p.challenge is TypeNumber,
    CardKind.debate => p.challenge is TakeASide,
    CardKind.quick => !p.hasPage && p.challenge is NoChallenge,
  };
}

/// [kind]'s name, as the reader reads it.
String kindName(AppLocalizations l, CardKind kind) => l.kindName(kind.name);

/// The cards of [kind] a reader living at [home] may be shown: those not
/// [read] first, each part in the day's order, [limit] at most.
List<Pill> cardsOfKind(
  CardKind kind, {
  required DateTime day,
  Place? home,
  Set<String> read = const {},
  int limit = 60,
}) {
  final List<Pill> fresh = [];
  final List<Pill> seen = [];
  for (final Pill p in PillBank.live) {
    if (p.book != null || !kind.fits(p)) continue;
    if (p.place != null && placeFit(p.place!, home) == PlaceFit.none) continue;
    (read.contains(p.id) ? seen : fresh).add(p);
  }
  final Random rng = Random(dateKey(day).hashCode ^ kind.index);
  fresh.shuffle(rng);
  seen.shuffle(rng);
  return [...fresh, ...seen].take(limit).toList();
}

/// Words to try before anything is typed: keywords a handful of cards share,
/// never one card's and never a whole subject's, [count] of them a day,
/// the same for everybody, turning over daily.
List<String> searchSuggestions(DateTime day, {int count = 6}) {
  final String key = '${dateKey(day)}:$count:${PillBank.live.length}';
  final List<String>? kept = _suggested[key];
  if (kept != null) return kept;
  final Map<String, int> n = {};
  for (final Pill p in PillBank.live) {
    if (p.book != null || p.place != null) continue;
    for (final String k in p.keywords) {
      final String w = k.trim().toLowerCase();
      if (w.length < 3 || w.length > 16) continue;
      n[w] = (n[w] ?? 0) + 1;
    }
  }
  final List<String> pool = [
    for (final MapEntry<String, int> e in n.entries)
      if (e.value >= 5 && e.value <= 40) e.key,
  ]..sort();
  pool.shuffle(Random(dateKey(day).hashCode));
  final List<String> out = List.unmodifiable(pool.take(count));
  _suggested
    ..clear()
    ..[key] = out;
  return out;
}

final Map<String, List<String>> _suggested = {};

/// The page under an empty search field.
class SearchStart extends StatelessWidget {
  const SearchStart({
    super.key,
    required this.day,
    required this.onTry,
    required this.onArea,
    required this.onKind,
  });

  final DateTime day;
  final ValueChanged<String> onTry;
  final ValueChanged<Goal> onArea;
  final ValueChanged<CardKind> onKind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final List<String> tries = searchSuggestions(day);
    return ListView(
      key: const ValueKey('search-start'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (tries.isNotEmpty) ...[
          _Label(l.searchTry),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final String w in tries)
                _Chip(
                  key: ValueKey('search-try-$w'),
                  label: w,
                  outlined: true,
                  onTap: () => onTry(w),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        _Label(l.searchByNeed),
        LayoutBuilder(
          builder: (context, box) {
            final double w = (box.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final Goal g in Goal.values)
                  SizedBox(
                    width: w,
                    child: _Need(
                      key: ValueKey('search-need-${g.key}'),
                      area: g,
                      onTap: () => onArea(g),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _Label(l.searchByKind),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final CardKind k in CardKind.values)
              _Chip(
                key: ValueKey('search-kind-${k.name}'),
                label: kindName(l, k),
                outlined: false,
                onTap: () => onKind(k),
              ),
          ],
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppText.label(
          size: 11.5,
          weight: FontWeight.w700,
          spacing: 1.3,
          color: context.p.inkMuted,
        ),
      ),
    ),
  );
}

/// A word to try, or a kind: a pill to tap.
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.outlined,
    required this.onTap,
  });

  final String label;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Material(
      color: outlined ? Colors.transparent : p.surfaceRaised,
      shape: StadiumBorder(
        side: outlined ? BorderSide(color: p.lineStrong) : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            label,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// An area, by need: its mark in its colour, its name, its line.
class _Need extends StatelessWidget {
  const _Need({super.key, required this.area, required this.onTap});

  final Goal area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Material(
      color: p.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(goalIcon(area), size: 17, color: goalHue(area)),
                  ),
                  const SizedBox(width: 8),
                  // Whole words, a point or two smaller where one would not
                  // fit the half of a small phone: a name broken inside a
                  // word ("Alltagsentschei / dungen") reads as a fault.
                  Expanded(
                    child: FitText(
                      goalName(l, area),
                      maxLines: 2,
                      minSize: 12,
                      wholeWords: true,
                      style: AppText.body(
                        size: 14.5,
                        weight: FontWeight.w700,
                        height: 1.25,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // The whole line, never cut short with three dots: in German
              // it takes a fourth line on a small phone.
              Text(
                goalLine(l, area),
                style: AppText.body(size: 12, height: 1.3, color: p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
