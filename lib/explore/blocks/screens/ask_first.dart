/// Ask first — artboard 140e, in two blocks.
///
/// `ask-first` is the question before the cards: "What do you want to
/// understand?" over a field that takes a question in the reader's own
/// words, a few words to try, and the cards that answer it. When nothing
/// does, the question can be kept, and it waits.
///
/// `questions-asked` is the reader's own record of that: every question
/// they kept, set as a conversation — the question, and under it the card
/// that answered it. A question kept with no answer is shown waiting, and
/// is asked of the bank again every time the shelf is drawn, so the day a
/// card answers it, the card is there under it. With nothing kept it is not
/// there at all; `ask-first` can carry the same list under its answers
/// (`style.asked`), where a question kept shows the moment it is.
///
/// What was typed never leaves the phone (docs/TRACKING.md: a search is
/// said by its shape, never its text). The questions are kept by
/// [ScreensMemory]; the notes this block leaves say how many words a
/// question had and how many cards answered it, and nothing else.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../data/pill_bank.dart';
import '../../../l10n/l10n.dart';
import '../../../models/pill.dart';
import '../../../models/place.dart';
import '../../../theme.dart';
import '../../../widgets/card_edge.dart';
import '../../explore_block.dart';
import 'ask_search.dart';
import 'memory.dart';
import 'parts.dart';

/// A host that can answer a question itself — the server's search, say —
/// rather than leave it to the bank on the phone. An [ExploreHost] that
/// also implements this is asked first; one that does not, or that answers
/// null, is answered from the bank the phone holds.
abstract class ScreensSearchHost {
  /// The cards that answer [question], best first, or null when it cannot
  /// say.
  Future<List<Pill>?> search(String question);
}

/// Whether [pill] may be found by a reader who lives at [home]: a card about
/// a place only by those who live there (docs/PLACES.md), as in every search.
bool foundFrom(Pill pill, Place? home) =>
    pill.place == null || placeFit(pill.place!, home) != PlaceFit.none;

/// The cards that answer [question] for the reader of [host], from the bank
/// on the phone: narrowed to the subject Explore is narrowed to.
List<Pill> answersOn(ExploreHost host, String question, {int limit = 30}) =>
    askCards(
      question,
      limit: limit,
      keep: (p) =>
          foundFrom(p, host.app.place) &&
          (host.subject == null || p.topic == host.subject),
    );

/// The ask field, the words to try, and what answers.
class AskFirstBlock extends ExploreBlock {
  const AskFirstBlock();

  @override
  String get name => 'ask-first';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    // The words to try are the section's own, or the first words the
    // cards of its source are filed under, each a search that finds them.
    List<String> tries = sectionWords(section, 'try', host.language);
    if (tries.isEmpty && styleOn(section, 'try')) {
      final Set<String> seen = {};
      tries = [
        for (final Pill p in host.cardsFor(section, limit: 24))
          for (final String k in p.keywords.take(1))
            if (k.length <= 18 && seen.add(k.toLowerCase())) k,
      ].take(6).toList();
    }
    return host.watch(
      section,
      _Ask(
        key: ValueKey('ask-${section.id}'),
        host: host,
        section: section,
        tries: styleOn(section, 'try') ? tries : const [],
        asked: styleOn(section, 'asked', fallback: false),
      ),
    );
  }
}

class _Ask extends StatefulWidget {
  const _Ask({
    super.key,
    required this.host,
    required this.section,
    required this.tries,
    required this.asked,
  });

  final ExploreHost host;
  final ExploreSection section;
  final List<String> tries;

  /// Whether the questions kept are listed under the answers.
  final bool asked;

  @override
  State<_Ask> createState() => _AskState();
}

class _AskState extends State<_Ask> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// The question the answers below are for, once the typing settles.
  String _asked = '';
  List<Pill> _found = const [];

  /// Whether the question with no answer has been kept.
  bool _kept = false;
  Timer? _settle;

  /// Answers that came back for a question since retyped are not shown.
  int _asking = 0;

  @override
  void dispose() {
    _settle?.cancel();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _typed(String text) {
    _settle?.cancel();
    setState(() {});
    if (text.trim().isEmpty) {
      setState(() {
        _asked = '';
        _found = const [];
        _kept = false;
      });
      return;
    }
    _settle = Timer(const Duration(milliseconds: 280), () => _ask(text));
  }

  /// Finds the answers to [text]. A question the reader [sent] — with the
  /// keyboard's search, or a word to try — is noted; the answers that come
  /// up as they type are not, or one question would be noted at every
  /// pause in the typing.
  Future<void> _ask(String text, {bool sent = false}) async {
    final String question = text.trim();
    final int asking = ++_asking;
    final ExploreHost host = widget.host;
    final int most = widget.section.limit ?? 5;
    List<Pill>? hits;
    if (host is ScreensSearchHost) {
      try {
        hits = await (host as ScreensSearchHost).search(question);
      } catch (_) {
        hits = null;
      }
      hits = hits
          ?.where(
            (p) =>
                foundFrom(p, host.app.place) &&
                (host.subject == null || p.topic == host.subject),
          )
          .toList();
    }
    hits ??= answersOn(host, question, limit: most);
    if (!mounted || asking != _asking) return;
    setState(() {
      _asked = question;
      _found = hits!.take(most).toList();
      _kept = false;
    });
    if (!sent) return;
    host.note(widget.section, 'asked', {
      'words': askWords(question).length,
      'results': _found.length,
    });
  }

  void _try(String word) {
    tickPicked();
    _field.text = word;
    _field.selection = TextSelection.collapsed(offset: word.length);
    _settle?.cancel();
    _ask(word, sent: true);
  }

  void _clear() {
    _settle?.cancel();
    _field.clear();
    setState(() {
      _asked = '';
      _found = const [];
      _kept = false;
    });
  }

  String get _today => screensDayKey(DateTime.now());

  void _open(Pill pill) {
    ScreensMemory.instance.keep(_asked, cardId: pill.id, on: _today);
    widget.host.note(widget.section, 'asked', {
      'words': askWords(_asked).length,
      'results': _found.length,
      'opened': _found.indexOf(pill) + 1,
    });
    widget.host.open(widget.section, _found, pill);
  }

  void _keep() {
    tickDone();
    ScreensMemory.instance.keep(_asked, on: _today);
    widget.host.note(widget.section, 'asked', {
      'words': askWords(_asked).length,
      'results': 0,
      'kept': true,
    });
    setState(() => _kept = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final ExploreSection section = widget.section;
    final String language = widget.host.language;
    final ScreenSize size = screenSizeOf(section);
    for (final Pill pill in _found) {
      widget.host.seen(section, pill);
    }
    final bool typed = _field.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (size != ScreenSize.s) ...[
                Text(
                  section.title(language) ?? l.screensAskTitle,
                  style: AppText.display(
                    size: bySize(size, s: 22, m: 26, l: 30),
                    weight: FontWeight.w600,
                    height: 1.12,
                    spacing: -0.7,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _input(context, typed, section.text('hint', language)),
              if (widget.tries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Kicker(l.screensAskTry),
                    ),
                    for (final String word in widget.tries)
                      _TryChip(word: word, onTap: () => _try(word)),
                  ],
                ),
              ],
            ],
          ),
        ),
        AnimatedSize(
          duration: paced(context, 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _asked.isEmpty || !typed
              ? const SizedBox(width: double.infinity)
              : _found.isEmpty
              ? _nothing(context)
              : _answers(context, size),
        ),
        if (widget.asked)
          ListenableBuilder(
            listenable: ScreensMemory.instance..open(),
            builder: (context, _) => _Asked(
              host: widget.host,
              section: section,
              memory: ScreensMemory.instance,
              title: l.screensAskedTitle,
              line: l.screensAskedLine,
              most: 3,
              top: 28,
            ),
          ),
      ],
    );
  }

  // The field, drawn as the canvas draws it: a well with a hairline, the
  // search mark, and the clear button once there is something to clear.
  Widget _input(BuildContext context, bool typed, String? hint) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
      decoration: BoxDecoration(
        color: p.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.ink.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: p.ink.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: ValueKey('ask-field-${widget.section.id}'),
              controller: _field,
              focusNode: _focus,
              onChanged: _typed,
              onSubmitted: (text) {
                _settle?.cancel();
                if (text.trim().isNotEmpty) _ask(text, sent: true);
              },
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.sentences,
              // A question is a sentence: it wraps where a word would
              // scroll, up to three lines, so all of it can be read back.
              minLines: 1,
              maxLines: 3,
              style: AppText.body(
                size: 15,
                weight: FontWeight.w500,
                color: p.ink,
              ),
              cursorColor: p.ink,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                hintText: hint ?? l.screensAskHint,
                hintStyle: AppText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  color: p.inkFaint,
                ),
              ),
            ),
          ),
          if (typed)
            Semantics(
              button: true,
              label: l.screensAskClear,
              child: GestureDetector(
                key: ValueKey('ask-clear-${widget.section.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: _clear,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: p.ink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: p.ink.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _answers(BuildContext context, ScreenSize size) {
    final l = context.l10n;
    return Padding(
      key: const ValueKey('ask-answers'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.screensAskFound(_found.length),
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1.2,
              color: context.p.ink.withValues(alpha: 0.5),
            ),
          ),
          for (final Pill pill in _found) ...[
            const SizedBox(height: 10),
            _Answer(
              pill: pill,
              size: size,
              read: widget.host.isRead(pill),
              onTap: () => _open(pill),
            ),
          ],
        ],
      ),
    );
  }

  Widget _nothing(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Padding(
      key: const ValueKey('ask-nothing'),
      padding: const EdgeInsets.only(top: 22),
      child: ScreenPanel(
        padding: const EdgeInsets.all(18),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.screensAskNone,
              style: AppText.display(
                size: 19,
                weight: FontWeight.w600,
                height: 1.2,
                spacing: -0.4,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.screensAskNoneLine,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w500,
                height: 1.45,
                color: p.ink.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            PillButton(
              key: ValueKey('ask-keep-${widget.section.id}'),
              label: _kept ? l.screensAskKept : l.screensAskKeep,
              icon: _kept ? Icons.check_rounded : null,
              background: _kept ? p.ink.withValues(alpha: 0.1) : p.inverse,
              foreground: _kept ? p.ink : p.onInverse,
              onTap: _kept ? null : _keep,
            ),
          ],
        ),
      ),
    );
  }
}

class _TryChip extends StatelessWidget {
  const _TryChip({required this.word, required this.onTap});

  final String word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey('ask-try-$word'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: p.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            word,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1.2,
              color: p.ink.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card that answers: its head and its question, on its colour.
class _Answer extends StatelessWidget {
  const _Answer({
    required this.pill,
    required this.size,
    required this.read,
    required this.onTap,
  });

  final Pill pill;
  final ScreenSize size;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double type = bySize(size, s: 14, m: 15.5, l: 17);
    return CardTap(
      pill: pill,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: cardFace(context, pill.color, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaceHead(
              pill: pill,
              trailing: read ? ReadMark(pill: pill, size: 13) : null,
            ),
            const SizedBox(height: 9),
            Text(
              pill.question,
              style: AppText.display(
                size: type,
                weight: FontWeight.w600,
                height: 1.16,
                spacing: -0.025 * type,
                color: pill.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The questions the reader kept, and the cards that answered them.
class QuestionsAskedBlock extends ExploreBlock {
  const QuestionsAskedBlock();

  @override
  String get name => 'questions-asked';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final ScreensMemory memory = ScreensMemory.instance..open();
    // Nothing kept, no shelf, title and all. Once there is, it follows the
    // store: a question forgotten goes at once, and one kept elsewhere
    // shows the next time Explore is drawn. Before the store is reached
    // nothing can be known, so the shelf waits for it rather than leaving
    // Explore without it.
    if (memory.isOpen && memory.asked.isEmpty) return null;
    final l = context.l10n;
    return host.watch(
      section,
      ListenableBuilder(
        listenable: memory,
        builder: (context, _) => _Asked(
          host: host,
          section: section,
          memory: memory,
          title: section.title(host.language) ?? l.screensAskedTitle,
          line: section.subtitle(host.language) ?? l.screensAskedLine,
          most: section.limit ?? 3,
        ),
      ),
    );
  }
}

class _Asked extends StatelessWidget {
  const _Asked({
    required this.host,
    required this.section,
    required this.memory,
    required this.title,
    required this.line,
    required this.most,
    this.top = 0,
  });

  final ExploreHost host;
  final ExploreSection section;
  final ScreensMemory memory;
  final String title;
  final String line;

  /// The most questions listed, newest first.
  final int most;

  /// Above the list, where it follows something else.
  final double top;

  @override
  Widget build(BuildContext context) {
    final List<AskedQuestion> all = memory.asked;
    final List<AskedQuestion> shown = all.take(most).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final ScreenSize size = screenSizeOf(section);
    // The card that answered each, or the first that answers it now.
    final List<Pill?> answers = [
      for (final AskedQuestion q in shown)
        q.cardId != null
            ? PillBank.byId(q.cardId!)
            : answersOn(host, q.question, limit: 1).firstOrNull,
    ];
    final List<Pill> shelf = [...answers.nonNulls];
    for (final Pill pill in shelf) {
      host.seen(section, pill);
    }
    final Widget list = ScreenShelf(
      head: styleOn(section, 'head'),
      title: title,
      line: line,
      gap: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _Exchange(
                key: ValueKey('asked-$i-${shown[i].question.hashCode}'),
                question: shown[i].question,
                answer: answers[i],
                size: size,
                read: answers[i] != null && host.isRead(answers[i]!),
                onOpen: answers[i] == null
                    ? null
                    : () => host.open(section, shelf, answers[i]!),
                onForget: () => _forget(context, all.indexOf(shown[i])),
              ),
            ],
          ],
        ),
      ),
    );
    return top == 0
        ? list
        : Padding(
            padding: EdgeInsets.only(top: top),
            child: list,
          );
  }

  void _forget(BuildContext context, int index) {
    final l = context.l10n;
    tickDone();
    final AskedQuestion? gone = memory.forget(index);
    host.note(section, 'asked forgotten', const {});
    if (gone == null) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l.screensAskedForgotten),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () => memory.restore(index, gone),
        ),
      ),
    );
  }
}

/// One question and its answer: the question on the right, as typed, the
/// card under it on the left, as a reply.
class _Exchange extends StatelessWidget {
  const _Exchange({
    super.key,
    required this.question,
    required this.answer,
    required this.size,
    required this.read,
    required this.onOpen,
    required this.onForget,
  });

  final String question;
  final Pill? answer;
  final ScreenSize size;
  final bool read;
  final VoidCallback? onOpen;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final double type = bySize(size, s: 13.5, m: 14.5, l: 16);
    return LayoutBuilder(
      builder: (context, box) {
        final double wide = box.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                customSemanticsActions: {
                  CustomSemanticsAction(label: l.screensAskedForget): onForget,
                },
                child: GestureDetector(
                  onLongPress: onForget,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: wide * 0.78),
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    decoration: BoxDecoration(
                      color: p.inverse,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Text(
                      question,
                      style: AppText.body(
                        size: 13.5,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: p.onInverse,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide * 0.86),
                child: answer == null
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(18),
                          ),
                          border: Border.all(
                            color: p.ink.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          l.screensAskedWaiting,
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w500,
                            height: 1.4,
                            color: p.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : CardTap(
                        pill: answer!,
                        onTap: onOpen!,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration:
                              cardFace(
                                context,
                                answer!.color,
                                radius: 18,
                              ).copyWith(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(6),
                                  bottomRight: Radius.circular(18),
                                ),
                              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FaceHead(
                                pill: answer!,
                                markSize: 14,
                                after: l.screensAskedAnswered,
                                trailing: read
                                    ? ReadMark(pill: answer!, size: 13)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                answer!.question,
                                style: AppText.display(
                                  size: type,
                                  weight: FontWeight.w600,
                                  height: 1.18,
                                  spacing: -0.3,
                                  color: answer!.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
