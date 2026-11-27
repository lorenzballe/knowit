# Analisi di Astute da nuovo utente — avanzamento

Avviata ven 27/11/2026 alle 7:00 (Roma), su richiesta del proprietario la sera del 26/11.
Questo file serve a riprendere il lavoro dopo un'interruzione: chi riparte legge qui cosa è già fatto.

## Brief (in breve)

- Fingere di essere un nuovo utente: scheda Google Play, sito, app, schermata per schermata. Cosa va e cosa non va.
- Poi la strategia: cosa cambiare per (1) fare soldi, (2) far restare di più l'utente, (3) far piacere l'app.
- Tutto in italiano. Solo analisi: nessuna modifica ad app o sito, nessun deploy, nessuna scrittura su dati di produzione, nessun acquisto, nessun account con l'email del proprietario.
- Non sporcare le statistiche: gli eventi verso PostHog vengono bloccati nel browser dell'analisi.
- Consegna: `REPORT.md` in questa cartella, sintesi in chat, pagina con gli screenshot.
- Il brief completo è il testo dell'attività programmata `trig_01KCfxRy9cHui4FsMTEhJGtw`.

## Dove sono le cose

- Sito: https://astutetheapp.com — app web: https://astutetheapp.com/app/ — Play: https://play.google.com/store/apps/details?id=com.astuto.app
- Script: `docs/audit/2026-11-27/scripts/` (driver Playwright). Screenshot: nello scratchpad della sessione (rigenerabili con gli script).

## Fasi

- [x] 0. Preparazione (questo file, driver)
- [x] 1. Scheda Google Play
- [x] 2. Sito
- [x] 3. App da nuovo utente (en-US, it-IT, giorno 2 e 3, stati limite)
- [x] 4. Inventario dal codice
- [x] 5. Dati reali da PostHog
- [x] 6. Strategia
- [x] 7. Report, pagina con screenshot, pulizia delle attività programmate

## Appunti per fase

### 1. Scheda Google Play (fatta, 27/11 ore 7:15)

- Dati: "Astute" di TheBaleCompany, **10+ download**, nessun voto e nessuna recensione, categoria **Lifestyle**, aggiornata il 15 nov 2026, acquisti in-app, PEGI 3 (IT) / Everyone 10+ (US). Nessun video.
- 6 immagini telefono + 6 tablet, belle, scure, con titoli: "Tap. The answer, in one line." / "Get smarter in three minutes a day." / "Go deeper, subject by subject." / "See what everyone is asking." / "Eighteen subjects. You set the mix." / "See what stays with you.". Cornici iPhone (9:41) su una scheda Android. L'immagine "eroe" (logo + Get smarter) è la seconda, non la prima.
- Testo: racconta l'app come "5 carte, una domanda, la risposta in una riga". Dice: **7 giorni gratis**, poi €29,99/anno o €3,99/mese; **gratis = 2 carte**; **18 materie**; **3 minuti**.
- Scheda italiana = traduzione automatica di Google, con errori di senso ("puoi ridurre ciò che desideri approfondire", "i giorni di prova te ne danno due", schede/carte mescolati).
- Ricerca su Play: "astute" → 1ª, "astute app" → 2ª; ricerche generiche ("daily facts cards", "learn something new every day") → assente.
- Il sito e l'app di oggi parlano d'altro (calibrazione, "how sure", sfide, notizie): la scheda è rimasta indietro.

### 2. Sito (fatto, 27/11 ore 7:40)

- Molto curato e velocissimo: 478 KB, 20 richieste, LCP ~0,2 s in laboratorio, CLS 0, nessun dominio terzo al caricamento. Accessibilità automatica: solo contrasto su alcune etichette-materia e 2 righe scorrevoli non raggiungibili da tastiera.
- Prima schermata chiara: "Five cards a day. A little sharper." + badge store + telefono giocabile (carte disegnate: Apollo 13, Hormuz, fecondazione, Russia/Africa).
- Dice: **14 giorni gratis** ("two free weeks"), €29,99/anno (€2,49/mese) o €3,99/mese; **gratis = 5 carte ogni mattina (2 scelte per te + 3 a caso)**; **20 materie**; **2 minuti**; 13 lingue ma "cards in English".
- **Incoerenze con Play**: prova 7 vs 14 giorni; gratis 2 carte vs 5; 18 vs 20 materie; 3 vs 2 minuti; posizionamento diverso.
- **iPhone = vicolo cieco**: Download → /get → "Coming soon", nessuna lista d'attesa, nessuna email, nessun "provala sul web" (la web app /app/ esiste e non è linkata da nessuna parte). Il badge Apple "Coming soon" resta un link a una pagina App Store che non esiste.
- Computer: Download → scorre in fondo → QR (piccolo, 96 px). Funziona.
- Android: Download → Play con referrer utm_source=site.
- Solo in inglese (lang=en anche con browser italiano); support/terms/delete-account hanno anche l'italiano in fondo alla pagina.
- `<title>` è solo "Astute" (SEO debole); sitemap ok; 404 ok; www/http/github.io reindirizzano bene.
- Pagina lunghissima su telefono: ~18.000 px (circa 21 schermate).
- Supporto su indirizzo Gmail (thebalecompany@gmail.com). /account è un segnaposto "Not connected yet" (non linkato).
- Lighthouse non eseguito (comando rifiutato dal controllo permessi): tempi e accessibilità misurati con Playwright + axe.

### 3–7. Completate il 27/11/2026

L'analisi è finita. Questo repository è pubblico: per questo il report completo (app schermata per schermata, dati d'uso, difetti, strategia) non è qui ma in una pagina privata consegnata al proprietario in chat. Qui restano solo gli appunti su ciò che chiunque può vedere da fuori (scheda Play e sito) e gli script usati.

