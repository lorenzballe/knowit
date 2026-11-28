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
  String dayTitle(int n) {
    return 'День $n';
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
  String get saveThisPill => 'Сохранить эту карточку';

  @override
  String get shareThisPill => 'Поделиться карточкой';

  @override
  String get share => 'Поделиться';

  @override
  String cardOf(int k, int n) {
    return 'Карточка $k из $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Завтрашняя пятёрка · через $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return 'Завтра: $topic · через $when';
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Искать среди $n карточки',
      many: 'Искать среди $n карточек',
      few: 'Искать среди $n карточек',
      one: 'Искать среди $n карточки',
    );
    return '$_temp0';
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
      'Под этот фильтр пока не подходит ни одна карточка.';

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
  String get backToTodaysFive => 'К сегодняшней пятёрке';

  @override
  String get archive => 'Архив';

  @override
  String get yourWeek => 'Твоя неделя';

  @override
  String get nothingThisWeekYet =>
      'На этой неделе пока ничего. Пять карточек её начнут.';

  @override
  String keptDaysOfSeven(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Засчитана — $_temp0 из семи.';
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
    String _temp0 = intl.Intl.pluralLogic(
      gap,
      locale: localeName,
      other: '$gap пункта',
      many: '$gap пунктов',
      few: '$gap пункта',
      one: '$gap пункт',
    );
    return 'Твоя уверенность отклонялась на $_temp0 от того, что ты знал на самом деле.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    String _temp0 = intl.Intl.pluralLogic(
      gap,
      locale: localeName,
      other: '$gap пункта',
      many: '$gap пунктов',
      few: '$gap пункта',
      one: '$gap пункт',
    );
    return 'Уверенность отклонялась на $_temp0 против $before на прошлой неделе. Разрыв сокращается.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    String _temp0 = intl.Intl.pluralLogic(
      gap,
      locale: localeName,
      other: '$gap пункта',
      many: '$gap пунктов',
      few: '$gap пункта',
      one: '$gap пункт',
    );
    return 'Уверенность отклонялась на $_temp0 против $before на прошлой неделе. Разрыв вырос.';
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n карточки прочитать',
      many: 'ещё $n карточек прочитать',
      few: 'ещё $n карточки прочитать',
      one: 'ещё $n карточку прочитать',
    );
    return '$_temp0';
  }

  @override
  String stepAnswer(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё на $n карточки ответить',
      many: 'ещё на $n карточек ответить',
      few: 'ещё на $n карточки ответить',
      one: 'ещё на $n карточку ответить',
    );
    return '$_temp0';
  }

  @override
  String stepJudge(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n ответа с оценкой уверенности',
      many: 'ещё $n ответов с оценкой уверенности',
      few: 'ещё $n ответа с оценкой уверенности',
      one: 'ещё $n ответ с оценкой уверенности',
    );
    return '$_temp0';
  }

  @override
  String stepHold(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n карточки удержать',
      many: 'ещё $n карточек удержать',
      few: 'ещё $n карточки удержать',
      one: 'ещё $n карточку удержать',
    );
    return '$_temp0';
  }

  @override
  String stepGap(int gap, int target) {
    String _temp0 = intl.Intl.pluralLogic(
      gap,
      locale: localeName,
      other: '$gap пункта',
      many: '$gap пунктов',
      few: '$gap пункта',
      one: '$gap пункт',
    );
    return 'твоя уверенность отклоняется на $_temp0 — хватит $target';
  }

  @override
  String stepBeforeJudged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n ответа, прежде чем приложение оценит твою уверенность',
      many: 'ещё $n ответов, прежде чем приложение оценит твою уверенность',
      few: 'ещё $n ответа, прежде чем приложение оценит твою уверенность',
      one: 'ещё $n ответ, прежде чем приложение оценит твою уверенность',
    );
    return '$_temp0';
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
      'curiosity': 'Любознательность',
      'observation': 'Наблюдательность',
      'method': 'Метод',
      'judgement': 'Здравомыслие',
      'insight': 'Понимание',
      'discernment': 'Зоркость',
      'acumen': 'Проницательность',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => 'Новый уровень';

  @override
  String levelUpGain(String skill, String n) {
    return 'Самый большой рост за неделю: $skill, $n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Пока $n ответа.',
      many: 'Пока $n ответов.',
      few: 'Пока $n ответа.',
      one: 'Пока $n ответ.',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => 'Уровень';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n очка до уровня «$level»',
      many: '$n очков до уровня «$level»',
      few: '$n очка до уровня «$level»',
      one: '$n очко до уровня «$level»',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ответа до уровня «$level»',
      many: '$n ответов до уровня «$level»',
      few: '$n ответа до уровня «$level»',
      one: '$n ответ до уровня «$level»',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => 'Высший уровень';

  @override
  String get levelShareTitle => 'Поделиться уровнем';

  @override
  String get signOutQuestion => 'Выйти?';

  @override
  String get signOutBody =>
      'Серия, сохранённые карточки и история остаются в аккаунте. Это удалит их с этого устройства.';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deletingAccount => 'Удаление аккаунта…';

  @override
  String get deleteAccountQuestion => 'Удалить аккаунт?';

  @override
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'ею управляют в настройках App Store.',
      'google': 'ею управляют в Google Play, в разделе «Платежи и подписки».',
      'other': 'ею управляют в магазине, где она была оформлена.',
    });
    return 'Аккаунт и его резервная копия удаляются навсегда, а это устройство начинает всё с начала. Подписка Astute+ при этом не отменяется: $_temp0';
  }

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
      'Удаляет всё на этом устройстве — серию, сохранённые карточки, ответы, историю оценок, темы и план — и открывает вступление заново.';

  @override
  String get wipeIt => 'Удалить';

  @override
  String get yourRecord => 'Твоя история';

  @override
  String get profileTodayFive => 'Пять на сегодня';

  @override
  String profileTodayOf(int read, int of) {
    return '$read из $of';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ещё $n',
      many: 'ещё $n',
      few: 'ещё $n',
      one: 'ещё $n',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores => 'Все твои рейтинги, неделя за неделей';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'дня подряд',
      many: 'дней подряд',
      few: 'дня подряд',
      one: 'день подряд',
    );
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => 'Последние 7 дней';

  @override
  String profileWeekPoints(int n) {
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
  String get journeyButtonLine =>
      'Твой уровень, ходы, которые ты продолжаешь упускать, твоя неделя в вопросах';

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
  String get yourFivePillsBeforeCoffee => 'Твои 5 карточек, до первого кофе.';

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
  String get yourCards => 'Твои карточки';

  @override
  String get emptyLikedHint => 'Удержите карточку, которая понравилась';

  @override
  String get emptySavedHint => 'Нажмите на закладку на карточке';

  @override
  String get lastSevenDays => 'Последние 7 дней';

  @override
  String get accountSection => 'Аккаунт';

  @override
  String get aboutSection => 'О приложении';

  @override
  String get manageSubscription => 'Управлять подпиской';

  @override
  String get howPillsAreWritten => 'Как пишутся карточки';

  @override
  String get howTitle => 'Каждую карточку здесь пишет ИИ-модель.';

  @override
  String get howIntro =>
      'Лучше скажем сразу, чем ты узнаешь сам. Вот как карточка доходит до тебя.';

  @override
  String get howStep1Title => 'Написана заранее, моделью';

  @override
  String get howStep1Line =>
      'Каждая карточка пишется по одному заданию: вопрос, который стоит задать, ответ, объясняющий почему, и один ход, который пригодится снова.';

  @override
  String get howStep2Title => 'С источниками, потом глазами критика';

  @override
  String get howStep2Line =>
      'Каждая карточка называет, откуда её факты, и три из четырёх одним касанием ведут к первоисточнику: всё можно проверить самостоятельно. Большинство читает вторая модель в роли критика, а то, что она не может подтвердить, попадает в список, который проверяет человек. Этот список пока не пуст.';

  @override
  String get howStep3Title => 'Пять, каждое утро';

  @override
  String get howStep3Line =>
      'Из тем, которые ты выбрал, — карточки, которых ты ещё не читал. Та, на которую ты ответил верно, вернётся позже: проверить, запомнилась ли.';

  @override
  String get howStep4Title => 'Читатели следят за честностью';

  @override
  String get howStep4Line =>
      'Когда достаточно читателей говорят, что карточка ошибочна, её перестают раздавать, пока её не проверит человек.';

  @override
  String get howReportTitle => 'Нашёл ошибку?';

  @override
  String get howReportLine =>
      'Нажми на флажок рядом с источником карточки, чтобы сообщить о ней.';

  @override
  String get howFoot =>
      'Мы читаем каждое сообщение и скорее исправим карточку, чем станем её защищать.';

  @override
  String get signingIn => 'Вход…';

  @override
  String get signInWithApple => 'Войти через Apple';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String acrossNAnswersHowSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'В $n ответах ты отметил, насколько уверен. Вот что вышло.',
      many: 'В $n ответах ты отметил, насколько уверен. Вот что вышло.',
      few: 'В $n ответах ты отметил, насколько уверен. Вот что вышло.',
      one: 'В $n ответе ты отметил, насколько уверен. Вот что вышло.',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points пункта',
      many: '$points пунктов',
      few: '$points пункта',
      one: '$points пункт',
    );
    return 'Ты переоцениваешь себя на $_temp0';
  }

  @override
  String underconfidentBy(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points пункта',
      many: '$points пунктов',
      few: '$points пункта',
      one: '$points пункт',
    );
    return 'Ты недооцениваешь себя на $_temp0';
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
  String get shareMyRecord => 'Поделиться историей';

  @override
  String lastCallsAgainstFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Твои последние $n оценки против первых $n',
      many: 'Твои последние $n оценок против первых $n',
      few: 'Твои последние $n оценки против первых $n',
      one: 'Твоя последняя $n оценка против первых $n',
    );
    return '$_temp0';
  }

  @override
  String closedByPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n пункта',
      many: '$n пунктов',
      few: '$n пункта',
      one: '$n пункт',
    );
    return 'Сократился на $_temp0';
  }

  @override
  String openedByPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n пункта',
      many: '$n пунктов',
      few: '$n пункта',
      one: '$n пункт',
    );
    return 'Вырос на $_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n лишних',
      many: '$n лишних',
      few: '$n лишних',
      one: '$n лишний',
    );
    return '$_temp0';
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
  String get seeThePlans => 'Посмотреть тарифы';

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
      other: 'карточки прочитано',
      many: 'карточек прочитано',
      few: 'карточки прочитаны',
      one: 'карточка прочитана',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки прочитано',
      many: '$n карточек прочитано',
      few: '$n карточки прочитаны',
      one: '$n карточка прочитана',
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n возвращаются',
      many: '$n возвращаются',
      few: '$n возвращаются',
      one: '$n возвращается',
    );
    return '$_temp0';
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
  String get welcomeBack => 'С возвращением';

  @override
  String get comebackTitle => 'Рады видеть тебя снова.';

  @override
  String get comebackStillYours => 'Всё ещё твоё';

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
  String get reminderAskTitle => 'Во сколько тебе напоминать?';

  @override
  String get reminderAskLine =>
      'Одно уведомление в день — с вопросом из твоих карточек.';

  @override
  String get reminderAskTrialLine =>
      'Мы напомним тебе за два дня до конца пробного периода.';

  @override
  String get reminderAskMorning => 'Утром';

  @override
  String get reminderAskLunch => 'В обед';

  @override
  String get reminderAskEvening => 'Вечером';

  @override
  String get reminderAskOther => 'Другое время';

  @override
  String get reminderAskPick => 'Выбираешь ты';

  @override
  String get reminderAskUsual => 'Когда ты обычно читаешь';

  @override
  String get reminderAskYes => 'Напоминать';

  @override
  String get reminderAskNotNow => 'Не сейчас';

  @override
  String get placeAskTitle => 'Карточки о том, где ты живёшь';

  @override
  String get placeAskLine =>
      'Время от времени Astute будет давать тебе карточку о месте, где ты живёшь, — о его истории, науке и неожиданностях.';

  @override
  String get placeOnlyCity =>
      'Сохраняется только твой город, а не точное местоположение.';

  @override
  String get placeAskPreviewLine => 'Рядом с тобой · Модена';

  @override
  String get placeAskPreviewQuestion => 'Гирландина наклонена. Насколько?';

  @override
  String get placeAskYes => 'Использовать моё местоположение';

  @override
  String get placeAskNotNow => 'Не сейчас';

  @override
  String get placeRowTitle => 'Где ты живёшь';

  @override
  String get placeRowOff => 'Выключено';

  @override
  String get placeRowOffLine =>
      'Включи, чтобы получать карточки о месте, где ты живёшь.';

  @override
  String get placeSwitchOn => 'Включить';

  @override
  String get placeUseNow => 'Использовать местоположение сейчас';

  @override
  String get placeRemove => 'Удалить';

  @override
  String placeSetTo(String place) {
    return 'Где ты живёшь: $place';
  }

  @override
  String get placeRemoved => 'Удалено. Astute больше не хранит, где ты живёшь.';

  @override
  String get placeNotFound =>
      'Сейчас не удалось определить, где ты. Astute попробует в другой день.';

  @override
  String get placeDeniedNote =>
      'Ничего страшного. Это можно включить в профиле в любой момент.';

  @override
  String get placeServicesOff =>
      'На этом телефоне выключена геолокация. Включи её в настройках и попробуй ещё раз.';

  @override
  String get placeNotHere => 'Это устройство не может определить, где ты.';

  @override
  String get placeSettingsTitle => 'Геолокация для Astute выключена';

  @override
  String get placeSettingsBody =>
      'Чтобы получать карточки о месте, где ты живёшь, разреши Astute доступ к геолокации в настройках. Сохраняется только твой город.';

  @override
  String get placeSettingsOpen => 'Открыть настройки';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Пробный период Astute+ закончится через $days дня.',
      many: 'Пробный период Astute+ закончится через $days дней.',
      few: 'Пробный период Astute+ закончится через $days дня.',
      one: 'Пробный период Astute+ заканчивается завтра.',
      zero: 'Пробный период Astute+ заканчивается сегодня.',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return '$date начнётся твой год подписки за $price. Чтобы продолжить, ничего делать не нужно. Чтобы отменить: $path.';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Пробный период закончится через $days дня',
      many: 'Пробный период закончится через $days дней',
      few: 'Пробный период закончится через $days дня',
      one: 'Пробный период заканчивается завтра',
      zero: 'Пробный период заканчивается сегодня',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => 'Управлять';

  @override
  String subjectsInTheMix(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total темы',
      many: '$total тем',
      few: '$total тем',
      one: '$total темы',
    );
    return '$n из $_temp0 в миксе';
  }

  @override
  String get everythingIsInDrag =>
      'Всё включено. Сдвинь тему влево, чтобы видеть её реже, или до конца, чтобы убрать.';

  @override
  String get next => 'Дальше';

  @override
  String get whatShouldWeTalkAbout => 'О чём поговорим?';

  @override
  String get fivePillsADayPick =>
      'Пять карточек в день, каждое утро новые. Выбери темы для микса — потом их можно изменить.';

  @override
  String startWithNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Начать с $n темы',
      many: 'Начать с $n темами',
      few: 'Начать с $n темами',
      one: 'Начать с $n темой',
    );
    return '$_temp0';
  }

  @override
  String saveNTopics(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Сохранить $n темы',
      many: 'Сохранить $n тем',
      few: 'Сохранить $n темы',
      one: 'Сохранить $n тему',
    );
    return '$_temp0';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Выбери минимум $n';
  }

  @override
  String get swipeToSeeMore => 'Листай дальше';

  @override
  String get tagline =>
      'Пойми, почему всё так, и насколько можно доверять тому, что знаешь';

  @override
  String get introTopicsTitle => 'Двадцать тем, пять карточек';

  @override
  String get introTopicsLine =>
      'Написаны заранее моделью, и каждая называет свой источник.';

  @override
  String get introQuestionTitle => 'Вопрос, уверенность, потом — почему';

  @override
  String get introQuestionLine =>
      'Сначала отметь уверенность. Со временем узнаешь цену своему «точно».';

  @override
  String get introMixTitle => 'Микс выбираешь ты';

  @override
  String get introMixLine =>
      'Убавь тему, чтобы видеть её реже, или выключи совсем.';

  @override
  String get introThirtyTitle => 'Две минуты в день';

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
  String get startReading => 'Начать читать';

  @override
  String get haveAnAccount => 'Уже есть аккаунт?';

  @override
  String get signInLink => 'Войти';

  @override
  String get signInWelcomeTitle => 'С возвращением';

  @override
  String get signInWelcomeLine =>
      'Войди, и твоя серия, сохранённые карточки и история вернутся вместе с тобой.';

  @override
  String get keepStreakOnNewPhone => 'Сохрани серию на новом телефоне';

  @override
  String get keepStreakTitle => 'Не потеряй серию';

  @override
  String get keepStreakLine =>
      'Войди, и новый телефон продолжит с того места, где остановился этот: твоя серия, сохранённые карточки, твоя история.';

  @override
  String get signInNotNow => 'Не сейчас';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': 'Мышление',
      'science': 'Наука',
      'maths': 'Математика',
      'space': 'Космос',
      'psychology': 'Психология',
      'economics': 'Экономика',
      'technology': 'Технологии',
      'history': 'История',
      'human_body': 'Тело человека',
      'philosophy': 'Философия',
      'pop_culture': 'Поп-культура',
      'nature': 'Природа',
      'language': 'Язык',
      'weird_facts': 'Курьёзы',
      'sport': 'Спорт',
      'cinema': 'Кино',
      'music': 'Музыка',
      'art': 'Искусство',
      'medicine': 'Медицина',
      'food': 'Еда',
      'life': 'Жизнь',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get cardsInEnglishNote =>
      'Карточки пока на английском; приложение говорит на твоём языке.';

  @override
  String termsLine(String terms, String privacy) {
    return 'Продолжая, ты принимаешь $terms и $privacy';
  }

  @override
  String get termsLineTerms => 'Условия использования';

  @override
  String get termsLinePrivacy => 'Политику конфиденциальности';

  @override
  String get skip => 'Пропустить';

  @override
  String get tapToRevealLower => 'нажми, чтобы открыть';

  @override
  String get barMoveCaps => 'ЧТО ЗАПОМНИТЬ';

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
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return 'Глубже. Источник: $source';
  }

  @override
  String get sourceKindPaper => 'Исследование';

  @override
  String get sourceKindBook => 'Книга';

  @override
  String get sourceKindInstitution => 'Учреждение';

  @override
  String get sourceKindDocument => 'Документ';

  @override
  String get sourceKindData => 'Данные';

  @override
  String get sourceKindReference => 'Справочник';

  @override
  String get sourceKindNews => 'Газета';

  @override
  String get sourceKindCompany => 'Данные компании';

  @override
  String get sourceKindStandard => 'Стандарт';

  @override
  String get sourceKindArithmetic => 'Расчёт';

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
  String get paywallRecordTitle => 'Узнай, сколько ты знаешь на самом деле.';

  @override
  String get paywallRecordMark => 'на самом деле.';

  @override
  String get paywallRecordLine =>
      'Каждый день ты оцениваешь свою уверенность. Astute+ показывает, сокращается ли разрыв между ней и верными ответами, и ходы, которые ты продолжаешь упускать.';

  @override
  String paywallRecordOver(int sure, int right) {
    return 'Твоя уверенность — $sure%, а верных ответов — $right%. Astute+ показывает, сокращается ли этот разрыв, и ходы, которые ты продолжаешь упускать.';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return 'Твоя уверенность — $sure%, а верных ответов — $right%: ты знаешь больше, чем думаешь. Astute+ показывает, сокращается ли этот разрыв.';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return 'Твоя уверенность — $sure%, а верных ответов — $right%: почти поровну. Astute+ показывает, сохранится ли это, и ходы, которые ты продолжаешь упускать.';
  }

  @override
  String get paywallOutcomeTitle => 'Не дай себя провести.';

  @override
  String get paywallOutcomeMark => 'провести.';

  @override
  String get paywallOutcomeLine =>
      'Пять карточек в день на твоём уровне. Те, где ты ошибаешься, возвращаются, пока не запомнятся. И ты видишь, как меняешься, неделя за неделей.';

  @override
  String get paywallFiveTitle => 'Все пять — твои.';

  @override
  String get paywallFiveMark => 'твои.';

  @override
  String get paywallFiveLine =>
      'Бесплатно две из пяти — для тебя, после недели подряд — три. Astute+ выбирает все пять из твоих веток, на твоём уровне, и возвращает ошибки.';

  @override
  String get paywallReadTitle => 'Прочитанное — день за днём.';

  @override
  String get paywallReadMark => 'день за днём.';

  @override
  String get paywallReadLine =>
      'Последние дни чтения, начиная с самого нового. Нажми на день, чтобы открыть его пять карточек, и на карточку, чтобы перечитать её.';

  @override
  String get perkGapTitle => 'Смотри, как разрыв сокращается';

  @override
  String get perkGapLine =>
      'Твой путь, неделя за неделей: уверенность против верных ответов и ходы, которые ты продолжаешь упускать.';

  @override
  String get perkOwnFiveTitle => 'Пять своих карточек';

  @override
  String get perkOwnFiveLine =>
      'Каждый день, на твоём уровне, а ошибки возвращаются.';

  @override
  String get perkReadTitle => 'Прочитанное';

  @override
  String get perkReadLine =>
      'Твои последние дни, по пять карточек в каждом, — открой снова.';

  @override
  String get perkAskTitle => 'Твой помощник';

  @override
  String get perkAskLine => 'Объясняет любую карточку и проверяет тебя.';

  @override
  String get perkCoachTitle => 'Тренер каждую неделю';

  @override
  String get perkCoachLine => 'Где ты ошибаешься и что тренировать.';

  @override
  String get perkNew => 'НОВОЕ';

  @override
  String get threeTitle => 'Три вопроса дня';

  @override
  String threeStep(int n, int total) {
    return '$n из $total';
  }

  @override
  String get threeSame => 'Сегодня у всех одни и те же три. Около минуты.';

  @override
  String threeYouSaid(String guess) {
    return 'Твой ответ: $guess.';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n очка',
      many: '+$n очков',
      few: '+$n очка',
      one: '+$n очко',
      zero: 'Нет очков',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => 'Дальше';

  @override
  String get threeSeeScore => 'Посмотреть результат';

  @override
  String get threeDone => 'Три вопроса дня · готово';

  @override
  String get threeYou => 'Ты';

  @override
  String whyMissing(String move) {
    return 'Ход мысли, который ты часто упускаешь: $move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move: снова, в новом случае';
  }

  @override
  String get whyAgain => 'Снова, чтобы взглянуть ещё раз';

  @override
  String whyGoal(String goal) {
    return 'Для твоей цели: $goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Похожа на $n карточки, которые тебе понравились',
      many: 'Похожа на $n карточек, которые тебе понравились',
      few: 'Похожа на $n карточки, которые тебе понравились',
      one: 'Похожа на $n карточку, которая тебе понравилась',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return 'Сложная: «$subject» — твоя сильная сторона';
  }

  @override
  String whyLevel(String subject) {
    return 'На твоём уровне: $subject';
  }

  @override
  String whyGentle(String subject) {
    return 'Лёгкий вход: $subject';
  }

  @override
  String whyYourSubject(String subject) {
    return 'Твой предмет: $subject';
  }

  @override
  String get whyRandom => 'Выпала случайно из твоих предметов';

  @override
  String get whyTitle => 'Почему эта карточка';

  @override
  String whyTrains(String move) {
    return 'Тренирует: $move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Встречался $n раза.',
      many: 'Встречался $n раз.',
      few: 'Встречался $n раза.',
      one: 'Встречался $n раз.',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Верно $n раза.',
      many: 'Верно $n раз.',
      few: 'Верно $n раза.',
      one: 'Верно $n раз.',
      zero: 'Пока ни разу верно.',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return 'Твой уровень: $subject';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': 'Начало',
      'some': 'В пути',
      'strong': 'Сильный уровень',
      'other': 'В пути',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => 'Последняя встреча с этим ходом';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня назад',
      many: '$n дней назад',
      few: '$n дня назад',
      one: '$n день назад',
      zero: 'Сегодня',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => 'Твоя цель';

  @override
  String get whyLikedRow => 'Похожие карточки, которые тебе понравились';

  @override
  String get whyRandomLine =>
      'В бесплатном плане часть каждого дня выпадает случайно из выбранных тобой предметов.';

  @override
  String get whyPlusLine =>
      'С Astute+ все пять выбираются для тебя: по твоему уровню, по твоему вкусу, а упущенные ходы мысли возвращаются.';

  @override
  String get whyMakeMine => 'Все пять — мои';

  @override
  String get whyMore => 'Больше такого';

  @override
  String get whyMoreDone => 'Учтено: больше такого';

  @override
  String get whyLess => 'Меньше';

  @override
  String get whyTune => 'Настроить свой микс';

  @override
  String get searchTry => 'Попробуй';

  @override
  String get searchByNeed => 'По задаче';

  @override
  String get searchByKind => 'По виду';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': 'Поиграть',
      'quiz': 'Викторины',
      'estimate': 'Оценки',
      'debate': 'Споры',
      'quick': 'Быстрое чтение',
      'other': 'Карточки',
    });
    return '$_temp0';
  }

  @override
  String kindCards(int n) {
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
  String get areaUsefulFor => 'Пригодится';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n маршрута · по десять карточек',
      many: '$n маршрутов · по десять карточек',
      few: '$n маршрута · по десять карточек',
      one: '$n маршрут · по десять карточек',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => 'Ходы мысли, которые здесь тренируются';

  @override
  String get areaMoreCards => 'Ещё карточки на эту тему';

  @override
  String get pathKicker => 'Маршрут';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · карточек: $n · около $minutes мин';
  }

  @override
  String pathPartOf(int part, int parts) {
    return 'Часть $part из $parts';
  }

  @override
  String pathTrains(String moves) {
    return 'Тренирует: $moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return 'Прочитано $n из $total';
  }

  @override
  String get pathFreeTag => 'Бесплатно';

  @override
  String get pathStart => 'Начать маршрут';

  @override
  String pathContinueAt(int n) {
    return 'Дальше · карточка $n';
  }

  @override
  String get pathContinue => 'Дальше';

  @override
  String get notesTitle => 'Заметки';

  @override
  String get noteYours => 'Твоя заметка';

  @override
  String get noteAdd => 'Добавить заметку';

  @override
  String get noteEdit => 'Изменить';

  @override
  String get noteSave => 'Сохранить';

  @override
  String get noteDelete => 'Удалить заметку';

  @override
  String get noteHint => 'Что ты хочешь запомнить из этой карточки?';

  @override
  String get notesEmpty =>
      'Заметок пока нет. Открой сохранённую карточку и запиши, что хочешь запомнить.';

  @override
  String get pathUnlock => 'Открыть все маршруты';

  @override
  String get pathFreeLine => 'Первые две карточки каждого маршрута бесплатны.';

  @override
  String pathNextPart(int n) {
    return 'Часть $n: глубже';
  }

  @override
  String pathDeeperLine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ещё $n карточки на ту же тему, сложнее.',
      many: 'Ещё $n карточек на ту же тему, сложнее.',
      few: 'Ещё $n карточки на ту же тему, сложнее.',
      one: 'Ещё $n карточка на ту же тему, сложнее.',
    );
    return '$_temp0';
  }

  @override
  String get pathAgain => 'Прочитать снова';

  @override
  String get subjectKicker => 'Предмет';

  @override
  String subjectReadOf(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total карточки',
      many: '$total карточек',
      few: '$total карточек',
      one: '$total карточки',
    );
    return 'Прочитано $n из $_temp0';
  }

  @override
  String subjectRight(int right, int answered) {
    return 'Верно $right из $answered';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n верного ответа до уровня $level',
      many: '$n верных ответов до уровня $level',
      few: '$n верных ответа до уровня $level',
      one: '$n верный ответ до уровня $level',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => 'Уровень';

  @override
  String get subjectNext => 'Следующая для тебя';

  @override
  String get subjectNextLine => 'На ступень выше твоего уровня.';

  @override
  String subjectInside(String subject) {
    return 'Внутри: $subject';
  }

  @override
  String get journeySubjectsTap =>
      'Нажми на предмет, чтобы открыть его страницу.';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Базовая частота',
      'survivorship': 'Ошибка выжившего',
      'regression': 'Регрессия к среднему',
      'confirmation': 'Подтверждение',
      'anchoring': 'Якорь',
      'sampling': 'Выборка',
      'confounding': 'Скрытые факторы',
      'counterfactual': 'По сравнению с чем',
      'multipleComparisons': 'Множество попыток',
      'availability': 'Доступность',
      'sunkCost': 'Невозвратные затраты',
      'conjunction': 'Конъюнкция',
      'conditional': 'Условная вероятность',
      'independence': 'Независимость',
      'coincidence': 'Совпадения',
      'exponential': 'Экспоненциальный рост',
      'reflection': 'Быстрый ответ',
      'simpson': 'Итоги',
      'estimation': 'Оценка',
      'computation': 'Посчитать',
      'other': 'Рассуждение',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Точность теста — не вероятность, что это про тебя',
      'survivorship': 'Данные, что у тебя есть, — это данные, которые выжили',
      'regression': 'Крайности сами возвращаются к среднему',
      'confirmation': 'Искать «да» — не значит проверять',
      'anchoring': 'Первое названное число сдвигает все последующие',
      'sampling': 'Кто попал в выборку, решает, что она может сказать',
      'confounding': 'Возможно, что-то третье вызывает и то и другое',
      'counterfactual': 'Изменение ничего не значит без сравнения',
      'multipleComparisons': 'Проверь достаточно всего — и что-то пройдёт',
      'availability': 'Легко представить — не значит часто',
      'sunkCost':
          'Потрачено — значит потрачено: решать можно только то, что осталось',
      'conjunction': 'Детали делают историю убедительнее и менее вероятной',
      'conditional': 'Новые сведения меняют шансы',
      'independence': 'У случая нет памяти',
      'coincidence': 'Редкое становится частым, когда попыток много',
      'exponential': 'Ни у кого нет чутья на удвоение',
      'reflection': 'Ответ, что приходит первым, и нужно проверить',
      'simpson':
          'Целое может склоняться туда, куда не склоняется ни одна часть',
      'estimation': 'Разбей неразрешимое на то, что можно оценить',
      'computation': 'Задача, которую правда можно решить до конца',
      'other': 'Рассуждение',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => 'Отправить';

  @override
  String get threeWhy => 'Посмотреть почему';

  @override
  String threeYesterday(int score) {
    return 'Вчерашние три: $score из 300.';
  }

  @override
  String get fiveTitle => 'Вызов дня';

  @override
  String get fiveSame => 'Сегодня у всех одни и те же пять. Около двух минут.';

  @override
  String get fiveDone => 'Вызов дня · готово';

  @override
  String dailyOf(int max) {
    return 'из $max';
  }

  @override
  String dailyPickRight(String answer) {
    return 'Верный ответ: $answer';
  }

  @override
  String dailyPickWrong(String answer) {
    return 'Не совсем. Верный ответ: $answer';
  }

  @override
  String dailyYourPick(String answer) {
    return 'Твой ответ: $answer';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Лучше, чем $pct% из $n сегодняшних игроков.',
      many: 'Лучше, чем $pct% из $n сегодняшних игроков.',
      few: 'Лучше, чем $pct% из $n сегодняшних игроков.',
      one: 'Лучше, чем $pct% из $n сегодняшнего игрока.',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Сегодня пока сыграли $n игрока.',
      many: 'Сегодня пока сыграли $n игроков.',
      few: 'Сегодня пока сыграли $n игрока.',
      one: 'Сегодня пока сыграл $n игрок.',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'Среди первых $n игроков сегодня: пока слишком мало для сравнения.',
      many: 'Среди первых $n игроков сегодня: пока слишком мало для сравнения.',
      few: 'Среди первых $n игроков сегодня: пока слишком мало для сравнения.',
      one: 'Первый игрок сегодня: пока слишком мало игроков для сравнения.',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => 'Считаем сегодняшних игроков…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return 'Верно: $right из $total. На этих вопросах читатели в среднем отвечают верно на $avg.';
  }

  @override
  String get dailyUncounted =>
      'Сейчас не получается посчитать сегодняшних игроков.';

  @override
  String get dailyEach => 'Вопрос за вопросом';

  @override
  String dailyItemRight(int pct) {
    return '$pct% сегодняшних игроков ответили верно';
  }

  @override
  String dailyItemGuess(String guess) {
    return 'Средняя оценка сегодня: $guess';
  }

  @override
  String get dailyItemFew => 'Пока слишком мало ответов для сравнения';

  @override
  String fiveYesterday(int score) {
    return 'Вчерашние пять: $score из 500.';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · Вызов дня · $date';
  }

  @override
  String fiveChallengeLine(int right) {
    return 'В «Пяти вопросах дня» Astute у меня $right из 5. Сможешь лучше?';
  }

  @override
  String get fiveChallengeAll =>
      'В «Пяти вопросах дня» Astute у меня 5 из 5. Повторишь?';

  @override
  String get fiveChallengeInvite =>
      '«Вызов дня» в Astute: одни и те же пять вопросов для всех. Сколько ответишь верно?';

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · Три вопроса дня · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score из $max · день $day';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score из $max';
  }

  @override
  String get skillsTitle => 'Чему учиться';

  @override
  String get skillsTitleMark => 'учиться';

  @override
  String get skillsLine =>
      'Каждый ответ двигает твой рейтинг. Карточки, которые тренируют выбранное, получат его знак.';

  @override
  String get skillsDone => 'Готово';

  @override
  String get skillsFocus => 'В ФОКУСЕ';

  @override
  String get skillMarkKicker => 'ЭТА КАРТОЧКА ТРЕНИРУЕТ';

  @override
  String skillMarkLabel(String skill) {
    return 'Тренирует: $skill';
  }

  @override
  String get skillMarkBody =>
      'Один из навыков, на которых ты сосредоточен. Каждый ответ на такой карточке двигает твой рейтинг в нём.';

  @override
  String get skillMarkOpen => 'Все твои рейтинги';

  @override
  String get trainingTitle => 'Твоя тренировка';

  @override
  String get trainingLine =>
      'Каждый ответ двигает твой рейтинг, а верный ответ на трудную карточку — сильнее всего. Потолка нет.';

  @override
  String get trainingOthers => 'Остальные';

  @override
  String get trainingEmpty =>
      'Выбери, в чём хочешь стать лучше. Каждый ответ на карточке, которая это тренирует, двигает твой рейтинг, а у карточки появляется его знак.';

  @override
  String get trainingPick => 'Выбрать навыки';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'и ещё $n',
      many: 'и ещё $n',
      few: 'и ещё $n',
      one: 'и ещё $n',
    );
    return '$_temp0';
  }

  @override
  String get aimTitle => 'Где ты хочешь видеть яснее?';

  @override
  String get aimLine =>
      'Выбери одно. Каждый день будут карточки для этого, а поменять можно когда угодно.';

  @override
  String aimWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На этой неделе $n карточки для этого',
      many: 'На этой неделе $n карточек для этого',
      few: 'На этой неделе $n карточки для этого',
      one: 'На этой неделе $n карточка для этого',
      zero: 'На этой неделе карточек для этого нет',
    );
    return '$_temp0';
  }

  @override
  String answersRightOf(int right, int n) {
    return '$right из $n верно';
  }

  @override
  String get aimOpen => 'Всё для этой цели';

  @override
  String get aimPlus =>
      'С Astute+: все пути по этой теме целиком и тренер, который работает над этим с тобой.';

  @override
  String get aimNone =>
      'Выбери, где ты хочешь видеть яснее: каждый день будут карточки для этого.';

  @override
  String get aimPick => 'Выбрать цель';

  @override
  String get strengthsTitle => 'Твои сильные стороны';

  @override
  String get strengthsLine =>
      'По твоим ответам, а не по выбору: где ты чаще отвечаешь верно, а где ошибаешься.';

  @override
  String strengthsFew(String skills) {
    return 'Пока мало ответов: $skills.';
  }

  @override
  String strengthsPractice(String skill) {
    return 'Потренироваться: $skill';
  }

  @override
  String get strengthsBest => 'Твоя сильная сторона';

  @override
  String get strengthsWeak => 'Где ты ошибаешься чаще всего';

  @override
  String get strengthsLocked =>
      'Где ты ошибаешься чаще всего, и всё остальное — с Astute+.';

  @override
  String get strengthsEmpty =>
      'Ещё несколько ответов — и здесь появятся твои сильные стороны.';

  @override
  String get readTitle => 'Где ты уже видишь ясно';

  @override
  String get readBlind => 'Твоё слепое пятно';

  @override
  String get readLocked =>
      'Пять карточек на твоё слепое пятно и весь профиль — с Astute+.';

  @override
  String get readEmpty =>
      'Ещё несколько ответов — и здесь будет видно, где ты видишь ясно, а где нет.';

  @override
  String get readNoAim =>
      'Выбери выше, где ты хочешь видеть яснее: твои ответы покажут, где ты уже видишь ясно.';

  @override
  String get readLine =>
      'Навыки, которые нужны для этой цели, по твоим ответам: где ты видишь ясно и твоё слепое пятно.';

  @override
  String get readOthers => 'Остальной профиль';

  @override
  String get focusTitle => 'Фокус недели';

  @override
  String get focusFromGoal =>
      'Выбран по твоей цели: каждую неделю другой навык.';

  @override
  String get focusFromMisses =>
      'Выбран по твоим ответам: здесь ты ошибаешься чаще всего.';

  @override
  String get focusLine =>
      'Карточки, которые его тренируют, отмечены его знаком. В воскресенье — итоги недели.';

  @override
  String focusLast(String skill) {
    return 'На прошлой неделе: $skill';
  }

  @override
  String focusNext(String skill) {
    return 'С понедельника: $skill';
  }

  @override
  String get focusResult => 'Итоги недели';

  @override
  String get focusPlus =>
      'С Astute+ фокус выбирают твои ответы: там, где ты ошибаешься чаще всего.';

  @override
  String get focusMarkBody =>
      'На этой неделе ты тренируешь этот навык: карточки, которые его тренируют, отмечены этим знаком. В воскресенье увидишь, как всё прошло.';

  @override
  String focusShelf(String skill) {
    return 'Фокус недели: $skill';
  }

  @override
  String get focusShelfLine =>
      'Карточки, которые его тренируют, ещё не прочитанные.';

  @override
  String get focusOpen => 'Твоя неделя';

  @override
  String get scoreTitle => 'Рейтинг Astute';

  @override
  String scoreWeek(String n) {
    return '$n за неделю';
  }

  @override
  String get scoreStart => 'Он начнётся с твоего первого ответа.';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name: $n за этот ответ';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'по $n ответам',
      many: 'по $n ответам',
      few: 'по $n ответам',
      one: 'по $n ответу',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => 'Видео';

  @override
  String get videoPlay => 'Воспроизвести';

  @override
  String get videoPause => 'Пауза';

  @override
  String get videoWatchAgain => 'Смотреть снова';

  @override
  String get videoOffline =>
      'Для видео нужно подключение. Коснитесь, чтобы повторить.';

  @override
  String get skillsRowTitle => 'Чему хочешь научиться';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Критическое мышление',
      'decisions': 'Лучшие решения',
      'money': 'Деньги и сбережения',
      'numbers': 'Числа и статистика',
      'talk': 'Общение',
      'persuade': 'Убеждение',
      'people': 'Понимать людей',
      'fakes': 'Распознавать фейки',
      'science': 'Мыслить как учёный',
      'focus': 'Концентрация',
      'lead': 'Лидерство',
      'culture': 'Общая эрудиция',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String skillLine(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': 'Отличать здравый аргумент от обманчивого.',
      'decisions': 'Выбирать по рискам и вероятностям, а не наугад.',
      'money': 'Цены, проценты, скидки: куда уходят твои деньги.',
      'numbers': 'Читать проценты и графики, не попадаясь на уловки.',
      'talk': 'Быть понятым устно и письменно.',
      'persuade': 'Убеждать и замечать, когда убеждают тебя.',
      'people': 'Почему люди поступают так, как поступают.',
      'fakes': 'Распознавать фейки, поддельные фото и раздутые исследования.',
      'science': 'Проверять идею, прежде чем в неё поверить.',
      'focus': 'Дольше держать внимание там, где это важно.',
      'lead': 'Вести группу и принимать решения за всех.',
      'culture': 'История, наука, искусство: то, что все цитируют.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => 'Каждый день, на твоём уровне.';

  @override
  String get perkShelvesTitle => 'Каждый путь и каждая книга';

  @override
  String get perkShelvesLine => 'Целиком, и новые каждую неделю.';

  @override
  String get perkGapShort => 'Насколько уверен — и насколько прав.';

  @override
  String get perkReadShort => 'Каждый прочитанный день — открыть снова.';

  @override
  String get trialToday => 'Сегодня · весь Astute+, бесплатно';

  @override
  String trialReminder(int day) {
    return 'День $day · мы напомним';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {
      'year': 'в год',
      'other': 'в месяц',
    });
    return 'День $day · $price $_temp0, с автопродлением, пока не отменишь';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '$price$suffix списываются сегодня, с автопродлением, пока не отменишь';
  }

  @override
  String cancelHow(String where) {
    return 'Отменить можно когда угодно: $where, не позже чем за 24 часа до продления.';
  }

  @override
  String get cancelWhereIos => 'Настройки › твоё имя › Подписки';

  @override
  String get cancelWhereAndroid =>
      'Google Play › Платежи и подписки › Подписки';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Запрашиваем цены в App Store…',
      'other': 'Запрашиваем цены в Google Play…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Не удалось связаться с App Store',
      'other': 'Не удалось связаться с Google Play',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine =>
      'Цены и бесплатный период приходят из магазина. Проверь подключение и попробуй ещё раз.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get purchasePending =>
      'Ждём подтверждения. Astute+ откроется, как только платёж пройдёт.';

  @override
  String get oneMoment => 'Секунду…';

  @override
  String get purchaseConfirming => 'Подтверждаем оплату…';

  @override
  String get purchaseConfirmingSlow =>
      'Это дольше, чем обычно. Оплата в безопасности: Astute+ включится сам.';

  @override
  String get closeLabel => 'Закрыть';

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
  String get verdictRight => 'Верно.';

  @override
  String get verdictClose => 'Достаточно близко.';

  @override
  String get verdictWrong => 'Не совсем.';

  @override
  String verdictSure(int pct) {
    return 'Ты был уверен на $pct%.';
  }

  @override
  String verdictYouSaid(String given) {
    return 'Твой ответ: $given';
  }

  @override
  String verdictYouSaidSure(String given, int pct) {
    return 'Твой ответ: $given, уверенность $pct%';
  }

  @override
  String verdictRightIs(String answer) {
    return 'Верный ответ: $answer';
  }

  @override
  String verdictRightWithin(String answer, String low, String high) {
    return 'Верный ответ: $answer (засчитывалось от $low до $high)';
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
  String get musicSound => 'Звук в музыкальных карточках';

  @override
  String get musicSoundIsOff => 'Звук музыкальных карточек выключен.';

  @override
  String get musicSoundTurnOn => 'Включить';

  @override
  String get thatWasTheOnlyOne => 'Это была единственная';

  @override
  String get lastOne => 'Последняя';

  @override
  String deckEndTitle(String word) {
    return 'Это все $word.';
  }

  @override
  String get deckEndAgain => 'Начать сначала';

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
      other:
          '$n карточки, на которые вы отвечали несколько дней назад, вернулись: помните ответы?',
      many:
          '$n карточек, на которые вы отвечали несколько дней назад, вернулись: помните ответы?',
      few:
          '$n карточки, на которые вы отвечали несколько дней назад, вернулись: помните ответы?',
      one:
          '$n карточка, на которую вы отвечали несколько дней назад, вернулась: помните ответ?',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Вы ещё помните?';

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
  String get nudgeBookTitle => 'Бесплатная книга этой недели';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '«$title», $author: главные идеи за $minutes мин.';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      read,
      locale: localeName,
      other: '$read карточки',
      many: '$read карточек',
      few: '$read карточки',
      one: '$read карточку',
    );
    return 'Две недели назад вы прочли $_temp0';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    String _temp0 = intl.Intl.pluralLogic(
      gap,
      locale: localeName,
      other: '$gap пункта',
      many: '$gap пунктов',
      few: '$gap пункта',
      one: '$gap пункт',
    );
    return 'Ваша уверенность отклонялась на $_temp0. Сегодня: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    String _temp0 = intl.Intl.pluralLogic(
      answered,
      locale: localeName,
      other: '$answered ответа',
      many: '$answered ответов',
      few: '$answered ответа',
      one: '$answered ответ',
    );
    return 'Пока $_temp0. Сегодня: $question';
  }

  @override
  String get yourJourney => 'Ваш путь';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'С прошлого визита, $days дня назад',
      many: 'С прошлого визита, $days дней назад',
      few: 'С прошлого визита, $days дня назад',
      one: 'С прошлого визита, $days день назад',
      zero: 'С прошлого визита, сегодня',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return '$n с прошлого визита';
  }

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
  String get consentTitle => 'Поможешь сделать Astute лучше?';

  @override
  String get consentLine =>
      'Делись тем, как пользуешься приложением, — без имени, почты и того, что ты пишешь.';

  @override
  String get consentNo => 'Нет, спасибо';

  @override
  String get consentYes => 'Да, делиться';

  @override
  String consentChangeLater(String profile, String setting) {
    return 'Это можно изменить в любой момент: $profile › $setting.';
  }

  @override
  String get yourMix => 'Твой микс';

  @override
  String get genresTitle => 'Какие части?';

  @override
  String get genresLine =>
      'Коснись жанра, чтобы пропустить его. Задержи — и темы поменьше внутри откроются прямо под ним.';

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
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total жанра',
      many: '$total жанров',
      few: '$total жанров',
      one: '$total жанра',
    );
    return 'Дальше · $on из $_temp0 включено';
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
      'Пять карточек в день, выбранных для тебя: из твоего микса, на твоём уровне, а те, где ты ошибаешься, возвращаются. С завтрашнего дня.';

  @override
  String get plusCardHeadline => 'Все пять — твои.';

  @override
  String get plusCardLine =>
      'Пять карточек в день из твоего микса, на твоём уровне. Твой путь. Весь твой архив.';

  @override
  String get archiveBeforeThisWeek => 'До этой недели';

  @override
  String get weekKeptThreeOwn => 'Семь дней подряд: завтра три из пяти — твои.';

  @override
  String get weekKeptSundayFourOwn =>
      'Семь дней подряд, а завтра воскресенье: четыре из пяти — твои.';

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
  String get topPicksTitle => 'Стоит потратить время';

  @override
  String get topPicksLine =>
      'Выбирает Astute, пока заполняется список читателей';

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
  String get themePracticalLine =>
      'Что попробовать или чем поделиться в разговоре — ещё до вечера';

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
  String get storyHint => 'Нажмите, чтобы продолжить · удерживайте для паузы';

  @override
  String get storyTapOn => 'Нажмите, чтобы продолжить';

  @override
  String get storyPrevious => 'Назад';

  @override
  String get storyClose => 'Закрыть историю';

  @override
  String get storySave => 'Сохранить';

  @override
  String get storySaved => 'Сохранено';

  @override
  String get storyShare => 'Поделиться';

  @override
  String get storyOpenCard => 'Открыть карточку';

  @override
  String get themeDebates => 'Выберите сторону';

  @override
  String get themeDebatesLine => 'Нет верного ответа, есть лишь лучший довод';

  @override
  String get themeWorkItOut => 'Посчитайте';

  @override
  String get themeWorkItOutLine =>
      'Угадайте число, прежде чем карточка его назовёт';

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
  String weekRecapMore(int n) {
    return 'Ещё $n за неделю с Astute+';
  }

  @override
  String get weekReviewTitle => 'Повтори неделю';

  @override
  String get weekReviewLine =>
      'Вопросы твоих карточек за эту неделю. Ответь на них ещё раз: так они запоминаются.';

  @override
  String get weekReviewGo => 'Повторить';

  @override
  String get weekReviewNone =>
      'Карточки, которые ты прочитаешь на этой неделе, вернутся сюда для повторения.';

  @override
  String get plusInTheApp =>
      'Astute+ — в приложении: скачай Astute на iPhone или Android, чтобы начать бесплатный период.';

  @override
  String get purchaseComplete => 'Покупка завершена.';

  @override
  String get trialStartedTitle => 'Бесплатный период начался.';

  @override
  String get successWelcome =>
      'Добро пожаловать в Astute+. Пять сегодняшних карточек готовы.';

  @override
  String successWelcomeNamed(String name) {
    return 'Добро пожаловать в Astute+, $name. Пять сегодняшних карточек готовы.';
  }

  @override
  String get successWelcomeTomorrow =>
      'Добро пожаловать в Astute+. Завтрашние пять — целиком твои.';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return 'Добро пожаловать в Astute+, $name. Завтрашние пять — целиком твои.';
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
  String get sceneLockIn => 'Готово';

  @override
  String get placeItDrag => 'Проведи по линейке.';

  @override
  String get placeItHappy => 'Так и оставить?';

  @override
  String get placeItEstimate => 'Твоя оценка';

  @override
  String get placeItNotSet => 'ещё не задана';

  @override
  String get placeItLock => 'Подтвердить мою оценку';

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
    return '$now мин в неделю, сначала $was мин';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m мин на этой неделе';
  }

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
  String get journeyMovesTitle => 'Замеченные приёмы';

  @override
  String get journeySureEmpty => 'Появится, когда ответишь на 80% и выше.';

  @override
  String get journeyMovesEmpty =>
      'Появится, когда заметишь приём на двух карточках.';

  @override
  String get journeyMissedEmpty =>
      'Шесть ответов по второй теме — и она измерена.';

  @override
  String get journeyFillsAsYouRead => 'Заполняется по мере чтения.';

  @override
  String journeyOfN(int n) {
    return 'из $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Последний: $name';
  }

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
  String get betWord => 'Поставить';

  @override
  String get biggerLabel => 'Больше';

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
  String get fewCards => 'В нескольких карточках';

  @override
  String get fewCardsLine => 'Когда одной карточки мало, чтобы объяснить';

  @override
  String get firstLabel => 'С';

  @override
  String get forYouNow => 'Для вас, прямо сейчас';

  @override
  String get hardBadge => 'Сложно';

  @override
  String hidesIn(String where) {
    return 'Где: $where';
  }

  @override
  String get howSure => 'Насколько я уверен — и почему?';

  @override
  String inRange(int pts, String said) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'Попали: +$pts очка. Это $said.',
      many: 'Попали: +$pts очков. Это $said.',
      few: 'Попали: +$pts очка. Это $said.',
      one: 'Попали: +$pts очко. Это $said.',
    );
    return '$_temp0';
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
  String get modeCloser => 'Ближе и ближе';

  @override
  String get modePick => 'Выберите';

  @override
  String get modeRange => 'Ставка на диапазон';

  @override
  String get modeSlide => 'Двигайте';

  @override
  String get modeStake => 'Делайте ставку';

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
  String get moveComparedToWhat => 'Много или мало?';

  @override
  String get moveComparedToWhatLine =>
      '«Рост на 30%» ничего не значит, пока вы не знаете: по сравнению с чем?';

  @override
  String get askingTitle => 'По вопросу из каждой темы';

  @override
  String askingIn(String subject) {
    return 'Вопросы: $subject';
  }

  @override
  String get askingLine =>
      'Одни на всех. Сначала ответьте, потом узнайте почему';

  @override
  String get moveSampling => 'Кого нет в данных?';

  @override
  String get moveSamplingLine =>
      'Любая статистика кого-то учитывает, а кого-то упускает. Тот, кого не посчитали, может перевернуть ответ';

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
  String rangeWidth(int w, int pts) {
    return '±$w · $pts оч.';
  }

  @override
  String get rightLastTime => 'В прошлый раз верно';

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
  String leanHint(String or) {
    return 'Сдвиньте «$or» туда, где вы стоите';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': 'немного',
      '2': 'скорее',
      '3': 'твёрдо',
      'other': 'полностью',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side, $how';
  }

  @override
  String leanTook(String side) {
    return 'Ваш выбор: $side';
  }

  @override
  String leanVerdict(String says) {
    return '$says. Откройте, чтобы узнать другую сторону.';
  }

  @override
  String get spotTitle => 'Найдите ложное';

  @override
  String get spotLine => 'Четыре утверждения. Три верны, одно ложно.';

  @override
  String get spotPrompt => 'Нажмите на то, что считаете ложным';

  @override
  String get spotConfirm => 'Это ложное';

  @override
  String get spotFound => 'Нашли. Остальные три верны.';

  @override
  String get spotMissed => 'Не это: оно верно. Ложное зачёркнуто.';

  @override
  String get spotWhy => 'Нажмите на любое, чтобы прочитать почему';

  @override
  String get spotYours => 'Ваш выбор';

  @override
  String get todayLabel => 'Сегодня';

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
  String get unmaskMisleadTitle => 'Графики, которые вводят в заблуждение';

  @override
  String get unmaskMisleadLine =>
      'Цифры верные. Подвох — в том, как они нарисованы.';

  @override
  String get unmaskAsk => 'Этот график вводит в заблуждение. Видите, как?';

  @override
  String get unmaskShowTrick => 'Показать подвох';

  @override
  String get unmaskHideTrick => 'Скрыть подвох';

  @override
  String get unmaskOriginal => 'Оригинал';

  @override
  String get unmaskCorrected => 'Исправлено';

  @override
  String unmaskTrickTruncated(String from) {
    return 'Ось начинается с $from, а не с нуля.';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return 'Ось идёт лишь от $low до $high, и небольшое изменение кажется огромным.';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return 'Ось идёт от $low до $high, и реальное изменение кажется плоским.';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return 'Показан только отрезок $shown, хотя данные охватывают $all.';
  }

  @override
  String get unmaskTrickTotals =>
      'Сравниваются голые итоги, а не честная мера.';

  @override
  String get unmaskTrickFlippedRise =>
      'Ось перевёрнута, и рост выглядит как падение.';

  @override
  String get unmaskTrickFlippedFall =>
      'Ось перевёрнута, и падение выглядит как рост.';

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

  @override
  String placeNearYou(String place) {
    return 'Рядом с тобой · $place';
  }

  @override
  String placeYourRegion(String place) {
    return 'Твой регион · $place';
  }

  @override
  String placeYourCountry(String place) {
    return 'Твоя страна · $place';
  }

  @override
  String get sundayOneMore => 'Воскресенье: ещё одна, выбранная для тебя';

  @override
  String get whereYouLive => 'Там, где ты живёшь';

  @override
  String get whereYouLiveLine =>
      'Сначала твой город, потом регион, потом страна';

  @override
  String get whereYouLiveAsk =>
      'Карточки о твоём городе, регионе и стране: не больше одной в день, и эта полка. Хранится только город, никогда — где именно ты находишься.';

  @override
  String get whereYouLiveSwitchOn => 'Включить';

  @override
  String get gateUpdateTitle => 'Обнови Astute';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Новая уже ждёт в App Store',
      'google': 'Новая уже ждёт в Google Play',
      'other': 'Новая уже ждёт в магазине приложений',
    });
    return 'Этой версией больше нельзя пользоваться. $_temp0, а карточки и серия останутся как были.';
  }

  @override
  String get gateUpdateButton => 'Обновить';

  @override
  String get gateSoftTitle => 'Вышла новая версия Astute';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': 'Она уже ждёт в App Store.',
      'google': 'Она уже ждёт в Google Play.',
      'other': 'Она уже ждёт в магазине приложений.',
    });
    return '$_temp0 Обновление пройдёт быстро, а карточки и серия останутся как есть.';
  }

  @override
  String get gateSoftLater => 'Позже';

  @override
  String get gatePauseTitle => 'Astute ненадолго на перерыве';

  @override
  String get gatePauseLine =>
      'Мы кое-что чиним за кулисами. Весь твой прогресс сохранён. Попробуй ещё раз чуть позже.';

  @override
  String get gatePauseTrying => 'Пробуем снова…';

  @override
  String get gatePauseStill =>
      'Перерыв ещё не закончился. Попробуй снова через несколько минут.';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return 'Сделать: $toDo, прочитать: $toRead';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return 'сделать: $toDo · прочитать: $toRead';
  }

  @override
  String get purposeFilterToRead => 'Читать';

  @override
  String get purposeFilterToDo => 'Делать';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': 'Правда или ложь',
      'pick': 'Выбери ответ',
      'typeNumber': 'Введи число',
      'bet': 'Угадай число',
      'side': 'Выбери сторону',
      'youFirst': 'Сначала ты',
      'moveIt': 'Двигай и смотри',
      'whatNext': 'Что будет дальше?',
      'spotTrick': 'Найди подвох',
      'drawIt': 'Нарисуй',
      'sortThem': 'Разложи по группам',
      'putInOrder': 'Расставь по порядку',
      'holdIt': 'Удерживай',
      'growSample': 'Увеличь выборку',
      'askWhy': 'Спроси почему',
      'sayPlainly': 'Скажи проще',
      'pairUp': 'Подбери пары',
      'followClues': 'Иди по подсказкам',
      'look': 'Просто смотри',
      'listen': 'Слушай',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return 'Читать · $n мин';
  }

  @override
  String get purposeCommitNote =>
      'Ответь здесь, а потом открой карточку и проверь себя. Ответ, который выбираешь сам, запоминается дольше.';

  @override
  String get purposeCommitTitle => 'Сначала ответь';

  @override
  String get purposeCommitLine => 'Скажи, что думаешь, потом открой карточку';

  @override
  String get purposeInYourHeadLine => 'Число, до которого надо дойти в уме';

  @override
  String get purposeInYourHead => 'В уме';

  @override
  String get purposeMoveKicker => 'Приём';

  @override
  String purposeMoveNew(int points) {
    return 'Новое · +$points, когда освоишь';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Базовая частота',
      'survivorship': 'Ошибка выжившего',
      'regression': 'Регрессия к среднему',
      'confirmation': 'Подтверждение',
      'anchoring': 'Якорение',
      'sampling': 'Выборка',
      'confounding': 'Скрытый фактор',
      'counterfactual': 'По сравнению с чем',
      'multipleComparisons': 'Много попыток',
      'availability': 'Доступность',
      'sunkCost': 'Невозвратные затраты',
      'conjunction': 'Конъюнкция',
      'conditional': 'Условная вероятность',
      'independence': 'Независимость',
      'coincidence': 'Совпадение',
      'exponential': 'Экспоненциальный рост',
      'reflection': 'Быстрый ответ',
      'simpson': 'Итоги и части',
      'estimation': 'Оценка',
      'computation': 'Расчёт',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Точность теста — это не вероятность, что это про тебя',
      'survivorship': 'Данные, что у тебя есть, — это те, что выжили',
      'regression': 'Крайности сами возвращаются к среднему',
      'confirmation': 'Искать «да» — это не проверка',
      'anchoring': 'Первое названное число сдвигает все следующие',
      'sampling': 'Кто попал в выборку, решает, о чём она может сказать',
      'confounding': 'Возможно, и то и другое вызывает что-то третье',
      'counterfactual': 'Без контрольной группы перемена ничего не значит',
      'multipleComparisons': 'Проверь достаточно всего — что-то пройдёт',
      'availability': 'Легко представить — не значит часто',
      'sunkCost': 'Потраченное потрачено; решать можно только об остатке',
      'conjunction':
          'Подробности делают историю убедительнее и менее вероятной',
      'conditional': 'То, что тебе сказали, меняет шансы',
      'independence': 'У случая нет памяти',
      'coincidence': 'Редкое становится частым, когда попыток много',
      'exponential': 'Удвоение никто не чувствует интуитивно',
      'reflection': 'Ответ, пришедший первым, и нужно проверить',
      'simpson':
          'Целое может склоняться туда, куда не склоняется ни одна часть',
      'estimation': 'Разбей вопрос без ответа на то, что можно прикинуть',
      'computation': 'Задача, которую реально довести до конца',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': 'Насколько это вообще было распространено?',
      'survivorship': 'Что так и не попало в данные?',
      'regression': 'Может, это просто крайность возвращается?',
      'confirmation': 'Что опровергло бы мою версию?',
      'anchoring': 'Какое число прозвучало первым?',
      'sampling': 'Кого посчитали?',
      'confounding': 'Что ещё могло вызвать и то и другое?',
      'counterfactual': 'По сравнению с чем?',
      'multipleComparisons': 'Сколько всего проверяли?',
      'availability': 'Это часто бывает или просто легко представить?',
      'sunkCost': 'Что ещё можно решить отсюда?',
      'conjunction': 'Каждая подробность делает это менее вероятным?',
      'conditional': 'Что меняет это знание?',
      'independence': 'Влияет ли прошлый результат на следующий?',
      'coincidence': 'Сколько было шансов?',
      'exponential': 'Что будет, если оно удвоится ещё раз?',
      'reflection': 'Первый ответ — правильный?',
      'simpson': 'Все ли части склоняются в одну сторону?',
      'estimation': 'Что можно прикинуть по дороге?',
      'computation': 'Можно ли посчитать это шаг за шагом?',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => 'Ступенькой выше';

  @override
  String get purposeStepAboveLine => 'Сложнее, чем ты обычно читаешь';

  @override
  String purposeThinTitle(String subject) {
    return 'Меньше всего прочитано: $subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return 'Прочитано $percent% раздела «$subject» — меньше всего';
  }

  @override
  String get purposeOtherSide => 'Другая сторона';

  @override
  String get purposeOtherSideLine =>
      'Сторона выбрана. Вот самый сильный довод против';

  @override
  String purposeYouSaid(String side) {
    return 'Твой ответ: $side';
  }

  @override
  String purposeCaseFor(String side) {
    return 'Доводы за «$side»';
  }

  @override
  String get purposeMechanism => 'Механизм';

  @override
  String purposeMovingUpdated(String date) {
    return 'Обновлено $date';
  }

  @override
  String get purposeMovingYears => 'Может измениться через несколько лет';

  @override
  String get purposeMovingMonths => 'Может измениться в этом году';

  @override
  String get purposeWhy => 'А, вот почему';

  @override
  String get purposeWhyLine => 'Один механизм — объяснён, пока не щёлкнет';

  @override
  String purposeWhyBand(int n) {
    return 'Почему · $n мин';
  }

  @override
  String get purposeMe => 'Это про меня';

  @override
  String get purposeMeLine => 'Что ты делаешь, не замечая';

  @override
  String get purposeMeFooter => 'Отметь карточки, в которых узнаёшь себя.';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки с отметкой «Это про меня».',
      many: '$n карточек с отметкой «Это про меня».',
      few: '$n карточки с отметкой «Это про меня».',
      one: '$n карточка с отметкой «Это про меня».',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => 'Новое для меня — и обо мне';

  @override
  String get purposeAboutYouLine => 'Твоё тело, твоё здоровье, твои шансы';

  @override
  String get purposeHeadline => 'В заголовке';

  @override
  String get purposeHeadlineLine =>
      'Исследования и заявления, которые звучат лучше, чем есть';

  @override
  String get purposeTheClaim => 'Заявление';

  @override
  String get purposeNumber => 'В цифре';

  @override
  String get purposeNumberLine =>
      'Шансы и проценты, на которые стоит взглянуть дважды';

  @override
  String get purposeOutOfWhat => 'Из скольких?';

  @override
  String get purposeOffer => 'В предложении';

  @override
  String get purposeOfferLine => 'Цены, сделки и кто на самом деле платит';

  @override
  String get purposeArgument => 'В споре';

  @override
  String get purposeArgumentLine => 'Где рассуждение поскальзывается';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Один вопрос, который ловит почти всё это',
      '2': 'Два вопроса, которые ловят почти всё это',
      '3': 'Три вопроса, которые ловят почти всё это',
      '4': 'Четыре вопроса, которые ловят почти всё это',
      '5': 'Пять вопросов, которые ловят почти всё это',
      'other': 'Вопросы, которые ловят почти всё это ($n)',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Деньги',
      'work': 'Работа и время',
      'clock': 'Время',
      'body': 'Твоё тело',
      'relationships': 'Отношения',
      'belief': 'Во что ты веришь',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Плачу ли я за то, чем правда пользуюсь?',
      'work': 'Что помогло бы легче начать завтра?',
      'clock': 'Куда на самом деле уходит моё время?',
      'body': 'Верно ли ещё то, что я знаю о своём теле?',
      'relationships': 'Что на самом деле нужно моим близким?',
      'belief': 'Насколько я уверен — и почему?',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Деньги',
      'work': 'Работа',
      'clock': 'Время',
      'body': 'Тело',
      'relationships': 'Отношения',
      'belief': 'Во что я верю',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => 'О чём тебе нужны вопросы получше?';

  @override
  String get purposeLifeFooter =>
      'Выбери любые — и карточки об этом появятся здесь.';

  @override
  String get purposeSpotTrick => 'Найди подвох';

  @override
  String get purposeSpotTrickLine => 'Какой вопрос его поймает?';

  @override
  String get purposePlayed => 'Сегодняшние игры';

  @override
  String get purposePlayedOff => 'пунктов мимо в среднем';

  @override
  String get purposePlayedTricks => 'подвохов найдено';

  @override
  String get purposePlayedAnswered => 'ответов на полках';

  @override
  String get purposePlayedFooter =>
      'Ответы на полках идут в «Ваш путь», как и ответы в «Сегодня».';

  @override
  String purposeOf(int n, int of) {
    return '$n из $of';
  }

  @override
  String purposeSetRead(int n, int of) {
    return 'Прочитано $n из $of';
  }

  @override
  String purposeSetDone(int n) {
    return 'Прочитаны все $n. Когда полка вернётся, добавятся новые.';
  }

  @override
  String get purposeComplete => 'Собрано';

  @override
  String get purposeStampsFooter =>
      'Каждая прочитанная карточка добавляет свою марку.';

  @override
  String get purposeSets => 'Твои наборы';

  @override
  String get purposeSetsLine =>
      'Чтение считается. Чтобы собрать набор, отвечать не нужно.';

  @override
  String get purposeTomorrow => 'Завтра на полках';

  @override
  String get purposeTomorrowLine =>
      'Полки меняются каждый день. Вот что дальше';

  @override
  String get purposeEnd => 'Это конец «Обзора»';

  @override
  String get purposeEndLine => 'До завтра';

  @override
  String get betsRangeTitle => 'Ставка на диапазон';

  @override
  String get betsRangeLine => 'Чем уже, тем больше платит, если ты прав';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts оч.';
  }

  @override
  String get betsBet => 'Поставить';

  @override
  String betsInRange(int pts, String said) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'В диапазоне: +$pts очка. Это $said.',
      many: 'В диапазоне: +$pts очков. Это $said.',
      few: 'В диапазоне: +$pts очка. Это $said.',
      one: 'В диапазоне: +$pts очко. Это $said.',
    );
    return '$_temp0';
  }

  @override
  String betsMissedRange(String said) {
    return 'Мимо: это $said.';
  }

  @override
  String get betsYourGuess => 'Твоя оценка';

  @override
  String get betsAnsweredAlready => 'Уже отвечено';

  @override
  String get betsOpenCard => 'Открыть карточку';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Сегодня осталось $n очка',
      many: 'Сегодня осталось $n очков',
      few: 'Сегодня осталось $n очка',
      one: 'Сегодня осталось $n очко',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => 'Твой купон';

  @override
  String betsSlipToday(String points) {
    return '$points сегодня';
  }

  @override
  String get betsSlipEmpty =>
      'Ставок пока нет. Каждая твоя ставка появится здесь.';

  @override
  String get betsSlipTipTwice =>
      'Бери узкий, когда уверен: платит вдвое больше.';

  @override
  String get betsSlipTipThrice =>
      'Бери узкий, когда уверен: платит втрое больше.';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: 'Бери узкий, когда уверен: платит в $times раза больше.',
      many: 'Бери узкий, когда уверен: платит в $times раз больше.',
      few: 'Бери узкий, когда уверен: платит в $times раза больше.',
      one: 'Бери узкий, когда уверен: платит в $times раз больше.',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return 'Узких ставок сыграло: $right из $n.';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return 'Верно $right из $n, в среднем ты был уверен на $pct%.';
  }

  @override
  String get betsRight => 'Верно';

  @override
  String get betsWrong => 'Неверно';

  @override
  String betsOneIn(String n) {
    return '1 из $n';
  }

  @override
  String get betsOneInLabel => '1 из';

  @override
  String betsScore(int right, int steps) {
    return '$right из $steps';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return 'Верно $right из $steps.';
  }

  @override
  String get betsStakeTitle => 'Делай ставку';

  @override
  String betsStakeLine(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points очка в день. Выиграешь — ставка удвоится',
      many: '$points очков в день. Выиграешь — ставка удвоится',
      few: '$points очка в день. Выиграешь — ставка удвоится',
      one: '$points очко в день. Выиграешь — ставка удвоится',
    );
    return '$_temp0';
  }

  @override
  String get betsStakeLabel => 'Ставка';

  @override
  String betsBetN(int n) {
    return 'Ставка $n';
  }

  @override
  String get betsPickFirst => 'Сначала выбери';

  @override
  String get betsNotEnough => 'Не хватает очков';

  @override
  String betsWin(int n) {
    return 'Ты выигрываешь $n.';
  }

  @override
  String betsLose(int n) {
    return 'Ты теряешь $n.';
  }

  @override
  String betsYouWereSure(int pct) {
    return 'Ты был уверен на $pct%.';
  }

  @override
  String get betsFriendTitle => 'Поспорь с другом';

  @override
  String get betsFriendLine => 'Отправь вопрос, а потом сравните догадки';

  @override
  String get betsFriendNote =>
      'Твоя догадка останется на твоём телефоне. Карточка уходит вместе с ответом, так что сначала спроси, что думает друг.';

  @override
  String betsFriendNoteSaid(String said) {
    return 'Ты сказал: $said. Карточка уходит вместе с ответом, так что сначала спроси, что думает друг.';
  }

  @override
  String get betsFriendSend => 'Отправить другу';

  @override
  String get betsFriendCopy => 'Скопировать вопрос';

  @override
  String get betsFriendCopied => 'Вопрос скопирован';

  @override
  String get betsFriendAsk => 'А ты как думаешь?';

  @override
  String get betsNumberTitle => 'Твоё число';

  @override
  String get betsNumberLine =>
      'Выставь, зафиксируй и посмотри, насколько ошибся';

  @override
  String get betsLock => 'Готово';

  @override
  String get betsSpotOn => 'Точно.';

  @override
  String betsCloseEnough(String by) {
    return 'Достаточно близко: ошибка $by.';
  }

  @override
  String betsOffBy(String by) {
    return 'Ошибка: $by.';
  }

  @override
  String get betsYou => 'ты';

  @override
  String get betsAnswer => 'ответ';

  @override
  String get betsBiggerTitle => 'Что больше?';

  @override
  String get betsBiggerLine =>
      'Два числа, которые можно вычислить. Нажми на большее';

  @override
  String get betsTapIfBigger => 'Нажми, если больше';

  @override
  String get betsBiggerGotIt => 'Больше · верно';

  @override
  String get betsBigger => 'Больше';

  @override
  String get betsYourPick => 'Твой выбор';

  @override
  String get betsOr => 'или';

  @override
  String get betsBiggerFoot =>
      'Каждое число — ответ на какую-то карточку. После выбора нажми на число, чтобы открыть его карточку.';

  @override
  String betsBiggerScore(int right, int n) {
    return 'Верно $right из $n.';
  }

  @override
  String get betsCloserTitle => 'Ближе и ближе';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Два шага «больше или меньше», чтобы подобраться к числу',
      '3': 'Три шага «больше или меньше», чтобы подобраться к числу',
      '4': 'Четыре шага «больше или меньше», чтобы подобраться к числу',
      '5': 'Пять шагов «больше или меньше», чтобы подобраться к числу',
      'other': '$steps шагов «больше или меньше», чтобы подобраться к числу',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      '2': 'Два шага, чтобы подобраться.',
      '3': 'Три шага, чтобы подобраться.',
      '4': 'Четыре шага, чтобы подобраться.',
      '5': 'Пять шагов, чтобы подобраться.',
      'other': '$steps шагов, чтобы подобраться.',
    });
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return 'Больше или меньше $v?';
  }

  @override
  String betsStepOf(int at, int of) {
    return 'Шаг $at из $of';
  }

  @override
  String get betsMore => 'Больше';

  @override
  String get betsLess => 'Меньше';

  @override
  String betsCloserYesMore(String v) {
    return 'Верно: больше $v.';
  }

  @override
  String betsCloserYesLess(String v) {
    return 'Верно: меньше $v.';
  }

  @override
  String betsCloserNoMore(String v) {
    return 'Неверно: больше $v.';
  }

  @override
  String betsCloserNoLess(String v) {
    return 'Неверно: меньше $v.';
  }

  @override
  String betsCloserExact(String said) {
    return 'Ровно $said.';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return 'Это $said. Верно $right из $steps.';
  }

  @override
  String get betsMagnitudeTitle => 'Порядки величины';

  @override
  String get betsMagnitudeLine => 'Десять, тысяча или миллион? Выбери масштаб';

  @override
  String get betsMagnitudeRight => 'Порядок угадан.';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ошибка на $n порядка.',
      many: 'Ошибка на $n порядков.',
      few: 'Ошибка на $n порядка.',
      one: 'Ошибка на $n порядок.',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => 'Ставка дня';

  @override
  String get betsDayLine => 'Подтверди догадку и посмотри, насколько ошибся';

  @override
  String get betsDayTag => 'Ставка дня';

  @override
  String get betsDayTagSame => 'Ставка дня · одна для всех';

  @override
  String get betsLockIn => 'Подтвердить';

  @override
  String betsItIs(String said) {
    return 'Это $said.';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ошибка $n процентного пункта.',
      many: 'Ошибка $n процентных пунктов.',
      few: 'Ошибка $n процентных пункта.',
      one: 'Ошибка $n процентный пункт.',
      zero: 'Точно.',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '«$text»';
  }

  @override
  String get screensExpertTitle => 'Думай как эксперт';

  @override
  String get screensExpertLine =>
      'Вопрос, который каждый из них всегда задаёт, и карточки, где он нужен';

  @override
  String get screensExpertStatistician => 'Статистик';

  @override
  String get screensExpertStatisticianAs => 'Думай как статистик';

  @override
  String get screensExpertStatisticianAsks =>
      'По сравнению с чем и из скольких?';

  @override
  String get screensExpertEconomist => 'Экономист';

  @override
  String get screensExpertEconomistAs => 'Думай как экономист';

  @override
  String get screensExpertEconomistAsks => 'Кто платит и чем жертвует?';

  @override
  String get screensExpertHistorian => 'Историк';

  @override
  String get screensExpertHistorianAs => 'Думай как историк';

  @override
  String get screensExpertHistorianAsks => 'Что знали люди в то время?';

  @override
  String get screensExpertDoctor => 'Врач';

  @override
  String get screensExpertDoctorAs => 'Думай как врач';

  @override
  String get screensExpertDoctorAsks =>
      'Насколько это часто и чем ещё это может быть?';

  @override
  String get screensExpertScientist => 'Учёный';

  @override
  String get screensExpertScientistAs => 'Думай как учёный';

  @override
  String get screensExpertScientistAsks => 'Как бы мы узнали, что это неверно?';

  @override
  String get screensDotsTitle => 'Соедини точки';

  @override
  String get screensDotsLine =>
      'Выбери тему и посмотри, где она пересекается с другими';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: 'Пересекается с $subjects темы',
      many: 'Пересекается с $subjects темами',
      few: 'Пересекается с $subjects темами',
      one: 'Пересекается с $subjects темой',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: 'в $cards карточки',
      many: 'в $cards карточках',
      few: 'в $cards карточках',
      one: 'в $cards карточке',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get screensDotsWhere => 'Где они пересекаются';

  @override
  String get screensDotsWhereLine => 'Один вопрос, два взгляда';

  @override
  String get screensAskTitle => 'Что ты хочешь понять?';

  @override
  String get screensAskHint => 'Спроси что угодно или введи слово';

  @override
  String get screensAskTry => 'Например';

  @override
  String get screensAskClear => 'Очистить вопрос';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На него отвечают $n карточки',
      many: 'На него отвечают $n карточек',
      few: 'На него отвечают $n карточки',
      one: 'На него отвечает $n карточка',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => 'Об этом пока нет карточки';

  @override
  String get screensAskNoneLine =>
      'Сохрани вопрос. Когда на него ответит карточка, она появится здесь, под вопросом.';

  @override
  String get screensAskKeep => 'Сохранить вопрос';

  @override
  String get screensAskKept => 'Сохранён';

  @override
  String get screensAskedTitle => 'Твои вопросы';

  @override
  String get screensAskedLine => 'И карточки, которые на них ответили';

  @override
  String get screensAskedAnswered => 'Ответ';

  @override
  String get screensAskedWaiting =>
      'Пока ни одна карточка на него не отвечает. Когда появится, она будет здесь.';

  @override
  String get screensAskedForget => 'Забыть этот вопрос';

  @override
  String get screensAskedForgotten => 'Вопрос забыт';

  @override
  String get screensWhyTitle => 'Продолжай спрашивать «почему»';

  @override
  String get screensWhyLine => 'Каждый ответ рождает следующий вопрос';

  @override
  String get screensWhyAsk => 'Почему?';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n «почему» в глубину.',
    );
    return '$_temp0 Глубже уже некуда.';
  }

  @override
  String get screensWhyAgain => 'Начать заново';

  @override
  String get screensWhyHoles => 'Ещё кроличьи норы';

  @override
  String get screensWhyHolesLine =>
      'Каждая уходит на несколько «почему» вглубь';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n «почему»',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => 'Копнуть глубже';

  @override
  String screensWhySource(String source) {
    return 'Источник: $source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '$at «почему» из $of',
    );
    return '$_temp0';
  }

  @override
  String get screensTimeTitle => 'Сквозь время';

  @override
  String get screensTimeLine =>
      'По одной эпохе, вплоть до этого года. Потяни, чтобы путешествовать';

  @override
  String get screensTimeCaption =>
      'Лет назад. Каждое деление уходит в прошлое в десять раз дальше.';

  @override
  String get screensTimeNow => 'Сейчас';

  @override
  String get screensTimeEarlier => 'Дальше в прошлое';

  @override
  String get screensTimeLater => 'Ближе к нашим дням';

  @override
  String get screensEraAncient => 'Древний мир';

  @override
  String get screensEraAncientWhen => 'До 500 года';

  @override
  String get screensEraMedieval => 'Средние века';

  @override
  String get screensEraMedievalWhen => '500–1500 годы';

  @override
  String get screensEraEarlyModern => 'Раннее Новое время';

  @override
  String get screensEraEarlyModernWhen => '1500–1800 годы';

  @override
  String get screensEraNineteenth => 'XIX век';

  @override
  String get screensEraNineteenthWhen => '1800–1900 годы';

  @override
  String get screensEraTwentieth => 'Прошлый век';

  @override
  String get screensEraTwentiethWhen => '1900–2000 годы';

  @override
  String get screensEraRecent => 'Этот век';

  @override
  String get screensEraRecentWhen => 'С 2000 года';

  @override
  String get screensMindTitle => 'Измени мнение';

  @override
  String get screensMindLine =>
      'Скажи, что думаешь, до чтения, а потом ещё раз после';

  @override
  String get screensMindClaim => 'Утверждение';

  @override
  String get screensMindBefore => 'До чтения';

  @override
  String get screensMindTap => 'Отметь свою позицию';

  @override
  String get screensMindKnow => 'Что мы знаем';

  @override
  String get screensMindNow => 'А теперь?';

  @override
  String get screensMindAgain => 'Отметь ещё раз';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': 'Точно нет',
      '1': 'Скорее нет',
      '2': 'Не знаю',
      '3': 'Скорее да',
      'other': 'Точно да',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На $n шага ближе к фактам.',
      many: 'На $n шагов ближе к фактам.',
      few: 'На $n шага ближе к фактам.',
      one: 'На $n шаг ближе к фактам.',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame =>
      'Как и раньше. Одна карточка — это всего одна карточка.';

  @override
  String get screensMindAlready =>
      'Твоё мнение совпадало с фактами ещё до чтения.';

  @override
  String get screensMindAway =>
      'Твоё мнение отдалилось от фактов. Стоит перечитать.';

  @override
  String get screensMindFirst =>
      'Сначала скажи, что думаешь. Одно касание, до чтения.';

  @override
  String screensMindChanged(int changed, int total) {
    return 'Мнение изменилось в $changed из $total.';
  }

  @override
  String get screensMindFoot =>
      'Изменённое мнение — значит, карточка сделала своё дело.';

  @override
  String get screensSayTitle => 'Скажи это сегодня вечером';

  @override
  String get screensSayLine => 'Одна фраза к ужину. Нажми, когда скажешь её';

  @override
  String get screensSayTonight => 'Фраза на вечер';

  @override
  String get screensSaySaid => 'Сказано';

  @override
  String get screensSayDone => 'Уже сказано';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На этой неделе сказано $n фразы.',
      many: 'На этой неделе сказано $n фраз.',
      few: 'На этой неделе сказаны $n фразы.',
      one: 'На этой неделе сказана $n фраза.',
      zero: 'На этой неделе пока ничего не сказано.',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts =>
      'Каждая сказанная фраза засчитывается и в «Топ недели».';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => 'Сегодняшний выпуск';

  @override
  String get screensFrontSame => 'Один на всех';

  @override
  String get screensFrontLead => 'Главное';

  @override
  String get screensFrontNumbers => 'В цифрах';

  @override
  String get screensFrontCorrections => 'Поправки';

  @override
  String get screensFrontPuzzle => 'Задача дня';

  @override
  String get screensFrontEnd => 'Это сегодняшний выпуск';

  @override
  String get screensFrontTomorrow => 'Завтрашний выйдет утром';

  @override
  String exploreDayRead(int read, int of) {
    return 'Сегодня: прочитано $read из $of';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'осталось $n',
      many: 'осталось $n',
      few: 'осталось $n',
      one: 'осталась $n',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => 'все прочитаны';

  @override
  String get exploreDayOpen => 'К сегодняшним карточкам';

  @override
  String get exploreGameNone =>
      'Сейчас здесь не во что играть. Возвращайся завтра.';

  @override
  String get challengesTitle => 'Испытания';

  @override
  String get challengesLine =>
      'Короткие упражнения на суждение и оценку, по несколько минут каждое.';

  @override
  String challengesPage(int n, int of) {
    return 'Страница $n из $of';
  }

  @override
  String get gamePlay => 'Начать';

  @override
  String get sixtyRules =>
      'Восемь утверждений, правда или ложь, за одну минуту. Испытание измеряет, насколько верно ты судишь в спешке, а именно так мы судим почти обо всём, что читаем.';

  @override
  String get sixtyReview => 'Восемь утверждений';

  @override
  String get gameRight => 'Верно';

  @override
  String get gameWrong => 'Неверно';

  @override
  String get gameUnanswered => 'Нет ответа';

  @override
  String get gameNext => 'Следующее испытание';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · Шестьдесят секунд · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$n из $of верно · $s с';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: 'Осталось $s секунды',
      many: 'Осталось $s секунд',
      few: 'Осталось $s секунды',
      one: 'Осталась $s секунда',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => 'Карточки';

  @override
  String get gameTomorrow => 'Новый раунд завтра';

  @override
  String get gameContinue => 'Продолжить';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return '$n из $of верно';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки сегодня',
      many: '$n карточек сегодня',
      few: '$n карточки сегодня',
      one: '$n карточка сегодня',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => 'Всё верно.';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n очка',
      many: '$n очков',
      few: '$n очка',
      one: '$n очко',
    );
    return '$_temp0';
  }

  @override
  String get gameSeeResult => 'Посмотреть итог';

  @override
  String get gameNextCard => 'Дальше';

  @override
  String get spotOnce => 'Один выбор в день';

  @override
  String get spotGotIt => 'Ложное найдено.';

  @override
  String get spotMissedIt => 'Не то: это правда.';

  @override
  String get tfRules =>
      'Утверждения, в которых ошибается большинство. Скажи «правда» или «ложь», а потом прочитай почему. Испытание измеряет суждение: умение отличить то, что верно, от того, что лишь кажется очевидным.';

  @override
  String get inOrderTitle => 'По порядку';

  @override
  String get inOrderRules =>
      'Четыре события из карточек, без года: расставь их в том порядке, в каком они произошли. Испытание измеряет чувство хронологии, первую проверку любого объяснения: причина идёт раньше следствия.';

  @override
  String get inOrderFirst => 'Нажми событие, которое было первым.';

  @override
  String get inOrderNext => 'Теперь то, что было следующим.';

  @override
  String get inOrderReady => 'Всё расставлено.';

  @override
  String get inOrderCheck => 'Проверить порядок';

  @override
  String inOrderPlaced(int n) {
    return 'На месте $n';
  }

  @override
  String inOrderYours(int n) {
    return 'Твоё место: $n';
  }

  @override
  String get inOrderPerfect => 'Всё на своих местах.';

  @override
  String get timeGap => 'пропущенный год';

  @override
  String get whatYearTitle => 'Какой год?';

  @override
  String get whatYearRules =>
      'Три события, без года. Выставь год каждого: чем ближе, тем больше очков, до десяти. Испытание измеряет чувство того, когда что произошло.';

  @override
  String whatYearPoints(int n, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      of,
      locale: localeName,
      other: '$of очка',
      many: '$of очков',
      few: '$of очков',
      one: '$of очка',
    );
    return '$n из $_temp0';
  }

  @override
  String get whatYearPerfect => 'Все годы точно.';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'В сумме ошибка на $n года.',
      many: 'В сумме ошибка на $n лет.',
      few: 'В сумме ошибка на $n года.',
      one: 'В сумме ошибка на $n год.',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Твой ответ: $guess · $points очка',
      many: 'Твой ответ: $guess · $points очков',
      few: 'Твой ответ: $guess · $points очка',
      one: 'Твой ответ: $guess · $points очко',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ошибка на $n года',
      many: 'Ошибка на $n лет',
      few: 'Ошибка на $n года',
      one: 'Ошибка на $n год',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На $n года раньше',
      many: 'На $n лет раньше',
      few: 'На $n года раньше',
      one: 'На $n год раньше',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'На $n года позже',
      many: 'На $n лет позже',
      few: 'На $n года позже',
      one: 'На $n год позже',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => 'Год';

  @override
  String get beforeAfterTitle => 'Раньше или позже?';

  @override
  String get beforeAfterRules =>
      'Шесть событий, одно за другим. Скажи, случилось ли каждое раньше или позже того, что выше. Испытание измеряет чувство последовательности.';

  @override
  String get beforeAfterBefore => 'Раньше';

  @override
  String get beforeAfterAfter => 'Позже';

  @override
  String beforeAfterAsk(String year) {
    return 'До или после $year?';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return 'Твой ответ: до $year';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return 'Твой ответ: после $year';
  }

  @override
  String get beforeAfterStart => 'С этого всё началось';

  @override
  String get beforeAfterPerfect => 'Ни одной ошибки.';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n пары сегодня',
      many: '$n пар сегодня',
      few: '$n пары сегодня',
      one: '$n пара сегодня',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => 'Интуиция';

  @override
  String get spotSkill => 'Зоркость';

  @override
  String get tfSkill => 'Суждение';

  @override
  String get biggerSkill => 'Пропорция';

  @override
  String get closerSkill => 'Оценка';

  @override
  String get magnitudeSkill => 'Масштаб';

  @override
  String get rangeSkill => 'Калибровка';

  @override
  String get stakeSkill => 'Уверенность';

  @override
  String get numberSkill => 'Точность';

  @override
  String get inOrderSkill => 'Хронология';

  @override
  String get whatYearSkill => 'Датировка';

  @override
  String get beforeAfterSkill => 'Очерёдность';

  @override
  String get sixtyAsks => 'Восемь утверждений на время.';

  @override
  String get spotAsks => 'Четыре утверждения, одно из них ложное.';

  @override
  String get tfAsks => 'Утверждения, в которых ошибается почти каждый.';

  @override
  String get biggerAsks => 'Два числа. Какое больше?';

  @override
  String get closerAsks => 'Шаг за шагом ближе к числу.';

  @override
  String get magnitudeAsks => 'Найди нужную степень десяти.';

  @override
  String get rangeAsks => 'Диапазон ровно нужной ширины.';

  @override
  String get stakeAsks => 'Ставь очки по степени уверенности.';

  @override
  String get numberAsks => 'Остановись на одном числе.';

  @override
  String get inOrderAsks => 'Четыре события, от самого раннего.';

  @override
  String get whatYearAsks => 'Помести событие в его год.';

  @override
  String get beforeAfterAsks => 'Каждое событие против предыдущего.';

  @override
  String get challengeBest => 'Рекорд';

  @override
  String get challengeToday => 'Сегодня';

  @override
  String get challengeAccuracy => 'Доля верных';

  @override
  String get challengeTime => 'Время';

  @override
  String challengeSeconds(int s) {
    return '$s с';
  }

  @override
  String get challengePersonalBest => 'Личный рекорд';

  @override
  String challengeAboveChance(int n, int of) {
    return 'Выше случайного: наугад в среднем выходит $n из $of.';
  }

  @override
  String challengeAtChance(int n, int of) {
    return 'На уровне случайного: наугад в среднем выходит $n из $of.';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return 'Ниже случайного: наугад в среднем выходит $n из $of.';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Время вышло, $n утверждения остались без ответа.',
      many: 'Время вышло, $n утверждений осталось без ответа.',
      few: 'Время вышло, $n утверждения остались без ответа.',
      one: 'Время вышло, $n утверждение осталось без ответа.',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => 'Ещё раз';

  @override
  String get spotRules =>
      'Четыре утверждения: три верны, одно ложно. Найди ложное. Испытание измеряет, насколько хорошо ты отличаешь обоснованное утверждение от того, что лишь звучит убедительно.';

  @override
  String get spotAsk => 'Нажми на утверждение, которое считаешь ложным.';

  @override
  String get biggerRules =>
      'Два числа, каждое — ответ на вопрос карточки. Нажми на то, которое, по-твоему, больше. Испытание измеряет чувство пропорции.';

  @override
  String get biggerAsk => 'Нажми на карточку с большим ответом.';

  @override
  String biggerRight(String big, String small) {
    return 'Верно: $big больше, чем $small.';
  }

  @override
  String biggerWrong(String big, String small) {
    return 'Неверно: $big больше, чем $small.';
  }

  @override
  String get closerRules =>
      'Приближайся к доле шаг за шагом: каждый раз говори, больше она или меньше середины оставшегося промежутка. Испытание измеряет умение оценивать.';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps шага',
      many: '$steps шагов',
      few: '$steps шагов',
      one: '$steps шага',
    );
    return 'Это $said: верно $right из $_temp0.';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps шага',
      many: '$steps шагов',
      few: '$steps шагов',
      one: '$steps шага',
    );
    return 'Это ровно $said: верно $right из $_temp0.';
  }

  @override
  String closerStepsRight(int right, int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps шага',
      many: '$steps шагов',
      few: '$steps шагов',
      one: '$steps шага',
    );
    return 'Верно $right из $_temp0.';
  }

  @override
  String get magnitudeRules =>
      'Десять, тысяча или миллион? Выбери степень десяти, ближайшую к ответу. Испытание измеряет чувство масштаба, которое важнее точных цифр.';

  @override
  String get rangeRules =>
      'Задай свою оценку, а затем диапазон вокруг неё: чем он уже, тем больше приносит, если ответ попадёт внутрь. Испытание измеряет калибровку: знание того, сколько ты знаешь.';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · даёт $pts';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: 'Это $said: в твоём диапазоне, +$pts очка.',
      many: 'Это $said: в твоём диапазоне, +$pts очков.',
      few: 'Это $said: в твоём диапазоне, +$pts очка.',
      one: 'Это $said: в твоём диапазоне, +$pts очко.',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return 'Это $said: вне твоего диапазона.';
  }

  @override
  String stakeRules(int points) {
    return 'Выбери ответ и поставь на него очки из своих $points в день: если прав, ставка удваивается; если нет, сгорает. Испытание измеряет убеждённость: ставить на то, что знаешь, и только на это.';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Верно: ты выигрываешь $n очка.',
      many: 'Верно: ты выигрываешь $n очков.',
      few: 'Верно: ты выигрываешь $n очка.',
      one: 'Верно: ты выигрываешь $n очко.',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Неверно: ты теряешь $n очка.',
      many: 'Неверно: ты теряешь $n очков.',
      few: 'Неверно: ты теряешь $n очка.',
      one: 'Неверно: ты теряешь $n очко.',
    );
    return '$_temp0';
  }

  @override
  String get numberRules =>
      'Задай кнопками одно число и зафиксируй его. Испытание измеряет точность: насколько близко ты подходишь, когда нужно остановиться на одном числе.';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Верно: это правда.',
      'other': 'Верно: это ложь.',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': 'Неверно: это правда.',
      'other': 'Неверно: это ложь.',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$n из $of на своём месте.';
  }

  @override
  String get whatYearYours => 'Твой год';

  @override
  String get whatYearExactly => 'Точный год';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Верно: это был $year год, до $above.',
      'other': 'Верно: это был $year год, после $above.',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': 'Неверно: это был $year год, до $above.',
      'other': 'Неверно: это был $year год, после $above.',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => 'Ответ';

  @override
  String get challengeYouSaid => 'Твой ответ';

  @override
  String get challengePoints => 'Очки';

  @override
  String get challengeThisRound => 'Этот раунд';

  @override
  String get challengeLeftToday => 'Осталось на сегодня';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject, уровень $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return 'Похоже на сохранённое: «$question»';
  }

  @override
  String get todaySeeAgain => 'Смотреть снова';

  @override
  String get todaySeeAgainHint =>
      'Сегодняшние карточки снова, во весь экран, с первой';

  @override
  String get yourFiveFromToday => 'Твои пять карточек за сегодня';

  @override
  String get dayMomentTitle => 'День пройден.';

  @override
  String get dayMomentLater => 'Позже';

  @override
  String get yourDayCard => 'Твой день';

  @override
  String get tuneTitle => 'Настрой свой микс';

  @override
  String get tuneEntryLine => 'Сколько каждой темы и какие её части';

  @override
  String get tuneLearned =>
      'Уже сдвинуто понравившимися и отброшенными карточками. Сдвинь, чтобы изменить.';

  @override
  String get tuneFresh => 'Сдвинь тему, чтобы видеть её чаще или реже.';

  @override
  String get tuneHowMuch => 'Сколько каждой';

  @override
  String get tuneInsideLine =>
      'Части, которые понравились больше всего, идут первыми. Нажми, чтобы пропустить, удерживай, чтобы заглянуть внутрь.';

  @override
  String get tuneSave => 'Сохранить';

  @override
  String get tuneHoldHint => 'Задержи палец на жанре, и откроются темы внутри';

  @override
  String get shareDayTitle => 'Поделись своим днём';

  @override
  String get shareDayRead => 'Пять карточек прочитано';

  @override
  String get shareDayTurn => 'Пять карточек в день. Твоя очередь.';

  @override
  String shareDaySure(int n) {
    return 'уверенность $n%';
  }

  @override
  String get shareDayHeadline => 'Пять карточек дня';

  @override
  String get shareFormatCover => 'Обложка';

  @override
  String get shareFormatList => 'Список';

  @override
  String get shareFormatStory => 'История';

  @override
  String crowdGotRight(int n) {
    return '$n% читателей ответили верно';
  }

  @override
  String crowdGotWrong(int n) {
    return '$n% читателей тоже ошиблись';
  }

  @override
  String get challengeFriend => 'Брось вызов другу';

  @override
  String get challengeLine => 'Ответишь на эту?';

  @override
  String pathFree(int n) {
    return '$n бесплатно';
  }

  @override
  String pathMoreTitle(int n) {
    return 'Ещё $n в этом маршруте.';
  }

  @override
  String get pathMoreLine =>
      'Каждый маршрут целиком, от самой лёгкой карточки до самой трудной, и каждую неделю новые.';

  @override
  String get pathMoreGo => 'Читать весь маршрут';

  @override
  String get paywallPathsTitle => 'Каждый маршрут, все десять.';

  @override
  String get paywallPathsMark => 'все десять.';

  @override
  String get paywallPathsLine =>
      'Десять карточек на одну тему, от самой лёгкой до самой трудной. Новые маршруты каждую неделю и твои пять на сегодня — по твоему уровню.';

  @override
  String get widgetAskTitle => 'Первая карточка завтра — на экране «Домой».';

  @override
  String get widgetAskLine =>
      'Каждое утро новая карточка, не открывая приложения, и рядом твоя серия.';

  @override
  String get widgetAskStepHold =>
      'Нажми и удерживай пустое место на экране «Домой».';

  @override
  String get widgetAskStepAppleAdd =>
      'Коснись «Изменить», затем «Добавить виджет».';

  @override
  String get widgetAskStepApplePick =>
      'Найди Astute, выбери размер и коснись «Добавить виджет».';

  @override
  String get widgetAskStepAndroidAdd => 'Коснись «Виджеты».';

  @override
  String get widgetAskStepAndroidPick =>
      'Найди Astute, удерживай виджет и перетащи его на место.';

  @override
  String get widgetAskLockScreen =>
      'И на экране блокировки: удерживай его и коснись «Настроить».';

  @override
  String get widgetAskPin => 'Добавить на экран «Домой»';

  @override
  String get widgetAskGotIt => 'Понятно';

  @override
  String get widgetAskNotNow => 'Не сейчас';

  @override
  String pathCardOf(int n, int total) {
    return 'Карточка $n из $total';
  }

  @override
  String get pathDoorNext => 'Дальше по маршруту';

  @override
  String get shareSendCard => 'Отправить карточку';

  @override
  String get shareAsImage => 'Картинкой';

  @override
  String get shareCopyLink => 'Копировать ссылку';

  @override
  String get shareAnswerNote =>
      'Друг сначала видит вопрос. Ответ — в одном касании, на странице карточки.';

  @override
  String get shareWhichSide => 'Ты на чьей стороне?';

  @override
  String get rereadRight => 'В первый раз ты ответил верно.';

  @override
  String get rereadWrong => 'В первый раз ты ошибся.';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: 'ошибся на $off пункта',
      many: 'ошибся на $off пунктов',
      few: 'ошибся на $off пункта',
      one: 'ошибся на $off пункт',
      zero: 'попал точно',
    );
    return 'Ставка дня в Astute: $_temp0. Сможешь точнее?';
  }

  @override
  String get playTheCard => 'Сыграть карточку';

  @override
  String get openTheCard => 'Открыть карточку';

  @override
  String get perkPathsTitle => 'Каждый путь целиком';

  @override
  String get perkPathsLine =>
      'Десять карточек на одну тему, от самой простой до самой сложной. Новые пути каждую неделю.';

  @override
  String get journeyStrongest => 'Сильнее всего';

  @override
  String get journeyMostMissed => 'Чаще всего мимо';

  @override
  String journeyRightShare(String pct) {
    return '$pct верно';
  }

  @override
  String get journeyChangedMind => 'Смена мнения';

  @override
  String get journeyNewToYou => 'Новое для тебя';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'из $n карточки, которые спрашивали',
      many: 'из $n карточек, которые спрашивали',
      few: 'из $n карточек, которые спрашивали',
      one: 'из $n карточки, которая спрашивала',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n уже знакомы',
      many: '$n уже знакомы',
      few: '$n уже знакомы',
      one: '$n уже знакомо',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => 'Твой путь как история';

  @override
  String get storyLabNote => 'Новая версия · в тесте, только TestFlight';

  @override
  String get storyChapterWeek => 'На этой неделе';

  @override
  String get storyChapterWhere => 'Где ты сейчас';

  @override
  String get storyChapterReason => 'Как ты рассуждаешь';

  @override
  String get storyChapterPractice => 'Тренировка';

  @override
  String get storyChapterStory => 'Твоя история';

  @override
  String get journeyChapterKnow => 'Что ты знаешь';

  @override
  String get journeyChapterHabits => 'Твои привычки';

  @override
  String get journeyChapterCoach => 'Твой коуч';

  @override
  String get coachTeaser =>
      'Каждую неделю — заметка коуча о том, как ты рассуждаешь: что получилось, какой ловушки остерегаться и что попробовать дальше.';

  @override
  String get coachRead => 'Прочитать заметку недели';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Из 10 уверенных ответов верны $n.',
      many: 'Из 10 уверенных ответов верны $n.',
      few: 'Из 10 уверенных ответов верны $n.',
      one: 'Из 10 уверенных ответов верен $n.',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => 'Лучше, чем на прошлой неделе.';

  @override
  String get storyWorse => 'Чуть хуже, чем на прошлой неделе.';

  @override
  String storyHeadlineStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня подряд. Не теряй нить.',
      many: '$n дней подряд. Не теряй нить.',
      few: '$n дня подряд. Не теряй нить.',
      one: '$n день подряд. Не теряй нить.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return 'В теме «$subject» верных ответов $pct.';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки прочитано. Путь начинается здесь.',
      many: '$n карточек прочитано. Путь начинается здесь.',
      few: '$n карточки прочитаны. Путь начинается здесь.',
      one: '$n карточка прочитана. Путь начинается здесь.',
      zero: 'Твоя первая карточка ждёт.',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadWeek(int n, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки прочитано',
      many: '$n карточек прочитано',
      few: '$n карточки прочитаны',
      one: '$n карточка прочитана',
    );
    String _temp1 = intl.Intl.pluralLogic(
      week,
      locale: localeName,
      other: '$week на этой неделе.',
      zero: 'на этой неделе пока ни одной.',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String storyHeadlineReadAllWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки прочитано, все на этой неделе.',
      many: '$n карточек прочитано, все на этой неделе.',
      few: '$n карточки прочитаны, все на этой неделе.',
      one: '$n карточка прочитана, все на этой неделе.',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return 'Твоя уверенность — $sure, верных ответов — $right.';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ещё $n ответа с уверенностью — и это будет измерено.',
      many: 'Ещё $n ответов с уверенностью — и это будет измерено.',
      few: 'Ещё $n ответа с уверенностью — и это будет измерено.',
      one: 'Ещё $n ответ с уверенностью — и это будет измерено.',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return 'Излишняя уверенность: $subject, на $points п.';
  }

  @override
  String get storyUnlock => 'Смотреть с Astute+';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ошибки при уверенности',
      many: '$n ошибок при уверенности',
      few: '$n ошибки при уверенности',
      one: '$n ошибка при уверенности',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки, изменившие твоё мнение',
      many: '$n карточек, изменивших твоё мнение',
      few: '$n карточки, изменившие твоё мнение',
      one: '$n карточка, изменившая твоё мнение',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '5 новых карточек: $subject';
  }

  @override
  String get storyPracticeNone =>
      'Пока нечего тренировать: ответь на несколько карточек, и всё появится.';

  @override
  String get storyFirstCard => 'Первая карточка';

  @override
  String storyReached(String level) {
    return 'Достигнуто: $level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Лучшая серия: $n дня',
      many: 'Лучшая серия: $n дней',
      few: 'Лучшая серия: $n дня',
      one: 'Лучшая серия: $n день',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n карточки прочитано',
      many: '$n карточек прочитано',
      few: '$n карточки прочитаны',
      one: '$n карточка прочитана',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => 'Сегодня';

  @override
  String get storySeePath => 'Смотреть путь';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n новой карточки сверху',
      many: '$n новых карточек сверху',
      few: '$n новые карточки сверху',
      one: '$n новая карточка сверху',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => 'Всё просмотрено: пока ничего нового.';

  @override
  String get deeperTitle => 'Глубже';

  @override
  String get deeperSimple => 'Объясни просто';

  @override
  String get deeperWhy => 'Почему это важно';

  @override
  String get deeperSides => 'Обе стороны';

  @override
  String get deeperExample => 'Пример из обычной жизни';

  @override
  String get deeperQuiz => 'Проверь меня на новом примере';

  @override
  String get deeperQuizRight => 'Верно.';

  @override
  String get deeperQuizWrong => 'Не совсем.';

  @override
  String get mathsDailySolve => 'Решить';

  @override
  String get mathsDailySolved => 'Решено';

  @override
  String get mathsDailyMissed => 'Не в этот раз';

  @override
  String get mathsDailyTomorrow => 'Завтра будет новая';

  @override
  String get mathsDailyAnother => 'Ещё одну такую';

  @override
  String goalShelf(String goal) {
    return 'Пригодится: $goal';
  }

  @override
  String get goalDecide => 'Решения на каждый день';

  @override
  String get goalPeople => 'Люди';

  @override
  String get goalBusiness => 'Работа и бизнес';

  @override
  String get goalMoney => 'Деньги и покупки';

  @override
  String get goalHealth => 'Здоровье';

  @override
  String get goalDecideLine => 'Выбор, риски и вероятности без догадок.';

  @override
  String get goalNews => 'Новости и соцсети';

  @override
  String get goalNewsLine =>
      'Заголовки, статистика и посты: чему можно верить.';

  @override
  String get goalPeopleLine => 'Кто пытается тебя убедить и как быть понятым.';

  @override
  String get goalBusinessLine => 'Переговоры, стимулы и цифры за любой идеей.';

  @override
  String get goalMoneyLine => 'Цены, скидки, проценты: ловушки в любой сделке.';

  @override
  String get goalHealthLine =>
      'Диеты, лекарства и исследования: что говорят факты.';

  @override
  String mathsDailyStreak(int n) {
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
  String get deeperYourTake => 'Твоя мысль под лупой';

  @override
  String get deeperYourTakeHint => 'Напиши, что ты об этом думаешь…';

  @override
  String get deeperAnalyse => 'Разобрать';

  @override
  String get deeperAsk => 'Спроси об этой карточке';

  @override
  String get deeperAskHint => 'Твой вопрос…';

  @override
  String get deeperSend => 'Спросить';

  @override
  String get deeperSource => 'Источник';

  @override
  String get deeperOpenSource => 'Открыть оригинал';

  @override
  String get deeperAiNote => 'Отвечает ИИ: он может ошибаться.';

  @override
  String get deeperBusy => 'Думаю…';

  @override
  String get deeperTomorrow => 'На сегодня хватит: завтра ещё.';

  @override
  String get deeperTryAgain => 'Не дошло. Попробуй через минуту.';

  @override
  String get deeperUnavailable => 'Сейчас недоступно. Попробуй позже.';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n издания',
      many: '$n изданий',
      few: '$n издания',
      one: '$n издание',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ч назад',
      zero: 'Только что',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня назад',
      many: '$n дней назад',
      few: '$n дня назад',
      one: 'Вчера',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => 'Мир';

  @override
  String get newsKeyPoints => 'Главное';

  @override
  String get newsBehind => 'За новостью';

  @override
  String get newsMeansForYou => 'Что это значит для тебя';

  @override
  String get newsMeans => 'Что это значит';

  @override
  String get newsHappenedBefore => 'Такое уже было';

  @override
  String get newsSources => 'Источники';

  @override
  String get newsMadeFrom =>
      'Написано Astute по этим материалам и сверено с ними.';

  @override
  String get newsWhyItMatters => 'Почему это важно';

  @override
  String get deeperDeclined => 'На это ИИ ответить не может.';

  @override
  String get deeperPlusOnly => 'С Astute+';

  @override
  String get deeperSimpleLead =>
      'Идея карточки простыми словами — как для любопытного десятилетнего ребёнка.';

  @override
  String get deeperSidesLead =>
      'Самые сильные доводы каждой стороны — и что решило бы спор.';

  @override
  String get deeperExampleLead =>
      'Момент из обычного дня, когда эта идея даёт о себе знать.';

  @override
  String get deeperQuizLead =>
      'Случай, которого нет в карточке: один вопрос, три ответа.';

  @override
  String get deeperYourTakeLead =>
      'Что в твоём рассуждении держится, где оно спотыкается, и вопрос, чтобы его проверить.';

  @override
  String get deeperAskLead => 'Всё, что после карточки хочется спросить.';

  @override
  String get deeperSideA => 'Одна сторона';

  @override
  String get deeperSideB => 'Другая сторона';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => 'Повторить';

  @override
  String get deeperSimpleGo => 'Объясни мне';

  @override
  String get deeperSidesGo => 'Покажи обе стороны';

  @override
  String get deeperExampleGo => 'Приведи пример';

  @override
  String get deeperQuizGo => 'Проверь меня';

  @override
  String get bookOfTheWeek => 'Книга недели';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n идеи',
      many: '$n идей',
      few: '$n идеи',
      one: '$n идея',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ещё $n идеи из этой книги',
      many: 'Ещё $n идей из этой книги',
      few: 'Ещё $n идеи из этой книги',
      one: 'Ещё $n идея из этой книги',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine =>
      'Вся книга с Astute+, а каждую неделю одна книга бесплатно.';

  @override
  String get bookMoreGo => 'Читать всю книгу';

  @override
  String bookMinutes(int n) {
    return '$n мин';
  }

  @override
  String get bookStart => 'Начать читать';

  @override
  String get bookContinue => 'Продолжить';

  @override
  String get bookAgain => 'Перечитать';

  @override
  String get bookTheIdeas => 'Идеи';

  @override
  String get bookRecommendedBy => 'Рекомендуют';

  @override
  String get bookFreeThisWeek => 'Бесплатно на этой неделе';

  @override
  String get booksSeeAll => 'Смотреть все';

  @override
  String get booksLibraryTitle => 'Все книги';

  @override
  String get bookDoneTitle => 'Книга прочитана';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return 'Главных идей: $ideas, за $minutes мин.';
  }

  @override
  String bookDoneCount(int count) {
    return 'Прочитано книг: $count';
  }

  @override
  String get bookDoneNext => 'Следующая книга';

  @override
  String get bookDoneGo => 'Открыть';

  @override
  String bookRetold(String title, String author) {
    return 'Идеи книги «$title» ($author), пересказанные словами Astute. Всю книгу ищи в книжном.';
  }

  @override
  String get foundersTitle => 'Что читают основатели';

  @override
  String founderBookCount(int n) {
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
  String get founderTheirBooks => 'Рекомендованные книги';

  @override
  String founderRole(String id, String role) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bill_gates': 'Сооснователь Microsoft',
      'warren_buffett': 'Инвестор, который построил Berkshire Hathaway',
      'mark_zuckerberg': 'Основатель Facebook',
      'charlie_munger': 'Партнёр Уоррена Баффета по Berkshire Hathaway',
      'marc_andreessen': 'Сооснователь Netscape и Andreessen Horowitz',
      'tobi_lutke': 'Основатель Shopify',
      'naval_ravikant': 'Сооснователь AngelList',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String founderWhere(String id, String where) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'gates_summer': 'GatesNotes, его книги на лето',
      'berkshire_meeting': 'годовое собрание акционеров Berkshire Hathaway',
      'berkshire_letter': 'его письмо акционерам Berkshire Hathaway',
      'year_of_books': 'A Year of Books, в Facebook',
      'publisher_praise': 'его отзыв о книге на сайте издательства',
      'ferriss_five':
          'The Tim Ferriss Show, среди пяти лучших прочитанных им книг',
      'other': '$where',
    });
    return '$_temp0';
  }

  @override
  String founderAbout(String name) {
    return 'Это книги, рекомендованные публично, в приведённых словах и с указанием, где это было сказано. $name не имеет никакого отношения к Astute.';
  }

  @override
  String founderPhoto(String author, String licence) {
    return 'Фото: $author, $licence, Wikimedia Commons, кадрировано';
  }

  @override
  String founderAlso(String names) {
    return 'Также рекомендуют: $names';
  }

  @override
  String get firstCardTitle => 'Твоя первая карточка';

  @override
  String get firstCardSwipeOn => 'Листай дальше';

  @override
  String get trialOfferTitle => 'Попробуй весь Astute+.';

  @override
  String get trialOfferMark => 'Astute+.';

  @override
  String get trialOfferLine =>
      'Пять сегодняшних карточек ждут тебя в любом случае.';

  @override
  String get trialStepToday => 'Сегодня';

  @override
  String get trialStepTodayLine =>
      'Открывается весь Astute+. Ты ничего не платишь.';

  @override
  String trialStepDay(int day) {
    return 'День $day';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Мы пришлём тебе уведомление: осталось $days дня.',
      many: 'Мы пришлём тебе уведомление: осталось $days дней.',
      few: 'Мы пришлём тебе уведомление: осталось $days дня.',
      one: 'Мы пришлём тебе уведомление: остался 1 день.',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine =>
      'Продлевается каждый год. Отмени хотя бы за 24 часа — и ничего не заплатишь.';

  @override
  String get trialOfferStart => 'Начать пробный период';

  @override
  String get trialOfferFree => 'Продолжить бесплатно';

  @override
  String get paywallStepFree => 'Всё бесплатно';

  @override
  String get paywallStepRemind => 'Мы напомним';

  @override
  String get paywallChargedToday => 'Списание сегодня · Отмена в любой момент';

  @override
  String paywallGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'Для тех, кто хочет решать лучше.',
      'money': 'Для тех, кого не провести с деньгами.',
      'people': 'Для тех, кто хочет понимать людей.',
      'news': 'Для тех, кто не верит заголовкам.',
      'health': 'Для тех, кому о здоровье нужны доказательства.',
      'business': 'Для тех, кто хочет ясности в работе.',
      'other': 'Для тех, кто хочет ясности.',
    });
    return '$_temp0';
  }

  @override
  String paywallGoalMark(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': 'лучше.',
      'money': 'деньгами.',
      'people': 'людей.',
      'news': 'заголовкам.',
      'health': 'доказательства.',
      'business': 'ясности',
      'other': 'ясности.',
    });
    return '$_temp0';
  }

  @override
  String paywallMadeLine(String subjects) {
    return 'Пять карточек в день на твоём уровне, темы: $subjects. Те, где ты ошибаешься, возвращаются, пока не запомнятся. И ты видишь, как меняешься, неделя за неделей.';
  }

  @override
  String subjectsTwo(String a, String b) {
    return '$a и $b';
  }

  @override
  String subjectsThree(String a, String b, String c) {
    return '$a, $b и $c';
  }

  @override
  String get firstWeekTitle => 'Твоя первая неделя';

  @override
  String get firstMonthTitle => 'Твой первый месяц';

  @override
  String firstOfferDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n дня чтения',
      many: '$n дней чтения',
      few: '$n дня чтения',
      one: '$n день чтения',
    );
    return '$_temp0';
  }

  @override
  String get firstWeekBest => 'Лучшая карточка недели';

  @override
  String get firstMonthBest => 'Лучшая карточка месяца';

  @override
  String firstOfferBestWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'said': 'Ты рассказал о ней кому-то.',
      'liked': 'Она тебе понравилась.',
      'saved': 'Ты её сохранил.',
      'changed': 'Она изменила твоё мнение.',
      'other': 'Ты её сохранил.',
    });
    return '$_temp0';
  }

  @override
  String firstOfferTrialTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+ бесплатно на $days дня',
      many: 'Astute+ бесплатно на $days дней',
      few: 'Astute+ бесплатно на $days дня',
      one: 'Astute+ бесплатно на $days день',
    );
    return '$_temp0';
  }

  @override
  String get firstOfferPlusLine =>
      'Пять своих карточек каждый день, каждый путь и каждая книга, а ещё твои цифры неделя за неделей.';

  @override
  String get firstOfferNotNow => 'Не сейчас';

  @override
  String get listenEntry => 'Послушай сегодняшние пять';

  @override
  String get listenEntryShort => 'Слушать';

  @override
  String get listenTitle => 'Пять карточек за сегодня';

  @override
  String get listenQuestion => 'Вопрос';

  @override
  String get listenThink => 'Подумай…';

  @override
  String get listenAnswer => 'Ответ';

  @override
  String get listenPreparing => 'Готовлю голос…';

  @override
  String get listenWaiting => 'Следующая карточка уже в пути…';

  @override
  String get listenFreeNote =>
      'Первая карточка бесплатно, остальные — с Astute+.';

  @override
  String get listenOfferTitle => 'Остальные карточки дня, прочитанные для тебя';

  @override
  String get listenOfferLine =>
      'С Astute+ ты слушаешь все пять каждый день, даже с заблокированным экраном.';

  @override
  String get listenNothing => 'В этой карточке нечего слушать';

  @override
  String get listenCardUnavailable => 'Сейчас недоступно';

  @override
  String get listenUnavailable =>
      'Прослушивание сейчас недоступно. Попробуй позже.';

  @override
  String get listenDone => 'Все карточки дня прослушаны.';

  @override
  String get listenAgain => 'Послушать ещё раз';

  @override
  String get listenNextCard => 'Следующая карточка';

  @override
  String get inviteSection => 'Друзья';

  @override
  String get inviteRow => 'Пригласить друга';

  @override
  String get inviteRowLine => 'Неделя Astute+ вам обоим';

  @override
  String get inviteCodeRow => 'Есть код?';

  @override
  String get inviteCodeAccepted => 'Код принят';

  @override
  String get inviteCodeAcceptedLine =>
      'Неделя начнётся, когда ты закончишь первый день';

  @override
  String get inviteSheetLine =>
      'Отправь другу свой код. Когда он закончит первый день — пять карточек, — каждый из вас получит неделю Astute+.';

  @override
  String get inviteYourCode => 'Твой код';

  @override
  String get inviteCopy => 'Копировать';

  @override
  String get inviteSend => 'Отправить приглашение';

  @override
  String inviteRules(int cap) {
    return 'Для нового аккаунта, у которого никогда не было Astute+. Ты получаешь до $cap недель в год.';
  }

  @override
  String inviteWeeksSoFar(int n, int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n из $cap недель в этом году',
    );
    return '$_temp0';
  }

  @override
  String inviteCapped(int cap) {
    return 'Ты уже получил $cap недель за этот год. Друзья всё равно получат свою.';
  }

  @override
  String inviteMessage(String code, String link) {
    return 'Приглашаю тебя в Astute: пять карточек в день, чтобы голова оставалась острой. С моим кодом $code, когда ты закончишь первый день, мы оба получим неделю Astute+.\n$link';
  }

  @override
  String inviteMessageCapped(String code, String link) {
    return 'Приглашаю тебя в Astute: пять карточек в день, чтобы голова оставалась острой. С моим кодом $code, когда ты закончишь первый день, ты получишь неделю Astute+ в подарок.\n$link';
  }

  @override
  String get inviteCodeTitle => 'Код от друга';

  @override
  String get inviteCodeLine =>
      'Введи код, который прислал тебе друг. Когда ты закончишь первый день, каждый из вас получит неделю Astute+.';

  @override
  String get inviteCodeUse => 'Применить код';

  @override
  String get inviteCodeWaitingLine =>
      'Закончи первый день — пять карточек: тогда начнётся неделя Astute+, для тебя и для друга, который тебя пригласил.';

  @override
  String get inviteRefusedUnknown =>
      'Такого кода нет. Проверь символы и попробуй ещё раз.';

  @override
  String get inviteRefusedOwn => 'Это твой собственный код: отправь его другу.';

  @override
  String get inviteRefusedUsed => 'Ты уже использовал код друга.';

  @override
  String get inviteRefusedLate =>
      'Коды действуют для новых аккаунтов, в их первую неделю.';

  @override
  String get inviteRefusedPlus =>
      'Коды действуют для аккаунтов, у которых никогда не было Astute+.';

  @override
  String get inviteSuccessTitle => 'Неделя Astute+ в подарок.';

  @override
  String get inviteSuccessPlan => 'Astute+ · неделя';

  @override
  String inviteSuccessUntil(String date) {
    return 'До $date';
  }

  @override
  String get inviteSuccessFoot =>
      'Ничего платить и ничего отменять не нужно: потом ты вернёшься на бесплатный план.';

  @override
  String inviteEarned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n друга закончили первый день: $n недели Astute+ для тебя.',
      many: '$n друзей закончили первый день: $n недель Astute+ для тебя.',
      few: '$n друга закончили первый день: $n недели Astute+ для тебя.',
      one: '$n друг закончил первый день: $n неделя Astute+ для тебя.',
    );
    return '$_temp0';
  }

  @override
  String giftTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+ твой на $days дня.',
      many: 'Astute+ твой на $days дней.',
      few: 'Astute+ твой на $days дня.',
      one: 'Astute+ твой на $days день.',
    );
    return '$_temp0';
  }

  @override
  String get giftMark => 'твой';

  @override
  String get giftLine => 'Без банковской карты, ничего не нужно отменять.';

  @override
  String get giftStepEndLine => 'Снова бесплатный план. Ничего не списывается.';

  @override
  String get giftStart => 'Начать читать';

  @override
  String giftEndsSoon(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+ твой ещё $days дня.',
      many: 'Astute+ твой ещё $days дней.',
      few: 'Astute+ твой ещё $days дня.',
      one: 'Последний день Astute+.',
    );
    return '$_temp0';
  }

  @override
  String giftPlanUntil(String date) {
    return 'Astute+ · в подарок до $date';
  }

  @override
  String get giftEndEyebrow => 'Подарок закончился';

  @override
  String giftEndTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Твои $days дня с Astute+.',
      many: 'Твои $days дней с Astute+.',
      few: 'Твои $days дня с Astute+.',
      one: 'Твой день с Astute+.',
    );
    return '$_temp0';
  }

  @override
  String get giftEndDaysLabel => 'дней чтения';

  @override
  String giftEndBackRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'сначала ошибка, потом верно',
      many: 'сначала ошибка, потом верно',
      few: 'сначала ошибка, потом верно',
      one: 'сначала ошибка, потом верно',
    );
    return '$_temp0';
  }

  @override
  String get giftLossTitle => 'С сегодняшнего дня, на бесплатном плане';

  @override
  String giftLossRandom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n из пяти твоих карточек — случайные.',
      many: '$n из пяти твоих карточек — случайные.',
      few: '$n из пяти твоих карточек — случайные.',
      one: '$n из пяти твоих карточек — случайная.',
    );
    return '$_temp0';
  }

  @override
  String get giftLossMisses =>
      'Карточки с ошибками больше не возвращаются в твою пятёрку: они ждут в «Обзоре».';

  @override
  String get giftLossAsk => 'Помощник к каждой карточке остаётся в Astute+.';

  @override
  String get giftKeep => 'Оставить Astute+';

  @override
  String sixthRandomToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Сегодня $n из твоих пяти — случайные.',
      many: 'Сегодня $n из твоих пяти — случайные.',
      few: 'Сегодня $n из твоих пяти — случайные.',
      one: 'Сегодня $n из твоих пяти — случайная.',
    );
    return '$_temp0';
  }

  @override
  String get sixthRandomTodayPlus =>
      'С Astute+ все пять были бы выбраны для тебя.';

  @override
  String sixthRandomTomorrow(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Завтра $n из твоих пяти будут случайными.',
      many: 'Завтра $n из твоих пяти будут случайными.',
      few: 'Завтра $n из твоих пяти будут случайными.',
      one: 'Завтра $n из твоих пяти будет случайной.',
    );
    return '$_temp0';
  }

  @override
  String get sixthRandomTomorrowPlus =>
      'С Astute+ все пять выбраны для тебя: из твоего микса, на твоём уровне.';

  @override
  String sixthSureWrong(String sure) {
    return 'Сегодня ты ошибся в карточке, в которой был уверен на $sure.';
  }

  @override
  String get sixthSureWrongPlus => 'С Astute+ она вернётся в твою пятёрку.';

  @override
  String sixthMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Вернулись $n карточки, где ты ошибся: они ждут в «Обзоре».',
      many: 'Вернулись $n карточек, где ты ошибся: они ждут в «Обзоре».',
      few: 'Вернулись $n карточки, где ты ошибся: они ждут в «Обзоре».',
      one: 'Вернулась $n карточка, где ты ошибся: она ждёт в «Обзоре».',
    );
    return '$_temp0';
  }

  @override
  String get sixthMissesPlus =>
      'С Astute+ ошибки возвращаются в твою пятёрку, по одной в день.';

  @override
  String sixthLevel(String subject, int right, int of) {
    return '$subject: верно $right из $of.';
  }

  @override
  String sixthLevelPlus(String subject) {
    return 'С Astute+ карточки по теме «$subject» стали бы на уровень выше.';
  }

  @override
  String get paywallScience =>
      'Калибровку можно натренировать: прогнозы точнее примерно на 10%.';

  @override
  String get paywallScienceSource => 'Меллерс и др., Good Judgment Project';

  @override
  String get paywallWarnBefore => 'Мы предупредим за два дня до списания';

  @override
  String get plusInTheAppAndroid =>
      'Astute+ — в приложении: скачай Astute на Android, чтобы начать бесплатный период. Скоро и на iPhone.';

  @override
  String get exploreCapTitle => 'На сегодня «Обзор» закончился.';

  @override
  String exploreCapLine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ты прочитал $n карточки сверх своих пяти. Завтра будут новые.',
      many: 'Ты прочитал $n карточек сверх своих пяти. Завтра будут новые.',
      few: 'Ты прочитал $n карточки сверх своих пяти. Завтра будут новые.',
      one: 'Ты прочитал $n карточку сверх своих пяти. Завтра будут новые.',
    );
    return '$_temp0';
  }

  @override
  String get exploreCapPlus => 'С Astute+ у «Обзора» нет конца.';
}
