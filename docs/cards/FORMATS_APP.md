# Card formats in the app

The HTML prototypes in `prototipi/` show what a card can be. They can't ship as
they are: the app is Flutter, and one-off code per card doesn't scale to
thousands of cards. So each idea that works becomes a **format**: one Flutter
widget, driven by a few fields of data in the card's `scene`. After that, a card
of that format is just data. A writer fills in the fields; no code is needed.

| `scene.type` | Name | What the reader does | Where it came from |
|---|---|---|---|
| `slider` | Move it and watch | Drags one quantity and watches another follow measured points | round 3 |
| `count` | Bet the number | Bets on an order of magnitude, then a giant number counts up and a field of dots makes the quantity visible | glass of water, Apollo bill (round 5) |
| `draw` | Draw it | Draws the line they expect on a chart, then the real one draws itself over it | best wards, AI growth |
| `sort` | Sort the pile | Swipes a short deck of items into two piles (alive / dead, myth / fact); each gets a one-line verdict | Swift's words |
| `timeline` | Place it in time | Drags events onto a timeline, then the real years slide in | memory sliders (round 4) |
| `hold` | Hold for it | Holds a finger for as long as they think something lasts, then sees the real duration | shot length |
| `rank` | Put them in order | Orders a few items by a quantity, then bars grow to the true values | — |
| `sample` | Grow the sample | Grows a random sample step by step and watches a pattern appear, then dissolve | dates of death |

The model for each lives in `lib/models/scenes/<type>.dart`, the widget in
`lib/widgets/scenes/<type>_view.dart`, the data rules in
`tool/cards/scene_kinds/<type>.py`. Each file's header documents its JSON fields.

## Second wave: formats built around the app's purpose

| `scene.type` | Name | What the reader does | Why it serves the purpose |
|---|---|---|---|
| `trick` | Spot the trick | Sees a chart, headline or offer that misleads, taps where the trick is, then watches it fixed | "They can't fool me any more" |
| `why` | Ask why | Taps "and why?" down a ladder of causes until the real one | "Ah, that's why" |
| `poll` | You first | Answers for themself, then sees how others and the research answered, and why people split | "That's me" |
| `story` | What happens next? | Taps through a real case in scenes, stops to predict the outcome, then sees it | Prediction before explanation |
| `translate` | Translate it | Taps the phrases of a piece of jargon (a contract, a doctor's report, a politician) to read what they really mean | Not fooled by words |
| `match` | Match them | Pairs things up (a bias with its everyday trap, a cause with its effect) | Connecting the dots |
| `clues` | Guess from clues | Clues arrive one at a time; guessing early is worth more | Reasoning from evidence |
