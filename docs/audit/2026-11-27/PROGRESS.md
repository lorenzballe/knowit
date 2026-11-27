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

- [ ] 0. Preparazione (questo file, driver)
- [ ] 1. Scheda Google Play
- [ ] 2. Sito
- [ ] 3. App da nuovo utente (en-US, it-IT, giorno 2 e 3, stati limite)
- [ ] 4. Inventario dal codice
- [ ] 5. Dati reali da PostHog
- [ ] 6. Strategia
- [ ] 7. Report, pagina con screenshot, pulizia delle attività programmate

## Appunti per fase

(si riempie man mano)
