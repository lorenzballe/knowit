import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/home_widget.dart';
import 'scaled_text.dart';
import 'subject_icon.dart';
import 'ui.dart';

/// Shows how to put Astute on the home screen, once, at the app's own
/// moment: a day just finished, the second or later
/// (AppState.shouldAskForWidget, chosen in lib/main.dart).
///
/// The widgets were built — the day's card, the five, the shelf, the streak,
/// on the home screen and on an iPhone's Lock Screen — and never offered:
/// a reader found them only by going to look. A widget is the day's first
/// card seen without opening anything, every morning, which is the whole
/// of what a daily app needs to be remembered.
///
/// Only to a reader with no widget placed, and only on a phone that says
/// what it has placed: where nothing answers, a test or a desktop, nothing
/// is shown. On Android, where the launcher puts a widget down when asked,
/// the sheet's button asks it; on an iPhone, which never lets an app do
/// that, the sheet says the three steps. True when the sheet was put.
Future<bool> offerWidget(BuildContext context, AppState app) async {
  if (kIsWeb) return false;
  final List<String>? placed = await placedHomeWidgets();
  if (placed == null || !context.mounted) return false;
  if (placed.isNotEmpty) {
    // One is already there: nothing to show, and nothing to show later.
    await app.notedWidgetAsked();
    return false;
  }
  final bool canPin = await canPinHomeWidget();
  if (!context.mounted) return false;
  await app.notedWidgetAsked();
  final bool apple = defaultTargetPlatform == TargetPlatform.iOS;
  Analytics.capture('widget asked', {'can_pin': canPin, 'apple': apple});
  if (!context.mounted) return false;
  final String? choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) =>
        WidgetAsk(card: _preview(app), canPin: canPin, apple: apple),
  );
  bool pinned = false;
  if (choice == 'pin') pinned = await pinHomeWidget();
  Analytics.capture('widget answered', {
    'choice': choice ?? 'dismissed',
    if (choice == 'pin') 'pin_asked': pinned,
  });
  return true;
}

/// The card the preview shows: tomorrow's first, which is what the widget
/// will hold when the reader next looks; failing that, a card with a
/// drawing from the bank.
Pill? _preview(AppState app) {
  final Pill? lead = app.tomorrowsDeck.firstOrNull;
  if (lead != null) return lead;
  return PillBank.live.where((p) => p.hasPage).firstOrNull ??
      PillBank.live.firstOrNull;
}

/// The sheet: the widget as it will look, what it gives, how to put it
/// there, and the answers. Public so a test can lay it out in every
/// language, on both phones.
class WidgetAsk extends StatelessWidget {
  const WidgetAsk({
    super.key,
    required this.card,
    required this.canPin,
    required this.apple,
  });

  /// The card the widget is drawn holding, or null for none to hand.
  final Pill? card;

  /// Whether the phone's launcher puts the widget down when asked.
  final bool canPin;

  /// An iPhone: its own steps, and the Lock Screen beside them.
  final bool apple;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final List<String> steps = apple
        ? [
            l.widgetAskStepHold,
            l.widgetAskStepAppleAdd,
            l.widgetAskStepApplePick,
          ]
        : [
            l.widgetAskStepHold,
            l.widgetAskStepAndroidAdd,
            l.widgetAskStepAndroidPick,
          ];
    return Container(
      key: const ValueKey('widget-ask'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
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
                  color: p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.widgetAskTitle,
              style: AppText.display(
                size: 20,
                weight: FontWeight.w600,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.widgetAskLine,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 16),
            _WidgetPreview(card: card),
            const SizedBox(height: 16),
            if (!canPin) ...[
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _Step(number: i + 1, text: steps[i]),
              ],
              if (apple) ...[
                const SizedBox(height: 10),
                Text(
                  l.widgetAskLockScreen,
                  key: const ValueKey('widget-ask-lock'),
                  style: AppText.body(
                    size: 12.5,
                    height: 1.4,
                    color: p.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: 18),
            ],
            PrimaryButton(
              key: const ValueKey('widget-yes'),
              label: canPin ? l.widgetAskPin : l.widgetAskGotIt,
              height: 52,
              onPressed: () =>
                  Navigator.of(context).pop(canPin ? 'pin' : 'got it'),
            ),
            const SizedBox(height: 4),
            QuietButton(
              key: const ValueKey('widget-not-now'),
              label: l.widgetAskNotNow,
              onPressed: () => Navigator.of(context).pop('not now'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One step, its number in a ring.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.lineStrong),
          ),
          child: Text(
            '$number',
            style: AppText.label(
              size: 11,
              weight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: AppText.body(
                size: 13.5,
                weight: FontWeight.w500,
                height: 1.35,
                color: p.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The widget as the home screen will hold it: the card's colour and mark,
/// its subject, its question, and the app's name — on a strip of home
/// screen, between two faint icons, so it reads as a widget and not a card.
class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({required this.card});

  final Pill? card;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Pill? c = card;
    final TopicStyle science = kTopics['science']!;
    final Color ground = c?.color ?? science.color;
    final Color ink = c?.ink ?? science.ink;
    final String subject = c?.topic ?? science.name;
    Widget icon() => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: p.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return ExcludeSemantics(
      child: Container(
        key: const ValueKey('widget-ask-preview'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Column(children: [icon(), const SizedBox(height: 12), icon()]),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 100,
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
                decoration: BoxDecoration(
                  color: ground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectIcon(subject: subject, size: 13, ink: ink),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            context.l10n.subjectOf(subject).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              size: 8.5,
                              weight: FontWeight.w700,
                              spacing: 1,
                              color: ink.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // As large as the box takes and never cut, as the
                    // widget itself sets it.
                    Expanded(
                      child: ScaledText(
                        text: c?.question ?? '',
                        min: 8,
                        max: 18,
                        alignment: Alignment.topLeft,
                        styleFor: (size) => AppText.display(
                          size: size,
                          weight: FontWeight.w600,
                          height: 1.15,
                          spacing: -0.2,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Astute',
                      style: AppText.label(
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
