# Video cards

A video card is a card that is a short film: drawn in its subject's colours
and the kit's type, it opens to the whole screen from its tile in Explore and
plays at once, from the frame its tile shows (`lib/widgets/video_card.dart`).
Opened, the card is the screen: the film covers it from its top to its foot,
and the row with how far it has run and the cross is laid over the top of its
picture. On a tablet, which it cannot cover without cutting its words, it
stands whole under that row, a card of its own on the card's ground
(`ground` in `lib/data/video_cards.dart`). The cards there are listed in
`lib/data/video_cards.dart`; Explore shows them in the section of block
`video-cards` (`remote/explore.json`).

## The frame

A film is 1080 by 2340, a modern phone's nine by nineteen and a half, and
the app scales it to cover the screen, so a phone of another shape cuts it:
a shorter one at its foot, a wider one at its sides. The app keeps its head
just under its row of controls, so every film keeps to these lines
(`kFilmWords` in `lib/widgets/video_card.dart`):

- Above y 330, only the card's ground: the status bar and the row of
  controls stand there. The head starts at y 330.
- Every word (captions, labels, numbers, the source) stays between x 64 and
  1016 and above y 1990. Below and beside that, only drawing that runs on (the
  ground, the Earth, light), which a phone may cut.
- On the frame its tile shows and on its last, no words below y 1700: on the
  smallest phones the card lays the word that it needs a connection and the
  way to watch it again at the screen's foot, over that part of the film.

A tile shows the film's frame at `posterAt` (four seconds unless the card says
otherwise), across its width from y 248, a little above the head, cut at the
tile's foot; the film plays on from that moment when the card opens, so the
picture comes alive rather than starting over.

## Making a film

Each film is a page made with GSAP and the kit's fonts, set frame by frame in
Chromium and encoded once per language. Its folder holds the page in each
language (`src-<language>.html`) and the two scripts; the built page is not
kept, and no frame is written to the disk:

    cd docs/cards/video/eratosthenes
    node build.cjs src-en.html /tmp/film-en.html
    HTML=/tmp/film-en.html OUT=/tmp/stills node render.cjs stills 1 4 20  # look first
    HTML=/tmp/film-en.html node render.cjs film ../../../../web/cards/video/eratosthenes-en.mp4
    ffmpeg -i /tmp/stills/t04.00.png -c:v libwebp -quality 88 \
      -compression_level 6 ../../../../assets/video/eratosthenes-en.webp

The film goes on the site (`web/cards/video/<file>-<language>.mp4`, H.264 at
CRF 26, fetched when it is played); its frame at `posterAt` goes in the app as
its tile (`assets/video/<file>-<language>.webp`, WebP at quality 88).

To see the card as a phone shows it, opened over its film's frames, with the
phone's status bar, island or notch and home bar, and its tile in Explore:

    HTML=/tmp/film-en.html OUT=/tmp/stills node render.cjs stills 1 52.6
    flutter test tool/video_shots.dart --update-goldens \
      --dart-define=FRAMES=/tmp/stills [--dart-define=LANGUAGE=it]

The pictures land in `tool/shots/video/`.
