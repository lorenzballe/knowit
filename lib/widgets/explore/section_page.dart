/// One section of Explore on a page of its own: a game picked from the
/// quick games, played with the room a game needs.
///
/// The section is drawn by the same engine and for the same host as the
/// page it was opened from, so it is the same block doing the same things —
/// a card opened from it opens as from any shelf, an answer is recorded as
/// any answer is, a round played here is the day's round.
library;

import 'package:flutter/material.dart';

import '../../explore/blocks/bets/bets_day.dart';
import '../../explore/explore_block.dart';
import '../../l10n/l10n.dart';
import '../../state/explore_play.dart';
import '../../theme.dart';
import '../ui.dart' show BackCircle;
import 'explore_engine.dart';

class ExploreSectionPage extends StatelessWidget {
  const ExploreSectionPage({
    super.key,
    required this.host,
    required this.section,
  });

  /// What the section is drawn for, and with: Explore's own host.
  final ExploreHost host;

  /// The section shown.
  final ExploreSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BackCircle(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                // What the reader read and answered, the day's play and the
                // day's bets: the game is drawn again as they change.
                listenable: Listenable.merge([
                  host.app,
                  ExplorePlay.instance,
                  BetsDay.instance,
                ]),
                builder: (context, _) {
                  final List<ExploreSlot> slots = exploreSlots(context, host, [
                    section,
                  ], host.app.remoteContext(host.language));
                  if (slots.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        context.l10n.exploreGameNone,
                        key: const ValueKey('section-page-none'),
                        style: AppText.body(
                          size: 14,
                          height: 1.4,
                          color: context.p.inkMuted,
                        ),
                      ),
                    );
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 40),
                        sliver: ExploreSliver(host: host, slots: slots),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
