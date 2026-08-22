# Knowit

Five AI-written "pills" a day — bite-size facts across science, history, psychology,
economics, tech, weird facts, the human body, philosophy, pop culture, nature and
language — each with a **Bar move** line (the reason to bring it up) and a source.
Swipe sideways to move to the next pill, tap to flip and reveal the answer.

Design mixes the *full-bleed, one-colour-per-topic card* look with the *editorial
light chrome + tab bar* layout from the original Claude Design mockups.

## Live preview

Every push to `main` builds and deploys automatically to GitHub Pages:

**https://lorenzballe.github.io/knowit/**

(First deploy: in the repo, go to **Settings → Pages** and set **Source** to
**GitHub Actions** if it isn't already — after that every push publishes on its own.)

## Running locally

```sh
flutter pub get
flutter run -d chrome   # web
flutter run              # any connected device/simulator
```

## Project structure

```
lib/
  data/        topic palette + the pill content pool
  models/      Pill
  state/       AppState — streak, saved pills, today's deck position (persisted)
  widgets/     the draggable card stack + card faces
  screens/     Today, Saved, Profile
```

## What's stubbed

`Knowit+` (the paywall) and push notifications are UI-only placeholders for now —
tapping them shows a "coming soon" message rather than doing anything.
