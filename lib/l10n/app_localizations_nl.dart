// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
    return 'DE $word VAN VANDAAG · VEEG OM TERUG TE KIJKEN';
  }

  @override
  String weekLine(int days) {
    return 'Je week · $days van 7 gehaald';
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
  String hoursMinutes(int h, int m) {
    return '${h}u ${m}m';
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
  String get fiveMore => 'Nog vijf';

  @override
  String get unlockFiveExtra => 'Vijf extra pillen ontgrendelen';

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
      'Duwtje aan, maar het systeem zei nee. Zet meldingen voor Astut aan in de instellingen.';

  @override
  String get nudgeOnNeedsPhone =>
      'Duwtje aan. Bezorging heeft de telefoonversie nodig.';

  @override
  String get howMuchYouKnow => 'Hoeveel je weet';

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
  String get seeEveryPrincipleWithPlus => 'Zie elk principe met Astut plus';

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
      'De meting loopt. Astut+ laat je zien welke kant het op gaat.';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 dagen gratis';

  @override
  String get watchTheGapMove => 'Zie het gat bewegen.';

  @override
  String get measurementFreeForever =>
      'De meting is gratis en blijft dat. Astut+ vertelt je welke kant het op gaat.';

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
  String get whatYouAlready => 'Wat je al ';

  @override
  String get know => 'weet';

  @override
  String get knowIntro =>
      'De vakken die je het hoogst zette. Het verandert wat een dag in elk van je vraagt — stevig krijgt vragen, nieuwsgierig krijgt uitleg — niet hoeveel je ervan krijgt.';

  @override
  String get startWithMyFirstCards => 'Beginnen met mijn eerste kaarten';

  @override
  String get skipForNow => 'Voor nu overslaan';

  @override
  String get levelCurious => 'Nieuwsgierig';

  @override
  String get levelSome => 'Wat';

  @override
  String get levelSolid => 'Stevig';

  @override
  String get save => 'Opslaan';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n van $total vakken in de mix';
  }

  @override
  String get yourSpace => 'Jouw ';

  @override
  String get mix => 'mix';

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
  String get introTopicsTitle => 'Twaalf vakken, vijf pillen';

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
  String get barMoveCaps => 'DE ZIN VOOR AAN DE BAR';

  @override
  String get theBarMoveCaps => 'DE ZIN VOOR AAN DE BAR';

  @override
  String get dayStreakCaps => 'DAGEN OP RIJ';

  @override
  String sourceLabel(String source) {
    return 'Bron · $source';
  }

  @override
  String get perkRecordTitle => 'Je staat van dienst door de tijd';

  @override
  String get perkRecordLine =>
      'Of het gat tussen hoe zeker je was en hoe goed je zat echt sluit.';

  @override
  String get perkPrinciplesTitle => 'Elk principe dat je tegenkwam';

  @override
  String get perkPrinciplesLine =>
      'Niet alleen de drie waar je het slechtst in bent — allemaal, en de contexten die je nog niet zag.';

  @override
  String get perkFreezesTitle => 'Drie reeks-freezes, niet één';

  @override
  String get perkFreezesLine =>
      'Genoeg voor een weekend weg. Een reeks die je alleen kunt verliezen, gaat uiteindelijk verloren.';

  @override
  String get perkExtraTitle => '5 extra pillen elke dag';

  @override
  String get perkExtraLine =>
      'Een tweede set gaat open zodra je de eerste af hebt.';

  @override
  String get perkArchiveTitle => 'Het volledige archief';

  @override
  String get perkArchiveLine =>
      'Elke pil die je ooit las, doorzoekbaar per vak.';

  @override
  String get perkTopicsTitle => 'Kies je eigen vakken';

  @override
  String get perkTopicsLine => 'Weeg de mix naar wat je echt leuk vindt.';

  @override
  String get plusIsActive => 'ASTUT+ IS ACTIEF';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Probeer 7 dagen gratis, daarna $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Proefperiode gestart. In deze versie is geen betaling aangesloten.';

  @override
  String get thatDidNotGoThrough => 'Dat is niet gelukt.';

  @override
  String get plusIsBack => 'Astut+ is terug.';

  @override
  String get nothingToRestore => 'Niets te herstellen op dit account.';

  @override
  String get findOutIfBetter => 'Ontdek of je echt beter wordt.';

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
  String get everythingOpensNothingCharged =>
      'Alles gaat open. Er wordt niets afgeschreven.';

  @override
  String dayN(int n) {
    return 'DAG $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Een herinnering, twee dagen voor de verlenging.';

  @override
  String get itRenewsUnlessCancelled =>
      'Het verlengt, tenzij je hebt opgezegd. Dat kan altijd.';

  @override
  String get howTheFreeWeekWorks => 'ZO WERKT DE GRATIS WEEK';

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
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kaarten kwamen terug — beantwoord ze opnieuw',
      one: '1 kaart kwam terug — beantwoord hem opnieuw',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Teruggekomen';

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
}
