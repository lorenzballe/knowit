import 'package:flutter/material.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../state/app_state.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/motion.dart';

/// What Astuto+ costs, in cents, so the saving can be worked out rather than
/// asserted. A hardcoded "save 48%" is a number that quietly stops being true
/// the first time a price moves.
const int kMonthlyCents = 399;
const int kYearlyCents = 2499;

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

// Volume is what every other daily-learning app is already selling, and
// several of them can afford to sell it harder. What this app has that they
// do not is a measurement of the reader, so that is what leads.
const _perks = [
  (
    icon: Icons.show_chart_rounded,
    title: 'Your record over time',
    sub:
        'Whether the gap between how sure you were and how right you were '
        'is actually closing.',
  ),
  (
    icon: Icons.grid_view_rounded,
    title: 'Every principle you have met',
    sub:
        'Not just the three you are worst at — all of them, and the '
        'contexts you have not been shown yet.',
  ),
  (
    icon: Icons.ac_unit_rounded,
    title: 'Three streak freezes, not one',
    sub:
        'Enough to cover a weekend away. A streak you can only lose is a '
        'streak that eventually goes.',
  ),
  (
    icon: Icons.add_circle_outline_rounded,
    title: '5 extra pills every day',
    sub: 'A second set unlocks the moment you finish the first.',
  ),
  (
    icon: Icons.search_rounded,
    title: 'The full archive',
    sub: 'Every pill you have ever read, searchable by topic.',
  ),
  (
    icon: Icons.tune_rounded,
    title: 'Pick your own topics',
    sub: 'Weight the mix toward what you actually like.',
  ),
];

/// Astuto+.
///
/// Prices come from the store when it answers, so what is shown is what the
/// reader's App Store will actually charge, in their currency. Where it has
/// not answered — no key in this build, or a product not yet approved — the
/// prices written into the app stand in, and the CTA says plainly that
/// nothing was charged rather than implying a purchase happened.
class PaywallScreen extends StatefulWidget {
  final AppState app;

  const PaywallScreen({super.key, required this.app});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late Plan _plan = widget.app.plan;

  Subscription get _store => Subscription.instance;

  /// What the store charges, or the price written into the app when it has
  /// not answered.
  String _priceFor(Plan plan) {
    final Package? package = plan == Plan.year ? _store.yearly : _store.monthly;
    if (package != null) return package.storeProduct.priceString;
    return _euros(plan == Plan.year ? kYearlyCents : kMonthlyCents);
  }

  String get _cta {
    if (widget.app.isPlus) return 'ASTUTO+ IS ACTIVE';
    final String suffix = _plan == Plan.year ? '/yr' : '/mo';
    return 'Try 7 days free, then ${_priceFor(_plan)}$suffix';
  }

  /// The package for the plan on screen, if the store has offered one.
  Package? get _package => _plan == Plan.year ? _store.yearly : _store.monthly;

  Future<void> _start() async {
    final Package? package = _package;

    // No store to buy from: unlock locally so the gated screens can be seen,
    // and say so rather than letting it look like a purchase.
    if (package == null) {
      await widget.app.startPlusTrial();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trial started. No payment is connected in this build.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final outcome = await _store.buy(package);
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.bought:
        await widget.app.applyEntitlement(true);
        if (mounted) Navigator.of(context).pop();
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That did not go through.')),
        );
    }
  }

  /// Apple requires a way back to something already paid for, and a reader on
  /// a new phone needs it before they will trust the first purchase.
  Future<void> _restore() async {
    final bool restored = await _store.restore();
    if (!mounted) return;
    if (restored) await widget.app.applyEntitlement(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? 'Astuto+ is back.' : 'Nothing to restore on this account.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: 'Close',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
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
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ASTUTO+',
                        style: AppText.label(
                          size: 11,
                          weight: FontWeight.w700,
                          spacing: 1.3,
                          color: AppColors.limeInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Find out if you are actually getting better.',
                    style: AppText.display(
                      size: 33,
                      weight: FontWeight.w700,
                      height: 1.06,
                      spacing: -1.4,
                      color: context.p.ink,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ..._perks.indexed.map(
                    (e) => RiseIn.staggered(
                      e.$1,
                      step: const Duration(milliseconds: 50),
                      child: _Perk(
                        icon: e.$2.icon,
                        title: e.$2.title,
                        sub: e.$2.sub,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _TrialSteps(),
                  const SizedBox(height: 22),
                  _PlanTile(
                    label: 'Yearly',
                    price: _euros(kYearlyCents),
                    per: 'per year',
                    note: '${_euros(kYearlyCents ~/ 12)} a month',
                    badge: 'SAVE $kYearlySavingPercent%',
                    selected: _plan == Plan.year,
                    onTap: () {
                      setState(() => _plan = Plan.year);
                      widget.app.setPlan(Plan.year);
                    },
                  ),
                  const SizedBox(height: 10),
                  _PlanTile(
                    label: 'Monthly',
                    price: _euros(kMonthlyCents),
                    per: 'per month',
                    note: 'billed monthly',
                    selected: _plan == Plan.month,
                    onTap: () {
                      setState(() => _plan = Plan.month);
                      widget.app.setPlan(Plan.month);
                    },
                  ),
                ],
              ),
            ),

            // The one button whose job is revenue does not scroll away.
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              decoration: BoxDecoration(
                color: context.p.surface,
                border: Border(top: BorderSide(color: context.p.line)),
              ),
              child: Column(
                children: [
                  ChunkyButton(
                    label: _cta,
                    height: 56,
                    fill: AppColors.lime,
                    ink: AppColors.limeInk,
                    onPressed: widget.app.isPlus ? null : _start,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.app.isPlus
                        ? () async {
                            await widget.app.endPlus();
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        : null,
                    child: Text(
                      widget.app.isPlus
                          ? 'Cancel the trial'
                          : _store.offering != null
                          ? 'Cancel any time'
                          : 'Cancel any time · No payment is taken in this '
                                'build',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        size: 11.5,
                        height: 1.4,
                        color: context.p.inkFaint,
                      ),
                    ),
                  ),
                  // Apple requires a way back to something already paid for,
                  // and it only means anything when there is a store.
                  if (_store.offering != null && !widget.app.isPlus)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _restore,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Restore purchases',
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: context.p.inkMuted,
                          ),
                        ),
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

class _Perk extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;

  const _Perk({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.limeDark),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(
                    size: 15,
                    weight: FontWeight.w700,
                    height: 1.25,
                    color: context.p.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: AppText.body(
                    size: 12.5,
                    height: 1.4,
                    color: context.p.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the seven days actually do.
///
/// The thing that stops people starting a trial is not the price, it is not
/// knowing when they will be charged. Saying it plainly costs nothing and is
/// the honest version of what every app that sells trials does here.
class _TrialSteps extends StatelessWidget {
  const _TrialSteps();

  static const _steps = [
    (day: 'TODAY', text: 'Everything opens. Nothing is charged.'),
    (day: 'DAY 5', text: 'A reminder, two days before it renews.'),
    (day: 'DAY 7', text: 'It renews, unless you cancelled. You can, any time.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: BoxDecoration(
        color: context.p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW THE FREE WEEK WORKS',
            style: AppText.label(
              size: 10,
              spacing: 1.3,
              color: context.p.inkFaint,
            ),
          ),
          const SizedBox(height: 12),
          ..._steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 54,
                    child: Text(
                      s.day,
                      style: AppText.label(
                        size: 10,
                        spacing: 0.8,
                        color: AppColors.limeDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.text,
                      style: AppText.body(
                        size: 13,
                        height: 1.35,
                        color: context.p.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    final edge = selected ? AppColors.limeDark : context.p.line;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price $per',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.lime.withValues(alpha: 0.13)
                : context.p.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: edge, width: selected ? 2 : 1.4),
          ),
          child: Row(
            children: [
              _Radio(on: selected),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 15.5,
                              weight: FontWeight.w700,
                              color: context.p.ink,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: AppText.label(
                                size: 9.5,
                                weight: FontWeight.w700,
                                spacing: 0.8,
                                color: AppColors.limeInk,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: AppText.body(
                        size: 12.5,
                        color: context.p.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: AppText.display(
                      size: 19,
                      weight: FontWeight.w700,
                      spacing: -0.5,
                      color: context.p.ink,
                    ),
                  ),
                  Text(
                    per,
                    style: AppText.body(size: 11, color: context.p.inkFaint),
                  ),
                ],
              ),
            ],
          ),
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
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.lime : Colors.transparent,
        border: Border.all(
          color: on ? AppColors.limeDark : context.p.lineStrong,
          width: 2,
        ),
      ),
      child: on
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.limeInk)
          : null,
    );
  }
}
