---
name: astute-cards
description: Create Astute cards the way the owner wants them — each one a small, beautiful, varied piece (game, slider, drawing, story, sound, one line…) built with the card kit, checked on three phones and judged before anyone sees it. Use whenever making, redesigning or reviewing Astute cards or card prototypes.
---

# Making Astute cards

Everything that decides what a good card is lives in `docs/cards/`. Read it before
writing anything; it wins over your own taste.

## 1. Read, in this order
1. `docs/cards/SCOPO.md`: why the app exists. Above every other rule.
2. `docs/cards/CRITERI.md`: the gates and the scores a card must pass.
3. `docs/cards/FORMATI.md`: the open catalogue of formats, and how to invent one.
4. `docs/cards/STILE.md`: what stays fixed, what may change, how a card speaks.
5. `docs/cards/ESEMPI.md`: the owner's verdicts. **Lesson 1: plain text cards are not enough.**
6. `docs/cards/ISPIRAZIONE.md` and the images in `docs/cards/ispirazione/`: the level to reach.
7. `docs/cards/kit/LIBRERIE.md`: the kit, the libraries, the colours, the checker.
8. The prototypes in `docs/cards/prototipi/`: what has been approved as the level.

## 1b. Design and motion skills to load as you build
These live in `.claude/skills/` (third-party, MIT/Apache, see `docs/cards/kit/SKILLS.md`).
They were written for web pages: use their taste and technique **inside the Astute card
frame**, never instead of it.
- `frontend-design`, `taste-taste-skill`: taste, typography, anti-generic rules. Load always.
- `taste-minimalist-skill`, `taste-soft-skill`, `taste-brutalist-skill`: three very different
  visual directions, so cards in a batch don't all look alike.
- `algorithmic-art`: generative art and particles (flow fields, seeded randomness).
- `hf-hyperframes-animation`, `hf-hyperframes-keyframes`, `hf-motion-graphics`: animation
  principles, easing, a catalogue of transitions and motion-graphics techniques.
- `dataviz` (built in): any chart or number shown as a picture.

## 2. Pick the stories
- Only stories with a real *why* that gives one of the feelings in SCOPO. No empty trivia.
- Sources must be real. If you cannot check a source, change the story.

## 3. Choose the form: ingenuity first
- Ask: **what is the most ingenious way to make this click?** Not the fastest to write.
- Invent a format when none fits. Mix formats.
- **Vary hard.** In one batch, no two cards share the same technique (particles, physics,
  3D, sketch, swipe, sound, drag, generative, branches, kinetic type, diagram with
  measures, simulation, draw-it, hotspots…) or the same layout. Vary tone too.

## 4. Build with the kit
- Start from `docs/cards/kit/template.html`, with `astute-card.css` and `astute-card.js`.
- Keep the Astute frame (subject colour, label, Fraunces and Figtree, source, no scroll).
- Draw at the card's real size (`Kit.fitSvg`, `Kit.fitCanvas`): text must never stretch.
- Register `Kit.play[cardId]` so the checker can play each card to its end state.

## 5. Check the graphics: never skip
1. `node tool/cards/card_check.cjs <page.html> <screenshot-dir>`. Fix until it reports all clear.
2. **Look at every screenshot yourself**, start and end state, on all three phones:
   alignment, overlapping or crooked text, tiny labels, empty bands, anything ugly.
   Fix and re-run.
3. Hand the screenshots to a separate critic agent, which scores each card with CRITERI.
   Below the bar, back to step 3.

## 6. Show and learn
- Publish the page for the owner. Cards are in English. Offer an Italian version for judging.
- Record every owner verdict, with the reason, in `docs/cards/ESEMPI.md`.
- Save approved pages in `docs/cards/prototipi/`.

## 7. Into the app
The app is Flutter. Each approved format is rebuilt once as a Flutter widget (see the
Flutter column in LIBRERIE.md); then cards of that format are data, written by any model.
