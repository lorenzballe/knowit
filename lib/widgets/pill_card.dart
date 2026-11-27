import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

import 'package:flutter/services.dart';

import '../analytics.dart';
import '../data/skill_scores.dart' show ScoreMove;
import '../data/skills.dart';
import '../data/topics.dart' show inkOn;
import '../measure/card_read.dart';
import '../models/pill.dart';
import '../models/place.dart';
import '../sync/served.dart';
import '../theme.dart';
import 'card_edge.dart';
import 'hold_to_keep.dart';
import 'liked_mark.dart';
import 'motion.dart';
import 'place_it.dart';
import 'place_line.dart';
import 'scene_view.dart';
import 'reveal_body.dart';
import 'scaled_text.dart';
import 'skill_mark.dart';
import 'skill_score.dart';
import 'source_foot.dart';
import 'subject_icon.dart';
import 'web/page_messages.dart';
import 'web/web_card_face.dart';
import 'web/web_card_page.dart';

/// Full-bleed, one-colour-per-topic card — the "card is the screen" look,
/// carrying the line to keep and a source once flipped.
class PillCard extends StatelessWidget {
  final Pill pill;

  /// Where this card sits in the set, or null when something else on screen
  /// already says. The bars above the deck and the viewer's own header both
  /// do, and printing it a second time on the card itself is chrome pretending
  /// to be content.
  final String? indexLabel;
  final bool flipped;

  /// What the reader committed to, and where to send a new commitment.
  /// Null while untouched.
  final Answer? given;
  final void Function(String response, int? confidence, String? reason)?
  onAnswer;

  /// True when this card is in today's deck because it came back.
  final bool isReview;

  /// True when this card was chosen for the reader on a day where the
  /// others came at random — the free day says which is which.
  final bool isOwn;

  /// Where the reader lives, for the line a card about a place carries on
  /// its front (see [placeLineOf]); null when they have not said.
  final Place? home;

  /// Why this card is in today's five, said on its front under its head
  /// the way a card about a place says so (lib/data/why.dart). Null for
  /// nothing to say.
  final String? note;

  /// The mark beside [note]: what kind of reason it is.
  final IconData? noteIcon;

  /// A tap on [note]: Why this card (why_sheet.dart). Null, the line is
  /// only read. On the back it is the way to the same sheet from the foot,
  /// beside Go deeper, where the foot being tried carries one
  /// (source_foot.dart).
  final VoidCallback? onNote;

  /// The skill the reader put in focus that this card trains, when it trains
  /// one (lib/data/skill_levels.dart): its small mark in the card's head,
  /// beside where the heart of a liked card stands (skill_mark.dart).
  final Skill? skill;

  /// A tap on that mark, on the card being read: what it means.
  final VoidCallback? onSkill;

  /// How the reader's answer moved their score, said beside the verdict on
  /// the back: in [skill] when the card trains it, or else in every skill
  /// together (lib/data/skill_scores.dart). Null, nothing is said.
  final ScoreMove? move;

  const PillCard({
    super.key,
    required this.pill,
    this.indexLabel,
    required this.flipped,
    this.given,
    this.onAnswer,
    this.isReview = false,
    this.isOwn = false,
    this.home,
    this.note,
    this.noteIcon,
    this.onNote,
    this.skill,
    this.onSkill,
    this.move,
    this.saved = false,
    this.onSave,
    this.liked = false,
    this.onLike,
    this.onShare,
    this.page,
    this.onPageMessage,
    this.controlsLive = true,
  });

  /// Whether the save and share on the card can be pressed, and read out:
  /// not on a card waiting under the one being read. They are drawn there
  /// all the same, so a card rises with them already on it rather than
  /// having them pop in half a second after it has come up.
  final bool controlsLive;

  /// A free card's live page, when the deck keeps one for it (see
  /// [WebCardPool]); without one its poster is drawn in the page's place.
  final WebCardPage? page;

  /// What a free card's page asks of the deck — an answer, a turn, the next
  /// card — heard on the card on top only.
  final ValueChanged<PageMessage>? onPageMessage;

  /// Keeping and sharing act on this card, not on the screen, so they live on
  /// it. They used to sit in a row of their own under the deck, which put two
  /// rows of controls along the bottom edge with the tab bar.
  final bool saved;
  final VoidCallback? onSave;

  /// Liking is the whole card held down, not a button: a bookmark is a
  /// thing you go and press, a like is a thing you do without letting go.
  final bool liked;
  final VoidCallback? onLike;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final Widget card = Stack(
      children: [
        _face(context),
        if (skill != null) _skillMark(context, skill!),
        // Each control is 44 square, its mark where the 38 one put it.
        if (onSave != null)
          Positioned(
            right: _CardControl.right,
            bottom: _CardControl.bottom,
            child: _live(
              Row(
                children: [
                  _CardControl(
                    label: saved
                        ? context.l10n.removeFromSaved
                        : context.l10n.saveThisPill,
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    ink: pill.ink,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onSave!.call();
                    },
                  ),
                  const SizedBox(width: 4),
                  _CardControl(
                    label: context.l10n.shareThisPill,
                    icon: Icons.ios_share_rounded,
                    ink: pill.ink,
                    onTap: () => onShare?.call(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    // Held, the whole card is the button. Built round every card, the one
    // waiting under the card being read too, which cannot be liked yet: a
    // card given a new parent as it rises is built again from nothing, and a
    // drawn card's page with it — the drawing gone for a frame, a flash, as
    // the card came to the front.
    return HoldToKeep(
      saved: liked,
      ink: pill.ink,
      ground: pill.color,
      onToggle: onLike,
      child: card,
    );
  }

  /// The mark of the skill in focus the card trains, in its head on the
  /// right: where the heart of a liked card stands, or just before it when
  /// the card is liked; at the height of the subject's name. On a drawn card
  /// the head is the page's, its tag on the right, and the mark stands
  /// before the tag as the heart does. Where the head has no room for it
  /// beside the subject and its chip, it is left out rather than laid on
  /// them.
  Widget _skillMark(BuildContext context, Skill skill) {
    // A drawn card's back is the app's own face, as every card's is.
    final bool drawn = pill.web != null && !flipped;
    // A number printed in the head, where none is printed today, keeps it.
    if (!drawn && indexLabel != null) return const SizedBox.shrink();
    final Color ink = drawn && pill.web?.ground != null
        ? inkOn(groundOf(pill))
        : pill.ink;
    final String? chip = isReview
        ? context.l10n.againChip
        : isOwn
        ? context.l10n.forYouChip
        : null;
    Widget at(BuildContext context, BoxConstraints box) {
      // On a drawn card the head is the page's: the mark waits until the
      // page has been read for the tag it prints on the right, so it never
      // stands on it.
      if (drawn && !CardTags.read(pill.id)) return const SizedBox.shrink();
      // The glyph's middle, from the card's top and right edges.
      final double top = drawn
          ? CardTags.headMiddle
          : _headMiddle(context, chip);
      final double right = drawn
          ? SkillMark.middleOnPage(CardTags.of(pill.id), liked: liked)
          : 28 +
                (liked ? LikedMark.size + SkillMark.gap : 0) +
                SkillMark.size / 2;
      if (!SkillMark.fits(
        width: box.maxWidth,
        middle: right,
        subject: context.l10n.subjectOf(pill.topic),
        chip: chip,
        scaler: drawn ? TextScaler.noScaling : MediaQuery.textScalerOf(context),
      )) {
        return const SizedBox.shrink();
      }
      const double half = SkillMark.touch / 2;
      return Stack(
        children: [
          // Liked, it steps aside for the heart as the heart comes in.
          AnimatedPositioned(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            top: top - half,
            right: right - half,
            child: SkillMark(
              skill: skill,
              ink: ink,
              onTap: controlsLive ? onSkill : null,
            ),
          ),
        ],
      );
    }

    return Positioned.fill(
      child: drawn
          ? ValueListenableBuilder<int>(
              valueListenable: CardTags.changes,
              builder: (context, _, _) => LayoutBuilder(builder: at),
            )
          : LayoutBuilder(builder: at),
    );
  }

  /// The middle of a card's own head, from its top, where the heart stands:
  /// below the face's top padding, half the head's row, which is the
  /// subject's mark, its name at the reader's text size, or the [chip], the
  /// tallest of them.
  double _headMiddle(BuildContext context, String? chip) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextStyle base = DefaultTextStyle.of(context).style;
    double lineOf(String text, double size, double spacing) {
      final TextPainter t = TextPainter(
        text: TextSpan(
          text: text.toUpperCase(),
          style: base.merge(AppText.label(size: size, spacing: spacing)),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double h = t.height;
      t.dispose();
      return h;
    }

    double row = math.max(
      16,
      lineOf(context.l10n.subjectOf(pill.topic), 11, 1.4),
    );
    if (chip != null) row = math.max(row, 6 + lineOf(chip, 9.5, 1));
    return 26 + row / 2;
  }

  /// The save and share as they are on this card: live on the card being
  /// read, drawn but not pressed or read out on one waiting under it.
  Widget _live(Widget controls) => controlsLive
      ? controls
      : ExcludeSemantics(child: IgnorePointer(child: controls));

  Widget _face(BuildContext context) {
    // A free card's front is its page, edge to edge inside the same frame:
    // the same corners, edge and shadow as every card, the page drawing
    // everything else — its head, its question, whatever it asks.
    if (!flipped && pill.web != null) {
      return Container(
        decoration: cardFace(context, groundOf(pill), radius: 34, lift: 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          // One shape liked or not, so the page keeps its element.
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebCardFace(
                pill: pill,
                page: page,
                onMessage: onPageMessage,
                chip: isReview
                    ? context.l10n.againChip
                    : isOwn
                    ? context.l10n.forYouChip
                    : null,
                note: placeLineOf(context, pill.place, home) ?? note,
              ),
              // Liked, the heart stands in the page's head on the right,
              // before the tag it prints there.
              if (liked)
                Positioned(
                  top: CardTags.headMiddle - LikedMark.size / 2,
                  right: CardTags.heartRight(CardTags.of(pill.id)),
                  child: IgnorePointer(
                    child: LikedMark(
                      ink: pill.web?.ground == null
                          ? pill.ink
                          : inkOn(groundOf(pill)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    // Cut from the page with a hairline where its colour is the page's
    // own, and lifted by a shadow that stays under the card (card_edge.dart).
    return Container(
      decoration: cardFace(context, pill.color, radius: 34, lift: 1),
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // The subject's own mark beside its name, as on the shelf
                  // the card ends the day on: one card, drawn one way.
                  CardMark(pill: pill, size: 16, ink: pill.ink),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.subjectOf(pill.topic).toUpperCase(),
                    style: AppText.label(
                      size: 11,
                      spacing: 1.4,
                      color: pill.ink.withValues(alpha: 0.72),
                    ),
                  ),
                  if (isReview || isOwn) ...[
                    const SizedBox(width: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: pill.wash,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isReview
                            ? context.l10n.againChip
                            : context.l10n.forYouChip,
                        style: AppText.label(
                          size: 9.5,
                          spacing: 1,
                          color: pill.ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (liked || indexLabel != null)
                Row(
                  children: [
                    if (liked) LikedMark(ink: pill.ink),
                    if (liked && indexLabel != null) const SizedBox(width: 8),
                    if (indexLabel != null)
                      Text(
                        indexLabel!,
                        style: AppText.label(
                          size: 11,
                          color: pill.ink.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (!flipped)
            if (placeLineOf(context, pill.place, home) case final String why)
              _WhyLine(
                key: const ValueKey('place-line'),
                icon: Icons.place_rounded,
                text: why,
                ink: pill.ink,
                // Being tried: where Why this card is said on the front of
                // every card (source_foot.dart), a card about a place opens
                // it from the line that says so.
                onTap: sourceFoot == SourceFoot.stack ? onNote : null,
              ),
          if (!flipped && note != null)
            _WhyLine(
              key: const ValueKey('card-note'),
              icon: noteIcon ?? Icons.auto_awesome_rounded,
              text: note!,
              ink: pill.ink,
              onTap: onNote,
            ),
          Expanded(
            child: flipped
                ? _BackFace(
                    pill: pill,
                    given: given,
                    move: move,
                    cornerRoom: onSave != null ? _CardControl.room : 0,
                    onWhy: onNote,
                  )
                // The challenge decides the front. A new kind of challenge
                // will not compile until it is given a face here.
                : switch (pill.challenge) {
                    NoChallenge() when pill.scene != null => _SceneFront(
                      pill: pill,
                    ),
                    NoChallenge() => _FrontFace(pill: pill),
                    PickOne(:final options) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      options: options,
                    ),
                    TakeASide(:final positions) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      prompt: context.l10n.pickASideNoRightAnswer,
                      options: positions,
                    ),
                    TypeNumber(:final unit) => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      input: (commit) => _NumberInput(
                        pill: pill,
                        unit: unit,
                        onAnswer: commit,
                      ),
                    ),
                    // Only a card with its page asks on its page; one that
                    // reached the native face without it is read.
                    PageJudged() => _FrontFace(pill: pill),
                    // A feel for size is placed on a ruler, not typed.
                    final Estimate estimate => _AskFace(
                      pill: pill,
                      onAnswer: onAnswer,
                      given: given,
                      corner: onSave != null,
                      prompt: context.l10n.estimateCloseEnough,
                      input: (commit) => PlaceItInput(
                        pill: pill,
                        estimate: estimate,
                        onAnswer: commit,
                      ),
                    ),
                  },
          ),
        ],
      ),
    );
  }
}

/// Why a card is in front of the reader, under its subject: "Near you ·
/// Modena" on a card about a place, with a pin; "Sunday: one more chosen
/// for you" on Sunday's one more of the reader's own, with a spark. Quiet
/// on purpose — the card is the question, and this is the one fact about
/// it the reader did not choose — so it takes the subject row's ink at the
/// same strength, sentence case, a mark beside it, and wraps rather than
/// being cut in a language that runs long.
class _WhyLine extends StatelessWidget {
  const _WhyLine({
    super.key,
    required this.icon,
    required this.text,
    required this.ink,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color ink;

  /// Opens what the line is short for; null, it is only read.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color muted = ink.withValues(alpha: 0.66);
    final Widget line = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: ExcludeSemantics(child: Icon(icon, size: 13, color: muted)),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: text,
                children: [
                  // A tap opens more: the line says so with a mark at its
                  // end, as a link in a sentence does.
                  if (onTap != null)
                    TextSpan(
                      text: '\u00a0\u203a',
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w800,
                        height: 1.25,
                        color: muted,
                      ),
                    ),
                ],
              ),
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w500,
                height: 1.25,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return line;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: line,
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  final Pill pill;
  const _FrontFace({required this.pill});

  @override
  Widget build(BuildContext context) {
    // Set to the space rather than to a fixed size, so a short question is
    // not a line floating in a field of colour — but inside an editorial
    // band, not a poster one. At sixty-four points a five-word question
    // shouted; the card is something you read, not a billboard.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ScaledText(
            text: pill.question,
            min: 21,
            max: 34,
            alignment: Alignment.centerLeft,
            styleFor: (size) => AppText.display(
              size: size,
              weight: FontWeight.w600,
              height: 1.08,
              // Tracking tightens as the type grows: what reads as generous
              // at 22pt reads as gappy at 54.
              spacing: -0.4 - size * 0.028,
              color: pill.ink,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.tapToReveal,
          style: AppText.body(
            size: 13,
            weight: FontWeight.w500,
            color: pill.ink.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// A card with something to play with: the question on top, the scene
/// filling the middle, the way to the answer at the foot.
class _SceneFront extends StatelessWidget {
  final Pill pill;
  const _SceneFront({required this.pill});

  @override
  Widget build(BuildContext context) {
    TextStyle styleFor(double size) => AppText.display(
      size: size,
      weight: FontWeight.w600,
      height: 1.12,
      spacing: -0.3 - size * 0.018,
      color: pill.ink,
    );
    return LayoutBuilder(
      builder: (context, box) {
        // A share of the card, or what the question needs at its smallest
        // size when that is more: a question that has to scroll keeps the
        // card's vertical throw for itself, so less like this stops working.
        final needed =
            (TextPainter(
              text: TextSpan(text: pill.question, style: styleFor(16)),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: box.maxWidth)).height +
            2;
        final room = math.min(
          math.max(box.maxHeight * 0.27, needed),
          box.maxHeight * 0.42,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: room,
              child: ScaledText(
                text: pill.question,
                min: 16,
                max: 27,
                alignment: Alignment.topLeft,
                styleFor: styleFor,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SceneView(
                scene: pill.scene!,
                ink: pill.ink,
                ground: pill.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.tapToReveal,
              style: AppText.body(
                size: 13,
                weight: FontWeight.w500,
                color: pill.ink.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackFace extends StatelessWidget {
  final Pill pill;
  final Answer? given;

  /// Room kept clear for the save and share buttons in the bottom corner.
  final double cornerRoom;

  /// How the answer moved the reader's score, beside the verdict.
  final ScoreMove? move;

  /// Opens Why this card from the foot, on a card of the day.
  final VoidCallback? onWhy;
  const _BackFace({
    required this.pill,
    this.given,
    this.move,
    this.cornerRoom = 0,
    this.onWhy,
  });

  @override
  Widget build(BuildContext context) {
    final given = this.given;
    final Estimate? estimate = switch (pill.challenge) {
      final Estimate e when pill.isGraded => e,
      _ => null,
    };

    // What the reader committed to, said first: right or wrong on a card
    // that is marked, the line they took on one that is not.
    Widget? lead;
    double Function(double, TextScaler)? leadHeight;
    Widget? shortLead;
    double Function(double, TextScaler)? shortLeadHeight;
    Widget? leastLead;
    double Function(double, TextScaler)? leastLeadHeight;
    if (given != null && pill.isGraded) {
      final bool right = pill.challenge.accepts(given.response);
      _Verdict verdictOf(_Room room) => _Verdict(
        pill: pill,
        right: right,
        given: pill.challenge.describe(given.response),
        confidence: given.confidence,
        move: move,
        room: room,
      );
      Widget leadOf(_Verdict verdict) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PopIn(delay: const Duration(milliseconds: 260), child: verdict),
          if (estimate != null) ...[
            const SizedBox(height: 6),
            PlaceItReveal(
              pill: pill,
              estimate: estimate,
              response: given.response,
            ),
          ],
        ],
      );
      double Function(double, TextScaler) heightOf(_Verdict verdict) =>
          (width, scaler) =>
              verdict.heightIn(context, width, scaler) +
              (estimate != null ? 6 + PlaceItReveal.height : 0);
      final _Verdict verdict = verdictOf(_Room.all);
      lead = leadOf(verdict);
      leadHeight = heightOf(verdict);
      // On a back too full for the whole of it, how sure goes first: it
      // was said a moment ago, on the front.
      final _Verdict brief = verdictOf(_Room.withoutSure);
      shortLead = leadOf(brief);
      shortLeadHeight = heightOf(brief);
      // Then, on a wrong answer, what was said: the answer under it says
      // what it is. A right one has nothing said back to give up.
      if (!right) {
        final _Verdict bare = verdictOf(_Room.verdictOnly);
        leastLead = leadOf(bare);
        leastLeadHeight = heightOf(bare);
      }
    } else if (given != null) {
      lead = PopIn(
        delay: const Duration(milliseconds: 260),
        child: _YourLine(pill: pill, given: given),
      );
      leadHeight = (width, scaler) =>
          _YourLine.heightFor(context, pill, given, width, scaler);
      if (given.hasReason) {
        shortLead = PopIn(
          delay: const Duration(milliseconds: 260),
          child: _YourLine(pill: pill, given: given, short: true),
        );
        shortLeadHeight = (width, scaler) => _YourLine.heightFor(
          context,
          pill,
          given,
          width,
          scaler,
          short: true,
        );
      }
    }

    return CardReveal(
      pill: pill,
      lead: lead,
      leadHeight: leadHeight,
      shortLead: shortLead,
      shortLeadHeight: shortLeadHeight,
      leastLead: leastLead,
      leastLeadHeight: leastLeadHeight,
      cornerRoom: cornerRoom,
      onWhy: onWhy,
      // On a card that asked first, the scene waits for the answer: played
      // before, it would have given it away.
      scene: pill.scene != null && pill.asksSomething
          ? (height) => SizedBox(
              height: height,
              child: SceneView(
                scene: pill.scene!,
                ink: pill.ink,
                ground: pill.color,
              ),
            )
          : null,
    );
  }
}

/// The height [text] is set at in [width], the way a [Text] here sets it:
/// on the inherited style, which carries the theme's tracking.
double _measure(
  BuildContext context,
  String text,
  TextStyle style,
  double width,
  TextScaler scaler,
) {
  final base = DefaultTextStyle.of(context);
  final p = TextPainter(
    text: TextSpan(text: text, style: base.style.merge(style)),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    textHeightBehavior: base.textHeightBehavior,
  )..layout(maxWidth: width);
  final h = p.height;
  p.dispose();
  return h;
}

double _measureSpan(
  BuildContext context,
  InlineSpan span,
  double width,
  TextScaler scaler, {
  List<PlaceholderDimensions> placeholders = const [],
}) {
  final base = DefaultTextStyle.of(context);
  final p = TextPainter(
    text: TextSpan(style: base.style, children: [span]),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    textHeightBehavior: base.textHeightBehavior,
  );
  if (placeholders.isNotEmpty) p.setPlaceholderDimensions(placeholders);
  p.layout(maxWidth: width);
  final h = p.height;
  p.dispose();
  return h;
}

/// How much of the verdict a back has room for, from all of it down: what
/// was said and how sure, what was said, the verdict alone.
enum _Room { all, withoutSure, verdictOnly }

/// Right or wrong, said plainly at the top of the reveal: the verdict in
/// the card's own voice, set large, running into what was said and how
/// sure, set small — a run-in head, as a paper sets one.
///
/// It used to be one line of eleven-point capitals, quieter than the
/// subject's name over the card. That is the wrong size for the moment the
/// app is built on, how sure against how right. Run in rather than stacked,
/// it takes about the room the old line took, so the back still fits the
/// card. A wrong answer is "Not quite.": said, and not rubbed in.
class _Verdict extends StatelessWidget {
  final Pill pill;
  final bool right;
  final String given;
  final int? confidence;

  /// How much of it the back has room for.
  final _Room room;

  /// How the answer moved the reader's score, said right after the verdict.
  final ScoreMove? move;
  const _Verdict({
    required this.pill,
    required this.right,
    required this.given,
    this.confidence,
    this.move,
    this.room = _Room.all,
  });

  /// The mark beside the words, and the gap after it.
  static const double _mark = 20;
  static const double _gap = 10;

  static TextStyle _headStyle(Color ink) => AppText.display(
    size: 20,
    weight: FontWeight.w600,
    height: 1.2,
    spacing: -0.4,
    color: ink,
  );

  static TextStyle _detailStyle(Color ink) => AppText.body(
    size: 13,
    weight: FontWeight.w500,
    height: 1.35,
    color: ink.withValues(alpha: 0.75),
  );

  /// The verdict itself.
  String _head(BuildContext context) => !right
      ? context.l10n.verdictWrong
      : pill.challenge is Estimate
      ? context.l10n.verdictClose
      : context.l10n.verdictRight;

  /// What was said, when it was not what the card says: the reader's
  /// answer, how sure they were when [sure] is given, and the card's — "Hai
  /// detto «About one in twelve», sicuro al 60% · Giusta: «More than four
  /// in five»". A card's words are quoted, so they never run on into the
  /// app's; a number is said as it is. The dot is held to the words before
  /// it, so a line never starts with it.
  String? _said(BuildContext context, int? sure) {
    if (right) return null;
    final l = context.l10n;
    String yours(String said) => sure == null
        ? l.verdictYouSaid(said)
        : l.verdictYouSaidSure(said, sure);
    return switch (pill.challenge) {
      Estimate(:final answerLabel, :final low, :final high) =>
        '${yours(given)}\u00A0· '
            '${l.verdictRightWithin(answerLabel, '$low', '$high')}',
      TypeNumber(:final answerLabel) =>
        '${yours(given)}\u00A0· ${l.verdictRightIs(answerLabel)}',
      // A wrong pick is said the way a wrong number is: what was picked,
      // and what it is. It used to be "almost everyone gets this wrong",
      // which is a claim about other readers that nothing on the phone can
      // back — how each card is answered is counted on the server, for the
      // tools that check cards (functions/src/scorecard.ts), and none of it
      // reaches a card's back.
      PickOne(:final correctOption) =>
        '${yours(l.quoted(given))}\u00A0· '
            '${l.verdictRightIs(l.quoted(correctOption))}',
      // Never marked, so never given a verdict: the back says the reader's
      // own line instead. A page marks its own and has said what was right
      // already; the answer under the verdict says why.
      NoChallenge() || TakeASide() || PageJudged() => null,
    };
  }

  /// How the readers who answered this card did, counted on the server
  /// and nothing about who (functions/src/scorecard.ts, crowdOf): the share
  /// who got it right, beside a right answer, or wrong too, beside a wrong
  /// one. Null where too few have answered for the number to mean anything.
  String? _crowd(BuildContext context) {
    final double? wrong = Served.instance.lastExplore?.wrongShare(pill.id);
    if (wrong == null) return null;
    return right
        ? context.l10n.crowdGotRight(((1 - wrong) * 100).round())
        : context.l10n.crowdGotWrong((wrong * 100).round());
  }

  /// What runs on after the verdict: what was said, how sure, and how the
  /// other readers did, each said once.
  String? _detail(BuildContext context) {
    if (room == _Room.verdictOnly) return null;
    final l = context.l10n;
    final int? sure = room == _Room.all ? confidence : null;
    final String? own =
        _said(context, sure) ?? (sure == null ? null : l.verdictSure(sure));
    final String? crowd = room == _Room.all ? _crowd(context) : null;
    final String? line = crowd == null
        ? own
        : own == null
        ? crowd
        : '$own\u00A0· $crowd';
    return line == null ? null : l.elided(line);
  }

  InlineSpan _span(BuildContext context) {
    final String? detail = _detail(context);
    final ScoreMove? move = this.move;
    return TextSpan(
      children: [
        TextSpan(text: _head(context), style: _headStyle(pill.ink)),
        // The score it moved, as it moved: said with the verdict, the
        // moment the back comes round.
        if (move != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ScoreMoveChip(move: move, ink: pill.ink),
          ),
        if (detail != null)
          TextSpan(text: '  $detail', style: _detailStyle(pill.ink)),
      ],
    );
  }

  /// The room the verdict takes at [width]: its words beside the mark.
  double heightIn(BuildContext context, double width, TextScaler scaler) {
    final ScoreMove? move = this.move;
    final double h = _measureSpan(
      context,
      _span(context),
      width - _mark - _gap,
      scaler,
      placeholders: [
        if (move != null)
          PlaceholderDimensions(
            size: ScoreMoveChip.sizeOf(context, move, scaler),
            alignment: PlaceholderAlignment.middle,
          ),
      ],
    );
    return math.max(h, _mark + 3);
  }

  @override
  Widget build(BuildContext context) {
    // Said out loud when the back comes round, for a reader who cannot see
    // the mark or the size of the words.
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The words say right or wrong; the mark repeats it in shape.
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ExcludeSemantics(
              child: Icon(
                right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: _mark,
                color: pill.ink,
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(child: Text.rich(_span(context))),
        ],
      ),
    );
  }
}

/// A card that asks before it tells: the question, whatever input the
/// challenge needs, and an optional nudge for when the reader is stuck.
class _AskFace extends StatefulWidget {
  final Pill pill;

  /// What a pick offers, an option a tap: true or false, one of three, a
  /// side. A pick is drawn here rather than by [input], because what
  /// happens to the options once one is tapped is the face's own (see
  /// [_PickGroup]).
  final List<String>? options;

  /// Built with the callback that reports a raw response: the input of a
  /// card that is not a pick.
  final Widget Function(ValueChanged<String>? commit)? input;
  final void Function(String response, int? confidence, String? reason)?
  onAnswer;

  /// Overrides the default line under the input, so a debate does not tell
  /// the reader to commit to a right answer that does not exist.
  final String? prompt;

  /// What this reader already committed, if anything. Only used to word the
  /// line under the input when the card cannot be answered here.
  final Answer? given;

  /// Whether the card's save and share sit in the bottom corner, which the
  /// face then keeps clear.
  final bool corner;

  const _AskFace({
    required this.pill,
    required this.onAnswer,
    this.options,
    this.input,
    this.prompt,
    this.given,
    this.corner = false,
  }) : assert(options != null || input != null);

  @override
  State<_AskFace> createState() => _AskFaceState();
}

class _AskFaceState extends State<_AskFace>
    with SingleTickerProviderStateMixin {
  bool _hintOpen = false;

  /// Held between answering and saying how sure you are.
  String? _pending;

  /// The option just tapped, locked in: filled with the card's ink the
  /// instant it is touched, and kept, ticked, over the step that follows,
  /// so a card that does not turn at once still says what was taken. The
  /// other options give way to it, and nothing more is taken until the
  /// card has turned.
  int? _locked;

  /// The level of how sure just tapped, locked in the same way.
  int? _level;

  /// The reason sent: the card turns on it, once.
  bool _sent = false;

  /// From the tap to the step under the option kept: the others dimmed at
  /// once, then folded away while the step comes in (see [_PickGroup]).
  late final AnimationController _lock = AnimationController(
    vsync: this,
    duration: _PickGroup.lockTime,
  );

  @override
  void didUpdateWidget(_AskFace old) {
    super.didUpdateWidget(old);
    // Another card in the same place starts untouched.
    if (old.pill.id != widget.pill.id) {
      _pending = null;
      _locked = null;
      _level = null;
      _sent = false;
      _lock.value = 0;
    }
  }

  @override
  void dispose() {
    _lock.dispose();
    super.dispose();
  }

  void _commit(String response) {
    // Taken already: nothing more is, until the card has turned.
    if (_pending != null || _locked != null) return;
    final bool pick = widget.options != null;
    // A graded card that does not ask how sure this time ([SureAsk]) is
    // answered as it is committed: right or wrong is kept all the same.
    // It turns at once, the option filled with ink turning with it.
    if (widget.pill.isGraded && !SureAsk.of(widget.pill)) {
      if (pick) setState(() => _locked = int.tryParse(response));
      widget.onAnswer?.call(response, null, null);
      return;
    }
    // The card does not turn yet: how sure, or why, comes first. The tap
    // is felt, and the option shows taken, before anything else moves.
    if (pick) HapticFeedback.lightImpact();
    setState(() {
      _pending = response;
      if (pick) _locked = int.tryParse(response);
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _lock.value = 1;
    } else {
      _lock.forward(from: 0);
    }
  }

  void _finish(int confidence) {
    final response = _pending;
    if (response == null || _level != null) return;
    setState(() => _level = confidence);
    widget.onAnswer?.call(response, confidence, null);
  }

  /// The ungraded path. Nothing here can be scored, so what is asked for is
  /// the reason — written down before the other side is shown, so it cannot
  /// be quietly rewritten to agree with whatever comes next.
  void _finishReason(String reason) {
    final response = _pending;
    if (response == null || _sent) return;
    _sent = true;
    widget.onAnswer?.call(response, null, reason);
  }

  /// The gap above the line under the input, and the least room that line
  /// keeps at the foot when the card's save and share are in the corner:
  /// they reach 33 points up into the face (15 + 44 less its padding of
  /// 26), and the input stays four clear of them.
  static const double _footGap = 14;
  static const double _cornerClear = 37;

  /// The largest the question is set on a face [width] wide: a short
  /// question set as large as a poster's line, so it fills the card rather
  /// than leaving a band of empty colour above its answers. It used to stop
  /// at 28, the size a drawn card's question keeps to beside its drawing; a
  /// card with no drawing has its question for a picture.
  static double _questionMax(double width) => (width * 0.16).clamp(40.0, 56.0);

  /// The nudge's row, and the gap above it.
  static const double _hintGap = 4;
  static const double _hintRow = 44;

  static TextStyle _questionStyle(Pill pill, double size) => AppText.display(
    size: size,
    weight: FontWeight.w600,
    height: 1.14,
    spacing: -0.3 - size * 0.018,
    color: pill.ink,
  );

  static TextStyle _promptStyle(Pill pill) => AppText.body(
    size: 12.5,
    weight: FontWeight.w500,
    color: pill.ink.withValues(alpha: 0.55),
  );

  /// The line under the input, before the reader has answered, or once
  /// they have ([answered]).
  String _prompt(BuildContext context, {bool? answered}) {
    final pill = widget.pill;
    return (answered ?? _pending != null)
        ? (pill.isGraded
              ? context.l10n.beingRightMattersLess
              : context.l10n.writeItBeforeTheirs)
        // Nowhere to commit means this is a re-read, and telling someone to
        // commit to a card they answered days ago is just wrong. It used to
        // also tell an unanswered one to go and answer it on Today — which
        // the cards sitting behind the top of today's own deck were saying,
        // on Today, about themselves.
        : widget.onAnswer == null && widget.given != null
        ? context.l10n.youAnsweredThisOne
        : widget.prompt ??
              context.l10n.commitBeforeYouTurn(
                context.l10n.difficultyLabel(pill.difficulty.name),
              );
  }

  /// How tall the input is, or the step that takes its place once the
  /// reader has answered, whichever is taller: the question is sized once,
  /// and does not jump when the step comes. Under a pick the step comes
  /// below the option taken, which stays.
  double _inputHeight(BuildContext context, double width, TextScaler scaler) {
    final pill = widget.pill;
    // The option the reader took, marked as theirs on a card read again.
    final int? taken = widget.onAnswer == null
        ? int.tryParse(widget.given?.response ?? '')
        : null;
    final List<String>? options = widget.options;
    final double input = options != null
        ? _PickGroup.heightFor(context, options, width, scaler, taken: taken)
        : switch (pill.challenge) {
            TypeNumber() => 54,
            Estimate() => PlaceItInput.heightFor(scaler),
            _ => 0,
          };
    final double step =
        (options == null
            ? 0
            : _PickGroup.keptHeightFor(context, options, width, scaler) +
                  _PickGroup.stepGap) +
        (pill.isGraded
            ? _ConfidenceStep.heightFor(context, width, scaler)
            : _ReasonStep.heightFor(scaler));
    return math.max(input, step);
  }

  /// The gap above the line under the input: wide enough, where the card's
  /// save and share are in the corner, that nothing above it reaches them.
  double _footGapFor(double promptHeight) => widget.corner
      ? math.max(_footGap, _cornerClear - promptHeight)
      : _footGap;

  /// How tall the question may be.
  ///
  /// All the face the answers leave it: the question at the top, set as
  /// large as that holds, and the answers at the foot, by the thumb, with
  /// the line under them. A share of the face (48%, as it was) left a band
  /// of empty colour under two answers, and a card is full. Unless what
  /// goes under it needs the room: on a small phone a three-answer card
  /// pushed the last answer under the card's save and share, where a tap on
  /// it saved the card. The question gives way first, down to what it needs
  /// at its smallest size, because a question set smaller is still read,
  /// and an answer under a button is not. A face shorter than 520 points
  /// starts from 40%.
  double _questionRoom(
    BuildContext context,
    BoxConstraints box,
    double promptHeight,
  ) {
    final double height = box.maxHeight;
    final double width = box.maxWidth;
    if (!height.isFinite || !width.isFinite) return 0;
    final pill = widget.pill;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double share = height * (height < 520 ? 0.40 : 0.48);
    double below =
        22 +
        _inputHeight(context, width, scaler) +
        _footGapFor(promptHeight) +
        promptHeight;
    if (pill.hasHint) below += _hintGap + _hintRow;
    // At its smallest, as drawn: ScaledText never sets it smaller.
    final double needed =
        _measure(
          context,
          pill.question,
          _questionStyle(pill, 18),
          width,
          TextScaler.noScaling,
        ) +
        2;
    return math.max(height - below, math.min(needed, share));
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final TextScaler scaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final String prompt = _prompt(context);
        final double promptWidth =
            constraints.maxWidth - (widget.corner ? _CardControl.room : 0);
        final double promptHeight = _measure(
          context,
          prompt,
          _promptStyle(pill),
          promptWidth,
          scaler,
        );
        // The question is sized for the taller of the two lines the input
        // has under it, before the answer and after, on a card that asks
        // before it turns: it never moves when the reader answers.
        final bool asks = !pill.isGraded || SureAsk.of(pill);
        final double promptRoom = widget.onAnswer == null || !asks
            ? promptHeight
            : math.max(
                promptHeight,
                _measure(
                  context,
                  _prompt(context, answered: _pending == null),
                  _promptStyle(pill),
                  promptWidth,
                  scaler,
                ),
              );
        final List<String>? options = widget.options;
        final Widget? step = _pending == null
            ? null
            : pill.isGraded
            ? _ConfidenceStep(
                pill: pill,
                chosen: _level,
                onPick: _level == null ? _finish : null,
              )
            : _ReasonStep(pill: pill, onSubmit: _finishReason);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The question takes what the answers leave it (see
                // [_questionRoom]), set as large as that will hold, up to a
                // poster's line ([_questionMax]); the answers come at the
                // foot.
                SizedBox(
                  height: _questionRoom(context, constraints, promptRoom),
                  child: ScaledText(
                    text: pill.question,
                    min: 18,
                    max: _questionMax(constraints.maxWidth),
                    // Where a short one leaves room even so, it stands a
                    // little above the middle of it, not hung from the top.
                    alignment: const Alignment(-1, -0.3),
                    styleFor: (size) => _questionStyle(pill, size),
                  ),
                ),
                const SizedBox(height: 22),
                if (options != null)
                  _PickGroup(
                    pill: pill,
                    options: options,
                    onPick: widget.onAnswer == null ? null : _commit,
                    taken: widget.onAnswer == null
                        ? int.tryParse(widget.given?.response ?? '')
                        : null,
                    locked: _locked,
                    fold: _lock,
                    step: step,
                  )
                else if (step == null)
                  widget.input!(widget.onAnswer == null ? null : _commit)
                else
                  step,
                if (pill.hasHint && options == null && _pending == null)
                  _hint(context),
                // Under a pick the nudge goes with the options the step
                // takes the place of, and is pressed no more once one is
                // taken.
                if (pill.hasHint && options != null)
                  AnimatedBuilder(
                    animation: _lock,
                    builder: (context, child) {
                      final double gone = _pending == null
                          ? 0
                          : _PickGroup.foldOf(_lock.value);
                      if (gone >= 1) return const SizedBox.shrink();
                      return IgnorePointer(
                        ignoring: _locked != null,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topLeft,
                            heightFactor: 1 - gone,
                            child: Opacity(opacity: 1 - gone, child: child),
                          ),
                        ),
                      );
                    },
                    child: _hint(context),
                  ),
                SizedBox(height: _footGapFor(promptHeight)),
                // Kept clear of the corner where the card's save and share
                // sit, so the line wraps rather than running under them.
                Padding(
                  padding: EdgeInsets.only(
                    right: widget.corner ? _CardControl.room : 0,
                  ),
                  child: Text(prompt, style: _promptStyle(pill)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The nudge, under the input: a line to tap, then the hint itself.
  Widget _hint(BuildContext context) {
    final pill = widget.pill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _hintGap),
        if (_hintOpen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            decoration: BoxDecoration(
              color: pill.wash,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HINT',
                  style: AppText.label(
                    size: 10.5,
                    spacing: 1.2,
                    color: pill.ink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pill.hint,
                  style: AppText.body(
                    size: 14,
                    height: 1.4,
                    color: pill.ink.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          )
        else
          // The words are the size of the line under the input; the target
          // round them is a finger's.
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _hintOpen = true);
                // Asked for help: a card that needed a hint sat above the
                // reader, and the dealer can hear that.
                Analytics.capture('hint shown', {
                  'pill_id': widget.pill.id,
                  'topic': widget.pill.topic,
                });
                CardRead.of(context)?.hinted();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _hintRow),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15,
                        color: pill.ink.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        context.l10n.giveMeANudge,
                        style: AppText.body(
                          size: 13,
                          weight: FontWeight.w500,
                          color: pill.ink.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The options of a pick, one tap each, the answer the option's index; and
/// what becomes of them once one is taken.
///
/// The one tapped is filled with the card's ink and ticked the instant it
/// is, and the others dim at once and are pressed no more: the reader sees
/// at once what was taken. A card that turns at once turns with it so. One
/// that asks first (how sure, or on a debate why) folds the others away
/// while the step comes in under the option kept, which stays filled to the
/// end: true or false, said once, is never left unsaid.
class _PickGroup extends StatelessWidget {
  final Pill pill;
  final List<String> options;
  final ValueChanged<String>? onPick;

  /// Which option was taken, on a card being re-read rather than answered.
  final int? taken;

  /// The option just tapped, locked in.
  final int? locked;

  /// From the tap on, 0 to 1 over [lockTime]: see [foldOf].
  final Animation<double> fold;

  /// What comes under the option kept, once the card asks before it turns:
  /// how sure, or why.
  final Widget? step;

  const _PickGroup({
    required this.pill,
    required this.options,
    required this.onPick,
    required this.fold,
    this.taken,
    this.locked,
    this.step,
  });

  /// From the tap until the step is in.
  static const Duration lockTime = Duration(milliseconds: 440);

  /// How far the others have folded away and the step come in, at [t] of
  /// [lockTime]: nothing for its first part, while the option taken fills
  /// and the others dim, where the eye is; then as one smooth move.
  static double foldOf(double t) => t >= 1
      // Exactly done at the end, so what has folded away leaves the page
      // (1 - 0.32, divided by 0.68, comes short of 1).
      ? 1
      : Curves.easeInOutCubic.transform(((t - 0.32) / 0.68).clamp(0.0, 1.0));

  /// Between one option and the next.
  static const double _gap = 10;

  /// Between the option kept and the step under it.
  static const double stepGap = 12;

  /// How tall the options set at [width], as [_ChoiceButton] lays them:
  /// each one's words, its padding and its edge, and the gap between. The
  /// option a reader took ([taken], on a card read again) sets its words
  /// firmer, inside a firmer edge, beside the word that marks it theirs:
  /// measured as one that was not, it wrapped where it had been counted on
  /// one line, and the answers ran down under the card's save and share.
  static double heightFor(
    BuildContext context,
    List<String> options,
    double width,
    TextScaler scaler, {
    int? taken,
  }) {
    double total = 0;
    for (int i = 0; i < options.length; i++) {
      final bool own = i == taken;
      final double edge = own
          ? _ChoiceButton.takenEdgeWidth
          : _ChoiceButton.edgeWidth;
      final double words =
          width -
          2 * (_ChoiceButton.padX + edge) -
          (own
              ? _ChoiceButton.tagGap + _ChoiceButton.tagWidth(context, scaler)
              : 0);
      total +=
          _measure(
            context,
            options[i],
            _ChoiceButton.labelStyle(const Color(0xFF000000), own),
            words,
            scaler,
          ) +
          2 * (_ChoiceButton.padY + edge);
      if (i > 0) total += _gap;
    }
    return total;
  }

  /// The tallest any option sets as the one kept: its words firmer, beside
  /// the tick.
  static double keptHeightFor(
    BuildContext context,
    List<String> options,
    double width,
    TextScaler scaler,
  ) {
    const double edge = _ChoiceButton.edgeWidth;
    final double words =
        width -
        2 * (_ChoiceButton.padX + edge) -
        _ChoiceButton.tagGap -
        _ChoiceButton.tick;
    double most = 0;
    for (final String option in options) {
      most = math.max(
        most,
        _measure(
              context,
              option,
              _ChoiceButton.labelStyle(const Color(0xFF000000), true),
              words,
              scaler,
            ) +
            2 * (_ChoiceButton.padY + edge),
      );
    }
    return most;
  }

  /// [child] shown to [height] of its own, from its top, and at [fade];
  /// against the start of the card, where the option kept stands, however
  /// narrow it sets (levels that wrap were centred, an indent of their own).
  static Widget _part(Widget child, double height, double fade) => ClipRect(
    child: Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: height.clamp(0.0, 1.0),
      child: Opacity(opacity: fade.clamp(0.0, 1.0), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final int? kept = locked;
    return AnimatedBuilder(
      animation: fold,
      builder: (context, _) {
        final double f = step == null ? 0 : foldOf(fold.value);
        final List<Widget> rows = [];
        for (int i = 0; i < options.length; i++) {
          final bool other = kept != null && i != kept;
          // Folded away for good: gone from the page.
          if (other && f >= 1) continue;
          final bool last = i == options.length - 1;
          Widget row = _ChoiceButton(
            label: options[i],
            ink: pill.ink,
            fill: pill.wash,
            edge: pill.washEdge,
            ground: pill.color,
            taken: onPick == null && taken == i,
            locked: i == kept,
            dimmed: other,
            onTap: onPick == null || kept != null ? null : () => onPick!('$i'),
          );
          // The gap under it goes with it; under the one kept, it goes as
          // the step comes, which brings its own.
          final double gap = last ? 0 : (i == kept ? _gap * (1 - f) : _gap);
          row = Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: row,
          );
          rows.add(other ? _part(row, 1 - f, 1 - f) : row);
        }
        if (step case final Widget step when f > 0) {
          rows.add(
            _part(
              Padding(
                padding: const EdgeInsets.only(top: stepGap),
                child: step,
              ),
              f,
              (f - 0.2) / 0.8,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Gives under the finger the instant it is touched, before the tap is even
/// a tap, and comes back with a little spring when let go: the press every
/// option and level of how sure has, on a card and in the card kit alike
/// (docs/cards/kit/astute-card.js, kit-took).
class _Press extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _Press({required this.onTap, required this.child});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.onTap != null;
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: live ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.965 : 1,
          duration: still
              ? Duration.zero
              : Duration(milliseconds: _down ? 70 : 280),
          curve: _down ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

/// The tick at the end of what was just taken, coming in with a small pop.
class _Tick extends StatelessWidget {
  final Color color;
  final double size;

  const _Tick({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final Widget icon = Icon(Icons.check_rounded, size: size, color: color);
    if (MediaQuery.disableAnimationsOf(context)) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: ((v - 0.4) / 0.6).clamp(0.0, 1.0),
        child: Transform.scale(scale: v, child: child),
      ),
      child: icon,
    );
  }
}

/// Type the number you worked out. Nothing is graded until you commit, and an
/// empty box will not commit.
class _NumberInput extends StatefulWidget {
  final Pill pill;
  final String unit;
  final ValueChanged<String>? onAnswer;

  const _NumberInput({
    required this.pill,
    required this.unit,
    required this.onAnswer,
  });

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  /// The least width the hint is shown in: what the longest of its
  /// translations takes at the hint's size, with a little over.
  static const double _hintRoom = 104;

  final _controller = TextEditingController();

  /// How long the typed answer was a keystroke ago.
  int _typed = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// What was typed, read the way the reader's language writes numbers.
  String? get _reading => TypeNumber.read(
    _controller.text,
    locale: Localizations.localeOf(context).toString(),
  );

  bool get _ready => _reading != null;

  /// Digits taken back are the reader changing their mind before they
  /// commit — counted, never read: what was typed stays here.
  void _edited(String text) {
    final CardRead? read = CardRead.of(context);
    read?.changeable();
    if (text.length < _typed) read?.changed();
    _typed = text.length;
    setState(() {});
  }

  /// Kept in plain form, so the answer is graded the same way whatever
  /// language the reader typed it in.
  void _submit() {
    final String? reading = _reading;
    if (reading == null || widget.onAnswer == null) return;
    widget.onAnswer!(reading);
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final unit = widget.unit;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: pill.wash,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pill.washEdge),
            ),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, room) => TextField(
                      controller: _controller,
                      onChanged: _edited,
                      onSubmitted: (_) => _submit(),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      style: AppText.display(
                        size: 22,
                        weight: FontWeight.w600,
                        color: pill.ink,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        // A hint only where it fits. Beside a long unit on
                        // a narrow phone the field is a few digits wide,
                        // and a hint cut short says less than none — the
                        // unit beside it already says what to type.
                        hintText: room.maxWidth >= _hintRoom
                            ? context.l10n.yourAnswer
                            : null,
                        hintStyle: AppText.body(
                          size: 14,
                          color: pill.ink.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                if (unit.isNotEmpty)
                  // Capped, because the unit is written with the card and the
                  // row is not. Most are a word — "days", "codes" — but a
                  // Fermi estimate counts "million journeys", and at a large
                  // text size, in a wide face, or on a narrow phone that is a
                  // label long enough to push the field it labels off the
                  // card. It gives up its own tail first.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 84),
                    child: Text(
                      unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 14,
                        color: pill.ink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: context.l10n.checkMyAnswer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submit,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _ready ? 1 : 0.35,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: pill.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: pill.color,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Color ink;
  final Color fill;
  final Color edge;

  /// The card's own colour: the words of the option just taken, set on its
  /// ink.
  final Color ground;
  final VoidCallback? onTap;

  /// True on the option this reader took, when the card is being looked at
  /// again rather than answered. Coming back to a question you have already
  /// answered and not being shown your own answer is the whole of what makes
  /// a re-read feel broken.
  final bool taken;

  /// True on the option just tapped: filled with the card's ink the instant
  /// it is, its words in the card's colour, a tick at its end.
  final bool locked;

  /// True on the options not taken, once one is: they dim at once.
  final bool dimmed;

  const _ChoiceButton({
    required this.label,
    required this.ink,
    required this.fill,
    required this.edge,
    required this.ground,
    required this.onTap,
    this.taken = false,
    this.locked = false,
    this.dimmed = false,
  });

  static TextStyle labelStyle(Color ink, bool taken) => AppText.body(
    size: 15.5,
    weight: taken ? FontWeight.w600 : FontWeight.w500,
    height: 1.35,
    color: ink,
  );

  /// The room round its words, inside its edge.
  static const double padX = 18, padY = 16;

  /// Its edge, and the firmer one round the option a reader took.
  static const double edgeWidth = 1, takenEdgeWidth = 1.6;

  /// Between the words and the word that marks the reader's own, or the
  /// tick of the option just taken.
  static const double tagGap = 10;

  /// The tick's size.
  static const double tick = 20;

  static TextStyle tagStyle(Color ink) =>
      AppText.label(size: 9, spacing: 1, color: ink.withValues(alpha: 0.6));

  /// How wide the word that marks the reader's own option sets.
  static double tagWidth(BuildContext context, TextScaler scaler) {
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: 'YOURS',
        style: DefaultTextStyle.of(context).style
            .merge(tagStyle(const Color(0xFF000000))),
      ),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final double w = p.width;
    p.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final Color words = locked ? ground : ink;
    return Semantics(
      button: onTap != null,
      selected: taken || locked,
      child: AnimatedOpacity(
        opacity: dimmed ? 0.32 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: _Press(
          onTap: onTap,
          // Filled at once, not faded in: a key that is down is down.
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: padX,
              vertical: padY,
            ),
            decoration: BoxDecoration(
              color: locked ? ink : fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: locked
                    ? ink
                    : taken
                    ? ink.withValues(alpha: 0.55)
                    : edge,
                width: taken ? takenEdgeWidth : edgeWidth,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: labelStyle(words, taken || locked)),
                ),
                if (locked) ...[
                  const SizedBox(width: tagGap),
                  _Tick(color: words, size: tick),
                ],
                if (taken) ...[
                  const SizedBox(width: tagGap),
                  Text('YOURS', style: tagStyle(ink)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The step between answering and finding out: how sure are you?
///
/// This is the part that makes the app worth keeping. Being right is a fact
/// about one card; knowing how often you are right is a fact about you.
///
/// The five levels stand in one row, each as wide as the others, where five
/// fit, as the card kit sets them (docs/cards/kit/astute-card.css, .sure):
/// three and two, the second row ragged, left a hole on the right of the
/// card. Where they do not fit, at a large text size, they wrap.
class _ConfidenceStep extends StatelessWidget {
  final Pill pill;

  /// The level just tapped: filled with the card's ink, the others dimmed,
  /// while the card turns.
  final int? chosen;

  /// Null once a level is chosen: nothing more is taken.
  final ValueChanged<int>? onPick;

  const _ConfidenceStep({
    required this.pill,
    required this.onPick,
    this.chosen,
  });

  static TextStyle _chip(Color color) =>
      AppText.body(size: 15, weight: FontWeight.w600, color: color);

  /// Between one level and the next.
  static const double _gap = 8;

  /// How wide [level] sets.
  static double _wordsWidth(
    BuildContext context,
    int level,
    TextScaler scaler,
  ) {
    final TextPainter p = TextPainter(
      text: TextSpan(
        text: '$level%',
        style: DefaultTextStyle.of(context).style
            .merge(_chip(const Color(0xFF000000))),
      ),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final double w = p.width;
    p.dispose();
    return w;
  }

  /// Whether the levels stand in one row at [width]: each as wide as the
  /// others, with room either side of its words. Six points a side, as the
  /// kit's row keeps none of its own: at twenty, a 375-point phone broke the
  /// five into three and two, with a hole on the right of the card.
  static bool oneRow(BuildContext context, double width, TextScaler scaler) {
    final int n = kConfidenceLevels.length;
    final double each = (width - _gap * (n - 1)) / n;
    double widest = 0;
    for (final int level in kConfidenceLevels) {
      widest = math.max(widest, _wordsWidth(context, level, scaler));
    }
    return widest + 12 <= each;
  }

  /// How tall the step sets at [width]: the question, and the levels in a
  /// row, or as they wrap.
  static double heightFor(
    BuildContext context,
    double width,
    TextScaler scaler,
  ) {
    final double chipHeight =
        _measure(
          context,
          '90%',
          _chip(const Color(0xFF000000)),
          width,
          scaler,
        ) +
        28;
    int rows = 1;
    if (!oneRow(context, width, scaler)) {
      double row = 0;
      for (final int level in kConfidenceLevels) {
        final double w = _wordsWidth(context, level, scaler) + 38;
        if (row > 0 && row + 9 + w > width) {
          rows++;
          row = w;
        } else {
          row += (row > 0 ? 9 : 0) + w;
        }
      }
    }
    return _measure(
          context,
          context.l10n.howSureAreYou,
          AppText.display(size: 19, weight: FontWeight.w600, spacing: -0.4),
          width,
          scaler,
        ) +
        14 +
        rows * chipHeight +
        (rows - 1) * 9;
  }

  /// A level: [padX] either side of its words where it sets its own width
  /// (wrapped), none where a row of equal ones gives it its width.
  Widget _level(BuildContext context, int level, {double padX = 18}) {
    final bool on = chosen == level;
    return Semantics(
      button: onPick != null,
      selected: on,
      label: context.l10n.percentSure(level),
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: chosen != null && !on ? 0.32 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 140),
        child: _Press(
          onTap: onPick == null ? null : () => onPick!(level),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padX, vertical: 13),
            alignment: padX == 0 ? Alignment.center : null,
            decoration: BoxDecoration(
              color: on ? pill.ink : pill.wash,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: on ? pill.ink : pill.washEdge),
            ),
            child: Text(
              '$level%',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: _chip(on ? pill.color : pill.ink),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final bool row = oneRow(
          context,
          box.maxWidth,
          MediaQuery.textScalerOf(context),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.howSureAreYou,
              style: AppText.display(
                size: 19,
                weight: FontWeight.w600,
                spacing: -0.4,
                color: pill.ink,
              ),
            ),
            const SizedBox(height: 14),
            if (row)
              Row(
                children: [
                  for (int i = 0; i < kConfidenceLevels.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: _level(context, kConfidenceLevels[i], padX: 0),
                    ),
                  ],
                ],
              )
            else
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final int level in kConfidenceLevels)
                    _level(context, level),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// The ungraded card's second step: one line saying why, before the other
/// side is shown.
///
/// Skipping is allowed. A reader who is made to type before they are allowed
/// to turn the card over stops turning cards over.
class _ReasonStep extends StatefulWidget {
  final Pill pill;
  final ValueChanged<String> onSubmit;

  const _ReasonStep({required this.pill, required this.onSubmit});

  /// About how tall the step sets: the line asking why, two lines to write
  /// in, and the button.
  static double heightFor(TextScaler scaler) =>
      scaler.scale(14.5) * 1.3 +
      10 +
      scaler.scale(14.5) * 1.35 * 2 +
      24 +
      10 +
      46;

  @override
  State<_ReasonStep> createState() => _ReasonStepState();
}

class _ReasonStepState extends State<_ReasonStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = widget.pill;
    final ink = pill.ink;
    final written = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.inOneLineWhy,
          style: AppText.body(
            size: 14.5,
            weight: FontWeight.w600,
            color: ink.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          decoration: BoxDecoration(
            color: pill.wash,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            maxLines: 2,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.body(size: 14.5, height: 1.35, color: ink),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: context.l10n.because,
              hintStyle: AppText.body(
                size: 14.5,
                color: ink.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSubmit(_controller.text.trim()),
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ink,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              written
                  ? context.l10n.nowShowMeTheOtherSide
                  : context.l10n.skipShowMeAnyway,
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: pill.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// What the reader committed to on an ungraded card, held next to what they
/// are about to read. Nothing is marked right: the point is that the line
/// they wrote is still visible while the other side makes its case.
class _YourLine extends StatelessWidget {
  final Pill pill;
  final Answer given;

  /// The side and the reason run together in one paragraph, for a back
  /// short of room.
  final bool short;
  const _YourLine({
    required this.pill,
    required this.given,
    this.short = false,
  });

  /// Set off by a rule down its left edge rather than boxed: it is the
  /// reader's own voice quoted back, and the one box on the back belongs to
  /// the line to keep.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(13, 2, 0, 2);
  static const double _rule = 2;

  static TextStyle _label(Color ink) =>
      AppText.label(size: 10, spacing: 1.3, color: ink.withValues(alpha: 0.55));
  static TextStyle _took(Color ink) =>
      AppText.body(size: 15, weight: FontWeight.w600, height: 1.3, color: ink);
  static TextStyle _reason(Color ink) =>
      AppText.body(size: 13.5, height: 1.4, color: ink.withValues(alpha: 0.75));

  /// How far the reader leant to the side, when it was leant to on a shelf
  /// rather than tapped: "firmly", "all the way".
  static String? _how(BuildContext context, Pill pill, Answer given) {
    final int? level = pill.isGraded ? null : leanLevel(given);
    return level == null ? null : context.l10n.leanHow('$level');
  }

  /// The side taken, run in after its label: one line where two would
  /// say no more.
  static TextSpan _tookSpan(
    String caps,
    Pill pill,
    Answer given, {
    String? how,
    bool short = false,
  }) => TextSpan(
    children: [
      TextSpan(text: '$caps  ', style: _label(pill.ink)),
      TextSpan(
        text: how == null
            ? pill.challenge.describe(given.response)
            : '${pill.challenge.describe(given.response)} · $how',
        style: _took(pill.ink),
      ),
      if (short && given.hasReason)
        TextSpan(text: '  "${given.reason!.trim()}"', style: _reason(pill.ink)),
    ],
  );

  /// The room the line takes at [width].
  static double heightFor(
    BuildContext context,
    Pill pill,
    Answer given,
    double width,
    TextScaler scaler, {
    bool short = false,
  }) {
    final inner = width - _padding.horizontal - _rule;
    double h(String text, TextStyle style) =>
        _measure(context, text, style, inner, scaler);

    final took = _measureSpan(
      context,
      _tookSpan(
        context.l10n.youTookCaps,
        pill,
        given,
        how: _how(context, pill, given),
        short: short,
      ),
      inner,
      scaler,
    );
    var total = _padding.vertical + took;
    if (given.hasReason && !short) {
      total += 6 + h('"${given.reason!.trim()}"', _reason(pill.ink));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ink = pill.ink;
    return Container(
      width: double.infinity,
      padding: _padding,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: ink.withValues(alpha: 0.45), width: _rule),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            _tookSpan(
              context.l10n.youTookCaps,
              pill,
              given,
              how: _how(context, pill, given),
              short: short,
            ),
          ),
          if (given.hasReason && !short) ...[
            const SizedBox(height: 6),
            Text('"${given.reason!.trim()}"', style: _reason(ink)),
          ],
        ],
      ),
    );
  }
}

/// The room the save and share take in a card's bottom corner, inside the
/// face's padding: what a free card's page keeps clear (the kit's foot
/// leaves it empty; see `--kit-corner-w` in docs/cards/kit/astute-card.css).
const Size kCardCorner = Size(_CardControl.room, _AskFaceState._cornerClear);

/// A control drawn on the card, in the card's own ink.
class _CardControl extends StatelessWidget {
  const _CardControl({
    required this.label,
    required this.icon,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color ink;
  final VoidCallback onTap;

  /// Where the pair sits from the card's corner, and the room the line
  /// beside it keeps clear inside the face's padding: the pair reaches 81
  /// points into it (17 + 44 + 4 + 44, less the padding of 28).
  static const double right = 17;
  static const double bottom = 15;
  static const double size = 44;
  static const double room = 88;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Icon(icon, size: 20, color: ink.withValues(alpha: 0.62)),
          ),
        ),
      ),
    );
  }
}
