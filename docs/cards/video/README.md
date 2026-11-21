# Video cards

A video card is a card that is a short film: drawn in its subject's colours
and the kit's type, it opens to the whole screen from its tile in Explore and
plays with a second tap (`lib/widgets/video_card.dart`). The cards there are
listed in `lib/data/video_cards.dart`; Explore shows them in the section of
block `video-cards` (`remote/explore.json`).

Each film is a page made with GSAP and the kit's fonts, set frame by frame in
Chromium and encoded once per language. Its folder holds the page in each
language (`src-<language>.html`) and the two scripts:

    cd docs/cards/video/eratosthenes
    node build.cjs src-en.html film-en.html
    HTML=film-en.html OUT=stills node render.cjs stills 1.7 4 20   # look first
    HTML=film-en.html OUT=frames-en node render.cjs frames
    ffmpeg -framerate 30 -i frames-en/f%04d.png -c:v libx264 -preset slow \
      -tune animation -crf 26 -pix_fmt yuv420p -movflags +faststart \
      ../../../../web/cards/video/eratosthenes-en.mp4

The film goes on the site (`web/cards/video/<file>-<language>.mp4`, fetched
when it is played); its frame at four seconds, the question whole over its
picture, goes in the app as its tile (`assets/video/<file>-<language>.webp`,
WebP at quality 88). The built page and the frames are not kept.

Every film keeps the bottom of its frame clear where the card lays its
controls: around 84% of the height on its first frame, for the way to play
it, and between its last picture and its source on its last frame, for the
way to watch it again.
