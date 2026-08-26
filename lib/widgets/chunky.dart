import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Buttons with a thickness to them.
///
/// A flat rectangle that changes opacity when you touch it is the cheapest
/// possible answer to "what happens when I press this". A face sitting on a
/// darker edge, which compresses under the finger and springs back, is the
/// thing that makes an app feel built rather than laid out — and it costs one
/// widget.

/// The edge under a face, derived rather than hand-picked, so any brand
/// colour dropped in gets a matching one.
Color chunkyEdge(Color face, [double amount = 0.16]) {
  final hsl = HSLColor.fromColor(face);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// How deep every chunky surface sits. One number, so nothing drifts.
const double kChunkDepth = 4.5;

class ChunkyButton extends StatefulWidget {
  final String label;
  final Color fill;
  final Color ink;

  /// Defaults to a darkened [fill].
  final Color? edge;
  final VoidCallback? onPressed;
  final double height;
  final double radius;

  /// Leading widget, sized and coloured by the caller.
  final Widget? leading;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.fill,
    required this.ink,
    this.edge,
    this.onPressed,
    this.height = 56,
    this.radius = 16,
    this.leading,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final fill = _enabled ? widget.fill : context.p.line;
    final ink = _enabled ? widget.ink : context.p.inkFaint;
    final edge = _enabled
        ? (widget.edge ?? chunkyEdge(widget.fill))
        : chunkyEdge(context.p.line, 0.06);
    final pressed = _down && _enabled;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          height: widget.height,
          decoration: BoxDecoration(
            color: edge,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          // Total height never changes; the face slides down into the edge,
          // so the button compresses instead of moving.
          padding: EdgeInsets.only(
            top: pressed ? kChunkDepth : 0,
            bottom: pressed ? 0 : kChunkDepth,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 9),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w700,
                      spacing: 0.6,
                      color: ink,
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

/// What an answer choice is currently saying about itself.
enum ChoiceState { idle, picked, right, wrong }

/// One tappable answer. Same thickness as the buttons, so a card of options
/// reads as a set of physical things rather than a list of rows.
class ChunkyOption extends StatefulWidget {
  final String label;
  final ChoiceState state;
  final VoidCallback? onTap;

  const ChunkyOption({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
  });

  @override
  State<ChunkyOption> createState() => _ChunkyOptionState();
}

class _ChunkyOptionState extends State<ChunkyOption> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final verdict = VerdictColours.of(context);
    final palette = context.p;

    final (Color face, Color line, Color ink) = switch (widget.state) {
      ChoiceState.idle => (palette.surface, palette.lineStrong, palette.ink),
      ChoiceState.picked => (
        verdict.pickedFill,
        verdict.pickedLine,
        verdict.pickedInk,
      ),
      ChoiceState.right => (
        verdict.rightFill,
        verdict.rightLine,
        verdict.rightInk,
      ),
      ChoiceState.wrong => (
        verdict.wrongFill,
        verdict.wrongLine,
        verdict.wrongInk,
      ),
    };

    final pressed = _down && widget.onTap != null;

    return Semantics(
      button: widget.onTap != null,
      selected: widget.state != ChoiceState.idle,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _down = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _down = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          margin: const EdgeInsets.only(bottom: 11),
          decoration: BoxDecoration(
            color: line,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.only(
            top: pressed ? kChunkDepth : 0,
            bottom: pressed ? 0 : kChunkDepth,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: line, width: 1.6),
            ),
            child: Text(
              widget.label,
              style: AppText.body(
                size: 15,
                weight: FontWeight.w600,
                height: 1.3,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The green and the red, in both themes.
///
/// These are not in the Palette because they are not the app's colours — they
/// are the two universal signals, and they have to keep meaning the same
/// thing on paper and on black.
class VerdictColours {
  final Color rightFill, rightLine, rightInk;
  final Color wrongFill, wrongLine, wrongInk;
  final Color pickedFill, pickedLine, pickedInk;

  const VerdictColours({
    required this.rightFill,
    required this.rightLine,
    required this.rightInk,
    required this.wrongFill,
    required this.wrongLine,
    required this.wrongInk,
    required this.pickedFill,
    required this.pickedLine,
    required this.pickedInk,
  });

  static const light = VerdictColours(
    rightFill: Color(0xFFE8FAD1),
    rightLine: Color(0xFF7FBF1F),
    rightInk: Color(0xFF3F6B0A),
    wrongFill: Color(0xFFFFE3E3),
    wrongLine: Color(0xFFE86A6A),
    wrongInk: Color(0xFFB01C1C),
    pickedFill: Color(0xFFE4EBFF),
    pickedLine: Color(0xFF7C97FF),
    pickedInk: Color(0xFF1F3A9E),
  );

  static const dark = VerdictColours(
    rightFill: Color(0xFF23310F),
    rightLine: Color(0xFF7FBF1F),
    rightInk: Color(0xFFCDF29A),
    wrongFill: Color(0xFF3A1A1A),
    wrongLine: Color(0xFFE86A6A),
    wrongInk: Color(0xFFFFC2C2),
    pickedFill: Color(0xFF1D2540),
    pickedLine: Color(0xFF7C97FF),
    pickedInk: Color(0xFFC6D3FF),
  );

  static VerdictColours of(BuildContext context) =>
      context.p.isDark ? dark : light;
}
