/// A book's summary, read: about a quarter of an hour, a part at a time
/// (lib/models/book_summary.dart).
///
/// Calm and plain, as a page of a book is: a bar with the book's title and
/// the way to the contents, a line under it that fills as the reader goes,
/// and each part on a page of its own: where it falls in the book, its
/// title, its paragraphs, and at its foot the way on. A swipe turns to the
/// next part. Where the reader stopped, and how far down, is kept
/// (lib/data/book_summaries.dart), so the next opening goes straight back
/// there; and the same place is the voice's, when the book is heard.
///
/// On the free plan a summary's first part is read, and the week's book
/// whole; a part past them is its title, a few faded lines and the offer of
/// the rest ([requirePlus], source `book summary`). The end is the book
/// read, and its cards offered to make its ideas stay.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../data/book_summaries.dart';
import '../data/books.dart';
import '../data/pill_bank.dart';
import '../explore/blocks/core/books_block.dart' show openBook;
import '../l10n/l10n.dart';
import '../models/book_summary.dart';
import '../screens/today_done_view.dart' show plusActionOf;
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/premium.dart';
import '../widgets/ui.dart' show BackCircle;
import 'book_player.dart';
import 'book_player_view.dart' show bookPlayerRoom;

/// Opens [book]'s summary where the reader left it, or at part [at], from
/// [from] (for what is measured).
Future<void> openSummary(
  BuildContext context,
  AppState app,
  CardBook book, {
  String? weekly,
  int? at,
  String from = 'book',
}) async {
  final SummaryRef? ref = PillBank.summaryOf(book.id);
  if (ref == null) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'summary'),
      builder: (_) => SummaryReaderScreen(
        app: app,
        book: book,
        summaryRef: ref,
        weekly: weekly,
        at: at,
        from: from,
      ),
    ),
  );
}

/// The reader.
class SummaryReaderScreen extends StatefulWidget {
  const SummaryReaderScreen({
    super.key,
    required this.app,
    required this.book,
    required this.summaryRef,
    this.weekly,
    this.at,
    this.from = 'book',
  });

  final AppState app;
  final CardBook book;
  final SummaryRef summaryRef;

  /// The book of the week's id: whole for everybody.
  final String? weekly;

  /// The part to open at; where the reader left it when null.
  final int? at;
  final String from;

  @override
  State<SummaryReaderScreen> createState() => _SummaryReaderScreenState();
}

class _SummaryReaderScreenState extends State<SummaryReaderScreen> {
  BookSummary? _summary;
  bool _failed = false;
  PageController? _pages;
  int _part = 0;
  double _through = 0;
  final Map<int, ScrollController> _scrolls = {};

  /// The parts said read this sitting, so each is said once.
  final Set<int> _said = {};
  bool _finishedSaid = false;

  AppState get _app => widget.app;
  String get _book => widget.book.id;
  bool get _whole => _app.isPlus || _book == widget.weekly;

  @override
  void initState() {
    super.initState();
    _app.addListener(_onApp);
    final BookSummary? now = BookSummaries.instance.inHand(widget.summaryRef);
    if (now != null) {
      _ready(now);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _app.removeListener(_onApp);
    // The book's page told where the reader stopped, as the reader goes.
    if (_summary != null && _part < _summary!.parts.length) {
      _keep(notify: true);
    }
    _pages?.dispose();
    for (final ScrollController c in _scrolls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Astute+ taken from the offer: the parts it opens are drawn at once.
  void _onApp() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    try {
      final BookSummary s = await BookSummaries.instance.of(widget.summaryRef);
      if (mounted) setState(() => _ready(s));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _ready(BookSummary s) {
    _summary = s;
    final SummaryPlace? place = _app.summaries.placeOf(_book);
    final bool resumed = widget.at == null && place != null && place.underway;
    final int start = (widget.at ?? (resumed ? place.part : 0)).clamp(
      0,
      s.parts.length - 1,
    );
    _part = start;
    _through = resumed && place.part == start ? place.through : 0;
    _pages = PageController(initialPage: start);
    Analytics.capture('summary opened', {
      'book': _book,
      'from': widget.from,
      'part': start + 1,
      'of': s.parts.length,
      'weekly': _book == widget.weekly,
      'is_plus': _app.isPlus,
      'resumed': resumed,
    });
    _keep(notify: true);
    // Back down the page to where the reader stopped, once it is laid out.
    final double through = _through;
    if (through > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ScrollController c = _scrollOf(start);
        if (c.hasClients) {
          c.jumpTo(c.position.maxScrollExtent * through);
        }
      });
    }
  }

  ScrollController _scrollOf(int i) => _scrolls.putIfAbsent(i, () {
    final ScrollController c = ScrollController();
    c.addListener(() => _scrolled(i, c));
    return c;
  });

  void _scrolled(int i, ScrollController c) {
    if (i != _part || !c.hasClients) return;
    final double most = c.position.maxScrollExtent;
    final double through = most <= 0
        ? 1
        : (c.position.pixels / most).clamp(0.0, 1.0);
    if ((through - _through).abs() >= 0.04 || through >= 0.98) {
      setState(() => _through = through);
      _keep(notify: false);
    }
    if (through >= 0.97) _read(i, how: 'scroll');
  }

  /// Keeps where the reader is. [notify] tells the book's page: only when
  /// the part changes, not on every line scrolled.
  void _keep({required bool notify}) {
    final SummaryPlace place =
        _app.summaries.placeOf(_book) ?? const SummaryPlace();
    unawaited(
      _app.summaries.keep(
        _book,
        place.copyWith(part: _part, through: _through, finished: false),
        notify: notify,
      ),
    );
  }

  /// Part [i] read to its end, said once a sitting.
  void _read(int i, {required String how}) {
    final BookSummary? s = _summary;
    if (s == null || i >= s.parts.length || _locked(i)) return;
    unawaited(_app.summaries.markRead(_book, i));
    if (!_said.add(i)) return;
    Analytics.capture('summary part read', {
      'book': _book,
      'part': i + 1,
      'of': s.parts.length,
      'is_plus': _app.isPlus,
      'how': how,
    });
  }

  bool _locked(int i) => !_whole && i > 0;

  void _turned(int i) {
    final BookSummary? s = _summary;
    if (s == null) return;
    // Turned past a part: it is read, as a page turned is.
    if (i > _part) _read(_part, how: 'turn');
    setState(() {
      _part = i;
      _through = 0;
    });
    if (i >= s.parts.length) {
      unawaited(_app.summaries.finish(_book));
      if (!_finishedSaid) {
        _finishedSaid = true;
        Analytics.capture('summary finished', {
          'book': _book,
          'of': s.parts.length,
          'read': _app.summaries.placeOf(_book)?.read.length ?? 0,
          'is_plus': _app.isPlus,
        });
      }
      return;
    }
    _keep(notify: true);
  }

  void _goTo(int i) {
    final PageController? pages = _pages;
    if (pages == null || !pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(i);
    } else {
      pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final BookSummary? s = _summary;
    return Scaffold(
      key: const ValueKey('summary-reader'),
      backgroundColor: p.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Bar(
              title: widget.book.book.title,
              onContents: s == null ? null : () => _contents(context, s),
            ),
            if (s != null)
              _Progress(
                summary: s,
                part: _part,
                through: _through,
                read: _app.summaries.placeOf(_book)?.read ?? const {},
                whole: _whole,
              ),
            Expanded(
              child: s == null
                  ? _Waiting(failed: _failed, onRetry: _load)
                  : PageView.builder(
                      controller: _pages,
                      onPageChanged: _turned,
                      itemCount: s.parts.length + 1,
                      itemBuilder: (context, i) => i == s.parts.length
                          ? _End(
                              app: _app,
                              book: widget.book,
                              summary: s,
                              weekly: widget.weekly,
                            )
                          : _locked(i)
                          ? _Gate(
                              app: _app,
                              summary: s,
                              part: i,
                              scroll: _scrollOf(i),
                            )
                          : _PartPage(
                              book: _book,
                              summary: s,
                              part: i,
                              scroll: _scrollOf(i),
                              onNext: () => _goTo(i + 1),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contents(BuildContext context, BookSummary s) async {
    final int? to = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C141416),
      builder: (_) => SummaryContents(
        summary: s,
        part: _part,
        read: _app.summaries.placeOf(_book)?.read ?? const {},
        locked: _locked,
      ),
    );
    if (to != null && mounted) _goTo(to);
  }
}

/// The bar over the reader: back, the book's title, the contents.
class _Bar extends StatelessWidget {
  const _Bar({required this.title, required this.onContents});

  final String title;
  final VoidCallback? onContents;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Row(
        children: [
          BackCircle(onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.display(
                size: 15.5,
                weight: FontWeight.w600,
                color: p.ink.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: context.l10n.summaryContents,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('summary-contents'),
              behavior: HitTestBehavior.opaque,
              onTap: onContents,
              // The back button's ring, on the other side of the title.
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.line),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.toc_rounded, size: 19, color: p.ink),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stroke a part, under the bar: the parts read filled, the one open
/// filled as far as it has been read, the ones for Astute+ fainter.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.summary,
    required this.part,
    required this.through,
    required this.read,
    required this.whole,
  });

  final BookSummary summary;
  final int part;
  final double through;
  final Set<int> read;
  final bool whole;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final int n = summary.parts.length;
    return Padding(
      key: const ValueKey('summary-line'),
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Row(
        children: [
          for (int k = 0; k < n; k++)
            Expanded(
              child: Container(
                height: 2.5,
                margin: EdgeInsets.only(right: k == n - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  color: !whole && k > 0
                      ? p.line.withValues(alpha: 0.5)
                      : p.line,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: part >= n
                      ? 1
                      : k == part
                      ? through
                      : read.contains(k) || k < part
                      ? 1
                      : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.ink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Where a part falls in the book, as its page heads it: PART 2 OF 7; and,
/// while the voice reads this very part, a quiet mark that says so.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow({
    required this.book,
    required this.summary,
    required this.part,
  });

  final String book;
  final BookSummary summary;
  final int part;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final Widget where = Text(
      l.summaryPartOf(part + 1, summary.parts.length).toUpperCase(),
      style: AppText.label(
        size: 11,
        weight: FontWeight.w800,
        spacing: 1.4,
        color: p.ink.withValues(alpha: 0.5),
      ),
    );
    return ValueListenableBuilder<BookPlayer?>(
      valueListenable: BookPlayer.current,
      builder: (context, player, _) {
        if (player == null || player.book.id != book) return where;
        return ListenableBuilder(
          listenable: player,
          builder: (context, _) {
            final bool here =
                player.at == part && player.phase == BookPlayerPhase.playing;
            if (!here) return where;
            return Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                where,
                Row(
                  key: const ValueKey('summary-now-playing'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 13,
                      color: p.ink.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l.summaryNowPlaying.toUpperCase(),
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w800,
                        spacing: 1.4,
                        color: p.ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The foot of a page: room for the small player while a book plays, and
/// the phone's own edge.
EdgeInsets _pagePadding(BuildContext context) => EdgeInsets.fromLTRB(
  24,
  22,
  24,
  MediaQuery.paddingOf(context).bottom + 36 + bookPlayerRoom(context),
);

/// One part: where it falls, its title, its paragraphs, and the way on.
class _PartPage extends StatelessWidget {
  const _PartPage({
    required this.book,
    required this.summary,
    required this.part,
    required this.scroll,
    required this.onNext,
  });

  final String book;
  final BookSummary summary;
  final int part;
  final ScrollController scroll;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final SummaryPart here = summary.parts[part];
    return ValueListenableBuilder<BookPlayer?>(
      valueListenable: BookPlayer.current,
      builder: (context, _, _) => ListView(
        key: ValueKey('summary-page-$part'),
        controller: scroll,
        padding: _pagePadding(context),
        children: [
          _Eyebrow(book: book, summary: summary, part: part),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              here.title,
              style: AppText.display(
                size: 29,
                weight: FontWeight.w600,
                height: 1.12,
                spacing: -0.6,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 28,
              height: 2,
              color: p.ink.withValues(alpha: 0.22),
            ),
          ),
          const SizedBox(height: 20),
          for (final String paragraph in here.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Text(
                typeset(paragraph),
                style: AppText.body(
                  size: 17.5,
                  height: 1.62,
                  color: p.ink.withValues(alpha: 0.88),
                ),
              ),
            ),
          const SizedBox(height: 14),
          _Next(summary: summary, part: part, onTap: onNext),
        ],
      ),
    );
  }
}

/// The way on, at the foot of a part: the next part's title, or the end.
class _Next extends StatelessWidget {
  const _Next({required this.summary, required this.part, required this.onTap});

  final BookSummary summary;
  final int part;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final bool last = part == summary.parts.length - 1;
    if (last) {
      return SizedBox(
        height: 54,
        child: FilledButton(
          key: const ValueKey('summary-finish'),
          style: FilledButton.styleFrom(
            backgroundColor: p.inverse,
            foregroundColor: p.onInverse,
            shape: const StadiumBorder(),
          ),
          onPressed: onTap,
          child: Text(
            l.summaryFinish,
            style: AppText.body(size: 16, weight: FontWeight.w700),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('summary-next'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.lineStrong),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.summaryNextPart.toUpperCase(),
                      style: AppText.label(
                        size: 10.5,
                        weight: FontWeight.w800,
                        spacing: 1.4,
                        color: p.ink.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      summary.parts[part + 1].title,
                      style: AppText.display(
                        size: 17,
                        weight: FontWeight.w600,
                        height: 1.22,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 20, color: p.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// A part on the free plan past the first: its title, its first lines
/// fading out, and the offer of the rest.
class _Gate extends StatelessWidget {
  const _Gate({
    required this.app,
    required this.summary,
    required this.part,
    required this.scroll,
  });

  final AppState app;
  final BookSummary summary;
  final int part;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    final SummaryPart here = summary.parts[part];
    return ListView(
      key: ValueKey('summary-gate-$part'),
      controller: scroll,
      padding: _pagePadding(context),
      children: [
        Text(
          l.summaryPartOf(part + 1, summary.parts.length).toUpperCase(),
          style: AppText.label(
            size: 11,
            weight: FontWeight.w800,
            spacing: 1.4,
            color: p.ink.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          here.title,
          style: AppText.display(
            size: 29,
            weight: FontWeight.w600,
            height: 1.12,
            spacing: -0.6,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 20),
        // The first lines, fading into the page: what the part opens on.
        ExcludeSemantics(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(rect),
            child: Text(
              typeset(here.paragraphs.first),
              maxLines: 4,
              overflow: TextOverflow.clip,
              style: AppText.body(
                size: 17.5,
                height: 1.62,
                color: p.ink.withValues(alpha: 0.88),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          key: const ValueKey('summary-gate'),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.plusNameCaps,
                style: AppText.label(
                  size: 10.5,
                  weight: FontWeight.w700,
                  spacing: 1.6,
                  color: p.link,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.summaryGateTitle,
                style: AppText.display(
                  size: 21,
                  weight: FontWeight.w600,
                  height: 1.2,
                  spacing: -0.3,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l.summaryGateLine(summary.parts.length),
                style: AppText.body(
                  size: 14,
                  height: 1.4,
                  color: p.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              ChunkyButton(
                key: const ValueKey('summary-plus'),
                label: plusActionOf(context),
                fill: p.inverse,
                ink: p.onInverse,
                height: 50,
                onPressed: () =>
                    requirePlus(context, app, () {}, source: 'book summary'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The end: the book read, and its cards, to make its ideas stay.
class _End extends StatelessWidget {
  const _End({
    required this.app,
    required this.book,
    required this.summary,
    required this.weekly,
  });

  final AppState app;
  final CardBook book;
  final BookSummary summary;
  final String? weekly;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    // The edition, as the summary names it, without its links.
    final String edition = summary.sources.isEmpty
        ? ''
        : summary.sources.first
              .replaceAll(RegExp(r',?\s*ISBN \d+'), '')
              .replaceAll(RegExp(r',?\s*https?://\S+'), '')
              .trim();
    return ListView(
      key: const ValueKey('summary-end'),
      padding: _pagePadding(context).copyWith(top: 56),
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: p.inverse, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 28, color: p.onInverse),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l.summaryDoneTitle(summary.title),
          textAlign: TextAlign.center,
          style: AppText.display(
            size: 27,
            weight: FontWeight.w600,
            height: 1.15,
            spacing: -0.5,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l.summaryDoneLine,
          textAlign: TextAlign.center,
          style: AppText.body(
            size: 15,
            height: 1.45,
            color: p.ink.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 54,
          child: FilledButton(
            key: const ValueKey('summary-to-cards'),
            style: FilledButton.styleFrom(
              backgroundColor: p.inverse,
              foregroundColor: p.onInverse,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              final NavigatorState nav = Navigator.of(context);
              nav.pop();
              openBook(nav.context, app, book, weekly: weekly);
            },
            child: Text(
              l.summaryToCards,
              style: AppText.body(size: 16, weight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            key: const ValueKey('summary-back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: p.ink,
              side: BorderSide(color: p.lineStrong, width: 1.2),
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              l.summaryBackToBook,
              style: AppText.body(size: 16, weight: FontWeight.w700),
            ),
          ),
        ),
        if (edition.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            edition,
            textAlign: TextAlign.center,
            style: AppText.body(size: 12.5, height: 1.4, color: p.inkFaint),
          ),
        ],
      ],
    );
  }
}

/// While the summary comes, or when it could not: a quiet wait, or the
/// word that it needs the network once, and the way to try again.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    if (!failed) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: p.inkMuted),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.summaryNeedsNetwork,
              textAlign: TextAlign.center,
              style: AppText.body(size: 15, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 14),
            TextButton(
              key: const ValueKey('summary-retry'),
              onPressed: onRetry,
              child: Text(
                l.tryAgain,
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The contents: every part of the summary, what is read, where the reader
/// is, and what Astute+ opens. Hands back the part tapped.
class SummaryContents extends StatelessWidget {
  const SummaryContents({
    super.key,
    required this.summary,
    required this.part,
    required this.read,
    required this.locked,
  });

  final BookSummary summary;
  final int part;
  final Set<int> read;
  final bool Function(int part) locked;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final l = context.l10n;
    return Container(
      key: const ValueKey('summary-contents-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 18),
            Text(
              l.summaryContents.toUpperCase(),
              style: AppText.label(
                size: 10.5,
                weight: FontWeight.w700,
                spacing: 1.6,
                color: p.ink.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary.title,
              style: AppText.display(
                size: 24,
                weight: FontWeight.w600,
                spacing: -0.5,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < summary.parts.length; i++)
              InkWell(
                key: ValueKey('summary-contents-$i'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).pop(i),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  decoration: i == part
                      ? BoxDecoration(
                          color: p.surfaceRaised,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.line),
                        )
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${i + 1}',
                          style: AppText.display(
                            size: 17,
                            weight: FontWeight.w600,
                            color: p.ink.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          summary.parts[i].title,
                          style: AppText.body(
                            size: 15,
                            weight: FontWeight.w600,
                            height: 1.35,
                            color: locked(i) ? p.inkMuted : p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        locked(i)
                            ? Icons.lock_rounded
                            : read.contains(i)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: read.contains(i) && !locked(i)
                            ? const Color(0xFF22C55E)
                            : p.ink.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
