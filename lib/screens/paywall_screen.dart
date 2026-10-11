import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../legal.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../state/app_state.dart';
import '../state/progress.dart' show kCalibrationFloor;
import '../sync/review_access.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/fit_text.dart';
import '../data/topics.dart';
import '../widgets/ambient.dart';
import '../widgets/motion.dart';
import 'purchase_success_screen.dart';

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

// Three things, the record first: the free profile says how far off the
// reader is today, and only the journey says whether that is closing, so it
// is the one thing the free plan cannot show at all. Then the day made of
// the reader's own cards, then the days to open again. Six perks read as a
// list of features; three read as a reason.
List<({IconData icon, String title, String sub})> _perks(AppLocalizations l) =>
    [
      (icon: Icons.insights_rounded, title: l.perkGapTitle, sub: l.perkGapLine),
      (
        icon: Icons.auto_awesome_rounded,
        title: l.perkOwnFiveTitle,
        sub: l.perkOwnFiveLine,
      ),
      (
        icon: Icons.inventory_2_rounded,
        title: l.perkReadTitle,
        sub: l.perkReadLine,
      ),
    ];

/// What the paywall opens on, by the door it was opened from.
///
/// A reader who reached for the journey wanted to know how they are doing,
/// one who reached for the card after the fifth wanted the rest of the day,
/// one who reached for the archive wanted something they read: the first
/// thing each reads should be that, not one headline for everybody about
/// what the free plan already mostly gives.
enum PaywallVariant {
  /// How sure against how right, and whether the gap closes: the journey.
  record('A'),

  /// What the day Astute+ deals adds up to: every door not named here.
  outcome('B'),

  /// All five of the day, against the free day's two: the card after the
  /// fifth.
  five('C'),

  /// The days read, to open again: the archive.
  read('D');

  const PaywallVariant(this.letter);

  /// How the paywall's numbers name it.
  final String letter;

  /// The variant [source] opens on. `calibration` is the record's own door
  /// in the paywall's numbers (see the README) and opens on the record,
  /// though no screen passes it today.
  static PaywallVariant of(String source) => switch (source) {
    'journey' || 'calibration' => record,
    'sixth card' => five,
    'archive' => read,
    _ => outcome,
  };
}

/// The reader's own numbers, once there are enough answers to say them
/// from (the floor the profile and the journey keep): how sure they say
/// they are on average and how often they are right, in whole percent, and
/// the signed gap between the two, positive when more sure than right.
({int sure, int right, double gap})? _readerNumbers(AppState app) {
  final double? gap = app.overconfidence;
  final said = app.sureAgainstRight;
  if (app.judgements.length < kCalibrationFloor ||
      gap == null ||
      said == null) {
    return null;
  }
  return (sure: said.sure.round(), right: said.right.round(), gap: gap);
}

/// What a door opens on: the headline, the words in it painted in the
/// lights, and the line under it.
({String title, String mark, String line}) _opening(
  AppLocalizations l,
  PaywallVariant variant,
  AppState app,
) => switch (variant) {
  PaywallVariant.record => (
    title: l.paywallRecordTitle,
    mark: l.paywallRecordMark,
    line: switch (_readerNumbers(app)) {
      // Said the way the profile says it: within five points either way is
      // a match, and only past that is the reader over or under.
      (:final int sure, :final int right, :final double gap)
          when gap.abs().round() <= 5 =>
        l.paywallRecordEven(sure, right),
      (:final int sure, :final int right, :final double gap) when gap > 0 =>
        l.paywallRecordOver(sure, right),
      (:final int sure, :final int right, gap: _) => l.paywallRecordUnder(
        sure,
        right,
      ),
      null => l.paywallRecordLine,
    },
  ),
  PaywallVariant.outcome => (
    title: l.paywallOutcomeTitle,
    mark: l.paywallOutcomeMark,
    line: l.paywallOutcomeLine,
  ),
  PaywallVariant.five => (
    title: l.paywallFiveTitle,
    mark: l.paywallFiveMark,
    line: l.paywallFiveLine,
  ),
  PaywallVariant.read => (
    title: l.paywallReadTitle,
    mark: l.paywallReadMark,
    line: l.paywallReadLine,
  ),
};

/// What the year comes to a month, in the store's own currency once it has
/// answered: an American reader saw "\$29.99" on the tile and "€2,49 a month"
/// under it. The store's figure first, then a twelfth of its price, then the
/// price written into the app.
String yearPerMonth() {
  final StoreProduct? year = Subscription.instance.yearly?.storeProduct;
  if (year == null) return _euros(kYearlyCents ~/ 12);
  final String? perMonth = year.pricePerMonthString;
  if (perMonth != null && perMonth.isNotEmpty) return perMonth;
  try {
    return NumberFormat.simpleCurrency(name: year.currencyCode)
        .format(year.price / 12);
  } catch (_) {
    return _euros(kYearlyCents ~/ 12);
  }
}

/// The year against twelve months of the month, from the store's two prices
/// when it has both — the same currency, so the share is true wherever the
/// reader is — and from the prices written into the app before. Null when
/// the year saves nothing, so no badge claims it does.
int? yearlySaving() {
  final Subscription store = Subscription.instance;
  final double? year = store.yearly?.storeProduct.price;
  final double? month = store.monthly?.storeProduct.price;
  final int saving = year != null && month != null && month > 0
      ? (100 * (month * 12 - year) / (month * 12)).round()
      : kYearlySavingPercent;
  return saving > 0 ? saving : null;
}

/// What the store charges for [plan], or the price written into the app
/// when it has not answered.
String planPrice(Plan plan) {
  final Subscription store = Subscription.instance;
  final Package? package = plan == Plan.year ? store.yearly : store.monthly;
  if (package != null) return package.storeProduct.priceString;
  return _euros(plan == Plan.year ? kYearlyCents : kMonthlyCents);
}

/// How many days free [plan] starts with for this reader, or null when it
/// is charged today. The store's word when it has answered — its
/// introductory offer at no charge, for a reader it will still give it to
/// — and otherwise the plans as sold: the year starts with [kTrialDays],
/// the month is charged today. The button and the line under it never
/// promise a day the store will not give.
int? planFreeDays(Plan plan) {
  final Subscription store = Subscription.instance;
  if (plan == Plan.year) return store.trialDays;
  final Package? package = store.monthly;
  return package == null ? null : freeDaysOf(package);
}

/// The screen a purchase ends on (design 129a): what was bought, what it
/// does next, and one button to begin. Returns when the reader starts.
///
/// Shown by the paywall after a purchase the store confirmed, and — to see
/// it without paying — by the debug tools and the site's `?simulate=purchase`.
Future<void> showPurchaseSuccess(
  BuildContext context,
  AppState app, {
  required String source,
  Plan? plan,
}) async {
  final l = context.l10n;
  final Plan bought = plan ?? app.plan;
  final String price = planPrice(bought);
  final String suffix = bought == Plan.year ? l.perYearShort : l.perMonthShort;
  final int? days = planFreeDays(bought);
  final DateTime now = DateTime.now();
  final DateTime renew = bought == Plan.year
      ? DateTime(now.year + 1, now.month, now.day)
      : DateTime(now.year, now.month + 1, now.day);
  final String locale = Localizations.localeOf(context).toString();
  String day(DateTime d) => DateFormat.MMMd(locale).format(d);
  final String? end = days == null ? null : day(now.add(Duration(days: days)));
  final String name = app.name.trim();
  final String? first = name.isEmpty || name == 'You'
      ? null
      : name.split(RegExp(r'\s+')).first;
  final bool iOS = Theme.of(context).platform == TargetPlatform.iOS;
  Analytics.capture('purchase success shown', {
    'source': source,
    'plan': bought.name,
    'trial': days != null,
  });
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, _, _) => PurchaseSuccessScreen(
        firstName: first,
        planName: l.successPlanName(
          bought == Plan.year ? l.planYearly : l.planMonthly,
        ),
        planLine: end != null
            ? l.successFreeUntil(end, price, suffix)
            : l.successRenewsLine(day(renew), price, suffix),
        foot: end != null
            ? l.successFootFirstCharge(end)
            : l.successFootRenews(day(renew)),
        onReceipt: () => openLink(
          iOS
              ? 'https://apps.apple.com/account/subscriptions'
              : 'https://play.google.com/store/account/subscriptions',
        ),
      ),
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

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

  /// How long the offer was on screen, how it was left, and how often the
  /// reader went between the plans — the three things a paywall's own
  /// numbers are made of.
  final Stopwatch _open = Stopwatch()..start();
  String _leftBy = 'back';
  int _planChanges = 0;

  Subscription get _store => Subscription.instance;

  /// What this door opens on.
  PaywallVariant get _variant => PaywallVariant.of(widget.source);

  @override
  void initState() {
    super.initState();
    Analytics.screen('paywall');
    Analytics.capture('paywall shown', {
      'source': widget.source,
      // Which opening the door gave, and whether the reader has numbers of
      // their own to be told: on the record's door they are the line under
      // the headline; on any other, they count who could have been told.
      'variant': _variant.letter,
      'has_number': _readerNumbers(widget.app) != null,
      'plan_shown': _plan.name,
      // Whether the prices on screen are the store's or the ones written
      // into the app. A conversion rate measured against a made-up price is
      // not a conversion rate.
      'store_answered': _store.ready && _store.offering != null,
    });
  }

  String _priceFor(Plan plan) => planPrice(plan);

  int? _freeDays(Plan plan) => planFreeDays(plan);

  String get _cta {
    if (widget.app.isPlus) return context.l10n.plusIsActive;
    final String suffix = _plan == Plan.year
        ? context.l10n.perYearShort
        : context.l10n.perMonthShort;
    final String price = _priceFor(_plan);
    final int? days = _freeDays(_plan);
    return days != null
        ? context.l10n.tryFreeThen(days, price, suffix)
        : context.l10n.subscribeFor(price, suffix);
  }

  /// The line under the button when the plan on screen has no free days:
  /// what happens today. With no store behind this build nothing is ever
  /// charged, and a month "charged today" would be a lie, so that case says
  /// so instead. A plan with free days has the trial's steps there instead,
  /// which say "nothing today" and "cancel" with the days on them.
  String get _terms {
    final l = context.l10n;
    return _package != null ? l.chargedTodayCancel : l.cancelAnyTimeNoPayment;
  }

  /// The free trial as it will go, when the plan on screen starts with one
  /// this reader can have: today, the reminder, and the day it is charged,
  /// at the store's own price. Null when there is no trial to show.
  List<String>? get _trialSteps {
    final int? days = _freeDays(_plan);
    if (days == null || widget.app.isPlus) return null;
    final l = context.l10n;
    return [
      l.trialToday,
      // The app reminds the reader two days before a trial ends. A trial
      // too short to have that day has no step for it.
      if (days >= 3) l.trialReminder(days - 2),
      l.trialCharge(days, _priceFor(_plan), _plan.name),
    ];
  }

  /// The package for the plan on screen, if the store has offered one.
  Package? get _package => _plan == Plan.year ? _store.yearly : _store.monthly;

  @override
  void dispose() {
    Analytics.capture('paywall closed', {
      'source': widget.source,
      'left_by': _leftBy,
      'ms_open': _open.elapsedMilliseconds,
      'plan': _plan.name,
      'plan_changes': _planChanges,
      'is_plus': widget.app.isPlus,
    });
    super.dispose();
  }

  void _pick(Plan plan) {
    if (plan == _plan) return;
    _planChanges += 1;
    Analytics.capture('paywall plan selected', {
      'source': widget.source,
      'plan': plan.name,
      'from': _plan.name,
      'ms_open': _open.elapsedMilliseconds,
    });
    setState(() => _plan = plan);
    widget.app.setPlan(plan);
  }

  void _leaveBy(String how) {
    _leftBy = how;
    _leave();
  }

  void _openLink(String which, String url) {
    Analytics.capture('paywall link opened', {
      'source': widget.source,
      'link': which,
    });
    openLink(url);
  }

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

    // No store to buy from. While developing, unlock locally so the gated
    // screens can be seen, and say so rather than let it look like a
    // purchase. Anywhere else — a store build whose store did not answer, or
    // the web app, which has none — buying nothing must not open Astute+.
    if (package == null && !kDebugMode) {
      Analytics.capture('purchase unavailable', {'source': widget.source});
      // The web app has no store: Astute+ is bought in the app, and never
      // opened here for nothing.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? context.l10n.plusInTheApp
                : context.l10n.thatDidNotGoThrough,
          ),
        ),
      );
      return;
    }
    if (package == null) {
      await widget.app.startPlusTrial();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.trialStartedNoPayment)),
      );
      _leaveBy('unlocked without a store');
      return;
    }

    final outcome = await _store.buy(package);
    Analytics.capture('purchase ended', {
      'source': widget.source,
      'plan': _plan.name,
      'outcome': outcome.name,
      'product': package.storeProduct.identifier,
      'price': package.storeProduct.price,
      'currency': package.storeProduct.currencyCode,
      'trial': package.storeProduct.introductoryPrice?.price == 0,
      'ms_open': _open.elapsedMilliseconds,
      'plan_changes': _planChanges,
    });
    if (!mounted) return;
    switch (outcome) {
      case PurchaseOutcome.bought:
        await widget.app.applyEntitlement(true);
        if (!mounted) return;
        await _celebrate();
        if (mounted) _leaveBy('bought');
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.thatDidNotGoThrough)),
        );
    }
  }

  /// The screen a purchase ends on (design 129a). Returns when the reader
  /// starts.
  Future<void> _celebrate() => showPurchaseSuccess(
    context,
    widget.app,
    source: widget.source,
    plan: _plan,
  );

  /// Google Play's reviewers cannot pay, so they type the code Play Console
  /// gave them. In English, as Google asks, and shown to nobody else: the
  /// badge only listens for a long press on Android.
  Future<void> _askReviewCode() async {
    final String? code = await showDialog<String>(
      context: context,
      builder: (context) => const _ReviewCodeDialog(),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    final bool open = await _store.redeemReviewCode(code);
    if (!mounted) return;
    if (!open) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('That code is not right.')));
      return;
    }
    await widget.app.applyEntitlement(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Astute+ is on for this device.')),
    );
    _leaveBy('review access');
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
    final p = context.p;
    final bool dark = p.isDark;
    final bool store = _store.offering != null;
    final double homeBar = MediaQuery.viewPaddingOf(context).bottom;
    final opening = _opening(l, _variant, widget.app);
    final List<String>? trial = _trialSteps;
    // A short phone — an SE, or a test's 800 by 600 — sets the headline and
    // the air around it a size smaller, so the perks keep room for all three
    // under the line the door adds and the trial's days over the links.
    final bool short =
        MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).vertical <
        700;
    return Scaffold(
      backgroundColor: p.surface,
      // One screen, no scrolling. What is for sale is read at a glance or
      // it is not read: the three perks sit in whatever height the opening,
      // the plans and the button leave them, and a phone too short for
      // their lines shows their titles alone rather than a scrollbar.
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Three soft lights behind the top of the screen, drifting.
          const Positioned(
            left: -80,
            top: -60,
            width: 560,
            height: 380,
            child: _Lights(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 6, 22, homeBar > 0 ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The badge and the way out share a row.
                  Row(
                    children: [
                      GestureDetector(
                        // Google Play's reviewers get in here with the code
                        // Play Console gives them; see review_access.dart.
                        onLongPress: reviewCodeOffered ? _askReviewCode : null,
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.inverse,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: dark ? 0.4 : 0.12,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            l.plusNameCaps,
                            style: AppText.label(
                              size: 12,
                              weight: FontWeight.w700,
                              spacing: 2.4,
                              height: 1,
                              color: p.onInverse,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: 'Close',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _leaveBy('close'),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.ink.withValues(alpha: 0.06),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: p.ink.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: short ? 14 : 22),
                  _Headline(
                    key: const ValueKey('paywall-headline'),
                    text: opening.title,
                    mark: opening.mark,
                    size: short ? 34 : 40,
                  ),
                  // What the door was reached for, in a line: the record,
                  // the whole day, the days, or what the habit adds up to.
                  Padding(
                    padding: EdgeInsets.only(top: short ? 8 : 10),
                    child: FitText(
                      opening.line,
                      key: const ValueKey('paywall-line'),
                      maxLines: 3,
                      minSize: 12.5,
                      style: AppText.body(
                        size: short ? 14 : 15,
                        height: 1.38,
                        color: p.ink.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, room) {
                        final perks = _perks(l);
                        // Never right up against the line above or the
                        // plans below, however short the phone.
                        final double air = math.min(
                          _Perk.leastAir,
                          room.maxHeight / 2,
                        );
                        final double height = room.maxHeight - 2 * air;
                        final _PerkSize size = _PerkSize.values.firstWhere(
                          (s) => height >= _Perk.needs(s, perks.length),
                          orElse: () => _PerkSize.tight,
                        );
                        // A phone too short even for three small titles
                        // keeps as many as there is room for, in order,
                        // rather than overflow: the record first.
                        final int shown =
                            height >= _Perk.needs(size, perks.length)
                            ? perks.length
                            : math.min(
                                perks.length,
                                (height + _Perk.gapAt(size)) ~/
                                    (_Perk.heightAt(size) + _Perk.gapAt(size)),
                              );
                        // Spread through the room rather than huddled in
                        // the middle of it: three things, each with air
                        // around it, is what three things looks like.
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: air),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (int i, perk)
                                  in perks.take(shown).indexed) ...[
                                if (i > 0 && size != _PerkSize.full)
                                  SizedBox(height: _Perk.gapAt(size)),
                                RiseIn.staggered(
                                  i,
                                  step: const Duration(milliseconds: 50),
                                  child: _Perk(
                                    icon: perk.icon,
                                    title: perk.title,
                                    sub: perk.sub,
                                    // Three points, three hues off the
                                    // wheel — the same wheel the reader's
                                    // own record is drawn in.
                                    colour:
                                        kSpectrum[(i * 4) % kSpectrum.length],
                                    size: size,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Side by side, the same height on their own: three lines
                  // each, every line fitted to the tile's width.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PlanTile(
                          label: l.planYearly,
                          price: _priceFor(Plan.year),
                          per: l.perYearShort,
                          note: l.aMonth(yearPerMonth()),
                          badge: switch (yearlySaving()) {
                            final int saving => l.savePercent(saving),
                            null => null,
                          },
                          selected: _plan == Plan.year,
                          onTap: () => _pick(Plan.year),
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
                          onTap: () => _pick(Plan.month),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: short ? 14 : 18),
                  // Sixty high on a five-point edge: the face and its edge
                  // together are sixty-five.
                  ChunkyButton(
                    label: _cta,
                    height: 65,
                    depth: 5,
                    radius: 22,
                    labelSize: 16.5,
                    labelSpacing: 0.3,
                    fill: p.inverse,
                    ink: p.onInverse,
                    edge: dark ? const Color(0xFFA8A59D) : null,
                    shadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.45 : 0.15,
                        ),
                        blurRadius: 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                    onPressed: widget.app.isPlus ? null : _start,
                  ),
                  // A reader already on Astute+ is sent to the store's own
                  // place for their plan. This used to say "Cancel the
                  // trial" and turn a flag off on the phone, while the store
                  // went on and charged them.
                  if (widget.app.isPlus)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Analytics.capture('manage subscription opened', {
                          'is_plus': true,
                          'from': 'paywall',
                        });
                        Subscription.instance.presentCustomerCenter();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l.manageSubscription,
                          textAlign: TextAlign.center,
                          style: _smallPrint(context),
                        ),
                      ),
                    )
                  else ...[
                    // What today costs, and when that changes. The thing
                    // that stops people starting is not the price, it is
                    // not knowing when they will be charged: with a trial,
                    // its days; without one, a line.
                    if (trial != null)
                      Padding(
                        padding: EdgeInsets.only(top: short ? 10 : 12),
                        child: _TrialTimeline(
                          key: const ValueKey('paywall-trial'),
                          steps: trial,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _terms,
                          textAlign: TextAlign.center,
                          style: _smallPrint(context),
                        ),
                      ),
                    // What Apple requires beside a subscription, on one
                    // line so the screen still does not scroll: a way back
                    // to something already paid for, which only means
                    // anything when there is a store, and the terms and the
                    // privacy policy.
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (store) ...[
                              _SmallLink(
                                l.restorePurchases,
                                onTap: _restore,
                                link: false,
                              ),
                              _SmallLink.dot(context),
                            ],
                            _SmallLink(
                              l.termsOfUse,
                              onTap: () => _openLink('terms', kTermsUrl),
                            ),
                            _SmallLink.dot(context),
                            _SmallLink(
                              l.privacyPolicy,
                              onTap: () => _openLink('privacy', kPrivacyUrl),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // In the onboarding the way out is written down, under
                    // the offer — a soft paywall says so rather than leaving
                    // the reader to find the cross.
                    if (widget.onClose != null)
                      Semantics(
                        button: true,
                        label: l.continueFree,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _leaveBy('continue free'),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              l.continueFree,
                              textAlign: TextAlign.center,
                              style: AppText.body(
                                size: 15,
                                weight: FontWeight.w600,
                                height: 1,
                                color: p.ink.withValues(alpha: 0.62),
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
        ],
      ),
    );
  }

  TextStyle _smallPrint(BuildContext context) => _smallPrintStyle(context);
}

TextStyle _smallPrintStyle(BuildContext context) => AppText.body(
  size: 12.5,
  weight: FontWeight.w500,
  height: 1.4,
  color: context.p.ink.withValues(alpha: 0.45),
);

/// A piece of the last line of small print that does something when
/// Asks a reviewer for their code. Its own widget so the field's controller
/// lives exactly as long as the dialog does.
class _ReviewCodeDialog extends StatefulWidget {
  const _ReviewCodeDialog();

  @override
  State<_ReviewCodeDialog> createState() => _ReviewCodeDialogState();
}

class _ReviewCodeDialogState extends State<_ReviewCodeDialog> {
  final TextEditingController _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _unlock() => Navigator.of(context).pop(_field.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Review access'),
    content: TextField(
      controller: _field,
      autofocus: true,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(hintText: 'Code from Play Console'),
      onSubmitted: (_) => _unlock(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _unlock, child: const Text('Unlock')),
    ],
  );
}

/// tapped — restore, the terms, the privacy policy — and the dot between two
/// of them.
class _SmallLink extends StatelessWidget {
  const _SmallLink(this.label, {required this.onTap, this.link = true});

  final String label;
  final VoidCallback onTap;

  /// A page that opens, rather than an action the app takes.
  final bool link;

  static Widget dot(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: ExcludeSemantics(child: Text('·', style: _smallPrintStyle(context))),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    link: link,
    button: !link,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(label, style: _smallPrintStyle(context)),
    ),
  );
}

/// The free trial under the button, as the days it will go by: today, the
/// day the reader is reminded, and the day the plan is charged.
///
/// Small print, in the small print's size, because these are the terms; a
/// dot for each step on a hairline, the first one filled because it is the
/// one the reader is on. Centred as a block under the button, its steps
/// aligned on their dots, and as wide as its longest step.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({super.key, required this.steps});

  final List<String> steps;

  /// Above and below each step's words, inside the step, so the rail runs
  /// unbroken from one dot to the next.
  static const double _pad = 2;

  @override
  Widget build(BuildContext context) {
    final Color ink = context.p.ink;
    final TextStyle style = _smallPrintStyle(context);
    // The dot sits on the middle of a step's first line, wherever the
    // phone's text size puts that line.
    final double line =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    return Center(
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (int i, String step) in steps.indexed)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 9,
                      child: CustomPaint(
                        painter: _RailPainter(
                          dotAt: _pad + line / 2,
                          first: i == 0,
                          last: i == steps.length - 1,
                          ink: ink,
                          ground: context.p.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: _pad),
                        child: Text(
                          step,
                          style: i == 0
                              ? style.copyWith(
                                  color: ink.withValues(alpha: 0.62),
                                )
                              : style,
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

/// One step's piece of the trial's rail: the hairline through it, and its
/// dot — filled for today, an open ring for the days to come.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.dotAt,
    required this.first,
    required this.last,
    required this.ink,
    required this.ground,
  });

  /// How far down the step its dot sits.
  final double dotAt;
  final bool first;
  final bool last;
  final Color ink;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final double x = size.width / 2;
    final Offset dot = Offset(x, dotAt);
    final Paint rail = Paint()
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: 0.16);
    if (!first) canvas.drawLine(Offset(x, 0), dot, rail);
    if (!last) canvas.drawLine(dot, Offset(x, size.height), rail);
    if (first) {
      canvas.drawCircle(dot, 3.5, Paint()..color = ink.withValues(alpha: 0.62));
      return;
    }
    canvas
      ..drawCircle(dot, 3.5, Paint()..color = ground)
      ..drawCircle(
        dot,
        3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = ink.withValues(alpha: 0.38),
      );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.dotAt != dotAt ||
      old.first != first ||
      old.last != last ||
      old.ink != ink ||
      old.ground != ground;
}

/// The three lights behind the top of the paywall: yellow, teal and violet,
/// blurred into one another and drifting fourteen points right and ten up
/// and back, seven seconds each way. Still when the phone asks for no
/// motion.
class _Lights extends StatelessWidget {
  const _Lights();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AmbientLoop(
        period: const Duration(seconds: 7),
        builder: (context, t) {
          final double e = Curves.easeInOut.transform(t);
          return Transform.translate(
            offset: Offset(14 * e, -10 * e),
            // Blurred once and moved whole: the drift never repaints it.
            child: const RepaintBoundary(child: _LightField()),
          );
        },
      ),
    );
  }
}

class _LightField extends StatelessWidget {
  const _LightField();

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(
        sigmaX: 38,
        sigmaY: 38,
        tileMode: TileMode.decal,
      ),
      child: const Stack(
        children: [
          _Light(
            left: 40,
            top: 80,
            width: 220,
            height: 180,
            colour: Color(0x29FFE14D),
          ),
          _Light(
            left: 220,
            top: 40,
            width: 240,
            height: 200,
            colour: Color(0x212DE0D2),
          ),
          _Light(
            left: 330,
            top: 150,
            width: 220,
            height: 180,
            colour: Color(0x298B6CFF),
          ),
        ],
      ),
    );
  }
}

class _Light extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final Color colour;

  const _Light({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

/// The headline, as large as two lines allow, with the word it leans on —
/// "really", "yours." — painted in the three colours of the lights.
///
/// Drawn twice, one over the other: the whole line with that word's place
/// kept but left clear, and over it the word alone through the gradient.
/// The gradient is measured on the word itself, so it runs across "yours."
/// and not across the line, whatever the language puts around it.
class _Headline extends StatelessWidget {
  final String text;

  /// The part painted in the gradient; nothing is when it is not found.
  final String mark;

  /// The size it is set at when two lines hold it.
  final double size;

  const _Headline({
    super.key,
    required this.text,
    required this.mark,
    this.size = _size,
  });

  static const double _size = 40;
  static const double _least = 28;

  static const List<Color> _darkStops = [
    Color(0xFFFFE14D),
    Color(0xFF2DE0D2),
    Color(0xFF8B6CFF),
  ];

  // On paper the same three, deepened enough to read.
  static const List<Color> _lightStops = [
    Color(0xFFD9A300),
    Color(0xFF00A99C),
    Color(0xFF6E3AFF),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final double width = box.maxWidth;
        final DefaultTextStyle inherited = DefaultTextStyle.of(context);
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final TextDirection direction = Directionality.of(context);
        final TextHeightBehavior? heights =
            inherited.textHeightBehavior ??
            DefaultTextHeightBehavior.maybeOf(context);
        TextStyle styleAt(double size) => inherited.style.merge(
          AppText.display(
            size: size,
            weight: FontWeight.w600,
            height: 1.04,
            spacing: -1.4 * size / _size,
            color: context.p.ink,
          ),
        );
        TextPainter laidOut(double size, {int? lines}) => TextPainter(
          text: TextSpan(text: text, style: styleAt(size)),
          textDirection: direction,
          textScaler: scaler,
          textHeightBehavior: heights,
          maxLines: lines,
        )..layout(maxWidth: width);

        double size = this.size;
        while (size > _least) {
          final TextPainter painter = laidOut(size, lines: 2);
          final bool fits = !painter.didExceedMaxLines;
          painter.dispose();
          if (fits) break;
          size -= 1;
        }
        final TextStyle style = styleAt(size);
        final int at = mark.isEmpty ? -1 : text.lastIndexOf(mark);
        if (at < 0) return Text(text, style: style);

        final TextPainter painter = laidOut(size);
        final List<TextBox> boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: at, extentOffset: at + mark.length),
        );
        painter.dispose();
        if (boxes.isEmpty) return Text(text, style: style);
        Rect word = boxes.first.toRect();
        for (final TextBox b in boxes.skip(1)) {
          word = word.expandToInclude(b.toRect());
        }

        const Color clear = Color(0x00000000);
        final String lead = text.substring(0, at);
        final String tail = text.substring(at + mark.length);
        return Stack(
          children: [
            Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: lead),
                  TextSpan(
                    text: mark,
                    style: const TextStyle(color: clear),
                  ),
                  TextSpan(text: tail),
                ],
              ),
            ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (_) => _gradient(
                    word,
                    context.p.isDark ? _darkStops : _lightStops,
                  ),
                  child: RichText(
                    textDirection: direction,
                    textScaler: scaler,
                    textHeightBehavior: heights,
                    text: TextSpan(
                      style: style.copyWith(color: clear),
                      children: [
                        TextSpan(text: lead),
                        TextSpan(
                          text: mark,
                          style: TextStyle(color: context.p.ink),
                        ),
                        TextSpan(text: tail),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A 95° linear gradient over [r], stopped at 0, 55 and 100%, drawn the
  /// way a browser draws `linear-gradient(95deg, …)`: along a line through
  /// the middle, long enough that the far corners meet the end colours.
  static Shader _gradient(Rect r, List<Color> colours) {
    const double angle = 95 * math.pi / 180;
    final Offset along = Offset(math.sin(angle), -math.cos(angle));
    final double length =
        r.width * math.sin(angle).abs() + r.height * math.cos(angle).abs();
    return ui.Gradient.linear(
      r.center - along * (length / 2),
      r.center + along * (length / 2),
      colours,
      const [0, 0.55, 1],
    );
  }
}

/// How much of a perk there is room for, most first.
enum _PerkSize {
  /// Its title and its line, beside its tile.
  full,

  /// Its title alone, beside its tile: most phones, once the door's line
  /// and the trial's days have taken theirs.
  compact,

  /// Its title alone, a size down, beside a smaller tile: a short phone's.
  tight,
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color colour;
  final _PerkSize size;

  const _Perk({
    required this.icon,
    required this.title,
    required this.sub,
    required this.colour,
    this.size = _PerkSize.full,
  });

  /// A title and three lines under it, which is what the longest line takes
  /// at the smallest size the text is allowed to shrink to.
  static const double fullHeight = 91;
  static const double gap = 22;

  /// The title alone, beside its tile, which is the taller of the two.
  static const double compactHeight = 46;
  static const double leastGap = 6;

  /// The same, a size down.
  static const double tightHeight = 26;
  static const double tightGap = 4;

  /// The least room kept above the first perk and below the last.
  static const double leastAir = 4;

  static double heightAt(_PerkSize size) => switch (size) {
    _PerkSize.full => fullHeight,
    _PerkSize.compact => compactHeight,
    _PerkSize.tight => tightHeight,
  };

  /// The least air between two perks at [size]; the room left over is
  /// spread between them.
  static double gapAt(_PerkSize size) => switch (size) {
    _PerkSize.full => gap,
    _PerkSize.compact => leastGap,
    _PerkSize.tight => tightGap,
  };

  /// The height [n] perks need at [size].
  static double needs(_PerkSize size, int n) =>
      n * heightAt(size) + (n - 1) * gapAt(size);

  @override
  Widget build(BuildContext context) {
    final bool full = size == _PerkSize.full;
    final bool tight = size == _PerkSize.tight;
    final double tile = tight ? tightHeight : compactHeight;
    return Row(
      crossAxisAlignment: full
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        // The tile is the app's own, as it was: the hue at a fifth for a
        // ground and the glyph in the hue.
        Container(
          width: tile,
          height: tile,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(tight ? 8.5 : 15),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: tight ? 14 : 23, color: colour),
        ),
        SizedBox(width: tight ? 12 : 18),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: full ? 3 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FitText(
                  title,
                  maxLines: 1,
                  minSize: tight ? 12 : 13,
                  style: AppText.body(
                    size: tight ? 15 : 18,
                    weight: FontWeight.w600,
                    height: 1.2,
                    spacing: -0.2,
                    color: context.p.ink,
                  ),
                ),
                if (full) ...[
                  const SizedBox(height: 6),
                  FitText(
                    sub,
                    maxLines: 3,
                    minSize: 11.5,
                    style: AppText.body(
                      size: 14,
                      height: 1.42,
                      color: context.p.ink.withValues(alpha: 0.56),
                    ),
                  ),
                ],
              ],
            ),
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
    final p = context.p;
    final bool dark = p.isDark;
    final Color off = dark ? const Color(0xFF0F0F11) : p.surfaceRaised;
    final List<Color> on = dark
        ? const [Color(0xFF242427), Color(0xFF161618)]
        : [p.surfaceRaised, p.surface];

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
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.ease,
              // The ring is half a point thicker on the chosen one and the
              // padding half a point thinner, so nothing inside moves.
              padding: selected
                  ? const EdgeInsets.fromLTRB(16, 16, 16, 15)
                  : const EdgeInsets.fromLTRB(16.5, 16.5, 16.5, 15.5),
              decoration: BoxDecoration(
                // 160°, top to bottom and a little across.
                gradient: LinearGradient(
                  begin: const Alignment(-0.33, -1.36),
                  end: const Alignment(0.33, 1.36),
                  colors: selected ? on : [off, off],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? p.inverse : p.ink.withValues(alpha: 0.09),
                  width: selected ? 2 : 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: p.inverse.withValues(alpha: 0.07),
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.5 : 0.12,
                          ),
                          blurRadius: 34,
                          offset: const Offset(0, 14),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _Radio(on: selected),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FitText(
                          label,
                          maxLines: 1,
                          minSize: 12,
                          style: AppText.body(
                            size: 16,
                            weight: FontWeight.w600,
                            height: 1,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FitText(
                          price,
                          maxLines: 1,
                          minSize: 16,
                          style: AppText.display(
                            size: 27,
                            weight: FontWeight.w600,
                            height: 1,
                            spacing: -0.8,
                            color: p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        per,
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w500,
                          height: 1,
                          color: p.ink.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  FitText(
                    note,
                    maxLines: 1,
                    minSize: 10,
                    style: AppText.body(
                      size: 12.5,
                      weight: FontWeight.w500,
                      height: 1.2,
                      color: p.ink.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
            // The saving rides the tile's top edge rather than taking a
            // row inside it, so the two tiles stay the same height.
            if (badge != null)
              Positioned(
                top: -12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: p.inverse,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.4 : 0.15,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: AppText.label(
                      size: 10,
                      weight: FontWeight.w700,
                      spacing: 1.4,
                      height: 1,
                      color: p.onInverse,
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
    final p = context.p;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.ease,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? p.inverse : p.inverse.withValues(alpha: 0),
        border: Border.all(
          color: on
              ? p.inverse.withValues(alpha: 0)
              : p.ink.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: on ? CustomPaint(painter: _Tick(p.onInverse)) : null,
    );
  }
}

/// The tick in the chosen plan's circle: a fourteen-point check, drawn on a
/// twenty-four grid, 2.8 wide on that grid, with round ends.
class _Tick extends CustomPainter {
  final Color colour;
  const _Tick(this.colour);

  @override
  void paint(Canvas canvas, Size size) {
    const double glyph = 14;
    final double unit = glyph / 24;
    final Offset o = Offset(
      (size.width - glyph) / 2,
      (size.height - glyph) / 2,
    );
    Offset at(double x, double y) => o + Offset(x * unit, y * unit);
    final Path path = Path()
      ..moveTo(at(5, 12.5).dx, at(5, 12.5).dy)
      ..lineTo(at(9.5, 17).dx, at(9.5, 17).dy)
      ..lineTo(at(19, 7.5).dx, at(19, 7.5).dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.colour != colour;
}
