// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => 'Vandaag';

  @override
  String get tabExplore => 'Ontdek';

  @override
  String get tabProfile => 'Profiel';

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Inloggen met $label is niet gelukt. Je kunt zonder account verder.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Een freeze heeft de reeks gered';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'één',
      '2': 'twee',
      '3': 'drie',
      '4': 'vier',
      '5': 'vijf',
      '6': 'zes',
      '7': 'zeven',
      '8': 'acht',
      '9': 'negen',
      '10': 'tien',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayTitle(int n) {
    return 'Dag $n';
  }

  @override
  String shelfEyebrow(String word) {
    return 'DE $word VAN VANDAAG';
  }

  @override
  String get tapToFlip => 'TIK OM TE DRAAIEN';

  @override
  String get shareThisCard => 'Deze kaart delen';

  @override
  String get removeFromSaved => 'Uit bewaard halen';

  @override
  String get saveThisPill => 'Deze kaart bewaren';

  @override
  String get shareThisPill => 'Deze kaart delen';

  @override
  String get share => 'Delen';

  @override
  String cardOf(int k, int n) {
    return 'Kaart $k van $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'De vijf van morgen · over $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return 'Morgen: $topic · over $when';
  }

  @override
  String get exploreTodaysBest => 'Ontdek het beste van vandaag';

  @override
  String magicUnlock(int days) {
    return 'Probeer $days dagen gratis';
  }

  @override
  String get getPlus => 'Neem Astute+';

  @override
  String nothingInYet(String subject) {
    return 'Nog niets in $subject.';
  }

  @override
  String get here => 'dit deel';

  @override
  String get todaysShelf => 'De plank van vandaag';

  @override
  String get sameForEveryone => 'Voor iedereen hetzelfde, en alleen vandaag';

  @override
  String becauseSitsAtFull(String name) {
    return 'Omdat $name helemaal bovenaan staat';
  }

  @override
  String get olderFromTurnedUp =>
      'Oudere kaarten uit de vakken die je omhoog zette';

  @override
  String moreOn(String name) {
    return 'Meer over $name';
  }

  @override
  String get subjectReadMost => 'Het vak waar je het meest van las';

  @override
  String monthOf(String name) {
    return 'Een maand $name';
  }

  @override
  String get somewhereToStart => 'Een beginpunt dat niet vandaag is';

  @override
  String get searchEveryCard => 'Zoek in alle kaarten';

  @override
  String nothingForYet(String query) {
    return 'Nog niets voor \"$query\".';
  }

  @override
  String matching(int n) {
    return '$n gevonden';
  }

  @override
  String get all => 'Alles';

  @override
  String get theArchive => 'Het archief';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n resultaten',
      one: '1 resultaat',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n kaarten. Tik op een dag om hem te openen.';
  }

  @override
  String get whatYouHaveCovered => 'Wat je hebt gehad';

  @override
  String searchNCards(int n) {
    return 'Zoek in $n kaarten';
  }

  @override
  String get cancel => 'Annuleren';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten',
      one: '1 kaart',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Gisteren';

  @override
  String get noPillsMatchFilter => 'Nog geen kaart past bij dat filter.';

  @override
  String nothingForTryTopic(String query) {
    return 'Niets voor \"$query\". Probeer een vak.';
  }

  @override
  String get saved => 'Bewaard';

  @override
  String get removedFromSaved => 'Uit bewaard gehaald.';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get nothingKeptYet => 'Nog niets bewaard';

  @override
  String nInTopic(int n, String topic) {
    return '$n in $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Bewaar wat je echt gaat gebruiken';

  @override
  String get backToTodaysFive => 'TERUG NAAR DE VIJF VAN VANDAAG';

  @override
  String get archive => 'Archief';

  @override
  String get yourWeek => 'Je week';

  @override
  String get nothingThisWeekYet =>
      'Nog niets deze week. Vijf kaarten zetten hem in gang.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Gehaald — $days van de zeven dagen.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days van de zeven dagen.',
      one: '1 van de zeven dagen.',
    );
    return '$_temp0 Vijf houden de week.';
  }

  @override
  String get howSureAgainstHowRight => 'Hoe zeker, tegenover hoe goed';

  @override
  String get sureAndWrong => 'Zeker, en fout';

  @override
  String get worthGoingBackTo =>
      'De kaarten om naar terug te gaan. Fout zitten over iets waar je zeker van was is de enige goedkope manier om te ontdekken wat je echt gelooft.';

  @override
  String get whereThisIsGoing => 'Waar dit heen gaat';

  @override
  String ofNRight(int n) {
    return 'van $n goed';
  }

  @override
  String get sayHowSureOnMore =>
      'Zeg bij nog een paar hoe zeker je bent en de app vertelt je wat die zekerheid waard is.';

  @override
  String confidenceOff(int gap) {
    return 'Je zekerheid zat $gap punten naast wat je echt wist.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Je zekerheid zat er $gap punten naast, tegen $before vorige week. Het gat sluit.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Je zekerheid zat er $gap punten naast, tegen $before vorige week. Het gat is groter geworden.';
  }

  @override
  String nextRung(String name) {
    return 'Volgende: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Je zei $n% zeker';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Dag één',
      'reading': 'Lezen',
      'answering': 'Antwoorden',
      'saying_how_sure': 'Zekerheid noemen',
      'calibrated': 'Gekalibreerd',
      'holding': 'Vasthouden',
      'sharp': 'Scherp',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Iedereen begint hier.',
      'reading': 'De gewoonte is begonnen.',
      'answering': 'Je legt je vast voor je de kaart omdraait.',
      'saying_how_sure': 'Je zet een getal op wat je denkt te weten.',
      'calibrated': 'Wat je zegt te weten, weet je.',
      'holding': 'Het blijft weken later nog bij je.',
      'sharp': 'Zeker als het moet, en goed als je het bent.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'nog $n kaarten lezen';
  }

  @override
  String stepAnswer(int n) {
    return 'nog $n kaarten beantwoorden';
  }

  @override
  String stepJudge(int n) {
    return 'nog $n antwoorden met hoe zeker je bent';
  }

  @override
  String stepHold(int n) {
    return 'nog $n kaarten vasthouden';
  }

  @override
  String stepGap(int gap, int target) {
    return 'je zekerheid zit er $gap punten naast — $target is genoeg';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'nog $n antwoorden voor de app je zekerheid beoordeelt';
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
      'curiosity': 'Nieuwsgierigheid',
      'observation': 'Oplettendheid',
      'method': 'Methode',
      'judgement': 'Oordeel',
      'insight': 'Inzicht',
      'discernment': 'Helderheid',
      'acumen': 'Scherpzinnigheid',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => 'Nieuw niveau';

  @override
  String levelUpGain(String skill, String n) {
    return 'Je grootste groei deze week: $skill, $n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n antwoorden tot nu toe.',
      one: 'Eén antwoord tot nu toe.',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => 'Niveau';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n punten tot $level',
      one: 'Nog 1 punt tot $level',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n antwoorden tot $level',
      one: 'Nog 1 antwoord tot $level',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => 'Het hoogste niveau';

  @override
  String get levelShareTitle => 'Deel je niveau';

  @override
  String get signOutQuestion => 'Uitloggen?';

  @override
  String get signOutBody =>
      'Je reeks, bewaarde kaarten en staat van dienst blijven in je account. Dit wist ze van dit apparaat.';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get deletingAccount => 'Je account wordt verwijderd…';

  @override
  String get deleteAccountQuestion => 'Je account verwijderen?';

  @override
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'een abonnement beheer je in de App Store-instellingen.',
      'google': 'een abonnement beheer je in Google Play, onder Betalingen en abonnementen.',
      'other':
          'een abonnement beheer je in de winkel waar je het hebt gekocht.',
    });
    return 'Je account en de back-up ervan worden definitief verwijderd, en dit apparaat begint weer bij het begin. Astute+ wordt hiermee niet opgezegd: $_temp0';
  }

  @override
  String get deleteAccountConfirm => 'Definitief verwijderen';

  @override
  String get accountDeleted => 'Je account is verwijderd.';

  @override
  String get couldNotDeleteAccount =>
      'Het account kon niet worden verwijderd. Probeer het zo nog eens.';

  @override
  String get signOut => 'Uitloggen';

  @override
  String get signedInRecordOnAccount =>
      'Ingelogd. Je reeks en staat van dienst staan nu in je account.';

  @override
  String couldNotSignInWith(String label) {
    return 'Inloggen met $label is niet gelukt.';
  }

  @override
  String get signInNotAvailableBuild =>
      'Inloggen is in deze versie niet beschikbaar.';

  @override
  String get startOverQuestion => 'Opnieuw beginnen?';

  @override
  String get startOverBody =>
      'Wist alles op dit apparaat — reeks, bewaarde kaarten, antwoorden, je oordeelsgeschiedenis, vakken en abonnement — en opent de introductie opnieuw.';

  @override
  String get wipeIt => 'Wissen';

  @override
  String get yourRecord => 'Je staat van dienst';

  @override
  String get profileTodayFive => 'De vijf van vandaag';

  @override
  String profileTodayOf(int read, int of) {
    return '$read van $of';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n te lezen',
      one: '1 te lezen',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores => 'Al je scores, week na week';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dagen op rij',
      one: 'dag op rij',
    );
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => 'Laatste 7 dagen';

  @override
  String profileWeekPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'punten',
      one: 'punt',
    );
    return '$_temp0';
  }

  @override
  String get appearance => 'Uiterlijk';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get yourTopics => 'Je vakken';

  @override
  String get edit => 'Bewerken';

  @override
  String get howWellYouKnowYourself => 'Hoe goed je jezelf kent';

  @override
  String get journeyButtonLine =>
      'Je niveau, de zetten die je blijft missen, je week in vragen';

  @override
  String get isTheGapClosing => 'Sluit het gat?';

  @override
  String get movesYouKeepMissing => 'De zetten die je blijft missen';

  @override
  String get dailyNudge => 'Dagelijks duwtje';

  @override
  String everyDayAt(String time) {
    return 'Elke dag om $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'Je 5 kaarten, voor de eerste koffie.';

  @override
  String get browserOnlySpeaksOpen =>
      'Een browser spreekt alleen zolang hij open is, dus hiervoor is de telefoonversie nodig.';

  @override
  String get nudgeOff => 'Duwtje uit.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Duwtje aan, elke dag om $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Duwtje aan, maar het systeem zei nee. Zet meldingen voor Astute aan in de instellingen.';

  @override
  String get nudgeOnNeedsPhone =>
      'Duwtje aan. Bezorging heeft de telefoonversie nodig.';

  @override
  String savedN(int n) {
    return 'Bewaard · $n';
  }

  @override
  String get yourCards => 'Je kaarten';

  @override
  String get emptyLikedHint => 'Houd een kaart vast die je goed vindt';

  @override
  String get emptySavedHint => 'Tik op de bladwijzer van een kaart';

  @override
  String get lastSevenDays => 'Laatste 7 dagen';

  @override
  String get accountSection => 'Account';

  @override
  String get aboutSection => 'Over';

  @override
  String get manageSubscription => 'Abonnement beheren';

  @override
  String get howPillsAreWritten => 'Hoe kaarten geschreven worden';

  @override
  String get howTitle => 'Elke kaart hier is geschreven door een AI-model.';

  @override
  String get howIntro =>
      'We zeggen het liever meteen dan dat je het zelf ontdekt. Zo komt een kaart bij jou.';

  @override
  String get howStep1Title => 'Vooraf geschreven, door een model';

  @override
  String get howStep1Line =>
      'Elke kaart volgt één opdracht: een vraag die het stellen waard is, een antwoord dat zegt waarom, en één zet die je opnieuw kunt gebruiken.';

  @override
  String get howStep2Title => 'Met bronnen, dan gelezen door een criticus';

  @override
  String get howStep2Line =>
      'Elke kaart zegt waar de feiten vandaan komen, en drie op de vier leiden met één tik naar het origineel, zodat je het zelf kunt controleren. De meeste worden gelezen door een tweede model dat als criticus optreedt, en wat het niet kan bevestigen komt op een lijst die een mens nakijkt. Die lijst is nog niet leeg.';

  @override
  String get howStep3Title => 'Vijf, elke ochtend gedeeld';

  @override
  String get howStep3Line =>
      'Uit de vakken die je koos, kaarten die je nog niet gelezen hebt. Een die je goed had, komt later terug, om te zien of hij is blijven hangen.';

  @override
  String get howStep4Title => 'Eerlijk gehouden door lezers';

  @override
  String get howStep4Line =>
      'Als genoeg lezers zeggen dat een kaart niet klopt, wordt ze niet meer gedeeld tot een mens haar heeft gecontroleerd.';

  @override
  String get howReportTitle => 'Iets fout gevonden?';

  @override
  String get howReportLine =>
      'Tik op het vlaggetje naast de bron van een kaart om haar te melden.';

  @override
  String get howFoot =>
      'We lezen elke melding, en we verbeteren een kaart liever dan dat we haar verdedigen.';

  @override
  String get signingIn => 'Inloggen…';

  @override
  String get signInWithApple => 'Inloggen met Apple';

  @override
  String get signInWithGoogle => 'Inloggen met Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'Bij $n antwoorden zei je hoe zeker je was. Dit is wat er gebeurde.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Iemand die perfect gekalibreerd is, heeft 70% van de tijd gelijk als hij 70% zegt.';

  @override
  String get notEnoughAnswersYet => 'Nog niet genoeg antwoorden';

  @override
  String get confidenceMatchesAccuracy =>
      'Je zekerheid klopt met je trefzekerheid';

  @override
  String overconfidentBy(int points) {
    return 'Je bent $points punten te zeker';
  }

  @override
  String underconfidentBy(int points) {
    return 'Je bent $points punten te onzeker';
  }

  @override
  String saidPercent(int n) {
    return 'Gezegd $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'goed $pct% ($right van $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'nog $n contexten hiervan komen',
      one: 'nog 1 context hiervan komt',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Zie elk principe met Astute plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'nog $n worden gevolgd',
      one: 'nog 1 wordt gevolgd',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'MIJN STAAT VAN DIENST DELEN';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Je laatste $n oordelen, tegen je eerste $n';
  }

  @override
  String closedByPoints(int n) {
    return '$n punten gesloten';
  }

  @override
  String openedByPoints(int n) {
    return '$n punten geopend';
  }

  @override
  String get holdingSteady => 'Blijft gelijk';

  @override
  String get measurementRunningPlus =>
      'De meting loopt. Astute+ laat je zien welke kant het op gaat.';

  @override
  String firstN(int n) {
    return 'Eerste $n';
  }

  @override
  String lastN(int n) {
    return 'Laatste $n';
  }

  @override
  String get trackingMoreClosely =>
      'Je zekerheid volgt je trefzekerheid dichter dan eerst.';

  @override
  String get distanceHasGrown =>
      'De afstand is gegroeid. De moeite waard om te vertragen voor je je vastlegt.';

  @override
  String get noRealMovementYet =>
      'Nog geen echte beweging. Dit duurt weken, geen dagen.';

  @override
  String get seeWhichWay => 'ZIE WELKE KANT';

  @override
  String get spotOn => 'precies goed';

  @override
  String pointsOver(int n) {
    return '$n te veel';
  }

  @override
  String pointsUnder(int n) {
    return '$n te weinig';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days dagen gratis';
  }

  @override
  String get seeThePlans => 'BEKIJK DE ABONNEMENTEN';

  @override
  String get recordStartsToday => 'Je staat van dienst begint vandaag.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dagen',
      one: 'dag',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'kaarten gelezen',
      one: 'kaart gelezen',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten gelezen',
      one: '1 kaart gelezen',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weken gehaald',
      one: '1 week gehaald',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n komen terug';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freezes over',
      one: '1 freeze over',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Gratis abonnement';

  @override
  String get welcomeBack => 'Welkom terug';

  @override
  String get comebackTitle => 'Fijn je weer te zien.';

  @override
  String get comebackStillYours => 'Nog steeds van jou';

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen zijn',
      one: 'Eén dag is',
    );
    return '$_temp0 nog steeds je record. Lees de vijf van vandaag en de teller begint weer bij één.';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic is nog steeds het vak dat je het meest bewaart';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten die je goed had komen vandaag terug',
      one: '1 kaart die je goed had komt vandaag terug',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive =>
      'Opnieuw beginnen met de vijf van vandaag';

  @override
  String moveMyReminderTo(String time) {
    return 'Mijn herinnering naar $time verzetten';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Dagelijks duwtje verzet naar $time.';
  }

  @override
  String get reminderAskTitle => 'Hoe laat wil je een herinnering?';

  @override
  String get reminderAskLine =>
      'Eén melding per dag, met een vraag uit je kaarten.';

  @override
  String get reminderAskTrialLine =>
      'We laten het je twee dagen voor het einde van je proefperiode weten.';

  @override
  String get reminderAskMorning => 'Ochtend';

  @override
  String get reminderAskLunch => 'Lunchtijd';

  @override
  String get reminderAskEvening => 'Avond';

  @override
  String get reminderAskOther => 'Ander tijdstip';

  @override
  String get reminderAskUsual => 'Wanneer je meestal leest';

  @override
  String get reminderAskYes => 'Herinner me';

  @override
  String get reminderAskNotNow => 'Niet nu';

  @override
  String get placeAskTitle => 'Kaarten over waar je woont';

  @override
  String get placeAskLine =>
      'Af en toe geeft Astute je een kaart over de plek waar je woont — de geschiedenis, de wetenschap, de verrassingen.';

  @override
  String get placeOnlyCity =>
      'Alleen je stad wordt bewaard, nooit je precieze locatie.';

  @override
  String get placeAskPreviewLine => 'Bij jou in de buurt · Modena';

  @override
  String get placeAskPreviewQuestion => 'De Ghirlandina helt over. Hoeveel?';

  @override
  String get placeAskYes => 'Gebruik mijn locatie';

  @override
  String get placeAskNotNow => 'Niet nu';

  @override
  String get placeRowTitle => 'Waar je woont';

  @override
  String get placeRowOff => 'Uit';

  @override
  String get placeRowOffLine =>
      'Zet het aan voor kaarten over de plek waar je woont.';

  @override
  String get placeSwitchOn => 'Aanzetten';

  @override
  String get placeUseNow => 'Gebruik nu mijn locatie';

  @override
  String get placeRemove => 'Verwijderen';

  @override
  String placeSetTo(String place) {
    return 'Waar je woont: $place';
  }

  @override
  String get placeRemoved =>
      'Verwijderd. Astute bewaart niet meer waar je woont.';

  @override
  String get placeNotFound =>
      'Het lukte nu niet om te zien waar je bent. Astute probeert het een andere dag opnieuw.';

  @override
  String get placeDeniedNote =>
      'Geen probleem. Je kunt het altijd aanzetten in Profiel.';

  @override
  String get placeServicesOff =>
      'Locatie staat uit op deze telefoon. Zet het aan in de instellingen en probeer het opnieuw.';

  @override
  String get placeNotHere => 'Dit apparaat kan niet zeggen waar je bent.';

  @override
  String get placeSettingsTitle => 'Locatie staat uit voor Astute';

  @override
  String get placeSettingsBody =>
      'Sta Astute in de instellingen toe je locatie te gebruiken, voor kaarten over de plek waar je woont. Alleen je stad wordt bewaard.';

  @override
  String get placeSettingsOpen => 'Open instellingen';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Je Astute+-proefperiode eindigt over $days dagen.',
      one: 'Je Astute+-proefperiode eindigt morgen.',
      zero: 'Je Astute+-proefperiode eindigt vandaag.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return 'Op $date begint je jaarabonnement voor $price. Wil je doorgaan, dan hoef je niets te doen. Opzeggen kan via $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Je proefperiode eindigt over $days dagen',
      one: 'Je proefperiode eindigt morgen',
      zero: 'Je proefperiode eindigt vandaag',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Beheren';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n van $total vakken in de mix';
  }

  @override
  String get everythingIsInDrag =>
      'Alles zit erin. Schuif een vak naar links om er minder van te zien, of helemaal om het te laten vallen.';

  @override
  String get next => 'Volgende';

  @override
  String get whatShouldWeTalkAbout => 'Waar zullen we het over hebben?';

  @override
  String get fivePillsADayPick =>
      'Vijf kaarten per dag, elke ochtend nieuwe. Kies de vakken die je in de mix wilt — je kunt ze later veranderen.';

  @override
  String startWithNTopics(int n) {
    return 'Beginnen met $n vakken';
  }

  @override
  String saveNTopics(int n) {
    return '$n vakken opslaan';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Kies er minstens $n';
  }

  @override
  String get swipeToSeeMore => 'Veeg voor meer';

  @override
  String get tagline =>
      'Begrijp het waarom van dingen en hoe ver je op je kennis kunt vertrouwen';

  @override
  String get introTopicsTitle => 'Twintig vakken, vijf kaarten';

  @override
  String get introTopicsLine =>
      'Vooraf geschreven door een model, en elke kaart noemt haar bron.';

  @override
  String get introQuestionTitle => 'Een vraag, hoe zeker, dan het waarom';

  @override
  String get introQuestionLine =>
      'Zeg eerst hoe zeker je bent. Gaandeweg zie je wat jouw ‘zeker’ waard is.';

  @override
  String get introMixTitle => 'Jij kiest de mix';

  @override
  String get introMixLine =>
      'Zet een vak lager om er minder van te zien, of helemaal uit.';

  @override
  String get introThirtyTitle => 'Twee minuten per dag';

  @override
  String get introThirtyLine =>
      'Eén melding, vijf kaarten, en een reeks die je niet wilt breken.';

  @override
  String introNotifyWhen(String time) {
    return 'Morgen, $time';
  }

  @override
  String get introNotifyLine => 'Je vijf staan klaar. Dag 1.';

  @override
  String get introOneOfFive => '1 VAN 5';

  @override
  String get introDayOne => 'DAG 1';

  @override
  String get introTapTomorrow => 'TIK MORGEN OM HET TE ONTDEKKEN';

  @override
  String get introDayOneTomorrow => 'DAG 1 · MORGEN';

  @override
  String get introDaySevenStreak => 'DAG 7 · EERSTE REEKS';

  @override
  String get continueWithApple => 'Doorgaan met Apple';

  @override
  String get continueWithGoogle => 'Doorgaan met Google';

  @override
  String get startReading => 'Begin met lezen';

  @override
  String get haveAnAccount => 'Heb je al een account?';

  @override
  String get signInLink => 'Inloggen';

  @override
  String get signInWelcomeTitle => 'Welkom terug';

  @override
  String get signInWelcomeLine =>
      'Log in, en je reeks, je bewaarde kaarten en je staat van dienst komen met je mee terug.';

  @override
  String get keepStreakOnNewPhone =>
      'Neem je reeks mee naar een nieuwe telefoon';

  @override
  String get keepStreakTitle => 'Houd je reeks vast';

  @override
  String get keepStreakLine =>
      'Log in, en een nieuwe telefoon gaat verder waar deze ophoudt: je reeks, je bewaarde kaarten, je staat van dienst.';

  @override
  String get signInNotNow => 'Niet nu';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': 'Denken',
      'science': 'Wetenschap',
      'maths': 'Wiskunde',
      'space': 'Ruimte',
      'psychology': 'Psychologie',
      'economics': 'Economie',
      'technology': 'Technologie',
      'history': 'Geschiedenis',
      'human_body': 'Lichaam',
      'philosophy': 'Filosofie',
      'pop_culture': 'Popcultuur',
      'nature': 'Natuur',
      'language': 'Taal',
      'weird_facts': 'Rariteiten',
      'sport': 'Sport',
      'cinema': 'Film',
      'music': 'Muziek',
      'art': 'Kunst',
      'medicine': 'Geneeskunde',
      'food': 'Eten',
      'life': 'Leven',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get cardsInEnglishNote =>
      'De kaarten zijn voorlopig in het Engels; de app spreekt jouw taal.';

  @override
  String termsLine(String terms, String privacy) {
    return 'Door verder te gaan ga je akkoord met onze $terms en $privacy';
  }

  @override
  String get termsLineTerms => 'Gebruiksvoorwaarden';

  @override
  String get termsLinePrivacy => 'Privacyverklaring';

  @override
  String get skip => 'Overslaan';

  @override
  String get tapToRevealLower => 'tik om te onthullen';

  @override
  String get barMoveCaps => 'OM TE ONTHOUDEN';

  @override
  String get widgetFootPlain => 'Vijf kaarten, twee minuten.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen op rij',
      one: '1 dag op rij',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Klaar voor vandaag';

  @override
  String get widgetStreakStart =>
      'Lees de vijf van vandaag om een reeks te starten.';

  @override
  String get widgetFiveTitle => 'DE VIJF VAN VANDAAG';

  @override
  String widgetFiveRead(int n) {
    return '$n van 5 gelezen';
  }

  @override
  String get widgetFiveDone => 'Alle vijf gelezen';

  @override
  String get widgetFiveWaiting => 'Er wachten vijf nieuwe kaarten';

  @override
  String get widgetShelfTitle => 'DE PLANK VAN VANDAAG';

  @override
  String get widgetShelfFrom => 'Van de plank van vandaag';

  @override
  String get dayStreakCaps => 'DAGEN OP RIJ';

  @override
  String sourceLabel(String source) {
    return 'Bron · $source';
  }

  @override
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return 'Verdiepen. Bron: $source';
  }

  @override
  String get sourceKindPaper => 'Studie';

  @override
  String get sourceKindBook => 'Boek';

  @override
  String get sourceKindInstitution => 'Instelling';

  @override
  String get sourceKindDocument => 'Document';

  @override
  String get sourceKindData => 'Cijfers';

  @override
  String get sourceKindReference => 'Naslagwerk';

  @override
  String get sourceKindNews => 'Krant';

  @override
  String get sourceKindCompany => 'Bedrijfsbron';

  @override
  String get sourceKindStandard => 'Norm';

  @override
  String get sourceKindArithmetic => 'Berekening';

  @override
  String get plusIsActive => 'ASTUTE+ IS ACTIEF';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days dagen gratis, daarna $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Abonneer voor $price$suffix';
  }

  @override
  String get paywallRecordTitle => 'Ontdek hoeveel je echt weet.';

  @override
  String get paywallRecordMark => 'echt';

  @override
  String get paywallRecordLine =>
      'Elke dag zeg je hoe zeker je bent. Astute+ laat zien of het gat tussen zeker en goed kleiner wordt, en de zetten die je blijft missen.';

  @override
  String paywallRecordOver(int sure, int right) {
    return 'Je zegt $sure% zeker te zijn en hebt het $right% van de keren goed. Astute+ laat zien of dat gat kleiner wordt, en de zetten die je blijft missen.';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return 'Je zegt $sure% zeker te zijn en hebt het $right% van de keren goed: je weet meer dan je denkt. Astute+ laat zien of dat gat kleiner wordt.';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return 'Je zegt $sure% zeker te zijn en hebt het $right% van de keren goed: bijna gelijk. Astute+ laat zien of dat zo blijft, en de zetten die je blijft missen.';
  }

  @override
  String get paywallOutcomeTitle => 'Laat je door niemand beetnemen.';

  @override
  String get paywallOutcomeMark => 'beetnemen.';

  @override
  String get paywallOutcomeLine =>
      'Vijf kaarten per dag op jouw niveau. Wat je mist, komt terug tot het blijft hangen. En je ziet jezelf veranderen, week na week.';

  @override
  String get paywallFiveTitle => 'Alle vijf, van jou.';

  @override
  String get paywallFiveMark => 'van jou.';

  @override
  String get paywallFiveLine =>
      'Gratis zijn er twee van de vijf voor jou, drie na een volgehouden week. Astute+ kiest alle vijf uit jouw draden, op jouw niveau, en brengt terug wat je mist.';

  @override
  String get paywallReadTitle => 'Wat je gelezen hebt, dag na dag.';

  @override
  String get paywallReadMark => 'dag na dag.';

  @override
  String get paywallReadLine =>
      'De dagen die je de laatste tijd las, nieuwste eerst. Tik op een dag om zijn vijf kaarten te openen, en op een kaart om hem opnieuw te lezen.';

  @override
  String get perkGapTitle => 'Zie het gat kleiner worden';

  @override
  String get perkGapLine =>
      'Je reis, week na week: hoe zeker tegenover hoe goed, en de zetten die je blijft missen.';

  @override
  String get perkOwnFiveTitle => 'Vijf eigen kaarten';

  @override
  String get perkOwnFiveLine =>
      'Elke dag, op jouw niveau, en wat je mist komt terug.';

  @override
  String get perkReadTitle => 'Wat je gelezen hebt';

  @override
  String get perkReadLine =>
      'Je laatste dagen, elk met zijn vijf kaarten, klaar om weer te openen.';

  @override
  String get perkAskTitle => 'Je assistent';

  @override
  String get perkAskLine => 'Legt elke kaart uit en test je daarna.';

  @override
  String get perkCoachTitle => 'Elke week een coach';

  @override
  String get perkCoachLine => 'Waar je misgaat en wat je oefent.';

  @override
  String get perkNew => 'NIEUW';

  @override
  String get threeTitle => 'De drie van vandaag';

  @override
  String threeStep(int n, int total) {
    return '$n van $total';
  }

  @override
  String get threeSame =>
      'Vandaag voor iedereen dezelfde drie. Ongeveer een minuut.';

  @override
  String threeYouSaid(String guess) {
    return 'Jij zei $guess.';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n punten',
      one: '+1 punt',
      zero: 'Geen punten',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => 'Volgende';

  @override
  String get threeSeeScore => 'Bekijk je score';

  @override
  String get threeDone => 'De drie van vandaag · klaar';

  @override
  String get threeYou => 'Jij';

  @override
  String whyMissing(String move) {
    return 'Een denkstap die je vaak mist: $move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move, terug in een nieuw geval';
  }

  @override
  String get whyAgain => 'Terug voor een tweede blik';

  @override
  String whyGoal(String goal) {
    return 'Voor je doel: $goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Zoals $n kaarten die je leuk vond',
      one: 'Zoals een kaart die je leuk vond',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return 'Een moeilijke: in $subject ben je sterk';
  }

  @override
  String whyLevel(String subject) {
    return 'Op jouw niveau in $subject';
  }

  @override
  String whyGentle(String subject) {
    return 'Een makkelijke ingang tot $subject';
  }

  @override
  String whyYourSubject(String subject) {
    return 'Uit $subject, een van je vakken';
  }

  @override
  String get whyRandom => 'Willekeurig gekozen uit je vakken';

  @override
  String get whyTitle => 'Waarom deze kaart';

  @override
  String whyTrains(String move) {
    return 'Ze traint: $move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n keer tegengekomen.',
      one: 'Eén keer tegengekomen.',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n keer goed.',
      one: 'Eén keer goed.',
      zero: 'Nog nooit goed.',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return 'Jouw niveau in $subject';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': 'Net begonnen',
      'some': 'Op weg',
      'strong': 'Sterk',
      'other': 'Op weg',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => 'Laatst met deze denkstap';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen geleden',
      one: 'Gisteren',
      zero: 'Vandaag',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => 'Je doel';

  @override
  String get whyLikedRow => 'Vergelijkbare kaarten die je leuk vond';

  @override
  String get whyRandomLine =>
      'Bij het gratis abonnement wordt een deel van elke dag willekeurig gekozen uit de vakken die je hield.';

  @override
  String get whyPlusLine =>
      'Met Astute+ worden alle vijf voor jou gekozen: op jouw niveau, naar je smaak, en de denkstappen die je mist komen terug.';

  @override
  String get whyMakeMine => 'Alle vijf voor mij';

  @override
  String get whyMore => 'Meer zoals deze';

  @override
  String get whyMoreDone => 'Genoteerd: meer zoals deze';

  @override
  String get whyLess => 'Minder';

  @override
  String get whyTune => 'Je mix afstellen';

  @override
  String get searchTry => 'Probeer';

  @override
  String get searchByNeed => 'Naar behoefte';

  @override
  String get searchByKind => 'Naar soort';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': 'Om te spelen',
      'quiz': 'Quizzen',
      'estimate': 'Schattingen',
      'debate': 'Debatten',
      'quick': 'Snel gelezen',
      'other': 'Kaarten',
    });
    return '$_temp0';
  }

  @override
  String kindCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten',
      one: '1 kaart',
    );
    return '$_temp0';
  }

  @override
  String get areaUsefulFor => 'Handig voor';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n paden · elk tien kaarten',
      one: 'Eén pad · tien kaarten',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => 'De denkstappen die je hier traint';

  @override
  String get areaMoreCards => 'Meer kaarten hiervoor';

  @override
  String get pathKicker => 'Pad';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · $n kaarten · zo\'n $minutes min';
  }

  @override
  String pathPartOf(int part, int parts) {
    return 'Deel $part van $parts';
  }

  @override
  String pathTrains(String moves) {
    return 'Traint: $moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return '$n van $total gelezen';
  }

  @override
  String get pathFreeTag => 'Gratis';

  @override
  String get pathStart => 'Begin het pad';

  @override
  String pathContinueAt(int n) {
    return 'Verder · kaart $n';
  }

  @override
  String get pathContinue => 'Verder';

  @override
  String get notesTitle => 'Notities';

  @override
  String get noteYours => 'Jouw notitie';

  @override
  String get noteAdd => 'Notitie toevoegen';

  @override
  String get noteEdit => 'Bewerken';

  @override
  String get noteSave => 'Opslaan';

  @override
  String get noteDelete => 'Notitie verwijderen';

  @override
  String get noteHint => 'Wat wil je onthouden van deze kaart?';

  @override
  String get notesEmpty =>
      'Nog geen notities. Open een kaart die je hebt bewaard en schrijf op wat je wilt onthouden.';

  @override
  String get pathUnlock => 'Alle paden ontgrendelen';

  @override
  String get pathFreeLine => 'De eerste twee kaarten van elk pad zijn gratis.';

  @override
  String pathNextPart(int n) {
    return 'Deel $n: dieper';
  }

  @override
  String pathDeeperLine(int n) {
    return 'Nog $n kaarten over hetzelfde thema, moeilijker.';
  }

  @override
  String get pathAgain => 'Opnieuw lezen';

  @override
  String get subjectKicker => 'Vak';

  @override
  String subjectReadOf(int n, int total) {
    return '$n van $total kaarten gelezen';
  }

  @override
  String subjectRight(int right, int answered) {
    return '$right goed van $answered beantwoord';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n goede antwoorden tot niveau $level',
      one: 'Eén goed antwoord tot niveau $level',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => 'Niveau';

  @override
  String get subjectNext => 'Volgende voor jou';

  @override
  String get subjectNextLine => 'Eén stap boven jouw niveau.';

  @override
  String subjectInside(String subject) {
    return 'Binnen $subject';
  }

  @override
  String get journeySubjectsTap => 'Tik op een vak voor zijn eigen pagina.';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Basiskansen',
      'survivorship': 'Overlevers',
      'regression': 'Terug naar het gemiddelde',
      'confirmation': 'Bevestiging',
      'anchoring': 'Ankeren',
      'sampling': 'Steekproef',
      'confounding': 'Verstorende factoren',
      'counterfactual': 'Vergeleken met wat',
      'multipleComparisons': 'Veel pogingen',
      'availability': 'Beschikbaarheid',
      'sunkCost': 'Verzonken kosten',
      'conjunction': 'Conjunctie',
      'conditional': 'Voorwaardelijke kans',
      'independence': 'Onafhankelijkheid',
      'coincidence': 'Toeval',
      'exponential': 'Exponentiële groei',
      'reflection': 'Het snelle antwoord',
      'simpson': 'Totalen',
      'estimation': 'Schatten',
      'computation': 'Uitrekenen',
      'other': 'Redeneren',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Hoe nauwkeurig een test is, zegt niet hoe waarschijnlijk het voor jou is',
      'survivorship': 'De data die je hebt, zijn de data die overleefden',
      'regression': 'Uitschieters zakken vanzelf terug',
      'confirmation': 'Zoeken naar een ja is geen test',
      'anchoring': 'Het eerste getal dat valt, verschuift alle getallen erna',
      'sampling': 'Wie in de steekproef zit, bepaalt wat die kan zeggen',
      'confounding': 'Misschien veroorzaakt iets anders allebei',
      'counterfactual': 'Een verandering zegt niets zonder vergelijking',
      'multipleComparisons': 'Test genoeg dingen en één slaagt',
      'availability': 'Makkelijk voor te stellen is niet hetzelfde als vaak',
      'sunkCost':
          'Uitgegeven is uitgegeven; alleen wat over is, valt te beslissen',
      'conjunction':
          'Details maken een verhaal geloofwaardiger en minder waarschijnlijk',
      'conditional': 'Wat je hoort, verandert de kansen',
      'independence': 'Toeval heeft geen geheugen',
      'coincidence': 'Zeldzame dingen zijn gewoon als er veel pogingen zijn',
      'exponential': 'Niemand heeft gevoel voor verdubbelen',
      'reflection':
          'Het antwoord dat eerst opkomt, is het antwoord om te checken',
      'simpson': 'Een geheel kan overhellen waar geen enkel deel overhelt',
      'estimation':
          'Breek het onbeantwoordbare op in dingen die je kunt schatten',
      'computation': 'Een probleem dat je echt kunt afmaken',
      'other': 'Redeneren',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => 'Versturen';

  @override
  String get threeWhy => 'Bekijk het waarom';

  @override
  String threeYesterday(int score) {
    return 'De drie van gisteren: $score van 300.';
  }

  @override
  String threeRowSaid(String said, String truth) {
    return 'Jij zei $said. Het is $truth.';
  }

  @override
  String get fiveTitle => 'De vijf van vandaag';

  @override
  String get fiveSame =>
      'Vandaag voor iedereen dezelfde vijf. Ongeveer twee minuten.';

  @override
  String get fiveDone => 'De vijf van vandaag · klaar';

  @override
  String dailyOf(int max) {
    return 'van $max';
  }

  @override
  String dailyPickRight(String answer) {
    return 'Goed: $answer.';
  }

  @override
  String dailyPickWrong(String answer) {
    return 'Niet helemaal: het is $answer.';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Beter dan $pct% van de $n spelers van vandaag.',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tot nu toe $n spelers vandaag.',
      one: 'Tot nu toe 1 speler vandaag.',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Een van de eerste $n vandaag: nog te weinig om te vergelijken.',
      one: 'De eerste die vandaag speelt: nog te weinig om te vergelijken.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => 'De spelers van vandaag worden geteld…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return 'Je had er $right van de $total goed. Bij deze hebben lezers er gemiddeld $avg goed.';
  }

  @override
  String get dailyUncounted =>
      'De spelers van vandaag kunnen nu niet worden geteld.';

  @override
  String get dailyEach => 'Vraag voor vraag';

  @override
  String dailyItemRight(int pct) {
    return '$pct% van de spelers van vandaag had het goed';
  }

  @override
  String dailyItemGuess(String guess) {
    return 'Gemiddelde schatting vandaag: $guess';
  }

  @override
  String get dailyItemFew => 'Nog te weinig antwoorden om te vergelijken';

  @override
  String fiveYesterday(int score) {
    return 'De vijf van gisteren: $score van 500.';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · De vijf van vandaag · $date';
  }

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · De drie van vandaag · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score van $max · dag $day';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score van $max';
  }

  @override
  String get skillsTitle => 'Wat leren';

  @override
  String get skillsTitleMark => 'leren';

  @override
  String get skillsLine =>
      'Elk antwoord beweegt je score. Kaarten die trainen wat je kiest, dragen zijn teken.';

  @override
  String get skillsDone => 'Klaar';

  @override
  String get skillsFocus => 'IN FOCUS';

  @override
  String get skillMarkKicker => 'DEZE KAART TRAINT';

  @override
  String skillMarkLabel(String skill) {
    return 'Traint $skill';
  }

  @override
  String get skillMarkBody =>
      'Een van de vaardigheden waar je op focust. Elk antwoord op een kaart als deze beweegt je score daarin.';

  @override
  String get skillMarkOpen => 'Al je scores bekijken';

  @override
  String get trainingTitle => 'Jouw training';

  @override
  String get trainingLine =>
      'Elk antwoord beweegt je score, een moeilijke kaart goed het meest. Er is geen plafond.';

  @override
  String get trainingOthers => 'De andere';

  @override
  String get trainingEmpty =>
      'Kies waar je beter in wilt worden. Elk antwoord op een kaart die het traint, beweegt je score, en de kaart draagt zijn teken.';

  @override
  String get trainingPick => 'Vaardigheden kiezen';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'en nog $n',
      one: 'en nog 1',
    );
    return '$_temp0';
  }

  @override
  String get scoreTitle => 'Astute-score';

  @override
  String scoreWeek(String n) {
    return '$n deze week';
  }

  @override
  String get scoreStart => 'Je eerste antwoord zet hem in gang.';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name: $n voor dit antwoord';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'uit $n antwoorden',
      one: 'uit 1 antwoord',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => 'Video';

  @override
  String get videoPlay => 'Afspelen';

  @override
  String get videoPause => 'Pauzeren';

  @override
  String get videoWatchAgain => 'Opnieuw kijken';

  @override
  String get videoOffline =>
      'De video heeft een verbinding nodig. Tik om het opnieuw te proberen.';

  @override
  String get skillsRowTitle => 'Wat je wilt leren';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Kritisch denken',
      'decisions': 'Beter beslissen',
      'money': 'Geld en sparen',
      'numbers': 'Cijfers en statistiek',
      'talk': 'Communiceren',
      'persuade': 'Overtuigen',
      'people': 'Mensen begrijpen',
      'fakes': 'Nepnieuws herkennen',
      'science': 'Denken als wetenschapper',
      'focus': 'Focus',
      'lead': 'Leiderschap',
      'culture': 'Algemene kennis',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => 'Elke dag, op jouw niveau.';

  @override
  String get perkShelvesTitle => 'Elk pad en elk boek';

  @override
  String get perkShelvesLine => 'Helemaal, en elke week nieuwe.';

  @override
  String get perkGapShort => 'Hoe zeker tegen hoe vaak juist, per week.';

  @override
  String get perkReadShort => 'Elke gelezen dag, om opnieuw te openen.';

  @override
  String get trialToday => 'Vandaag · heel Astute+, gratis';

  @override
  String trialReminder(int day) {
    return 'Dag $day · we herinneren je eraan';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'year': 'per jaar',
      'other': 'per maand',
    });
    return 'Dag $day · $price $_temp0, automatisch verlengd tot je opzegt';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '$price$suffix vandaag afgeschreven, automatisch verlengd tot je opzegt';
  }

  @override
  String cancelHow(String where) {
    return 'Zeg op wanneer je wilt via $where, uiterlijk 24 uur voor de verlenging.';
  }

  @override
  String get cancelWhereIos => 'Instellingen › je naam › Abonnementen';

  @override
  String get cancelWhereAndroid =>
      'Google Play › Betalingen en abonnementen › Abonnementen';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Prijzen opvragen bij de App Store…',
      'other': 'Prijzen opvragen bij Google Play…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'De App Store is niet bereikbaar',
      'other': 'Google Play is niet bereikbaar',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine =>
      'De prijzen en de gratis proefperiode komen uit de store. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get tryAgain => 'Opnieuw proberen';

  @override
  String get purchasePending =>
      'Wacht op goedkeuring. Astute+ gaat open zodra de betaling rond is.';

  @override
  String get oneMoment => 'Even geduld…';

  @override
  String get purchaseConfirming => 'Betaling wordt bevestigd…';

  @override
  String get purchaseConfirmingSlow =>
      'Dit duurt langer dan normaal. De betaling is veilig: Astute+ gaat vanzelf aan.';

  @override
  String get closeLabel => 'Sluiten';

  @override
  String get thatDidNotGoThrough => 'Dat is niet gelukt.';

  @override
  String get plusIsBack => 'Astute+ is terug.';

  @override
  String get nothingToRestore => 'Niets te herstellen op dit account.';

  @override
  String get planYearly => 'Jaarlijks';

  @override
  String get planMonthly => 'Maandelijks';

  @override
  String get perYearShort => '/jaar';

  @override
  String get perMonthShort => '/maand';

  @override
  String get perYear => 'per jaar';

  @override
  String aMonth(String price) {
    return '$price per maand';
  }

  @override
  String savePercent(int n) {
    return 'BESPAAR $n%';
  }

  @override
  String get perMonth => 'per maand';

  @override
  String get billedMonthly => 'maandelijks afgerekend';

  @override
  String get cancelTheTrial => 'Proefperiode stoppen';

  @override
  String get cancelAnyTime => 'Altijd opzegbaar';

  @override
  String get restorePurchases => 'Aankopen herstellen';

  @override
  String get termsOfUse => 'Voorwaarden';

  @override
  String get privacyPolicy => 'Privacy';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Kies een kant. Er is geen goed antwoord.';

  @override
  String get estimateCloseEnough => 'Schat. Dichtbij telt.';

  @override
  String get tapToReveal => 'Tik om te onthullen';

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Je zei $given · het is $answer, en $band telt';
  }

  @override
  String youSaidItIs(String given, String answer) {
    return 'Je zei $given · het is $answer';
  }

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · je zei $pct% zeker';
  }

  @override
  String get verdictRight => 'Goed.';

  @override
  String get verdictClose => 'Dichtbij genoeg.';

  @override
  String get verdictWrong => 'Niet helemaal.';

  @override
  String verdictSure(int pct) {
    return 'Je was $pct% zeker.';
  }

  @override
  String get giveMeANudge => 'Geef me een hint';

  @override
  String get beingRightMattersLess =>
      'Gelijk hebben telt minder dan weten hoe vaak je het hebt.';

  @override
  String get writeItBeforeTheirs => 'Schrijf het op voor je het hunne leest.';

  @override
  String get youAnsweredThisOne => 'Deze heb je al beantwoord.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Makkelijk',
      'medium': 'Gemiddeld',
      'hard': 'Moeilijk',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · leg je vast voor je hem omdraait.';
  }

  @override
  String get yourAnswer => 'Je antwoord';

  @override
  String get checkMyAnswer => 'Mijn antwoord checken';

  @override
  String get howSureAreYou => 'Hoe zeker ben je?';

  @override
  String percentSure(int n) {
    return '$n procent zeker';
  }

  @override
  String get inOneLineWhy => 'In één zin — waarom?';

  @override
  String get because => 'Omdat…';

  @override
  String get nowShowMeTheOtherSide => 'Laat me nu de andere kant zien';

  @override
  String get skipShowMeAnyway => 'Overslaan — toch laten zien';

  @override
  String get youTookCaps => 'JIJ KOOS';

  @override
  String get putSimplyCaps => 'SIMPEL GEZEGD';

  @override
  String get explainLikeImThree => 'Leg het uit als aan een kind';

  @override
  String get whatTheOtherSideSaysCaps => 'WAT DE ANDERE KANT ZEGT';

  @override
  String get whatTheOtherSideSays => 'Wat de andere kant zegt';

  @override
  String theTrap(String trap) {
    return 'De valkuil: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Je koos de kant: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' met $n% zekerheid';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Deze had je goed$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Je zei $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Veeg voor de volgende';

  @override
  String get musicSound => 'Geluid bij muziekkaarten';

  @override
  String get musicSoundIsOff => 'Het geluid van muziekkaarten staat uit.';

  @override
  String get musicSoundTurnOn => 'Aanzetten';

  @override
  String get thatWasTheOnlyOne => 'Dat was de enige';

  @override
  String get lastOne => 'De laatste';

  @override
  String deckEndTitle(String word) {
    return 'Dat waren ze alle $word.';
  }

  @override
  String get deckEndAgain => 'Opnieuw vanaf de eerste';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'De kaart kon niet getekend worden.';

  @override
  String get textCopiedInstead => 'In plaats daarvan is de tekst gekopieerd.';

  @override
  String get copiedToClipboard => 'Gekopieerd naar het klembord.';

  @override
  String get rendering => 'Tekenen…';

  @override
  String get theSourceGoesWithIt => 'De bron gaat mee';

  @override
  String get shareMyDay => 'Delen';

  @override
  String climbedTo(String rung) {
    return 'Vandaag bracht je naar $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right van $asked goed';
  }

  @override
  String saidSure(int sure) {
    return '$sure% zeker';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n kaarten die je dagen geleden beantwoordde, terug om te zien of het is blijven hangen',
      one: 'Een kaart die je dagen geleden beantwoordde, terug om te zien of het is blijven hangen',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Weet je het nog?';

  @override
  String get holdACardYouLike => 'Bevalt hij? Houd vast';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n vandaag geliket',
      one: '1 vandaag geliket',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Geliket';

  @override
  String likedN(int n) {
    return 'Geliket · $n';
  }

  @override
  String get nothingLikedYet => 'Nog niets geliket';

  @override
  String get likeThisPill => 'Deze kaart liken';

  @override
  String get removeFromLiked => 'Uit geliket halen';

  @override
  String get removedFromLiked => 'Uit geliket gehaald.';

  @override
  String get lessLikeThis => 'Minder zoals dit';

  @override
  String get whatYouLikedLandsHere => 'De kaarten die je nog eens zou lezen';

  @override
  String get holdToLikeLandsHere =>
      'Houd een kaart vast die je goed vindt en hij komt hier — en de app geeft je er meer van.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Tik op de bladwijzer van een kaart en hij komt hier — de kaarten die je denken veranderden, bewaard.';

  @override
  String get nudgeTitle => 'Je vijf staan klaar';

  @override
  String get nudgeBookTitle => 'Het gratis boek van deze week';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '$title van $author: de grote ideeën in $minutes minuten.';
  }

  @override
  String get nudgeFreezeTitle => 'Je freeze houdt stand';

  @override
  String nudgeFreezeBody(String question) {
    return 'Gisteren is gedekt. Vandaag: $question';
  }

  @override
  String get nudgeSureTitle => 'Hier was je zeker van';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — je zei $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Twee weken geleden had je $read kaarten gelezen';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Je zekerheid zat er $gap punten naast. Vandaag: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '$answered beantwoord tot nu toe. Vandaag: $question';
  }

  @override
  String get yourJourney => 'Je reis';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Sinds je laatste bezoek, $days dagen geleden',
      one: 'Sinds je laatste bezoek, gisteren',
      zero: 'Sinds je laatste bezoek, eerder vandaag',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return '$n sinds je laatste bezoek';
  }

  @override
  String get thePath => 'Het pad';

  @override
  String get youAreHere => 'JE BENT HIER';

  @override
  String reachedOn(String date) {
    return 'Bereikt op $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n van $of tot nu toe gelezen';
  }

  @override
  String nRead(int n) {
    return '$n gelezen';
  }

  @override
  String get topLevel => 'Hoogste niveau';

  @override
  String plusNToday(int n) {
    return '+$n vandaag';
  }

  @override
  String get bySubject => 'Per vak';

  @override
  String get pts => 'punten';

  @override
  String nStillWithYou(int n) {
    return '$n nog bij je';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n trucs',
      one: '1 truc',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'Je score begint met de vijf van vandaag.';

  @override
  String get anonymousUsage => 'Gebruiksgegevens';

  @override
  String get anonymousUsageLine =>
      'Hoe de app wordt gebruikt — wat gelezen, bewaard en gezegd wordt, en wat misgaat — zodat de volgende kaarten beter zijn. Nooit je naam, je e-mail of wat je schrijft.';

  @override
  String get usageOn => 'Gedeeld, zonder je naam of je woorden.';

  @override
  String get usageOff => 'Er wordt niets meer gemeten.';

  @override
  String get consentTitle => 'Help je Astute beter te maken?';

  @override
  String get consentLine =>
      'Deel hoe je de app gebruikt — nooit je naam, je e-mail of wat je schrijft.';

  @override
  String get consentNo => 'Nee, bedankt';

  @override
  String get consentYes => 'Ja, delen';

  @override
  String consentChangeLater(String profile, String setting) {
    return 'Je kunt dit altijd wijzigen in $profile, onder $setting.';
  }

  @override
  String get yourMix => 'Jouw mix';

  @override
  String get genresTitle => 'Welke delen?';

  @override
  String get genresLine =>
      'Tik op een genre om het over te slaan. Houd het vast en de kleinere onderwerpen erin openen er vlak onder.';

  @override
  String get insideGenre => 'Binnenin';

  @override
  String nOfSixOn(int n, int total) {
    return '$n van $total aan';
  }

  @override
  String get offInYourMix => 'niet in jouw mix';

  @override
  String continueGenresOn(int on, int total) {
    return 'Doorgaan · $on van $total genres aan';
  }

  @override
  String get mixRarely => 'Zelden';

  @override
  String get mixSometimes => 'Soms';

  @override
  String get mixOften => 'Vaak';

  @override
  String get mixALot => 'Veel';

  @override
  String get mixFull => 'Vol';

  @override
  String get forYouChip => 'VOOR JOU';

  @override
  String get againChip => 'OPNIEUW';

  @override
  String get magicLine =>
      'Vijf kaarten per dag voor jou gekozen: uit je mix, op jouw niveau, en wat je mist, komt terug. Vanaf morgen.';

  @override
  String get plusCardHeadline => 'Alle vijf van jou.';

  @override
  String get plusCardLine =>
      'Vijf kaarten per dag uit je mix, op jouw niveau. Je reis. Je hele archief.';

  @override
  String get archiveBeforeThisWeek => 'Vóór deze week';

  @override
  String get weekKeptThreeOwn =>
      'Zeven dagen op rij: morgen zijn drie van de vijf van jou.';

  @override
  String get weekKeptSundayFourOwn =>
      'Zeven dagen op rij, en morgen is het zondag: vier van de vijf zijn van jou.';

  @override
  String get topOfTheWeek => 'Top van de week';

  @override
  String get topOfTheMonth => 'Top van de maand';

  @override
  String topIn(String subject) {
    return 'Top in $subject';
  }

  @override
  String get topLineWeek =>
      'Het meest geliket, bewaard en verteld in de afgelopen 7 dagen';

  @override
  String get topLineMonth =>
      'Het meest geliket, bewaard en verteld in de afgelopen 30 dagen';

  @override
  String get topWeek => 'Week';

  @override
  String get topMonth => 'Maand';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lezers',
      one: '1 lezer',
    );
    return '$_temp0';
  }

  @override
  String get topPicksTitle => 'Je tijd waard';

  @override
  String get topPicksLine =>
      'Uitgekozen door Astute zolang de lijst van lezers nog groeit';

  @override
  String get readMark => 'Gelezen';

  @override
  String get lovedSinceTheStart => 'Het meest geliefd sinds het begin';

  @override
  String lovedIn(String subject) {
    return 'Het meest geliefd in $subject';
  }

  @override
  String get lovedLine =>
      'Wat lezers het vaakst bewaarden en jij nog niet hebt gelezen';

  @override
  String get forYouShelf => 'Voor jou';

  @override
  String get forYouLine => 'Wat je lezen vooropzet';

  @override
  String get exploreOffline =>
      'Je bent offline. Dit is Verkennen zoals het het laatst gelezen is.';

  @override
  String get askYourselfCaps => 'VRAAG JEZELF';

  @override
  String get themeMyths => 'Mythes ontkracht';

  @override
  String get themeMythsLine =>
      'Wat bijna iedereen gelooft, en waarom het niet klopt';

  @override
  String get themeParadoxes => 'Paradoxen';

  @override
  String get themeParadoxesLine =>
      'Twee ware dingen die niet allebei waar zouden mogen zijn';

  @override
  String get themeNumbers => 'Verrassende getallen';

  @override
  String get themeNumbersLine => 'Waar het getal de twist is';

  @override
  String get themePractical => 'Vandaag te gebruiken';

  @override
  String get themePracticalLine =>
      'Iets om te proberen, of om in een gesprek te laten vallen, vóór vanavond';

  @override
  String get themeOrigins => 'Waar het vandaan komt';

  @override
  String get themeOriginsLine =>
      'Het begin van dingen die je elke dag gebruikt';

  @override
  String get themeStories => 'Ware verhalen';

  @override
  String get themeStoriesLine => 'Dingen die echt gebeurd zijn';

  @override
  String get storyHint => 'Tik om verder te gaan · houd vast om te pauzeren';

  @override
  String get storyTapOn => 'Tik om verder te gaan';

  @override
  String get storyPrevious => 'Vorige';

  @override
  String get storyClose => 'Verhaal sluiten';

  @override
  String get storySave => 'Bewaren';

  @override
  String get storySaved => 'Bewaard';

  @override
  String get storyShare => 'Delen';

  @override
  String get storyOpenCard => 'Open de kaart';

  @override
  String get themeDebates => 'Kies een kant';

  @override
  String get themeDebatesLine =>
      'Geen goed antwoord, alleen een beter argument';

  @override
  String get themeWorkItOut => 'Reken het uit';

  @override
  String get themeWorkItOutLine =>
      'Raad het getal voordat de kaart het je vertelt';

  @override
  String get themeSeen => 'Om te zien';

  @override
  String get themeSeenLine => 'Kaarten die hun punt tekenen';

  @override
  String get themeSharpest => 'Voor de scherpsten';

  @override
  String get themeSharpestLine => 'De moeilijkste kaarten die er zijn';

  @override
  String get themePast0 => 'De oudheid';

  @override
  String get themePast1 => 'De 17e tot 19e eeuw';

  @override
  String get themePast2 => 'De vorige eeuw';

  @override
  String get themePastLine => 'Elke keer een ander tijdperk';

  @override
  String get themePlace0 => 'Azië en het Midden-Oosten';

  @override
  String get themePlace1 => 'Amerika';

  @override
  String get themePlace2 => 'Europa';

  @override
  String get themePlaceLine => 'Elke keer een ander deel van de wereld';

  @override
  String get themeTrueOrFalse => 'Waar of niet waar?';

  @override
  String get themeTrueOrFalseLine =>
      'Beslis voor je omdraait. De meesten zitten fout';

  @override
  String get themeReasoning => 'Alleen redeneren';

  @override
  String get themeReasoningLine =>
      'Niets om te onthouden: alleen een manier om het te doordenken';

  @override
  String get themeIdeas => 'Grote ideeën';

  @override
  String get themeIdeasLine => 'De theorie achter dingen, één idee tegelijk';

  @override
  String get themeCurious => 'Gewoon nieuwsgierig';

  @override
  String get themeCuriousLine => 'Voor het plezier van het waarom';

  @override
  String get themeMoving => 'In beweging';

  @override
  String get themeMovingLine => 'Wat nu verandert, en waarom het ertoe doet';

  @override
  String get themeHowItWorks => 'Hoe het echt werkt';

  @override
  String get themeHowItWorksLine =>
      'Het mechanisme achter iets wat je elke dag ziet';

  @override
  String get themePuzzles => 'Puzzels';

  @override
  String get themePuzzlesLine => 'Raadsels voor een pen en een minuut';

  @override
  String get weekRecapCaps => 'DEZE WEEK VROEG JE JEZELF AF';

  @override
  String get weekRecapLine => 'De vragen die je kaarten je meegaven';

  @override
  String weekRecapMore(int n) {
    return 'Nog $n uit je week met Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ zit in de app: download Astute op iPhone of Android om je gratis proefperiode te starten.';

  @override
  String get purchaseComplete => 'Aankoop voltooid.';

  @override
  String get trialStartedTitle => 'Gratis proefperiode gestart.';

  @override
  String get successWelcome =>
      'Welkom bij Astute+. De vijf kaarten van vandaag staan klaar.';

  @override
  String successWelcomeNamed(String name) {
    return 'Welkom bij Astute+, $name. De vijf kaarten van vandaag staan klaar.';
  }

  @override
  String get successWelcomeTomorrow =>
      'Welkom bij Astute+. De vijf van morgen zijn helemaal van jou.';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return 'Welkom bij Astute+, $name. De vijf van morgen zijn helemaal van jou.';
  }

  @override
  String get successFiveCards => '5 kaarten per dag';

  @override
  String get successArchive => 'Volledig archief';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Gratis tot $date, daarna $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Verlengt op $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Bon';

  @override
  String get letsStart => 'Aan de slag';

  @override
  String successFootFirstCharge(String date) {
    return 'Eerste betaling op $date · altijd opzegbaar';
  }

  @override
  String successFootRenews(String date) {
    return 'Verlengt op $date · altijd opzegbaar';
  }

  @override
  String get tryToday => 'PROBEER HET VANDAAG';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'of';

  @override
  String get nextStep => 'Volgende stap';

  @override
  String get showAllSteps => 'Alles tonen';

  @override
  String get revealSeePicture => 'Bekijk de tekening';

  @override
  String get revealPlayScene => 'Probeer het zelf';

  @override
  String get revealBackToAnswer => 'Terug naar het antwoord';

  @override
  String get revealShowWorking => 'Toon de uitwerking';

  @override
  String get sceneLockIn => 'VASTLEGGEN';

  @override
  String get sceneYou => 'JIJ';

  @override
  String get sceneTruth => 'ECHT';

  @override
  String get sceneTryAgain => 'Opnieuw';

  @override
  String get sceneDrawHint => 'Teken je gok met je vinger';

  @override
  String get sceneHoldHint => 'Ingedrukt houden';

  @override
  String get sceneSwipeHint => 'Veeg of tik';

  @override
  String get sceneTapToPick => 'Tik je keuze';

  @override
  String get sceneShowMe => 'Laat zien';

  @override
  String get sceneYourGuess => 'Jouw gok';

  @override
  String sceneNOfM(int n, int m) {
    return '$n van $m';
  }

  @override
  String get reportProblem => 'Een probleem melden';

  @override
  String get reportedThanks => 'Gemeld. Bedankt.';

  @override
  String get reportTitle => 'Wat klopt er niet aan deze kaart?';

  @override
  String get reportLead =>
      'We controleren elke melding aan de hand van de bronnen en verbeteren de kaart.';

  @override
  String get reportFact => 'Een feit klopt niet';

  @override
  String get reportAnswer => 'Het als goed gemarkeerde antwoord is fout';

  @override
  String get reportSource => 'De bron onderbouwt het niet';

  @override
  String get reportUnclear => 'Het is onduidelijk';

  @override
  String get reportTypo => 'Een typfout of een kapotte regel';

  @override
  String get reportOther => 'Iets anders';

  @override
  String get reportNoteHint =>
      'Alles wat ons helpt het te controleren (optioneel)';

  @override
  String get reportSend => 'Versturen';

  @override
  String get reportSentToast => 'Bedankt. We kijken ernaar.';

  @override
  String get journeyPointsOff => 'punten ernaast';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n antwoorden met hoe zeker, en het wordt gemeten.',
      one: 'Nog één antwoord met hoe zeker, en het wordt gemeten.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Je score';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'punten',
      one: 'punt',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n in 4 weken';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Deze week heb je tot nu toe $n punten verdiend.',
      one: 'Deze week heb je tot nu toe 1 punt verdiend.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In de week van $date verdiende je $n punten.',
      one: 'In de week van $date verdiende je 1 punt.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten',
      one: '1 kaart',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Je score aan het eind van elke week sinds $date. Tik op een punt om die week te zien.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Niveau $n van $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\ntot $rung';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten',
      one: '1 kaart',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n antwoorden',
      one: '1 antwoord',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n antwoorden met hoe zeker',
      one: '1 antwoord met hoe zeker',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten vastgehouden',
      one: '1 kaart vastgehouden',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n punten',
      one: '1 punt',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Waarde';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n boeken',
      one: '1 boek',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'of $h u documentaires';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'nog $n tot het eerste boek',
      one: 'nog 1 tot het eerste boek',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Op rij';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Record $best · $active van $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n van $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'vakken · gestippeld: $month';
  }

  @override
  String get journeySubjects => 'vakken';

  @override
  String get journeyHowHard => 'Hoe moeilijk';

  @override
  String get journeyOfThree => 'van 3';

  @override
  String get journeyHardNow => 'De kaarten die je opent.';

  @override
  String journeyHardThen(String v, String month) {
    return 'De kaarten die je opent. $v in $month';
  }

  @override
  String get journeyReadingTime => 'Leestijd';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h u $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m min';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now min per week, was $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min deze week';
  }

  @override
  String get journeyTimedFromToday => 'Geteld vanaf vandaag';

  @override
  String journeyPointsOffFrom(int was) {
    return 'punten ernaast, was $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · max. $n';
  }

  @override
  String get journeyRightWhenSure => 'Goed als je zeker bent';

  @override
  String journeyFromIn(String v, String month) {
    return 'Was $v in $month';
  }

  @override
  String get journeySureNone => 'Nog geen antwoord met 80% of meer';

  @override
  String get journeyMovesTitle => 'Trucs die je herkent';

  @override
  String journeyOfN(int n) {
    return 'van $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Nieuwste: $name';
  }

  @override
  String get journeyNoneYet => 'Nog niets';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'kaarten nog bij je',
      one: 'kaart nog bij je',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: 'een dag',
    );
    return '$right van $of na $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weken',
      one: 'een week',
    );
    return '$right van $of na $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: '1 dag',
    );
    return '$active van $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Vooral \'s ochtends';

  @override
  String get journeyMostlyAfternoon => 'Vooral \'s middags';

  @override
  String get journeyMostlyEvening => 'Vooral \'s avonds';

  @override
  String get journeyMostlyNight => 'Vooral \'s nachts';

  @override
  String get journeyInTime => 'Door de tijd';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString jaar';
  }

  @override
  String journeyFromEra(String era) {
    return 'van $era tot nu';
  }

  @override
  String get journeyEraAncient => 'de oudheid';

  @override
  String get journeyEraMedieval => 'de middeleeuwen';

  @override
  String get journeyEraEarlyModern => 'de 16e eeuw';

  @override
  String get journeyEraNineteenth => 'de 19e eeuw';

  @override
  String get journeyEraTwentieth => 'de 20e eeuw';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'nog niets met een datum';

  @override
  String get journeyInPlace => 'Over de wereld';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regio\'s',
      one: '1 regio',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list en de ruimte';
  }

  @override
  String get journeyRegionAmericas => 'Amerika';

  @override
  String get journeyRegionEurope => 'Europa';

  @override
  String get journeyRegionAsia => 'Azië';

  @override
  String get journeyRegionOceania => 'Oceanië';

  @override
  String get journeyRegionAfrica => 'Afrika';

  @override
  String get journeyRegionMiddleEast => 'Midden-Oosten';

  @override
  String get journeyNoPlace => 'nog geen plek';

  @override
  String get journeyTopics => 'Onderwerpen';

  @override
  String journeyMet(int n) {
    return '$n ontdekt';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n daarvan in $subject';
  }

  @override
  String get journeyWords => 'Woorden';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nieuwe',
      one: '1 nieuw',
    );
    return '$_temp0';
  }

  @override
  String get anotherOne => 'Nog een';

  @override
  String answerIs(String said) {
    return 'Antwoord: $said';
  }

  @override
  String get answeredAlready => 'Al beantwoord';

  @override
  String get anyCard => 'Elk onderwerp, elke plank, één kaart';

  @override
  String betN(int n) {
    return '$n inzetten';
  }

  @override
  String get betWord => 'Inzetten';

  @override
  String get biggerLabel => 'Groter';

  @override
  String get biggerYouGotIt => 'Groter · goed';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Na $n dagen',
      one: 'Na een dag',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Na een week';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Na $n weken',
      one: 'Na een week',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Controleer';

  @override
  String closerDone(String said, int right, int steps) {
    return 'Het is $said. Je had er $right van de $steps goed.';
  }

  @override
  String closerNoLess(String v) {
    return 'Nee: het is minder dan $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'Nee: het is meer dan $v.';
  }

  @override
  String get closerStart => 'Drie stappen om het in te sluiten.';

  @override
  String closerYesLess(String v) {
    return 'Goed: het is minder dan $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Goed: het is meer dan $v.';
  }

  @override
  String get didYouKnow => 'Wist je dat?';

  @override
  String get didYouKnowLine =>
      'Draai hem om: nieuw voor je, of wist je het al?';

  @override
  String get dragToSet => 'Sleep om in te stellen';

  @override
  String get dykAgain => 'Opnieuw';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n wist je al',
      one: '1 wist je al',
      zero: 'Geen wist je al',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nieuw voor je',
      one: '1 nieuw voor je',
      zero: 'Niets nieuws vandaag',
    );
    return '$_temp0';
  }

  @override
  String get eraShortAncient => 'Oudheid';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Middeleeuwen';

  @override
  String get eraShortNineteenth => '19e eeuw';

  @override
  String get eraShortRecent => '21e eeuw';

  @override
  String get eraShortTwentieth => '20e eeuw';

  @override
  String get fewCards => 'In een paar kaarten';

  @override
  String get fewCardsLine =>
      'Als één kaart niet genoeg is om het uit te leggen';

  @override
  String get firstLabel => 'Sinds';

  @override
  String get forYouNow => 'Voor jou, nu';

  @override
  String get hardBadge => 'Moeilijk';

  @override
  String hidesIn(String where) {
    return 'Thema: $where';
  }

  @override
  String get howSure => 'Hoe zeker ben ik, en waarom?';

  @override
  String inRange(int pts, String said) {
    return 'Raak: +$pts punten. Het is $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'In je zetten · $n×';
  }

  @override
  String itIs(String said) {
    return 'Het is $said.';
  }

  @override
  String get knewIt => 'Wist ik al';

  @override
  String get less => 'Minder';

  @override
  String get lookFirst => 'Kijk naar de grafiek voor je de kop gelooft.';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Mis: het is $said.';
  }

  @override
  String get modeBigger => 'Wat is groter?';

  @override
  String get modeCloser => 'Steeds dichterbij';

  @override
  String get modePick => 'Kies er een';

  @override
  String get modeRange => 'Zet in op een bereik';

  @override
  String get modeSlide => 'Schuif';

  @override
  String get modeStake => 'Plaats je inzet';

  @override
  String get monthShelfLine =>
      'Elke maand een nieuw onderwerp, voor iedereen hetzelfde';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards kaarten',
      one: '1 kaart',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'Je tijd';

  @override
  String get moodTitle => 'Jouw stemming, jouw minuten';

  @override
  String get moodTone => 'Toon';

  @override
  String get more => 'Meer';

  @override
  String moreOrLess(String v) {
    return 'Meer of minder dan $v?';
  }

  @override
  String get moveComparedToWhat => 'Veel of weinig?';

  @override
  String get moveComparedToWhatLine =>
      '‘30% meer’ zegt niets zolang je niet weet: vergeleken waarmee?';

  @override
  String get askingTitle => 'Uit elk vak een vraag';

  @override
  String askingIn(String subject) {
    return 'Vragen over $subject';
  }

  @override
  String get askingLine =>
      'Voor iedereen hetzelfde. Eerst antwoorden, dan het waarom';

  @override
  String get moveSampling => 'Wie ontbreekt er in de data?';

  @override
  String get moveSamplingLine =>
      'Elke statistiek telt sommige mensen en mist andere. Wie er ontbreekt, kan het antwoord omdraaien';

  @override
  String nOfM(int at, int of) {
    return '$at van $of';
  }

  @override
  String get newMove => 'Nieuw voor je';

  @override
  String get newToMe => 'Nieuw voor mij';

  @override
  String get notEnoughPoints => 'Niet genoeg punten';

  @override
  String get notSureLine => 'Eén kaart van ergens in Astute';

  @override
  String get notSureTitle => 'Weet je niet waar je moet beginnen?';

  @override
  String get openWord => 'Openen';

  @override
  String get pickOneFirst => 'Kies er eerst een';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pt';
  }

  @override
  String get rightLastTime => 'Vorige keer goed';

  @override
  String get sayFalse => 'Niet waar';

  @override
  String get sayTrue => 'Waar';

  @override
  String get seriesAnchors => 'Eerste indrukken';

  @override
  String get seriesGrowth => 'Getallen die op hol slaan';

  @override
  String seriesMeta(int n, int m) {
    return '$n kaarten · ongeveer $m min';
  }

  @override
  String get seriesOdds => 'Kansen die liegen';

  @override
  String get seriesRetold => 'Geschiedenis, opnieuw verteld';

  @override
  String seriesStrand(String name) {
    return '$name, in een paar kaarten';
  }

  @override
  String get seriesStudies => 'Waarom onderzoek misleidt';

  @override
  String showAllN(int n) {
    return 'Alle $n tonen';
  }

  @override
  String get showFewer => 'Minder tonen';

  @override
  String get sixtyAgain => 'Nog een keer';

  @override
  String sixtyIn(int s) {
    return 'in $s seconden';
  }

  @override
  String get sixtyLine => 'Acht keer waar of niet waar. Ga op je gevoel af';

  @override
  String get sixtyPerfect => 'Alle acht goed.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tot nu toe $n goed',
      one: 'Tot nu toe 1 goed',
      zero: 'Nog geen goed',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'seconden voor acht\nkeer waar of niet waar';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Start';

  @override
  String get sixtyTimeUp => 'voordat de tijd om was';

  @override
  String get sixtyTitle => 'Zestig seconden';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Je zat er $n punten naast.',
      one: 'Je zat er 1 punt naast.',
      zero: 'Precies goed.',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => 'Inzet';

  @override
  String stepOf(int at, int of) {
    return 'Stap $at van $of';
  }

  @override
  String get surpriseMe => 'Verras me';

  @override
  String get tapIfBigger => 'Tik als groter';

  @override
  String get tapToTurn => 'Tik om om te draaien';

  @override
  String get tfRight => 'Goed. Open hem voor het waarom.';

  @override
  String tfWrong(String side) {
    return 'Het is $side. Open hem voor het waarom.';
  }

  @override
  String theAnswer(String said) {
    return 'Het antwoord: $said.';
  }

  @override
  String leanHint(String or) {
    return 'Schuif het ‘$or’ naar waar jij staat';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'een beetje',
      '2': 'alles afwegend',
      '3': 'beslist',
      'other': 'helemaal',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Je koos $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Open hem voor de andere kant.';
  }

  @override
  String get spotTitle => 'Welke is niet waar?';

  @override
  String get spotLine => 'Vier beweringen. Drie zijn waar, één is niet waar.';

  @override
  String get spotPrompt => 'Tik op de bewering die volgens jou niet klopt';

  @override
  String get spotConfirm => 'Deze is niet waar';

  @override
  String get spotFound => 'Gevonden. De andere drie zijn waar.';

  @override
  String get spotMissed =>
      'Niet deze: die is waar. De onware is doorgestreept.';

  @override
  String get spotWhy => 'Tik op een ervan om te lezen waarom';

  @override
  String get spotYours => 'Jouw keuze';

  @override
  String get todayLabel => 'Vandaag';

  @override
  String get toneCurious => 'Nieuwsgierig';

  @override
  String get toneLight => 'Licht';

  @override
  String get toneSerious => 'Serieus';

  @override
  String get toneTough => 'Pittig';

  @override
  String get unmaskBack => 'Toon zoals gepubliceerd';

  @override
  String get unmaskFlipped => 'Draai hem goed om';

  @override
  String get unmaskLine => 'Dezelfde getallen, een ander beeld';

  @override
  String get unmaskStretched => 'Gebruik een eerlijke schaal';

  @override
  String get unmaskTitle => 'Ontmasker de grafiek';

  @override
  String get unmaskTotals => 'Maak de vergelijking eerlijk';

  @override
  String get unmaskTruncated => 'Laat de as bij nul beginnen';

  @override
  String get unmaskWindow => 'Toon de hele reeks';

  @override
  String get unmaskMisleadTitle => 'Grafieken die misleiden';

  @override
  String get unmaskMisleadLine =>
      'De cijfers kloppen. De truc zit in de tekening.';

  @override
  String get unmaskAsk => 'Deze grafiek misleidt. Zie je hoe?';

  @override
  String get unmaskShowTrick => 'Toon de truc';

  @override
  String get unmaskHideTrick => 'Verberg de truc';

  @override
  String get unmaskOriginal => 'Origineel';

  @override
  String get unmaskCorrected => 'Gecorrigeerd';

  @override
  String unmaskTrickTruncated(String from) {
    return 'De as begint bij $from, niet bij nul.';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return 'De as loopt maar van $low tot $high, dus een kleine verandering lijkt enorm.';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return 'De as loopt van $low tot $high, dus een echte verandering lijkt vlak.';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return 'Je ziet alleen $shown, maar de cijfers beslaan $all.';
  }

  @override
  String get unmaskTrickTotals =>
      'Hij vergelijkt kale totalen, geen eerlijke maat.';

  @override
  String get unmaskTrickFlippedRise =>
      'De as staat op zijn kop, dus een stijging lijkt een daling.';

  @override
  String get unmaskTrickFlippedFall =>
      'De as staat op zijn kop, dus een daling lijkt een stijging.';

  @override
  String get whatIfTrue => 'Wat als het waar is?';

  @override
  String get whatIfTrueLine => 'Kaarten die blijven werken nadat je ze sluit';

  @override
  String get whatYouBelieve => 'Wat je gelooft';

  @override
  String get wrongLastTime => 'Vorige keer fout';

  @override
  String youLose(int n) {
    return 'Je verliest $n.';
  }

  @override
  String youWin(int n) {
    return 'Je wint $n.';
  }

  @override
  String get yourPick => 'Jouw keuze';

  @override
  String placeNearYou(String place) {
    return 'Bij jou in de buurt · $place';
  }

  @override
  String placeYourRegion(String place) {
    return 'Jouw regio · $place';
  }

  @override
  String placeYourCountry(String place) {
    return 'Jouw land · $place';
  }

  @override
  String get sundayOneMore => 'Zondag: één extra, voor jou gekozen';

  @override
  String get whereYouLive => 'Waar je woont';

  @override
  String get whereYouLiveLine => 'Eerst je stad, dan je regio, dan je land';

  @override
  String get whereYouLiveAsk =>
      'Kaarten over je stad, je regio en je land: hooguit één per dag, en deze plank. Alleen de stad wordt bewaard, nooit waar je precies bent.';

  @override
  String get whereYouLiveSwitchOn => 'Aanzetten';

  @override
  String get gateUpdateTitle => 'Werk Astute bij';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'De nieuwe staat klaar in de App Store',
      'google': 'De nieuwe staat klaar in Google Play',
      'other': 'De nieuwe staat klaar in je appwinkel',
    });
    return 'Met deze versie kun je niet verder. $_temp0, met je kaarten en je reeks precies zoals je ze achterliet.';
  }

  @override
  String get gateUpdateButton => 'Bijwerken';

  @override
  String get gateSoftTitle => 'Er is een nieuwe versie van Astute';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Ze staat klaar in de App Store.',
      'google': 'Ze staat klaar in Google Play.',
      'other': 'Ze staat klaar in je appwinkel.',
    });
    return '$_temp0 Bijwerken duurt maar even, en je kaarten en je reeks blijven zoals ze zijn.';
  }

  @override
  String get gateSoftLater => 'Later';

  @override
  String get gatePauseTitle => 'Astute neemt even pauze';

  @override
  String get gatePauseLine =>
      'We zetten achter de schermen iets recht. Alles wat je hebt gedaan, is veilig. Probeer het zo nog eens.';

  @override
  String get gatePauseTrying => 'Opnieuw proberen…';

  @override
  String get gatePauseStill =>
      'Nog steeds pauze. Probeer het over een paar minuten nog eens.';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return '$toDo om te doen, $toRead om te lezen';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return '$toDo om te doen · $toRead om te lezen';
  }

  @override
  String get purposeFilterToRead => 'Lezen';

  @override
  String get purposeFilterToDo => 'Doen';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': 'Waar of niet waar',
      'pick': 'Kies er een',
      'typeNumber': 'Typ een getal',
      'bet': 'Gok het getal',
      'side': 'Kies een kant',
      'youFirst': 'Jij eerst',
      'moveIt': 'Schuif en kijk',
      'whatNext': 'Wat gebeurt er dan?',
      'spotTrick': 'Vind de truc',
      'drawIt': 'Teken het',
      'sortThem': 'Sorteer ze',
      'putInOrder': 'Zet ze op volgorde',
      'holdIt': 'Houd vast',
      'growSample': 'Laat de steekproef groeien',
      'askWhy': 'Vraag waarom',
      'sayPlainly': 'Zeg het simpel',
      'pairUp': 'Koppel ze',
      'followClues': 'Volg de aanwijzingen',
      'look': 'Kijk gewoon',
      'listen': 'Luister',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return 'Lezen · $n min';
  }

  @override
  String get purposeCommitNote =>
      'Antwoord hier en open dan de kaart om te zien of je gelijk had. Een gok waar je je aan vastlegt, blijft langer hangen.';

  @override
  String get purposeCommitTitle => 'Eerst antwoorden';

  @override
  String get purposeCommitLine => 'Zeg wat je denkt en open dan de kaart';

  @override
  String get purposeInYourHeadLine =>
      'Een getal om uit je hoofd uit te rekenen';

  @override
  String get purposeInYourHead => 'Uit je hoofd';

  @override
  String get purposeMoveKicker => 'Een zet';

  @override
  String purposeMoveNew(int points) {
    return 'Nieuw · +$points als je hem beheerst';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Basisfrequenties',
      'survivorship': 'Overlevingsbias',
      'regression': 'Terug naar het gemiddelde',
      'confirmation': 'Bevestiging',
      'anchoring': 'Ankeren',
      'sampling': 'Steekproef',
      'confounding': 'Verstorende factor',
      'counterfactual': 'Vergeleken met wat',
      'multipleComparisons': 'Veel pogingen',
      'availability': 'Beschikbaarheid',
      'sunkCost': 'Verzonken kosten',
      'conjunction': 'Conjunctie',
      'conditional': 'Voorwaardelijke kans',
      'independence': 'Onafhankelijkheid',
      'coincidence': 'Toeval',
      'exponential': 'Exponentiële groei',
      'reflection': 'Het snelle antwoord',
      'simpson': 'Totalen',
      'estimation': 'Schatten',
      'computation': 'Uitrekenen',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Hoe nauwkeurig een test is, zegt niet hoe waarschijnlijk het bij jou is',
      'survivorship': 'De data die je hebt, zijn de data die het overleefden',
      'regression': 'Uitschieters keren vanzelf terug naar het gemiddelde',
      'confirmation': 'Een ja zoeken is geen test',
      'anchoring': 'Het eerste getal dat valt, verschuift elk getal daarna',
      'sampling': 'Wie in de steekproef belandde, bepaalt wat die kan zeggen',
      'confounding': 'Misschien veroorzaakt iets anders allebei',
      'counterfactual': 'Een verandering zegt niets zonder controlegroep',
      'multipleComparisons': 'Test genoeg dingen en er slaagt er een',
      'availability': 'Makkelijk voor te stellen is niet hetzelfde als vaak',
      'sunkCost':
          'Uitgegeven is uitgegeven; alleen over de rest valt te beslissen',
      'conjunction':
          'Details maken een verhaal geloofwaardiger en minder waarschijnlijk',
      'conditional': 'Wat je verteld is, verandert de kansen',
      'independence': 'Toeval heeft geen geheugen',
      'coincidence': 'Zeldzaam wordt gewoon als er veel pogingen zijn',
      'exponential': 'Niemand heeft gevoel voor verdubbelen',
      'reflection':
          'Het antwoord dat het eerst komt, is het antwoord om te controleren',
      'simpson': 'Een geheel kan overhellen waar geen enkel deel overhelt',
      'estimation':
          'Hak het onbeantwoordbare op in dingen die je kunt schatten',
      'computation': 'Een probleem dat je echt kunt afmaken',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Hoe vaak kwam het eigenlijk voor?',
      'survivorship': 'Wat haalde de data nooit?',
      'regression': 'Is het gewoon een uitschieter die terugkeert?',
      'confirmation': 'Wat zou me ongelijk geven?',
      'anchoring': 'Welk getal kwam eerst?',
      'sampling': 'Wie werd er geteld?',
      'confounding': 'Wat kan allebei veroorzaken?',
      'counterfactual': 'Vergeleken met wat?',
      'multipleComparisons': 'Hoeveel dingen zijn er geprobeerd?',
      'availability':
          'Komt het vaak voor, of is het alleen makkelijk voor te stellen?',
      'sunkCost': 'Wat valt er vanaf hier nog te beslissen?',
      'conjunction': 'Maakt elk detail het minder waarschijnlijk?',
      'conditional': 'Wat verandert het dat ik dat weet?',
      'independence': 'Verandert de vorige uitkomst de volgende?',
      'coincidence': 'Hoeveel kansen waren er?',
      'exponential': 'Wat gebeurt er als het nog eens verdubbelt?',
      'reflection': 'Is het eerste antwoord het goede?',
      'simpson': 'Helt elk deel dezelfde kant op?',
      'estimation': 'Wat kan ik onderweg schatten?',
      'computation': 'Kan ik het stap voor stap uitrekenen?',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => 'Een trede hoger';

  @override
  String get purposeStepAboveLine => 'Moeilijker dan wat je meestal leest';

  @override
  String purposeThinTitle(String subject) {
    return 'Het minst gelezen: $subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return '$percent% van $subject gelezen, je laagste';
  }

  @override
  String get purposeOtherSide => 'De andere kant';

  @override
  String get purposeOtherSideLine =>
      'Je koos een kant. Dit is het sterkste argument ertegen';

  @override
  String purposeYouSaid(String side) {
    return 'Jij zei $side';
  }

  @override
  String purposeCaseFor(String side) {
    return 'Wat er voor ‘$side’ pleit';
  }

  @override
  String get purposeMechanism => 'Het mechanisme';

  @override
  String purposeMovingUpdated(String date) {
    return 'Bijgewerkt op $date';
  }

  @override
  String get purposeMovingYears => 'Kan over een paar jaar veranderen';

  @override
  String get purposeMovingMonths => 'Kan dit jaar nog veranderen';

  @override
  String get purposeWhy => 'Ah, dáárom';

  @override
  String get purposeWhyLine => 'Eén mechanisme, uitgelegd tot het klikt';

  @override
  String purposeWhyBand(int n) {
    return 'Het waarom · $n min';
  }

  @override
  String get purposeMe => 'Dat ben ik';

  @override
  String get purposeMeLine => 'Dingen die je doet zonder het te merken';

  @override
  String get purposeMeFooter => 'Markeer de kaarten waarin je jezelf herkent.';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten gemarkeerd met ‘Dat ben ik’.',
      one: 'Eén kaart gemarkeerd met ‘Dat ben ik’.',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => 'Nieuw voor mij, en over mij';

  @override
  String get purposeAboutYouLine => 'Je lichaam, je gezondheid, je kansen';

  @override
  String get purposeHeadline => 'In een kop';

  @override
  String get purposeHeadlineLine =>
      'Onderzoeken en beweringen die beter klinken dan ze zijn';

  @override
  String get purposeTheClaim => 'De bewering';

  @override
  String get purposeNumber => 'In een getal';

  @override
  String get purposeNumberLine =>
      'Kansen en percentages die een tweede blik verdienen';

  @override
  String get purposeOutOfWhat => 'Op hoeveel?';

  @override
  String get purposeOffer => 'In een aanbieding';

  @override
  String get purposeOfferLine => 'Prijzen, deals en wie er echt betaalt';

  @override
  String get purposeArgument => 'In een discussie';

  @override
  String get purposeArgumentLine => 'Waar de redenering uitglijdt';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Eén vraag die de meeste hiervan doorziet',
      '2': 'Twee vragen die de meeste hiervan doorzien',
      '3': 'Drie vragen die de meeste hiervan doorzien',
      '4': 'Vier vragen die de meeste hiervan doorzien',
      '5': 'Vijf vragen die de meeste hiervan doorzien',
      'other': '$n vragen die de meeste hiervan doorzien',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Geld',
      'work': 'Werk en tijd',
      'clock': 'Tijd',
      'body': 'Je lichaam',
      'relationships': 'Relaties',
      'belief': 'Wat je gelooft',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Betaal ik voor wat ik echt gebruik?',
      'work': 'Wat zou morgen makkelijker laten beginnen?',
      'clock': 'Waar gaat mijn tijd echt naartoe?',
      'body': 'Klopt wat ik over mijn lichaam weet nog?',
      'relationships': 'Wat hebben de mensen om me heen echt nodig?',
      'belief': 'Hoe zeker ben ik, en waarom?',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Geld',
      'work': 'Werk',
      'clock': 'Tijd',
      'body': 'Lichaam',
      'relationships': 'Relaties',
      'belief': 'Wat ik geloof',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => 'Waarover wil je betere vragen?';

  @override
  String get purposeLifeFooter =>
      'Kies wat je wilt, en de kaarten erover verschijnen hier.';

  @override
  String get purposeSpotTrick => 'Vind de truc';

  @override
  String get purposeSpotTrickLine => 'Welke vraag zou hem doorzien?';

  @override
  String get purposePlayed => 'Wat je vandaag speelde';

  @override
  String get purposePlayedOff => 'punten ernaast, gemiddeld';

  @override
  String get purposePlayedTricks => 'trucs doorzien';

  @override
  String get purposePlayedAnswered => 'beantwoord op een plank';

  @override
  String get purposePlayedFooter =>
      'Antwoorden op een plank tellen mee in ‘Je reis’, net als die van Vandaag.';

  @override
  String purposeOf(int n, int of) {
    return '$n van $of';
  }

  @override
  String purposeSetRead(int n, int of) {
    return '$n van $of gelezen';
  }

  @override
  String purposeSetDone(int n) {
    return 'Alle $n gelezen. Als de plank terugkomt, komen er nieuwe bij.';
  }

  @override
  String get purposeComplete => 'Compleet';

  @override
  String get purposeStampsFooter =>
      'Elke kaart die je leest, voegt zijn zegel toe.';

  @override
  String get purposeSets => 'Je sets';

  @override
  String get purposeSetsLine =>
      'Lezen telt. Je hoeft niet te antwoorden om een set te vullen.';

  @override
  String get purposeTomorrow => 'Morgen op de planken';

  @override
  String get purposeTomorrowLine =>
      'De planken wisselen elke dag. Deze komen hierna';

  @override
  String get purposeEnd => 'Dit is het einde van Ontdek';

  @override
  String get purposeEndLine => 'Tot morgen';

  @override
  String get betsRangeTitle => 'Zet in op een bereik';

  @override
  String get betsRangeLine =>
      'Hoe smaller, hoe meer het oplevert, als je gelijk hebt';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts pt';
  }

  @override
  String get betsBet => 'Inzetten';

  @override
  String betsInRange(int pts, String said) {
    return 'Raak: +$pts punten. Het is $said.';
  }

  @override
  String betsMissedRange(String said) {
    return 'Mis: het is $said.';
  }

  @override
  String get betsYourGuess => 'Jouw schatting';

  @override
  String get betsAnsweredAlready => 'Al beantwoord';

  @override
  String get betsOpenCard => 'Open de kaart';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n punten vandaag',
      one: 'Nog 1 punt vandaag',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => 'Je wedbriefje';

  @override
  String betsSlipToday(String points) {
    return '$points vandaag';
  }

  @override
  String get betsSlipEmpty =>
      'Nog geen weddenschappen. Elke inzet komt hier te staan.';

  @override
  String get betsSlipTipTwice =>
      'Ga smal als je zeker bent: het levert twee keer zoveel op.';

  @override
  String get betsSlipTipThrice =>
      'Ga smal als je zeker bent: het levert drie keer zoveel op.';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: 'Ga smal als je zeker bent: het levert $times keer zoveel op.',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return 'Smalle inzetten raak: $right van de $n.';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return '$right van de $n goed, gemiddeld $pct% zeker.';
  }

  @override
  String get betsRight => 'Goed';

  @override
  String get betsWrong => 'Fout';

  @override
  String betsOneIn(String n) {
    return '1 op $n';
  }

  @override
  String get betsOneInLabel => '1 op';

  @override
  String betsScore(int right, int steps) {
    return '$right van de $steps';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return 'Je had er $right van de $steps goed.';
  }

  @override
  String get betsStakeTitle => 'Plaats je inzet';

  @override
  String betsStakeLine(int points) {
    return '$points punten per dag. Win je, dan verdubbel je je inzet';
  }

  @override
  String get betsStakeLabel => 'Inzet';

  @override
  String betsBetN(int n) {
    return '$n inzetten';
  }

  @override
  String get betsPickFirst => 'Kies er eerst een';

  @override
  String get betsNotEnough => 'Niet genoeg punten';

  @override
  String betsWin(int n) {
    return 'Je wint $n.';
  }

  @override
  String betsLose(int n) {
    return 'Je verliest $n.';
  }

  @override
  String betsYouWereSure(int pct) {
    return 'Je was $pct% zeker.';
  }

  @override
  String get betsFriendTitle => 'Wed met een vriend';

  @override
  String get betsFriendLine =>
      'Stuur een vraag en vergelijk daarna jullie schattingen';

  @override
  String get betsFriendNote =>
      'Jouw schatting blijft op je telefoon. De kaart gaat met het antwoord mee, dus vraag eerst naar die van hen.';

  @override
  String betsFriendNoteSaid(String said) {
    return 'Jij zei $said. De kaart gaat met het antwoord mee, dus vraag eerst naar hun schatting.';
  }

  @override
  String get betsFriendSend => 'Stuur naar een vriend';

  @override
  String get betsFriendCopy => 'Kopieer de vraag';

  @override
  String get betsFriendCopied => 'Vraag gekopieerd';

  @override
  String get betsFriendAsk => 'Wat zeg jij?';

  @override
  String get betsNumberTitle => 'Jouw getal';

  @override
  String get betsNumberLine =>
      'Stel het in, zet het vast, zie hoe ver je ernaast zat';

  @override
  String get betsLock => 'Vast';

  @override
  String get betsSpotOn => 'Precies goed.';

  @override
  String betsCloseEnough(String by) {
    return 'Dichtbij genoeg: $by ernaast.';
  }

  @override
  String betsOffBy(String by) {
    return '$by ernaast.';
  }

  @override
  String get betsYou => 'jij';

  @override
  String get betsAnswer => 'antwoord';

  @override
  String get betsBiggerTitle => 'Wat is groter?';

  @override
  String get betsBiggerLine =>
      'Twee getallen die je kunt uitrekenen. Tik op het grootste';

  @override
  String get betsTapIfBigger => 'Tik als groter';

  @override
  String get betsBiggerGotIt => 'Groter · goed';

  @override
  String get betsBigger => 'Groter';

  @override
  String get betsYourPick => 'Jouw keuze';

  @override
  String get betsOr => 'of';

  @override
  String get betsBiggerFoot =>
      'Elk getal is het antwoord op een kaart. Na je keuze open je met een tik de kaart.';

  @override
  String betsBiggerScore(int right, int n) {
    return '$right van de $n goed.';
  }

  @override
  String get betsCloserTitle => 'Steeds dichterbij';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Twee stappen van meer of minder om het getal in te sluiten',
      '3': 'Drie stappen van meer of minder om het getal in te sluiten',
      '4': 'Vier stappen van meer of minder om het getal in te sluiten',
      '5': 'Vijf stappen van meer of minder om het getal in te sluiten',
      'other': '$steps stappen van meer of minder om het getal in te sluiten',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Twee stappen om het in te sluiten.',
      '3': 'Drie stappen om het in te sluiten.',
      '4': 'Vier stappen om het in te sluiten.',
      '5': 'Vijf stappen om het in te sluiten.',
      'other': '$steps stappen om het in te sluiten.',
    });
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return 'Meer of minder dan $v?';
  }

  @override
  String betsStepOf(int at, int of) {
    return 'Stap $at van $of';
  }

  @override
  String get betsMore => 'Meer';

  @override
  String get betsLess => 'Minder';

  @override
  String betsCloserYesMore(String v) {
    return 'Goed: het is meer dan $v.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Goed: het is minder dan $v.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Fout: het is meer dan $v.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Fout: het is minder dan $v.';
  }

  @override
  String betsCloserExact(String said) {
    return 'Het is precies $said.';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return 'Het is $said. Je had er $right van de $steps goed.';
  }

  @override
  String get betsMagnitudeTitle => 'Ordes van grootte';

  @override
  String get betsMagnitudeLine =>
      'Tien, duizend of een miljoen? Kies de grootte';

  @override
  String get betsMagnitudeRight => 'Juiste orde van grootte.';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ordes van grootte ernaast.',
      one: '1 orde van grootte ernaast.',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => 'De gok van de dag';

  @override
  String get betsDayLine =>
      'Zet je schatting vast en zie hoe ver je ernaast zat';

  @override
  String get betsDayTag => 'Gok van de dag';

  @override
  String get betsDayTagSame => 'Gok van de dag · voor iedereen dezelfde';

  @override
  String get betsLockIn => 'Vastzetten';

  @override
  String betsItIs(String said) {
    return 'Het is $said.';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Je zat er $n procentpunten naast.',
      one: 'Je zat er 1 procentpunt naast.',
      zero: 'Precies goed.',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '‘$text’';
  }

  @override
  String get screensExpertTitle => 'Denk als een expert';

  @override
  String get screensExpertLine =>
      'De vraag die elk van hen altijd stelt, en de kaarten waarbij die telt';

  @override
  String get screensExpertStatistician => 'Statisticus';

  @override
  String get screensExpertStatisticianAs => 'Denk als een statisticus';

  @override
  String get screensExpertStatisticianAsks =>
      'Vergeleken met wat, en van hoeveel?';

  @override
  String get screensExpertEconomist => 'Econoom';

  @override
  String get screensExpertEconomistAs => 'Denk als een econoom';

  @override
  String get screensExpertEconomistAsks =>
      'Wie betaalt, en wat geeft die ervoor op?';

  @override
  String get screensExpertHistorian => 'Historicus';

  @override
  String get screensExpertHistorianAs => 'Denk als een historicus';

  @override
  String get screensExpertHistorianAsks => 'Wat wist men toen?';

  @override
  String get screensExpertDoctor => 'Arts';

  @override
  String get screensExpertDoctorAs => 'Denk als een arts';

  @override
  String get screensExpertDoctorAsks =>
      'Hoe vaak komt het voor, en wat kan het nog meer zijn?';

  @override
  String get screensExpertScientist => 'Wetenschapper';

  @override
  String get screensExpertScientistAs => 'Denk als een wetenschapper';

  @override
  String get screensExpertScientistAsks =>
      'Hoe zouden we weten dat het niet klopt?';

  @override
  String get screensDotsTitle => 'Verbind de stippen';

  @override
  String get screensDotsLine => 'Kies een vak en zie waar het de andere raakt';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: 'Raakt $subjects vakken',
      one: 'Raakt 1 vak',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: 'in $cards kaarten',
      one: 'in 1 kaart',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get screensDotsWhere => 'Waar ze elkaar raken';

  @override
  String get screensDotsWhereLine => 'Eén vraag, twee manieren van kijken';

  @override
  String get screensAskTitle => 'Wat wil je begrijpen?';

  @override
  String get screensAskHint => 'Vraag wat je wilt, of typ een woord';

  @override
  String get screensAskTry => 'Probeer';

  @override
  String get screensAskClear => 'Vraag wissen';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten geven antwoord',
      one: '1 kaart geeft antwoord',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => 'Nog geen kaart hierover';

  @override
  String get screensAskNoneLine =>
      'Bewaar de vraag. Zodra een kaart antwoord geeft, staat die hier, onder de vraag.';

  @override
  String get screensAskKeep => 'Vraag bewaren';

  @override
  String get screensAskKept => 'Bewaard';

  @override
  String get screensAskedTitle => 'Jouw vragen';

  @override
  String get screensAskedLine => 'En de kaarten die antwoord gaven';

  @override
  String get screensAskedAnswered => 'Beantwoord';

  @override
  String get screensAskedWaiting =>
      'Nog geen kaart geeft antwoord. Zodra er een is, staat die hier.';

  @override
  String get screensAskedForget => 'Deze vraag vergeten';

  @override
  String get screensAskedForgotten => 'Vraag vergeten';

  @override
  String get screensWhyTitle => 'Blijf vragen waarom';

  @override
  String get screensWhyLine => 'Elk antwoord roept de volgende vraag op';

  @override
  String get screensWhyAsk => 'Waarom?';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n waaroms diep.',
      one: '1 waarom diep.',
    );
    return '$_temp0 Dieper gaat deze niet.';
  }

  @override
  String get screensWhyAgain => 'Opnieuw beginnen';

  @override
  String get screensWhyHoles => 'Meer konijnenholen';

  @override
  String get screensWhyHolesLine => 'Elk gaat een paar waaroms diep';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n waaroms',
      one: '1 waarom',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => 'Dieper graven';

  @override
  String screensWhySource(String source) {
    return 'Bron: $source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '$at waaroms',
      one: '1 waarom',
    );
    return '$_temp0 van $of';
  }

  @override
  String get screensTimeTitle => 'Door de tijd';

  @override
  String get screensTimeLine =>
      'Eén tijdperk tegelijk, tot dit jaar. Sleep om te reizen';

  @override
  String get screensTimeCaption =>
      'Jaren geleden. Elk streepje is tien keer verder terug.';

  @override
  String get screensTimeNow => 'Nu';

  @override
  String get screensTimeEarlier => 'Verder terug';

  @override
  String get screensTimeLater => 'Dichter bij nu';

  @override
  String get screensEraAncient => 'De oudheid';

  @override
  String get screensEraAncientWhen => 'Vóór 500';

  @override
  String get screensEraMedieval => 'De middeleeuwen';

  @override
  String get screensEraMedievalWhen => '500 tot 1500';

  @override
  String get screensEraEarlyModern => 'De vroegmoderne tijd';

  @override
  String get screensEraEarlyModernWhen => '1500 tot 1800';

  @override
  String get screensEraNineteenth => 'De negentiende eeuw';

  @override
  String get screensEraNineteenthWhen => '1800 tot 1900';

  @override
  String get screensEraTwentieth => 'De vorige eeuw';

  @override
  String get screensEraTwentiethWhen => '1900 tot 2000';

  @override
  String get screensEraRecent => 'Deze eeuw';

  @override
  String get screensEraRecentWhen => 'Sinds 2000';

  @override
  String get screensMindTitle => 'Verander van mening';

  @override
  String get screensMindLine =>
      'Zeg waar je staat voor je leest, en daarna nog eens';

  @override
  String get screensMindClaim => 'Bewering';

  @override
  String get screensMindBefore => 'Voor je leest';

  @override
  String get screensMindTap => 'Tik waar je staat';

  @override
  String get screensMindKnow => 'Wat we weten';

  @override
  String get screensMindNow => 'En nu?';

  @override
  String get screensMindAgain => 'Tik nog eens';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': 'Helemaal oneens',
      '1': 'Oneens',
      '2': 'Weet niet',
      '3': 'Eens',
      'other': 'Helemaal eens',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Je schoof $n stappen op naar het bewijs.',
      one: 'Je schoof 1 stap op naar het bewijs.',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame =>
      'Zelfde als eerst. Eén kaart is maar één kaart.';

  @override
  String get screensMindAlready =>
      'Je stond al aan de kant van het bewijs voor je het las.';

  @override
  String get screensMindAway =>
      'Je schoof weg van het bewijs. Lees de kaart nog eens.';

  @override
  String get screensMindFirst =>
      'Zeg eerst waar je staat. Eén tik, voor je leest.';

  @override
  String screensMindChanged(int changed, int total) {
    return 'Je veranderde van mening bij $changed van de $total.';
  }

  @override
  String get screensMindFoot =>
      'Een veranderde mening is een kaart die haar werk deed.';

  @override
  String get screensSayTitle => 'Zeg het vanavond';

  @override
  String get screensSayLine =>
      'Eén zin voor aan tafel. Tik zodra je hem gezegd hebt';

  @override
  String get screensSayTonight => 'De zin van vanavond';

  @override
  String get screensSaySaid => 'Ik heb het gezegd';

  @override
  String get screensSayDone => 'Gezegd';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Je zei deze week $n zinnen.',
      one: 'Je zei deze week 1 zin.',
      zero: 'Deze week nog niets gezegd.',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts =>
      'Elke zin die je zegt, telt ook mee voor de Top van de week.';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => 'Editie van vandaag';

  @override
  String get screensFrontSame => 'Voor iedereen hetzelfde';

  @override
  String get screensFrontLead => 'Opening';

  @override
  String get screensFrontNumbers => 'In cijfers';

  @override
  String get screensFrontCorrections => 'Rectificaties';

  @override
  String get screensFrontPuzzle => 'De puzzel van de dag';

  @override
  String get screensFrontEnd => 'Dat was de editie van vandaag';

  @override
  String get screensFrontTomorrow => 'Die van morgen verschijnt \'s ochtends';

  @override
  String exploreDayRead(int read, int of) {
    return 'Vandaag: $read van $of gelezen';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'nog $n',
      one: 'nog 1',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => 'alles gelezen';

  @override
  String get exploreDayOpen => 'Naar de kaarten van vandaag';

  @override
  String get exploreGameNone =>
      'Hier valt nu niets te spelen. Kom morgen terug.';

  @override
  String get challengesTitle => 'Uitdagingen';

  @override
  String get challengesLine =>
      'Korte oefeningen in oordeel en schatting, elk een paar minuten.';

  @override
  String challengesPage(int n, int of) {
    return 'Pagina $n van $of';
  }

  @override
  String get gamePlay => 'Beginnen';

  @override
  String get sixtyRules =>
      'Acht beweringen, waar of niet waar, in één minuut. Het meet hoe goed je onder tijdsdruk oordeelt, en zo beoordelen we het meeste wat we lezen.';

  @override
  String get sixtyReview => 'De acht beweringen';

  @override
  String get gameRight => 'Goed';

  @override
  String get gameWrong => 'Fout';

  @override
  String get gameUnanswered => 'Geen antwoord';

  @override
  String get gameNext => 'Volgende uitdaging';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · Zestig seconden · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$n van $of goed · $s s';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: 'Nog $s seconden',
      one: 'Nog 1 seconde',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => 'De kaarten';

  @override
  String get gameTomorrow => 'Morgen een nieuwe ronde';

  @override
  String get gameContinue => 'Verder';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return '$n van $of goed';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten vandaag',
      one: '1 kaart vandaag',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => 'Allemaal goed.';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n punten',
      one: '1 punt',
    );
    return '$_temp0';
  }

  @override
  String get gameSeeResult => 'Bekijk hoe het ging';

  @override
  String get gameNextCard => 'Volgende';

  @override
  String get spotOnce => 'Eén keuze per dag';

  @override
  String get spotGotIt => 'Je hebt de onware gevonden.';

  @override
  String get spotMissedIt => 'Die niet: die is waar.';

  @override
  String get tfRules =>
      'Beweringen waar de meeste mensen naast zitten. Zeg waar of niet waar en lees dan waarom. Het meet je oordeel: onderscheiden wat klopt van wat alleen voor de hand lijkt te liggen.';

  @override
  String get inOrderTitle => 'Op volgorde';

  @override
  String get inOrderRules =>
      'Vier momenten uit de kaarten, zonder jaartal, te zetten in de volgorde waarin ze gebeurden. Het meet je gevoel voor chronologie, de eerste toets van elke verklaring: een oorzaak komt vóór haar gevolg.';

  @override
  String get inOrderFirst => 'Tik op het moment dat het eerst kwam.';

  @override
  String get inOrderNext => 'Nu het moment dat daarna kwam.';

  @override
  String get inOrderReady => 'Alles geplaatst.';

  @override
  String get inOrderCheck => 'Volgorde nakijken';

  @override
  String inOrderPlaced(int n) {
    return 'Op plek $n';
  }

  @override
  String inOrderYours(int n) {
    return 'Jouw plek: $n';
  }

  @override
  String get inOrderPerfect => 'Alles op de goede plek.';

  @override
  String get timeGap => 'een ontbrekend jaartal';

  @override
  String get whatYearTitle => 'Welk jaar?';

  @override
  String get whatYearRules =>
      'Drie momenten, zonder jaartal. Stel van elk het jaar in: hoe dichterbij, hoe meer punten, tot tien. Het meet je gevoel voor wanneer dingen gebeurden.';

  @override
  String whatYearPoints(int n, int of) {
    return '$n van $of punten';
  }

  @override
  String get whatYearPerfect => 'Elk jaartal precies goed.';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In totaal $n jaar ernaast.',
      one: 'In totaal 1 jaar ernaast.',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Jij zei $guess · $points punten',
      one: 'Jij zei $guess · 1 punt',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jaar ernaast',
      one: '1 jaar ernaast',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jaar eerder',
      one: '1 jaar eerder',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jaar later',
      one: '1 jaar later',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => 'Jaar';

  @override
  String get beforeAfterTitle => 'Ervoor of erna?';

  @override
  String get beforeAfterRules =>
      'Zes momenten, na elkaar. Zeg of elk vóór of na het moment erboven gebeurde. Het meet je gevoel voor volgorde.';

  @override
  String get beforeAfterBefore => 'Ervoor';

  @override
  String get beforeAfterAfter => 'Erna';

  @override
  String beforeAfterAsk(String year) {
    return 'Voor of na $year?';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return 'Jij zei: vóór $year';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return 'Jij zei: na $year';
  }

  @override
  String get beforeAfterStart => 'Hier begon de reeks';

  @override
  String get beforeAfterPerfect => 'Geen enkele ernaast.';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n paren vandaag',
      one: '1 paar vandaag',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => 'Intuïtie';

  @override
  String get spotSkill => 'Onderscheid';

  @override
  String get tfSkill => 'Oordeel';

  @override
  String get biggerSkill => 'Verhouding';

  @override
  String get closerSkill => 'Schatting';

  @override
  String get magnitudeSkill => 'Schaal';

  @override
  String get rangeSkill => 'Kalibratie';

  @override
  String get stakeSkill => 'Overtuiging';

  @override
  String get numberSkill => 'Precisie';

  @override
  String get inOrderSkill => 'Chronologie';

  @override
  String get whatYearSkill => 'Datering';

  @override
  String get beforeAfterSkill => 'Volgorde';

  @override
  String get sixtyAsks => 'Acht beweringen tegen de klok.';

  @override
  String get spotAsks => 'Vier beweringen, één is niet waar.';

  @override
  String get tfAsks => 'Beweringen waarover bijna iedereen zich vergist.';

  @override
  String get biggerAsks => 'Twee getallen. Welk is groter?';

  @override
  String get closerAsks => 'Stap voor stap naar een getal toe.';

  @override
  String get magnitudeAsks => 'Vind de juiste macht van tien.';

  @override
  String get rangeAsks => 'Een bereik, net breed genoeg.';

  @override
  String get stakeAsks => 'Zet punten in naar je zekerheid.';

  @override
  String get numberAsks => 'Kies één enkel getal.';

  @override
  String get inOrderAsks => 'Vier momenten, het vroegste eerst.';

  @override
  String get whatYearAsks => 'Plaats een moment in zijn jaar.';

  @override
  String get beforeAfterAsks => 'Elk moment tegenover het vorige.';

  @override
  String get challengeBest => 'Record';

  @override
  String get challengeToday => 'Vandaag';

  @override
  String get challengeAccuracy => 'Trefzekerheid';

  @override
  String get challengeTime => 'Tijd';

  @override
  String challengeSeconds(int s) {
    return '$s s';
  }

  @override
  String get challengePersonalBest => 'Persoonlijk record';

  @override
  String challengeAboveChance(int n, int of) {
    return 'Beter dan toeval: gokken levert gemiddeld $n van $of op.';
  }

  @override
  String challengeAtChance(int n, int of) {
    return 'Gelijk aan toeval: gokken levert gemiddeld $n van $of op.';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return 'Slechter dan toeval: gokken levert gemiddeld $n van $of op.';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'De tijd was op met $n beweringen onbeantwoord.',
      one: 'De tijd was op met één bewering onbeantwoord.',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => 'Nog een ronde';

  @override
  String get spotRules =>
      'Vier beweringen: drie zijn waar en één is niet waar. Vind de onware. Het meet hoe goed je een gefundeerde bewering onderscheidt van een die alleen maar goed klinkt.';

  @override
  String get spotAsk => 'Tik op de bewering die volgens jou niet waar is.';

  @override
  String get biggerRules =>
      'Twee getallen, elk het antwoord op de vraag van een kaart. Tik op de kaart waarvan je denkt dat het antwoord groter is. Het meet je gevoel voor verhoudingen.';

  @override
  String get biggerAsk => 'Tik op de kaart met het grotere antwoord.';

  @override
  String biggerRight(String big, String small) {
    return 'Goed: $big is meer dan $small.';
  }

  @override
  String biggerWrong(String big, String small) {
    return 'Fout: $big is meer dan $small.';
  }

  @override
  String get closerRules =>
      'Kom stap voor stap dichter bij een percentage: zeg elke keer of het boven of onder het midden ligt van wat overblijft. Het meet je schattingsvermogen.';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    return 'Het is $said: $right van de $steps stappen goed.';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    return 'Het is precies $said: $right van de $steps stappen goed.';
  }

  @override
  String closerStepsRight(int right, int steps) {
    return '$right van de $steps stappen goed.';
  }

  @override
  String get magnitudeRules =>
      'Tien, duizend of een miljoen? Kies de macht van tien die het dichtst bij het antwoord ligt. Het meet je gevoel voor schaal, dat meer telt dan de precieze cijfers.';

  @override
  String get rangeRules =>
      'Zet je schatting en dan een bereik eromheen: hoe smaller, hoe meer het oplevert als het antwoord erin valt. Het meet je kalibratie: weten hoeveel je weet.';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · levert $pts';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'Het is $said: binnen je bereik, +$pts punten.',
      one: 'Het is $said: binnen je bereik, +1 punt.',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return 'Het is $said: buiten je bereik.';
  }

  @override
  String stakeRules(int points) {
    return 'Kies een antwoord en zet er punten op in, van $points per dag: goed, dan verdubbelt je inzet; fout, dan ben je hem kwijt. Het meet je overtuiging: inzetten op wat je weet, en alleen daarop.';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Goed: je wint $n punten.',
      one: 'Goed: je wint 1 punt.',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Fout: je verliest $n punten.',
      one: 'Fout: je verliest 1 punt.',
    );
    return '$_temp0';
  }

  @override
  String get numberRules =>
      'Stel met de knoppen één getal in en zet het vast. Het meet je precisie: hoe dichtbij je komt als je je op één getal moet vastleggen.';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Goed: het is waar.',
      'other': 'Goed: het is niet waar.',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Fout: het is waar.',
      'other': 'Fout: het is niet waar.',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$n van de $of op de goede plek.';
  }

  @override
  String get whatYearYours => 'Jouw jaar';

  @override
  String get whatYearExactly => 'Precies het jaar';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Goed: het was $year, vóór $above.',
      'other': 'Goed: het was $year, na $above.',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Fout: het was $year, vóór $above.',
      'other': 'Fout: het was $year, na $above.',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => 'Antwoord';

  @override
  String get challengeYouSaid => 'Jij zei';

  @override
  String get challengePoints => 'Punten';

  @override
  String get challengeThisRound => 'Deze ronde';

  @override
  String get challengeLeftToday => 'Over vandaag';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject, niveau $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return 'Omdat je ‘$question’ bewaarde';
  }

  @override
  String get todaySeeAgain => 'Opnieuw zien';

  @override
  String get todaySeeAgainHint =>
      'De kaarten van vandaag opnieuw, op volle grootte, vanaf de eerste';

  @override
  String get yourFiveFromToday => 'Jouw vijf van vandaag';

  @override
  String get tuneTitle => 'Stel je mix af';

  @override
  String get tuneEntryLine => 'Hoeveel van elk vak, en welke delen ervan';

  @override
  String get tuneLearned =>
      'Al bijgesteld door de kaarten die je leuk vond en weggooide. Schuif om het te veranderen.';

  @override
  String get tuneFresh => 'Schuif een vak om er meer of minder van te zien.';

  @override
  String get tuneHowMuch => 'Hoeveel van elk';

  @override
  String get tuneInsideLine =>
      'De delen die je het leukst vond staan vooraan. Tik er een aan om hem over te slaan, houd hem vast om erin te kijken.';

  @override
  String get tuneSave => 'Opslaan';

  @override
  String get tuneHoldHint =>
      'Houd een genre vast om de kleinere onderwerpen erin te openen';

  @override
  String get shareDayTitle => 'Deel je dag';

  @override
  String get shareDayRead => 'Vijf kaarten, gelezen';

  @override
  String get shareDayTurn => 'Vijf kaarten per dag. Jouw beurt.';

  @override
  String shareDaySure(int n) {
    return '$n% zeker';
  }

  @override
  String get shareDayHeadline => 'De vijf van vandaag';

  @override
  String get shareFormatCover => 'Omslag';

  @override
  String get shareFormatList => 'Lijst';

  @override
  String get shareFormatStory => 'Verhaal';

  @override
  String crowdGotRight(int n) {
    return '$n% van de lezers had het goed';
  }

  @override
  String crowdGotWrong(int n) {
    return 'Ook $n% van de lezers had het fout';
  }

  @override
  String get challengeFriend => 'Daag een vriend uit';

  @override
  String get challengeLine => 'Weet jij deze?';

  @override
  String pathFree(int n) {
    return '$n gratis';
  }

  @override
  String pathMoreTitle(int n) {
    return 'Nog $n in dit pad.';
  }

  @override
  String get pathMoreLine =>
      'Elk pad helemaal, van de makkelijkste kaart tot de moeilijkste, en elke week een nieuwe rij.';

  @override
  String get pathMoreGo => 'Lees het hele pad';

  @override
  String get paywallPathsTitle => 'Elk pad, alle tien.';

  @override
  String get paywallPathsMark => 'alle tien.';

  @override
  String get paywallPathsLine =>
      'Tien kaarten over één thema, van de makkelijkste tot de moeilijkste. Elke week nieuwe paden, en je vijf van de dag op jouw niveau.';

  @override
  String get widgetAskTitle => 'De eerste kaart van morgen, op je beginscherm.';

  @override
  String get widgetAskLine =>
      'Elke ochtend een nieuwe kaart zonder de app te openen, met je reeks ernaast.';

  @override
  String get widgetAskStepHold =>
      'Houd een lege plek op je beginscherm ingedrukt.';

  @override
  String get widgetAskStepAppleAdd =>
      'Tik op Wijzig en dan op Voeg widget toe.';

  @override
  String get widgetAskStepApplePick =>
      'Zoek Astute, kies een formaat en tik op Voeg widget toe.';

  @override
  String get widgetAskStepAndroidAdd => 'Tik op Widgets.';

  @override
  String get widgetAskStepAndroidPick =>
      'Zoek Astute, houd een widget vast en sleep hem naar zijn plek.';

  @override
  String get widgetAskLockScreen =>
      'Ook op het toegangsscherm: houd het ingedrukt en tik op Pas aan.';

  @override
  String get widgetAskPin => 'Zet op beginscherm';

  @override
  String get widgetAskGotIt => 'Begrepen';

  @override
  String get widgetAskNotNow => 'Niet nu';

  @override
  String pathCardOf(int n, int total) {
    return 'Kaart $n van $total';
  }

  @override
  String get pathDoorNext => 'Volgende in het pad';

  @override
  String get shareSendCard => 'Stuur de kaart';

  @override
  String get shareAsImage => 'Als afbeelding';

  @override
  String get shareCopyLink => 'Link kopiëren';

  @override
  String get shareAnswerNote =>
      'Je vriend ziet eerst de vraag. Het antwoord is één tik verder, op de pagina van de kaart.';

  @override
  String get shareWhichSide => 'Aan welke kant sta jij?';

  @override
  String get rereadRight => 'De eerste keer had je het goed.';

  @override
  String get rereadWrong => 'De eerste keer had je het mis.';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: '$off punten ernaast',
      one: '1 punt ernaast',
      zero: 'precies goed',
    );
    return 'De uitdaging van vandaag op Astute: $_temp0. Kun jij het beter?';
  }

  @override
  String get playTheCard => 'Speel de kaart';

  @override
  String get openTheCard => 'Open de kaart';

  @override
  String get perkPathsTitle => 'Elk pad, helemaal';

  @override
  String get perkPathsLine =>
      'Tien kaarten over één thema, van de makkelijkste tot de moeilijkste. Elke week nieuwe paden.';

  @override
  String get journeyStrongest => 'Sterkst';

  @override
  String get journeyMostMissed => 'Vaakst gemist';

  @override
  String journeyRightShare(String pct) {
    return '$pct goed';
  }

  @override
  String get journeySubjectsNotYet =>
      'Zes antwoorden in een vak, en het wordt gemeten.';

  @override
  String get journeyChangedMind => 'Van mening veranderd';

  @override
  String get journeyNewToYou => 'Nieuw voor jou';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'van $n kaarten die het vroegen',
      one: 'van 1 kaart die het vroeg',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n wist je al',
      one: '1 wist je al',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => 'Jouw reis, als verhaal';

  @override
  String get storyLabNote => 'Nieuwe versie · op proef, alleen TestFlight';

  @override
  String get storyChapterWeek => 'Deze week';

  @override
  String get storyChapterWhere => 'Waar je staat';

  @override
  String get storyChapterReason => 'Hoe je redeneert';

  @override
  String get storyChapterPractice => 'Oefen';

  @override
  String get storyChapterStory => 'Jouw verhaal';

  @override
  String get journeyChapterKnow => 'Wat je weet';

  @override
  String get journeyChapterHabits => 'Je gewoontes';

  @override
  String get journeyChapterCoach => 'Je coach';

  @override
  String get coachTeaser =>
      'Elke week een notitie van je coach over hoe je redeneert: wat goed ging, op welke valkuil je moet letten, wat je hierna probeert.';

  @override
  String get coachRead => 'Lees de notitie van deze week';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Bij de antwoorden waar je zeker van was, had je $n op de 10 keer gelijk.',
      one: 'Bij de antwoorden waar je zeker van was, had je 1 op de 10 keer gelijk.',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => 'Beter dan vorige week.';

  @override
  String get storyWorse => 'Iets minder dan vorige week.';

  @override
  String storyHeadlineStreak(int n) {
    return '$n dagen op rij. Hou de draad vast.';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return 'In $subject heb je in $pct van de gevallen gelijk.';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten gelezen. Hier begint de reis.',
      one: 'Eén kaart gelezen. Hier begint de reis.',
      zero: 'Je eerste kaart wacht.',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return 'Jouw zekerheid: $sure. Je hebt in $right van de gevallen gelijk.';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n antwoorden met hoe zeker, en het wordt gemeten.',
      one: 'Nog één antwoord met hoe zeker, en het wordt gemeten.',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return 'Waar je jezelf te veel vertrouwt: $subject, met $points punten.';
  }

  @override
  String get storyUnlock => 'Bekijk het met Astute+';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'De $n die je fout had terwijl je zeker was',
      one: 'Die ene die je fout had terwijl je zeker was',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'De $n die je van mening deden veranderen',
      one: 'De kaart die je van mening deed veranderen',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '5 nieuwe kaarten in $subject';
  }

  @override
  String get storyPracticeNone =>
      'Nog niets te oefenen: beantwoord een paar kaarten en het komt.';

  @override
  String get storyFirstCard => 'Eerste kaart';

  @override
  String storyReached(String level) {
    return 'Bereikt: $level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Beste reeks: $n dagen',
      one: 'Beste reeks: 1 dag',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten gelezen',
      one: '1 kaart gelezen',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => 'Vandaag';

  @override
  String get storySeePath => 'Bekijk het pad';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nieuwe kaarten bovenaan',
      one: '1 nieuwe kaart bovenaan',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => 'Je bent bij: voorlopig niets nieuws.';

  @override
  String get deeperTitle => 'Verdiepen';

  @override
  String get deeperSimple => 'Leg het simpel uit';

  @override
  String get deeperWhy => 'Waarom het ertoe doet';

  @override
  String get deeperSides => 'Beide kanten';

  @override
  String get deeperExample => 'Een voorbeeld uit het dagelijks leven';

  @override
  String get deeperQuiz => 'Test me met een nieuw geval';

  @override
  String get deeperQuizRight => 'Goed.';

  @override
  String get deeperQuizWrong => 'Niet helemaal.';

  @override
  String get mathsDailySolve => 'Los het op';

  @override
  String get mathsDailySolved => 'Opgelost';

  @override
  String get mathsDailyMissed => 'Deze keer niet';

  @override
  String get mathsDailyTomorrow => 'Morgen een nieuwe';

  @override
  String get mathsDailyAnother => 'Nog een zoals deze';

  @override
  String goalShelf(String goal) {
    return 'Handig voor: $goal';
  }

  @override
  String get goalDecide => 'Dagelijkse beslissingen';

  @override
  String get goalPeople => 'Mensen';

  @override
  String get goalBusiness => 'Werk en zaken';

  @override
  String get goalMoney => 'Geld en aankopen';

  @override
  String get goalHealth => 'Gezondheid';

  @override
  String get goalDecideLine =>
      'Keuzes, risico’s en kansen, zonder onderbuikgevoel.';

  @override
  String get goalNews => 'Nieuws en sociale media';

  @override
  String get goalNewsLine =>
      'Koppen, statistieken en posts: wat overeind blijft.';

  @override
  String get goalPeopleLine =>
      'Wie je wil overtuigen, en hoe je begrepen wordt.';

  @override
  String get goalBusinessLine =>
      'Onderhandelingen, prikkels en de cijfers achter een idee.';

  @override
  String get goalMoneyLine =>
      'Prijzen, aanbiedingen, rente: de valkuilen van een deal.';

  @override
  String get goalHealthLine => 'Diëten, kuren en studies: wat het bewijs zegt.';

  @override
  String mathsDailyStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen op rij',
      one: '1 dag op rij',
    );
    return '$_temp0';
  }

  @override
  String get deeperYourTake => 'Jouw idee, bekeken';

  @override
  String get deeperYourTakeHint => 'Schrijf wat je ervan vindt…';

  @override
  String get deeperAnalyse => 'Bekijk het';

  @override
  String get deeperAsk => 'Vraag iets over deze kaart';

  @override
  String get deeperAskHint => 'Je vraag…';

  @override
  String get deeperSend => 'Vragen';

  @override
  String get deeperSource => 'Bron';

  @override
  String get deeperOpenSource => 'Open het origineel';

  @override
  String get deeperAiNote => 'Beantwoord door AI: die kan zich vergissen.';

  @override
  String get deeperBusy => 'Even denken…';

  @override
  String get deeperTomorrow => 'Genoeg voor vandaag: morgen meer.';

  @override
  String get deeperTryAgain => 'Het kwam niet door. Probeer het zo opnieuw.';

  @override
  String get deeperUnavailable =>
      'Nu even niet beschikbaar. Probeer het later opnieuw.';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n media',
      one: '1 medium',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n u geleden',
      zero: 'Zojuist',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dagen geleden',
      one: 'Gisteren',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => 'Wereld';

  @override
  String get newsKeyPoints => 'De kern';

  @override
  String get newsBehind => 'Achter het nieuws';

  @override
  String get newsSources => 'Bronnen';

  @override
  String get newsMadeFrom =>
      'Door Astute geschreven uit deze berichten, en eraan getoetst.';

  @override
  String get newsWhyItMatters => 'Waarom het ertoe doet';

  @override
  String get deeperDeclined => 'Hierop kan ze geen antwoord geven.';

  @override
  String get deeperPlusOnly => 'Met Astute+';

  @override
  String get deeperSimpleLead =>
      'Het idee van de kaart, zoals je het aan een nieuwsgierige tienjarige zou vertellen.';

  @override
  String get deeperSidesLead =>
      'De sterkste argumenten van beide kanten, en wat de vraag zou beslechten.';

  @override
  String get deeperExampleLead =>
      'Een moment uit een gewone dag waarop dit idee opduikt.';

  @override
  String get deeperQuizLead =>
      'Een geval dat de kaart niet noemt: één vraag, drie antwoorden.';

  @override
  String get deeperYourTakeLead =>
      'Wat er klopt aan je redenering, waar die wankelt, en een vraag om haar te toetsen.';

  @override
  String get deeperAskLead =>
      'Alles waar de kaart je over aan het denken zette.';

  @override
  String get deeperSideA => 'De ene kant';

  @override
  String get deeperSideB => 'De andere kant';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => 'Opnieuw proberen';

  @override
  String get deeperSimpleGo => 'Leg het me uit';

  @override
  String get deeperSidesGo => 'Laat beide kanten zien';

  @override
  String get deeperExampleGo => 'Geef me een voorbeeld';

  @override
  String get deeperQuizGo => 'Test me';

  @override
  String get bookOfTheWeek => 'Boek van de week';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ideeën',
      one: '1 idee',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n ideeën uit dit boek',
      one: 'Nog één idee uit dit boek',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine =>
      'Het hele boek met Astute+, en elke week een gratis boek.';

  @override
  String get bookMoreGo => 'Lees het hele boek';

  @override
  String bookMinutes(int n) {
    return '$n min';
  }

  @override
  String get bookStart => 'Begin met lezen';

  @override
  String get bookContinue => 'Verder lezen';

  @override
  String get bookAgain => 'Opnieuw lezen';

  @override
  String get bookTheIdeas => 'De ideeën';

  @override
  String get bookRecommendedBy => 'Aanbevolen door';

  @override
  String get bookFreeThisWeek => 'Gratis deze week';

  @override
  String get booksSeeAll => 'Alles bekijken';

  @override
  String get booksLibraryTitle => 'Alle boeken';

  @override
  String get bookDoneTitle => 'Boek uit';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return '$ideas grote ideeën, in $minutes minuten.';
  }

  @override
  String bookDoneCount(int count) {
    return 'Boeken uit: $count';
  }

  @override
  String get bookDoneNext => 'Volgend boek';

  @override
  String get bookDoneGo => 'Openen';

  @override
  String bookRetold(String title, String author) {
    return 'De ideeën uit $title van $author, in Astutes eigen woorden. Het hele boek vind je in de boekhandel.';
  }

  @override
  String get foundersTitle => 'Wat oprichters lezen';

  @override
  String founderBookCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n boeken',
      one: '1 boek',
    );
    return '$_temp0';
  }

  @override
  String get founderTheirBooks => 'Aanbevolen boeken';

  @override
  String founderAbout(String name) {
    return 'Dit zijn boeken die $name in het openbaar aanraadde, met de geciteerde woorden en waar ze werden gezegd. $name heeft geen enkele band met Astute.';
  }

  @override
  String founderPhoto(String author, String licence) {
    return 'Foto: $author, $licence, Wikimedia Commons, bijgesneden';
  }

  @override
  String founderAlso(String names) {
    return 'Ook aanbevolen door $names';
  }

  @override
  String get firstCardTitle => 'Je eerste kaart';

  @override
  String get firstCardSwipeOn => 'Veeg om verder te gaan';

  @override
  String get trialOfferTitle => 'Probeer heel Astute+.';

  @override
  String get trialOfferMark => 'Astute+.';

  @override
  String get trialOfferLine =>
      'De vijf kaarten van vandaag wachten hoe dan ook op je.';

  @override
  String get trialStepToday => 'Vandaag';

  @override
  String get trialStepTodayLine => 'Heel Astute+ gaat open. Je betaalt niets.';

  @override
  String trialStepDay(int day) {
    return 'Dag $day';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'We sturen je een melding: nog $days dagen.',
      one: 'We sturen je een melding: nog 1 dag.',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine =>
      'Wordt elk jaar verlengd. Zeg minstens 24 uur van tevoren op en je betaalt niets.';

  @override
  String get trialOfferStart => 'Start de proefperiode';

  @override
  String get trialOfferFree => 'Gratis doorgaan';
}
