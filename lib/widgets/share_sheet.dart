import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../models/pill.dart';
import '../theme.dart';
import '../utils/image_saver.dart';
import 'ui.dart';

/// Opens the share sheet for [pill] — the square export preview plus the
/// three actions under it.
Future<void> showShareSheet(BuildContext context, Pill pill) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => _ShareSheet(pill: pill),
  );
}

class _ShareSheet extends StatefulWidget {
  final Pill pill;
  const _ShareSheet({required this.pill});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  /// Shared text carries the source and where it came from — a card in
  /// someone else's chat is the only free distribution this app has.
  ///
  /// The body has to follow the kind of card: a worked problem's `answer` is
  /// the last line of its solution and a debate's is one side of it, so
  /// neither can be pasted on its own.
  String get _shareText {
    final pill = widget.pill;
    final buffer = StringBuffer(pill.question)..write('\n\n');

    if (pill.hasSteps) {
      for (var i = 0; i < pill.steps.length; i++) {
        buffer.writeln('${i + 1}. ${pill.steps[i]}');
      }
    } else {
      buffer.writeln(pill.answer);
    }

    if (pill.hasCounterpoint) {
      buffer
        ..write('\nThe other side: ')
        ..writeln(pill.counterpoint);
    }

    return '$buffer\n${pill.barMove}\n\nSource: ${pill.source}\n'
        '— Knowit · lorenzballe.github.io/knowit';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Rasterises the preview card at 3x so the export is usable at story size.
  Future<Uint8List?> _capture() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast('Could not render the card.');
        return;
      }
      final name = 'knowit-${widget.pill.id}.png'.replaceAll(
        RegExp(r'[^\w.-]'),
        '-',
      );
      final saved = await savePng(bytes, name);
      if (saved) {
        _toast('Image saved.');
      } else {
        await Clipboard.setData(ClipboardData(text: _shareText));
        _toast('Text copied — image export is web-only for now.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    _toast('Copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share this pill',
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _cardKey,
              child: _ShareCard(pill: pill),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _busy ? 'Rendering…' : 'Share image',
                    height: 52,
                    onPressed: _busy ? null : _shareImage,
                  ),
                ),
                const SizedBox(width: 10),
                _CircleAction(
                  icon: Icons.download_rounded,
                  onTap: _busy ? null : _shareImage,
                ),
                const SizedBox(width: 10),
                _CircleAction(icon: Icons.copy_rounded, onTap: _copyText),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Source travels with the image',
                style: AppText.body(
                  size: 12,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The square that gets exported.
class _ShareCard extends StatelessWidget {
  final Pill pill;
  const _ShareCard({required this.pill});

  @override
  Widget build(BuildContext context) {
    final onCard = pill.ink;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pill.topic.toUpperCase(),
              style: AppText.label(
                size: 10.5,
                spacing: 1.4,
                color: onCard.withValues(alpha: 0.7),
              ),
            ),
            Flexible(
              child: Text(
                pill.question,
                style: AppText.display(
                  size: 26,
                  weight: FontWeight.w600,
                  height: 1.16,
                  spacing: -0.9,
                  color: onCard,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    pill.barMove,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w500,
                      height: 1.4,
                      color: onCard.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Knowit',
                  style: AppText.display(
                    size: 13,
                    weight: FontWeight.w600,
                    color: onCard.withValues(alpha: 0.6),
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

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: AppColors.ink),
      ),
    );
  }
}
