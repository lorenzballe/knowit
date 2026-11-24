import 'package:flutter/material.dart';

import '../../data/explore_mix.dart';
import '../../l10n/l10n.dart';
import '../../models/pill.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../../analytics.dart';
import 'parts.dart';
import '../card_edge.dart';

/// A round of Sixty seconds, kept and counted the same way wherever it is
/// played — on its shelf ([SixtySeconds]) or on a screen of its own
/// (lib/widgets/explore/sixty_game.dart): the answers given, in order, how
/// long the round took, the day's round kept as it ended (`sixty` in
/// [ExplorePlay]), and the events that say it was started and finished.
class SixtyRound {
  SixtyRound(this.pills);

  /// How long a round lasts.
  static const int seconds = 60;

  /// The claims, in the order they are asked.
  final List<Pill> pills;

  /// The answers given, in order: true for "true". Null before a round.
  List<bool>? answers;

  /// How long the round took, once it is over.
  double? took;

  bool get running => answers != null && took == null;
  bool get over => answers != null && took != null;

  /// The round played earlier today, as it ended, when it was these very
  /// claims: true when there was one.
  bool restore() {
    final Object? kept = ExplorePlay.instance['sixty'];
    if (kept is! Map || kept['a'] is! List || kept['ids'] is! List) {
      return false;
    }
    final ids = (kept['ids'] as List).cast<Object?>();
    if (ids.length != pills.length) return false;
    for (int i = 0; i < ids.length; i++) {
      if (ids[i] != pills[i].id) return false;
    }
    answers = [for (final a in kept['a'] as List) a == true];
    took = (kept['s'] as num?)?.toDouble() ?? seconds.toDouble();
    return true;
  }

  /// A new round, from the first claim.
  void start() {
    answers = [];
    took = null;
    Analytics.capture('explore sixty started');
  }

  /// [sayTrue] said of the claim in front of the reader. True when it was
  /// the last one, and the round is to end.
  bool answer(bool sayTrue) {
    final List<bool>? given = answers;
    if (given == null || took != null) return false;
    given.add(sayTrue);
    return given.length >= pills.length;
  }

  /// The round over after [took] seconds: kept as the day's round, and
  /// said. How many were right.
  int finish(double took) {
    this.took = took;
    final int right = this.right;
    ExplorePlay.instance.put('sixty', {
      'ids': [for (final p in pills) p.id],
      'a': [...?answers],
      's': took,
    });
    Analytics.capture('explore sixty finished', {
      'right': right,
      'answered': answers?.length ?? 0,
      'seconds': took.round(),
    });
    return right;
  }

  /// Whether the claim at [i] was said right; null when it was not
  /// answered before the time ran out.
  bool? rightAt(int i) {
    final List<bool> given = answers ?? const [];
    if (i >= given.length || i >= pills.length) return null;
    return given[i] == trueOrFalseAnswer(pills[i]);
  }

  /// How many were said right.
  int get right {
    int n = 0;
    for (int i = 0; i < pills.length; i++) {
      if (rightAt(i) == true) n++;
    }
    return n;
  }

  /// Whether every claim was answered before the time ran out.
  bool get allAnswered => (answers?.length ?? 0) >= pills.length;

  /// The claims missed: said wrong, or not said at all.
  List<int> get misses => [
    for (int i = 0; i < pills.length; i++)
      if (rightAt(i) != true) i,
  ];
}

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
    this.onFinished,
  });

  final List<Pill> pills;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  /// A round just ended, with how many claims were right: what the record
  /// outside the day is kept from. Not called for a round shown again as it
  /// ended earlier today.
  final ValueChanged<int>? onFinished;

  @override
  State<SixtySeconds> createState() => _SixtySecondsState();
}

class _SixtySecondsState extends State<SixtySeconds>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const int _seconds = SixtyRound.seconds;

  /// The round's minute: a minute whatever the phone says of motion. A
  /// controller left to the platform runs twenty times as fast where motion
  /// is reduced, and the round was over in three seconds.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _seconds),
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_ticked);

  /// The round: what was answered, and how long it took. A round played
  /// earlier today is shown as it ended.
  late final SixtyRound _game = SixtyRound(widget.pills)..restore();

  List<bool>? get _answers => _game.answers;
  double? get _took => _game.took;
  bool get _running => _game.running;

  @override
  bool get wantKeepAlive => _running;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _ticked(AnimationStatus status) {
    if (status == AnimationStatus.completed && _running) _finish();
  }

  void _start() {
    setState(_game.start);
    updateKeepAlive();
    _clock.forward(from: 0);
  }

  void _answer(bool sayTrue) {
    if (!_running) return;
    late final bool last;
    setState(() => last = _game.answer(sayTrue));
    if (last) _finish();
  }

  void _finish() {
    _clock.stop();
    final double took = _clock.value * _seconds;
    late final int right;
    setState(() => right = _game.finish(took));
    updateKeepAlive();
    widget.onFinished?.call(right);
  }

  int get _right => _game.right;

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
      decoration: cardFace(context, p.color, radius: 24),
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
              decoration: cardFace(context, p.color, radius: 7),
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
