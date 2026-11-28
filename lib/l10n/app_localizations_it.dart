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
  String get freezeKeptStreak => 'Un jolly ha salvato la serie';

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
  String dayTitle(int n) {
    return 'Giorno $n';
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
  String get share => 'Condividi';

  @override
  String cardOf(int k, int n) {
    return 'Carta $k di $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Le cinque di domani · tra $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return 'Domani: $topic · tra $when';
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
    return 'Ancora niente per «$query».';
  }

  @override
  String matching(int n) {
    return '$n trovate';
  }

  @override
  String get all => 'Tutte';

  @override
  String get theArchive => 'L’archivio';

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
    return 'Niente per «$query». Prova con una materia.';
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
  String get backToTodaysFive => 'Torna alle cinque di oggi';

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
      'Quelle su cui vale la pena tornare. Sbagliare qualcosa di cui eri sicuro è l’unico modo economico per scoprire cosa credi davvero.';

  @override
  String get whereThisIsGoing => 'Dove sta andando';

  @override
  String ofNRight(int n) {
    return 'su $n giuste';
  }

  @override
  String get sayHowSureOnMore =>
      'Di’ quanto sei sicuro su qualche altra carta e l’app ti dirà quanto vale quella sicurezza.';

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
    return 'Eri sicuro al $n%';
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
      'reading': 'L’abitudine è partita.',
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
    return 'ancora $n risposte prima che l’app giudichi la tua sicurezza';
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
  String scoreLevel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'curiosity': 'Curiosità',
      'observation': 'Osservazione',
      'method': 'Metodo',
      'judgement': 'Giudizio',
      'insight': 'Intuito',
      'discernment': 'Discernimento',
      'acumen': 'Acume',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => 'Nuovo livello';

  @override
  String levelUpGain(String skill, String n) {
    return 'La crescita più grande della settimana: $skill, $n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n risposte finora.',
      one: 'Una risposta finora.',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => 'Livello';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$level tra $n punti',
      one: '$level tra 1 punto',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$level tra $n risposte',
      one: '$level tra 1 risposta',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => 'Il livello più alto';

  @override
  String get levelShareTitle => 'Condividi il tuo livello';

  @override
  String get signOutQuestion => 'Vuoi uscire?';

  @override
  String get signOutBody =>
      'Serie, carte salvate e record restano sul tuo account. Questo li cancella da questo dispositivo.';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deletingAccount => 'Eliminazione dell’account…';

  @override
  String get deleteAccountQuestion => 'Eliminare il tuo account?';

  @override
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'l’abbonamento si gestisce nelle impostazioni dell’App Store.',
      'google': 'l’abbonamento si gestisce in Google Play, in Pagamenti e abbonamenti.',
      'other': 'l’abbonamento si gestisce nello store in cui l’hai acquistato.',
    });
    return 'Il tuo account e il suo backup vengono eliminati per sempre, e questo dispositivo riparte dall’inizio. Astute+ non viene disdetto: $_temp0';
  }

  @override
  String get deleteAccountConfirm => 'Elimina per sempre';

  @override
  String get accountDeleted => 'Il tuo account è stato eliminato.';

  @override
  String get couldNotDeleteAccount =>
      'Non è stato possibile eliminare l’account. Riprova tra poco.';

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
      'L’accesso non è disponibile in questa versione.';

  @override
  String get startOverQuestion => 'Ricominciare da capo?';

  @override
  String get startOverBody =>
      'Cancella tutto su questo dispositivo — serie, carte salvate, risposte, il tuo record di giudizi, materie e piano — e riapre l’introduzione.';

  @override
  String get wipeIt => 'Cancella';

  @override
  String get yourRecord => 'Il tuo record';

  @override
  String get profileTodayFive => 'Le cinque di oggi';

  @override
  String profileTodayOf(int read, int of) {
    return '$read su $of';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n da leggere',
      one: '1 da leggere',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores =>
      'Tutti i tuoi punteggi, settimana per settimana';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'giorni di fila',
      one: 'giorno di fila',
    );
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => 'Ultimi 7 giorni';

  @override
  String profileWeekPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'punti',
      one: 'punto',
    );
    return '$_temp0';
  }

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
  String get yourCards => 'Le tue carte';

  @override
  String get emptyLikedHint => 'Tieni premuta una carta che ti piace';

  @override
  String get emptySavedHint => 'Tocca il segnalibro su una carta';

  @override
  String get lastSevenDays => 'Ultimi 7 giorni';

  @override
  String get accountSection => 'Account';

  @override
  String get aboutSection => 'Info';

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
  String get howStep2Title => 'Con le sue fonti, poi riletta da un critico';

  @override
  String get howStep2Line =>
      'Ogni carta dice da dove vengono i suoi fatti, e tre su quattro portano all’originale con un tocco, così puoi controllarli da te. La maggior parte viene letta da un secondo modello che fa da critico, e ciò che non riesce a confermare finisce in un elenco che controlla una persona. Quell’elenco non è ancora vuoto.';

  @override
  String get howStep3Title => 'Cinque, distribuite ogni mattina';

  @override
  String get howStep3Line =>
      'Dalle materie che hai scelto, carte che non hai ancora letto. Una a cui hai risposto giusto torna più avanti, per vedere se ti è rimasta.';

  @override
  String get howStep4Title => 'Tenute oneste dai lettori';

  @override
  String get howStep4Line =>
      'Quando abbastanza lettori dicono che una carta è sbagliata, smette di essere distribuita finché una persona non l’ha controllata.';

  @override
  String get howReportTitle => 'Hai trovato un errore?';

  @override
  String get howReportLine =>
      'Tocca la bandierina accanto alla fonte di una carta per segnalarla.';

  @override
  String get howFoot =>
      'Leggiamo ogni segnalazione, e preferiamo correggere una carta piuttosto che difenderla.';

  @override
  String get signingIn => 'Accesso in corso…';

  @override
  String get signInWithApple => 'Accedi con Apple';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'In $n risposte hai detto quanto eri sicuro. Ecco com’è andata.';
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
  String get shareMyRecord => 'Condividi il mio record';

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
  String get seeThePlans => 'Vedi i piani';

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
      other: '$n jolly disponibili',
      one: '1 jolly disponibile',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Piano gratuito';

  @override
  String get welcomeBack => 'Bentornato';

  @override
  String get comebackTitle => 'Che bello rivederti.';

  @override
  String get comebackStillYours => 'Resta tuo';

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
  String get reminderAskTitle => 'A che ora vuoi il promemoria?';

  @override
  String get reminderAskLine =>
      'Una notifica al giorno, con una domanda dalle tue carte.';

  @override
  String get reminderAskTrialLine =>
      'Ti avviseremo due giorni prima della fine del periodo di prova.';

  @override
  String get reminderAskMorning => 'Mattina';

  @override
  String get reminderAskLunch => 'Pranzo';

  @override
  String get reminderAskEvening => 'Sera';

  @override
  String get reminderAskOther => 'Un altro orario';

  @override
  String get reminderAskPick => 'Scegli tu';

  @override
  String get reminderAskUsual => 'Quando leggi di solito';

  @override
  String get reminderAskYes => 'Ricordamelo';

  @override
  String get reminderAskNotNow => 'Non ora';

  @override
  String get placeAskTitle => 'Carte sul posto in cui vivi';

  @override
  String get placeAskLine =>
      'Ogni tanto Astute ti darà una carta sul posto in cui vivi — la sua storia, la sua scienza, le sue sorprese.';

  @override
  String get placeOnlyCity =>
      'Conserviamo solo la tua città, mai la tua posizione esatta.';

  @override
  String get placeAskPreviewLine => 'Vicino a te · Modena';

  @override
  String get placeAskPreviewQuestion => 'La Ghirlandina pende. Di quanto?';

  @override
  String get placeAskYes => 'Usa la mia posizione';

  @override
  String get placeAskNotNow => 'Non ora';

  @override
  String get placeRowTitle => 'Dove vivi';

  @override
  String get placeRowOff => 'Disattivato';

  @override
  String get placeRowOffLine =>
      'Attivalo per avere carte sul posto in cui vivi.';

  @override
  String get placeSwitchOn => 'Attiva';

  @override
  String get placeUseNow => 'Usa la mia posizione ora';

  @override
  String get placeRemove => 'Rimuovi';

  @override
  String placeSetTo(String place) {
    return 'Dove vivi: $place';
  }

  @override
  String get placeRemoved =>
      'Rimosso. Astute non conserva più il posto in cui vivi.';

  @override
  String get placeNotFound =>
      'Per ora non è stato possibile capire dove sei. Astute riproverà un altro giorno.';

  @override
  String get placeDeniedNote =>
      'Nessun problema. Puoi attivarlo quando vuoi in Profilo.';

  @override
  String get placeServicesOff =>
      'La localizzazione è spenta su questo telefono. Attivala nelle impostazioni e riprova.';

  @override
  String get placeNotHere => 'Questo dispositivo non può dire dove sei.';

  @override
  String get placeSettingsTitle => 'La posizione è disattivata per Astute';

  @override
  String get placeSettingsBody =>
      'Per avere carte sul posto in cui vivi, consenti ad Astute di usare la posizione nelle impostazioni. Conserviamo solo la tua città.';

  @override
  String get placeSettingsOpen => 'Apri Impostazioni';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Il tuo periodo di prova di Astute+ finisce tra $days giorni.',
      one: 'Il tuo periodo di prova di Astute+ finisce domani.',
      zero: 'Il tuo periodo di prova di Astute+ finisce oggi.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return 'Il $date inizia il tuo anno di abbonamento a $price. Per continuare, non devi fare nulla. Per disdire: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Il tuo periodo di prova finisce tra $days giorni',
      one: 'Il tuo periodo di prova finisce domani',
      zero: 'Il tuo periodo di prova finisce oggi',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Gestisci';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n materie su $total nel mix';
  }

  @override
  String get everythingIsInDrag =>
      'C’è tutto. Fai scorrere una materia verso sinistra per vederne meno, o fino in fondo per toglierla.';

  @override
  String get next => 'Avanti';

  @override
  String get whatShouldWeTalkAbout => 'Di cosa parliamo?';

  @override
  String get fivePillsADayPick =>
      'Cinque carte al giorno, nuove ogni mattina. Scegli le materie che vuoi nel mix — puoi cambiarle dopo.';

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
      'Capisci il perché delle cose e scopri quanto fidarti di quello che sai';

  @override
  String get introTopicsTitle => 'Venti materie, cinque carte';

  @override
  String get introTopicsLine =>
      'Scritte prima da un modello, e ognuna cita la sua fonte.';

  @override
  String get introQuestionTitle =>
      'Una domanda, quanto sei sicuro, poi il perché';

  @override
  String get introQuestionLine =>
      'Prima di’ quanto sei sicuro. Col tempo scopri quanto vale il tuo «sono sicuro».';

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
  String get startReading => 'Inizia a leggere';

  @override
  String get haveAnAccount => 'Hai già un account?';

  @override
  String get signInLink => 'Accedi';

  @override
  String get signInWelcomeTitle => 'Bentornato';

  @override
  String get signInWelcomeLine =>
      'Accedi, e la tua serie, le carte salvate e il tuo record tornano con te.';

  @override
  String get keepStreakOnNewPhone => 'Porta la tua serie su un nuovo telefono';

  @override
  String get keepStreakTitle => 'Non perdere la tua serie';

  @override
  String get keepStreakLine =>
      'Accedi, e un nuovo telefono riparte da dove si ferma questo: la tua serie, le carte salvate, il tuo record.';

  @override
  String get signInNotNow => 'Non ora';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': 'Pensiero',
      'science': 'Scienza',
      'maths': 'Matematica',
      'space': 'Spazio',
      'psychology': 'Psicologia',
      'economics': 'Economia',
      'technology': 'Tecnologia',
      'history': 'Storia',
      'human_body': 'Corpo umano',
      'philosophy': 'Filosofia',
      'pop_culture': 'Cultura pop',
      'nature': 'Natura',
      'language': 'Lingua',
      'weird_facts': 'Stranezze',
      'sport': 'Sport',
      'cinema': 'Cinema',
      'music': 'Musica',
      'art': 'Arte',
      'medicine': 'Medicina',
      'food': 'Cibo',
      'life': 'Vita',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get cardsInEnglishNote =>
      'Le carte, per ora, sono in inglese; l’app parla la tua lingua.';

  @override
  String termsLine(String terms, String privacy) {
    return 'Continuando accetti i $terms e l’$privacy';
  }

  @override
  String get termsLineTerms => 'Termini d’uso';

  @override
  String get termsLinePrivacy => 'Informativa sulla privacy';

  @override
  String get skip => 'Salta';

  @override
  String get tapToRevealLower => 'tocca per scoprire';

  @override
  String get barMoveCaps => 'DA PORTARE CON TE';

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
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return 'Approfondisci. Fonte: $source';
  }

  @override
  String get sourceKindPaper => 'Studio';

  @override
  String get sourceKindBook => 'Libro';

  @override
  String get sourceKindInstitution => 'Istituzione';

  @override
  String get sourceKindDocument => 'Documento';

  @override
  String get sourceKindData => 'Dati';

  @override
  String get sourceKindReference => 'Opera di riferimento';

  @override
  String get sourceKindNews => 'Giornale';

  @override
  String get sourceKindCompany => 'Fonte aziendale';

  @override
  String get sourceKindStandard => 'Norma tecnica';

  @override
  String get sourceKindArithmetic => 'Calcolo';

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
  String get paywallRecordTitle => 'Scopri quanto ne sai davvero.';

  @override
  String get paywallRecordMark => 'davvero.';

  @override
  String get paywallRecordLine =>
      'Ogni giorno dici quanto sei sicuro. Astute+ ti mostra se il divario tra sicurezza e risposte giuste si chiude, e le mosse che sbagli più spesso.';

  @override
  String paywallRecordOver(int sure, int right) {
    return 'Ti dici sicuro al $sure% e hai ragione $right volte su 100. Astute+ ti mostra se quel divario si chiude, e le mosse che sbagli più spesso.';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return 'Ti dici sicuro al $sure% e hai ragione $right volte su 100: ne sai più di quanto pensi. Astute+ ti mostra se quel divario si chiude.';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return 'Ti dici sicuro al $sure% e hai ragione $right volte su 100: quasi alla pari. Astute+ ti mostra se regge, e le mosse che sbagli più spesso.';
  }

  @override
  String get paywallOutcomeTitle => 'Diventa chi non si fa fregare.';

  @override
  String get paywallOutcomeMark => 'fregare.';

  @override
  String get paywallOutcomeLine =>
      'Cinque carte al giorno al tuo livello. Quelle che sbagli tornano finché non restano. E vedi come cambi, settimana per settimana.';

  @override
  String get paywallFiveTitle => 'Cinque carte, tutte tue.';

  @override
  String get paywallFiveMark => 'tue.';

  @override
  String get paywallFiveLine =>
      'Gratis ne hai due scelte per te, tre dopo una settimana di fila. Astute+ sceglie tutte e cinque dai tuoi filoni, al tuo livello, e riporta quelle che sbagli.';

  @override
  String get paywallReadTitle => 'Quello che hai letto, giorno per giorno.';

  @override
  String get paywallReadMark => 'giorno per giorno.';

  @override
  String get paywallReadLine =>
      'Gli ultimi giorni che hai letto, dal più recente. Toccane uno per aprirne le cinque carte, e una carta per rileggerla.';

  @override
  String get perkGapTitle => 'Guarda il divario chiudersi';

  @override
  String get perkGapLine =>
      'Ogni settimana: quanto sei sicuro contro quanto ci prendi, e cosa sbagli di più.';

  @override
  String get perkOwnFiveTitle => 'Le tue cinque carte';

  @override
  String get perkOwnFiveLine =>
      'Ogni giorno, al tuo livello, e quelle che sbagli tornano.';

  @override
  String get perkReadTitle => 'Quello che hai letto';

  @override
  String get perkReadLine =>
      'I tuoi ultimi giorni, ognuno con le sue cinque carte, pronti da riaprire.';

  @override
  String get perkAskTitle => 'Il tuo assistente';

  @override
  String get perkAskLine => 'Ti spiega ogni carta e ti mette alla prova.';

  @override
  String get perkCoachTitle => 'Un coach ogni settimana';

  @override
  String get perkCoachLine => 'Dove sbagli, e cosa allenare dopo.';

  @override
  String get perkNew => 'NUOVO';

  @override
  String get threeTitle => 'Le tre di oggi';

  @override
  String threeStep(int n, int total) {
    return '$n di $total';
  }

  @override
  String get threeSame => 'Le stesse tre per tutti, oggi. Circa un minuto.';

  @override
  String threeYouSaid(String guess) {
    return 'Avevi detto $guess.';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n punti',
      one: '+1 punto',
      zero: 'Nessun punto',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => 'Avanti';

  @override
  String get threeSeeScore => 'Vedi il punteggio';

  @override
  String get threeDone => 'Le tre di oggi · fatto';

  @override
  String get threeYou => 'Tu';

  @override
  String whyMissing(String move) {
    return 'Una mossa che ti sfugge: $move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move: torna in un caso nuovo';
  }

  @override
  String get whyAgain => 'Torna per un secondo sguardo';

  @override
  String whyGoal(String goal) {
    return 'Per il tuo obiettivo: $goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Simile a $n carte che ti sono piaciute',
      one: 'Simile a una carta che ti è piaciuta',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return 'Una difficile: in $subject sei forte';
  }

  @override
  String whyLevel(String subject) {
    return 'Al tuo livello in $subject';
  }

  @override
  String whyGentle(String subject) {
    return 'Un modo facile per entrare in $subject';
  }

  @override
  String whyYourSubject(String subject) {
    return 'Da $subject, una delle tue materie';
  }

  @override
  String get whyRandom => 'Pescata a caso tra le tue materie';

  @override
  String get whyTitle => 'Perché questa carta';

  @override
  String whyTrains(String move) {
    return 'Allena: $move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'L’hai incontrata $n volte.',
      one: 'L’hai incontrata una volta.',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Giusta $n volte.',
      one: 'Giusta una volta.',
      zero: 'Ancora nessuna giusta.',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return 'Il tuo livello in $subject';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': 'Agli inizi',
      'some': 'Discreto',
      'strong': 'Forte',
      'other': 'Discreto',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => 'L’ultima volta con questa mossa';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni fa',
      one: 'Ieri',
      zero: 'Oggi',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => 'Il tuo obiettivo';

  @override
  String get whyLikedRow => 'Carte simili che ti sono piaciute';

  @override
  String get whyRandomLine =>
      'Con il piano gratuito, una parte di ogni giorno è pescata a caso tra le materie che hai scelto.';

  @override
  String get whyPlusLine =>
      'Con Astute+ tutte e cinque sono scelte per te: al tuo livello, secondo i tuoi gusti, e le mosse che ti sfuggono tornano.';

  @override
  String get whyMakeMine => 'Rendi mie tutte e cinque';

  @override
  String get whyMore => 'Di più così';

  @override
  String get whyMoreDone => 'Ne vedrai di più';

  @override
  String get whyLess => 'Meno';

  @override
  String get whyTune => 'Regola il tuo mix';

  @override
  String get searchTry => 'Prova';

  @override
  String get searchByNeed => 'Per bisogno';

  @override
  String get searchByKind => 'Per tipo';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': 'Da giocare',
      'quiz': 'Quiz',
      'estimate': 'Stime',
      'debate': 'Dibattiti',
      'quick': 'Letture veloci',
      'other': 'Carte',
    });
    return '$_temp0';
  }

  @override
  String kindCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte',
      one: '1 carta',
    );
    return '$_temp0';
  }

  @override
  String get areaUsefulFor => 'Ti serve per';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n percorsi · dieci carte ciascuno',
      one: 'Un percorso · dieci carte',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => 'Le mosse che alleni qui';

  @override
  String get areaMoreCards => 'Altre carte per questo';

  @override
  String get pathKicker => 'Percorso';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · $n carte · circa $minutes min';
  }

  @override
  String pathPartOf(int part, int parts) {
    return 'Parte $part di $parts';
  }

  @override
  String pathTrains(String moves) {
    return 'Allena: $moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return '$n su $total lette';
  }

  @override
  String get pathFreeTag => 'Gratis';

  @override
  String get pathStart => 'Inizia il percorso';

  @override
  String pathContinueAt(int n) {
    return 'Continua · carta $n';
  }

  @override
  String get pathContinue => 'Continua';

  @override
  String get notesTitle => 'Note';

  @override
  String get noteYours => 'La tua nota';

  @override
  String get noteAdd => 'Aggiungi una nota';

  @override
  String get noteEdit => 'Modifica';

  @override
  String get noteSave => 'Salva';

  @override
  String get noteDelete => 'Elimina la nota';

  @override
  String get noteHint => 'Cosa vuoi ricordare di questa carta?';

  @override
  String get notesEmpty =>
      'Ancora nessuna nota. Apri una carta che hai salvato e scrivi cosa vuoi ricordare.';

  @override
  String get pathUnlock => 'Sblocca tutti i percorsi';

  @override
  String get pathFreeLine => 'Le prime due carte di ogni percorso sono gratis.';

  @override
  String pathNextPart(int n) {
    return 'Parte $n: vai più a fondo';
  }

  @override
  String pathDeeperLine(int n) {
    return 'Altre $n carte sullo stesso tema, più difficili.';
  }

  @override
  String get pathAgain => 'Rileggilo';

  @override
  String get subjectKicker => 'Materia';

  @override
  String subjectReadOf(int n, int total) {
    return '$n carte lette su $total';
  }

  @override
  String subjectRight(int right, int answered) {
    return '$right giuste su $answered risposte';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n risposte giuste al livello $level',
      one: 'Una risposta giusta al livello $level',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => 'Livello';

  @override
  String get subjectNext => 'La prossima per te';

  @override
  String get subjectNextLine => 'Un gradino sopra il tuo livello.';

  @override
  String subjectInside(String subject) {
    return 'Dentro $subject';
  }

  @override
  String get journeySubjectsTap => 'Tocca una materia per la sua pagina.';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Frequenze di base',
      'survivorship': 'Il sopravvissuto',
      'regression': 'Ritorno alla media',
      'confirmation': 'Conferma',
      'anchoring': 'Ancoraggio',
      'sampling': 'Campione',
      'confounding': 'Fattori nascosti',
      'counterfactual': 'Rispetto a cosa',
      'multipleComparisons': 'Troppi tentativi',
      'availability': 'Disponibilità',
      'sunkCost': 'Costi sommersi',
      'conjunction': 'Congiunzione',
      'conditional': 'Probabilità condizionata',
      'independence': 'Indipendenza',
      'coincidence': 'Coincidenze',
      'exponential': 'Crescita esponenziale',
      'reflection': 'La risposta rapida',
      'simpson': 'Aggregati',
      'estimation': 'Stima',
      'computation': 'Fare i conti',
      'other': 'Ragionamento',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate':
          'L’accuratezza di un test non è la probabilità che riguardi te',
      'survivorship': 'I dati che hai sono quelli sopravvissuti',
      'regression': 'Gli estremi tornano indietro da soli',
      'confirmation': 'Cercare un sì non è una prova',
      'anchoring': 'Il primo numero detto sposta tutti quelli dopo',
      'sampling': 'Chi finisce nel campione decide cosa può dire',
      'confounding': 'Forse qualcos’altro causa entrambe le cose',
      'counterfactual': 'Un cambiamento non dice nulla senza un confronto',
      'multipleComparisons': 'Prova abbastanza cose e una passerà',
      'availability': 'Facile da immaginare non vuol dire frequente',
      'sunkCost': 'Speso è speso: si decide solo su ciò che resta',
      'conjunction':
          'I dettagli rendono una storia più credibile e meno probabile',
      'conditional': 'Quello che sai cambia le probabilità',
      'independence': 'Il caso non ha memoria',
      'coincidence': 'Le cose rare sono comuni quando i tentativi sono tanti',
      'exponential': 'Nessuno ha intuito per i raddoppi',
      'reflection': 'La risposta che arriva per prima è quella da controllare',
      'simpson':
          'Un insieme può pendere da un lato dove nessuna sua parte pende',
      'estimation': 'Spezza l’impossibile in cose che puoi stimare',
      'computation': 'Un problema che puoi davvero finire',
      'other': 'Ragionamento',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => 'Mandalo';

  @override
  String get threeWhy => 'Vedi il perché';

  @override
  String threeYesterday(int score) {
    return 'Le tre di ieri: $score su 300.';
  }

  @override
  String get fiveTitle => 'Le cinque di oggi';

  @override
  String get fiveSame => 'Le stesse cinque per tutti, oggi. Circa due minuti.';

  @override
  String get fiveDone => 'Le cinque di oggi · fatto';

  @override
  String dailyOf(int max) {
    return 'su $max';
  }

  @override
  String dailyPickRight(String answer) {
    return 'Giusta: $answer';
  }

  @override
  String dailyPickWrong(String answer) {
    return 'Non proprio. Giusta: $answer';
  }

  @override
  String dailyYourPick(String answer) {
    return 'La tua: $answer';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Meglio del $pct% dei $n giocatori di oggi.',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Finora $n giocatori oggi.',
      one: 'Finora 1 giocatore oggi.',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Tra i primi $n a giocare oggi: ancora troppo pochi per un confronto.',
      one: 'Il primo a giocare oggi: ancora troppo pochi per un confronto.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => 'Conto i giocatori di oggi…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return 'Ne hai indovinate $right su $total. Su queste, i lettori ne indovinano in media $avg.';
  }

  @override
  String get dailyUncounted =>
      'Ora non si possono contare i giocatori di oggi.';

  @override
  String get dailyEach => 'Domanda per domanda';

  @override
  String dailyItemRight(int pct) {
    return 'L’ha azzeccata il $pct% dei giocatori di oggi';
  }

  @override
  String dailyItemGuess(String guess) {
    return 'Stima media di oggi: $guess';
  }

  @override
  String get dailyItemFew => 'Ancora troppo poche risposte per un confronto';

  @override
  String fiveYesterday(int score) {
    return 'Le cinque di ieri: $score su 500.';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · Le cinque di oggi · $date';
  }

  @override
  String fiveChallengeLine(int right) {
    return 'Ho indovinato $right delle cinque di oggi su Astute. Riesci a battermi?';
  }

  @override
  String get fiveChallengeAll =>
      'Ho indovinato tutte le cinque di oggi su Astute. Riesci a fare lo stesso?';

  @override
  String get fiveChallengeInvite =>
      'Le cinque di oggi su Astute: le stesse cinque domande per tutti. Quante ne indovini?';

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · Le tre di oggi · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score su $max · giorno $day';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score su $max';
  }

  @override
  String get skillsTitle => 'Cosa imparare';

  @override
  String get skillsTitleMark => 'imparare';

  @override
  String get skillsLine =>
      'Ogni risposta muove il punteggio. Le carte che allenano ciò che scegli ne hanno il segno.';

  @override
  String get skillsDone => 'Fatto';

  @override
  String get skillsFocus => 'IN FOCUS';

  @override
  String get skillMarkKicker => 'QUESTA CARTA ALLENA';

  @override
  String skillMarkLabel(String skill) {
    return 'Allena $skill';
  }

  @override
  String get skillMarkBody =>
      'Una delle abilità che hai messo a fuoco. Ogni risposta su una carta come questa ne muove il punteggio.';

  @override
  String get skillMarkOpen => 'Vedi tutti i tuoi punteggi';

  @override
  String get trainingTitle => 'Il tuo allenamento';

  @override
  String get trainingLine =>
      'Ogni risposta muove il tuo punteggio, di più una carta difficile indovinata. Non c’è un massimo.';

  @override
  String get trainingOthers => 'Le altre';

  @override
  String get trainingEmpty =>
      'Scegli in cosa vuoi migliorare. Ogni risposta su una carta che lo allena ne muove il punteggio, e la carta ne porta il segno.';

  @override
  String get trainingPick => 'Scegli le abilità';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'e altre $n',
      one: 'e un’altra',
    );
    return '$_temp0';
  }

  @override
  String get aimTitle => 'Dove vuoi vederci più chiaro?';

  @override
  String get aimLine =>
      'Scegline uno. Ogni giorno trovi carte per questo, e lo cambi quando vuoi.';

  @override
  String aimWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte per questo, questa settimana',
      one: '1 carta per questo, questa settimana',
      zero: 'Nessuna carta per questo, questa settimana',
    );
    return '$_temp0';
  }

  @override
  String answersRightOf(int right, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$right giuste su $n',
      one: '1 giusta su $n',
    );
    return '$_temp0';
  }

  @override
  String get aimOpen => 'Tutto per questo obiettivo';

  @override
  String get aimPlus =>
      'Con Astute+: tutti i percorsi interi su questo, e un coach che ci lavora con te.';

  @override
  String get aimNone =>
      'Scegli dove vuoi vederci più chiaro: ogni giorno troverai carte per questo.';

  @override
  String get aimPick => 'Scegli l’obiettivo';

  @override
  String get strengthsTitle => 'Dove sei forte';

  @override
  String get strengthsLine =>
      'Lo dicono le tue risposte, non una scelta: dove indovini di più, e dove sbagli.';

  @override
  String strengthsFew(String skills) {
    return 'Ancora poche risposte: $skills.';
  }

  @override
  String strengthsPractice(String skill) {
    return 'Allenati su $skill';
  }

  @override
  String get strengthsBest => 'Il tuo punto forte';

  @override
  String get strengthsWeak => 'Dove sbagli di più';

  @override
  String get strengthsLocked =>
      'Dove sbagli di più, e tutto il resto, con Astute+.';

  @override
  String get strengthsEmpty =>
      'Ancora qualche risposta, e qui vedrai dove sei forte.';

  @override
  String get readTitle => 'Dove ci vedi già chiaro';

  @override
  String get readBlind => 'Il tuo punto cieco';

  @override
  String get readLocked =>
      'Cinque carte sul tuo punto cieco, e il profilo intero, con Astute+.';

  @override
  String get readEmpty =>
      'Ancora qualche risposta, e qui vedrai dove ci vedi chiaro e dove no.';

  @override
  String get readNoAim =>
      'Scegli qui sopra dove vuoi vederci più chiaro: le tue risposte ti diranno dove ci vedi già.';

  @override
  String get readLine =>
      'Le abilità che servono a questo obiettivo, lette dalle tue risposte: dove ci vedi chiaro, e il tuo punto cieco.';

  @override
  String get readOthers => 'Il resto del tuo profilo';

  @override
  String get focusTitle => 'Il focus della settimana';

  @override
  String get focusFromGoal =>
      'Scelto dal tuo obiettivo: ogni settimana un’abilità diversa.';

  @override
  String get focusFromMisses =>
      'Scelto dalle tue risposte: è dove sbagli di più.';

  @override
  String get focusLine =>
      'Le carte che lo allenano ne hanno il segno. Domenica, com’è andata la settimana.';

  @override
  String focusLast(String skill) {
    return 'La settimana scorsa: $skill';
  }

  @override
  String focusNext(String skill) {
    return 'Da lunedì: $skill';
  }

  @override
  String get focusResult => 'Com’è andata la settimana';

  @override
  String get focusPlus =>
      'Con Astute+ il focus lo scelgono le tue risposte: dove sbagli di più.';

  @override
  String get focusMarkBody =>
      'Questa settimana alleni questa abilità: le carte che la allenano hanno questo segno. Domenica vedi com’è andata.';

  @override
  String focusShelf(String skill) {
    return 'Il focus della settimana: $skill';
  }

  @override
  String get focusShelfLine => 'Carte per allenarlo, ancora da leggere.';

  @override
  String get focusOpen => 'La tua settimana';

  @override
  String get scoreTitle => 'Punteggio Astute';

  @override
  String scoreWeek(String n) {
    return '$n questa settimana';
  }

  @override
  String get scoreStart => 'Parte dalla tua prima risposta.';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name: $n per questa risposta';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'da $n risposte',
      one: 'da 1 risposta',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => 'Video';

  @override
  String get videoPlay => 'Riproduci';

  @override
  String get videoPause => 'Pausa';

  @override
  String get videoWatchAgain => 'Guarda di nuovo';

  @override
  String get videoOffline =>
      'Il video ha bisogno della connessione. Tocca per riprovare.';

  @override
  String get skillsRowTitle => 'Cosa vuoi imparare';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Pensiero critico',
      'decisions': 'Decidere meglio',
      'money': 'Soldi e risparmio',
      'numbers': 'Numeri e statistica',
      'talk': 'Comunicare',
      'persuade': 'Persuadere',
      'people': 'Capire le persone',
      'fakes': 'Smascherare le bufale',
      'science': 'Pensare da scienziato',
      'focus': 'Concentrazione',
      'lead': 'Leadership',
      'culture': 'Cultura generale',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String skillLine(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Distinguere un buon argomento da uno che inganna.',
      'decisions': 'Scegliere con rischi e probabilità, non d’istinto.',
      'money': 'Prezzi, interessi, offerte: dove vanno i tuoi soldi.',
      'numbers': 'Leggere percentuali e grafici senza farsi fregare.',
      'talk': 'Farti capire, a voce e per iscritto.',
      'persuade': 'Convincere, e accorgerti quando cercano di convincerti.',
      'people': 'Perché la gente fa quello che fa.',
      'fakes': 'Riconoscere notizie false, foto truccate, studi gonfiati.',
      'science': 'Mettere alla prova un’idea prima di crederci.',
      'focus': 'Tenere l’attenzione dove serve, più a lungo.',
      'lead': 'Guidare un gruppo e decidere per tutti.',
      'culture': 'Storia, scienza, arte: le cose che tutti citano.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => 'Ogni giorno, al tuo livello.';

  @override
  String get perkShelvesTitle => 'Ogni percorso e ogni libro';

  @override
  String get perkShelvesLine => 'Interi, e nuovi ogni settimana.';

  @override
  String get perkGapShort => 'Quanto sei sicuro contro quanto ci prendi.';

  @override
  String get perkReadShort => 'Ogni giorno letto, da riaprire.';

  @override
  String get trialToday => 'Oggi · tutto Astute+, gratis';

  @override
  String trialReminder(int day) {
    return 'Giorno $day · te lo ricordiamo';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'year': 'all’anno',
      'other': 'al mese',
    });
    return 'Giorno $day · $price $_temp0, con rinnovo automatico finché non disdici';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '$price$suffix addebitati oggi, con rinnovo automatico finché non disdici';
  }

  @override
  String cancelHow(String where) {
    return 'Disdici quando vuoi da $where, almeno 24 ore prima del rinnovo.';
  }

  @override
  String get cancelWhereIos => 'Impostazioni › il tuo nome › Abbonamenti';

  @override
  String get cancelWhereAndroid =>
      'Google Play › Pagamenti e abbonamenti › Abbonamenti';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Chiediamo i prezzi all’App Store…',
      'other': 'Chiediamo i prezzi a Google Play…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Impossibile raggiungere l’App Store',
      'other': 'Impossibile raggiungere Google Play',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine =>
      'I prezzi e la prova gratuita arrivano dallo store. Controlla la connessione e riprova.';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get purchasePending =>
      'In attesa di approvazione. Astute+ si apre appena il pagamento va a buon fine.';

  @override
  String get oneMoment => 'Un attimo…';

  @override
  String get purchaseConfirming => 'Sto confermando il pagamento…';

  @override
  String get purchaseConfirmingSlow =>
      'Ci vuole più del solito. Il pagamento è al sicuro: Astute+ si attiva da solo.';

  @override
  String get closeLabel => 'Chiudi';

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
  String get perYear => 'all’anno';

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
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get termsOfUse => 'Termini d’uso';

  @override
  String get privacyPolicy => 'Privacy';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Scegli una parte. Non c’è una risposta giusta.';

  @override
  String get estimateCloseEnough => 'Stima. Basta andarci vicino.';

  @override
  String get tapToReveal => 'Tocca per scoprire';

  @override
  String get verdictRight => 'Giusto.';

  @override
  String get verdictClose => 'Abbastanza vicino.';

  @override
  String get verdictWrong => 'Non proprio.';

  @override
  String verdictSure(int pct) {
    return 'Eri sicuro al $pct%.';
  }

  @override
  String verdictYouSaid(String given) {
    return 'Hai detto $given';
  }

  @override
  String verdictYouSaidSure(String given, int pct) {
    return 'Hai detto $given, sicuro al $pct%';
  }

  @override
  String verdictRightIs(String answer) {
    return 'Giusta: $answer';
  }

  @override
  String verdictRightWithin(String answer, String low, String high) {
    return 'Giusta: $answer (andava bene da $low a $high)';
  }

  @override
  String get giveMeANudge => 'Dammi un aiuto';

  @override
  String get beingRightMattersLess =>
      'Avere ragione conta meno che sapere quanto spesso ce l’hai.';

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
    return '$difficulty · scegli prima di girarla.';
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
  String get nowShowMeTheOtherSide => 'Ora mostrami l’altra parte';

  @override
  String get skipShowMeAnyway => 'Salta — mostramela comunque';

  @override
  String get youTookCaps => 'HAI SCELTO';

  @override
  String get putSimplyCaps => 'IN PAROLE SEMPLICI';

  @override
  String get explainLikeImThree => 'Spiegamelo come a un bambino';

  @override
  String get whatTheOtherSideSaysCaps => 'COSA DICE L’ALTRA PARTE';

  @override
  String get whatTheOtherSideSays => 'Cosa dice l’altra parte';

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
    return 'Questa l’hai indovinata$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Hai detto $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Scorri per la prossima';

  @override
  String get musicSound => 'Suono nelle carte di musica';

  @override
  String get musicSoundIsOff => 'Il suono delle carte di musica è spento.';

  @override
  String get musicSoundTurnOn => 'Accendi';

  @override
  String get thatWasTheOnlyOne => 'Era l’unica';

  @override
  String get lastOne => 'L’ultima';

  @override
  String deckEndTitle(String word) {
    return 'Sono tutte e $word.';
  }

  @override
  String get deckEndAgain => 'Ricomincia dalla prima';

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
      'Tieni premuta una carta che ti piace e finisce qui — e l’app te ne dà altre così.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Tocca il segnalibro su una carta e finisce qui — quelle che ti hanno cambiato il modo di pensare, tenute.';

  @override
  String get nudgeTitle => 'Le tue cinque sono pronte';

  @override
  String get nudgeBookTitle => 'Il libro gratis di questa settimana';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '$title di $author: le grandi idee in $minutes minuti.';
  }

  @override
  String get nudgeFreezeTitle => 'La tua serie è al sicuro';

  @override
  String nudgeFreezeBody(String question) {
    return 'Ieri ti ha coperto un jolly. Oggi: $question';
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
  String get yourJourney => 'Il tuo viaggio';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Dalla tua ultima visita, $days giorni fa',
      one: 'Dalla tua ultima visita, ieri',
      zero: 'Dalla tua ultima visita di oggi',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return '$n dalla tua ultima visita';
  }

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
  String get consentTitle => 'Ci aiuti a migliorare Astute?';

  @override
  String get consentLine =>
      'Condividi come usi l’app — mai il tuo nome, la tua email o quello che scrivi.';

  @override
  String get consentNo => 'No, grazie';

  @override
  String get consentYes => 'Sì, condividi';

  @override
  String consentChangeLater(String profile, String setting) {
    return 'Puoi cambiarlo quando vuoi in $profile, alla voce $setting.';
  }

  @override
  String get yourMix => 'Il tuo mix';

  @override
  String get genresTitle => 'Quali parti?';

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
      'Cinque carte al giorno scelte per te: dal tuo mix, al tuo livello, e quelle che sbagli tornano. Da domani.';

  @override
  String get plusCardHeadline => 'Tutte e cinque, tue.';

  @override
  String get plusCardLine =>
      'Cinque carte al giorno dal tuo mix, al tuo livello. Il tuo viaggio. Tutto il tuo archivio.';

  @override
  String get archiveBeforeThisWeek => 'Prima di questa settimana';

  @override
  String get weekKeptThreeOwn =>
      'Sette giorni di fila: domani tre delle cinque sono tue.';

  @override
  String get weekKeptSundayFourOwn =>
      'Sette giorni di fila, e domani è domenica: quattro delle cinque sono tue.';

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
  String get topPicksTitle => 'Meritano il tuo tempo';

  @override
  String get topPicksLine =>
      'Scelte da Astute mentre si riempie la classifica dei lettori';

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
      'Sei offline. Questa è Esplora come l’hai letta l’ultima volta.';

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
  String get storyHint => 'Tocca per andare avanti · tieni premuto per fermare';

  @override
  String get storyTapOn => 'Tocca per andare avanti';

  @override
  String get storyPrevious => 'Indietro';

  @override
  String get storyClose => 'Chiudi la storia';

  @override
  String get storySave => 'Salva';

  @override
  String get storySaved => 'Salvata';

  @override
  String get storyShare => 'Condividi';

  @override
  String get storyOpenCard => 'Apri la carta';

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
  String get themePast1 => 'Dal Seicento all’Ottocento';

  @override
  String get themePast2 => 'Il secolo scorso';

  @override
  String get themePastLine => 'Un’epoca diversa ogni volta che torna';

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
  String get themeIdeasLine => 'La teoria dietro le cose, un’idea alla volta';

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
  String weekRecapMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Altre $n della tua settimana con Astute+',
      one: 'Un’altra della tua settimana con Astute+',
    );
    return '$_temp0';
  }

  @override
  String get weekReviewTitle => 'Ripassa la settimana';

  @override
  String get weekReviewLine =>
      'Le domande delle tue carte di questa settimana. Rispondi di nuovo: è così che restano.';

  @override
  String get weekReviewGo => 'Ripassa';

  @override
  String get weekReviewNone =>
      'Le carte che leggi questa settimana tornano qui, da ripassare.';

  @override
  String get plusInTheApp =>
      'Astute+ è nell’app: scarica Astute su iPhone o Android per iniziare la prova gratuita.';

  @override
  String get purchaseComplete => 'Acquisto completato.';

  @override
  String get trialStartedTitle => 'Prova gratuita avviata.';

  @override
  String get successWelcome =>
      'Benvenuto in Astute+. Le cinque carte di oggi sono pronte.';

  @override
  String successWelcomeNamed(String name) {
    return 'Benvenuto in Astute+, $name. Le cinque carte di oggi sono pronte.';
  }

  @override
  String get successWelcomeTomorrow =>
      'Benvenuto in Astute+. Le cinque di domani sono tutte tue.';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return 'Benvenuto in Astute+, $name. Le cinque di domani sono tutte tue.';
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
  String get sceneLockIn => 'Conferma';

  @override
  String get placeItDrag => 'Trascina lungo il righello.';

  @override
  String get placeItHappy => 'Va bene così?';

  @override
  String get placeItEstimate => 'La tua stima';

  @override
  String get placeItNotSet => 'non ancora data';

  @override
  String get placeItLock => 'Conferma la mia stima';

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
    return '$now min a settimana, all’inizio $was min';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min questa settimana';
  }

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
  String get journeyMovesTitle => 'Mosse che riconosci';

  @override
  String get journeySureEmpty =>
      'Compare quando rispondi sicuro all’80% o più.';

  @override
  String get journeyMovesEmpty =>
      'Compare quando riconosci una mossa in due carte.';

  @override
  String get journeyMissedEmpty =>
      'Sei risposte in una seconda materia, e viene misurata.';

  @override
  String get journeyFillsAsYouRead => 'Si riempie man mano che leggi.';

  @override
  String journeyOfN(int n) {
    return 'su $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Ultima: $name';
  }

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
  String get anotherOne => 'Un’altra';

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
    return 'Tema: $where';
  }

  @override
  String get howSure => 'Quanto ne sono sicuro, e perché?';

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
  String get modeBigger => 'Qual è più grande?';

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
  String get moveComparedToWhat => 'Tanto o poco?';

  @override
  String get moveComparedToWhatLine =>
      '«+30%» non vuol dire niente finché non sai: rispetto a cosa?';

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
  String get moveSampling => 'Chi manca nei dati?';

  @override
  String get moveSamplingLine =>
      'Ogni statistica conta qualcuno e ne lascia fuori altri. Chi manca può ribaltare la risposta';

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
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pt';
  }

  @override
  String get rightLastTime => 'Giusta l’ultima volta';

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
  String get sixtyLine => 'Otto vero o falso. Segui l’istinto';

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
    return '$says. Aprila per sentire l’altra campana.';
  }

  @override
  String get spotTitle => 'Trova quella falsa';

  @override
  String get spotLine => 'Quattro affermazioni. Tre sono vere, una è falsa.';

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
  String get todayLabel => 'Oggi';

  @override
  String get toneCurious => 'Curioso';

  @override
  String get toneLight => 'Leggero';

  @override
  String get toneSerious => 'Serio';

  @override
  String get toneTough => 'Tosto';

  @override
  String get unmaskBack => 'Mostralo com’era';

  @override
  String get unmaskFlipped => 'Rimettilo dritto';

  @override
  String get unmaskLine => 'Stessi numeri, un’altra immagine';

  @override
  String get unmaskStretched => 'Usa una scala onesta';

  @override
  String get unmaskTitle => 'Smaschera il grafico';

  @override
  String get unmaskTotals => 'Rendi il confronto equo';

  @override
  String get unmaskTruncated => 'Fai partire l’asse da zero';

  @override
  String get unmaskWindow => 'Mostra tutta la serie';

  @override
  String get unmaskMisleadTitle => 'Grafici che ingannano';

  @override
  String get unmaskMisleadLine =>
      'I numeri sono veri. Il trucco è nel disegno.';

  @override
  String get unmaskAsk => 'Questo grafico inganna. Riesci a vedere come?';

  @override
  String get unmaskShowTrick => 'Mostra il trucco';

  @override
  String get unmaskHideTrick => 'Nascondi il trucco';

  @override
  String get unmaskOriginal => 'Originale';

  @override
  String get unmaskCorrected => 'Corretto';

  @override
  String unmaskTrickTruncated(String from) {
    return 'L’asse parte da $from, non da zero.';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return 'L’asse va solo da $low a $high: un piccolo cambiamento sembra enorme.';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return 'L’asse va da $low a $high: un cambiamento vero sembra piatto.';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return 'Mostra solo $shown, ma i dati coprono $all.';
  }

  @override
  String get unmaskTrickTotals =>
      'Confronta totali grezzi, non una misura equa.';

  @override
  String get unmaskTrickFlippedRise =>
      'L’asse è capovolto: una salita sembra una discesa.';

  @override
  String get unmaskTrickFlippedFall =>
      'L’asse è capovolto: una discesa sembra una salita.';

  @override
  String get whatIfTrue => 'E se fosse vero?';

  @override
  String get whatIfTrueLine =>
      'Carte che continuano a lavorare dopo che le chiudi';

  @override
  String get whatYouBelieve => 'Ciò in cui credi';

  @override
  String get wrongLastTime => 'Sbagliata l’ultima volta';

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

  @override
  String placeNearYou(String place) {
    return 'Vicino a te · $place';
  }

  @override
  String placeYourRegion(String place) {
    return 'La tua regione · $place';
  }

  @override
  String placeYourCountry(String place) {
    return 'Il tuo paese · $place';
  }

  @override
  String get sundayOneMore => 'Domenica: una in più, scelta per te';

  @override
  String get whereYouLive => 'Dove vivi';

  @override
  String get whereYouLiveLine =>
      'Prima la tua città, poi la regione, poi il paese';

  @override
  String get whereYouLiveAsk =>
      'Carte sulla tua città, la tua regione e il tuo paese: al massimo una al giorno, e questo scaffale. Si tiene solo la città, mai dove sei di preciso.';

  @override
  String get whereYouLiveSwitchOn => 'Attiva';

  @override
  String get gateUpdateTitle => 'Aggiorna Astute';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'La nuova ti aspetta nell’App Store',
      'google': 'La nuova ti aspetta su Google Play',
      'other': 'La nuova ti aspetta nel tuo store',
    });
    return 'Questa versione non può più andare avanti. $_temp0, con le tue carte e la tua serie così come le hai lasciate.';
  }

  @override
  String get gateUpdateButton => 'Aggiorna';

  @override
  String get gateSoftTitle => 'È pronta una nuova versione di Astute';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Ti aspetta nell’App Store.',
      'google': 'Ti aspetta su Google Play.',
      'other': 'Ti aspetta nel tuo store.',
    });
    return '$_temp0 Aggiornare richiede un attimo, e le tue carte e la tua serie restano come sono.';
  }

  @override
  String get gateSoftLater => 'Più tardi';

  @override
  String get gatePauseTitle => 'Astute si prende una breve pausa';

  @override
  String get gatePauseLine =>
      'Stiamo sistemando una cosa dietro le quinte. Tutto quello che hai fatto è al sicuro. Riprova tra poco.';

  @override
  String get gatePauseTrying => 'Riprovo…';

  @override
  String get gatePauseStill => 'Ancora in pausa. Riprova tra qualche minuto.';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return '$toDo da fare, $toRead da leggere';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return '$toDo da fare · $toRead da leggere';
  }

  @override
  String get purposeFilterToRead => 'Da leggere';

  @override
  String get purposeFilterToDo => 'Da fare';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': 'Vero o falso',
      'pick': 'Scegline una',
      'typeNumber': 'Scrivi un numero',
      'bet': 'Scommetti sul numero',
      'side': 'Scegli una parte',
      'youFirst': 'Prima tu',
      'moveIt': 'Spostalo e guarda',
      'whatNext': 'Cosa succede dopo?',
      'spotTrick': 'Trova il trucco',
      'drawIt': 'Disegnalo',
      'sortThem': 'Smistali',
      'putInOrder': 'Mettili in ordine',
      'holdIt': 'Tieni premuto',
      'growSample': 'Fai crescere il campione',
      'askWhy': 'Chiedi perché',
      'sayPlainly': 'Dillo semplice',
      'pairUp': 'Abbinali',
      'followClues': 'Segui gli indizi',
      'look': 'Guarda e basta',
      'listen': 'Ascolta',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return 'Leggi · $n min';
  }

  @override
  String get purposeCommitNote =>
      'Rispondi qui, poi apri la carta per vedere se avevi ragione. Una risposta su cui ti sbilanci ti resta in testa più a lungo.';

  @override
  String get purposeCommitTitle => 'Prima rispondi';

  @override
  String get purposeCommitLine => 'Di’ cosa ne pensi, poi apri la carta';

  @override
  String get purposeInYourHeadLine => 'Un numero da trovare a mente';

  @override
  String get purposeInYourHead => 'A mente';

  @override
  String get purposeMoveKicker => 'Una mossa';

  @override
  String purposeMoveNew(int points) {
    return 'Nuova · +$points quando la padroneggi';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Frequenze di base',
      'survivorship': 'Sopravvivenza',
      'regression': 'Regressione verso la media',
      'confirmation': 'Conferma',
      'anchoring': 'Ancoraggio',
      'sampling': 'Campione',
      'confounding': 'Variabile nascosta',
      'counterfactual': 'Rispetto a cosa',
      'multipleComparisons': 'Tanti tentativi',
      'availability': 'Disponibilità',
      'sunkCost': 'Costo irrecuperabile',
      'conjunction': 'Congiunzione',
      'conditional': 'Probabilità condizionata',
      'independence': 'Indipendenza',
      'coincidence': 'Coincidenza',
      'exponential': 'Crescita esponenziale',
      'reflection': 'La risposta veloce',
      'simpson': 'Aggregati',
      'estimation': 'Stima',
      'computation': 'Fare il conto',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Quanto è preciso un test non dice quanto è probabile che riguardi te',
      'survivorship': 'I dati che hai sono quelli sopravvissuti',
      'regression': 'Gli estremi tornano da soli verso la media',
      'confirmation': 'Cercare un sì non è una prova',
      'anchoring': 'Il primo numero detto sposta tutti quelli dopo',
      'sampling': 'Chi finisce nel campione decide cosa può dire',
      'confounding': 'Forse qualcos’altro causa entrambe le cose',
      'counterfactual':
          'Un cambiamento non vuol dire nulla senza un gruppo di controllo',
      'multipleComparisons': 'Prova abbastanza cose e una passerà',
      'availability': 'Facile da immaginare non vuol dire frequente',
      'sunkCost': 'Speso è speso: si decide solo su quello che resta',
      'conjunction':
          'I dettagli rendono una storia più credibile e meno probabile',
      'conditional': 'Quello che ti hanno detto cambia le probabilità',
      'independence': 'Il caso non ha memoria',
      'coincidence': 'Le cose rare sono comuni quando i tentativi sono tanti',
      'exponential': 'Nessuno ha l’intuito per i raddoppi',
      'reflection': 'La risposta che arriva per prima è quella da controllare',
      'simpson': 'Il totale può pendere dove nessuna parte pende',
      'estimation': 'Spezza l’impossibile in cose che puoi stimare',
      'computation': 'Un problema che puoi davvero finire',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Quanto era comune in partenza?',
      'survivorship': 'Cosa non è mai entrato nei dati?',
      'regression': 'È solo un estremo che torna indietro?',
      'confirmation': 'Cosa mi darebbe torto?',
      'anchoring': 'Quale numero è arrivato per primo?',
      'sampling': 'Chi è stato contato?',
      'confounding': 'Cos’altro potrebbe causare entrambe le cose?',
      'counterfactual': 'Rispetto a cosa?',
      'multipleComparisons': 'Quante cose sono state provate?',
      'availability': 'È comune o solo facile da immaginare?',
      'sunkCost': 'Cosa resta da decidere da qui in poi?',
      'conjunction': 'Ogni dettaglio lo rende meno probabile?',
      'conditional': 'Cosa cambia saperlo?',
      'independence': 'L’ultimo risultato cambia il prossimo?',
      'coincidence': 'Quante occasioni c’erano?',
      'exponential': 'Cosa succede quando raddoppia ancora?',
      'reflection': 'La prima risposta è quella giusta?',
      'simpson': 'Ogni parte pende dalla stessa parte?',
      'estimation': 'Cosa posso stimare strada facendo?',
      'computation': 'Posso calcolarlo passo per passo?',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => 'Un gradino sopra';

  @override
  String get purposeStepAboveLine =>
      'Più difficili di quelle che leggi di solito';

  @override
  String purposeThinTitle(String subject) {
    return 'Quella che leggi meno: $subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return 'Hai letto il $percent% di $subject, meno che in ogni altra';
  }

  @override
  String get purposeOtherSide => 'L’altra parte';

  @override
  String get purposeOtherSideLine =>
      'Hai scelto da che parte stare. Ecco le ragioni migliori contro';

  @override
  String purposeYouSaid(String side) {
    return 'Hai detto $side';
  }

  @override
  String purposeCaseFor(String side) {
    return 'Le ragioni del «$side»';
  }

  @override
  String get purposeMechanism => 'Il meccanismo';

  @override
  String purposeMovingUpdated(String date) {
    return 'Aggiornata il $date';
  }

  @override
  String get purposeMovingYears => 'Può cambiare tra qualche anno';

  @override
  String get purposeMovingMonths => 'Può cambiare entro l’anno';

  @override
  String get purposeWhy => 'Ah, ecco perché';

  @override
  String get purposeWhyLine => 'Un meccanismo, spiegato finché non scatta';

  @override
  String purposeWhyBand(int n) {
    return 'Il perché · $n min';
  }

  @override
  String get purposeMe => 'Sono io';

  @override
  String get purposeMeLine => 'Cose che fai senza accorgertene';

  @override
  String get purposeMeFooter => 'Segna le carte in cui ti riconosci.';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte segnate con «Sono io».',
      one: 'Una carta segnata con «Sono io».',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => 'Non lo sapevo, e parla di me';

  @override
  String get purposeAboutYouLine =>
      'Il tuo corpo, la tua salute, le tue probabilità';

  @override
  String get purposeHeadline => 'In un titolo';

  @override
  String get purposeHeadlineLine =>
      'Studi e affermazioni che suonano meglio di quel che sono';

  @override
  String get purposeTheClaim => 'L’affermazione';

  @override
  String get purposeNumber => 'In un numero';

  @override
  String get purposeNumberLine =>
      'Probabilità e percentuali da guardare due volte';

  @override
  String get purposeOutOfWhat => 'Su quanti?';

  @override
  String get purposeOffer => 'In un’offerta';

  @override
  String get purposeOfferLine => 'Prezzi, affari e chi paga davvero';

  @override
  String get purposeArgument => 'In una discussione';

  @override
  String get purposeArgumentLine => 'Dove il ragionamento scivola';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Una domanda che smaschera quasi tutto questo',
      '2': 'Due domande che smascherano quasi tutto questo',
      '3': 'Tre domande che smascherano quasi tutto questo',
      '4': 'Quattro domande che smascherano quasi tutto questo',
      '5': 'Cinque domande che smascherano quasi tutto questo',
      'other': '$n domande che smascherano quasi tutto questo',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Soldi',
      'work': 'Lavoro e tempo',
      'clock': 'Tempo',
      'body': 'Il tuo corpo',
      'relationships': 'Relazioni',
      'belief': 'Ciò in cui credi',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Sto pagando per quello che uso davvero?',
      'work': 'Cosa renderebbe più facile cominciare domani?',
      'clock': 'Dove va davvero il mio tempo?',
      'body': 'Quello che so del mio corpo è ancora vero?',
      'relationships':
          'Di cosa hanno davvero bisogno le persone che mi stanno vicino?',
      'belief': 'Quanto ne sono sicuro, e perché?',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Soldi',
      'work': 'Lavoro',
      'clock': 'Tempo',
      'body': 'Corpo',
      'relationships': 'Relazioni',
      'belief': 'Ciò in cui credo',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => 'Su cosa vuoi domande migliori?';

  @override
  String get purposeLifeFooter =>
      'Scegline quanti vuoi: qui sotto compaiono le carte che ne parlano.';

  @override
  String get purposeSpotTrick => 'Trova il trucco';

  @override
  String get purposeSpotTrickLine => 'Quale domanda lo smaschererebbe?';

  @override
  String get purposePlayed => 'Cosa hai giocato oggi';

  @override
  String get purposePlayedOff => 'punti di scarto, in media';

  @override
  String get purposePlayedTricks => 'trucchi scoperti';

  @override
  String get purposePlayedAnswered => 'risposte su uno scaffale';

  @override
  String get purposePlayedFooter =>
      'Le risposte date su uno scaffale contano in «Il tuo viaggio», come quelle di Oggi.';

  @override
  String purposeOf(int n, int of) {
    return '$n su $of';
  }

  @override
  String purposeSetRead(int n, int of) {
    return '$n su $of lette';
  }

  @override
  String purposeSetDone(int n) {
    return 'Lette tutte e $n. Quando lo scaffale torna, se ne aggiungono di nuove.';
  }

  @override
  String get purposeComplete => 'Completa';

  @override
  String get purposeStampsFooter =>
      'Ogni carta che leggi aggiunge il suo francobollo.';

  @override
  String get purposeSets => 'Le tue raccolte';

  @override
  String get purposeSetsLine =>
      'Leggere conta. Non serve rispondere per completare una raccolta.';

  @override
  String get purposeTomorrow => 'Domani sugli scaffali';

  @override
  String get purposeTomorrowLine =>
      'Gli scaffali cambiano ogni giorno. Ecco i prossimi';

  @override
  String get purposeEnd => 'Sei in fondo a Esplora';

  @override
  String get purposeEndLine => 'A domani';

  @override
  String get betsRangeTitle => 'Punta su un intervallo';

  @override
  String get betsRangeLine => 'Più stretto è, più paga, se hai ragione';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts pt';
  }

  @override
  String get betsBet => 'Punta';

  @override
  String betsInRange(int pts, String said) {
    return 'Dentro: +$pts punti. È $said.';
  }

  @override
  String betsMissedRange(String said) {
    return 'Mancato: è $said.';
  }

  @override
  String get betsYourGuess => 'La tua stima';

  @override
  String get betsAnsweredAlready => 'Già risposta';

  @override
  String get betsOpenCard => 'Apri la carta';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ti restano $n punti oggi',
      one: 'Ti resta 1 punto oggi',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => 'La tua schedina';

  @override
  String betsSlipToday(String points) {
    return '$points oggi';
  }

  @override
  String get betsSlipEmpty =>
      'Ancora nessuna puntata. Ognuna che fai finisce qui.';

  @override
  String get betsSlipTipTwice =>
      'Vai stretto quando sei sicuro: paga il doppio.';

  @override
  String get betsSlipTipThrice =>
      'Vai stretto quando sei sicuro: paga il triplo.';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: 'Vai stretto quando sei sicuro: paga $times volte tanto.',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return 'Puntate strette azzeccate: $right su $n.';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return 'Giuste $right su $n, sicuro in media al $pct%.';
  }

  @override
  String get betsRight => 'Giusta';

  @override
  String get betsWrong => 'Sbagliata';

  @override
  String betsOneIn(String n) {
    return '1 su $n';
  }

  @override
  String get betsOneInLabel => '1 su';

  @override
  String betsScore(int right, int steps) {
    return '$right su $steps';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return 'Ne hai indovinati $right su $steps.';
  }

  @override
  String get betsStakeTitle => 'Fai la tua puntata';

  @override
  String betsStakeLine(int points) {
    return '$points punti al giorno. Se vinci, raddoppi la puntata';
  }

  @override
  String get betsStakeLabel => 'Puntata';

  @override
  String betsBetN(int n) {
    return 'Punta $n';
  }

  @override
  String get betsPickFirst => 'Prima scegline una';

  @override
  String get betsNotEnough => 'Punti insufficienti';

  @override
  String betsWin(int n) {
    return 'Vinci $n.';
  }

  @override
  String betsLose(int n) {
    return 'Perdi $n.';
  }

  @override
  String betsYouWereSure(int pct) {
    return 'Eri sicuro al $pct%.';
  }

  @override
  String get betsFriendTitle => 'Sfida un amico';

  @override
  String get betsFriendLine => 'Mandagli una domanda, poi confrontate le stime';

  @override
  String get betsFriendNote =>
      'La tua stima resta sul tuo telefono. La carta arriva con la risposta, quindi chiedi prima la sua.';

  @override
  String betsFriendNoteSaid(String said) {
    return 'Hai detto $said. La carta arriva con la risposta, quindi chiedi prima la sua stima.';
  }

  @override
  String get betsFriendSend => 'Manda a un amico';

  @override
  String get betsFriendCopy => 'Copia la domanda';

  @override
  String get betsFriendCopied => 'Domanda copiata';

  @override
  String get betsFriendAsk => 'Tu cosa dici?';

  @override
  String get betsNumberTitle => 'Il tuo numero';

  @override
  String get betsNumberLine =>
      'Impostalo, bloccalo, guarda di quanto hai sbagliato';

  @override
  String get betsLock => 'Conferma';

  @override
  String get betsSpotOn => 'Centrato.';

  @override
  String betsCloseEnough(String by) {
    return 'Abbastanza vicino: hai sbagliato di $by.';
  }

  @override
  String betsOffBy(String by) {
    return 'Hai sbagliato di $by.';
  }

  @override
  String get betsYou => 'tu';

  @override
  String get betsAnswer => 'risposta';

  @override
  String get betsBiggerTitle => 'Qual è più grande?';

  @override
  String get betsBiggerLine =>
      'Due cifre che puoi calcolare. Tocca la più grande';

  @override
  String get betsTapIfBigger => 'Tocca se è più grande';

  @override
  String get betsBiggerGotIt => 'Più grande · indovinato';

  @override
  String get betsBigger => 'Più grande';

  @override
  String get betsYourPick => 'La tua scelta';

  @override
  String get betsOr => 'o';

  @override
  String get betsBiggerFoot =>
      'Ogni cifra è la risposta di una carta. Dopo la scelta, toccane una per aprire la sua carta.';

  @override
  String betsBiggerScore(int right, int n) {
    return 'Giuste $right su $n.';
  }

  @override
  String get betsCloserTitle => 'Più vicino';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Due passi di più o meno per avvicinarti al numero',
      '3': 'Tre passi di più o meno per avvicinarti al numero',
      '4': 'Quattro passi di più o meno per avvicinarti al numero',
      '5': 'Cinque passi di più o meno per avvicinarti al numero',
      'other': '$steps passi di più o meno per avvicinarti al numero',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Due passi per avvicinarti.',
      '3': 'Tre passi per avvicinarti.',
      '4': 'Quattro passi per avvicinarti.',
      '5': 'Cinque passi per avvicinarti.',
      'other': '$steps passi per avvicinarti.',
    });
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return 'Più o meno di $v?';
  }

  @override
  String betsStepOf(int at, int of) {
    return 'Passo $at di $of';
  }

  @override
  String get betsMore => 'Di più';

  @override
  String get betsLess => 'Meno';

  @override
  String betsCloserYesMore(String v) {
    return 'Giusto: è più di $v.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Giusto: è meno di $v.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Sbagliato: è più di $v.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Sbagliato: è meno di $v.';
  }

  @override
  String betsCloserExact(String said) {
    return 'È esattamente $said.';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return 'È $said. Ne hai indovinati $right su $steps.';
  }

  @override
  String get betsMagnitudeTitle => 'Ordini di grandezza';

  @override
  String get betsMagnitudeLine =>
      'Dieci, mille o un milione? Scegli la grandezza';

  @override
  String get betsMagnitudeRight => 'Ordine di grandezza giusto.';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sbagliato di $n ordini di grandezza.',
      one: 'Sbagliato di 1 ordine di grandezza.',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => 'La puntata del giorno';

  @override
  String get betsDayLine =>
      'Conferma la tua stima, poi guarda di quanto hai sbagliato';

  @override
  String get betsDayTag => 'Puntata del giorno';

  @override
  String get betsDayTagSame => 'Puntata del giorno · uguale per tutti';

  @override
  String get betsLockIn => 'Conferma';

  @override
  String betsItIs(String said) {
    return 'È $said.';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hai sbagliato di $n punti percentuali.',
      one: 'Hai sbagliato di 1 punto percentuale.',
      zero: 'Centrato.',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '«$text»';
  }

  @override
  String get screensExpertTitle => 'Pensa come un esperto';

  @override
  String get screensExpertLine =>
      'La domanda che ognuno di loro fa sempre, e le carte in cui serve';

  @override
  String get screensExpertStatistician => 'Statistico';

  @override
  String get screensExpertStatisticianAs => 'Pensa come uno statistico';

  @override
  String get screensExpertStatisticianAsks => 'Rispetto a cosa, e su quanti?';

  @override
  String get screensExpertEconomist => 'Economista';

  @override
  String get screensExpertEconomistAs => 'Pensa come un economista';

  @override
  String get screensExpertEconomistAsks => 'Chi paga, e a cosa rinuncia?';

  @override
  String get screensExpertHistorian => 'Storico';

  @override
  String get screensExpertHistorianAs => 'Pensa come uno storico';

  @override
  String get screensExpertHistorianAsks => 'Cosa si sapeva all’epoca?';

  @override
  String get screensExpertDoctor => 'Medico';

  @override
  String get screensExpertDoctorAs => 'Pensa come un medico';

  @override
  String get screensExpertDoctorAsks =>
      'Quanto è comune, e cos’altro potrebbe essere?';

  @override
  String get screensExpertScientist => 'Scienziato';

  @override
  String get screensExpertScientistAs => 'Pensa come uno scienziato';

  @override
  String get screensExpertScientistAsks => 'Come sapremmo se fosse sbagliato?';

  @override
  String get screensDotsTitle => 'Unisci i puntini';

  @override
  String get screensDotsLine =>
      'Scegli una materia per vedere dove incontra le altre';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: 'Incontra $subjects materie',
      one: 'Incontra 1 materia',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: 'in $cards carte',
      one: 'in 1 carta',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get screensDotsWhere => 'Dove si incontrano';

  @override
  String get screensDotsWhereLine => 'Una domanda, due modi di guardarla';

  @override
  String get screensAskTitle => 'Cosa vuoi capire?';

  @override
  String get screensAskHint => 'Chiedi qualsiasi cosa, o scrivi una parola';

  @override
  String get screensAskTry => 'Prova';

  @override
  String get screensAskClear => 'Cancella la domanda';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte rispondono',
      one: '1 carta risponde',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => 'Ancora nessuna carta su questo';

  @override
  String get screensAskNoneLine =>
      'Conserva la domanda. Quando una carta le risponderà, la troverai qui, sotto la domanda.';

  @override
  String get screensAskKeep => 'Conserva la domanda';

  @override
  String get screensAskKept => 'Conservata';

  @override
  String get screensAskedTitle => 'Le domande che hai fatto';

  @override
  String get screensAskedLine => 'E le carte che hanno risposto';

  @override
  String get screensAskedAnswered => 'La risposta';

  @override
  String get screensAskedWaiting =>
      'Nessuna carta le risponde ancora. Quando arriverà, la troverai qui.';

  @override
  String get screensAskedForget => 'Dimentica questa domanda';

  @override
  String get screensAskedForgotten => 'Domanda dimenticata';

  @override
  String get screensWhyTitle => 'Continua a chiedere perché';

  @override
  String get screensWhyLine => 'Ogni risposta apre la domanda successiva';

  @override
  String get screensWhyAsk => 'Perché?';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n perché di profondità.',
      one: 'Un perché di profondità.',
    );
    return '$_temp0 Più giù di così non si va.';
  }

  @override
  String get screensWhyAgain => 'Ricomincia';

  @override
  String get screensWhyHoles => 'Altre tane del Bianconiglio';

  @override
  String get screensWhyHolesLine => 'Ognuna scende di qualche perché';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n perché',
      one: '1 perché',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => 'Vai più a fondo';

  @override
  String screensWhySource(String source) {
    return 'Fonte: $source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '$at perché',
      one: '1 perché',
    );
    return '$_temp0 su $of';
  }

  @override
  String get screensTimeTitle => 'Nel tempo';

  @override
  String get screensTimeLine =>
      'Un’epoca alla volta, fino a quest’anno. Trascina per viaggiare';

  @override
  String get screensTimeCaption =>
      'Anni fa. Ogni tacca è dieci volte più indietro.';

  @override
  String get screensTimeNow => 'Oggi';

  @override
  String get screensTimeEarlier => 'Più indietro';

  @override
  String get screensTimeLater => 'Più vicino a oggi';

  @override
  String get screensEraAncient => 'Il mondo antico';

  @override
  String get screensEraAncientWhen => 'Prima del 500';

  @override
  String get screensEraMedieval => 'Il Medioevo';

  @override
  String get screensEraMedievalWhen => 'Dal 500 al 1500';

  @override
  String get screensEraEarlyModern => 'La prima età moderna';

  @override
  String get screensEraEarlyModernWhen => 'Dal 1500 al 1800';

  @override
  String get screensEraNineteenth => 'L’Ottocento';

  @override
  String get screensEraNineteenthWhen => 'Dal 1800 al 1900';

  @override
  String get screensEraTwentieth => 'Il secolo scorso';

  @override
  String get screensEraTwentiethWhen => 'Dal 1900 al 2000';

  @override
  String get screensEraRecent => 'Questo secolo';

  @override
  String get screensEraRecentWhen => 'Dal 2000';

  @override
  String get screensMindTitle => 'Cambia idea';

  @override
  String get screensMindLine =>
      'Di’ come la pensi prima di leggere, e poi di nuovo dopo';

  @override
  String get screensMindClaim => 'Affermazione';

  @override
  String get screensMindBefore => 'Prima di leggere';

  @override
  String get screensMindTap => 'Tocca la tua posizione';

  @override
  String get screensMindKnow => 'Cosa sappiamo';

  @override
  String get screensMindNow => 'E adesso?';

  @override
  String get screensMindAgain => 'Tocca di nuovo';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': 'Per nulla d’accordo',
      '1': 'In disaccordo',
      '2': 'Non so',
      '3': 'D’accordo',
      'other': 'Del tutto d’accordo',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hai fatto $n passi verso le prove.',
      one: 'Hai fatto 1 passo verso le prove.',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame => 'Come prima. Una carta è solo una carta.';

  @override
  String get screensMindAlready =>
      'Eri dalla parte delle prove ancora prima di leggerle.';

  @override
  String get screensMindAway =>
      'La tua risposta si è allontanata dalle prove. Merita una seconda lettura.';

  @override
  String get screensMindFirst =>
      'Prima di’ come la pensi. Un tocco, prima di leggere.';

  @override
  String screensMindChanged(int changed, int total) {
    return 'Hai cambiato idea $changed volte su $total.';
  }

  @override
  String get screensMindFoot =>
      'Se cambi idea, la carta ha fatto il suo lavoro.';

  @override
  String get screensSayTitle => 'Dillo stasera';

  @override
  String get screensSayLine =>
      'Una frase da portare a cena. Tocca quando l’hai detta';

  @override
  String get screensSayTonight => 'La frase di stasera';

  @override
  String get screensSaySaid => 'L’ho detta';

  @override
  String get screensSayDone => 'Detta';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hai detto $n frasi questa settimana.',
      one: 'Hai detto 1 frase questa settimana.',
      zero: 'Ancora niente detto questa settimana.',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts =>
      'Ogni frase che dici conta anche per la Top della settimana.';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => 'Edizione di oggi';

  @override
  String get screensFrontSame => 'Uguale per tutti';

  @override
  String get screensFrontLead => 'In apertura';

  @override
  String get screensFrontNumbers => 'In cifre';

  @override
  String get screensFrontCorrections => 'Rettifiche';

  @override
  String get screensFrontPuzzle => 'Il rompicapo del giorno';

  @override
  String get screensFrontEnd => 'Questa è l’edizione di oggi';

  @override
  String get screensFrontTomorrow => 'Quella di domani esce al mattino';

  @override
  String exploreDayRead(int read, int of) {
    return 'Oggi: $read su $of lette';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ne mancano $n',
      one: 'ne manca 1',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => 'tutte lette';

  @override
  String get exploreDayOpen => 'Vai alle carte di oggi';

  @override
  String get exploreGameNone =>
      'Per ora qui non c’è niente da giocare. Torna domani.';

  @override
  String get challengesTitle => 'Sfide';

  @override
  String get challengesLine =>
      'Brevi esercizi di giudizio e di stima, pochi minuti ciascuno.';

  @override
  String challengesPage(int n, int of) {
    return 'Pagina $n di $of';
  }

  @override
  String get gamePlay => 'Inizia';

  @override
  String get sixtyRules =>
      'Otto affermazioni, vere o false, in un minuto. Misura quanto giudichi bene in fretta: è così che giudichiamo quasi tutto ciò che leggiamo.';

  @override
  String get sixtyReview => 'Le otto affermazioni';

  @override
  String get gameRight => 'Giusto';

  @override
  String get gameWrong => 'Sbagliato';

  @override
  String get gameUnanswered => 'Nessuna risposta';

  @override
  String get gameNext => 'Prossima sfida';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · Sessanta secondi · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$n su $of giuste · $s s';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: 'Mancano $s secondi',
      one: 'Manca 1 secondo',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => 'Le carte';

  @override
  String get gameTomorrow => 'Nuovo turno domani';

  @override
  String get gameContinue => 'Continua';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return 'Punteggio: $n su $of';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte oggi',
      one: '1 carta oggi',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => 'Tutte giuste.';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n punti',
      one: '1 punto',
    );
    return '$_temp0';
  }

  @override
  String get gameSeeResult => 'Guarda com’è andata';

  @override
  String get gameNextCard => 'Avanti';

  @override
  String get spotOnce => 'Una scelta al giorno';

  @override
  String get spotGotIt => 'Hai trovato quella falsa.';

  @override
  String get spotMissedIt => 'Non quella: è vera.';

  @override
  String get tfRules =>
      'Affermazioni su cui quasi tutti sbagliano. Di’ vero o falso, poi leggi perché. Misura il giudizio: distinguere ciò che è vero da ciò che sembra soltanto ovvio.';

  @override
  String get inOrderTitle => 'In ordine';

  @override
  String get inOrderRules =>
      'Quattro momenti dalle carte, senza il loro anno, da mettere nell’ordine in cui sono accaduti. Misura il senso della cronologia, la prima prova di ogni spiegazione: una causa viene prima del suo effetto.';

  @override
  String get inOrderFirst => 'Tocca il momento venuto per primo.';

  @override
  String get inOrderNext => 'Ora quello venuto dopo.';

  @override
  String get inOrderReady => 'Tutti al loro posto.';

  @override
  String get inOrderCheck => 'Controlla l’ordine';

  @override
  String inOrderPlaced(int n) {
    return 'Al posto $n';
  }

  @override
  String inOrderYours(int n) {
    return 'Il tuo posto: $n';
  }

  @override
  String get inOrderPerfect => 'Tutti al posto giusto.';

  @override
  String get timeGap => 'un anno mancante';

  @override
  String get whatYearTitle => 'In che anno?';

  @override
  String get whatYearRules =>
      'Tre momenti, senza il loro anno. Trova l’anno di ciascuno sulla rotella: più ti avvicini, più punti fai, fino a dieci. Misura il senso di quando le cose sono accadute.';

  @override
  String whatYearPoints(int n, int of) {
    return '$n punti su $of';
  }

  @override
  String get whatYearPerfect => 'Ogni anno esatto.';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Fuori di $n anni in tutto.',
      one: 'Fuori di 1 anno in tutto.',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Hai detto $guess · $points punti',
      one: 'Hai detto $guess · 1 punto',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Fuori di $n anni',
      one: 'Fuori di 1 anno',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anni prima',
      one: '1 anno prima',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n anni dopo',
      one: '1 anno dopo',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => 'Anno';

  @override
  String get beforeAfterTitle => 'Prima o dopo?';

  @override
  String get beforeAfterRules =>
      'Sei momenti, uno dopo l’altro. Di’ se ciascuno è accaduto prima o dopo quello sopra. Misura il senso della sequenza.';

  @override
  String get beforeAfterBefore => 'Prima';

  @override
  String get beforeAfterAfter => 'Dopo';

  @override
  String beforeAfterAsk(String year) {
    return 'Prima o dopo il $year?';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return 'Hai detto: prima del $year';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return 'Hai detto: dopo il $year';
  }

  @override
  String get beforeAfterStart => 'Da qui è partita la catena';

  @override
  String get beforeAfterPerfect => 'Nemmeno uno fuori posto.';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n coppie oggi',
      one: '1 coppia oggi',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => 'Intuito';

  @override
  String get spotSkill => 'Discernimento';

  @override
  String get tfSkill => 'Giudizio';

  @override
  String get biggerSkill => 'Proporzione';

  @override
  String get closerSkill => 'Stima';

  @override
  String get magnitudeSkill => 'Scala';

  @override
  String get rangeSkill => 'Calibrazione';

  @override
  String get stakeSkill => 'Convinzione';

  @override
  String get numberSkill => 'Precisione';

  @override
  String get inOrderSkill => 'Cronologia';

  @override
  String get whatYearSkill => 'Datazione';

  @override
  String get beforeAfterSkill => 'Sequenza';

  @override
  String get sixtyAsks => 'Otto affermazioni contro il tempo.';

  @override
  String get spotAsks => 'Quattro affermazioni, una è falsa.';

  @override
  String get tfAsks => 'Affermazioni su cui quasi tutti sbagliano.';

  @override
  String get biggerAsks => 'Due cifre. Qual è la maggiore?';

  @override
  String get closerAsks => 'Avvicinati a una cifra, passo dopo passo.';

  @override
  String get magnitudeAsks => 'Trova la giusta potenza di dieci.';

  @override
  String get rangeAsks => 'Un intervallo largo quanto basta.';

  @override
  String get stakeAsks => 'Punta in base a quanto sei sicuro.';

  @override
  String get numberAsks => 'Scegli una sola cifra.';

  @override
  String get inOrderAsks => 'Quattro momenti, dal più antico.';

  @override
  String get whatYearAsks => 'Colloca un momento nel suo anno.';

  @override
  String get beforeAfterAsks => 'Ogni momento rispetto al precedente.';

  @override
  String get challengeBest => 'Record';

  @override
  String get challengeToday => 'Oggi';

  @override
  String get challengeAccuracy => 'Accuratezza';

  @override
  String get challengeTime => 'Tempo';

  @override
  String challengeSeconds(int s) {
    return '$s s';
  }

  @override
  String get challengePersonalBest => 'Record personale';

  @override
  String challengeAboveChance(int n, int of) {
    return 'Meglio del caso: tirando a indovinare si fa in media $n su $of.';
  }

  @override
  String challengeAtChance(int n, int of) {
    return 'Pari al caso: tirando a indovinare si fa in media $n su $of.';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return 'Sotto il caso: tirando a indovinare si fa in media $n su $of.';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Il tempo è finito con $n affermazioni senza risposta.',
      one: 'Il tempo è finito con un’affermazione senza risposta.',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => 'Un’altra prova';

  @override
  String get spotRules =>
      'Quattro affermazioni: tre sono vere e una è falsa. Trova quella falsa. Misura quanto sai distinguere un’affermazione fondata da una che sembra soltanto vera.';

  @override
  String get spotAsk => 'Tocca l’affermazione che secondo te è falsa.';

  @override
  String get biggerRules =>
      'Due cifre, ognuna la risposta alla domanda di una carta. Tocca quella che secondo te è più grande. Misura il senso delle proporzioni.';

  @override
  String get biggerAsk => 'Tocca la carta con la risposta più grande.';

  @override
  String biggerRight(String big, String small) {
    return 'Giusto: $big è più di $small.';
  }

  @override
  String biggerWrong(String big, String small) {
    return 'Sbagliato: $big è più di $small.';
  }

  @override
  String get closerRules =>
      'Avvicinati a una percentuale passo dopo passo: ogni volta di’ se è più o meno del valore a metà dell’intervallo rimasto. Misura la capacità di stima.';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    return 'È $said: hai indovinato $right passi su $steps.';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    return 'È esattamente $said: hai indovinato $right passi su $steps.';
  }

  @override
  String closerStepsRight(int right, int steps) {
    return 'Hai indovinato $right passi su $steps.';
  }

  @override
  String get magnitudeRules =>
      'Dieci, mille o un milione? Scegli la potenza di dieci più vicina alla risposta. Misura il senso delle grandezze, che conta più delle cifre esatte.';

  @override
  String get rangeRules =>
      'Fissa la tua stima, poi un intervallo intorno: più è stretto, più paga se la risposta ci cade dentro. Misura la calibrazione: sapere quanto sai.';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · paga $pts';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'È $said: dentro il tuo intervallo, +$pts punti.',
      one: 'È $said: dentro il tuo intervallo, +1 punto.',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return 'È $said: fuori dal tuo intervallo.';
  }

  @override
  String stakeRules(int points) {
    return 'Scegli una risposta e puntaci dei punti, su $points al giorno: se è giusta la puntata raddoppia, se è sbagliata la perdi. Misura la convinzione: puntare su ciò che sai, e solo su quello.';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Giusto: vinci $n punti.',
      one: 'Giusto: vinci 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Sbagliato: perdi $n punti.',
      one: 'Sbagliato: perdi 1 punto.',
    );
    return '$_temp0';
  }

  @override
  String get numberRules =>
      'Imposta una sola cifra con i pulsanti e bloccala. Misura la precisione: quanto ti avvicini quando devi impegnarti su un numero.';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Giusto: è vero.',
      'other': 'Giusto: è falso.',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Sbagliato: è vero.',
      'other': 'Sbagliato: è falso.',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$n su $of al posto giusto.';
  }

  @override
  String get whatYearYours => 'Il tuo anno';

  @override
  String get whatYearExactly => 'L’anno esatto';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Giusto: era il $year, prima del $above.',
      'other': 'Giusto: era il $year, dopo il $above.',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Sbagliato: era il $year, prima del $above.',
      'other': 'Sbagliato: era il $year, dopo il $above.',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => 'Risposta';

  @override
  String get challengeYouSaid => 'Hai detto';

  @override
  String get challengePoints => 'Punti';

  @override
  String get challengeThisRound => 'Questo giro';

  @override
  String get challengeLeftToday => 'Restano oggi';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject, livello $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return 'Perché hai salvato «$question»';
  }

  @override
  String get todaySeeAgain => 'Rivedi';

  @override
  String get todaySeeAgainHint =>
      'Le carte di oggi di nuovo, a schermo intero, dalla prima';

  @override
  String get yourFiveFromToday => 'Le tue cinque di oggi';

  @override
  String get dayMomentTitle => 'Giornata completa.';

  @override
  String get dayMomentLater => 'Più tardi';

  @override
  String get yourDayCard => 'La tua giornata';

  @override
  String get tuneTitle => 'Regola il tuo mix';

  @override
  String get tuneEntryLine => 'Quanto di ogni materia, e quali parti';

  @override
  String get tuneLearned =>
      'Già spostato dalle carte che ti sono piaciute e da quelle che hai scartato. Trascina per cambiarlo.';

  @override
  String get tuneFresh => 'Trascina una materia per vederne di più o di meno.';

  @override
  String get tuneHowMuch => 'Quanto di ognuna';

  @override
  String get tuneInsideLine =>
      'Le parti che ti sono piaciute di più vengono prima. Tocca per toglierne una, tieni premuto per vedere dentro.';

  @override
  String get tuneSave => 'Salva';

  @override
  String get tuneHoldHint =>
      'Tieni premuto un genere per aprire i suoi sotto-argomenti';

  @override
  String get shareDayTitle => 'Condividi la tua giornata';

  @override
  String get shareDayRead => 'Cinque carte, lette';

  @override
  String get shareDayTurn => 'Cinque carte al giorno. Tocca a te.';

  @override
  String shareDaySure(int n) {
    return 'sicuro al $n%';
  }

  @override
  String get shareDayHeadline => 'Le cinque di oggi';

  @override
  String get shareFormatCover => 'Copertina';

  @override
  String get shareFormatList => 'Elenco';

  @override
  String get shareFormatStory => 'Storia';

  @override
  String crowdGotRight(int n) {
    return 'L’ha azzeccata il $n% dei lettori';
  }

  @override
  String crowdGotWrong(int n) {
    return 'Anche il $n% dei lettori l’ha sbagliata';
  }

  @override
  String get challengeFriend => 'Sfida un amico';

  @override
  String get challengeLine => 'Riesci a indovinare questa?';

  @override
  String pathFree(int n) {
    return '$n gratis';
  }

  @override
  String pathMoreTitle(int n) {
    return 'Altre $n in questo percorso.';
  }

  @override
  String get pathMoreLine =>
      'Ogni percorso intero, dalla carta più facile alla più difficile, e una fila nuova ogni settimana.';

  @override
  String get pathMoreGo => 'Leggi tutto il percorso';

  @override
  String get paywallPathsTitle => 'Ogni percorso, tutte e dieci.';

  @override
  String get paywallPathsMark => 'tutte e dieci.';

  @override
  String get paywallPathsLine =>
      'Dieci carte su un tema, dalla più facile alla più difficile. Una fila nuova di percorsi ogni settimana, e le tue cinque del giorno al tuo livello.';

  @override
  String get widgetAskTitle =>
      'La prima carta di domani, nella schermata Home.';

  @override
  String get widgetAskLine =>
      'Una carta nuova ogni mattina senza aprire l’app, e accanto la tua serie.';

  @override
  String get widgetAskStepHold =>
      'Tieni premuto un punto vuoto della schermata Home.';

  @override
  String get widgetAskStepAppleAdd => 'Tocca Modifica, poi Aggiungi widget.';

  @override
  String get widgetAskStepApplePick =>
      'Cerca Astute, scegli la misura e tocca Aggiungi widget.';

  @override
  String get widgetAskStepAndroidAdd => 'Tocca Widget.';

  @override
  String get widgetAskStepAndroidPick =>
      'Cerca Astute, poi tieni premuto un widget e trascinalo dove vuoi.';

  @override
  String get widgetAskLockScreen =>
      'Anche nella schermata di blocco: tienila premuta, poi tocca Personalizza.';

  @override
  String get widgetAskPin => 'Aggiungi alla schermata Home';

  @override
  String get widgetAskGotIt => 'Ho capito';

  @override
  String get widgetAskNotNow => 'Non ora';

  @override
  String pathCardOf(int n, int total) {
    return 'Carta $n di $total';
  }

  @override
  String get pathDoorNext => 'Prossima nel percorso';

  @override
  String get shareSendCard => 'Manda la carta';

  @override
  String get shareAsImage => 'Come immagine';

  @override
  String get shareCopyLink => 'Copia link';

  @override
  String get shareAnswerNote =>
      'Il tuo amico vede prima la domanda. La risposta è a un tocco, sulla pagina della carta.';

  @override
  String get shareWhichSide => 'Tu da che parte stai?';

  @override
  String get rereadRight => 'La prima volta l’hai indovinata.';

  @override
  String get rereadWrong => 'La prima volta l’hai sbagliata.';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: 'ho sbagliato di $off punti',
      one: 'ho sbagliato di 1 punto',
      zero: 'ho fatto centro',
    );
    return 'La sfida di oggi su Astute: $_temp0. Fai meglio?';
  }

  @override
  String get playTheCard => 'Gioca la carta';

  @override
  String get openTheCard => 'Apri la carta';

  @override
  String get perkPathsTitle => 'Ogni percorso, intero';

  @override
  String get perkPathsLine =>
      'Dieci carte su un tema, dalla più facile alla più difficile. Nuovi percorsi ogni settimana.';

  @override
  String get journeyStrongest => 'Punto forte';

  @override
  String get journeyMostMissed => 'Punto cieco';

  @override
  String journeyRightShare(String pct) {
    return '$pct giuste';
  }

  @override
  String get journeyChangedMind => 'Hai cambiato idea';

  @override
  String get journeyNewToYou => 'Nuove per te';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'su $n carte che lo chiedevano',
      one: 'su 1 carta che lo chiedeva',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n le sapevi già',
      one: '1 la sapevi già',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => 'Il tuo percorso, come una storia';

  @override
  String get storyLabNote => 'Versione nuova · in prova, solo TestFlight';

  @override
  String get storyChapterWeek => 'Questa settimana';

  @override
  String get storyChapterWhere => 'Dove sei';

  @override
  String get storyChapterReason => 'Come ragioni';

  @override
  String get storyChapterPractice => 'Allenati';

  @override
  String get storyChapterStory => 'La tua storia';

  @override
  String get journeyChapterKnow => 'Cosa sai';

  @override
  String get journeyChapterHabits => 'Le tue abitudini';

  @override
  String get journeyChapterCoach => 'Il tuo coach';

  @override
  String get coachTeaser =>
      'Ogni settimana, una nota del coach su come ragioni: cosa è andato bene, la trappola da evitare, cosa provare.';

  @override
  String get coachRead => 'Leggi la nota della settimana';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nelle risposte date con sicurezza, avevi ragione $n volte su 10.',
      one: 'Nelle risposte date con sicurezza, avevi ragione 1 volta su 10.',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => 'Meglio della settimana scorsa.';

  @override
  String get storyWorse => 'Un po’ meno della settimana scorsa.';

  @override
  String storyHeadlineStreak(int n) {
    return '$n giorni di fila. Non perdere il filo.';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return 'In $subject hai ragione il $pct delle volte.';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte lette. Il percorso comincia qui.',
      one: 'Una carta letta. Il percorso comincia qui.',
      zero: 'La tua prima carta ti aspetta.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadWeek(int n, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte lette',
      one: 'Una carta letta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      week,
      locale: localeName,
      other: '$week questa settimana.',
      one: 'una questa settimana.',
      zero: 'nessuna ancora questa settimana.',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String storyHeadlineReadAllWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte lette, tutte questa settimana.',
      one: 'Una carta letta finora.',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return 'La tua sicurezza: $sure. Hai ragione il $right delle volte.';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ancora $n risposte con il quanto sei sicuro, e si misura.',
      one: 'Ancora una risposta con il quanto sei sicuro, e si misura.',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return 'Dove ti fidi troppo: $subject, di $points punti.';
  }

  @override
  String get storyUnlock => 'Vedilo con Astute+';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Le $n sbagliate con sicurezza',
      one: 'Quella sbagliata con sicurezza',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Le $n che ti hanno fatto cambiare idea',
      one: 'La carta che ti ha fatto cambiare idea',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '5 carte nuove di $subject';
  }

  @override
  String get storyPracticeNone =>
      'Ancora niente da allenare: rispondi a qualche carta e arriva.';

  @override
  String get storyFirstCard => 'Prima carta';

  @override
  String storyReached(String level) {
    return 'Raggiunto: $level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Serie migliore: $n giorni',
      one: 'Serie migliore: 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte lette',
      one: '1 carta letta',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => 'Oggi';

  @override
  String get storySeePath => 'Vedi il percorso';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n carte nuove in cima',
      one: '1 carta nuova in cima',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => 'Sei in pari: per ora niente di nuovo.';

  @override
  String get deeperTitle => 'Approfondisci';

  @override
  String get deeperSimple => 'Spiegamelo semplice';

  @override
  String get deeperWhy => 'Perché conta';

  @override
  String get deeperSides => 'Le due parti';

  @override
  String get deeperExample => 'Un esempio di tutti i giorni';

  @override
  String get deeperQuiz => 'Mettimi alla prova su un caso nuovo';

  @override
  String get deeperQuizRight => 'Giusto.';

  @override
  String get deeperQuizWrong => 'Non proprio.';

  @override
  String get mathsDailySolve => 'Risolvilo';

  @override
  String get mathsDailySolved => 'Risolto';

  @override
  String get mathsDailyMissed => 'Non stavolta';

  @override
  String get mathsDailyTomorrow => 'Domani uno nuovo';

  @override
  String get mathsDailyAnother => 'Un altro come questo';

  @override
  String goalShelf(String goal) {
    return 'Ti serve per: $goal';
  }

  @override
  String get goalDecide => 'Decisioni di ogni giorno';

  @override
  String get goalPeople => 'Le persone';

  @override
  String get goalBusiness => 'Lavoro e affari';

  @override
  String get goalMoney => 'Soldi e acquisti';

  @override
  String get goalHealth => 'Salute';

  @override
  String get goalDecideLine =>
      'Scelte, rischi e probabilità, senza andare a istinto.';

  @override
  String get goalNews => 'Notizie e social';

  @override
  String get goalNewsLine => 'Titoli, statistiche e post: cosa regge davvero.';

  @override
  String get goalPeopleLine => 'Chi ti vuole convincere, e come farti capire.';

  @override
  String get goalBusinessLine =>
      'Trattative, incentivi e i numeri dietro un’idea.';

  @override
  String get goalMoneyLine =>
      'Prezzi, offerte, interessi: le trappole di un affare.';

  @override
  String get goalHealthLine =>
      'Diete, cure e studi: cosa dicono davvero le prove.';

  @override
  String mathsDailyStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni di fila',
      one: '1 giorno di fila',
    );
    return '$_temp0';
  }

  @override
  String get deeperYourTake => 'La tua idea, analizzata';

  @override
  String get deeperYourTakeHint => 'Scrivi cosa ne pensi…';

  @override
  String get deeperAnalyse => 'Analizza';

  @override
  String get deeperAsk => 'Chiedi su questa carta';

  @override
  String get deeperAskHint => 'La tua domanda…';

  @override
  String get deeperSend => 'Chiedi';

  @override
  String get deeperSource => 'Fonte';

  @override
  String get deeperOpenSource => 'Apri l’originale';

  @override
  String get deeperAiNote => 'Risponde un’AI: può sbagliare.';

  @override
  String get deeperBusy => 'Ci penso…';

  @override
  String get deeperTomorrow => 'Per oggi basta: domani ancora.';

  @override
  String get deeperTryAgain => 'Non è arrivato. Riprova tra poco.';

  @override
  String get deeperUnavailable =>
      'Non disponibile in questo momento. Riprova più tardi.';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n testate',
      one: '1 testata',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n h fa',
      zero: 'Adesso',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni fa',
      one: 'Ieri',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => 'Mondo';

  @override
  String get newsKeyPoints => 'I punti chiave';

  @override
  String get newsBehind => 'Dietro la notizia';

  @override
  String get newsMeansForYou => 'Cosa significa per te';

  @override
  String get newsMeans => 'Cosa significa';

  @override
  String get newsHappenedBefore => 'È già successo';

  @override
  String get newsSources => 'Fonti';

  @override
  String get newsMadeFrom =>
      'Scritto da Astute a partire da questi articoli, e verificato su di essi.';

  @override
  String get newsWhyItMatters => 'Perché conta';

  @override
  String get deeperDeclined => 'A questa non può rispondere.';

  @override
  String get deeperPlusOnly => 'Con Astute+';

  @override
  String get deeperSimpleLead =>
      'L’idea della carta, come la racconteresti a un bambino curioso di dieci anni.';

  @override
  String get deeperSidesLead =>
      'Le ragioni più forti di ciascuna parte, e cosa chiuderebbe la questione.';

  @override
  String get deeperExampleLead =>
      'Un momento di una giornata qualunque in cui questa idea salta fuori.';

  @override
  String get deeperQuizLead =>
      'Un caso che la carta non cita: una domanda, tre risposte.';

  @override
  String get deeperYourTakeLead =>
      'Cosa regge nel tuo ragionamento, dove scivola, e una domanda per metterlo alla prova.';

  @override
  String get deeperAskLead => 'Quello che la carta ti ha lasciato da chiedere.';

  @override
  String get deeperSideA => 'Una parte';

  @override
  String get deeperSideB => 'L’altra parte';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => 'Riprova';

  @override
  String get deeperSimpleGo => 'Spiegamelo';

  @override
  String get deeperSidesGo => 'Mostrami le due parti';

  @override
  String get deeperExampleGo => 'Fammi un esempio';

  @override
  String get deeperQuizGo => 'Mettimi alla prova';

  @override
  String get bookOfTheWeek => 'Libro della settimana';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n idee',
      one: '1 idea',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Altre $n idee da questo libro',
      one: 'Ancora un’idea da questo libro',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine =>
      'Il libro intero con Astute+, e ogni settimana un libro gratis.';

  @override
  String get bookMoreGo => 'Leggi tutto il libro';

  @override
  String bookMinutes(int n) {
    return '$n min';
  }

  @override
  String get bookStart => 'Inizia a leggere';

  @override
  String get bookContinue => 'Continua';

  @override
  String get bookAgain => 'Rileggi';

  @override
  String get bookTheIdeas => 'Le idee';

  @override
  String get bookRecommendedBy => 'Consigliato da';

  @override
  String get bookFreeThisWeek => 'Gratis questa settimana';

  @override
  String get booksSeeAll => 'Vedi tutti';

  @override
  String get booksLibraryTitle => 'Tutti i libri';

  @override
  String get bookDoneTitle => 'Libro finito';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return '$ideas grandi idee, in $minutes minuti.';
  }

  @override
  String bookDoneCount(int count) {
    return 'Libri finiti: $count';
  }

  @override
  String get bookDoneNext => 'Il prossimo libro';

  @override
  String get bookDoneGo => 'Aprilo';

  @override
  String bookRetold(String title, String author) {
    return 'Le idee di $title di $author, raccontate con parole di Astute. Per il libro intero, cercalo in libreria.';
  }

  @override
  String get foundersTitle => 'Cosa leggono i fondatori';

  @override
  String founderBookCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n libri',
      one: '1 libro',
    );
    return '$_temp0';
  }

  @override
  String get founderTheirBooks => 'I libri che ha consigliato';

  @override
  String founderRole(String id, String role) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bill_gates': 'Cofondatore di Microsoft',
      'warren_buffett': 'L’investitore che ha fatto grande Berkshire Hathaway',
      'mark_zuckerberg': 'Fondatore di Facebook',
      'charlie_munger': 'Socio di Warren Buffett in Berkshire Hathaway',
      'marc_andreessen': 'Cofondatore di Netscape e di Andreessen Horowitz',
      'tobi_lutke': 'Fondatore di Shopify',
      'naval_ravikant': 'Cofondatore di AngelList',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String founderWhere(String id, String where) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'gates_summer': 'GatesNotes, i suoi libri per l’estate',
      'berkshire_meeting': 'l’assemblea annuale di Berkshire Hathaway',
      'berkshire_letter': 'la sua lettera agli azionisti di Berkshire Hathaway',
      'year_of_books': 'A Year of Books, su Facebook',
      'publisher_praise': 'il suo elogio del libro, sul sito dell’editore',
      'ferriss_five':
          'The Tim Ferriss Show, tra i cinque libri migliori che abbia letto',
      'other': '$where',
    });
    return '$_temp0';
  }

  @override
  String founderAbout(String name) {
    return 'Sono libri che $name ha consigliato in pubblico, con le parole citate e il punto in cui le ha dette. $name non ha alcun legame con Astute.';
  }

  @override
  String founderPhoto(String author, String licence) {
    return 'Foto: $author, $licence, Wikimedia Commons, ritagliata';
  }

  @override
  String founderAlso(String names) {
    return 'Consigliato anche da $names';
  }

  @override
  String get firstCardTitle => 'La tua prima carta';

  @override
  String get firstCardSwipeOn => 'Scorri per andare avanti';

  @override
  String get trialOfferTitle => 'Prova tutto Astute+.';

  @override
  String get trialOfferMark => 'Astute+.';

  @override
  String get trialOfferLine =>
      'Le cinque carte di oggi ti aspettano in ogni caso.';

  @override
  String get trialStepToday => 'Oggi';

  @override
  String get trialStepTodayLine => 'Si apre tutto Astute+. Non paghi nulla.';

  @override
  String trialStepDay(int day) {
    return 'Giorno $day';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ti mandiamo una notifica: mancano $days giorni.',
      one: 'Ti mandiamo una notifica: manca 1 giorno.',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine =>
      'Si rinnova ogni anno. Disdici almeno 24 ore prima e non paghi nulla.';

  @override
  String get trialOfferStart => 'Inizia la prova';

  @override
  String get trialOfferFree => 'Continua gratis';

  @override
  String get paywallStepFree => 'Tutto gratis';

  @override
  String get paywallStepRemind => 'Te lo ricordiamo';

  @override
  String get paywallChargedToday => 'Addebito oggi · Disdici quando vuoi';

  @override
  String paywallGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'Per chi vuole decidere meglio.',
      'money': 'Per chi non si fa fregare sui soldi.',
      'people': 'Per chi vuole capire le persone.',
      'news': 'Per chi non abbocca ai titoli.',
      'health': 'Per chi sulla salute vuole le prove.',
      'business': 'Per chi al lavoro vuole vederci chiaro.',
      'other': 'Per chi vuole vederci chiaro.',
    });
    return '$_temp0';
  }

  @override
  String paywallGoalMark(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'meglio.',
      'money': 'soldi.',
      'people': 'persone.',
      'news': 'titoli.',
      'health': 'prove.',
      'business': 'chiaro.',
      'other': 'chiaro.',
    });
    return '$_temp0';
  }

  @override
  String paywallMadeLine(String subjects) {
    return 'Cinque carte al giorno di $subjects, al tuo livello. Quelle che sbagli tornano finché non restano. E vedi come cambi, settimana per settimana.';
  }

  @override
  String subjectsTwo(String a, String b) {
    return '$a e $b';
  }

  @override
  String subjectsThree(String a, String b, String c) {
    return '$a, $b e $c';
  }

  @override
  String get firstWeekTitle => 'La tua prima settimana';

  @override
  String get firstMonthTitle => 'Il tuo primo mese';

  @override
  String firstOfferDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n giorni di lettura',
      one: 'Un giorno di lettura',
    );
    return '$_temp0';
  }

  @override
  String get firstWeekBest => 'La carta migliore della settimana';

  @override
  String get firstMonthBest => 'La carta migliore del mese';

  @override
  String firstOfferBestWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'said': 'L’hai raccontata a qualcuno.',
      'liked': 'Ti è piaciuta.',
      'saved': 'L’hai salvata.',
      'changed': 'Ti ha fatto cambiare idea.',
      'other': 'L’hai tenuta.',
    });
    return '$_temp0';
  }

  @override
  String firstOfferTrialTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+, gratis per $days giorni',
      one: 'Astute+, gratis per un giorno',
    );
    return '$_temp0';
  }

  @override
  String get firstOfferPlusLine =>
      'Cinque carte tutte tue ogni giorno, ogni percorso e ogni libro, e i tuoi numeri settimana per settimana.';

  @override
  String get firstOfferNotNow => 'Non ora';

  @override
  String get listenEntry => 'Ascolta le cinque di oggi';

  @override
  String get listenEntryShort => 'Ascolta';

  @override
  String get listenTitle => 'Le cinque di oggi';

  @override
  String get listenQuestion => 'Domanda';

  @override
  String get listenThink => 'Pensaci…';

  @override
  String get listenAnswer => 'Risposta';

  @override
  String get listenPreparing => 'Preparo la voce…';

  @override
  String get listenWaiting => 'La prossima carta sta arrivando…';

  @override
  String get listenFreeNote => 'La prima carta è gratis; le altre con Astute+.';

  @override
  String get listenOfferTitle => 'Le altre carte di oggi, lette per te';

  @override
  String get listenOfferLine =>
      'Con Astute+ ascolti tutte e cinque ogni giorno, anche a schermo bloccato.';

  @override
  String get listenNothing => 'Niente da ascoltare in questa carta';

  @override
  String get listenCardUnavailable => 'Non disponibile adesso';

  @override
  String get listenUnavailable =>
      'L’ascolto non è disponibile adesso. Riprova più tardi.';

  @override
  String get listenDone => 'Tutte le carte di oggi, ascoltate.';

  @override
  String get listenAgain => 'Ascolta di nuovo';

  @override
  String get listenNextCard => 'Carta successiva';

  @override
  String get inviteSection => 'Amici';

  @override
  String get inviteRow => 'Invita un amico';

  @override
  String get inviteRowLine => 'Una settimana di Astute+ a tutti e due';

  @override
  String get inviteCodeRow => 'Hai un codice?';

  @override
  String get inviteCodeAccepted => 'Codice accettato';

  @override
  String get inviteCodeAcceptedLine =>
      'La settimana parte quando finisci la prima giornata';

  @override
  String get inviteSheetLine =>
      'Manda il tuo codice a un amico. Quando finisce la sua prima giornata, le cinque carte, avete una settimana di Astute+ a testa.';

  @override
  String get inviteYourCode => 'Il tuo codice';

  @override
  String get inviteCopy => 'Copia';

  @override
  String get inviteSend => 'Invia l’invito';

  @override
  String inviteRules(int cap) {
    return 'Vale per un account nuovo che non ha mai avuto Astute+. Ricevi fino a $cap settimane l’anno.';
  }

  @override
  String inviteWeeksSoFar(int n, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n settimane su $cap quest’anno',
      one: '1 settimana su $cap quest’anno',
    );
    return '$_temp0';
  }

  @override
  String inviteCapped(int cap) {
    return 'Hai avuto le $cap settimane di quest’anno. I tuoi amici ricevono comunque la loro.';
  }

  @override
  String inviteMessage(String code, String link) {
    return 'Ti invito su Astute: cinque carte al giorno per tenere la mente allenata. Con il mio codice $code, quando finisci la tua prima giornata abbiamo una settimana di Astute+ a testa.\n$link';
  }

  @override
  String inviteMessageCapped(String code, String link) {
    return 'Ti invito su Astute: cinque carte al giorno per tenere la mente allenata. Con il mio codice $code, quando finisci la tua prima giornata hai una settimana di Astute+ in regalo.\n$link';
  }

  @override
  String get inviteCodeTitle => 'Il codice di un amico';

  @override
  String get inviteCodeLine =>
      'Scrivi il codice che ti ha mandato un amico. Quando finisci la tua prima giornata, avete una settimana di Astute+ a testa.';

  @override
  String get inviteCodeUse => 'Usa il codice';

  @override
  String get inviteCodeWaitingLine =>
      'Finisci la tua prima giornata, le cinque carte: poi la settimana di Astute+ parte, per te e per chi ti ha invitato.';

  @override
  String get inviteRefusedUnknown =>
      'Questo codice non esiste. Controlla le lettere e riprova.';

  @override
  String get inviteRefusedOwn => 'È il tuo codice: mandalo a un amico.';

  @override
  String get inviteRefusedUsed => 'Hai già usato il codice di un amico.';

  @override
  String get inviteRefusedLate =>
      'Il codice vale per gli account nuovi, nella loro prima settimana.';

  @override
  String get inviteRefusedPlus =>
      'Il codice vale per chi non ha mai avuto Astute+.';

  @override
  String get inviteSuccessTitle => 'Una settimana di Astute+, in regalo.';

  @override
  String get inviteSuccessPlan => 'Astute+ · una settimana';

  @override
  String inviteSuccessUntil(String date) {
    return 'Fino al $date';
  }

  @override
  String get inviteSuccessFoot =>
      'Niente da pagare e niente da disdire: poi torni al piano gratuito.';

  @override
  String inviteEarned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n amici hanno finito la prima giornata: $n settimane di Astute+ per te.',
      one: 'Un amico ha finito la sua prima giornata: una settimana di Astute+ per te.',
    );
    return '$_temp0';
  }
}
