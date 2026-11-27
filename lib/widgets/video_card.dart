/// A video card (lib/data/video_cards.dart): a tile of its first frame, and
/// the card itself, opened to the whole screen with a tap on the tile and
/// playing at once.
///
/// Opened, the card is the screen, not a card laid on it: the film covers it
/// from the top to the foot, the row with how far it has run and the cross
/// laid over the top of its picture, the tile's picture growing into it as
/// it opens. The film plays as soon as it is there, from the frame the tile
/// showed, so the picture comes alive rather than starting over. A tap
/// pauses it, another goes on; at its end the last frame stays with the way
/// to watch it again. A pull down, or the cross, puts it back where it came
/// from.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../analytics.dart';
import '../data/video_cards.dart';
import '../l10n/l10n.dart';
import '../theme.dart';
import 'glass_round.dart';

/// The film's own frame, in its pixels: a modern phone's nine by nineteen
/// and a half (docs/cards/video/README.md).
const Size kFilmFrame = Size(1080, 2340);

/// The film's own proportion, width over height.
const double kFilmAspect = 1080 / 2340;

/// The part of the film's frame its words keep to, in its pixels. Above it
/// only its ground, under the status bar and the row of controls laid over
/// it, with its head on its top line; outside it only drawing that runs on
/// (the ground, the Earth, light), which a phone wider or shorter than the
/// frame may cut.
const Rect kFilmWords = Rect.fromLTRB(64, 330, 1016, 1990);

/// How much of the film's height a tile leaves out above its own top: the
/// room for the controls, down to as far above the head as the words keep
/// from the sides (330 - 82 of its 2340 pixels).
const double kTileCut = 248 / 2340;

/// The corners of a video card, on the screen and as a tile.
const double _corner = 28;

/// The ink of the films' type, for what is laid over them.
const Color _filmInk = Color(0xFF10100C);

/// How long a film runs, as a clock shows it: "0:53".
String filmClock(Duration length) {
  final int seconds = (length.inMilliseconds / 1000).round();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

Object _heroOf(VideoCard card) => 'video-card-${card.id}';

/// What the film of [card] grows out of when it is opened from [where], a
/// section of Explore that lays it as a card among cards ([VideoCardHero]):
/// a section lays a card once, so the tag is the page's only one.
Object videoHeroTag(VideoCard card, String where) =>
    'video-card-${card.id}@$where';

/// Where the row of controls ends, under the top of the screen's own inset:
/// four points of air and a row as tall as the cross.
const double _controls = 48;

/// The air between the row of controls and the film's head, and the least
/// it is given on a phone so short its head comes up closer.
const double _headAir = 12, _headAirLeast = 4;

/// How close the film's words come to the screen's sides, and to its foot
/// (or to its home bar), at the closest.
const double _wordsSide = 8, _wordsFoot = 2;

/// The corners of the film where it is a card of its own on the ground, on a
/// screen too wide or too tall for it to cover.
const double _filmCorner = 20;

/// Where the film stands on a screen of [size] with [safe] insets: over the
/// whole screen, from its top to its foot, its head right under the row of
/// controls laid over its top. On a phone shorter than the frame, its foot
/// is cut, under its words; on one taller, its sides, and a little more of
/// them so its head comes up under the controls, as far as its words keep
/// off the edges. On a screen it cannot cover without cutting its words (a
/// tablet), as large as fits under the row, a card of its own on the ground.
Rect filmPlace(Size size, EdgeInsets safe) {
  const Size frame = kFilmFrame;
  const Rect words = kFilmWords;
  final double width = size.width, height = size.height;
  final double head = safe.top + _controls + _headAir;
  final double headLeast = safe.top + _controls + _headAirLeast;
  // Large enough to cover the screen; on a phone taller than the frame,
  // larger still for the head to come up under the controls, as long as
  // the words keep off the sides.
  final double cover = math.max(width / frame.width, height / frame.height);
  final double widest =
      (width / 2 - _wordsSide) / (frame.width / 2 - words.left);
  final double lifted = (height - head) / (frame.height - words.top);
  final double scale = math.max(cover, math.min(lifted, widest));
  // How high it may stand: no higher than keeps its head under the
  // controls and the screen's foot covered, no lower than keeps its words
  // above the foot and the screen's top covered.
  final double highest = math.max(
    height - frame.height * scale,
    headLeast - words.top * scale,
  );
  final double lowest = math.min(
    0.0,
    height - math.max(safe.bottom, _wordsFoot) - words.bottom * scale,
  );
  if (scale <= widest + 1e-9 && highest <= lowest) {
    final double top = (head - words.top * scale).clamp(highest, lowest);
    return Rect.fromLTWH(
      (width - frame.width * scale) / 2,
      top,
      frame.width * scale,
      frame.height * scale,
    );
  }
  final double room = math.max(0.0, height - headLeast - safe.bottom - 10);
  final double h = math.min(width / kFilmAspect, room);
  final double w = h * kFilmAspect;
  return Rect.fromLTWH((width - w) / 2, headLeast, w, h);
}

/// Whether the film at [place] stands across the whole of a screen [width]
/// wide.
bool _across(Rect place, double width) => place.width >= width - 0.5;

/// Where a tile of [box] shows the film: across its width, from a little
/// above its head, cut at the tile's foot.
Rect _tilePlace(Size box) {
  final double height = box.width / kFilmAspect;
  return Rect.fromLTWH(0, -kTileCut * height, box.width, height);
}

/// A video card's first frame on its ground, at [place] in the box it is
/// given; by default across the box's width from a little above its head,
/// cut at its foot, as a tile shows it.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.card,
    required this.language,
    this.corner = _corner,
    this.place,
    this.filmCorner = 0,
  });

  final VideoCard card;
  final String language;

  /// The frame's own corners.
  final double corner;

  /// Where the picture stands in a box of the given size.
  final Rect Function(Size box)? place;

  /// The picture's own corners, within the frame.
  final double filmCorner;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(corner),
    child: ColoredBox(
      color: Color(card.ground),
      child: LayoutBuilder(
        builder: (context, box) {
          final Size size = box.biggest;
          final Rect at = place?.call(size) ?? _tilePlace(size);
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fromRect(
                rect: at,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(filmCorner),
                  child: Image.asset(
                    card.posterFor(language),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    gaplessPlayback: true,
                    // Where the picture will not come, the card's own
                    // ground.
                    errorBuilder: (_, _, _) => const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// The tile's picture grows straight into the screen, as a picture opened
/// on a phone does, rather than swinging along an arc.
RectTween _straight(Rect? begin, Rect? end) =>
    RectTween(begin: begin, end: end);

/// The tile's picture on its way to the screen and back: its box grows from
/// the tile to the whole screen, its corners going square, and the picture
/// moves within it from where the tile shows it to where the film stands.
Widget _flight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final BuildContext screen = direction == HeroFlightDirection.push
      ? toContext
      : fromContext;
  final Hero hero = screen.widget as Hero;
  final _Frame end = hero.child as _Frame;
  final MediaQueryData m = MediaQuery.of(flightContext);
  final Rect place = filmPlace(m.size, m.padding);
  final double across = _across(place, m.size.width) ? 0 : _filmCorner;
  // Where the film stands, as parts of the screen.
  final double left = place.left / m.size.width;
  final double top = place.top / m.size.height;
  final double width = place.width / m.size.width;
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final double t = animation.value;
      return _Frame(
        card: end.card,
        language: end.language,
        corner: _corner * (1 - t),
        filmCorner: across * t,
        place: (box) {
          final double w = box.width * (1 + (width - 1) * t);
          final Rect tile = _tilePlace(box);
          return Rect.fromLTWH(
            box.width * left * t,
            tile.top * (1 - t) + box.height * top * t,
            w,
            w / kFilmAspect,
          );
        },
      );
    },
  );
}

/// A video card as Explore shows it: its first frame from a little above its
/// head, at the size it is given, and a mark in its corner that it plays and
/// how long.
class VideoCardTile extends StatelessWidget {
  const VideoCardTile({
    super.key,
    required this.card,
    required this.language,
    required this.onOpen,
  });

  final VideoCard card;
  final String language;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String clock = filmClock(card.length);
    return Semantics(
      key: ValueKey('video-tile-${card.id}'),
      button: true,
      label: '${card.titleFor(language)}. ${l.videoKicker}, $clock',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onOpen();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: _heroOf(card),
              createRectTween: _straight,
              flightShuttleBuilder: _flight,
              child: _Frame(card: card, language: language),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: _Chip(
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    clock,
                    style: AppText.label(
                      size: 12,
                      weight: FontWeight.w700,
                      spacing: 0.6,
                      color: Colors.white,
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

/// A video card's tile wherever Explore lays it as a card among cards (the
/// feed, the cover): the film grows out of it when it is opened with the
/// same [tag] ([videoHeroTag], openVideoCard's `heroTag`), and goes back
/// into it, as from the tile of its own first frame.
class VideoCardHero extends StatelessWidget {
  const VideoCardHero({super.key, required this.tag, required this.child});

  final Object tag;

  /// The tile: the card in words, with its play mark.
  final Widget child;

  @override
  Widget build(BuildContext context) => Hero(
    tag: tag,
    createRectTween: _straight,
    flightShuttleBuilder: _flight,
    child: child,
  );
}

/// A small dark pill laid over a film.
class _Chip extends StatelessWidget {
  const _Chip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
    decoration: BoxDecoration(
      color: _filmInk.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: children),
  );
}

/// Opens [card] to the whole screen, its tile's picture growing into it:
/// the tile that carries [heroTag] ([VideoCardHero]), or the card's own
/// tile ([VideoCardTile]) when none is given.
Future<void> openVideoCard(
  BuildContext context,
  VideoCard card, {
  required String language,
  Object? heroTag,
}) {
  Analytics.capture('video card opened', {
    'card': card.id,
    'language': card.languageFor(language),
  });
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, _, _) =>
          VideoCardScreen(card: card, language: language, heroTag: heroTag),
    ),
  );
}

/// Makes the player of a film; a test hands in its own.
typedef FilmPlayerMaker = VideoPlayerController Function(Uri film);

/// The card on the whole screen.
class VideoCardScreen extends StatefulWidget {
  const VideoCardScreen({
    super.key,
    required this.card,
    required this.language,
    this.heroTag,
  });

  final VideoCard card;
  final String language;

  /// The tile the film grows out of and goes back into: its own
  /// ([VideoCardTile]) when null, or the card laid among cards that
  /// carries this tag ([VideoCardHero]).
  final Object? heroTag;

  /// How a film's player is made: from the site, mixed with whatever else
  /// the phone is playing, since a card's film has no sound of its own.
  static FilmPlayerMaker makePlayer = (film) =>
      VideoPlayerController.networkUrl(
        film,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

  @override
  State<VideoCardScreen> createState() => _VideoCardScreenState();
}

class _VideoCardScreenState extends State<VideoCardScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _player;

  /// Whether the card has come all the way up: the film waits for it, so
  /// it starts on the frame the tile grew into rather than behind it.
  bool _up = false;

  /// Whether the film has been started.
  bool _started = false;

  /// Whether the film has moved off the frame it was started on, and is
  /// shown in its picture's place.
  bool _shows = false;

  /// Where the film was started from.
  Duration _from = Duration.zero;

  /// Whether the reader paused it.
  bool _paused = false;

  /// Whether the film could not be had.
  bool _failed = false;

  /// Whether the film has played to its end.
  bool _ended = false;

  /// Whether its playing has been said, once a stint.
  bool _said = false;

  /// How far the film has run, 0 to 1, moving smoothly between what the
  /// player says.
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: widget.card.length,
  );

  /// The film coming: a stroke running along the line of how far it has
  /// run, until it plays.
  late final AnimationController _coming = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// How far the card has been pulled down, and its way back when let go.
  double _pull = 0;
  late final AnimationController _back =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      )..addListener(
        () => setState(
          () => _pull =
              _pulledFrom * (1 - Curves.easeOutCubic.transform(_back.value)),
        ),
      );
  double _pulledFrom = 0;

  Animation<double>? _route;

  VideoCard get card => widget.card;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    _screen = route;
    final Animation<double>? animation = route?.animation;
    if (animation != _route) {
      _route?.removeStatusListener(_arrived);
      _route = animation;
      animation?.addStatusListener(_arrived);
    }
    if (route == null || animation == null) {
      _arrive();
    } else {
      _arrived(animation.status);
    }
  }

  /// The route the card is up in.
  ModalRoute<Object?>? _screen;

  /// Up once its way up is over. The first frame of a route is laid out
  /// out of sight, as if it were already up, for the picture to know where
  /// it flies to: that frame is not the card being up.
  void _arrived(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_screen?.offstage ?? false) return;
    _arrive();
  }

  void _arrive() {
    if (_up) return;
    _up = true;
    _go();
  }

  /// Makes the player and has it fetch the film from the frame the tile
  /// shows, to play the moment the card is up.
  void _prepare() {
    final VideoPlayerController player = VideoCardScreen.makePlayer(
      card.filmFor(widget.language),
    );
    _player = player;
    player.addListener(_heard);
    if (!_coming.isAnimating) _coming.repeat();
    player.initialize().then(
      (_) async {
        if (!mounted || _player != player) return;
        if (!_started) {
          _from = card.posterAt;
          await player.seekTo(_from);
          if (!mounted || _player != player) return;
        }
        setState(() {});
        _go();
      },
      onError: (Object error) {
        if (!mounted || _player != player) return;
        _coming.stop();
        setState(() => _failed = true);
      },
    );
  }

  /// Plays the film once the card is up and the film is there, unless the
  /// reader paused it first.
  void _go() {
    final VideoPlayerController? player = _player;
    if (!_up || _started || _paused || player == null) return;
    if (!player.value.isInitialized) return;
    _play();
  }

  /// What the player says: how far it is, and whether it has ended.
  void _heard() {
    final VideoPlayerController? player = _player;
    if (player == null || !mounted) return;
    final VideoPlayerValue v = player.value;
    if (v.hasError && !_failed) {
      _coming.stop();
      setState(() => _failed = true);
      return;
    }
    if (!v.isInitialized) return;
    final int total = v.duration.inMilliseconds;
    if (total > 0) {
      final double at = (v.position.inMilliseconds / total).clamp(0.0, 1.0);
      if ((_run.value - at).abs() > 0.02) _run.value = at;
      if (v.isPlaying && !_run.isAnimating && at < 1) {
        _run.duration = v.duration;
        _run.forward(from: at);
      } else if (!v.isPlaying && _run.isAnimating) {
        _run.stop();
      }
    }
    // The film takes the picture's place once it has moved off the frame
    // it was started on, so the picture never blinks.
    if (_started && !_shows && (v.position - _from).inMilliseconds.abs() > 40) {
      _shows = true;
      _coming.stop();
    }
    final bool ended =
        _started &&
        !v.isPlaying &&
        total > 0 &&
        v.position.inMilliseconds >= total - 250;
    if (ended != _ended) {
      setState(() => _ended = ended);
      if (ended) {
        _run.value = 1;
        Analytics.capture('video card finished', {'card': card.id});
      }
    } else {
      setState(() {});
    }
  }

  Future<void> _play() async {
    final VideoPlayerController? player = _player;
    if (player == null || !player.value.isInitialized) return;
    setState(() {
      _started = true;
      _paused = false;
      _ended = false;
    });
    if (!_said) {
      _said = true;
      Analytics.capture('video card played', {
        'card': card.id,
        'language': card.languageFor(widget.language),
      });
    }
    final int total = player.value.duration.inMilliseconds;
    if (total > 0 && player.value.position.inMilliseconds >= total - 250) {
      _from = Duration.zero;
      await player.seekTo(Duration.zero);
      _run.value = 0;
    }
    await player.play();
  }

  void _tap() {
    HapticFeedback.selectionClick();
    final VideoPlayerController? player = _player;
    if (_failed) {
      // Another go: a new player, played as soon as it can be.
      player?.removeListener(_heard);
      player?.dispose();
      setState(() {
        _failed = false;
        _started = false;
        _shows = false;
      });
      _prepare();
      return;
    }
    if (player != null && player.value.isPlaying) {
      player.pause();
      setState(() => _paused = true);
      return;
    }
    if (_ended) return;
    if (player == null || !player.value.isInitialized) {
      // Paused before it came: it waits for another tap.
      setState(() => _paused = !_paused);
      return;
    }
    _play();
  }

  void _close() => Navigator.of(context).maybePop();

  void _pulled(DragUpdateDetails d) {
    _back.stop();
    setState(() {
      // Down freely, up only a little, against a hand holding it.
      final double next = _pull + d.delta.dy;
      _pull = next < 0 ? next * 0.3 : next;
    });
  }

  void _letGo(DragEndDetails d) {
    if (_pull > 110 || (d.primaryVelocity ?? 0) > 800) {
      _close();
      return;
    }
    _pulledFrom = _pull;
    _back.forward(from: 0);
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_arrived);
    _player?.removeListener(_heard);
    _player?.dispose();
    _run.dispose();
    _coming.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final MediaQueryData m = MediaQuery.of(context);
    final EdgeInsets safe = m.padding;
    final Animation<double> route =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final VideoPlayerController? player = _player;
    final bool playing = player?.value.isPlaying ?? false;
    final Color ground = Color(card.ground);
    // The card's own ink, for what is laid on its ground.
    final bool light =
        ThemeData.estimateBrightnessForColor(ground) == Brightness.light;
    final Color ink = light ? _filmInk : Colors.white;
    final Rect place = filmPlace(m.size, safe);
    final Rect seen = place.intersect(Offset.zero & m.size);
    final bool across = _across(place, m.size.width);
    final double pulled = _pull.clamp(0.0, 600.0);
    final double fade = 1 - math.min(pulled / 420, 0.7);
    // Pulled, the screen becomes a card again: smaller, and round.
    final double scale = 1 - math.min(pulled / 1600, 0.16);
    final double round = math.min(pulled / 160, 1) * _corner;
    final Animation<double> late = CurvedAnimation(
      parent: route,
      curve: const Interval(0.6, 1, curve: Curves.easeOut),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      // The words laid over the film take the app's type, not a page's.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // What the card was opened over, darkened, seen only as the
            // card is pulled away.
            Positioned.fill(
              child: FadeTransition(
                opacity: route,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.6 * fade),
                ),
              ),
            ),
            Positioned.fill(
              child: Semantics(
                button: true,
                label: [
                  card.titleFor(widget.language),
                  _failed
                      ? l.videoOffline
                      : _ended
                      ? l.videoWatchAgain
                      : playing || (!_paused && !_started)
                      ? l.videoPause
                      : l.videoPlay,
                ].join('. '),
                excludeSemantics: true,
                onTap: _tap,
                child: GestureDetector(
                  key: const ValueKey('video-card'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  onVerticalDragUpdate: _pulled,
                  onVerticalDragEnd: _letGo,
                  child: Transform.translate(
                    offset: Offset(0, _pull),
                    child: Transform.scale(
                      scale: scale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(round),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: widget.heroTag ?? _heroOf(card),
                              createRectTween: _straight,
                              flightShuttleBuilder: _flight,
                              child: _Frame(
                                card: card,
                                language: widget.language,
                                corner: 0,
                                filmCorner: across ? 0 : _filmCorner,
                                place: (_) => place,
                              ),
                            ),
                            // The film over its picture, faded out with the
                            // rest as the card goes back to its tile.
                            if (_shows && player != null)
                              Positioned.fromRect(
                                rect: place,
                                child: FadeTransition(
                                  opacity: late,
                                  child: ClipRRect(
                                    key: const ValueKey('video-film'),
                                    borderRadius: BorderRadius.circular(
                                      across ? 0 : _filmCorner,
                                    ),
                                    child: VideoPlayer(player),
                                  ),
                                ),
                              ),
                            // What is said over the film, on as much of it
                            // as is seen: the screen, when it covers it.
                            Positioned.fromRect(
                              rect: seen,
                              child: FadeTransition(
                                opacity: late,
                                child: _Over(
                                  paused: _paused && !_ended,
                                  failed: _failed,
                                  ended: _ended,
                                  onAgain: _play,
                                  foot: seen.bottom >= m.size.height - 0.5
                                      ? safe.bottom
                                      : 0,
                                ),
                              ),
                            ),
                            // The row over the top of the film: how far it
                            // has run, and the way out.
                            Positioned(
                              top: safe.top + 4,
                              left: 20,
                              right: 12,
                              height: 44,
                              child: FadeTransition(
                                opacity: late,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedBuilder(
                                        animation: Listenable.merge([
                                          _run,
                                          _coming,
                                        ]),
                                        builder: (context, _) => _RunBar(
                                          value: _run.value,
                                          coming: _shows || _failed
                                              ? null
                                              : _coming.value,
                                          ink: ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    GlassRound(
                                      symbol: GlassRound.close,
                                      label: l.closeLabel,
                                      onPressed: _close,
                                      fallback: Semantics(
                                        button: true,
                                        label: l.closeLabel,
                                        child: GestureDetector(
                                          key: const ValueKey('video-close'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _close,
                                          child: SizedBox.square(
                                            dimension: 44,
                                            child: Center(
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: ink.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 19,
                                                  color: ink,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// How far the film has run: a thin line in the card's ink, on a fainter
/// one; while the film is coming ([coming], 0 to 1 and round again), a
/// short stroke runs along it.
class _RunBar extends StatelessWidget {
  const _RunBar({required this.value, required this.ink, this.coming});

  final double value;
  final Color ink;
  final double? coming;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (context, box) {
          final double w = box.maxWidth;
          final double? t = coming;
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: ink.withValues(alpha: 0.18)),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(color: ink.withValues(alpha: 0.85)),
              ),
              if (t != null)
                Positioned(
                  key: const ValueKey('video-coming'),
                  left: -w * 0.25 + w * 1.25 * Curves.easeInOut.transform(t),
                  top: 0,
                  bottom: 0,
                  width: w * 0.25,
                  child: ColoredBox(color: ink.withValues(alpha: 0.55)),
                ),
            ],
          );
        },
      ),
    ),
  );
}

/// What is laid over the film, on as much of it as is seen: paused, the way
/// on in its middle; at its end, the way to watch it again at its foot,
/// under the thumb; where it could not be had, the word that it needs a
/// connection, at its foot too. The film keeps its own words out of its
/// foot on the frames these stand over, its first and its last
/// (docs/cards/video/README.md).
class _Over extends StatelessWidget {
  const _Over({
    required this.paused,
    required this.failed,
    required this.ended,
    required this.onAgain,
    this.foot = 0,
  });

  final bool paused, failed, ended;
  final VoidCallback onAgain;

  /// The screen's own inset at the film's foot, where the film reaches it:
  /// what stands at the foot stands above it.
  final double foot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final double k = (box.maxWidth / 402).clamp(0.75, 1.1);
        // [child] at the foot, above the home bar where there is one.
        Widget atFoot(Widget child) => Positioned(
          left: 0,
          right: 0,
          bottom: math.max(foot, 10) + 8,
          child: Center(child: child),
        );
        if (failed) {
          return Stack(
            children: [
              atFoot(
                Padding(
                  padding: EdgeInsets.fromLTRB(28 * k, 0, 28 * k, 8),
                  child: Container(
                    key: const ValueKey('video-offline'),
                    padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
                    decoration: BoxDecoration(
                      color: _filmInk.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      l.videoOffline,
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        if (ended) {
          return Stack(
            children: [
              atFoot(
                GestureDetector(
                  key: const ValueKey('video-again'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onAgain,
                  // A finger's room round the chip.
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _Chip(
                      children: [
                        const Icon(
                          Icons.replay_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.videoWatchAgain,
                          style: AppText.body(
                            size: 15,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        // Paused: the way on, in the middle, over the frame it stopped on.
        return IgnorePointer(
          child: Center(
            child: AnimatedOpacity(
              opacity: paused ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: AnimatedScale(
                scale: paused ? 1 : 0.8,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Container(
                  key: paused ? const ValueKey('video-play') : null,
                  width: 72 * k,
                  height: 72 * k,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _filmInk.withValues(alpha: 0.78),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 40 * k,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
