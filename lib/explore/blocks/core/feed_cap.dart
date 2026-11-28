/// Where Explore's endless flow ends for a reader on the free plan, behind
/// the server's number `explore.freeCards` (AppState.kExploreFreeCardsKnob),
/// nought as built: no end. With a number, once the cards read in a day
/// beyond the day's five reach it (AppState.exploreCapped), the flow lays
/// no band after the ones already on the page, and this card stands where
/// the next would have: what was read, that more comes tomorrow, and that
/// Astute+ has no end. A soft end, and a calm one: what is on the page
/// stays open, the shelves above the flow are as they were, and nothing is
/// taken away mid-scroll.
library;

import 'package:flutter/material.dart';

import '../../../analytics.dart';
import '../../../data/pills_repository.dart' show dateKey;
import '../../../l10n/l10n.dart';
import '../../../screens/today_done_view.dart' show plusActionOf;
import '../../../state/app_state.dart';
import '../../../theme.dart';
import '../../../widgets/premium.dart' show requirePlus;

/// The day the end was last said, so it is counted once a day.
String? _saidOn;

/// The end of the flow: see the library's own words.
class FeedCapCard extends StatelessWidget {
  const FeedCapCard({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.p;
    final int read = app.readBeyondFiveToday;
    final String day = dateKey(app.today);
    if (_saidOn != day) {
      _saidOn = day;
      Analytics.capture('explore end shown', {
        'cards_read': read,
        'cap': AppState.kExploreFreeCardsKnob.value,
      });
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Container(
        key: const ValueKey('explore-cap'),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: p.line, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.plusNameCaps,
              style: AppText.label(
                size: 11,
                weight: FontWeight.w700,
                spacing: 2.4,
                color: p.inkMuted,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.exploreCapTitle,
              key: const ValueKey('explore-cap-title'),
              style: AppText.display(
                size: 25,
                weight: FontWeight.w500,
                height: 1.12,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.exploreCapLine(read),
              style: AppText.body(
                size: 14.5,
                height: 1.4,
                color: p.ink.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: p.line),
            const SizedBox(height: 14),
            Text(
              l.exploreCapPlus,
              style: AppText.body(
                size: 14.5,
                weight: FontWeight.w600,
                height: 1.35,
                color: p.ink,
              ),
            ),
            // The door, as quiet as the card: the paywall.
            Semantics(
              button: true,
              child: GestureDetector(
                key: const ValueKey('explore-cap-plus'),
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    requirePlus(context, app, () {}, source: 'explore end'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '${plusActionOf(context)}  ›',
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      height: 1.2,
                      color: p.link,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
