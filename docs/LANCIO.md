# Il piano per il lancio (ottobre 2026)

> Dove siamo e cosa manca, in ordine. Si aggiorna man mano che le cose si fanno.

## Dove siamo
- **L'app è costruita:** onboarding, Oggi, Esplora con ricerca, Salvate, Profilo, percorso, amici, paywall, widget, promemoria, 13 lingue.
- **Abbonamenti:** RevenueCat collegato a iOS e Android (prodotti, offerta, entitlement `astuto_pro`, ripristino, prova gratuita).
- **Server:** Cloud Functions online, regole del database testate. Analisi con PostHog. Privacy, termini e supporto sul sito.
- **Carte:** 5.042 nella banca, ma quasi tutte "da leggere". 557 affermazioni ancora da verificare (`tool/cards/UNVERIFIED.md`).
- **Il nuovo livello di carte** (giochi, disegni, video, 3D) esiste come prototipo in `docs/cards/prototipi/`, non ancora nell'app.

## Cosa blocca l'uscita negli store, in ordine
1. **Android non si può pubblicare:** manca la chiave di firma (keystore), manca il flusso di build e caricamento su Play, mancano le impronte SHA in Firebase (senza, l'accesso con Google non funziona).
2. **Gli strumenti da sviluppatore** (`lib/debug_flags.dart`) sono accesi nelle build: vanno spenti con `--dart-define=DEBUG_TOOLS=false` nelle build per il pubblico. **Già spenti sull'app web pubblica** (`deploy.yml`); su TestFlight restano finché servono a te.
3. **Le schede degli store** (descrizioni, parole chiave, età, privacy, screenshot nelle misure giuste) non ci sono ancora.
4. **iOS:** manca il file privacy `PrivacyInfo.xcprivacy`; da fare una volta il gruppo app `group.com.astuto.app`, la chiave certificato fissa, gli abbonamenti "pronti" e allegati alla versione.
5. **Rischi in revisione:** il pulsante di accesso con email è visibile ma non funziona; il lavoro notturno delle carte (`cards.yml`) fallisce dal 21 settembre.

## L'ordine dei lavori
| # | Cosa | Chi | Tempo |
|---|---|---|---|
| 1 | Build sicure: strumenti spenti, file privacy iOS, pulsante email nascosto | Claude | ½ giorno |
| 2 | Portale Apple: gruppo app, chiave certificato, abbonamenti; una build TestFlight provata da capo a fondo | Proprietario, con istruzioni | ½–1 giorno |
| 3 | Android: keystore nuovo, build e caricamento su Play (traccia interna), SHA in Firebase, modulo "Sicurezza dei dati" | Claude + proprietario per le console | 2–3 giorni |
| 4 | Schede degli store: testi, parole chiave, screenshot | Claude (skill `aso-*`, `mk-*`) | 2–3 giorni |
| 5 | Contenuti: verificare le affermazioni rimaste, riparare `cards.yml` | Claude | 2–4 giorni |
| 6 | Invio: iOS in revisione, Android prima in test chiuso | Proprietario | — |
| 7 | **Dopo il lancio:** le carte nuove nell'app (formati come widget Flutter, video, poi il resto) | Claude | 4–8 settimane |

## Immagini, video e voce con l'IA
- **Google (una chiave sola):** immagini (Nano Banana), clip (Veo), voce. È l'unico servizio già raggiungibile da qui. Strumento pronto: `tool/media/gemini.py`. Serve la chiave `GEMINI_API_KEY` nei segreti dell'ambiente.
- **Recraft:** illustrazioni con uno stile fisso per ogni materia, anche in vettoriale. Va aggiunto `api.recraft.ai` alla rete.
- **ElevenLabs:** la voce migliore per le carte video, musica ed effetti. Skill `el-*` installate; va aggiunto `api.elevenlabs.io` alla rete e `ELEVENLABS_API_KEY` ai segreti.
- **Higgsfield:** installato con le sue skill, ma bloccato dalla rete (`higgsfield.ai`, `*.higgsfield.ai`).
- Costo stimato per 300 illustrazioni, 30 clip e 30 voci al mese: **circa 130–190 $**.
- Regola: l'IA dà atmosfera, mai fatti, mai scritte (vedi `docs/cards/HIGGSFIELD.md`).
