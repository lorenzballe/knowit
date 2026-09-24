// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => '今日';

  @override
  String get tabExplore => '探す';

  @override
  String get tabProfile => 'プロフィール';

  @override
  String signInNotConnected(String provider) {
    return '$providerでのログインはまだ接続されていません。カードはこの端末に保存されます。';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return '$labelでログインできませんでした。アカウントなしで続けられます。';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n日',
      one: '1日',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'フリーズが連続記録を守りました';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': '1',
      '2': '2',
      '3': '3',
      '4': '4',
      '5': '5',
      '6': '6',
      '7': '7',
      '8': '8',
      '9': '9',
      '10': '10',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return '$n日目 · $word枚読了';
  }

  @override
  String shelfEyebrow(String word) {
    return '今日の$word枚';
  }

  @override
  String get tapToFlip => 'タップでめくる';

  @override
  String get shareThisCard => 'このカードを共有';

  @override
  String get removeFromSaved => '保存から外す';

  @override
  String get saveThisPill => 'このピルを保存';

  @override
  String get shareThisPill => 'このピルを共有';

  @override
  String cardOf(int k, int n) {
    return '$n枚中$k枚目';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h時間$m分';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return '明日の5枚は$when後に開きます';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topicが明日の5枚を開きます。$when後';
  }

  @override
  String get exploreTodaysBest => '今日のベストを見る';

  @override
  String get magicUnlock => '7日間無料で試す';

  @override
  String nothingInYet(String subject) {
    return '$subjectにはまだ何もありません。';
  }

  @override
  String get here => 'このセクション';

  @override
  String get todaysShelf => '今日の棚';

  @override
  String get sameForEveryone => 'みんな同じ、今日だけ';

  @override
  String get onesThatAskTheMost => 'いちばん問いかけてくるカード';

  @override
  String get acrossEveryone => 'あなたのミックスだけでなく、全員の中で';

  @override
  String becauseSitsAtFull(String name) {
    return '$nameが最大だから';
  }

  @override
  String get olderFromTurnedUp => 'あなたが上げた分野の古いカード';

  @override
  String moreOn(String name) {
    return '$nameをもっと';
  }

  @override
  String get subjectReadMost => 'いちばん読んだ分野';

  @override
  String monthOf(String name) {
    return '$nameのひと月';
  }

  @override
  String get somewhereToStart => '今日ではない出発点';

  @override
  String get searchEveryCard => 'すべてのカードを検索';

  @override
  String nothingForYet(String query) {
    return '「$query」に該当するものはまだありません。';
  }

  @override
  String matching(int n) {
    return '$n件';
  }

  @override
  String get all => 'すべて';

  @override
  String get theArchive => 'アーカイブ';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n件',
      one: '1件',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n枚のカード。日付をタップで開きます。';
  }

  @override
  String get whatYouHaveCovered => 'これまでに読んだ範囲';

  @override
  String searchNCards(int n) {
    return '$n枚から検索';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚',
      one: '1枚',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '昨日';

  @override
  String get noPillsMatchFilter => 'この絞り込みに合うピルはまだありません。';

  @override
  String nothingForTryTopic(String query) {
    return '「$query」は見つかりません。分野で試してみてください。';
  }

  @override
  String get saved => '保存済み';

  @override
  String get removedFromSaved => '保存から外しました。';

  @override
  String get undo => '元に戻す';

  @override
  String get nothingKeptYet => 'まだ何も保存していません';

  @override
  String nInTopic(int n, String topic) {
    return '$topicに$n枚';
  }

  @override
  String get keepTheOnesYoullUse => '本当に使うものだけを残す';

  @override
  String get backToTodaysFive => '今日の5枚に戻る';

  @override
  String get archive => 'アーカイブ';

  @override
  String get yourWeek => '今週のあなた';

  @override
  String get nothingThisWeekYet => '今週はまだ何もありません。5枚で始まります。';

  @override
  String keptDaysOfSeven(int days) {
    return '達成 — 7日中$days日。';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '7日中$days日。',
      one: '7日中1日。',
    );
    return '${_temp0}5日で今週は達成です。';
  }

  @override
  String get howSureAgainstHowRight => '自信の高さと、正解率';

  @override
  String get sureAndWrong => '自信があって、間違えた';

  @override
  String get worthGoingBackTo =>
      '見直す価値のあるカード。自信があったことを間違えるのは、自分が本当に何を信じているかを知る唯一の安上がりな方法です。';

  @override
  String get whereThisIsGoing => 'この先';

  @override
  String ofNRight(int n) {
    return '$n問中正解';
  }

  @override
  String get sayHowSureOnMore => 'あと数問、自信の度合いを答えると、その自信にどれだけの価値があるかアプリが教えます。';

  @override
  String confidenceOff(int gap) {
    return 'あなたの自信は、実際に知っていたことから$gapポイントずれていました。';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return '自信のずれは$gapポイント、先週は$before。差は縮まっています。';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return '自信のずれは$gapポイント、先週は$before。差は広がりました。';
  }

  @override
  String nextRung(String name) {
    return '次：$name';
  }

  @override
  String youSaidPercentSure(int n) {
    return '自信$n%と答えた';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': '1日目',
      'reading': '読む',
      'answering': '答える',
      'saying_how_sure': '自信を言う',
      'calibrated': '較正済み',
      'holding': '定着',
      'sharp': '鋭い',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': '誰もがここから始めます。',
      'reading': '習慣が始まりました。',
      'answering': 'カードをめくる前に答えを決めています。',
      'saying_how_sure': '知っていると思うことに数字をつけています。',
      'calibrated': '知っていると言うことを、本当に知っています。',
      'holding': '数週間たっても残っています。',
      'sharp': '必要なときに自信を持ち、自信のあるときに正しい。',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return 'あと$n枚読む';
  }

  @override
  String stepAnswer(int n) {
    return 'あと$n枚答える';
  }

  @override
  String stepJudge(int n) {
    return 'あと$n回、自信の度合いを添えて答える';
  }

  @override
  String stepHold(int n) {
    return 'あと$n枚定着させる';
  }

  @override
  String stepGap(int gap, int target) {
    return '自信のずれは$gapポイント — $targetまで縮めれば到達';
  }

  @override
  String stepBeforeJudged(int n) {
    return 'アプリが自信を判定するまで、あと$n回の回答';
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
  String get signOutQuestion => 'ログアウトしますか？';

  @override
  String get signOutBody => '連続記録、保存したピル、記録はアカウントに残ります。この端末からは消去されます。';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deletingAccount => 'アカウントを削除しています…';

  @override
  String get deleteAccountQuestion => 'アカウントを削除しますか？';

  @override
  String get deleteAccountBody =>
      'アカウントとそのバックアップ、友達に見えるボードが完全に削除され、この端末は最初からやり直しになります。Astute+ は解約されません。サブスクリプションは App Store の設定で管理してください。';

  @override
  String get deleteAccountConfirm => '完全に削除';

  @override
  String get accountDeleted => 'アカウントを削除しました。';

  @override
  String get couldNotDeleteAccount => 'アカウントを削除できませんでした。少し待ってからもう一度お試しください。';

  @override
  String get signOut => 'ログアウト';

  @override
  String get signedInRecordOnAccount => 'ログインしました。連続記録と記録はアカウントに保存されています。';

  @override
  String couldNotSignInWith(String label) {
    return '$labelでログインできませんでした。';
  }

  @override
  String get signInNotAvailableBuild => 'このビルドではログインできません。';

  @override
  String get startOverQuestion => '最初からやり直しますか？';

  @override
  String get startOverBody =>
      'この端末のすべて（連続記録、保存したピル、回答、判断の記録、分野、プラン）を消去し、イントロを再表示します。';

  @override
  String get wipeIt => '消去';

  @override
  String get yourRecord => 'あなたの記録';

  @override
  String get appearance => '外観';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSystem => 'システム';

  @override
  String get yourTopics => 'あなたの分野';

  @override
  String get edit => '編集';

  @override
  String get howWellYouKnowYourself => '自分をどれだけ知っているか';

  @override
  String get isTheGapClosing => '差は縮まっている？';

  @override
  String get movesYouKeepMissing => '何度も見逃している手';

  @override
  String get dailyNudge => '毎日の通知';

  @override
  String everyDayAt(String time) {
    return '毎日$time';
  }

  @override
  String get yourFivePillsBeforeCoffee => '最初のコーヒーの前に、5枚のピルを。';

  @override
  String get browserOnlySpeaksOpen => 'ブラウザは開いている間しか話せないので、これにはスマホ版が必要です。';

  @override
  String get nudgeOff => '通知オフ。';

  @override
  String nudgeOnEveryDayAt(String time) {
    return '通知オン、毎日$time。';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      '通知はオンですが、システムに拒否されました。設定でAstuteの通知を許可してください。';

  @override
  String get nudgeOnNeedsPhone => '通知オン。届けるにはスマホ版が必要です。';

  @override
  String savedN(int n) {
    return '保存済み · $n';
  }

  @override
  String get manageSubscription => 'サブスクリプションを管理';

  @override
  String get howPillsAreWritten => 'ピルの作り方';

  @override
  String get signingIn => 'ログイン中…';

  @override
  String get signInWithApple => 'Appleでログイン';

  @override
  String get signInWithGoogle => 'Googleでログイン';

  @override
  String acrossNAnswersHowSure(int n) {
    return '$n回の回答で自信の度合いを答えました。結果はこうでした。';
  }

  @override
  String get perfectlyCalibratedLine => '完璧に較正された人は、「70%」と言ったときに70%の確率で正解します。';

  @override
  String get notEnoughAnswersYet => 'まだ回答が足りません';

  @override
  String get confidenceMatchesAccuracy => '自信と正解率が一致しています';

  @override
  String overconfidentBy(int points) {
    return '$pointsポイント自信過剰です';
  }

  @override
  String underconfidentBy(int points) {
    return '$pointsポイント自信不足です';
  }

  @override
  String saidPercent(int n) {
    return '回答$n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return '正解$pct%（$count問中$right問）';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'この文脈があと$nつ',
      one: 'この文脈があと1つ',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Astute plusですべての原則を見る';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$nつ追跡中',
      one: 'あと1つ追跡中',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => '記録を共有';

  @override
  String lastCallsAgainstFirst(int n) {
    return '最近$n回の判断と、最初の$n回';
  }

  @override
  String closedByPoints(int n) {
    return '$nポイント縮小';
  }

  @override
  String openedByPoints(int n) {
    return '$nポイント拡大';
  }

  @override
  String get holdingSteady => '横ばい';

  @override
  String get measurementRunningPlus => '計測は進行中です。Astute+がどちらに向かっているかを示します。';

  @override
  String firstN(int n) {
    return '最初の$n回';
  }

  @override
  String lastN(int n) {
    return '最近の$n回';
  }

  @override
  String get trackingMoreClosely => '自信が以前より正解率に近づいています。';

  @override
  String get distanceHasGrown => '差が広がりました。答える前に少しゆっくり考える価値があります。';

  @override
  String get noRealMovementYet => 'まだ目立った変化はありません。数日ではなく数週間かかります。';

  @override
  String get seeWhichWay => '方向を見る';

  @override
  String get spotOn => 'ぴったり';

  @override
  String pointsOver(int n) {
    return '$n上';
  }

  @override
  String pointsUnder(int n) {
    return '$n下';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String get sevenDaysFree => '7日間無料';

  @override
  String get seeThePlans => 'プランを見る';

  @override
  String get recordStartsToday => 'あなたの記録は今日から始まります。';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '日',
      one: '日',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '枚読了',
      one: '枚読了',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚読了',
      one: '1枚読了',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n週達成',
      one: '1週達成',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n枚が再登場';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'フリーズ$n個',
      one: 'フリーズ1個',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => '無料プラン';

  @override
  String get streakReset => '連続記録リセット';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n日\n空きました。',
      one: '1日\n空きました。',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n日',
      one: '1日',
    );
    return '$_temp0が今も最高記録です。今日の5枚を読めば、カウンターは1から再開します。';
  }

  @override
  String get whileYouWereAway => '離れている間に';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚が未読のまま',
      one: '1枚が未読のまま',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topicは今も、いちばん保存している分野です';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '正解したカード$n枚が今日戻ってきます',
      one: '正解したカード1枚が今日戻ってきます',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => '今日の5枚から再開';

  @override
  String moveMyReminderTo(String time) {
    return '通知を$timeに変更';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return '毎日の通知を$timeに変更しました。';
  }

  @override
  String subjectsInTheMix(int n, int total) {
    return '$total分野中$n分野がミックスに';
  }

  @override
  String get everythingIsInDrag => 'すべて入っています。分野を下にドラッグすると減り、ゼロまで下げると外れます。';

  @override
  String get next => '次へ';

  @override
  String get whatShouldWeTalkAbout => '何について話しますか？';

  @override
  String get fivePillsADayPick =>
      '1日5枚のピルを、毎朝新しく。ミックスに入れる分野を選んでください — あとで変えられます。';

  @override
  String nSelected(int n) {
    return '$n件選択';
  }

  @override
  String startWithNTopics(int n) {
    return '$n分野で始める';
  }

  @override
  String saveNTopics(int n) {
    return '$n分野を保存';
  }

  @override
  String pickAtLeastN(int n) {
    return '$nつ以上選んでください';
  }

  @override
  String get swipeToSeeMore => 'スワイプして続きを見る';

  @override
  String get tagline => '1日5つの賢い話題。会話でそのまま使えます';

  @override
  String get introTopicsTitle => '18の分野、5枚のピル';

  @override
  String get introTopicsLine => '毎朝新しく書かれ、出典と照合されます。';

  @override
  String get introQuestionTitle => '問いがあって、答えがある';

  @override
  String get introQuestionLine => 'どのピルにも、声に出す価値のあるひと言が入っています。';

  @override
  String get introMixTitle => 'ミックスはあなたが決める';

  @override
  String get introMixLine => '分野を下げれば減り、切ればなくなります。';

  @override
  String get introThirtyTitle => '1日30秒';

  @override
  String get introThirtyLine => '通知が1つ、カードが5枚、そして途切れさせたくない連続記録。';

  @override
  String get continueWithApple => 'Appleで続ける';

  @override
  String get continueWithGoogle => 'Googleで続ける';

  @override
  String get continueWithEmail => 'メールで続ける';

  @override
  String get termsLine => '登録すると利用規約とプライバシーポリシーに同意したことになります';

  @override
  String get skip => 'スキップ';

  @override
  String get tapToRevealLower => 'タップで表示';

  @override
  String get barMoveCaps => '会話のひと言';

  @override
  String get theBarMoveCaps => '会話のひと言';

  @override
  String get widgetFootPlain => '5枚のカード、2分。';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n日連続',
      one: '1日連続',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => '今日は完了';

  @override
  String get widgetStreakStart => '今日の5枚を読んで連続記録を始めよう。';

  @override
  String get widgetFiveTitle => '今日の5枚';

  @override
  String widgetFiveRead(int n) {
    return '5枚中$n枚読了';
  }

  @override
  String get widgetFiveDone => '5枚すべて読了';

  @override
  String get widgetFiveWaiting => '新しい5枚が待っています';

  @override
  String get dayStreakCaps => '日連続';

  @override
  String sourceLabel(String source) {
    return '出典 · $source';
  }

  @override
  String get perkArchiveTitle => 'あなたのアーカイブすべて';

  @override
  String get perkArchiveLine => '読んだ日をすべて、ずっと保存。無料版は1週間。';

  @override
  String get plusIsActive => 'ASTUTE+ 有効';

  @override
  String tryFreeThen(String price, String suffix) {
    return '7日間無料で試す。その後$price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return '$price$suffixで登録';
  }

  @override
  String get noChargeTodayCancel => '今日は請求なし · いつでもキャンセル可能';

  @override
  String get chargedTodayCancel => '今日請求されます · いつでもキャンセル可能';

  @override
  String get everyCardForYouMark => 'あなた';

  @override
  String get trialStartedNoPayment => 'トライアル開始。このビルドでは支払いは接続されていません。';

  @override
  String get thatDidNotGoThrough => '処理できませんでした。';

  @override
  String get plusIsBack => 'Astute+が戻りました。';

  @override
  String get nothingToRestore => 'このアカウントに復元するものはありません。';

  @override
  String get planYearly => '年額';

  @override
  String get planMonthly => '月額';

  @override
  String get perYearShort => '/年';

  @override
  String get perMonthShort => '/月';

  @override
  String get perYear => '/年';

  @override
  String aMonth(String price) {
    return '月あたり$price';
  }

  @override
  String savePercent(int n) {
    return '$n%お得';
  }

  @override
  String get perMonth => '/月';

  @override
  String get billedMonthly => '毎月請求';

  @override
  String get cancelTheTrial => 'トライアルをキャンセル';

  @override
  String get cancelAnyTime => 'いつでもキャンセル可能';

  @override
  String get cancelAnyTimeNoPayment => 'いつでもキャンセル可能 · このビルドでは請求されません';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get termsOfUse => '利用規約';

  @override
  String get privacyPolicy => 'プライバシー';

  @override
  String planPrice(String label, String price, String per) {
    return '$label、$price $per';
  }

  @override
  String get pickASideNoRightAnswer => 'どちらかを選んでください。正解はありません。';

  @override
  String get estimateCloseEnough => '見積もってください。近ければ正解です。';

  @override
  String get tapToReveal => 'タップで表示';

  @override
  String closeEnoughItIs(String answer) {
    return '惜しい · 正解は$answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'あなたの答え$given · 正解は$answer、$bandは正解扱い';
  }

  @override
  String get youGotIt => '正解';

  @override
  String youSaidItIs(String given, String answer) {
    return 'あなたの答え$given · 正解は$answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'ほとんどの人が間違えます';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · 自信$pct%と答えた';
  }

  @override
  String get giveMeANudge => 'ヒントをください';

  @override
  String get beingRightMattersLess => '正解することより、どれくらい正解するかを知ることのほうが大事です。';

  @override
  String get writeItBeforeTheirs => '相手の答えを読む前に書いてください。';

  @override
  String get youAnsweredThisOne => 'これは回答済みです。';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'やさしい',
      'medium': 'ふつう',
      'hard': 'むずかしい',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · めくる前に答えを決めてください。';
  }

  @override
  String get yourAnswer => 'あなたの答え';

  @override
  String get checkMyAnswer => '答え合わせ';

  @override
  String get howSureAreYou => 'どのくらい自信がありますか？';

  @override
  String percentSure(int n) {
    return '自信$n%';
  }

  @override
  String get inOneLineWhy => 'ひと言で — なぜ？';

  @override
  String get because => 'なぜなら…';

  @override
  String get nowShowMeTheOtherSide => '反対側を見る';

  @override
  String get skipShowMeAnyway => 'スキップ — そのまま見る';

  @override
  String get youTookCaps => 'あなたの選択';

  @override
  String get putSimplyCaps => 'かんたんに言うと';

  @override
  String get explainLikeImThree => '子どもにもわかるように';

  @override
  String get whatTheOtherSideSaysCaps => '反対側の言い分';

  @override
  String get whatTheOtherSideSays => '反対側の言い分';

  @override
  String theTrap(String trap) {
    return '落とし穴：$trap';
  }

  @override
  String youTookTheSide(String side) {
    return '選んだ側：$side';
  }

  @override
  String atPercentSure(int n) {
    return '（自信$n%）';
  }

  @override
  String youGotThisOne(String sure) {
    return 'これは正解$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'あなたの答え：$answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'スワイプで次へ';

  @override
  String get thatWasTheOnlyOne => 'これが最後の1枚でした';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'カードを描画できませんでした。';

  @override
  String get textCopiedInstead => '代わりにテキストをコピーしました。';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました。';

  @override
  String get rendering => '描画中…';

  @override
  String get theSourceGoesWithIt => '出典も一緒に';

  @override
  String get fiveADayALittleSharper => '1日5枚。少しだけ鋭く。';

  @override
  String get shareMyDay => 'シェア';

  @override
  String climbedTo(String rung) {
    return '今日で$rungに上がりました';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$asked問中$right問正解';
  }

  @override
  String saidSure(int sure) {
    return '確信度$sure%';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚のカードが戻ってきました — もう一度答えましょう',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => '戻ってきたカード';

  @override
  String get holdACardYouLike => '気に入ったら長押し';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今日$n枚にいいね',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'いいね';

  @override
  String likedN(int n) {
    return 'いいね · $n';
  }

  @override
  String get nothingLikedYet => 'まだいいねはありません';

  @override
  String get likeThisPill => 'このカードにいいね';

  @override
  String get removeFromLiked => 'いいねを外す';

  @override
  String get removedFromLiked => 'いいねを外しました。';

  @override
  String get lessLikeThis => 'こういうのは少なめに';

  @override
  String get whatYouLikedLandsHere => 'もう一度読みたいカード';

  @override
  String get holdToLikeLandsHere => '気に入ったカードを長押しするとここに集まり、同じようなカードが増えます。';

  @override
  String get tapTheBookmarkLandsHere =>
      'カードのブックマークを押すとここに集まります — 考え方を変えたカードを、手元に。';

  @override
  String get nudgeTitle => '今日の5枚が届いています';

  @override
  String get nudgeFreezeTitle => 'フリーズが効いています';

  @override
  String nudgeFreezeBody(String question) {
    return '昨日はカバーされました。今日：$question';
  }

  @override
  String get nudgeSureTitle => 'これには自信がありましたね';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — $sure%と答えました。';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return '2週間前、$read枚読んでいました';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return '自信は$gapポイントずれていました。今日：$question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return 'これまで$answered問回答。今日：$question';
  }

  @override
  String get friends => '友だち';

  @override
  String friendsN(int n) {
    return '友だち · $n';
  }

  @override
  String get yourFriendCode => 'あなたの友だちコード';

  @override
  String get codeCopied => 'コードをコピーしました。';

  @override
  String get addAFriend => '友だちを追加';

  @override
  String get theirCode => '相手のコード';

  @override
  String get add => '追加';

  @override
  String get noFriendsYet =>
      'まだ誰もいません。友だちとコードを交換して、連続日数と確信度の精度を比べましょう — 答えは決して見えません。';

  @override
  String get friendsNeedAnAccount => '比べるにはスマホ版アプリとアカウントが必要です。コードは保存されています。';

  @override
  String get noReaderWithCode => 'そのコードの読者はいません。';

  @override
  String get thatsYourOwnCode => 'それはあなた自身のコードです。';

  @override
  String pointsOff(int n) {
    return '$nポイントのずれ';
  }

  @override
  String get notMeasuredYet => 'まだ測定されていません';

  @override
  String get thisWeekByCalibration => '今週、確信度の精度順';

  @override
  String get notYetToday => '今日はまだ';

  @override
  String nOfSeven(int n) {
    return '7日中$n日';
  }

  @override
  String get you => 'あなた';

  @override
  String get todaysQuestion => '今日の問題';

  @override
  String get right => '正解';

  @override
  String get wrong => '不正解';

  @override
  String rightAtSure(int sure) {
    return '正解、確信度$sure%';
  }

  @override
  String wrongAtSure(int sure) {
    return '不正解、確信度$sure%';
  }

  @override
  String get yourJourney => 'あなたの旅';

  @override
  String get thePath => '道のり';

  @override
  String get youAreHere => '現在地';

  @override
  String reachedOn(String date) {
    return '$dateに到達';
  }

  @override
  String readSoFar(int n, int of) {
    return 'これまで$of枚中$n枚';
  }

  @override
  String nRead(int n) {
    return '$n枚';
  }

  @override
  String levelNamed(int n, String name) {
    return 'レベル$n · $name';
  }

  @override
  String get topLevel => '最上位';

  @override
  String plusNToday(int n) {
    return '今日 +$n';
  }

  @override
  String stillWithYouOf(int n, int total) {
    return 'まだ覚えている · $total枚中$n枚';
  }

  @override
  String get stillWithYouNothing => 'まだ覚えている · 未回答';

  @override
  String get calibrationPointsOff => '確信度 · ポイントのずれ';

  @override
  String get calibrationNotMeasured => '確信度 · 未測定';

  @override
  String inARowBest(int n) {
    return '連続 · 最高$n日';
  }

  @override
  String movesYouCanSpot(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '見抜ける型$n個',
    );
    return '$_temp0';
  }

  @override
  String nCardsIsAbout(int n) {
    return '$n枚はおよそ';
  }

  @override
  String nonFictionBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '冊のノンフィクション',
    );
    return '$_temp0';
  }

  @override
  String hoursOfDocumentaries(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '時間のドキュメンタリー',
    );
    return '$_temp0';
  }

  @override
  String lectures(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '回の講義');
    return '$_temp0';
  }

  @override
  String inTotalACard(String time) {
    return '合計$time · 1枚およそ40秒';
  }

  @override
  String get bySubject => '分野別';

  @override
  String get readOfTheShelf => '読了 · 棚のうち';

  @override
  String get toSayTonight => '今夜話すなら';

  @override
  String get anotherOne => '別のを';

  @override
  String get saidIt => '話した';

  @override
  String get saidAlready => '話した';

  @override
  String justMinutes(int m) {
    return '$m分';
  }

  @override
  String get pts => 'ポイント';

  @override
  String nStillWithYou(int n) {
    return '$n枚がまだ記憶に';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '型$n個');
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'スコアは今日の5枚から始まります。';

  @override
  String get anonymousUsage => '匿名の利用状況';

  @override
  String get anonymousUsageLine =>
      '読まれた・保存された・話されたカードの数だけ。次のカードをよくするためです。名前もメールも、書いた内容も送りません。';

  @override
  String get usageOn => '数だけ、名前はなし。';

  @override
  String get usageOff => 'もう何も計測しません。';

  @override
  String get yourMix => 'あなたのミックス';

  @override
  String get genresLine => 'ジャンルをタップすると外せます。長押しすると、中の三つの筋がすぐ下に開きます。';

  @override
  String get insideGenre => 'この中身';

  @override
  String nOfSixOn(int n) {
    return '6つ中$nつオン';
  }

  @override
  String get offInYourMix => 'ミックスに入っていません';

  @override
  String continueGenresOn(int on, int total) {
    return '続ける · $total中$onジャンルがオン';
  }

  @override
  String get mixRarely => 'まれに';

  @override
  String get mixSometimes => 'ときどき';

  @override
  String get mixOften => 'よく';

  @override
  String get mixALot => 'たくさん';

  @override
  String get mixFull => 'いっぱい';

  @override
  String get forYouChip => 'あなた向け';

  @override
  String get againChip => 'もう一度';

  @override
  String theOthersYours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '残りの$n枚も、あなたのものに。',
      one: '残りの1枚も、あなたのものに。',
    );
    return '$_temp0';
  }

  @override
  String get magicLine =>
      '毎日5枚、あなたのために選んだカード。あなたのミックスから、あなたのレベルで、読んだものは二度と出ません。明日から。';

  @override
  String get everyCardForYou => 'すべてのカードを、あなたのために。';

  @override
  String get perkOwnTitle => '毎日5枚、すべてあなたのもの';

  @override
  String get perkOwnLine => 'あなたの選んだ系統から、あなたのレベルで、既読は二度と出ません。無料版は1日1枚。';

  @override
  String get plusCardHeadline => '5枚すべてを、あなたのものに。';

  @override
  String get plusCardLine => 'あなたのミックスから、あなたのレベルで毎日5枚。あなたの旅。アーカイブすべて。';

  @override
  String get continueFree => '無料で続ける';

  @override
  String get archiveBeforeThisWeek => '今週より前のすべて';

  @override
  String get whatStays => '残るもの';

  @override
  String nReadOfN(int read, int total) {
    return '$total枚中$read枚を読了';
  }

  @override
  String nAnswered(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚に回答',
    );
    return '$_temp0';
  }

  @override
  String nCameBackAgain(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚が戻ってきた',
    );
    return '$_temp0';
  }

  @override
  String nKeptOnReturn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚は戻ってきても正解',
    );
    return '$_temp0';
  }

  @override
  String get nothingBackYet =>
      'まだ何も戻ってきていません。カードは3日後、1週間後、1か月後に戻ってきます。そのとき正解できるものが、本当に知っていることです。';

  @override
  String get weekKeptTwoOwn => '1週間続いた：明日は5枚のうち2枚があなたのカード。';

  @override
  String get perkJourneyLine => 'あなたのレベル、系統ごとの各分野、残ったこと、そして今夜話すカード。';
}
