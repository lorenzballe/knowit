import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/reader_profile.dart' show kMostLoved;
import '../data/subject_icons.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/fit_text.dart';
import 'mix_screen.dart';

/// The first run's last question, after Your mix: up to three subjects the
/// reader loves.
///
/// Everything before it is asked in the negative — the mix starts all the
/// way in and the reader turns things down — and a tester said what was
/// missing: "pick the three you love" gives better cards on the first day
/// and makes the app feel yours. So it is asked in the positive, of the
/// subjects still in the mix, in the mix's own order and colours: a tap
/// lights a subject and numbers it, a second tap lets it go, and three is
/// the most. None is an answer too: the button is there from the start.
///
/// What it does is said under the title, and is so: the first three days
/// open on these subjects, a card of each every day (lib/data/
/// first_days.dart), and the reader's own cards lean to them after
/// (AppState.leanedWeights).
class LovesScreen extends StatefulWidget {
  const LovesScreen({super.key, required this.mix, required this.onDone});

  /// The mix just set, by topic key: the subjects in it are the ones to
  /// pick from. Empty is every subject.
  final Map<String, double> mix;

  /// The subjects picked, by topic key, in the order they were picked.
  final ValueChanged<List<String>> onDone;

  @override
  State<LovesScreen> createState() => _LovesScreenState();
}

class _LovesScreenState extends State<LovesScreen> {
  /// The subjects the reader can pick: those in the mix, in its order.
  late final List<MixSubject> _subjects = [
    for (final MixSubject s in kMixSubjects)
      if (widget.mix.isEmpty || (widget.mix[s.key] ?? 0) > 0) s,
  ];

  /// What is picked, in the order it was.
  final List<String> _picked = [];

  /// True for a moment after a fourth subject was tapped: the line under
  /// the grid says three is the most.
  bool _full = false;
  Timer? _fullTimer;

  @override
  void dispose() {
    _fullTimer?.cancel();
    super.dispose();
  }

  void _tap(MixSubject subject) {
    if (_picked.contains(subject.key)) {
      HapticFeedback.selectionClick();
      setState(() {
        _picked.remove(subject.key);
        _full = false;
      });
      return;
    }
    if (_picked.length >= kMostLoved) {
      HapticFeedback.lightImpact();
      _fullTimer?.cancel();
      setState(() => _full = true);
      _fullTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _full = false);
      });
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _picked.add(subject.key));
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    // As on Your mix: one screen up to a little past the default text size,
    // the rows sharing what the heading and the button leave; larger, a
    // page that scrolls, the tiles the height their names need.
    final bool large = MediaQuery.textScalerOf(context).scale(10) > 11.5;
    return Scaffold(
      key: const ValueKey('loves-page'),
      backgroundColor: Colors.black,
      body: large
          ? LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: _page(context, safe, scrolls: true),
                ),
              ),
            )
          : _page(context, safe, scrolls: false),
    );
  }

  Widget _page(BuildContext context, EdgeInsets safe, {required bool scrolls}) {
    final l = context.l10n;
    final Widget top = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.lovesTitle,
          style: AppText.display(
            size: 30,
            weight: FontWeight.w600,
            height: 1.04,
            spacing: -1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l.lovesLine,
          style: AppText.body(
            size: 13.5,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.48),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
    final Widget bottom = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _full ? l.lovesFull : l.lovesCount(_picked.length),
            key: ValueKey(_full ? 'full' : 'count-${_picked.length}'),
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w500,
              color: Colors.white.withValues(alpha: _full ? 0.78 : 0.38),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FirstRunButton(
          key: const ValueKey('loves-done'),
          label: l.startReading,
          onTap: () => widget.onDone(List.of(_picked)),
        ),
      ],
    );
    final Widget grid = _LoveGrid(
      subjects: _subjects,
      picked: _picked,
      onTap: _tap,
      fixed: scrolls,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        safe.top > 14 ? safe.top : 14,
        18,
        22 + (safe.bottom > 34 ? safe.bottom - 34 : 0),
      ),
      child: scrolls
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [top, grid],
                ),
                bottom,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                top,
                Expanded(child: grid),
                bottom,
              ],
            ),
    );
  }
}

class _LoveGrid extends StatelessWidget {
  const _LoveGrid({
    required this.subjects,
    required this.picked,
    required this.onTap,
    required this.fixed,
  });

  final List<MixSubject> subjects;
  final List<String> picked;
  final ValueChanged<MixSubject> onTap;

  /// Rows of their own height, on a page that scrolls.
  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final int columns = fixed && scaler.scale(10) > 14 ? 1 : 2;
    final int rows = (subjects.length / columns).ceil();
    final double height = scaler.scale(13.5) * 1.1 + 22;
    // A grid of few subjects keeps the height of a full one's rows rather
    // than stretching three tiles over the screen.
    final int slots = (kMixSubjects.length / columns).ceil();
    // Stretched: each tile is its row's whole height, as on Your mix.
    Widget row(int r) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int c = 0; c < columns; c++) ...[
          if (c > 0) const SizedBox(width: 8),
          Expanded(
            child: r * columns + c < subjects.length
                ? _LoveTile(
                    key: ValueKey('love-${subjects[r * columns + c].key}'),
                    subject: subjects[r * columns + c],
                    order: picked.indexOf(subjects[r * columns + c].key) + 1,
                    onTap: () => onTap(subjects[r * columns + c]),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
    if (fixed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: 8),
            SizedBox(height: height, child: row(r)),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final double each = (box.maxHeight - 8 * (slots - 1)) / slots;
        return Column(
          children: [
            for (int r = 0; r < rows; r++) ...[
              if (r > 0) const SizedBox(height: 8),
              SizedBox(height: each, child: row(r)),
            ],
          ],
        );
      },
    );
  }
}

/// One subject: dark until picked, then in its own colour with its number.
class _LoveTile extends StatelessWidget {
  const _LoveTile({
    super.key,
    required this.subject,
    required this.order,
    required this.onTap,
  });

  final MixSubject subject;

  /// 1 to 3 in the order it was picked; 0 while it is not.
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool on = order > 0;
    final bool pale = kPaleSubjects.contains(subject.name);
    final Color ink = on && pale ? const Color(0xFF10100C) : Colors.white;
    return Semantics(
      button: true,
      selected: on,
      label: context.l10n.subjectOf(subject.name),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: on
                ? subject.color
                : Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.055),
                    Colors.black,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: subject.color.withValues(alpha: 0.27),
                      blurRadius: 22,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: on ? 0.92 : 0.6,
                child: SizedBox(
                  width: 17,
                  height: 17,
                  // In the tile's own ink: a pale subject's mark is drawn
                  // dark for its own fill, and would vanish on the dark.
                  child: SvgPicture.string(
                    subjectIconSvg(subject.name),
                    colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FitText(
                  context.l10n.subjectOf(subject.name),
                  maxLines: 1,
                  minSize: 10,
                  style: AppText.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    height: 1.1,
                    spacing: -0.3,
                    color: ink.withValues(alpha: on ? 0.95 : 0.82),
                  ),
                ),
              ),
              // Its place among the three, in a dark round: the order is
              // the reader's, and the first of them opens the first day.
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: on ? 1 : 0,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    on ? '$order' : '',
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w700,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
