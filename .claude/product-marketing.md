# Astute: product marketing context

Read by the marketing, ASO and growth skills (`mk-*`, `aso-*`, `rc-*`) before they ask
questions. Facts here come from the code and from the owner; anything marked
**TO CONFIRM** is a guess the owner has not checked yet. The full purpose, in Italian,
is `docs/cards/SCOPO.md` — it wins over this file.

## The product
- **Name:** Astute. Site: https://astutetheapp.com (web app at /app/, which does not sell
  Plus: the web sends people to the stores).
- **What it is:** five "smart pills" a day — short cards, often interactive (a game, a
  slider, a drawing, a story in scenes, a sound), each explaining the *why* of something
  and ending with what to keep. Like the expert who appears between cat videos and finally
  explains something properly (Geopop, Kurzgesagt, 3Blue1Brown).
- **Promise:** sharper, more critical, harder to fool — as if you had read many books
  and lived more, without doing it. You learn to ask yourself the right questions.
- **Subjects:** 20, from science, history, psychology, economics and thinking to art,
  music, food, the human body, pop culture and weird facts. Cards in English for now.
- **Personalisation:** deep — subjects, level, tone and format adapt to each reader.
- **Platforms:** iOS, Android (Flutter), web. Firebase backend.

## Who it is for
All ages. Typical readers:
1. People who **feel a bit behind** and want to catch up.
2. People who are **already sharp and want to get sharper**.
3. Adults scrolling Instagram/Facebook who **stop when an expert explains a why**.
4. **Curious teenagers** who would rather grow than scroll.
Shared wish: feel smarter, surer, less naive; have something to say.

## Jobs, pains, outcomes
- Job: "Give me a few minutes a day that leave me smarter, not emptier."
- Pains: doomscrolling guilt; feeling out of the loop; being fooled by charts, offers,
  headlines; books take too long.
- Outcomes after weeks: sees the trick in a chart, an offer, a headline; asks better
  questions about money, work, relationships; understands why the world is the way it is.

## Feelings each card must give (at least one)
"Ah, that's why!" · "That's me." · "Cool, I didn't know — and it's about me." ·
"Interesting point of view… what if it's true?" (and for beauty cards: "how beautiful").

## Differentiation
- Not trivia: every card has a real why and a real, visible source.
- Not text slides: each story told in its best form, often interactive; every card
  looks hand-made.
- Five a day, so each counts. Varied tones: never the same day twice.
- Competitors / references: Headway, Imprint, Blinkist, Brilliant, Elevate, Duolingo
  (habit), Geopop and similar creators. **TO CONFIRM** which the owner sees as main rivals.

## Pricing and subscription (from the code)
- **Astute+**: €3,99 / month (anchor) or **€29,99 / year** (preselected, ≈ €2,50 a month).
  No lifetime, no third tier.
- Yearly plan sold with a **14-day free trial**.
- RevenueCat entitlement `astuto_pro`, offering `default` (Annual, Monthly).
- iOS products `astuto_pro_year`, `astuto_pro`; Android `com.astuto.app.plus.yearly:yearly`,
  `com.astuto.app.plus.monthly:monthly`.
- **TO CONFIRM:** what free users get vs Plus.

## Brand voice
Sharp, warm, curious, never preachy or academic. Short sentences. Sometimes funny,
sometimes hard. Never "AI slop": no hype words, no empty superlatives. Type: Fraunces
(serif) over Figtree; each subject has its own bright colour.

## Channels and stage
- Solo founder, Italian. Pre-launch / early launch. **TO CONFIRM** dates.
- Planned: App Store, Google Play, the site, short videos and carousels made from the
  cards (the cards are the content), analytics in PostHog.
- Languages: app UI in 13 languages; cards English first.
