// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
    return 'LE $word DI OGGI · SCORRI PER RIVEDERE';
  }

  @override
  String weekLine(int days) {
    return 'La tua settimana · $days su 7 tenuti';
  }

  @override
  String get tapToFlip => 'TOCCA PER GIRARE';

  @override
  String get shareThisCard => 'Condividi questa carta';

  @override
  String get removeFromSaved => 'Togli dai salvati';

  @override
  String get saveThisPill => 'Salva questa pillola';

  @override
  String get shareThisPill => 'Condividi questa pillola';

  @override
  String cardOf(int k, int n) {
    return 'Carta $k di $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '${h}h ${m}m';
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
  String get fiveMore => 'Altre cinque';

  @override
  String get unlockFiveExtra => 'Sblocca cinque pillole extra';

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
  String get onesThatAskTheMost => 'Quelle che chiedono di più';

  @override
  String get acrossEveryone => 'Tra tutti, non solo nel tuo mix';

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
      'Nessuna pillola corrisponde ancora a questo filtro.';

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
      'Serie, pillole salvate e record restano sul tuo account. Questo li cancella da questo dispositivo.';

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
      'Cancella tutto su questo dispositivo — serie, pillole salvate, risposte, il tuo record di giudizi, materie e piano — e riapre l\'introduzione.';

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
      'Le tue 5 pillole, prima del primo caffè.';

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
      'Promemoria acceso, ma il sistema ha detto di no. Attiva le notifiche per Astut nelle impostazioni.';

  @override
  String get nudgeOnNeedsPhone =>
      'Promemoria acceso. Per riceverlo serve la versione per telefono.';

  @override
  String get howMuchYouKnow => 'Quanto ne sai';

  @override
  String savedN(int n) {
    return 'Salvate · $n';
  }

  @override
  String get manageSubscription => 'Gestisci abbonamento';

  @override
  String get howPillsAreWritten => 'Come sono scritte le pillole';

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
  String get seeEveryPrincipleWithPlus => 'Vedi ogni principio con Astut plus';

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
      'La misurazione è in corso. Astut+ ti mostra in che direzione va.';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 giorni gratis';

  @override
  String get watchTheGapMove => 'Guarda il divario muoversi.';

  @override
  String get measurementFreeForever =>
      'La misurazione è gratis e lo sarà sempre. Astut+ è ciò che ti dice in che direzione va.';

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
      other: 'pillole lette',
      one: 'pillola letta',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pillole lette',
      one: '1 pillola letta',
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
  String get streakReset => 'Serie azzerata';

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
      other: '$n pillole non lette',
      one: '1 pillola non letta',
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
  String get whatYouAlready => 'Cosa già ';

  @override
  String get know => 'sai';

  @override
  String get knowIntro =>
      'Le materie che hai spinto più in alto. Cambia cosa una giornata ti chiede in ciascuna — solido riceve domande, curioso riceve spiegazioni — non quanta ne ricevi.';

  @override
  String get startWithMyFirstCards => 'Inizia con le mie prime carte';

  @override
  String get skipForNow => 'Salta per ora';

  @override
  String get levelCurious => 'Curioso';

  @override
  String get levelSome => 'Un po\'';

  @override
  String get levelSolid => 'Solido';

  @override
  String get save => 'Salva';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n materie su $total nel mix';
  }

  @override
  String get yourSpace => 'Il tuo ';

  @override
  String get mix => 'mix';

  @override
  String get everythingIsInDrag =>
      'C\'è tutto. Trascina una materia verso il basso per vederne meno, o fino a zero per toglierla.';

  @override
  String get next => 'Avanti';

  @override
  String get whatShouldWeTalkAbout => 'Di cosa parliamo?';

  @override
  String get fivePillsADayPick =>
      'Cinque pillole al giorno, scritte fresche ogni mattina. Scegli le materie che vuoi nel mix — puoi cambiarle dopo.';

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
  String get introTopicsTitle => 'Dodici materie, cinque pillole';

  @override
  String get introTopicsLine =>
      'Scritte fresche ogni mattina, e verificate su una fonte.';

  @override
  String get introQuestionTitle => 'Una domanda, poi la risposta';

  @override
  String get introQuestionLine =>
      'Ogni pillola porta la frase che vale la pena dire ad alta voce.';

  @override
  String get introMixTitle => 'Il mix lo scegli tu';

  @override
  String get introMixLine =>
      'Abbassa una materia per vederne meno, o spegnila del tutto.';

  @override
  String get introThirtyTitle => 'Trenta secondi al giorno';

  @override
  String get introThirtyLine =>
      'Una notifica, cinque carte, e una serie che non vorrai spezzare.';

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
  String get barMoveCaps => 'LA MOSSA DA BAR';

  @override
  String get theBarMoveCaps => 'LA MOSSA DA BAR';

  @override
  String get dayStreakCaps => 'GIORNI DI SERIE';

  @override
  String sourceLabel(String source) {
    return 'Fonte · $source';
  }

  @override
  String get perkRecordTitle => 'Il tuo record nel tempo';

  @override
  String get perkRecordLine =>
      'Se il divario tra quanto eri sicuro e quanto avevi ragione si sta davvero chiudendo.';

  @override
  String get perkPrinciplesTitle => 'Ogni principio che hai incontrato';

  @override
  String get perkPrinciplesLine =>
      'Non solo i tre in cui vai peggio — tutti, e i contesti che non hai ancora visto.';

  @override
  String get perkFreezesTitle => 'Tre freeze per la serie, non uno';

  @override
  String get perkFreezesLine =>
      'Abbastanza per un weekend fuori. Una serie che puoi solo perdere è una serie che prima o poi se ne va.';

  @override
  String get perkExtraTitle => '5 pillole extra ogni giorno';

  @override
  String get perkExtraLine =>
      'Un secondo set si sblocca appena finisci il primo.';

  @override
  String get perkArchiveTitle => 'L\'archivio completo';

  @override
  String get perkArchiveLine =>
      'Ogni pillola che hai letto, cercabile per materia.';

  @override
  String get perkTopicsTitle => 'Scegli le tue materie';

  @override
  String get perkTopicsLine => 'Pesa il mix verso quello che ti piace davvero.';

  @override
  String get plusIsActive => 'ASTUT+ È ATTIVO';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Prova 7 giorni gratis, poi $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Prova avviata. Nessun pagamento è collegato in questa versione.';

  @override
  String get thatDidNotGoThrough => 'Non è andata a buon fine.';

  @override
  String get plusIsBack => 'Astut+ è tornato.';

  @override
  String get nothingToRestore => 'Niente da ripristinare su questo account.';

  @override
  String get findOutIfBetter => 'Scopri se stai davvero migliorando.';

  @override
  String get perYear => 'all\'anno';

  @override
  String aMonth(String price) {
    return '$price al mese';
  }

  @override
  String savePercent(int n) {
    return 'RISPARMI IL $n%';
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
  String get everythingOpensNothingCharged =>
      'Si apre tutto. Non paghi niente.';

  @override
  String dayN(int n) {
    return 'GIORNO $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Un promemoria, due giorni prima del rinnovo.';

  @override
  String get itRenewsUnlessCancelled =>
      'Si rinnova, a meno che tu non abbia disdetto. Puoi farlo quando vuoi.';

  @override
  String get howTheFreeWeekWorks => 'COME FUNZIONA LA SETTIMANA GRATIS';

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
  String get shareMyDay => 'Condividi la mia giornata';

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
      other: '$n carte sono tornate — rispondi di nuovo',
      one: '1 carta è tornata — rispondi di nuovo',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Tornate';

  @override
  String get holdACardYouLike => 'Tieni premuta una carta che ti piace';

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
  String get likeThisPill => 'Mi piace questa pillola';

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
      'Tocca il segnalibro su una pillola e finisce qui — quelle che ti hanno cambiato il modo di pensare, tenute.';
}
