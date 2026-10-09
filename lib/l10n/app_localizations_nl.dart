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
  String signInNotConnected(String provider) {
    return 'Inloggen met $provider is nog niet aangesloten. Je kaarten blijven op dit apparaat.';
  }

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
  String dayRead(int n, String word) {
    return 'Dag $n · $word gelezen';
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
  String get saveThisPill => 'Deze pil bewaren';

  @override
  String get shareThisPill => 'Deze pil delen';

  @override
  String cardOf(int k, int n) {
    return 'Kaart $k van $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'De vijf van morgen gaan open over $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic opent de vijf van morgen, over $when';
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
  String get onesThatAskTheMost => 'De kaarten die het meest vragen';

  @override
  String get acrossEveryone => 'Bij iedereen, niet alleen in jouw mix';

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
  String get noPillsMatchFilter => 'Nog geen pil past bij dat filter.';

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
  String get signOutQuestion => 'Uitloggen?';

  @override
  String get signOutBody =>
      'Je reeks, bewaarde pillen en staat van dienst blijven in je account. Dit wist ze van dit apparaat.';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get deletingAccount => 'Je account wordt verwijderd…';

  @override
  String get deleteAccountQuestion => 'Je account verwijderen?';

  @override
  String get deleteAccountBody =>
      'Je account, de back-up ervan en het bord dat je vrienden zien worden definitief verwijderd, en dit apparaat begint weer bij het begin. Astute+ wordt hiermee niet opgezegd: een abonnement beheer je in de App Store-instellingen.';

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
      'Wist alles op dit apparaat — reeks, bewaarde pillen, antwoorden, je oordeelsgeschiedenis, vakken en abonnement — en opent de introductie opnieuw.';

  @override
  String get wipeIt => 'Wissen';

  @override
  String get yourRecord => 'Je staat van dienst';

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
  String get yourFivePillsBeforeCoffee => 'Je 5 pillen, voor de eerste koffie.';

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
  String get manageSubscription => 'Abonnement beheren';

  @override
  String get howPillsAreWritten => 'Hoe pillen geschreven worden';

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
      other: 'pillen gelezen',
      one: 'pil gelezen',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pillen gelezen',
      one: '1 pil gelezen',
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
  String get streakReset => 'Reeks op nul';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Je hebt\n$n dagen gemist.',
      one: 'Je hebt\neen dag gemist.',
    );
    return '$_temp0';
  }

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
  String get whileYouWereAway => 'Terwijl je weg was';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pillen bleven ongelezen',
      one: '1 pil bleef ongelezen',
    );
    return '$_temp0';
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
  String subjectsInTheMix(int n, int total) {
    return '$n van $total vakken in de mix';
  }

  @override
  String get everythingIsInDrag =>
      'Alles zit erin. Sleep een vak omlaag om er minder van te zien, of tot nul om het te laten vallen.';

  @override
  String get next => 'Volgende';

  @override
  String get whatShouldWeTalkAbout => 'Waar zullen we het over hebben?';

  @override
  String get fivePillsADayPick =>
      'Vijf pillen per dag, elke ochtend vers geschreven. Kies de vakken die je in de mix wilt — je kunt ze later veranderen.';

  @override
  String nSelected(int n) {
    return '$n gekozen';
  }

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
      'Vijf slimme dingen per dag, klaar voor het volgende gesprek';

  @override
  String get introTopicsTitle => 'Achttien vakken, vijf pillen';

  @override
  String get introTopicsLine =>
      'Elke ochtend vers geschreven, en gecheckt tegen een bron.';

  @override
  String get introQuestionTitle => 'Een vraag, dan het antwoord';

  @override
  String get introQuestionLine =>
      'Elke pil draagt de ene zin die het waard is hardop te zeggen.';

  @override
  String get introMixTitle => 'Jij kiest de mix';

  @override
  String get introMixLine =>
      'Zet een vak lager om er minder van te zien, of helemaal uit.';

  @override
  String get introThirtyTitle => 'Dertig seconden per dag';

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
  String get continueWithEmail => 'Doorgaan met e-mail';

  @override
  String get termsLine =>
      'Door je aan te melden ga je akkoord met onze Servicevoorwaarden en Privacyverklaring';

  @override
  String get skip => 'Overslaan';

  @override
  String get tapToRevealLower => 'tik om te onthullen';

  @override
  String get barMoveCaps => 'OM TE ONTHOUDEN';

  @override
  String get theBarMoveCaps => 'DE ZIN VOOR AAN DE BAR';

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
  String get dayStreakCaps => 'DAGEN OP RIJ';

  @override
  String sourceLabel(String source) {
    return 'Bron · $source';
  }

  @override
  String get perkArchiveTitle => 'Je hele archief';

  @override
  String get perkArchiveLine => 'Elke dag die je las, voorgoed bewaard.';

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
  String get noChargeTodayCancel => 'Vandaag niets betalen · altijd opzegbaar';

  @override
  String get chargedTodayCancel => 'Vandaag afgeschreven · altijd opzegbaar';

  @override
  String get everyCardForYouMark => 'jou';

  @override
  String get trialStartedNoPayment =>
      'Proefperiode gestart. In deze versie is geen betaling aangesloten.';

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
  String get cancelAnyTimeNoPayment =>
      'Altijd opzegbaar · In deze versie wordt niets afgeschreven';

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
  String closeEnoughItIs(String answer) {
    return 'Dichtbij · het is $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Je zei $given · het is $answer, en $band telt';
  }

  @override
  String get youGotIt => 'Goed';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Je zei $given · het is $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Bijna iedereen heeft deze fout';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · je zei $pct% zeker';
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
  String get thatWasTheOnlyOne => 'Dat was de enige';

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
  String get fiveADayALittleSharper => 'Vijf per dag. Een beetje scherper.';

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
  String get likeThisPill => 'Deze pil liken';

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
      'Tik op de bladwijzer van een pil en hij komt hier — de kaarten die je denken veranderden, bewaard.';

  @override
  String get nudgeTitle => 'Je vijf staan klaar';

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
  String get friends => 'Vrienden';

  @override
  String friendsN(int n) {
    return 'Vrienden · $n';
  }

  @override
  String get yourFriendCode => 'Je vriendencode';

  @override
  String get codeCopied => 'Code gekopieerd.';

  @override
  String get addAFriend => 'Een vriend toevoegen';

  @override
  String get theirCode => 'Hun code';

  @override
  String get add => 'Toevoegen';

  @override
  String get noFriendsYet =>
      'Nog niemand. Wissel codes uit met een vriend en vergelijk reeksen en kalibratie — nooit antwoorden.';

  @override
  String get friendsNeedAnAccount =>
      'Vergelijken vraagt de telefoon-app en een account. Je codes blijven bewaard.';

  @override
  String get noReaderWithCode => 'Geen lezer met die code.';

  @override
  String get thatsYourOwnCode => 'Dat is je eigen code.';

  @override
  String pointsOff(int n) {
    return '$n punten ernaast';
  }

  @override
  String get notMeasuredYet => 'nog niet gemeten';

  @override
  String get thisWeekByCalibration => 'Deze week, op kalibratie';

  @override
  String get notYetToday => 'vandaag nog niet';

  @override
  String nOfSeven(int n) {
    return '$n van 7';
  }

  @override
  String get you => 'Jij';

  @override
  String get todaysQuestion => 'De vraag van vandaag';

  @override
  String get right => 'goed';

  @override
  String get wrong => 'fout';

  @override
  String rightAtSure(int sure) {
    return 'goed, $sure% zeker';
  }

  @override
  String wrongAtSure(int sure) {
    return 'fout, $sure% zeker';
  }

  @override
  String get yourJourney => 'Je reis';

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
  String get yourMix => 'Jouw mix';

  @override
  String get genresLine =>
      'Tik op een genre om het over te slaan. Houd het vast en de drie draden erin openen er vlak onder.';

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
      'Vijf kaarten per dag voor jou gekozen: uit je mix, op jouw niveau, nooit een die je al las. Vanaf morgen.';

  @override
  String get everyCardForYou => 'Elke kaart, voor jou gekozen.';

  @override
  String get perkOwnTitle => 'Vijf kaarten per dag, allemaal van jou';

  @override
  String get perkOwnLine =>
      'Uit jouw draden, op jouw niveau, nooit een die je al las. Gratis krijg je er twee per dag.';

  @override
  String get plusCardHeadline => 'Alle vijf van jou.';

  @override
  String get plusCardLine =>
      'Vijf kaarten per dag uit je mix, op jouw niveau. Je reis. Je hele archief.';

  @override
  String get continueFree => 'Gratis verdergaan';

  @override
  String get archiveBeforeThisWeek => 'Vóór deze week';

  @override
  String get weekKeptThreeOwn =>
      'Een week volgehouden: morgen zijn drie van de vijf van jou.';

  @override
  String get perkJourneyLine =>
      'Je niveau, elk vak draad voor draad, wat bleef, en de kaart om vanavond te vertellen.';

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
  String get topEmpty =>
      'Nog niets op de lijst. Elke kaart die je liket, bewaart of vertelt telt mee.';

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
  String get themePracticalLine => 'Iets om vóór vanavond te proberen';

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
  String get themeDebates => 'Kies een kant';

  @override
  String get themeDebatesLine =>
      'Geen goed antwoord, alleen een beter argument';

  @override
  String get themeWorkItOut => 'Reken het uit';

  @override
  String get themeWorkItOutLine => 'Een getal om uit je hoofd te vinden';

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
  String get successWelcome =>
      'Welkom bij Astute+. De vijf kaarten van vandaag staan klaar.';

  @override
  String successWelcomeNamed(String name) {
    return 'Welkom bij Astute+, $name. De vijf kaarten van vandaag staan klaar.';
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
  String get aMove => 'Een zet';

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
  String get betSlip => 'Je wedbriefje';

  @override
  String get betWord => 'Inzetten';

  @override
  String get biggerLabel => 'Groter';

  @override
  String get biggerNote => 'Elk getal is het antwoord van een kaart.';

  @override
  String biggerScore(int right, int asked) {
    return '$right van de $asked goed.';
  }

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
  String get corrections => 'Rectificaties';

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
  String get editionEnd => 'Dat was de editie van vandaag';

  @override
  String get editionTomorrow => 'Die van morgen verschijnt \'s ochtends';

  @override
  String get eraAncient => 'De oudheid';

  @override
  String get eraAncientWhen => 'Vóór 500';

  @override
  String get eraEarlyModern => 'De vroegmoderne tijd';

  @override
  String get eraEarlyModernWhen => '1500 tot 1800';

  @override
  String get eraMedieval => 'De middeleeuwen';

  @override
  String get eraMedievalWhen => '500 tot 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nog $n uit deze tijd',
      one: 'Nog 1 uit deze tijd',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'De negentiende eeuw';

  @override
  String get eraNineteenthWhen => '1800 tot 1900';

  @override
  String get eraRecent => 'Deze eeuw';

  @override
  String get eraRecentWhen => 'Sinds 2000';

  @override
  String get eraRulerNow => 'Nu';

  @override
  String get eraRulerOld => 'Oudheid';

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
  String get eraTwentieth => 'De vorige eeuw';

  @override
  String get eraTwentiethWhen => '1900 tot 2000';

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
  String get goNarrow =>
      'Ga smal als je zeker bent: dat levert drie keer zoveel op.';

  @override
  String get hardBadge => 'Moeilijk';

  @override
  String hidesIn(String where) {
    return 'In $where';
  }

  @override
  String get howSure => 'Hoe zeker ben ik, en waarom?';

  @override
  String get inNumbers => 'In cijfers';

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
  String get markTried => 'Geprobeerd';

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
  String get modeBiggerLine =>
      'Twee getallen om in te schatten. Tik op de grootste';

  @override
  String get modeCloser => 'Steeds dichterbij';

  @override
  String get modeCloserLine =>
      'Drie stappen meer of minder om het getal in te sluiten';

  @override
  String get modePick => 'Kies er een';

  @override
  String get modePickLine => 'Drie bedragen. Kies voor je de kaart opent';

  @override
  String get modeRange => 'Zet in op een bereik';

  @override
  String get modeRangeLine =>
      'Hoe smaller, hoe meer het oplevert, als je gelijk hebt';

  @override
  String get modeSlide => 'Schuif';

  @override
  String get modeSlideLine =>
      'Zet eerst je antwoord, zie dan hoe ver je ernaast zat';

  @override
  String get modeStake => 'Plaats je inzet';

  @override
  String modeStakeLine(int n) {
    return '$n punten per dag. Win en je verdubbelt je inzet';
  }

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
  String get moveComparedToWhat => 'Vergeleken waarmee';

  @override
  String get moveComparedToWhatLine =>
      'Een verandering zegt niets zonder controlegroep';

  @override
  String get moveSampling => 'De steekproef';

  @override
  String get moveSamplingLine =>
      'Wie in de steekproef belandt, bepaalt wat die kan zeggen';

  @override
  String mythDeckHint(int at, int of) {
    return '$at van $of · veeg om om te draaien';
  }

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
  String pointsToday(int n) {
    return '+$n vandaag';
  }

  @override
  String get puzzleOfTheDay => 'De puzzel van de dag';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pt';
  }

  @override
  String get rightLastTime => 'Vorige keer goed';

  @override
  String get sameForEveryoneCaps => 'Voor iedereen hetzelfde';

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
  String slideAverage(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Gemiddeld $n punten ernaast.',
      one: 'Gemiddeld 1 punt ernaast.',
      zero: 'Gemiddeld precies goed.',
    );
    return '$_temp0';
  }

  @override
  String get slideNote =>
      'Instellen, controleren. Hoe ver je ernaast zat, daar gaat het om.';

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
  String get slipEmpty => 'Nog geen inzetten. Elke inzet komt hier.';

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
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Opening';

  @override
  String get throughTime => 'Door de tijd';

  @override
  String get throughTimeLine =>
      'Van de oudheid tot dit jaar. Sleep om te reizen';

  @override
  String get todayLabel => 'Vandaag';

  @override
  String get todaysEdition => 'Editie van vandaag';

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
}
