import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/topics.dart';
import '../theme.dart';
import '../widgets/ambient.dart';

/// How much of a subject the reader wants.
enum SubjectVerdict { drop, keep, favourite }

/// One of the twelve subjects, with the pill used to show what it is like.
class Subject {
  const Subject({
    required this.key,
    required this.name,
    required this.question,
    required this.answer,
  });

  final String key;
  final String name;
  final String question;
  final String answer;

  Color get color => kTopics[key]!.color;

  Color get ink => kTopics[key]!.ink;
}

/// The twelve subjects the run deals, in the canvas's order.
///
/// `thinking` is deliberately absent: every card that asks something lives
/// there, so it is never on the wheel and never off the deck.
const List<Subject> kSubjects = [
  Subject(
    key: 'science',
    name: 'Science',
    question: 'Why is glass transparent when sand is not?',
    answer:
        'Sand is a jumble of crystals that scatter light at every boundary. '
        'Melt it and the structure becomes uniform, so light passes straight '
        'through.',
  ),
  Subject(
    key: 'space',
    name: 'Space',
    question: 'Why do we only ever see one face of the Moon?',
    answer:
        'The Moon is tidally locked: it turns once per orbit, so the same '
        'hemisphere always faces us. The far side is not dark, it just never '
        'points here.',
  ),
  Subject(
    key: 'psychology',
    name: 'Psychology',
    question: 'Why do you replay embarrassing moments for years?',
    answer:
        'Unfinished business stays open in memory, the Zeigarnik effect. The '
        'brain keeps rehearsing whatever it never got to file away.',
  ),
  Subject(
    key: 'economics',
    name: 'Economics',
    question: 'Why does cinema popcorn cost more than the ticket?',
    answer:
        'Ticket money is split with the studio, concessions are not. The '
        'theatre keeps almost the whole popcorn margin, so the snack pays for '
        'the screen.',
  ),
  Subject(
    key: 'technology',
    name: 'Technology',
    question: 'Why do phone batteries die faster in the cold?',
    answer:
        'Cold slows the ions moving through the electrolyte, so the battery '
        'cannot deliver current. The charge is still there; it comes back '
        'when it warms.',
  ),
  Subject(
    key: 'history',
    name: 'History',
    question: 'Why were medieval bridges covered in shops?',
    answer:
        'The shops paid the rent. Bridge tolls rarely covered maintenance, so '
        'cities leased the deck to traders and let the shops fund the '
        'stonework.',
  ),
  Subject(
    key: 'human_body',
    name: 'Human body',
    question: 'How long does a single red blood cell live?',
    answer:
        'About 120 days, then the spleen takes it apart and recycles the '
        'iron. You replace roughly two million of them every second.',
  ),
  Subject(
    key: 'philosophy',
    name: 'Philosophy',
    question: 'What is the ship of Theseus actually asking?',
    answer:
        'Whether identity lives in the parts or the pattern. Replace every '
        'plank one by one and nothing physical remains, yet the ship never '
        'stopped being itself.',
  ),
  Subject(
    key: 'pop_culture',
    name: 'Pop culture',
    question: 'Why do film trailers all use the same three chords?',
    answer:
        'It is the Inception horn and its descendants: a slow brass swell '
        'over a rising minor third, cheap to license and instantly legible as '
        'dread.',
  ),
  Subject(
    key: 'nature',
    name: 'Nature',
    question: 'How does a tree know when to drop its leaves?',
    answer:
        'Falling light, not falling temperature. Trees measure night length, '
        'and past a threshold they cut the leaf loose at a prepared seam.',
  ),
  Subject(
    key: 'language',
    name: 'Language',
    question: 'What did the word "nice" originally mean?',
    answer:
        'Foolish. It comes from Latin nescius, ignorant, drifted through '
        'precise in the 1600s, and only landed on pleasant in the 1700s.',
  ),
  Subject(
    key: 'weird_facts',
    name: 'Weird facts',
    question: 'Why does Norway have a town that banned clocks?',
    answer:
        'Sommaroy sits in polar daylight for 69 days, and in 2019 the '
        'islanders campaigned to abolish clock time altogether. It was half '
        'stunt, half sincere.',
  ),
];

/// The second and last step of the onboarding: twelve subjects, one at a
/// time, thrown left to drop, right to keep, up to make a favourite.
///
/// A run rather than a grid of checkboxes, because a grid asks the reader to
/// judge twelve things at once and they answer by ticking everything.
class SubjectRunScreen extends StatefulWidget {
  const SubjectRunScreen({super.key, required this.onDone});

  /// Weights for the subjects worth dealing: dropped subjects are absent.
  final ValueChanged<Map<String, double>> onDone;

  @override
  State<SubjectRunScreen> createState() => _SubjectRunScreenState();
}

class _SubjectRunScreenState extends State<SubjectRunScreen> {
  static const double _ground = 0;
  static const Color _bg = Color(0xFF08080A);

  int _i = 0;
  double _dx = 0;
  double _dy = 0;
  bool _dragging = false;
  bool _flipped = false;
  final Map<String, SubjectVerdict> _answers = {};
  final List<String> _history = [];

  bool get _done => _i >= kSubjects.length;

  Subject get _current => kSubjects[math.min(_i, kSubjects.length - 1)];

  List<Subject> get _favourites => kSubjects
      .where((s) => _answers[s.name] == SubjectVerdict.favourite)
      .toList();

  int get _dropped =>
      kSubjects.where((s) => _answers[s.name] == SubjectVerdict.drop).length;

  void _decide(SubjectVerdict verdict) {
    if (_done) return;
    setState(() {
      _answers[_current.name] = verdict;
      _history.add(_current.name);
      _i += 1;
      _dx = 0;
      _dy = 0;
      _flipped = false;
    });
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _answers.remove(_history.removeLast());
      _i = math.max(0, _i - 1);
      _dx = 0;
      _dy = 0;
      _flipped = false;
    });
  }

  void _reset() => setState(() {
    _i = 0;
    _dx = 0;
    _dy = 0;
    _flipped = false;
    _answers.clear();
    _history.clear();
  });

  /// Skips the rest of the run: everything unanswered is kept, which is the
  /// generous reading and the one that leaves a full deck.
  void _skip() {
    for (final Subject s in kSubjects) {
      _answers.putIfAbsent(s.name, () => SubjectVerdict.keep);
    }
    setState(() => _i = kSubjects.length);
  }

  void _finish() {
    final Map<String, double> weights = {};
    for (final Subject s in kSubjects) {
      switch (_answers[s.name]) {
        case SubjectVerdict.favourite:
          weights[s.key] = 2;
        case SubjectVerdict.keep:
          weights[s.key] = 1;
        case SubjectVerdict.drop:
        case null:
          break;
      }
    }
    // A reader who drops everything still has to be dealt something.
    if (weights.isEmpty) {
      for (final Subject s in kSubjects) {
        weights[s.key] = 1;
      }
    }
    widget.onDone(weights);
  }

  void _onDragEnd() {
    final double dx = _dx;
    final double dy = _dy;
    _dragging = false;
    if (dy < -92 && dy.abs() > dx.abs()) {
      _decide(SubjectVerdict.favourite);
    } else if (dx < -92) {
      _decide(SubjectVerdict.drop);
    } else if (dx > 92) {
      _decide(SubjectVerdict.keep);
    } else {
      setState(() {
        _dx = 0;
        _dy = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 130,
            child: Center(child: _Halo(color: _current.color)),
          ),
          const Positioned.fill(child: Bokeh()),
          const Positioned.fill(child: Vignette(ground: _bg)),
          _EdgeGlow(
            up: (-_dy / 140).clamp(_ground, 0.75),
            left: (-_dx / 140).clamp(_ground, 0.75),
            right: (_dx / 140).clamp(_ground, 0.75),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              child: _done ? _buildDone(context) : _buildRun(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRun(BuildContext context) {
    return Column(
      children: [
        _Header(
          index: math.min(_i + 1, kSubjects.length),
          total: kSubjects.length,
          canUndo: _history.isNotEmpty,
          onUndo: _undo,
          onSkip: _skip,
        ),
        const SizedBox(height: 14),
        _ProgressBar(value: _i / kSubjects.length, color: _current.color),
        const SizedBox(height: 26),
        // Fixed, not Expanded: the deck is drawn at one size, and stretching
        // it leaves the card floating over a gap on a taller phone.
        SizedBox(height: 428, child: _buildStack()),
        const SizedBox(height: 4),
        _Slots(favourites: _favourites),
        const SizedBox(height: 10),
        Text(
          '${_favourites.length} of 5 favourites picked',
          style: AppText.body(
            size: 11.5,
            weight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.34),
          ),
        ),
        const Spacer(),
        const SizedBox(height: 16),
        _Choices(
          onDrop: () => _decide(SubjectVerdict.drop),
          onKeep: () => _decide(SubjectVerdict.keep),
          onFavourite: () => _decide(SubjectVerdict.favourite),
        ),
      ],
    );
  }

  Widget _buildStack() {
    final List<Widget> cards = [];
    for (int d = 2; d >= 0; d--) {
      final int at = _i + d;
      if (at >= kSubjects.length) continue;
      final bool top = d == 0;
      cards.add(
        _SubjectCard(
          key: ValueKey(kSubjects[at].name),
          subject: kSubjects[at],
          number: at + 1,
          depth: d,
          isTop: top,
          flipped: top && _flipped,
          dx: top ? _dx : 0,
          dy: top ? _dy : 0,
          dragging: top && _dragging,
          onPanStart: top
              ? () => setState(() {
                  _dragging = true;
                })
              : null,
          onPanUpdate: top
              ? (Offset delta) => setState(() {
                  _dx += delta.dx;
                  _dy += delta.dy;
                })
              : null,
          onPanEnd: top ? _onDragEnd : null,
          onTap: top ? () => setState(() => _flipped = !_flipped) : null,
        ),
      );
    }
    return Stack(children: cards);
  }

  Widget _buildDone(BuildContext context) {
    return _DoneView(
      favourites: _favourites,
      dropped: _dropped,
      answers: _answers,
      onDeal: _finish,
      onAgain: _reset,
    );
  }
}

/// The colour bloom behind the stack, tinted by whichever subject is up.
class _Halo extends StatefulWidget {
  const _Halo({required this.color});

  final Color color;

  @override
  State<_Halo> createState() => _HaloState();
}

class _HaloState extends State<_Halo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget bloom = AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: 430,
      height: 430,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            widget.color.withValues(alpha: 0.44),
            widget.color.withValues(alpha: 0),
          ],
          stops: const [0, 0.68],
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return bloom;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_c.value);
        return Opacity(
          opacity: 0.5 + 0.35 * t,
          child: Transform.scale(scale: 1 + 0.1 * t, child: child),
        );
      },
      child: bloom,
    );
  }
}

/// Light on the edge the card is heading for, so a throw is answered before
/// it lands.
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow({required this.up, required this.left, required this.right});

  final double up;
  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 190,
            child: Opacity(
              opacity: up,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 120,
            child: Opacity(
              opacity: left,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 120,
            child: Opacity(
              opacity: right,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.canUndo,
    required this.onUndo,
    required this.onSkip,
  });

  final int index;
  final int total;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              index.toString().padLeft(2, '0'),
              style: AppText.display(
                size: 26,
                weight: FontWeight.w600,
                spacing: -0.8,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'of $total',
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canUndo ? onUndo : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canUndo ? 1 : 0.28,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // An icon rather than ↺, which Figtree does not carry and
                    // which therefore rendered as an empty box.
                    const Icon(
                      Icons.undo_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Undo',
                      style: AppText.body(
                        size: 13.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSkip,
              child: Text(
                'Skip',
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.34),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 4,
        color: Colors.white.withValues(alpha: 0.10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The five favourite slots, filling as they are picked.
class _Slots extends StatelessWidget {
  const _Slots({required this.favourites});

  final List<Subject> favourites;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < favourites.length
                    ? favourites[i].color
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(11),
              ),
              child: i < favourites.length
                  ? Text(
                      favourites[i].name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 9.5,
                        weight: FontWeight.w600,
                        height: 1.1,
                        spacing: -0.1,
                        color: favourites[i].ink,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.onDrop,
    required this.onKeep,
    required this.onFavourite,
  });

  final VoidCallback onDrop;
  final VoidCallback onKeep;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 10,
          child: _PressButton(
            onTap: onDrop,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Text(
              'Drop',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 10,
          child: _PressButton(
            onTap: onKeep,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Text(
              'Keep',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // The wide one, as drawn: it is the answer the run is really asking
        // for, and the only one with a name long enough to need the room.
        Expanded(
          flex: 13,
          child: _PressButton(
            onTap: onFavourite,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Favourite',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 15,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PressButton extends StatefulWidget {
  const _PressButton({
    required this.onTap,
    required this.decoration,
    required this.child,
    this.height = 56,
  });

  final VoidCallback onTap;
  final BoxDecoration decoration;
  final Widget child;
  final double height;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: widget.height,
          alignment: Alignment.center,
          decoration: widget.decoration,
          child: widget.child,
        ),
      ),
    );
  }
}

/// One subject, face up or turned over.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    super.key,
    required this.subject,
    required this.number,
    required this.depth,
    required this.isTop,
    required this.flipped,
    required this.dx,
    required this.dy,
    required this.dragging,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onTap,
  });

  final Subject subject;
  final int number;
  final int depth;
  final bool isTop;
  final bool flipped;
  final double dx;
  final double dy;
  final bool dragging;
  final VoidCallback? onPanStart;
  final ValueChanged<Offset>? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double throwOpacity = isTop
        ? (1 - math.max(dx.abs(), dy.abs()) / 480).clamp(0, 1)
        : (depth == 1 ? 0.5 : 0.22);

    final Widget card = Container(
      padding: const EdgeInsets.all(26),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: subject.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 58,
            offset: Offset(0, 26),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Opacity(
                    opacity: 0.58,
                    child: Text(
                      'SUBJECT ${number.toString().padLeft(2, '0')}',
                      style: AppText.label(
                        size: 11,
                        spacing: 1.6,
                        color: subject.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Opacity(
                      opacity: 0.72,
                      child: Text(
                        'tap to flip',
                        style: AppText.body(
                          size: 10.5,
                          weight: FontWeight.w600,
                          spacing: 0.4,
                          color: subject.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: flipped ? _back() : _front(),
                ),
              ),
              Opacity(
                opacity: 0.62,
                child: Text(
                  'Up for a favourite · right to keep · left to drop',
                  style: AppText.body(
                    size: 13,
                    height: 1.4,
                    color: subject.ink,
                  ),
                ),
              ),
            ],
          ),
          if (isTop) ..._stamps(),
        ],
      ),
    );

    final Widget positioned = Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 412,
      child: IgnorePointer(
        ignoring: !isTop,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onPanStart: onPanStart == null ? null : (_) => onPanStart!(),
          onPanUpdate: onPanUpdate == null
              ? null
              : (d) => onPanUpdate!(d.delta),
          onPanEnd: onPanEnd == null ? null : (_) => onPanEnd!(),
          onPanCancel: onPanEnd,
          child: AnimatedContainer(
            duration: dragging
                ? Duration.zero
                : const Duration(milliseconds: 440),
            curve: const Cubic(0.3, 1.16, 0.3, 1),
            transform: isTop
                ? (Matrix4.identity()
                    ..translateByDouble(dx, dy, 0, 1)
                    ..rotateZ(dx * 0.032 * math.pi / 180))
                : (Matrix4.identity()
                    ..translateByDouble(0, -depth * 15, 0, 1)
                    ..scaleByDouble(
                      1 - depth * 0.045,
                      1 - depth * 0.045,
                      1,
                      1,
                    )),
            transformAlignment: Alignment.center,
            child: AnimatedOpacity(
              duration: dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              opacity: throwOpacity,
              child: card,
            ),
          ),
        ),
      ),
    );

    return positioned;
  }

  Widget _front() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        subject.name,
        style: AppText.display(
          size: 40,
          weight: FontWeight.w600,
          height: 1.02,
          spacing: -1.3,
          color: subject.ink,
        ),
      ),
      const SizedBox(height: 16),
      Opacity(opacity: 0.2, child: Container(height: 1, color: subject.ink)),
      const SizedBox(height: 16),
      Opacity(
        opacity: 0.6,
        child: Text(
          'A PILL FROM HERE',
          style: AppText.label(size: 10, spacing: 1.5, color: subject.ink),
        ),
      ),
      const SizedBox(height: 7),
      Opacity(
        opacity: 0.94,
        child: Text(
          subject.question,
          style: AppText.body(
            size: 17.5,
            weight: FontWeight.w500,
            height: 1.34,
            color: subject.ink,
          ),
        ),
      ),
    ],
  );

  Widget _back() => Column(
    key: const ValueKey('back'),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Opacity(
        opacity: 0.85,
        child: Text(
          subject.question,
          style: AppText.body(
            size: 15,
            weight: FontWeight.w600,
            height: 1.28,
            color: subject.ink,
          ),
        ),
      ),
      const SizedBox(height: 13),
      Opacity(opacity: 0.2, child: Container(height: 1, color: subject.ink)),
      const SizedBox(height: 13),
      Opacity(
        opacity: 0.95,
        child: Text(
          subject.answer,
          style: AppText.body(size: 15.5, height: 1.44, color: subject.ink),
        ),
      ),
    ],
  );

  List<Widget> _stamps() => [
    Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: Center(
        child: _Stamp(
          label: 'FAVOURITE',
          opacity: (-dy / 100).clamp(0, 1),
          border: Colors.white,
          color: Colors.white,
          angle: 0,
        ),
      ),
    ),
    Positioned(
      left: 0,
      top: 70,
      child: _Stamp(
        label: 'KEEP',
        opacity: (dx / 100).clamp(0, 1),
        border: Colors.white.withValues(alpha: 0.9),
        color: Colors.white,
        angle: -11,
      ),
    ),
    Positioned(
      right: 0,
      top: 70,
      child: _Stamp(
        label: 'DROP',
        opacity: (-dx / 100).clamp(0, 1),
        border: Colors.white.withValues(alpha: 0.75),
        color: Colors.white.withValues(alpha: 0.85),
        angle: 11,
      ),
    ),
  ];
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.opacity,
    required this.border,
    required this.color,
    required this.angle,
  });

  final String label;
  final double opacity;
  final Color border;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 16,
              weight: FontWeight.w700,
              spacing: 1.5,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// What the run produced, and the way into the first five cards.
class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.favourites,
    required this.dropped,
    required this.answers,
    required this.onDeal,
    required this.onAgain,
  });

  final List<Subject> favourites;
  final int dropped;
  final Map<String, SubjectVerdict> answers;
  final VoidCallback onDeal;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'YOUR DECK',
          style: AppText.label(
            size: 11,
            spacing: 1.7,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 11),
        Text(
          '${favourites.length} favourite${favourites.length == 1 ? '' : 's'}, '
          '$dropped dropped.',
          style: AppText.display(
            size: 33,
            weight: FontWeight.w600,
            height: 1.05,
            spacing: -1.1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < kSubjects.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(child: _tick(kSubjects[i])),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final Subject s in favourites)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  s.name,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: s.ink,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Five cards are already written for you',
                style: AppText.body(
                  size: 15.5,
                  weight: FontWeight.w600,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Read them now. We will ask for an account only once you have '
                'a streak worth keeping.',
                style: AppText.body(
                  size: 13.5,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _PressButton(
          onTap: onDeal,
          decoration: BoxDecoration(
            color: const Color(0xFFFF2E9C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5CFF2E9C),
                blurRadius: 34,
                offset: Offset(0, 14),
              ),
            ],
          ),
          height: 58,
          child: Text(
            'Deal my first five',
            style: AppText.body(
              size: 16.5,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAgain,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Run the subjects again',
                style: AppText.body(
                  size: 13.5,
                  weight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.36),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tick(Subject s) {
    final SubjectVerdict? v = answers[s.name];
    final double height = switch (v) {
      SubjectVerdict.favourite => 20,
      SubjectVerdict.keep => 13,
      _ => 6,
    };
    final Color color = switch (v) {
      null => Colors.white.withValues(alpha: 0.10),
      SubjectVerdict.drop => Colors.white.withValues(alpha: 0.16),
      _ => s.color,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
