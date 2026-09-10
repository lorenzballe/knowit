// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabExplore => 'Explorer';

  @override
  String get tabProfile => 'Profil';

  @override
  String signInNotConnected(String provider) {
    return 'La connexion avec $provider n\'est pas encore branchée. Tes cartes restent sur cet appareil.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Connexion avec $label impossible. Tu peux continuer sans compte.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Un freeze a sauvé la série';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'une',
      '2': 'deux',
      '3': 'trois',
      '4': 'quatre',
      '5': 'cinq',
      '6': 'six',
      '7': 'sept',
      '8': 'huit',
      '9': 'neuf',
      '10': 'dix',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Jour $n · $word lues';
  }

  @override
  String shelfEyebrow(String word) {
    return 'LES $word DU JOUR · GLISSE POUR REVOIR';
  }

  @override
  String weekLine(int days) {
    return 'Ta semaine · $days sur 7 tenus';
  }

  @override
  String get tapToFlip => 'TOUCHE POUR RETOURNER';

  @override
  String get shareThisCard => 'Partager cette carte';

  @override
  String get removeFromSaved => 'Retirer des gardées';

  @override
  String get saveThisPill => 'Garder cette pilule';

  @override
  String get shareThisPill => 'Partager cette pilule';

  @override
  String cardOf(int k, int n) {
    return 'Carte $k sur $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Les cinq de demain s\'ouvrent dans $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic ouvre les cinq de demain, dans $when';
  }

  @override
  String get exploreTodaysBest => 'Explorer le meilleur du jour';

  @override
  String get fiveMore => 'Cinq de plus';

  @override
  String get unlockFiveExtra => 'Débloquer cinq pilules de plus';

  @override
  String nothingInYet(String subject) {
    return 'Rien encore dans $subject.';
  }

  @override
  String get here => 'cette section';

  @override
  String get todaysShelf => 'L\'étagère du jour';

  @override
  String get sameForEveryone => 'La même pour tous, et seulement aujourd\'hui';

  @override
  String get onesThatAskTheMost => 'Celles qui demandent le plus';

  @override
  String get acrossEveryone => 'Chez tout le monde, pas seulement dans ton mix';

  @override
  String becauseSitsAtFull(String name) {
    return 'Parce que $name est au maximum';
  }

  @override
  String get olderFromTurnedUp =>
      'Des cartes plus anciennes des sujets que tu as montés';

  @override
  String moreOn(String name) {
    return 'Encore sur $name';
  }

  @override
  String get subjectReadMost => 'Le sujet que tu as le plus lu';

  @override
  String monthOf(String name) {
    return 'Un mois de $name';
  }

  @override
  String get somewhereToStart =>
      'Un point de départ qui n\'est pas aujourd\'hui';

  @override
  String get searchEveryCard => 'Chercher dans toutes les cartes';

  @override
  String nothingForYet(String query) {
    return 'Rien encore pour « $query ».';
  }

  @override
  String matching(int n) {
    return '$n trouvées';
  }

  @override
  String get all => 'Tout';

  @override
  String get theArchive => 'L\'archive';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n cartes. Touche un jour pour l\'ouvrir.';
  }

  @override
  String get whatYouHaveCovered => 'Ce que tu as couvert';

  @override
  String searchNCards(int n) {
    return 'Chercher dans $n cartes';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes',
      one: '1 carte',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Hier';

  @override
  String get noPillsMatchFilter =>
      'Aucune pilule ne correspond encore à ce filtre.';

  @override
  String nothingForTryTopic(String query) {
    return 'Rien pour « $query ». Essaie un sujet.';
  }

  @override
  String get saved => 'Gardées';

  @override
  String get removedFromSaved => 'Retirée des gardées.';

  @override
  String get undo => 'Annuler';

  @override
  String get nothingKeptYet => 'Rien de gardé pour l\'instant';

  @override
  String nInTopic(int n, String topic) {
    return '$n en $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Garde celles que tu utiliseras vraiment';

  @override
  String get backToTodaysFive => 'RETOUR AUX CINQ DU JOUR';

  @override
  String get archive => 'Archive';

  @override
  String get yourWeek => 'Ta semaine';

  @override
  String get nothingThisWeekYet =>
      'Rien encore cette semaine. Cinq cartes la lancent.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Tenue — $days jours sur sept.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours sur sept.',
      one: '1 jour sur sept.',
    );
    return '$_temp0 Cinq, et la semaine est tenue.';
  }

  @override
  String get howSureAgainstHowRight =>
      'Ta certitude, face à tes réponses justes';

  @override
  String get sureAndWrong => 'Sûr, et faux';

  @override
  String get worthGoingBackTo =>
      'Celles sur lesquelles revenir. Se tromper sur une chose dont on était sûr est le seul moyen bon marché de découvrir ce que l\'on croit vraiment.';

  @override
  String get whereThisIsGoing => 'Où cela mène';

  @override
  String ofNRight(int n) {
    return 'sur $n justes';
  }

  @override
  String get sayHowSureOnMore =>
      'Dis à quel point tu es sûr sur quelques-unes de plus, et l\'app te dira ce que vaut cette certitude.';

  @override
  String confidenceOff(int gap) {
    return 'Ta certitude était à $gap points de ce que tu savais vraiment.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Ta certitude était décalée de $gap points, contre $before la semaine dernière. L\'écart se referme.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Ta certitude était décalée de $gap points, contre $before la semaine dernière. L\'écart s\'est creusé.';
  }

  @override
  String nextRung(String name) {
    return 'Suivant : $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Tu as dit $n % sûr';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Jour un',
      'reading': 'Lecture',
      'answering': 'Réponse',
      'saying_how_sure': 'Dire sa certitude',
      'calibrated': 'Calibré',
      'holding': 'Retenue',
      'sharp': 'Affûté',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Tout le monde commence ici.',
      'reading': 'L\'habitude est lancée.',
      'answering': 'Tu t\'engages avant de retourner la carte.',
      'saying_how_sure': 'Tu mets un chiffre sur ce que tu crois savoir.',
      'calibrated': 'Ce que tu dis savoir, tu le sais.',
      'holding': 'Ça reste avec toi des semaines plus tard.',
      'sharp': 'Sûr quand il le faut, et juste quand tu l\'es.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'encore $n cartes à lire';
  }

  @override
  String stepAnswer(int n) {
    return 'encore $n cartes à répondre';
  }

  @override
  String stepJudge(int n) {
    return 'encore $n réponses avec ta certitude';
  }

  @override
  String stepHold(int n) {
    return 'encore $n cartes à retenir';
  }

  @override
  String stepGap(int gap, int target) {
    return 'ta certitude est décalée de $gap points — $target suffit';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'encore $n réponses avant que l\'app juge ta certitude';
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
  String get signOutQuestion => 'Se déconnecter ?';

  @override
  String get signOutBody =>
      'Ta série, tes pilules gardées et ton historique restent sur ton compte. Ceci les efface de cet appareil.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signedInRecordOnAccount =>
      'Connecté. Ta série et ton historique sont maintenant sur ton compte.';

  @override
  String couldNotSignInWith(String label) {
    return 'Connexion avec $label impossible.';
  }

  @override
  String get signInNotAvailableBuild =>
      'La connexion n\'est pas disponible dans cette version.';

  @override
  String get startOverQuestion => 'Tout recommencer ?';

  @override
  String get startOverBody =>
      'Efface tout sur cet appareil — série, pilules gardées, réponses, ton historique de jugements, sujets et forfait — et rouvre l\'introduction.';

  @override
  String get wipeIt => 'Effacer';

  @override
  String get yourRecord => 'Ton historique';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get yourTopics => 'Tes sujets';

  @override
  String get edit => 'Modifier';

  @override
  String get howWellYouKnowYourself => 'À quel point tu te connais';

  @override
  String get isTheGapClosing => 'L\'écart se referme-t-il ?';

  @override
  String get movesYouKeepMissing => 'Les coups que tu rates encore';

  @override
  String get dailyNudge => 'Rappel quotidien';

  @override
  String everyDayAt(String time) {
    return 'Chaque jour à $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'Tes 5 pilules, avant le premier café.';

  @override
  String get browserOnlySpeaksOpen =>
      'Un navigateur ne parle que lorsqu\'il est ouvert, il faut donc la version téléphone.';

  @override
  String get nudgeOff => 'Rappel désactivé.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Rappel activé, chaque jour à $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Rappel activé, mais le système a refusé. Active les notifications d\'Astut dans les réglages.';

  @override
  String get nudgeOnNeedsPhone =>
      'Rappel activé. La livraison demande la version téléphone.';

  @override
  String get howMuchYouKnow => 'Ce que tu sais';

  @override
  String savedN(int n) {
    return 'Gardées · $n';
  }

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get howPillsAreWritten => 'Comment les pilules sont écrites';

  @override
  String get signingIn => 'Connexion…';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'Sur $n réponses, tu as dit à quel point tu étais sûr. Voici ce qui s\'est passé.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Une personne parfaitement calibrée a raison 70 % du temps quand elle dit 70 %.';

  @override
  String get notEnoughAnswersYet => 'Pas encore assez de réponses';

  @override
  String get confidenceMatchesAccuracy =>
      'Ta certitude correspond à ta précision';

  @override
  String overconfidentBy(int points) {
    return 'Tu es trop sûr de $points points';
  }

  @override
  String underconfidentBy(int points) {
    return 'Tu es trop peu sûr de $points points';
  }

  @override
  String saidPercent(int n) {
    return 'Dit $n %';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'juste à $pct % ($right sur $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'encore $n contextes à venir',
      one: 'encore 1 contexte à venir',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus =>
      'Voir chaque principe avec Astut plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n de plus suivis',
      one: '1 de plus suivi',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'PARTAGER MON HISTORIQUE';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Tes $n dernières réponses, face aux $n premières';
  }

  @override
  String closedByPoints(int n) {
    return 'Refermé de $n points';
  }

  @override
  String openedByPoints(int n) {
    return 'Creusé de $n points';
  }

  @override
  String get holdingSteady => 'Stable';

  @override
  String get measurementRunningPlus =>
      'La mesure est en cours. Astut+ te montre dans quel sens elle va.';

  @override
  String firstN(int n) {
    return '$n premières';
  }

  @override
  String lastN(int n) {
    return '$n dernières';
  }

  @override
  String get trackingMoreClosely =>
      'Ta certitude suit ta précision de plus près qu\'avant.';

  @override
  String get distanceHasGrown =>
      'L\'écart a grandi. Ça vaut le coup de ralentir avant de t\'engager.';

  @override
  String get noRealMovementYet =>
      'Pas encore de vrai mouvement. Ça prend des semaines, pas des jours.';

  @override
  String get seeWhichWay => 'VOIR DANS QUEL SENS';

  @override
  String get spotOn => 'pile';

  @override
  String pointsOver(int n) {
    return '$n de trop';
  }

  @override
  String pointsUnder(int n) {
    return '$n de moins';
  }

  @override
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 jours gratuits';

  @override
  String get watchTheGapMove => 'Regarde l\'écart bouger.';

  @override
  String get measurementFreeForever =>
      'La mesure est gratuite et le restera. Astut+ est ce qui te dit dans quel sens elle va.';

  @override
  String get seeThePlans => 'VOIR LES FORFAITS';

  @override
  String get recordStartsToday => 'Ton historique commence aujourd\'hui.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'pilules lues',
      one: 'pilule lue',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pilules lues',
      one: '1 pilule lue',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semaines tenues',
      one: '1 semaine tenue',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n qui reviennent';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freezes en réserve',
      one: '1 freeze en réserve',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Forfait gratuit';

  @override
  String get streakReset => 'Série remise à zéro';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tu as manqué\n$n jours.',
      one: 'Tu as manqué\nun jour.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours restent',
      one: 'Un jour reste',
    );
    return '$_temp0 ton record. Lis les cinq du jour et le compteur repart de un.';
  }

  @override
  String get whileYouWereAway => 'Pendant ton absence';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pilules sont restées non lues',
      one: '1 pilule est restée non lue',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic reste le sujet que tu gardes le plus';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes que tu avais justes reviennent aujourd\'hui',
      one: '1 carte que tu avais juste revient aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Repartir avec les cinq du jour';

  @override
  String moveMyReminderTo(String time) {
    return 'Déplacer mon rappel à $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Rappel quotidien déplacé à $time.';
  }

  @override
  String get whatYouAlready => 'Ce que tu ';

  @override
  String get know => 'sais déjà';

  @override
  String get knowIntro =>
      'Les sujets que tu as montés le plus haut. Ça change ce qu\'une journée te demande dans chacun — solide reçoit des questions, curieux reçoit des explications — pas la quantité.';

  @override
  String get startWithMyFirstCards => 'Commencer avec mes premières cartes';

  @override
  String get skipForNow => 'Passer pour l\'instant';

  @override
  String get levelCurious => 'Curieux';

  @override
  String get levelSome => 'Un peu';

  @override
  String get levelSolid => 'Solide';

  @override
  String get save => 'Enregistrer';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n sujets sur $total dans le mix';
  }

  @override
  String get yourSpace => 'Ton ';

  @override
  String get mix => 'mix';

  @override
  String get everythingIsInDrag =>
      'Tout est dedans. Fais glisser un sujet vers le bas pour en voir moins, ou jusqu\'à zéro pour le retirer.';

  @override
  String get next => 'Suivant';

  @override
  String get whatShouldWeTalkAbout => 'De quoi parle-t-on ?';

  @override
  String get fivePillsADayPick =>
      'Cinq pilules par jour, écrites chaque matin. Choisis les sujets que tu veux dans le mix — tu pourras les changer plus tard.';

  @override
  String nSelected(int n) {
    return '$n choisis';
  }

  @override
  String startWithNTopics(int n) {
    return 'Commencer avec $n sujets';
  }

  @override
  String saveNTopics(int n) {
    return 'Enregistrer $n sujets';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Choisis-en au moins $n';
  }

  @override
  String get swipeToSeeMore => 'Glisse pour voir la suite';

  @override
  String get tagline =>
      'Cinq choses intelligentes par jour, prêtes à ressortir en conversation';

  @override
  String get introTopicsTitle => 'Douze sujets, cinq pilules';

  @override
  String get introTopicsLine =>
      'Écrites chaque matin, et vérifiées contre une source.';

  @override
  String get introQuestionTitle => 'Une question, puis la réponse';

  @override
  String get introQuestionLine =>
      'Chaque pilule porte la phrase qui mérite d\'être dite à voix haute.';

  @override
  String get introMixTitle => 'Tu choisis le mix';

  @override
  String get introMixLine =>
      'Baisse un sujet pour en voir moins, ou coupe-le pour de bon.';

  @override
  String get introThirtyTitle => 'Trente secondes par jour';

  @override
  String get introThirtyLine =>
      'Une notification, cinq cartes, et une série que tu ne voudras pas casser.';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithEmail => 'Continuer avec l\'e-mail';

  @override
  String get termsLine =>
      'En t\'inscrivant, tu acceptes nos Conditions d\'utilisation et notre Politique de confidentialité';

  @override
  String get skip => 'Passer';

  @override
  String get tapToRevealLower => 'touche pour révéler';

  @override
  String get barMoveCaps => 'LA PHRASE DE COMPTOIR';

  @override
  String get theBarMoveCaps => 'LA PHRASE DE COMPTOIR';

  @override
  String get dayStreakCaps => 'JOURS DE SÉRIE';

  @override
  String sourceLabel(String source) {
    return 'Source · $source';
  }

  @override
  String get perkRecordTitle => 'Ton historique dans le temps';

  @override
  String get perkRecordLine =>
      'Si l\'écart entre ta certitude et tes réponses justes se referme vraiment.';

  @override
  String get perkPrinciplesTitle => 'Chaque principe rencontré';

  @override
  String get perkPrinciplesLine =>
      'Pas seulement les trois où tu es le plus faible — tous, et les contextes que tu n\'as pas encore vus.';

  @override
  String get perkFreezesTitle => 'Trois freezes de série, pas un';

  @override
  String get perkFreezesLine =>
      'De quoi couvrir un week-end. Une série qu\'on ne peut que perdre finit toujours par partir.';

  @override
  String get perkExtraTitle => '5 pilules de plus chaque jour';

  @override
  String get perkExtraLine =>
      'Un second jeu se débloque dès que tu finis le premier.';

  @override
  String get perkArchiveTitle => 'L\'archive complète';

  @override
  String get perkArchiveLine =>
      'Chaque pilule que tu as lue, cherchable par sujet.';

  @override
  String get perkTopicsTitle => 'Choisis tes propres sujets';

  @override
  String get perkTopicsLine => 'Penche le mix vers ce que tu aimes vraiment.';

  @override
  String get plusIsActive => 'ASTUT+ EST ACTIF';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Essaie 7 jours gratuits, puis $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Essai lancé. Aucun paiement n\'est branché dans cette version.';

  @override
  String get thatDidNotGoThrough => 'Ça n\'est pas passé.';

  @override
  String get plusIsBack => 'Astut+ est de retour.';

  @override
  String get nothingToRestore => 'Rien à restaurer sur ce compte.';

  @override
  String get findOutIfBetter => 'Découvre si tu progresses vraiment.';

  @override
  String get perYear => 'par an';

  @override
  String aMonth(String price) {
    return '$price par mois';
  }

  @override
  String savePercent(int n) {
    return 'ÉCONOMISE $n %';
  }

  @override
  String get perMonth => 'par mois';

  @override
  String get billedMonthly => 'facturé chaque mois';

  @override
  String get cancelTheTrial => 'Annuler l\'essai';

  @override
  String get cancelAnyTime => 'Annule quand tu veux';

  @override
  String get cancelAnyTimeNoPayment =>
      'Annule quand tu veux · Aucun paiement dans cette version';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get everythingOpensNothingCharged =>
      'Tout s\'ouvre. Rien n\'est débité.';

  @override
  String dayN(int n) {
    return 'JOUR $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Un rappel, deux jours avant le renouvellement.';

  @override
  String get itRenewsUnlessCancelled =>
      'Ça se renouvelle, sauf si tu as annulé. Tu peux le faire à tout moment.';

  @override
  String get howTheFreeWeekWorks => 'COMMENT MARCHE LA SEMAINE GRATUITE';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Choisis un camp. Il n\'y a pas de bonne réponse.';

  @override
  String get estimateCloseEnough => 'Estime. Être proche compte.';

  @override
  String get tapToReveal => 'Touche pour révéler';

  @override
  String closeEnoughItIs(String answer) {
    return 'Assez proche · c\'est $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Tu as dit $given · c\'est $answer, et $band compte';
  }

  @override
  String get youGotIt => 'Juste';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Tu as dit $given · c\'est $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong =>
      'Presque tout le monde se trompe ici';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · tu as dit $pct % sûr';
  }

  @override
  String get giveMeANudge => 'Donne-moi un indice';

  @override
  String get beingRightMattersLess =>
      'Avoir raison compte moins que savoir à quelle fréquence tu l\'as.';

  @override
  String get writeItBeforeTheirs => 'Écris-le avant de lire le leur.';

  @override
  String get youAnsweredThisOne => 'Tu as déjà répondu à celle-ci.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Facile',
      'medium': 'Moyen',
      'hard': 'Difficile',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · engage-toi avant de la retourner.';
  }

  @override
  String get yourAnswer => 'Ta réponse';

  @override
  String get checkMyAnswer => 'Vérifier ma réponse';

  @override
  String get howSureAreYou => 'À quel point es-tu sûr ?';

  @override
  String percentSure(int n) {
    return '$n pour cent sûr';
  }

  @override
  String get inOneLineWhy => 'En une ligne — pourquoi ?';

  @override
  String get because => 'Parce que…';

  @override
  String get nowShowMeTheOtherSide => 'Montre-moi l\'autre côté';

  @override
  String get skipShowMeAnyway => 'Passer — montre quand même';

  @override
  String get youTookCaps => 'TU AS PRIS';

  @override
  String get putSimplyCaps => 'EN CLAIR';

  @override
  String get explainLikeImThree => 'Explique-le comme à un enfant';

  @override
  String get whatTheOtherSideSaysCaps => 'CE QUE DIT L\'AUTRE CÔTÉ';

  @override
  String get whatTheOtherSideSays => 'Ce que dit l\'autre côté';

  @override
  String theTrap(String trap) {
    return 'Le piège : $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Tu as pris le camp : $side';
  }

  @override
  String atPercentSure(int n) {
    return ' à $n % de certitude';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Tu as eu celle-ci$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Tu as dit $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Glisse pour la suivante';

  @override
  String get thatWasTheOnlyOne => 'C\'était la seule';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Impossible de dessiner la carte.';

  @override
  String get textCopiedInstead => 'Le texte a été copié à la place.';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers.';

  @override
  String get rendering => 'Rendu en cours…';

  @override
  String get theSourceGoesWithIt => 'La source part avec';

  @override
  String get fiveADayALittleSharper => 'Cinq par jour. Un peu plus affûté.';

  @override
  String get shareMyDay => 'Partager';

  @override
  String climbedTo(String rung) {
    return 'Aujourd\'hui t\'a fait monter à $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right sur $asked justes';
  }

  @override
  String saidSure(int sure) {
    return 'sûr à $sure %';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes sont revenues — réponds encore',
      one: '1 carte est revenue — réponds encore',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Revenues';

  @override
  String get holdACardYouLike => 'Tu aimes ? Maintiens';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n aimées aujourd\'hui',
      one: '1 aimée aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Aimées';

  @override
  String likedN(int n) {
    return 'Aimées · $n';
  }

  @override
  String get nothingLikedYet => 'Rien d\'aimé pour l\'instant';

  @override
  String get likeThisPill => 'J\'aime cette pilule';

  @override
  String get removeFromLiked => 'Retirer des aimées';

  @override
  String get removedFromLiked => 'Retirée des aimées.';

  @override
  String get lessLikeThis => 'Moins comme ça';

  @override
  String get whatYouLikedLandsHere => 'Celles que tu relirais';

  @override
  String get holdToLikeLandsHere =>
      'Maintiens une carte que tu aimes et elle atterrit ici — et l\'app t\'en donne d\'autres du même genre.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Touche le marque-page d\'une pilule et elle atterrit ici — celles qui ont changé ta façon de penser, gardées.';

  @override
  String get nudgeTitle => 'Tes cinq sont prêtes';

  @override
  String get nudgeFreezeTitle => 'Ton gel tient';

  @override
  String nudgeFreezeBody(String question) {
    return 'Hier est couvert. Aujourd\'hui : $question';
  }

  @override
  String get nudgeSureTitle => 'De celle-ci tu étais sûr';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — tu avais dit $sure %.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Il y a deux semaines tu avais lu $read cartes';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Ta confiance était à $gap points de la réalité. Aujourd\'hui : $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '$answered réponses jusqu\'ici. Aujourd\'hui : $question';
  }

  @override
  String get friends => 'Amis';

  @override
  String friendsN(int n) {
    return 'Amis · $n';
  }

  @override
  String get yourFriendCode => 'Ton code ami';

  @override
  String get codeCopied => 'Code copié.';

  @override
  String get addAFriend => 'Ajouter un ami';

  @override
  String get theirCode => 'Son code';

  @override
  String get add => 'Ajouter';

  @override
  String get noFriendsYet =>
      'Personne pour l\'instant. Échange ton code avec un ami et comparez séries et calibration — jamais les réponses.';

  @override
  String get friendsNeedAnAccount =>
      'Comparer demande l\'app sur téléphone et un compte. Tes codes sont gardés.';

  @override
  String get noReaderWithCode => 'Aucun lecteur avec ce code.';

  @override
  String get thatsYourOwnCode => 'C\'est ton propre code.';

  @override
  String pointsOff(int n) {
    return '$n points d\'écart';
  }

  @override
  String get notMeasuredYet => 'pas encore mesurée';

  @override
  String get thisWeekByCalibration => 'Cette semaine, par calibration';

  @override
  String get notYetToday => 'pas encore aujourd\'hui';

  @override
  String nOfSeven(int n) {
    return '$n sur 7';
  }

  @override
  String get you => 'Toi';

  @override
  String get todaysQuestion => 'La question du jour';

  @override
  String get right => 'juste';

  @override
  String get wrong => 'fausse';

  @override
  String rightAtSure(int sure) {
    return 'juste, sûr à $sure %';
  }

  @override
  String wrongAtSure(int sure) {
    return 'fausse, sûr à $sure %';
  }

  @override
  String get yourJourney => 'Ton voyage';

  @override
  String get thePath => 'Le chemin';

  @override
  String get youAreHere => 'TU ES ICI';

  @override
  String reachedOn(String date) {
    return 'Atteint le $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n sur $of lues pour l\'instant';
  }
}
