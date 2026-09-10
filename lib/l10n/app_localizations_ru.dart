// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

  @override
  String get tabToday => 'Сегодня';

  @override
  String get tabExplore => 'Обзор';

  @override
  String get tabProfile => 'Профиль';

  @override
  String signInNotConnected(String provider) {
    return 'Вход через $provider ещё не подключён. Твои карточки остаются на этом устройстве.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Не удалось войти через $label. Можно продолжить без аккаунта.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня',
      many: '$n дней',
      few: '$n дня',
      one: '$n день',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'Заморозка спасла серию';

  @override
  String get holdACardToKeepIt => 'Удержи карточку, чтобы сохранить';

  @override
  String keptToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n сохранено сегодня',
      many: '$n сохранено сегодня',
      few: '$n сохранены сегодня',
      one: '$n сохранена сегодня',
    );
    return '$_temp0';
  }

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'одна',
      '2': 'две',
      '3': 'три',
      '4': 'четыре',
      '5': 'пять',
      '6': 'шесть',
      '7': 'семь',
      '8': 'восемь',
      '9': 'девять',
      '10': 'десять',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'День $n · прочитано $word';
  }

  @override
  String shelfEyebrow(String word) {
    return 'СЕГОДНЯШНИЕ $word · ЛИСТАЙ, ЧТОБЫ ПОВТОРИТЬ';
  }

  @override
  String weekLine(int days) {
    return 'Твоя неделя · $days из 7';
  }

  @override
  String get tapToFlip => 'НАЖМИ, ЧТОБЫ ПЕРЕВЕРНУТЬ';

  @override
  String get shareThisCard => 'Поделиться карточкой';

  @override
  String get removeFromSaved => 'Убрать из сохранённых';

  @override
  String get saveThisPill => 'Сохранить эту пилюлю';

  @override
  String get shareThisPill => 'Поделиться пилюлей';

  @override
  String cardOf(int k, int n) {
    return 'Карточка $k из $n';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Завтрашняя пятёрка откроется через $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic открывает завтрашнюю пятёрку через $when';
  }

  @override
  String get exploreTodaysBest => 'Лучшее за сегодня';

  @override
  String get fiveMore => 'Ещё пять';

  @override
  String get unlockFiveExtra => 'Открыть пять дополнительных пилюль';

  @override
  String nothingInYet(String subject) {
    return 'В $subject пока ничего нет.';
  }

  @override
  String get here => 'этом разделе';

  @override
  String get todaysShelf => 'Полка дня';

  @override
  String get sameForEveryone => 'Одна на всех, и только сегодня';

  @override
  String get onesThatAskTheMost => 'Те, что спрашивают больше всего';

  @override
  String get acrossEveryone => 'У всех, а не только в твоём миксе';

  @override
  String becauseSitsAtFull(String name) {
    return 'Потому что $name на максимуме';
  }

  @override
  String get olderFromTurnedUp => 'Старые карточки из тем, которые ты поднял';

  @override
  String moreOn(String name) {
    return 'Ещё о $name';
  }

  @override
  String get subjectReadMost => 'Тема, о которой ты читал больше всего';

  @override
  String monthOf(String name) {
    return 'Месяц $name';
  }

  @override
  String get somewhereToStart => 'Точка старта, которая не сегодня';

  @override
  String get searchEveryCard => 'Искать по всем карточкам';

  @override
  String nothingForYet(String query) {
    return 'По запросу «$query» пока ничего.';
  }

  @override
  String matching(int n) {
    return 'Найдено: $n';
  }

  @override
  String get all => 'Все';

  @override
  String get theArchive => 'Архив';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n результата',
      many: '$n результатов',
      few: '$n результата',
      one: '$n результат',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return 'Карточек: $n. Нажми на день, чтобы открыть.';
  }

  @override
  String get whatYouHaveCovered => 'Что ты уже прошёл';

  @override
  String searchNCards(int n) {
    return 'Искать среди $n карточек';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки',
      many: '$n карточек',
      few: '$n карточки',
      one: '$n карточка',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Вчера';

  @override
  String get noPillsMatchFilter =>
      'Под этот фильтр пока не подходит ни одна пилюля.';

  @override
  String nothingForTryTopic(String query) {
    return 'По запросу «$query» ничего. Попробуй тему.';
  }

  @override
  String get saved => 'Сохранённые';

  @override
  String get removedFromSaved => 'Убрано из сохранённых.';

  @override
  String get undo => 'Вернуть';

  @override
  String get nothingKeptYet => 'Пока ничего не сохранено';

  @override
  String nInTopic(int n, String topic) {
    return '$n в теме $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Сохраняй те, что правда пригодятся';

  @override
  String get tapTheHeartLandsHere =>
      'Нажми на сердце на любой пилюле — и она окажется здесь. Те, что изменили твоё мышление, сохранены.';

  @override
  String get backToTodaysFive => 'К СЕГОДНЯШНЕЙ ПЯТЁРКЕ';

  @override
  String get archive => 'Архив';

  @override
  String get yourWeek => 'Твоя неделя';

  @override
  String get nothingThisWeekYet =>
      'На этой неделе пока ничего. Пять карточек её начнут.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Засчитана — $days дней из семи.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня из семи.',
      many: '$days дней из семи.',
      few: '$days дня из семи.',
      one: '$days день из семи.',
    );
    return '$_temp0 Пять — и неделя засчитана.';
  }

  @override
  String get howSureAgainstHowRight => 'Насколько уверен — и насколько прав';

  @override
  String get sureAndWrong => 'Уверен — и неправ';

  @override
  String get worthGoingBackTo =>
      'К ним стоит вернуться. Ошибиться в том, в чём был уверен, — единственный дешёвый способ узнать, во что ты веришь на самом деле.';

  @override
  String get whereThisIsGoing => 'Куда это ведёт';

  @override
  String ofNRight(int n) {
    return 'из $n верно';
  }

  @override
  String get sayHowSureOnMore =>
      'Отметь уверенность ещё на нескольких, и приложение скажет, чего эта уверенность стоит.';

  @override
  String confidenceOff(int gap) {
    return 'Твоя уверенность отклонялась на $gap пунктов от того, что ты знал на самом деле.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Уверенность отклонялась на $gap пунктов против $before на прошлой неделе. Разрыв сокращается.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Уверенность отклонялась на $gap пунктов против $before на прошлой неделе. Разрыв вырос.';
  }

  @override
  String nextRung(String name) {
    return 'Дальше: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'Ты сказал: уверен на $n%';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'День первый',
      'reading': 'Чтение',
      'answering': 'Ответы',
      'saying_how_sure': 'Оценка уверенности',
      'calibrated': 'Откалиброван',
      'holding': 'Удержание',
      'sharp': 'Острый ум',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Здесь начинают все.',
      'reading': 'Привычка началась.',
      'answering': 'Ты отвечаешь до того, как перевернёшь карточку.',
      'saying_how_sure':
          'Ты ставишь число на то, что, как тебе кажется, знаешь.',
      'calibrated': 'То, что ты говоришь, что знаешь, ты знаешь.',
      'holding': 'Остаётся с тобой спустя недели.',
      'sharp': 'Уверен, когда стоит, и прав, когда уверен.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'ещё $n карточек прочитать';
  }

  @override
  String stepAnswer(int n) {
    return 'ещё $n карточек ответить';
  }

  @override
  String stepJudge(int n) {
    return 'ещё $n ответов с оценкой уверенности';
  }

  @override
  String stepHold(int n) {
    return 'ещё $n карточек удержать';
  }

  @override
  String stepGap(int gap, int target) {
    return 'твоя уверенность отклоняется на $gap пунктов — хватит $target';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'ещё $n ответов, прежде чем приложение оценит твою уверенность';
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
  String get signOutQuestion => 'Выйти?';

  @override
  String get signOutBody =>
      'Серия, сохранённые пилюли и история остаются в аккаунте. Это удалит их с этого устройства.';

  @override
  String get signOut => 'Выйти';

  @override
  String get signedInRecordOnAccount =>
      'Вход выполнен. Серия и история теперь в твоём аккаунте.';

  @override
  String couldNotSignInWith(String label) {
    return 'Не удалось войти через $label.';
  }

  @override
  String get signInNotAvailableBuild => 'Вход недоступен в этой сборке.';

  @override
  String get startOverQuestion => 'Начать заново?';

  @override
  String get startOverBody =>
      'Удаляет всё на этом устройстве — серию, сохранённые пилюли, ответы, историю оценок, темы и план — и открывает вступление заново.';

  @override
  String get wipeIt => 'Удалить';

  @override
  String get yourRecord => 'Твоя история';

  @override
  String get appearance => 'Оформление';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get yourTopics => 'Твои темы';

  @override
  String get edit => 'Изменить';

  @override
  String get howWellYouKnowYourself => 'Насколько ты себя знаешь';

  @override
  String get isTheGapClosing => 'Разрыв сокращается?';

  @override
  String get movesYouKeepMissing => 'Ходы, которые ты продолжаешь упускать';

  @override
  String get dailyNudge => 'Ежедневное напоминание';

  @override
  String everyDayAt(String time) {
    return 'Каждый день в $time';
  }

  @override
  String get yourFivePillsBeforeCoffee => 'Твои 5 пилюль, до первого кофе.';

  @override
  String get browserOnlySpeaksOpen =>
      'Браузер говорит только пока открыт, так что для этого нужна версия для телефона.';

  @override
  String get nudgeOff => 'Напоминание выключено.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Напоминание включено, каждый день в $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Напоминание включено, но система отказала. Включи уведомления для Astut в настройках.';

  @override
  String get nudgeOnNeedsPhone =>
      'Напоминание включено. Для доставки нужна версия для телефона.';

  @override
  String get howMuchYouKnow => 'Сколько ты знаешь';

  @override
  String savedN(int n) {
    return 'Сохранённые · $n';
  }

  @override
  String get manageSubscription => 'Управлять подпиской';

  @override
  String get howPillsAreWritten => 'Как пишутся пилюли';

  @override
  String get signingIn => 'Вход…';

  @override
  String get signInWithApple => 'Войти через Apple';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'В $n ответах ты отметил, насколько уверен. Вот что вышло.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'Идеально откалиброванный человек прав в 70% случаев, когда говорит «70%».';

  @override
  String get notEnoughAnswersYet => 'Пока мало ответов';

  @override
  String get confidenceMatchesAccuracy =>
      'Твоя уверенность совпадает с точностью';

  @override
  String overconfidentBy(int points) {
    return 'Ты переоцениваешь себя на $points пунктов';
  }

  @override
  String underconfidentBy(int points) {
    return 'Ты недооцениваешь себя на $points пунктов';
  }

  @override
  String saidPercent(int n) {
    return 'Сказал $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'верно $pct% ($right из $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'впереди ещё $n контекста',
      many: 'впереди ещё $n контекстов',
      few: 'впереди ещё $n контекста',
      one: 'впереди ещё $n контекст',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Все принципы — с Astut plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n отслеживаются',
      many: 'ещё $n отслеживаются',
      few: 'ещё $n отслеживаются',
      one: 'ещё $n отслеживается',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'ПОДЕЛИТЬСЯ ИСТОРИЕЙ';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Твои последние $n оценок против первых $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Сократился на $n пунктов';
  }

  @override
  String openedByPoints(int n) {
    return 'Вырос на $n пунктов';
  }

  @override
  String get holdingSteady => 'Без изменений';

  @override
  String get measurementRunningPlus =>
      'Измерение идёт. Astut+ показывает, в какую сторону.';

  @override
  String firstN(int n) {
    return 'Первые $n';
  }

  @override
  String lastN(int n) {
    return 'Последние $n';
  }

  @override
  String get trackingMoreClosely =>
      'Твоя уверенность следует за точностью ближе, чем раньше.';

  @override
  String get distanceHasGrown =>
      'Разрыв вырос. Стоит притормозить, прежде чем отвечать.';

  @override
  String get noRealMovementYet =>
      'Пока без заметного движения. На это уходят недели, не дни.';

  @override
  String get seeWhichWay => 'В КАКУЮ СТОРОНУ';

  @override
  String get spotOn => 'точно';

  @override
  String pointsOver(int n) {
    return '$n лишних';
  }

  @override
  String pointsUnder(int n) {
    return '$n недостаёт';
  }

  @override
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 дней бесплатно';

  @override
  String get watchTheGapMove => 'Смотри, как движется разрыв.';

  @override
  String get measurementFreeForever =>
      'Измерение бесплатно и останется таким. Astut+ — это то, что говорит, куда оно движется.';

  @override
  String get seeThePlans => 'ПОСМОТРЕТЬ ТАРИФЫ';

  @override
  String get recordStartsToday => 'Твоя история начинается сегодня.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'дня',
      many: 'дней',
      few: 'дня',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'пилюли прочитано',
      many: 'пилюль прочитано',
      few: 'пилюли прочитаны',
      one: 'пилюля прочитана',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n пилюли прочитано',
      many: '$n пилюль прочитано',
      few: '$n пилюли прочитаны',
      one: '$n пилюля прочитана',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n недели засчитано',
      many: '$n недель засчитано',
      few: '$n недели засчитаны',
      one: '$n неделя засчитана',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n возвращаются';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n заморозки в запасе',
      many: '$n заморозок в запасе',
      few: '$n заморозки в запасе',
      one: '$n заморозка в запасе',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Бесплатный план';

  @override
  String get streakReset => 'Серия сброшена';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ты пропустил\n$n дня.',
      many: 'Ты пропустил\n$n дней.',
      few: 'Ты пропустил\n$n дня.',
      one: 'Ты пропустил\n$n день.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня —',
      many: '$n дней —',
      few: '$n дня —',
      one: '$n день —',
    );
    return '$_temp0 по-прежнему твой рекорд. Прочитай сегодняшнюю пятёрку, и счётчик снова начнёт с одного.';
  }

  @override
  String get whileYouWereAway => 'Пока тебя не было';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n пилюли остались непрочитанными',
      many: '$n пилюль остались непрочитанными',
      few: '$n пилюли остались непрочитанными',
      one: '$n пилюля осталась непрочитанной',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic — по-прежнему твоя самая сохраняемая тема';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки, на которые ты ответил верно, возвращаются сегодня',
      many: '$n карточек, на которые ты ответил верно, возвращаются сегодня',
      few: '$n карточки, на которые ты ответил верно, возвращаются сегодня',
      one: '$n карточка, на которую ты ответил верно, возвращается сегодня',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Начать заново с сегодняшней пятёрки';

  @override
  String moveMyReminderTo(String time) {
    return 'Перенести напоминание на $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Ежедневное напоминание перенесено на $time.';
  }

  @override
  String get whatYouAlready => 'Что ты уже ';

  @override
  String get know => 'знаешь';

  @override
  String get knowIntro =>
      'Темы, которые ты поднял выше всего. Это меняет, чего день требует от тебя в каждой из них — уверенный получает вопросы, любопытный получает объяснения, — а не сколько ты получаешь.';

  @override
  String get startWithMyFirstCards => 'Начать с первых карточек';

  @override
  String get skipForNow => 'Пока пропустить';

  @override
  String get levelCurious => 'Любопытно';

  @override
  String get levelSome => 'Немного';

  @override
  String get levelSolid => 'Уверенно';

  @override
  String get save => 'Сохранить';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n из $total тем в миксе';
  }

  @override
  String get yourSpace => 'Твой ';

  @override
  String get mix => 'микс';

  @override
  String get everythingIsInDrag =>
      'Всё включено. Потяни тему вниз, чтобы видеть её реже, или до нуля, чтобы убрать.';

  @override
  String get next => 'Дальше';

  @override
  String get whatShouldWeTalkAbout => 'О чём поговорим?';

  @override
  String get fivePillsADayPick =>
      'Пять пилюль в день, свежие каждое утро. Выбери темы для микса — потом их можно изменить.';

  @override
  String nSelected(int n) {
    return 'Выбрано: $n';
  }

  @override
  String startWithNTopics(int n) {
    return 'Начать с $n тем';
  }

  @override
  String saveNTopics(int n) {
    return 'Сохранить $n тем';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Выбери минимум $n';
  }

  @override
  String get swipeToSeeMore => 'Листай дальше';

  @override
  String get tagline => 'Пять умных вещей в день, готовых для разговора';

  @override
  String get introTopicsTitle => 'Двенадцать тем, пять пилюль';

  @override
  String get introTopicsLine => 'Пишутся каждое утро и сверяются с источником.';

  @override
  String get introQuestionTitle => 'Вопрос, потом ответ';

  @override
  String get introQuestionLine =>
      'В каждой пилюле — та самая фраза, которую стоит сказать вслух.';

  @override
  String get introMixTitle => 'Микс выбираешь ты';

  @override
  String get introMixLine =>
      'Убавь тему, чтобы видеть её реже, или выключи совсем.';

  @override
  String get introThirtyTitle => 'Тридцать секунд в день';

  @override
  String get introThirtyLine =>
      'Одно уведомление, пять карточек и серия, которую не захочется прервать.';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithEmail => 'Продолжить по почте';

  @override
  String get termsLine =>
      'Регистрируясь, ты принимаешь Условия использования и Политику конфиденциальности';

  @override
  String get skip => 'Пропустить';

  @override
  String get tapToRevealLower => 'нажми, чтобы открыть';

  @override
  String get barMoveCaps => 'ФРАЗА ДЛЯ РАЗГОВОРА';

  @override
  String get theBarMoveCaps => 'ФРАЗА ДЛЯ РАЗГОВОРА';

  @override
  String get dayStreakCaps => 'ДНЕЙ ПОДРЯД';

  @override
  String sourceLabel(String source) {
    return 'Источник · $source';
  }

  @override
  String get perkRecordTitle => 'Твоя история во времени';

  @override
  String get perkRecordLine =>
      'Действительно ли сокращается разрыв между тем, насколько ты был уверен, и тем, насколько был прав.';

  @override
  String get perkPrinciplesTitle => 'Каждый принцип, который ты встретил';

  @override
  String get perkPrinciplesLine =>
      'Не только три худших — все, и контексты, которые тебе ещё не показывали.';

  @override
  String get perkFreezesTitle => 'Три заморозки серии вместо одной';

  @override
  String get perkFreezesLine =>
      'Хватит на выходные вне дома. Серия, которую можно только потерять, рано или поздно уходит.';

  @override
  String get perkExtraTitle => '5 дополнительных пилюль каждый день';

  @override
  String get perkExtraLine =>
      'Второй набор открывается, как только закончишь первый.';

  @override
  String get perkArchiveTitle => 'Полный архив';

  @override
  String get perkArchiveLine =>
      'Каждая прочитанная пилюля, с поиском по темам.';

  @override
  String get perkTopicsTitle => 'Выбирай темы сам';

  @override
  String get perkTopicsLine => 'Сдвинь микс к тому, что тебе правда нравится.';

  @override
  String get plusIsActive => 'ASTUT+ АКТИВЕН';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Попробуй 7 дней бесплатно, затем $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Пробный период начат. В этой сборке оплата не подключена.';

  @override
  String get thatDidNotGoThrough => 'Не получилось.';

  @override
  String get plusIsBack => 'Astut+ снова с тобой.';

  @override
  String get nothingToRestore => 'В этом аккаунте нечего восстанавливать.';

  @override
  String get findOutIfBetter => 'Узнай, правда ли ты становишься лучше.';

  @override
  String get perYear => 'в год';

  @override
  String aMonth(String price) {
    return '$price в месяц';
  }

  @override
  String savePercent(int n) {
    return 'ЭКОНОМИЯ $n%';
  }

  @override
  String get perMonth => 'в месяц';

  @override
  String get billedMonthly => 'списывается ежемесячно';

  @override
  String get cancelTheTrial => 'Отменить пробный период';

  @override
  String get cancelAnyTime => 'Отмена в любой момент';

  @override
  String get cancelAnyTimeNoPayment =>
      'Отмена в любой момент · В этой сборке ничего не списывается';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get everythingOpensNothingCharged =>
      'Открывается всё. Ничего не списывается.';

  @override
  String dayN(int n) {
    return 'ДЕНЬ $n';
  }

  @override
  String get reminderTwoDaysBefore => 'Напоминание за два дня до продления.';

  @override
  String get itRenewsUnlessCancelled =>
      'Продлевается, если ты не отменил. Отменить можно в любой момент.';

  @override
  String get howTheFreeWeekWorks => 'КАК РАБОТАЕТ БЕСПЛАТНАЯ НЕДЕЛЯ';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer =>
      'Выбери сторону. Правильного ответа нет.';

  @override
  String get estimateCloseEnough => 'Оцени. Близко — уже засчитывается.';

  @override
  String get tapToReveal => 'Нажми, чтобы открыть';

  @override
  String closeEnoughItIs(String answer) {
    return 'Достаточно близко · это $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'Ты сказал $given · это $answer, и $band засчитано';
  }

  @override
  String get youGotIt => 'Верно';

  @override
  String youSaidItIs(String given, String answer) {
    return 'Ты сказал $given · это $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Почти все здесь ошибаются';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · ты был уверен на $pct%';
  }

  @override
  String get giveMeANudge => 'Дай подсказку';

  @override
  String get beingRightMattersLess =>
      'Быть правым важно меньше, чем знать, как часто ты прав.';

  @override
  String get writeItBeforeTheirs => 'Напиши до того, как прочтёшь их версию.';

  @override
  String get youAnsweredThisOne => 'На эту ты уже отвечал.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Легко',
      'medium': 'Средне',
      'hard': 'Сложно',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · ответь до того, как перевернёшь.';
  }

  @override
  String get yourAnswer => 'Твой ответ';

  @override
  String get checkMyAnswer => 'Проверить ответ';

  @override
  String get howSureAreYou => 'Насколько ты уверен?';

  @override
  String percentSure(int n) {
    return 'уверен на $n процентов';
  }

  @override
  String get inOneLineWhy => 'Одной строкой — почему?';

  @override
  String get because => 'Потому что…';

  @override
  String get nowShowMeTheOtherSide => 'Теперь покажи другую сторону';

  @override
  String get skipShowMeAnyway => 'Пропустить — всё равно покажи';

  @override
  String get youTookCaps => 'ТЫ ВЫБРАЛ';

  @override
  String get putSimplyCaps => 'ПРОЩЕ ГОВОРЯ';

  @override
  String get explainLikeImThree => 'Объясни как ребёнку';

  @override
  String get whatTheOtherSideSaysCaps => 'ЧТО ГОВОРИТ ДРУГАЯ СТОРОНА';

  @override
  String get whatTheOtherSideSays => 'Что говорит другая сторона';

  @override
  String theTrap(String trap) {
    return 'Ловушка: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'Ты выбрал сторону: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' с уверенностью $n%';
  }

  @override
  String youGotThisOne(String sure) {
    return 'Здесь ты угадал$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'Ты сказал $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Листай к следующей';

  @override
  String get thatWasTheOnlyOne => 'Это была единственная';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Не удалось отрисовать карточку.';

  @override
  String get textCopiedInstead => 'Вместо этого скопирован текст.';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена.';

  @override
  String get rendering => 'Отрисовка…';

  @override
  String get theSourceGoesWithIt => 'Источник идёт вместе с ней';

  @override
  String get fiveADayALittleSharper => 'Пять в день. Чуть острее.';

  @override
  String get shareMyDay => 'Поделиться моим днём';

  @override
  String climbedTo(String rung) {
    return 'Сегодня вы поднялись до $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right из $asked верно';
  }

  @override
  String saidSure(int sure) {
    return 'уверенность $sure%';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки вернулись — ответьте ещё раз',
      many: '$n карточек вернулось — ответьте ещё раз',
      few: '$n карточки вернулись — ответьте ещё раз',
      one: '$n карточка вернулась — ответьте ещё раз',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Вернулись';
}
