import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils/image_saver.dart';
import 'ui.dart';

/// Opens the share sheet for the reader's own track record.
///
/// Sharing a fact competes with every other daily-learning app on the terms
/// they are already better funded at. A number about yourself is the one
/// thing this app makes that nobody else holds, so it is the one worth
/// putting in someone else's chat.
Future<void> showRecordShareSheet(BuildContext context, AppState app) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => _RecordShareSheet(app: app),
  );
}

/// The reader's record, reduced to the few numbers that fit on a card.
class RecordSummary {
  /// What they claimed on average, and how often they were actually right,
  /// both as percentages.
  final double said;
  final double wasRight;
  final int calls;
  final int streak;
  final String? weakest;

  const RecordSummary({
    required this.said,
    required this.wasRight,
    required this.calls,
    required this.streak,
    required this.weakest,
  });

  factory RecordSummary.of(AppState app) {
    final judgements = app.judgements;
    var claimed = 0.0;
    var right = 0;
    for (final j in judgements) {
      claimed += j.confidence;
      if (j.correct) right++;
    }
    final n = judgements.length;
    final weak = app.masteryByWeakness.where((m) => m.isWeak).toList();
    return RecordSummary(
      said: n == 0 ? 0 : claimed / n,
      wasRight: n == 0 ? 0 : right * 100 / n,
      calls: n,
      streak: app.liveStreak,
      weakest: weak.isEmpty ? null : weak.first.principle.label,
    );
  }

  /// Positive means overconfident — the usual direction.
  double get gap => said - wasRight;

  /// Inside this band, the difference is noise rather than a habit.
  static const _band = 5;

  bool get isCalibrated => gap.abs() <= _band;

  /// The one line that carries the card.
  String get verdict {
    final points = gap.abs().round();
    if (isCalibrated) return 'Calibrated within $points points';
    return gap > 0
        ? '$points points overconfident'
        : '$points points underconfident';
  }
}

class _RecordShareSheet extends StatefulWidget {
  final AppState app;
  const _RecordShareSheet({required this.app});

  @override
  State<_RecordShareSheet> createState() => _RecordShareSheetState();
}

class _RecordShareSheetState extends State<_RecordShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  RecordSummary get _summary => RecordSummary.of(widget.app);

  String get _shareText {
    final s = _summary;
    return 'My judgement, measured over ${s.calls} calls:\n\n'
        'I said I was ${s.said.round()}% sure.\n'
        'I was right ${s.wasRight.round()}% of the time.\n'
        '${s.verdict}.\n\n'
        'How close would yours be?\n'
        '— Astuto · lorenzballe.github.io/knowit';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

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
      final saved = await savePng(bytes, 'knowit-record.png');
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
    return Container(
      decoration: BoxDecoration(
        color: context.p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                  color: context.p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share your record',
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: context.p.ink,
              ),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _cardKey,
              child: RecordCard(summary: _summary),
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
                'Nobody else can see your answers',
                style: AppText.body(size: 12, color: context.p.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card that gets exported. Fixed colours: it leaves the app as an
/// image, so it should not arrive in someone's chat wearing that reader's
/// theme.
class RecordCard extends StatelessWidget {
  final RecordSummary summary;
  const RecordCard({super.key, required this.summary});

  // The app's own colour, not a neutral. This leaves as an image into a feed
  // of other images, where being instantly recognisable is the whole job —
  // and a near-black card is exactly what everything else already looks like.
  static const _ground = AppColors.lime;
  static const _ink = AppColors.limeInk;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
        decoration: BoxDecoration(
          color: _ground,
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
          children: [
            Text(
              'MY RECORD',
              style: AppText.label(
                size: 10.5,
                spacing: 1.6,
                color: _ink.withValues(alpha: 0.55),
              ),
            ),
            const Spacer(flex: 2),
            _Claim(
              lead: 'I said I was',
              value: '${summary.said.round()}%',
              tail: 'sure.',
            ),
            const SizedBox(height: 16),
            _Claim(
              lead: 'I was right',
              value: '${summary.wasRight.round()}%',
              tail: 'of the time.',
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                summary.verdict,
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: _ground,
                ),
              ),
            ),
            const Spacer(flex: 3),
            Container(height: 1, color: _ink.withValues(alpha: 0.18)),
            const SizedBox(height: 13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    _footline,
                    style: AppText.body(
                      size: 12.5,
                      height: 1.45,
                      color: _ink.withValues(alpha: 0.62),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Astuto',
                  style: AppText.display(
                    size: 14,
                    weight: FontWeight.w600,
                    color: _ink.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _footline {
    final calls = '${summary.calls} call${summary.calls == 1 ? '' : 's'}';
    final parts = <String>[calls];
    if (summary.streak > 0) parts.add('${summary.streak}-day streak');
    final head = parts.join(' · ');
    final weak = summary.weakest;
    return weak == null ? head : '$head\nStill missing: $weak';
  }
}

class _Claim extends StatelessWidget {
  final String lead;
  final String value;
  final String tail;

  const _Claim({required this.lead, required this.value, required this.tail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lead,
          style: AppText.body(
            size: 14,
            color: RecordCard._ink.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppText.display(
                  size: 44,
                  weight: FontWeight.w700,
                  height: 1,
                  spacing: -2,
                  color: RecordCard._ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tail,
                style: AppText.display(
                  size: 19,
                  weight: FontWeight.w500,
                  spacing: -0.5,
                  color: RecordCard._ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
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
          border: Border.all(color: context.p.line),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: context.p.ink),
      ),
    );
  }
}
