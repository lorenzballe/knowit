import 'package:flutter/material.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../state/app_state.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/fit_text.dart';
import '../data/topics.dart';
import '../widgets/motion.dart';

/// What Astute+ costs, in cents, so the saving can be worked out rather than
/// asserted. A hardcoded "save 37%" is a number that quietly stops being true
/// the first time a price moves.
///
/// €3,99 a month is the anchor; €29,99 a year is the plan, preselected, at
/// two and a half a month. No lifetime, no third tier.
const int kMonthlyCents = 399;
const int kYearlyCents = 2999;

String _euros(int cents) {
  final whole = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  return '€$whole,$rest';
}

/// Yearly against twelve months of monthly.
int get kYearlySavingPercent {
  final full = kMonthlyCents * 12;
  return (100 * (full - kYearlyCents) / full).round();
}

// Three things, and everything else is the same on both plans. The day made
// entirely of the reader's own cards; what they actually know, on the
// journey; the whole archive. Six perks read as a list of features; three
// read as a reason.
List<({IconData icon, String title, String sub})> _perks(
  AppLocalizations l,
) => [
  (icon: Icons.auto_awesome_rounded, title: l.perkOwnTitle, sub: l.perkOwnLine),
  (icon: Icons.psychology_rounded, title: l.perkKnowTitle, sub: l.perkKnowLine),
  (
    icon: Icons.inventory_2_rounded,
    title: l.perkArchiveTitle,
    sub: l.perkArchiveLine,
  ),
];

/// Astute+.
///
/// Prices come from the store when it answers, so what is shown is what the
/// reader's App Store will actually charge, in their currency. Where it has
/// not answered — no key in this build, or a product not yet approved — the
/// prices written into the app stand in, and the CTA says plainly that
/// nothing was charged rather than implying a purchase happened.
class PaywallScreen extends StatefulWidget {
  final AppState app;

  /// What the reader reached for to end up here. Required, and a plain word
  /// rather than a default, because "where did they come from" is the only
  /// question a paywall's numbers ever really answer — and a default would be
  /// a fifth of the traffic labelled `unknown` within a week.
  final String source;

  /// Where the screen goes when it is done — the way out, and where a trial
  /// lands. Set by the onboarding, where this is a stage rather than a
  /// route pushed over another screen and there is nothing to pop back to;
  /// absent, the screen pops itself.
  final VoidCallback? onClose;

  const PaywallScreen({
    super.key,
    required this.app,
    required this.source,
    this.onClose,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Plan _plan = widget.app.plan;

  Subscription get _store => Subscription.instance;

  @override
  void initState() {
    super.initState();
    Analytics.screen('paywall');
    Analytics.capture('paywall shown', {
      'source': widget.source,
      'plan_shown': _plan.name,
      // Whether the prices on screen are the store's or the ones written
      // into the app. A conversion rate measured against a made-up price is
      // not a conversion rate.
      'store_answered': _store.ready && _store.offering != null,
    });
  }

  /// What the store charges, or the price written into the app when it has
  /// not answered.
  String _priceFor(Plan plan) {
    final Package? package = plan == Plan.year ? _store.yearly : _store.monthly;
    if (package != null) return package.storeProduct.priceString;
    return _euros(plan == Plan.year ? kYearlyCents : kMonthlyCents);
  }

  String get _cta {
    if (widget.app.isPlus) return context.l10n.plusIsActive;
    final String suffix = _plan == Plan.year
        ? context.l10n.perYearShort
        : context.l10n.perMonthShort;
    return context.l10n.tryFreeThen(_priceFor(_plan), suffix);
  }

  /// The package for the plan on screen, if the store has offered one.
  Package? get _package => _plan == Plan.year ? _store.yearly : _store.monthly;

  /// The way out, whichever way this screen was reached.
  void _leave() {
    final VoidCallback? onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _start() async {
    final Package? package = _package;
    Analytics.capture('purchase started', {
      'source': widget.source,
      'plan': _plan.name,
      'has_package': package != null,
    });

    // No store to buy from: unlock locally so the gated screens can be seen,
    // and say so rather than letting it look like a purchase.
    if (package == null) {
      await widget.app.startPlusTrial();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.trialStartedNoPayment)),
      );
      _leave();
      return;
    }

    final outcome = await _store.buy(package);
    Analytics.capture('purchase ended', {
      'source': widget.source,
      'plan': _plan.name,
      'outcome': outcome.name,
      'product': package.storeProduct.identifier,
    });
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.bought:
        await widget.app.applyEntitlement(true);
        if (mounted) _leave();
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.thatDidNotGoThrough)),
        );
    }
  }

  /// Apple requires a way back to something already paid for, and a reader on
  /// a new phone needs it before they will trust the first purchase.
  Future<void> _restore() async {
    final bool restored = await _store.restore();
    Analytics.capture('purchases restored', {'found': restored});
    if (!mounted) return;
    if (restored) await widget.app.applyEntitlement(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? context.l10n.plusIsBack : context.l10n.nothingToRestore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bool store = _store.offering != null;
    return Scaffold(
      backgroundColor: context.p.surface,
      // One screen, no scrolling. What is for sale is read at a glance or
      // it is not read: the three perks sit in whatever height the plans
      // and the button leave them, and a phone too short for their lines
      // shows their titles alone rather than a scrollbar.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The badge and the way out share a row.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.p.inverse,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.plusNameCaps,
                      style: AppText.label(
                        size: 11,
                        weight: FontWeight.w700,
                        spacing: 1.3,
                        color: context.p.onInverse,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _leave,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: context.p.inkFaint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FitText(
                l.everyCardForYou,
                maxLines: 2,
                minSize: 24,
                style: AppText.display(
                  size: 30,
                  weight: FontWeight.w700,
                  height: 1.06,
                  spacing: -1.2,
                  color: context.p.ink,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, room) {
                    final perks = _perks(l);
                    final bool full =
                        room.maxHeight >=
                        perks.length * _Perk.fullHeight +
                            (perks.length - 1) * _Perk.gap;
                    // Spread through the room rather than huddled in the
                    // middle of it: three things, each with air around it,
                    // is what three things looks like.
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (int i, perk) in perks.indexed) ...[
                          if (i > 0 && !full)
                            const SizedBox(height: _Perk.leastGap),
                          RiseIn.staggered(
                            i,
                            step: const Duration(milliseconds: 50),
                            child: _Perk(
                              icon: perk.icon,
                              title: perk.title,
                              sub: perk.sub,
                              // Three points, three hues off the wheel —
                              // the same wheel the reader's own record is
                              // drawn in. A column of identical grey chips
                              // says nothing about what the app is.
                              colour: kSpectrum[(i * 4) % kSpectrum.length],
                              compact: !full,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Side by side: two tiles stacked were the height of two
              // perks. They come out the same height on their own, being
              // three lines each, every line fitted to the tile's width.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PlanTile(
                      label: l.planYearly,
                      price: _priceFor(Plan.year),
                      per: l.perYearShort,
                      note: l.aMonth(_euros(kYearlyCents ~/ 12)),
                      badge: l.savePercent(kYearlySavingPercent),
                      selected: _plan == Plan.year,
                      onTap: () {
                        setState(() => _plan = Plan.year);
                        widget.app.setPlan(Plan.year);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlanTile(
                      label: l.planMonthly,
                      price: _priceFor(Plan.month),
                      per: l.perMonthShort,
                      note: l.billedMonthly,
                      selected: _plan == Plan.month,
                      onTap: () {
                        setState(() => _plan = Plan.month);
                        widget.app.setPlan(Plan.month);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ChunkyButton(
                label: _cta,
                height: 56,
                fill: context.p.inverse,
                ink: context.p.onInverse,
                onPressed: widget.app.isPlus ? null : _start,
              ),
              const SizedBox(height: 8),
              if (widget.app.isPlus)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await widget.app.endPlus();
                    if (context.mounted) _leave();
                  },
                  child: Text(
                    l.cancelTheTrial,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 11.5,
                      height: 1.4,
                      color: context.p.inkFaint,
                    ),
                  ),
                )
              else ...[
                // What the seven days actually do, in a line. The thing
                // that stops people starting a trial is not the price, it
                // is not knowing when they will be charged. Where there is
                // no store, say instead that nothing is taken at all.
                Text(
                  store ? l.trialTerms : l.cancelAnyTimeNoPayment,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 11.5,
                    height: 1.4,
                    color: context.p.inkFaint,
                  ),
                ),
                // Apple requires a way back to something already paid for,
                // and it only means anything when there is a store.
                if (store)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _restore,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        l.restorePurchases,
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: context.p.inkMuted,
                        ),
                      ),
                    ),
                  ),
                // In the onboarding the way out is written down, under the
                // offer, in small — a soft paywall says so rather than
                // leaving the reader to find the cross.
                if (widget.onClose != null)
                  Semantics(
                    button: true,
                    label: l.continueFree,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _leave,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l.continueFree,
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: context.p.inkMuted,
                          ),
                        ),
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

class _Perk extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color colour;

  /// The title alone, for a phone too short for three perks with their lines.
  final bool compact;

  const _Perk({
    required this.icon,
    required this.title,
    required this.sub,
    required this.colour,
    this.compact = false,
  });

  /// A title and three lines under it, which is what the longest line takes
  /// at the smallest size the text is allowed to shrink to.
  static const double fullHeight = 84;
  static const double gap = 22;
  static const double leastGap = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 23, color: colour),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FitText(
                title,
                maxLines: 1,
                minSize: 13,
                style: AppText.body(
                  size: 17,
                  weight: FontWeight.w700,
                  height: 1.25,
                  color: context.p.ink,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 5),
                FitText(
                  sub,
                  maxLines: 3,
                  minSize: 11.5,
                  style: AppText.body(
                    size: 14,
                    height: 1.4,
                    color: context.p.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String label;
  final String price;
  final String per;
  final String note;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.label,
    required this.price,
    required this.per,
    required this.note,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final edge = selected ? context.p.inverse : context.p.line;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price $per',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: selected
                    ? context.p.inverse.withValues(alpha: 0.13)
                    : context.p.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: edge, width: selected ? 2 : 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _Radio(on: selected),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FitText(
                          label,
                          maxLines: 1,
                          minSize: 12,
                          style: AppText.body(
                            size: 14.5,
                            weight: FontWeight.w700,
                            color: context.p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FitText(
                          price,
                          maxLines: 1,
                          minSize: 14,
                          style: AppText.display(
                            size: 19,
                            weight: FontWeight.w700,
                            spacing: -0.5,
                            color: context.p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        per,
                        style: AppText.body(
                          size: 11,
                          color: context.p.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FitText(
                    note,
                    maxLines: 1,
                    minSize: 10,
                    style: AppText.body(size: 11.5, color: context.p.inkMuted),
                  ),
                ],
              ),
            ),
            // The saving rides the tile's top edge rather than taking a
            // row inside it, so the two tiles stay the same height.
            if (badge != null)
              Positioned(
                top: -9,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.p.inverse,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: AppText.label(
                      size: 9.5,
                      weight: FontWeight.w700,
                      spacing: 0.8,
                      color: context.p.onInverse,
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

class _Radio extends StatelessWidget {
  final bool on;
  const _Radio({required this.on});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? context.p.inverse : Colors.transparent,
        border: Border.all(
          color: on ? context.p.inverse : context.p.lineStrong,
          width: 2,
        ),
      ),
      child: on
          ? Icon(Icons.check_rounded, size: 13, color: context.p.onInverse)
          : null,
    );
  }
}
