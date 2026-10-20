/// The bottom of Explore — the canvas's 138f.
///
/// The last shelf, Surprise me and every subject are in the app already,
/// as core's. What this family adds is what the shelves bring tomorrow,
/// and the line that says the page is at its end.
library;

import 'package:flutter/material.dart';

import '../../../data/themed_shelves.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../theme.dart';
import '../../explore_block.dart';
import 'kit.dart';

/// How many of tomorrow's shelves are named when the section names none.
const int kTomorrowShelves = 3;

/// 138f: what the shelves bring tomorrow, each by its name and its line.
class TomorrowBlock extends ExploreBlock {
  const TomorrowBlock();

  @override
  String get name => 'purpose.tomorrow';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final List<(String, String)> shelves = [];
    final List<Map<Object?, Object?>> parts = partsOf(section, 'shelves');
    if (parts.isNotEmpty) {
      // What the server will show tomorrow, in its words: a shelf without
      // a name is passed over.
      for (final Map<Object?, Object?> part in parts) {
        final ExploreSection shelf = partOf(section, part);
        final String? title = shelf.text('title', lang);
        if (title == null || title.trim().isEmpty) continue;
        shelves.add((title, shelf.text('subtitle', lang) ?? ''));
      }
    } else {
      final List<Pill> pool = host.cardsFor(section, limit: kPurposePool);
      for (final ThemedShelf t in themedShelves(
        pool,
        day: today() + 1,
      ).take(limitOf(section, kTomorrowShelves))) {
        shelves.add((themeTitle(l, t.theme, t.variant), themeLine(l, t.theme)));
      }
    }
    if (shelves.isEmpty) return null;
    final Palette pal = context.p;
    return host.watch(
      section,
      PurposeShelf(
        title: section.title(lang) ?? l.purposeTomorrow,
        line: section.subtitle(lang) ?? l.purposeTomorrowLine,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: pal.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < shelves.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(
                              color: pal.ink.withValues(alpha: 0.08),
                            ),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelves[i].$1,
                        key: ValueKey('tomorrow-$i'),
                        style: AppText.body(
                          size: 14.5,
                          weight: FontWeight.w600,
                          height: 1.2,
                          color: pal.ink,
                        ),
                      ),
                      if (shelves[i].$2.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          shelves[i].$2,
                          style: AppText.body(
                            size: 12,
                            height: 1.3,
                            color: pal.ink.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 138f: that's the bottom of Explore, and see you tomorrow.
class EndBlock extends ExploreBlock {
  const EndBlock();

  @override
  String get name => 'purpose.end';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final l = context.l10n;
    final String lang = host.language;
    final Palette pal = context.p;
    return host.watch(
      section,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                wordsOf(section, 'line', lang, l.purposeEnd),
                textAlign: TextAlign.center,
                style: AppText.display(
                  size: 18,
                  weight: FontWeight.w600,
                  height: 1.2,
                  spacing: -0.3,
                  color: pal.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wordsOf(section, 'subline', lang, l.purposeEndLine),
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12,
                height: 1.3,
                color: pal.ink.withValues(alpha: 0.42),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
