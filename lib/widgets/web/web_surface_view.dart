import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/pill.dart';
import '../../state/music_sound.dart';
import '../../theme.dart';
import 'card_kit.dart';
import 'page_gestures.dart';
import 'page_messages.dart';
import 'web_card_page.dart';
import 'web_surface.dart';

/// Any page made with the card kit, drawn [height] tall and as wide as it
/// is given: what Explore's `web` block draws with, and anything else that
/// wants a piece of kit HTML on screen.
///
/// The page gets what a free card's page gets — the kit, its libraries and
/// fonts inside it, the bridge, the reader's theme, language, motion and
/// sound — except a deck: there is no card to turn or send on, so it holds
/// the finger only on the parts it marks as its own (`data-drag`,
/// `touch-action: none`), takes taps, and leaves every other drag to what
/// it sits in, a list that scrolls. What it says that only its host can
/// act on — an answer, a tap — goes to [onMessage].
Widget webSurface(
  BuildContext context, {
  required String html,
  required double height,
  ValueChanged<PageMessage>? onMessage,
}) => SizedBox(
  height: height,
  child: KitPageView(html: html, onMessage: onMessage),
);

/// A kit page that fills the box it is given. See [webSurface].
class KitPageView extends StatefulWidget {
  const KitPageView({super.key, required this.html, this.onMessage});

  final String html;
  final ValueChanged<PageMessage>? onMessage;

  @override
  State<KitPageView> createState() => _KitPageViewState();
}

class _KitPageViewState extends State<KitPageView> {
  late final WebSurface _surface = WebSurfaces.create()..onMessage = _heard;
  bool _ready = false;
  List<Rect> _zones = const [];
  String? _loaded;
  PageEnv? _env;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    MusicSound.on.addListener(_retell);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _retell();
  }

  @override
  void dispose() {
    MusicSound.on.removeListener(_retell);
    _surface.dispose();
    super.dispose();
  }

  PageEnv _envAt(Size size) => PageEnv(
    dark: context.p.isDark,
    language: Localizations.localeOf(context).languageCode,
    calm: MediaQuery.disableAnimationsOf(context),
    sound: MusicSound.on.value,
    touch: WebTouch.drags,
    platform: kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : 'ios',
    shown: true,
    size: size,
  );

  /// Tells a page already drawn what changed about where it is shown.
  void _retell() {
    final PageEnv? env = _env;
    if (env == null || !mounted) return;
    final PageEnv now = _envAt(env.size);
    final Map<String, Object?>? change = now.since(env);
    _env = now;
    if (change != null && _ready) _surface.tell({'t': 'env', 'env': change});
  }

  Future<void> _load(Size size) async {
    if (_loading || (_loaded == widget.html && _env?.size == size)) return;
    _loading = true;
    final PageEnv env = _envAt(size);
    try {
      final String page = await CardKit.instance.page(widget.html, env);
      if (!mounted) return;
      _env = env;
      _loaded = widget.html;
      setState(() => _ready = false);
      await _surface.load(page, background: const Color(0x00000000));
    } catch (error) {
      debugPrint('Astute: a kit page did not load: $error');
    } finally {
      _loading = false;
    }
  }

  void _heard(PageMessage message) {
    if (!mounted) return;
    switch (message) {
      case PageReady():
        setState(() => _ready = true);
      case PageZones(:final rects):
        _zones = rects;
      default:
        if (!answerAside(message)) widget.onMessage?.call(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_surface.available) return const SizedBox.expand();
    return LayoutBuilder(
      builder: (context, box) {
        final Size size = box.biggest;
        if (size.isFinite && !size.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load(size);
          });
        }
        return IgnorePointer(
          ignoring: !_ready,
          child: AnimatedOpacity(
            opacity: _ready ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            child: _surface.view(
              gestures: pageGestures(WebTouch.drags, zones: () => _zones),
            ),
          ),
        );
      },
    );
  }
}
