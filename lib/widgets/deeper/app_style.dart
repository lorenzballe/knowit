/// Go deeper's parts in the app's own language, under the card's coloured
/// head: the ground every screen stands on (black, or paper), each part a
/// raised rounded card like the profile's, its name a small tinted label as
/// a card's subject is, the asking a pill like the app's own, and nothing
/// that moves faster than it needs to.
///
/// The subject's colour is only an echo: in the names, on the cards' edges
/// and in the chips over the two views.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'look.dart';
import 'pieces.dart' show deeperStill;

/// The few colours the parts use, from the app's palette and the subject.
class AppInk {
  AppInk._(this.p, this.accent, this.edge, this.sideA, this.sideB);

  factory AppInk.of(BuildContext context, DeeperLook look) {
    final Palette p = context.p;
    final bool dark = p.isDark;
    final double c = look.pearl ? 0.02 : 0.09;
    Color tint(double l, double chroma, double hue) =>
        Oklch(l, chroma, hue % 360).toColour();
    final Color accent = look.pearl
        ? p.inkMuted
        : dark
        ? tint(0.80, c, look.hue)
        : tint(0.48, c * 1.15, look.hue);
    return AppInk._(
      p,
      accent,
      Color.alphaBlend(accent.withValues(alpha: dark ? 0.16 : 0.2), p.line),
      dark
          ? tint(0.80, c, look.sideA.hue)
          : tint(0.47, c * 1.2, look.sideA.hue),
      dark
          ? tint(0.80, c, look.sideB.hue)
          : tint(0.47, c * 1.2, look.sideB.hue),
    );
  }

  final Palette p;

  /// The subject's colour, quietly: the names and the few marks.
  final Color accent;

  /// A card's edge, the app's hairline with a breath of the subject in it.
  final Color edge;

  /// The two views' own marks.
  final Color sideA;
  final Color sideB;

  /// What sits inside a card: a box to write in, a bubble, a view.
  Color get inset => p.isDark ? const Color(0xFF1A1A1E) : p.surface;
}

/// The words of a part, as the app sets its running text.
TextStyle appBody(BuildContext context) => AppText.body(
  size: 16,
  height: 1.55,
  color: context.p.ink.withValues(alpha: context.p.isDark ? 0.9 : 0.88),
);

/// The idea said simply: in the app's display face, as its cards speak.
TextStyle appSimply(BuildContext context) => AppText.display(
  size: 20,
  weight: FontWeight.w500,
  height: 1.4,
  spacing: -0.2,
  color: context.p.ink,
);

/// A small name in capitals, as a card names its subject.
TextStyle appLabel(Color colour, {double size = 11.5}) => AppText.label(
  size: size,
  weight: FontWeight.w700,
  spacing: 1.4,
  height: 1.3,
  color: colour,
);

/// A part: a raised rounded card, its name a small tinted label, the line
/// on what it gives under it, then what it says.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.look,
    required this.title,
    required this.child,
    this.lead,
    this.badge,
  });

  final DeeperLook look;
  final String title;
  final String? lead;
  final Widget? badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // The one mark of the subject's colour on a part.
                ExcludeSemantics(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: look.pearl ? p.ink : look.world,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title.toUpperCase(),
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w600,
                        spacing: 1.3,
                        height: 1.3,
                        color: p.inkMuted,
                      ),
                    ),
                  ),
                ),
                if (badge case final Widget b) ...[
                  const SizedBox(width: 10),
                  b,
                ],
              ],
            ),
            if (lead case final String said) ...[
              const SizedBox(height: 6),
              Text(
                said,
                style: AppText.body(size: 14, height: 1.45, color: p.inkMuted),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// The two views: each on an inset of its own inside the card, under a
/// small chip in its own colour, the one under the other.
class AppVersus extends StatelessWidget {
  const AppVersus({
    super.key,
    required this.look,
    required this.a,
    required this.b,
  });

  final DeeperLook look;
  final (String, String) a;
  final (String, String)? b;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AppInk ink = AppInk.of(context, look);
    final (String, String)? other = b;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AppView(
          ink: ink,
          chip: other == null ? l.deeperSideB : l.deeperSideA,
          colour: other == null ? ink.sideB : ink.sideA,
          view: a,
        ),
        if (other != null) ...[
          const SizedBox(height: 10),
          _AppView(
            ink: ink,
            chip: l.deeperSideB,
            colour: ink.sideB,
            view: other,
          ),
        ],
      ],
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({
    required this.ink,
    required this.chip,
    required this.colour,
    required this.view,
  });

  final AppInk ink;
  final String chip;
  final Color colour;
  final (String, String) view;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.inset,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chip != view.$1) ...[
              ExcludeSemantics(
                child: Text(
                  chip.toUpperCase(),
                  style: AppText.label(
                    size: 10.5,
                    spacing: 1.3,
                    color: p.inkFaint,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Semantics(
              header: true,
              child: Text(
                view.$1,
                style: AppText.body(
                  size: 16,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              view.$2,
              style: AppText.body(
                size: 15,
                height: 1.5,
                color: p.ink.withValues(alpha: p.isDark ? 0.82 : 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small tinted pill, as the profile marks Astute+.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.colour,
    this.icon,
  });

  final String label;
  final Color colour;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: context.p.isDark ? 0.16 : 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final IconData i) ...[
          Icon(i, size: 12, color: colour),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w600,
              height: 1.2,
              color: colour,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Astute+, beside a part's name on the free plan: the profile's chip.
class AppPlusBadge extends StatelessWidget {
  const AppPlusBadge({super.key});

  @override
  Widget build(BuildContext context) => AppChip(
    label: 'ASTUTE+',
    colour: context.p.link,
    icon: Icons.lock_rounded,
  );
}

/// The button that asks Claude: the app's own pill, its ink reversed, as
/// the tab bar marks where the reader is. While the answer comes it steps
/// back to a quiet pill and a small ring turns slowly beside its words.
class AppAskButton extends StatefulWidget {
  const AppAskButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.locked = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool locked;
  final bool busy;

  @override
  State<AppAskButton> createState() => _AppAskButtonState();
}

class _AppAskButtonState extends State<AppAskButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final bool busy = widget.busy;
    final bool on = widget.onPressed != null && !busy;
    final bool still = deeperStill(context);
    final Duration calm = still
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final Color fill = on
        ? p.inverse
        : p.isDark
        ? const Color(0xFF1E1E22)
        : const Color(0xFFEAE7E0);
    final Color ink = on
        ? p.onInverse
        : busy
        ? p.inkMuted
        : p.inkFaint;
    final Widget mark = busy
        ? SizedBox(
            key: const ValueKey('busy'),
            width: 15,
            height: 15,
            child: still
                ? Icon(Icons.more_horiz_rounded, size: 15, color: ink)
                : CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: ink,
                    backgroundColor: ink.withValues(alpha: 0.18),
                  ),
          )
        : Icon(
            widget.locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
            key: const ValueKey('idle'),
            size: 16,
            color: ink,
          );
    return Semantics(
      button: true,
      enabled: on,
      liveRegion: busy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: on ? (_) => setState(() => _down = true) : null,
        onTapUp: on ? (_) => setState(() => _down = false) : null,
        onTapCancel: on ? () => setState(() => _down = false) : null,
        onTap: on
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _down && on ? 0.97 : 1,
          child: AnimatedContainer(
            duration: calm,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(18, 13, 22, 13),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(duration: calm, child: mark),
                const SizedBox(width: 10),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: calm,
                    child: Text(
                      busy ? context.l10n.deeperBusy : widget.label,
                      key: ValueKey(busy),
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        height: 1.25,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The reader's own words, at the right on an inset, as a sent message is
/// in the app's quiet colours.
class AppReaderBubble extends StatelessWidget {
  const AppReaderBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        alignment: AlignmentDirectional.centerEnd,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF1E1E22) : p.surface,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(18),
                topEnd: Radius.circular(18),
                bottomStart: Radius.circular(18),
                bottomEnd: Radius.circular(6),
              ).resolve(Directionality.of(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
              child: Text(
                text,
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  height: 1.45,
                  color: p.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The foot of the sheet: the source under the app's eyebrow, and the way
/// to the original as a quiet pill.
class AppSource extends StatelessWidget {
  const AppSource({
    super.key,
    required this.look,
    required this.source,
    required this.kind,
    required this.open,
  });

  final DeeperLook look;
  final String source;
  final String? kind;
  final VoidCallback? open;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final String eyebrow = [
      l.deeperSource,
      if (kind case final String k) k,
    ].join('  ·  ').toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: AppText.label(size: 11, spacing: 1.3, color: p.inkFaint),
          ),
          const SizedBox(height: 10),
          Text(
            source,
            style: AppText.display(
              size: 17,
              weight: FontWeight.w500,
              height: 1.38,
              spacing: -0.15,
              color: p.ink,
            ),
          ),
          if (open case final VoidCallback go) ...[
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                button: true,
                link: true,
                child: GestureDetector(
                  key: const ValueKey('deeper-open-source'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    go();
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 11, 16, 11),
                    decoration: BoxDecoration(
                      color: p.surfaceRaised,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l.deeperOpenSource,
                            style: AppText.body(
                              size: 14.5,
                              weight: FontWeight.w600,
                              color: p.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 17,
                          color: p.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
