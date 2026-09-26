import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';

import '../analytics.dart';
import '../l10n/l10n.dart';
import '../legal.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../state/app_state.dart';
import '../sync/review_access.dart';
import '../sync/subscription.dart';
import '../theme.dart';
import '../widgets/chunky.dart';
import '../widgets/fit_text.dart';
import '../data/topics.dart';
import '../widgets/ambient.dart';
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
// entirely of the reader's own cards; the journey; the whole archive. Six
// perks read as a list of features; three read as a reason.
List<({IconData icon, String title, String sub})> _perks(
  AppLocalizations l,
) => [
  (icon: Icons.auto_awesome_rounded, title: l.perkOwnTitle, sub: l.perkOwnLine),
  (icon: Icons.route_rounded, title: l.yourJourney, sub: l.perkJourneyLine),
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

  /// How long the offer was on screen, how it was left, and how often the
  /// reader went between the plans — the three things a paywall's own
  /// numbers are made of.
  final Stopwatch _open = Stopwatch()..start();
  String _leftBy = 'back';
  int _planChanges = 0;

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

  /// Whether the plan starts with a free week. The store's word when it has
  /// answered — its introductory offer at no charge — and otherwise the
  /// plans as sold: the year starts free, the month is charged today. The
  /// button and the line under it never promise a week the store will not
  /// give.
  bool _startsFree(Plan plan) {
    final Package? package = plan == Plan.year ? _store.yearly : _store.monthly;
    if (package != null) {
      final IntroductoryPrice? intro = package.storeProduct.introductoryPrice;
      return intro != null && intro.price == 0;
    }
    return plan == Plan.year;
  }

  String get _cta {
    if (widget.app.isPlus) return context.l10n.plusIsActive;
    final String suffix = _plan == Plan.year
        ? context.l10n.perYearShort
        : context.l10n.perMonthShort;
    final String price = _priceFor(_plan);
    return _startsFree(_plan)
        ? context.l10n.tryFreeThen(price, suffix)
        : context.l10n.subscribeFor(price, suffix);
  }

  /// The line under the button: what happens today. With no store behind
  /// this build nothing is ever charged, and a month "charged today" would
  /// be a lie, so that case says so instead.
  String get _terms {
    final l = context.l10n;
    if (_startsFree(_plan)) return l.noChargeTodayCancel;
    return _package != null ? l.chargedTodayCancel : l.cancelAnyTimeNoPayment;
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

    // No store to buy from. On the web preview, and while developing, unlock
    // locally so the gated screens can be seen, and say so rather than let
    // it look like a purchase. In a store build it means the store did not
    // answer, and buying nothing must not open Astute+.
    if (package == null && !kIsWeb && !kDebugMode) {
      Analytics.capture('purchase unavailable', {'source': widget.source});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.thatDidNotGoThrough)));
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
        if (mounted) _leaveBy('bought');
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.thatDidNotGoThrough)),
        );
    }
  }

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
    return Scaffold(
      backgroundColor: p.surface,
      // One screen, no scrolling. What is for sale is read at a glance or
      // it is not read: the three perks sit in whatever height the plans
      // and the button leave them, and a phone too short for their lines
      // shows their titles alone rather than a scrollbar.
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
                  const SizedBox(height: 22),
                  _Headline(
                    text: l.everyCardForYou,
                    mark: l.everyCardForYouMark,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, room) {
                        final perks = _perks(l);
                        final bool full =
                            room.maxHeight >=
                            perks.length * _Perk.fullHeight +
                                (perks.length - 1) * _Perk.gap;
                        // Spread through the room rather than huddled in
                        // the middle of it: three things, each with air
                        // around it, is what three things looks like.
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
                                  // Three points, three hues off the
                                  // wheel — the same wheel the reader's
                                  // own record is drawn in.
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
                          note: l.aMonth(_euros(kYearlyCents ~/ 12)),
                          badge: l.savePercent(kYearlySavingPercent),
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
                  const SizedBox(height: 18),
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
                  if (widget.app.isPlus)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await widget.app.endPlus();
                        if (context.mounted) _leave();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l.cancelTheTrial,
                          textAlign: TextAlign.center,
                          style: _smallPrint(context),
                        ),
                      ),
                    )
                  else ...[
                    // What today costs, in a line. The thing that stops
                    // people starting is not the price, it is not knowing
                    // when they will be charged.
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

/// The headline, as large as two lines allow, with the word for "you"
/// painted in the three colours of the lights.
///
/// Drawn twice, one over the other: the whole line with that word's place
/// kept but left clear, and over it the word alone through the gradient.
/// The gradient is measured on the word itself, so it runs across "you."
/// and not across the line, whatever the language puts around it.
class _Headline extends StatelessWidget {
  final String text;

  /// The part painted in the gradient; nothing is when it is not found.
  final String mark;

  const _Headline({required this.text, required this.mark});

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

        double size = _size;
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
  static const double fullHeight = 91;
  static const double gap = 22;
  static const double leastGap = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // The tile is the app's own, as it was: the hue at a fifth for a
        // ground and the glyph in the hue.
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
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: compact ? 0 : 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FitText(
                  title,
                  maxLines: 1,
                  minSize: 13,
                  style: AppText.body(
                    size: 18,
                    weight: FontWeight.w600,
                    height: 1.2,
                    spacing: -0.2,
                    color: context.p.ink,
                  ),
                ),
                if (!compact) ...[
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
