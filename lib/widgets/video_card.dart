/// A video card (lib/data/video_cards.dart): a tile of its first frame, and
/// the card itself, opened to the whole screen with a tap on the tile and
/// played with a second tap on the card.
///
/// The card is the film's own frame, as large as the screen takes it, with
/// a card's corners, on black, the way a photograph is opened: the tile's
/// picture grows into it. A tap plays it, another pauses it, and at its end
/// the last frame stays with the way to watch it again. A pull down, or the
/// cross above it, puts it back where it came from.
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

/// The film's own proportion, width over height.
const double kFilmAspect = 9 / 16;

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

/// A video card's first frame, cut from the top to the box it is given.
class _Frame extends StatelessWidget {
  const _Frame({required this.card, required this.language});

  final VideoCard card;
  final String language;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(_corner),
    child: ColoredBox(
      color: Color(card.ground),
      child: Image.asset(
        card.posterFor(language),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        // Where the picture will not come, the card's own ground.
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    ),
  );
}

/// A video card as Explore shows it: its first frame from the top, at the
/// size it is given, and a mark in its corner that it plays and how long.
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

/// Opens [card] to the whole screen, its tile's picture growing into it.
Future<void> openVideoCard(
  BuildContext context,
  VideoCard card, {
  required String language,
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
      pageBuilder: (_, _, _) => VideoCardScreen(card: card, language: language),
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
  });

  final VideoCard card;
  final String language;

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

  /// Whether the film has been started; until then the card is its first
  /// frame, waiting for the second tap.
  bool _started = false;

  /// Whether a tap asked for the film before it could be played: it plays
  /// as soon as it can.
  bool _waiting = false;

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

  VideoCard get card => widget.card;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  /// Makes the player and has it fetch the film's start, so the second tap
  /// plays at once.
  void _prepare() {
    final VideoPlayerController player = VideoCardScreen.makePlayer(
      card.filmFor(widget.language),
    );
    _player = player;
    player.addListener(_heard);
    player.initialize().then(
      (_) {
        if (!mounted || _player != player) return;
        setState(() {});
        if (_waiting) _play();
      },
      onError: (Object error) {
        if (!mounted || _player != player) return;
        setState(() {
          _failed = true;
          _waiting = false;
        });
      },
    );
  }

  /// What the player says: how far it is, and whether it has ended.
  void _heard() {
    final VideoPlayerController? player = _player;
    if (player == null || !mounted) return;
    final VideoPlayerValue v = player.value;
    if (v.hasError && !_failed) {
      setState(() {
        _failed = true;
        _waiting = false;
      });
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
      // The first frame of the film, once it moves, takes the card from its
      // picture.
      setState(() {});
    }
  }

  Future<void> _play() async {
    final VideoPlayerController? player = _player;
    if (player == null) return;
    if (!player.value.isInitialized) {
      setState(() => _waiting = true);
      return;
    }
    setState(() {
      _waiting = false;
      _started = true;
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
        _waiting = true;
      });
      _prepare();
      return;
    }
    if (player != null && player.value.isPlaying) {
      player.pause();
      setState(() {});
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
    _player?.removeListener(_heard);
    _player?.dispose();
    _run.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final Animation<double> route =
        ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    final VideoPlayerController? player = _player;
    final VideoPlayerValue? v = player?.value;
    final bool playing = v?.isPlaying ?? false;
    // The film shows once it has moved past its first frame; until then, the
    // picture the tile grew from.
    final bool filmShows =
        _started &&
        (v?.isInitialized ?? false) &&
        (v!.position > const Duration(milliseconds: 60) || !playing);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // The words laid over the film take the app's type, not a page's.
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, box) {
            // The largest card of the film's proportion between the row of
            // controls and the foot of the screen.
            final double top = safe.top + 52;
            final double room = math.max(
              0,
              box.maxHeight - top - safe.bottom - 10,
            );
            double width = box.maxWidth;
            double height = width / kFilmAspect;
            if (height > room) {
              height = room;
              width = height * kFilmAspect;
            }
            final Rect place = Rect.fromLTWH(
              (box.maxWidth - width) / 2,
              top + (room - height) / 2,
              width,
              height,
            );
            final double pulled = _pull.clamp(0.0, 600.0);
            final double fade = 1 - math.min(pulled / 420, 0.7);
            final Animation<double> late = CurvedAnimation(
              parent: route,
              curve: const Interval(0.6, 1, curve: Curves.easeOut),
            );
            return Stack(
              children: [
                // Black, as a photograph is opened on; it lets the page show
                // through as the card is pulled away.
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: FadeTransition(
                      opacity: route,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: fade),
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: place,
                  child: Semantics(
                    button: true,
                    label: [
                      card.titleFor(widget.language),
                      _failed
                          ? l.videoOffline
                          : _ended
                          ? l.videoWatchAgain
                          : playing
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
                          scale: 1 - math.min(pulled / 1600, 0.16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: _heroOf(card),
                                child: _Frame(
                                  card: card,
                                  language: widget.language,
                                ),
                              ),
                              // The film over its picture, faded out with
                              // the rest as the card goes back to its tile.
                              if (_started && player != null)
                                FadeTransition(
                                  opacity: late,
                                  child: AnimatedOpacity(
                                    opacity: filmShows ? 1 : 0,
                                    duration: const Duration(milliseconds: 220),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        _corner,
                                      ),
                                      child: VideoPlayer(player),
                                    ),
                                  ),
                                ),
                              FadeTransition(
                                opacity: late,
                                child: _Over(
                                  card: card,
                                  started: _started,
                                  playing: playing,
                                  waiting: _waiting,
                                  failed: _failed,
                                  ended: _ended,
                                  onAgain: _play,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The row above the card: how far the film has run, and the
                // way out.
                Positioned(
                  top: safe.top + 4,
                  left: 20,
                  right: 12,
                  height: 44,
                  child: FadeTransition(
                    opacity: late,
                    child: Opacity(
                      opacity: fade,
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _run,
                              builder: (context, _) =>
                                  _RunBar(value: _run.value),
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
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 19,
                                        color: Colors.white,
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// How far the film has run: a thin line, white on a fainter white.
class _RunBar extends StatelessWidget {
  const _RunBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      height: 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.white.withValues(alpha: 0.22)),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: const ColoredBox(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

/// What is laid over the film. Before it is first played, the way to play
/// it and the word for it, low on the card, on the ground the films keep
/// clear there; paused, a smaller way to go on in the card's corner, so the
/// frame it stopped on is read whole; at its end, the way to watch it again,
/// in the room the last frame leaves between its picture and its source;
/// where it could not be had, the word that it needs a connection.
class _Over extends StatelessWidget {
  const _Over({
    required this.card,
    required this.started,
    required this.playing,
    required this.waiting,
    required this.failed,
    required this.ended,
    required this.onAgain,
  });

  final VideoCard card;
  final bool started, playing, waiting, failed, ended;
  final VoidCallback onAgain;

  /// Where on the card, from its top, the things laid over it stand (their
  /// middles): the way to play it on the ground of its first frame, and the
  /// way to watch it again between the last frame's picture (to 81%) and
  /// its source (from 90%).
  static const double playAt = 0.84, againAt = 0.853;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, box) {
        final double k = (box.maxWidth / 402).clamp(0.75, 1.1);
        // [child]'s middle at [y] of the card's height.
        Widget at(double y, Widget child) => Positioned(
          left: 0,
          right: 0,
          top: box.maxHeight * y,
          child: FractionalTranslation(
            translation: const Offset(0, -0.5),
            child: Center(child: child),
          ),
        );
        Widget round(double size, {required bool spin}) => Container(
          key: const ValueKey('video-play'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _filmInk.withValues(alpha: 0.9),
          ),
          alignment: Alignment.center,
          child: spin
              ? SizedBox.square(
                  dimension: size * 0.38,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.play_arrow_rounded,
                  size: size * 0.56,
                  color: Colors.white,
                ),
        );
        if (failed) {
          return Stack(
            children: [
              at(
                playAt,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28 * k),
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
              at(
                againAt,
                GestureDetector(
                  key: const ValueKey('video-again'),
                  onTap: onAgain,
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
            ],
          );
        }
        if (playing) return const SizedBox.shrink();
        if (started) {
          // Paused: the way on, small, in the corner.
          return Stack(
            children: [
              Positioned(
                right: 16 * k,
                bottom: 16 * k,
                child: round(46 * k, spin: waiting),
              ),
            ],
          );
        }
        final double button = 64 * k;
        return Stack(
          children: [
            at(playAt, round(button, spin: waiting)),
            Positioned(
              left: 0,
              right: 0,
              top: box.maxHeight * playAt + button / 2 + 12,
              child: Center(
                child: Text(
                  l.videoTapToPlay.toUpperCase(),
                  style: AppText.label(
                    size: 11,
                    weight: FontWeight.w700,
                    spacing: 1.4,
                    color: _filmInk.withValues(alpha: 0.72),
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
