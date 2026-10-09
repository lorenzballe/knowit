import 'package:flutter/material.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../../analytics.dart';
import 'parts.dart';

/// Sixty seconds — artboard 140d's round.
///
/// Eight claims, true or false, against a minute: gut, not deliberation,
/// which is the other half of what calibration is about. The eight are the
/// same for everybody today. At the end the score, the time, and every one
/// missed with the line that says why, each a tap from its card.
///
/// The clock is an animation controller rather than a timer: a pending timer
/// outlives a disposed widget, and the round keeps itself alive while it
/// runs, so scrolling past it does not throw it away.
class SixtySeconds extends StatefulWidget {
  const SixtySeconds({
    super.key,
    required this.pills,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  State<SixtySeconds> createState() => _SixtySecondsState();
}

class _SixtySecondsState extends State<SixtySeconds>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const int _seconds = 60;

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _seconds),
  )..addStatusListener(_ticked);

  /// The answers given this round, in order: true for "true".
  List<bool>? _answers;

  /// How long the round took, once it is over.
  double? _took;

  bool get _running => _answers != null && _took == null;

  @override
  bool get wantKeepAlive => _running;

  @override
  void initState() {
    super.initState();
    // A round played earlier today is shown as it ended.
    final Object? kept = ExplorePlay.instance['sixty'];
    if (kept is Map && kept['a'] is List && kept['ids'] is List) {
      final ids = (kept['ids'] as List).cast<Object?>();
      if (ids.length == widget.pills.length &&
          [for (int i = 0; i < ids.length; i++) ids[i] == widget.pills[i].id]
              .every((same) => same)) {
        _answers = [for (final a in kept['a'] as List) a == true];
        _took = (kept['s'] as num?)?.toDouble() ?? _seconds.toDouble();
      }
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _ticked(AnimationStatus status) {
    if (status == AnimationStatus.completed && _running) _finish();
  }

  void _start() {
    setState(() {
      _answers = [];
      _took = null;
    });
    updateKeepAlive();
    _clock.forward(from: 0);
    Analytics.capture('explore sixty started');
  }

  void _answer(bool sayTrue) {
    if (!_running) return;
    setState(() => _answers!.add(sayTrue));
    if (_answers!.length >= widget.pills.length) _finish();
  }

  void _finish() {
    _clock.stop();
    final double took = _clock.value * _seconds;
    setState(() => _took = took);
    updateKeepAlive();
    final int right = _right;
    ExplorePlay.instance.put('sixty', {
      'ids': [for (final p in widget.pills) p.id],
      'a': _answers,
      's': took,
    });
    Analytics.capture('explore sixty finished', {
      'right': right,
      'answered': _answers!.length,
      'seconds': took.round(),
    });
  }

  int get _right {
    int n = 0;
    final answers = _answers ?? const <bool>[];
    for (int i = 0; i < answers.length && i < widget.pills.length; i++) {
      if (answers[i] == trueOrFalseAnswer(widget.pills[i])) n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    for (final p in widget.pills) {
      widget.onShown?.call(p);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _answers == null
            ? _idle(context)
            : _running
            ? _round(context)
            : _end(context),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required Widget child,
    double pad = 22,
  }) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(pad),
    decoration: BoxDecoration(
      color: context.p.ink.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );

  Widget _idle(BuildContext context) {
    final Color ink = context.p.ink;
    return _panel(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_seconds',
                style: AppText.display(
                  size: 76,
                  weight: FontWeight.w600,
                  height: 0.85,
                  spacing: -3,
                  color: ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    context.l10n.sixtySecondsFor,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (int i = 0; i < widget.pills.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.pills[i].color,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          FlatButton(
            key: const ValueKey('sixty-start'),
            label: context.l10n.sixtyStart,
            background: context.p.inverse,
            foreground: context.p.onInverse,
            height: 44,
            size: 14,
            padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
            icon: Icon(
              Icons.play_arrow_rounded,
              size: 18,
              color: context.p.onInverse,
            ),
            onTap: _start,
          ),
        ],
      ),
    );
  }

  Widget _round(BuildContext context) {
    final int at = _answers!.length.clamp(0, widget.pills.length - 1);
    final Pill p = widget.pills[at];
    final l = context.l10n;
    return Container(
      key: const ValueKey('sixty-round'),
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final double left = (1 - _clock.value) * _seconds;
              return Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      l.sixtySecondsLeft(left.ceil()),
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        height: 1,
                        color: p.ink,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(color: fillOn(p)),
                            ),
                            Positioned.fill(
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: (1 - _clock.value).clamp(0, 1),
                                child: ColoredBox(color: p.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.nOfM(at + 1, widget.pills.length),
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      height: 1,
                      color: p.ink,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          CardHead(pill: p),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: CardQuestion(
              key: ValueKey('sixty-claim-${p.id}'),
              text: claimOf(p),
              color: p.ink,
              min: 14,
              max: 23,
              height: 1.12,
              tracking: -0.032,
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FlatButton(
                  key: const ValueKey('sixty-false'),
                  label: l.sayFalse,
                  background: fillOn(p),
                  foreground: p.ink,
                  height: 52,
                  radius: 14,
                  size: 15,
                  expand: true,
                  onTap: () => _answer(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FlatButton(
                  key: const ValueKey('sixty-true'),
                  label: l.sayTrue,
                  background: p.ink,
                  foreground: p.color,
                  height: 52,
                  radius: 14,
                  size: 15,
                  expand: true,
                  onTap: () => _answer(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l.sixtyScore(_right),
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1,
              color: subOn(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _end(BuildContext context) {
    final l = context.l10n;
    final Color ink = context.p.ink;
    final answers = _answers!;
    final int n = widget.pills.length;
    final misses = <int>[
      for (int i = 0; i < n; i++)
        if (i >= answers.length ||
            answers[i] != trueOrFalseAnswer(widget.pills[i]))
          i,
    ];
    final bool allAnswered = answers.length >= n;
    return _panel(
      context,
      pad: 20,
      child: Column(
        key: const ValueKey('sixty-end'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                l.nOfM(_right, n),
                style: AppText.display(
                  size: 46,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -1.5,
                  color: ink,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  allAnswered ? l.sixtyIn((_took ?? 0).round()) : l.sixtyTimeUp,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: ink.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          if (misses.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.sixtyPerfect,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                height: 1.3,
                color: winColor(context),
              ),
            ),
          ],
          for (final int i in misses) ...[
            const SizedBox(height: 12),
            _miss(context, widget.pills[i]),
          ],
          const SizedBox(height: 16),
          FlatButton(
            key: const ValueKey('sixty-again'),
            label: l.sixtyAgain,
            background: context.p.inverse,
            foreground: context.p.onInverse,
            height: 40,
            size: 13,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onTap: _start,
          ),
        ],
      ),
    );
  }

  Widget _miss(BuildContext context, Pill p) {
    final Color ink = context.p.ink;
    final bool truth = trueOrFalseAnswer(p);
    return GestureDetector(
      key: ValueKey('sixty-miss-${p.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpen(widget.pills, p),
      child: Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: ink.withValues(alpha: 0.1))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.color,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                upper(
                  context,
                  truth ? context.l10n.sayTrue : context.l10n.sayFalse,
                ),
                style: AppText.label(
                  size: 10,
                  weight: FontWeight.w700,
                  spacing: 0.8,
                  height: 1,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claimOf(p),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      height: 1.3,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstLines(
                      p.answer.replaceFirst(
                        RegExp(r'^(true|false)[.!]?\s*', caseSensitive: false),
                        '',
                      ),
                      max: 150,
                    ),
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w500,
                      height: 1.35,
                      color: ink.withValues(alpha: 0.55),
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
