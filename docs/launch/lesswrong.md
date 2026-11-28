# LessWrong, Metaculus, Good Judgment Open

Un post per chi si allena a prevedere e a stimare: LessWrong come post, e
lo stesso testo, accorciato, nei forum di Metaculus e di Good Judgment
Open.

## Prima di pubblicare

- **Un account con un po’ di storia** in quella comunità: su LessWrong i
  primi post passano dai moderatori, e un post che sembra pubblicità viene
  tolto. Qualche settimana di commenti veri, prima, cambia tutto. In
  alternativa, la prima volta, un commento nell’Open Thread del mese.
- **Le email ai creatori, mandate prima** (il post parla delle carte nate
  dai video).
- **La versione nel browser funziona** su un computer
  (https://astutetheapp.com/app/): quasi tutti leggono da lì.
- **Le risposte pronte** sui due punti deboli che il post stesso nomina: la
  scala che parte dal 50% e il punteggio che non usa la sicurezza. Qualcuno
  chiederà se li cambierai: decidi prima cosa rispondere.
- **Prezzo e prova** come sono quel giorno negli store.

## Titolo

A daily calibration workout with sources, and the parts I'm unsure about

## Testo

I've built an app, Astute, meant as a small daily calibration workout. I'm posting it here because this is the community most likely to tell me where the method is wrong.

Every morning it deals five cards from subjects you choose, twenty in all: science, history, economics, psychology and so on. About two in five ask something: pick one of a few answers, or estimate a number. Before the answer shows, you say how sure you are: 50, 60, 70, 80 or 90 percent. Then the card turns over with the answer, the reasoning, often the trap most people fall into, and a named source you can check.

Once there are enough answers, your profile sets each level of confidence against how often you were right at it ("you said 70%, you were right 63% of the time: 7 points overconfident"). The paid tier follows the same thing week by week. Two exercises aim at it more directly: one asks for a range around a numerical guess, and pays more the narrower the range if the answer falls inside it; the other has you stake points on an answer, doubled if you are right and lost if you are wrong.

General brain training does not seem to transfer to other tasks (Simons et al., 2016). Narrower training has better evidence behind it: training against specific biases has transferred to new problems (Morewedge et al., 2015; Sellier, Scopelliti and Morewedge, 2019), and in the Good Judgment Project a short training in probabilistic reasoning made forecasts about 10% more accurate (Mellers et al., 2014), although a re-analysis of the same data finds that effect shrinks, vanishes or even reverses once other variables are controlled (Hauenstein et al., 2025). None of that shows Astute does the same. I have no data on it yet, and with so few users I won't for a while.

Three parts of the design I'm unsure about:

- The scale starts at 50% even on questions with three options, where a blind guess is right a third of the time. It keeps the choice simple, but it pushes guesses into the lowest level and makes people look overconfident there.
- The score on the front page is an Elo-style rating of right and wrong answers against how hard each card is. Confidence does not enter it, and calibration is shown separately. A proper scoring rule, log or Brier, would reward honest confidence directly, at the cost of being harder to explain to people who have never heard of one.
- An AI model writes the cards from named sources; most of the drawn ones start from science explainer videos, usually with a link to the minute where the point is made. A second model reviews most cards and sends what it cannot confirm to a person. Readers can flag a card, and a flagged card stops being dealt until someone has checked it. For a tool about knowing how far to trust yourself, that is a lot of trust placed in a pipeline, and I would like to hear how you would audit it.

It is free on Android and iPhone, and in the browser without an account at https://astutetheapp.com/app/. There is a paid tier (€29.99 a year, with 14 days free); the calibration in the profile is free.

If you try it, the most useful thing you could tell me is where a card was wrong, or where its source does not say what the card says.

## Riferimenti, se qualcuno li chiede

- Simons, D. J. et al. (2016). Do "brain-training" programs work?
  *Psychological Science in the Public Interest*, 17(3), 103–186.
- Morewedge, C. K. et al. (2015). Debiasing decisions: Improved decision
  making with a single training intervention. *Policy Insights from the
  Behavioral and Brain Sciences*, 2(1), 129–140.
- Sellier, A.-L., Scopelliti, I. & Morewedge, C. K. (2019). Debiasing
  training improves decision making in the field. *Psychological Science*,
  30(9), 1371–1379.
- Mellers, B. et al. (2014). Psychological strategies for winning a
  geopolitical forecasting tournament. *Psychological Science*, 25(5),
  1106–1115.
- Hauenstein, C. E., Thomas, R. P., Illingworth, D. A. & Dougherty, M. R. P.
  (2025). Rethinking the role of teams and training in geopolitical
  forecasting: The effect of uncontrolled method variance on statistical
  conclusions. *Psychological Science*, 36(1), 3–18.
