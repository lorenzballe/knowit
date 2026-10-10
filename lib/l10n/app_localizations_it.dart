// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => 'Oggi';

  @override
  String get tabExplore => 'Esplora';

  @override
  String get tabProfile => 'Profilo';

  @override
  String signInNotConnected(String provider) {
    return 'L\'accesso con $provider non è ancora collegato. Le tue carte restano su questo dispositivo.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Accesso con $label non riuscito. Puoi continuare senza account.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Un freeze ha salvato la serie';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'una',
      '2': 'due',
      '3': 'tre',
      '4': 'quattro',
      '5': 'cinque',
      '6': 'sei',
      '7': 'sette',
      '8': 'otto',
      '9': 'nove',
      '10': 'dieci',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Giorno $n · $word lette';
  }

  @override
  String shelfEyebrow(String word) {
    return 'LE $word DI OGGI';
  }

  @override
  String get tapToFlip => 'TOCCA PER GIRARE';

  @override
  String get shareThisCard => 'Condividi questa carta';

  @override
  String get removeFromSaved => 'Togli dai salvati';

  @override
  String get saveThisPill => 'Salva questa carta';

  @override
  String get shareThisPill => 'Condividi questa carta';

  @override
  String cardOf(int k, int n) {
    return 'Carta $k di $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Le cinque di domani si aprono tra $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic apre le cinque di domani, tra $when';
  }

  @override
  String get exploreTodaysBest => 'Esplora il meglio di oggi';

  @override
  String magicUnlock(int days) {
    return 'Prova $days giorni gratis';
  }

  @override
  String get getPlus => 'Passa ad Astute+';

  @override
  String nothingInYet(String subject) {
    return 'Ancora niente in $subject.';
  }

  @override
  String get here => 'questa sezione';

  @override
  String get todaysShelf => 'Lo scaffale di oggi';

  @override
  String get sameForEveryone => 'Uguale per tutti, e solo oggi';

  @override
  String becauseSitsAtFull(String name) {
    return 'Perché $name è al massimo';
  }

  @override
  String get olderFromTurnedUp =>
      'Carte più vecchie delle materie che hai alzato';

  @override
  String moreOn(String name) {
    return 'Ancora su $name';
  }

  @override
  String get subjectReadMost => 'La materia di cui hai letto di più';

  @override
  String monthOf(String name) {
    return 'Un mese di $name';
  }

  @override
  String get somewhereToStart => 'Un punto di partenza che non è oggi';

  @override
  String get searchEveryCard => 'Cerca tra tutte le carte';

  @override
  String nothingForYet(String query) {
    return 'Ancora niente per \"$query\".';
  }

  @override
  String matching(int n) {
    return '$n trovate';
  }

  @override
  String get all => 'Tutte';

  @override
  String get theArchive => 'L\'archivio';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n risultati',
      one: '1 risultato',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n carte. Tocca un giorno per aprirlo.';
  }

  @override
  String get whatYouHaveCovered => 'Cosa hai coperto';

  @override
  String searchNCards(int n) {
    return 'Cerca tra $n carte';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte',
      one: '1 carta',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Ieri';

  @override
  String get noPillsMatchFilter =>
      'Nessuna carta corrisponde ancora a questo filtro.';

  @override
  String nothingForTryTopic(String query) {
    return 'Niente per \"$query\". Prova con una materia.';
  }

  @override
  String get saved => 'Salvate';

  @override
  String get removedFromSaved => 'Tolta dai salvati.';

  @override
  String get undo => 'Annulla';

  @override
  String get nothingKeptYet => 'Ancora niente di tenuto';

  @override
  String nInTopic(int n, String topic) {
    return '$n in $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Tieni quelle che userai davvero';

  @override
  String get backToTodaysFive => 'TORNA ALLE CINQUE DI OGGI';

  @override
  String get archive => 'Archivio';

  @override
  String get yourWeek => 'La tua settimana';

  @override
  String get nothingThisWeekYet =>
      'Ancora niente questa settimana. Cinque carte la fanno partire.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Tenuta — $days giorni su sette.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni su sette.',
      one: '1 giorno su sette.',
    );
    return '$_temp0 Con cinque la settimana è tenuta.';
  }

  @override
  String get howSureAgainstHowRight => 'Quanto sicuro, contro quanto giusto';

  @override
  String get sureAndWrong => 'Sicuro, e sbagliato';

  @override
  String get worthGoingBackTo =>
      'Quelle su cui vale la pena tornare. Sbagliare qualcosa di cui eri sicuro è l\'unico modo economico per scoprire cosa credi davvero.';

  @override
  String get whereThisIsGoing => 'Dove sta andando';

  @override
  String ofNRight(int n) {
    return 'su $n giuste';
  }

  @override
  String get sayHowSureOnMore =>
      'Di\' quanto sei sicuro su qualche altra carta e l\'app ti dirà quanto vale quella sicurezza.';

  @override
  String confidenceOff(int gap) {
    return 'La tua sicurezza era $gap punti lontana da quello che sapevi davvero.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'La tua sicurezza era $gap punti fuori, contro $before la settimana scorsa. Si sta chiudendo.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'La tua sicurezza era $gap punti fuori, contro $before la settimana scorsa. Si è allargata.';
  }

  @override
  String nextRung(String name) {
    return 'Prossimo: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Hai detto $n% sicuro';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Giorno uno',
      'reading': 'Lettura',
      'answering': 'Risposta',
      'saying_how_sure': 'Dire quanto sei sicuro',
      'calibrated': 'Calibrato',
      'holding': 'Tenuta',
      'sharp': 'Lucido',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Tutti partono da qui.',
      'reading': 'L\'abitudine è partita.',
      'answering': 'Ti impegni prima di girare la carta.',
      'saying_how_sure': 'Metti un numero su quello che pensi di sapere.',
      'calibrated': 'Quello che dici di sapere, lo sai.',
      'holding': 'Resta con te settimane dopo.',
      'sharp': 'Sicuro quando devi, e giusto quando lo sei.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'ancora $n carte da leggere';
  }

  @override
  String stepAnswer(int n) {
    return 'ancora $n carte a cui rispondere';
  }

  @override
  String stepJudge(int n) {
    return 'ancora $n risposte con quanto sei sicuro';
  }

  @override
  String stepHold(int n) {
    return 'ancora $n carte da tenere';
  }

  @override
  String stepGap(int gap, int target) {
    return 'la tua sicurezza è $gap punti fuori — bastano $target';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'ancora $n risposte prima che l\'app giudichi la tua sicurezza';
  }

  @override
  String stepThenRung(String step, String name) {
    return '$step → $name';
  }

  @override
  String rungOfTotal(int at, int of) {
    return '$at / $of';
  }

  @override
  String get signOutQuestion => 'Vuoi uscire?';

  @override
  String get signOutBody =>
      'Serie, carte salvate e record restano sul tuo account. Questo li cancella da questo dispositivo.';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deletingAccount => 'Eliminazione dell\'account…';

  @override
  String get deleteAccountQuestion => 'Eliminare il tuo account?';

  @override
  String get deleteAccountBody =>
      'Il tuo account, il suo backup e la scheda che vedono i tuoi amici vengono eliminati per sempre, e questo dispositivo riparte dall\'inizio. Astute+ non viene disdetto: l\'abbonamento si gestisce nelle impostazioni dell\'App Store.';

  @override
  String get deleteAccountConfirm => 'Elimina per sempre';

  @override
  String get accountDeleted => 'Il tuo account è stato eliminato.';

  @override
  String get couldNotDeleteAccount =>
      'Non è stato possibile eliminare l\'account. Riprova tra poco.';

  @override
  String get signOut => 'Esci';

  @override
  String get signedInRecordOnAccount =>
      'Accesso fatto. Serie e record ora sono sul tuo account.';

  @override
  String couldNotSignInWith(String label) {
    return 'Accesso con $label non riuscito.';
  }

  @override
  String get signInNotAvailableBuild =>
      'L\'accesso non è disponibile in questa versione.';

  @override
  String get startOverQuestion => 'Ricominciare da capo?';

  @override
  String get startOverBody =>
      'Cancella tutto su questo dispositivo — serie, carte salvate, risposte, il tuo record di giudizi, materie e piano — e riapre l\'introduzione.';

  @override
  String get wipeIt => 'Cancella';

  @override
  String get yourRecord => 'Il tuo record';

  @override
  String get appearance => 'Aspetto';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get yourTopics => 'Le tue materie';

  @override
  String get edit => 'Modifica';

  @override
  String get howWellYouKnowYourself => 'Quanto ti conosci';

  @override
  String get journeyButtonLine =>
      'Il tuo livello, le mosse che continui a mancare, la tua settimana in domande';

  @override
  String get isTheGapClosing => 'Il divario si sta chiudendo?';

  @override
  String get movesYouKeepMissing => 'Le mosse che continui a mancare';

  @override
  String get dailyNudge => 'Promemoria quotidiano';

  @override
  String everyDayAt(String time) {
    return 'Ogni giorno alle $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'Le tue 5 carte, prima del primo caffè.';

  @override
  String get browserOnlySpeaksOpen =>
      'Un browser parla solo mentre è aperto, quindi serve la versione per telefono.';

  @override
  String get nudgeOff => 'Promemoria spento.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Promemoria acceso, ogni giorno alle $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Promemoria acceso, ma il sistema ha detto di no. Attiva le notifiche per Astute nelle impostazioni.';

  @override
  String get nudgeOnNeedsPhone =>
      'Promemoria acceso. Per riceverlo serve la versione per telefono.';

  @override
  String savedN(int n) {
    return 'Salvate · $n';
  }

  @override
  String get manageSubscription => 'Gestisci abbonamento';

  @override
  String get howPillsAreWritten => 'Come sono scritte le carte';

  @override
  String get howTitle => 'Ogni carta qui è scritta da un modello di IA.';

  @override
  String get howIntro =>
      'Preferiamo dirlo subito piuttosto che te ne accorga da solo. Ecco come una carta arriva fino a te.';

  @override
  String get howStep1Title => 'Scritta prima, da un modello';

  @override
  String get howStep1Line =>
      'Ogni carta segue una sola consegna: una domanda che vale la pena porsi, una risposta che dice perché e una mossa da riusare.';

  @override
  String get howStep2Title => 'Controllata sulla sua fonte';

  @override
  String get howStep2Line =>
      'Ogni carta dice da dove viene, e un secondo modello la legge da critico prima che esca. Quello che non regge viene tagliato.';

  @override
  String get howStep3Title => 'Cinque, distribuite ogni mattina';

  @override
  String get howStep3Line =>
      'Dalle materie che hai scelto, e mai una che hai già letto.';

  @override
  String get howStep4Title => 'Tenute oneste dai lettori';

  @override
  String get howStep4Line =>
      'Quando abbastanza lettori dicono che una carta è sbagliata, smette di essere distribuita finché una persona non l\'ha controllata.';

  @override
  String get howReportTitle => 'Hai trovato un errore?';

  @override
  String get howReportLine =>
      'Tocca la bandierina accanto alla fonte di una carta per segnalarla.';

  @override
  String get howFoot => 'Le fonti vengono ricontrollate ogni mese.';

  @override
  String get signingIn => 'Accesso in corso…';

  @override
  String get signInWithApple => 'Accedi con Apple';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'In $n risposte hai detto quanto eri sicuro. Ecco com\'è andata.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Una persona perfettamente calibrata ha ragione il 70% delle volte quando dice 70%.';

  @override
  String get notEnoughAnswersYet => 'Ancora troppo poche risposte';

  @override
  String get confidenceMatchesAccuracy =>
      'La tua sicurezza corrisponde alla tua precisione';

  @override
  String overconfidentBy(int points) {
    return 'Sei troppo sicuro di $points punti';
  }

  @override
  String underconfidentBy(int points) {
    return 'Sei troppo poco sicuro di $points punti';
  }

  @override
  String saidPercent(int n) {
    return 'Detto $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'giusto il $pct% ($right su $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ancora $n contesti in arrivo',
      one: 'ancora 1 contesto in arrivo',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Vedi ogni principio con Astute plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'altri $n in osservazione',
      one: '1 altro in osservazione',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'CONDIVIDI IL MIO RECORD';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Le tue ultime $n risposte, contro le prime $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Chiuso di $n punti';
  }

  @override
  String openedByPoints(int n) {
    return 'Aperto di $n punti';
  }

  @override
  String get holdingSteady => 'Stabile';

  @override
  String get measurementRunningPlus =>
      'La misurazione è in corso. Astute+ ti mostra in che direzione va.';

  @override
  String firstN(int n) {
    return 'Prime $n';
  }

  @override
  String lastN(int n) {
    return 'Ultime $n';
  }

  @override
  String get trackingMoreClosely =>
      'La tua sicurezza segue la tua precisione più da vicino di prima.';

  @override
  String get distanceHasGrown =>
      'La distanza è cresciuta. Vale la pena rallentare prima di impegnarti.';

  @override
  String get noRealMovementYet =>
      'Nessun movimento vero ancora. Ci vogliono settimane, non giorni.';

  @override
  String get seeWhichWay => 'VEDI IN CHE DIREZIONE';

  @override
  String get spotOn => 'esatto';

  @override
  String pointsOver(int n) {
    return '$n in più';
  }

  @override
  String pointsUnder(int n) {
    return '$n in meno';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days giorni gratis';
  }

  @override
  String get seeThePlans => 'VEDI I PIANI';

  @override
  String get recordStartsToday => 'Il tuo record inizia oggi.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'giorni',
      one: 'giorno',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'carte lette',
      one: 'carta letta',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte lette',
      one: '1 carta letta',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n settimane tenute',
      one: '1 settimana tenuta',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n in arrivo';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freeze disponibili',
      one: '1 freeze disponibile',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Piano gratuito';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hai saltato\n$n giorni.',
      one: 'Hai saltato\nun giorno.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni sono',
      one: 'Un giorno è',
    );
    return '$_temp0 ancora il tuo record. Leggi le cinque di oggi e il contatore riparte da uno.';
  }

  @override
  String get whileYouWereAway => 'Mentre non c\'eri';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte non lette',
      one: '1 carta non letta',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic è ancora la materia che tieni di più';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte che avevi indovinato tornano oggi',
      one: '1 carta che avevi indovinato torna oggi',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Riparti dalle cinque di oggi';

  @override
  String moveMyReminderTo(String time) {
    return 'Sposta il promemoria alle $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Promemoria spostato alle $time.';
  }

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n materie su $total nel mix';
  }

  @override
  String get everythingIsInDrag =>
      'C\'è tutto. Trascina una materia verso il basso per vederne meno, o fino a zero per toglierla.';

  @override
  String get next => 'Avanti';

  @override
  String get whatShouldWeTalkAbout => 'Di cosa parliamo?';

  @override
  String get fivePillsADayPick =>
      'Cinque carte al giorno, nuove ogni mattina. Scegli le materie che vuoi nel mix — puoi cambiarle dopo.';

  @override
  String nSelected(int n) {
    return '$n selezionate';
  }

  @override
  String startWithNTopics(int n) {
    return 'Inizia con $n materie';
  }

  @override
  String saveNTopics(int n) {
    return 'Salva $n materie';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Scegline almeno $n';
  }

  @override
  String get swipeToSeeMore => 'Scorri per vedere altro';

  @override
  String get tagline =>
      'Cinque cose intelligenti al giorno, pronte da usare in conversazione';

  @override
  String get introTopicsTitle => 'Diciannove materie, cinque carte';

  @override
  String get introTopicsLine =>
      'Scritte prima da un modello, e ognuna verificata sulla sua fonte.';

  @override
  String get introQuestionTitle => 'Una domanda, poi la risposta';

  @override
  String get introQuestionLine =>
      'Ogni carta porta la frase che vale la pena dire ad alta voce.';

  @override
  String get introMixTitle => 'Il mix lo scegli tu';

  @override
  String get introMixLine =>
      'Abbassa una materia per vederne meno, o spegnila del tutto.';

  @override
  String get introThirtyTitle => 'Due minuti al giorno';

  @override
  String get introThirtyLine =>
      'Una notifica, cinque carte, e una serie che non vorrai spezzare.';

  @override
  String introNotifyWhen(String time) {
    return 'Domani, $time';
  }

  @override
  String get introNotifyLine => 'Le tue cinque sono pronte. Giorno 1.';

  @override
  String get introOneOfFive => '1 DI 5';

  @override
  String get introDayOne => 'GIORNO 1';

  @override
  String get introTapTomorrow => 'TOCCA DOMANI PER SCOPRIRLO';

  @override
  String get introDayOneTomorrow => 'GIORNO 1 · DOMANI';

  @override
  String get introDaySevenStreak => 'GIORNO 7 · PRIMA SERIE';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get continueWithEmail => 'Continua con l\'email';

  @override
  String get termsLine =>
      'Registrandoti accetti i Termini di servizio e la Privacy Policy';

  @override
  String get skip => 'Salta';

  @override
  String get tapToRevealLower => 'tocca per scoprire';

  @override
  String get barMoveCaps => 'DA PORTARE CON TE';

  @override
  String get theBarMoveCaps => 'LA MOSSA DA BAR';

  @override
  String get widgetFootPlain => 'Cinque carte, due minuti.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Serie di $n giorni',
      one: 'Serie di 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Fatto per oggi';

  @override
  String get widgetStreakStart =>
      'Leggi le cinque di oggi per iniziare una serie.';

  @override
  String get widgetFiveTitle => 'LE CINQUE DI OGGI';

  @override
  String widgetFiveRead(int n) {
    return '$n su 5 lette';
  }

  @override
  String get widgetFiveDone => 'Tutte e cinque lette';

  @override
  String get widgetFiveWaiting => 'Ti aspettano cinque carte nuove';

  @override
  String get widgetShelfTitle => 'LO SCAFFALE DI OGGI';

  @override
  String get widgetShelfFrom => 'Dallo scaffale di oggi';

  @override
  String get dayStreakCaps => 'GIORNI DI SERIE';

  @override
  String sourceLabel(String source) {
    return 'Fonte · $source';
  }

  @override
  String get perkArchiveTitle => 'Tutto il tuo archivio';

  @override
  String get perkArchiveLine => 'Ogni giorno che hai letto, per sempre.';

  @override
  String get plusIsActive => 'ASTUTE+ È ATTIVO';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days giorni gratis, poi $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Abbonati a $price$suffix';
  }

  @override
  String get noChargeTodayCancel =>
      'Nessun addebito oggi · disdici quando vuoi';

  @override
  String get chargedTodayCancel => 'Addebito oggi · disdici quando vuoi';

  @override
  String get everyCardForYouMark => 'te.';

  @override
  String get trialStartedNoPayment =>
      'Prova avviata. Nessun pagamento è collegato in questa versione.';

  @override
  String get thatDidNotGoThrough => 'Non è andata a buon fine.';

  @override
  String get plusIsBack => 'Astute+ è tornato.';

  @override
  String get nothingToRestore => 'Niente da ripristinare su questo account.';

  @override
  String get planYearly => 'Annuale';

  @override
  String get planMonthly => 'Mensile';

  @override
  String get perYearShort => '/anno';

  @override
  String get perMonthShort => '/mese';

  @override
  String get perYear => 'all\'anno';

  @override
  String aMonth(String price) {
    return '$price al mese';
  }

  @override
  String savePercent(int n) {
    return 'RISPARMI $n%';
  }

  @override
  String get perMonth => 'al mese';

  @override
  String get billedMonthly => 'addebito mensile';

  @override
  String get cancelTheTrial => 'Annulla la prova';

  @override
  String get cancelAnyTime => 'Disdici quando vuoi';

  @override
  String get cancelAnyTimeNoPayment =>
      'Disdici quando vuoi · Nessun pagamento in questa versione';

  @override
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get termsOfUse => 'Termini d\'uso';

  @override
  String get privacyPolicy => 'Privacy';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Scegli una parte. Non c\'è una risposta giusta.';

  @override
  String get estimateCloseEnough => 'Stima. Basta andarci vicino.';

  @override
  String get tapToReveal => 'Tocca per scoprire';

  @override
  String closeEnoughItIs(String answer) {
    return 'Ci sei andato vicino · è $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Hai detto $given · è $answer, e $band conta';
  }

  @override
  String get youGotIt => 'Giusto';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Hai detto $given · è $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Quasi tutti sbagliano questa';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · hai detto $pct% sicuro';
  }

  @override
  String get giveMeANudge => 'Dammi un aiuto';

  @override
  String get beingRightMattersLess =>
      'Avere ragione conta meno che sapere quanto spesso ce l\'hai.';

  @override
  String get writeItBeforeTheirs => 'Scrivilo prima di leggere la loro.';

  @override
  String get youAnsweredThisOne => 'A questa hai già risposto.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Facile',
      'medium': 'Media',
      'hard': 'Difficile',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · impegnati prima di girarla.';
  }

  @override
  String get yourAnswer => 'La tua risposta';

  @override
  String get checkMyAnswer => 'Controlla la mia risposta';

  @override
  String get howSureAreYou => 'Quanto sei sicuro?';

  @override
  String percentSure(int n) {
    return '$n per cento sicuro';
  }

  @override
  String get inOneLineWhy => 'In una riga — perché?';

  @override
  String get because => 'Perché…';

  @override
  String get nowShowMeTheOtherSide => 'Ora mostrami l\'altra parte';

  @override
  String get skipShowMeAnyway => 'Salta — mostramela comunque';

  @override
  String get youTookCaps => 'HAI SCELTO';

  @override
  String get putSimplyCaps => 'IN PAROLE SEMPLICI';

  @override
  String get explainLikeImThree => 'Spiegamelo come a un bambino';

  @override
  String get whatTheOtherSideSaysCaps => 'COSA DICE L\'ALTRA PARTE';

  @override
  String get whatTheOtherSideSays => 'Cosa dice l\'altra parte';

  @override
  String theTrap(String trap) {
    return 'La trappola: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Hai scelto la parte: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' al $n% di sicurezza';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Questa l\'hai indovinata$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Hai detto $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Scorri per la prossima';

  @override
  String get thatWasTheOnlyOne => 'Era l\'unica';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Impossibile disegnare la carta.';

  @override
  String get textCopiedInstead => 'Copiato il testo al suo posto.';

  @override
  String get copiedToClipboard => 'Copiato negli appunti.';

  @override
  String get rendering => 'Sto disegnando…';

  @override
  String get theSourceGoesWithIt => 'La fonte viaggia con lei';

  @override
  String get fiveADayALittleSharper => 'Cinque al giorno. Un po\' più lucido.';

  @override
  String get shareMyDay => 'Condividi';

  @override
  String climbedTo(String rung) {
    return 'Oggi sei salito a $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right su $asked giuste';
  }

  @override
  String saidSure(int sure) {
    return 'sicuro al $sure%';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n carte a cui hai risposto giorni fa, di nuovo qui per vedere se ti sono rimaste',
      one: 'Una carta a cui hai risposto giorni fa, di nuovo qui per vedere se ti è rimasta',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Ti ricordi ancora?';

  @override
  String get holdACardYouLike => 'Se ti piace, tienila';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n piaciute oggi',
      one: '1 piaciuta oggi',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Piaciute';

  @override
  String likedN(int n) {
    return 'Piaciute · $n';
  }

  @override
  String get nothingLikedYet => 'Ancora niente di piaciuto';

  @override
  String get likeThisPill => 'Mi piace questa carta';

  @override
  String get removeFromLiked => 'Togli dai mi piace';

  @override
  String get removedFromLiked => 'Tolta dai mi piace.';

  @override
  String get lessLikeThis => 'Meno così';

  @override
  String get whatYouLikedLandsHere => 'Quelle che rileggeresti';

  @override
  String get holdToLikeLandsHere =>
      'Tieni premuta una carta che ti piace e finisce qui — e l\'app te ne dà altre così.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Tocca il segnalibro su una carta e finisce qui — quelle che ti hanno cambiato il modo di pensare, tenute.';

  @override
  String get nudgeTitle => 'Le tue cinque sono pronte';

  @override
  String get nudgeFreezeTitle => 'Il tuo congelamento sta tenendo';

  @override
  String nudgeFreezeBody(String question) {
    return 'Ieri è coperto. Oggi: $question';
  }

  @override
  String get nudgeSureTitle => 'Di questa eri sicuro';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — avevi detto $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Due settimane fa avevi letto $read carte';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'La tua sicurezza era di $gap punti fuori. Oggi: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '$answered risposte finora. Oggi: $question';
  }

  @override
  String get friends => 'Amici';

  @override
  String friendsN(int n) {
    return 'Amici · $n';
  }

  @override
  String get yourFriendCode => 'Il tuo codice amico';

  @override
  String get codeCopied => 'Codice copiato.';

  @override
  String get addAFriend => 'Aggiungi un amico';

  @override
  String get theirCode => 'Il suo codice';

  @override
  String get add => 'Aggiungi';

  @override
  String get noFriendsYet =>
      'Ancora nessuno. Scambiati il codice con un amico e confrontate serie e calibrazione — mai le risposte.';

  @override
  String get friendsNeedAnAccount =>
      'Per confrontare servono l\'app sul telefono e un account. I tuoi codici restano.';

  @override
  String get noReaderWithCode => 'Nessun lettore con quel codice.';

  @override
  String get thatsYourOwnCode => 'È il tuo stesso codice.';

  @override
  String pointsOff(int n) {
    return '$n punti fuori';
  }

  @override
  String get notMeasuredYet => 'non ancora misurata';

  @override
  String get thisWeekByCalibration => 'Questa settimana, per calibrazione';

  @override
  String get notYetToday => 'oggi non ancora';

  @override
  String nOfSeven(int n) {
    return '$n su 7';
  }

  @override
  String get you => 'Tu';

  @override
  String get todaysQuestion => 'La domanda di oggi';

  @override
  String get right => 'giusta';

  @override
  String get wrong => 'sbagliata';

  @override
  String rightAtSure(int sure) {
    return 'giusta, sicuro al $sure%';
  }

  @override
  String wrongAtSure(int sure) {
    return 'sbagliata, sicuro al $sure%';
  }

  @override
  String get yourJourney => 'Il tuo viaggio';

  @override
  String get thePath => 'Il percorso';

  @override
  String get youAreHere => 'SEI QUI';

  @override
  String reachedOn(String date) {
    return 'Raggiunto il $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n su $of lette finora';
  }

  @override
  String nRead(int n) {
    return '$n lette';
  }

  @override
  String get topLevel => 'Ultimo livello';

  @override
  String plusNToday(int n) {
    return '+$n oggi';
  }

  @override
  String get bySubject => 'Per materia';

  @override
  String get pts => 'punti';

  @override
  String nStillWithYou(int n) {
    return '$n ancora con te';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mosse',
      one: '1 mossa',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'Il tuo punteggio parte dalle cinque di oggi.';

  @override
  String get anonymousUsage => 'Dati di utilizzo';

  @override
  String get anonymousUsageLine =>
      'Come viene usata l’app — cosa si legge, si tiene e si dice, e cosa non funziona — così le prossime carte saranno migliori. Mai il tuo nome, la tua email o quello che scrivi.';

  @override
  String get usageOn => 'Condivisi, senza il tuo nome né le tue parole.';

  @override
  String get usageOff => 'Non si misura più nulla.';

  @override
  String get yourMix => 'Il tuo mix';

  @override
  String get genresLine =>
      'Tocca un genere per saltarlo. Tienilo premuto e i sotto-argomenti dentro si aprono qui sotto.';

  @override
  String get insideGenre => 'Dentro';

  @override
  String nOfSixOn(int n, int total) {
    return '$n di $total attivi';
  }

  @override
  String get offInYourMix => 'fuori dal tuo mix';

  @override
  String continueGenresOn(int on, int total) {
    return 'Continua · $on di $total generi attivi';
  }

  @override
  String get mixRarely => 'Di rado';

  @override
  String get mixSometimes => 'A volte';

  @override
  String get mixOften => 'Spesso';

  @override
  String get mixALot => 'Molto';

  @override
  String get mixFull => 'Al massimo';

  @override
  String get forYouChip => 'PER TE';

  @override
  String get againChip => 'DI NUOVO';

  @override
  String get magicLine =>
      'Cinque carte al giorno scelte per te: dal tuo mix, al tuo livello, mai una già letta. Da domani.';

  @override
  String get everyCardForYou => 'Ogni carta, scelta per te.';

  @override
  String get perkOwnTitle => 'Cinque carte al giorno, tutte tue';

  @override
  String get perkOwnLine =>
      'Dai tuoi filoni, al tuo livello, mai una già letta. Gratis ne hai due al giorno.';

  @override
  String get plusCardHeadline => 'Tutte e cinque, tue.';

  @override
  String get plusCardLine =>
      'Cinque carte al giorno dal tuo mix, al tuo livello. Il tuo viaggio. Tutto il tuo archivio.';

  @override
  String get continueFree => 'Continua gratis';

  @override
  String get archiveBeforeThisWeek => 'Prima di questa settimana';

  @override
  String get weekKeptThreeOwn =>
      'Una settimana di fila: domani tre delle cinque sono tue.';

  @override
  String get perkJourneyLine =>
      'Il tuo livello, ogni materia filone per filone, cosa ti è rimasto, e le mosse che continui a mancare.';

  @override
  String get topOfTheWeek => 'Top della settimana';

  @override
  String get topOfTheMonth => 'Top del mese';

  @override
  String topIn(String subject) {
    return 'Top in $subject';
  }

  @override
  String get topLineWeek =>
      'Le più piaciute, salvate e raccontate negli ultimi 7 giorni';

  @override
  String get topLineMonth =>
      'Le più piaciute, salvate e raccontate negli ultimi 30 giorni';

  @override
  String get topWeek => 'Settimana';

  @override
  String get topMonth => 'Mese';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lettori',
      one: '1 lettore',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Ancora niente in classifica. Ogni carta che ti piace, salvi o racconti conta.';

  @override
  String get readMark => 'Letta';

  @override
  String get lovedSinceTheStart => 'Le più amate da sempre';

  @override
  String lovedIn(String subject) {
    return 'Le più amate in $subject';
  }

  @override
  String get lovedLine =>
      'Quelle che i lettori hanno tenuto di più, e che non hai ancora letto';

  @override
  String get forYouShelf => 'Per te';

  @override
  String get forYouLine => 'Quello che la tua lettura mette al primo posto';

  @override
  String get exploreOffline =>
      'Sei offline. Questa è Esplora come l\'hai letta l\'ultima volta.';

  @override
  String get askYourselfCaps => 'CHIEDITI';

  @override
  String get themeMyths => 'Miti da sfatare';

  @override
  String get themeMythsLine =>
      'Ciò che quasi tutti credono, e perché è sbagliato';

  @override
  String get themeParadoxes => 'Paradossi';

  @override
  String get themeParadoxesLine =>
      'Due cose vere che non dovrebbero esserlo entrambe';

  @override
  String get themeNumbers => 'Numeri che sorprendono';

  @override
  String get themeNumbersLine => 'Dove il colpo di scena è la cifra';

  @override
  String get themePractical => 'Da usare oggi';

  @override
  String get themePracticalLine =>
      'Qualcosa da provare, o da tirare fuori in una conversazione, prima di stasera';

  @override
  String get themeOrigins => 'Da dove viene';

  @override
  String get themeOriginsLine => 'Le origini di cose che usi ogni giorno';

  @override
  String get themeStories => 'Storie vere';

  @override
  String get themeStoriesLine => 'Cose successe davvero';

  @override
  String get themeDebates => 'Scegli da che parte stare';

  @override
  String get themeDebatesLine =>
      'Nessuna risposta giusta, solo un argomento migliore';

  @override
  String get themeWorkItOut => 'Fai il conto';

  @override
  String get themeWorkItOutLine =>
      'Indovina il numero prima che te lo dica la carta';

  @override
  String get themeSeen => 'Da vedere';

  @override
  String get themeSeenLine => 'Carte che disegnano il loro punto';

  @override
  String get themeSharpest => 'Per i più acuti';

  @override
  String get themeSharpestLine => 'Le carte più difficili che ci sono';

  @override
  String get themePast0 => 'Il mondo antico';

  @override
  String get themePast1 => 'Dal Seicento all\'Ottocento';

  @override
  String get themePast2 => 'Il secolo scorso';

  @override
  String get themePastLine => 'Un\'epoca diversa ogni volta che torna';

  @override
  String get themePlace0 => 'Asia e Medio Oriente';

  @override
  String get themePlace1 => 'Le Americhe';

  @override
  String get themePlace2 => 'Europa';

  @override
  String get themePlaceLine =>
      'Una parte del mondo diversa ogni volta che torna';

  @override
  String get themeTrueOrFalse => 'Vero o falso?';

  @override
  String get themeTrueOrFalseLine =>
      'Decidi prima di girare. Quasi tutti sbagliano';

  @override
  String get themeReasoning => 'Solo ragionamento';

  @override
  String get themeReasoningLine =>
      'Niente da sapere a memoria: solo un modo di pensarci';

  @override
  String get themeIdeas => 'Grandi idee';

  @override
  String get themeIdeasLine => 'La teoria dietro le cose, un\'idea alla volta';

  @override
  String get themeCurious => 'Solo curiosità';

  @override
  String get themeCuriousLine => 'Per il gusto di sapere il perché';

  @override
  String get themeMoving => 'In movimento';

  @override
  String get themeMovingLine =>
      'Cose che stanno cambiando ora, e perché contano';

  @override
  String get themeHowItWorks => 'Come funziona davvero';

  @override
  String get themeHowItWorksLine =>
      'Il meccanismo dietro qualcosa che vedi ogni giorno';

  @override
  String get themePuzzles => 'Rompicapi';

  @override
  String get themePuzzlesLine =>
      'Enigmi da risolvere con una penna e un minuto';

  @override
  String get weekRecapCaps => 'QUESTA SETTIMANA TI SEI CHIESTO';

  @override
  String get weekRecapLine => 'Le domande che le tue carte ti hanno lasciato';

  @override
  String weekRecapMore(int n) {
    return 'Altre $n della tua settimana con Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ è nell\'app: scarica Astute su iPhone o Android per iniziare la prova gratuita.';

  @override
  String get purchaseComplete => 'Acquisto completato.';

  @override
  String get successWelcome =>
      'Benvenuto in Astute+. Le cinque carte di oggi sono pronte.';

  @override
  String successWelcomeNamed(String name) {
    return 'Benvenuto in Astute+, $name. Le cinque carte di oggi sono pronte.';
  }

  @override
  String get successFiveCards => '5 carte al giorno';

  @override
  String get successArchive => 'Tutto l’archivio';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Gratis fino al $date, poi $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Si rinnova il $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Ricevuta';

  @override
  String get letsStart => 'Iniziamo';

  @override
  String successFootFirstCharge(String date) {
    return 'Primo addebito il $date · disdici quando vuoi';
  }

  @override
  String successFootRenews(String date) {
    return 'Si rinnova il $date · disdici quando vuoi';
  }

  @override
  String get tryToday => 'PROVALO OGGI';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'o';

  @override
  String get nextStep => 'Passo successivo';

  @override
  String get showAllSteps => 'Mostra tutto';

  @override
  String get revealSeePicture => 'Guarda il disegno';

  @override
  String get revealPlayScene => 'Provalo tu';

  @override
  String get revealBackToAnswer => 'Torna alla risposta';

  @override
  String get revealShowWorking => 'Mostra il ragionamento';

  @override
  String get sceneLockIn => 'CONFERMA';

  @override
  String get sceneYou => 'TU';

  @override
  String get sceneTruth => 'VERO';

  @override
  String get sceneTryAgain => 'Riprova';

  @override
  String get sceneDrawHint => 'Disegna la tua ipotesi col dito';

  @override
  String get sceneHoldHint => 'Tieni premuto';

  @override
  String get sceneSwipeHint => 'Scorri o tocca';

  @override
  String get sceneTapToPick => 'Tocca la tua scelta';

  @override
  String get sceneShowMe => 'Fammi vedere';

  @override
  String get sceneYourGuess => 'La tua ipotesi';

  @override
  String sceneNOfM(int n, int m) {
    return '$n su $m';
  }

  @override
  String get reportProblem => 'Segnala un problema';

  @override
  String get reportedThanks => 'Segnalata. Grazie.';

  @override
  String get reportTitle => 'Cosa non va in questa carta?';

  @override
  String get reportLead =>
      'Controlliamo ogni segnalazione sulle fonti e correggiamo la carta.';

  @override
  String get reportFact => 'Un fatto è sbagliato';

  @override
  String get reportAnswer => 'La risposta data per giusta è sbagliata';

  @override
  String get reportSource => 'La fonte non lo conferma';

  @override
  String get reportUnclear => 'Non si capisce';

  @override
  String get reportTypo => 'Un refuso o una riga rotta';

  @override
  String get reportOther => 'Altro';

  @override
  String get reportNoteHint =>
      'Qualcosa che ci aiuti a controllare (facoltativo)';

  @override
  String get reportSend => 'Invia';

  @override
  String get reportSentToast => 'Grazie. La controlliamo.';

  @override
  String get journeyPointsOff => 'punti fuori';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ancora $n risposte con quanto sei sicuro, e lo misuriamo.',
      one: 'Ancora una risposta con quanto sei sicuro, e lo misuriamo.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Il tuo punteggio';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'punti',
      one: 'punto',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n in 4 settimane';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Questa settimana finora hai guadagnato $n punti.',
      one: 'Questa settimana finora hai guadagnato 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nella settimana del $date hai guadagnato $n punti.',
      one: 'Nella settimana del $date hai guadagnato 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte',
      one: '1 carta',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Il tuo punteggio alla fine di ogni settimana, dal $date. Tocca un punto per vedere quella settimana.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Livello $n di $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\nda $rung';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte',
      one: '1 carta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n risposte',
      one: '1 risposta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n risposte con quanto sei sicuro',
      one: '1 risposta con quanto sei sicuro',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte tenute',
      one: '1 carta tenuta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n punti',
      one: '1 punto',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Quanto vale';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n saggi',
      one: '1 saggio',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'o $h h di documentari';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'mancano $n al primo saggio',
      one: 'manca 1 al primo saggio',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Di fila';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Record $best · $active su $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n su $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'materie · tratteggio: $month';
  }

  @override
  String get journeySubjects => 'materie';

  @override
  String get journeyHowHard => 'Difficoltà';

  @override
  String get journeyOfThree => 'su 3';

  @override
  String get journeyHardNow => 'Le carte che apri.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Le carte che apri. $v in $month';
  }

  @override
  String get journeyReadingTime => 'Tempo di lettura';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h h $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m min';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now min a settimana, prima $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min questa settimana';
  }

  @override
  String get journeyTimedFromToday => 'Si conta da oggi';

  @override
  String journeyPointsOffFrom(int was) {
    return 'punti fuori, prima $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · $n o meno';
  }

  @override
  String get journeyRightWhenSure => 'Giusto se sicuro';

  @override
  String journeyFromIn(String v, String month) {
    return '$v in $month';
  }

  @override
  String get journeySureNone => 'Non hai ancora detto 80% o più';

  @override
  String get journeyMovesTitle => 'Mosse che riconosci';

  @override
  String journeyOfN(int n) {
    return 'su $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Ultima: $name';
  }

  @override
  String get journeyNoneYet => 'Ancora niente';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'carte ancora con te',
      one: 'carta ancora con te',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni',
      one: 'un giorno',
    );
    return '$right su $of dopo $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks settimane',
      one: 'una settimana',
    );
    return '$right su $of dopo $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days giorni',
      one: '1 giorno',
    );
    return '$active su $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Soprattutto di mattina';

  @override
  String get journeyMostlyAfternoon => 'Soprattutto di pomeriggio';

  @override
  String get journeyMostlyEvening => 'Soprattutto di sera';

  @override
  String get journeyMostlyNight => 'Soprattutto di notte';

  @override
  String get journeyInTime => 'Nel tempo';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString anni';
  }

  @override
  String journeyFromEra(String era) {
    return 'dal $era a oggi';
  }

  @override
  String get journeyEraAncient => 'mondo antico';

  @override
  String get journeyEraMedieval => 'Medioevo';

  @override
  String get journeyEraEarlyModern => 'XVI secolo';

  @override
  String get journeyEraNineteenth => 'XIX secolo';

  @override
  String get journeyEraTwentieth => 'XX secolo';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'ancora niente di datato';

  @override
  String get journeyInPlace => 'Nel mondo';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regioni',
      one: '1 regione',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list e lo spazio';
  }

  @override
  String get journeyRegionAmericas => 'Americhe';

  @override
  String get journeyRegionEurope => 'Europa';

  @override
  String get journeyRegionAsia => 'Asia';

  @override
  String get journeyRegionOceania => 'Oceania';

  @override
  String get journeyRegionAfrica => 'Africa';

  @override
  String get journeyRegionMiddleEast => 'Medio Oriente';

  @override
  String get journeyNoPlace => 'ancora nessun luogo';

  @override
  String get journeyTopics => 'Argomenti';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n incontrati',
      one: '1 incontrato',
    );
    return '$_temp0';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return 'di cui $n in $subject';
  }

  @override
  String get journeyWords => 'Parole';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuove',
      one: '1 nuova',
    );
    return '$_temp0';
  }

  @override
  String get anotherOne => 'Un\'altra';

  @override
  String answerIs(String said) {
    return 'Risposta: $said';
  }

  @override
  String get answeredAlready => 'Già risposta';

  @override
  String get anyCard => 'Qualsiasi materia, qualsiasi scaffale, una carta';

  @override
  String betN(int n) {
    return 'Punta $n';
  }

  @override
  String get betWord => 'Punta';

  @override
  String get biggerLabel => 'Più grande';

  @override
  String get biggerYouGotIt => 'Più grande · indovinato';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Dopo $n giorni',
      one: 'Dopo un giorno',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Dopo una settimana';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Dopo $n settimane',
      one: 'Dopo una settimana',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Verifica';

  @override
  String closerDone(String said, int right, int steps) {
    return 'È $said. Ne hai indovinati $right su $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'No: è meno di $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'No: è più di $v.';
  }

  @override
  String get closerStart => 'Tre passi per avvicinarti.';

  @override
  String closerYesLess(String v) {
    return 'Giusto: è meno di $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Giusto: è più di $v.';
  }

  @override
  String get corrections => 'Rettifiche';

  @override
  String get didYouKnow => 'Lo sapevi?';

  @override
  String get didYouKnowLine => 'Girala, poi: nuova per te, o la sapevi?';

  @override
  String get dragToSet => 'Trascina per scegliere';

  @override
  String get dykAgain => 'Ancora';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n le sapevi',
      one: '1 la sapevi',
      zero: 'Nessuna la sapevi',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nuove per te',
      one: '1 nuova per te',
      zero: 'Niente di nuovo oggi',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'Questa è l\'edizione di oggi';

  @override
  String get editionTomorrow => 'Quella di domani esce al mattino';

  @override
  String get eraAncient => 'Il mondo antico';

  @override
  String get eraAncientWhen => 'Prima del 500';

  @override
  String get eraEarlyModern => 'La prima età moderna';

  @override
  String get eraEarlyModernWhen => 'Dal 1500 al 1800';

  @override
  String get eraMedieval => 'Il Medioevo';

  @override
  String get eraMedievalWhen => 'Dal 500 al 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Altre $n di quest\'epoca',
      one: 'Un\'altra di quest\'epoca',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'L\'Ottocento';

  @override
  String get eraNineteenthWhen => 'Dal 1800 al 1900';

  @override
  String get eraRecent => 'Questo secolo';

  @override
  String get eraRecentWhen => 'Dal 2000';

  @override
  String get eraRulerNow => 'Oggi';

  @override
  String get eraRulerOld => 'Antichità';

  @override
  String get eraShortAncient => 'Antichità';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Medioevo';

  @override
  String get eraShortNineteenth => 'Ottocento';

  @override
  String get eraShortRecent => 'Duemila';

  @override
  String get eraShortTwentieth => 'Novecento';

  @override
  String get eraTwentieth => 'Il secolo scorso';

  @override
  String get eraTwentiethWhen => 'Dal 1900 al 2000';

  @override
  String get fewCards => 'In poche carte';

  @override
  String get fewCardsLine => 'Quando una carta sola non basta a spiegarlo';

  @override
  String get firstLabel => 'Dal';

  @override
  String get forYouNow => 'Per te, adesso';

  @override
  String get hardBadge => 'Difficile';

  @override
  String hidesIn(String where) {
    return 'In $where';
  }

  @override
  String get howSure => 'Quanto ne sono sicuro, e perché?';

  @override
  String get inNumbers => 'In cifre';

  @override
  String inRange(int pts, String said) {
    return 'Dentro: +$pts punti. È $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'Nelle tue mosse · $n×';
  }

  @override
  String itIs(String said) {
    return 'È $said.';
  }

  @override
  String get knewIt => 'Lo sapevo';

  @override
  String get less => 'Meno';

  @override
  String get lookFirst => 'Guarda il grafico prima di credere al titolo.';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Mancato: è $said.';
  }

  @override
  String get modeBigger => 'Quale è più grande?';

  @override
  String get modeCloser => 'Più vicino';

  @override
  String get modePick => 'Scegline una';

  @override
  String get modeRange => 'Punta su un intervallo';

  @override
  String get modeSlide => 'Spostalo';

  @override
  String get modeStake => 'Fai la tua puntata';

  @override
  String get monthShelfLine => 'Una materia nuova ogni mese, uguale per tutti';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards carte',
      one: '1 carta',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'Il tempo che hai';

  @override
  String get moodTitle => 'Il tuo umore, i tuoi minuti';

  @override
  String get moodTone => 'Tono';

  @override
  String get more => 'Di più';

  @override
  String moreOrLess(String v) {
    return 'Più o meno di $v?';
  }

  @override
  String get moveComparedToWhat => 'Rispetto a cosa?';

  @override
  String get moveComparedToWhatLine =>
      'Un cambiamento non dice nulla senza qualcosa con cui confrontarlo';

  @override
  String get askingTitle => 'Una domanda per ogni materia';

  @override
  String askingIn(String subject) {
    return 'Domande su $subject';
  }

  @override
  String get askingLine =>
      'Uguali per tutti. Prima rispondi, poi scopri perché';

  @override
  String get moveSampling => 'Chi è stato contato?';

  @override
  String get moveSamplingLine =>
      'Chi finisce in uno studio decide che cosa può dirti';

  @override
  String mythDeckHint(int at, int of) {
    return '$at di $of · scorri per girarla';
  }

  @override
  String nOfM(int at, int of) {
    return '$at di $of';
  }

  @override
  String get newMove => 'Nuova per te';

  @override
  String get newToMe => 'Nuova per me';

  @override
  String get notEnoughPoints => 'Punti insufficienti';

  @override
  String get notSureLine => 'Una carta da qualsiasi parte di Astute';

  @override
  String get notSureTitle => 'Non sai da dove cominciare?';

  @override
  String get openWord => 'Apri';

  @override
  String get pickOneFirst => 'Prima scegline una';

  @override
  String get puzzleOfTheDay => 'Il rompicapo del giorno';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pt';
  }

  @override
  String get rightLastTime => 'Giusta l\'ultima volta';

  @override
  String get sameForEveryoneCaps => 'Uguale per tutti';

  @override
  String get sayFalse => 'Falso';

  @override
  String get sayTrue => 'Vero';

  @override
  String get seriesAnchors => 'Prime impressioni';

  @override
  String get seriesGrowth => 'Numeri che scappano di mano';

  @override
  String seriesMeta(int n, int m) {
    return '$n carte · circa $m min';
  }

  @override
  String get seriesOdds => 'Probabilità che ingannano';

  @override
  String get seriesRetold => 'La storia, raccontata di nuovo';

  @override
  String seriesStrand(String name) {
    return '$name, in poche carte';
  }

  @override
  String get seriesStudies => 'Perché gli studi ingannano';

  @override
  String showAllN(int n) {
    return 'Mostra tutte e $n';
  }

  @override
  String get showFewer => 'Mostra meno';

  @override
  String get sixtyAgain => 'Gioca ancora';

  @override
  String sixtyIn(int s) {
    return 'in $s secondi';
  }

  @override
  String get sixtyLine => 'Otto vero o falso. Segui l\'istinto';

  @override
  String get sixtyPerfect => 'Tutte e otto giuste.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giuste finora',
      one: '1 giusta finora',
      zero: 'Ancora nessuna giusta',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'secondi per otto\nvero o falso';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Via';

  @override
  String get sixtyTimeUp => 'prima che scadesse il tempo';

  @override
  String get sixtyTitle => 'Sessanta secondi';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hai sbagliato di $n punti.',
      one: 'Hai sbagliato di 1 punto.',
      zero: 'Centrato.',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => 'Puntata';

  @override
  String stepOf(int at, int of) {
    return 'Passo $at di $of';
  }

  @override
  String get surpriseMe => 'Sorprendimi';

  @override
  String get tapIfBigger => 'Tocca se è più grande';

  @override
  String get tapToTurn => 'Tocca per girarla';

  @override
  String get tfRight => 'Giusto. Aprila per sapere perché.';

  @override
  String tfWrong(String side) {
    return 'È $side. Aprila per sapere perché.';
  }

  @override
  String theAnswer(String said) {
    return 'La risposta: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'In apertura';

  @override
  String get throughTime => 'Nel tempo';

  @override
  String get throughTimeLine =>
      'Dal mondo antico a quest\'anno. Trascina, o scrivi un anno';

  @override
  String leanHint(String or) {
    return 'Trascina la «$or» fin dove la pensi';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'di poco',
      '2': 'tutto sommato',
      '3': 'con decisione',
      'other': 'fino in fondo',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Hai scelto $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Aprila per sentire l\'altra campana.';
  }

  @override
  String get spotTitle => 'Trova quella falsa';

  @override
  String get spotLine => 'Tre sono vere. Una no.';

  @override
  String get spotPrompt => 'Tocca quella che secondo te è falsa';

  @override
  String get spotConfirm => 'È questa quella falsa';

  @override
  String get spotFound => 'Trovata. Le altre tre sono vere.';

  @override
  String get spotMissed => 'Non questa: è vera. Quella falsa è barrata.';

  @override
  String get spotWhy => 'Toccane una per leggere il perché';

  @override
  String get spotYours => 'La tua scelta';

  @override
  String get yearHint => 'Scrivi un anno';

  @override
  String get yearAd => 'd.C.';

  @override
  String get yearBc => 'a.C.';

  @override
  String yearNamed(String year) {
    return '$year';
  }

  @override
  String yearAdOf(String year) {
    return '$year d.C.';
  }

  @override
  String yearBcOf(String year) {
    return '$year a.C.';
  }

  @override
  String get yearGo => 'Vai a quest\'anno';

  @override
  String yearNearest(String year) {
    return 'Prima le più vicine al $year';
  }

  @override
  String yearNoneNamed(String year) {
    return 'Nessuna carta qui nomina un anno vicino al $year. Queste sono della sua epoca.';
  }

  @override
  String yearNoAge(String year) {
    return 'Oggi qui non c\'è niente di vicino al $year. Questa è l\'epoca più vicina.';
  }

  @override
  String yearFuture(String year) {
    return 'Il $year deve ancora venire. Ecco questo secolo.';
  }

  @override
  String get yearZero => 'L\'anno 0 non è mai esistito. Prova 1 a.C. o 1 d.C.';

  @override
  String get todayLabel => 'Oggi';

  @override
  String get todaysEdition => 'Edizione di oggi';

  @override
  String get toneCurious => 'Curioso';

  @override
  String get toneLight => 'Leggero';

  @override
  String get toneSerious => 'Serio';

  @override
  String get toneTough => 'Tosto';

  @override
  String get unmaskBack => 'Mostralo com\'era';

  @override
  String get unmaskFlipped => 'Rimettilo dritto';

  @override
  String get unmaskLine => 'Stessi numeri, un\'altra immagine';

  @override
  String get unmaskStretched => 'Usa una scala onesta';

  @override
  String get unmaskTitle => 'Smaschera il grafico';

  @override
  String get unmaskTotals => 'Rendi il confronto equo';

  @override
  String get unmaskTruncated => 'Fai partire l\'asse da zero';

  @override
  String get unmaskWindow => 'Mostra tutta la serie';

  @override
  String get whatIfTrue => 'E se fosse vero?';

  @override
  String get whatIfTrueLine =>
      'Carte che continuano a lavorare dopo che le chiudi';

  @override
  String get whatYouBelieve => 'Ciò in cui credi';

  @override
  String get wrongLastTime => 'Sbagliata l\'ultima volta';

  @override
  String youLose(int n) {
    return 'Perdi $n.';
  }

  @override
  String youWin(int n) {
    return 'Vinci $n.';
  }

  @override
  String get yourPick => 'La tua scelta';
}
