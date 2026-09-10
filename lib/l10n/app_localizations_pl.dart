// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
    return 'DZISIEJSZE $word · PRZESUŃ, BY POWTÓRZYĆ';
  }

  @override
  String weekLine(int days) {
    return 'Twój tydzień · $days z 7 zaliczonych';
  }

  @override
  String get tapToFlip => 'DOTKNIJ, BY ODWRÓCIĆ';

  @override
  String get shareThisCard => 'Udostępnij tę kartę';

  @override
  String get removeFromSaved => 'Usuń z zachowanych';

  @override
  String get saveThisPill => 'Zachowaj tę pigułkę';

  @override
  String get shareThisPill => 'Udostępnij tę pigułkę';

  @override
  String cardOf(int k, int n) {
    return 'Karta $k z $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h h $m min';
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
  String get fiveMore => 'Pięć więcej';

  @override
  String get unlockFiveExtra => 'Odblokuj pięć dodatkowych pigułek';

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
  String get onesThatAskTheMost => 'Te, które pytają najwięcej';

  @override
  String get acrossEveryone => 'U wszystkich, nie tylko w twoim miksie';

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
      'Żadna pigułka nie pasuje jeszcze do tego filtra.';

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
      'Twoja seria, zachowane pigułki i historia zostają na koncie. To usuwa je z tego urządzenia.';

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
      'Usuwa wszystko z tego urządzenia — serię, zachowane pigułki, odpowiedzi, historię ocen, tematy i plan — i otwiera wprowadzenie od nowa.';

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
  String get yourFivePillsBeforeCoffee =>
      'Twoje 5 pigułek, przed pierwszą kawą.';

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
      'Przypomnienie włączone, ale system odmówił. Włącz powiadomienia dla Astut w ustawieniach.';

  @override
  String get nudgeOnNeedsPhone =>
      'Przypomnienie włączone. Dostarczenie wymaga wersji na telefon.';

  @override
  String get howMuchYouKnow => 'Ile wiesz';

  @override
  String savedN(int n) {
    return 'Zachowane · $n';
  }

  @override
  String get manageSubscription => 'Zarządzaj subskrypcją';

  @override
  String get howPillsAreWritten => 'Jak powstają pigułki';

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
  String get seeEveryPrincipleWithPlus => 'Zobacz każdą zasadę z Astut plus';

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
      'Pomiar trwa. Astut+ pokazuje ci, w którą stronę zmierza.';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 dni za darmo';

  @override
  String get watchTheGapMove => 'Patrz, jak luka się rusza.';

  @override
  String get measurementFreeForever =>
      'Pomiar jest darmowy i taki zostanie. Astut+ mówi ci, w którą stronę zmierza.';

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
      other: 'pigułek przeczytanych',
      many: 'pigułek przeczytanych',
      few: 'pigułki przeczytane',
      one: 'pigułka przeczytana',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pigułek przeczytanych',
      many: '$n pigułek przeczytanych',
      few: '$n pigułki przeczytane',
      one: '1 pigułka przeczytana',
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
  String get streakReset => 'Seria wyzerowana';

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
      other: '$n pigułek zostało nieprzeczytanych',
      many: '$n pigułek zostało nieprzeczytanych',
      few: '$n pigułki zostały nieprzeczytane',
      one: '1 pigułka została nieprzeczytana',
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
  String get whatYouAlready => 'Co już ';

  @override
  String get know => 'wiesz';

  @override
  String get knowIntro =>
      'Tematy, które podkręciłeś najwyżej. To zmienia, czego dzień od ciebie wymaga w każdym z nich — solidny dostaje pytania, ciekawy dostaje wyjaśnienia — a nie ile ich dostajesz.';

  @override
  String get startWithMyFirstCards => 'Zacznij od moich pierwszych kart';

  @override
  String get skipForNow => 'Na razie pomiń';

  @override
  String get levelCurious => 'Ciekawy';

  @override
  String get levelSome => 'Trochę';

  @override
  String get levelSolid => 'Solidnie';

  @override
  String get save => 'Zapisz';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n z $total tematów w miksie';
  }

  @override
  String get yourSpace => 'Twój ';

  @override
  String get mix => 'miks';

  @override
  String get everythingIsInDrag =>
      'Wszystko jest w środku. Przeciągnij temat w dół, żeby widzieć go mniej, albo do zera, żeby go wyrzucić.';

  @override
  String get next => 'Dalej';

  @override
  String get whatShouldWeTalkAbout => 'O czym rozmawiamy?';

  @override
  String get fivePillsADayPick =>
      'Pięć pigułek dziennie, pisanych świeżo każdego ranka. Wybierz tematy do miksu — możesz je później zmienić.';

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
      'Pięć mądrych rzeczy dziennie, gotowych do użycia w rozmowie';

  @override
  String get introTopicsTitle => 'Dwanaście tematów, pięć pigułek';

  @override
  String get introTopicsLine =>
      'Pisane świeżo każdego ranka i sprawdzone ze źródłem.';

  @override
  String get introQuestionTitle => 'Pytanie, potem odpowiedź';

  @override
  String get introQuestionLine =>
      'Każda pigułka niesie to jedno zdanie, które warto powiedzieć na głos.';

  @override
  String get introMixTitle => 'Ty wybierasz miks';

  @override
  String get introMixLine =>
      'Ścisz temat, żeby widzieć go mniej, albo wyłącz na dobre.';

  @override
  String get introThirtyTitle => 'Trzydzieści sekund dziennie';

  @override
  String get introThirtyLine =>
      'Jedno powiadomienie, pięć kart i seria, której nie będziesz chciał przerwać.';

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
  String get barMoveCaps => 'ZDANIE NA IMPREZĘ';

  @override
  String get theBarMoveCaps => 'ZDANIE NA IMPREZĘ';

  @override
  String get dayStreakCaps => 'DNI SERII';

  @override
  String sourceLabel(String source) {
    return 'Źródło · $source';
  }

  @override
  String get perkRecordTitle => 'Twoja historia w czasie';

  @override
  String get perkRecordLine =>
      'Czy luka między tym, jak pewny byłeś, a tym, jak trafny, naprawdę się domyka.';

  @override
  String get perkPrinciplesTitle => 'Każda zasada, którą spotkałeś';

  @override
  String get perkPrinciplesLine =>
      'Nie tylko trzy, w których jesteś najsłabszy — wszystkie, i konteksty, których jeszcze nie widziałeś.';

  @override
  String get perkFreezesTitle => 'Trzy zamrożenia serii, nie jedno';

  @override
  String get perkFreezesLine =>
      'Wystarczy na weekend poza domem. Seria, którą można tylko stracić, w końcu przepada.';

  @override
  String get perkExtraTitle => '5 dodatkowych pigułek każdego dnia';

  @override
  String get perkExtraLine =>
      'Drugi zestaw odblokowuje się, gdy tylko skończysz pierwszy.';

  @override
  String get perkArchiveTitle => 'Pełne archiwum';

  @override
  String get perkArchiveLine =>
      'Każda pigułka, którą przeczytałeś, do przeszukania po temacie.';

  @override
  String get perkTopicsTitle => 'Wybierz własne tematy';

  @override
  String get perkTopicsLine =>
      'Przechyl miks w stronę tego, co naprawdę lubisz.';

  @override
  String get plusIsActive => 'ASTUT+ JEST AKTYWNY';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Wypróbuj 7 dni za darmo, potem $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Okres próbny rozpoczęty. W tej wersji nie ma podłączonej płatności.';

  @override
  String get thatDidNotGoThrough => 'To się nie powiodło.';

  @override
  String get plusIsBack => 'Astut+ wrócił.';

  @override
  String get nothingToRestore => 'Nie ma nic do przywrócenia na tym koncie.';

  @override
  String get findOutIfBetter => 'Sprawdź, czy naprawdę robisz postępy.';

  @override
  String get perYear => 'rocznie';

  @override
  String aMonth(String price) {
    return '$price miesięcznie';
  }

  @override
  String savePercent(int n) {
    return 'OSZCZĘDZASZ $n%';
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
  String get everythingOpensNothingCharged =>
      'Wszystko się otwiera. Nic nie jest pobierane.';

  @override
  String dayN(int n) {
    return 'DZIEŃ $n';
  }

  @override
  String get reminderTwoDaysBefore =>
      'Przypomnienie, dwa dni przed odnowieniem.';

  @override
  String get itRenewsUnlessCancelled =>
      'Odnawia się, chyba że anulowałeś. Możesz to zrobić w każdej chwili.';

  @override
  String get howTheFreeWeekWorks => 'JAK DZIAŁA DARMOWY TYDZIEŃ';

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
  String get yourAnswer => 'Twoja odpowiedź';

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
      other: '$n karty wróciły — odpowiedz jeszcze raz',
      many: '$n kart wróciło — odpowiedz jeszcze raz',
      few: '$n karty wróciły — odpowiedz jeszcze raz',
      one: '1 karta wróciła — odpowiedz jeszcze raz',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Wróciły';

  @override
  String get holdACardYouLike => 'Przytrzymaj, jeśli lubisz';

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
  String get likeThisPill => 'Polub tę pigułkę';

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
      'Dotknij zakładki na pigułce, a trafi tutaj — te, które zmieniły twoje myślenie, zachowane.';

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
}
