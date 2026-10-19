/// Bet a friend (139b): a card to send before they have seen its answer,
/// through the app's own share sheet.
///
/// The canvas has the friend answer and both readers see who was closer.
/// That needs a server to carry a bet between two phones, and there is
/// none: what is sent is the card itself, from the share sheet every card
/// has, and the card goes with its answer. So the panel says so — ask for
/// their guess before they read on — and offers the question on its own,
/// copied, for a friend who should not see the answer at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../../utils/share_link.dart';
import '../../../widgets/explore/parts.dart' show CardHead;
import '../../../widgets/share_sheet.dart';
import '../../explore_block.dart';
import 'answers.dart';
import 'bets_day.dart';
import 'block.dart';
import 'deal.dart';
import 'parts.dart';

/// The block: one card in a bubble, to send to a friend.
class FriendBlock extends BetBlock {
  const FriendBlock();

  @override
  String get name => 'bets-friend';

  @override
  int get defaultLimit => 1;

  /// A pick of amounts first, which a friend can answer in a word; any card
  /// with a number for an answer when there is none.
  @override
  bool fits(BetAnswer a) => true;

  @override
  String title(AppLocalizations l, BetSection shelf) => l.betsFriendTitle;

  @override
  String line(AppLocalizations l, BetSection shelf) => l.betsFriendLine;

  @override
  List<BetAnswer> deal(ExploreHost host, BetSection shelf) {
    final Pill? named = shelf.card('card');
    if (named != null && answerOf(named) != null) return [answerOf(named)!];
    final List<BetAnswer> pick = dealBets(
      host,
      shelf,
      fits: (a) => a.isPick,
      count: 1,
      salt: name,
    );
    if (pick.isNotEmpty) return pick;
    return dealBets(host, shelf, fits: fits, count: 1, salt: '$name-any');
  }

  @override
  Widget body(
    BuildContext context,
    ExploreHost host,
    BetSection shelf,
    List<BetAnswer> cards,
  ) {
    // The bet just laid is the one worth sending: the latest stake today,
    // unless the section names its own card.
    BetAnswer card = cards.first;
    Bet? laid;
    if (shelf.card('card') == null) {
      for (final Bet b in BetsDay.instance.slip.reversed) {
        if (b.kind != 'stake') continue;
        final Pill? p = PillBank.byId(b.pill);
        final BetAnswer? a = p == null ? null : answerOf(p);
        if (a == null) continue;
        card = a;
        laid = b;
        break;
      }
    } else {
      laid = BetsDay.instance.betOn('stake', card.pill.id);
    }
    final BetAnswer sent = card;
    return BetTiles(
      key: ValueKey('bets-friend-${sent.pill.id}'),
      size: BetTileSize.l,
      count: 1,
      onSeen: (_) => host.seen(shelf.section, sent.pill),
      builder: (context, _) => FriendPanel(
        host: host,
        shelf: shelf,
        answer: sent,
        laid: laid,
        size: shelf.size(sizes, defaultSize),
      ),
    );
  }

  @override
  bool canShow(ExploreHost host, BetSection shelf) {
    final Pill? named = shelf.card('card');
    return (named != null && answerOf(named) != null) ||
        super.canShow(host, shelf);
  }
}

/// The panel: the card as a message about to go, what goes with it, and the
/// two ways to send it.
class FriendPanel extends StatelessWidget {
  const FriendPanel({
    super.key,
    required this.host,
    required this.shelf,
    required this.answer,
    required this.laid,
    required this.size,
  });

  final ExploreHost host;
  final BetSection shelf;
  final BetAnswer answer;

  /// The stake laid on it today, if one was.
  final Bet? laid;

  /// `s` leaves the card out, `m` sends it as a bubble, `l` as a bubble the
  /// width of the panel.
  final String size;

  /// The question on its own, with the options to answer from: what is
  /// copied, so a friend can be asked without being told.
  String questionText(AppLocalizations l) {
    final Pill pill = answer.pill;
    final List<String> options = answer.options;
    return [
      pill.question,
      if (options.isNotEmpty) options.join(' · '),
      '${l.betsFriendAsk}\n— Astute · ${ShareRef.card.link}',
    ].join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Pill pill = answer.pill;
    final BetInk panel = BetInk.page(context);
    final BetInk card = BetInk.of(context, pill, BetTone.subject);
    final Bet? bet = laid;
    final int? said = bet == null ? null : int.tryParse(bet.said);
    final List<String> options = answer.options;
    final String note = said != null && said >= 0 && said < options.length
        ? l.betsFriendNoteSaid(options[said])
        : l.betsFriendNote;
    final bool wide = size == 'l';
    final double bubble = wide ? double.infinity : 250;

    Future<void> send() async {
      host.note(shelf.section, 'bet sent', {'pill_id': pill.id});
      await showShareSheet(context, pill);
    }

    Future<void> copy() async {
      await Clipboard.setData(ClipboardData(text: questionText(l)));
      host.note(shelf.section, 'bet copied', {'pill_id': pill.id});
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(l.betsFriendCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel.ground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (size != 's') ...[
            Container(
              key: ValueKey('bets-friend-card-${pill.id}'),
              width: bubble,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card.ground,
                border: card.edge,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardHead(
                    pill: pill,
                    label: l.subjectOf(pill.topic),
                    ink: card.mark,
                    labelInk: card.sub,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pill.question,
                    style: AppText.display(
                      size: wide ? 16 : 13.5,
                      weight: FontWeight.w600,
                      height: 1.16,
                      spacing: -0.025 * (wide ? 16 : 13.5),
                      color: card.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.isEmpty)
                        Expanded(
                          child: BetChip(
                            label: answer.unit.isEmpty
                                ? '?'
                                : '? ${answer.unit}',
                            ink: card,
                            height: 30,
                            radius: 9,
                            weight: FontWeight.w600,
                          ),
                        )
                      else
                        for (int j = 0; j < options.length; j++) ...[
                          if (j > 0) const SizedBox(width: 5),
                          Expanded(
                            child: BetChip(
                              label: options[j],
                              ink: card,
                              height: 30,
                              radius: 9,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? double.infinity : 260),
            child: Text(
              note,
              key: const ValueKey('bets-friend-note'),
              textAlign: TextAlign.right,
              style: AppText.body(
                size: 11.5,
                weight: FontWeight.w500,
                height: 1.35,
                color: panel.sub,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Action(
                  key: const ValueKey('bets-friend-send'),
                  label: l.betsFriendSend,
                  icon: Icons.ios_share_rounded,
                  background: context.p.inverse,
                  foreground: context.p.onInverse,
                  onTap: send,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Action(
                  key: const ValueKey('bets-friend-copy'),
                  label: l.betsFriendCopy,
                  background: context.p.ink.withValues(alpha: 0.08),
                  foreground: context.p.ink,
                  onTap: copy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A button under the panel, the height of a thumb.
class _Action extends StatelessWidget {
  const _Action({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                ExcludeSemantics(
                  child: Icon(icon, size: 16, color: foreground),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    height: 1.15,
                    color: foreground,
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
