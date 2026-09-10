// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
    return '今日$word张 · 滑动回顾';
  }

  @override
  String weekLine(int days) {
    return '本周 · 7 天完成 $days 天';
  }

  @override
  String get tapToFlip => '点按翻面';

  @override
  String get shareThisCard => '分享这张卡片';

  @override
  String get removeFromSaved => '取消收藏';

  @override
  String get saveThisPill => '收藏这颗药丸';

  @override
  String get shareThisPill => '分享这颗药丸';

  @override
  String cardOf(int k, int n) {
    return '第 $k 张，共 $n 张';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h 小时 $m 分';
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
  String get fiveMore => '再来五张';

  @override
  String get unlockFiveExtra => '解锁额外五颗药丸';

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
  String get onesThatAskTheMost => '最爱发问的卡片';

  @override
  String get acrossEveryone => '来自所有人，而不只是你的组合';

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
  String get noPillsMatchFilter => '还没有药丸符合这个筛选。';

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
  String get signOutBody => '连续记录、收藏的药丸和记录会保留在账号里。此操作只会从这台设备上清除它们。';

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
  String get startOverBody => '清除这台设备上的一切——连续记录、收藏的药丸、回答、判断记录、主题和方案——并重新打开引导。';

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
  String get yourFivePillsBeforeCoffee => '第一杯咖啡之前，你的 5 颗药丸。';

  @override
  String get browserOnlySpeaksOpen => '浏览器只有打开时才能出声，所以这需要手机版。';

  @override
  String get nudgeOff => '提醒已关闭。';

  @override
  String nudgeOnEveryDayAt(String time) {
    return '提醒已开启，每天 $time。';
  }

  @override
  String get nudgeOnSystemSaidNo => '提醒已开启，但系统拒绝了。请在设置中允许 Astut 的通知。';

  @override
  String get nudgeOnNeedsPhone => '提醒已开启。送达需要手机版。';

  @override
  String get howMuchYouKnow => '你知道多少';

  @override
  String savedN(int n) {
    return '收藏 · $n';
  }

  @override
  String get manageSubscription => '管理订阅';

  @override
  String get howPillsAreWritten => '药丸是怎么写出来的';

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
  String get seeEveryPrincipleWithPlus => '用 Astut plus 查看每一条原则';

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
  String get measurementRunningPlus => '测量正在进行。Astut+ 会告诉你它朝哪个方向走。';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '免费 7 天';

  @override
  String get watchTheGapMove => '看着差距变化。';

  @override
  String get measurementFreeForever => '测量永远免费。Astut+ 告诉你它朝哪个方向走。';

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
      other: '颗已读',
      one: '颗已读',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '已读 $n 颗',
      one: '已读 1 颗',
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
  String get streakReset => '连续记录已重置';

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
      other: '有 $n 颗药丸未读',
      one: '有 1 颗药丸未读',
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
  String get whatYouAlready => '你已经';

  @override
  String get know => '知道的';

  @override
  String get knowIntro =>
      '你调得最高的主题。它改变的是一天在每个主题里向你要什么——扎实就多提问，好奇就多讲解——而不是你得到多少。';

  @override
  String get startWithMyFirstCards => '开始我的第一批卡片';

  @override
  String get skipForNow => '暂时跳过';

  @override
  String get levelCurious => '好奇';

  @override
  String get levelSome => '略懂';

  @override
  String get levelSolid => '扎实';

  @override
  String get save => '保存';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$total 个主题中有 $n 个在组合里';
  }

  @override
  String get yourSpace => '你的';

  @override
  String get mix => '组合';

  @override
  String get everythingIsInDrag => '全部都在。把主题往下拖会少看到它，拖到零则移除。';

  @override
  String get next => '下一步';

  @override
  String get whatShouldWeTalkAbout => '我们聊什么？';

  @override
  String get fivePillsADayPick => '每天五颗药丸，每天早上新写。选出你想放进组合的主题——以后可以更改。';

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
  String get tagline => '每天五件聪明事，随时可以拿来聊';

  @override
  String get introTopicsTitle => '十二个主题，五颗药丸';

  @override
  String get introTopicsLine => '每天早上新写，并与来源核对。';

  @override
  String get introQuestionTitle => '先问，再答';

  @override
  String get introQuestionLine => '每颗药丸都带着那句值得说出口的话。';

  @override
  String get introMixTitle => '组合由你决定';

  @override
  String get introMixLine => '调低一个主题就少看到它，关掉就不再出现。';

  @override
  String get introThirtyTitle => '每天三十秒';

  @override
  String get introThirtyLine => '一条通知，五张卡片，和一段你不想中断的连续记录。';

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
  String get barMoveCaps => '饭桌上的那句话';

  @override
  String get theBarMoveCaps => '饭桌上的那句话';

  @override
  String get dayStreakCaps => '天连续';

  @override
  String sourceLabel(String source) {
    return '来源 · $source';
  }

  @override
  String get perkRecordTitle => '你随时间变化的记录';

  @override
  String get perkRecordLine => '你的把握和你的正确率之间的差距，是否真的在缩小。';

  @override
  String get perkPrinciplesTitle => '你遇到过的每一条原则';

  @override
  String get perkPrinciplesLine => '不只是最弱的三条——全部，包括还没展示给你的情境。';

  @override
  String get perkFreezesTitle => '三次冻结，而不是一次';

  @override
  String get perkFreezesLine => '足够覆盖一个外出的周末。只能失去的连续记录，终究会断。';

  @override
  String get perkExtraTitle => '每天额外 5 颗药丸';

  @override
  String get perkExtraLine => '读完第一组的那一刻，第二组就会解锁。';

  @override
  String get perkArchiveTitle => '完整档案';

  @override
  String get perkArchiveLine => '你读过的每一颗药丸，可按主题搜索。';

  @override
  String get perkTopicsTitle => '自己选主题';

  @override
  String get perkTopicsLine => '把组合偏向你真正喜欢的内容。';

  @override
  String get plusIsActive => 'ASTUT+ 已激活';

  @override
  String tryFreeThen(String price, String suffix) {
    return '免费试用 7 天，之后 $price$suffix';
  }

  @override
  String get trialStartedNoPayment => '试用已开始。此版本未接入付款。';

  @override
  String get thatDidNotGoThrough => '没有成功。';

  @override
  String get plusIsBack => 'Astut+ 回来了。';

  @override
  String get nothingToRestore => '此账号没有可恢复的内容。';

  @override
  String get findOutIfBetter => '看看你是不是真的在进步。';

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
  String get everythingOpensNothingCharged => '全部开放。不收费。';

  @override
  String dayN(int n) {
    return '第 $n 天';
  }

  @override
  String get reminderTwoDaysBefore => '续订前两天会提醒你。';

  @override
  String get itRenewsUnlessCancelled => '除非你取消，否则会续订。随时都可以取消。';

  @override
  String get howTheFreeWeekWorks => '免费一周是怎么回事';

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
      other: '$n张卡片回来了 — 再答一次',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => '回来的卡片';

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
}
