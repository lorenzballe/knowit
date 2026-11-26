import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import '../data/genres.dart';
import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/fit_text.dart';
import '../widgets/ui.dart';
import 'genres_screen.dart';
import 'mix_screen.dart';

/// The mix, fine-tuned: the onboarding's two answers again, on one page
/// under the topics editor — how much of each subject (the bars), and which
/// parts of each (the six, and the three inside them).
///
/// Not the answers as they were given. A reader who has been here a while
/// has liked cards and thrown cards away, and the personal deals have
/// leaned their mix by it ([AppState.leanedWeights], [AppState.taste]). The
/// bars start where that left them, so a subject the reader keeps liking is
/// already longer than the rest, and a thin line on the tile keeps where
/// the reader had put it themselves. Inside each subject the parts they
/// liked come first, with a heart. The page shows what the app has learned
/// and lets the reader correct it, instead of asking the first-day question
/// again as if nothing had happened since.
///
/// Saved whole when the reader says so, never a bar at a time: a mix half
/// dragged is not an answer yet.
///
/// One page, scrolled whole, the button at its foot: only the way back
/// stays where it is, as iOS keeps its own, with the page fading under it
/// once it has scrolled. The first time the parts of the subjects come to
/// rest on screen, the first of them shows what holding one does: pressed,
/// it opens what is inside under it, says so in a line, and folds again.
class TuneScreen extends StatefulWidget {
  const TuneScreen({super.key, required this.app, required this.picked});

  final AppState app;

  /// The subjects in the mix as the editor under this page has them now,
  /// chips the reader toggled included: the page starts from what they are
  /// looking at, not from what was last saved.
  final Set<String> picked;

  @override
  State<TuneScreen> createState() => _TuneScreenState();
}

class _TuneScreenState extends State<TuneScreen>
    with SingleTickerProviderStateMixin {
  AppState get app => widget.app;

  /// Where it is kept that the hint has been shown, once for good.
  static const String _kHoldHint = 'knowit.tuneHoldHint';

  /// How long the hint takes: a press as long as a hold, what is inside
  /// open long enough to read, and folded away.
  static const Duration _hintTime = Duration(milliseconds: 3800);

  /// How far the page has scrolled under the way back, 0 to 1: what the
  /// fade under it is drawn at.
  final ValueNotifier<double> _edge = ValueNotifier(0);

  /// The first subject whose parts are shown, which the hint plays on.
  final GlobalKey _firstParts = GlobalKey();

  /// Whether the hint is still to be shown: unknown until the phone has
  /// said, then true until it has been shown or a part held.
  bool _hintOwed = false;

  /// The hint as it plays.
  AnimationController? _hint;

  /// The hint said still, for a reader who asked for less motion.
  bool _hintStill = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted || (prefs.getBool(_kHoldHint) ?? false)) return;
      _hintOwed = true;
      // Shown at once where the parts are on screen as the page opens; else
      // when the reader comes to rest on them.
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeHint());
    });
  }

  @override
  void dispose() {
    _hint?.dispose();
    _edge.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _edge.value = (n.metrics.pixels / 24).clamp(0.0, 1.0);
    // Looked at once the page is laid out where it came to rest.
    if (n is ScrollEndNotification && _hintOwed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeHint());
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    return false;
  }

  /// The hint, if it is owed and the first subject's parts stand whole on
  /// screen, clear of the way back, with room under them for what opens:
  /// what a hold opens opens under all of them.
  void _maybeHint() {
    if (!_hintOwed || !mounted) return;
    final RenderObject? parts = _firstParts.currentContext?.findRenderObject();
    if (parts is! RenderBox || !parts.hasSize) return;
    final double top = parts.localToGlobal(Offset.zero).dy;
    final Size screen = MediaQuery.sizeOf(context);
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final double head = safe.top + 64;
    final double bottom = screen.height - safe.bottom - 16;
    if (top < head || top + parts.size.height + 120 > bottom) return;
    _showHint();
  }

  void _showHint() {
    _hintOwed = false;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_kHoldHint, true),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _hintStill = true);
      return;
    }
    final AnimationController hint = AnimationController(
      vsync: this,
      duration: _hintTime,
    );
    hint.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      setState(() => _hint = null);
      _dropAfterFrame(hint);
    });
    setState(() => _hint = hint);
    hint.forward();
  }

  /// [hint], let go once the frame that stops drawing it is drawn.
  void _dropAfterFrame(AnimationController hint) {
    hint.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) => hint.dispose());
  }

  /// A part held by the reader: they have found what holding does, and the
  /// hint is not owed any more.
  void _held() {
    if (_hintOwed) {
      _hintOwed = false;
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setBool(_kHoldHint, true),
      );
    }
    final AnimationController? hint = _hint;
    if (hint != null) {
      _hint = null;
      _dropAfterFrame(hint);
    }
    _hintStill = false;
  }

  /// What the reader asked for, by topic key: 0 for a subject out of the
  /// mix. A subject in it with no weight of its own is all the way in,
  /// which is what the onboarding starts everything at.
  late final Map<String, double> _asked = {
    for (final MixSubject s in kMixSubjects)
      s.key: widget.picked.contains(s.key)
          ? (app.topicWeights[s.key] ?? 1.0)
          : 0.0,
  };

  /// How much the reader's likes and throws have moved each subject: what
  /// the personal deals multiply the asked-for weight by.
  late final Map<String, double> _lean = {
    for (final MixSubject s in kMixSubjects) s.key: _leanOf(s.key),
  };

  double _leanOf(String key) {
    final double asked = _asked[key]!;
    final double? leaned = app.leanedWeights[key];
    if (asked <= 0 || leaned == null) return 1.0;
    return leaned / asked;
  }

  /// What turns a leaned weight back into the reader's own terms: the
  /// subjects in the mix, on average, are where the reader put them, and
  /// the lean moves each away from that — the ones they keep liking up, to
  /// full at most, the ones they keep throwing away down. Scaled instead so
  /// that the most liked subject was the whole bar, a reader who had set
  /// everything all the way in found every other subject at half, as if
  /// the app had turned them down.
  late final double _scale = () {
    double asked = 0, leaned = 0;
    for (final MixSubject s in kMixSubjects) {
      asked += _asked[s.key]!;
      leaned += _asked[s.key]! * _lean[s.key]!;
    }
    return leaned > 0 ? asked / leaned : 1.0;
  }();

  /// The bars, 0 to 100, by topic key: where the deals have them now, in
  /// the reader's own terms.
  late final Map<String, int> _value = {
    for (final MixSubject s in kMixSubjects)
      s.key: (_asked[s.key]! * _lean[s.key]! * _scale * 100).round().clamp(
        0,
        100,
      ),
  };

  /// Where the reader had each bar, 0 to 100, where the app has moved it
  /// far enough to see.
  late final Map<String, int> _mark = {
    for (final MixSubject s in kMixSubjects)
      if (_asked[s.key]! > 0 &&
          ((_asked[s.key]! * 100).round().clamp(0, 100) - _value[s.key]!)
                  .abs() >=
              3)
        s.key: (_asked[s.key]! * 100).round().clamp(0, 100),
  };

  /// The bars the reader moved on this page. The rest are saved as the
  /// reader last asked for them, so the lean is not counted twice.
  final Set<String> _touched = {};

  late final Set<String> _genresOff = {...app.genresOff};
  late final Set<String> _strandsOff = {...app.strandsOff};
  final Set<String> _open = {};

  /// The subjects in the order the bars put them, the most wanted first,
  /// fixed when the page opens: a list that re-sorted under a finger
  /// dragging a bar above it would jump.
  late final List<String> _order = () {
    final keys = [for (final MixSubject s in kMixSubjects) s.key];
    final at = {for (var i = 0; i < keys.length; i++) keys[i]: i};
    keys.sort((a, b) {
      final int by = _value[b]!.compareTo(_value[a]!);
      return by != 0 ? by : at[a]!.compareTo(at[b]!);
    });
    return keys;
  }();

  bool get _learned => app.likedIds.isNotEmpty || app.dislikedIds.isNotEmpty;

  int get _inMix => _value.values.where((v) => v > kMixFloor).length;

  static const int _minTopics = 3;

  void _setAt(MixSubject subject, double dx, double width) {
    final int next = ((dx / width).clamp(0.0, 1.0) * 100).round();
    final int was = _value[subject.key]!;
    if (was == next) return;
    if (next ~/ 5 != was ~/ 5) HapticFeedback.selectionClick();
    setState(() {
      _value[subject.key] = next;
      _touched.add(subject.key);
    });
  }

  Future<void> _save() async {
    final Map<String, double> weights = {};
    for (final MixSubject s in kMixSubjects) {
      final int v = _value[s.key]!;
      if (v <= kMixFloor) continue;
      final double asked = _asked[s.key]!;
      weights[s.key] = !_touched.contains(s.key) && asked > 0
          ? asked
          // Back from the bar to what the reader asks for: the bar shows
          // the asked-for weight leaned, on the page's scale.
          : (v / 100 / _scale / _lean[s.key]!).clamp(0.05, 3.0);
    }
    Analytics.capture('mix tuned', {
      'moved': _touched.length,
      'in_mix': weights.length,
      'learned': _learned,
    });
    await app.setTopicMix(weights);
    await app.setGenresOff(_genresOff, _strandsOff);
    if (mounted) Navigator.of(context).pop({...app.pickedTopics});
  }

  /// The page's own theme: dark, whatever the phone's, as the onboarding's
  /// bars and parts are. The tiles are drawn for black.
  static final ThemeData _dark = buildAstutoTheme(Brightness.dark);

  @override
  Widget build(BuildContext context) => Theme(
    data: _dark,
    child: Builder(builder: _page),
  );

  Widget _page(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool enough = _inMix >= _minTopics;
    final Map<String, double> taste = app.taste;
    final bool likedParts = taste.keys.any(
      (k) => k.startsWith('genre:') && taste[k]! > 0,
    );

    final EdgeInsets safe = MediaQuery.paddingOf(context);
    // The first subject whose parts are drawn: the hint plays on it.
    final String? first = _order
        .where((k) => kGenres.containsKey(k) && _value[k]! > kMixFloor)
        .firstOrNull;
    return ScreenView(
      name: 'tune',
      child: Scaffold(
        backgroundColor: p.surface,
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: ListView(
                key: const ValueKey('tune-page'),
                padding: EdgeInsets.fromLTRB(
                  18,
                  safe.top + 8,
                  18,
                  safe.bottom + 24,
                ),
                children: [
                  // The title beside the way back, as every screen with one
                  // sets it, one line, smaller where a language runs long;
                  // it goes up with the page, the way back stays.
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        const SizedBox(width: 44 + 12),
                        Expanded(
                          child: FitText(
                            l.tuneTitle,
                            key: const ValueKey('tune-title'),
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
                  const SizedBox(height: 8),
                  Text(
                    _learned ? l.tuneLearned : l.tuneFresh,
                    style: AppText.body(
                      size: 13.5,
                      height: 1.4,
                      color: p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Eyebrow(l.tuneHowMuch),
                  const SizedBox(height: 10),
                  _Bars(value: _value, mark: _mark, onDragAt: _setAt),
                  const SizedBox(height: 8),
                  Text(
                    l.subjectsInTheMix(_inMix, kMixSubjects.length),
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: p.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Eyebrow(l.genresTitle),
                  const SizedBox(height: 7),
                  Text(
                    likedParts ? l.tuneInsideLine : l.genresLine,
                    style: AppText.body(
                      size: 12.5,
                      height: 1.4,
                      color: p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final String key in _order)
                    if (kGenres.containsKey(key))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _value[key]! > kMixFloor
                            ? GenreSubject(
                                key: key == first ? _firstParts : null,
                                topicKey: key,
                                weight: _value[key]! / 100,
                                genresOff: _genresOff,
                                strandsOff: _strandsOff,
                                open: _open,
                                taste: taste,
                                hint: key == first ? _hint : null,
                                hintLine:
                                    key == first &&
                                        (_hint != null || _hintStill)
                                    ? l.tuneHoldHint
                                    : null,
                                onTapGenre: (Genre g) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (!_genresOff.remove(g.id)) {
                                      _genresOff.add(g.id);
                                    }
                                  });
                                },
                                onHoldGenre: (Genre g) {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    _held();
                                    if (!_open.remove(g.id)) _open.add(g.id);
                                  });
                                },
                                onTapStrand: (Strand s) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (!_strandsOff.remove(s.id)) {
                                      _strandsOff.add(s.id);
                                    }
                                  });
                                },
                              )
                            : GenreSubjectOff(topicKey: key),
                      ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    key: const ValueKey('tune-save'),
                    label: enough ? l.tuneSave : l.pickAtLeastN(_minTopics),
                    background: enough ? p.ink : p.line,
                    foreground: enough ? null : p.inkFaint,
                    onPressed: enough ? _save : null,
                  ),
                ],
              ),
            ),
            // What runs under the way back fades into the page there, as
            // iOS fades what runs under its own: drawn only once the page
            // has moved, so at rest the title stands beside it untouched.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: safe.top + 8 + 44 + 20,
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: _edge,
                  builder: (context, edge, _) => Opacity(
                    opacity: edge,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          // Whole behind the way back, so nothing runs
                          // through its ring, then gone a little under it.
                          colors: [
                            p.surface,
                            p.surface,
                            p.surface.withValues(alpha: 0.7),
                            p.surface.withValues(alpha: 0),
                          ],
                          stops: [
                            0,
                            (safe.top + 8 + 36) / (safe.top + 72),
                            (safe.top + 8 + 50) / (safe.top + 72),
                            1,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The way back stays where it is: on iOS 26 it is Apple's own
            // glass button, a native view, and one inside a scrolling page
            // is drawn away from its place.
            Positioned(
              left: 18,
              top: safe.top + 8,
              child: BackCircle(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The twenty bars, two by two, each a row of its own height on a page
/// that scrolls: under the editor the bars are one part of a longer page,
/// not the whole screen they are in the onboarding.
class _Bars extends StatelessWidget {
  const _Bars({
    required this.value,
    required this.mark,
    required this.onDragAt,
  });

  final Map<String, int> value;
  final Map<String, int> mark;
  final void Function(MixSubject, double dx, double width) onDragAt;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final int columns = scaler.scale(10) > 14 ? 1 : 2;
    final int rows = (kMixSubjects.length / columns).ceil();
    final double height = math.max(44, scaler.scale(13.5) * 1.1 + 24);
    return Column(
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: Row(
              children: [
                for (int c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 8),
                  Expanded(
                    child: r * columns + c < kMixSubjects.length
                        ? MixTile(
                            key: ValueKey(
                              'tune-${kMixSubjects[r * columns + c].key}',
                            ),
                            subject: kMixSubjects[r * columns + c],
                            value: value[kMixSubjects[r * columns + c].key]!,
                            mark: mark[kMixSubjects[r * columns + c].key],
                            index: r * columns + c,
                            onDragAt: onDragAt,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
