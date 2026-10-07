import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import '../models/pill.dart';
import '../theme.dart';
import 'diagram_view.dart';
import 'motion.dart';

/// Everything a card says once it is turned over: the reasoning, the trap,
/// the plain-words retelling and the other side of a debate.
///
/// This lives on its own because it is needed twice — on the back of a card
/// and on the detail screen reached from the archive — and the two drifted
/// apart. The detail screen was showing only `pill.answer`, which on a worked
/// problem is the last line of the solution and on a debate is one side of it.
class RevealBody extends StatefulWidget {
  final Pill pill;

  /// Text colour on whatever this is sitting on: the card's ink on a card,
  /// the app's ink on paper.
  final Color ink;

  /// Panel fill and edge to match.
  final Color wash;
  final Color washEdge;

  /// A worked solution one step at a time, the first time it is turned
  /// over; whole, when it is looked at again from the archive.
  final bool stepByStep;

  const RevealBody({
    super.key,
    required this.pill,
    required this.ink,
    required this.wash,
    required this.washEdge,
    this.stepByStep = false,
  });

  /// The version that sits on the page rather than on a card, so it takes
  /// its colours from the palette in force.
  factory RevealBody.onPage(Pill pill, Palette palette, {Key? key}) =>
      RevealBody(
        key: key,
        pill: pill,
        ink: palette.ink,
        wash: palette.line,
        washEdge: palette.lineStrong,
      );

  @override
  State<RevealBody> createState() => _RevealBodyState();
}

class _RevealBodyState extends State<RevealBody> {
  bool _simplyOpen = false;
  bool _counterOpen = false;

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pill.hasSteps)
          _Steps(
            pill: pill,
            ink: widget.ink,
            stepByStep: widget.stepByStep,
            style: _Type.step(widget.ink, 15),
            gap: 14,
          )
        else
          Text(
            pill.answer,
            style: AppText.body(
              size: 16,
              height: 1.5,
              color: widget.ink.withValues(alpha: 0.92),
            ),
          ),
        // The picture comes right after the words it illustrates, and is
        // drawn while they are being read.
        if (pill.diagram != null) ...[
          const SizedBox(height: 18),
          DiagramView(diagram: pill.diagram!, ink: widget.ink),
        ],
        if (pill.hasSimply) ...[
          const SizedBox(height: 14),
          if (_simplyOpen)
            _Panel(
              label: context.l10n.putSimplyCaps,
              body: pill.simply,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.child_care_rounded,
              label: context.l10n.explainLikeImThree,
              onTap: () => setState(() => _simplyOpen = true),
            ),
        ],
        if (pill.hasCounterpoint) ...[
          const SizedBox(height: 14),
          if (_counterOpen)
            _Panel(
              label: context.l10n.whatTheOtherSideSaysCaps,
              body: pill.counterpoint,
              ink: widget.ink,
              wash: widget.wash,
            )
          else
            _TextAction(
              ink: widget.ink,
              icon: Icons.swap_horiz_rounded,
              label: context.l10n.whatTheOtherSideSays,
              onTap: () => setState(() => _counterOpen = true),
            ),
        ],
        if (pill.asksSomething && pill.trap.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.theTrap(pill.trap),
            style: AppText.body(
              size: 13.5,
              weight: FontWeight.w500,
              height: 1.45,
              color: widget.ink.withValues(alpha: 0.75),
            ),
          ),
        ],
        // One box to end on: what to keep, or the question to ask yourself
        // when the card has nothing to keep — both only on a card that asks
        // for both. Two panels of take-aways read as homework.
        if (pill.showsMove) ...[
          const SizedBox(height: 20),
          _Panel(
            label: context.l10n.barMoveCaps,
            body: pill.barMove,
            ink: widget.ink,
            wash: widget.wash,
          ),
        ],
        if (pill.showsAsk) ...[
          SizedBox(height: pill.showsMove ? 10 : 20),
          _Panel(
            label: context.l10n.askYourselfCaps,
            body: pill.ask,
            ink: widget.ink,
            wash: widget.wash,
          ),
        ],
        const SizedBox(height: 13),
        Text(
          context.l10n.sourceLabel(pill.source),
          style: AppText.body(
            size: 11.5,
            color: widget.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}


/// The type of the reveal, in one place, so what is measured to fit the
/// card is exactly what is then set on it.
abstract final class _Type {
  static TextStyle answer(Color ink, double size) => AppText.body(
    size: size,
    height: 1.48,
    color: ink.withValues(alpha: 0.92),
  );

  static TextStyle step(Color ink, double size) => AppText.body(
    size: size,
    height: 1.45,
    color: ink.withValues(alpha: 0.92),
  );

  static TextStyle question(Color ink, double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.16,
    spacing: -0.3 - size * 0.018,
    color: ink,
  );

  static TextStyle trap(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    height: 1.45,
    color: ink.withValues(alpha: 0.75),
  );

  static TextStyle action(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w500,
    color: ink.withValues(alpha: 0.65),
  );

  static TextStyle panelLabel(Color ink) =>
      AppText.label(size: 10.5, spacing: 1.2, color: ink.withValues(alpha: 0.6));

  static TextStyle panelBody(Color ink, double size) => AppText.body(
    size: size,
    height: 1.45,
    color: ink.withValues(alpha: 0.92),
  );

  /// The line to keep is the one thing on the back set bold: it is what the
  /// card is for, and it should read as the conclusion, not as more text.
  static TextStyle keep(Color ink, double size) => AppText.body(
    size: size,
    weight: FontWeight.w600,
    height: 1.36,
    color: ink,
  );

  static TextStyle source(Color ink, double size) => AppText.body(
    size: size,
    height: 1.35,
    color: ink.withValues(alpha: 0.6),
  );

  static TextStyle nextStep(Color ground) =>
      AppText.body(size: 13.5, weight: FontWeight.w700, color: ground);

  static TextStyle showAll(Color ink) => AppText.body(
    size: 13.5,
    weight: FontWeight.w600,
    color: ink.withValues(alpha: 0.7),
  );
}

/// The solution, one move at a time: the first step is shown, and each tap
/// brings the next one in under it, joined by a line, so a derivation is
/// followed rather than skimmed. "Show all" is there for the reader who
/// would rather see it whole.
class _Steps extends StatefulWidget {
  final Pill pill;
  final Color ink;
  final bool stepByStep;

  /// How each step is set, and the room between one step and the next.
  final TextStyle style;
  final double gap;

  const _Steps({
    super.key,
    required this.pill,
    required this.ink,
    required this.stepByStep,
    required this.style,
    required this.gap,
  });

  /// The room the steps take at [width] with the first [shown] of them out,
  /// and the buttons under them while some are still to come.
  static double heightFor({
    required List<String> steps,
    required int shown,
    required TextStyle style,
    required double gap,
    required double width,
    required _Measure m,
  }) {
    var h = 0.0;
    for (var i = 0; i < shown && i < steps.length; i++) {
      final text = m.height(steps[i], style, width - 38);
      final pad = 1 + (i == shown - 1 ? 0 : gap);
      h += text + pad > 22 ? text + pad : 22;
    }
    if (shown < steps.length) {
      final next = m.size(
        '${m.l10n.nextStep}  ${steps.length}/${steps.length}',
        _Type.nextStep(const Color(0xFF000000)),
      );
      final all = m.size(m.l10n.showAllSteps, _Type.showAll(const Color(0xFF000000)));
      final pill = Size(next.width + 32, next.height + 20);
      h += 14;
      h += pill.width + 14 + all.width <= width
          ? (pill.height > all.height ? pill.height : all.height)
          : pill.height + 8 + all.height;
    }
    return h;
  }

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  late int _shown = widget.stepByStep ? 1 : widget.pill.steps.length;

  @override
  Widget build(BuildContext context) {
    final steps = widget.pill.steps;
    final ink = widget.ink;
    final all = _shown >= steps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _shown && i < steps.length; i++)
          RiseIn(
            key: ValueKey('step-$i'),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == _shown - 1 && !all
                                ? ink
                                : ink.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AppText.label(
                              size: 10.5,
                              spacing: 0,
                              color: i == _shown - 1 && !all
                                  ? widget.pill.color
                                  : ink.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        if (i < _shown - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: ink.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 1,
                        bottom: i == _shown - 1 ? 0 : widget.gap,
                      ),
                      child: Text(steps[i], style: widget.style),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!all) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                button: true,
                child: GestureDetector(
                  key: const ValueKey('next-step'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _shown++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${context.l10n.nextStep}  ${_shown + 1}/${steps.length}',
                      style: _Type.nextStep(widget.pill.color),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  key: const ValueKey('all-steps'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _shown = steps.length),
                  child: Text(
                    context.l10n.showAllSteps,
                    style: _Type.showAll(ink),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A labelled panel — the shape the bar move, a retelling and a counterpoint
/// all take.
class _Panel extends StatelessWidget {
  final String label;
  final String body;
  final Color ink;
  final Color wash;

  /// How the body is set; the page's regular 14 when not given.
  final TextStyle? style;

  /// Drawn a little closer around its words, on a card short of room.
  final bool tight;

  const _Panel({
    required this.label,
    required this.body,
    required this.ink,
    required this.wash,
    this.style,
    this.tight = false,
  });

  static EdgeInsets _padding(bool tight) => tight
      ? const EdgeInsets.fromLTRB(14, 10, 14, 11)
      : const EdgeInsets.fromLTRB(15, 12, 15, 13);
  static double _gap(bool tight) => tight ? 4 : 6;

  static double heightFor(
    String label,
    String body,
    TextStyle style,
    double width,
    _Measure m, {
    bool tight = false,
  }) {
    final pad = _padding(tight);
    return pad.vertical +
        m.height(
          label,
          _Type.panelLabel(const Color(0xFF000000)),
          width - pad.horizontal,
        ) +
        _gap(tight) +
        m.height(body, style, width - pad.horizontal);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: _padding(tight),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _Type.panelLabel(ink)),
          SizedBox(height: _gap(tight)),
          Text(body, style: style ?? _Type.panelBody(ink, 14)),
        ],
      ),
    );
  }
}

/// The closed state of one of those panels: an icon and a line to tap.
class _TextAction extends StatelessWidget {
  final Color ink;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  const _TextAction({
    super.key,
    required this.ink,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 13,
  });

  /// Padded above and below so the line is a target a thumb can find, not
  /// just the height of its letters.
  static const double _pad = 7;

  static double heightFor(String label, double size, double width, _Measure m) {
    final text = m.height(label, _Type.action(const Color(0xFF000000), size), width - 23);
    return 2 * _pad + (text > 16 ? text : 16);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _pad),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(icon, size: 16, color: ink.withValues(alpha: 0.65)),
              ),
              const SizedBox(width: 7),
              Flexible(child: Text(label, style: _Type.action(ink, size))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text measured the way it will be set: same styles, same width, and the
/// reader's own text size.
class _Measure {
  _Measure(BuildContext context)
    : scaler = MediaQuery.textScalerOf(context),
      l10n = context.l10n,
      _base = DefaultTextStyle.of(context),
      _direction = Directionality.of(context);
  final TextScaler scaler;
  final AppLocalizations l10n;

  /// What a [Text] merges its own style onto, which carries the theme's
  /// tracking: measured without it, a line breaks a word later than it is
  /// set and the plan comes up a line short.
  final DefaultTextStyle _base;
  final TextDirection _direction;

  TextPainter _lay(String text, TextStyle style, double width) => TextPainter(
    text: TextSpan(text: text, style: _base.style.merge(style)),
    textDirection: _direction,
    textScaler: scaler,
    textHeightBehavior: _base.textHeightBehavior,
  )..layout(maxWidth: width);

  double height(String text, TextStyle style, double width) {
    final p = _lay(text, style, width);
    final h = p.height;
    p.dispose();
    return h;
  }

  Size size(String text, TextStyle style) {
    final p = _lay(text, style, double.infinity);
    final s = p.size;
    p.dispose();
    return s;
  }
}

/// The sizes one back of a card is set at.
class _Fit {
  const _Fit({
    required this.question,
    required this.questionSize,
    required this.body,
    required this.gap,
    required this.scene,
    this.tucked = false,
    this.scrolls = false,
  });

  /// Whether the question is printed again above the answer. It is the
  /// first thing to go: the reader turned the card over a second ago and
  /// the question was the whole of the front.
  final bool question;
  final double questionSize;

  /// The answer's size; everything smaller follows from it.
  final double body;

  /// The room between blocks, as a share of the full spacing.
  final double gap;

  /// The scene's band, on a card that asked before it played.
  final double scene;

  /// True when the picture — a diagram, a scene — does not fit beside the
  /// words and waits behind a line to tap, taking the answer's place when
  /// it is opened rather than pushing the card's foot off the screen.
  final bool tucked;

  /// True when even the tightest setting does not fit — only at a large
  /// text size — and the back scrolls rather than shrink the reader's type.
  final bool scrolls;

  bool get tight => gap < 1;
  double get step => body - 0.5;
  double get small => (body * 0.84).clamp(12.5, 14.5);
  double get keep => (body * 0.9).clamp(13.5, 15.5);
  double get source => tight ? 10.5 : 11.5;

  _Fit copyWith({
    double? questionSize,
    double? scene,
    bool? tucked,
    bool? scrolls,
  }) => _Fit(
    question: question,
    questionSize: questionSize ?? this.questionSize,
    body: body,
    gap: gap,
    scene: scene ?? this.scene,
    tucked: tucked ?? this.tucked,
    scrolls: scrolls ?? this.scrolls,
  );
}

/// One piece of the back: what it is, and the room it takes. A null child
/// is the give — the space between the reading and the box at the foot.
class _Block {
  const _Block(this.height, [this.child]);
  final double height;
  final Widget? child;
}

/// Everything a card says once it is turned over, set to fit the card.
///
/// The back is one screen, like the front (docs/cards/STILE.md: "Niente
/// scroll"). So rather than a column in a scroll view it is planned: every
/// block is measured at the width it will have, with the reader's text
/// size, and the sizes are chosen to fill the card without running off it.
/// In order of what gives first: the question repeated from the front is
/// dropped, the type steps down within a band that stays comfortable to
/// read, the spacing tightens, and a picture that still does not fit
/// waits behind a line to tap. Whatever room is left goes to the scene,
/// then to the question, then sits between the reading and the box at the
/// foot, which is always at the bottom of the card. Only when none of that
/// fits — a very large text size — does the back scroll, at full size,
/// because shrinking type the reader asked to be large is not fitting it.
class CardReveal extends StatefulWidget {
  final Pill pill;

  /// What the reader committed to, set above everything else, and the room
  /// it takes at a width.
  final Widget? lead;
  final double Function(double width, TextScaler scaler)? leadHeight;

  /// Keeps the source's lines clear of the save and share buttons in the
  /// bottom corner.
  final double cornerRoom;

  /// The scene, on a card that asked first and plays it with the answer.
  final Widget Function(double height)? scene;

  const CardReveal({
    super.key,
    required this.pill,
    this.lead,
    this.leadHeight,
    this.cornerRoom = 0,
    this.scene,
  });

  /// The answer's band. Eighteen is as large as body text reads well at a
  /// phone's width; fourteen is as small as it should go for a reader at
  /// an ordinary text size.
  static const double maxBody = 18;
  static const double minBody = 14;

  /// The question comes back only if the answer can still be set at this.
  static const double minBodyWithQuestion = 15.5;

  /// The scene's band beside the words, and on its own once opened. Below
  /// the least of it a scene's own controls no longer have room.
  static const double sceneMin = 250;
  static const double sceneMax = 270;
  static const double sceneOpenMax = 330;

  @override
  State<CardReveal> createState() => _CardRevealState();
}

/// Called with each block's planned height and the room, when set. For
/// tests and the card camera; null in the app.
@visibleForTesting
void Function(List<double> blocks, double room)? debugRevealBlocks;

class _CardRevealState extends State<CardReveal> {
  bool _simplyOpen = false;
  bool _counterOpen = false;

  /// The tucked picture is out, in the answer's place.
  bool _pictureOpen = false;

  bool get _hasPicture => widget.scene != null || widget.pill.diagram != null;

  List<_Block> _blocks(
    _Fit f,
    double width,
    _Measure m, {
    required bool pictureOpen,
  }) {
    final pill = widget.pill;
    final l10n = m.l10n;
    final ink = pill.ink;
    final g = f.gap;
    final out = <_Block>[_Block(8 * g, SizedBox(height: 8 * g))];
    void gap(double h) => out.add(_Block(h * g, SizedBox(height: h * g)));

    if (widget.lead != null) {
      out.add(
        _Block(
          widget.leadHeight!(width, m.scaler),
          KeyedSubtree(key: const ValueKey('lead'), child: widget.lead!),
        ),
      );
      gap(14);
    }
    if (f.question) {
      final style = _Type.question(ink, f.questionSize);
      out.add(
        _Block(
          m.height(pill.question, style, width),
          Text(pill.question, style: style),
        ),
      );
      gap(14);
    }

    // The picture, inline or behind its line.
    final words = !f.tucked || !pictureOpen;
    final showPicture = !f.tucked || pictureOpen;
    _Block toggle() {
      final String label = pictureOpen
          ? l10n.revealBackToAnswer
          : widget.scene != null
          ? l10n.revealPlayScene
          : l10n.revealSeePicture;
      final IconData icon = pictureOpen
          ? Icons.notes_rounded
          : widget.scene != null
          ? Icons.play_circle_outline_rounded
          : Icons.insert_chart_outlined_rounded;
      return _Block(
        _TextAction.heightFor(label, f.small, width, m),
        _TextAction(
          key: const ValueKey('picture-toggle'),
          ink: ink,
          icon: icon,
          label: label,
          size: f.small,
          onTap: () => setState(() => _pictureOpen = !_pictureOpen),
        ),
      );
    }

    if (widget.scene != null && showPicture) {
      out.add(
        _Block(
          f.scene,
          KeyedSubtree(
            key: const ValueKey('scene'),
            child: widget.scene!(f.scene),
          ),
        ),
      );
      gap(16);
    }
    if (words) {
      if (pill.hasSteps) {
        final style = _Type.step(ink, f.step);
        double at(int shown) => _Steps.heightFor(
          steps: pill.steps,
          shown: shown,
          style: style,
          gap: 12 * g,
          width: width,
          m: m,
        );
        final first = at(1);
        final whole = at(pill.steps.length);
        out.add(
          _Block(
            first > whole ? first : whole,
            _Steps(
              key: const ValueKey('steps'),
              pill: pill,
              ink: ink,
              stepByStep: true,
              style: style,
              gap: 12 * g,
            ),
          ),
        );
      } else {
        final style = _Type.answer(ink, f.body);
        out.add(
          _Block(
            m.height(pill.answer, style, width),
            Text(pill.answer, style: style),
          ),
        );
      }
    }
    if (pill.diagram != null && showPicture) {
      if (words) gap(16);
      out.add(
        _Block(
          DiagramView.heightFor(
            pill.diagram!,
            width,
            m.scaler,
            ink: ink,
            base: m._base.style,
          ),
          DiagramView(
            key: const ValueKey('diagram'),
            diagram: pill.diagram!,
            ink: ink,
          ),
        ),
      );
    }
    if (f.tucked) {
      gap(6);
      out.add(toggle());
    }
    if (words) {
      // The trap belongs to the explanation, so it follows it straight
      // away, before anything the reader can choose to open.
      if (pill.asksSomething && pill.trap.isNotEmpty) {
        gap(12);
        final text = l10n.theTrap(pill.trap);
        final style = _Type.trap(ink, f.small);
        out.add(_Block(m.height(text, style, width), Text(text, style: style)));
      }
      final panelStyle = _Type.panelBody(ink, f.small);
      _Block opener({
        required bool open,
        required String caps,
        required String body,
        required String label,
        required IconData icon,
        required VoidCallback onOpen,
      }) => open
          ? _Block(
              _Panel.heightFor(caps, body, panelStyle, width, m, tight: f.tight),
              _Panel(
                label: caps,
                body: body,
                ink: ink,
                wash: pill.wash,
                style: panelStyle,
                tight: f.tight,
              ),
            )
          : _Block(
              _TextAction.heightFor(label, f.small, width, m),
              _TextAction(
                ink: ink,
                icon: icon,
                label: label,
                size: f.small,
                onTap: onOpen,
              ),
            );
      if (pill.hasSimply) {
        gap(_simplyOpen ? 12 : 6);
        out.add(
          opener(
            open: _simplyOpen,
            caps: l10n.putSimplyCaps,
            body: pill.simply,
            label: l10n.explainLikeImThree,
            icon: Icons.child_care_rounded,
            onOpen: () => setState(() => _simplyOpen = true),
          ),
        );
      }
      if (pill.hasCounterpoint) {
        gap(_counterOpen ? 12 : 6);
        out.add(
          opener(
            open: _counterOpen,
            caps: l10n.whatTheOtherSideSaysCaps,
            body: pill.counterpoint,
            label: l10n.whatTheOtherSideSays,
            icon: Icons.swap_horiz_rounded,
            onOpen: () => setState(() => _counterOpen = true),
          ),
        );
      }
    }

    // The give, then the box the card ends on, pinned to the foot.
    out.add(_Block(16 * g));
    final keep = _Type.keep(ink, f.keep);
    if (pill.showsMove) {
      out.add(
        _Block(
          _Panel.heightFor(
            l10n.barMoveCaps,
            pill.barMove,
            keep,
            width,
            m,
            tight: f.tight,
          ),
          _Panel(
            label: l10n.barMoveCaps,
            body: pill.barMove,
            ink: ink,
            wash: pill.wash,
            style: keep,
            tight: f.tight,
          ),
        ),
      );
    }
    if (pill.showsAsk) {
      if (pill.showsMove) gap(8);
      // Beside a box to keep, the question is the second voice, so it is
      // set as the panel body rather than in bold.
      final style = pill.showsMove ? _Type.panelBody(ink, f.small) : keep;
      out.add(
        _Block(
          _Panel.heightFor(
            l10n.askYourselfCaps,
            pill.ask,
            style,
            width,
            m,
            tight: f.tight,
          ),
          _Panel(
            label: l10n.askYourselfCaps,
            body: pill.ask,
            ink: ink,
            wash: pill.wash,
            style: style,
            tight: f.tight,
          ),
        ),
      );
    }
    gap(10);
    final source = l10n.sourceLabel(pill.source);
    final sourceStyle = _Type.source(ink, f.source);
    out.add(
      _Block(
        m.height(source, sourceStyle, width - widget.cornerRoom),
        Padding(
          padding: EdgeInsets.only(right: widget.cornerRoom),
          child: Text(source, style: sourceStyle),
        ),
      ),
    );
    return out;
  }

  double _total(List<_Block> blocks) =>
      blocks.fold(0.0, (sum, b) => sum + b.height);

  _Fit _choose(double width, double height, _Measure m) {
    final hasScene = widget.scene != null;
    // A point spare, so a rounding in layout never tips a fit over.
    final room = height - 1;
    double need(_Fit f, {bool open = false}) =>
        _total(_blocks(f, width, m, pictureOpen: open));
    // Every state the reader can reach must fit: the steps all out, a panel
    // opened, the picture swapped in. Opening the other side's case may
    // re-plan the card, which is a re-plan, not a scroll.
    bool fits(_Fit f) =>
        need(f) <= room && (!f.tucked || need(f, open: true) <= room);

    _Fit grow(_Fit f) {
      if (hasScene) {
        final open = f.tucked;
        final more = room - need(f, open: open);
        final scene = (f.scene + more).clamp(
          CardReveal.sceneMin,
          open ? CardReveal.sceneOpenMax : CardReveal.sceneMax,
        );
        f = f.copyWith(scene: scene);
      }
      // A short answer leaves room the question can use: it grows toward
      // the size it had on the front, so the back is not a field of colour.
      while (f.question && f.questionSize < 22) {
        final bigger = f.copyWith(questionSize: f.questionSize + 1);
        if (!fits(bigger)) break;
        f = bigger;
      }
      return f;
    }

    _Fit at(
      double body, {
      required bool question,
      double gap = 1,
      bool tucked = false,
    }) => _Fit(
      question: question,
      questionSize: 17,
      body: body,
      gap: gap,
      scene: CardReveal.sceneMin,
      tucked: tucked,
    );

    Iterable<double> band(double from, double to) sync* {
      for (var b = from; b >= to - 0.01; b -= 0.5) {
        yield b;
      }
    }

    // A picture beside its words first; tucked away only when the words
    // would otherwise go below a comfortable size.
    for (final tucked in [false, if (_hasPicture) true]) {
      for (final b in band(CardReveal.maxBody, CardReveal.minBodyWithQuestion)) {
        final f = at(b, question: true, tucked: tucked);
        if (fits(f)) return grow(f);
      }
      for (final b in band(CardReveal.maxBody, CardReveal.minBody + 0.5)) {
        final f = at(b, question: false, tucked: tucked);
        if (fits(f)) return grow(f);
      }
      for (final b in band(15, CardReveal.minBody)) {
        final f = at(b, question: false, gap: 0.75, tucked: tucked);
        if (fits(f)) return grow(f);
      }
    }
    return at(
      CardReveal.minBody,
      question: false,
      gap: 0.75,
      tucked: _hasPicture,
    ).copyWith(scrolls: true);
  }

  @override
  Widget build(BuildContext context) {
    final m = _Measure(context);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final fit = _choose(width, box.maxHeight, m);
        final blocks = _blocks(
          fit,
          width,
          m,
          pictureOpen: fit.tucked && _pictureOpen,
        );
        debugRevealBlocks?.call([
          for (final b in blocks) b.height,
        ], box.maxHeight);
        final children = [
          for (final b in blocks)
            if (b.child != null)
              b.child!
            else if (fit.scrolls)
              SizedBox(height: b.height)
            else
              Expanded(child: SizedBox(height: b.height)),
        ];
        if (!fit.scrolls) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        }
        return SingleChildScrollView(
          child: Padding(
            // Room to scroll the last line clear of the buttons in the
            // corner.
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
