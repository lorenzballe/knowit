import 'package:flutter/material.dart';

import '../../models/pill.dart';
import '../subject_icon.dart';
import 'parts.dart';

/// A month of one subject — artboard 131f's bento, with 132b's signature.
///
/// A big card, then two small ones stacked, then two more, and round again,
/// so the shelf reads as a spread rather than a row of equal tiles. The big
/// cards carry the subject's own mark drawn large in a darker tone of the
/// card, tipped and cut by the edge: a star for Pop culture, a planet for
/// Space, a fork for Food. The mark changes with the month, because the
/// subject does.
class MonthShelf extends StatelessWidget {
  const MonthShelf({
    super.key,
    required this.pills,
    required this.isRead,
    required this.onOpen,
    this.onShown,
  });

  final List<Pill> pills;
  final bool Function(Pill) isRead;
  final void Function(List<Pill>, Pill) onOpen;
  final ValueChanged<Pill>? onShown;

  /// The slots the cards fall into: a lead, then two pairs, then a lead
  /// again.
  List<(bool, List<Pill>)> get _slots {
    final out = <(bool, List<Pill>)>[];
    int i = 0;
    while (i < pills.length) {
      out.add((true, [pills[i]]));
      i++;
      for (int k = 0; k < 2 && i < pills.length; k++) {
        final int end = (i + 2).clamp(0, pills.length);
        out.add((false, pills.sublist(i, end)));
        i = end;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots;
    return SideRow(
      height: 240,
      count: slots.length,
      itemBuilder: (context, i) {
        final (bool lead, List<Pill> slot) = slots[i];
        for (final p in slot) {
          onShown?.call(p);
        }
        if (lead) {
          return _Lead(
            pill: slot.first,
            read: isRead(slot.first),
            onTap: () => onOpen(pills, slot.first),
          );
        }
        return SizedBox(
          width: 168,
          child: Column(
            children: [
              for (int k = 0; k < slot.length; k++) ...[
                if (k > 0) const SizedBox(height: 10),
                Expanded(
                  child: _Small(
                    pill: slot[k],
                    read: isRead(slot[k]),
                    onTap: () => onOpen(pills, slot[k]),
                  ),
                ),
              ],
              if (slot.length == 1) ...[
                const SizedBox(height: 10),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead({required this.pill, required this.read, required this.onTap});

  final Pill pill;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CardTap(
      pill: pill,
      onTap: onTap,
      child: Container(
        width: 214,
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // The month's mark, large, tipped and cut by the edge.
            Positioned(
              right: -60,
              bottom: -64,
              child: Transform.rotate(
                angle: -0.21,
                child: SubjectIcon(
                  subject: pill.topic,
                  size: 210,
                  stroke: 2.4,
                  ink: shade(pill.color, 0.86),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardHead(
                    pill: pill,
                    trailing: read ? ReadMark(pill: pill) : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: CardQuestion(
                        text: pill.question,
                        color: pill.ink,
                        min: 12,
                        max: 19,
                        height: 1.14,
                        tracking: -0.032,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
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

class _Small extends StatelessWidget {
  const _Small({required this.pill, required this.read, required this.onTap});

  final Pill pill;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CardTap(
      pill: pill,
      onTap: onTap,
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: pill.color,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SubjectIcon(subject: pill.topic, size: 15, ink: pill.ink),
                const Spacer(),
                if (read) ReadMark(pill: pill, size: 13),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CardQuestion(
                  text: pill.question,
                  color: pill.ink,
                  min: 10,
                  max: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
