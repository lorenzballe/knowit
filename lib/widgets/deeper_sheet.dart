/// Go deeper: what opens when the reader taps a card's source.
///
/// What the card file holds below what the card shows: the idea said simply
/// (`simply`), why it matters (`why`), the two views of a contested question
/// (`views`, or a debate's own other side), and the source itself with the
/// way to the original (`reference`). New cards fill these (tool/cards/
/// RULES.md §22); an older card shows what it has, and the source always.
///
/// For Astute+, where the answers are switched on, Claude adds what the file
/// does not: the card said simply or its two sides when the card has none
/// written, an everyday example, a test on a new case, the reader's own
/// reasoning looked at, and a question of theirs answered (sync/
/// card_ask.dart). On the free plan those are marked, and a tap opens the
/// paywall.
///
/// The sheet is the card's world (deeper/look.dart): its head is the card's
/// own colour, lit by lights that drift across it, with the card's question
/// set large (deeper/header.dart); each part below wears a colour of its own
/// from a set around the subject's, with a small drawing of its own
/// (deeper/art.dart). The two views face each other in two contrasting
/// halves; the reader's words and Claude's answers are a conversation. The
/// parts arrive one after another as the sheet opens, an answer is let down
/// over its part as it comes, and nothing moves for a reader who asked for
/// less motion (deeper/pieces.dart).
///
/// Being tried: three editorial ways of setting the parts under the same
/// head, with no drawings and colour only as the head's echo (deeper/
/// editorial.dart, [deeperStyle]); the column is the one shown for now.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:url_launcher/url_launcher.dart';

import '../analytics.dart';
import '../debug_flags.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../remote/knobs.dart';
import '../state/app_state.dart';
import '../sync/card_ask.dart';
import '../theme.dart';
import 'chunky.dart' show VerdictColours, chunkyEdge;
import 'deeper/app_style.dart' show AppBath, appBath;
import 'deeper/art.dart';
import 'deeper/editorial.dart';
import 'deeper/header.dart';
import 'deeper/look.dart';
import 'deeper/pieces.dart';
import 'motion.dart' show PopIn, RiseIn;
import 'premium.dart';
import 'reveal_body.dart' show sourceKindName;

/// Where a tap on a card's source goes: set once by the app (main.dart), so
/// a card's back, a page's source and the detail screen all open the same
/// sheet without each carrying the app. Null under a test that sets none.
abstract final class GoDeeper {
  static void Function(BuildContext context, Pill pill)? open;
}

/// Whether the answers by Claude are on: for the developer tools now (the
/// TestFlight installs), and for everyone the remote switch `cardAi` lets
/// in, once it is turned on.
bool cardAiOn(AppState app, String language) =>
    debugToolsOn ||
    Flags.on('cardAi', app.remoteContext(language), fallback: false);

/// Opens Go deeper on [pill].
Future<void> showDeeperSheet(BuildContext context, AppState app, Pill pill) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C141416),
    builder: (_) => DeeperSheet(app: app, pill: pill),
  );
}

class DeeperSheet extends StatefulWidget {
  const DeeperSheet({super.key, required this.app, required this.pill});

  final AppState app;
  final Pill pill;

  @override
  State<DeeperSheet> createState() => _DeeperSheetState();
}

class _DeeperSheetState extends State<DeeperSheet>
    with TickerProviderStateMixin {
  final Map<AskMode, AskResult?> _results = {};
  final Set<AskMode> _busy = {};

  /// What the reader sent, for the parts they write into: shown as theirs
  /// above the answer, and sent again on a retry.
  final Map<AskMode, String> _words = {};
  final TextEditingController _take = TextEditingController();
  final TextEditingController _ask = TextEditingController();
  bool _said = false;

  /// The sheet's arrival: the head's words, then the parts one after
  /// another, each drawing its picture in as it lands.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// The head's lights, drifting once and coming to rest: alive while the
  /// head is what the reader looks at, still while they read the parts.
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  /// How far the sheet has scrolled, for the head to lag behind.
  final ValueNotifier<double> _scroll = ValueNotifier<double>(0);

  /// Whether the reader has read past the head since its lights last
  /// drifted: coming back up to it sets them going again.
  bool _away = false;

  /// How far the first part lies over the head's foot.
  static const double _overlap = 26;

  Pill get pill => widget.pill;
  AppState get app => widget.app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_said) return;
    _said = true;
    if (deeperStill(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _drift.forward();
    }
    Analytics.capture('card deeper opened', {
      ...app.cardFacts(pill.id),
      'has_simply': pill.simply.isNotEmpty,
      'has_why': pill.why.isNotEmpty,
      'has_views': pill.views.length == 2,
      'has_link': _original.isNotEmpty,
      'ai': _aiOn,
      'is_plus': app.isPlus,
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    _scroll.dispose();
    _take.dispose();
    _ask.dispose();
    super.dispose();
  }

  bool get _aiOn => cardAiOn(app, Localizations.localeOf(context).languageCode);

  Future<void> _askAi(AskMode mode, {String text = ''}) async {
    if (_busy.contains(mode)) return;
    await requirePlus(context, app, () async {
      if (!mounted) return;
      setState(() {
        _busy.add(mode);
        _results.remove(mode);
        if (text.isNotEmpty) _words[mode] = text;
      });
      // The words sent move out of the box and into the conversation; the
      // box is left for the next ones.
      final TextEditingController? box = switch (mode) {
        AskMode.take => _take,
        AskMode.ask => _ask,
        _ => null,
      };
      if (box != null && text.isNotEmpty) {
        if (box.text.trim() == text) box.clear();
        FocusManager.instance.primaryFocus?.unfocus();
      }
      final DateTime start = DateTime.now();
      // The words written stay on the phone's side of analytics: only how
      // many there were is said.
      Analytics.capture('card ai asked', {
        ...app.cardFacts(pill.id),
        'mode': mode.name,
        'chars': text.length,
      });
      final AskResult result = await CardAsk.call(
        pill.id,
        mode,
        text: text,
        language: Localizations.localeOf(context).languageCode,
      );
      Analytics.capture('card ai answered', {
        ...app.cardFacts(pill.id),
        'mode': mode.name,
        'ok': result is AskAnswer,
        if (result case AskNone(:final why)) 'why_not': why.name,
        'ms': DateTime.now().difference(start).inMilliseconds,
      });
      if (!mounted) return;
      setState(() {
        _busy.remove(mode);
        _results[mode] = result;
      });
    }, source: 'card ai ${mode.name}');
  }

  /// Where the original is: the page or the DOI the card names, or, for an
  /// idea of a book, the book's own entry in the open library catalogue.
  String get _original => pill.reference.isNotEmpty
      ? pill.reference
      : (pill.book?.isbn.isNotEmpty ?? false)
      ? 'https://openlibrary.org/isbn/${pill.book!.isbn}'
      : '';

  Future<void> _openSource() async {
    final Uri? url = Uri.tryParse(_original);
    if (url == null) return;
    Analytics.capture('card source opened', app.cardFacts(pill.id));
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final double at = n.metrics.pixels;
    _scroll.value = at;
    if (at > 280) {
      _away = true;
    } else if (_away && at < 60) {
      _away = false;
      if (!deeperStill(context) && !_drift.isAnimating) {
        _drift.forward(from: 0);
      }
    }
    return false;
  }

  /// When the part at [i] begins to arrive, as a part of the arrival.
  static double _start(int i) => math.min(0.6, 0.16 + i * 0.075);

  Animation<double> _arrive(int i) => _entrance.drive(
    CurveTween(
      curve: Interval(
        _start(i),
        math.min(1, _start(i) + 0.42),
        curve: Curves.easeOutCubic,
      ),
    ),
  );

  Animation<double> _draw(int i) => _entrance.drive(
    CurveTween(curve: Interval(_start(i) + 0.1, math.min(1, _start(i) + 0.66))),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool ai = _aiOn;
    final bool plus = app.isPlus;
    final DeeperLook world = DeeperLook.of(pill.color, dark: p.isDark);
    // The head is always the card's world; set editorially, the parts
    // under it take one quiet tone of it.
    final DeeperLook look = deeperStyle == DeeperStyle.app
        ? world.quietOn(p.surface)
        : deeperEditorial
        ? world.quiet
        : world;
    // In the app's style the head's colour flows on down behind the
    // cards, and the head falls into it rather than into the ground.
    final Color? bath = deeperStyle == DeeperStyle.app
        ? appBath(world, p)
        : null;
    final List<Widget Function(Animation<double> draw)> parts = [
      // The idea said simply: written, or asked for.
      if (pill.simply.isNotEmpty)
        (draw) => DeeperTile(
          key: const ValueKey('deeper-simple'),
          tone: look.tone(DeeperPart.simply),
          art: DeeperArt.blocks,
          look: look,
          draw: draw,
          title: l.deeperSimple,
          child: Text(pill.simply, style: deeperSimply(context)),
        )
      else if (ai)
        (draw) => _AiPart(
          key: const ValueKey('deeper-simple-ai'),
          look: look,
          part: DeeperPart.simply,
          art: DeeperArt.blocks,
          draw: draw,
          title: l.deeperSimple,
          lead: l.deeperSimpleLead,
          go: l.deeperSimpleGo,
          style: deeperSimply(context),
          locked: !plus,
          busy: _busy.contains(AskMode.simple),
          result: _results[AskMode.simple],
          onAsk: () => _askAi(AskMode.simple),
        ),
      if (pill.why.isNotEmpty)
        (draw) => DeeperTile(
          key: const ValueKey('deeper-why'),
          tone: look.tone(DeeperPart.why),
          art: DeeperArt.target,
          look: look,
          draw: draw,
          title: l.deeperWhy,
          child: DeeperGlass(
            locked: !plus,
            onUnlock: () => _askUnlock('deeper why'),
            child: Text(pill.why, style: deeperBody(context)),
          ),
        ),
      // The two views: written, a debate's other side, or asked for.
      if (pill.views.length == 2)
        (draw) => DeeperTile(
          key: const ValueKey('deeper-views'),
          tone: look.tone(DeeperPart.sides),
          art: DeeperArt.scale,
          look: look,
          draw: draw,
          title: l.deeperSides,
          child: DeeperGlass(
            locked: !plus,
            onUnlock: () => _askUnlock('deeper views'),
            child: DeeperVersus(
              look: look,
              a: splitView(pill.views[0], l.deeperSideA),
              b: splitView(pill.views[1], l.deeperSideB),
              progress: draw,
            ),
          ),
        )
      else if (pill.counterpoint.isNotEmpty)
        (draw) => DeeperTile(
          key: const ValueKey('deeper-counterpoint'),
          tone: look.tone(DeeperPart.sides),
          art: DeeperArt.scale,
          look: look,
          draw: draw,
          title: l.deeperSides,
          child: DeeperVersus(
            look: look,
            a: (l.deeperSideB, pill.counterpoint),
            b: null,
            progress: draw,
          ),
        )
      else if (ai)
        (draw) => _AiPart(
          key: const ValueKey('deeper-sides-ai'),
          look: look,
          part: DeeperPart.sides,
          art: DeeperArt.scale,
          draw: draw,
          title: l.deeperSides,
          lead: l.deeperSidesLead,
          go: l.deeperSidesGo,
          style: deeperBody(context),
          locked: !plus,
          busy: _busy.contains(AskMode.sides),
          result: _results[AskMode.sides],
          onAsk: () => _askAi(AskMode.sides),
        ),
      // The idea where the reader will meet it: asked for.
      if (ai)
        (draw) => _AiPart(
          key: const ValueKey('deeper-example-ai'),
          look: look,
          part: DeeperPart.example,
          art: DeeperArt.cup,
          draw: draw,
          title: l.deeperExample,
          lead: l.deeperExampleLead,
          go: l.deeperExampleGo,
          style: deeperBody(context),
          locked: !plus,
          busy: _busy.contains(AskMode.example),
          result: _results[AskMode.example],
          onAsk: () => _askAi(AskMode.example),
        ),
      // The idea carried to a case the card does not mention: a question
      // to answer there and then, the best way to keep an idea.
      if (ai)
        (draw) => _QuizPart(
          key: const ValueKey('deeper-quiz-ai'),
          look: look,
          draw: draw,
          title: l.deeperQuiz,
          lead: l.deeperQuizLead,
          go: l.deeperQuizGo,
          locked: !plus,
          busy: _busy.contains(AskMode.quiz),
          result: _results[AskMode.quiz],
          onAsk: () => _askAi(AskMode.quiz),
          seed: pill.id.codeUnits.fold(0, (a, b) => a + b),
          onAnswered: (right) => Analytics.capture('card quiz answered', {
            ...app.cardFacts(pill.id),
            'right': right,
          }),
        ),
      if (ai)
        (draw) => _WritePart(
          key: const ValueKey('deeper-take'),
          look: look,
          part: DeeperPart.take,
          art: DeeperArt.lens,
          draw: draw,
          title: l.deeperYourTake,
          lead: l.deeperYourTakeLead,
          hint: l.deeperYourTakeHint,
          action: l.deeperAnalyse,
          controller: _take,
          locked: !plus,
          busy: _busy.contains(AskMode.take),
          result: _results[AskMode.take],
          asked: _words[AskMode.take],
          onAsk: (text) => _askAi(AskMode.take, text: text),
        ),
      if (ai)
        (draw) => _WritePart(
          key: const ValueKey('deeper-ask'),
          look: look,
          part: DeeperPart.ask,
          art: DeeperArt.chat,
          draw: draw,
          title: l.deeperAsk,
          lead: l.deeperAskLead,
          hint: l.deeperAskHint,
          action: l.deeperSend,
          controller: _ask,
          locked: !plus,
          busy: _busy.contains(AskMode.ask),
          result: _results[AskMode.ask],
          asked: _words[AskMode.ask],
          onAsk: (text) => _askAi(AskMode.ask, text: text),
        ),
    ];
    const BorderRadius top = BorderRadius.vertical(top: Radius.circular(30));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => DecoratedBox(
        decoration: BoxDecoration(color: look.ground, borderRadius: top),
        child: ClipRRect(
          borderRadius: top,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: SingleChildScrollView(
              controller: scroll,
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.paddingOf(context).bottom +
                    MediaQuery.viewInsetsOf(context).bottom +
                    34 -
                    _overlap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DeeperHeader(
                    key: const ValueKey('deeper-head'),
                    pill: pill,
                    // The head as it is; in the app's style it ends in
                    // the app's own ground.
                    look: bath != null ? world.quietOn(bath) : world,
                    drift: _drift,
                    scroll: _scroll,
                    entrance: _entrance,
                    still: deeperStill(context),
                    // In the app's style the head runs a little longer, for
                    // its colour to fall slowly into the ground.
                    overlap: deeperStyle == DeeperStyle.app
                        ? _overlap + 34
                        : _overlap,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_overlap),
                    child: Stack(
                      children: [
                        if (bath != null)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AppBath(
                              bath: bath,
                              ground: look.ground,
                              depth: MediaQuery.sizeOf(context).height * 0.95,
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Set editorially, nothing lies over the head's foot:
                            // it is let go into the sheet's ground instead, and the
                            // parts start below it.
                            if (deeperEditorial)
                              ExcludeSemantics(
                                child: Container(
                                  height: _overlap + 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        (bath ?? look.ground).withValues(
                                          alpha: 0,
                                        ),
                                        bath ?? look.ground,
                                      ],
                                      stops: const [0, 0.75],
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < parts.length; i++) ...[
                                    if (i > 0) SizedBox(height: deeperGap),
                                    DeeperArrive(
                                      animation: _arrive(i),
                                      child: EdFirst(
                                        first: i == 0,
                                        child: parts[i](_draw(i)),
                                      ),
                                    ),
                                  ],
                                  SizedBox(
                                    height: parts.isEmpty
                                        ? 8
                                        : deeperEditorial
                                        ? 44
                                        : 34,
                                  ),
                                  DeeperArrive(
                                    animation: _arrive(parts.length),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: DeeperSource(
                                        key: const ValueKey('deeper-source'),
                                        look: look,
                                        source: pill.source,
                                        kind: sourceKindName(
                                          l,
                                          pill.sourceKind,
                                        ),
                                        draw: _draw(parts.length),
                                        open: _original.isEmpty
                                            ? null
                                            : _openSource,
                                      ),
                                    ),
                                  ),
                                  if (ai) ...[
                                    const SizedBox(height: 26),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: DeeperAiNote(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _askUnlock(String source) => requirePlus(context, app, () {
    if (mounted) setState(() {});
  }, source: source);
}

/// Grows a part to what it now holds, and fades what it held out before
/// what it holds comes in: never a jump.
class _Grow extends StatelessWidget {
  const _Grow({required this.phase, required this.child});

  /// What the part is showing: a change of it fades one for the other.
  final Object phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool still = deeperStill(context);
    return AnimatedSize(
      duration: still ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 420),
        switchInCurve: const Interval(0.4, 1, curve: Curves.easeOut),
        switchOutCurve: const Interval(0.6, 1, curve: Curves.easeIn),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(key: ValueKey(phase), child: child),
      ),
    );
  }
}

/// What a part asked of Claude is showing.
Object _phaseOf(bool busy, AskResult? result) => switch ((busy, result)) {
  (true, _) => 'ask',
  (_, AskAnswer()) => 'answer',
  (_, AskNone()) => 'none',
  _ => 'ask',
};

/// The button that asks, with the lines where the answer will be under it
/// while it comes.
class _Asking extends StatelessWidget {
  const _Asking({
    required this.look,
    required this.tone,
    required this.label,
    required this.locked,
    required this.busy,
    required this.onAsk,
  });

  final DeeperLook look;
  final DeeperTone tone;
  final String label;
  final bool locked;
  final bool busy;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: DeeperAskButton(
          look: look,
          label: label,
          vivid: tone.vivid,
          locked: locked,
          busy: busy,
          onPressed: onAsk,
        ),
      ),
      // Set editorially, the button's own line says the answer is coming.
      if (busy && !deeperEditorial) ...[
        const SizedBox(height: 20),
        RiseIn(distance: 8, child: DeeperSkeleton(tone: tone)),
      ],
    ],
  );
}

/// A part Claude writes on request: a button until asked, then the answer.
class _AiPart extends StatelessWidget {
  const _AiPart({
    super.key,
    required this.look,
    required this.part,
    required this.art,
    required this.draw,
    required this.title,
    required this.lead,
    required this.go,
    required this.style,
    required this.locked,
    required this.busy,
    required this.result,
    required this.onAsk,
  });

  final DeeperLook look;
  final DeeperPart part;
  final DeeperArt art;
  final Animation<double> draw;
  final String title;
  final String lead;

  /// What its button says: the asking, in a few words.
  final String go;

  /// The answer's words, in the part's own voice.
  final TextStyle style;
  final bool locked;
  final bool busy;
  final AskResult? result;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final DeeperTone tone = look.tone(part);
    return DeeperTile(
      tone: tone,
      art: art,
      look: look,
      draw: draw,
      title: title,
      lead: lead,
      badge: locked ? const DeeperPlusBadge() : null,
      child: _Grow(
        phase: _phaseOf(busy, result),
        child: switch ((busy, result)) {
          (false, final AskAnswer answer) => DeeperUnfold(
            child: Text(answer.text, style: style),
          ),
          (false, final AskNone none) => _WhyNot(
            none,
            tone: tone,
            onRetry: onAsk,
          ),
          _ => _Asking(
            look: look,
            tone: tone,
            label: go,
            locked: locked,
            busy: busy,
            onAsk: onAsk,
          ),
        },
      ),
    );
  }
}

/// A new question on the card's idea: asked for, then answered on the spot,
/// the right option shown and why. Text that is not a quiz is shown as it
/// came.
class _QuizPart extends StatefulWidget {
  const _QuizPart({
    super.key,
    required this.look,
    required this.draw,
    required this.title,
    required this.lead,
    required this.go,
    required this.locked,
    required this.busy,
    required this.result,
    required this.onAsk,
    required this.seed,
    required this.onAnswered,
  });

  final DeeperLook look;
  final Animation<double> draw;
  final String title;
  final String lead;

  /// What its button says.
  final String go;
  final bool locked;
  final bool busy;
  final AskResult? result;
  final VoidCallback onAsk;

  /// Picks the order the options are shown in, the same for a card each
  /// time, so the right one is not always where the model put it.
  final int seed;
  final ValueChanged<bool> onAnswered;

  @override
  State<_QuizPart> createState() => _QuizPartState();
}

/// The six ways three options can stand.
const List<List<int>> _orders = [
  [0, 1, 2],
  [1, 2, 0],
  [2, 0, 1],
  [0, 2, 1],
  [2, 1, 0],
  [1, 0, 2],
];

class _QuizPartState extends State<_QuizPart> {
  /// The place tapped, once one is.
  int? _chosen;

  @override
  void didUpdateWidget(covariant _QuizPart old) {
    super.didUpdateWidget(old);
    if (old.result != widget.result) _chosen = null;
  }

  @override
  Widget build(BuildContext context) {
    final DeeperTone tone = widget.look.tone(DeeperPart.quiz);
    return DeeperTile(
      tone: tone,
      art: DeeperArt.quiz,
      look: widget.look,
      draw: widget.draw,
      title: widget.title,
      lead: widget.lead,
      badge: widget.locked ? const DeeperPlusBadge() : null,
      child: _Grow(
        phase: _phaseOf(widget.busy, widget.result),
        child: switch ((widget.busy, widget.result)) {
          (false, final AskAnswer answer) => _quiz(context, answer.text, tone),
          (false, final AskNone none) => _WhyNot(
            none,
            tone: tone,
            onRetry: widget.onAsk,
          ),
          _ => _Asking(
            look: widget.look,
            tone: tone,
            label: widget.go,
            locked: widget.locked,
            busy: widget.busy,
            onAsk: widget.onAsk,
          ),
        },
      ),
    );
  }

  Widget _quiz(BuildContext context, String text, DeeperTone tone) {
    final CardQuiz? quiz = CardQuiz.parse(text);
    if (quiz == null) {
      return DeeperUnfold(child: Text(text, style: deeperBody(context)));
    }
    final l = context.l10n;
    final Palette p = context.p;
    final VerdictColours verdict = VerdictColours.of(context);
    final List<int> order = _orders[widget.seed % _orders.length];
    final int? chosen = _chosen;
    final bool? right = chosen == null ? null : order[chosen] == quiz.right;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeeperUnfold(
          child: Text(
            quiz.question,
            style: switch (deeperStyle) {
              DeeperStyle.playful => AppText.display(
                size: 19.5,
                weight: FontWeight.w600,
                height: 1.3,
                spacing: -0.2,
                color: p.ink,
              ),
              DeeperStyle.app => AppText.display(
                size: 19,
                weight: FontWeight.w500,
                height: 1.35,
                spacing: -0.2,
                color: p.ink,
              ),
              DeeperStyle.magazine => AppText.display(
                size: 20,
                weight: FontWeight.w400,
                height: 1.36,
                spacing: -0.25,
                color: p.ink,
              ),
              _ => AppText.body(
                size: 17.5,
                weight: FontWeight.w600,
                height: 1.45,
                color: p.ink,
              ),
            },
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < order.length; i++)
          RiseIn(
            delay: Duration(milliseconds: 160 + 90 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuizOption(
                key: ValueKey('deeper-quiz-option-$i'),
                letter: 'ABC'[i],
                label: quiz.options[order[i]],
                tone: tone,
                // Once answered: the right one green, a wrong pick red,
                // the rest stepped back.
                mark: chosen == null
                    ? _Mark.open
                    : order[i] == quiz.right
                    ? _Mark.right
                    : i == chosen
                    ? _Mark.wrong
                    : _Mark.rest,
                onTap: chosen != null
                    ? null
                    : () {
                        final bool hit = order[i] == quiz.right;
                        if (hit) {
                          HapticFeedback.lightImpact();
                        } else {
                          HapticFeedback.selectionClick();
                        }
                        setState(() => _chosen = i);
                        widget.onAnswered(hit);
                      },
              ),
            ),
          ),
        if (right != null) ...[
          const SizedBox(height: 8),
          PopIn(
            child: Row(
              children: [
                Container(
                  width: deeperEditorial ? 22 : 30,
                  height: deeperEditorial ? 22 : 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: right ? verdict.rightLine : verdict.wrongLine,
                  ),
                  child: Icon(
                    right ? Icons.check_rounded : Icons.close_rounded,
                    size: deeperEditorial ? 14 : 19,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Flexible(
                  child: Text(
                    right ? l.deeperQuizRight : l.deeperQuizWrong,
                    key: const ValueKey('deeper-quiz-verdict'),
                    style: deeperEditorial
                        ? AppText.body(
                            size: 17,
                            weight: FontWeight.w700,
                            color: right ? verdict.rightInk : verdict.wrongInk,
                          )
                        : AppText.display(
                            size: 20,
                            weight: FontWeight.w700,
                            color: right ? verdict.rightInk : verdict.wrongInk,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DeeperUnfold(child: Text(quiz.why, style: deeperBody(context))),
        ],
      ],
    );
  }
}

/// What an option is saying about itself.
enum _Mark { open, right, wrong, rest }

/// One of the three options: its letter on a disc, its words; once a pick
/// is made, the right one green with a tick, a wrong pick red with a cross
/// and a shake, the rest stepped back.
class _QuizOption extends StatefulWidget {
  const _QuizOption({
    super.key,
    required this.letter,
    required this.label,
    required this.tone,
    required this.mark,
    required this.onTap,
  });

  final String letter;
  final String label;
  final DeeperTone tone;
  final _Mark mark;
  final VoidCallback? onTap;

  @override
  State<_QuizOption> createState() => _QuizOptionState();
}

class _QuizOptionState extends State<_QuizOption>
    with SingleTickerProviderStateMixin {
  bool _down = false;

  /// The shake of a wrong pick, or the swell of the right one.
  late final AnimationController _jolt = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(covariant _QuizOption old) {
    super.didUpdateWidget(old);
    if (old.mark != widget.mark &&
        (widget.mark == _Mark.wrong || widget.mark == _Mark.right) &&
        !deeperStill(context)) {
      _jolt.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _jolt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final VerdictColours v = VerdictColours.of(context);
    final DeeperTone tone = widget.tone;
    final (
      Color face,
      Color line,
      Color ink,
      Color disc,
      Color letter,
    ) = switch (widget.mark) {
      _Mark.right => (
        v.rightFill,
        v.rightLine,
        v.rightInk,
        v.rightLine,
        Colors.white,
      ),
      _Mark.wrong => (
        v.wrongFill,
        v.wrongLine,
        v.wrongInk,
        v.wrongLine,
        Colors.white,
      ),
      _ => (tone.field, tone.edge, p.ink, tone.vivid.fill, tone.vivid.ink),
    };
    final bool pressed = _down && widget.onTap != null;
    final bool ed = deeperEditorial;
    final Widget body = ed
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
            decoration: BoxDecoration(
              color: widget.mark == _Mark.open || widget.mark == _Mark.rest
                  ? (pressed ? tone.field : null)
                  : face,
              borderRadius: BorderRadius.circular(
                deeperStyle == DeeperStyle.app ? 16 : 2,
              ),
              border: Border.all(color: line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: switch (widget.mark) {
                    _Mark.right => Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: v.rightInk,
                    ),
                    _Mark.wrong => Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: v.wrongInk,
                    ),
                    _ => Text(
                      widget.letter,
                      textScaler: TextScaler.noScaling,
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        height: 1.35,
                        color: tone.accent,
                      ),
                    ),
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppText.body(
                      size: 15.5,
                      weight: FontWeight.w500,
                      height: 1.38,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          )
        : AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.only(
              top: pressed ? 4 : 0,
              bottom: pressed ? 0 : 4,
            ),
            decoration: BoxDecoration(
              color: chunkyEdge(line, p.isDark ? 0.08 : 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line, width: 1.6),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: disc,
                      shape: BoxShape.circle,
                    ),
                    child: switch (widget.mark) {
                      _Mark.right => Icon(
                        Icons.check_rounded,
                        size: 19,
                        color: letter,
                      ),
                      _Mark.wrong => Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: letter,
                      ),
                      _ => Text(
                        widget.letter,
                        textScaler: TextScaler.noScaling,
                        style: AppText.display(
                          size: 16,
                          weight: FontWeight.w800,
                          height: 1,
                          color: letter,
                        ),
                      ),
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppText.body(
                        size: 16,
                        weight: FontWeight.w600,
                        height: 1.32,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _down = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _down = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          opacity: widget.mark == _Mark.rest ? 0.5 : 1,
          child: AnimatedBuilder(
            animation: _jolt,
            child: body,
            builder: (context, child) {
              final double t = _jolt.value;
              if (widget.mark == _Mark.wrong) {
                return Transform.translate(
                  offset: Offset(8 * math.sin(t * math.pi * 6) * (1 - t), 0),
                  child: child,
                );
              }
              return Transform.scale(
                scale: 1 + 0.035 * math.sin(t * math.pi),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A part the reader writes into, their reasoning or their question, as a
/// conversation: what they sent on the right, the answer on the left, and
/// the box for the next words under them.
class _WritePart extends StatefulWidget {
  const _WritePart({
    super.key,
    required this.look,
    required this.part,
    required this.art,
    required this.draw,
    required this.title,
    required this.lead,
    required this.hint,
    required this.action,
    required this.controller,
    required this.locked,
    required this.busy,
    required this.result,
    required this.asked,
    required this.onAsk,
  });

  final DeeperLook look;
  final DeeperPart part;
  final DeeperArt art;
  final Animation<double> draw;
  final String title;
  final String lead;
  final String hint;
  final String action;
  final TextEditingController controller;
  final bool locked;
  final bool busy;
  final AskResult? result;

  /// The words last sent, once some are.
  final String? asked;
  final ValueChanged<String> onAsk;

  @override
  State<_WritePart> createState() => _WritePartState();
}

class _WritePartState extends State<_WritePart> {
  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final DeeperTone tone = widget.look.tone(widget.part);
    final String text = widget.controller.text.trim();
    final String? asked = widget.asked;
    final bool talking =
        asked != null && (widget.busy || widget.result != null);
    final bool ed = deeperEditorial;
    final bool inApp = deeperStyle == DeeperStyle.app;
    final OutlineInputBorder edge = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        inApp
            ? 16
            : ed
            ? 2
            : 18,
      ),
      borderSide: BorderSide(color: inApp ? p.line : tone.edge),
    );
    return DeeperTile(
      tone: tone,
      art: widget.art,
      look: widget.look,
      draw: widget.draw,
      title: widget.title,
      lead: widget.lead,
      badge: widget.locked ? const DeeperPlusBadge() : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Grow(
            phase: talking,
            child: !talking
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DeeperReaderBubble(text: asked, vivid: tone.vivid),
                        SizedBox(height: ed ? 16 : 12),
                        DeeperAnswerBubble(
                          tone: tone,
                          child: switch ((widget.busy, widget.result)) {
                            (false, final AskAnswer answer) => DeeperUnfold(
                              child: Text(
                                answer.text,
                                style: ed
                                    ? deeperBody(context)
                                    : AppText.body(
                                        size: 16.5,
                                        height: 1.5,
                                        color: p.ink,
                                      ),
                              ),
                            ),
                            (false, final AskNone none) => _WhyNot(
                              none,
                              tone: tone,
                              bare: true,
                              onRetry: () => widget.onAsk(asked),
                            ),
                            // Set editorially, the button's line is the
                            // only thing that moves while it comes.
                            _ =>
                              ed
                                  ? const SizedBox(width: double.infinity)
                                  : DeeperTyping(colour: tone.accent),
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          TextField(
            controller: widget.controller,
            maxLength: CardAsk.maxText,
            minLines: 2,
            maxLines: 5,
            enabled: !widget.busy,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            cursorColor: tone.accent,
            style: AppText.body(size: 16, height: 1.4, color: p.ink),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.body(size: 16, color: p.inkFaint),
              counterText: '',
              isDense: true,
              filled: inApp || !ed,
              fillColor: inApp
                  ? (p.isDark ? const Color(0xFF1A1A1E) : p.surface)
                  : tone.field,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: edge,
              enabledBorder: edge,
              disabledBorder: edge,
              focusedBorder: edge.copyWith(
                borderSide: BorderSide(
                  color: inApp ? p.lineStrong : tone.accent,
                  width: ed ? 1.2 : 1.8,
                ),
              ),
            ),
          ),
          SizedBox(height: ed ? 14 : 12),
          Align(
            alignment: ed
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: DeeperAskButton(
              look: widget.look,
              label: widget.action,
              vivid: tone.vivid,
              locked: widget.locked,
              busy: widget.busy,
              onPressed: text.length < 3 ? null : () => widget.onAsk(text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Why there is no answer, and, when it is worth it, the way to ask again.
class _WhyNot extends StatelessWidget {
  const _WhyNot(
    this.none, {
    required this.tone,
    required this.onRetry,
    this.bare = false,
  });

  final AskNone none;
  final DeeperTone tone;
  final VoidCallback onRetry;

  /// Inside a bubble that is already its ground.
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final AskWhyNot why = none.why;
    final String line = switch (why) {
      AskWhyNot.tomorrow => l.deeperTomorrow,
      AskWhyNot.declined => l.deeperDeclined,
      AskWhyNot.plus => l.deeperPlusOnly,
      AskWhyNot.later => l.deeperTryAgain,
    };
    final IconData icon = switch (why) {
      AskWhyNot.tomorrow => Icons.bedtime_rounded,
      AskWhyNot.declined => Icons.do_not_disturb_on_rounded,
      AskWhyNot.plus => Icons.lock_rounded,
      AskWhyNot.later => Icons.cloud_off_rounded,
    };
    final String? detail = debugToolsOn ? none.detail : null;
    final Widget said = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: tone.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line,
                style: AppText.body(size: 15.5, height: 1.4, color: p.ink),
              ),
            ),
          ],
        ),
        // The server's own words, for the TestFlight installs only.
        if (detail != null && detail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 30),
            child: Text(
              detail,
              key: const ValueKey('deeper-why-not-detail'),
              style: AppText.body(size: 11, color: p.inkFaint),
            ),
          ),
        if (why == AskWhyNot.later) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: _Retry(tone: tone, onTap: onRetry),
          ),
        ],
      ],
    );
    if (bare || deeperEditorial) return said;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tone.field,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.edge),
      ),
      child: said,
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.tone, required this.onTap});

  final DeeperTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            deeperEditorial && deeperStyle != DeeperStyle.app ? 2 : 99,
          ),
          border: Border.all(
            color: deeperEditorial ? tone.edge : tone.accent,
            width: deeperEditorial ? 1 : 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 18, color: tone.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.deeperRetry,
                style: AppText.body(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: tone.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
