/// Your number (139c): a number set with steppers, locked, and how far off
/// it was.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bet_host.dart';
import 'bets_day.dart';
import 'block.dart';
import 'deal.dart';
import 'parts.dart';

/// The block: a row of numbers to set and lock.
class NumberBlock extends BetBlock {
  const NumberBlock();

  @override
  String get name => 'bets-number';

  @override
  int get defaultLimit => 3;

  /// A count, a temperature, a length the card has the reader type: set
  /// here on steppers, kept as typed. Not a share, which a track sets
  /// better, and not one the steppers cannot reach.
  @override
  bool fits(BetAnswer a) =>
      a.kind == BetAnswerKind.typed && !a.share && StepScale.around(a) != null;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsNumberTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.betsNumberLine;

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    final BetTileSize size = sizeOf(shelf);
    return BetTiles(
      size: size,
      count: cards.length,
      onSeen: (i) => host.seen(shelf.section, cards[i].pill),
      builder: (context, i) => NumberTile(
        key: ValueKey('bets-number-${cards[i].pill.id}'),
        host: host,
        shelf: shelf,
        answer: cards[i],
        cards: cards,
        size: size,
      ),
    );
  }
}

/// A round number at or above [v]: 1, 2, 2.5 or 5 of a power of ten.
double niceAbove(double v) {
  if (v <= 0) return 1;
  final double p = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final double k in const [1, 2, 2.5, 5, 10]) {
    if (k * p >= v - 1e-9) return k * p;
  }
  return 10 * p;
}

/// One number to set.
class NumberTile extends StatelessWidget {
  const NumberTile({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.cards,
    required this.size,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;
  final List<BetAnswer> cards;
  final BetTileSize size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pill = answer.pill;
    final BetsDay day = BetsDay.instance;
    final BetInk ink = BetInk.of(context, pill, shelf.tone());
    final BetNumbers n = BetNumbers(
      Localizations.localeOf(context).languageCode,
    );
    final StepScale scale = StepScale.around(answer)!;
    final String key = BetsDay.draftKey('number', pill.id);
    final Bet? bet = day.betOn('number', pill.id);
    final bool elsewhere = bet == null && host.app.answerFor(pill.id) != null;
    final Map draft = day.draft(key) is Map ? day.draft(key) as Map : const {};
    final double v = bet != null
        ? double.tryParse(bet.said) ?? scale.start
        : (draft['v'] as num?)?.toDouble() ?? scale.start;
    final bool laid = bet != null;
    final bool pending = !laid && !elsewhere && draft['p'] == true;
    final bool open = !laid && !elsewhere && !pending;
    final String unit = answer.unit;
    final double inner = size.inner(MediaQuery.sizeOf(context).width);
    String say(double x) => n.plain(x, decimals: scale.decimals);

    // Where the number is this moment: a held stepper steps more than once
    // between two frames, and each step goes on from the one before.
    double now() {
      final Object? kept = day.draft(key);
      final Object? at = kept is Map ? kept['v'] : null;
      return at is num ? at.toDouble() : v;
    }

    String amount(double x) => unit.isEmpty ? say(x) : '${say(x)} $unit';

    Future<void> lay(int? sure) async {
      final String response = plainResponse(v);
      await layBet(
        host,
        shelf.section,
        Bet(
          kind: 'number',
          section: shelf.id,
          pill: pill.id,
          said: response,
          right: answer.accepts(response),
          confidence: sure,
          facts: {'places': scale.decimals, 'off': (v - answer.value).abs()},
          at: DateTime.now().millisecondsSinceEpoch,
        ),
        pill: pill,
        response: response,
      );
    }

    void lock() {
      BetFeel.lay();
      if (shelf.asksSure) {
        day.keepDraft(key, {'v': v, 'p': true});
      } else {
        lay(null);
      }
    }

    Widget steppers({bool ghost = false}) => Row(
      children: [
        for (final double by in [
          -scale.big,
          -scale.small,
          scale.small,
          scale.big,
        ]) ...[
          Expanded(
            child: _Stepper(
              key: ghost ? null : ValueKey('bets-number-${pill.id}-$by'),
              label: '${by < 0 ? '−' : '+'}${say(by.abs())}',
              ink: ink,
              enabled: open && !ghost && (by > 0 || v > 0),
              onStep: () => day.keepDraft(key, {'v': scale.move(now(), by)}),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          flex: 13,
          child: BetChip(
            key: ghost ? null : ValueKey('bets-number-lock-${pill.id}'),
            label: l.betsLock,
            ink: ink,
            on: true,
            height: 40,
            radius: 12,
            size: 13,
            onTap: open && !ghost ? lock : null,
          ),
        ),
      ],
    );

    Widget settled({bool ghost = false, double? at, int? sure}) {
      final double you = at ?? v;
      final String response = plainResponse(you);
      final double off = (you - answer.value).abs();
      final bool right = answer.accepts(response);
      final String verdict = right && off < 1e-9
          ? l.betsSpotOn
          : right
          ? l.betsCloseEnough(amount(off))
          : l.betsOffBy(amount(off));
      final int? s = sure ?? bet?.confidence;
      final double top = niceAbove(math.max(you, answer.value) / 0.8);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
            child: CustomPaint(
              painter: _Scale(
                ink: ink,
                you: top == 0 ? 0 : you / top,
                answer: top == 0 ? 0 : answer.value / top,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Legend(
            ink: ink,
            from: say(0),
            to: unit.length <= 12 ? amount(top) : say(top),
          ),
          const SizedBox(height: 10),
          BetVerdict(
            s == null ? verdict : '$verdict ${l.betsYouWereSure(s)}',
            key: ghost ? null : ValueKey('bets-number-said-${pill.id}'),
            ink: ink,
          ),
          BetWhy(pill, ink: ink),
        ],
      );
    }

    Widget sureStep({bool ghost = false}) => SureStep(
      key: ghost ? null : ValueKey('bets-number-sure-${pill.id}'),
      pill: pill,
      ink: ink,
      width: inner,
      onPick: ghost ? (_) {} : (s) => lay(s),
    );

    Widget game(Widget foot) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: open,
          label: l.betsNumberTitle,
          value: amount(v),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  say(v),
                  style: AppText.display(
                    size: 46,
                    weight: FontWeight.w600,
                    height: 1,
                    spacing: -1.6,
                    color: ink.ink,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      unit,
                      maxLines: 2,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.15,
                        color: ink.sub,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        foot,
      ],
    );

    final Widget foot = laid
        ? settled()
        : pending
        ? sureStep()
        : elsewhere
        ? Text(
            l.betsAnsweredAlready,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              color: ink.sub,
            ),
          )
        : steppers();
    // The longest a verdict can come to: off by about the answer itself.
    final double far = answer.value * 4 + scale.big * 7;
    return BetFrame(
      pill: pill,
      ink: ink,
      size: size,
      read: host.isRead(pill),
      onOpen: laid || elsewhere
          ? () =>
                host.open(shelf.section, [for (final c in cards) c.pill], pill)
          : null,
      game: BetRoom(
        keep: size.inRow,
        ghosts: [
          if (!laid) ...[
            game(settled(ghost: true, at: far, sure: 90)),
            if (shelf.asksSure) game(sureStep(ghost: true)),
          ],
        ],
        child: game(foot),
      ),
    );
  }
}

/// A stepper: a tap moves the number a step; held, it keeps stepping,
/// faster the longer it is held, with a click at every step.
class _Stepper extends StatefulWidget {
  const _Stepper({
    super.key,
    required this.label,
    required this.ink,
    required this.enabled,
    required this.onStep,
  });

  final String label;
  final BetInk ink;
  final bool enabled;
  final VoidCallback onStep;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  Timer? _held;
  int _steps = 0;

  void _step() {
    BetFeel.tick();
    widget.onStep();
  }

  void _hold() {
    _steps = 0;
    _held?.cancel();
    _held = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted || !widget.enabled) {
        t.cancel();
        return;
      }
      _steps++;
      // Slow at first, so a hold that meant a tap moves one more step at
      // most; then every tick.
      if (_steps < 5 && _steps.isOdd) return;
      _step();
    });
  }

  void _let() {
    _held?.cancel();
    _held = null;
  }

  @override
  void dispose() {
    _held?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.enabled ? (_) => _hold() : null,
      onLongPressEnd: widget.enabled ? (_) => _let() : null,
      onLongPressCancel: _let,
      child: BetChip(
        label: widget.label,
        ink: widget.ink,
        dim: !widget.enabled,
        height: 40,
        radius: 12,
        size: 13,
        padding: 2,
        onTap: widget.enabled ? _step : null,
      ),
    );
  }
}

/// The scale once a number is locked: a line from nought, the answer as a
/// bar on it, the reader's number as a ring.
class _Scale extends CustomPainter {
  const _Scale({required this.ink, required this.you, required this.answer});

  final BetInk ink;

  /// Where each sits, from 0 to 1 along the line.
  final double you;
  final double answer;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width - 16;
    double x(double t) => 8 + w * t.clamp(0, 1);
    canvas.drawRect(
      Rect.fromLTWH(0, 11, size.width, 2),
      Paint()..color = ink.hair,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(answer) - 2,
        2,
        x(answer) + 2,
        22,
        const Radius.circular(2),
      ),
      Paint()..color = ink.ink,
    );
    canvas.drawCircle(Offset(x(you), 12), 7, Paint()..color = ink.ground);
    canvas.drawCircle(
      Offset(x(you), 12),
      5.5,
      Paint()
        ..color = ink.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_Scale old) =>
      old.you != you || old.answer != answer || old.ink.ink != ink.ink;
}

/// Under the scale: where it starts, what the marks are, where it ends.
class _Legend extends StatelessWidget {
  const _Legend({required this.ink, required this.from, required this.to});

  final BetInk ink;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final TextStyle style = AppText.body(
      size: 10,
      weight: FontWeight.w600,
      height: 1.2,
      color: ink.sub,
    );
    final Widget marks = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink.sub, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(l.betsYou, style: style),
        Text('  ·  ', style: style),
        Container(
          width: 3,
          height: 9,
          decoration: BoxDecoration(
            color: ink.sub,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 4),
        Text(l.betsAnswer, style: style),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(from, style: style),
        const SizedBox(width: 8),
        Expanded(child: Center(child: marks)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(to, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }
}
