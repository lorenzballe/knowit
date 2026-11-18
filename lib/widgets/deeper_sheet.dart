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
/// written, the reader's own reasoning looked at, and a question of theirs
/// answered (sync/card_ask.dart). On the free plan those are marked, and a
/// tap opens the paywall.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics.dart';
import '../debug_flags.dart';
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../remote/knobs.dart';
import '../state/app_state.dart';
import '../sync/card_ask.dart';
import '../theme.dart';
import 'premium.dart';
import 'grounds.dart';

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

class _DeeperSheetState extends State<DeeperSheet> {
  final Map<AskMode, AskResult?> _results = {};
  final Set<AskMode> _busy = {};
  final TextEditingController _take = TextEditingController();
  final TextEditingController _ask = TextEditingController();
  bool _said = false;

  Pill get pill => widget.pill;
  AppState get app => widget.app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_said) return;
    _said = true;
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
      });
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final bool ai = _aiOn;
    final bool plus = app.isPlus;
    final List<Widget> parts = [
      // The idea said simply: written, or asked for.
      if (pill.simply.isNotEmpty)
        _Part(
          key: const ValueKey('deeper-simple'),
          title: l.deeperSimple,
          child: _Body(pill.simply),
        )
      else if (ai)
        _AiPart(
          key: const ValueKey('deeper-simple-ai'),
          title: l.deeperSimple,
          locked: !plus,
          busy: _busy.contains(AskMode.simple),
          result: _results[AskMode.simple],
          onAsk: () => _askAi(AskMode.simple),
        ),
      if (pill.why.isNotEmpty)
        _Part(
          key: const ValueKey('deeper-why'),
          title: l.deeperWhy,
          child: _Glass(
            locked: !plus,
            onUnlock: () => _askUnlock('deeper why'),
            child: _Body(pill.why),
          ),
        ),
      // The two views: written, a debate's other side, or asked for.
      if (pill.views.length == 2)
        _Part(
          key: const ValueKey('deeper-views'),
          title: l.deeperSides,
          child: _Glass(
            locked: !plus,
            onUnlock: () => _askUnlock('deeper views'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Body(pill.views[0]),
                const SizedBox(height: 10),
                _Body(pill.views[1]),
              ],
            ),
          ),
        )
      else if (pill.counterpoint.isNotEmpty)
        _Part(
          key: const ValueKey('deeper-counterpoint'),
          title: l.deeperSides,
          child: _Body(pill.counterpoint),
        )
      else if (ai)
        _AiPart(
          key: const ValueKey('deeper-sides-ai'),
          title: l.deeperSides,
          locked: !plus,
          busy: _busy.contains(AskMode.sides),
          result: _results[AskMode.sides],
          onAsk: () => _askAi(AskMode.sides),
        ),
      // The idea where the reader will meet it: asked for.
      if (ai)
        _AiPart(
          key: const ValueKey('deeper-example-ai'),
          title: l.deeperExample,
          locked: !plus,
          busy: _busy.contains(AskMode.example),
          result: _results[AskMode.example],
          onAsk: () => _askAi(AskMode.example),
        ),
      // The idea carried to a case the card does not mention: a question
      // to answer there and then, the best way to keep an idea.
      if (ai)
        _QuizPart(
          key: const ValueKey('deeper-quiz-ai'),
          title: l.deeperQuiz,
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
        _WritePart(
          key: const ValueKey('deeper-take'),
          title: l.deeperYourTake,
          hint: l.deeperYourTakeHint,
          action: l.deeperAnalyse,
          controller: _take,
          locked: !plus,
          busy: _busy.contains(AskMode.take),
          result: _results[AskMode.take],
          onAsk: (text) => _askAi(AskMode.take, text: text),
        ),
      if (ai)
        _WritePart(
          key: const ValueKey('deeper-ask'),
          title: l.deeperAsk,
          hint: l.deeperAskHint,
          action: l.deeperSend,
          controller: _ask,
          locked: !plus,
          busy: _busy.contains(AskMode.ask),
          result: _results[AskMode.ask],
          onAsk: (text) => _askAi(AskMode.ask, text: text),
        ),
      _Part(
        key: const ValueKey('deeper-source'),
        title: l.deeperSource,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Body(pill.source),
            if (_original.isNotEmpty) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                key: const ValueKey('deeper-open-source'),
                onPressed: _openSource,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: p.link,
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: Text(
                  l.deeperOpenSource,
                  style: AppText.body(size: 14.5, weight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => SheetGround(
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(
              22,
              14,
              22,
              MediaQuery.paddingOf(context).bottom +
                  MediaQuery.viewInsetsOf(context).bottom +
                  24,
            ),
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
              const SizedBox(height: 20),
              Text(
                l.deeperTitle,
                style: AppText.display(
                  size: 24,
                  weight: FontWeight.w600,
                  spacing: -0.6,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pill.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 14, height: 1.35, color: p.inkMuted),
              ),
              const SizedBox(height: 18),
              for (final Widget part in parts) ...[
                part,
                const SizedBox(height: 12),
              ],
              if (ai)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l.deeperAiNote,
                    style: AppText.body(size: 12, color: p.inkFaint),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _askUnlock(String source) => requirePlus(context, app, () {
    if (mounted) setState(() {});
  }, source: source);
}

/// A part of the sheet: what it is, then what it says.
class _Part extends StatelessWidget {
  const _Part({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: p.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.body(
              size: 11,
              weight: FontWeight.w800,
              spacing: 1.2,
              color: p.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppText.body(size: 15.5, height: 1.45, color: context.p.ink),
  );
}

/// What Astute+ shows, behind frosted glass on the free plan, the way
/// through on top of it.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.locked,
    required this.onUnlock,
    required this.child,
  });

  final bool locked;
  final VoidCallback onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onUnlock,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: child,
            ),
          ),
          const _PlusChip(),
        ],
      ),
    );
  }
}

class _PlusChip extends StatelessWidget {
  const _PlusChip();

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: p.inverse,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 14, color: p.onInverse),
          const SizedBox(width: 6),
          Text(
            context.l10n.deeperPlusOnly,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: p.onInverse,
            ),
          ),
        ],
      ),
    );
  }
}

/// A part Claude writes on request: a button until asked, then the answer.
class _AiPart extends StatelessWidget {
  const _AiPart({
    super.key,
    required this.title,
    required this.locked,
    required this.busy,
    required this.result,
    required this.onAsk,
  });

  final String title;
  final bool locked;
  final bool busy;
  final AskResult? result;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return _Part(
      title: title,
      child: switch ((busy, result)) {
        (true, _) => const _Busy(),
        (_, final AskAnswer answer) => _Body(answer.text),
        (_, final AskNone none) => _WhyNot(none, onRetry: onAsk),
        _ => _AskButton(label: title, locked: locked, onPressed: onAsk),
      },
    );
  }
}

/// A new question on the card's idea: asked for, then answered on the spot,
/// the right option shown and why. Text that is not a quiz is shown as it
/// came.
class _QuizPart extends StatefulWidget {
  const _QuizPart({
    super.key,
    required this.title,
    required this.locked,
    required this.busy,
    required this.result,
    required this.onAsk,
    required this.seed,
    required this.onAnswered,
  });

  final String title;
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
  Widget build(BuildContext context) => _Part(
    title: widget.title,
    child: switch ((widget.busy, widget.result)) {
      (true, _) => const _Busy(),
      (_, final AskAnswer answer) => _quiz(context, answer.text),
      (_, final AskNone none) => _WhyNot(none, onRetry: widget.onAsk),
      _ => _AskButton(
        label: widget.title,
        locked: widget.locked,
        onPressed: widget.onAsk,
      ),
    },
  );

  Widget _quiz(BuildContext context, String text) {
    final CardQuiz? quiz = CardQuiz.parse(text);
    if (quiz == null) return _Body(text);
    final l = context.l10n;
    final Palette p = context.p;
    final List<int> order = _orders[widget.seed % _orders.length];
    final int? chosen = _chosen;
    final bool? right = chosen == null ? null : order[chosen] == quiz.right;
    final Color green = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3BE07A)
        : const Color(0xFF0E8A3E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          quiz.question,
          style: AppText.body(
            size: 15.5,
            weight: FontWeight.w700,
            height: 1.35,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < order.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _QuizOption(
            key: ValueKey('deeper-quiz-option-$i'),
            label: quiz.options[order[i]],
            // Once answered: the right one green, a wrong pick red.
            mark: chosen == null
                ? null
                : order[i] == quiz.right
                ? green
                : i == chosen
                ? p.alert
                : null,
            onTap: chosen != null
                ? null
                : () {
                    setState(() => _chosen = i);
                    widget.onAnswered(order[i] == quiz.right);
                  },
          ),
        ],
        if (right != null) ...[
          const SizedBox(height: 14),
          Text(
            right ? l.deeperQuizRight : l.deeperQuizWrong,
            key: const ValueKey('deeper-quiz-verdict'),
            style: AppText.body(
              size: 15,
              weight: FontWeight.w800,
              color: right ? green : p.alert,
            ),
          ),
          const SizedBox(height: 6),
          _Body(quiz.why),
        ],
      ],
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    super.key,
    required this.label,
    required this.mark,
    required this.onTap,
  });

  final String label;
  final Color? mark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final Color? m = mark;
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: m == null ? p.surfaceRaised : m.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: m ?? p.line, width: m == null ? 1 : 1.6),
          ),
          child: Text(
            label,
            style: AppText.body(
              size: 14.5,
              weight: FontWeight.w600,
              height: 1.3,
              color: p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A part the reader writes into: their reasoning, or their question.
class _WritePart extends StatefulWidget {
  const _WritePart({
    super.key,
    required this.title,
    required this.hint,
    required this.action,
    required this.controller,
    required this.locked,
    required this.busy,
    required this.result,
    required this.onAsk,
  });

  final String title;
  final String hint;
  final String action;
  final TextEditingController controller;
  final bool locked;
  final bool busy;
  final AskResult? result;
  final ValueChanged<String> onAsk;

  @override
  State<_WritePart> createState() => _WritePartState();
}

class _WritePartState extends State<_WritePart> {
  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final String text = widget.controller.text.trim();
    return _Part(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.controller,
            maxLength: CardAsk.maxText,
            minLines: 2,
            maxLines: 5,
            enabled: !widget.busy,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            style: AppText.body(size: 15, height: 1.35, color: p.ink),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppText.body(size: 15, color: p.inkFaint),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: p.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: p.line),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.busy)
            const _Busy()
          else ...[
            _AskButton(
              label: widget.action,
              locked: widget.locked,
              onPressed: text.length < 3 ? null : () => widget.onAsk(text),
            ),
            if (widget.result case final AskAnswer answer) ...[
              const SizedBox(height: 12),
              _Body(answer.text),
            ] else if (widget.result case final AskNone none) ...[
              const SizedBox(height: 12),
              _WhyNot(none, onRetry: () => widget.onAsk(text)),
            ],
          ],
        ],
      ),
    );
  }
}

class _AskButton extends StatelessWidget {
  const _AskButton({
    required this.label,
    required this.locked,
    required this.onPressed,
  });

  final String label;
  final bool locked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: p.inverse,
          foregroundColor: p.onInverse,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: const StadiumBorder(),
        ),
        icon: Icon(
          locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
          size: 16,
        ),
        label: Text(
          label,
          style: AppText.body(size: 14, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.p.ink.withValues(alpha: 0.6),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        context.l10n.deeperBusy,
        style: AppText.body(size: 14, color: context.p.inkMuted),
      ),
    ],
  );
}

class _WhyNot extends StatelessWidget {
  const _WhyNot(this.none, {required this.onRetry});

  final AskNone none;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final AskWhyNot why = none.why;
    final String line = switch (why) {
      AskWhyNot.tomorrow => l.deeperTomorrow,
      AskWhyNot.declined => l.deeperDeclined,
      AskWhyNot.plus => l.deeperPlusOnly,
      AskWhyNot.later => l.deeperTryAgain,
    };
    final String? detail = debugToolsOn ? none.detail : null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line,
                style: AppText.body(size: 14, color: context.p.inkMuted),
              ),
              // The server's own words, for the TestFlight installs only.
              if (detail != null && detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    detail,
                    key: const ValueKey('deeper-why-not-detail'),
                    style: AppText.body(size: 11, color: context.p.inkFaint),
                  ),
                ),
            ],
          ),
        ),
        if (why == AskWhyNot.later)
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: context.p.ink,
          ),
      ],
    );
  }
}
