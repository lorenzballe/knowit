import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../remote/gate.dart';
import '../remote/remote.dart';
import '../state/app_state.dart';
import '../store_links.dart';
import '../theme.dart';
import '../widgets/ambient.dart';
import '../widgets/balanced_text.dart';
import '../widgets/brand_mark.dart';
import '../widgets/chunky.dart' show chunkyEdge;
import '../widgets/ui.dart';

/// Keeps the app behind the update gate (lib/remote/gate.dart): the screen
/// that asks for an update, or the one that says the app is paused, in
/// place of everything else while the gate is closed.
///
/// It sits above the navigator, in MaterialApp's builder, so nothing of the
/// app — no route, no sheet, no dialog — is ever drawn over it, and it is
/// decided before the app's state is: from the build, the platform, the
/// language and the document kept from the last run, all read in main()
/// before the first frame. Asked again whenever that moves: a newer
/// document taken up, the state ready.
///
/// A gate that is closed from the launch keeps the app from being built at
/// all. One that closes later, over an app already running, keeps it
/// alive and out of sight underneath — its account and its store are
/// started once per launch and must not start twice — and tells it so
/// ([closes]): it asks nothing while it is covered. Every return to the app
/// asks the server again, so a gate lifted there lifts here.
class GateKeeper extends StatefulWidget {
  const GateKeeper({super.key, required this.app, required this.child});

  final AppState app;

  /// The app: the navigator and everything on it.
  final Widget child;

  /// Whether the gate is closed over [context]'s part of the app — which
  /// is then out of sight, and must ask the reader nothing.
  static bool closes(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GateScope>()?.closed ?? false;

  @override
  State<GateKeeper> createState() => _GateKeeperState();
}

class _GateKeeperState extends State<GateKeeper> {
  /// Whether the app has been on the screen in this run. Once it has, it
  /// stays built, under any gate that closes later.
  bool _appBuilt = false;

  /// The verdict last said to measurement, so each is said once.
  GateVerdict _said = GateVerdict.open;

  final GlobalKey _appKey = GlobalKey();

  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Who is looking, for the gate's rules: everything the app's state
  /// says once it is ready, and before that what the phone knows by itself
  /// — the plan and the days since the install are left out, and a pause
  /// aimed by them waits (UpdateGate.verdict).
  GateVerdict _verdict(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    final AppState app = widget.app;
    final RemoteContext at = app.ready
        ? app.remoteContext(language)
        : RemoteContext(
            platform: Remote.platform,
            build: Remote.build,
            language: language,
            plus: false,
            daysSinceInstall: 0,
            now: DateTime.now(),
          );
    return UpdateGate.verdict(at, stateKnown: app.ready);
  }

  /// A return to the app, with the gate closed: the server may have lifted
  /// it meanwhile. The app's own return asks too, when it is built; the
  /// second ask is the first one's (Remote.refresh).
  Future<void> _onResume() async {
    if (!_said.closes) return;
    try {
      await Remote.refresh(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  /// Says a gate that has just closed, once, after the frame that shows it.
  void _measure(GateVerdict verdict) {
    if (verdict == _said) return;
    final bool atLaunch = !_appBuilt;
    _said = verdict;
    if (!verdict.closes) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Analytics.capture('update gate shown', {
        'kind': verdict.kind.name,
        'reason': verdict.reason,
        'build': Remote.build,
        'platform': Remote.platform,
        'at_launch': atLaunch,
        'own_words': verdict.message != null,
        'remote_hash': Remote.config.hash,
      });
    });
  }

  Future<void> _update() async {
    final bool opened = await openStorePage(Remote.platform);
    Analytics.capture('update store opened', {
      'from': 'gate',
      'opened': opened,
      'build': Remote.build,
    });
  }

  /// Asks the server again at once, for the pause screen's button. True
  /// when the gate is still closed after it.
  Future<bool> _retry() async {
    bool took = false;
    try {
      took = await Remote.refresh(
        await SharedPreferences.getInstance(),
        force: true,
      );
    } catch (_) {}
    if (!mounted) return false;
    final bool still = _verdict(context).closes;
    Analytics.capture('pause retried', {
      'still_paused': still,
      'took_newer': took,
    });
    return still;
  }

  @override
  Widget build(BuildContext context) {
    final GateVerdict verdict = _verdict(context);
    _measure(verdict);
    final bool closed = verdict.closes;
    if (!closed) _appBuilt = true;
    return _GateScope(
      closed: closed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Always first, and under its own key, so that a gate opening and
          // closing over it never builds the app again.
          if (_appBuilt)
            KeyedSubtree(
              key: _appKey,
              child: Offstage(
                offstage: closed,
                child: TickerMode(enabled: !closed, child: widget.child),
              ),
            ),
          if (closed)
            GateScreen(
              key: ValueKey(verdict.kind),
              verdict: verdict,
              platform: Remote.platform,
              onUpdate: _update,
              onRetry: _retry,
            ),
        ],
      ),
    );
  }
}

class _GateScope extends InheritedWidget {
  const _GateScope({required this.closed, required super.child});

  final bool closed;

  @override
  bool updateShouldNotify(_GateScope old) => old.closed != closed;
}

/// The gate's full screen: "Update Astute", with the way to the store, or
/// "Astute is taking a short break", with a way to try again. Calm, in the
/// light the app opens in — the splash's blooms — and nothing on it but the
/// mark, the words and one button.
///
/// Public so a test, and the camera, can lay it out in every language.
class GateScreen extends StatefulWidget {
  const GateScreen({
    super.key,
    required this.verdict,
    required this.platform,
    required this.onUpdate,
    required this.onRetry,
  });

  final GateVerdict verdict;

  /// `ios`, `android`, `web`: which store the words name.
  final String platform;

  /// Opens the store, for an update.
  final VoidCallback onUpdate;

  /// Asks the server again, for a pause: true while the gate stays closed.
  final Future<bool> Function() onRetry;

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  bool _trying = false;
  bool _still = false;

  bool get _updating => widget.verdict.kind == GateKind.update;

  Future<void> _retry() async {
    if (_trying) return;
    setState(() {
      _trying = true;
      _still = false;
    });
    final bool still = await widget.onRetry();
    if (!mounted) return;
    setState(() {
      _trying = false;
      _still = still;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final String store = storeWordFor(widget.platform);
    final String title = _updating ? l.gateUpdateTitle : l.gatePauseTitle;
    final String line =
        widget.verdict.message ??
        (_updating ? l.gateUpdateLine(store) : l.gatePauseLine);
    return ScreenView(
      name: _updating ? 'update gate' : 'pause',
      child: Material(
        color: p.surface,
        child: Stack(
          children: [
            // The splash's light for an update, a cooler one for a pause:
            // the same app, waiting rather than starting.
            Positioned.fill(
              child: AmbientBlooms(
                colors: _updating ? kSceneBlooms.first : _kPauseBlooms,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  const EdgeInsets pad = EdgeInsets.fromLTRB(28, 20, 28, 18);
                  // The screen's whole height, and a scroll past it at the
                  // largest text — with no Spacer, which would ask the
                  // balanced lines for heights they cannot give before they
                  // are laid out: the room left over goes above the words
                  // and below them in equal parts.
                  return SingleChildScrollView(
                    padding: pad,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0, box.maxHeight - pad.vertical),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox.shrink(),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GateMark(kind: widget.verdict.kind),
                              const SizedBox(height: 34),
                              // Balanced, so a centred title never ends on
                              // one word alone, in any of the languages.
                              BalancedText(
                                title,
                                key: const ValueKey('gate-title'),
                                textAlign: TextAlign.center,
                                style: AppText.display(
                                  size: 32,
                                  weight: FontWeight.w700,
                                  height: 1.1,
                                  spacing: -1.1,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              BalancedText(
                                line,
                                key: const ValueKey('gate-line'),
                                textAlign: TextAlign.center,
                                style: AppText.body(
                                  size: 15.5,
                                  height: 1.5,
                                  color: p.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_updating)
                                PrimaryButton(
                                  key: const ValueKey('gate-update'),
                                  label: l.gateUpdateButton,
                                  onPressed: widget.onUpdate,
                                )
                              else
                                PrimaryButton(
                                  key: const ValueKey('gate-retry'),
                                  label: _trying
                                      ? l.gatePauseTrying
                                      : l.tryAgain,
                                  onPressed: _trying ? null : _retry,
                                ),
                              // A line's room is kept under the button either
                              // way, so the words above do not move when one
                              // is said there.
                              SizedBox(
                                height: 44,
                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: _still ? 1 : 0,
                                    duration: const Duration(milliseconds: 240),
                                    child: Text(
                                      _still ? l.gatePauseStill : '',
                                      key: const ValueKey('gate-still'),
                                      textAlign: TextAlign.center,
                                      style: AppText.body(
                                        size: 13,
                                        height: 1.35,
                                        color: p.inkMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A cooler light than the splash's, for the app at rest.
const List<Color> _kPauseBlooms = [
  Color(0xFF7A5CFF),
  Color(0xFF2B4BFF),
  Color(0xFF00C2A8),
];

/// The app's own mark, with what the gate says about it on its corner: an
/// arrow up for a newer version, two bars for a pause. Around it, a ring of
/// light breathes slowly — still when the phone asks for less motion.
class GateMark extends StatelessWidget {
  const GateMark({
    super.key,
    required this.kind,
    this.size = 96,
    this.glow = true,
  });

  final GateKind kind;

  /// The mark's own side; with [glow], the light around it takes more.
  final double size;

  /// Whether the ring of light is drawn: on the full screen, not in a row.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    // A small mark carries a larger badge, or its arrow is a speck.
    final double badge = size * (glow ? 0.36 : 0.42);
    final double radius = size * 0.225;
    // The tile's thickness: the mark sits on an edge of its own, as the
    // app's buttons do (ChunkyButton) — drawn rather than blurred, so it is
    // the same on every screen it lands on.
    final double depth = size * 0.065;
    final Color edge = p.isDark
        ? const Color(0xFF2E2E35)
        : chunkyEdge(const Color(0xFFF3F2EE), 0.13);
    // From the mark's corner to the edge of the room the light takes.
    final double inset = glow ? size * 0.35 : 0;
    final Color light = kind == GateKind.update
        ? const Color(0xFFFF2E9C)
        : const Color(0xFF2B4BFF);
    return SizedBox(
      width: size + 2 * inset,
      height: size + 2 * inset,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow)
            AmbientLoop(
              period: const Duration(seconds: 4),
              builder: (context, t) => Container(
                width: size * (1.32 + 0.16 * t),
                height: size * (1.32 + 0.16 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      light.withValues(
                        alpha: (p.isDark ? 0.26 : 0.18) * (1 - t * 0.35),
                      ),
                      light.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, depth),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: edge,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BrandMark(size: size),
          ),
          Positioned(
            right: inset - badge * 0.35,
            top: inset - badge * 0.35,
            child: ExcludeSemantics(
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: p.inverse,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface, width: glow ? 3 : 2),
                ),
                alignment: Alignment.center,
                child: Icon(
                  kind == GateKind.update
                      ? Icons.arrow_upward_rounded
                      : Icons.pause_rounded,
                  size: badge * 0.56,
                  color: p.onInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Says that a newer version is out, once for each build the server
/// suggests (UpdateGate.suggestion): what it is, and Update or Later.
/// True when the reader chose to update; the caller opens the store.
///
/// A sheet rather than a screen: the build still works, and the reader is
/// free to go on with it. main.dart chooses the moment, as for every other
/// sheet the app puts of its own accord.
Future<bool> showUpdateSheet(
  BuildContext context, {
  required String platform,
  String? message,
}) async {
  final bool? update = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => UpdateSheet(platform: platform, message: message),
  );
  return update ?? false;
}

/// The sheet itself. Public so a test, and the camera, can lay it out in
/// every language.
class UpdateSheet extends StatelessWidget {
  const UpdateSheet({super.key, required this.platform, this.message});

  /// `ios`, `android`: which store the words name.
  final String platform;

  /// The server's own words, said in place of the build's line.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      key: const ValueKey('update-sheet'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: p.lineStrong,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GateMark(kind: GateKind.update, size: 50, glow: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: BalancedText(
                      l.gateSoftTitle,
                      style: AppText.display(
                        size: 20,
                        weight: FontWeight.w600,
                        height: 1.2,
                        spacing: -0.6,
                        color: p.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            BalancedText(
              message ?? l.gateSoftLine(storeWordFor(platform)),
              style: AppText.body(size: 13.5, height: 1.45, color: p.inkMuted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              key: const ValueKey('update-yes'),
              label: l.gateUpdateButton,
              height: 52,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            QuietButton(
              key: const ValueKey('update-later'),
              label: l.gateSoftLater,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
