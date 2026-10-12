import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme.dart';
import 'parts.dart';

/// "Where you live", for a reader who has not said: one tile in place of
/// the shelf's cards, with what switching it on gives and the promise about
/// what is kept, and the one button that asks.
///
/// The asking itself is not here. It is the place capture's own sheet
/// (docs/PLACES.md §2), handed in as [onSwitchOn], so this shelf and every
/// other door to it ask the same way and say the same thing.
class WhereYouLiveAsk extends StatelessWidget {
  const WhereYouLiveAsk({super.key, required this.onSwitchOn});

  final VoidCallback onSwitchOn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        key: const ValueKey('where-you-live-ask'),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        decoration: BoxDecoration(
          color: context.p.ink.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: context.p.ink.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.place_rounded,
                      size: 17,
                      color: context.p.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l.whereYouLiveAsk,
                    style: AppText.body(
                      size: 13,
                      weight: FontWeight.w500,
                      height: 1.4,
                      color: context.p.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            FlatButton(
              key: const ValueKey('where-you-live-switch-on'),
              label: l.whereYouLiveSwitchOn,
              background: context.p.inverse,
              foreground: context.p.onInverse,
              height: 40,
              onTap: onSwitchOn,
            ),
          ],
        ),
      ),
    );
  }
}
