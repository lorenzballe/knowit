// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
  String get holdACardToKeepIt =>
      'Halte eine Karte gedrückt, um sie zu behalten';

  @override
  String keptToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n heute behalten',
      one: '1 heute behalten',
    );
    return '$_temp0';
  }

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
    return 'DIE $word VON HEUTE · WISCHEN ZUM WIEDERHOLEN';
  }

  @override
  String weekLine(int days) {
    return 'Deine Woche · $days von 7 geschafft';
  }

  @override
  String get tapToFlip => 'TIPPEN ZUM UMDREHEN';

  @override
  String get shareThisCard => 'Diese Karte teilen';

  @override
  String get removeFromSaved => 'Aus Behalten entfernen';

  @override
  String get saveThisPill => 'Diese Pille behalten';

  @override
  String get shareThisPill => 'Diese Pille teilen';

  @override
  String cardOf(int k, int n) {
    return 'Karte $k von $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h h $m min';
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
  String get fiveMore => 'Fünf mehr';

  @override
  String get unlockFiveExtra => 'Fünf zusätzliche Pillen freischalten';

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
  String get onesThatAskTheMost => 'Die, die am meisten fragen';

  @override
  String get acrossEveryone => 'Bei allen, nicht nur in deinem Mix';

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
  String get noPillsMatchFilter => 'Noch keine Pille passt zu diesem Filter.';

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
  String get tapTheHeartLandsHere =>
      'Tippe auf das Herz einer Pille und sie landet hier — die, die dein Denken verändert haben, behalten.';

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
      'Serie, behaltene Pillen und Bilanz bleiben in deinem Konto. Das hier löscht sie von diesem Gerät.';

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
      'Löscht alles auf diesem Gerät — Serie, behaltene Pillen, Antworten, deine Urteilsbilanz, Fächer und Tarif — und öffnet die Einführung neu.';

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
      'Deine 5 Pillen, vor dem ersten Kaffee.';

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
      'Anstoß an, aber das System hat abgelehnt. Schalte Benachrichtigungen für Astut in den Einstellungen ein.';

  @override
  String get nudgeOnNeedsPhone =>
      'Anstoß an. Die Zustellung braucht die Handy-Version.';

  @override
  String get howMuchYouKnow => 'Wie viel du weißt';

  @override
  String savedN(int n) {
    return 'Behalten · $n';
  }

  @override
  String get manageSubscription => 'Abo verwalten';

  @override
  String get howPillsAreWritten => 'Wie Pillen geschrieben werden';

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
  String get seeEveryPrincipleWithPlus => 'Jedes Prinzip sehen, mit Astut plus';

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
      'Die Messung läuft. Astut+ zeigt dir, in welche Richtung.';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 Tage gratis';

  @override
  String get watchTheGapMove => 'Sieh zu, wie sich die Lücke bewegt.';

  @override
  String get measurementFreeForever =>
      'Die Messung ist gratis und bleibt es. Astut+ sagt dir, in welche Richtung sie geht.';

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
      other: 'Pillen gelesen',
      one: 'Pille gelesen',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Pillen gelesen',
      one: '1 Pille gelesen',
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
  String get streakReset => 'Serie zurückgesetzt';

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
      other: '$n Pillen blieben ungelesen',
      one: '1 Pille blieb ungelesen',
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
  String get whatYouAlready => 'Was du schon ';

  @override
  String get know => 'weißt';

  @override
  String get knowIntro =>
      'Die Fächer, die du am höchsten gedreht hast. Es ändert, was ein Tag in jedem von dir verlangt — solide bekommt Fragen, neugierig bekommt Erklärungen — nicht, wie viel du davon bekommst.';

  @override
  String get startWithMyFirstCards => 'Mit meinen ersten Karten starten';

  @override
  String get skipForNow => 'Vorerst überspringen';

  @override
  String get levelCurious => 'Neugierig';

  @override
  String get levelSome => 'Etwas';

  @override
  String get levelSolid => 'Solide';

  @override
  String get save => 'Speichern';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n von $total Fächern im Mix';
  }

  @override
  String get yourSpace => 'Dein ';

  @override
  String get mix => 'Mix';

  @override
  String get everythingIsInDrag =>
      'Alles ist drin. Zieh ein Fach nach unten, um weniger davon zu sehen, oder bis auf null, um es zu streichen.';

  @override
  String get next => 'Weiter';

  @override
  String get whatShouldWeTalkAbout => 'Worüber reden wir?';

  @override
  String get fivePillsADayPick =>
      'Fünf Pillen am Tag, jeden Morgen frisch geschrieben. Wähl die Fächer für deinen Mix — du kannst sie später ändern.';

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
  String get introTopicsTitle => 'Zwölf Fächer, fünf Pillen';

  @override
  String get introTopicsLine =>
      'Jeden Morgen frisch geschrieben und an einer Quelle geprüft.';

  @override
  String get introQuestionTitle => 'Eine Frage, dann die Antwort';

  @override
  String get introQuestionLine =>
      'Jede Pille trägt den einen Satz, der es wert ist, laut gesagt zu werden.';

  @override
  String get introMixTitle => 'Du wählst den Mix';

  @override
  String get introMixLine =>
      'Dreh ein Fach runter, um weniger davon zu sehen, oder ganz aus.';

  @override
  String get introThirtyTitle => 'Dreißig Sekunden am Tag';

  @override
  String get introThirtyLine =>
      'Eine Benachrichtigung, fünf Karten und eine Serie, die du nicht reißen lassen willst.';

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
  String get barMoveCaps => 'DER SATZ FÜR DIE BAR';

  @override
  String get theBarMoveCaps => 'DER SATZ FÜR DIE BAR';

  @override
  String get dayStreakCaps => 'TAGE IN SERIE';

  @override
  String sourceLabel(String source) {
    return 'Quelle · $source';
  }

  @override
  String get perkRecordTitle => 'Deine Bilanz über die Zeit';

  @override
  String get perkRecordLine =>
      'Ob sich die Lücke zwischen deiner Sicherheit und deiner Trefferquote wirklich schließt.';

  @override
  String get perkPrinciplesTitle => 'Jedes Prinzip, dem du begegnet bist';

  @override
  String get perkPrinciplesLine =>
      'Nicht nur die drei, bei denen du am schwächsten bist — alle, und die Kontexte, die du noch nicht gesehen hast.';

  @override
  String get perkFreezesTitle => 'Drei Serien-Freezes statt einem';

  @override
  String get perkFreezesLine =>
      'Genug für ein Wochenende weg. Eine Serie, die man nur verlieren kann, geht irgendwann verloren.';

  @override
  String get perkExtraTitle => '5 zusätzliche Pillen jeden Tag';

  @override
  String get perkExtraLine =>
      'Ein zweiter Satz schaltet sich frei, sobald du den ersten beendest.';

  @override
  String get perkArchiveTitle => 'Das ganze Archiv';

  @override
  String get perkArchiveLine =>
      'Jede Pille, die du je gelesen hast, nach Fach durchsuchbar.';

  @override
  String get perkTopicsTitle => 'Wähl deine eigenen Fächer';

  @override
  String get perkTopicsLine =>
      'Gewichte den Mix zu dem, was dich wirklich interessiert.';

  @override
  String get plusIsActive => 'ASTUT+ IST AKTIV';

  @override
  String tryFreeThen(String price, String suffix) {
    return '7 Tage gratis testen, dann $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Test gestartet. In dieser Version ist keine Zahlung angebunden.';

  @override
  String get thatDidNotGoThrough => 'Das hat nicht geklappt.';

  @override
  String get plusIsBack => 'Astut+ ist zurück.';

  @override
  String get nothingToRestore => 'Nichts zum Wiederherstellen in diesem Konto.';

  @override
  String get findOutIfBetter => 'Finde heraus, ob du wirklich besser wirst.';

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
  String get everythingOpensNothingCharged =>
      'Alles öffnet sich. Nichts wird abgebucht.';

  @override
  String dayN(int n) {
    return 'TAG $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Eine Erinnerung, zwei Tage vor der Verlängerung.';

  @override
  String get itRenewsUnlessCancelled =>
      'Es verlängert sich, außer du hast gekündigt. Das geht jederzeit.';

  @override
  String get howTheFreeWeekWorks => 'SO FUNKTIONIERT DIE GRATIS-WOCHE';

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
}
