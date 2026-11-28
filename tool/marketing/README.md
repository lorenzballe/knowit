# A card a day, as a video

`card_video.cjs` turns one of Astute's drawn cards into a vertical video
for TikTok, Instagram Reels and YouTube Shorts: 1080 × 1920, H.264, about
20 to 25 seconds, without sound. Every video has the same five beats:

1. the card's question, alone on the night paper;
2. the card itself, played as a reader plays it, with a finger where it
   taps;
3. the answer the card ends on, held long enough to read;
4. the why in one line, with the card's source;
5. the same close every day: «Cinque così ogni mattina · Astute» (or
   "Five like this every morning · Astute") and where to get the app.

The card is the real page from the bank, drawn by the same kit the app
uses, so what people see in the video is what they get in the app.

## Making one

Once, on a computer with this repository: Node, Playwright with Chromium,
and ffmpeg (all already there in a Claude session).

```sh
node tool/marketing/card_video.cjs nature-half-mountain-tsunami --lang it --out ~/Videos/astute --frames
```

- The first word is the card's id: the name of its file in
  `tool/cards/bank/<subject>/`, without `.html`.
- `--lang it` asks for Italian. The video is always in the card's own
  language, so as long as the cards are in English the videos are too, and
  the tool says so; when a card is written in Italian, its video will be.
- `--out` is the folder the video goes in; `--frames` also saves a still of
  each beat beside it, to look at before posting.
- It takes about two minutes. The video is `<id>-<lang>.mp4`.

## One a day

1. **Pick the card.** Drawn cards only (the ones with an `.html` page and
   something to tap or drag). The best first: the opening of a new
   reader's first days, listed in `lib/data/first_days.dart`, then the
   rest. Never the same card twice; keep a list of the ones posted.
2. **Make it** with the line above, and look at the stills.
3. **Post it** on TikTok, Reels and Shorts, the same video on all three.
   - The caption: the card's question, then one line of your own, then
     where the card comes from (for example «Fonte: Geopop, YouTube»).
     Two or three plain hashtags at most: #curiosità #scienza.
   - The cover: the first second, the question.
   - Sound: the video has none. A quiet track from the app's own library is
     fine; nothing that talks over the question.
4. **Answer the comments** in the first hour: that is when the apps decide
   whether to show it to more people.

Posting at the same time every morning matters more than the time chosen.

## Notes

- The why and the source come from the card's file (`move` and `source`).
  A card whose source is a creator's video names that creator on screen
  and in the caption, always.
- The bottom fifth of the frame is left empty on purpose: TikTok, Reels and
  Shorts put their own buttons and captions there.
- Playwright's own video recorder records a page at its size in CSS pixels
  (366 × 606 for a card), too coarse for a 1080-wide video, and drops the
  frames where nothing moves. So the card is filmed a frame at a time on the
  page's own clock instead, sharp and complete however busy the computer is.
- No sound: the card kit has none of its own to add.
