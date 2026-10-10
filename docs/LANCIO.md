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
2. **Gli strumenti da sviluppatore** (`lib/debug_flags.dart`): **su iPhone è fatto.** All'avvio il telefono dice da dove è stata installata l'app: gli strumenti compaiono su TestFlight e nelle build di debug, mai a chi scarica dall'App Store, anche se il binario è lo stesso. Se il telefono non risponde entro 300 ms restano spenti. Anche la copia che installano i revisori Apple ha una ricevuta sandbox, quindi la build da mandare in revisione si fa con il flusso Codemagic **iOS · App Store (for review)**: è identica a quella di TestFlight ma costruita con `DEBUG_TOOLS=false`, e gli strumenti non ci sono proprio. **Su Android** la build per Google Play va fatta con `--dart-define=DEBUG_TOOLS=false` (da mettere nel flusso di Play, punto 1). **Già spenti sull'app web pubblica** (`deploy.yml`), dove `?debug` nell'indirizzo li riaccende per una visita.
3. **Le schede degli store** (descrizioni, parole chiave, età, privacy, screenshot nelle misure giuste) non ci sono ancora.
4. **iOS:** il file privacy `PrivacyInfo.xcprivacy` c'è, uno per l'app e uno per il widget: dice gli stessi dati di `site/privacy.html` e perché l'app legge `UserDefaults`. Le risposte al questionario privacy di App Store Connect sono quelle (il "Privacy Report" che Xcode genera dall'archivio le elenca). Da fare una volta il gruppo app `group.com.astuto.app`, la chiave certificato fissa, gli abbonamenti "pronti" e allegati alla versione.
5. **Rischi in revisione:** il pulsante di accesso con email è visibile ma non funziona; il lavoro notturno delle carte (`cards.yml`) fallisce dal 21 settembre.

## L'ordine dei lavori
| # | Cosa | Chi | Tempo |
|---|---|---|---|
| 1 | Build sicure: pulsante email nascosto (fatti: strumenti solo su TestFlight, file privacy iOS) | Claude | ½ giorno |
| 2 | Portale Apple: gruppo app, chiave certificato, abbonamenti; una build TestFlight provata da capo a fondo | Proprietario, con istruzioni | ½–1 giorno |
| 3 | Android: keystore nuovo, build e caricamento su Play (traccia interna, con `DEBUG_TOOLS=false`), SHA in Firebase, modulo "Sicurezza dei dati" | Claude + proprietario per le console | 2–3 giorni |
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
