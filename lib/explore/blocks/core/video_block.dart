import 'package:flutter/material.dart';

import '../../../data/topics.dart' show topicKeyForName;
import '../../../data/video_cards.dart';
import '../../../widgets/video_card.dart';
import '../../explore_block.dart';
import 'layout.dart';

/// Video cards (lib/data/video_cards.dart): each a card that is a short
/// film. A tap on one opens it to the whole screen, a second tap plays it
/// (lib/widgets/video_card.dart).
///
/// One card is shown large, across the page, cut from the top of its first
/// frame, a little taller than wide; more than one go in a row, each as a
/// film is held, upright. On a subject's page, that subject's.
class VideoCardsBlock extends ExploreBlock with SectionLayout {
  const VideoCardsBlock();

  @override
  String get name => 'video-cards';

  @override
  Widget? build(
    BuildContext context,
    ExploreHost host,
    ExploreSection section,
  ) {
    final String? subject = host.subject;
    final List<VideoCard> cards = [
      for (final VideoCard card in kVideoCards)
        if (subject == null || _sameSubject(card.subject, subject)) card,
    ];
    if (cards.isEmpty) return null;
    final String language = host.language;
    void open(VideoCard card) {
      host.note(section, 'video opened', {'card': card.id});
      openVideoCard(context, card, language: language);
    }

    final Widget shown;
    if (cards.length == 1) {
      final VideoCard card = cards.single;
      shown = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(
          builder: (context, box) => SizedBox(
            width: box.maxWidth,
            // Five by six: the head, the question and its picture, the
            // film's own frame cut from the top above the ground.
            height: box.maxWidth * 6 / 5,
            child: VideoCardTile(
              card: card,
              language: language,
              onOpen: () => open(card),
            ),
          ),
        ),
      );
    } else {
      const double width = 200;
      shown = SizedBox(
        height: width / kFilmAspect,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => SizedBox(
            width: width,
            child: VideoCardTile(
              card: cards[i],
              language: language,
              onOpen: () => open(cards[i]),
            ),
          ),
        ),
      );
    }
    return SectionFrame(
      title: section.title(language),
      line: section.subtitle(language),
      child: shown,
    );
  }
}

/// Whether a card of subject [key] belongs on the page of the subject named
/// [page].
bool _sameSubject(String key, String page) =>
    (topicKeyForName(page) ?? page) == key;
