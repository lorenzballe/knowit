# Show HN

## Prima di pubblicare

- **L’app su iPhone.** Chi legge Hacker News usa soprattutto l’iPhone: un
  post con «solo Android» perde metà dei lettori al primo commento. Si
  pubblica quando Astute è sull’App Store, e la riga sull’iPhone qui sotto
  diventa vera.
- **Le email ai creatori, mandate prima.** Il post dice che molte carte
  nascono dai video di Geopop e Veritasium: devono saperlo da te, non da
  Hacker News (vedi `creator-geopop-it.md` e `creator-en.md`).
- **La versione nel browser funziona** su un computer, in Chrome e in
  Safari: https://astutetheapp.com/app/ è il link che quasi tutti
  apriranno.
- **Prezzo e prova** come sono in quel momento negli store (qui: 29,99 €
  l’anno, 14 giorni gratis).
- **Il testo va nel campo «text»**, il link in «url». Se Hacker News non
  mostra il testo in cima, incollalo come primo commento.
- **Una giornata libera.** Si pubblica da martedì a giovedì verso le 14 o
  le 15 italiane (le 8 o le 9 a New York) e si risponde ai commenti per sei ore,
  a tutti, anche ai più duri.
- **Mai chiedere voti** a nessuno: Hacker News li riconosce e affonda il
  post.

## Titolo (80 caratteri al massimo)

Show HN: Astute, five questions a day and a record of how sure you were

## Link

https://astutetheapp.com

## Testo

Hi HN. I made Astute, an app that gives you five cards every morning. Some of them ask a question, and before the card turns over you say how sure you are, from 50% to 90%. Then you get the answer, the reasoning and the source. After a few weeks your profile shows how often you were right at each level of confidence.

You can try it in the browser without an account: https://astutetheapp.com/app/ (it is the same Flutter app as the phone one). It is on Google Play and the App Store.

Some details:

- About 6,500 cards across 20 subjects. Around 900 are small drawings you play with: drop half of Etna into the sea and watch what reaches the far coast, or lengthen a straw until the air can no longer push the water up.
- An AI model writes the cards ahead of time, each from a named source. Most of the drawn ones start from science explainer videos (Geopop and Veritasium), usually with a link to the minute where the point is made. A second model reviews most cards, and anything it cannot confirm goes on a list for a person to check. Readers can flag a card; a card flagged enough stops being dealt until someone has checked it.
- The free plan is five cards a day (two picked for you, three at random from your subjects), plus Explore: today's challenge (five questions, the same for everyone), short estimation exercises, and a news digest with its sources. Astute+ is €29.99 a year with 14 days free: it picks all five at your level and shows your calibration week by week.
- No ads, and no account needed. Signing in only moves your record to a new phone.
- Built with Flutter, Firebase and RevenueCat. The drawn cards are HTML pages on a small kit, shown in a webview, so a new kind of card does not need an app release.

Two things I would like to know: whether saying how sure you are feels useful or like a chore, and whether the cards are pitched right, too easy or too obscure.
