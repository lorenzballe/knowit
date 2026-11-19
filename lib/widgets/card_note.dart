/// The reader's note on a card, on the card's own page: what they wrote, or
/// the way to write one; and the sheet it is written in.
library;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../state/app_state.dart';
import '../state/card_notes.dart';
import '../theme.dart';
import 'chunky.dart';

/// Where a card's own page keeps the reader's note on it.
class CardNoteSection extends StatelessWidget {
  const CardNoteSection({super.key, required this.app, required this.pill});

  final AppState app;
  final Pill pill;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final l = context.l10n;
        final Palette p = context.p;
        final String? note = app.noteOn(pill.id);
        if (note == null) {
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('note-add'),
              onPressed: () => showCardNoteSheet(context, app, pill),
              style: TextButton.styleFrom(
                foregroundColor: p.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 22),
              label: Text(
                l.noteAdd,
                style: AppText.body(size: 14.5, weight: FontWeight.w700),
              ),
            ),
          );
        }
        return Semantics(
          button: true,
          label: '${l.noteYours}: $note',
          excludeSemantics: true,
          child: Material(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: const ValueKey('note-open'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => showCardNoteSheet(context, app, pill),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: p.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l.noteYours.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              size: 11,
                              weight: FontWeight.w700,
                              spacing: 1.2,
                              color: p.inkMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.noteEdit,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: p.link,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note,
                      key: const ValueKey('note-text'),
                      style: AppText.body(size: 15, height: 1.45, color: p.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Opens the sheet [pill]'s note is written in: what is there already, to
/// change; kept as it is left by Save, taken away by the bin.
Future<void> showCardNoteSheet(BuildContext context, AppState app, Pill pill) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NoteSheet(app: app, pill: pill),
  );
}

class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.app, required this.pill});

  final AppState app;
  final Pill pill;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final String? _was = widget.app.noteOn(widget.pill.id);
  late final TextEditingController _text = TextEditingController(
    text: _was ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _keep(String text) async {
    final NavigatorState nav = Navigator.of(context);
    await widget.app.setNote(widget.pill.id, text);
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.noteYours,
              style: AppText.display(
                size: 22,
                weight: FontWeight.w600,
                spacing: -0.4,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.pill.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 13, height: 1.35, color: p.inkMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('note-field'),
              controller: _text,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: CardNotes.maxLength,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.body(size: 15, height: 1.45, color: p.ink),
              decoration: InputDecoration(
                hintText: l.noteHint,
                hintStyle: AppText.body(size: 15, color: p.inkFaint),
                filled: true,
                fillColor: p.surfaceRaised,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_was != null) ...[
                  IconButton(
                    key: const ValueKey('note-delete'),
                    tooltip: l.noteDelete,
                    onPressed: () => _keep(''),
                    icon: Icon(Icons.delete_outline_rounded, color: p.inkMuted),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ChunkyButton(
                    key: const ValueKey('note-save'),
                    label: l.noteSave,
                    fill: p.inverse,
                    ink: p.onInverse,
                    height: 50,
                    onPressed: () => _keep(_text.text),
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
