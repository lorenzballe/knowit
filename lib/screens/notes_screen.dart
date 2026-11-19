/// The reader's notes, all of them: each card's question over what the
/// reader wrote on it, the note written last first. A tap opens the card's
/// own page, where its note is changed or taken away, the other noted cards
/// a swipe away.
library;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/pill_bank.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fit_text.dart';
import '../widgets/subject_icon.dart';
import '../widgets/ui.dart' show BackCircle, ScreenView;
import 'pill_detail_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.app});

  final AppState app;

  static Future<void> open(BuildContext context, AppState app) {
    Analytics.capture('notes opened', {'notes': app.notedIds.length});
    return Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => NotesScreen(app: app)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return ScreenView(
      name: 'notes',
      child: Scaffold(
        backgroundColor: p.surface,
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final List<Pill> cards = [
                for (final String id in app.notedIds)
                  if (PillBank.byId(id) case final Pill pill) pill,
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The way back stays put above what scrolls: on iOS 26 it
                  // is Apple's own glass button, a native view, and one
                  // inside a scrolling list is drawn away from its place.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        BackCircle(
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FitText(
                            l.notesTitle,
                            maxLines: 1,
                            minSize: 20,
                            style: AppText.display(
                              size: 27,
                              weight: FontWeight.w600,
                              height: 1,
                              spacing: -0.8,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cards.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: Text(
                              l.notesEmpty,
                              key: const ValueKey('notes-empty'),
                              style: AppText.body(
                                size: 15,
                                height: 1.45,
                                color: p.inkMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                            itemCount: cards.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) => _NoteRow(
                              key: ValueKey('note-row-${cards[i].id}'),
                              pill: cards[i],
                              note: app.noteOn(cards[i].id) ?? '',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PillDetailScreen(
                                    pill: cards[i],
                                    app: app,
                                    among: cards,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A note: its card's subject and question, and what the reader wrote.
class _NoteRow extends StatelessWidget {
  const _NoteRow({
    super.key,
    required this.pill,
    required this.note,
    required this.onTap,
  });

  final Pill pill;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TopicStyle? style = kTopics[topicKeyForName(pill.topic) ?? ''];
    return Material(
      color: p.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (style != null) ...[
                    SubjectIcon(
                      subject: style.name,
                      size: 13,
                      ink: p.isDark ? style.color : style.ink,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      l.subjectOf(pill.topic).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        size: 10.5,
                        weight: FontWeight.w700,
                        spacing: 1.2,
                        color: p.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                pill.question,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 14.5,
                  weight: FontWeight.w700,
                  height: 1.3,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: style == null
                          ? p.lineStrong
                          : (p.isDark ? style.color : style.ink),
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  note,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 14, height: 1.4, color: p.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
