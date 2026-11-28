import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/genre_names.dart';
import '../data/genres.dart';
import '../data/topics.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/balanced_text.dart';
import '../widgets/fit_text.dart';
import '../widgets/subject_icon.dart';
import 'mix_screen.dart';
import '../widgets/ui.dart';

/// Artboard 86a: the mix, one layer down — Which parts.
///
/// Your mix asks how much of each subject, which is as fine as a subject
/// goes — two readers both ask for Space and one of them means rockets while
/// the other means how big the thing is. This is where they say which. Six
/// genres a subject, three strands inside each genre, and everything starts
/// on: the reader is turning things down rather than building a deck out of
/// nothing, the same way the mix works.
///
/// It used to be the first run's third question, two hundred genres and
/// their strands before a single card, which a tester found too many. It is
/// offered instead, once, on the finished day's shelf from the third
/// finished day (lib/widgets/parts_offer.dart), and opens over it as a page
/// of its own; the fine-tuning under the topics editor ([TuneScreen]) has
/// the same parts whenever the reader wants them.
///
/// The subjects are in the order of the reader's mix, and a subject asked
/// for more is drawn larger — the screen is a reading of the mix rather than
/// a second, unrelated list. A subject left out of the mix keeps a line at
/// the foot of the list, dimmed, so it is quiet rather than gone.
class GenresScreen extends StatefulWidget {
  final AppState app;

  /// The genres and strands turned off, handed over once at the end. A chip
  /// is not a decision until the reader leaves the screen.
  final void Function(Set<String> genresOff, Set<String> strandsOff) onDone;

  /// The way back, which keeps nothing.
  final VoidCallback onBack;

  const GenresScreen({
    super.key,
    required this.app,
    required this.onDone,
    required this.onBack,
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
    // A subject in the mix with no weight of its own is all the way in, as
    // the fine-tuning reads it: a mix never set is every picked subject in.
    final Map<String, double> mix = widget.app.topicWeights;
    final Set<String> picked = widget.app.pickedTopics;
    final list = [
      for (final key in kGenres.keys)
        (key, picked.contains(key) ? (mix[key] ?? 1.0) : 0.0),
    ];
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

  /// The page's own theme: dark, whatever the phone's, as the mix's bars
  /// and parts are wherever they are shown: the colours are drawn for black.
  static final ThemeData _dark = buildAstutoTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) => Theme(
    data: _dark,
    child: Builder(builder: _page),
  );

  Widget _page(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;

    return ScreenView(
      name: 'genres',
      child: Scaffold(
        backgroundColor: p.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // The way back stays put above what scrolls, as on the other
              // pages pushed over the tabs.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BackCircle(onPressed: widget.onBack),
                ),
              ),
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
                                // Its own question. It used to repeat the mix's
                                // "Your mix", so the page read as the same one
                                // again.
                                Text(
                                  l.genresTitle,
                                  style: AppText.display(
                                    size: 28,
                                    weight: FontWeight.w600,
                                    spacing: -0.9,
                                    color: p.ink,
                                  ),
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
                              ? GenreSubject(
                                  topicKey: key,
                                  weight: weight,
                                  genresOff: _genresOff,
                                  strandsOff: _strandsOff,
                                  open: _open,
                                  onTapGenre: _toggleGenre,
                                  onHoldGenre: _openGenre,
                                  onTapStrand: _toggleStrand,
                                )
                              : GenreSubjectOff(topicKey: key),
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
                              colors: [
                                p.surface.withValues(alpha: 0),
                                p.surface,
                              ],
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
                      key: const ValueKey('genres-done'),
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
      ),
    );
  }
}

/// One subject in the mix: its planet, its six, and whatever is open under
/// them. The onboarding's list is made of these, and so is the
/// fine-tuning's ([TuneScreen]), which hands it what the reader liked.
class GenreSubject extends StatelessWidget {
  final String topicKey;
  final double weight;
  final Set<String> genresOff;
  final Set<String> strandsOff;
  final Set<String> open;
  final ValueChanged<Genre> onTapGenre;
  final ValueChanged<Genre> onHoldGenre;
  final ValueChanged<Strand> onTapStrand;

  const GenreSubject({
    super.key,
    required this.topicKey,
    required this.weight,
    required this.genresOff,
    required this.strandsOff,
    required this.open,
    required this.onTapGenre,
    required this.onHoldGenre,
    required this.onTapStrand,
    this.taste = const {},
    this.hint,
    this.hintLine,
  });

  /// The reader's lean on each trait ([AppState.taste]): the genres they
  /// liked come first, and are marked. Empty, the six keep their order.
  final Map<String, double> taste;

  /// The hint that holding a genre opens it, played on the first of them, 0
  /// to 1: a fingertip on the chip and its outline traced for as long as a
  /// hold takes ([kHoldHintPress]), what is inside unfolding under it with
  /// [hintLine], and folding away again ([kHoldHintFold]). Null when no
  /// hint is playing.
  final Animation<double>? hint;

  /// The line the hint says. Without [hint], it is said alone and still,
  /// under the genres: the hint for a reader who asked for less motion.
  final String? hintLine;

  /// The six, the ones the reader leaned towards first. Ties keep the
  /// order the subject lists them in.
  List<Genre> _ordered(List<Genre> genres) {
    if (taste.isEmpty) return genres;
    double lean(Genre g) => taste['genre:${g.id}'] ?? 0;
    final indexed = [for (var i = 0; i < genres.length; i++) (i, genres[i])];
    indexed.sort((a, b) {
      final int by = lean(b.$2).compareTo(lean(a.$2));
      return by != 0 ? by : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }

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
    final List<Genre> genres = _ordered(kGenres[topicKey]!);

    // A subject asked for more is drawn larger. It is the one thing on this
    // screen that carries the wheel's answer rather than asking a new
    // question, so it is worth the pixels.
    final double planet = 26 + weight * 35;
    final int on = genres.where((g) => !genresOff.contains(g.id)).length;
    // Every genre tapped off is the subject off: grey, and said so, rather
    // than a lit planet over "0 of 6 on".
    final bool dark = on == 0;

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
                  color: dark ? p.lineStrong : style.color,
                  shape: BoxShape.circle,
                  boxShadow: dark
                      ? null
                      : [
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
                  ink: dark ? p.inkFaint : style.ink,
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
                      l.subjectOf(style.name),
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        spacing: -0.2,
                        color: dark ? p.inkFaint : p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dark
                        ? l.offInYourMix
                        : '${_level(l)} · ${l.nOfSixOn(on, genres.length)}',
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
                    _held(
                      genre == genres.first ? hint : null,
                      _GenreChip(
                        genre: genre,
                        colour: style.color,
                        ink: style.ink,
                        liked: (taste['genre:${genre.id}'] ?? 0) > 0,
                        off: genresOff.contains(genre.id),
                        strandsOff: genre.strands
                            .where((s) => strandsOff.contains(s.id))
                            .length,
                        onTap: () => onTapGenre(genre),
                        onHold: () => onHoldGenre(genre),
                      ),
                    ),
                ],
              ),
              if (hint case final Animation<double> playing
                  when !open.contains(genres.first.id))
                _HintBloom(
                  animation: playing,
                  line: hintLine,
                  colour: style.color,
                  child: _Inside(
                    genre: genres.first,
                    colour: style.color,
                    strandsOff: strandsOff,
                    genreOff: genresOff.contains(genres.first.id),
                    onTapStrand: onTapStrand,
                  ),
                )
              else if (hint == null && hintLine != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _HintLine(line: hintLine!, colour: style.color),
                ),
              // What a hold opens unfolds into place, downwards only, and
              // folds away. As wide as the row from the first frame: grown
              // from nothing in width as well, it showed its words cut off
              // at a slant ("DENTRO TRUCC") for the first part of the turn.
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// [chip], pressed by the hint when one is playing on it.
Widget _held(Animation<double>? hint, Widget chip) =>
    hint == null ? chip : _PressHint(animation: hint, child: chip);

/// Where the hint's press ends and what is inside starts to unfold, on its
/// timeline of 0 to 1.
const double kHoldHintPress = 0.2;

/// Where what the hint unfolded starts to fold away again.
const double kHoldHintFold = 0.76;

/// The part of [t] that falls between [from] and [to], 0 to 1, through
/// [curve].
double _between(
  double t,
  double from,
  double to, [
  Curve curve = Curves.linear,
]) => curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

/// The press of the hint on the first chip: a fingertip on it, the chip
/// sinking a little under it while a line goes once round its edge — as
/// long as a hold takes — and then let go, as what is inside opens.
class _PressHint extends AnimatedWidget {
  const _PressHint({required Animation<double> animation, required this.child})
    : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;
    final double down = _between(t, 0.04, kHoldHintPress, Curves.easeInOut);
    final double up = _between(
      t,
      kHoldHintPress,
      kHoldHintPress + 0.1,
      Curves.easeOutBack,
    );
    return CustomPaint(
      foregroundPainter: _PressPainter(
        touch: _between(t, 0.01, 0.07, Curves.easeOut),
        traced: down,
        let: _between(t, kHoldHintPress, kHoldHintPress + 0.1, Curves.easeOut),
        ink: context.p.ink,
      ),
      child: Transform.scale(scale: 1 - 0.05 * down * (1 - up), child: child),
    );
  }
}

class _PressPainter extends CustomPainter {
  const _PressPainter({
    required this.touch,
    required this.traced,
    required this.let,
    required this.ink,
  });

  /// How far the fingertip has come down, 0 to 1.
  final double touch;

  /// How much of the chip's edge the line has gone round, 0 to 1.
  final double traced;

  /// How far the press has been let go, 0 to 1: the fingertip spreads and
  /// fades, and the line with it.
  final double let;

  /// The page's ink, the line's colour.
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final double gone = 1 - let;
    if (gone <= 0) return;
    // The fingertip, a soft disc of light on the chip.
    final Offset centre = size.center(Offset.zero);
    final double r = size.height * (0.38 + 0.12 * touch + 0.5 * let);
    canvas.drawCircle(
      centre,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.34 * touch * gone),
    );
    // The edge, gone round once from the top, clockwise, as a hold is held.
    if (traced > 0) {
      final Rect around = (Offset.zero & size).inflate(3.5);
      final double r = around.height / 2;
      final Path path = Path()
        ..moveTo(around.center.dx, around.top)
        ..lineTo(around.right - r, around.top)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(around.right - r, around.center.dy),
            radius: r,
          ),
          -math.pi / 2,
          math.pi,
          false,
        )
        ..lineTo(around.left + r, around.bottom)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(around.left + r, around.center.dy),
            radius: r,
          ),
          math.pi / 2,
          math.pi,
          false,
        )
        ..close();
      final Paint line = Paint()
        ..color = ink.withValues(alpha: 0.9 * gone)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (final PathMetric metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * traced), line);
      }
    }
  }

  @override
  bool shouldRepaint(_PressPainter old) =>
      old.touch != touch ||
      old.traced != traced ||
      old.let != let ||
      old.ink != ink;
}

/// What the hint's press opens: [child], the first genre's inside, with the
/// hint's line over it, unfolding as the press is let go and folding away
/// again.
class _HintBloom extends AnimatedWidget {
  const _HintBloom({
    required Animation<double> animation,
    required this.line,
    required this.colour,
    required this.child,
  }) : super(listenable: animation);

  final String? line;
  final Color colour;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;
    final double open =
        _between(
          t,
          kHoldHintPress,
          kHoldHintPress + 0.13,
          Curves.easeOutCubic,
        ) *
        (1 -
            _between(
              t,
              kHoldHintFold,
              kHoldHintFold + 0.14,
              Curves.easeInOutCubic,
            ));
    if (open <= 0) return const SizedBox.shrink();
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: open,
        child: Opacity(
          opacity: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (line case final String said)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _HintLine(line: said, colour: colour),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// The hint's line, after a small drawing of a fingertip held down: a dot
/// in the subject's colour, ringed.
class _HintLine extends StatelessWidget {
  const _HintLine({required this.line, required this.colour});

  final String line;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Row(
      key: const ValueKey('genre-hold-hint'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Container(
            width: 14,
            height: 14,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colour, width: 1.3),
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: BalancedText(
            line,
            style: AppText.body(
              size: 12,
              weight: FontWeight.w600,
              height: 1.3,
              color: p.ink,
            ),
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

  /// The reader has liked cards of this genre: a small heart before its
  /// name says why it came first.
  final bool liked;
  final int strandsOff;
  final VoidCallback onTap;
  final VoidCallback onHold;

  const _GenreChip({
    required this.genre,
    required this.colour,
    required this.ink,
    required this.off,
    this.liked = false,
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
      label: context.l10n.themeOf(genre),
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
              if (liked) ...[
                Icon(Icons.favorite_rounded, size: 10, color: label),
                const SizedBox(width: 5),
              ],
              // Flexible, because a genre's name is written with the content
              // and the chip is not. Most are two words; "Where things come
              // from" is five, and on a narrow phone, at a large text size or
              // in Russian it is wider than the line it has to sit on. It
              // sets itself a size or two smaller first, and gives up its
              // own tail only past that, rather than run off the card.
              Flexible(
                child: FitText(
                  context.l10n.themeOf(genre),
                  maxLines: 1,
                  minSize: 9.5,
                  ellipsis: true,
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
                '${context.l10n.insideGenre} ${context.l10n.themeOf(genre)}'
                    .toUpperCase(),
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
      label: context.l10n.strandOf(strand),
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
                  context.l10n.strandOf(strand),
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
class GenreSubjectOff extends StatelessWidget {
  final String topicKey;

  const GenreSubjectOff({super.key, required this.topicKey});

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
            '${context.l10n.subjectOf(kTopics[topicKey]!.name)} · ${context.l10n.offInYourMix}',
            style: AppText.body(size: 13, color: p.inkFaint),
          ),
        ),
      ],
    );
  }
}
