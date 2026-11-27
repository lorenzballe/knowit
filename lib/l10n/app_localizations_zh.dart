// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => '今天';

  @override
  String get tabExplore => '探索';

  @override
  String get tabProfile => '我的';

  @override
  String couldNotSignInCarryOn(String label) {
    return '无法通过 $label 登录。你可以不用账号继续。';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => '一次冻结保住了连续记录';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': '一',
      '2': '两',
      '3': '三',
      '4': '四',
      '5': '五',
      '6': '六',
      '7': '七',
      '8': '八',
      '9': '九',
      '10': '十',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayTitle(int n) {
    return '第 $n 天';
  }

  @override
  String shelfEyebrow(String word) {
    return '今日$word张';
  }

  @override
  String get tapToFlip => '点按翻面';

  @override
  String get shareThisCard => '分享这张卡片';

  @override
  String get removeFromSaved => '取消收藏';

  @override
  String get saveThisPill => '收藏这张卡片';

  @override
  String get shareThisPill => '分享这张卡片';

  @override
  String get share => '分享';

  @override
  String cardOf(int k, int n) {
    return '第 $k 张，共 $n 张';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return '明天的五张 · 还有$when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '明天从$topic开始 · 还有$when';
  }

  @override
  String get exploreTodaysBest => '探索今日精选';

  @override
  String magicUnlock(int days) {
    return '免费试用$days天';
  }

  @override
  String get getPlus => '升级到 Astute+';

  @override
  String nothingInYet(String subject) {
    return '$subject 里还没有内容。';
  }

  @override
  String get here => '这个板块';

  @override
  String get todaysShelf => '今日书架';

  @override
  String get sameForEveryone => '人人相同，仅限今天';

  @override
  String becauseSitsAtFull(String name) {
    return '因为 $name 已调到最高';
  }

  @override
  String get olderFromTurnedUp => '你调高的主题里的旧卡片';

  @override
  String moreOn(String name) {
    return '更多 $name';
  }

  @override
  String get subjectReadMost => '你读得最多的主题';

  @override
  String monthOf(String name) {
    return '一个月的 $name';
  }

  @override
  String get somewhereToStart => '一个不是今天的起点';

  @override
  String get searchEveryCard => '搜索所有卡片';

  @override
  String nothingForYet(String query) {
    return '还没有与“$query”相关的内容。';
  }

  @override
  String matching(int n) {
    return '$n 条匹配';
  }

  @override
  String get all => '全部';

  @override
  String get theArchive => '档案';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 条结果',
      one: '1 条结果',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n 张卡片。点按某一天即可打开。';
  }

  @override
  String get whatYouHaveCovered => '你已涉及的范围';

  @override
  String searchNCards(int n) {
    return '在 $n 张卡片中搜索';
  }

  @override
  String get cancel => '取消';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张',
      one: '1 张',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '昨天';

  @override
  String get noPillsMatchFilter => '还没有卡片符合这个筛选。';

  @override
  String nothingForTryTopic(String query) {
    return '没有与“$query”相关的内容。试试按主题找。';
  }

  @override
  String get saved => '收藏';

  @override
  String get removedFromSaved => '已取消收藏。';

  @override
  String get undo => '撤销';

  @override
  String get nothingKeptYet => '还没有收藏';

  @override
  String nInTopic(int n, String topic) {
    return '$topic 中 $n 张';
  }

  @override
  String get keepTheOnesYoullUse => '只收藏你真会用到的';

  @override
  String get backToTodaysFive => '回到今日五张';

  @override
  String get archive => '档案';

  @override
  String get yourWeek => '你的这一周';

  @override
  String get nothingThisWeekYet => '本周还没有记录。五张卡片就是开始。';

  @override
  String keptDaysOfSeven(int days) {
    return '已达成——七天中完成 $days 天。';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '七天中完成 $days 天。',
      one: '七天中完成 1 天。',
    );
    return '$_temp0完成五天即算达成。';
  }

  @override
  String get howSureAgainstHowRight => '有多确定，对了多少';

  @override
  String get sureAndWrong => '确定，却答错了';

  @override
  String get worthGoingBackTo => '值得回头看的卡片。在自己确信的事情上出错，是弄清自己真正相信什么的唯一便宜办法。';

  @override
  String get whereThisIsGoing => '接下来的方向';

  @override
  String ofNRight(int n) {
    return '共 $n 题，答对';
  }

  @override
  String get sayHowSureOnMore => '再多答几题并说出你的把握，应用就能告诉你这份把握值多少。';

  @override
  String confidenceOff(int gap) {
    return '你的把握与实际所知相差 $gap 分。';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return '你的把握偏差 $gap 分，上周为 $before。差距正在缩小。';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return '你的把握偏差 $gap 分，上周为 $before。差距扩大了。';
  }

  @override
  String nextRung(String name) {
    return '下一步：$name';
  }

  @override
  String youSaidPercentSure(int n) {
    return '你说有 $n% 的把握';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': '第一天',
      'reading': '阅读',
      'answering': '作答',
      'saying_how_sure': '说出把握',
      'calibrated': '已校准',
      'holding': '记住',
      'sharp': '敏锐',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': '每个人都从这里开始。',
      'reading': '习惯已经开始。',
      'answering': '翻牌之前先给出答案。',
      'saying_how_sure': '给自以为知道的东西标上数字。',
      'calibrated': '你说自己知道的，你确实知道。',
      'holding': '几周后依然记得。',
      'sharp': '该确定时确定，确定时就是对的。',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return '再读 $n 张卡片';
  }

  @override
  String stepAnswer(int n) {
    return '再作答 $n 张卡片';
  }

  @override
  String stepJudge(int n) {
    return '再给出 $n 个带把握的回答';
  }

  @override
  String stepHold(int n) {
    return '再记住 $n 张卡片';
  }

  @override
  String stepGap(int gap, int target) {
    return '你的把握偏差 $gap 分——降到 $target 即可';
  }

  @override
  String stepBeforeJudged(int n) {
    return '还需 $n 个回答，应用才能评估你的把握';
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
      'curiosity': '好奇心',
      'observation': '观察力',
      'method': '条理',
      'judgement': '判断力',
      'insight': '洞察力',
      'discernment': '明辨',
      'acumen': '慧眼',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String get levelUpTitle => '新等级';

  @override
  String levelUpGain(String skill, String n) {
    return '本周进步最大：$skill，$n';
  }

  @override
  String levelUpAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '至今已作答 $n 次',
    );
    return '$_temp0';
  }

  @override
  String get levelLabel => '等级';

  @override
  String levelPointsTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '距“$level”还差 $n 分',
    );
    return '$_temp0';
  }

  @override
  String levelAnswersTo(int n, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '距“$level”还需作答 $n 次',
    );
    return '$_temp0';
  }

  @override
  String get levelTop => '最高等级';

  @override
  String get levelShareTitle => '分享你的等级';

  @override
  String get signOutQuestion => '退出登录？';

  @override
  String get signOutBody => '连续记录、收藏的卡片和记录会保留在账号里。此操作只会从这台设备上清除它们。';

  @override
  String get deleteAccount => '删除账号';

  @override
  String get deletingAccount => '正在删除账号…';

  @override
  String get deleteAccountQuestion => '删除你的账号？';

  @override
  String deleteAccountBody(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': '订阅请在 App Store 设置中管理。',
      'google': '订阅请在 Google Play 的“付款和订阅”中管理。',
      'other': '订阅请在你购买它的商店中管理。',
    });
    return '你的账号及其备份将被永久删除，这台设备会从头开始。这不会取消 Astute+：$_temp0';
  }

  @override
  String get deleteAccountConfirm => '永久删除';

  @override
  String get accountDeleted => '你的账号已删除。';

  @override
  String get couldNotDeleteAccount => '无法删除账号。请稍后再试。';

  @override
  String get signOut => '退出登录';

  @override
  String get signedInRecordOnAccount => '已登录。你的连续记录和记录已存入账号。';

  @override
  String couldNotSignInWith(String label) {
    return '无法通过 $label 登录。';
  }

  @override
  String get signInNotAvailableBuild => '此版本不支持登录。';

  @override
  String get startOverQuestion => '重新开始？';

  @override
  String get startOverBody => '清除这台设备上的一切——连续记录、收藏的卡片、回答、判断记录、主题和方案——并重新打开引导。';

  @override
  String get wipeIt => '清除';

  @override
  String get yourRecord => '你的记录';

  @override
  String get profileTodayFive => '今天的五张';

  @override
  String profileTodayOf(int read, int of) {
    return '$read/$of';
  }

  @override
  String profileTodayToRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '待读 $n 张',
    );
    return '$_temp0';
  }

  @override
  String get profileJourneyScores => '你的全部分数，按周来看';

  @override
  String profileInARowLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '连续天数');
    return '$_temp0';
  }

  @override
  String get profileWeekTitle => '最近 7 天';

  @override
  String profileWeekPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '分');
    return '$_temp0';
  }

  @override
  String get appearance => '外观';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get yourTopics => '你的主题';

  @override
  String get edit => '编辑';

  @override
  String get howWellYouKnowYourself => '你有多了解自己';

  @override
  String get journeyButtonLine => '你的等级、你一再错过的招，以及用问题回顾的一周';

  @override
  String get isTheGapClosing => '差距在缩小吗？';

  @override
  String get movesYouKeepMissing => '你一再错过的招';

  @override
  String get dailyNudge => '每日提醒';

  @override
  String everyDayAt(String time) {
    return '每天 $time';
  }

  @override
  String get yourFivePillsBeforeCoffee => '第一杯咖啡之前，你的 5 张卡片。';

  @override
  String get browserOnlySpeaksOpen => '浏览器只有打开时才能出声，所以这需要手机版。';

  @override
  String get nudgeOff => '提醒已关闭。';

  @override
  String nudgeOnEveryDayAt(String time) {
    return '提醒已开启，每天 $time。';
  }

  @override
  String get nudgeOnSystemSaidNo => '提醒已开启，但系统拒绝了。请在设置中允许 Astute 的通知。';

  @override
  String get nudgeOnNeedsPhone => '提醒已开启。送达需要手机版。';

  @override
  String savedN(int n) {
    return '收藏 · $n';
  }

  @override
  String get yourCards => '你的卡片';

  @override
  String get emptyLikedHint => '长按你喜欢的卡片';

  @override
  String get emptySavedHint => '点一下卡片上的书签';

  @override
  String get lastSevenDays => '最近 7 天';

  @override
  String get accountSection => '账号';

  @override
  String get aboutSection => '关于';

  @override
  String get manageSubscription => '管理订阅';

  @override
  String get howPillsAreWritten => '卡片是怎么写出来的';

  @override
  String get howTitle => '这里的每张卡片都由 AI 模型撰写。';

  @override
  String get howIntro => '与其让你自己发现，不如我们先说清楚。下面是一张卡片到你手上的过程。';

  @override
  String get howStep1Title => '由模型提前写好';

  @override
  String get howStep1Line => '每张卡片都按同一要求写成：一个值得问的问题，一个讲清原因的答案，一个可以反复用的招。';

  @override
  String get howStep2Title => '注明出处，再由批评者通读';

  @override
  String get howStep2Line =>
      '每张卡片都注明事实的来源，四张中有三张一点就能打开原文，你可以自己核对。大部分卡片由扮演批评者的第二个模型审读，它无法确认的内容会进入一份由人工核查的清单。这份清单还没有清空。';

  @override
  String get howStep3Title => '每天早上发五张';

  @override
  String get howStep3Line => '来自你选的主题，都是你还没读过的卡片。答对的卡片过一阵会再出现，看看你是否记住了。';

  @override
  String get howStep4Title => '由读者守住真实';

  @override
  String get howStep4Line => '当足够多的读者认为一张卡片有误，它会停止发放，直到有人核查过。';

  @override
  String get howReportTitle => '发现错误了？';

  @override
  String get howReportLine => '点一下卡片出处旁边的小旗即可举报。';

  @override
  String get howFoot => '每一条报告我们都会读。比起为一张卡片辩护，我们更愿意把它改对。';

  @override
  String get signingIn => '登录中…';

  @override
  String get signInWithApple => '通过 Apple 登录';

  @override
  String get signInWithGoogle => '通过 Google 登录';

  @override
  String acrossNAnswersHowSure(int n) {
    return '在 $n 次回答中，你说出了自己的把握。结果如下。';
  }

  @override
  String get perfectlyCalibratedLine => '一个完美校准的人，在说“70%”时有 70% 的时候是对的。';

  @override
  String get notEnoughAnswersYet => '回答还不够多';

  @override
  String get confidenceMatchesAccuracy => '你的把握与准确率相符';

  @override
  String overconfidentBy(int points) {
    return '你高估了自己 $points 分';
  }

  @override
  String underconfidentBy(int points) {
    return '你低估了自己 $points 分';
  }

  @override
  String saidPercent(int n) {
    return '自称 $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return '答对 $pct%（$count 题中 $right 题）';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '还有 $n 个相关情境',
      one: '还有 1 个相关情境',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => '用 Astute plus 查看每一条原则';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '另有 $n 条在跟踪',
      one: '另有 1 条在跟踪',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => '分享我的记录';

  @override
  String lastCallsAgainstFirst(int n) {
    return '你最近的 $n 次判断，对比最初的 $n 次';
  }

  @override
  String closedByPoints(int n) {
    return '缩小了 $n 分';
  }

  @override
  String openedByPoints(int n) {
    return '扩大了 $n 分';
  }

  @override
  String get holdingSteady => '保持不变';

  @override
  String get measurementRunningPlus => '测量正在进行。Astute+ 会告诉你它朝哪个方向走。';

  @override
  String firstN(int n) {
    return '最初 $n 次';
  }

  @override
  String lastN(int n) {
    return '最近 $n 次';
  }

  @override
  String get trackingMoreClosely => '你的把握比以前更贴近准确率了。';

  @override
  String get distanceHasGrown => '差距变大了。下决定前值得放慢一点。';

  @override
  String get noRealMovementYet => '还没有明显变化。这需要几周，而不是几天。';

  @override
  String get seeWhichWay => '看看方向';

  @override
  String get spotOn => '正好';

  @override
  String pointsOver(int n) {
    return '高出 $n';
  }

  @override
  String pointsUnder(int n) {
    return '低了 $n';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '免费 $days 天';
  }

  @override
  String get seeThePlans => '查看方案';

  @override
  String get recordStartsToday => '你的记录从今天开始。';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '天',
      one: '天',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '张已读',
      one: '张已读',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已读 $n 张',
      one: '已读 1 张',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '达成 $n 周',
      one: '达成 1 周',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n 张将回归';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '手上有 $n 次冻结',
      one: '手上有 1 次冻结',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => '免费方案';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get comebackTitle => '很高兴再见到你。';

  @override
  String get comebackStillYours => '依然属于你';

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 天',
      one: '1 天',
    );
    return '$_temp0仍是你的最佳记录。读完今天的五张，计数就从一重新开始。';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic 仍是你收藏最多的主题';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '你答对过的 $n 张卡片今天回归',
      one: '你答对过的 1 张卡片今天回归',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => '从今天的五张重新开始';

  @override
  String moveMyReminderTo(String time) {
    return '把提醒改到 $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return '每日提醒已改到 $time。';
  }

  @override
  String get reminderAskTitle => '什么时候提醒你？';

  @override
  String get reminderAskLine => '每天一条通知，附上你卡片里的一个问题。';

  @override
  String get reminderAskTrialLine => '我们会在试用结束前两天提醒你。';

  @override
  String get reminderAskMorning => '早上';

  @override
  String get reminderAskLunch => '中午';

  @override
  String get reminderAskEvening => '晚上';

  @override
  String get reminderAskOther => '其他时间';

  @override
  String get reminderAskUsual => '你平时阅读的时间';

  @override
  String get reminderAskYes => '提醒我';

  @override
  String get reminderAskNotNow => '暂不';

  @override
  String get placeAskTitle => '关于你住的地方的卡片';

  @override
  String get placeAskLine => 'Astute 会不时给你发一张关于你住的地方的卡片 — 它的历史、科学，还有意想不到的故事。';

  @override
  String get placeOnlyCity => '只保存你所在的城市，从不保存你的精确位置。';

  @override
  String get placeAskPreviewLine => '你附近 · 摩德纳';

  @override
  String get placeAskPreviewQuestion => '吉尔兰迪纳塔是斜的。斜了多少？';

  @override
  String get placeAskYes => '使用我的位置';

  @override
  String get placeAskNotNow => '暂不';

  @override
  String get placeRowTitle => '你住的地方';

  @override
  String get placeRowOff => '已关闭';

  @override
  String get placeRowOffLine => '开启后，你会收到关于你住的地方的卡片。';

  @override
  String get placeSwitchOn => '开启';

  @override
  String get placeUseNow => '现在使用我的位置';

  @override
  String get placeRemove => '移除';

  @override
  String placeSetTo(String place) {
    return '你住的地方：$place';
  }

  @override
  String get placeRemoved => '已移除。Astute 不再保存你住的地方。';

  @override
  String get placeNotFound => '暂时无法确定你在哪里。Astute 会改天再试。';

  @override
  String get placeDeniedNote => '没关系。你随时可以在“我的”里开启。';

  @override
  String get placeServicesOff => '这台手机的定位服务已关闭。请在设置中开启后再试。';

  @override
  String get placeNotHere => '这台设备无法确定你的位置。';

  @override
  String get placeSettingsTitle => 'Astute 的定位权限已关闭';

  @override
  String get placeSettingsBody =>
      '要收到关于你住的地方的卡片，请在设置中允许 Astute 使用你的位置。只会保存你所在的城市。';

  @override
  String get placeSettingsOpen => '打开设置';

  @override
  String trialWarningTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '你的 Astute+ 试用将在 $days 天后结束。',
      one: '你的 Astute+ 试用明天结束。',
      zero: '你的 Astute+ 试用今天结束。',
    );
    return '$_temp0';
  }

  @override
  String trialWarningBody(String date, String price, String path) {
    return '$date起，你的年度订阅开始，价格为 $price。想继续，无需任何操作。想取消：$path。';
  }

  @override
  String trialEndsNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '试用 $days 天后结束',
      one: '试用明天结束',
      zero: '试用今天结束',
    );
    return '$_temp0';
  }

  @override
  String get trialNoticeManage => '管理';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$total 个主题中有 $n 个在组合里';
  }

  @override
  String get everythingIsInDrag => '全部都在。把主题向左滑会少看到它，滑到底则移除。';

  @override
  String get next => '下一步';

  @override
  String get whatShouldWeTalkAbout => '我们聊什么？';

  @override
  String get fivePillsADayPick => '每天五张卡片，每天早上换新。选出你想放进组合的主题——以后可以更改。';

  @override
  String startWithNTopics(int n) {
    return '从 $n 个主题开始';
  }

  @override
  String saveNTopics(int n) {
    return '保存 $n 个主题';
  }

  @override
  String pickAtLeastN(int n) {
    return '至少选 $n 个';
  }

  @override
  String get swipeToSeeMore => '滑动查看更多';

  @override
  String get tagline => '弄懂事物背后的“为什么”，也看清自己知道的能信几分';

  @override
  String get introTopicsTitle => '二十个主题，五张卡片';

  @override
  String get introTopicsLine => '由模型提前写好，每一张都注明出处。';

  @override
  String get introQuestionTitle => '一道题，有多确定，再看为什么';

  @override
  String get introQuestionLine => '先说你有几分把握。久而久之，你会知道自己的“确定”值多少。';

  @override
  String get introMixTitle => '组合由你决定';

  @override
  String get introMixLine => '调低一个主题就少看到它，关掉就不再出现。';

  @override
  String get introThirtyTitle => '每天两分钟';

  @override
  String get introThirtyLine => '一条通知，五张卡片，和一段你不想中断的连续记录。';

  @override
  String introNotifyWhen(String time) {
    return '明天 $time';
  }

  @override
  String get introNotifyLine => '今天的五张已就绪。第 1 天。';

  @override
  String get introOneOfFive => '1 / 5';

  @override
  String get introDayOne => '第 1 天';

  @override
  String get introTapTomorrow => '明天点按揭晓';

  @override
  String get introDayOneTomorrow => '第 1 天 · 明天';

  @override
  String get introDaySevenStreak => '第 7 天 · 第一段连续记录';

  @override
  String get continueWithApple => '使用 Apple 继续';

  @override
  String get continueWithGoogle => '使用 Google 继续';

  @override
  String get startReading => '开始阅读';

  @override
  String get haveAnAccount => '已有账号？';

  @override
  String get signInLink => '登录';

  @override
  String get signInWelcomeTitle => '欢迎回来';

  @override
  String get signInWelcomeLine => '登录后，你的连续记录、收藏的卡片和记录都会回来。';

  @override
  String get keepStreakOnNewPhone => '换了手机，连续记录也不丢';

  @override
  String get keepStreakTitle => '守住你的连续记录';

  @override
  String get keepStreakLine => '登录后，换了新手机也能接着这里继续：你的连续记录、收藏的卡片和记录都在。';

  @override
  String get signInNotNow => '暂不';

  @override
  String subjectName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'thinking': '思维',
      'science': '科学',
      'maths': '数学',
      'space': '太空',
      'psychology': '心理学',
      'economics': '经济',
      'technology': '科技',
      'history': '历史',
      'human_body': '人体',
      'philosophy': '哲学',
      'pop_culture': '流行文化',
      'nature': '自然',
      'language': '语言',
      'weird_facts': '奇闻',
      'sport': '体育',
      'cinema': '电影',
      'music': '音乐',
      'art': '艺术',
      'medicine': '医学',
      'food': '美食',
      'life': '生活',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get cardsInEnglishNote => '卡片目前只有英文；应用界面使用你的语言。';

  @override
  String termsLine(String terms, String privacy) {
    return '继续即表示你同意我们的$terms和$privacy';
  }

  @override
  String get termsLineTerms => '使用条款';

  @override
  String get termsLinePrivacy => '隐私政策';

  @override
  String get skip => '跳过';

  @override
  String get tapToRevealLower => '点按揭晓';

  @override
  String get barMoveCaps => '值得记住';

  @override
  String get widgetFootPlain => '五张卡片，两分钟。';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '连续 $n 天',
      one: '连续 1 天',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => '今天已完成';

  @override
  String get widgetStreakStart => '读完今天的五张，开始连续记录。';

  @override
  String get widgetFiveTitle => '今天的五张';

  @override
  String widgetFiveRead(int n) {
    return '已读 $n/5';
  }

  @override
  String get widgetFiveDone => '五张全部读完';

  @override
  String get widgetFiveWaiting => '新的五张在等你';

  @override
  String get widgetShelfTitle => '今日书架';

  @override
  String get widgetShelfFrom => '来自今日书架';

  @override
  String get dayStreakCaps => '天连续';

  @override
  String sourceLabel(String source) {
    return '来源 · $source';
  }

  @override
  String sourceLabelKind(String kind, String source) {
    return '$kind · $source';
  }

  @override
  String deeperFootLabel(String source) {
    return '深入了解。来源：$source';
  }

  @override
  String get sourceKindPaper => '研究';

  @override
  String get sourceKindBook => '书籍';

  @override
  String get sourceKindInstitution => '机构';

  @override
  String get sourceKindDocument => '原始文件';

  @override
  String get sourceKindData => '数据';

  @override
  String get sourceKindReference => '工具书';

  @override
  String get sourceKindNews => '报纸';

  @override
  String get sourceKindCompany => '企业资料';

  @override
  String get sourceKindStandard => '标准';

  @override
  String get sourceKindArithmetic => '计算';

  @override
  String get plusIsActive => 'ASTUTE+ 已激活';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '免费试用 $days 天，之后 $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return '以 $price$suffix 订阅';
  }

  @override
  String get paywallRecordTitle => '看看你真正知道多少。';

  @override
  String get paywallRecordMark => '真正';

  @override
  String get paywallRecordLine =>
      '每天你都会说出自己有多确定。Astute+ 会告诉你，确定与答对之间的差距是否在缩小，以及你一再错过的招。';

  @override
  String paywallRecordOver(int sure, int right) {
    return '你说有 $sure% 的把握，实际答对 $right%。Astute+ 会告诉你这个差距是否在缩小，以及你一再错过的招。';
  }

  @override
  String paywallRecordUnder(int sure, int right) {
    return '你说有 $sure% 的把握，实际答对 $right%：你知道的比你以为的多。Astute+ 会告诉你这个差距是否在缩小。';
  }

  @override
  String paywallRecordEven(int sure, int right) {
    return '你说有 $sure% 的把握，实际答对 $right%：几乎一致。Astute+ 会告诉你能否保持，以及你一再错过的招。';
  }

  @override
  String get paywallOutcomeTitle => '做那个谁都骗不了的人。';

  @override
  String get paywallOutcomeMark => '骗不了';

  @override
  String get paywallOutcomeLine => '每天五张，匹配你的水平。答错的会一再回来，直到你记住。你还会看到自己一周一周地变化。';

  @override
  String get paywallFiveTitle => '五张，全是你的。';

  @override
  String get paywallFiveMark => '你的。';

  @override
  String get paywallFiveLine =>
      '免费版的五张里有两张为你挑选，连续一周后的第二天是三张。Astute+ 从你的分支、按你的水平挑选全部五张，还会把答错的带回来。';

  @override
  String get paywallReadTitle => '你读过的，按天回看。';

  @override
  String get paywallReadMark => '按天回看。';

  @override
  String get paywallReadLine => '你最近读过的日子，最新的在前。点按某一天打开那天的五张卡片，点按卡片即可重读。';

  @override
  String get perkGapTitle => '看着差距缩小';

  @override
  String get perkGapLine => '你的旅程，一周一周：有多确定，对了多少，以及你一再错过的招。';

  @override
  String get perkOwnFiveTitle => '五张属于你的卡片';

  @override
  String get perkOwnFiveLine => '每天按你的水平挑选，答错的会回来。';

  @override
  String get perkReadTitle => '你读过的';

  @override
  String get perkReadLine => '你最近的每一天，各带五张卡片，可随时重新打开。';

  @override
  String get perkAskTitle => '你的助手';

  @override
  String get perkAskLine => '讲解每张卡片，再考考你。';

  @override
  String get perkCoachTitle => '每周教练';

  @override
  String get perkCoachLine => '你在哪里出错，接下来练什么。';

  @override
  String get perkNew => '新';

  @override
  String get threeTitle => '今日三题';

  @override
  String threeStep(int n, int total) {
    return '$n / $total';
  }

  @override
  String get threeSame => '今天大家都是同样三题，约一分钟。';

  @override
  String threeYouSaid(String guess) {
    return '你猜的是 $guess。';
  }

  @override
  String threePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n 分',
      zero: '没有得分',
    );
    return '$_temp0';
  }

  @override
  String get threeNext => '下一题';

  @override
  String get threeSeeScore => '查看得分';

  @override
  String get threeDone => '今日三题 · 完成';

  @override
  String get threeYou => '你';

  @override
  String whyMissing(String move) {
    return '你常错过的思路：$move';
  }

  @override
  String whyMoveAgain(String move) {
    return '$move，换个新情境再来';
  }

  @override
  String get whyAgain => '再看一次';

  @override
  String whyGoal(String goal) {
    return '为了你的目标：$goal';
  }

  @override
  String whyLiked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '和你喜欢的 $n 张卡片相似',
    );
    return '$_temp0';
  }

  @override
  String whyHard(String subject) {
    return '难一点的：你在$subject上很强';
  }

  @override
  String whyLevel(String subject) {
    return '符合你在$subject的水平';
  }

  @override
  String whyGentle(String subject) {
    return '轻松进入$subject';
  }

  @override
  String whyYourSubject(String subject) {
    return '来自你的科目：$subject';
  }

  @override
  String get whyRandom => '从你的科目中随机抽取';

  @override
  String get whyTitle => '为什么是这张卡片';

  @override
  String whyTrains(String move) {
    return '训练的思路：$move';
  }

  @override
  String whyMet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '你遇到过 $n 次。',
    );
    return '$_temp0';
  }

  @override
  String whyRight(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '答对 $n 次。',
      zero: '还没答对过。',
    );
    return '$_temp0';
  }

  @override
  String whyLevelRow(String subject) {
    return '你在$subject的水平';
  }

  @override
  String whyLevelWord(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'starting': '刚起步',
      'some': '在进步',
      'strong': '很强',
      'other': '在进步',
    });
    return '$_temp0';
  }

  @override
  String get whyLastMetRow => '上次遇到这个思路';

  @override
  String whyDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 天前',
      one: '昨天',
      zero: '今天',
    );
    return '$_temp0';
  }

  @override
  String get whyGoalRow => '你的目标';

  @override
  String get whyLikedRow => '你喜欢的相似卡片';

  @override
  String get whyRandomLine => '免费版中，每天有一部分卡片从你选的科目里随机抽取。';

  @override
  String get whyPlusLine => '有了 Astute+，五张都为你挑选：符合你的水平，贴合你的喜好，你常错过的思路会再出现。';

  @override
  String get whyMakeMine => '五张都为我挑选';

  @override
  String get whyMore => '多来点这样的';

  @override
  String get whyMoreDone => '已记下：多来点这样的';

  @override
  String get whyLess => '少一点';

  @override
  String get whyTune => '调整你的组合';

  @override
  String get searchTry => '试试';

  @override
  String get searchByNeed => '按需求';

  @override
  String get searchByKind => '按类型';

  @override
  String kindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'play': '可互动',
      'quiz': '选择题',
      'estimate': '估算题',
      'debate': '辩论',
      'quick': '快速阅读',
      'other': '卡片',
    });
    return '$_temp0';
  }

  @override
  String kindCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张卡片',
    );
    return '$_temp0';
  }

  @override
  String get areaUsefulFor => '用得上';

  @override
  String areaPaths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 条路线 · 每条十张卡片',
    );
    return '$_temp0';
  }

  @override
  String get areaMoves => '在这里训练的思路';

  @override
  String get areaMoreCards => '更多相关卡片';

  @override
  String get pathKicker => '路线';

  @override
  String pathMeta(String subject, int n, int minutes) {
    return '$subject · $n 张卡片 · 约 $minutes 分钟';
  }

  @override
  String pathPartOf(int part, int parts) {
    return '第 $part 部分，共 $parts 部分';
  }

  @override
  String pathTrains(String moves) {
    return '训练：$moves';
  }

  @override
  String pathReadOf(int n, int total) {
    return '已读 $n/$total';
  }

  @override
  String get pathFreeTag => '免费';

  @override
  String get pathStart => '开始这条路线';

  @override
  String pathContinueAt(int n) {
    return '继续 · 第 $n 张';
  }

  @override
  String get pathContinue => '继续';

  @override
  String get notesTitle => '笔记';

  @override
  String get noteYours => '你的笔记';

  @override
  String get noteAdd => '添加笔记';

  @override
  String get noteEdit => '编辑';

  @override
  String get noteSave => '保存';

  @override
  String get noteDelete => '删除笔记';

  @override
  String get noteHint => '这张卡片里你想记住什么？';

  @override
  String get notesEmpty => '还没有笔记。打开一张你收藏的卡片，写下你想记住的内容。';

  @override
  String get pathUnlock => '解锁所有路线';

  @override
  String get pathFreeLine => '每条路线的前两张卡片免费。';

  @override
  String pathNextPart(int n) {
    return '第 $n 部分：更深入';
  }

  @override
  String pathDeeperLine(int n) {
    return '同一主题再多 $n 张卡片，更难。';
  }

  @override
  String get pathAgain => '再读一遍';

  @override
  String get subjectKicker => '科目';

  @override
  String subjectReadOf(int n, int total) {
    return '已读 $n/$total 张卡片';
  }

  @override
  String subjectRight(int right, int answered) {
    return '答对 $right/$answered';
  }

  @override
  String subjectToNext(int n, int level) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再答对 $n 题升到 $level 级',
    );
    return '$_temp0';
  }

  @override
  String get subjectLevel => '级别';

  @override
  String get subjectNext => '下一张给你';

  @override
  String get subjectNextLine => '比你现在的水平高一级。';

  @override
  String subjectInside(String subject) {
    return '$subject 里面';
  }

  @override
  String get journeySubjectsTap => '点一个科目，打开它的页面。';

  @override
  String moveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': '基础比率',
      'survivorship': '幸存者偏差',
      'regression': '回归均值',
      'confirmation': '确认偏误',
      'anchoring': '锚定',
      'sampling': '抽样',
      'confounding': '混杂因素',
      'counterfactual': '和什么比',
      'multipleComparisons': '多重比较',
      'availability': '可得性',
      'sunkCost': '沉没成本',
      'conjunction': '合取谬误',
      'conditional': '条件概率',
      'independence': '独立性',
      'coincidence': '巧合',
      'exponential': '指数增长',
      'reflection': '第一反应',
      'simpson': '汇总陷阱',
      'estimation': '估算',
      'computation': '算一算',
      'other': '思考',
    });
    return '$_temp0';
  }

  @override
  String moveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': '检测有多准，不等于你有多大可能中招',
      'survivorship': '你手上的数据，是幸存下来的数据',
      'regression': '极端值会自己回落',
      'confirmation': '寻找“是”不等于检验',
      'anchoring': '最先说出的数字会牵动之后所有数字',
      'sampling': '谁进了样本，决定了样本能说明什么',
      'confounding': '也许是别的东西同时导致了两者',
      'counterfactual': '没有对照，变化说明不了什么',
      'multipleComparisons': '试得够多，总有一个能过',
      'availability': '容易想象不等于常见',
      'sunkCost': '花掉的就花掉了，只有剩下的才能决定',
      'conjunction': '细节让故事更可信，却更不可能',
      'conditional': '你得知的信息会改变概率',
      'independence': '随机没有记忆',
      'coincidence': '尝试足够多时，罕见的事也很常见',
      'exponential': '没人对翻倍有直觉',
      'reflection': '最先冒出的答案正是要检查的答案',
      'simpson': '整体可以偏向任何部分都不偏的方向',
      'estimation': '把无法回答的问题拆成能估计的部分',
      'computation': '一个你真能解完的问题',
      'other': '思考',
    });
    return '$_temp0';
  }

  @override
  String get threeSend => '发送';

  @override
  String get threeWhy => '看看为什么';

  @override
  String threeYesterday(int score) {
    return '昨天的三题：$score / 300。';
  }

  @override
  String get fiveTitle => '今日五题';

  @override
  String get fiveSame => '今天大家都是同样五题，约两分钟。';

  @override
  String get fiveDone => '今日五题 · 完成';

  @override
  String dailyOf(int max) {
    return '/ $max';
  }

  @override
  String dailyPickRight(String answer) {
    return '正确答案：$answer';
  }

  @override
  String dailyPickWrong(String answer) {
    return '差一点。正确答案：$answer';
  }

  @override
  String dailyYourPick(String answer) {
    return '你的答案：$answer';
  }

  @override
  String dailyBetter(int pct, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '比今天 $n 位玩家中的 $pct% 更好。',
    );
    return '$_temp0';
  }

  @override
  String dailyPlayers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天目前有 $n 位玩家。',
    );
    return '$_temp0';
  }

  @override
  String dailyFirst(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '你是今天最早的 $n 位玩家之一：人数还太少，无法比较。',
      one: '你是今天第一个玩的：人数还太少，无法比较。',
    );
    return '$_temp0';
  }

  @override
  String get dailyCounting => '正在统计今天的玩家…';

  @override
  String dailyAverage(int right, int total, String avg) {
    return '$total 题中你答对了 $right 题。这几题读者平均答对 $avg 题。';
  }

  @override
  String get dailyUncounted => '现在无法统计今天的玩家。';

  @override
  String get dailyEach => '逐题来看';

  @override
  String dailyItemRight(int pct) {
    return '今天 $pct% 的玩家答对了';
  }

  @override
  String dailyItemGuess(String guess) {
    return '今天的平均估计：$guess';
  }

  @override
  String get dailyItemFew => '回答还太少，无法比较';

  @override
  String fiveYesterday(int score) {
    return '昨天的五题：$score / 500。';
  }

  @override
  String fiveShareHead(String date) {
    return 'Astute · 今日五题 · $date';
  }

  @override
  String fiveChallengeLine(int right) {
    return 'Astute 今日五题，我答对了 $right 道。你能超过我吗？';
  }

  @override
  String get fiveChallengeAll => 'Astute 今日五题，我全部答对。你也能做到吗？';

  @override
  String get fiveChallengeInvite => 'Astute 今日五题：每个人都是同样的五道题。你能答对几道？';

  @override
  String threeShareHeadIn(String subject, String date) {
    return 'Astute · 今日三题 · $subject · $date';
  }

  @override
  String dailyShareScore(int score, int max, int day) {
    return '$score / $max · 第 $day 天';
  }

  @override
  String dailyShareScoreAlone(int score, int max) {
    return '$score / $max';
  }

  @override
  String get skillsTitle => '想学什么';

  @override
  String get skillsTitleMark => '学';

  @override
  String get skillsLine => '每次回答都会改变你的分数。训练你所选能力的卡片会带有它的标记。';

  @override
  String get skillsDone => '完成';

  @override
  String get skillsFocus => '专注中';

  @override
  String get skillMarkKicker => '这张卡片训练';

  @override
  String skillMarkLabel(String skill) {
    return '训练$skill';
  }

  @override
  String get skillMarkBody => '这是你重点关注的能力之一。每回答一张这样的卡片，你在这项能力上的分数就会变化。';

  @override
  String get skillMarkOpen => '查看你的全部分数';

  @override
  String get trainingTitle => '你的训练';

  @override
  String get trainingLine => '每次回答都会改变你的分数，答对难题加得最多。分数没有上限。';

  @override
  String get trainingOthers => '其他';

  @override
  String get trainingEmpty => '选择你想提升的方面。每回答一张训练它的卡片，你的分数就会变化，卡片上也会带有它的标记。';

  @override
  String get trainingPick => '选择能力';

  @override
  String trainingMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '还有 $n 项',
      one: '还有 1 项',
    );
    return '$_temp0';
  }

  @override
  String get aimTitle => '你想在哪些方面看得更清楚？';

  @override
  String get aimLine => '选一个。每天都有为它准备的卡片，随时可以更改。';

  @override
  String aimWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '本周这方面的卡片：$n 张',
      zero: '本周还没有这方面的卡片',
    );
    return '$_temp0';
  }

  @override
  String answersRightOf(int right, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      right,
      locale: localeName,
      other: '$n 题答对 $right 题',
    );
    return '$_temp0';
  }

  @override
  String get aimOpen => '这个目标的全部内容';

  @override
  String get aimPlus => '有了 Astute+：这方面的全部路径完整开放，还有一位陪你练习的教练。';

  @override
  String get aimNone => '选出你想看得更清楚的方面：每天都有为它准备的卡片。';

  @override
  String get aimPick => '选择目标';

  @override
  String get strengthsTitle => '你的强项';

  @override
  String get strengthsLine => '不是你选的，而是从你的回答中看出：你在哪里答对最多，在哪里出错。';

  @override
  String strengthsFew(String skills) {
    return '回答还太少：$skills';
  }

  @override
  String strengthsPractice(String skill) {
    return '练习：$skill';
  }

  @override
  String get strengthsBest => '你最强的一项';

  @override
  String get strengthsWeak => '你最常出错的地方';

  @override
  String get strengthsLocked => '你最常出错的地方和其余内容，需要 Astute+。';

  @override
  String get strengthsEmpty => '再多答几题，这里就会显示你的强项。';

  @override
  String get scoreTitle => 'Astute 分数';

  @override
  String scoreWeek(String n) {
    return '本周 $n';
  }

  @override
  String get scoreStart => '从你的第一次回答开始。';

  @override
  String scoreMoveLabel(String name, String n) {
    return '$name：这次回答 $n';
  }

  @override
  String scoreAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '基于 $n 次回答',
      one: '基于 1 次回答',
    );
    return '$_temp0';
  }

  @override
  String get videoKicker => '视频';

  @override
  String get videoPlay => '播放';

  @override
  String get videoPause => '暂停';

  @override
  String get videoWatchAgain => '再看一遍';

  @override
  String get videoOffline => '视频需要联网。点一下重试。';

  @override
  String get skillsRowTitle => '想学的内容';

  @override
  String skillName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'critical': '批判性思维',
      'decisions': '更好地决策',
      'money': '金钱与储蓄',
      'numbers': '数字与统计',
      'talk': '沟通',
      'persuade': '说服',
      'people': '理解他人',
      'fakes': '识破假消息',
      'science': '像科学家一样思考',
      'focus': '专注力',
      'lead': '领导力',
      'culture': '通识',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String get perkFiveShort => '每天，按你的水平。';

  @override
  String get perkShelvesTitle => '每条路径，每本书';

  @override
  String get perkShelvesLine => '完整开放，每周上新。';

  @override
  String get perkGapShort => '有多确定，对了多少，每周对比。';

  @override
  String get perkReadShort => '读过的每一天，随时重温。';

  @override
  String get trialToday => '今天 · 免费使用全部 Astute+';

  @override
  String trialReminder(int day) {
    return '第 $day 天 · 我们会提醒你';
  }

  @override
  String trialCharge(int day, String price, String plan) {
    String _temp0 = intl.Intl.selectLogic(plan, {'year': '每年', 'other': '每月'});
    return '第 $day 天 · $_temp0 $price，取消前自动续订';
  }

  @override
  String chargedTodayRenews(String price, String suffix) {
    return '今天扣款 $price$suffix，取消前自动续订';
  }

  @override
  String cancelHow(String where) {
    return '可随时在“$where”中取消，请在续订前至少 24 小时操作。';
  }

  @override
  String get cancelWhereIos => '设置 › 你的姓名 › 订阅';

  @override
  String get cancelWhereAndroid => 'Google Play › 付款和订阅 › 订阅';

  @override
  String storeAsking(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': '正在向 App Store 获取价格…',
      'other': '正在向 Google Play 获取价格…',
    });
    return '$_temp0';
  }

  @override
  String storeUnreachable(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': '无法连接 App Store',
      'other': '无法连接 Google Play',
    });
    return '$_temp0';
  }

  @override
  String get storeUnreachableLine => '价格和免费试用都来自应用商店。请检查网络连接后重试。';

  @override
  String get tryAgain => '重试';

  @override
  String get purchasePending => '等待批准。付款完成后，Astute+ 会立即开通。';

  @override
  String get oneMoment => '请稍候…';

  @override
  String get purchaseConfirming => '正在确认付款…';

  @override
  String get purchaseConfirmingSlow => '比平时久一些。付款是安全的：Astute+ 会自动开通。';

  @override
  String get closeLabel => '关闭';

  @override
  String get thatDidNotGoThrough => '没有成功。';

  @override
  String get plusIsBack => 'Astute+ 回来了。';

  @override
  String get nothingToRestore => '此账号没有可恢复的内容。';

  @override
  String get planYearly => '年付';

  @override
  String get planMonthly => '月付';

  @override
  String get perYearShort => '/年';

  @override
  String get perMonthShort => '/月';

  @override
  String get perYear => '每年';

  @override
  String aMonth(String price) {
    return '每月 $price';
  }

  @override
  String savePercent(int n) {
    return '省 $n%';
  }

  @override
  String get perMonth => '每月';

  @override
  String get billedMonthly => '按月计费';

  @override
  String get cancelTheTrial => '取消试用';

  @override
  String get cancelAnyTime => '随时可取消';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String planPrice(String label, String price, String per) {
    return '$label，$price $per';
  }

  @override
  String get pickASideNoRightAnswer => '选一边。没有标准答案。';

  @override
  String get estimateCloseEnough => '估一下。接近就算对。';

  @override
  String get tapToReveal => '点按揭晓';

  @override
  String get verdictRight => '答对了。';

  @override
  String get verdictClose => '足够接近。';

  @override
  String get verdictWrong => '差一点。';

  @override
  String verdictSure(int pct) {
    return '你当时有 $pct% 的把握。';
  }

  @override
  String verdictYouSaid(String given) {
    return '你的答案：$given';
  }

  @override
  String verdictYouSaidSure(String given, int pct) {
    return '你的答案：$given（$pct% 的把握）';
  }

  @override
  String verdictRightIs(String answer) {
    return '正确答案：$answer';
  }

  @override
  String verdictRightWithin(String answer, String low, String high) {
    return '正确答案：$answer（$low 到 $high 之间都算对）';
  }

  @override
  String get giveMeANudge => '给点提示';

  @override
  String get beingRightMattersLess => '答对不如知道自己多常答对来得重要。';

  @override
  String get writeItBeforeTheirs => '先写下来，再看他们的。';

  @override
  String get youAnsweredThisOne => '这题你已经答过了。';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': '简单',
      'medium': '中等',
      'hard': '困难',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · 翻面之前先给出答案。';
  }

  @override
  String get yourAnswer => '你的答案';

  @override
  String get checkMyAnswer => '核对答案';

  @override
  String get howSureAreYou => '你有多确定？';

  @override
  String percentSure(int n) {
    return '$n% 的把握';
  }

  @override
  String get inOneLineWhy => '用一句话——为什么？';

  @override
  String get because => '因为…';

  @override
  String get nowShowMeTheOtherSide => '现在看看另一面';

  @override
  String get skipShowMeAnyway => '跳过——直接看';

  @override
  String get youTookCaps => '你的选择';

  @override
  String get putSimplyCaps => '简单说';

  @override
  String get explainLikeImThree => '像讲给孩子听一样';

  @override
  String get whatTheOtherSideSaysCaps => '另一方怎么说';

  @override
  String get whatTheOtherSideSays => '另一方怎么说';

  @override
  String theTrap(String trap) {
    return '陷阱：$trap';
  }

  @override
  String youTookTheSide(String side) {
    return '你选的一边：$side';
  }

  @override
  String atPercentSure(int n) {
    return '（$n% 的把握）';
  }

  @override
  String youGotThisOne(String sure) {
    return '这题你答对了$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return '你说 $answer$sure';
  }

  @override
  String get swipeForTheNextOne => '滑动看下一张';

  @override
  String get musicSound => '音乐卡片的声音';

  @override
  String get musicSoundIsOff => '音乐卡片的声音已关闭。';

  @override
  String get musicSoundTurnOn => '打开';

  @override
  String get thatWasTheOnlyOne => '只有这一张';

  @override
  String get lastOne => '最后一张';

  @override
  String deckEndTitle(String word) {
    return '$word张，就这些了。';
  }

  @override
  String get deckEndAgain => '从第一张重新开始';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => '无法绘制卡片。';

  @override
  String get textCopiedInstead => '改为复制了文字。';

  @override
  String get copiedToClipboard => '已复制到剪贴板。';

  @override
  String get rendering => '绘制中…';

  @override
  String get theSourceGoesWithIt => '来源一并附上';

  @override
  String get shareMyDay => '分享';

  @override
  String climbedTo(String rung) {
    return '今天你升到了$rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$asked题答对$right题';
  }

  @override
  String saidSure(int sure) {
    return '自信度$sure%';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '几天前答过的$n张卡片回来了，看看你还记不记得',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => '还记得吗？';

  @override
  String get holdACardYouLike => '喜欢就长按';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天喜欢了$n张',
    );
    return '$_temp0';
  }

  @override
  String get liked => '喜欢';

  @override
  String likedN(int n) {
    return '喜欢 · $n';
  }

  @override
  String get nothingLikedYet => '还没有喜欢的卡片';

  @override
  String get likeThisPill => '喜欢这张卡片';

  @override
  String get removeFromLiked => '取消喜欢';

  @override
  String get removedFromLiked => '已取消喜欢。';

  @override
  String get lessLikeThis => '少一些这样的';

  @override
  String get whatYouLikedLandsHere => '你会再读一遍的卡片';

  @override
  String get holdToLikeLandsHere => '长按你喜欢的卡片，它就会出现在这里 — 应用也会给你更多类似的。';

  @override
  String get tapTheBookmarkLandsHere => '点一下卡片上的书签，它就会出现在这里 — 那些改变了你想法的卡片，留下来。';

  @override
  String get nudgeTitle => '今天的五张已就绪';

  @override
  String get nudgeBookTitle => '本周免费书';

  @override
  String nudgeBookBody(String title, String author, int minutes) {
    return '$author《$title》的核心观点，$minutes分钟读完。';
  }

  @override
  String get nudgeFreezeTitle => '你的冻结还在生效';

  @override
  String nudgeFreezeBody(String question) {
    return '昨天已被覆盖。今天：$question';
  }

  @override
  String get nudgeSureTitle => '这一题你当时很确定';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — 你说了$sure%。';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return '两周前你已读了$read张卡片';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return '你的自信偏差了$gap分。今天：$question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '到目前为止答了$answered题。今天：$question';
  }

  @override
  String get yourJourney => '你的旅程';

  @override
  String journeySince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '自上次访问（$days 天前）以来',
      one: '自上次访问（昨天）以来',
      zero: '自上次访问（今天）以来',
    );
    return '$_temp0';
  }

  @override
  String journeySinceMark(String n) {
    return '自上次访问以来 $n';
  }

  @override
  String get thePath => '路径';

  @override
  String get youAreHere => '你在这里';

  @override
  String reachedOn(String date) {
    return '$date到达';
  }

  @override
  String readSoFar(int n, int of) {
    return '目前已读$of张中的$n张';
  }

  @override
  String nRead(int n) {
    return '已读$n张';
  }

  @override
  String get topLevel => '最高等级';

  @override
  String plusNToday(int n) {
    return '今天 +$n';
  }

  @override
  String get bySubject => '按学科';

  @override
  String get pts => '分';

  @override
  String nStillWithYou(int n) {
    return '$n张仍记得';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n个套路',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => '你的分数从今天的五张开始。';

  @override
  String get anonymousUsage => '使用数据';

  @override
  String get anonymousUsageLine =>
      '应用的使用情况——哪些卡被读过、留下和说出口，以及哪里出了问题——好让接下来的卡更好。绝不包括你的姓名、邮箱或你写下的任何内容。';

  @override
  String get usageOn => '已共享，不含你的名字和你写的话。';

  @override
  String get usageOff => '不再测量任何内容。';

  @override
  String get consentTitle => '帮我们把 Astute 做得更好？';

  @override
  String get consentLine => '分享你使用应用的方式——绝不包括你的名字、邮箱或你写的内容。';

  @override
  String get consentNo => '不用了，谢谢';

  @override
  String get consentYes => '好，分享';

  @override
  String consentChangeLater(String profile, String setting) {
    return '你可以随时在“$profile”的“$setting”中更改。';
  }

  @override
  String get yourMix => '你的组合';

  @override
  String get genresTitle => '哪些部分？';

  @override
  String get genresLine => '点一下跳过某个类别。长按，里面更小的主题就在下面展开。';

  @override
  String get insideGenre => '里面有';

  @override
  String nOfSixOn(int n, int total) {
    return '$total 个中开启 $n 个';
  }

  @override
  String get offInYourMix => '不在你的组合里';

  @override
  String continueGenresOn(int on, int total) {
    return '继续 · $total 个类别中开启 $on 个';
  }

  @override
  String get mixRarely => '很少';

  @override
  String get mixSometimes => '有时';

  @override
  String get mixOften => '经常';

  @override
  String get mixALot => '很多';

  @override
  String get mixFull => '拉满';

  @override
  String get forYouChip => '为你而选';

  @override
  String get againChip => '再来一次';

  @override
  String get magicLine => '每天五张为你挑选的卡片：来自你的组合，匹配你的水平，答错的会再回来。明天开始。';

  @override
  String get plusCardHeadline => '让五张全都为你。';

  @override
  String get plusCardLine => '每天五张来自你的组合、匹配你的水平。你的旅程。你的全部档案。';

  @override
  String get archiveBeforeThisWeek => '本周之前的一切';

  @override
  String get weekKeptThreeOwn => '连续七天：明天五张里有三张是你的。';

  @override
  String get weekKeptSundayFourOwn => '连续七天，明天又是星期日：五张里有四张是你的。';

  @override
  String get topOfTheWeek => '本周热门';

  @override
  String get topOfTheMonth => '本月热门';

  @override
  String topIn(String subject) {
    return '$subject热门';
  }

  @override
  String get topLineWeek => '过去 7 天里被喜欢、收藏和讲述最多的卡片';

  @override
  String get topLineMonth => '过去 30 天里被喜欢、收藏和讲述最多的卡片';

  @override
  String get topWeek => '周';

  @override
  String get topMonth => '月';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 位读者',
    );
    return '$_temp0';
  }

  @override
  String get topPicksTitle => '值得一看';

  @override
  String get topPicksLine => '读者榜单形成之前，由 Astute 挑选';

  @override
  String get readMark => '已读';

  @override
  String get lovedSinceTheStart => '自开始以来最受喜爱';

  @override
  String lovedIn(String subject) {
    return '$subject中最受喜爱';
  }

  @override
  String get lovedLine => '读者保留最多、而你还没读过的卡片';

  @override
  String get forYouShelf => '为你推荐';

  @override
  String get forYouLine => '你的阅读最先带来的内容';

  @override
  String get exploreOffline => '你已离线。这是上次读取的\"探索\"页面。';

  @override
  String get askYourselfCaps => '问问自己';

  @override
  String get themeMyths => '破除迷思';

  @override
  String get themeMythsLine => '几乎人人都信的事，以及它错在哪里';

  @override
  String get themeParadoxes => '悖论';

  @override
  String get themeParadoxesLine => '不该同时为真的两件真事';

  @override
  String get themeNumbers => '令人惊讶的数字';

  @override
  String get themeNumbersLine => '数字本身就是反转';

  @override
  String get themePractical => '今天就能用';

  @override
  String get themePracticalLine => '今晚之前可以试试，或者聊天时说起的事';

  @override
  String get themeOrigins => '它从哪里来';

  @override
  String get themeOriginsLine => '你每天用的东西的起源';

  @override
  String get themeStories => '真实故事';

  @override
  String get themeStoriesLine => '真正发生过的事';

  @override
  String get storyHint => '轻点继续 · 按住暂停';

  @override
  String get storyTapOn => '轻点继续';

  @override
  String get storyPrevious => '上一个';

  @override
  String get storyClose => '关闭故事';

  @override
  String get storySave => '收藏';

  @override
  String get storySaved => '已收藏';

  @override
  String get storyShare => '分享';

  @override
  String get storyOpenCard => '打开卡片';

  @override
  String get themeDebates => '选一边';

  @override
  String get themeDebatesLine => '没有标准答案，只有更好的论证';

  @override
  String get themeWorkItOut => '算一算';

  @override
  String get themeWorkItOutLine => '在卡片揭晓之前，猜猜这个数字';

  @override
  String get themeSeen => '一看就懂';

  @override
  String get themeSeenLine => '把要点画出来的卡片';

  @override
  String get themeSharpest => '给最敏锐的人';

  @override
  String get themeSharpestLine => '最难的卡片';

  @override
  String get themePast0 => '古代世界';

  @override
  String get themePast1 => '17至19世纪';

  @override
  String get themePast2 => '上个世纪';

  @override
  String get themePastLine => '每次回来都换一个时代';

  @override
  String get themePlace0 => '亚洲与中东';

  @override
  String get themePlace1 => '美洲';

  @override
  String get themePlace2 => '欧洲';

  @override
  String get themePlaceLine => '每次回来都换一个地区';

  @override
  String get themeTrueOrFalse => '是真是假？';

  @override
  String get themeTrueOrFalseLine => '翻开前先决定。大多数人都会错';

  @override
  String get themeReasoning => '纯推理';

  @override
  String get themeReasoningLine => '无需记忆：只是一种思考方式';

  @override
  String get themeIdeas => '大观念';

  @override
  String get themeIdeasLine => '事物背后的理论，一次一个';

  @override
  String get themeCurious => '纯属好奇';

  @override
  String get themeCuriousLine => '为了知道为什么的乐趣';

  @override
  String get themeMoving => '正在变化';

  @override
  String get themeMovingLine => '此刻正在改变的事，以及它为何重要';

  @override
  String get themeHowItWorks => '它到底怎么运作';

  @override
  String get themeHowItWorksLine => '你每天看到的事物背后的机制';

  @override
  String get themePuzzles => '谜题';

  @override
  String get themePuzzlesLine => '一支笔一分钟就能解的谜';

  @override
  String weekRecapMore(int n) {
    return '用 Astute+ 再看本周 $n 张';
  }

  @override
  String get weekReviewTitle => '复习本周';

  @override
  String get weekReviewLine => '本周卡片里的问题。再答一遍：这样才能记住。';

  @override
  String get weekReviewGo => '复习';

  @override
  String get weekReviewNone => '本周读过的卡片会回到这里，供你复习。';

  @override
  String get plusInTheApp =>
      'Astute+ 在应用中提供：在 iPhone 或 Android 上下载 Astute，开始免费试用。';

  @override
  String get purchaseComplete => '购买成功。';

  @override
  String get trialStartedTitle => '免费试用已开始。';

  @override
  String get successWelcome => '欢迎加入 Astute+。今天的五张卡片已经准备好了。';

  @override
  String successWelcomeNamed(String name) {
    return '欢迎加入 Astute+，$name。今天的五张卡片已经准备好了。';
  }

  @override
  String get successWelcomeTomorrow => '欢迎加入 Astute+。明天的五张卡片都为你而选。';

  @override
  String successWelcomeTomorrowNamed(String name) {
    return '欢迎加入 Astute+，$name。明天的五张卡片都为你而选。';
  }

  @override
  String get successFiveCards => '每天 5 张卡片';

  @override
  String get successArchive => '完整存档';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return '$date 前免费，之后 $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return '$date 续订 · $price$suffix';
  }

  @override
  String get successReceipt => '收据';

  @override
  String get letsStart => '开始吧';

  @override
  String successFootFirstCharge(String date) {
    return '首次扣款 $date · 随时取消';
  }

  @override
  String successFootRenews(String date) {
    return '$date 续订 · 随时取消';
  }

  @override
  String get tryToday => '今天就试试';

  @override
  String minutesShort(int n) {
    return '$n 分钟';
  }

  @override
  String get sideOr => '还是';

  @override
  String get nextStep => '下一步';

  @override
  String get showAllSteps => '全部显示';

  @override
  String get revealSeePicture => '看图';

  @override
  String get revealPlayScene => '自己试试';

  @override
  String get revealBackToAnswer => '回到答案';

  @override
  String get revealShowWorking => '查看推理过程';

  @override
  String get sceneLockIn => '确定';

  @override
  String get placeItDrag => '沿着刻度尺拖动。';

  @override
  String get placeItHappy => '就这样吗？';

  @override
  String get placeItEstimate => '你的估计';

  @override
  String get placeItNotSet => '未设置';

  @override
  String get placeItLock => '确定我的估计';

  @override
  String get sceneYou => '你';

  @override
  String get sceneTruth => '真相';

  @override
  String get sceneTryAgain => '再试一次';

  @override
  String get sceneDrawHint => '用手指画出你的猜测';

  @override
  String get sceneHoldHint => '按住';

  @override
  String get sceneSwipeHint => '滑动或点击';

  @override
  String get sceneTapToPick => '点选你的答案';

  @override
  String get sceneShowMe => '给我看';

  @override
  String get sceneYourGuess => '你的猜测';

  @override
  String sceneNOfM(int n, int m) {
    return '$m个中的$n个';
  }

  @override
  String get reportProblem => '报告问题';

  @override
  String get reportedThanks => '已报告，谢谢。';

  @override
  String get reportTitle => '这张卡片哪里有问题？';

  @override
  String get reportLead => '每条报告我们都会对照来源核实，并修正卡片。';

  @override
  String get reportFact => '事实有误';

  @override
  String get reportAnswer => '标为正确的答案是错的';

  @override
  String get reportSource => '来源并不支持这一点';

  @override
  String get reportUnclear => '看不明白';

  @override
  String get reportTypo => '错别字或显示错乱';

  @override
  String get reportOther => '其他';

  @override
  String get reportNoteHint => '有助于我们核实的信息（可选）';

  @override
  String get reportSend => '发送';

  @override
  String get reportSentToast => '谢谢，我们会核实。';

  @override
  String get journeyPointsOff => '分偏差';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再带把握回答 $n 题，就能测出来。',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => '你的分数';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '分');
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '4 周内 +$n';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '本周到目前为止，你获得了 $n 分。',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$date那一周，你获得了 $n 分。',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张',
      one: '1 张',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return '自$date以来每周结束时的分数。点一个点，查看那一周。';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return '等级 $n / $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\n即可升至“$rung”';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再读 $n 张',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再答 $n 题',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再带把握答 $n 题',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再记住 $n 张',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再降 $n 分',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => '折合';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 本书',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return '或 $h 小时纪录片';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '距第一本书还差 $n 张',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => '连续';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return '最高 $best 天 · $days 天中 $active 天';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n / $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return '主题 · 虚线：$month';
  }

  @override
  String get journeySubjects => '主题';

  @override
  String get journeyHowHard => '难度';

  @override
  String get journeyOfThree => '/ 3';

  @override
  String get journeyHardNow => '你打开的卡片。';

  @override
  String journeyHardThen(String v, String month) {
    return '你打开的卡片。$month为 $v';
  }

  @override
  String get journeyReadingTime => '阅读时间';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h 小时 $m 分';
  }

  @override
  String journeyMinutes(int m) {
    return '$m 分钟';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '每周 $now 分钟，起初 $was 分钟';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '本周 $m 分钟';
  }

  @override
  String journeyPointsOffFrom(int was) {
    return '分偏差，起初 $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · $n 及以下';
  }

  @override
  String get journeyRightWhenSure => '有把握时的正确率';

  @override
  String journeyFromIn(String v, String month) {
    return '$month时为 $v';
  }

  @override
  String get journeyMovesTitle => '能识破的套路';

  @override
  String get journeySureEmpty => '当你以 80% 及以上的把握作答后显示。';

  @override
  String get journeyMovesEmpty => '在两张卡片上识破同一个套路后显示。';

  @override
  String get journeyMissedEmpty => '第二个科目答满六题即可测出。';

  @override
  String get journeyFillsAsYouRead => '读得越多，这里越满。';

  @override
  String journeyOfN(int n) {
    return '/ $n';
  }

  @override
  String journeyNewest(String name) {
    return '最新：$name';
  }

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '仍记得的卡片',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days 天后',
    );
    return '$_temp0，$of 张中 $right 张';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks 周后',
    );
    return '$_temp0，$of 张中 $right 张';
  }

  @override
  String journeyActiveDays(int active, int days) {
    return '$days 天中 $active 天';
  }

  @override
  String get journeyMostlyMorning => '多在上午';

  @override
  String get journeyMostlyAfternoon => '多在下午';

  @override
  String get journeyMostlyEvening => '多在晚上';

  @override
  String get journeyMostlyNight => '多在深夜';

  @override
  String get journeyInTime => '时间跨度';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString 年';
  }

  @override
  String journeyFromEra(String era) {
    return '从$era到今年';
  }

  @override
  String get journeyEraAncient => '古代';

  @override
  String get journeyEraMedieval => '中世纪';

  @override
  String get journeyEraEarlyModern => '16世纪';

  @override
  String get journeyEraNineteenth => '19世纪';

  @override
  String get journeyEraTwentieth => '20世纪';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyInPlace => '地域';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个地区',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list和太空';
  }

  @override
  String get journeyRegionAmericas => '美洲';

  @override
  String get journeyRegionEurope => '欧洲';

  @override
  String get journeyRegionAsia => '亚洲';

  @override
  String get journeyRegionOceania => '大洋洲';

  @override
  String get journeyRegionAfrica => '非洲';

  @override
  String get journeyRegionMiddleEast => '中东';

  @override
  String get journeyTopics => '话题';

  @override
  String journeyMet(int n) {
    return '已接触 $n 个';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '其中 $n 个属于$subject';
  }

  @override
  String get journeyWords => '词汇';

  @override
  String journeyNew(int n) {
    return '新词 $n 个';
  }

  @override
  String get anotherOne => '换一张';

  @override
  String answerIs(String said) {
    return '答案：$said';
  }

  @override
  String get answeredAlready => '已作答';

  @override
  String get anyCard => '任意学科，任意书架，一张卡片';

  @override
  String betN(int n) {
    return '下注 $n';
  }

  @override
  String get betWord => '下注';

  @override
  String get biggerLabel => '更大';

  @override
  String get biggerYouGotIt => '更大 · 答对了';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 天后',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => '一周后';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 周后',
    );
    return '$_temp0';
  }

  @override
  String get check => '核对';

  @override
  String closerDone(String said, int right, int steps) {
    return '答案是 $said。$steps 步答对 $right 步。';
  }

  @override
  String closerNoLess(String v) {
    return '不对：比 $v 少。';
  }

  @override
  String closerNoMore(String v) {
    return '不对：比 $v 多。';
  }

  @override
  String get closerStart => '三步逼近答案。';

  @override
  String closerYesLess(String v) {
    return '对：比 $v 少。';
  }

  @override
  String closerYesMore(String v) {
    return '对：比 $v 多。';
  }

  @override
  String get didYouKnow => '你知道吗？';

  @override
  String get didYouKnowLine => '翻过来，然后：是新知道的，还是早就知道？';

  @override
  String get dragToSet => '拖动设定';

  @override
  String get dykAgain => '再来';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '早就知道 $n 张',
      zero: '没有早就知道的',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '新知道 $n 张',
      zero: '今天没有新知',
    );
    return '$_temp0';
  }

  @override
  String get eraShortAncient => '古代';

  @override
  String get eraShortEarlyModern => '1500–1800年';

  @override
  String get eraShortMedieval => '中世纪';

  @override
  String get eraShortNineteenth => '19世纪';

  @override
  String get eraShortRecent => '21世纪';

  @override
  String get eraShortTwentieth => '20世纪';

  @override
  String get fewCards => '几张卡片讲明白';

  @override
  String get fewCardsLine => '一张卡片讲不清的时候';

  @override
  String get firstLabel => '始于';

  @override
  String get forYouNow => '此刻为你';

  @override
  String get hardBadge => '难';

  @override
  String hidesIn(String where) {
    return '藏在：$where';
  }

  @override
  String get howSure => '我有多确定？为什么？';

  @override
  String inRange(int pts, String said) {
    return '命中：+$pts 分。答案是 $said。';
  }

  @override
  String inYourMoves(int n) {
    return '你的招数 · $n 次';
  }

  @override
  String itIs(String said) {
    return '答案是 $said。';
  }

  @override
  String get knewIt => '早就知道';

  @override
  String get less => '更少';

  @override
  String get lookFirst => '先看图表，再信标题。';

  @override
  String minutesLabel(int n) {
    return '$n 分钟';
  }

  @override
  String missedRange(String said) {
    return '没中：答案是 $said。';
  }

  @override
  String get modeBigger => '哪个更大？';

  @override
  String get modeCloser => '越来越近';

  @override
  String get modePick => '选一个';

  @override
  String get modeRange => '押一个区间';

  @override
  String get modeSlide => '拖一拖';

  @override
  String get modeStake => '下注吧';

  @override
  String get monthShelfLine => '每月换一个学科，人人相同';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards 张',
    );
    return '$_temp0 · $minutes 分钟';
  }

  @override
  String get moodTime => '你有多少时间';

  @override
  String get moodTitle => '你的心情，你的时间';

  @override
  String get moodTone => '基调';

  @override
  String get more => '更多';

  @override
  String moreOrLess(String v) {
    return '比 $v 多还是少？';
  }

  @override
  String get moveComparedToWhat => '多，还是少？';

  @override
  String get moveComparedToWhatLine => '“增长30%”说明不了什么，除非你知道：和什么比？';

  @override
  String get askingTitle => '每个主题一道题';

  @override
  String askingIn(String subject) {
    return '$subject的题目';
  }

  @override
  String get askingLine => '人人相同。先作答，再看原因';

  @override
  String get moveSampling => '数据里少了谁？';

  @override
  String get moveSamplingLine => '每个统计都算进了一些人，也漏掉了另一些人。漏掉的是谁，可能让答案完全反过来';

  @override
  String nOfM(int at, int of) {
    return '$at/$of';
  }

  @override
  String get newMove => '新招';

  @override
  String get newToMe => '新知道';

  @override
  String get notEnoughPoints => '积分不足';

  @override
  String get notSureLine => '从 Astute 任意角落抽一张';

  @override
  String get notSureTitle => '不知道从哪开始？';

  @override
  String get openWord => '打开';

  @override
  String get pickOneFirst => '先选一个';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts 分';
  }

  @override
  String get rightLastTime => '上次答对了';

  @override
  String get sayFalse => '假';

  @override
  String get sayTrue => '真';

  @override
  String get seriesAnchors => '第一印象';

  @override
  String get seriesGrowth => '失控的数字';

  @override
  String seriesMeta(int n, int m) {
    return '$n 张 · 约 $m 分钟';
  }

  @override
  String get seriesOdds => '会骗人的概率';

  @override
  String get seriesRetold => '重讲历史';

  @override
  String seriesStrand(String name) {
    return '几张卡片讲$name';
  }

  @override
  String get seriesStudies => '研究为何会误导';

  @override
  String showAllN(int n) {
    return '显示全部 $n 张';
  }

  @override
  String get showFewer => '收起';

  @override
  String get sixtyAgain => '再玩一次';

  @override
  String sixtyIn(int s) {
    return '用时 $s 秒';
  }

  @override
  String get sixtyLine => '八道判断题，凭直觉';

  @override
  String get sixtyPerfect => '八道全对。';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '目前答对 $n 道',
      zero: '还没答对',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => '秒内完成\n八道判断题';

  @override
  String sixtySecondsLeft(int s) {
    return '$s 秒';
  }

  @override
  String get sixtyStart => '开始';

  @override
  String get sixtyTimeUp => '在时间耗尽前';

  @override
  String get sixtyTitle => '六十秒';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '差了 $n 个百分点。',
      zero: '分毫不差。',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => '押注';

  @override
  String stepOf(int at, int of) {
    return '第 $at/$of 步';
  }

  @override
  String get surpriseMe => '给我惊喜';

  @override
  String get tapIfBigger => '更大就点';

  @override
  String get tapToTurn => '点击翻面';

  @override
  String get tfRight => '答对了，打开看原因。';

  @override
  String tfWrong(String side) {
    return '答案是$side，打开看原因。';
  }

  @override
  String theAnswer(String said) {
    return '答案：$said。';
  }

  @override
  String leanHint(String or) {
    return '把“$or”滑到你的立场';
  }

  @override
  String leanHow(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '1': '有一点',
      '2': '总体上',
      '3': '坚定地',
      'other': '完全',
    });
    return '$_temp0';
  }

  @override
  String leanSays(String side, String how) {
    return '$side（$how）';
  }

  @override
  String leanTook(String side) {
    return '你选了$side';
  }

  @override
  String leanVerdict(String says) {
    return '$says。打开看另一方的理由。';
  }

  @override
  String get spotTitle => '找出假的那条';

  @override
  String get spotLine => '四条说法。三条是真的，一条是假的。';

  @override
  String get spotPrompt => '点你认为是假的那条';

  @override
  String get spotConfirm => '这条是假的';

  @override
  String get spotFound => '找到了。其余三条都是真的。';

  @override
  String get spotMissed => '不是这条，它是真的。假的那条已划掉。';

  @override
  String get spotWhy => '点任意一条看原因';

  @override
  String get spotYours => '你的选择';

  @override
  String get todayLabel => '今天';

  @override
  String get toneCurious => '好奇';

  @override
  String get toneLight => '轻松';

  @override
  String get toneSerious => '严肃';

  @override
  String get toneTough => '硬核';

  @override
  String get unmaskBack => '看原版';

  @override
  String get unmaskFlipped => '把它正过来';

  @override
  String get unmaskLine => '同样的数字，不同的画面';

  @override
  String get unmaskStretched => '用公平的刻度';

  @override
  String get unmaskTitle => '揭穿图表';

  @override
  String get unmaskTotals => '公平比较';

  @override
  String get unmaskTruncated => '让坐标轴从零开始';

  @override
  String get unmaskWindow => '显示完整序列';

  @override
  String get unmaskMisleadTitle => '误导人的图表';

  @override
  String get unmaskMisleadLine => '数字是真的，花招在画法里。';

  @override
  String get unmaskAsk => '这张图在误导人。你看得出是怎么做到的吗？';

  @override
  String get unmaskShowTrick => '揭示花招';

  @override
  String get unmaskHideTrick => '隐藏花招';

  @override
  String get unmaskOriginal => '原图';

  @override
  String get unmaskCorrected => '修正后';

  @override
  String unmaskTrickTruncated(String from) {
    return '坐标轴从$from开始，而不是从零开始。';
  }

  @override
  String unmaskTrickZoomed(String low, String high) {
    return '坐标轴只覆盖$low到$high，小变化看起来很大。';
  }

  @override
  String unmaskTrickWide(String low, String high) {
    return '坐标轴从$low到$high，真实的变化看起来很平。';
  }

  @override
  String unmaskTrickWindow(String shown, String all) {
    return '只显示了$shown，而数据涵盖$all。';
  }

  @override
  String get unmaskTrickTotals => '比较的是原始总数，而不是公平的指标。';

  @override
  String get unmaskTrickFlippedRise => '坐标轴上下颠倒，上升看起来像下降。';

  @override
  String get unmaskTrickFlippedFall => '坐标轴上下颠倒，下降看起来像上升。';

  @override
  String get whatIfTrue => '如果是真的呢？';

  @override
  String get whatIfTrueLine => '合上之后仍在发酵的卡片';

  @override
  String get whatYouBelieve => '你相信的事';

  @override
  String get wrongLastTime => '上次答错了';

  @override
  String youLose(int n) {
    return '输掉 $n。';
  }

  @override
  String youWin(int n) {
    return '赢得 $n。';
  }

  @override
  String get yourPick => '你的选择';

  @override
  String placeNearYou(String place) {
    return '你附近 · $place';
  }

  @override
  String placeYourRegion(String place) {
    return '你的地区 · $place';
  }

  @override
  String placeYourCountry(String place) {
    return '你的国家 · $place';
  }

  @override
  String get sundayOneMore => '星期日：再为你多选一张';

  @override
  String get whereYouLive => '你住的地方';

  @override
  String get whereYouLiveLine => '先是你的城市，然后是地区，再是国家';

  @override
  String get whereYouLiveAsk =>
      '关于你的城市、地区和国家的卡片：每天最多一张，还有这个书架。只保存城市，从不保存你的确切位置。';

  @override
  String get whereYouLiveSwitchOn => '开启';

  @override
  String get gateUpdateTitle => '更新 Astute';

  @override
  String gateUpdateLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': '新版本正在 App Store 等你',
      'google': '新版本正在 Google Play 等你',
      'other': '新版本正在应用商店等你',
    });
    return '这个版本已经无法继续使用。$_temp0，你的卡片和连续记录都会原样保留。';
  }

  @override
  String get gateUpdateButton => '更新';

  @override
  String get gateSoftTitle => 'Astute 新版本已就绪';

  @override
  String gateSoftLine(String store) {
    String _temp0 = intl.Intl.selectLogic(store, {
      'apple': '它正在 App Store 等你。',
      'google': '它正在 Google Play 等你。',
      'other': '它正在应用商店等你。',
    });
    return '$_temp0更新只需片刻，你的卡片和连续记录都不会变。';
  }

  @override
  String get gateSoftLater => '稍后';

  @override
  String get gatePauseTitle => 'Astute 正在短暂休息';

  @override
  String get gatePauseLine => '我们正在幕后修好一些东西。你做过的一切都安然无恙。请稍后再试。';

  @override
  String get gatePauseTrying => '正在重试…';

  @override
  String get gatePauseStill => '仍在休息中。请过几分钟再试。';

  @override
  String purposeReadOrDoCount(int toDo, int toRead) {
    return '要做的 $toDo 张，要读的 $toRead 张';
  }

  @override
  String purposeShelfCount(int toDo, int toRead) {
    return '做 $toDo · 读 $toRead';
  }

  @override
  String get purposeFilterToRead => '读';

  @override
  String get purposeFilterToDo => '做';

  @override
  String purposeVerb(String verb) {
    String _temp0 = intl.Intl.selectLogic(verb, {
      'trueFalse': '是真是假',
      'pick': '选一个',
      'typeNumber': '填个数字',
      'bet': '押个数字',
      'side': '选一边',
      'youFirst': '你先答',
      'moveIt': '拖动看看',
      'whatNext': '接下来会怎样？',
      'spotTrick': '找出花招',
      'drawIt': '画出来',
      'sortThem': '分一分',
      'putInOrder': '排好顺序',
      'holdIt': '长按',
      'growSample': '扩大样本',
      'askWhy': '追问为什么',
      'sayPlainly': '说得简单些',
      'pairUp': '配对',
      'followClues': '顺着线索',
      'look': '只管看',
      'listen': '听一听',
      'other': '$verb',
    });
    return '$_temp0';
  }

  @override
  String purposeVerbRead(int n) {
    return '阅读 · $n 分钟';
  }

  @override
  String get purposeCommitNote => '先在这里作答，再打开卡片看看对不对。自己认定的答案，记得更久。';

  @override
  String get purposeCommitTitle => '先作答';

  @override
  String get purposeCommitLine => '先说出你的想法，再打开卡片';

  @override
  String get purposeInYourHeadLine => '在脑子里算出的数字';

  @override
  String get purposeInYourHead => '心算';

  @override
  String get purposeMoveKicker => '一招';

  @override
  String purposeMoveNew(int points) {
    return '新招 · 掌握后 +$points';
  }

  @override
  String purposeMoveName(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': '基础比率',
      'survivorship': '幸存者偏差',
      'regression': '均值回归',
      'confirmation': '证实偏差',
      'anchoring': '锚定',
      'sampling': '抽样',
      'confounding': '混杂因素',
      'counterfactual': '跟什么比',
      'multipleComparisons': '多次尝试',
      'availability': '可得性',
      'sunkCost': '沉没成本',
      'conjunction': '合取',
      'conditional': '条件概率',
      'independence': '独立性',
      'coincidence': '巧合',
      'exponential': '指数增长',
      'reflection': '快速答案',
      'simpson': '汇总陷阱',
      'estimation': '估算',
      'computation': '算出来',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveLine(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': '检测准不准，不等于你有多大可能中招',
      'survivorship': '你手上的数据，是活下来的数据',
      'regression': '极端值会自己回到平均',
      'confirmation': '只找“是”，算不上检验',
      'anchoring': '第一个说出口的数字，会带动后面所有数字',
      'sampling': '谁进了样本，决定了它能说明什么',
      'confounding': '也许是别的东西同时导致了两者',
      'counterfactual': '没有对照组，变化说明不了什么',
      'multipleComparisons': '试得够多，总有一个会过',
      'availability': '容易想到，不等于常见',
      'sunkCost': '花掉的就花掉了，能决定的只有剩下的',
      'conjunction': '细节让故事更可信，却更不可能',
      'conditional': '你得知的信息会改变概率',
      'independence': '运气没有记忆',
      'coincidence': '尝试够多，罕见的事就会常见',
      'exponential': '没人对翻倍有直觉',
      'reflection': '最先冒出来的答案，正是该检查的答案',
      'simpson': '整体可以偏向任何部分都不偏的方向',
      'estimation': '把答不上的问题拆成能估的小块',
      'computation': '一个你真能算完的问题',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String purposeMoveAsk(String move) {
    String _temp0 = intl.Intl.selectLogic(move, {
      'baseRate': '它本来有多常见？',
      'survivorship': '什么从没进过数据？',
      'regression': '会不会只是极端值回落？',
      'confirmation': '什么能证明我错了？',
      'anchoring': '最先出现的是哪个数字？',
      'sampling': '谁被算进去了？',
      'confounding': '还有什么能同时导致两者？',
      'counterfactual': '跟什么比？',
      'multipleComparisons': '一共试了多少样？',
      'availability': '是真常见，还是只是容易想到？',
      'sunkCost': '从这里起，还有什么可以决定？',
      'conjunction': '每多一个细节，可能性是不是更低？',
      'conditional': '知道这一点会改变什么？',
      'independence': '上一次结果会影响下一次吗？',
      'coincidence': '一共有多少次机会？',
      'exponential': '再翻一倍会怎样？',
      'reflection': '第一个答案是对的吗？',
      'simpson': '每个部分都朝同一个方向偏吗？',
      'estimation': '一路上我能估出什么？',
      'computation': '能一步一步算出来吗？',
      'other': '$move',
    });
    return '$_temp0';
  }

  @override
  String get purposeStepAbove => '再难一级';

  @override
  String get purposeStepAboveLine => '比你平时读的难一点';

  @override
  String purposeThinTitle(String subject) {
    return '你读得最少：$subject';
  }

  @override
  String purposeThinLine(int percent, String subject) {
    return '$subject只读了 $percent%，是你读得最少的';
  }

  @override
  String get purposeOtherSide => '另一边';

  @override
  String get purposeOtherSideLine => '你选了一边。这是反方最有力的理由';

  @override
  String purposeYouSaid(String side) {
    return '你说$side';
  }

  @override
  String purposeCaseFor(String side) {
    return '“$side”一方的理由';
  }

  @override
  String get purposeMechanism => '机制';

  @override
  String purposeMovingUpdated(String date) {
    return '$date更新';
  }

  @override
  String get purposeMovingYears => '几年内可能会变';

  @override
  String get purposeMovingMonths => '今年就可能变';

  @override
  String get purposeWhy => '啊，原来如此';

  @override
  String get purposeWhyLine => '一个机制，讲到你恍然大悟';

  @override
  String purposeWhyBand(int n) {
    return '为什么 · $n 分钟';
  }

  @override
  String get purposeMe => '说的就是我';

  @override
  String get purposeMeLine => '你不知不觉在做的事';

  @override
  String get purposeMeFooter => '给说中你的卡片做个记号。';

  @override
  String purposeMeMarked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已标记“说的就是我”的卡片：$n 张。',
    );
    return '$_temp0';
  }

  @override
  String get purposeAboutYou => '原来如此，还和我有关';

  @override
  String get purposeAboutYouLine => '你的身体、你的健康、你的概率';

  @override
  String get purposeHeadline => '在标题里';

  @override
  String get purposeHeadlineLine => '听起来比实际更好的研究和说法';

  @override
  String get purposeTheClaim => '说法';

  @override
  String get purposeNumber => '在数字里';

  @override
  String get purposeNumberLine => '值得再看一眼的概率和百分比';

  @override
  String get purposeOutOfWhat => '基数是多少？';

  @override
  String get purposeOffer => '在优惠里';

  @override
  String get purposeOfferLine => '价格、交易，以及到底谁在买单';

  @override
  String get purposeArgument => '在争论里';

  @override
  String get purposeArgumentLine => '推理失足的地方';

  @override
  String purposeKeepHeading(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': '一个能识破大多数花招的问题',
      '2': '两个能识破大多数花招的问题',
      '3': '三个能识破大多数花招的问题',
      '4': '四个能识破大多数花招的问题',
      '5': '五个能识破大多数花招的问题',
      'other': '$n 个能识破大多数花招的问题',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeAbout(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': '金钱',
      'work': '工作与时间',
      'clock': '时间',
      'body': '你的身体',
      'relationships': '人际关系',
      'belief': '你相信的事',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeQuestion(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': '我是在为真正用到的东西付钱吗？',
      'work': '怎样让明天更容易开始？',
      'clock': '我的时间到底去了哪里？',
      'body': '我对自己身体的了解还对吗？',
      'relationships': '身边的人真正需要什么？',
      'belief': '我有多确定？为什么？',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String purposeLifeChip(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': '金钱',
      'work': '工作',
      'clock': '时间',
      'body': '身体',
      'relationships': '人际关系',
      'belief': '我相信的事',
      'other': '$topic',
    });
    return '$_temp0';
  }

  @override
  String get purposeLifeAsk => '你想在哪方面问出更好的问题？';

  @override
  String get purposeLifeFooter => '随便选几个，相关的卡片就会出现在这里。';

  @override
  String get purposeSpotTrick => '找出花招';

  @override
  String get purposeSpotTrickLine => '哪个问题能识破它？';

  @override
  String get purposePlayed => '今天玩过的';

  @override
  String get purposePlayedOff => '平均偏差（点）';

  @override
  String get purposePlayedTricks => '识破的花招';

  @override
  String get purposePlayedAnswered => '在书架上作答';

  @override
  String get purposePlayedFooter => '在书架上作答，也会像“今天”里的回答一样计入“你的旅程”。';

  @override
  String purposeOf(int n, int of) {
    return '$n/$of';
  }

  @override
  String purposeSetRead(int n, int of) {
    return '已读 $n/$of';
  }

  @override
  String purposeSetDone(int n) {
    return '$n 张全部读完。这个书架再轮到时，会加入新卡。';
  }

  @override
  String get purposeComplete => '已集齐';

  @override
  String get purposeStampsFooter => '每读一张卡，就盖上一枚邮票。';

  @override
  String get purposeSets => '你的合集';

  @override
  String get purposeSetsLine => '读了就算数。不用作答也能集满。';

  @override
  String get purposeTomorrow => '明天的书架';

  @override
  String get purposeTomorrowLine => '书架每天都在换。接下来是这些';

  @override
  String get purposeEnd => '“探索”到底了';

  @override
  String get purposeEndLine => '明天见';

  @override
  String get betsRangeTitle => '押一个区间';

  @override
  String get betsRangeLine => '区间越窄，猜中赢得越多';

  @override
  String betsRangeWidth(int w, int pts) {
    return '±$w · $pts 分';
  }

  @override
  String get betsBet => '下注';

  @override
  String betsInRange(int pts, String said) {
    return '命中：+$pts 分。答案是 $said。';
  }

  @override
  String betsMissedRange(String said) {
    return '没中：答案是 $said。';
  }

  @override
  String get betsYourGuess => '你的猜测';

  @override
  String get betsAnsweredAlready => '已作答';

  @override
  String get betsOpenCard => '打开卡片';

  @override
  String betsWalletSays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天还剩 $n 分',
    );
    return '$_temp0';
  }

  @override
  String get betsSlipTitle => '你的投注单';

  @override
  String betsSlipToday(String points) {
    return '今天 $points';
  }

  @override
  String get betsSlipEmpty => '还没有下注。每一注都会出现在这里。';

  @override
  String get betsSlipTipTwice => '有把握就押窄：赢得是两倍。';

  @override
  String get betsSlipTipThrice => '有把握就押窄：赢得是三倍。';

  @override
  String betsSlipTipTimes(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '有把握就押窄：赢得是 $times 倍。',
    );
    return '$_temp0';
  }

  @override
  String betsSlipNarrow(int right, int n) {
    return '窄区间命中：$n 次中 $right 次。';
  }

  @override
  String betsSlipSure(int right, int n, int pct) {
    return '$n 次答对 $right 次，平均把握 $pct%。';
  }

  @override
  String get betsRight => '答对';

  @override
  String get betsWrong => '答错';

  @override
  String betsOneIn(String n) {
    return '$n 分之 1';
  }

  @override
  String get betsOneInLabel => '几分之一';

  @override
  String betsScore(int right, int steps) {
    return '$steps 步中 $right 步';
  }

  @override
  String betsScoreSentence(int right, int steps) {
    return '$steps 步答对 $right 步。';
  }

  @override
  String get betsStakeTitle => '下注吧';

  @override
  String betsStakeLine(int points) {
    return '每天 $points 分。赢了，赌注翻倍';
  }

  @override
  String get betsStakeLabel => '押注';

  @override
  String betsBetN(int n) {
    return '下注 $n';
  }

  @override
  String get betsPickFirst => '先选一个';

  @override
  String get betsNotEnough => '积分不足';

  @override
  String betsWin(int n) {
    return '赢得 $n。';
  }

  @override
  String betsLose(int n) {
    return '输掉 $n。';
  }

  @override
  String betsYouWereSure(int pct) {
    return '你当时有 $pct% 的把握。';
  }

  @override
  String get betsFriendTitle => '和朋友打个赌';

  @override
  String get betsFriendLine => '发一道题过去，然后比比谁猜得更准';

  @override
  String get betsFriendNote => '你的猜测只留在你的手机上。卡片会连同答案一起发出，所以先问问对方怎么猜。';

  @override
  String betsFriendNoteSaid(String said) {
    return '你猜的是 $said。卡片会连同答案一起发出，所以先问问对方怎么猜。';
  }

  @override
  String get betsFriendSend => '发给朋友';

  @override
  String get betsFriendCopy => '复制题目';

  @override
  String get betsFriendCopied => '题目已复制';

  @override
  String get betsFriendAsk => '你怎么看？';

  @override
  String get betsNumberTitle => '你的数字';

  @override
  String get betsNumberLine => '调好、锁定，看看差了多少';

  @override
  String get betsLock => '确定';

  @override
  String get betsSpotOn => '分毫不差。';

  @override
  String betsCloseEnough(String by) {
    return '足够接近：差了 $by。';
  }

  @override
  String betsOffBy(String by) {
    return '差了 $by。';
  }

  @override
  String get betsYou => '你';

  @override
  String get betsAnswer => '答案';

  @override
  String get betsBiggerTitle => '哪个更大？';

  @override
  String get betsBiggerLine => '两个可以算出来的数字。点更大的那个';

  @override
  String get betsTapIfBigger => '更大就点';

  @override
  String get betsBiggerGotIt => '更大 · 答对了';

  @override
  String get betsBigger => '更大';

  @override
  String get betsYourPick => '你的选择';

  @override
  String get betsOr => '还是';

  @override
  String get betsBiggerFoot => '每个数字都是一张卡片的答案。选完后点一下就能打开那张卡片。';

  @override
  String betsBiggerScore(int right, int n) {
    return '$n 次答对 $right 次。';
  }

  @override
  String get betsCloserTitle => '越来越近';

  @override
  String betsCloserLine(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {
      'other': '用 $steps 次“多还是少”逼近这个数字',
    });
    return '$_temp0';
  }

  @override
  String betsCloserStart(String steps) {
    String _temp0 = intl.Intl.selectLogic(steps, {'other': '$steps 步逼近答案。'});
    return '$_temp0';
  }

  @override
  String betsMoreOrLess(String v) {
    return '比 $v 多还是少？';
  }

  @override
  String betsStepOf(int at, int of) {
    return '第 $at/$of 步';
  }

  @override
  String get betsMore => '更多';

  @override
  String get betsLess => '更少';

  @override
  String betsCloserYesMore(String v) {
    return '答对了：比 $v 多。';
  }

  @override
  String betsCloserYesLess(String v) {
    return '答对了：比 $v 少。';
  }

  @override
  String betsCloserNoMore(String v) {
    return '答错了：比 $v 多。';
  }

  @override
  String betsCloserNoLess(String v) {
    return '答错了：比 $v 少。';
  }

  @override
  String betsCloserExact(String said) {
    return '正好是 $said。';
  }

  @override
  String betsCloserDone(String said, int right, int steps) {
    return '答案是 $said。$steps 步答对 $right 步。';
  }

  @override
  String get betsMagnitudeTitle => '数量级';

  @override
  String get betsMagnitudeLine => '十、一千还是一百万？选一个量级';

  @override
  String get betsMagnitudeRight => '数量级猜对了。';

  @override
  String betsMagnitudeOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '差了 $n 个数量级。',
    );
    return '$_temp0';
  }

  @override
  String get betsDayTitle => '今日一赌';

  @override
  String get betsDayLine => '确定你的猜测，再看看差了多少';

  @override
  String get betsDayTag => '今日一赌';

  @override
  String get betsDayTagSame => '今日一赌 · 人人同题';

  @override
  String get betsLockIn => '确定';

  @override
  String betsItIs(String said) {
    return '答案是 $said。';
  }

  @override
  String betsPointsOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '差了 $n 个百分点。',
      zero: '分毫不差。',
    );
    return '$_temp0';
  }

  @override
  String screensQuoted(String text) {
    return '“$text”';
  }

  @override
  String get screensExpertTitle => '像专家一样思考';

  @override
  String get screensExpertLine => '他们每个人总会问的问题，以及需要这个问题的卡片';

  @override
  String get screensExpertStatistician => '统计学家';

  @override
  String get screensExpertStatisticianAs => '像统计学家一样思考';

  @override
  String get screensExpertStatisticianAsks => '和什么比？总数是多少？';

  @override
  String get screensExpertEconomist => '经济学家';

  @override
  String get screensExpertEconomistAs => '像经济学家一样思考';

  @override
  String get screensExpertEconomistAsks => '谁来付钱？又放弃了什么？';

  @override
  String get screensExpertHistorian => '历史学家';

  @override
  String get screensExpertHistorianAs => '像历史学家一样思考';

  @override
  String get screensExpertHistorianAsks => '当时的人知道些什么？';

  @override
  String get screensExpertDoctor => '医生';

  @override
  String get screensExpertDoctorAs => '像医生一样思考';

  @override
  String get screensExpertDoctorAsks => '这有多常见？还可能是别的什么？';

  @override
  String get screensExpertScientist => '科学家';

  @override
  String get screensExpertScientistAs => '像科学家一样思考';

  @override
  String get screensExpertScientistAsks => '如果它是错的，我们怎么会知道？';

  @override
  String get screensDotsTitle => '连点成线';

  @override
  String get screensDotsLine => '选一个主题，看看它在哪里与其他主题交汇';

  @override
  String screensDotsMeets(int subjects, int cards) {
    String _temp0 = intl.Intl.pluralLogic(
      subjects,
      locale: localeName,
      other: '与 $subjects 个主题',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '在 $cards 张卡片中交汇',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get screensDotsWhere => '交汇之处';

  @override
  String get screensDotsWhereLine => '一个问题，两种视角';

  @override
  String get screensAskTitle => '你想弄懂什么？';

  @override
  String get screensAskHint => '问任何问题，或输入一个词';

  @override
  String get screensAskTry => '试试';

  @override
  String get screensAskClear => '清除问题';

  @override
  String screensAskFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 张卡片能回答',
    );
    return '$_temp0';
  }

  @override
  String get screensAskNone => '还没有关于这个的卡片';

  @override
  String get screensAskNoneLine => '把问题留着。等有卡片回答它，它会出现在这里，就在问题下方。';

  @override
  String get screensAskKeep => '留下这个问题';

  @override
  String get screensAskKept => '已留下';

  @override
  String get screensAskedTitle => '你问过的问题';

  @override
  String get screensAskedLine => '以及回答了它们的卡片';

  @override
  String get screensAskedAnswered => '已回答';

  @override
  String get screensAskedWaiting => '还没有卡片回答它。等有了，就会出现在这里。';

  @override
  String get screensAskedForget => '忘掉这个问题';

  @override
  String get screensAskedForgotten => '问题已忘掉';

  @override
  String get screensWhyTitle => '一直问为什么';

  @override
  String get screensWhyLine => '每个答案都引出下一个问题';

  @override
  String get screensWhyAsk => '为什么？';

  @override
  String screensWhyBottom(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已经问了 $n 个为什么。',
    );
    return '$_temp0这一串到底了。';
  }

  @override
  String get screensWhyAgain => '从头开始';

  @override
  String get screensWhyHoles => '更多兔子洞';

  @override
  String get screensWhyHolesLine => '每一个都要问上几个为什么';

  @override
  String screensWhyCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个为什么',
    );
    return '$_temp0';
  }

  @override
  String get screensWhyDeeper => '再深入一点';

  @override
  String screensWhySource(String source) {
    return '来源：$source';
  }

  @override
  String screensWhyDepth(int at, int of) {
    String _temp0 = intl.Intl.pluralLogic(
      at,
      locale: localeName,
      other: '第 $at 个为什么，共 $of 个',
    );
    return '$_temp0';
  }

  @override
  String get screensTimeTitle => '穿越时间';

  @override
  String get screensTimeLine => '一次一个时代，直到今年。拖动来穿越';

  @override
  String get screensTimeCaption => '距今年数。每一格都再往前推十倍。';

  @override
  String get screensTimeNow => '现在';

  @override
  String get screensTimeEarlier => '更早';

  @override
  String get screensTimeLater => '更近';

  @override
  String get screensEraAncient => '古代世界';

  @override
  String get screensEraAncientWhen => '公元500年以前';

  @override
  String get screensEraMedieval => '中世纪';

  @override
  String get screensEraMedievalWhen => '500年至1500年';

  @override
  String get screensEraEarlyModern => '近代早期';

  @override
  String get screensEraEarlyModernWhen => '1500年至1800年';

  @override
  String get screensEraNineteenth => '19世纪';

  @override
  String get screensEraNineteenthWhen => '1800年至1900年';

  @override
  String get screensEraTwentieth => '上个世纪';

  @override
  String get screensEraTwentiethWhen => '1900年至2000年';

  @override
  String get screensEraRecent => '本世纪';

  @override
  String get screensEraRecentWhen => '2000年以来';

  @override
  String get screensMindTitle => '改变想法';

  @override
  String get screensMindLine => '读之前说说你的立场，读完再说一次';

  @override
  String get screensMindClaim => '观点';

  @override
  String get screensMindBefore => '读之前';

  @override
  String get screensMindTap => '点选你的立场';

  @override
  String get screensMindKnow => '我们知道的';

  @override
  String get screensMindNow => '现在呢？';

  @override
  String get screensMindAgain => '再点一次';

  @override
  String screensMindLevel(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      '0': '非常不同意',
      '1': '不同意',
      '2': '不确定',
      '3': '同意',
      'other': '非常同意',
    });
    return '$_temp0';
  }

  @override
  String screensMindToward(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '你向证据靠近了 $n 步。',
    );
    return '$_temp0';
  }

  @override
  String get screensMindSame => '和之前一样。一张卡片终究只是一张卡片。';

  @override
  String get screensMindAlready => '读之前，你就和证据站在一起了。';

  @override
  String get screensMindAway => '你离证据更远了。值得再读一遍。';

  @override
  String get screensMindFirst => '先说说你的立场。读之前，点一下就好。';

  @override
  String screensMindChanged(int changed, int total) {
    return '$total 条中有 $changed 条，你改变了想法。';
  }

  @override
  String get screensMindFoot => '改变了想法，就说明这张卡片起了作用。';

  @override
  String get screensSayTitle => '今晚说出来';

  @override
  String get screensSayLine => '带去晚餐的一句话。说过之后点一下';

  @override
  String get screensSayTonight => '今晚这一句';

  @override
  String get screensSaySaid => '我说了';

  @override
  String get screensSayDone => '已说过';

  @override
  String screensSayWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '这周你说了 $n 句。',
      zero: '这周还没说过。',
    );
    return '$_temp0';
  }

  @override
  String get screensSayCounts => '你说出的每一句，也会计入本周热门。';

  @override
  String get screensFrontName => 'The Astute';

  @override
  String get screensFrontEdition => '今日版';

  @override
  String get screensFrontSame => '人人相同';

  @override
  String get screensFrontLead => '头条';

  @override
  String get screensFrontNumbers => '数字看点';

  @override
  String get screensFrontCorrections => '更正';

  @override
  String get screensFrontPuzzle => '今日谜题';

  @override
  String get screensFrontEnd => '今天这一期就到这里';

  @override
  String get screensFrontTomorrow => '明天的一期早上发布';

  @override
  String exploreDayRead(int read, int of) {
    return '今天：已读 $read/$of';
  }

  @override
  String exploreDayLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '还剩 $n 张',
    );
    return '$_temp0';
  }

  @override
  String get exploreDayDone => '全部读完';

  @override
  String get exploreDayOpen => '前往今天的卡片';

  @override
  String get exploreGameNone => '现在这里没有可玩的。明天再来。';

  @override
  String get challengesTitle => '挑战';

  @override
  String get challengesLine => '关于判断与估算的简短练习，每个只需几分钟。';

  @override
  String challengesPage(int n, int of) {
    return '第 $n 页，共 $of 页';
  }

  @override
  String get gamePlay => '开始';

  @override
  String get sixtyRules =>
      '一分钟内判断八条说法的真假。它衡量你在匆忙中判断的准确程度，而我们读到的大多数内容，正是这样被判断的。';

  @override
  String get sixtyReview => '八条说法';

  @override
  String get gameRight => '答对了';

  @override
  String get gameWrong => '答错了';

  @override
  String get gameUnanswered => '未作答';

  @override
  String get gameNext => '下一个挑战';

  @override
  String sixtyShareHead(String date) {
    return 'Astute · 六十秒 · $date';
  }

  @override
  String sixtyShareScore(int n, int of, int s) {
    return '$of 道答对 $n 道 · $s 秒';
  }

  @override
  String sixtySecondsLeftLabel(int s) {
    String _temp0 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '还剩 $s 秒',
    );
    return '$_temp0';
  }

  @override
  String get gameReview => '卡片';

  @override
  String get gameTomorrow => '明天有新一轮';

  @override
  String get gameContinue => '继续';

  @override
  String gameShareHead(String game, String date) {
    return 'Astute · $game · $date';
  }

  @override
  String gameShareScore(int n, int of) {
    return '$of 个中答对 $n 个';
  }

  @override
  String gameCardsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天 $n 张',
    );
    return '$_temp0';
  }

  @override
  String get gameAllRight => '全部答对。';

  @override
  String gamePoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n 分');
    return '$_temp0';
  }

  @override
  String get gameSeeResult => '查看结果';

  @override
  String get gameNextCard => '下一张';

  @override
  String get spotOnce => '每天只能选一次';

  @override
  String get spotGotIt => '你找出了假的那条。';

  @override
  String get spotMissedIt => '不是那条：它是真的。';

  @override
  String get tfRules => '大多数人都会答错的说法。判断真假，再读原因。它衡量你的判断力：分清真正正确的和只是看似显然的。';

  @override
  String get inOrderTitle => '时间排序';

  @override
  String get inOrderRules =>
      '卡片里的四个时刻，年份都被隐去，请按发生的先后排列。它衡量你的时间顺序感，这是一切解释的第一道检验：原因总在结果之前。';

  @override
  String get inOrderFirst => '点最先发生的时刻。';

  @override
  String get inOrderNext => '再点接下来发生的。';

  @override
  String get inOrderReady => '都排好了。';

  @override
  String get inOrderCheck => '检查顺序';

  @override
  String inOrderPlaced(int n) {
    return '第 $n 个';
  }

  @override
  String inOrderYours(int n) {
    return '你排在：第 $n';
  }

  @override
  String get inOrderPerfect => '全部排对了。';

  @override
  String get timeGap => '缺失的年份';

  @override
  String get whatYearTitle => '哪一年？';

  @override
  String get whatYearRules =>
      '三个时刻，年份都被隐去。为每一个转到对应的年份：越接近，得分越高，最多十分。它衡量你对事情发生时间的感觉。';

  @override
  String whatYearPoints(int n, int of) {
    return '$of 分中得 $n 分';
  }

  @override
  String get whatYearPerfect => '每个年份都完全正确。';

  @override
  String whatYearOffInAll(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '总共差了 $n 年。',
    );
    return '$_temp0';
  }

  @override
  String whatYearSaid(String guess, int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '你的答案：$guess · $points 分',
    );
    return '$_temp0';
  }

  @override
  String whatYearOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '差了 $n 年',
    );
    return '$_temp0';
  }

  @override
  String whatYearEarlier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '往前 $n 年',
    );
    return '$_temp0';
  }

  @override
  String whatYearLater(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '往后 $n 年',
    );
    return '$_temp0';
  }

  @override
  String get whatYearDial => '年份';

  @override
  String get beforeAfterTitle => '之前还是之后？';

  @override
  String get beforeAfterRules => '六个时刻依次出现。判断每一个发生在上面那个之前还是之后。它衡量你的顺序感。';

  @override
  String get beforeAfterBefore => '之前';

  @override
  String get beforeAfterAfter => '之后';

  @override
  String beforeAfterAsk(String year) {
    return '在 $year 年之前还是之后？';
  }

  @override
  String beforeAfterSaidBefore(String year) {
    return '你的答案：$year 年之前';
  }

  @override
  String beforeAfterSaidAfter(String year) {
    return '你的答案：$year 年之后';
  }

  @override
  String get beforeAfterStart => '从这里开始';

  @override
  String get beforeAfterPerfect => '一个都没错。';

  @override
  String biggerPairsToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今天 $n 组',
    );
    return '$_temp0';
  }

  @override
  String get sixtySkill => '直觉';

  @override
  String get spotSkill => '辨别';

  @override
  String get tfSkill => '判断';

  @override
  String get biggerSkill => '比例';

  @override
  String get closerSkill => '估算';

  @override
  String get magnitudeSkill => '量级';

  @override
  String get rangeSkill => '校准';

  @override
  String get stakeSkill => '把握';

  @override
  String get numberSkill => '精确';

  @override
  String get inOrderSkill => '时序';

  @override
  String get whatYearSkill => '断代';

  @override
  String get beforeAfterSkill => '先后';

  @override
  String get sixtyAsks => '一分钟，八条说法。';

  @override
  String get spotAsks => '四条说法，其中一条是假的。';

  @override
  String get tfAsks => '大多数人会答错的说法。';

  @override
  String get biggerAsks => '两个数字，哪个更大？';

  @override
  String get closerAsks => '一步步逼近一个数字。';

  @override
  String get magnitudeAsks => '找出正确的十的幂。';

  @override
  String get rangeAsks => '一个刚好够宽的区间。';

  @override
  String get stakeAsks => '按你的把握程度押分。';

  @override
  String get numberAsks => '认定一个数字。';

  @override
  String get inOrderAsks => '四个时刻，从最早的开始。';

  @override
  String get whatYearAsks => '把一个时刻放回它的年份。';

  @override
  String get beforeAfterAsks => '每个时刻与上一个相比。';

  @override
  String get challengeBest => '最佳';

  @override
  String get challengeToday => '今天';

  @override
  String get challengeAccuracy => '正确率';

  @override
  String get challengeTime => '用时';

  @override
  String challengeSeconds(int s) {
    return '$s 秒';
  }

  @override
  String get challengePersonalBest => '个人最佳';

  @override
  String challengeAboveChance(int n, int of) {
    return '高于随机水平：纯靠猜测，平均$of个中对$n个。';
  }

  @override
  String challengeAtChance(int n, int of) {
    return '与随机水平持平：纯靠猜测，平均$of个中对$n个。';
  }

  @override
  String challengeBelowChance(int n, int of) {
    return '低于随机水平：纯靠猜测，平均$of个中对$n个。';
  }

  @override
  String sixtyUnanswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '时间到了，还有 $n 条说法没有作答。',
    );
    return '$_temp0';
  }

  @override
  String get challengeAgain => '再来一轮';

  @override
  String get spotRules => '四条说法：三条是真的，一条是假的。找出假的那条。它衡量你能否分辨有根据的说法和只是听起来对的说法。';

  @override
  String get spotAsk => '点你认为是假的那条说法。';

  @override
  String get biggerRules => '两个数字，各是一张卡片问题的答案。点你认为更大的那个。它衡量你的比例感。';

  @override
  String get biggerAsk => '点答案更大的那张卡片。';

  @override
  String biggerRight(String big, String small) {
    return '答对了：$big 比 $small 大。';
  }

  @override
  String biggerWrong(String big, String small) {
    return '答错了：$big 比 $small 大。';
  }

  @override
  String get closerRules => '一步步逼近一个比例：每一次，判断它比剩下范围的中点多还是少。它衡量你的估算能力。';

  @override
  String closerDoneSteps(String said, int right, int steps) {
    return '答案是 $said：$steps 步中答对 $right 步。';
  }

  @override
  String closerExactSteps(String said, int right, int steps) {
    return '答案正好是 $said：$steps 步中答对 $right 步。';
  }

  @override
  String closerStepsRight(int right, int steps) {
    return '$steps 步中答对 $right 步。';
  }

  @override
  String get magnitudeRules => '十、一千还是一百万？选出最接近答案的十的幂。它衡量你的量级感，这比精确的数字更重要。';

  @override
  String get rangeRules =>
      '先定下你的估计，再在它周围设一个范围：范围越窄，答案落在其中时得分越高。它衡量你的校准能力：知道自己知道多少。';

  @override
  String rangeOption(int w, int pts) {
    return '±$w · 得 $pts 分';
  }

  @override
  String rangeIn(String said, int pts) {
    String _temp0 = intl.Intl.pluralLogic(
      pts,
      locale: localeName,
      other: '答案是 $said：在你的范围内，+$pts 分。',
    );
    return '$_temp0';
  }

  @override
  String rangeOut(String said) {
    return '答案是 $said：在你的范围外。';
  }

  @override
  String stakeRules(int points) {
    return '选一个答案，从每天的 $points 分里拿出分数押上：答对，赌注翻倍；答错，赌注输掉。它衡量你的确信：只押你知道的。';
  }

  @override
  String stakeWon(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '答对了：赢得 $n 分。',
    );
    return '$_temp0';
  }

  @override
  String stakeLost(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '答错了：输掉 $n 分。',
    );
    return '$_temp0';
  }

  @override
  String get numberRules => '用按钮定下一个数字并锁定。它衡量你的精确度：在必须给出一个数字时，你能接近到什么程度。';

  @override
  String tfRightIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': '答对了：这是真的。',
      'other': '答对了：这是假的。',
    });
    return '$_temp0';
  }

  @override
  String tfWrongIs(String side) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'true': '答错了：这是真的。',
      'other': '答错了：这是假的。',
    });
    return '$_temp0';
  }

  @override
  String inOrderTold(int n, int of) {
    return '$of 个中有 $n 个位置正确。';
  }

  @override
  String get whatYearYours => '你的年份';

  @override
  String get whatYearExactly => '年份完全正确';

  @override
  String beforeAfterRight(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': '答对了：是 $year 年，在 $above 年之前。',
      'other': '答对了：是 $year 年，在 $above 年之后。',
    });
    return '$_temp0';
  }

  @override
  String beforeAfterWrong(String side, String year, String above) {
    String _temp0 = intl.Intl.selectLogic(side, {
      'before': '答错了：是 $year 年，在 $above 年之前。',
      'other': '答错了：是 $year 年，在 $above 年之后。',
    });
    return '$_temp0';
  }

  @override
  String get challengeAnswer => '答案';

  @override
  String get challengeYouSaid => '你的答案';

  @override
  String get challengePoints => '得分';

  @override
  String get challengeThisRound => '本轮';

  @override
  String get challengeLeftToday => '今天剩余';

  @override
  String exploreSubjectLevel(String subject, int n) {
    return '$subject，等级 $n';
  }

  @override
  String exploreBecauseSaved(String question) {
    return '因为你收藏了“$question”';
  }

  @override
  String get todaySeeAgain => '再看一遍';

  @override
  String get todaySeeAgainHint => '从第一张开始，全屏重看今天的卡片';

  @override
  String get yourFiveFromToday => '你今天的五张卡片';

  @override
  String get dayMomentTitle => '今天的五张，完成。';

  @override
  String get dayMomentLater => '稍后';

  @override
  String get yourDayCard => '你的一天';

  @override
  String get tuneTitle => '调整你的组合';

  @override
  String get tuneEntryLine => '每个主题要多少，以及哪些部分';

  @override
  String get tuneLearned => '已经根据你喜欢和丢掉的卡片做了调整。滑动即可更改。';

  @override
  String get tuneFresh => '滑动一个主题，看得更多或更少。';

  @override
  String get tuneHowMuch => '各要多少';

  @override
  String get tuneInsideLine => '你最喜欢的部分排在前面。轻点可跳过，长按可查看里面。';

  @override
  String get tuneSave => '保存';

  @override
  String get tuneHoldHint => '长按某个类别，打开里面更小的主题';

  @override
  String get shareDayTitle => '分享你的一天';

  @override
  String get shareDayRead => '五张卡片，读完了';

  @override
  String get shareDayTurn => '每天五张卡。轮到你了。';

  @override
  String shareDaySure(int n) {
    return '把握 $n%';
  }

  @override
  String get shareDayHeadline => '今天的五张';

  @override
  String get shareFormatCover => '封面';

  @override
  String get shareFormatList => '列表';

  @override
  String get shareFormatStory => '快拍';

  @override
  String crowdGotRight(int n) {
    return '$n% 的读者答对了';
  }

  @override
  String crowdGotWrong(int n) {
    return '也有 $n% 的读者答错了';
  }

  @override
  String get challengeFriend => '挑战好友';

  @override
  String get challengeLine => '这道你能答对吗？';

  @override
  String pathFree(int n) {
    return '$n张免费';
  }

  @override
  String pathMoreTitle(int n) {
    return '这条路线还有$n张。';
  }

  @override
  String get pathMoreLine => '每条路线完整解锁，从最简单的卡片到最难的，每周还有一排新路线。';

  @override
  String get pathMoreGo => '读完整条路线';

  @override
  String get paywallPathsTitle => '每条路线，十张全看。';

  @override
  String get paywallPathsMark => '十张全看。';

  @override
  String get paywallPathsLine => '一个主题十张卡片，从最简单到最难。每周都有新路线，今天的五张也按你的水平来。';

  @override
  String get widgetAskTitle => '明天的第一张卡片，放在主屏幕上。';

  @override
  String get widgetAskLine => '不用打开应用，每天早上一张新卡片，旁边还有你的连续天数。';

  @override
  String get widgetAskStepHold => '长按主屏幕上的空白处。';

  @override
  String get widgetAskStepAppleAdd => '轻点“编辑”，然后轻点“添加小组件”。';

  @override
  String get widgetAskStepApplePick => '找到 Astute，选择尺寸，然后轻点“添加小组件”。';

  @override
  String get widgetAskStepAndroidAdd => '轻点“小组件”。';

  @override
  String get widgetAskStepAndroidPick => '找到 Astute，按住一个小组件并拖到想放的位置。';

  @override
  String get widgetAskLockScreen => '锁定屏幕也可以：长按锁定屏幕，然后轻点“自定”。';

  @override
  String get widgetAskPin => '添加到主屏幕';

  @override
  String get widgetAskGotIt => '知道了';

  @override
  String get widgetAskNotNow => '以后再说';

  @override
  String pathCardOf(int n, int total) {
    return '第$n张，共$total张';
  }

  @override
  String get pathDoorNext => '这条路的下一张';

  @override
  String get shareSendCard => '发送卡片';

  @override
  String get shareAsImage => '以图片分享';

  @override
  String get shareCopyLink => '复制链接';

  @override
  String get shareAnswerNote => '朋友会先看到问题，答案在卡片页面上，点一下就能看到。';

  @override
  String get shareWhichSide => '你站哪一边？';

  @override
  String get rereadRight => '第一次你答对了。';

  @override
  String get rereadWrong => '第一次你答错了。';

  @override
  String betsDayShareLine(int off) {
    String _temp0 = intl.Intl.pluralLogic(
      off,
      locale: localeName,
      other: '我差了 $off 个百分点',
      zero: '我正好猜中',
    );
    return '今天的 Astute 挑战：$_temp0。你能猜得更准吗？';
  }

  @override
  String get playTheCard => '玩这张卡片';

  @override
  String get openTheCard => '打开卡片';

  @override
  String get perkPathsTitle => '每条路径，完整开放';

  @override
  String get perkPathsLine => '同一主题的十张卡片，从最简单到最难。每周都有新路径。';

  @override
  String get journeyStrongest => '最擅长';

  @override
  String get journeyMostMissed => '最常答错';

  @override
  String journeyRightShare(String pct) {
    return '正确率 $pct';
  }

  @override
  String get journeyChangedMind => '改变了看法';

  @override
  String get journeyNewToYou => '新知';

  @override
  String journeyReactedOf(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '共$n张询问过的卡片',
    );
    return '$_temp0';
  }

  @override
  String journeyKnewAlready(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n张你早就知道',
    );
    return '$_temp0';
  }

  @override
  String get storyLabTitle => '你的旅程，像一个故事';

  @override
  String get storyLabNote => '新版本 · 测试中，仅限 TestFlight';

  @override
  String get storyChapterWeek => '本周';

  @override
  String get storyChapterWhere => '你在哪里';

  @override
  String get storyChapterReason => '你如何推理';

  @override
  String get storyChapterPractice => '练习';

  @override
  String get storyChapterStory => '你的故事';

  @override
  String get journeyChapterKnow => '你知道的';

  @override
  String get journeyChapterHabits => '你的习惯';

  @override
  String get journeyChapterCoach => '你的教练';

  @override
  String get coachTeaser => '每周，教练会就你的思考方式写一段话：哪里做得好，要留意的陷阱，接下来试试什么。';

  @override
  String get coachRead => '阅读本周的话';

  @override
  String storyHeadlineSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '在你有把握的回答里，10 次有 $n 次是对的。',
    );
    return '$_temp0';
  }

  @override
  String get storyBetter => '比上周更好。';

  @override
  String get storyWorse => '比上周略低。';

  @override
  String storyHeadlineStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '连续 $n 天。别断了这条线。',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineStrong(String subject, String pct) {
    return '在$subject方面，你的正确率是 $pct。';
  }

  @override
  String storyHeadlineRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已读 $n 张卡片。旅程从这里开始。',
      zero: '你的第一张卡片在等你。',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadWeek(int n, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      week,
      locale: localeName,
      other: '已读 $n 张卡片，本周 $week 张。',
      zero: '已读 $n 张卡片，本周还没有。',
    );
    return '$_temp0';
  }

  @override
  String storyHeadlineReadAllWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已读 $n 张卡片，全在本周。',
      one: '目前已读 1 张卡片。',
    );
    return '$_temp0';
  }

  @override
  String storySaidRight(String sure, String right) {
    return '你的把握：$sure。你的正确率：$right。';
  }

  @override
  String storySaidRightToGo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '再有 $n 个附带把握度的回答，就能测量了。',
    );
    return '$_temp0';
  }

  @override
  String storyOverconfident(String subject, int points) {
    return '你过于自信的地方：$subject，高出 $points 分。';
  }

  @override
  String get storyUnlock => '用 Astute+ 查看';

  @override
  String storyPracticeMisses(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '有把握却答错的 $n 张',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeChanged(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '改变了你看法的 $n 张',
    );
    return '$_temp0';
  }

  @override
  String storyPracticeBlind(String subject) {
    return '$subject的 5 张新卡片';
  }

  @override
  String get storyPracticeNone => '暂时没有可练习的：回答几张卡片后就会出现。';

  @override
  String get storyFirstCard => '第一张卡片';

  @override
  String storyReached(String level) {
    return '达成：$level';
  }

  @override
  String storyBestStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '最佳连续：$n 天',
    );
    return '$_temp0';
  }

  @override
  String storyCardsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已读 $n 张卡片',
    );
    return '$_temp0';
  }

  @override
  String get storyToday => '今天';

  @override
  String get storySeePath => '查看路径';

  @override
  String exploreFreshCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '顶部有 $n 张新卡片',
    );
    return '$_temp0';
  }

  @override
  String get exploreUpToDate => '你已看完：暂时没有新内容。';

  @override
  String get deeperTitle => '深入了解';

  @override
  String get deeperSimple => '简单解释一下';

  @override
  String get deeperWhy => '为什么重要';

  @override
  String get deeperSides => '正反两面';

  @override
  String get deeperExample => '一个日常例子';

  @override
  String get deeperQuiz => '用一个新情境考考我';

  @override
  String get deeperQuizRight => '答对了。';

  @override
  String get deeperQuizWrong => '不太对。';

  @override
  String get mathsDailySolve => '去解题';

  @override
  String get mathsDailySolved => '已解出';

  @override
  String get mathsDailyMissed => '这次没答对';

  @override
  String get mathsDailyTomorrow => '明天还有新题';

  @override
  String get mathsDailyAnother => '再来一道类似的';

  @override
  String goalShelf(String goal) {
    return '用得上：$goal';
  }

  @override
  String get goalDecide => '日常决定';

  @override
  String get goalPeople => '与人相处';

  @override
  String get goalBusiness => '工作与商业';

  @override
  String get goalMoney => '金钱与购物';

  @override
  String get goalHealth => '健康';

  @override
  String get goalDecideLine => '选择、风险与概率，不凭直觉。';

  @override
  String get goalNews => '新闻与社交媒体';

  @override
  String get goalNewsLine => '标题、统计和帖子：哪些站得住脚。';

  @override
  String get goalPeopleLine => '谁在试图说服你，以及如何让别人理解你。';

  @override
  String get goalBusinessLine => '谈判、激励，以及点子背后的数字。';

  @override
  String get goalMoneyLine => '价格、优惠、利息：交易里的陷阱。';

  @override
  String get goalHealthLine => '饮食、疗法与研究：证据怎么说。';

  @override
  String mathsDailyStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '连续$n天',
    );
    return '$_temp0';
  }

  @override
  String get deeperYourTake => '你的想法，分析一下';

  @override
  String get deeperYourTakeHint => '写下你的看法…';

  @override
  String get deeperAnalyse => '分析';

  @override
  String get deeperAsk => '就这张卡片提问';

  @override
  String get deeperAskHint => '你的问题…';

  @override
  String get deeperSend => '提问';

  @override
  String get deeperSource => '来源';

  @override
  String get deeperOpenSource => '打开原文';

  @override
  String get deeperAiNote => '由 AI 回答：可能出错。';

  @override
  String get deeperBusy => '思考中…';

  @override
  String get deeperTomorrow => '今天就到这里：明天继续。';

  @override
  String get deeperTryAgain => '没有送达。请稍后再试。';

  @override
  String get deeperUnavailable => '暂时无法使用。请稍后再试。';

  @override
  String newsOutlets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n家媒体',
    );
    return '$_temp0';
  }

  @override
  String newsHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n小时前',
      zero: '刚刚',
    );
    return '$_temp0';
  }

  @override
  String newsDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n天前',
      one: '昨天',
    );
    return '$_temp0';
  }

  @override
  String get newsWorld => '国际';

  @override
  String get newsKeyPoints => '要点';

  @override
  String get newsBehind => '新闻背后';

  @override
  String get newsMeansForYou => '这对你意味着什么';

  @override
  String get newsMeans => '这意味着什么';

  @override
  String get newsHappenedBefore => '以前也发生过';

  @override
  String get newsSources => '来源';

  @override
  String get newsMadeFrom => '由 Astute 根据这些报道撰写，并与报道逐一核对。';

  @override
  String get newsWhyItMatters => '为何重要';

  @override
  String get deeperDeclined => '这个问题无法回答。';

  @override
  String get deeperPlusOnly => '使用 Astute+';

  @override
  String get deeperSimpleLead => '把这张卡片的道理，讲给一个好奇的十岁孩子听。';

  @override
  String get deeperSidesLead => '双方最有力的理由，以及什么能让争论有定论。';

  @override
  String get deeperExampleLead => '平常一天里，这个道理冒出来的某个瞬间。';

  @override
  String get deeperQuizLead => '一个卡片没提到的情境：一道题，三个选项。';

  @override
  String get deeperYourTakeLead => '你的推理哪里站得住、哪里有漏洞，再给一个检验它的问题。';

  @override
  String get deeperAskLead => '这张卡片让你好奇的任何问题。';

  @override
  String get deeperSideA => '一方';

  @override
  String get deeperSideB => '另一方';

  @override
  String get deeperVersus => 'VS';

  @override
  String get deeperRetry => '重试';

  @override
  String get deeperSimpleGo => '讲给我听';

  @override
  String get deeperSidesGo => '看看正反两面';

  @override
  String get deeperExampleGo => '举个例子';

  @override
  String get deeperQuizGo => '考考我';

  @override
  String get bookOfTheWeek => '本周之书';

  @override
  String bookIdeas(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 个观点',
    );
    return '$_temp0';
  }

  @override
  String bookMoreTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '这本书还有 $n 个观点',
    );
    return '$_temp0';
  }

  @override
  String get bookMoreLine => '整本书在 Astute+ 中，每周还有一本免费。';

  @override
  String get bookMoreGo => '阅读整本书';

  @override
  String bookMinutes(int n) {
    return '$n 分钟';
  }

  @override
  String get bookStart => '开始阅读';

  @override
  String get bookContinue => '继续阅读';

  @override
  String get bookAgain => '再读一遍';

  @override
  String get bookTheIdeas => '观点';

  @override
  String get bookRecommendedBy => '推荐者';

  @override
  String get bookFreeThisWeek => '本周免费';

  @override
  String get booksSeeAll => '查看全部';

  @override
  String get booksLibraryTitle => '全部书籍';

  @override
  String get bookDoneTitle => '读完了';

  @override
  String bookDoneLine(int ideas, int minutes) {
    return '$ideas个核心观点，$minutes分钟。';
  }

  @override
  String bookDoneCount(int count) {
    return '已读完：$count本';
  }

  @override
  String get bookDoneNext => '下一本书';

  @override
  String get bookDoneGo => '打开';

  @override
  String bookRetold(String title, String author) {
    return '$author《$title》中的观点，由 Astute 用自己的话讲述。完整的书请到书店寻找。';
  }

  @override
  String get foundersTitle => '创始人读什么';

  @override
  String founderBookCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n 本书',
    );
    return '$_temp0';
  }

  @override
  String get founderTheirBooks => '推荐过的书';

  @override
  String founderRole(String id, String role) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'bill_gates': '微软联合创始人',
      'warren_buffett': '让伯克希尔·哈撒韦壮大的投资人',
      'mark_zuckerberg': 'Facebook 创始人',
      'charlie_munger': '沃伦·巴菲特在伯克希尔·哈撒韦的搭档',
      'marc_andreessen': '网景和安德森·霍洛维茨的联合创始人',
      'tobi_lutke': 'Shopify 创始人',
      'naval_ravikant': 'AngelList 联合创始人',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String founderWhere(String id, String where) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'gates_summer': 'GatesNotes，他的夏季书单',
      'berkshire_meeting': '伯克希尔·哈撒韦股东大会',
      'berkshire_letter': '他致伯克希尔·哈撒韦股东的信',
      'year_of_books': 'Facebook 上的“A Year of Books”',
      'publisher_praise': '他在出版社页面上的推荐语',
      'ferriss_five': 'The Tim Ferriss Show，他读过的五本最好的书之一',
      'other': '$where',
    });
    return '$_temp0';
  }

  @override
  String founderAbout(String name) {
    return '这些是$name公开推荐过的书，附有原话和说话的出处。$name与 Astute 没有任何关系。';
  }

  @override
  String founderPhoto(String author, String licence) {
    return '照片：$author，$licence，Wikimedia Commons，已裁剪';
  }

  @override
  String founderAlso(String names) {
    return '其他推荐者：$names';
  }

  @override
  String get firstCardTitle => '你的第一张卡片';

  @override
  String get firstCardSwipeOn => '滑动继续';

  @override
  String get trialOfferTitle => '试用全部 Astute+。';

  @override
  String get trialOfferMark => 'Astute+。';

  @override
  String get trialOfferLine => '无论怎么选，今天的五张卡片都在等你。';

  @override
  String get trialStepToday => '今天';

  @override
  String get trialStepTodayLine => '全部 Astute+ 即刻开放。不收取任何费用。';

  @override
  String trialStepDay(int day) {
    return '第 $day 天';
  }

  @override
  String trialStepReminderLine(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '我们会发通知提醒你：还剩 $days 天。',
    );
    return '$_temp0';
  }

  @override
  String get trialStepChargeLine => '每年自动续订。至少提前 24 小时取消，就不会扣费。';

  @override
  String get trialOfferStart => '开始免费试用';

  @override
  String get trialOfferFree => '继续免费使用';

  @override
  String get paywallStepFree => '全部免费';

  @override
  String get paywallStepRemind => '我们会提醒你';

  @override
  String get paywallChargedToday => '今天扣款 · 随时可取消';

  @override
  String paywallGoalTitle(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': '给想做出更好决定的人。',
      'money': '给在钱上不被忽悠的人。',
      'people': '给想读懂人的人。',
      'news': '给不被标题骗到的人。',
      'health': '给在健康上要证据的人。',
      'business': '给想在工作中看清楚的人。',
      'other': '给想看清楚的人。',
    });
    return '$_temp0';
  }

  @override
  String paywallGoalMark(String goal) {
    String _temp0 = intl.Intl.selectLogic(goal, {
      'decide': '更好决定',
      'money': '在钱上',
      'people': '读懂人',
      'news': '标题',
      'health': '证据',
      'business': '看清楚',
      'other': '看清楚',
    });
    return '$_temp0';
  }

  @override
  String paywallMadeLine(String subjects) {
    return '每天五张，来自$subjects，匹配你的水平。答错的会一再回来，直到你记住。你还会看到自己一周一周地变化。';
  }

  @override
  String subjectsTwo(String a, String b) {
    return '$a和$b';
  }

  @override
  String subjectsThree(String a, String b, String c) {
    return '$a、$b和$c';
  }

  @override
  String get firstWeekTitle => '你的第一周';

  @override
  String get firstMonthTitle => '你的第一个月';

  @override
  String firstOfferDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '阅读了 $n 天',
    );
    return '$_temp0';
  }

  @override
  String get firstWeekBest => '这一周的最佳卡片';

  @override
  String get firstMonthBest => '这个月的最佳卡片';

  @override
  String firstOfferBestWhy(String why) {
    String _temp0 = intl.Intl.selectLogic(why, {
      'said': '你把它讲给了别人。',
      'liked': '你喜欢这张卡片。',
      'saved': '你收藏了它。',
      'changed': '它改变了你的想法。',
      'other': '你留下了它。',
    });
    return '$_temp0';
  }

  @override
  String firstOfferTrialTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Astute+ 免费 $days 天',
    );
    return '$_temp0';
  }

  @override
  String get firstOfferPlusLine => '每天五张属于你的卡片，每条路径和每本书，还有你每周的数字。';

  @override
  String get firstOfferNotNow => '暂不';
}
