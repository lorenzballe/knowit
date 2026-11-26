import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../analytics.dart';
import '../../../data/day_lines.dart';
import '../../../data/topics.dart';
import '../../../l10n/l10n.dart';
import '../../../legal.dart' show openLink;
import '../../../theme.dart';
import '../../../utils/share_link.dart';
import '../../../widgets/glow_outline.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// The outline the line wears (widgets/glow_outline.dart): a sheen that
/// travels slowly round a white hairline. The other two looks are `breath`
/// and `spectrum`; a build given `--dart-define=LINE_OUTLINE=breath` wears
/// another without a change here.
const String _outline = String.fromEnvironment(
  'LINE_OUTLINE',
  defaultValue: 'sheen',
);
const GlowOutlineStyle kLineOutline = _outline == 'breath'
    ? GlowOutlineStyle.breath
    : _outline == 'spectrum'
    ? GlowOutlineStyle.spectrum
    : GlowOutlineStyle.sheen;

/// The line of the day (lib/data/day_lines.dart): one sentence worth
/// keeping, the same for every reader, under who wrote it and where, which
/// opens the page where anyone can read it as it was written. It can be
/// sent on, with where it is from.
///
/// On Explore for every subject any line; on a subject's page a line of
/// its themes, and nothing on a page that has none.
class LineOfDayBlock extends ExploreBlock with SectionLayout {
  const LineOfDayBlock();

  @override
  String get name => 'line-of-day';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final String? subject = host.subject;
    final DayLine? line = lineOfDay(
      host.app.today,
      subject: subject == null ? null : _keyOf(subject),
    );
    if (line == null) return null;
    final String? title = section.title(host.language);
    return SectionFrame(
      title: title,
      line: section.subtitle(host.language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DayLineCard(line: line, name: title),
      ),
    );
  }
}

/// The key of the subject called [name] (kTopics), or the name itself
/// for one this build does not know, whose page has no lines.
String _keyOf(String name) {
  for (final MapEntry<String, TopicStyle> e in kTopics.entries) {
    if (e.value.name == name) return e.key;
  }
  return name;
}

/// The line itself: the words large, in the app's serif, then who wrote
/// them and where, and the way to send it on.
class DayLineCard extends StatelessWidget {
  const DayLineCard({super.key, required this.line, this.name});

  final DayLine line;

  /// The section's name, said with the line when it is sent.
  final String? name;

  /// Where the line was written, as the card prints it: "On Liberty, 1859",
  /// and who put it into English when someone did.
  static String whereOf(DayLine line) => [
    '${line.work}, ${line.year}',
    if (line.translator.isNotEmpty) 'tr. ${line.translator}',
  ].join(' · ');

  /// What goes to a friend: the line, who and where, and the app.
  static String textOf(DayLine line, String? name) => [
    '“${line.text}”',
    '— ${line.author}, ${whereOf(line)}',
    '',
    [?name, ShareRef.line.link].join(' · '),
  ].join('\n');

  Future<void> _send(BuildContext context) async {
    HapticFeedback.lightImpact();
    final l = context.l10n;
    final String text = textOf(line, name);
    final bool shared = await sendText(text);
    Analytics.capture('line shared', {
      'author': line.author,
      'as': shared ? 'sheet' : 'copied',
    });
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.copiedToClipboard),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final int n = line.text.length;
    // The words as large as their length allows: a short line is a poster,
    // a long one still reads in a glance or two.
    final double size = n <= 90
        ? 22
        : n <= 160
        ? 20
        : n <= 240
        ? 18.5
        : 17;
    // The one card on the page with a light round it: a line worth
    // keeping should not look like the shelves around it.
    return GlowOutline(
      style: kLineOutline,
      radius: 22,
      child: Container(
        key: const ValueKey('day-line'),
        decoration: BoxDecoration(
          color: p.ink.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(22),
        ),
        // A little more room than a card without an edge needs, so the
        // words stand clear of the light round them.
        padding: const EdgeInsets.fromLTRB(20, 20, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '“${line.text}”',
                style: AppText.display(
                  size: size,
                  weight: FontWeight.w500,
                  height: 1.3,
                  spacing: -0.2,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    link: true,
                    child: InkWell(
                      key: const ValueKey('day-line-source'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Analytics.capture('line source opened', {
                          'author': line.author,
                        });
                        openLink(line.url);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.author,
                              style: AppText.body(
                                size: 14.5,
                                weight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            // The arrow held to the last word by a space that
                            // does not break, never on a line of its own.
                            Text(
                              '${whereOf(line)}\u00A0↗',
                              style: AppText.body(
                                size: 12.5,
                                weight: FontWeight.w600,
                                height: 1.35,
                                color: p.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('day-line-share'),
                  tooltip: l.share,
                  onPressed: () => _send(context),
                  icon: Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: p.ink.withValues(alpha: 0.7),
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
