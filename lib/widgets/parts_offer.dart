import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../screens/genres_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'consent_card.dart';

/// Which parts, offered once on the finished day's shelf: "Which parts? A
/// few days in, you know the cards. Inside each subject, keep the parts you
/// want and leave the rest", with the way in and "Not now".
///
/// The first run used to ask it before a single card — two hundred genres,
/// and three strands inside each — and a tester said it belonged after a
/// few days. So it comes from the third finished day (`parts.offerDay`),
/// to a reader who has not chosen parts already, the evening it is first
/// shown and never again (AppState.partsOfferDue); and quietly, as a card
/// among the shelf's, never a sheet over it. The parts are always in the
/// fine-tuning under the topics editor besides.
class PartsOfferCard extends StatefulWidget {
  const PartsOfferCard({
    super.key,
    required this.app,
    this.padding = EdgeInsets.zero,
  });

  final AppState app;

  /// Around the card while it is up; folded away with it once answered.
  final EdgeInsets padding;

  /// Whether the card is on the shelf now: due, and not on an evening whose
  /// reminder question is still to come over the shelf.
  static bool due(AppState app) =>
      app.partsOfferDue && !ConsentCard.reminderFirst(app);

  @override
  State<PartsOfferCard> createState() => _PartsOfferCardState();
}

class _PartsOfferCardState extends State<PartsOfferCard> {
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    // Noted as it is put on the shelf, so it is put on no other evening.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && PartsOfferCard.due(widget.app)) {
        widget.app.notedPartsOfferShown();
      }
    });
  }

  Future<void> _choose() async {
    // Taken before anything is awaited: once the answer is kept the shelf
    // folds the card away, and the page still has to open.
    final NavigatorState navigator = Navigator.of(context);
    setState(() => _answered = true);
    final AppState app = widget.app;
    unawaited(app.notedPartsOfferAnswered(chose: true));
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (route) => GenresScreen(
          app: app,
          onBack: () => Navigator.of(route).pop(),
          onDone: (genresOff, strandsOff) async {
            await app.setGenresOff(genresOff, strandsOff);
            if (route.mounted) Navigator.of(route).pop();
          },
        ),
      ),
    );
  }

  Future<void> _notNow() async {
    setState(() => _answered = true);
    await widget.app.notedPartsOfferAnswered(chose: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool shown = !_answered && PartsOfferCard.due(widget.app);
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: shown
          ? Padding(padding: widget.padding, child: _card(context))
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _card(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    return Container(
      key: const ValueKey('parts-offer'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.genresTitle,
              style: AppText.body(
                size: 15.5,
                weight: FontWeight.w700,
                height: 1.25,
                spacing: -0.2,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.partsOfferLine,
              style: AppText.body(size: 13.5, height: 1.4, color: p.inkMuted),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Button(
                      key: const ValueKey('parts-offer-not-now'),
                      label: l.partsOfferNotNow,
                      strong: false,
                      onTap: _notNow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Button(
                      key: const ValueKey('parts-offer-choose'),
                      label: l.partsOfferChoose,
                      strong: true,
                      onTap: _choose,
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

/// One of the offer's two answers: the way in filled with the page's ink,
/// "Not now" in a hairline beside it, the same size.
class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.label,
    required this.strong,
    required this.onTap,
  });

  final String label;
  final bool strong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: strong ? p.inverse : p.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: strong ? p.inverse : p.ink.withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              height: 1.2,
              color: strong ? p.onInverse : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}
