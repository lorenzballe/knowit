/// Sunday's week as a sheet (lib/state/your_week.dart says when it rises):
/// the week's name and "Your week", the reader's numbers two to a row
/// between hairlines — the cards read, the right answers, how sure against
/// how right, the days in a row — the subject they did best in, under them
/// the one figure only Astute+ shows, its name clear and itself blurred,
/// and, to a reader without an account, the account in one line. Then the
/// week gone over again, the way the journey's foot goes over it, and
/// Close.
///
/// Calm, as the app's other sheets are: the page's own ground, night or
/// paper, nothing that moves but the sheet coming up, and nothing asked.
library;

import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../analytics.dart';
import '../data/pills_repository.dart' show dateKey, pillById;
import '../data/topics.dart' show kTopics;
import '../l10n/dates.dart' show formatDay;
import '../l10n/l10n.dart';
import '../models/pill.dart';
import '../screens/deck_viewer_screen.dart';
import '../screens/journey_screen.dart' show openJourney, weekPlusFigure;
import '../state/app_state.dart';
import '../state/journey_record.dart' show Tally;
import '../state/your_week.dart';
import '../sync/account.dart';
import '../theme.dart';
import 'fit_text.dart';
import 'premium.dart';
import 'profile_menu.dart' show GoogleMark;
import 'sign_in_sheet.dart';
import 'ui.dart';

/// How the sheet was left.
enum WeekLeft {
  /// Close, the way back, or a swipe down.
  close,

  /// The week gone over again.
  review,

  /// The figure of Astute+'s: the plans, on the journey's door.
  plus,

  /// The account's line: the sign-in sheet.
  account,
}

/// How many of the week's cards the free plan goes over again: a day's
/// worth, as the journey's own review of the week.
const int kWeekReviewFree = 5;

/// Raises the week of [monday] over [context]'s screen, noted as shown as
/// it rises, and does what it was left for: the week gone over again, the
/// plans, or the account's own sheet with Apple and Google. A no on that
/// sheet is kept, and the line is not offered again.
Future<void> showYourWeek(
  BuildContext context, {
  required AppState app,
  required Account account,
  required DateTime monday,
}) async {
  final bool offerAccount = weekOffersAccount(
    app,
    signedIn: account.signedInForReal,
    canSignIn: account.canSignIn,
  );
  await app.notedWeekShown(dateKey(monday), account: offerAccount);
  if (!context.mounted) return;
  final YourWeek week = YourWeek.of(app, monday);
  final ({String key, String label, String value})? plus = weekPlusFigure(
    context,
    app,
  );
  // What the sheet said, as counts and kinds: never a subject's words.
  Analytics.capture('week sheet shown', {
    'week': dateKey(monday),
    'monday': app.today.weekday == DateTime.monday,
    'cards': week.cards,
    'days': week.days,
    'answered': week.answered.of,
    'right': week.answered.right,
    'has_sure': week.sure != null,
    'has_best': week.best != null,
    'plus_figure': plus?.key,
    'account': offerAccount,
  });
  final WeekLeft left =
      await showModalBottomSheet<WeekLeft>(
        context: context,
        isScrollControlled: true,
        // Never up under the status bar: a long week on a small phone
        // scrolls inside the sheet.
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x8C141416),
        builder: (_) => YourWeekSheet(
          app: app,
          week: week,
          plus: plus,
          account: offerAccount,
        ),
      ) ??
      WeekLeft.close;
  Analytics.capture('week sheet closed', {'left_by': left.name});
  if (!context.mounted) return;
  switch (left) {
    case WeekLeft.close:
      return;
    case WeekLeft.review:
      final List<Pill> cards = [
        for (final String id in app.record.readBetween(
          dateKey(monday),
          dateKey(week.sunday),
        ))
          ?pillById(id),
      ];
      final List<Pill> deck = app.isPlus
          ? cards
          : cards.take(kWeekReviewFree).toList();
      if (deck.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DeckViewerScreen(
            app: app,
            deck: deck,
            title: context.l10n.weekReviewTitle,
            answering: true,
            records: false,
            source: 'week',
          ),
        ),
      );
    case WeekLeft.plus:
      await requirePlus(
        context,
        app,
        () => openJourney(context, app),
        source: 'journey',
      );
    case WeekLeft.account:
      final bool signedIn = await showSignInSheet(
        context,
        account: account,
        app: app,
        door: SignInDoor.week,
      );
      if (!signedIn) {
        await app.notedWeekAccountDeclined();
        return;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(context.l10n.signedInRecordOnAccount)),
      );
  }
}

/// Capitals, with Turkish's dotted capital I.
String _caps(BuildContext context, String text) =>
    Localizations.localeOf(context).languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();

/// One of the week's numbers: the figure, what it is, and what it is made
/// of where that says more.
typedef _Figure = ({String key, String value, String label, String? note});

/// The sheet. Public so a test, and the camera, can lay it out.
class YourWeekSheet extends StatelessWidget {
  const YourWeekSheet({
    super.key,
    required this.app,
    required this.week,
    required this.plus,
    required this.account,
  });

  final AppState app;
  final YourWeek week;

  /// The figure of Astute+'s, blurred; none when none can be said yet.
  final ({String key, String label, String value})? plus;

  /// Whether the account is offered in its one line.
  final bool account;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final Palette p = context.p;
    final String locale = Localizations.localeOf(context).toString();
    String percent(int v) =>
        NumberFormat.percentPattern(locale).format(v / 100);
    DateFormat day;
    try {
      day = DateFormat.MMMMd(locale);
    } catch (_) {
      day = DateFormat.MMMMd('en');
    }
    final List<_Figure> figures = [
      (
        key: 'cards',
        value: NumberFormat.decimalPattern(locale).format(week.cards),
        label: l.pillReadWord(week.cards),
        note: null,
      ),
      if (week.answered.of > 0)
        (
          key: 'right',
          value: l.weekSheetRightValue(week.answered.right, week.answered.of),
          label: l.weekSheetRightLabel,
          note: null,
        ),
      if (week.sure case (:final int sure, :final int right, :final int n))
        (
          key: 'sure',
          value: '${percent(sure)} · ${percent(right)}',
          label: l.howSureAgainstHowRight,
          note: l.weekSheetAcross(n),
        ),
      if (week.streak > 0)
        (
          key: 'streak',
          value: l.streakDays(week.streak),
          label: l.journeyInARow,
          note: null,
        ),
    ];
    final BorderSide rule = BorderSide(color: p.line);
    const EdgeInsets row = EdgeInsets.symmetric(vertical: 12);
    final ({String key, Tally tally})? best = week.best;
    final ({String key, String label, String value})? plus = this.plus;

    return Container(
      key: const ValueKey('your-week'),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.paddingOf(context).bottom + 14,
      ),
      child: SingleChildScrollView(
        key: const ValueKey('your-week-scroll'),
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
            const SizedBox(height: 20),
            Text(
              _caps(context, l.weekSheetOf(formatDay(day, week.monday))),
              key: const ValueKey('your-week-eyebrow'),
              style: AppText.label(
                size: 11,
                weight: FontWeight.w700,
                spacing: 2,
                color: p.inkMuted,
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                l.yourWeek,
                style: AppText.display(
                  size: 32,
                  weight: FontWeight.w500,
                  height: 1.05,
                  spacing: -1,
                  color: p.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // The numbers, two to a row between hairlines; the last of an
            // odd count has its row to itself.
            for (int i = 0; i < figures.length; i += 2)
              Container(
                decoration: BoxDecoration(border: Border(top: rule)),
                padding: row,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _Cell(figure: figures[i])),
                    if (i + 1 < figures.length) ...[
                      const SizedBox(width: 16),
                      Expanded(child: _Cell(figure: figures[i + 1])),
                    ],
                  ],
                ),
              ),
            // The subject the week went best in, its colour beside it.
            if (best != null)
              Container(
                key: const ValueKey('your-week-best'),
                decoration: BoxDecoration(border: Border(top: rule)),
                padding: row,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 3,
                        height: 40,
                        margin: const EdgeInsetsDirectional.only(
                          end: 12,
                          top: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kTopics[best.key]?.color ?? p.ink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Cell(
                        figure: (
                          key: 'subject',
                          value: l.subjectOf(
                            kTopics[best.key]?.name ?? best.key,
                          ),
                          label: l.journeyStrongest,
                          note: l.answersRightOf(
                            best.tally.right,
                            best.tally.of,
                          ),
                        ),
                        word: true,
                      ),
                    ),
                  ],
                ),
              ),
            // The one figure only Astute+ shows: its name in the clear, the
            // reader's own figure blurred, and a tap the plans.
            if (plus != null)
              Container(
                decoration: BoxDecoration(border: Border(top: rule)),
                child: _PlusRow(
                  label: plus.label,
                  value: plus.value,
                  onTap: () => Navigator.of(context).pop(WeekLeft.plus),
                ),
              ),
            // The account, in one line, to a reader who has none.
            if (account)
              Container(
                decoration: BoxDecoration(border: Border(top: rule)),
                child: _AccountLine(
                  onTap: () => Navigator.of(context).pop(WeekLeft.account),
                ),
              ),
            Container(
              decoration: BoxDecoration(border: Border(top: rule)),
              padding: const EdgeInsets.only(top: 16),
              child: PrimaryButton(
                key: const ValueKey('your-week-review'),
                label: l.weekReviewTitle,
                onPressed: () => Navigator.of(context).pop(WeekLeft.review),
              ),
            ),
            const SizedBox(height: 4),
            QuietButton(
              key: const ValueKey('your-week-close'),
              label: l.closeLabel,
              onPressed: () => Navigator.of(context).pop(WeekLeft.close),
            ),
          ],
        ),
      ),
    );
  }
}

/// A number of the week: the figure in the display face, as large as one
/// line allows, its name in small capitals under it, and what it is made
/// of, quieter. A subject's name, [word], a little smaller, on two lines at
/// most.
class _Cell extends StatelessWidget {
  const _Cell({required this.figure, this.word = false});

  final _Figure figure;
  final bool word;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    final _Figure f = figure;
    return Column(
      key: ValueKey('your-week-${f.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FitText(
          f.value,
          maxLines: word ? 2 : 1,
          minSize: word ? 16 : 17,
          wholeWords: true,
          style: AppText.display(
            size: word ? 22 : 26,
            weight: FontWeight.w500,
            height: 1.08,
            spacing: word ? -0.4 : -0.7,
            color: p.ink,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 4),
        Text(
          _caps(context, f.label),
          style: AppText.label(
            size: 10.5,
            weight: FontWeight.w700,
            spacing: 1.5,
            height: 1.25,
            color: p.inkMuted,
          ),
        ),
        if (f.note case final String note)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              note,
              style: AppText.body(
                size: 12.5,
                height: 1.3,
                color: p.ink.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// The figure of Astute+'s: its name in small capitals and the Astute+
/// mark beside it, the reader's own figure under them behind a blur no word
/// of it reads through, and the whole row the way to the plans.
class _PlusRow extends StatelessWidget {
  const _PlusRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      label: '$label. ${context.l10n.storyUnlock}',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('your-week-plus'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _caps(context, label),
                      style: AppText.label(
                        size: 10.5,
                        weight: FontWeight.w700,
                        spacing: 1.5,
                        height: 1.25,
                        color: p.inkMuted,
                      ),
                    ),
                  ),
                  const PlusLock(locked: true),
                ],
              ),
              const SizedBox(height: 8),
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    style: AppText.display(
                      size: 20,
                      weight: FontWeight.w500,
                      height: 1.25,
                      color: p.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The account, in one line: Google's mark and Apple's, "Keep your week on
/// every phone", and the way on.
class _AccountLine extends StatelessWidget {
  const _AccountLine({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('your-week-account'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GoogleMark(size: 16),
                    const SizedBox(width: 7),
                    Icon(Icons.apple, size: 19, color: p.ink),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.weekSheetAccount,
                  style: AppText.body(
                    size: 14.5,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: p.ink.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
