import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/genres.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/subject_icon.dart';
import 'mix_screen.dart';
import '../widgets/ui.dart';

/// Artboard 86a: the mix, one layer down.
///
/// The wheel before this one asks how much of each subject, which is as fine
/// as a subject goes — two readers both ask for Space and one of them means
/// rockets while the other means how big the thing is. This is where they say
/// which. Six genres a subject, three strands inside each genre, and
/// everything starts on: the reader is turning things down rather than
/// building a deck out of nothing, the same way the wheel works.
///
/// The subjects are in the order the reader just put them in, and a subject
/// asked for more is drawn larger — the screen is a reading of the wheel
/// rather than a second, unrelated list. A subject left out of the mix keeps
/// a line at the foot of the list, dimmed, so it is quiet rather than gone.
class GenresScreen extends StatefulWidget {
  final AppState app;

  /// The genres and strands turned off, handed over once at the end. A chip
  /// is not a decision until the reader leaves the screen.
  final void Function(Set<String> genresOff, Set<String> strandsOff) onDone;

  /// Walked past. Everything stays on, which is what it already was.
  final VoidCallback onSkip;

  const GenresScreen({
    super.key,
    required this.app,
    required this.onDone,
    required this.onSkip,
  });

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  /// Copies, not the state's own sets: a chip tapped and tapped back should
  /// leave nothing behind if the reader backs out of the screen.
  late final Set<String> _genresOff = {...widget.app.genresOff};
  late final Set<String> _strandsOff = {...widget.app.strandsOff};

  /// Which genres have their three open. More than one may be, because
  /// closing the last one on every hold would take away the comparison the
  /// reader opened the second one to make.
  final Set<String> _open = {};

  @override
  void initState() {
    super.initState();
    Analytics.capture('genres shown', {
      'subjects_in_mix': _subjects.where((s) => s.$2 > 0).length,
    });
  }

  /// The subjects, most asked-for first, each with the weight the wheel gave
  /// it. A subject the reader dragged to nothing is weight zero and sinks to
  /// the bottom of the list on its own.
  List<(String, double)> get _subjects {
    final Map<String, double> mix = widget.app.topicWeights;
    final list = [for (final key in kGenres.keys) (key, mix[key] ?? 0.0)];
    list.sort((a, b) {
      final int byWeight = b.$2.compareTo(a.$2);
      if (byWeight != 0) return byWeight;
      // Ties keep the order of the grid the reader was just looking at.
      //
      // This matters more than it sounds. The wheel starts every subject all
      // the way in, so a reader who drags three of them down leaves fifteen
      // at exactly the same weight — and that tie is most of the list. Broken
      // by kTopicOrder it came out in an order the reader had never seen:
      // science, space, psychology… against a grid that reads economics,
      // sport, nature. The screen looked like it had ignored the wheel,
      // because the only part of it the reader could see was the part that
      // owed nothing to them.
      return _onTheGrid(a.$1).compareTo(_onTheGrid(b.$1));
    });
    return list;
  }

  /// Where a subject sat on the wheel. Anything the grid does not carry goes
  /// last rather than first, which is the safe end for a subject nobody was
  /// offered.
  static int _onTheGrid(String key) {
    final int at = kMixSubjects.indexWhere((s) => s.key == key);
    return at < 0 ? kMixSubjects.length : at;
  }

  int get _genresOn => kAllGenres.length - _genresOff.length;

  void _toggleGenre(Genre genre) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_genresOff.remove(genre.id)) _genresOff.add(genre.id);
    });
  }

  void _openGenre(Genre genre) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (!_open.remove(genre.id)) _open.add(genre.id);
    });
  }

  void _toggleStrand(Strand strand) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_strandsOff.remove(strand.id)) _strandsOff.add(strand.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;

    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // The head scrolls with the subjects rather than sitting
                  // over them: it is the first thing on the page, not a bar.
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _subjects.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l.yourMix,
                                      style: AppText.display(
                                        size: 28,
                                        weight: FontWeight.w600,
                                        spacing: -0.9,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                  // Level with the title, ending the same
                                  // distance from the edge as on the intro
                                  // and the mix.
                                  SkipCorner(onTap: widget.onSkip, inset: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.genresLine,
                                style: AppText.body(
                                  size: 12.5,
                                  height: 1.4,
                                  color: p.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final (String key, double weight) = _subjects[i - 1];
                      return Padding(
                        padding: EdgeInsets.only(top: i > 1 ? 20 : 0),
                        child: weight > 0
                            ? _Subject(
                                topicKey: key,
                                weight: weight,
                                genresOff: _genresOff,
                                strandsOff: _strandsOff,
                                open: _open,
                                onTapGenre: _toggleGenre,
                                onHoldGenre: _openGenre,
                                onTapStrand: _toggleStrand,
                              )
                            : _SubjectOff(topicKey: key),
                      );
                    },
                  ),
                  // The list runs under the footer rather than stopping short
                  // of it, so it reads as continuing rather than as ending on
                  // whatever row the scroll happened to leave there.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 36,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [p.surface.withValues(alpha: 0), p.surface],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  PrimaryButton(
                    label: l.continueGenresOn(_genresOn, kAllGenres.length),
                    height: 54,
                    onPressed: () => widget.onDone(_genresOff, _strandsOff),
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

/// One subject in the mix: its planet, its six, and whatever is open under
/// them.
class _Subject extends StatelessWidget {
  final String topicKey;
  final double weight;
  final Set<String> genresOff;
  final Set<String> strandsOff;
  final Set<String> open;
  final ValueChanged<Genre> onTapGenre;
  final ValueChanged<Genre> onHoldGenre;
  final ValueChanged<Strand> onTapStrand;

  const _Subject({
    required this.topicKey,
    required this.weight,
    required this.genresOff,
    required this.strandsOff,
    required this.open,
    required this.onTapGenre,
    required this.onHoldGenre,
    required this.onTapStrand,
  });

  /// How much of the wheel this subject got, as one of five words.
  String _level(AppLocalizations l) =>
      switch ((weight * 5).ceil().clamp(1, 5)) {
        1 => l.mixRarely,
        2 => l.mixSometimes,
        3 => l.mixOften,
        4 => l.mixALot,
        _ => l.mixFull,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final TopicStyle style = kTopics[topicKey]!;
    final List<Genre> genres = kGenres[topicKey]!;

    // A subject asked for more is drawn larger. It is the one thing on this
    // screen that carries the wheel's answer rather than asking a new
    // question, so it is worth the pixels.
    final double planet = 26 + weight * 35;
    final int on = genres.where((g) => !genresOff.contains(g.id)).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Center(
              child: Container(
                width: planet,
                height: planet,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withValues(alpha: 0.6),
                      blurRadius: 26,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SubjectIcon(
                  subject: style.name,
                  size: planet * 0.5,
                  ink: style.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      style.name,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        spacing: -0.2,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_level(l)} · ${l.nOfSixOn(on)}',
                    style: AppText.body(size: 10.5, color: p.inkFaint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final genre in genres)
                    _GenreChip(
                      genre: genre,
                      colour: style.color,
                      ink: style.ink,
                      off: genresOff.contains(genre.id),
                      strandsOff: genre.strands
                          .where((s) => strandsOff.contains(s.id))
                          .length,
                      onTap: () => onTapGenre(genre),
                      onHold: () => onHoldGenre(genre),
                    ),
                ],
              ),
              for (final genre in genres)
                if (open.contains(genre.id))
                  _Inside(
                    genre: genre,
                    colour: style.color,
                    strandsOff: strandsOff,
                    genreOff: genresOff.contains(genre.id),
                    onTapStrand: onTapStrand,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One of the six. Tap to skip it, hold to see what is inside.
class _GenreChip extends StatelessWidget {
  final Genre genre;
  final Color colour;
  final Color ink;
  final bool off;
  final int strandsOff;
  final VoidCallback onTap;
  final VoidCallback onHold;

  const _GenreChip({
    required this.genre,
    required this.colour,
    required this.ink,
    required this.off,
    required this.strandsOff,
    required this.onTap,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    // On, it is the subject's own colour. Off, it is a hairline with nothing
    // in it — the difference has to be readable at a glance across six chips
    // and eighteen subjects, so it is fill against no fill rather than two
    // shades of the same thing.
    final Color background = off ? Colors.transparent : colour;
    final Color label = off ? p.inkMuted : ink;

    return Semantics(
      button: true,
      toggled: !off,
      label: genre.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onHold,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: off ? p.lineStrong : Colors.transparent),
          ),
          // No alignment: a Container given one takes all the width it is
          // offered, and six chips that each fill the row are a list rather
          // than the row of six this is meant to be.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flexible, because a genre's name is written with the content
              // and the chip is not. Most are two words; "Where things come
              // from" is five, and on a narrow phone or at a large text size
              // it is wider than the line it has to sit on. It gives up its
              // own tail rather than running off the card.
              Flexible(
                child: Text(
                  genre.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: label,
                  ),
                ),
              ),
              // Only when some of the three are off. A chip that says "3" on
              // every genre says nothing; one that says "2" says the reader
              // has been inside this one and changed something.
              if (!off && strandsOff > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${genre.strands.length - strandsOff}',
                    style: AppText.label(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: label,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The three, opened in place under the row rather than over it.
///
/// A sheet would cover the six the reader is comparing against and cost a
/// Done button to get back from. This keeps the list exactly where it was.
class _Inside extends StatelessWidget {
  final Genre genre;
  final Color colour;
  final Set<String> strandsOff;
  final bool genreOff;
  final ValueChanged<Strand> onTapStrand;

  const _Inside({
    required this.genre,
    required this.colour,
    required this.strandsOff,
    required this.genreOff,
    required this.onTapStrand,
  });

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 16, height: 1, color: colour),
              const SizedBox(width: 8),
              Text(
                '${context.l10n.insideGenre} ${genre.label}'.toUpperCase(),
                style: AppText.label(
                  size: 9,
                  weight: FontWeight.w700,
                  spacing: 1.2,
                  color: p.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final strand in genre.strands) ...[
            _StrandRow(
              strand: strand,
              colour: colour,
              // A strand under a genre that is off is off with it, and says
              // so rather than offering a choice that changes nothing.
              off: genreOff || strandsOff.contains(strand.id),
              onTap: genreOff ? null : () => onTapStrand(strand),
            ),
            if (strand != genre.strands.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _StrandRow extends StatelessWidget {
  final Strand strand;
  final Color colour;
  final bool off;
  final VoidCallback? onTap;

  const _StrandRow({
    required this.strand,
    required this.colour,
    required this.off,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      toggled: !off,
      label: strand.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: off ? Colors.transparent : colour.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: off ? p.line : Colors.transparent),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: off ? p.lineStrong : colour,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  strand.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: off ? p.inkMuted : p.ink,
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

/// A subject the wheel left out. It keeps a line so the list is the whole
/// wheel rather than the part of it that survived — a subject that vanishes
/// reads as one the app does not have.
class _SubjectOff extends StatelessWidget {
  final String topicKey;

  const _SubjectOff({required this.topicKey});

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: p.lineStrong, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            '${kTopics[topicKey]!.name} · ${context.l10n.offInYourMix}',
            style: AppText.body(size: 13, color: p.inkFaint),
          ),
        ),
      ],
    );
  }
}
