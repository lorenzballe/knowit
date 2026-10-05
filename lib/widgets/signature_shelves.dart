import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/themed_shelves.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../theme.dart';
import 'scaled_text.dart';
import 'subject_icon.dart';

/// The cards of Explore's always-on shelves, one drawing per kind of shelf
/// (design 132, "one signature per kind"): the figure itself for a number
/// that surprises, two halves for a debate, a sun about to set for something
/// to try before tonight. Each graphic is a darker tone of the card's own
/// colour, so it never fights the text.

/// The card's colour, a few steps darker: the tone every signature is
/// drawn in.
Color _deeper(Color c, [double by = 0.14]) => Color.lerp(c, Colors.black, by)!;

/// A horizontal shelf of signature cards.
class SignatureRow extends StatelessWidget {
  const SignatureRow({
    super.key,
    required this.shelf,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final ThemedShelf shelf;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  @override
  Widget build(BuildContext context) {
    final (double h, double w) = switch (shelf.theme) {
      ShelfTheme.numbers => (210.0, 206.0),
      ShelfTheme.debates => (226.0, 300.0),
      _ => (184.0, 268.0),
    };
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        itemCount: shelf.pills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pill = shelf.pills[i];
          onShown?.call(pill);
          return GestureDetector(
            key: ValueKey('explore-${pill.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onOpen(shelf.pills, pill),
            child: SizedBox(
              width: w,
              child: switch (shelf.theme) {
                ShelfTheme.numbers => _NumberCard(
                  pill: pill,
                  read: isRead(pill),
                ),
                ShelfTheme.debates => _SideCard(pill: pill, read: isRead(pill)),
                _ => _TryCard(pill: pill, read: isRead(pill)),
              },
            ),
          );
        },
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.ink});
  final Color ink;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.readMark,
    child: Icon(
      Icons.check_circle_rounded,
      size: 15,
      color: ink.withValues(alpha: 0.8),
    ),
  );
}

/// Numbers that surprise: the figure, as big as the card allows, then the
/// question it belongs to.
class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.pill, required this.read});
  final Pill pill;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final figure = shelfFigure(pill) ?? '?';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: pill.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      figure,
                      maxLines: 1,
                      style: AppText.display(
                        size: 72,
                        weight: FontWeight.w800,
                        height: 1,
                        spacing: -3,
                        color: _deeper(pill.color, 0.42),
                      ),
                    ),
                  ),
                ),
                if (read) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _Tick(ink: pill.ink),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ScaledText(
              text: pill.question,
              min: 10.5,
              max: 15,
              alignment: Alignment.bottomLeft,
              styleFor: (size) => AppText.display(
                size: size,
                weight: FontWeight.w600,
                height: 1.15,
                spacing: -0.4 * size / 15,
                color: pill.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick a side: the card split down the middle in two tones, the question
/// across both, and the two sides at the foot with "or" between them.
class _SideCard extends StatelessWidget {
  const _SideCard({required this.pill, required this.read});
  final Pill pill;
  final bool read;

  /// "Yes, require the record" reads as Yes on a button: the word before the
  /// comma when there is one and it is short, the whole side otherwise.
  static String _short(String side) {
    final head = side.split(',').first.trim();
    return head.length <= 14 ? head : side;
  }

  @override
  Widget build(BuildContext context) {
    final positions = switch (pill.challenge) {
      TakeASide(:final positions) => positions,
      _ => const <String>[],
    };
    final deep = _deeper(pill.color);
    Widget side(String label) => Expanded(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: pill.ink.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _short(label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            size: 14,
            weight: FontWeight.w700,
            color: pill.ink,
          ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: pill.color,
        child: Stack(
          children: [
            // The two halves.
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 150,
              child: ColoredBox(color: deep),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
                      const SizedBox(width: 7),
                      Text(
                        pill.topic.toUpperCase(),
                        style: AppText.label(
                          size: 10,
                          spacing: 1.6,
                          color: pill.ink.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      if (read) _Tick(ink: pill.ink),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ScaledText(
                      text: pill.question,
                      min: 13,
                      max: 20,
                      alignment: Alignment.topLeft,
                      styleFor: (size) => AppText.display(
                        size: size,
                        weight: FontWeight.w600,
                        height: 1.12,
                        spacing: -0.4 * size / 15,
                        color: pill.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (positions.length >= 2)
                    Row(
                      children: [
                        side(positions[0]),
                        Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: pill.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            context.l10n.sideOr,
                            style: AppText.display(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: pill.color,
                            ),
                          ),
                        ),
                        side(positions[1]),
                      ],
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

/// Use it today: the question, a sun going down behind it in the corner,
/// and a foot that says when and how long.
class _TryCard extends StatelessWidget {
  const _TryCard({required this.pill, required this.read});
  final Pill pill;
  final bool read;

  /// About how long the card takes to read and try, at a reading pace.
  static int minutes(Pill p) {
    final words = '${p.question} ${p.answer}'.split(RegExp(r'\s+')).length;
    return (words / 60).ceil().clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final soft = pill.ink.withValues(alpha: 0.82);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: pill.color,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SunsetPainter(_deeper(pill.color, 0.1)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SubjectIcon(
                              subject: pill.topic,
                              size: 15,
                              ink: pill.ink,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                pill.topic.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.label(
                                  size: 10,
                                  spacing: 1.6,
                                  color: pill.ink.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (read) _Tick(ink: pill.ink),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ScaledText(
                            text: pill.question,
                            min: 11.5,
                            max: 17,
                            alignment: Alignment.topLeft,
                            styleFor: (size) => AppText.display(
                              size: size,
                              weight: FontWeight.w600,
                              height: 1.14,
                              spacing: -0.4 * size / 15,
                              color: pill.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 1, color: pill.ink.withValues(alpha: 0.18)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 11, 18, 12),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.tryToday,
                        style: AppText.label(
                          size: 10.5,
                          spacing: 1.8,
                          color: soft,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.minutesShort(minutes(pill)),
                        style: AppText.label(
                          size: 10.5,
                          spacing: 1.8,
                          color: soft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A sun half under the horizon, low in the right-hand corner.
class _SunsetPainter extends CustomPainter {
  _SunsetPainter(this.tone);
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height * 0.62;
    final c = Offset(size.width * 0.78, size.height - 44 + r * 0.35);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height - 44));
    canvas.drawCircle(c, r, Paint()..color = tone);
    // Two thin rays, so it reads as a sun and not a stain.
    final ray = Paint()
      ..color = tone
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final a in [-2.2, -1.57, -0.95]) {
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (r + 8), c + d * (r + 18), ray);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunsetPainter old) => old.tone != tone;
}
