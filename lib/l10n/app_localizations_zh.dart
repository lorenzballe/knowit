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
  String signInNotConnected(String provider) {
    return '$provider 登录尚未接入。你的卡片会保存在这台设备上。';
  }

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
  String dayRead(int n, String word) {
    return '第 $n 天 · 已读$word张';
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
  String cardOf(int k, int n) {
    return '第 $k 张，共 $n 张';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return '明天的五张将在 $when 后开启';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic 将开启明天的五张，还有 $when';
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
  String get deleteAccountBody =>
      '你的账号、它的备份以及好友能看到的看板将被永久删除，这台设备会从头开始。这不会取消 Astute+：订阅请在 App Store 设置中管理。';

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
  String get howStep2Title => '对照出处核查';

  @override
  String get howStep2Line => '每张卡片都注明出处，发布前还有第二个模型以批评者的眼光通读。站不住的内容会被删掉。';

  @override
  String get howStep3Title => '每天早上发五张';

  @override
  String get howStep3Line => '来自你选的主题，绝不重复你读过的卡片。';

  @override
  String get howStep4Title => '由读者守住真实';

  @override
  String get howStep4Line => '当足够多的读者认为一张卡片有误，它会停止发放，直到有人核查过。';

  @override
  String get howReportTitle => '发现错误了？';

  @override
  String get howReportLine => '点一下卡片出处旁边的小旗即可举报。';

  @override
  String get howFoot => '出处每月重新核查一次。';

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
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '你错过了\n$n 天。',
      one: '你错过了\n一天。',
    );
    return '$_temp0';
  }

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
  String get whileYouWereAway => '你离开的这段时间';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '有 $n 张卡片未读',
      one: '有 1 张卡片未读',
    );
    return '$_temp0';
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
  String get reminderAskYes => '提醒我';

  @override
  String get reminderAskNotNow => '暂不';

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
  String get everythingIsInDrag => '全部都在。把主题往下拖会少看到它，拖到零则移除。';

  @override
  String get next => '下一步';

  @override
  String get whatShouldWeTalkAbout => '我们聊什么？';

  @override
  String get fivePillsADayPick => '每天五张卡片，每天早上换新。选出你想放进组合的主题——以后可以更改。';

  @override
  String nSelected(int n) {
    return '已选 $n 个';
  }

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
  String get introTopicsTitle => '十九个主题，五张卡片';

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
  String get continueWithEmail => '使用邮箱继续';

  @override
  String get termsLine => '注册即表示你同意我们的服务条款和隐私政策';

  @override
  String get skip => '跳过';

  @override
  String get tapToRevealLower => '点按揭晓';

  @override
  String get barMoveCaps => '值得记住';

  @override
  String get theBarMoveCaps => '饭桌上的那句话';

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
  String get perkArchiveTitle => '你的全部档案';

  @override
  String get perkArchiveLine => '你读过的每一天，永久保存。';

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
  String get noChargeTodayCancel => '今天不扣款 · 随时可取消';

  @override
  String get chargedTodayCancel => '今天扣款 · 随时可取消';

  @override
  String get everyCardForYouMark => '你';

  @override
  String get trialStartedNoPayment => '试用已开始。此版本未接入付款。';

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
  String get cancelAnyTimeNoPayment => '随时可取消 · 此版本不会扣款';

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
  String closeEnoughItIs(String answer) {
    return '够接近 · 答案是 $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return '你说 $given · 答案是 $answer，$band 之内算对';
  }

  @override
  String get youGotIt => '答对了';

  @override
  String youSaidItIs(String given, String answer) {
    return '你说 $given · 答案是 $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => '几乎所有人都会答错';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · 你说有 $pct% 的把握';
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
  String get thatWasTheOnlyOne => '只有这一张';

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
  String get fiveADayALittleSharper => '每天五张，更敏锐一点。';

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
  String get friends => '朋友';

  @override
  String friendsN(int n) {
    return '朋友 · $n';
  }

  @override
  String get yourFriendCode => '你的好友码';

  @override
  String get codeCopied => '已复制代码。';

  @override
  String get addAFriend => '添加朋友';

  @override
  String get theirCode => '对方的代码';

  @override
  String get add => '添加';

  @override
  String get noFriendsYet => '还没有人。和朋友交换代码，比较连续天数和自信校准 — 永远不会看到答案。';

  @override
  String get friendsNeedAnAccount => '比较需要手机应用和账户。你的代码会被保留。';

  @override
  String get noReaderWithCode => '没有使用该代码的读者。';

  @override
  String get thatsYourOwnCode => '这是你自己的代码。';

  @override
  String pointsOff(int n) {
    return '偏差$n分';
  }

  @override
  String get notMeasuredYet => '尚未测量';

  @override
  String get thisWeekByCalibration => '本周，按校准排序';

  @override
  String get notYetToday => '今天还没有';

  @override
  String nOfSeven(int n) {
    return '7天中$n天';
  }

  @override
  String get you => '你';

  @override
  String get todaysQuestion => '今日一题';

  @override
  String get right => '答对';

  @override
  String get wrong => '答错';

  @override
  String rightAtSure(int sure) {
    return '答对，自信度$sure%';
  }

  @override
  String wrongAtSure(int sure) {
    return '答错，自信度$sure%';
  }

  @override
  String get yourJourney => '你的旅程';

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
  String get yourMix => '你的组合';

  @override
  String get genresLine => '点一下跳过某个类别。长按，里面的三条线索就在下面展开。';

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
  String get magicLine => '每天五张为你挑选的卡片：来自你的组合，匹配你的水平，绝不重复已读。明天开始。';

  @override
  String get everyCardForYou => '每一张卡片，都为你而选。';

  @override
  String get perkOwnTitle => '每天五张，全部为你';

  @override
  String get perkOwnLine => '来自你选的分支，按你的水平，绝不重复已读。免费版每天两张。';

  @override
  String get plusCardHeadline => '让五张全都为你。';

  @override
  String get plusCardLine => '每天五张来自你的组合、匹配你的水平。你的旅程。你的全部档案。';

  @override
  String get continueFree => '免费继续';

  @override
  String get archiveBeforeThisWeek => '本周之前的一切';

  @override
  String get weekKeptThreeOwn => '坚持了一周：明天五张里有三张是你的。';

  @override
  String get perkJourneyLine => '你的等级、逐个分支的每个学科、你记住了什么，以及你一再错过的招。';

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
  String get topEmpty => '榜单还是空的。你喜欢、收藏或讲给别人听的每张卡片都会计入。';

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
  String get weekRecapCaps => '这周你问过自己';

  @override
  String get weekRecapLine => '你的卡片留给你的问题';

  @override
  String weekRecapMore(int n) {
    return '用 Plus 再看本周 $n 条';
  }

  @override
  String get plusInTheApp =>
      'Astute+ 在应用中提供：在 iPhone 或 Android 上下载 Astute，开始免费试用。';

  @override
  String get purchaseComplete => '购买成功。';

  @override
  String get successWelcome => '欢迎加入 Astute+。今天的五张卡片已经准备好了。';

  @override
  String successWelcomeNamed(String name) {
    return '欢迎加入 Astute+，$name。今天的五张卡片已经准备好了。';
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
  String get journeyTimedFromToday => '从今天开始计时';

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
  String get journeySureNone => '还没有 80% 及以上的回答';

  @override
  String get journeyMovesTitle => '能识破的套路';

  @override
  String journeyOfN(int n) {
    return '/ $n';
  }

  @override
  String journeyNewest(String name) {
    return '最新：$name';
  }

  @override
  String get journeyNoneYet => '还没有';

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
  String get journeyNothingDated => '还没有带年代的卡片';

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
  String get journeyNoPlace => '还没有地点';

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
  String get corrections => '更正';

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
  String get editionEnd => '今天这一期就到这里';

  @override
  String get editionTomorrow => '明天的一期早上发布';

  @override
  String get eraAncient => '古代世界';

  @override
  String get eraAncientWhen => '公元500年以前';

  @override
  String get eraEarlyModern => '近代早期';

  @override
  String get eraEarlyModernWhen => '1500年至1800年';

  @override
  String get eraMedieval => '中世纪';

  @override
  String get eraMedievalWhen => '500年至1500年';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '这个时代还有 $n 张',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => '19世纪';

  @override
  String get eraNineteenthWhen => '1800年至1900年';

  @override
  String get eraRecent => '本世纪';

  @override
  String get eraRecentWhen => '2000年以来';

  @override
  String get eraRulerNow => '现在';

  @override
  String get eraRulerOld => '古代';

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
  String get eraTwentieth => '上个世纪';

  @override
  String get eraTwentiethWhen => '1900年至2000年';

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
  String get inNumbers => '数字看点';

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
  String get moveComparedToWhat => '和什么比？';

  @override
  String get moveComparedToWhatLine => '没有可以比较的东西，变化说明不了什么';

  @override
  String get askingTitle => '每个主题一道题';

  @override
  String askingIn(String subject) {
    return '$subject的题目';
  }

  @override
  String get askingLine => '人人相同。先作答，再看原因';

  @override
  String get moveSampling => '谁被算进去了？';

  @override
  String get moveSamplingLine => '研究里有谁，决定了它能告诉你什么';

  @override
  String mythDeckHint(int at, int of) {
    return '第 $at/$of 张 · 滑动翻过';
  }

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
  String get puzzleOfTheDay => '今日谜题';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts 分';
  }

  @override
  String get rightLastTime => '上次答对了';

  @override
  String get sameForEveryoneCaps => '人人相同';

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
  String get theAstute => 'The Astute';

  @override
  String get theLead => '头条';

  @override
  String get throughTime => '穿越时间';

  @override
  String get throughTimeLine => '从古代到今年，拖动，或输入一个年份';

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
  String get spotLine => '三条是真的，一条不是。';

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
  String get yearHint => '输入年份';

  @override
  String get yearAd => '公元';

  @override
  String get yearBc => '公元前';

  @override
  String yearNamed(String year) {
    return '$year年';
  }

  @override
  String yearAdOf(String year) {
    return '公元$year年';
  }

  @override
  String yearBcOf(String year) {
    return '公元前$year年';
  }

  @override
  String get yearGo => '前往这一年';

  @override
  String yearNearest(String year) {
    return '离$year最近的在前';
  }

  @override
  String yearNoneNamed(String year) {
    return '这里没有卡片提到$year附近的年份。这些来自同一时代。';
  }

  @override
  String yearNoAge(String year) {
    return '今天没有$year前后的卡片。这是最近的时代。';
  }

  @override
  String yearFuture(String year) {
    return '$year还没到来。这是本世纪。';
  }

  @override
  String get yearZero => '没有公元0年。试试公元前1年或公元1年。';

  @override
  String get todayLabel => '今天';

  @override
  String get todaysEdition => '今日版';

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
}
