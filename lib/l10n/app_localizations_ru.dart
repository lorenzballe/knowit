// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

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
    return 'СЕГОДНЯШНИЕ $word';
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
  String magicUnlock(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Попробуй $_temp0 бесплатно';
  }

  @override
  String get getPlus => 'Перейти на Astute+';

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
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deletingAccount => 'Удаление аккаунта…';

  @override
  String get deleteAccountQuestion => 'Удалить аккаунт?';

  @override
  String get deleteAccountBody =>
      'Аккаунт, его резервная копия и доска, которую видят друзья, удаляются навсегда, а это устройство начинает всё с начала. Подписка Astute+ при этом не отменяется: ею управляют в настройках App Store.';

  @override
  String get deleteAccountConfirm => 'Удалить навсегда';

  @override
  String get accountDeleted => 'Аккаунт удалён.';

  @override
  String get couldNotDeleteAccount =>
      'Не удалось удалить аккаунт. Попробуйте ещё раз чуть позже.';

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
      'Напоминание включено, но система отказала. Включи уведомления для Astute в настройках.';

  @override
  String get nudgeOnNeedsPhone =>
      'Напоминание включено. Для доставки нужна версия для телефона.';

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
  String get seeEveryPrincipleWithPlus => 'Все принципы — с Astute plus';

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
      'Измерение идёт. Astute+ показывает, в какую сторону.';

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
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return '$_temp0 бесплатно';
  }

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
  String subjectsInTheMix(int n, int total) {
    return '$n из $total тем в миксе';
  }

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
  String get introTopicsTitle => 'Восемнадцать тем, пять пилюль';

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
  String introNotifyWhen(String time) {
    return 'Завтра, $time';
  }

  @override
  String get introNotifyLine => 'Ваши пять готовы. День 1.';

  @override
  String get introOneOfFive => '1 ИЗ 5';

  @override
  String get introDayOne => 'ДЕНЬ 1';

  @override
  String get introTapTomorrow => 'НАЖМИ ЗАВТРА, ЧТОБЫ УЗНАТЬ';

  @override
  String get introDayOneTomorrow => 'ДЕНЬ 1 · ЗАВТРА';

  @override
  String get introDaySevenStreak => 'ДЕНЬ 7 · ПЕРВАЯ СЕРИЯ';

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
  String get barMoveCaps => 'ЧТО ЗАПОМНИТЬ';

  @override
  String get theBarMoveCaps => 'ФРАЗА ДЛЯ РАЗГОВОРА';

  @override
  String get widgetFootPlain => 'Пять карточек, две минуты.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня подряд',
      many: '$n дней подряд',
      few: '$n дня подряд',
      one: '$n день подряд',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'На сегодня всё';

  @override
  String get widgetStreakStart =>
      'Прочитай сегодняшние пять, чтобы начать серию.';

  @override
  String get widgetFiveTitle => 'ПЯТЬ НА СЕГОДНЯ';

  @override
  String widgetFiveRead(int n) {
    return 'Прочитано $n из 5';
  }

  @override
  String get widgetFiveDone => 'Все пять прочитаны';

  @override
  String get widgetFiveWaiting => 'Ждут пять новых карточек';

  @override
  String get widgetShelfTitle => 'ПОЛКА ДНЯ';

  @override
  String get widgetShelfFrom => 'С полки дня';

  @override
  String get dayStreakCaps => 'ДНЕЙ ПОДРЯД';

  @override
  String sourceLabel(String source) {
    return 'Источник · $source';
  }

  @override
  String get perkArchiveTitle => 'Весь твой архив';

  @override
  String get perkArchiveLine => 'Каждый прочитанный день — навсегда.';

  @override
  String get plusIsActive => 'ASTUTE+ АКТИВЕН';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return '$_temp0 бесплатно, затем $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Подписаться за $price$suffix';
  }

  @override
  String get noChargeTodayCancel =>
      'Сегодня без списания · отмена в любой момент';

  @override
  String get chargedTodayCancel => 'Списание сегодня · отмена в любой момент';

  @override
  String get everyCardForYouMark => 'тебя.';

  @override
  String get trialStartedNoPayment =>
      'Пробный период начат. В этой сборке оплата не подключена.';

  @override
  String get thatDidNotGoThrough => 'Не получилось.';

  @override
  String get plusIsBack => 'Astute+ снова с тобой.';

  @override
  String get nothingToRestore => 'В этом аккаунте нечего восстанавливать.';

  @override
  String get planYearly => 'На год';

  @override
  String get planMonthly => 'На месяц';

  @override
  String get perYearShort => '/год';

  @override
  String get perMonthShort => '/мес.';

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
  String get termsOfUse => 'Условия';

  @override
  String get privacyPolicy => 'Конфиденциальность';

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
  String get shareMyDay => 'Поделиться';

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

  @override
  String get holdACardYouLike => 'Нравится? Удержите';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n понравились сегодня',
      many: '$n понравилось сегодня',
      few: '$n понравились сегодня',
      one: '$n понравилась сегодня',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Понравившиеся';

  @override
  String likedN(int n) {
    return 'Понравившиеся · $n';
  }

  @override
  String get nothingLikedYet => 'Пока ничего не понравилось';

  @override
  String get likeThisPill => 'Нравится эта карточка';

  @override
  String get removeFromLiked => 'Убрать из понравившихся';

  @override
  String get removedFromLiked => 'Убрано из понравившихся.';

  @override
  String get lessLikeThis => 'Меньше таких';

  @override
  String get whatYouLikedLandsHere => 'Те, что вы перечитали бы';

  @override
  String get holdToLikeLandsHere =>
      'Удержите карточку, которая вам понравилась, и она окажется здесь — а приложение даст больше таких.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Нажмите на закладку на карточке, и она окажется здесь — те, что изменили ваше мышление, сохранены.';

  @override
  String get nudgeTitle => 'Ваши пять готовы';

  @override
  String get nudgeFreezeTitle => 'Ваша заморозка держится';

  @override
  String nudgeFreezeBody(String question) {
    return 'Вчера закрыто. Сегодня: $question';
  }

  @override
  String get nudgeSureTitle => 'В этой вы были уверены';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — вы сказали $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Две недели назад вы прочли $read карточек';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Ваша уверенность отклонялась на $gap пунктов. Сегодня: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return 'Пока $answered ответов. Сегодня: $question';
  }

  @override
  String get friends => 'Друзья';

  @override
  String friendsN(int n) {
    return 'Друзья · $n';
  }

  @override
  String get yourFriendCode => 'Ваш код друга';

  @override
  String get codeCopied => 'Код скопирован.';

  @override
  String get addAFriend => 'Добавить друга';

  @override
  String get theirCode => 'Его код';

  @override
  String get add => 'Добавить';

  @override
  String get noFriendsYet =>
      'Пока никого. Обменяйтесь кодами с другом и сравнивайте серии и калибровку — никогда ответы.';

  @override
  String get friendsNeedAnAccount =>
      'Для сравнения нужны приложение на телефоне и аккаунт. Ваши коды сохраняются.';

  @override
  String get noReaderWithCode => 'Нет читателя с таким кодом.';

  @override
  String get thatsYourOwnCode => 'Это ваш собственный код.';

  @override
  String pointsOff(int n) {
    return '$n пунктов отклонения';
  }

  @override
  String get notMeasuredYet => 'ещё не измерена';

  @override
  String get thisWeekByCalibration => 'На этой неделе, по калибровке';

  @override
  String get notYetToday => 'сегодня ещё нет';

  @override
  String nOfSeven(int n) {
    return '$n из 7';
  }

  @override
  String get you => 'Вы';

  @override
  String get todaysQuestion => 'Вопрос дня';

  @override
  String get right => 'верно';

  @override
  String get wrong => 'неверно';

  @override
  String rightAtSure(int sure) {
    return 'верно, уверенность $sure%';
  }

  @override
  String wrongAtSure(int sure) {
    return 'неверно, уверенность $sure%';
  }

  @override
  String get yourJourney => 'Ваш путь';

  @override
  String get thePath => 'Дорога';

  @override
  String get youAreHere => 'ВЫ ЗДЕСЬ';

  @override
  String reachedOn(String date) {
    return 'Достигнуто $date';
  }

  @override
  String readSoFar(int n, int of) {
    return 'Пока прочитано $n из $of';
  }

  @override
  String nRead(int n) {
    return '$n прочитано';
  }

  @override
  String get topLevel => 'Высший уровень';

  @override
  String plusNToday(int n) {
    return '+$n сегодня';
  }

  @override
  String get bySubject => 'По темам';

  @override
  String get pts => 'очков';

  @override
  String nStillWithYou(int n) {
    return '$n ещё с вами';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n приёма',
      many: '$n приёмов',
      few: '$n приёма',
      one: '$n приём',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'Ваш счёт начинается с сегодняшней пятёрки.';

  @override
  String get anonymousUsage => 'Данные об использовании';

  @override
  String get anonymousUsageLine =>
      'Как используется приложение — что прочитано, сохранено и сказано вслух и что пошло не так, — чтобы следующие карточки были лучше. Никогда ваше имя, почта или то, что вы пишете.';

  @override
  String get usageOn => 'Передаются — без вашего имени и ваших слов.';

  @override
  String get usageOff => 'Больше ничего не измеряется.';

  @override
  String get yourMix => 'Твой микс';

  @override
  String get genresLine =>
      'Коснись жанра, чтобы пропустить его. Задержи — и три ветки внутри откроются прямо под ним.';

  @override
  String get insideGenre => 'Внутри';

  @override
  String nOfSixOn(int n, int total) {
    return '$n из $total включено';
  }

  @override
  String get offInYourMix => 'вне твоего микса';

  @override
  String continueGenresOn(int on, int total) {
    return 'Дальше · $on из $total жанров включено';
  }

  @override
  String get mixRarely => 'Редко';

  @override
  String get mixSometimes => 'Иногда';

  @override
  String get mixOften => 'Часто';

  @override
  String get mixALot => 'Много';

  @override
  String get mixFull => 'По максимуму';

  @override
  String get forYouChip => 'ДЛЯ ТЕБЯ';

  @override
  String get againChip => 'СНОВА';

  @override
  String get magicLine =>
      'Пять карточек в день, выбранных для тебя: из твоего микса, на твоём уровне, ни одной уже прочитанной. С завтрашнего дня.';

  @override
  String get everyCardForYou => 'Каждая карточка — выбрана для тебя.';

  @override
  String get perkOwnTitle => 'Пять карточек в день, все твои';

  @override
  String get perkOwnLine =>
      'Из твоих веток, на твоём уровне, ни одной уже прочитанной. Бесплатно — две в день.';

  @override
  String get plusCardHeadline => 'Все пять — твои.';

  @override
  String get plusCardLine =>
      'Пять карточек в день из твоего микса, на твоём уровне. Твой путь. Весь твой архив.';

  @override
  String get continueFree => 'Продолжить бесплатно';

  @override
  String get archiveBeforeThisWeek => 'До этой недели';

  @override
  String get weekKeptThreeOwn => 'Неделя подряд: завтра три из пяти — твои.';

  @override
  String get perkJourneyLine =>
      'Твой уровень, каждый предмет по веткам, что осталось, и карточка, о которой рассказать сегодня вечером.';

  @override
  String get topOfTheWeek => 'Топ недели';

  @override
  String get topOfTheMonth => 'Топ месяца';

  @override
  String topIn(String subject) {
    return 'Топ: $subject';
  }

  @override
  String get topLineWeek =>
      'Чаще всего нравились, сохранялись и пересказывались за 7 дней';

  @override
  String get topLineMonth =>
      'Чаще всего нравились, сохранялись и пересказывались за 30 дней';

  @override
  String get topWeek => 'Неделя';

  @override
  String get topMonth => 'Месяц';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n читателя',
      many: '$n читателей',
      few: '$n читателя',
      one: '$n читатель',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'В списке пока пусто. Считается каждая карточка, которую лайкнули, сохранили или рассказали.';

  @override
  String get readMark => 'Прочитано';

  @override
  String get lovedSinceTheStart => 'Самые любимые с самого начала';

  @override
  String lovedIn(String subject) {
    return 'Самые любимые: $subject';
  }

  @override
  String get lovedLine =>
      'То, что читатели сохраняли чаще всего, а вы ещё не читали';

  @override
  String get forYouShelf => 'Для вас';

  @override
  String get forYouLine => 'То, что ваше чтение ставит на первое место';

  @override
  String get exploreOffline =>
      'Вы офлайн. Это раздел «Обзор» в том виде, в каком он был прочитан в последний раз.';

  @override
  String get askYourselfCaps => 'СПРОСИ СЕБЯ';

  @override
  String get themeMyths => 'Развенчанные мифы';

  @override
  String get themeMythsLine => 'Во что верят почти все и почему это неверно';

  @override
  String get themeParadoxes => 'Парадоксы';

  @override
  String get themeParadoxesLine =>
      'Две правды, которые не должны быть верны одновременно';

  @override
  String get themeNumbers => 'Удивительные числа';

  @override
  String get themeNumbersLine => 'Где поворот — это число';

  @override
  String get themePractical => 'Пригодится сегодня';

  @override
  String get themePracticalLine => 'Что попробовать до вечера';

  @override
  String get themeOrigins => 'Откуда это взялось';

  @override
  String get themeOriginsLine =>
      'Истоки вещей, которыми вы пользуетесь каждый день';

  @override
  String get themeStories => 'Правдивые истории';

  @override
  String get themeStoriesLine => 'То, что случилось на самом деле';

  @override
  String get themeDebates => 'Выберите сторону';

  @override
  String get themeDebatesLine => 'Нет верного ответа, есть лишь лучший довод';

  @override
  String get themeWorkItOut => 'Посчитайте';

  @override
  String get themeWorkItOutLine => 'Число, которое найти в уме';

  @override
  String get themeSeen => 'Посмотреть';

  @override
  String get themeSeenLine => 'Карточки, которые рисуют свою мысль';

  @override
  String get themeSharpest => 'Для самых острых умов';

  @override
  String get themeSharpestLine => 'Самые трудные карточки';

  @override
  String get themePast0 => 'Древний мир';

  @override
  String get themePast1 => 'XVII–XIX века';

  @override
  String get themePast2 => 'Прошлый век';

  @override
  String get themePastLine => 'Каждый раз другая эпоха';

  @override
  String get themePlace0 => 'Азия и Ближний Восток';

  @override
  String get themePlace1 => 'Америка';

  @override
  String get themePlace2 => 'Европа';

  @override
  String get themePlaceLine => 'Каждый раз другая часть света';

  @override
  String get themeTrueOrFalse => 'Правда или ложь?';

  @override
  String get themeTrueOrFalseLine =>
      'Реши, прежде чем перевернуть. Почти все ошибаются';

  @override
  String get themeReasoning => 'Только рассуждение';

  @override
  String get themeReasoningLine =>
      'Ничего не нужно запоминать: только способ подумать';

  @override
  String get themeIdeas => 'Большие идеи';

  @override
  String get themeIdeasLine => 'Теория, стоящая за вещами, по одной идее';

  @override
  String get themeCurious => 'Просто любопытно';

  @override
  String get themeCuriousLine => 'Ради удовольствия узнать почему';

  @override
  String get themeMoving => 'В движении';

  @override
  String get themeMovingLine => 'То, что меняется сейчас, и почему это важно';

  @override
  String get themeHowItWorks => 'Как это устроено на самом деле';

  @override
  String get themeHowItWorksLine => 'Механизм того, что ты видишь каждый день';

  @override
  String get themePuzzles => 'Головоломки';

  @override
  String get themePuzzlesLine => 'Задачки на ручку и минуту';

  @override
  String get weekRecapCaps => 'НА ЭТОЙ НЕДЕЛЕ ТЫ СПРАШИВАЛ СЕБЯ';

  @override
  String get weekRecapLine => 'Вопросы, которые оставили тебе карточки';

  @override
  String weekRecapMore(int n) {
    return 'Ещё $n за неделю с Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ — в приложении: скачай Astute на iPhone или Android, чтобы начать бесплатный период.';

  @override
  String get purchaseComplete => 'Покупка завершена.';

  @override
  String get successWelcome =>
      'Добро пожаловать в Astute+. Пять сегодняшних карточек готовы.';

  @override
  String successWelcomeNamed(String name) {
    return 'Добро пожаловать в Astute+, $name. Пять сегодняшних карточек готовы.';
  }

  @override
  String get successFiveCards => '5 карточек в день';

  @override
  String get successArchive => 'Весь архив';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Бесплатно до $date, затем $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Продление $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Чек';

  @override
  String get letsStart => 'Начнём';

  @override
  String successFootFirstCharge(String date) {
    return 'Первое списание $date · отмена в любой момент';
  }

  @override
  String successFootRenews(String date) {
    return 'Продление $date · отмена в любой момент';
  }

  @override
  String get tryToday => 'ПОПРОБУЙ СЕГОДНЯ';

  @override
  String minutesShort(int n) {
    return '$n МИН';
  }

  @override
  String get sideOr => 'или';

  @override
  String get nextStep => 'Следующий шаг';

  @override
  String get showAllSteps => 'Показать всё';

  @override
  String get revealSeePicture => 'Посмотреть рисунок';

  @override
  String get revealPlayScene => 'Попробовать самому';

  @override
  String get revealBackToAnswer => 'Вернуться к ответу';

  @override
  String get revealShowWorking => 'Показать решение';

  @override
  String get sceneLockIn => 'ГОТОВО';

  @override
  String get sceneYou => 'ВЫ';

  @override
  String get sceneTruth => 'ИСТИНА';

  @override
  String get sceneTryAgain => 'Ещё раз';

  @override
  String get sceneDrawHint => 'Нарисуйте догадку пальцем';

  @override
  String get sceneHoldHint => 'Нажмите и держите';

  @override
  String get sceneSwipeHint => 'Смахните или нажмите';

  @override
  String get sceneTapToPick => 'Нажмите свой вариант';

  @override
  String get sceneShowMe => 'Покажите';

  @override
  String get sceneYourGuess => 'Ваша догадка';

  @override
  String sceneNOfM(int n, int m) {
    return '$n из $m';
  }

  @override
  String get reportProblem => 'Сообщить о проблеме';

  @override
  String get reportedThanks => 'Отправлено. Спасибо.';

  @override
  String get reportTitle => 'Что не так с этой карточкой?';

  @override
  String get reportLead =>
      'Мы сверяем каждое сообщение с источниками и исправляем карточку.';

  @override
  String get reportFact => 'Неверный факт';

  @override
  String get reportAnswer => 'Ответ, отмеченный как верный, неверен';

  @override
  String get reportSource => 'Источник этого не подтверждает';

  @override
  String get reportUnclear => 'Непонятно';

  @override
  String get reportTypo => 'Опечатка или сбитая строка';

  @override
  String get reportOther => 'Другое';

  @override
  String get reportNoteHint => 'Что поможет нам проверить (необязательно)';

  @override
  String get reportSend => 'Отправить';

  @override
  String get reportSentToast => 'Спасибо. Мы проверим.';

  @override
  String get journeyPointsOff => 'пунктов отклонения';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ещё $n ответа с уверенностью — и будет измерено.',
      many: 'Ещё $n ответов с уверенностью — и будет измерено.',
      few: 'Ещё $n ответа с уверенностью — и будет измерено.',
      one: 'Ещё $n ответ с уверенностью — и будет измерено.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Ваш счёт';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'очка',
      many: 'очков',
      few: 'очка',
      one: 'очко',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n за 4 недели';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На этой неделе вы пока набрали $n очка.',
      many: 'На этой неделе вы пока набрали $n очков.',
      few: 'На этой неделе вы пока набрали $n очка.',
      one: 'На этой неделе вы пока набрали $n очко.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'За неделю с $date вы набрали $n очка.',
      many: 'За неделю с $date вы набрали $n очков.',
      few: 'За неделю с $date вы набрали $n очка.',
      one: 'За неделю с $date вы набрали $n очко.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
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
  String journeyScoreCaption(String date) {
    return 'Ваш счёт на конец каждой недели с $date. Коснитесь точки, чтобы открыть эту неделю.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Уровень $n из $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\nдо уровня «$rung»';
  }

  @override
  String journeyToGoCards(int n) {
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
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ответа',
      many: '$n ответов',
      few: '$n ответа',
      one: '$n ответ',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ответа с уверенностью',
      many: '$n ответов с уверенностью',
      few: '$n ответа с уверенностью',
      one: '$n ответ с уверенностью',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n удержанной карточки',
      many: '$n удержанных карточек',
      few: '$n удержанные карточки',
      one: '$n удержанная карточка',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n пункта',
      many: '$n пунктов',
      few: '$n пункта',
      one: '$n пункт',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Эквивалент';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n книги',
      many: '$n книг',
      few: '$n книги',
      one: '$n книга',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'или $h ч документального кино';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n до первой книги',
      many: 'ещё $n до первой книги',
      few: 'ещё $n до первой книги',
      one: 'ещё $n до первой книги',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'Подряд';

  @override
  String journeyDays(int n) {
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
  String journeyBestActive(int best, int active, int days) {
    return 'Рекорд $best · $active из $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n из $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'тем · пунктир: $month';
  }

  @override
  String get journeySubjects => 'тем';

  @override
  String get journeyHowHard => 'Сложность';

  @override
  String get journeyOfThree => 'из 3';

  @override
  String get journeyHardNow => 'Карточки, которые вы открываете.';

  @override
  String journeyHardThen(String v, String month) {
    return 'Карточки, которые вы открываете. $v за $month';
  }

  @override
  String get journeyReadingTime => 'Время чтения';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h ч $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m мин';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now мин в неделю, было $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m мин на этой неделе';
  }

  @override
  String get journeyTimedFromToday => 'Отсчёт с сегодняшнего дня';

  @override
  String journeyPointsOffFrom(int was) {
    return 'пунктов отклонения, было $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · макс. $n';
  }

  @override
  String get journeyRightWhenSure => 'Верно, если уверены';

  @override
  String journeyFromIn(String v, String month) {
    return 'За $month: $v';
  }

  @override
  String get journeySureNone => 'Пока нет ответов на 80% и выше';

  @override
  String get journeyMovesTitle => 'Замеченные приёмы';

  @override
  String journeyOfN(int n) {
    return 'из $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Последний: $name';
  }

  @override
  String get journeyNoneYet => 'Пока нет';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'карточки ещё с вами',
      many: 'карточек ещё с вами',
      few: 'карточки ещё с вами',
      one: 'карточка ещё с вами',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return '$right из $of спустя $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks недели',
      many: '$weeks недель',
      few: '$weeks недели',
      one: '$weeks неделю',
    );
    return '$right из $of спустя $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дней',
      one: '$days дня',
    );
    return '$active из $_temp0';
  }

  @override
  String get journeyMostlyMorning => 'Чаще утром';

  @override
  String get journeyMostlyAfternoon => 'Чаще днём';

  @override
  String get journeyMostlyEvening => 'Чаще вечером';

  @override
  String get journeyMostlyNight => 'Чаще ночью';

  @override
  String get journeyInTime => 'Во времени';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString года',
      many: '$nString лет',
      few: '$nString года',
      one: '$nString год',
    );
    return '$_temp0';
  }

  @override
  String journeyFromEra(String era) {
    return 'от $era до наших дней';
  }

  @override
  String get journeyEraAncient => 'древности';

  @override
  String get journeyEraMedieval => 'Средневековья';

  @override
  String get journeyEraEarlyModern => 'XVI века';

  @override
  String get journeyEraNineteenth => 'XIX века';

  @override
  String get journeyEraTwentieth => 'XX века';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'пока без дат';

  @override
  String get journeyInPlace => 'По миру';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n региона',
      many: '$n регионов',
      few: '$n региона',
      one: '$n регион',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list и космос';
  }

  @override
  String get journeyRegionAmericas => 'Америка';

  @override
  String get journeyRegionEurope => 'Европа';

  @override
  String get journeyRegionAsia => 'Азия';

  @override
  String get journeyRegionOceania => 'Океания';

  @override
  String get journeyRegionAfrica => 'Африка';

  @override
  String get journeyRegionMiddleEast => 'Ближний Восток';

  @override
  String get journeyNoPlace => 'пока нигде';

  @override
  String get journeyTopics => 'Подтемы';

  @override
  String journeyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n знакомой',
      many: '$n знакомых',
      few: '$n знакомые',
      one: '$n знакомая',
    );
    return '$_temp0';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n из них в теме $subject';
  }

  @override
  String get journeyWords => 'Слова';

  @override
  String journeyNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n нового',
      many: '$n новых',
      few: '$n новых',
      one: '$n новое',
    );
    return '$_temp0';
  }

  @override
  String get aMove => 'Приём';

  @override
  String get anotherOne => 'Другую';

  @override
  String answerIs(String said) {
    return 'Ответ: $said';
  }

  @override
  String get answeredAlready => 'Уже отвечено';

  @override
  String get anyCard => 'Любая тема, любая полка, одна карточка';

  @override
  String betN(int n) {
    return 'Ставка $n';
  }

  @override
  String get betSlip => 'Ваш купон';

  @override
  String get betWord => 'Поставить';

  @override
  String get biggerLabel => 'Больше';

  @override
  String get biggerNote => 'Каждое число — ответ одной из карточек.';

  @override
  String biggerScore(int right, int asked) {
    return 'Верно: $right из $asked.';
  }

  @override
  String get biggerYouGotIt => 'Больше · верно';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Через $n дня',
      many: 'Через $n дней',
      few: 'Через $n дня',
      one: 'Через $n день',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'Через неделю';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Через $n недели',
      many: 'Через $n недель',
      few: 'Через $n недели',
      one: 'Через $n неделю',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Проверить';

  @override
  String closerDone(String said, int right, int steps) {
    return 'Это $said. Верно $right из $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'Нет: меньше $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'Нет: больше $v.';
  }

  @override
  String get closerStart => 'Три шага, чтобы подобраться.';

  @override
  String closerYesLess(String v) {
    return 'Верно: меньше $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Верно: больше $v.';
  }

  @override
  String get corrections => 'Поправки';

  @override
  String get didYouKnow => 'А вы знали?';

  @override
  String get didYouKnowLine => 'Переверните, а потом: новое для вас или знали?';

  @override
  String get dragToSet => 'Перетащите';

  @override
  String get dykAgain => 'Ещё раз';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n знакомых',
      many: '$n знакомых',
      few: '$n знакомые',
      one: '$n знакомая',
      zero: 'Знакомых нет',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n новых для вас',
      many: '$n новых для вас',
      few: '$n новые для вас',
      one: '$n новая для вас',
      zero: 'Сегодня ничего нового',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'Это сегодняшний выпуск';

  @override
  String get editionTomorrow => 'Завтрашний выйдет утром';

  @override
  String get eraAncient => 'Древний мир';

  @override
  String get eraAncientWhen => 'До 500 года';

  @override
  String get eraEarlyModern => 'Раннее Новое время';

  @override
  String get eraEarlyModernWhen => '1500–1800 годы';

  @override
  String get eraMedieval => 'Средние века';

  @override
  String get eraMedievalWhen => '500–1500 годы';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ещё $n из этой эпохи',
      many: 'Ещё $n из этой эпохи',
      few: 'Ещё $n из этой эпохи',
      one: 'Ещё $n из этой эпохи',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'XIX век';

  @override
  String get eraNineteenthWhen => '1800–1900 годы';

  @override
  String get eraRecent => 'Этот век';

  @override
  String get eraRecentWhen => 'С 2000 года';

  @override
  String get eraRulerNow => 'Сейчас';

  @override
  String get eraRulerOld => 'Древность';

  @override
  String get eraShortAncient => 'Древность';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Средневековье';

  @override
  String get eraShortNineteenth => 'XIX век';

  @override
  String get eraShortRecent => 'XXI век';

  @override
  String get eraShortTwentieth => 'XX век';

  @override
  String get eraTwentieth => 'Прошлый век';

  @override
  String get eraTwentiethWhen => '1900–2000 годы';

  @override
  String get fewCards => 'В нескольких карточках';

  @override
  String get fewCardsLine => 'Когда одной карточки мало, чтобы объяснить';

  @override
  String get firstLabel => 'С';

  @override
  String get forYouNow => 'Для вас, прямо сейчас';

  @override
  String get goNarrow => 'Сужайте, когда уверены: это приносит втрое больше.';

  @override
  String get hardBadge => 'Сложно';

  @override
  String hidesIn(String where) {
    return 'Где: $where';
  }

  @override
  String get howSure => 'Насколько я уверен — и почему?';

  @override
  String get inNumbers => 'В цифрах';

  @override
  String inRange(int pts, String said) {
    return 'Попали: +$pts очков. Это $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'В ваших приёмах · $n×';
  }

  @override
  String itIs(String said) {
    return 'Это $said.';
  }

  @override
  String get knewIt => 'Знаю';

  @override
  String get less => 'Меньше';

  @override
  String get lookFirst => 'Посмотрите на график, прежде чем верить заголовку.';

  @override
  String get markTried => 'Попробовано';

  @override
  String minutesLabel(int n) {
    return '$n мин';
  }

  @override
  String missedRange(String said) {
    return 'Мимо: это $said.';
  }

  @override
  String get modeBigger => 'Что больше?';

  @override
  String get modeBiggerLine =>
      'Два числа, которые можно оценить. Нажмите на большее';

  @override
  String get modeCloser => 'Ближе и ближе';

  @override
  String get modeCloserLine =>
      'Три шага «больше или меньше», чтобы подобраться к числу';

  @override
  String get modePick => 'Выберите';

  @override
  String get modePickLine =>
      'Три варианта. Решите до того, как откроете карточку';

  @override
  String get modeRange => 'Ставка на диапазон';

  @override
  String get modeRangeLine => 'Чем уже, тем больше выигрыш — если угадаете';

  @override
  String get modeSlide => 'Двигайте';

  @override
  String get modeSlideLine =>
      'Сначала задайте ответ, потом посмотрите, насколько ошиблись';

  @override
  String get modeStake => 'Делайте ставку';

  @override
  String modeStakeLine(int n) {
    return '$n очков в день. Выиграете — ставка удвоится';
  }

  @override
  String get monthShelfLine => 'Каждый месяц новая тема, одна на всех';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards карточки',
      many: '$cards карточек',
      few: '$cards карточки',
      one: '$cards карточка',
    );
    return '$_temp0 · $minutes мин';
  }

  @override
  String get moodTime => 'Сколько у вас времени';

  @override
  String get moodTitle => 'Ваше настроение, ваши минуты';

  @override
  String get moodTone => 'Тон';

  @override
  String get more => 'Больше';

  @override
  String moreOrLess(String v) {
    return 'Больше или меньше $v?';
  }

  @override
  String get moveComparedToWhat => 'По сравнению с чем';

  @override
  String get moveComparedToWhatLine =>
      'Изменение ничего не значит без контрольной группы';

  @override
  String get moveSampling => 'Выборка';

  @override
  String get moveSamplingLine =>
      'Кто попал в выборку, то и решает, о чём она говорит';

  @override
  String mythDeckHint(int at, int of) {
    return '$at из $of · смахните, чтобы перевернуть';
  }

  @override
  String nOfM(int at, int of) {
    return '$at из $of';
  }

  @override
  String get newMove => 'Новое для вас';

  @override
  String get newToMe => 'Новое для меня';

  @override
  String get notEnoughPoints => 'Недостаточно очков';

  @override
  String get notSureLine => 'Одна карточка из любого уголка Astute';

  @override
  String get notSureTitle => 'Не знаете, с чего начать?';

  @override
  String get openWord => 'Открыть';

  @override
  String get pickOneFirst => 'Сначала выберите';

  @override
  String pointsToday(int n) {
    return '+$n сегодня';
  }

  @override
  String get puzzleOfTheDay => 'Задача дня';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts оч.';
  }

  @override
  String get rightLastTime => 'В прошлый раз верно';

  @override
  String get sameForEveryoneCaps => 'Один на всех';

  @override
  String get sayFalse => 'Ложь';

  @override
  String get sayTrue => 'Правда';

  @override
  String get seriesAnchors => 'Первые впечатления';

  @override
  String get seriesGrowth => 'Числа, которые убегают';

  @override
  String seriesMeta(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки',
      many: '$n карточек',
      few: '$n карточки',
      one: '$n карточка',
    );
    return '$_temp0 · около $m мин';
  }

  @override
  String get seriesOdds => 'Обманчивые вероятности';

  @override
  String get seriesRetold => 'История заново';

  @override
  String seriesStrand(String name) {
    return '$name в нескольких карточках';
  }

  @override
  String get seriesStudies => 'Почему исследования вводят в заблуждение';

  @override
  String showAllN(int n) {
    return 'Показать все $n';
  }

  @override
  String get showFewer => 'Свернуть';

  @override
  String get sixtyAgain => 'Сыграть ещё';

  @override
  String sixtyIn(int s) {
    return 'за $s с';
  }

  @override
  String get sixtyLine => 'Восемь «правда или ложь». Доверьтесь чутью';

  @override
  String get sixtyPerfect => 'Все восемь верно.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Пока $n верных',
      many: 'Пока $n верных',
      few: 'Пока $n верных',
      one: 'Пока $n верный',
      zero: 'Пока ни одного верного',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'секунд на восемь\n«правда или ложь»';

  @override
  String sixtySecondsLeft(int s) {
    return '$s с';
  }

  @override
  String get sixtyStart => 'Начать';

  @override
  String get sixtyTimeUp => 'пока не вышло время';

  @override
  String get sixtyTitle => 'Шестьдесят секунд';

  @override
  String slideAverage(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'В среднем ошибка $n пункта.',
      many: 'В среднем ошибка $n пунктов.',
      few: 'В среднем ошибка $n пункта.',
      one: 'В среднем ошибка $n пункт.',
      zero: 'В среднем точно.',
    );
    return '$_temp0';
  }

  @override
  String get slideNote => 'Задайте, проверьте. Важно, насколько вы ошиблись.';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ошибка $n пункта.',
      many: 'Ошибка $n пунктов.',
      few: 'Ошибка $n пункта.',
      one: 'Ошибка $n пункт.',
      zero: 'Точно.',
    );
    return '$_temp0';
  }

  @override
  String get slipEmpty => 'Ставок пока нет. Каждая будет здесь.';

  @override
  String get stakeLabel => 'Ставка';

  @override
  String stepOf(int at, int of) {
    return 'Шаг $at из $of';
  }

  @override
  String get surpriseMe => 'Удивите меня';

  @override
  String get tapIfBigger => 'Нажмите, если больше';

  @override
  String get tapToTurn => 'Нажмите, чтобы перевернуть';

  @override
  String get tfRight => 'Верно. Откройте, чтобы узнать почему.';

  @override
  String tfWrong(String side) {
    return 'Это $side. Откройте, чтобы узнать почему.';
  }

  @override
  String theAnswer(String said) {
    return 'Ответ: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'Главное';

  @override
  String get throughTime => 'Сквозь время';

  @override
  String get throughTimeLine =>
      'От древнего мира до наших дней. Перетащите, чтобы путешествовать';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get todaysEdition => 'Сегодняшний выпуск';

  @override
  String get toneCurious => 'Любопытно';

  @override
  String get toneLight => 'Легко';

  @override
  String get toneSerious => 'Серьёзно';

  @override
  String get toneTough => 'Сложно';

  @override
  String get unmaskBack => 'Показать как было';

  @override
  String get unmaskFlipped => 'Перевернуть правильно';

  @override
  String get unmaskLine => 'Те же числа, другая картина';

  @override
  String get unmaskStretched => 'Честный масштаб';

  @override
  String get unmaskTitle => 'Разоблачите график';

  @override
  String get unmaskTotals => 'Сравнить честно';

  @override
  String get unmaskTruncated => 'Начать ось с нуля';

  @override
  String get unmaskWindow => 'Показать весь ряд';

  @override
  String get whatIfTrue => 'А если это правда?';

  @override
  String get whatIfTrueLine =>
      'Карточки, которые продолжают работать после того, как вы их закрыли';

  @override
  String get whatYouBelieve => 'Во что вы верите';

  @override
  String get wrongLastTime => 'В прошлый раз неверно';

  @override
  String youLose(int n) {
    return 'Вы теряете $n.';
  }

  @override
  String youWin(int n) {
    return 'Вы выигрываете $n.';
  }

  @override
  String get yourPick => 'Ваш выбор';
}
