// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => 'Heute';

  @override
  String get tabExplore => 'Entdecken';

  @override
  String get tabProfile => 'Profil';

  @override
  String signInNotConnected(String provider) {
    return 'Die Anmeldung mit $provider ist noch nicht angebunden. Deine Karten bleiben auf diesem Gerät.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Anmeldung mit $label fehlgeschlagen. Du kannst ohne Konto weitermachen.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Ein Freeze hat die Serie gerettet';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'eine',
      '2': 'zwei',
      '3': 'drei',
      '4': 'vier',
      '5': 'fünf',
      '6': 'sechs',
      '7': 'sieben',
      '8': 'acht',
      '9': 'neun',
      '10': 'zehn',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Tag $n · $word gelesen';
  }

  @override
  String shelfEyebrow(String word) {
    return 'DIE $word VON HEUTE';
  }

  @override
  String get tapToFlip => 'TIPPEN ZUM UMDREHEN';

  @override
  String get shareThisCard => 'Diese Karte teilen';

  @override
  String get removeFromSaved => 'Aus Behalten entfernen';

  @override
  String get saveThisPill => 'Diese Karte behalten';

  @override
  String get shareThisPill => 'Diese Karte teilen';

  @override
  String cardOf(int k, int n) {
    return 'Karte $k von $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Die fünf von morgen öffnen sich in $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic eröffnet die fünf von morgen, in $when';
  }

  @override
  String get exploreTodaysBest => 'Das Beste von heute entdecken';

  @override
  String magicUnlock(int days) {
    return '$days Tage gratis testen';
  }

  @override
  String get getPlus => 'Astute+ holen';

  @override
  String nothingInYet(String subject) {
    return 'Noch nichts in $subject.';
  }

  @override
  String get here => 'diesem Bereich';

  @override
  String get todaysShelf => 'Das Regal von heute';

  @override
  String get sameForEveryone => 'Für alle gleich, und nur heute';

  @override
  String becauseSitsAtFull(String name) {
    return 'Weil $name ganz oben steht';
  }

  @override
  String get olderFromTurnedUp =>
      'Ältere Karten aus den Fächern, die du hochgedreht hast';

  @override
  String moreOn(String name) {
    return 'Mehr zu $name';
  }

  @override
  String get subjectReadMost => 'Das Fach, von dem du am meisten gelesen hast';

  @override
  String monthOf(String name) {
    return 'Ein Monat $name';
  }

  @override
  String get somewhereToStart => 'Ein Anfang, der nicht heute ist';

  @override
  String get searchEveryCard => 'Alle Karten durchsuchen';

  @override
  String nothingForYet(String query) {
    return 'Noch nichts für „$query“.';
  }

  @override
  String matching(int n) {
    return '$n Treffer';
  }

  @override
  String get all => 'Alle';

  @override
  String get theArchive => 'Das Archiv';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Ergebnisse',
      one: '1 Ergebnis',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n Karten. Tippe auf einen Tag, um ihn zu öffnen.';
  }

  @override
  String get whatYouHaveCovered => 'Was du abgedeckt hast';

  @override
  String searchNCards(int n) {
    return '$n Karten durchsuchen';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten',
      one: '1 Karte',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Gestern';

  @override
  String get noPillsMatchFilter => 'Noch keine Karte passt zu diesem Filter.';

  @override
  String nothingForTryTopic(String query) {
    return 'Nichts für „$query“. Versuch es mit einem Fach.';
  }

  @override
  String get saved => 'Behalten';

  @override
  String get removedFromSaved => 'Aus Behalten entfernt.';

  @override
  String get undo => 'Rückgängig';

  @override
  String get nothingKeptYet => 'Noch nichts behalten';

  @override
  String nInTopic(int n, String topic) {
    return '$n in $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Behalte die, die du wirklich brauchst';

  @override
  String get backToTodaysFive => 'ZURÜCK ZU DEN FÜNF VON HEUTE';

  @override
  String get archive => 'Archiv';

  @override
  String get yourWeek => 'Deine Woche';

  @override
  String get nothingThisWeekYet =>
      'Diese Woche noch nichts. Fünf Karten starten sie.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Geschafft — $days von sieben Tagen.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days von sieben Tagen.',
      one: '1 von sieben Tagen.',
    );
    return '$_temp0 Fünf halten die Woche.';
  }

  @override
  String get howSureAgainstHowRight => 'Wie sicher, gegen wie richtig';

  @override
  String get sureAndWrong => 'Sicher, und falsch';

  @override
  String get worthGoingBackTo =>
      'Die, zu denen es sich zurückzugehen lohnt. Bei etwas falsch zu liegen, dessen man sich sicher war, ist der einzige günstige Weg herauszufinden, was man wirklich glaubt.';

  @override
  String get whereThisIsGoing => 'Wohin das führt';

  @override
  String ofNRight(int n) {
    return 'von $n richtig';
  }

  @override
  String get sayHowSureOnMore =>
      'Sag bei ein paar weiteren, wie sicher du bist, und die App sagt dir, was diese Sicherheit wert ist.';

  @override
  String confidenceOff(int gap) {
    return 'Deine Sicherheit lag $gap Punkte neben dem, was du wirklich wusstest.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Deine Sicherheit lag $gap Punkte daneben, gegenüber $before letzte Woche. Die Lücke schließt sich.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Deine Sicherheit lag $gap Punkte daneben, gegenüber $before letzte Woche. Die Lücke ist größer geworden.';
  }

  @override
  String nextRung(String name) {
    return 'Als Nächstes: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Du sagtest $n % sicher';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Tag eins',
      'reading': 'Lesen',
      'answering': 'Antworten',
      'saying_how_sure': 'Sicherheit nennen',
      'calibrated': 'Kalibriert',
      'holding': 'Behalten',
      'sharp': 'Scharf',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Hier fängt jeder an.',
      'reading': 'Die Gewohnheit hat begonnen.',
      'answering': 'Du legst dich fest, bevor du die Karte umdrehst.',
      'saying_how_sure': 'Du gibst dem, was du zu wissen glaubst, eine Zahl.',
      'calibrated': 'Was du zu wissen sagst, weißt du.',
      'holding': 'Es bleibt Wochen später noch bei dir.',
      'sharp':
          'Sicher, wenn du es sein solltest, und richtig, wenn du es bist.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'noch $n Karten lesen';
  }

  @override
  String stepAnswer(int n) {
    return 'noch $n Karten beantworten';
  }

  @override
  String stepJudge(int n) {
    return 'noch $n Antworten mit deiner Sicherheit';
  }

  @override
  String stepHold(int n) {
    return 'noch $n Karten behalten';
  }

  @override
  String stepGap(int gap, int target) {
    return 'deine Sicherheit liegt $gap Punkte daneben — $target reichen';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'noch $n Antworten, bevor die App deine Sicherheit beurteilt';
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
  String get signOutQuestion => 'Abmelden?';

  @override
  String get signOutBody =>
      'Serie, behaltene Karten und Bilanz bleiben in deinem Konto. Das hier löscht sie von diesem Gerät.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deletingAccount => 'Dein Konto wird gelöscht…';

  @override
  String get deleteAccountQuestion => 'Dein Konto löschen?';

  @override
  String get deleteAccountBody =>
      'Dein Konto, seine Sicherung und die Tafel, die deine Freunde sehen, werden endgültig gelöscht, und dieses Gerät beginnt wieder von vorn. Astute+ wird dadurch nicht gekündigt: Ein Abo verwaltest du in den App-Store-Einstellungen.';

  @override
  String get deleteAccountConfirm => 'Endgültig löschen';

  @override
  String get accountDeleted => 'Dein Konto wurde gelöscht.';

  @override
  String get couldNotDeleteAccount =>
      'Das Konto konnte nicht gelöscht werden. Versuch es gleich noch einmal.';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signedInRecordOnAccount =>
      'Angemeldet. Serie und Bilanz liegen jetzt in deinem Konto.';

  @override
  String couldNotSignInWith(String label) {
    return 'Anmeldung mit $label fehlgeschlagen.';
  }

  @override
  String get signInNotAvailableBuild =>
      'Anmelden ist in dieser Version nicht verfügbar.';

  @override
  String get startOverQuestion => 'Von vorn anfangen?';

  @override
  String get startOverBody =>
      'Löscht alles auf diesem Gerät — Serie, behaltene Karten, Antworten, deine Urteilsbilanz, Fächer und Tarif — und öffnet die Einführung neu.';

  @override
  String get wipeIt => 'Löschen';

  @override
  String get yourRecord => 'Deine Bilanz';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get yourTopics => 'Deine Fächer';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get howWellYouKnowYourself => 'Wie gut du dich kennst';

  @override
  String get journeyButtonLine =>
      'Dein Level, die Züge, die du immer wieder verpasst, deine Woche in Fragen';

  @override
  String get isTheGapClosing => 'Schließt sich die Lücke?';

  @override
  String get movesYouKeepMissing => 'Die Züge, die du immer wieder verpasst';

  @override
  String get dailyNudge => 'Täglicher Anstoß';

  @override
  String everyDayAt(String time) {
    return 'Jeden Tag um $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'Deine 5 Karten, vor dem ersten Kaffee.';

  @override
  String get browserOnlySpeaksOpen =>
      'Ein Browser spricht nur, solange er offen ist — dafür braucht es die Handy-Version.';

  @override
  String get nudgeOff => 'Anstoß aus.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Anstoß an, jeden Tag um $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Anstoß an, aber das System hat abgelehnt. Schalte Benachrichtigungen für Astute in den Einstellungen ein.';

  @override
  String get nudgeOnNeedsPhone =>
      'Anstoß an. Die Zustellung braucht die Handy-Version.';

  @override
  String savedN(int n) {
    return 'Behalten · $n';
  }

  @override
  String get manageSubscription => 'Abo verwalten';

  @override
  String get howPillsAreWritten => 'Wie Karten geschrieben werden';

  @override
  String get howTitle => 'Jede Karte hier schreibt ein KI-Modell.';

  @override
  String get howIntro =>
      'Wir sagen es lieber gleich, als dass du es selbst herausfindest. So kommt eine Karte zu dir.';

  @override
  String get howStep1Title => 'Vorab geschrieben, von einem Modell';

  @override
  String get howStep1Line =>
      'Jede Karte folgt einer Vorgabe: eine Frage, die sich lohnt, eine Antwort, die sagt warum, und ein Denkzug, den du wieder nutzen kannst.';

  @override
  String get howStep2Title => 'An ihrer Quelle geprüft';

  @override
  String get howStep2Line =>
      'Jede Karte nennt ihre Quelle, und ein zweites Modell liest sie als Kritiker, bevor sie erscheint. Was sich nicht belegen lässt, fliegt raus.';

  @override
  String get howStep3Title => 'Fünf, jeden Morgen ausgeteilt';

  @override
  String get howStep3Line =>
      'Aus den Fächern, die du gewählt hast, und nie eine, die du schon gelesen hast.';

  @override
  String get howStep4Title => 'Ehrlich gehalten von den Lesern';

  @override
  String get howStep4Line =>
      'Wenn genug Leser sagen, dass eine Karte falsch ist, wird sie nicht mehr ausgeteilt, bis ein Mensch sie geprüft hat.';

  @override
  String get howReportTitle => 'Einen Fehler gefunden?';

  @override
  String get howReportLine =>
      'Tippe auf das Fähnchen neben der Quelle einer Karte, um sie zu melden.';

  @override
  String get howFoot => 'Die Quellen werden jeden Monat neu geprüft.';

  @override
  String get signingIn => 'Anmeldung…';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'Bei $n Antworten hast du gesagt, wie sicher du warst. So ist es ausgegangen.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Wer perfekt kalibriert ist, hat in 70 % der Fälle recht, wenn er 70 % sagt.';

  @override
  String get notEnoughAnswersYet => 'Noch nicht genug Antworten';

  @override
  String get confidenceMatchesAccuracy =>
      'Deine Sicherheit deckt sich mit deiner Trefferquote';

  @override
  String overconfidentBy(int points) {
    return 'Du bist um $points Punkte zu sicher';
  }

  @override
  String underconfidentBy(int points) {
    return 'Du bist um $points Punkte zu unsicher';
  }

  @override
  String saidPercent(int n) {
    return 'Gesagt: $n %';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'richtig: $pct % ($right von $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'noch $n Kontexte dazu kommen',
      one: 'noch 1 Kontext dazu kommt',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus =>
      'Jedes Prinzip sehen, mit Astute plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weitere werden verfolgt',
      one: '1 weiteres wird verfolgt',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'MEINE BILANZ TEILEN';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Deine letzten $n Urteile, gegen deine ersten $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Um $n Punkte geschlossen';
  }

  @override
  String openedByPoints(int n) {
    return 'Um $n Punkte geöffnet';
  }

  @override
  String get holdingSteady => 'Bleibt gleich';

  @override
  String get measurementRunningPlus =>
      'Die Messung läuft. Astute+ zeigt dir, in welche Richtung.';

  @override
  String firstN(int n) {
    return 'Erste $n';
  }

  @override
  String lastN(int n) {
    return 'Letzte $n';
  }

  @override
  String get trackingMoreClosely =>
      'Deine Sicherheit folgt deiner Trefferquote enger als vorher.';

  @override
  String get distanceHasGrown =>
      'Der Abstand ist gewachsen. Es lohnt sich, vor dem Festlegen langsamer zu werden.';

  @override
  String get noRealMovementYet =>
      'Noch keine echte Bewegung. Das dauert Wochen, nicht Tage.';

  @override
  String get seeWhichWay => 'RICHTUNG ANSEHEN';

  @override
  String get spotOn => 'genau';

  @override
  String pointsOver(int n) {
    return '$n zu viel';
  }

  @override
  String pointsUnder(int n) {
    return '$n zu wenig';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days Tage gratis';
  }

  @override
  String get seeThePlans => 'TARIFE ANSEHEN';

  @override
  String get recordStartsToday => 'Deine Bilanz beginnt heute.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tage',
      one: 'Tag',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Karten gelesen',
      one: 'Karte gelesen',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten gelesen',
      one: '1 Karte gelesen',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Wochen geschafft',
      one: '1 Woche geschafft',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n kommen zurück';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Freezes übrig',
      one: '1 Freeze übrig',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Gratis-Tarif';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Du hast\n$n Tage verpasst.',
      one: 'Du hast\neinen Tag verpasst.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage sind',
      one: 'Ein Tag ist',
    );
    return '$_temp0 weiterhin dein Rekord. Lies die fünf von heute und der Zähler beginnt wieder bei eins.';
  }

  @override
  String get whileYouWereAway => 'Während du weg warst';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten blieben ungelesen',
      one: '1 Karte blieb ungelesen',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic ist noch immer dein meistbehaltenes Fach';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten, die du richtig hattest, kommen heute zurück',
      one: '1 Karte, die du richtig hattest, kommt heute zurück',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Mit den fünf von heute neu starten';

  @override
  String moveMyReminderTo(String time) {
    return 'Erinnerung auf $time verschieben';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Täglicher Anstoß auf $time verschoben.';
  }

  @override
  String get reminderAskTitle => 'Wann sollen wir dich erinnern?';

  @override
  String get reminderAskLine =>
      'Eine Benachrichtigung am Tag, mit einer Frage aus deinen Karten.';

  @override
  String get reminderAskTrialLine =>
      'Wir erinnern dich zwei Tage, bevor deine Testphase endet.';

  @override
  String get reminderAskMorning => 'Morgens';

  @override
  String get reminderAskLunch => 'Mittags';

  @override
  String get reminderAskEvening => 'Abends';

  @override
  String get reminderAskOther => 'Andere Uhrzeit';

  @override
  String get reminderAskYes => 'Erinnere mich';

  @override
  String get reminderAskNotNow => 'Nicht jetzt';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Deine Astute+-Testphase endet in $days Tagen.',
      one: 'Deine Astute+-Testphase endet morgen.',
      zero: 'Deine Astute+-Testphase endet heute.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return 'Am $date beginnt dein Jahr für $price. Um weiterzumachen, musst du nichts tun. Zum Kündigen: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Deine Testphase endet in $days Tagen',
      one: 'Deine Testphase endet morgen',
      zero: 'Deine Testphase endet heute',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Verwalten';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n von $total Fächern im Mix';
  }

  @override
  String get everythingIsInDrag =>
      'Alles ist drin. Zieh ein Fach nach unten, um weniger davon zu sehen, oder bis auf null, um es zu streichen.';

  @override
  String get next => 'Weiter';

  @override
  String get whatShouldWeTalkAbout => 'Worüber reden wir?';

  @override
  String get fivePillsADayPick =>
      'Fünf Karten am Tag, jeden Morgen neue. Wähl die Fächer für deinen Mix — du kannst sie später ändern.';

  @override
  String nSelected(int n) {
    return '$n ausgewählt';
  }

  @override
  String startWithNTopics(int n) {
    return 'Mit $n Fächern starten';
  }

  @override
  String saveNTopics(int n) {
    return '$n Fächer speichern';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Wähl mindestens $n';
  }

  @override
  String get swipeToSeeMore => 'Wischen für mehr';

  @override
  String get tagline => 'Fünf kluge Dinge am Tag, bereit fürs nächste Gespräch';

  @override
  String get introTopicsTitle => 'Neunzehn Fächer, fünf Karten';

  @override
  String get introTopicsLine =>
      'Vorab von einem Modell geschrieben, und jede an ihrer Quelle geprüft.';

  @override
  String get introQuestionTitle => 'Eine Frage, dann die Antwort';

  @override
  String get introQuestionLine =>
      'Jede Karte trägt den einen Satz, der es wert ist, laut gesagt zu werden.';

  @override
  String get introMixTitle => 'Du wählst den Mix';

  @override
  String get introMixLine =>
      'Dreh ein Fach runter, um weniger davon zu sehen, oder ganz aus.';

  @override
  String get introThirtyTitle => 'Zwei Minuten am Tag';

  @override
  String get introThirtyLine =>
      'Eine Benachrichtigung, fünf Karten und eine Serie, die du nicht reißen lassen willst.';

  @override
  String introNotifyWhen(String time) {
    return 'Morgen, $time';
  }

  @override
  String get introNotifyLine => 'Deine fünf sind bereit. Tag 1.';

  @override
  String get introOneOfFive => '1 VON 5';

  @override
  String get introDayOne => 'TAG 1';

  @override
  String get introTapTomorrow => 'MORGEN TIPPEN UND ERFAHREN';

  @override
  String get introDayOneTomorrow => 'TAG 1 · MORGEN';

  @override
  String get introDaySevenStreak => 'TAG 7 · ERSTE SERIE';

  @override
  String get continueWithApple => 'Weiter mit Apple';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get continueWithEmail => 'Weiter mit E-Mail';

  @override
  String get termsLine =>
      'Mit der Registrierung akzeptierst du unsere Nutzungsbedingungen und Datenschutzerklärung';

  @override
  String get skip => 'Überspringen';

  @override
  String get tapToRevealLower => 'tippen zum Aufdecken';

  @override
  String get barMoveCaps => 'ZUM MITNEHMEN';

  @override
  String get theBarMoveCaps => 'DER SATZ FÜR DIE BAR';

  @override
  String get widgetFootPlain => 'Fünf Karten, zwei Minuten.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage in Serie',
      one: '1 Tag in Serie',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Für heute erledigt';

  @override
  String get widgetStreakStart =>
      'Lies die fünf von heute, um eine Serie zu starten.';

  @override
  String get widgetFiveTitle => 'DIE FÜNF VON HEUTE';

  @override
  String widgetFiveRead(int n) {
    return '$n von 5 gelesen';
  }

  @override
  String get widgetFiveDone => 'Alle fünf gelesen';

  @override
  String get widgetFiveWaiting => 'Fünf neue Karten warten';

  @override
  String get widgetShelfTitle => 'DAS REGAL VON HEUTE';

  @override
  String get widgetShelfFrom => 'Aus dem Regal von heute';

  @override
  String get dayStreakCaps => 'TAGE IN SERIE';

  @override
  String sourceLabel(String source) {
    return 'Quelle · $source';
  }

  @override
  String get perkArchiveTitle => 'Dein ganzes Archiv';

  @override
  String get perkArchiveLine => 'Jeder gelesene Tag, für immer.';

  @override
  String get plusIsActive => 'ASTUTE+ IST AKTIV';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days Tage gratis, dann $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Abonnieren für $price$suffix';
  }

  @override
  String get noChargeTodayCancel => 'Heute keine Abbuchung · jederzeit kündbar';

  @override
  String get chargedTodayCancel => 'Heute abgebucht · jederzeit kündbar';

  @override
  String get everyCardForYouMark => 'dich';

  @override
  String get trialStartedNoPayment =>
      'Test gestartet. In dieser Version ist keine Zahlung angebunden.';

  @override
  String get thatDidNotGoThrough => 'Das hat nicht geklappt.';

  @override
  String get plusIsBack => 'Astute+ ist zurück.';

  @override
  String get nothingToRestore => 'Nichts zum Wiederherstellen in diesem Konto.';

  @override
  String get planYearly => 'Jährlich';

  @override
  String get planMonthly => 'Monatlich';

  @override
  String get perYearShort => '/Jahr';

  @override
  String get perMonthShort => '/Monat';

  @override
  String get perYear => 'pro Jahr';

  @override
  String aMonth(String price) {
    return '$price im Monat';
  }

  @override
  String savePercent(int n) {
    return 'SPARE $n %';
  }

  @override
  String get perMonth => 'pro Monat';

  @override
  String get billedMonthly => 'monatliche Abrechnung';

  @override
  String get cancelTheTrial => 'Test abbrechen';

  @override
  String get cancelAnyTime => 'Jederzeit kündbar';

  @override
  String get cancelAnyTimeNoPayment =>
      'Jederzeit kündbar · In dieser Version wird nichts abgebucht';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get termsOfUse => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutz';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Wähl eine Seite. Es gibt keine richtige Antwort.';

  @override
  String get estimateCloseEnough => 'Schätze. Nah dran zählt.';

  @override
  String get tapToReveal => 'Tippen zum Aufdecken';

  @override
  String closeEnoughItIs(String answer) {
    return 'Nah dran · es ist $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Du sagtest $given · es ist $answer, und $band zählt';
  }

  @override
  String get youGotIt => 'Richtig';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Du sagtest $given · es ist $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Fast alle liegen hier falsch';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · du sagtest $pct % sicher';
  }

  @override
  String get giveMeANudge => 'Gib mir einen Schubs';

  @override
  String get beingRightMattersLess =>
      'Recht zu haben zählt weniger als zu wissen, wie oft du es hast.';

  @override
  String get writeItBeforeTheirs => 'Schreib es auf, bevor du ihres liest.';

  @override
  String get youAnsweredThisOne => 'Die hast du schon beantwortet.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Leicht',
      'medium': 'Mittel',
      'hard': 'Schwer',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · leg dich fest, bevor du sie umdrehst.';
  }

  @override
  String get yourAnswer => 'Deine Antwort';

  @override
  String get checkMyAnswer => 'Meine Antwort prüfen';

  @override
  String get howSureAreYou => 'Wie sicher bist du?';

  @override
  String percentSure(int n) {
    return '$n Prozent sicher';
  }

  @override
  String get inOneLineWhy => 'In einer Zeile — warum?';

  @override
  String get because => 'Weil…';

  @override
  String get nowShowMeTheOtherSide => 'Jetzt zeig mir die andere Seite';

  @override
  String get skipShowMeAnyway => 'Überspringen — trotzdem zeigen';

  @override
  String get youTookCaps => 'DU HAST GEWÄHLT';

  @override
  String get putSimplyCaps => 'EINFACH GESAGT';

  @override
  String get explainLikeImThree => 'Erklär es mir wie einem Kind';

  @override
  String get whatTheOtherSideSaysCaps => 'WAS DIE ANDERE SEITE SAGT';

  @override
  String get whatTheOtherSideSays => 'Was die andere Seite sagt';

  @override
  String theTrap(String trap) {
    return 'Die Falle: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Du hast die Seite gewählt: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' mit $n % Sicherheit';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Die hattest du richtig$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Du sagtest $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Wischen für die nächste';

  @override
  String get thatWasTheOnlyOne => 'Das war die einzige';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Die Karte konnte nicht gezeichnet werden.';

  @override
  String get textCopiedInstead => 'Stattdessen wurde der Text kopiert.';

  @override
  String get copiedToClipboard => 'In die Zwischenablage kopiert.';

  @override
  String get rendering => 'Wird gezeichnet…';

  @override
  String get theSourceGoesWithIt => 'Die Quelle geht mit';

  @override
  String get fiveADayALittleSharper => 'Fünf am Tag. Ein bisschen schärfer.';

  @override
  String get shareMyDay => 'Teilen';

  @override
  String climbedTo(String rung) {
    return 'Heute hat dich auf $rung gebracht';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right von $asked richtig';
  }

  @override
  String saidSure(int sure) {
    return '$sure % sicher';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n Karten, die du vor Tagen beantwortet hast, sind wieder da: Sitzen die Antworten noch?',
      one: 'Eine Karte, die du vor Tagen beantwortet hast, ist wieder da: Sitzt die Antwort noch?',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Weißt du es noch?';

  @override
  String get holdACardYouLike => 'Gefällt sie? Halten';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n heute gemocht',
      one: '1 heute gemocht',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Gemocht';

  @override
  String likedN(int n) {
    return 'Gemocht · $n';
  }

  @override
  String get nothingLikedYet => 'Noch nichts gemocht';

  @override
  String get likeThisPill => 'Diese Karte mögen';

  @override
  String get removeFromLiked => 'Aus Gemocht entfernen';

  @override
  String get removedFromLiked => 'Aus Gemocht entfernt.';

  @override
  String get lessLikeThis => 'Weniger davon';

  @override
  String get whatYouLikedLandsHere => 'Die, die du nochmal lesen würdest';

  @override
  String get holdToLikeLandsHere =>
      'Halte eine Karte, die dir gefällt, und sie landet hier — und die App gibt dir mehr davon.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Tippe auf das Lesezeichen einer Karte und sie landet hier — die, die dein Denken verändert haben, behalten.';

  @override
  String get nudgeTitle => 'Deine fünf sind bereit';

  @override
  String get nudgeFreezeTitle => 'Dein Freeze hält';

  @override
  String nudgeFreezeBody(String question) {
    return 'Gestern ist gedeckt. Heute: $question';
  }

  @override
  String get nudgeSureTitle => 'Bei dieser warst du sicher';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — du hast $sure % gesagt.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Vor zwei Wochen hattest du $read Karten gelesen';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Deine Sicherheit lag $gap Punkte daneben. Heute: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return 'Bisher $answered beantwortet. Heute: $question';
  }

  @override
  String get friends => 'Freunde';

  @override
  String friendsN(int n) {
    return 'Freunde · $n';
  }

  @override
  String get yourFriendCode => 'Dein Freundescode';

  @override
  String get codeCopied => 'Code kopiert.';

  @override
  String get addAFriend => 'Freund hinzufügen';

  @override
  String get theirCode => 'Sein Code';

  @override
  String get add => 'Hinzufügen';

  @override
  String get noFriendsYet =>
      'Noch niemand. Tausch Codes mit einem Freund und vergleicht Serien und Kalibrierung — nie Antworten.';

  @override
  String get friendsNeedAnAccount =>
      'Vergleichen braucht die Telefon-App und ein Konto. Deine Codes bleiben.';

  @override
  String get noReaderWithCode => 'Kein Leser mit diesem Code.';

  @override
  String get thatsYourOwnCode => 'Das ist dein eigener Code.';

  @override
  String pointsOff(int n) {
    return '$n Punkte daneben';
  }

  @override
  String get notMeasuredYet => 'noch nicht gemessen';

  @override
  String get thisWeekByCalibration => 'Diese Woche, nach Kalibrierung';

  @override
  String get notYetToday => 'heute noch nicht';

  @override
  String nOfSeven(int n) {
    return '$n von 7';
  }

  @override
  String get you => 'Du';

  @override
  String get todaysQuestion => 'Die Frage des Tages';

  @override
  String get right => 'richtig';

  @override
  String get wrong => 'falsch';

  @override
  String rightAtSure(int sure) {
    return 'richtig, $sure % sicher';
  }

  @override
  String wrongAtSure(int sure) {
    return 'falsch, $sure % sicher';
  }

  @override
  String get yourJourney => 'Deine Reise';

  @override
  String get thePath => 'Der Weg';

  @override
  String get youAreHere => 'DU BIST HIER';

  @override
  String reachedOn(String date) {
    return 'Erreicht am $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n von $of bisher gelesen';
  }

  @override
  String nRead(int n) {
    return '$n gelesen';
  }

  @override
  String get topLevel => 'Höchste Stufe';

  @override
  String plusNToday(int n) {
    return '+$n heute';
  }

  @override
  String get bySubject => 'Nach Fach';

  @override
  String get pts => 'Punkte';

  @override
  String nStillWithYou(int n) {
    return '$n noch da';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Muster',
      one: '1 Muster',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday =>
      'Dein Punktestand beginnt mit den fünf von heute.';

  @override
  String get anonymousUsage => 'Nutzungsdaten';

  @override
  String get anonymousUsageLine =>
      'Wie die App genutzt wird – was gelesen, behalten und gesagt wird und was schiefgeht –, damit die nächsten Karten besser sind. Nie dein Name, deine E-Mail oder was du schreibst.';

  @override
  String get usageOn => 'Geteilt, ohne deinen Namen und deine Worte.';

  @override
  String get usageOff => 'Es wird nichts mehr gemessen.';

  @override
  String get yourMix => 'Dein Mix';

  @override
  String get genresLine =>
      'Tippe ein Genre an, um es zu überspringen. Halte es, und die drei Stränge darin öffnen sich direkt darunter.';

  @override
  String get insideGenre => 'Darin';

  @override
  String nOfSixOn(int n, int total) {
    return '$n von $total an';
  }

  @override
  String get offInYourMix => 'nicht in deinem Mix';

  @override
  String continueGenresOn(int on, int total) {
    return 'Weiter · $on von $total Genres an';
  }

  @override
  String get mixRarely => 'Selten';

  @override
  String get mixSometimes => 'Manchmal';

  @override
  String get mixOften => 'Oft';

  @override
  String get mixALot => 'Viel';

  @override
  String get mixFull => 'Voll';

  @override
  String get forYouChip => 'FÜR DICH';

  @override
  String get againChip => 'NOCHMAL';

  @override
  String get magicLine =>
      'Fünf Karten am Tag, für dich gewählt: aus deinem Mix, auf deinem Niveau, nie eine schon gelesene. Ab morgen.';

  @override
  String get everyCardForYou => 'Jede Karte, für dich gewählt.';

  @override
  String get perkOwnTitle => 'Fünf Karten am Tag, alle deine';

  @override
  String get perkOwnLine =>
      'Aus deinen Strängen, auf deinem Niveau, nie eine schon gelesene. Gratis sind es zwei am Tag.';

  @override
  String get plusCardHeadline => 'Alle fünf, deine.';

  @override
  String get plusCardLine =>
      'Fünf Karten am Tag aus deinem Mix, auf deinem Niveau. Deine Reise. Dein ganzes Archiv.';

  @override
  String get continueFree => 'Gratis weiter';

  @override
  String get archiveBeforeThisWeek => 'Vor dieser Woche';

  @override
  String get weekKeptThreeOwn =>
      'Eine Woche gehalten: morgen sind drei der fünf deine.';

  @override
  String get perkJourneyLine =>
      'Dein Niveau, jedes Fach Strang für Strang, was blieb, und die Züge, die du immer wieder verpasst.';

  @override
  String get topOfTheWeek => 'Top der Woche';

  @override
  String get topOfTheMonth => 'Top des Monats';

  @override
  String topIn(String subject) {
    return 'Top in $subject';
  }

  @override
  String get topLineWeek =>
      'Am meisten gemocht, behalten und erzählt in den letzten 7 Tagen';

  @override
  String get topLineMonth =>
      'Am meisten gemocht, behalten und erzählt in den letzten 30 Tagen';

  @override
  String get topWeek => 'Woche';

  @override
  String get topMonth => 'Monat';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Leser',
      one: '1 Leser',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Noch nichts auf der Liste. Jede Karte, die du magst, behältst oder erzählst, zählt.';

  @override
  String get readMark => 'Gelesen';

  @override
  String get lovedSinceTheStart => 'Seit Beginn am meisten geliebt';

  @override
  String lovedIn(String subject) {
    return 'Am meisten geliebt in $subject';
  }

  @override
  String get lovedLine =>
      'Was Leser am häufigsten behalten haben und du noch nicht gelesen hast';

  @override
  String get forYouShelf => 'Für dich';

  @override
  String get forYouLine => 'Was dein Lesen nach vorn stellt';

  @override
  String get exploreOffline =>
      'Du bist offline. Das ist Entdecken, wie es zuletzt gelesen wurde.';

  @override
  String get askYourselfCaps => 'FRAG DICH';

  @override
  String get themeMyths => 'Mythen entlarvt';

  @override
  String get themeMythsLine => 'Was fast alle glauben, und warum es falsch ist';

  @override
  String get themeParadoxes => 'Paradoxe';

  @override
  String get themeParadoxesLine =>
      'Zwei wahre Dinge, die nicht beide wahr sein dürften';

  @override
  String get themeNumbers => 'Zahlen, die überraschen';

  @override
  String get themeNumbersLine => 'Wo die Zahl die Wendung ist';

  @override
  String get themePractical => 'Heute anwenden';

  @override
  String get themePracticalLine =>
      'Etwas zum Ausprobieren oder zum Weitererzählen, noch vor heute Abend';

  @override
  String get themeOrigins => 'Woher es kommt';

  @override
  String get themeOriginsLine => 'Die Anfänge von Dingen, die du täglich nutzt';

  @override
  String get themeStories => 'Wahre Geschichten';

  @override
  String get themeStoriesLine => 'Dinge, die wirklich passiert sind';

  @override
  String get themeDebates => 'Wähle eine Seite';

  @override
  String get themeDebatesLine =>
      'Keine richtige Antwort, nur ein besseres Argument';

  @override
  String get themeWorkItOut => 'Rechne es aus';

  @override
  String get themeWorkItOutLine =>
      'Schätz die Zahl, bevor die Karte sie dir verrät';

  @override
  String get themeSeen => 'Zum Ansehen';

  @override
  String get themeSeenLine => 'Karten, die ihren Punkt zeichnen';

  @override
  String get themeSharpest => 'Für die Schärfsten';

  @override
  String get themeSharpestLine => 'Die schwierigsten Karten, die es gibt';

  @override
  String get themePast0 => 'Die Antike';

  @override
  String get themePast1 => '17. bis 19. Jahrhundert';

  @override
  String get themePast2 => 'Das letzte Jahrhundert';

  @override
  String get themePastLine => 'Jedes Mal eine andere Epoche';

  @override
  String get themePlace0 => 'Asien und Naher Osten';

  @override
  String get themePlace1 => 'Amerika';

  @override
  String get themePlace2 => 'Europa';

  @override
  String get themePlaceLine => 'Jedes Mal ein anderer Teil der Welt';

  @override
  String get themeTrueOrFalse => 'Wahr oder falsch?';

  @override
  String get themeTrueOrFalseLine =>
      'Entscheide vor dem Umdrehen. Die meisten liegen falsch';

  @override
  String get themeReasoning => 'Nur Denken';

  @override
  String get themeReasoningLine =>
      'Nichts zum Auswendiglernen: nur ein Weg, es zu durchdenken';

  @override
  String get themeIdeas => 'Große Ideen';

  @override
  String get themeIdeasLine =>
      'Die Theorie hinter den Dingen, eine Idee nach der anderen';

  @override
  String get themeCurious => 'Einfach neugierig';

  @override
  String get themeCuriousLine => 'Aus Freude am Warum';

  @override
  String get themeMoving => 'In Bewegung';

  @override
  String get themeMovingLine => 'Was sich gerade ändert, und warum es zählt';

  @override
  String get themeHowItWorks => 'Wie es wirklich funktioniert';

  @override
  String get themeHowItWorksLine =>
      'Der Mechanismus hinter etwas, das du jeden Tag siehst';

  @override
  String get themePuzzles => 'Knobeln';

  @override
  String get themePuzzlesLine => 'Rätsel für einen Stift und eine Minute';

  @override
  String get weekRecapCaps => 'DIESE WOCHE HAST DU DICH GEFRAGT';

  @override
  String get weekRecapLine =>
      'Die Fragen, die deine Karten dir hinterlassen haben';

  @override
  String weekRecapMore(int n) {
    return '$n weitere aus deiner Woche mit Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ gibt es in der App: Lade Astute auf iPhone oder Android und starte deine kostenlose Testphase.';

  @override
  String get purchaseComplete => 'Kauf abgeschlossen.';

  @override
  String get successWelcome =>
      'Willkommen bei Astute+. Die fünf Karten von heute sind bereit.';

  @override
  String successWelcomeNamed(String name) {
    return 'Willkommen bei Astute+, $name. Die fünf Karten von heute sind bereit.';
  }

  @override
  String get successFiveCards => '5 Karten am Tag';

  @override
  String get successArchive => 'Ganzes Archiv';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Gratis bis $date, dann $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Verlängert sich am $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Beleg';

  @override
  String get letsStart => 'Los geht’s';

  @override
  String successFootFirstCharge(String date) {
    return 'Erste Abbuchung am $date · jederzeit kündbar';
  }

  @override
  String successFootRenews(String date) {
    return 'Verlängert sich am $date · jederzeit kündbar';
  }

  @override
  String get tryToday => 'HEUTE AUSPROBIEREN';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'oder';

  @override
  String get nextStep => 'Nächster Schritt';

  @override
  String get showAllSteps => 'Alle zeigen';

  @override
  String get revealSeePicture => 'Bild ansehen';

  @override
  String get revealPlayScene => 'Selbst ausprobieren';

  @override
  String get revealBackToAnswer => 'Zurück zur Antwort';

  @override
  String get revealShowWorking => 'Rechenweg zeigen';

  @override
  String get sceneLockIn => 'FESTLEGEN';

  @override
  String get sceneYou => 'DU';

  @override
  String get sceneTruth => 'WAHRHEIT';

  @override
  String get sceneTryAgain => 'Nochmal';

  @override
  String get sceneDrawHint => 'Zeichne deine Vermutung mit dem Finger';

  @override
  String get sceneHoldHint => 'Gedrückt halten';

  @override
  String get sceneSwipeHint => 'Wischen oder tippen';

  @override
  String get sceneTapToPick => 'Tippe deine Wahl';

  @override
  String get sceneShowMe => 'Zeig es mir';

  @override
  String get sceneYourGuess => 'Deine Vermutung';

  @override
  String sceneNOfM(int n, int m) {
    return '$n von $m';
  }

  @override
  String get reportProblem => 'Problem melden';

  @override
  String get reportedThanks => 'Gemeldet. Danke.';

  @override
  String get reportTitle => 'Was stimmt mit dieser Karte nicht?';

  @override
  String get reportLead =>
      'Wir prüfen jede Meldung anhand der Quellen und korrigieren die Karte.';

  @override
  String get reportFact => 'Ein Fakt ist falsch';

  @override
  String get reportAnswer => 'Die als richtig markierte Antwort ist falsch';

  @override
  String get reportSource => 'Die Quelle belegt es nicht';

  @override
  String get reportUnclear => 'Es ist unverständlich';

  @override
  String get reportTypo => 'Ein Tippfehler oder eine kaputte Zeile';

  @override
  String get reportOther => 'Etwas anderes';

  @override
  String get reportNoteHint => 'Alles, was uns beim Prüfen hilft (optional)';

  @override
  String get reportSend => 'Senden';

  @override
  String get reportSentToast => 'Danke. Wir prüfen es.';

  @override
  String get journeyPointsOff => 'Punkte daneben';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Noch $n Antworten mit Sicherheit, dann wird es gemessen.',
      one: 'Noch eine Antwort mit Sicherheit, dann wird es gemessen.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Dein Punktestand';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Punkte',
      one: 'Punkt',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n in 4 Wochen';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Diese Woche hast du bisher $n Punkte gesammelt.',
      one: 'Diese Woche hast du bisher 1 Punkt gesammelt.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In der Woche vom $date hast du $n Punkte gesammelt.',
      one: 'In der Woche vom $date hast du 1 Punkt gesammelt.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten',
      one: '1 Karte',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Dein Punktestand am Ende jeder Woche seit dem $date. Tippe auf einen Punkt, um diese Woche zu sehen.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Stufe $n von $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\nbis $rung';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten',
      one: '1 Karte',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Antworten',
      one: '1 Antwort',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Antworten mit Sicherheit',
      one: '1 Antwort mit Sicherheit',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Karten behalten',
      one: '1 Karte behalten',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Punkte',
      one: '1 Punkt',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Gegenwert';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Sachbücher',
      one: '1 Sachbuch',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'oder $h Std Dokus';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'noch $n bis zum ersten Sachbuch',
      one: 'noch 1 bis zum ersten Sachbuch',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Am Stück';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Rekord $best · $active von $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n von $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'Fächern · gestrichelt: $month';
  }

  @override
  String get journeySubjects => 'Fächern';

  @override
  String get journeyHowHard => 'Wie schwer';

  @override
  String get journeyOfThree => 'von 3';

  @override
  String get journeyHardNow => 'Die Karten, die du öffnest.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Die Karten, die du öffnest. $v im $month';
  }

  @override
  String get journeyReadingTime => 'Lesezeit';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h Std $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m Min';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now Min pro Woche, anfangs $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m Min diese Woche';
  }

  @override
  String get journeyTimedFromToday => 'Gezählt ab heute';

  @override
  String journeyPointsOffFrom(int was) {
    return 'Punkte daneben, anfangs $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · max. $n';
  }

  @override
  String get journeyRightWhenSure => 'Richtig, wenn sicher';

  @override
  String journeyFromIn(String v, String month) {
    return 'Im $month waren es $v';
  }

  @override
  String get journeySureNone => 'Noch keine Antwort mit 80 % oder mehr';

  @override
  String get journeyMovesTitle => 'Erkannte Muster';

  @override
  String journeyOfN(int n) {
    return 'von $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Neuestes: $name';
  }

  @override
  String get journeyNoneYet => 'Noch keine';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Karten noch da',
      one: 'Karte noch da',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: 'einem Tag',
    );
    return '$right von $of nach $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks Wochen',
      one: 'einer Woche',
    );
    return '$right von $of nach $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
    );
    return '$active von $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Meist morgens';

  @override
  String get journeyMostlyAfternoon => 'Meist nachmittags';

  @override
  String get journeyMostlyEvening => 'Meist abends';

  @override
  String get journeyMostlyNight => 'Meist nachts';

  @override
  String get journeyInTime => 'Durch die Zeit';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString Jahre';
  }

  @override
  String journeyFromEra(String era) {
    return 'seit $era';
  }

  @override
  String get journeyEraAncient => 'der Antike';

  @override
  String get journeyEraMedieval => 'dem Mittelalter';

  @override
  String get journeyEraEarlyModern => 'dem 16. Jahrhundert';

  @override
  String get journeyEraNineteenth => 'dem 19. Jahrhundert';

  @override
  String get journeyEraTwentieth => 'dem 20. Jahrhundert';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'noch nichts mit Datum';

  @override
  String get journeyInPlace => 'Rund um die Welt';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Regionen',
      one: '1 Region',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list und das All';
  }

  @override
  String get journeyRegionAmericas => 'Amerika';

  @override
  String get journeyRegionEurope => 'Europa';

  @override
  String get journeyRegionAsia => 'Asien';

  @override
  String get journeyRegionOceania => 'Ozeanien';

  @override
  String get journeyRegionAfrica => 'Afrika';

  @override
  String get journeyRegionMiddleEast => 'Nahost';

  @override
  String get journeyNoPlace => 'noch kein Ort';

  @override
  String get journeyTopics => 'Themen';

  @override
  String journeyMet(int n) {
    return '$n entdeckt';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n davon in $subject';
  }

  @override
  String get journeyWords => 'Begriffe';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n neue',
      one: '1 neuer',
    );
    return '$_temp0';
  }

  @override
  String get anotherOne => 'Noch eine';

  @override
  String answerIs(String said) {
    return 'Antwort: $said';
  }

  @override
  String get answeredAlready => 'Schon beantwortet';

  @override
  String get anyCard => 'Jedes Fach, jedes Regal, eine Karte';

  @override
  String betN(int n) {
    return '$n setzen';
  }

  @override
  String get betWord => 'Setzen';

  @override
  String get biggerLabel => 'Größer';

  @override
  String get biggerYouGotIt => 'Größer · richtig';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nach $n Tagen',
      one: 'Nach einem Tag',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Nach einer Woche';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Nach $n Wochen',
      one: 'Nach einer Woche',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Prüfen';

  @override
  String closerDone(String said, int right, int steps) {
    return 'Es sind $said. $right von $steps richtig.';
  }

  @override
  String closerNoLess(String v) {
    return 'Nein: weniger als $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'Nein: mehr als $v.';
  }

  @override
  String get closerStart => 'Drei Schritte, um es einzukreisen.';

  @override
  String closerYesLess(String v) {
    return 'Richtig: weniger als $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Richtig: mehr als $v.';
  }

  @override
  String get corrections => 'Berichtigungen';

  @override
  String get didYouKnow => 'Wusstest du\'s?';

  @override
  String get didYouKnowLine =>
      'Dreh sie um, dann: neu für dich, oder wusstest du\'s?';

  @override
  String get dragToSet => 'Zum Einstellen ziehen';

  @override
  String get dykAgain => 'Nochmal';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kanntest du',
      one: '1 kanntest du',
      zero: 'Keine kanntest du',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n neu für dich',
      one: '1 neu für dich',
      zero: 'Heute nichts Neues',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'Das war die heutige Ausgabe';

  @override
  String get editionTomorrow => 'Die von morgen erscheint am Morgen';

  @override
  String get eraAncient => 'Die Antike';

  @override
  String get eraAncientWhen => 'Vor 500';

  @override
  String get eraEarlyModern => 'Die Frühe Neuzeit';

  @override
  String get eraEarlyModernWhen => '1500 bis 1800';

  @override
  String get eraMedieval => 'Das Mittelalter';

  @override
  String get eraMedievalWhen => '500 bis 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weitere aus dieser Zeit',
      one: '1 weitere aus dieser Zeit',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'Das 19. Jahrhundert';

  @override
  String get eraNineteenthWhen => '1800 bis 1900';

  @override
  String get eraRecent => 'Dieses Jahrhundert';

  @override
  String get eraRecentWhen => 'Seit 2000';

  @override
  String get eraRulerNow => 'Heute';

  @override
  String get eraRulerOld => 'Antike';

  @override
  String get eraShortAncient => 'Antike';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Mittelalter';

  @override
  String get eraShortNineteenth => '1800er';

  @override
  String get eraShortRecent => '2000er';

  @override
  String get eraShortTwentieth => '1900er';

  @override
  String get eraTwentieth => 'Das letzte Jahrhundert';

  @override
  String get eraTwentiethWhen => '1900 bis 2000';

  @override
  String get fewCards => 'In ein paar Karten';

  @override
  String get fewCardsLine => 'Wenn eine Karte nicht reicht, um es zu erklären';

  @override
  String get firstLabel => 'Seit';

  @override
  String get forYouNow => 'Für dich, jetzt';

  @override
  String get hardBadge => 'Schwer';

  @override
  String hidesIn(String where) {
    return 'In $where';
  }

  @override
  String get howSure => 'Wie sicher bin ich, und warum?';

  @override
  String get inNumbers => 'In Zahlen';

  @override
  String inRange(int pts, String said) {
    return 'Getroffen: +$pts Punkte. Es sind $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'In deinen Zügen · $n×';
  }

  @override
  String itIs(String said) {
    return 'Es sind $said.';
  }

  @override
  String get knewIt => 'Wusste ich';

  @override
  String get less => 'Weniger';

  @override
  String get lookFirst =>
      'Schau dir die Grafik an, bevor du der Schlagzeile glaubst.';

  @override
  String minutesLabel(int n) {
    return '$n Min.';
  }

  @override
  String missedRange(String said) {
    return 'Daneben: Es sind $said.';
  }

  @override
  String get modeBigger => 'Was ist größer?';

  @override
  String get modeCloser => 'Immer näher';

  @override
  String get modePick => 'Wähle eine';

  @override
  String get modeRange => 'Setz auf einen Bereich';

  @override
  String get modeSlide => 'Schieb es';

  @override
  String get modeStake => 'Platziere deinen Einsatz';

  @override
  String get monthShelfLine => 'Jeden Monat ein neues Fach, für alle gleich';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards Karten',
      one: '1 Karte',
    );
    return '$_temp0 · $minutes Min.';
  }

  @override
  String get moodTime => 'Deine Zeit';

  @override
  String get moodTitle => 'Deine Stimmung, deine Minuten';

  @override
  String get moodTone => 'Ton';

  @override
  String get more => 'Mehr';

  @override
  String moreOrLess(String v) {
    return 'Mehr oder weniger als $v?';
  }

  @override
  String get moveComparedToWhat => 'Verglichen womit?';

  @override
  String get moveComparedToWhatLine =>
      'Eine Veränderung sagt nichts ohne etwas, womit man sie vergleicht';

  @override
  String get askingTitle => 'Eine Frage aus jedem Fach';

  @override
  String askingIn(String subject) {
    return 'Fragen zu $subject';
  }

  @override
  String get askingLine => 'Für alle gleich. Erst antworten, dann das Warum';

  @override
  String get moveSampling => 'Wer wurde gezählt?';

  @override
  String get moveSamplingLine =>
      'Wer in einer Studie landet, bestimmt, was sie dir sagen kann';

  @override
  String mythDeckHint(int at, int of) {
    return '$at von $of · wischen zum Umdrehen';
  }

  @override
  String nOfM(int at, int of) {
    return '$at von $of';
  }

  @override
  String get newMove => 'Neu für dich';

  @override
  String get newToMe => 'Neu für mich';

  @override
  String get notEnoughPoints => 'Nicht genug Punkte';

  @override
  String get notSureLine => 'Eine Karte von irgendwo in Astute';

  @override
  String get notSureTitle => 'Weißt du nicht, wo du anfangen sollst?';

  @override
  String get openWord => 'Öffnen';

  @override
  String get pickOneFirst => 'Erst eine wählen';

  @override
  String get puzzleOfTheDay => 'Das Rätsel des Tages';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts P.';
  }

  @override
  String get rightLastTime => 'Letztes Mal richtig';

  @override
  String get sameForEveryoneCaps => 'Für alle gleich';

  @override
  String get sayFalse => 'Falsch';

  @override
  String get sayTrue => 'Wahr';

  @override
  String get seriesAnchors => 'Erste Eindrücke';

  @override
  String get seriesGrowth => 'Zahlen, die davonlaufen';

  @override
  String seriesMeta(int n, int m) {
    return '$n Karten · etwa $m Min.';
  }

  @override
  String get seriesOdds => 'Wahrscheinlichkeiten, die lügen';

  @override
  String get seriesRetold => 'Geschichte, neu erzählt';

  @override
  String seriesStrand(String name) {
    return '$name, in ein paar Karten';
  }

  @override
  String get seriesStudies => 'Warum Studien täuschen';

  @override
  String showAllN(int n) {
    return 'Alle $n zeigen';
  }

  @override
  String get showFewer => 'Weniger zeigen';

  @override
  String get sixtyAgain => 'Nochmal spielen';

  @override
  String sixtyIn(int s) {
    return 'in $s Sekunden';
  }

  @override
  String get sixtyLine => 'Acht Mal wahr oder falsch. Hör auf dein Bauchgefühl';

  @override
  String get sixtyPerfect => 'Alle acht richtig.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Bisher $n richtig',
      one: 'Bisher 1 richtig',
      zero: 'Noch keine richtig',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'Sekunden für acht\nMal wahr oder falsch';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Los';

  @override
  String get sixtyTimeUp => 'bevor die Zeit ablief';

  @override
  String get sixtyTitle => 'Sechzig Sekunden';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Punkte daneben.',
      one: '1 Punkt daneben.',
      zero: 'Genau getroffen.',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => 'Einsatz';

  @override
  String stepOf(int at, int of) {
    return 'Schritt $at von $of';
  }

  @override
  String get surpriseMe => 'Überrasch mich';

  @override
  String get tapIfBigger => 'Tippen, wenn größer';

  @override
  String get tapToTurn => 'Tippen zum Umdrehen';

  @override
  String get tfRight => 'Richtig. Öffne sie für das Warum.';

  @override
  String tfWrong(String side) {
    return 'Es ist $side. Öffne sie für das Warum.';
  }

  @override
  String theAnswer(String said) {
    return 'Die Antwort: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Aufmacher';

  @override
  String get throughTime => 'Durch die Zeit';

  @override
  String get throughTimeLine =>
      'Von der Antike bis heute. Zieh, oder tipp ein Jahr';

  @override
  String leanHint(String or) {
    return 'Schieb das „$or“ dorthin, wo du stehst';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'ein wenig',
      '2': 'alles in allem',
      '3': 'entschieden',
      'other': 'voll und ganz',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Du hast $side gewählt';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Öffne sie für die Gegenseite.';
  }

  @override
  String get spotTitle => 'Finde die falsche';

  @override
  String get spotLine => 'Drei sind wahr. Eine nicht.';

  @override
  String get spotPrompt => 'Tippe auf die, die du für falsch hältst';

  @override
  String get spotConfirm => 'Das ist die falsche';

  @override
  String get spotFound => 'Gefunden. Die anderen drei sind wahr.';

  @override
  String get spotMissed =>
      'Nicht diese: Sie ist wahr. Die falsche ist durchgestrichen.';

  @override
  String get spotWhy => 'Tippe auf eine, um zu lesen, warum';

  @override
  String get spotYours => 'Deine Wahl';

  @override
  String get yearHint => 'Gib ein Jahr ein';

  @override
  String get yearAd => 'n. Chr.';

  @override
  String get yearBc => 'v. Chr.';

  @override
  String yearNamed(String year) {
    return '$year';
  }

  @override
  String yearAdOf(String year) {
    return '$year n. Chr.';
  }

  @override
  String yearBcOf(String year) {
    return '$year v. Chr.';
  }

  @override
  String get yearGo => 'Zu diesem Jahr';

  @override
  String yearNearest(String year) {
    return 'Am nächsten an $year zuerst';
  }

  @override
  String yearNoneNamed(String year) {
    return 'Keine Karte hier nennt ein Jahr nahe $year. Diese sind aus seiner Epoche.';
  }

  @override
  String yearNoAge(String year) {
    return 'Heute nichts aus der Zeit um $year. Das ist die nächste Epoche.';
  }

  @override
  String yearFuture(String year) {
    return '$year kommt erst noch. Hier ist dieses Jahrhundert.';
  }

  @override
  String get yearZero =>
      'Ein Jahr 0 gab es nicht. Versuch 1 v. Chr. oder 1 n. Chr.';

  @override
  String get todayLabel => 'Heute';

  @override
  String get todaysEdition => 'Heutige Ausgabe';

  @override
  String get toneCurious => 'Neugierig';

  @override
  String get toneLight => 'Leicht';

  @override
  String get toneSerious => 'Ernst';

  @override
  String get toneTough => 'Knifflig';

  @override
  String get unmaskBack => 'Wie veröffentlicht zeigen';

  @override
  String get unmaskFlipped => 'Richtig herum drehen';

  @override
  String get unmaskLine => 'Gleiche Zahlen, anderes Bild';

  @override
  String get unmaskStretched => 'Faire Skala nehmen';

  @override
  String get unmaskTitle => 'Entlarve die Grafik';

  @override
  String get unmaskTotals => 'Den Vergleich fair machen';

  @override
  String get unmaskTruncated => 'Achse bei null beginnen';

  @override
  String get unmaskWindow => 'Ganze Reihe zeigen';

  @override
  String get whatIfTrue => 'Und wenn es stimmt?';

  @override
  String get whatIfTrueLine => 'Karten, die weiterwirken, wenn du sie schließt';

  @override
  String get whatYouBelieve => 'Was du glaubst';

  @override
  String get wrongLastTime => 'Letztes Mal falsch';

  @override
  String youLose(int n) {
    return 'Du verlierst $n.';
  }

  @override
  String youWin(int n) {
    return 'Du gewinnst $n.';
  }

  @override
  String get yourPick => 'Deine Wahl';
}
