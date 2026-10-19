/// The bet slip (139a): every bet laid today, what was said and what it
/// came to, the day's points won or lost, and a line about how the bets
/// are going.
library;

import 'package:flutter/material.dart';

import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bets_day.dart';
import 'deal.dart';
import 'parts.dart';

/// The name a bet goes by on the slip: the card's first handle, in
/// sentence case ("Pollinators", "30-day streak"), or the start of its
/// question when it has none.
String slipName(Pill pill) {
  final String handle = pill.keywords.isEmpty ? '' : pill.keywords.first.trim();
  if (handle.isNotEmpty) {
    return handle[0].toUpperCase() + handle.substring(1);
  }
  final List<String> words = pill.question.split(RegExp(r'\s+'));
  return words.length <= 5 ? pill.question : '${words.take(5).join(' ')}…';
}

/// A count of points as the slip says it: "+30", "−20", "0".
String signed(int n) => n > 0 ? '+$n' : (n < 0 ? '−${-n}' : '0');

/// The slip, as a panel on the page.
class BetSlip extends StatelessWidget {
  const BetSlip({
    super.key,
    this.onlySection,
    this.kinds,
    this.widths,
    this.most,
    this.title,
  });

  /// Only the bets laid in this section; every section's when null.
  final String? onlySection;

  /// Only bets of these kinds; every kind when null.
  final Set<String>? kinds;

  /// The widths of the range it stands under, for the line that says how
  /// much narrow pays.
  final List<RangeWidth>? widths;

  /// The most bets it lists, the latest; all of them when null.
  final int? most;

  /// Its name, where the section gives it one.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BetsDay.instance,
      builder: (context, _) => _slip(context),
    );
  }

  Widget _slip(BuildContext context) {
    final l = context.l10n;
    final BetInk ink = BetInk.page(context);
    final List<Bet> all = [
      for (final Bet b in BetsDay.instance.slip)
        if ((onlySection == null || b.section == onlySection) &&
            (kinds == null || kinds!.contains(b.kind)))
          b,
    ];
    final List<Bet> shown = most == null || all.length <= most!
        ? all
        : all.sublist(all.length - most!);
    final int total = all.fold(0, (n, b) => n + b.points);
    final String? foot = _foot(context, all);
    return Container(
      key: const ValueKey('bets-slip'),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: ink.ground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  title ?? l.betsSlipTitle,
                  style: AppText.body(
                    size: 16,
                    weight: FontWeight.w600,
                    height: 1.15,
                    spacing: -0.2,
                    color: ink.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l.betsSlipToday(total == 0 ? '+0' : signed(total)),
                key: const ValueKey('bets-slip-total'),
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w700,
                  height: 1,
                  color: total >= 0 ? betWin(context) : ink.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (all.isEmpty)
            Text(
              l.betsSlipEmpty,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w500,
                height: 1.4,
                color: ink.sub,
              ),
            )
          else
            for (int i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _Row(bet: shown[i], ink: ink),
            ],
          if (foot != null) ...[
            const SizedBox(height: 10),
            Text(
              foot,
              key: const ValueKey('bets-slip-foot'),
              style: AppText.body(
                size: 12,
                weight: FontWeight.w500,
                height: 1.4,
                color: ink.sub,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The line at the foot: how the narrow bets went, or what narrow pays
  /// before there are any; how sure against how right, where bets asked.
  String? _foot(BuildContext context, List<Bet> all) {
    final l = context.l10n;
    final List<Bet> ranges = [
      for (final b in all)
        if (b.kind == 'range') b,
    ];
    final List<Bet> narrow = [
      for (final b in ranges)
        if ((b.facts['w'] as num?)?.toInt() == 0) b,
    ];
    if (narrow.isNotEmpty) {
      final int right = narrow.where((b) => b.facts['hit'] == true).length;
      return l.betsSlipNarrow(right, narrow.length);
    }
    final List<RangeWidth>? w = widths;
    if (w != null && w.length >= 2) {
      final double times = w.first.pays / w.last.pays;
      if (times < 2 || times != times.roundToDouble()) return null;
      return switch (times.round()) {
        2 => l.betsSlipTipTwice,
        3 => l.betsSlipTipThrice,
        final int n => l.betsSlipTipTimes(n),
      };
    }
    final List<Bet> sure = [
      for (final b in all)
        if (b.confidence != null) b,
    ];
    if (sure.length >= 2) {
      final int right = sure.where((b) => b.right).length;
      final int mean = (sure.fold(0, (n, b) => n + b.confidence!) / sure.length)
          .round();
      return l.betsSlipSure(right, sure.length, mean);
    }
    return null;
  }
}

/// One bet on the slip: its name, what was said, what it came to.
class _Row extends StatelessWidget {
  const _Row({required this.bet, required this.ink});

  final Bet bet;
  final BetInk ink;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final Pill? pill = PillBank.byId(bet.pill);
    final String name = pill == null ? bet.pill : slipName(pill);
    final String said = _said(context, n, pill);
    final bool points = bet.kind == 'range' || bet.kind == 'stake';
    final Color good = betWin(context);
    final Widget result = points
        ? Text(
            signed(bet.points),
            textAlign: TextAlign.right,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              height: 1,
              color: bet.points > 0 ? good : ink.sub,
            ),
          )
        : Semantics(
            label: bet.right ? l.betsRight : l.betsWrong,
            child: Icon(
              bet.right ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color: bet.right ? good : ink.sub,
            ),
          );
    return CustomPaint(
      painter: _Dashes(ink.hair),
      child: Padding(
        padding: const EdgeInsets.only(top: 11),
        child: Row(
          key: ValueKey('bets-slip-${bet.kind}-${bet.pill}'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  height: 1.2,
                  color: ink.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                said,
                maxLines: 2,
                textAlign: TextAlign.right,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.2,
                  color: ink.sub,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 34),
              child: Align(alignment: Alignment.centerRight, child: result),
            ),
          ],
        ),
      ),
    );
  }

  /// What was bet, said again in the reader's language.
  String _said(BuildContext context, BetNumbers n, Pill? pill) {
    final l = context.l10n;
    double fact(String k) => (bet.facts[k] as num?)?.toDouble() ?? 0;
    final BetAnswer? a = pill == null ? null : answerOf(pill);
    switch (bet.kind) {
      case 'range':
        return n.range(fact('lo'), fact('hi'));
      case 'stake':
        final int? o = int.tryParse(bet.said);
        final List<String> options = a?.options ?? const [];
        final String picked = o != null && o >= 0 && o < options.length
            ? options[o]
            : bet.said;
        return '$picked · ${(bet.facts['stake'] as num?)?.toInt() ?? 0}';
      case 'number':
        final double v = double.tryParse(bet.said) ?? 0;
        final int places = (bet.facts['places'] as num?)?.toInt() ?? 2;
        final String unit = a?.unit ?? '';
        final String number = n.plain(v, decimals: places);
        return unit.isEmpty ? number : '$number $unit';
      case 'magnitude':
        final double v = fact('value');
        return a != null && a.odds
            ? l.betsOneIn(n.compact(v))
            : '${n.compact(v)} ${a?.unit ?? ''}'.trim();
      case 'day':
        return n.percent(double.tryParse(bet.said) ?? 0);
      case 'closer':
        return l.betsScore(
          (bet.facts['right'] as num?)?.toInt() ?? 0,
          (bet.facts['steps'] as num?)?.toInt() ?? 0,
        );
      case 'bigger':
        return '${n.percent(fact('a'))} · ${n.percent(fact('b'))}';
      default:
        return bet.said;
    }
  }
}

/// The dashed hairline over a row of the slip.
class _Dashes extends CustomPainter {
  const _Dashes(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset((x + 3).clamp(0, size.width), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}

/// The slip on its own, anywhere on Explore: every bet laid today on every
/// shelf of bets. `s` is the day's points and the latest bet, `m` the
/// latest few (`limit`, five by default), `l` all of them.
class BetSlipBlock extends ExploreBlock {
  const BetSlipBlock();

  @override
  String get name => 'bets-slip';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final BetSection shelf = BetSection(section);
    final BetsDay day = BetsDay.instance;
    day.load();
    // An empty slip is an invitation, and worth showing only where there
    // is something to bet on.
    if (day.loaded && day.slip.isEmpty && !_anything(host, shelf)) {
      return null;
    }
    if (!day.loaded && !_anything(host, shelf)) return null;
    final String size = shelf.size(const ['s', 'm', 'l'], 'm');
    final int? most = switch (size) {
      's' => 1,
      'l' => null,
      _ => shelf.limit(5, most: 50),
    };
    final Object? kinds = section.json['kinds'];
    return host.watch(
      section,
      KeyedSubtree(
        key: ValueKey('bets-${section.id}'),
        child: BetSlip(
          most: most,
          title: section.title(host.language),
          kinds: kinds is List ? {for (final k in kinds) '$k'} : null,
        ),
      ),
    );
  }

  bool _anything(ExploreHost host, BetSection shelf) {
    for (final p in host.cardsFor(shelf.section, limit: kBetPool)) {
      if (answerOf(p) != null) return true;
    }
    return false;
  }
}
