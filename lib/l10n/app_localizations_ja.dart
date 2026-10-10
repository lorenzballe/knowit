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
  String magicUnlock(int days) {
    return '$days日間無料で試す';
  }

  @override
  String get getPlus => 'Astute+にする';

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
  String trialDaysFree(int days) {
    return '$days日間無料';
  }

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
  String introNotifyWhen(String time) {
    return '明日 $time';
  }

  @override
  String get introNotifyLine => '今日の5枚が届いています。1日目。';

  @override
  String get introOneOfFive => '1 / 5';

  @override
  String get introDayOne => '1日目';

  @override
  String get introTapTomorrow => '明日タップして答えを見る';

  @override
  String get introDayOneTomorrow => '1日目 · 明日';

  @override
  String get introDaySevenStreak => '7日目 · 初めての連続記録';

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
  String get barMoveCaps => '持ち帰ること';

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
  String get perkArchiveLine => '読んだ日をすべて、ずっと保存。';

  @override
  String get plusIsActive => 'ASTUTE+ 有効';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return '$days日間無料で試す。その後$price$suffix';
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
      other: '数日前に答えた$n枚のカード。まだ覚えているか確かめよう',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'まだ覚えてる？';

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
  String get topLevel => '最上位';

  @override
  String plusNToday(int n) {
    return '今日 +$n';
  }

  @override
  String get bySubject => '分野別';

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
  String get anonymousUsage => '利用データ';

  @override
  String get anonymousUsageLine =>
      'アプリの使われ方（読まれた・保存された・話されたカード、うまくいかなかったこと）を送ります。次のカードをよくするためです。名前もメールも、書いた内容も送りません。';

  @override
  String get usageOn => '共有中。名前も、書いた言葉も含みません。';

  @override
  String get usageOff => 'もう何も計測しません。';

  @override
  String get yourMix => 'あなたのミックス';

  @override
  String get genresLine => 'ジャンルをタップすると外せます。長押しすると、中の三つの筋がすぐ下に開きます。';

  @override
  String get insideGenre => 'この中身';

  @override
  String nOfSixOn(int n, int total) {
    return '$totalつ中$nつオン';
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
  String get magicLine =>
      '毎日5枚、あなたのために選んだカード。あなたのミックスから、あなたのレベルで、読んだものは二度と出ません。明日から。';

  @override
  String get everyCardForYou => 'すべてのカードを、あなたのために。';

  @override
  String get perkOwnTitle => '毎日5枚、すべてあなたのもの';

  @override
  String get perkOwnLine => 'あなたの選んだ系統から、あなたのレベルで、既読は二度と出ません。無料版は1日2枚。';

  @override
  String get plusCardHeadline => '5枚すべてを、あなたのものに。';

  @override
  String get plusCardLine => 'あなたのミックスから、あなたのレベルで毎日5枚。あなたの旅。アーカイブすべて。';

  @override
  String get continueFree => '無料で続ける';

  @override
  String get archiveBeforeThisWeek => '今週より前のすべて';

  @override
  String get weekKeptThreeOwn => '1週間続いた：明日は5枚のうち3枚があなたのカード。';

  @override
  String get perkJourneyLine => 'あなたのレベル、系統ごとの各分野、残ったこと、そして今夜話すカード。';

  @override
  String get topOfTheWeek => '今週のトップ';

  @override
  String get topOfTheMonth => '今月のトップ';

  @override
  String topIn(String subject) {
    return '$subjectのトップ';
  }

  @override
  String get topLineWeek => '過去7日間で、いちばんいいね・保存・話されたカード';

  @override
  String get topLineMonth => '過去30日間で、いちばんいいね・保存・話されたカード';

  @override
  String get topWeek => '週';

  @override
  String get topMonth => '月';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n人');
    return '$_temp0';
  }

  @override
  String get topEmpty => 'まだランキングはありません。いいね・保存・話したカードがすべてカウントされます。';

  @override
  String get readMark => '既読';

  @override
  String get lovedSinceTheStart => 'はじまりから愛されたカード';

  @override
  String lovedIn(String subject) {
    return '$subjectで愛されたカード';
  }

  @override
  String get lovedLine => '読者がいちばん残したカードで、あなたがまだ読んでいないもの';

  @override
  String get forYouShelf => 'あなたへ';

  @override
  String get forYouLine => 'あなたの読み方が最初に置くもの';

  @override
  String get exploreOffline => 'オフラインです。これは最後に読み込んだ「探す」です。';

  @override
  String get askYourselfCaps => '自分に問う';

  @override
  String get themeMyths => '覆される神話';

  @override
  String get themeMythsLine => 'ほとんどの人が信じていること、そしてその誤り';

  @override
  String get themeParadoxes => 'パラドックス';

  @override
  String get themeParadoxesLine => '両方とも真であるはずのない二つの真実';

  @override
  String get themeNumbers => '驚きの数字';

  @override
  String get themeNumbersLine => '数字そのものが意外な結末';

  @override
  String get themePractical => '今日使える';

  @override
  String get themePracticalLine => '今夜までに試せること、会話のネタになること';

  @override
  String get themeOrigins => 'その始まり';

  @override
  String get themeOriginsLine => '毎日使うものの起源';

  @override
  String get themeStories => '本当にあった話';

  @override
  String get themeStoriesLine => '実際に起きたこと';

  @override
  String get themeDebates => 'どちらにつく？';

  @override
  String get themeDebatesLine => '正解はない、より良い論拠があるだけ';

  @override
  String get themeWorkItOut => '計算してみよう';

  @override
  String get themeWorkItOutLine => 'カードが答えを言う前に、数字を当てよう';

  @override
  String get themeSeen => '見て分かる';

  @override
  String get themeSeenLine => '要点を描くカード';

  @override
  String get themeSharpest => '鋭い人へ';

  @override
  String get themeSharpestLine => 'いちばん難しいカード';

  @override
  String get themePast0 => '古代の世界';

  @override
  String get themePast1 => '17〜19世紀';

  @override
  String get themePast2 => '前世紀';

  @override
  String get themePastLine => '来るたびに違う時代';

  @override
  String get themePlace0 => 'アジアと中東';

  @override
  String get themePlace1 => '南北アメリカ';

  @override
  String get themePlace2 => 'ヨーロッパ';

  @override
  String get themePlaceLine => '来るたびに違う地域';

  @override
  String get themeTrueOrFalse => '正しい？間違い？';

  @override
  String get themeTrueOrFalseLine => 'めくる前に決めて。ほとんどの人が間違えます';

  @override
  String get themeReasoning => '考えるだけ';

  @override
  String get themeReasoningLine => '覚えることはなし。考え方だけ';

  @override
  String get themeIdeas => '大きなアイデア';

  @override
  String get themeIdeasLine => '物事の背後にある理論を一つずつ';

  @override
  String get themeCurious => 'ただの好奇心';

  @override
  String get themeCuriousLine => '「なぜ」を知る楽しみのために';

  @override
  String get themeMoving => 'いま動いていること';

  @override
  String get themeMovingLine => 'いま変わりつつあることと、その意味';

  @override
  String get themeHowItWorks => '本当の仕組み';

  @override
  String get themeHowItWorksLine => '毎日見ているものの裏にある仕組み';

  @override
  String get themePuzzles => 'パズル';

  @override
  String get themePuzzlesLine => 'ペンと1分で解ける謎';

  @override
  String get weekRecapCaps => '今週あなたが自分に問いかけたこと';

  @override
  String get weekRecapLine => 'カードが残してくれた問い';

  @override
  String weekRecapMore(int n) {
    return 'Plusで今週のあと$n件';
  }

  @override
  String get plusInTheApp =>
      'Astute+ はアプリで利用できます。iPhone か Android に Astute をダウンロードして無料体験を始めましょう。';

  @override
  String get purchaseComplete => '購入が完了しました。';

  @override
  String get successWelcome => 'Astute+へようこそ。今日の5枚のカードが用意できました。';

  @override
  String successWelcomeNamed(String name) {
    return 'Astute+へようこそ、$nameさん。今日の5枚のカードが用意できました。';
  }

  @override
  String get successFiveCards => '1日5枚のカード';

  @override
  String get successArchive => 'すべてのアーカイブ';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return '$dateまで無料、その後$price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return '$dateに更新 · $price$suffix';
  }

  @override
  String get successReceipt => 'レシート';

  @override
  String get letsStart => 'はじめよう';

  @override
  String successFootFirstCharge(String date) {
    return '初回請求は$date · いつでも解約可能';
  }

  @override
  String successFootRenews(String date) {
    return '$dateに更新 · いつでも解約可能';
  }

  @override
  String get tryToday => '今日やってみる';

  @override
  String minutesShort(int n) {
    return '$n分';
  }

  @override
  String get sideOr => 'または';

  @override
  String get nextStep => '次のステップ';

  @override
  String get showAllSteps => 'すべて表示';

  @override
  String get revealSeePicture => '図を見る';

  @override
  String get revealPlayScene => '自分で試す';

  @override
  String get revealBackToAnswer => '答えに戻る';

  @override
  String get revealShowWorking => '考え方を見る';

  @override
  String get sceneLockIn => '決定';

  @override
  String get sceneYou => 'あなた';

  @override
  String get sceneTruth => '正解';

  @override
  String get sceneTryAgain => 'もう一度';

  @override
  String get sceneDrawHint => '指で予想を描いてください';

  @override
  String get sceneHoldHint => '長押し';

  @override
  String get sceneSwipeHint => 'スワイプかタップ';

  @override
  String get sceneTapToPick => '選んでタップ';

  @override
  String get sceneShowMe => '見せて';

  @override
  String get sceneYourGuess => 'あなたの予想';

  @override
  String sceneNOfM(int n, int m) {
    return '$m中$n';
  }

  @override
  String get reportProblem => '問題を報告';

  @override
  String get reportedThanks => '報告しました。ありがとうございます。';

  @override
  String get reportTitle => 'このカードの何が問題ですか？';

  @override
  String get reportLead => '報告はすべて出典と照らし合わせて確認し、カードを直します。';

  @override
  String get reportFact => '事実が間違っている';

  @override
  String get reportAnswer => '正解とされた答えが間違っている';

  @override
  String get reportSource => '出典が裏付けていない';

  @override
  String get reportUnclear => 'わかりにくい';

  @override
  String get reportTypo => '誤字や表示の崩れ';

  @override
  String get reportOther => 'その他';

  @override
  String get reportNoteHint => '確認に役立つこと（任意）';

  @override
  String get reportSend => '送信';

  @override
  String get reportSentToast => 'ありがとうございます。確認します。';

  @override
  String get journeyPointsOff => 'ポイントのずれ';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$n回、確信度つきで答えると測れます。',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'あなたのスコア';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'ポイント');
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '4週間で+$n';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '今週はここまでで$nポイント獲得しました。',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$dateの週は$nポイント獲得しました。',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n枚',
      one: '1枚',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return '$dateから、毎週末時点のスコアです。点をタップするとその週を表示します。';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'レベル$n / $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\n「$rung」まで';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$n枚',
      one: 'あと1枚',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$n回答',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '確信度つきであと$n回答',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$n枚定着',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'あと$nポイント',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => '換算すると';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n冊');
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'またはドキュメンタリー$h時間';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '最初の1冊まであと$n枚',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => '連続';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n日',
      one: '1日',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return '最高$best日 · $days日中$active日';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n / $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return '分野 · 点線：$month';
  }

  @override
  String get journeySubjects => '分野';

  @override
  String get journeyHowHard => '難しさ';

  @override
  String get journeyOfThree => '/ 3';

  @override
  String get journeyHardNow => 'あなたが開いたカード。';

  @override
  String journeyHardThen(String v, String month) {
    return 'あなたが開いたカード。$monthは$v';
  }

  @override
  String get journeyReadingTime => '読書時間';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h時間$m分';
  }

  @override
  String journeyMinutes(int m) {
    return '$m分';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '週$now分、最初は$was分';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '今週$m分';
  }

  @override
  String get journeyTimedFromToday => '今日から計測';

  @override
  String journeyPointsOffFrom(int was) {
    return 'ポイントのずれ、最初は$was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · $n以下';
  }

  @override
  String get journeyRightWhenSure => '確信時の正解率';

  @override
  String journeyFromIn(String v, String month) {
    return '$monthの$vから';
  }

  @override
  String get journeySureNone => '80%以上の回答はまだなし';

  @override
  String get journeyMovesTitle => '見抜ける型';

  @override
  String journeyOfN(int n) {
    return '/ $n';
  }

  @override
  String journeyNewest(String name) {
    return '最新：$name';
  }

  @override
  String get journeyNoneYet => 'まだありません';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'まだ覚えているカード',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days日後に',
    );
    return '$_temp0$of枚中$right枚';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks週間後に',
    );
    return '$_temp0$of枚中$right枚';
  }

  @override
  String journeyActiveDays(int active, int days) {
    return '$days日中$active日';
  }

  @override
  String get journeyMostlyMorning => '主に朝';

  @override
  String get journeyMostlyAfternoon => '主に午後';

  @override
  String get journeyMostlyEvening => '主に夜';

  @override
  String get journeyMostlyNight => '主に深夜';

  @override
  String get journeyInTime => '時代';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString年';
  }

  @override
  String journeyFromEra(String era) {
    return '$eraから今年まで';
  }

  @override
  String get journeyEraAncient => '古代';

  @override
  String get journeyEraMedieval => '中世';

  @override
  String get journeyEraEarlyModern => '16世紀';

  @override
  String get journeyEraNineteenth => '19世紀';

  @override
  String get journeyEraTwentieth => '20世紀';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => '年代のわかるカードはまだなし';

  @override
  String get journeyInPlace => '地域';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n地域');
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$listと宇宙';
  }

  @override
  String get journeyRegionAmericas => '南北アメリカ';

  @override
  String get journeyRegionEurope => 'ヨーロッパ';

  @override
  String get journeyRegionAsia => 'アジア';

  @override
  String get journeyRegionOceania => 'オセアニア';

  @override
  String get journeyRegionAfrica => 'アフリカ';

  @override
  String get journeyRegionMiddleEast => '中東';

  @override
  String get journeyNoPlace => 'まだ場所なし';

  @override
  String get journeyTopics => 'トピック';

  @override
  String journeyMet(int n) {
    return '$n個に出会った';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return 'うち$n個が$subject';
  }

  @override
  String get journeyWords => '用語';

  @override
  String journeyNew(int n) {
    return '新出$n語';
  }

  @override
  String get anotherOne => '別のカード';

  @override
  String answerIs(String said) {
    return '答え：$said';
  }

  @override
  String get answeredAlready => '回答済み';

  @override
  String get anyCard => 'どの分野、どの棚からでも、1枚';

  @override
  String betN(int n) {
    return '$nを賭ける';
  }

  @override
  String get betWord => '賭ける';

  @override
  String get biggerLabel => '大きい';

  @override
  String get biggerYouGotIt => '大きい・正解';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n日後');
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => '1週間後';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n週間後',
    );
    return '$_temp0';
  }

  @override
  String get check => '答え合わせ';

  @override
  String closerDone(String said, int right, int steps) {
    return '答えは$said。$steps回中$right回正解。';
  }

  @override
  String closerNoLess(String v) {
    return 'いいえ、$vより少ない。';
  }

  @override
  String closerNoMore(String v) {
    return 'いいえ、$vより多い。';
  }

  @override
  String get closerStart => '3ステップで絞り込もう。';

  @override
  String closerYesLess(String v) {
    return '正解、$vより少ない。';
  }

  @override
  String closerYesMore(String v) {
    return '正解、$vより多い。';
  }

  @override
  String get corrections => '訂正';

  @override
  String get didYouKnow => '知ってた？';

  @override
  String get didYouKnowLine => 'めくって、それから：初耳？知ってた？';

  @override
  String get dragToSet => 'ドラッグで設定';

  @override
  String get dykAgain => 'もう一度';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '知っていたのは$n枚',
      zero: '知っていたのは0枚',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '初耳は$n枚',
      zero: '今日は初耳なし',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => '今日の号はここまで';

  @override
  String get editionTomorrow => '明日の号は朝に届きます';

  @override
  String get eraAncient => '古代の世界';

  @override
  String get eraAncientWhen => '500年より前';

  @override
  String get eraEarlyModern => '近世';

  @override
  String get eraEarlyModernWhen => '1500年〜1800年';

  @override
  String get eraMedieval => '中世';

  @override
  String get eraMedievalWhen => '500年〜1500年';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'この時代からあと$n枚',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => '19世紀';

  @override
  String get eraNineteenthWhen => '1800年〜1900年';

  @override
  String get eraRecent => '今世紀';

  @override
  String get eraRecentWhen => '2000年以降';

  @override
  String get eraRulerNow => '現在';

  @override
  String get eraRulerOld => '古代';

  @override
  String get eraShortAncient => '古代';

  @override
  String get eraShortEarlyModern => '1500–1800年';

  @override
  String get eraShortMedieval => '中世';

  @override
  String get eraShortNineteenth => '1800年代';

  @override
  String get eraShortRecent => '2000年代';

  @override
  String get eraShortTwentieth => '1900年代';

  @override
  String get eraTwentieth => '前世紀';

  @override
  String get eraTwentiethWhen => '1900年〜2000年';

  @override
  String get fewCards => '数枚で分かる';

  @override
  String get fewCardsLine => '1枚では説明しきれないときに';

  @override
  String get firstLabel => '始まり';

  @override
  String get forYouNow => '今のあなたに';

  @override
  String get hardBadge => '難問';

  @override
  String hidesIn(String where) {
    return '場所：$where';
  }

  @override
  String get howSure => 'どれくらい確かで、なぜそう思う？';

  @override
  String get inNumbers => '数字で見る';

  @override
  String inRange(int pts, String said) {
    return '範囲内：+$ptsポイント。答えは$said。';
  }

  @override
  String inYourMoves(int n) {
    return 'あなたの手 · $n回';
  }

  @override
  String itIs(String said) {
    return '答えは$said。';
  }

  @override
  String get knewIt => '知ってた';

  @override
  String get less => '少ない';

  @override
  String get lookFirst => '見出しを信じる前に、グラフを見よう。';

  @override
  String minutesLabel(int n) {
    return '$n分';
  }

  @override
  String missedRange(String said) {
    return '外れ：答えは$said。';
  }

  @override
  String get modeBigger => 'どっちが大きい？';

  @override
  String get modeCloser => 'だんだん近づく';

  @override
  String get modePick => '1つ選ぶ';

  @override
  String get modeRange => '範囲に賭ける';

  @override
  String get modeSlide => '動かす';

  @override
  String get modeStake => '賭けてみる';

  @override
  String get monthShelfLine => '毎月新しい分野、みんな同じ';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards枚',
    );
    return '$_temp0 · $minutes分';
  }

  @override
  String get moodTime => '使える時間';

  @override
  String get moodTitle => '気分と時間で';

  @override
  String get moodTone => 'トーン';

  @override
  String get more => '多い';

  @override
  String moreOrLess(String v) {
    return '$vより多い？少ない？';
  }

  @override
  String get moveComparedToWhat => '何と比べて？';

  @override
  String get moveComparedToWhatLine => '比べるものがなければ、変化は何も語らない';

  @override
  String get askingTitle => '分野ごとに1問';

  @override
  String askingIn(String subject) {
    return '$subjectの問題';
  }

  @override
  String get askingLine => 'みんな同じ。まず答えて、それから理由を';

  @override
  String get moveSampling => '誰が数えられた？';

  @override
  String get moveSamplingLine => '研究に誰が入ったかで、わかることが決まる';

  @override
  String mythDeckHint(int at, int of) {
    return '$of枚中$at枚目 · スワイプでめくる';
  }

  @override
  String nOfM(int at, int of) {
    return '$at/$of';
  }

  @override
  String get newMove => 'はじめての手';

  @override
  String get newToMe => '初耳';

  @override
  String get notEnoughPoints => 'ポイント不足';

  @override
  String get notSureLine => 'Astuteのどこかから1枚';

  @override
  String get notSureTitle => 'どこから始めるか迷ったら';

  @override
  String get openWord => '開く';

  @override
  String get pickOneFirst => 'まず1つ選んで';

  @override
  String get puzzleOfTheDay => '今日のパズル';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w・${pts}pt';
  }

  @override
  String get rightLastTime => '前回は正解';

  @override
  String get sameForEveryoneCaps => 'みんな同じ';

  @override
  String get sayFalse => '間違い';

  @override
  String get sayTrue => '正しい';

  @override
  String get seriesAnchors => '第一印象のわな';

  @override
  String get seriesGrowth => '暴走する数字';

  @override
  String seriesMeta(int n, int m) {
    return '$n枚 · 約$m分';
  }

  @override
  String get seriesOdds => 'うそをつく確率';

  @override
  String get seriesRetold => '語り直される歴史';

  @override
  String seriesStrand(String name) {
    return '数枚でわかる「$name」';
  }

  @override
  String get seriesStudies => '研究がまどわせる理由';

  @override
  String showAllN(int n) {
    return '$n枚すべて表示';
  }

  @override
  String get showFewer => '少なく表示';

  @override
  String get sixtyAgain => 'もう一度';

  @override
  String sixtyIn(int s) {
    return '$s秒で';
  }

  @override
  String get sixtyLine => '正しい？間違い？を8問。直感で';

  @override
  String get sixtyPerfect => '8問すべて正解。';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'ここまで$n問正解',
      zero: 'まだ正解なし',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => '秒で\n正誤8問';

  @override
  String sixtySecondsLeft(int s) {
    return '$s秒';
  }

  @override
  String get sixtyStart => 'スタート';

  @override
  String get sixtyTimeUp => '時間切れまでに';

  @override
  String get sixtyTitle => '60秒';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nポイントずれ。',
      zero: 'ぴったり。',
    );
    return '$_temp0';
  }

  @override
  String get stakeLabel => '賭け金';

  @override
  String stepOf(int at, int of) {
    return 'ステップ $at/$of';
  }

  @override
  String get surpriseMe => 'おまかせ';

  @override
  String get tapIfBigger => '大きいならタップ';

  @override
  String get tapToTurn => 'タップでめくる';

  @override
  String get tfRight => '正解。理由はカードで。';

  @override
  String tfWrong(String side) {
    return '答えは「$side」。理由はカードで。';
  }

  @override
  String theAnswer(String said) {
    return '答え：$said。';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'トップ記事';

  @override
  String get throughTime => '時代をめぐる';

  @override
  String get throughTimeLine => '古代から今年まで。ドラッグして旅しよう';

  @override
  String get todayLabel => '今日';

  @override
  String get todaysEdition => '今日の号';

  @override
  String get toneCurious => '好奇心';

  @override
  String get toneLight => '気軽に';

  @override
  String get toneSerious => 'まじめに';

  @override
  String get toneTough => '手ごわい';

  @override
  String get unmaskBack => '元のグラフに戻す';

  @override
  String get unmaskFlipped => '正しい向きに直す';

  @override
  String get unmaskLine => '同じ数字、違う見え方';

  @override
  String get unmaskStretched => '公平な目盛りにする';

  @override
  String get unmaskTitle => 'グラフの正体';

  @override
  String get unmaskTotals => '公平に比べる';

  @override
  String get unmaskTruncated => '軸をゼロから始める';

  @override
  String get unmaskWindow => '全期間を表示';

  @override
  String get whatIfTrue => 'もし本当なら？';

  @override
  String get whatIfTrueLine => '閉じたあとも考えさせるカード';

  @override
  String get whatYouBelieve => '信じていること';

  @override
  String get wrongLastTime => '前回は不正解';

  @override
  String youLose(int n) {
    return '$n失いました。';
  }

  @override
  String youWin(int n) {
    return '$n獲得！';
  }

  @override
  String get yourPick => 'あなたの選択';
}
