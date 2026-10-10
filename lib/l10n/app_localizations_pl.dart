// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => 'Dziś';

  @override
  String get tabExplore => 'Odkrywaj';

  @override
  String get tabProfile => 'Profil';

  @override
  String signInNotConnected(String provider) {
    return 'Logowanie przez $provider nie jest jeszcze podłączone. Twoje karty zostają na tym urządzeniu.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Nie udało się zalogować przez $label. Możesz działać dalej bez konta.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dni',
      many: '$n dni',
      few: '$n dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Zamrożenie uratowało serię';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'jedna',
      '2': 'dwie',
      '3': 'trzy',
      '4': 'cztery',
      '5': 'pięć',
      '6': 'sześć',
      '7': 'siedem',
      '8': 'osiem',
      '9': 'dziewięć',
      '10': 'dziesięć',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Dzień $n · $word przeczytane';
  }

  @override
  String shelfEyebrow(String word) {
    return 'DZISIEJSZE $word';
  }

  @override
  String get tapToFlip => 'DOTKNIJ, BY ODWRÓCIĆ';

  @override
  String get shareThisCard => 'Udostępnij tę kartę';

  @override
  String get removeFromSaved => 'Usuń z zachowanych';

  @override
  String get saveThisPill => 'Zachowaj tę kartę';

  @override
  String get shareThisPill => 'Udostępnij tę kartę';

  @override
  String cardOf(int k, int n) {
    return 'Karta $k z $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Jutrzejsza piątka otworzy się za $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic otwiera jutrzejszą piątkę, za $when';
  }

  @override
  String get exploreTodaysBest => 'Odkryj to, co dziś najlepsze';

  @override
  String magicUnlock(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      one: '$days dzień',
    );
    return 'Wypróbuj $_temp0 za darmo';
  }

  @override
  String get getPlus => 'Przejdź na Astute+';

  @override
  String nothingInYet(String subject) {
    return 'W $subject jeszcze nic nie ma.';
  }

  @override
  String get here => 'tej sekcji';

  @override
  String get todaysShelf => 'Dzisiejsza półka';

  @override
  String get sameForEveryone => 'Ta sama dla wszystkich, i tylko dziś';

  @override
  String becauseSitsAtFull(String name) {
    return 'Bo $name jest na maksimum';
  }

  @override
  String get olderFromTurnedUp => 'Starsze karty z tematów, które podkręciłeś';

  @override
  String moreOn(String name) {
    return 'Więcej o $name';
  }

  @override
  String get subjectReadMost => 'Temat, o którym czytałeś najwięcej';

  @override
  String monthOf(String name) {
    return 'Miesiąc z $name';
  }

  @override
  String get somewhereToStart => 'Punkt startu, który nie jest dzisiaj';

  @override
  String get searchEveryCard => 'Szukaj we wszystkich kartach';

  @override
  String nothingForYet(String query) {
    return 'Jeszcze nic dla „$query”.';
  }

  @override
  String matching(int n) {
    return '$n pasujących';
  }

  @override
  String get all => 'Wszystkie';

  @override
  String get theArchive => 'Archiwum';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n wyników',
      many: '$n wyników',
      few: '$n wyniki',
      one: '1 wynik',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n kart. Dotknij dnia, żeby go otworzyć.';
  }

  @override
  String get whatYouHaveCovered => 'Co już masz za sobą';

  @override
  String searchNCards(int n) {
    return 'Szukaj wśród $n kart';
  }

  @override
  String get cancel => 'Anuluj';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
      many: '$n kart',
      few: '$n karty',
      one: '1 karta',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get noPillsMatchFilter =>
      'Żadna karta nie pasuje jeszcze do tego filtra.';

  @override
  String nothingForTryTopic(String query) {
    return 'Nic dla „$query”. Spróbuj tematu.';
  }

  @override
  String get saved => 'Zachowane';

  @override
  String get removedFromSaved => 'Usunięto z zachowanych.';

  @override
  String get undo => 'Cofnij';

  @override
  String get nothingKeptYet => 'Jeszcze nic nie zachowano';

  @override
  String nInTopic(int n, String topic) {
    return '$n w $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Zachowuj te, których naprawdę użyjesz';

  @override
  String get backToTodaysFive => 'WRÓĆ DO DZISIEJSZEJ PIĄTKI';

  @override
  String get archive => 'Archiwum';

  @override
  String get yourWeek => 'Twój tydzień';

  @override
  String get nothingThisWeekYet =>
      'W tym tygodniu jeszcze nic. Pięć kart go zaczyna.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Zaliczony — $days dni z siedmiu.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni z siedmiu.',
      many: '$days dni z siedmiu.',
      few: '$days dni z siedmiu.',
      one: '1 dzień z siedmiu.',
    );
    return '$_temp0 Pięć zalicza tydzień.';
  }

  @override
  String get howSureAgainstHowRight => 'Jak pewnie, kontra jak trafnie';

  @override
  String get sureAndWrong => 'Pewnie, i błędnie';

  @override
  String get worthGoingBackTo =>
      'Te, do których warto wrócić. Pomylić się w czymś, czego byłeś pewien, to jedyny tani sposób, by odkryć, w co naprawdę wierzysz.';

  @override
  String get whereThisIsGoing => 'Dokąd to zmierza';

  @override
  String ofNRight(int n) {
    return 'z $n trafnych';
  }

  @override
  String get sayHowSureOnMore =>
      'Powiedz przy kilku kolejnych, jak bardzo jesteś pewien, a aplikacja powie ci, ile ta pewność jest warta.';

  @override
  String confidenceOff(int gap) {
    return 'Twoja pewność była o $gap punktów od tego, co naprawdę wiedziałeś.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Twoja pewność rozminęła się o $gap punktów, wobec $before w zeszłym tygodniu. Luka się domyka.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Twoja pewność rozminęła się o $gap punktów, wobec $before w zeszłym tygodniu. Luka się otworzyła.';
  }

  @override
  String nextRung(String name) {
    return 'Następnie: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Powiedziałeś $n% pewności';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Dzień pierwszy',
      'reading': 'Czytanie',
      'answering': 'Odpowiadanie',
      'saying_how_sure': 'Nazywanie pewności',
      'calibrated': 'Skalibrowany',
      'holding': 'Utrzymywanie',
      'sharp': 'Bystry',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Każdy zaczyna tutaj.',
      'reading': 'Nawyk się zaczął.',
      'answering': 'Deklarujesz się, zanim odwrócisz kartę.',
      'saying_how_sure': 'Nadajesz liczbę temu, co myślisz, że wiesz.',
      'calibrated': 'To, co mówisz, że wiesz, wiesz.',
      'holding': 'Zostaje z tobą tygodnie później.',
      'sharp': 'Pewny, gdy trzeba, i trafny, gdy jesteś.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'jeszcze $n kart do przeczytania';
  }

  @override
  String stepAnswer(int n) {
    return 'jeszcze $n kart do odpowiedzi';
  }

  @override
  String stepJudge(int n) {
    return 'jeszcze $n odpowiedzi z twoją pewnością';
  }

  @override
  String stepHold(int n) {
    return 'jeszcze $n kart do utrzymania';
  }

  @override
  String stepGap(int gap, int target) {
    return 'twoja pewność rozmija się o $gap punktów — wystarczy $target';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'jeszcze $n odpowiedzi, zanim aplikacja oceni twoją pewność';
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
  String get signOutQuestion => 'Wylogować się?';

  @override
  String get signOutBody =>
      'Twoja seria, zachowane karty i historia zostają na koncie. To usuwa je z tego urządzenia.';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deletingAccount => 'Usuwanie konta…';

  @override
  String get deleteAccountQuestion => 'Usunąć konto?';

  @override
  String get deleteAccountBody =>
      'Twoje konto, jego kopia zapasowa i tablica widoczna dla znajomych zostaną usunięte na zawsze, a to urządzenie zacznie od początku. Nie anuluje to Astute+: subskrypcją zarządzasz w ustawieniach App Store.';

  @override
  String get deleteAccountConfirm => 'Usuń na zawsze';

  @override
  String get accountDeleted => 'Twoje konto zostało usunięte.';

  @override
  String get couldNotDeleteAccount =>
      'Nie udało się usunąć konta. Spróbuj ponownie za chwilę.';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get signedInRecordOnAccount =>
      'Zalogowano. Twoja seria i historia są teraz na koncie.';

  @override
  String couldNotSignInWith(String label) {
    return 'Nie udało się zalogować przez $label.';
  }

  @override
  String get signInNotAvailableBuild =>
      'Logowanie nie jest dostępne w tej wersji.';

  @override
  String get startOverQuestion => 'Zacząć od nowa?';

  @override
  String get startOverBody =>
      'Usuwa wszystko z tego urządzenia — serię, zachowane karty, odpowiedzi, historię ocen, tematy i plan — i otwiera wprowadzenie od nowa.';

  @override
  String get wipeIt => 'Usuń';

  @override
  String get yourRecord => 'Twoja historia';

  @override
  String get appearance => 'Wygląd';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get yourTopics => 'Twoje tematy';

  @override
  String get edit => 'Edytuj';

  @override
  String get howWellYouKnowYourself => 'Jak dobrze znasz siebie';

  @override
  String get journeyButtonLine =>
      'Twój poziom, ruchy, które wciąż ci umykają, twój tydzień w pytaniach';

  @override
  String get isTheGapClosing => 'Czy luka się domyka?';

  @override
  String get movesYouKeepMissing => 'Ruchy, które wciąż ci umykają';

  @override
  String get dailyNudge => 'Codzienne przypomnienie';

  @override
  String everyDayAt(String time) {
    return 'Codziennie o $time';
  }

  @override
  String get yourFivePillsBeforeCoffee => 'Twoje 5 kart, przed pierwszą kawą.';

  @override
  String get browserOnlySpeaksOpen =>
      'Przeglądarka mówi tylko wtedy, gdy jest otwarta, więc to wymaga wersji na telefon.';

  @override
  String get nudgeOff => 'Przypomnienie wyłączone.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Przypomnienie włączone, codziennie o $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Przypomnienie włączone, ale system odmówił. Włącz powiadomienia dla Astute w ustawieniach.';

  @override
  String get nudgeOnNeedsPhone =>
      'Przypomnienie włączone. Dostarczenie wymaga wersji na telefon.';

  @override
  String savedN(int n) {
    return 'Zachowane · $n';
  }

  @override
  String get manageSubscription => 'Zarządzaj subskrypcją';

  @override
  String get howPillsAreWritten => 'Jak powstają karty';

  @override
  String get howTitle => 'Każdą kartę tutaj pisze model AI.';

  @override
  String get howIntro =>
      'Wolimy powiedzieć to od razu, niż żebyś sam to odkrył. Oto jak karta do ciebie trafia.';

  @override
  String get howStep1Title => 'Napisana wcześniej, przez model';

  @override
  String get howStep1Line =>
      'Każda karta powstaje według jednego zadania: pytanie warte zadania, odpowiedź, która mówi dlaczego, i jeden ruch do ponownego użycia.';

  @override
  String get howStep2Title => 'Sprawdzona ze źródłem';

  @override
  String get howStep2Line =>
      'Każda karta podaje, skąd pochodzi, a drugi model czyta ją jako krytyk, zanim się ukaże. To, czego nie da się poprzeć, wylatuje.';

  @override
  String get howStep3Title => 'Pięć, rozdawanych co rano';

  @override
  String get howStep3Line =>
      'Z tematów, które wybrałeś, i nigdy taka, którą już czytałeś.';

  @override
  String get howStep4Title => 'Czytelnicy pilnują uczciwości';

  @override
  String get howStep4Line =>
      'Gdy wystarczająco wielu czytelników uzna kartę za błędną, przestaje być rozdawana, dopóki nie sprawdzi jej człowiek.';

  @override
  String get howReportTitle => 'Znalazłeś błąd?';

  @override
  String get howReportLine =>
      'Dotknij flagi obok źródła karty, aby ją zgłosić.';

  @override
  String get howFoot => 'Źródła są sprawdzane ponownie co miesiąc.';

  @override
  String get signingIn => 'Logowanie…';

  @override
  String get signInWithApple => 'Zaloguj się przez Apple';

  @override
  String get signInWithGoogle => 'Zaloguj się przez Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'W $n odpowiedziach powiedziałeś, jak bardzo jesteś pewien. Oto, co z tego wyszło.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Idealnie skalibrowana osoba ma rację w 70% przypadków, gdy mówi 70%.';

  @override
  String get notEnoughAnswersYet => 'Jeszcze za mało odpowiedzi';

  @override
  String get confidenceMatchesAccuracy =>
      'Twoja pewność zgadza się z trafnością';

  @override
  String overconfidentBy(int points) {
    return 'Jesteś zbyt pewny o $points punktów';
  }

  @override
  String underconfidentBy(int points) {
    return 'Jesteś zbyt niepewny o $points punktów';
  }

  @override
  String saidPercent(int n) {
    return 'Powiedziano $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'trafnie $pct% ($right z $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jeszcze $n kontekstów przed tobą',
      many: 'jeszcze $n kontekstów przed tobą',
      few: 'jeszcze $n konteksty przed tobą',
      one: 'jeszcze 1 kontekst przed tobą',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Zobacz każdą zasadę z Astute plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jeszcze $n śledzonych',
      many: 'jeszcze $n śledzonych',
      few: 'jeszcze $n śledzone',
      one: 'jeszcze 1 śledzona',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'UDOSTĘPNIJ MOJĄ HISTORIĘ';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Twoje ostatnie $n ocen, kontra pierwsze $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Domknięta o $n punktów';
  }

  @override
  String openedByPoints(int n) {
    return 'Otwarta o $n punktów';
  }

  @override
  String get holdingSteady => 'Bez zmian';

  @override
  String get measurementRunningPlus =>
      'Pomiar trwa. Astute+ pokazuje ci, w którą stronę zmierza.';

  @override
  String firstN(int n) {
    return 'Pierwsze $n';
  }

  @override
  String lastN(int n) {
    return 'Ostatnie $n';
  }

  @override
  String get trackingMoreClosely =>
      'Twoja pewność podąża za trafnością bliżej niż wcześniej.';

  @override
  String get distanceHasGrown =>
      'Dystans urósł. Warto zwolnić, zanim się zadeklarujesz.';

  @override
  String get noRealMovementYet =>
      'Jeszcze bez prawdziwego ruchu. To trwa tygodnie, nie dni.';

  @override
  String get seeWhichWay => 'ZOBACZ, W KTÓRĄ STRONĘ';

  @override
  String get spotOn => 'w punkt';

  @override
  String pointsOver(int n) {
    return '$n za dużo';
  }

  @override
  String pointsUnder(int n) {
    return '$n za mało';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      one: '$days dzień',
    );
    return '$_temp0 za darmo';
  }

  @override
  String get seeThePlans => 'ZOBACZ PLANY';

  @override
  String get recordStartsToday => 'Twoja historia zaczyna się dziś.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dni',
      many: 'dni',
      few: 'dni',
      one: 'dzień',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'kart przeczytanych',
      many: 'kart przeczytanych',
      few: 'karty przeczytane',
      one: 'karta przeczytana',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart przeczytanych',
      many: '$n kart przeczytanych',
      few: '$n karty przeczytane',
      one: '1 karta przeczytana',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tygodni zaliczonych',
      many: '$n tygodni zaliczonych',
      few: '$n tygodnie zaliczone',
      one: '1 tydzień zaliczony',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n wraca';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n zamrożeń w zapasie',
      many: '$n zamrożeń w zapasie',
      few: '$n zamrożenia w zapasie',
      one: '1 zamrożenie w zapasie',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Plan darmowy';

  @override
  String get welcomeBack => 'Witaj z powrotem';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Opuściłeś\n$n dni.',
      many: 'Opuściłeś\n$n dni.',
      few: 'Opuściłeś\n$n dni.',
      one: 'Opuściłeś\njeden dzień.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dni to',
      many: '$n dni to',
      few: '$n dni to',
      one: 'Jeden dzień to',
    );
    return '$_temp0 wciąż twój rekord. Przeczytaj dzisiejszą piątkę, a licznik ruszy znów od jednego.';
  }

  @override
  String get whileYouWereAway => 'Gdy cię nie było';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart zostało nieprzeczytanych',
      many: '$n kart zostało nieprzeczytanych',
      few: '$n karty zostały nieprzeczytane',
      one: '1 karta została nieprzeczytana',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic to wciąż temat, który zachowujesz najczęściej';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart, które trafiłeś, wraca dziś',
      many: '$n kart, które trafiłeś, wraca dziś',
      few: '$n karty, które trafiłeś, wracają dziś',
      one: '1 karta, którą trafiłeś, wraca dziś',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Zacznij od nowa z dzisiejszą piątką';

  @override
  String moveMyReminderTo(String time) {
    return 'Przesuń przypomnienie na $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Codzienne przypomnienie przesunięte na $time.';
  }

  @override
  String get reminderAskTitle => 'O której mamy ci przypominać?';

  @override
  String get reminderAskLine =>
      'Jedno powiadomienie dziennie, z pytaniem z twoich kart.';

  @override
  String get reminderAskTrialLine =>
      'Przypomnimy ci dwa dni przed końcem okresu próbnego.';

  @override
  String get reminderAskMorning => 'Rano';

  @override
  String get reminderAskLunch => 'W południe';

  @override
  String get reminderAskEvening => 'Wieczorem';

  @override
  String get reminderAskOther => 'Inna godzina';

  @override
  String get reminderAskYes => 'Przypominaj mi';

  @override
  String get reminderAskNotNow => 'Nie teraz';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Twój okres próbny Astute+ kończy się za $days dni.',
      many: 'Twój okres próbny Astute+ kończy się za $days dni.',
      few: 'Twój okres próbny Astute+ kończy się za $days dni.',
      one: 'Twój okres próbny Astute+ kończy się jutro.',
      zero: 'Twój okres próbny Astute+ kończy się dzisiaj.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return '$date zaczyna się twój rok subskrypcji za $price. Żeby kontynuować, nie musisz nic robić. Żeby zrezygnować: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Okres próbny kończy się za $days dni',
      many: 'Okres próbny kończy się za $days dni',
      few: 'Okres próbny kończy się za $days dni',
      one: 'Okres próbny kończy się jutro',
      zero: 'Okres próbny kończy się dzisiaj',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Zarządzaj';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n z $total tematów w miksie';
  }

  @override
  String get everythingIsInDrag =>
      'Wszystko jest w środku. Przeciągnij temat w dół, żeby widzieć go mniej, albo do zera, żeby go wyrzucić.';

  @override
  String get next => 'Dalej';

  @override
  String get whatShouldWeTalkAbout => 'O czym rozmawiamy?';

  @override
  String get fivePillsADayPick =>
      'Pięć kart dziennie, co rano nowe. Wybierz tematy do miksu — możesz je później zmienić.';

  @override
  String nSelected(int n) {
    return '$n wybranych';
  }

  @override
  String startWithNTopics(int n) {
    return 'Zacznij z $n tematami';
  }

  @override
  String saveNTopics(int n) {
    return 'Zapisz $n tematów';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Wybierz co najmniej $n';
  }

  @override
  String get swipeToSeeMore => 'Przesuń, by zobaczyć więcej';

  @override
  String get tagline =>
      'Zrozum, dlaczego jest tak, a nie inaczej, i na ile ufać temu, co wiesz';

  @override
  String get introTopicsTitle => 'Dziewiętnaście tematów, pięć kart';

  @override
  String get introTopicsLine =>
      'Pisane wcześniej przez model, a każda podaje swoje źródło.';

  @override
  String get introQuestionTitle => 'Pytanie, pewność, potem dlaczego';

  @override
  String get introQuestionLine =>
      'Najpierw oceń swoją pewność. Z czasem zobaczysz, ile warte jest twoje „na pewno”.';

  @override
  String get introMixTitle => 'Ty wybierasz miks';

  @override
  String get introMixLine =>
      'Ścisz temat, żeby widzieć go mniej, albo wyłącz na dobre.';

  @override
  String get introThirtyTitle => 'Dwie minuty dziennie';

  @override
  String get introThirtyLine =>
      'Jedno powiadomienie, pięć kart i seria, której nie będziesz chciał przerwać.';

  @override
  String introNotifyWhen(String time) {
    return 'Jutro, $time';
  }

  @override
  String get introNotifyLine => 'Twoja piątka jest gotowa. Dzień 1.';

  @override
  String get introOneOfFive => '1 Z 5';

  @override
  String get introDayOne => 'DZIEŃ 1';

  @override
  String get introTapTomorrow => 'DOTKNIJ JUTRO, BY SIĘ DOWIEDZIEĆ';

  @override
  String get introDayOneTomorrow => 'DZIEŃ 1 · JUTRO';

  @override
  String get introDaySevenStreak => 'DZIEŃ 7 · PIERWSZA SERIA';

  @override
  String get continueWithApple => 'Kontynuuj z Apple';

  @override
  String get continueWithGoogle => 'Kontynuuj z Google';

  @override
  String get continueWithEmail => 'Kontynuuj z e-mailem';

  @override
  String get termsLine =>
      'Rejestrując się, akceptujesz nasz Regulamin i Politykę prywatności';

  @override
  String get skip => 'Pomiń';

  @override
  String get tapToRevealLower => 'dotknij, by odsłonić';

  @override
  String get barMoveCaps => 'DO ZAPAMIĘTANIA';

  @override
  String get theBarMoveCaps => 'ZDANIE NA IMPREZĘ';

  @override
  String get widgetFootPlain => 'Pięć kart, dwie minuty.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Seria: $n dni',
      many: 'Seria: $n dni',
      few: 'Seria: $n dni',
      one: 'Seria: 1 dzień',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Na dziś gotowe';

  @override
  String get widgetStreakStart =>
      'Przeczytaj dzisiejszą piątkę, by zacząć serię.';

  @override
  String get widgetFiveTitle => 'DZISIEJSZA PIĄTKA';

  @override
  String widgetFiveRead(int n) {
    return 'Przeczytane: $n z 5';
  }

  @override
  String get widgetFiveDone => 'Wszystkie pięć przeczytane';

  @override
  String get widgetFiveWaiting => 'Czeka nowa piątka';

  @override
  String get widgetShelfTitle => 'DZISIEJSZA PÓŁKA';

  @override
  String get widgetShelfFrom => 'Z dzisiejszej półki';

  @override
  String get dayStreakCaps => 'DNI SERII';

  @override
  String sourceLabel(String source) {
    return 'Źródło · $source';
  }

  @override
  String get perkArchiveTitle => 'Całe twoje archiwum';

  @override
  String get perkArchiveLine => 'Każdy przeczytany dzień, na zawsze.';

  @override
  String get plusIsActive => 'ASTUTE+ JEST AKTYWNY';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni',
      one: '$days dzień',
    );
    return '$_temp0 gratis, potem $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Subskrybuj za $price$suffix';
  }

  @override
  String get noChargeTodayCancel => 'Dziś bez opłat · anuluj, kiedy chcesz';

  @override
  String get chargedTodayCancel => 'Opłata dziś · anuluj, kiedy chcesz';

  @override
  String get everyCardForYouMark => 'ciebie.';

  @override
  String get trialStartedNoPayment =>
      'Okres próbny rozpoczęty. W tej wersji nie ma podłączonej płatności.';

  @override
  String get thatDidNotGoThrough => 'To się nie powiodło.';

  @override
  String get plusIsBack => 'Astute+ wrócił.';

  @override
  String get nothingToRestore => 'Nie ma nic do przywrócenia na tym koncie.';

  @override
  String get planYearly => 'Rocznie';

  @override
  String get planMonthly => 'Miesięcznie';

  @override
  String get perYearShort => '/rok';

  @override
  String get perMonthShort => '/mies.';

  @override
  String get perYear => 'rocznie';

  @override
  String aMonth(String price) {
    return '$price miesięcznie';
  }

  @override
  String savePercent(int n) {
    return 'OSZCZĘDŹ $n%';
  }

  @override
  String get perMonth => 'miesięcznie';

  @override
  String get billedMonthly => 'rozliczane co miesiąc';

  @override
  String get cancelTheTrial => 'Anuluj okres próbny';

  @override
  String get cancelAnyTime => 'Anuluj, kiedy chcesz';

  @override
  String get cancelAnyTimeNoPayment =>
      'Anuluj, kiedy chcesz · W tej wersji nic nie jest pobierane';

  @override
  String get restorePurchases => 'Przywróć zakupy';

  @override
  String get termsOfUse => 'Warunki';

  @override
  String get privacyPolicy => 'Prywatność';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Wybierz stronę. Nie ma dobrej odpowiedzi.';

  @override
  String get estimateCloseEnough => 'Oszacuj. Blisko też się liczy.';

  @override
  String get tapToReveal => 'Dotknij, by odsłonić';

  @override
  String closeEnoughItIs(String answer) {
    return 'Blisko · to $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Powiedziałeś $given · to $answer, i $band się liczy';
  }

  @override
  String get youGotIt => 'Trafione';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Powiedziałeś $given · to $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Prawie każdy się tu myli';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · powiedziałeś $pct% pewności';
  }

  @override
  String get giveMeANudge => 'Daj mi podpowiedź';

  @override
  String get beingRightMattersLess =>
      'Mieć rację znaczy mniej niż wiedzieć, jak często ją masz.';

  @override
  String get writeItBeforeTheirs => 'Zapisz to, zanim przeczytasz ich wersję.';

  @override
  String get youAnsweredThisOne => 'Na tę już odpowiedziałeś.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Łatwa',
      'medium': 'Średnia',
      'hard': 'Trudna',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · zadeklaruj się, zanim ją odwrócisz.';
  }

  @override
  String get yourAnswer => 'Odpowiedź';

  @override
  String get checkMyAnswer => 'Sprawdź moją odpowiedź';

  @override
  String get howSureAreYou => 'Jak bardzo jesteś pewien?';

  @override
  String percentSure(int n) {
    return '$n procent pewności';
  }

  @override
  String get inOneLineWhy => 'W jednym zdaniu — dlaczego?';

  @override
  String get because => 'Bo…';

  @override
  String get nowShowMeTheOtherSide => 'Teraz pokaż mi drugą stronę';

  @override
  String get skipShowMeAnyway => 'Pomiń — pokaż mimo to';

  @override
  String get youTookCaps => 'WYBRAŁEŚ';

  @override
  String get putSimplyCaps => 'NAJPROŚCIEJ';

  @override
  String get explainLikeImThree => 'Wytłumacz jak dziecku';

  @override
  String get whatTheOtherSideSaysCaps => 'CO MÓWI DRUGA STRONA';

  @override
  String get whatTheOtherSideSays => 'Co mówi druga strona';

  @override
  String theTrap(String trap) {
    return 'Pułapka: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Wybrałeś stronę: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' z $n% pewności';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Tę trafiłeś$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Powiedziałeś $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Przesuń po następną';

  @override
  String get thatWasTheOnlyOne => 'To była jedyna';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Nie udało się narysować karty.';

  @override
  String get textCopiedInstead => 'Zamiast tego skopiowano tekst.';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka.';

  @override
  String get rendering => 'Rysowanie…';

  @override
  String get theSourceGoesWithIt => 'Źródło idzie razem z nią';

  @override
  String get fiveADayALittleSharper => 'Pięć dziennie. Trochę bystrzej.';

  @override
  String get shareMyDay => 'Udostępnij';

  @override
  String climbedTo(String rung) {
    return 'Dziś wspiąłeś się na $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right z $asked dobrze';
  }

  @override
  String saidSure(int sure) {
    return 'pewność $sure%';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n karty sprzed kilku dni wracają: sprawdź, czy pamiętasz odpowiedzi',
      many: '$n kart sprzed kilku dni wraca: sprawdź, czy pamiętasz odpowiedzi',
      few:
          '$n karty sprzed kilku dni wracają: sprawdź, czy pamiętasz odpowiedzi',
      one: '1 karta sprzed kilku dni wraca: sprawdź, czy pamiętasz odpowiedź',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Pamiętasz jeszcze?';

  @override
  String get holdACardYouLike => 'Podoba się? Przytrzymaj';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n polubione dziś',
      many: '$n polubionych dziś',
      few: '$n polubione dziś',
      one: '1 polubiona dziś',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Polubione';

  @override
  String likedN(int n) {
    return 'Polubione · $n';
  }

  @override
  String get nothingLikedYet => 'Jeszcze nic polubionego';

  @override
  String get likeThisPill => 'Polub tę kartę';

  @override
  String get removeFromLiked => 'Usuń z polubionych';

  @override
  String get removedFromLiked => 'Usunięto z polubionych.';

  @override
  String get lessLikeThis => 'Mniej takich';

  @override
  String get whatYouLikedLandsHere => 'Te, które przeczytasz ponownie';

  @override
  String get holdToLikeLandsHere =>
      'Przytrzymaj kartę, która ci się podoba, a trafi tutaj — a aplikacja da ci więcej takich.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Dotknij zakładki na karcie, a trafi tutaj — te, które zmieniły twoje myślenie, zachowane.';

  @override
  String get nudgeTitle => 'Twoja piątka jest gotowa';

  @override
  String get nudgeFreezeTitle => 'Twoje zamrożenie trzyma';

  @override
  String nudgeFreezeBody(String question) {
    return 'Wczoraj jest pokryte. Dziś: $question';
  }

  @override
  String get nudgeSureTitle => 'Tej byłeś pewien';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — powiedziałeś $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Dwa tygodnie temu miałeś przeczytane $read kart';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Twoja pewność była o $gap punktów obok. Dziś: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return 'Dotąd $answered odpowiedzi. Dziś: $question';
  }

  @override
  String get friends => 'Znajomi';

  @override
  String friendsN(int n) {
    return 'Znajomi · $n';
  }

  @override
  String get yourFriendCode => 'Twój kod znajomego';

  @override
  String get codeCopied => 'Kod skopiowany.';

  @override
  String get addAFriend => 'Dodaj znajomego';

  @override
  String get theirCode => 'Jego kod';

  @override
  String get add => 'Dodaj';

  @override
  String get noFriendsYet =>
      'Jeszcze nikogo. Wymień się kodem ze znajomym i porównujcie serie i kalibrację — nigdy odpowiedzi.';

  @override
  String get friendsNeedAnAccount =>
      'Porównywanie wymaga aplikacji na telefonie i konta. Twoje kody zostają.';

  @override
  String get noReaderWithCode => 'Brak czytelnika z tym kodem.';

  @override
  String get thatsYourOwnCode => 'To twój własny kod.';

  @override
  String pointsOff(int n) {
    return '$n punktów obok';
  }

  @override
  String get notMeasuredYet => 'jeszcze nie zmierzona';

  @override
  String get thisWeekByCalibration => 'W tym tygodniu, według kalibracji';

  @override
  String get notYetToday => 'dziś jeszcze nie';

  @override
  String nOfSeven(int n) {
    return '$n z 7';
  }

  @override
  String get you => 'Ty';

  @override
  String get todaysQuestion => 'Pytanie dnia';

  @override
  String get right => 'dobrze';

  @override
  String get wrong => 'źle';

  @override
  String rightAtSure(int sure) {
    return 'dobrze, pewność $sure%';
  }

  @override
  String wrongAtSure(int sure) {
    return 'źle, pewność $sure%';
  }

  @override
  String get yourJourney => 'Twoja podróż';

  @override
  String get thePath => 'Ścieżka';

  @override
  String get youAreHere => 'JESTEŚ TUTAJ';

  @override
  String reachedOn(String date) {
    return 'Osiągnięto $date';
  }

  @override
  String readSoFar(int n, int of) {
    return 'Dotąd $n z $of przeczytanych';
  }

  @override
  String nRead(int n) {
    return '$n przeczytanych';
  }

  @override
  String get topLevel => 'Najwyższy poziom';

  @override
  String plusNToday(int n) {
    return '+$n dziś';
  }

  @override
  String get bySubject => 'Według dziedziny';

  @override
  String get pts => 'punktów';

  @override
  String nStillWithYou(int n) {
    return '$n wciąż z tobą';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n chwytu',
      many: '$n chwytów',
      few: '$n chwyty',
      one: '1 chwyt',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday =>
      'Twój wynik zaczyna się od dzisiejszej piątki.';

  @override
  String get anonymousUsage => 'Dane o użyciu';

  @override
  String get anonymousUsageLine =>
      'Jak używana jest aplikacja — co zostaje przeczytane, zachowane i powiedziane, i co nie działa — żeby następne karty były lepsze. Nigdy twoje imię, e-mail ani to, co piszesz.';

  @override
  String get usageOn => 'Udostępniane, bez twojego imienia i twoich słów.';

  @override
  String get usageOff => 'Nic już nie jest mierzone.';

  @override
  String get yourMix => 'Twój miks';

  @override
  String get genresLine =>
      'Dotknij gatunku, żeby go pominąć. Przytrzymaj, a trzy nurty w środku otworzą się tuż pod nim.';

  @override
  String get insideGenre => 'W środku';

  @override
  String nOfSixOn(int n, int total) {
    return '$n z $total włączonych';
  }

  @override
  String get offInYourMix => 'poza twoim miksem';

  @override
  String continueGenresOn(int on, int total) {
    return 'Dalej · $on z $total gatunków włączonych';
  }

  @override
  String get mixRarely => 'Rzadko';

  @override
  String get mixSometimes => 'Czasem';

  @override
  String get mixOften => 'Często';

  @override
  String get mixALot => 'Dużo';

  @override
  String get mixFull => 'Maksymalnie';

  @override
  String get forYouChip => 'DLA CIEBIE';

  @override
  String get againChip => 'ZNOWU';

  @override
  String get magicLine =>
      'Pięć kart dziennie wybranych dla ciebie: z twojego miksu, na twoim poziomie, nigdy już przeczytana. Od jutra.';

  @override
  String get everyCardForYou => 'Każda karta wybrana dla ciebie.';

  @override
  String get perkOwnTitle => 'Pięć kart dziennie, wszystkie twoje';

  @override
  String get perkOwnLine =>
      'Z twoich wątków, na twoim poziomie, nigdy już przeczytana. Za darmo masz dwie dziennie.';

  @override
  String get plusCardHeadline => 'Wszystkie pięć, twoje.';

  @override
  String get plusCardLine =>
      'Pięć kart dziennie z twojego miksu, na twoim poziomie. Twoja podróż. Całe twoje archiwum.';

  @override
  String get continueFree => 'Kontynuuj za darmo';

  @override
  String get archiveBeforeThisWeek => 'Sprzed tego tygodnia';

  @override
  String get weekKeptThreeOwn =>
      'Tydzień z rzędu: jutro trzy z pięciu są twoje.';

  @override
  String get perkJourneyLine =>
      'Twój poziom, każdy temat wątek po wątku, co zostało, i ruchy, które wciąż ci umykają.';

  @override
  String get topOfTheWeek => 'Top tygodnia';

  @override
  String get topOfTheMonth => 'Top miesiąca';

  @override
  String topIn(String subject) {
    return 'Top: $subject';
  }

  @override
  String get topLineWeek =>
      'Najczęściej lubiane, zachowane i opowiadane w ostatnich 7 dniach';

  @override
  String get topLineMonth =>
      'Najczęściej lubiane, zachowane i opowiadane w ostatnich 30 dniach';

  @override
  String get topWeek => 'Tydzień';

  @override
  String get topMonth => 'Miesiąc';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n czytelnika',
      many: '$n czytelników',
      few: '$n czytelnicy',
      one: '1 czytelnik',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Na liście jeszcze nic nie ma. Liczy się każda karta, którą polubisz, zachowasz lub opowiesz.';

  @override
  String get readMark => 'Przeczytana';

  @override
  String get lovedSinceTheStart => 'Najbardziej lubiane od początku';

  @override
  String lovedIn(String subject) {
    return 'Najbardziej lubiane: $subject';
  }

  @override
  String get lovedLine =>
      'To, co czytelnicy zachowywali najczęściej, a ty jeszcze nie czytałeś';

  @override
  String get forYouShelf => 'Dla ciebie';

  @override
  String get forYouLine => 'To, co twoje czytanie stawia na pierwszym miejscu';

  @override
  String get exploreOffline =>
      'Jesteś offline. To Odkrywaj w wersji z ostatniego odczytu.';

  @override
  String get askYourselfCaps => 'ZAPYTAJ SIEBIE';

  @override
  String get themeMyths => 'Obalone mity';

  @override
  String get themeMythsLine => 'W co wierzy prawie każdy i dlaczego to błąd';

  @override
  String get themeParadoxes => 'Paradoksy';

  @override
  String get themeParadoxesLine =>
      'Dwie prawdy, które nie powinny być prawdziwe naraz';

  @override
  String get themeNumbers => 'Liczby, które zaskakują';

  @override
  String get themeNumbersLine => 'Gdzie zwrotem akcji jest liczba';

  @override
  String get themePractical => 'Na dziś';

  @override
  String get themePracticalLine =>
      'Coś do wypróbowania albo do wtrącenia w rozmowie, jeszcze przed wieczorem';

  @override
  String get themeOrigins => 'Skąd się wzięło';

  @override
  String get themeOriginsLine => 'Początki rzeczy, których używasz codziennie';

  @override
  String get themeStories => 'Prawdziwe historie';

  @override
  String get themeStoriesLine => 'Rzeczy, które naprawdę się wydarzyły';

  @override
  String get themeDebates => 'Wybierz stronę';

  @override
  String get themeDebatesLine =>
      'Nie ma dobrej odpowiedzi, jest tylko lepszy argument';

  @override
  String get themeWorkItOut => 'Policz to';

  @override
  String get themeWorkItOutLine => 'Zgadnij liczbę, zanim zdradzi ją karta';

  @override
  String get themeSeen => 'Do obejrzenia';

  @override
  String get themeSeenLine => 'Karty, które rysują swój sens';

  @override
  String get themeSharpest => 'Dla najbystrzejszych';

  @override
  String get themeSharpestLine => 'Najtrudniejsze karty, jakie są';

  @override
  String get themePast0 => 'Świat starożytny';

  @override
  String get themePast1 => 'Od XVII do XIX wieku';

  @override
  String get themePast2 => 'Ubiegłe stulecie';

  @override
  String get themePastLine => 'Za każdym razem inna epoka';

  @override
  String get themePlace0 => 'Azja i Bliski Wschód';

  @override
  String get themePlace1 => 'Ameryki';

  @override
  String get themePlace2 => 'Europa';

  @override
  String get themePlaceLine => 'Za każdym razem inna część świata';

  @override
  String get themeTrueOrFalse => 'Prawda czy fałsz?';

  @override
  String get themeTrueOrFalseLine =>
      'Zdecyduj, zanim odwrócisz. Większość się myli';

  @override
  String get themeReasoning => 'Samo rozumowanie';

  @override
  String get themeReasoningLine =>
      'Nic do zapamiętania: tylko sposób, by to przemyśleć';

  @override
  String get themeIdeas => 'Wielkie idee';

  @override
  String get themeIdeasLine => 'Teoria stojąca za rzeczami, jedna idea naraz';

  @override
  String get themeCurious => 'Z czystej ciekawości';

  @override
  String get themeCuriousLine => 'Dla przyjemności poznania dlaczego';

  @override
  String get themeMoving => 'W ruchu';

  @override
  String get themeMovingLine => 'Co zmienia się teraz i dlaczego to ważne';

  @override
  String get themeHowItWorks => 'Jak to naprawdę działa';

  @override
  String get themeHowItWorksLine => 'Mechanizm za czymś, co widzisz codziennie';

  @override
  String get themePuzzles => 'Łamigłówki';

  @override
  String get themePuzzlesLine => 'Zagadki na długopis i minutę';

  @override
  String get weekRecapCaps => 'W TYM TYGODNIU ZAPYTAŁEŚ SIEBIE';

  @override
  String get weekRecapLine => 'Pytania, które zostawiły ci twoje karty';

  @override
  String weekRecapMore(int n) {
    return 'Jeszcze $n z twojego tygodnia z Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ jest w aplikacji: pobierz Astute na iPhone\'a lub Androida, aby zacząć darmowy okres próbny.';

  @override
  String get purchaseComplete => 'Zakup zakończony.';

  @override
  String get successWelcome =>
      'Witaj w Astute+. Dzisiejsze pięć kart jest gotowe.';

  @override
  String successWelcomeNamed(String name) {
    return 'Witaj w Astute+, $name. Dzisiejsze pięć kart jest gotowe.';
  }

  @override
  String get successFiveCards => '5 kart dziennie';

  @override
  String get successArchive => 'Całe archiwum';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Za darmo do $date, potem $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Odnawia się $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Paragon';

  @override
  String get letsStart => 'Zaczynajmy';

  @override
  String successFootFirstCharge(String date) {
    return 'Pierwsza płatność $date · anuluj w każdej chwili';
  }

  @override
  String successFootRenews(String date) {
    return 'Odnawia się $date · anuluj w każdej chwili';
  }

  @override
  String get tryToday => 'WYPRÓBUJ DZIŚ';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'czy';

  @override
  String get nextStep => 'Następny krok';

  @override
  String get showAllSteps => 'Pokaż wszystko';

  @override
  String get revealSeePicture => 'Zobacz rysunek';

  @override
  String get revealPlayScene => 'Wypróbuj sam';

  @override
  String get revealBackToAnswer => 'Wróć do odpowiedzi';

  @override
  String get revealShowWorking => 'Pokaż tok rozumowania';

  @override
  String get sceneLockIn => 'ZATWIERDŹ';

  @override
  String get sceneYou => 'TY';

  @override
  String get sceneTruth => 'PRAWDA';

  @override
  String get sceneTryAgain => 'Jeszcze raz';

  @override
  String get sceneDrawHint => 'Narysuj palcem, jak myślisz';

  @override
  String get sceneHoldHint => 'Przytrzymaj';

  @override
  String get sceneSwipeHint => 'Przesuń lub dotknij';

  @override
  String get sceneTapToPick => 'Dotknij swój wybór';

  @override
  String get sceneShowMe => 'Pokaż';

  @override
  String get sceneYourGuess => 'Twój typ';

  @override
  String sceneNOfM(int n, int m) {
    return '$n z $m';
  }

  @override
  String get reportProblem => 'Zgłoś problem';

  @override
  String get reportedThanks => 'Zgłoszono. Dziękujemy.';

  @override
  String get reportTitle => 'Co jest nie tak z tą kartą?';

  @override
  String get reportLead =>
      'Każde zgłoszenie sprawdzamy w źródłach i poprawiamy kartę.';

  @override
  String get reportFact => 'Fakt jest błędny';

  @override
  String get reportAnswer => 'Odpowiedź oznaczona jako poprawna jest błędna';

  @override
  String get reportSource => 'Źródło tego nie potwierdza';

  @override
  String get reportUnclear => 'Jest niejasne';

  @override
  String get reportTypo => 'Literówka lub rozjechana linijka';

  @override
  String get reportOther => 'Coś innego';

  @override
  String get reportNoteHint => 'Coś, co pomoże nam to sprawdzić (opcjonalnie)';

  @override
  String get reportSend => 'Wyślij';

  @override
  String get reportSentToast => 'Dziękujemy. Sprawdzimy to.';

  @override
  String get journeyPointsOff => 'punktów obok';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Jeszcze $n odpowiedzi z pewnością i zmierzymy.',
      many: 'Jeszcze $n odpowiedzi z pewnością i zmierzymy.',
      few: 'Jeszcze $n odpowiedzi z pewnością i zmierzymy.',
      one: 'Jeszcze jedna odpowiedź z pewnością i zmierzymy.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Twój wynik';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'punktu',
      many: 'punktów',
      few: 'punkty',
      one: 'punkt',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n w 4 tygodnie';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'W tym tygodniu masz na razie $n punktu.',
      many: 'W tym tygodniu masz na razie $n punktów.',
      few: 'W tym tygodniu masz na razie $n punkty.',
      one: 'W tym tygodniu masz na razie 1 punkt.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tydzień od $date przyniósł ci $n punktu.',
      many: 'Tydzień od $date przyniósł ci $n punktów.',
      few: 'Tydzień od $date przyniósł ci $n punkty.',
      one: 'Tydzień od $date przyniósł ci 1 punkt.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
      many: '$n kart',
      few: '$n karty',
      one: '1 karta',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Twój wynik na koniec każdego tygodnia od $date. Dotknij punktu, aby zobaczyć ten tydzień.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Poziom $n z $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\ndo poziomu „$rung”';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n kart',
      many: '$n kart',
      few: '$n karty',
      one: '1 karta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n odpowiedzi',
      many: '$n odpowiedzi',
      few: '$n odpowiedzi',
      one: '1 odpowiedź',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n odpowiedzi z pewnością',
      many: '$n odpowiedzi z pewnością',
      few: '$n odpowiedzi z pewnością',
      one: '1 odpowiedź z pewnością',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n utrzymanej karty',
      many: '$n utrzymanych kart',
      few: '$n utrzymane karty',
      one: '1 utrzymana karta',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n punktu',
      many: '$n punktów',
      few: '$n punkty',
      one: '1 punkt',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Równowartość';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n książki',
      many: '$n książek',
      few: '$n książki',
      one: '1 książka',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'albo $h godz dokumentów';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jeszcze $n do pierwszej książki',
      many: 'jeszcze $n do pierwszej książki',
      few: 'jeszcze $n do pierwszej książki',
      one: 'jeszcze 1 do pierwszej książki',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Z rzędu';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dni',
      many: '$n dni',
      few: '$n dni',
      one: '1 dzień',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Rekord $best · $active z $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n z $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'tematów · przerywana: $month';
  }

  @override
  String get journeySubjects => 'tematów';

  @override
  String get journeyHowHard => 'Jak trudne';

  @override
  String get journeyOfThree => 'na 3';

  @override
  String get journeyHardNow => 'Karty, które otwierasz.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Karty, które otwierasz. $v za $month';
  }

  @override
  String get journeyReadingTime => 'Czas czytania';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h godz $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m min';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now min tygodniowo, wcześniej $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min w tym tygodniu';
  }

  @override
  String get journeyTimedFromToday => 'Liczone od dziś';

  @override
  String journeyPointsOffFrom(int was) {
    return 'punktów obok, wcześniej $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · maks. $n';
  }

  @override
  String get journeyRightWhenSure => 'Trafne przy pewności';

  @override
  String journeyFromIn(String v, String month) {
    return 'Za $month: $v';
  }

  @override
  String get journeySureNone => 'Jeszcze żadnej odpowiedzi na 80% lub więcej';

  @override
  String get journeyMovesTitle => 'Wyłapane chwyty';

  @override
  String journeyOfN(int n) {
    return 'z $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Najnowszy: $name';
  }

  @override
  String get journeyNoneYet => 'Jeszcze brak';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'karty wciąż z tobą',
      many: 'kart wciąż z tobą',
      few: 'karty wciąż z tobą',
      one: 'karta wciąż z tobą',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dniach',
      many: '$days dniach',
      few: '$days dniach',
      one: 'dniu',
    );
    return '$right z $of po $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks tygodniach',
      many: '$weeks tygodniach',
      few: '$weeks tygodniach',
      one: 'tygodniu',
    );
    return '$right z $of po $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dnia',
      many: '$days dni',
      few: '$days dni',
      one: '1 dnia',
    );
    return '$active z $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Głównie rano';

  @override
  String get journeyMostlyAfternoon => 'Głównie po południu';

  @override
  String get journeyMostlyEvening => 'Głównie wieczorem';

  @override
  String get journeyMostlyNight => 'Głównie w nocy';

  @override
  String get journeyInTime => 'W czasie';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString roku',
      many: '$nString lat',
      few: '$nString lata',
      one: '$nString rok',
    );
    return '$_temp0';
  }

  @override
  String journeyFromEra(String era) {
    return 'od $era do dziś';
  }

  @override
  String get journeyEraAncient => 'starożytności';

  @override
  String get journeyEraMedieval => 'średniowiecza';

  @override
  String get journeyEraEarlyModern => 'XVI wieku';

  @override
  String get journeyEraNineteenth => 'XIX wieku';

  @override
  String get journeyEraTwentieth => 'XX wieku';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'jeszcze nic z datą';

  @override
  String get journeyInPlace => 'Na świecie';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regionu',
      many: '$n regionów',
      few: '$n regiony',
      one: '1 region',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list i kosmos';
  }

  @override
  String get journeyRegionAmericas => 'Ameryki';

  @override
  String get journeyRegionEurope => 'Europa';

  @override
  String get journeyRegionAsia => 'Azja';

  @override
  String get journeyRegionOceania => 'Oceania';

  @override
  String get journeyRegionAfrica => 'Afryka';

  @override
  String get journeyRegionMiddleEast => 'Bliski Wschód';

  @override
  String get journeyNoPlace => 'jeszcze brak miejsc';

  @override
  String get journeyTopics => 'Wątki';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n poznanego',
      many: '$n poznanych',
      few: '$n poznane',
      one: '1 poznany',
    );
    return '$_temp0';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n z nich: $subject';
  }

  @override
  String get journeyWords => 'Słowa';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nowego',
      many: '$n nowych',
      few: '$n nowe',
      one: '1 nowe',
    );
    return '$_temp0';
  }

  @override
  String get anotherOne => 'Inna';

  @override
  String answerIs(String said) {
    return 'Odpowiedź: $said';
  }

  @override
  String get answeredAlready => 'Już odpowiedziana';

  @override
  String get anyCard => 'Dowolny temat, dowolna półka, jedna karta';

  @override
  String betN(int n) {
    return 'Postaw $n';
  }

  @override
  String get betWord => 'Postaw';

  @override
  String get biggerLabel => 'Większe';

  @override
  String get biggerYouGotIt => 'Większe · trafione';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Po $n dniach',
      many: 'Po $n dniach',
      few: 'Po $n dniach',
      one: 'Po jednym dniu',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Po tygodniu';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Po $n tygodniach',
      many: 'Po $n tygodniach',
      few: 'Po $n tygodniach',
      one: 'Po tygodniu',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Sprawdź';

  @override
  String closerDone(String said, int right, int steps) {
    return 'To $said. Trafione: $right z $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'Nie: to mniej niż $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'Nie: to więcej niż $v.';
  }

  @override
  String get closerStart => 'Trzy kroki, żeby się zbliżyć.';

  @override
  String closerYesLess(String v) {
    return 'Tak: to mniej niż $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Tak: to więcej niż $v.';
  }

  @override
  String get corrections => 'Sprostowania';

  @override
  String get didYouKnow => 'Czy to wiesz?';

  @override
  String get didYouKnowLine =>
      'Odwróć, a potem: nowe dla ciebie czy już to znasz?';

  @override
  String get dragToSet => 'Przeciągnij, aby ustawić';

  @override
  String get dykAgain => 'Jeszcze raz';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Znanych: $n',
      many: 'Znanych: $n',
      few: 'Znane: $n',
      one: 'Znana: 1',
      zero: 'Znane: żadna',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n nowych dla ciebie',
      many: '$n nowych dla ciebie',
      few: '$n nowe dla ciebie',
      one: '1 nowa dla ciebie',
      zero: 'Dziś nic nowego',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'To całe dzisiejsze wydanie';

  @override
  String get editionTomorrow => 'Jutrzejsze ukaże się rano';

  @override
  String get eraAncient => 'Świat starożytny';

  @override
  String get eraAncientWhen => 'Przed rokiem 500';

  @override
  String get eraEarlyModern => 'Wczesna nowożytność';

  @override
  String get eraEarlyModernWhen => 'Od 1500 do 1800';

  @override
  String get eraMedieval => 'Średniowiecze';

  @override
  String get eraMedievalWhen => 'Od 500 do 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Jeszcze $n z tej epoki',
      many: 'Jeszcze $n z tej epoki',
      few: 'Jeszcze $n z tej epoki',
      one: 'Jeszcze 1 z tej epoki',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'Wiek XIX';

  @override
  String get eraNineteenthWhen => 'Od 1800 do 1900';

  @override
  String get eraRecent => 'Ten wiek';

  @override
  String get eraRecentWhen => 'Od 2000 roku';

  @override
  String get eraRulerNow => 'Dziś';

  @override
  String get eraRulerOld => 'Starożytność';

  @override
  String get eraShortAncient => 'Starożytność';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Średniowiecze';

  @override
  String get eraShortNineteenth => 'XIX wiek';

  @override
  String get eraShortRecent => 'XXI wiek';

  @override
  String get eraShortTwentieth => 'XX wiek';

  @override
  String get eraTwentieth => 'Ubiegły wiek';

  @override
  String get eraTwentiethWhen => 'Od 1900 do 2000';

  @override
  String get fewCards => 'W kilku kartach';

  @override
  String get fewCardsLine => 'Gdy jedna karta nie wystarczy, by to wyjaśnić';

  @override
  String get firstLabel => 'Od';

  @override
  String get forYouNow => 'Dla ciebie, teraz';

  @override
  String get hardBadge => 'Trudne';

  @override
  String hidesIn(String where) {
    return 'W: $where';
  }

  @override
  String get howSure => 'Na ile mam pewność i dlaczego?';

  @override
  String get inNumbers => 'W liczbach';

  @override
  String inRange(int pts, String said) {
    return 'Trafione: +$pts pkt. To $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'W twoich ruchach · $n×';
  }

  @override
  String itIs(String said) {
    return 'To $said.';
  }

  @override
  String get knewIt => 'Znam to';

  @override
  String get less => 'Mniej';

  @override
  String get lookFirst => 'Spójrz na wykres, zanim uwierzysz w nagłówek.';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Pudło: to $said.';
  }

  @override
  String get modeBigger => 'Co jest większe?';

  @override
  String get modeCloser => 'Coraz bliżej';

  @override
  String get modePick => 'Wybierz jedną';

  @override
  String get modeRange => 'Obstaw przedział';

  @override
  String get modeSlide => 'Przesuń';

  @override
  String get modeStake => 'Postaw zakład';

  @override
  String get monthShelfLine => 'Co miesiąc nowy temat, ten sam dla wszystkich';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards karty',
      many: '$cards kart',
      few: '$cards karty',
      one: '1 karta',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'Ile masz czasu';

  @override
  String get moodTitle => 'Twój nastrój, twoje minuty';

  @override
  String get moodTone => 'Ton';

  @override
  String get more => 'Więcej';

  @override
  String moreOrLess(String v) {
    return 'Więcej czy mniej niż $v?';
  }

  @override
  String get moveComparedToWhat => 'W porównaniu z czym?';

  @override
  String get moveComparedToWhatLine =>
      'Zmiana nic nie znaczy, jeśli nie ma jej z czym porównać';

  @override
  String get askingTitle => 'Po pytaniu z każdego tematu';

  @override
  String askingIn(String subject) {
    return 'Pytania: $subject';
  }

  @override
  String get askingLine =>
      'Te same dla wszystkich. Najpierw odpowiedz, potem zobacz dlaczego';

  @override
  String get moveSampling => 'Kogo policzono?';

  @override
  String get moveSamplingLine =>
      'To, kto trafia do badania, decyduje, co może ono powiedzieć';

  @override
  String mythDeckHint(int at, int of) {
    return '$at z $of · przesuń, by odwrócić';
  }

  @override
  String nOfM(int at, int of) {
    return '$at z $of';
  }

  @override
  String get newMove => 'Nowość dla ciebie';

  @override
  String get newToMe => 'Nowe dla mnie';

  @override
  String get notEnoughPoints => 'Za mało punktów';

  @override
  String get notSureLine => 'Jedna karta z dowolnego miejsca w Astute';

  @override
  String get notSureTitle => 'Nie wiesz, od czego zacząć?';

  @override
  String get openWord => 'Otwórz';

  @override
  String get pickOneFirst => 'Najpierw wybierz';

  @override
  String get puzzleOfTheDay => 'Łamigłówka dnia';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pkt';
  }

  @override
  String get rightLastTime => 'Ostatnio dobrze';

  @override
  String get sameForEveryoneCaps => 'Taka sama dla wszystkich';

  @override
  String get sayFalse => 'Fałsz';

  @override
  String get sayTrue => 'Prawda';

  @override
  String get seriesAnchors => 'Pierwsze wrażenia';

  @override
  String get seriesGrowth => 'Liczby, które uciekają';

  @override
  String seriesMeta(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n karty',
      many: '$n kart',
      few: '$n karty',
    );
    return '$_temp0 · około $m min';
  }

  @override
  String get seriesOdds => 'Kłamliwe prawdopodobieństwa';

  @override
  String get seriesRetold => 'Historia opowiedziana na nowo';

  @override
  String seriesStrand(String name) {
    return '$name w kilku kartach';
  }

  @override
  String get seriesStudies => 'Dlaczego badania wprowadzają w błąd';

  @override
  String showAllN(int n) {
    return 'Pokaż wszystkie ($n)';
  }

  @override
  String get showFewer => 'Pokaż mniej';

  @override
  String get sixtyAgain => 'Zagraj jeszcze raz';

  @override
  String sixtyIn(int s) {
    return 'w $s s';
  }

  @override
  String get sixtyLine => 'Osiem razy prawda czy fałsz. Zaufaj intuicji';

  @override
  String get sixtyPerfect => 'Wszystkie osiem dobrze.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Na razie $n dobrze',
      many: 'Na razie $n dobrze',
      few: 'Na razie $n dobrze',
      one: 'Na razie 1 dobrze',
      zero: 'Na razie żadnej dobrze',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'sekund na osiem\nrazy prawda czy fałsz';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Start';

  @override
  String get sixtyTimeUp => 'zanim skończył się czas';

  @override
  String get sixtyTitle => 'Sześćdziesiąt sekund';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n punktu różnicy.',
      many: '$n punktów różnicy.',
      few: '$n punkty różnicy.',
      one: '1 punkt różnicy.',
      zero: 'Idealnie.',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => 'Stawka';

  @override
  String stepOf(int at, int of) {
    return 'Krok $at z $of';
  }

  @override
  String get surpriseMe => 'Zaskocz mnie';

  @override
  String get tapIfBigger => 'Stuknij, jeśli większe';

  @override
  String get tapToTurn => 'Stuknij, by odwrócić';

  @override
  String get tfRight => 'Dobrze. Otwórz, żeby poznać powód.';

  @override
  String tfWrong(String side) {
    return 'To $side. Otwórz, żeby poznać powód.';
  }

  @override
  String theAnswer(String said) {
    return 'Odpowiedź: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Temat dnia';

  @override
  String get throughTime => 'Przez wieki';

  @override
  String get throughTimeLine =>
      'Od starożytności po ten rok. Przeciągnij albo wpisz rok';

  @override
  String leanHint(String or) {
    return 'Przesuń „$or” tam, gdzie stoisz';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'trochę',
      '2': 'raczej',
      '3': 'zdecydowanie',
      'other': 'w pełni',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Twój wybór: $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Otwórz, żeby poznać drugą stronę.';
  }

  @override
  String get spotTitle => 'Znajdź fałsz';

  @override
  String get spotLine => 'Trzy są prawdziwe. Jedno nie.';

  @override
  String get spotPrompt => 'Stuknij to, które uważasz za fałszywe';

  @override
  String get spotConfirm => 'To jest fałszywe';

  @override
  String get spotFound => 'Znalezione. Pozostałe trzy są prawdziwe.';

  @override
  String get spotMissed =>
      'Nie to: jest prawdziwe. Fałszywe jest przekreślone.';

  @override
  String get spotWhy => 'Stuknij dowolne, żeby przeczytać dlaczego';

  @override
  String get spotYours => 'Twój wybór';

  @override
  String get yearHint => 'Wpisz rok';

  @override
  String get yearAd => 'n.e.';

  @override
  String get yearBc => 'p.n.e.';

  @override
  String yearNamed(String year) {
    return '$year';
  }

  @override
  String yearAdOf(String year) {
    return '$year n.e.';
  }

  @override
  String yearBcOf(String year) {
    return '$year p.n.e.';
  }

  @override
  String get yearGo => 'Przejdź do tego roku';

  @override
  String yearNearest(String year) {
    return 'Najpierw najbliższe roku $year';
  }

  @override
  String yearNoneNamed(String year) {
    return 'Żadna karta nie podaje tu roku bliskiego $year. Te są z jego epoki.';
  }

  @override
  String yearNoAge(String year) {
    return 'Dziś nic z okolic roku $year. To najbliższa epoka.';
  }

  @override
  String yearFuture(String year) {
    return 'Rok $year dopiero nadejdzie. Oto ten wiek.';
  }

  @override
  String get yearZero => 'Roku 0 nie było. Spróbuj 1 p.n.e. lub 1 n.e.';

  @override
  String get todayLabel => 'Dziś';

  @override
  String get todaysEdition => 'Dzisiejsze wydanie';

  @override
  String get toneCurious => 'Ciekawe';

  @override
  String get toneLight => 'Lekkie';

  @override
  String get toneSerious => 'Poważne';

  @override
  String get toneTough => 'Trudne';

  @override
  String get unmaskBack => 'Pokaż jak w oryginale';

  @override
  String get unmaskFlipped => 'Odwróć właściwie';

  @override
  String get unmaskLine => 'Te same liczby, inny obraz';

  @override
  String get unmaskStretched => 'Użyj uczciwej skali';

  @override
  String get unmaskTitle => 'Zdemaskuj wykres';

  @override
  String get unmaskTotals => 'Porównaj uczciwie';

  @override
  String get unmaskTruncated => 'Zacznij oś od zera';

  @override
  String get unmaskWindow => 'Pokaż całą serię';

  @override
  String get whatIfTrue => 'A jeśli to prawda?';

  @override
  String get whatIfTrueLine => 'Karty, które działają dalej po zamknięciu';

  @override
  String get whatYouBelieve => 'W co wierzysz';

  @override
  String get wrongLastTime => 'Ostatnio źle';

  @override
  String youLose(int n) {
    return 'Tracisz $n.';
  }

  @override
  String youWin(int n) {
    return 'Wygrywasz $n.';
  }

  @override
  String get yourPick => 'Twój wybór';
}
