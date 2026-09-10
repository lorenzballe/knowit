// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

  @override
  String get tabToday => '오늘';

  @override
  String get tabExplore => '탐색';

  @override
  String get tabProfile => '프로필';

  @override
  String signInNotConnected(String provider) {
    return '$provider 로그인은 아직 연결되지 않았습니다. 카드는 이 기기에 보관됩니다.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return '$label(으)로 로그인할 수 없습니다. 계정 없이 계속할 수 있어요.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n일',
      one: '1일',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => '프리즈가 연속 기록을 지켰어요';

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
    return '$n일째 · $word장 읽음';
  }

  @override
  String shelfEyebrow(String word) {
    return '오늘의 $word장 · 밀어서 다시 보기';
  }

  @override
  String weekLine(int days) {
    return '이번 주 · 7일 중 $days일';
  }

  @override
  String get tapToFlip => '탭하여 뒤집기';

  @override
  String get shareThisCard => '이 카드 공유';

  @override
  String get removeFromSaved => '보관에서 빼기';

  @override
  String get saveThisPill => '이 알약 보관';

  @override
  String get shareThisPill => '이 알약 공유';

  @override
  String cardOf(int k, int n) {
    return '$n장 중 $k번째';
  }

  @override
  String hoursMinutes(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return '내일의 다섯 장은 $when 후에 열려요';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic이(가) 내일의 다섯 장을 엽니다. $when 후';
  }

  @override
  String get exploreTodaysBest => '오늘의 베스트 보기';

  @override
  String get fiveMore => '다섯 장 더';

  @override
  String get unlockFiveExtra => '추가 알약 다섯 장 잠금 해제';

  @override
  String nothingInYet(String subject) {
    return '$subject에는 아직 아무것도 없어요.';
  }

  @override
  String get here => '이 섹션';

  @override
  String get todaysShelf => '오늘의 선반';

  @override
  String get sameForEveryone => '모두에게 같고, 오늘만';

  @override
  String get onesThatAskTheMost => '가장 많이 묻는 카드';

  @override
  String get acrossEveryone => '내 믹스만이 아니라 모두에게서';

  @override
  String becauseSitsAtFull(String name) {
    return '$name이(가) 최대이기 때문에';
  }

  @override
  String get olderFromTurnedUp => '올려둔 주제의 오래된 카드';

  @override
  String moreOn(String name) {
    return '$name 더 보기';
  }

  @override
  String get subjectReadMost => '가장 많이 읽은 주제';

  @override
  String monthOf(String name) {
    return '$name의 한 달';
  }

  @override
  String get somewhereToStart => '오늘이 아닌 출발점';

  @override
  String get searchEveryCard => '모든 카드 검색';

  @override
  String nothingForYet(String query) {
    return '\"$query\"에 해당하는 카드가 아직 없어요.';
  }

  @override
  String matching(int n) {
    return '$n장 일치';
  }

  @override
  String get all => '전체';

  @override
  String get theArchive => '아카이브';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n개 결과',
      one: '1개 결과',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '카드 $n장. 날짜를 탭하여 여세요.';
  }

  @override
  String get whatYouHaveCovered => '지금까지 다룬 것';

  @override
  String searchNCards(int n) {
    return '$n장에서 검색';
  }

  @override
  String get cancel => '취소';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n장',
      one: '1장',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => '어제';

  @override
  String get noPillsMatchFilter => '이 필터에 맞는 알약이 아직 없어요.';

  @override
  String nothingForTryTopic(String query) {
    return '\"$query\"에 해당하는 것이 없어요. 주제로 찾아보세요.';
  }

  @override
  String get saved => '보관함';

  @override
  String get removedFromSaved => '보관에서 뺐어요.';

  @override
  String get undo => '되돌리기';

  @override
  String get nothingKeptYet => '아직 보관한 것이 없어요';

  @override
  String nInTopic(int n, String topic) {
    return '$topic에 $n장';
  }

  @override
  String get keepTheOnesYoullUse => '정말 쓸 것만 보관하세요';

  @override
  String get backToTodaysFive => '오늘의 다섯 장으로';

  @override
  String get archive => '아카이브';

  @override
  String get yourWeek => '이번 주';

  @override
  String get nothingThisWeekYet => '이번 주는 아직 비어 있어요. 다섯 장이 시작입니다.';

  @override
  String keptDaysOfSeven(int days) {
    return '달성 — 7일 중 $days일.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '7일 중 $days일.',
      one: '7일 중 1일.',
    );
    return '$_temp0 5일이면 이번 주 달성입니다.';
  }

  @override
  String get howSureAgainstHowRight => '얼마나 확신했나, 얼마나 맞았나';

  @override
  String get sureAndWrong => '확신했지만 틀린';

  @override
  String get worthGoingBackTo =>
      '다시 볼 가치가 있는 카드. 확신했던 것을 틀리는 것은 내가 정말 무엇을 믿는지 알아내는 유일하게 값싼 방법입니다.';

  @override
  String get whereThisIsGoing => '앞으로의 방향';

  @override
  String ofNRight(int n) {
    return '$n문제 중 정답';
  }

  @override
  String get sayHowSureOnMore =>
      '몇 문제 더 확신 정도를 말해 주면, 그 확신이 얼마나 가치 있는지 앱이 알려줄게요.';

  @override
  String confidenceOff(int gap) {
    return '확신이 실제로 아는 것보다 $gap포인트 벗어났어요.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return '확신의 오차는 $gap포인트, 지난주는 $before. 간격이 좁아지고 있어요.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return '확신의 오차는 $gap포인트, 지난주는 $before. 간격이 벌어졌어요.';
  }

  @override
  String nextRung(String name) {
    return '다음: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return '확신 $n%라고 답함';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': '첫째 날',
      'reading': '읽기',
      'answering': '답하기',
      'saying_how_sure': '확신 말하기',
      'calibrated': '보정됨',
      'holding': '유지',
      'sharp': '예리함',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': '누구나 여기서 시작합니다.',
      'reading': '습관이 시작됐어요.',
      'answering': '카드를 뒤집기 전에 답을 정합니다.',
      'saying_how_sure': '안다고 생각하는 것에 숫자를 붙입니다.',
      'calibrated': '안다고 말하는 것을, 정말 압니다.',
      'holding': '몇 주가 지나도 남아 있습니다.',
      'sharp': '확신해야 할 때 확신하고, 확신할 때 맞습니다.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return '$n장 더 읽기';
  }

  @override
  String stepAnswer(int n) {
    return '$n장 더 답하기';
  }

  @override
  String stepJudge(int n) {
    return '확신 정도와 함께 $n번 더 답하기';
  }

  @override
  String stepHold(int n) {
    return '$n장 더 유지하기';
  }

  @override
  String stepGap(int gap, int target) {
    return '확신 오차 $gap포인트 — $target이면 충분';
  }

  @override
  String stepBeforeJudged(int n) {
    return '앱이 확신을 평가하기까지 $n번의 답';
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
  String get signOutQuestion => '로그아웃할까요?';

  @override
  String get signOutBody => '연속 기록, 보관한 알약, 기록은 계정에 남습니다. 이 기기에서만 지워집니다.';

  @override
  String get signOut => '로그아웃';

  @override
  String get signedInRecordOnAccount => '로그인됐어요. 연속 기록과 기록이 이제 계정에 있어요.';

  @override
  String couldNotSignInWith(String label) {
    return '$label(으)로 로그인할 수 없습니다.';
  }

  @override
  String get signInNotAvailableBuild => '이 빌드에서는 로그인을 사용할 수 없어요.';

  @override
  String get startOverQuestion => '처음부터 다시 할까요?';

  @override
  String get startOverBody =>
      '이 기기의 모든 것(연속 기록, 보관한 알약, 답, 판단 기록, 주제, 요금제)을 지우고 소개를 다시 엽니다.';

  @override
  String get wipeIt => '지우기';

  @override
  String get yourRecord => '내 기록';

  @override
  String get appearance => '화면';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSystem => '시스템';

  @override
  String get yourTopics => '내 주제';

  @override
  String get edit => '편집';

  @override
  String get howWellYouKnowYourself => '나를 얼마나 아는가';

  @override
  String get isTheGapClosing => '간격이 좁아지고 있나요?';

  @override
  String get movesYouKeepMissing => '계속 놓치는 수';

  @override
  String get dailyNudge => '매일 알림';

  @override
  String everyDayAt(String time) {
    return '매일 $time';
  }

  @override
  String get yourFivePillsBeforeCoffee => '첫 커피 전에, 알약 다섯 장.';

  @override
  String get browserOnlySpeaksOpen =>
      '브라우저는 열려 있을 때만 말할 수 있어서, 이건 휴대폰 버전이 필요해요.';

  @override
  String get nudgeOff => '알림 꺼짐.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return '알림 켜짐, 매일 $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      '알림은 켜져 있지만 시스템이 거부했어요. 설정에서 Astut 알림을 허용하세요.';

  @override
  String get nudgeOnNeedsPhone => '알림 켜짐. 전달에는 휴대폰 버전이 필요해요.';

  @override
  String get howMuchYouKnow => '얼마나 아는가';

  @override
  String savedN(int n) {
    return '보관함 · $n';
  }

  @override
  String get manageSubscription => '구독 관리';

  @override
  String get howPillsAreWritten => '알약이 만들어지는 방법';

  @override
  String get signingIn => '로그인 중…';

  @override
  String get signInWithApple => 'Apple로 로그인';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String acrossNAnswersHowSure(int n) {
    return '$n번의 답에서 확신 정도를 말했어요. 결과는 이렇습니다.';
  }

  @override
  String get perfectlyCalibratedLine =>
      '완벽하게 보정된 사람은 70%라고 말할 때 70%의 확률로 맞습니다.';

  @override
  String get notEnoughAnswersYet => '아직 답이 충분하지 않아요';

  @override
  String get confidenceMatchesAccuracy => '확신이 정확도와 일치해요';

  @override
  String overconfidentBy(int points) {
    return '$points포인트 과신하고 있어요';
  }

  @override
  String underconfidentBy(int points) {
    return '$points포인트 과소평가하고 있어요';
  }

  @override
  String saidPercent(int n) {
    return '답변 $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return '정답 $pct% ($count문제 중 $right)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '이 문맥이 $n개 더',
      one: '이 문맥이 1개 더',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus => 'Astut plus로 모든 원칙 보기';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n개 더 추적 중',
      one: '1개 더 추적 중',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => '내 기록 공유';

  @override
  String lastCallsAgainstFirst(int n) {
    return '최근 $n번의 판단과 처음 $n번';
  }

  @override
  String closedByPoints(int n) {
    return '$n포인트 좁아짐';
  }

  @override
  String openedByPoints(int n) {
    return '$n포인트 벌어짐';
  }

  @override
  String get holdingSteady => '변동 없음';

  @override
  String get measurementRunningPlus => '측정이 진행 중입니다. Astut+가 어느 방향인지 보여줍니다.';

  @override
  String firstN(int n) {
    return '처음 $n번';
  }

  @override
  String lastN(int n) {
    return '최근 $n번';
  }

  @override
  String get trackingMoreClosely => '확신이 전보다 정확도를 더 가까이 따라가고 있어요.';

  @override
  String get distanceHasGrown => '간격이 커졌어요. 답을 정하기 전에 조금 천천히 갈 만해요.';

  @override
  String get noRealMovementYet => '아직 뚜렷한 변화는 없어요. 며칠이 아니라 몇 주가 걸립니다.';

  @override
  String get seeWhichWay => '방향 보기';

  @override
  String get spotOn => '정확';

  @override
  String pointsOver(int n) {
    return '$n 초과';
  }

  @override
  String pointsUnder(int n) {
    return '$n 부족';
  }

  @override
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7일 무료';

  @override
  String get watchTheGapMove => '간격이 움직이는 것을 지켜보세요.';

  @override
  String get measurementFreeForever =>
      '측정은 언제나 무료입니다. Astut+는 그것이 어느 방향인지 알려줍니다.';

  @override
  String get seeThePlans => '요금제 보기';

  @override
  String get recordStartsToday => '내 기록은 오늘 시작됩니다.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '일',
      one: '일',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '장 읽음',
      one: '장 읽음',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n장 읽음',
      one: '1장 읽음',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n주 달성',
      one: '1주 달성',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n장 다시 옴';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '프리즈 $n개',
      one: '프리즈 1개',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => '무료 요금제';

  @override
  String get streakReset => '연속 기록 초기화';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n일을\n놓쳤어요.',
      one: '하루를\n놓쳤어요.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n일',
      one: '1일',
    );
    return '$_temp0이 여전히 최고 기록입니다. 오늘의 다섯 장을 읽으면 카운터가 1부터 다시 시작해요.';
  }

  @override
  String get whileYouWereAway => '떠나 있는 동안';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n장을 읽지 않았어요',
      one: '1장을 읽지 않았어요',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic은(는) 여전히 가장 많이 보관한 주제예요';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '맞혔던 카드 $n장이 오늘 돌아와요',
      one: '맞혔던 카드 1장이 오늘 돌아와요',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => '오늘의 다섯 장으로 다시 시작';

  @override
  String moveMyReminderTo(String time) {
    return '알림을 $time(으)로 옮기기';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return '매일 알림을 $time(으)로 옮겼어요.';
  }

  @override
  String get whatYouAlready => '이미 ';

  @override
  String get know => '아는 것';

  @override
  String get knowIntro =>
      '가장 높이 올린 주제들입니다. 하루가 각 주제에서 무엇을 요구하는지가 바뀝니다 — 탄탄하면 질문을, 궁금하면 설명을 — 양은 그대로예요.';

  @override
  String get startWithMyFirstCards => '첫 카드로 시작';

  @override
  String get skipForNow => '지금은 건너뛰기';

  @override
  String get levelCurious => '궁금';

  @override
  String get levelSome => '조금';

  @override
  String get levelSolid => '탄탄';

  @override
  String get save => '저장';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$total개 주제 중 $n개가 믹스에';
  }

  @override
  String get yourSpace => '나의 ';

  @override
  String get mix => '믹스';

  @override
  String get everythingIsInDrag => '모두 들어 있어요. 주제를 아래로 끌면 덜 보이고, 0까지 내리면 빠집니다.';

  @override
  String get next => '다음';

  @override
  String get whatShouldWeTalkAbout => '무엇에 대해 이야기할까요?';

  @override
  String get fivePillsADayPick =>
      '하루 다섯 장, 매일 아침 새로 씁니다. 믹스에 넣을 주제를 고르세요 — 나중에 바꿀 수 있어요.';

  @override
  String nSelected(int n) {
    return '$n개 선택';
  }

  @override
  String startWithNTopics(int n) {
    return '$n개 주제로 시작';
  }

  @override
  String saveNTopics(int n) {
    return '$n개 주제 저장';
  }

  @override
  String pickAtLeastN(int n) {
    return '$n개 이상 고르세요';
  }

  @override
  String get swipeToSeeMore => '밀어서 더 보기';

  @override
  String get tagline => '하루 다섯 가지 똑똑한 이야기, 대화에서 바로 쓸 수 있게';

  @override
  String get introTopicsTitle => '열두 개 주제, 다섯 장의 알약';

  @override
  String get introTopicsLine => '매일 아침 새로 쓰고, 출처와 대조합니다.';

  @override
  String get introQuestionTitle => '질문, 그리고 답';

  @override
  String get introQuestionLine => '모든 알약에는 소리 내어 말할 가치가 있는 한 문장이 있습니다.';

  @override
  String get introMixTitle => '믹스는 당신이 정합니다';

  @override
  String get introMixLine => '주제를 내리면 덜 보이고, 끄면 사라집니다.';

  @override
  String get introThirtyTitle => '하루 30초';

  @override
  String get introThirtyLine => '알림 하나, 카드 다섯 장, 그리고 끊고 싶지 않은 연속 기록.';

  @override
  String get continueWithApple => 'Apple로 계속';

  @override
  String get continueWithGoogle => 'Google로 계속';

  @override
  String get continueWithEmail => '이메일로 계속';

  @override
  String get termsLine => '가입하면 서비스 약관과 개인정보 처리방침에 동의하게 됩니다';

  @override
  String get skip => '건너뛰기';

  @override
  String get tapToRevealLower => '탭하여 보기';

  @override
  String get barMoveCaps => '대화용 한 문장';

  @override
  String get theBarMoveCaps => '대화용 한 문장';

  @override
  String get dayStreakCaps => '일 연속';

  @override
  String sourceLabel(String source) {
    return '출처 · $source';
  }

  @override
  String get perkRecordTitle => '시간에 따른 내 기록';

  @override
  String get perkRecordLine => '확신과 정답 사이의 간격이 정말 좁아지고 있는지.';

  @override
  String get perkPrinciplesTitle => '만난 모든 원칙';

  @override
  String get perkPrinciplesLine => '가장 약한 세 가지만이 아니라 전부, 아직 보지 못한 문맥까지.';

  @override
  String get perkFreezesTitle => '연속 기록 프리즈 세 개';

  @override
  String get perkFreezesLine => '주말 여행에도 충분합니다. 잃을 수만 있는 연속 기록은 결국 사라집니다.';

  @override
  String get perkExtraTitle => '매일 추가 알약 5장';

  @override
  String get perkExtraLine => '첫 세트를 끝내는 순간 두 번째 세트가 열립니다.';

  @override
  String get perkArchiveTitle => '전체 아카이브';

  @override
  String get perkArchiveLine => '지금까지 읽은 모든 알약을 주제별로 검색.';

  @override
  String get perkTopicsTitle => '주제를 직접 고르기';

  @override
  String get perkTopicsLine => '정말 좋아하는 쪽으로 믹스를 기울이세요.';

  @override
  String get plusIsActive => 'ASTUT+ 활성화됨';

  @override
  String tryFreeThen(String price, String suffix) {
    return '7일 무료 체험 후 $price$suffix';
  }

  @override
  String get trialStartedNoPayment => '체험이 시작됐어요. 이 빌드에는 결제가 연결되어 있지 않습니다.';

  @override
  String get thatDidNotGoThrough => '처리되지 않았어요.';

  @override
  String get plusIsBack => 'Astut+가 돌아왔어요.';

  @override
  String get nothingToRestore => '이 계정에 복원할 것이 없어요.';

  @override
  String get findOutIfBetter => '정말 나아지고 있는지 알아보세요.';

  @override
  String get perYear => '/년';

  @override
  String aMonth(String price) {
    return '월 $price';
  }

  @override
  String savePercent(int n) {
    return '$n% 절약';
  }

  @override
  String get perMonth => '/월';

  @override
  String get billedMonthly => '매월 청구';

  @override
  String get cancelTheTrial => '체험 취소';

  @override
  String get cancelAnyTime => '언제든 취소 가능';

  @override
  String get cancelAnyTimeNoPayment => '언제든 취소 가능 · 이 빌드에서는 결제되지 않음';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get everythingOpensNothingCharged => '모든 것이 열립니다. 청구는 없어요.';

  @override
  String dayN(int n) {
    return '$n일째';
  }

  @override
  String get reminderTwoDaysBefore => '갱신 이틀 전에 알려드려요.';

  @override
  String get itRenewsUnlessCancelled => '취소하지 않으면 갱신됩니다. 언제든 취소할 수 있어요.';

  @override
  String get howTheFreeWeekWorks => '무료 일주일은 이렇게';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer => '한쪽을 고르세요. 정답은 없습니다.';

  @override
  String get estimateCloseEnough => '추정하세요. 가까우면 정답입니다.';

  @override
  String get tapToReveal => '탭하여 보기';

  @override
  String closeEnoughItIs(String answer) {
    return '근접 · 답은 $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return '내 답 $given · 정답 $answer, $band까지 인정';
  }

  @override
  String get youGotIt => '정답';

  @override
  String youSaidItIs(String given, String answer) {
    return '내 답 $given · 정답 $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => '거의 모두가 틀리는 문제';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · 확신 $pct%라고 답함';
  }

  @override
  String get giveMeANudge => '힌트 주세요';

  @override
  String get beingRightMattersLess => '맞히는 것보다 얼마나 자주 맞히는지 아는 것이 더 중요합니다.';

  @override
  String get writeItBeforeTheirs => '상대의 답을 읽기 전에 적으세요.';

  @override
  String get youAnsweredThisOne => '이미 답한 문제예요.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': '쉬움',
      'medium': '보통',
      'hard': '어려움',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · 뒤집기 전에 답을 정하세요.';
  }

  @override
  String get yourAnswer => '내 답';

  @override
  String get checkMyAnswer => '답 확인';

  @override
  String get howSureAreYou => '얼마나 확신하나요?';

  @override
  String percentSure(int n) {
    return '확신 $n퍼센트';
  }

  @override
  String get inOneLineWhy => '한 줄로 — 왜?';

  @override
  String get because => '왜냐하면…';

  @override
  String get nowShowMeTheOtherSide => '이제 반대편 보기';

  @override
  String get skipShowMeAnyway => '건너뛰기 — 그래도 보기';

  @override
  String get youTookCaps => '내 선택';

  @override
  String get putSimplyCaps => '쉽게 말하면';

  @override
  String get explainLikeImThree => '아이에게 설명하듯';

  @override
  String get whatTheOtherSideSaysCaps => '반대편의 주장';

  @override
  String get whatTheOtherSideSays => '반대편의 주장';

  @override
  String theTrap(String trap) {
    return '함정: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return '고른 쪽: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' (확신 $n%)';
  }

  @override
  String youGotThisOne(String sure) {
    return '이 문제는 맞혔어요$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return '내 답: $answer$sure';
  }

  @override
  String get swipeForTheNextOne => '밀어서 다음으로';

  @override
  String get thatWasTheOnlyOne => '마지막 한 장이었어요';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => '카드를 그릴 수 없어요.';

  @override
  String get textCopiedInstead => '대신 텍스트를 복사했어요.';

  @override
  String get copiedToClipboard => '클립보드에 복사했어요.';

  @override
  String get rendering => '그리는 중…';

  @override
  String get theSourceGoesWithIt => '출처도 함께';

  @override
  String get fiveADayALittleSharper => '하루 다섯 장. 조금 더 예리하게.';

  @override
  String get shareMyDay => '오늘 결과 공유';

  @override
  String climbedTo(String rung) {
    return '오늘 $rung 단계에 올랐어요';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$asked문제 중 $right문제 정답';
  }

  @override
  String saidSure(int sure) {
    return '확신 $sure%';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '카드 $n장이 돌아왔어요 — 다시 답해 보세요',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => '돌아온 카드';

  @override
  String get holdACardYouLike => '마음에 드는 카드를 길게 누르세요';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '오늘 $n장 좋아요',
    );
    return '$_temp0';
  }

  @override
  String get liked => '좋아요';

  @override
  String likedN(int n) {
    return '좋아요 · $n';
  }

  @override
  String get nothingLikedYet => '아직 좋아요한 카드가 없어요';

  @override
  String get likeThisPill => '이 카드 좋아요';

  @override
  String get removeFromLiked => '좋아요 취소';

  @override
  String get removedFromLiked => '좋아요를 취소했어요.';

  @override
  String get lessLikeThis => '이런 카드는 줄이기';

  @override
  String get whatYouLikedLandsHere => '다시 읽고 싶은 카드';

  @override
  String get holdToLikeLandsHere =>
      '마음에 드는 카드를 길게 누르면 여기에 모이고, 앱이 비슷한 카드를 더 보여줘요.';

  @override
  String get tapTheBookmarkLandsHere =>
      '카드의 북마크를 누르면 여기에 모여요 — 생각을 바꾼 카드를 간직하세요.';

  @override
  String get nudgeTitle => '오늘의 다섯 장이 준비됐어요';

  @override
  String get nudgeFreezeTitle => '프리즈가 버티고 있어요';

  @override
  String nudgeFreezeBody(String question) {
    return '어제는 보호됐어요. 오늘: $question';
  }

  @override
  String get nudgeSureTitle => '이건 확신했었죠';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — $sure%라고 했어요.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return '2주 전엔 $read장을 읽었어요';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return '확신이 $gap점 어긋나 있었어요. 오늘: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '지금까지 $answered문제 답함. 오늘: $question';
  }

  @override
  String get friends => '친구';

  @override
  String friendsN(int n) {
    return '친구 · $n';
  }

  @override
  String get yourFriendCode => '내 친구 코드';

  @override
  String get codeCopied => '코드를 복사했어요.';

  @override
  String get addAFriend => '친구 추가';

  @override
  String get theirCode => '친구의 코드';

  @override
  String get add => '추가';

  @override
  String get noFriendsYet =>
      '아직 아무도 없어요. 친구와 코드를 교환하고 연속 기록과 확신 정확도를 비교하세요 — 답은 절대 보이지 않아요.';

  @override
  String get friendsNeedAnAccount => '비교하려면 휴대폰 앱과 계정이 필요해요. 코드는 저장돼요.';

  @override
  String get noReaderWithCode => '그 코드를 가진 독자가 없어요.';

  @override
  String get thatsYourOwnCode => '그건 당신의 코드예요.';

  @override
  String pointsOff(int n) {
    return '$n점 어긋남';
  }

  @override
  String get notMeasuredYet => '아직 측정 전';

  @override
  String get thisWeekByCalibration => '이번 주, 확신 정확도 순';

  @override
  String get notYetToday => '오늘은 아직';

  @override
  String nOfSeven(int n) {
    return '7일 중 $n일';
  }

  @override
  String get you => '나';
}
