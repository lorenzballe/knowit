// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

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
    return 'LES $word DU JOUR';
  }

  @override
  String get tapToFlip => 'TOUCHE POUR RETOURNER';

  @override
  String get shareThisCard => 'Partager cette carte';

  @override
  String get removeFromSaved => 'Retirer des gardées';

  @override
  String get saveThisPill => 'Garder cette carte';

  @override
  String get shareThisPill => 'Partager cette carte';

  @override
  String cardOf(int k, int n) {
    return 'Carte $k sur $n';
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
  String magicUnlock(int days) {
    return 'Essaie $days jours gratuits';
  }

  @override
  String get getPlus => 'Passe à Astute+';

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
      'Aucune carte ne correspond encore à ce filtre.';

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
      'Ta série, tes cartes gardées et ton historique restent sur ton compte. Ceci les efface de cet appareil.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deletingAccount => 'Suppression du compte…';

  @override
  String get deleteAccountQuestion => 'Supprimer ton compte ?';

  @override
  String get deleteAccountBody =>
      'Ton compte, sa sauvegarde et le tableau que voient tes amis sont supprimés définitivement, et cet appareil repart de zéro. Astute+ n\'est pas résilié pour autant : l\'abonnement se gère dans les réglages de l\'App Store.';

  @override
  String get deleteAccountConfirm => 'Supprimer définitivement';

  @override
  String get accountDeleted => 'Ton compte a été supprimé.';

  @override
  String get couldNotDeleteAccount =>
      'Impossible de supprimer le compte. Réessaie dans un instant.';

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
      'Efface tout sur cet appareil — série, cartes gardées, réponses, ton historique de jugements, sujets et forfait — et rouvre l\'introduction.';

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
  String get journeyButtonLine =>
      'Ton niveau, les coups que tu rates encore, ta semaine en questions';

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
      'Tes 5 cartes, avant le premier café.';

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
      'Rappel activé, mais le système a refusé. Active les notifications d\'Astute dans les réglages.';

  @override
  String get nudgeOnNeedsPhone =>
      'Rappel activé. La livraison demande la version téléphone.';

  @override
  String savedN(int n) {
    return 'Gardées · $n';
  }

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

  @override
  String get howPillsAreWritten => 'Comment les cartes sont écrites';

  @override
  String get howTitle => 'Chaque carte ici est écrite par un modèle d\'IA.';

  @override
  String get howIntro =>
      'Nous préférons le dire d\'emblée plutôt que tu le découvres. Voici comment une carte arrive jusqu\'à toi.';

  @override
  String get howStep1Title => 'Écrite à l\'avance, par un modèle';

  @override
  String get howStep1Line =>
      'Chaque carte suit une seule consigne : une question qui vaut la peine, une réponse qui dit pourquoi, et un réflexe à réutiliser.';

  @override
  String get howStep2Title => 'Vérifiée sur sa source';

  @override
  String get howStep2Line =>
      'Chaque carte dit d\'où elle vient, et un second modèle la relit en critique avant sa sortie. Ce qui ne tient pas est coupé.';

  @override
  String get howStep3Title => 'Cinq, distribuées chaque matin';

  @override
  String get howStep3Line =>
      'Parmi les sujets que tu as choisis, et jamais une que tu as déjà lue.';

  @override
  String get howStep4Title => 'Gardée honnête par les lecteurs';

  @override
  String get howStep4Line =>
      'Quand assez de lecteurs disent qu\'une carte est fausse, elle n\'est plus distribuée tant qu\'une personne ne l\'a pas vérifiée.';

  @override
  String get howReportTitle => 'Tu as trouvé une erreur ?';

  @override
  String get howReportLine =>
      'Touche le drapeau à côté de la source d\'une carte pour la signaler.';

  @override
  String get howFoot => 'Les sources sont revérifiées chaque mois.';

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
      'Voir chaque principe avec Astute plus';

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
      'La mesure est en cours. Astute+ te montre dans quel sens elle va.';

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
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days jours gratuits';
  }

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
      other: 'cartes lues',
      one: 'carte lue',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes lues',
      one: '1 carte lue',
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
  String get welcomeBack => 'Bon retour';

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
      other: '$n cartes sont restées non lues',
      one: '1 carte est restée non lue',
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
  String subjectsInTheMix(int n, int total) {
    return '$n sujets sur $total dans le mix';
  }

  @override
  String get everythingIsInDrag =>
      'Tout est dedans. Fais glisser un sujet vers le bas pour en voir moins, ou jusqu\'à zéro pour le retirer.';

  @override
  String get next => 'Suivant';

  @override
  String get whatShouldWeTalkAbout => 'De quoi parle-t-on ?';

  @override
  String get fivePillsADayPick =>
      'Cinq cartes par jour, nouvelles chaque matin. Choisis les sujets que tu veux dans le mix — tu pourras les changer plus tard.';

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
  String get introTopicsTitle => 'Dix-neuf sujets, cinq cartes';

  @override
  String get introTopicsLine =>
      'Écrites à l\'avance par un modèle, et chacune vérifiée sur sa source.';

  @override
  String get introQuestionTitle => 'Une question, puis la réponse';

  @override
  String get introQuestionLine =>
      'Chaque carte porte la phrase qui mérite d\'être dite à voix haute.';

  @override
  String get introMixTitle => 'Tu choisis le mix';

  @override
  String get introMixLine =>
      'Baisse un sujet pour en voir moins, ou coupe-le pour de bon.';

  @override
  String get introThirtyTitle => 'Deux minutes par jour';

  @override
  String get introThirtyLine =>
      'Une notification, cinq cartes, et une série que tu ne voudras pas casser.';

  @override
  String introNotifyWhen(String time) {
    return 'Demain, $time';
  }

  @override
  String get introNotifyLine => 'Tes cinq sont prêtes. Jour 1.';

  @override
  String get introOneOfFive => '1 SUR 5';

  @override
  String get introDayOne => 'JOUR 1';

  @override
  String get introTapTomorrow => 'TOUCHE DEMAIN POUR SAVOIR';

  @override
  String get introDayOneTomorrow => 'JOUR 1 · DEMAIN';

  @override
  String get introDaySevenStreak => 'JOUR 7 · PREMIÈRE SÉRIE';

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
  String get barMoveCaps => 'À RETENIR';

  @override
  String get theBarMoveCaps => 'LA PHRASE DE COMPTOIR';

  @override
  String get widgetFootPlain => 'Cinq cartes, deux minutes.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Série de $n jours',
      one: 'Série de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Terminé pour aujourd\'hui';

  @override
  String get widgetStreakStart => 'Lis les cinq du jour pour lancer une série.';

  @override
  String get widgetFiveTitle => 'LES CINQ DU JOUR';

  @override
  String widgetFiveRead(int n) {
    return '$n sur 5 lues';
  }

  @override
  String get widgetFiveDone => 'Les cinq sont lues';

  @override
  String get widgetFiveWaiting => 'Cinq nouvelles cartes t\'attendent';

  @override
  String get widgetShelfTitle => 'L\'ÉTAGÈRE DU JOUR';

  @override
  String get widgetShelfFrom => 'De l\'étagère du jour';

  @override
  String get dayStreakCaps => 'JOURS DE SÉRIE';

  @override
  String sourceLabel(String source) {
    return 'Source · $source';
  }

  @override
  String get perkArchiveTitle => 'Toute ton archive';

  @override
  String get perkArchiveLine => 'Chaque jour lu, gardé pour de bon.';

  @override
  String get plusIsActive => 'ASTUTE+ EST ACTIF';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days jours gratuits, puis $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'S\'abonner pour $price$suffix';
  }

  @override
  String get noChargeTodayCancel =>
      'Rien à payer aujourd\'hui · annule quand tu veux';

  @override
  String get chargedTodayCancel => 'Payé aujourd\'hui · annule quand tu veux';

  @override
  String get everyCardForYouMark => 'toi.';

  @override
  String get trialStartedNoPayment =>
      'Essai lancé. Aucun paiement n\'est branché dans cette version.';

  @override
  String get thatDidNotGoThrough => 'Ça n\'est pas passé.';

  @override
  String get plusIsBack => 'Astute+ est de retour.';

  @override
  String get nothingToRestore => 'Rien à restaurer sur ce compte.';

  @override
  String get planYearly => 'Annuel';

  @override
  String get planMonthly => 'Mensuel';

  @override
  String get perYearShort => '/an';

  @override
  String get perMonthShort => '/mois';

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
  String get termsOfUse => 'Conditions';

  @override
  String get privacyPolicy => 'Confidentialité';

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
      other:
          '$n cartes auxquelles tu as répondu il y a quelques jours, revenues pour voir si c\'est resté',
      one: 'Une carte à laquelle tu as répondu il y a quelques jours, revenue pour voir si c\'est resté',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Tu t\'en souviens encore ?';

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
  String get likeThisPill => 'J\'aime cette carte';

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
      'Touche le marque-page d\'une carte et elle atterrit ici — celles qui ont changé ta façon de penser, gardées.';

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

  @override
  String nRead(int n) {
    return '$n lues';
  }

  @override
  String get topLevel => 'Niveau max';

  @override
  String plusNToday(int n) {
    return '+$n aujourd\'hui';
  }

  @override
  String get bySubject => 'Par matière';

  @override
  String get pts => 'points';

  @override
  String nStillWithYou(int n) {
    return '$n encore avec toi';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pièges',
      one: '1 piège',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday =>
      'Ton score commence avec les cinq d\'aujourd\'hui.';

  @override
  String get anonymousUsage => 'Données d’usage';

  @override
  String get anonymousUsageLine =>
      'Comment l’app est utilisée — ce qui est lu, gardé et dit, et ce qui ne marche pas — pour que les prochaines cartes soient meilleures. Jamais ton nom, ton e-mail ni ce que tu écris.';

  @override
  String get usageOn => 'Partagées, sans ton nom ni tes mots.';

  @override
  String get usageOff => 'Plus rien n’est mesuré.';

  @override
  String get yourMix => 'Ton mélange';

  @override
  String get genresLine =>
      'Touche un genre pour le passer. Maintiens-le et les trois fils qu’il contient s’ouvrent juste dessous.';

  @override
  String get insideGenre => 'Dedans';

  @override
  String nOfSixOn(int n, int total) {
    return '$n sur $total actifs';
  }

  @override
  String get offInYourMix => 'hors de ton mélange';

  @override
  String continueGenresOn(int on, int total) {
    return 'Continuer · $on genres sur $total actifs';
  }

  @override
  String get mixRarely => 'Rarement';

  @override
  String get mixSometimes => 'Parfois';

  @override
  String get mixOften => 'Souvent';

  @override
  String get mixALot => 'Beaucoup';

  @override
  String get mixFull => 'À fond';

  @override
  String get forYouChip => 'POUR TOI';

  @override
  String get againChip => 'ENCORE';

  @override
  String get magicLine =>
      'Cinq cartes par jour choisies pour toi : de ton mix, à ton niveau, jamais une déjà lue. Dès demain.';

  @override
  String get everyCardForYou => 'Chaque carte, choisie pour toi.';

  @override
  String get perkOwnTitle => 'Cinq cartes par jour, toutes à toi';

  @override
  String get perkOwnLine =>
      'De tes fils, à ton niveau, jamais une déjà lue. En gratuit, deux par jour.';

  @override
  String get plusCardHeadline => 'Les cinq, à toi.';

  @override
  String get plusCardLine =>
      'Cinq cartes par jour de ton mix, à ton niveau. Ton voyage. Toute ton archive.';

  @override
  String get continueFree => 'Continuer gratuitement';

  @override
  String get archiveBeforeThisWeek => 'Avant cette semaine';

  @override
  String get weekKeptThreeOwn =>
      'Une semaine tenue : demain, trois des cinq sont à toi.';

  @override
  String get perkJourneyLine =>
      'Ton niveau, chaque sujet fil par fil, ce qui est resté, et les coups que tu rates encore.';

  @override
  String get topOfTheWeek => 'Top de la semaine';

  @override
  String get topOfTheMonth => 'Top du mois';

  @override
  String topIn(String subject) {
    return 'Top en $subject';
  }

  @override
  String get topLineWeek =>
      'Les plus aimées, gardées et racontées ces 7 derniers jours';

  @override
  String get topLineMonth =>
      'Les plus aimées, gardées et racontées ces 30 derniers jours';

  @override
  String get topWeek => 'Semaine';

  @override
  String get topMonth => 'Mois';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lecteurs',
      one: '1 lecteur',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Rien dans la liste pour l\'instant. Chaque carte que tu aimes, gardes ou racontes compte.';

  @override
  String get readMark => 'Lue';

  @override
  String get lovedSinceTheStart => 'Les plus aimées depuis le début';

  @override
  String lovedIn(String subject) {
    return 'Les plus aimées en $subject';
  }

  @override
  String get lovedLine =>
      'Ce que les lecteurs ont le plus gardé, et que tu n\'as pas encore lu';

  @override
  String get forYouShelf => 'Pour toi';

  @override
  String get forYouLine => 'Ce que ta lecture met en premier';

  @override
  String get exploreOffline =>
      'Tu es hors ligne. Voici Explorer tel qu\'il a été lu la dernière fois.';

  @override
  String get askYourselfCaps => 'DEMANDE-TOI';

  @override
  String get themeMyths => 'Mythes démontés';

  @override
  String get themeMythsLine =>
      'Ce que presque tout le monde croit, et pourquoi c\'est faux';

  @override
  String get themeParadoxes => 'Paradoxes';

  @override
  String get themeParadoxesLine =>
      'Deux choses vraies qui ne devraient pas l\'être ensemble';

  @override
  String get themeNumbers => 'Des chiffres qui surprennent';

  @override
  String get themeNumbersLine => 'Là où le chiffre est le coup de théâtre';

  @override
  String get themePractical => 'À utiliser aujourd\'hui';

  @override
  String get themePracticalLine =>
      'Quelque chose à essayer, ou à glisser dans une conversation, avant ce soir';

  @override
  String get themeOrigins => 'D\'où ça vient';

  @override
  String get themeOriginsLine =>
      'L\'origine de choses que vous utilisez chaque jour';

  @override
  String get themeStories => 'Histoires vraies';

  @override
  String get themeStoriesLine => 'Des choses vraiment arrivées';

  @override
  String get themeDebates => 'Choisissez votre camp';

  @override
  String get themeDebatesLine =>
      'Pas de bonne réponse, seulement un meilleur argument';

  @override
  String get themeWorkItOut => 'Faites le calcul';

  @override
  String get themeWorkItOutLine =>
      'Devine le nombre avant que la carte te le dise';

  @override
  String get themeSeen => 'À voir';

  @override
  String get themeSeenLine => 'Des cartes qui dessinent leur idée';

  @override
  String get themeSharpest => 'Pour les plus vifs';

  @override
  String get themeSharpestLine => 'Les cartes les plus difficiles';

  @override
  String get themePast0 => 'Le monde antique';

  @override
  String get themePast1 => 'Du XVIIe au XIXe siècle';

  @override
  String get themePast2 => 'Le siècle dernier';

  @override
  String get themePastLine => 'Une autre époque à chaque retour';

  @override
  String get themePlace0 => 'Asie et Moyen-Orient';

  @override
  String get themePlace1 => 'Les Amériques';

  @override
  String get themePlace2 => 'L\'Europe';

  @override
  String get themePlaceLine => 'Une autre région du monde à chaque retour';

  @override
  String get themeTrueOrFalse => 'Vrai ou faux ?';

  @override
  String get themeTrueOrFalseLine =>
      'Décide avant de retourner. Presque tout le monde se trompe';

  @override
  String get themeReasoning => 'Juste raisonner';

  @override
  String get themeReasoningLine =>
      'Rien à retenir : seulement une façon d\'y réfléchir';

  @override
  String get themeIdeas => 'Grandes idées';

  @override
  String get themeIdeasLine =>
      'La théorie derrière les choses, une idée à la fois';

  @override
  String get themeCurious => 'Juste curieux';

  @override
  String get themeCuriousLine => 'Pour le plaisir de savoir pourquoi';

  @override
  String get themeMoving => 'En mouvement';

  @override
  String get themeMovingLine =>
      'Ce qui change en ce moment, et pourquoi ça compte';

  @override
  String get themeHowItWorks => 'Comment ça marche vraiment';

  @override
  String get themeHowItWorksLine =>
      'Le mécanisme derrière ce que tu vois chaque jour';

  @override
  String get themePuzzles => 'Casse-têtes';

  @override
  String get themePuzzlesLine => 'Des énigmes pour un stylo et une minute';

  @override
  String get weekRecapCaps => 'CETTE SEMAINE TU T\'ES DEMANDÉ';

  @override
  String get weekRecapLine => 'Les questions que tes cartes t\'ont laissées';

  @override
  String weekRecapMore(int n) {
    return '$n de plus de ta semaine avec Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ est dans l\'app : télécharge Astute sur iPhone ou Android pour commencer ton essai gratuit.';

  @override
  String get purchaseComplete => 'Achat effectué.';

  @override
  String get successWelcome =>
      'Bienvenue dans Astute+. Les cinq cartes du jour sont prêtes.';

  @override
  String successWelcomeNamed(String name) {
    return 'Bienvenue dans Astute+, $name. Les cinq cartes du jour sont prêtes.';
  }

  @override
  String get successFiveCards => '5 cartes par jour';

  @override
  String get successArchive => 'Toutes les archives';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Gratuit jusqu’au $date, puis $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Renouvellement le $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Reçu';

  @override
  String get letsStart => 'C’est parti';

  @override
  String successFootFirstCharge(String date) {
    return 'Premier prélèvement le $date · résiliable à tout moment';
  }

  @override
  String successFootRenews(String date) {
    return 'Renouvellement le $date · résiliable à tout moment';
  }

  @override
  String get tryToday => 'À ESSAYER AUJOURD’HUI';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'ou';

  @override
  String get nextStep => 'Étape suivante';

  @override
  String get showAllSteps => 'Tout voir';

  @override
  String get revealSeePicture => 'Voir le schéma';

  @override
  String get revealPlayScene => 'Essaie toi-même';

  @override
  String get revealBackToAnswer => 'Retour à la réponse';

  @override
  String get revealShowWorking => 'Voir le raisonnement';

  @override
  String get sceneLockIn => 'VALIDER';

  @override
  String get sceneYou => 'VOUS';

  @override
  String get sceneTruth => 'RÉEL';

  @override
  String get sceneTryAgain => 'Recommencer';

  @override
  String get sceneDrawHint => 'Dessinez votre idée du doigt';

  @override
  String get sceneHoldHint => 'Maintenez appuyé';

  @override
  String get sceneSwipeHint => 'Glissez ou touchez';

  @override
  String get sceneTapToPick => 'Touchez votre choix';

  @override
  String get sceneShowMe => 'Montrez-moi';

  @override
  String get sceneYourGuess => 'Votre idée';

  @override
  String sceneNOfM(int n, int m) {
    return '$n sur $m';
  }

  @override
  String get reportProblem => 'Signaler un problème';

  @override
  String get reportedThanks => 'Signalé. Merci.';

  @override
  String get reportTitle => 'Qu\'est-ce qui ne va pas sur cette carte ?';

  @override
  String get reportLead =>
      'Nous vérifions chaque signalement dans les sources et corrigeons la carte.';

  @override
  String get reportFact => 'Un fait est faux';

  @override
  String get reportAnswer => 'La réponse donnée comme juste est fausse';

  @override
  String get reportSource => 'La source ne le confirme pas';

  @override
  String get reportUnclear => 'C\'est confus';

  @override
  String get reportTypo => 'Une coquille ou une ligne cassée';

  @override
  String get reportOther => 'Autre chose';

  @override
  String get reportNoteHint => 'Ce qui peut nous aider à vérifier (facultatif)';

  @override
  String get reportSend => 'Envoyer';

  @override
  String get reportSentToast => 'Merci. Nous allons vérifier.';

  @override
  String get journeyPointsOff => 'points d\'écart';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Encore $n réponses avec ta certitude, et on le mesure.',
      one: 'Encore une réponse avec ta certitude, et on le mesure.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Ton score';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'points',
      one: 'point',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n en 4 semaines';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cette semaine, pour l\'instant, tu as gagné $n points.',
      one: 'Cette semaine, pour l\'instant, tu as gagné $n point.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'La semaine du $date, tu as gagné $n points.',
      one: 'La semaine du $date, tu as gagné $n point.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes',
      one: '$n carte',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Ton score à la fin de chaque semaine depuis le $date. Touche un point pour voir cette semaine.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Niveau $n sur $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\navant $rung';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes',
      one: '$n carte',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n réponses',
      one: '$n réponse',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n réponses avec ta certitude',
      one: '$n réponse avec ta certitude',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cartes retenues',
      one: '$n carte retenue',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n points',
      one: '$n point',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Équivalent';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n essais',
      one: '$n essai',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'ou $h h de documentaires';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'encore $n avant le premier essai',
      one: 'encore $n avant le premier essai',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'D\'affilée';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '$n jour',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Record $best · $active sur $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n sur $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'sujets · pointillés : $month';
  }

  @override
  String get journeySubjects => 'sujets';

  @override
  String get journeyHowHard => 'Difficulté';

  @override
  String get journeyOfThree => 'sur 3';

  @override
  String get journeyHardNow => 'Les cartes que tu ouvres.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Les cartes que tu ouvres. $v en $month';
  }

  @override
  String get journeyReadingTime => 'Temps de lecture';

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
    return '$now min par semaine, contre $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min cette semaine';
  }

  @override
  String get journeyTimedFromToday => 'Compté dès aujourd\'hui';

  @override
  String journeyPointsOffFrom(int was) {
    return 'points d\'écart, contre $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · $n max';
  }

  @override
  String get journeyRightWhenSure => 'Juste quand tu es sûr';

  @override
  String journeyFromIn(String v, String month) {
    return 'Contre $v en $month';
  }

  @override
  String get journeySureNone => 'Encore aucune réponse à 80 % ou plus';

  @override
  String get journeyMovesTitle => 'Pièges que tu repères';

  @override
  String journeyOfN(int n) {
    return 'sur $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Dernier : $name';
  }

  @override
  String get journeyNoneYet => 'Rien pour l\'instant';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'cartes encore avec toi',
      one: 'carte encore avec toi',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: 'un jour',
    );
    return '$right sur $of après $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semaines',
      one: 'une semaine',
    );
    return '$right sur $of après $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$active sur $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Surtout le matin';

  @override
  String get journeyMostlyAfternoon => 'Surtout l\'après-midi';

  @override
  String get journeyMostlyEvening => 'Surtout le soir';

  @override
  String get journeyMostlyNight => 'Surtout la nuit';

  @override
  String get journeyInTime => 'Dans le temps';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString ans';
  }

  @override
  String journeyFromEra(String era) {
    return 'depuis $era jusqu\'à nos jours';
  }

  @override
  String get journeyEraAncient => 'l\'Antiquité';

  @override
  String get journeyEraMedieval => 'le Moyen Âge';

  @override
  String get journeyEraEarlyModern => 'le XVIe siècle';

  @override
  String get journeyEraNineteenth => 'le XIXe siècle';

  @override
  String get journeyEraTwentieth => 'le XXe siècle';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'rien de daté pour l\'instant';

  @override
  String get journeyInPlace => 'Dans le monde';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n régions',
      one: '$n région',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list et l\'espace';
  }

  @override
  String get journeyRegionAmericas => 'Amériques';

  @override
  String get journeyRegionEurope => 'Europe';

  @override
  String get journeyRegionAsia => 'Asie';

  @override
  String get journeyRegionOceania => 'Océanie';

  @override
  String get journeyRegionAfrica => 'Afrique';

  @override
  String get journeyRegionMiddleEast => 'Moyen-Orient';

  @override
  String get journeyNoPlace => 'aucun lieu pour l\'instant';

  @override
  String get journeyTopics => 'Thèmes';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rencontrés',
      one: '$n rencontré',
    );
    return '$_temp0';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return 'dont $n en $subject';
  }

  @override
  String get journeyWords => 'Mots';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nouveaux',
      one: '$n nouveau',
    );
    return '$_temp0';
  }

  @override
  String get anotherOne => 'Une autre';

  @override
  String answerIs(String said) {
    return 'Réponse : $said';
  }

  @override
  String get answeredAlready => 'Déjà répondue';

  @override
  String get anyCard =>
      'N\'importe quel sujet, n\'importe quelle étagère, une carte';

  @override
  String betN(int n) {
    return 'Miser $n';
  }

  @override
  String get betWord => 'Miser';

  @override
  String get biggerLabel => 'Plus grand';

  @override
  String get biggerYouGotIt => 'Plus grand · bien vu';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Après $n jours',
      one: 'Après un jour',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Après une semaine';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Après $n semaines',
      one: 'Après une semaine',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Vérifier';

  @override
  String closerDone(String said, int right, int steps) {
    return 'C\'est $said. Tu en as eu $right sur $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'Non : c\'est moins de $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'Non : c\'est plus de $v.';
  }

  @override
  String get closerStart => 'Trois étapes pour s\'en approcher.';

  @override
  String closerYesLess(String v) {
    return 'Oui : c\'est moins de $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Oui : c\'est plus de $v.';
  }

  @override
  String get corrections => 'Rectificatifs';

  @override
  String get didYouKnow => 'Le savais-tu ?';

  @override
  String get didYouKnowLine =>
      'Retourne-la, puis : nouveau pour toi, ou tu le savais ?';

  @override
  String get dragToSet => 'Fais glisser';

  @override
  String get dykAgain => 'Encore';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n que tu savais',
      one: '1 que tu savais',
      zero: 'Aucune que tu savais',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nouvelles pour toi',
      one: '1 nouvelle pour toi',
      zero: 'Rien de nouveau aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'C\'était l\'édition du jour';

  @override
  String get editionTomorrow => 'Celle de demain sort au matin';

  @override
  String get eraAncient => 'Le monde antique';

  @override
  String get eraAncientWhen => 'Avant 500';

  @override
  String get eraEarlyModern => 'Les Temps modernes';

  @override
  String get eraEarlyModernWhen => 'De 1500 à 1800';

  @override
  String get eraMedieval => 'Le Moyen Âge';

  @override
  String get eraMedievalWhen => 'De 500 à 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n autres de cette époque',
      one: '1 autre de cette époque',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'Le XIXe siècle';

  @override
  String get eraNineteenthWhen => 'De 1800 à 1900';

  @override
  String get eraRecent => 'Ce siècle';

  @override
  String get eraRecentWhen => 'Depuis 2000';

  @override
  String get eraRulerNow => 'Aujourd\'hui';

  @override
  String get eraRulerOld => 'Antiquité';

  @override
  String get eraShortAncient => 'Antiquité';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Moyen Âge';

  @override
  String get eraShortNineteenth => 'XIXe siècle';

  @override
  String get eraShortRecent => 'XXIe siècle';

  @override
  String get eraShortTwentieth => 'XXe siècle';

  @override
  String get eraTwentieth => 'Le siècle dernier';

  @override
  String get eraTwentiethWhen => 'De 1900 à 2000';

  @override
  String get fewCards => 'En quelques cartes';

  @override
  String get fewCardsLine =>
      'Quand une seule carte ne suffit pas à l\'expliquer';

  @override
  String get firstLabel => 'Dès';

  @override
  String get forYouNow => 'Pour toi, maintenant';

  @override
  String get hardBadge => 'Difficile';

  @override
  String hidesIn(String where) {
    return 'Dans $where';
  }

  @override
  String get howSure => 'À quel point j\'en suis sûr, et pourquoi ?';

  @override
  String get inNumbers => 'En chiffres';

  @override
  String inRange(int pts, String said) {
    return 'Dans la fourchette : +$pts points. C\'est $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'Dans tes coups · $n×';
  }

  @override
  String itIs(String said) {
    return 'C\'est $said.';
  }

  @override
  String get knewIt => 'Je savais';

  @override
  String get less => 'Moins';

  @override
  String get lookFirst => 'Regarde le graphique avant de croire le titre.';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Raté : c\'est $said.';
  }

  @override
  String get modeBigger => 'Lequel est plus grand ?';

  @override
  String get modeCloser => 'De plus en plus près';

  @override
  String get modePick => 'Choisis';

  @override
  String get modeRange => 'Parie sur une fourchette';

  @override
  String get modeSlide => 'Fais glisser';

  @override
  String get modeStake => 'Place ta mise';

  @override
  String get monthShelfLine =>
      'Un nouveau sujet chaque mois, le même pour tous';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cartes',
      one: '1 carte',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'Le temps que tu as';

  @override
  String get moodTitle => 'Ton humeur, tes minutes';

  @override
  String get moodTone => 'Ton';

  @override
  String get more => 'Plus';

  @override
  String moreOrLess(String v) {
    return 'Plus ou moins de $v ?';
  }

  @override
  String get moveComparedToWhat => 'Par rapport à quoi ?';

  @override
  String get moveComparedToWhatLine =>
      'Un changement ne veut rien dire sans quelque chose à quoi le comparer';

  @override
  String get askingTitle => 'Une question par sujet';

  @override
  String askingIn(String subject) {
    return 'Questions en $subject';
  }

  @override
  String get askingLine =>
      'Les mêmes pour tous. Réponds d\'abord, puis vois pourquoi';

  @override
  String get moveSampling => 'Qui a été compté ?';

  @override
  String get moveSamplingLine =>
      'Qui se retrouve dans une étude décide de ce qu\'elle peut te dire';

  @override
  String mythDeckHint(int at, int of) {
    return '$at sur $of · fais glisser pour passer';
  }

  @override
  String nOfM(int at, int of) {
    return '$at sur $of';
  }

  @override
  String get newMove => 'Nouveau pour toi';

  @override
  String get newToMe => 'Nouveau pour moi';

  @override
  String get notEnoughPoints => 'Pas assez de points';

  @override
  String get notSureLine => 'Une carte de n\'importe où dans Astute';

  @override
  String get notSureTitle => 'Tu ne sais pas par où commencer ?';

  @override
  String get openWord => 'Ouvrir';

  @override
  String get pickOneFirst => 'Choisis d\'abord';

  @override
  String get puzzleOfTheDay => 'L\'énigme du jour';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get rightLastTime => 'Juste la dernière fois';

  @override
  String get sameForEveryoneCaps => 'La même pour tous';

  @override
  String get sayFalse => 'Faux';

  @override
  String get sayTrue => 'Vrai';

  @override
  String get seriesAnchors => 'Premières impressions';

  @override
  String get seriesGrowth => 'Des nombres qui s\'emballent';

  @override
  String seriesMeta(int n, int m) {
    return '$n cartes · environ $m min';
  }

  @override
  String get seriesOdds => 'Des probabilités qui mentent';

  @override
  String get seriesRetold => 'L\'histoire, racontée autrement';

  @override
  String seriesStrand(String name) {
    return '$name, en quelques cartes';
  }

  @override
  String get seriesStudies => 'Pourquoi les études trompent';

  @override
  String showAllN(int n) {
    return 'Tout afficher ($n)';
  }

  @override
  String get showFewer => 'Afficher moins';

  @override
  String get sixtyAgain => 'Rejouer';

  @override
  String sixtyIn(int s) {
    return 'en $s secondes';
  }

  @override
  String get sixtyLine => 'Huit vrai ou faux. Fie-toi à ton instinct';

  @override
  String get sixtyPerfect => 'Les huit justes.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n justes pour l\'instant',
      one: '1 juste pour l\'instant',
      zero: 'Aucune juste pour l\'instant',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'secondes pour huit\nvrai ou faux';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Commencer';

  @override
  String get sixtyTimeUp => 'avant la fin du temps';

  @override
  String get sixtyTitle => 'Soixante secondes';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tu étais à $n points.',
      one: 'Tu étais à 1 point.',
      zero: 'Pile.',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => 'Mise';

  @override
  String stepOf(int at, int of) {
    return 'Étape $at sur $of';
  }

  @override
  String get surpriseMe => 'Surprends-moi';

  @override
  String get tapIfBigger => 'Touche si plus grand';

  @override
  String get tapToTurn => 'Touche pour la retourner';

  @override
  String get tfRight => 'Juste. Ouvre-la pour savoir pourquoi.';

  @override
  String tfWrong(String side) {
    return 'C\'est $side. Ouvre-la pour savoir pourquoi.';
  }

  @override
  String theAnswer(String said) {
    return 'La réponse : $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'À la une';

  @override
  String get throughTime => 'À travers le temps';

  @override
  String get throughTimeLine =>
      'Du monde antique à cette année. Fais glisser pour voyager';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get todaysEdition => 'Édition du jour';

  @override
  String get toneCurious => 'Curieux';

  @override
  String get toneLight => 'Léger';

  @override
  String get toneSerious => 'Sérieux';

  @override
  String get toneTough => 'Corsé';

  @override
  String get unmaskBack => 'Le montrer tel que publié';

  @override
  String get unmaskFlipped => 'Le remettre à l\'endroit';

  @override
  String get unmaskLine => 'Mêmes chiffres, autre image';

  @override
  String get unmaskStretched => 'Prendre une échelle juste';

  @override
  String get unmaskTitle => 'Démasque le graphique';

  @override
  String get unmaskTotals => 'Rendre la comparaison juste';

  @override
  String get unmaskTruncated => 'Démarrer l\'axe à zéro';

  @override
  String get unmaskWindow => 'Montrer toute la série';

  @override
  String get whatIfTrue => 'Et si c\'était vrai ?';

  @override
  String get whatIfTrueLine =>
      'Des cartes qui continuent d\'agir une fois fermées';

  @override
  String get whatYouBelieve => 'Ce que tu crois';

  @override
  String get wrongLastTime => 'Ratée la dernière fois';

  @override
  String youLose(int n) {
    return 'Tu perds $n.';
  }

  @override
  String youWin(int n) {
    return 'Tu gagnes $n.';
  }

  @override
  String get yourPick => 'Ton choix';
}
