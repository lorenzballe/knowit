// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Astute';

  @override
  String get plusName => 'Astute+';

  @override
  String get tabToday => 'Today';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabProfile => 'Profile';

  @override
  String signInNotConnected(String provider) {
    return '$provider sign-in is not connected yet. Your cards are kept on this device.';
  }

  @override
  String couldNotSignInCarryOn(String label) {
    return 'Could not sign in with $label. You can carry on without an account.';
  }

  @override
  String streakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get freezeKeptStreak => 'A freeze kept the streak';

  @override
  String countWord(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'one',
      '2': 'two',
      '3': 'three',
      '4': 'four',
      '5': 'five',
      '6': 'six',
      '7': 'seven',
      '8': 'eight',
      '9': 'nine',
      '10': 'ten',
      'other': '$n',
    });
    return '$_temp0';
  }

  @override
  String dayRead(int n, String word) {
    return 'Day $n · $word read';
  }

  @override
  String shelfEyebrow(String word) {
    return 'TODAY\'S $word';
  }

  @override
  String get tapToFlip => 'TAP TO FLIP';

  @override
  String get shareThisCard => 'Share this card';

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get saveThisPill => 'Save this pill';

  @override
  String get shareThisPill => 'Share this pill';

  @override
  String cardOf(int k, int n) {
    return 'Card $k of $n';
  }

  @override
  String tomorrowsFiveOpenIn(String when) {
    return 'Tomorrow\'s five open in $when';
  }

  @override
  String topicOpensTomorrow(String topic, String when) {
    return '$topic opens tomorrow\'s five, in $when';
  }

  @override
  String get exploreTodaysBest => 'Explore today\'s best';

  @override
  String magicUnlock(int days) {
    return 'Try $days days free';
  }

  @override
  String get getPlus => 'Get Astute+';

  @override
  String nothingInYet(String subject) {
    return 'Nothing in $subject yet.';
  }

  @override
  String get here => 'here';

  @override
  String get todaysShelf => 'Today\'s shelf';

  @override
  String get sameForEveryone => 'The same for everyone, and only today';

  @override
  String get onesThatAskTheMost => 'The ones that ask the most';

  @override
  String get acrossEveryone => 'Across everyone, not just your mix';

  @override
  String becauseSitsAtFull(String name) {
    return 'Because $name sits at full';
  }

  @override
  String get olderFromTurnedUp => 'Older cards from the subjects you turned up';

  @override
  String moreOn(String name) {
    return 'More on $name';
  }

  @override
  String get subjectReadMost => 'The subject you have read most of';

  @override
  String monthOf(String name) {
    return 'A month of $name';
  }

  @override
  String get somewhereToStart => 'Somewhere to start that is not today';

  @override
  String get searchEveryCard => 'Search every card';

  @override
  String nothingForYet(String query) {
    return 'Nothing for \"$query\" yet.';
  }

  @override
  String matching(int n) {
    return '$n matching';
  }

  @override
  String get all => 'All';

  @override
  String get theArchive => 'The archive';

  @override
  String results(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String cardsTapADay(int n) {
    return '$n cards. Tap a day to open it.';
  }

  @override
  String get whatYouHaveCovered => 'What you have covered';

  @override
  String searchNCards(int n) {
    return 'Search $n cards';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String nCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noPillsMatchFilter => 'No pills match that filter yet.';

  @override
  String nothingForTryTopic(String query) {
    return 'Nothing for \"$query\". Try a topic instead.';
  }

  @override
  String get saved => 'Saved';

  @override
  String get removedFromSaved => 'Removed from saved.';

  @override
  String get undo => 'Undo';

  @override
  String get nothingKeptYet => 'Nothing kept yet';

  @override
  String nInTopic(int n, String topic) {
    return '$n in $topic';
  }

  @override
  String get keepTheOnesYoullUse => 'Keep the ones you\'ll actually use';

  @override
  String get backToTodaysFive => 'BACK TO TODAY\'S FIVE';

  @override
  String get archive => 'Archive';

  @override
  String get yourWeek => 'Your week';

  @override
  String get nothingThisWeekYet =>
      'Nothing this week yet. Five cards start it.';

  @override
  String keptDaysOfSeven(int days) {
    return 'Kept — $days days of seven.';
  }

  @override
  String daysOfSevenFiveKeeps(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days of seven.',
      one: '1 day of seven.',
    );
    return '$_temp0 Five keeps the week.';
  }

  @override
  String get howSureAgainstHowRight => 'How sure, against how right';

  @override
  String get sureAndWrong => 'Sure, and wrong';

  @override
  String get worthGoingBackTo =>
      'The ones worth going back to. Being wrong about something you were sure of is the only cheap way to find out what you actually believe.';

  @override
  String get whereThisIsGoing => 'Where this is going';

  @override
  String ofNRight(int n) {
    return 'of $n right';
  }

  @override
  String get sayHowSureOnMore =>
      'Say how sure you are on a few more and the app will tell you what that confidence is worth.';

  @override
  String confidenceOff(int gap) {
    return 'Your confidence was $gap points off what you actually knew.';
  }

  @override
  String confidenceClosing(int gap, int before) {
    return 'Your confidence was $gap points off, against $before last week. It is closing.';
  }

  @override
  String confidenceOpened(int gap, int before) {
    return 'Your confidence was $gap points off, against $before last week. It opened up.';
  }

  @override
  String nextRung(String name) {
    return 'Next: $name';
  }

  @override
  String youSaidPercentSure(int n) {
    return 'You said $n% sure';
  }

  @override
  String rungName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Day one',
      'reading': 'Reading',
      'answering': 'Answering',
      'saying_how_sure': 'Saying how sure',
      'calibrated': 'Calibrated',
      'holding': 'Holding',
      'sharp': 'Sharp',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String rungClaim(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'day_one': 'Everybody starts here.',
      'reading': 'The habit has started.',
      'answering': 'You commit before you turn the card over.',
      'saying_how_sure': 'You put a number on what you think you know.',
      'calibrated': 'What you say you know, you know.',
      'holding': 'It stays with you weeks later.',
      'sharp': 'Sure when you should be, and right when you are.',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String stepRead(int n) {
    return '$n more cards to read';
  }

  @override
  String stepAnswer(int n) {
    return '$n more cards to answer';
  }

  @override
  String stepJudge(int n) {
    return '$n more answers with how sure you are';
  }

  @override
  String stepHold(int n) {
    return '$n more cards to hold';
  }

  @override
  String stepGap(int gap, int target) {
    return 'your confidence is $gap points off — $target does it';
  }

  @override
  String stepBeforeJudged(int n) {
    return '$n more answers before the app will judge your confidence';
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
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutBody =>
      'Your streak, saved pills and record stay on your account. This clears them from this device.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deletingAccount => 'Deleting your account…';

  @override
  String get deleteAccountQuestion => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your account, its backup and the board your friends see are deleted for good, and this device starts again from the beginning. This does not cancel Astute+: a subscription is managed in your App Store settings.';

  @override
  String get deleteAccountConfirm => 'Delete for good';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get couldNotDeleteAccount =>
      'The account could not be deleted. Try again in a moment.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signedInRecordOnAccount =>
      'Signed in. Your streak and record are on your account now.';

  @override
  String couldNotSignInWith(String label) {
    return 'Could not sign in with $label.';
  }

  @override
  String get signInNotAvailableBuild =>
      'Signing in is not available on this build.';

  @override
  String get startOverQuestion => 'Start over?';

  @override
  String get startOverBody =>
      'Wipes everything on this device — streak, saved pills, answers, your judgement record, topics and plan — and reopens the intro.';

  @override
  String get wipeIt => 'Wipe it';

  @override
  String get yourRecord => 'Your record';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get yourTopics => 'Your topics';

  @override
  String get edit => 'Edit';

  @override
  String get howWellYouKnowYourself => 'How well you know yourself';

  @override
  String get isTheGapClosing => 'Is the gap closing?';

  @override
  String get movesYouKeepMissing => 'The moves you keep missing';

  @override
  String get dailyNudge => 'Daily nudge';

  @override
  String everyDayAt(String time) {
    return 'Every day at $time';
  }

  @override
  String get yourFivePillsBeforeCoffee =>
      'Your 5 pills, before the first coffee.';

  @override
  String get browserOnlySpeaksOpen =>
      'A browser can only speak while it is open, so this one needs the phone build.';

  @override
  String get nudgeOff => 'Nudge off.';

  @override
  String nudgeOnEveryDayAt(String time) {
    return 'Nudge on, every day at $time.';
  }

  @override
  String get nudgeOnSystemSaidNo =>
      'Nudge on, but the system said no. Turn notifications on for Astute in settings.';

  @override
  String get nudgeOnNeedsPhone => 'Nudge on. Delivery needs the phone build.';

  @override
  String savedN(int n) {
    return 'Saved · $n';
  }

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get howPillsAreWritten => 'How pills are written';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String acrossNAnswersHowSure(int n) {
    return 'Across $n answers you said how sure you were. Here is what happened.';
  }

  @override
  String get perfectlyCalibratedLine =>
      'A perfectly calibrated person is right 70% of the time when they say 70%.';

  @override
  String get notEnoughAnswersYet => 'Not enough answers yet';

  @override
  String get confidenceMatchesAccuracy =>
      'Your confidence matches your accuracy';

  @override
  String overconfidentBy(int points) {
    return 'You are overconfident by $points points';
  }

  @override
  String underconfidentBy(int points) {
    return 'You are underconfident by $points points';
  }

  @override
  String saidPercent(int n) {
    return 'Said $n%';
  }

  @override
  String rightPercentOf(int pct, int right, int count) {
    return 'right $pct% ($right of $count)';
  }

  @override
  String moreOfThisToCome(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more contexts of this to come',
      one: '1 more context of this to come',
    );
    return '$_temp0';
  }

  @override
  String get seeEveryPrincipleWithPlus =>
      'See every principle with Astute plus';

  @override
  String moreBeingTracked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more being tracked',
      one: '1 more being tracked',
    );
    return '$_temp0';
  }

  @override
  String get shareMyRecord => 'SHARE MY RECORD';

  @override
  String lastCallsAgainstFirst(int n) {
    return 'Your last $n calls, against your first $n';
  }

  @override
  String closedByPoints(int n) {
    return 'Closed by $n points';
  }

  @override
  String openedByPoints(int n) {
    return 'Opened by $n points';
  }

  @override
  String get holdingSteady => 'Holding steady';

  @override
  String get measurementRunningPlus =>
      'The measurement is running. Astute+ shows you which way it is going.';

  @override
  String firstN(int n) {
    return 'First $n';
  }

  @override
  String lastN(int n) {
    return 'Last $n';
  }

  @override
  String get trackingMoreClosely =>
      'Your confidence is tracking your accuracy more closely than it did.';

  @override
  String get distanceHasGrown =>
      'The distance has grown. Worth slowing down before you commit.';

  @override
  String get noRealMovementYet =>
      'No real movement yet. This takes weeks, not days.';

  @override
  String get seeWhichWay => 'SEE WHICH WAY';

  @override
  String get spotOn => 'spot on';

  @override
  String pointsOver(int n) {
    return '$n over';
  }

  @override
  String pointsUnder(int n) {
    return '$n under';
  }

  @override
  String get plusNameCaps => 'ASTUTE+';

  @override
  String trialDaysFree(int days) {
    return '$days days free';
  }

  @override
  String get seeThePlans => 'SEE THE PLANS';

  @override
  String get recordStartsToday => 'Your record starts today.';

  @override
  String dayWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String pillReadWord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'pills read',
      one: 'pill read',
    );
    return '$_temp0';
  }

  @override
  String nPillsRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pills read',
      one: '1 pill read',
    );
    return '$_temp0';
  }

  @override
  String nWeeksKept(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks kept',
      one: '1 week kept',
    );
    return '$_temp0';
  }

  @override
  String nComingBack(int n) {
    return '$n coming back';
  }

  @override
  String nFreezesInHand(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freezes in hand',
      one: '1 freeze in hand',
    );
    return '$_temp0';
  }

  @override
  String get freePlan => 'Free plan';

  @override
  String get streakReset => 'Streak reset';

  @override
  String youMissedDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'You missed\n$n days.',
      one: 'You missed\na day.',
    );
    return '$_temp0';
  }

  @override
  String bestStreakStillRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days are',
      one: 'One day is',
    );
    return '$_temp0 still your record. Read today\'s five and the counter starts again from one.';
  }

  @override
  String get whileYouWereAway => 'While you were away';

  @override
  String pillsWentUnread(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pills went unread',
      one: '1 pill went unread',
    );
    return '$_temp0';
  }

  @override
  String stillMostKeptTopic(String topic) {
    return '$topic is still your most kept topic';
  }

  @override
  String cardsDueBackToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards you got right are due back today',
      one: '1 card you got right is due back today',
    );
    return '$_temp0';
  }

  @override
  String get startAgainWithTodaysFive => 'Start again with today\'s five';

  @override
  String moveMyReminderTo(String time) {
    return 'Move my reminder to $time';
  }

  @override
  String dailyNudgeMovedTo(String time) {
    return 'Daily nudge moved to $time.';
  }

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n of $total subjects in the mix';
  }

  @override
  String get everythingIsInDrag =>
      'Everything is in. Drag a subject down to see less of it, or all the way to zero to drop it.';

  @override
  String get next => 'Next';

  @override
  String get whatShouldWeTalkAbout => 'What should we talk about?';

  @override
  String get fivePillsADayPick =>
      'Five pills a day, written fresh each morning. Pick the topics you want in the mix — you can change them later.';

  @override
  String nSelected(int n) {
    return '$n selected';
  }

  @override
  String startWithNTopics(int n) {
    return 'Start with $n topics';
  }

  @override
  String saveNTopics(int n) {
    return 'Save $n topics';
  }

  @override
  String pickAtLeastN(int n) {
    return 'Pick at least $n';
  }

  @override
  String get swipeToSeeMore => 'Swipe to see more';

  @override
  String get tagline => 'Five smart things a day, ready to use in conversation';

  @override
  String get introTopicsTitle => 'Eighteen topics, five pills';

  @override
  String get introTopicsLine =>
      'Written fresh every morning, and checked against a source.';

  @override
  String get introQuestionTitle => 'A question, then the answer';

  @override
  String get introQuestionLine =>
      'Every pill carries the one line that makes it worth saying out loud.';

  @override
  String get introMixTitle => 'You choose the mix';

  @override
  String get introMixLine =>
      'Turn a topic down to see less of it, or off for good.';

  @override
  String get introThirtyTitle => 'Thirty seconds a day';

  @override
  String get introThirtyLine =>
      'One notification, five cards, and a streak you will not want to break.';

  @override
  String introNotifyWhen(String time) {
    return 'Tomorrow, $time';
  }

  @override
  String get introNotifyLine => 'Your five are ready. Day 1.';

  @override
  String get introOneOfFive => '1 OF 5';

  @override
  String get introDayOne => 'DAY 1';

  @override
  String get introTapTomorrow => 'TAP TOMORROW TO FIND OUT';

  @override
  String get introDayOneTomorrow => 'DAY 1 · TOMORROW';

  @override
  String get introDaySevenStreak => 'DAY 7 · FIRST STREAK';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get termsLine =>
      'By signing up you agree to our Terms of Service & Privacy Policy';

  @override
  String get skip => 'Skip';

  @override
  String get tapToRevealLower => 'tap to reveal';

  @override
  String get barMoveCaps => 'WHAT TO KEEP';

  @override
  String get theBarMoveCaps => 'THE BAR MOVE';

  @override
  String get widgetFootPlain => 'Five cards, two minutes.';

  @override
  String widgetFootStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get widgetFootDone => 'Done for today';

  @override
  String get widgetStreakStart => 'Read today\'s five to start a streak.';

  @override
  String get widgetFiveTitle => 'TODAY\'S FIVE';

  @override
  String widgetFiveRead(int n) {
    return '$n of 5 read';
  }

  @override
  String get widgetFiveDone => 'All five read';

  @override
  String get widgetFiveWaiting => 'A new five is waiting';

  @override
  String get dayStreakCaps => 'DAY STREAK';

  @override
  String sourceLabel(String source) {
    return 'Source · $source';
  }

  @override
  String get perkArchiveTitle => 'Your whole archive';

  @override
  String get perkArchiveLine => 'Every day you have read, kept for good.';

  @override
  String get plusIsActive => 'ASTUTE+ IS ACTIVE';

  @override
  String tryFreeThen(int days, String price, String suffix) {
    return 'Try $days days free, then $price$suffix';
  }

  @override
  String subscribeFor(String price, String suffix) {
    return 'Subscribe for $price$suffix';
  }

  @override
  String get noChargeTodayCancel => 'No charge today · cancel any time';

  @override
  String get chargedTodayCancel => 'Charged today · cancel any time';

  @override
  String get everyCardForYouMark => 'you.';

  @override
  String get trialStartedNoPayment =>
      'Trial started. No payment is connected in this build.';

  @override
  String get thatDidNotGoThrough => 'That did not go through.';

  @override
  String get plusIsBack => 'Astute+ is back.';

  @override
  String get nothingToRestore => 'Nothing to restore on this account.';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get perYearShort => '/yr';

  @override
  String get perMonthShort => '/mo';

  @override
  String get perYear => 'per year';

  @override
  String aMonth(String price) {
    return '$price a month';
  }

  @override
  String savePercent(int n) {
    return 'SAVE $n%';
  }

  @override
  String get perMonth => 'per month';

  @override
  String get billedMonthly => 'billed monthly';

  @override
  String get cancelTheTrial => 'Cancel the trial';

  @override
  String get cancelAnyTime => 'Cancel any time';

  @override
  String get cancelAnyTimeNoPayment =>
      'Cancel any time · No payment is taken in this build';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String planPrice(String label, String price, String per) {
    return '$label, $price $per';
  }

  @override
  String get pickASideNoRightAnswer => 'Pick a side. There is no right answer.';

  @override
  String get estimateCloseEnough => 'Estimate. Close enough counts.';

  @override
  String get tapToReveal => 'Tap to reveal';

  @override
  String closeEnoughItIs(String answer) {
    return 'Close enough · it is $answer';
  }

  @override
  String youSaidItIsCounted(String given, String answer, String band) {
    return 'You said $given · it is $answer, and $band counted';
  }

  @override
  String get youGotIt => 'You got it';

  @override
  String youSaidItIs(String given, String answer) {
    return 'You said $given · it is $answer';
  }

  @override
  String get almostEveryoneGetsThisWrong => 'Almost everyone gets this wrong';

  @override
  String lineYouSaidSure(String line, int pct) {
    return '$line · you said $pct% sure';
  }

  @override
  String get giveMeANudge => 'Give me a nudge';

  @override
  String get beingRightMattersLess =>
      'Being right matters less than knowing how often you are.';

  @override
  String get writeItBeforeTheirs => 'Write it before you read theirs.';

  @override
  String get youAnsweredThisOne => 'You answered this one.';

  @override
  String difficultyLabel(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'other': '$id',
    });
    return '$_temp0';
  }

  @override
  String commitBeforeYouTurn(String difficulty) {
    return '$difficulty · commit before you turn it over.';
  }

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get checkMyAnswer => 'Check my answer';

  @override
  String get howSureAreYou => 'How sure are you?';

  @override
  String percentSure(int n) {
    return '$n percent sure';
  }

  @override
  String get inOneLineWhy => 'In one line — why?';

  @override
  String get because => 'Because…';

  @override
  String get nowShowMeTheOtherSide => 'Now show me the other side';

  @override
  String get skipShowMeAnyway => 'Skip — show me anyway';

  @override
  String get youTookCaps => 'YOU TOOK';

  @override
  String get putSimplyCaps => 'PUT SIMPLY';

  @override
  String get explainLikeImThree => 'Explain it like I am three';

  @override
  String get whatTheOtherSideSaysCaps => 'WHAT THE OTHER SIDE SAYS';

  @override
  String get whatTheOtherSideSays => 'What the other side says';

  @override
  String theTrap(String trap) {
    return 'The trap: $trap';
  }

  @override
  String youTookTheSide(String side) {
    return 'You took the side: $side';
  }

  @override
  String atPercentSure(int n) {
    return ' at $n% sure';
  }

  @override
  String youGotThisOne(String sure) {
    return 'You got this one$sure';
  }

  @override
  String youSaidAnswer(String answer, String sure) {
    return 'You said $answer$sure';
  }

  @override
  String get swipeForTheNextOne => 'Swipe for the next one';

  @override
  String get thatWasTheOnlyOne => 'That was the only one';

  @override
  String indexOfN(int i, int n) {
    return '$i/$n';
  }

  @override
  String get couldNotRenderCard => 'Could not render the card.';

  @override
  String get textCopiedInstead => 'Text copied instead.';

  @override
  String get copiedToClipboard => 'Copied to clipboard.';

  @override
  String get rendering => 'Rendering…';

  @override
  String get theSourceGoesWithIt => 'The source goes with it';

  @override
  String get fiveADayALittleSharper => 'Five a day. A little sharper.';

  @override
  String get shareMyDay => 'Share day';

  @override
  String climbedTo(String rung) {
    return 'Today took you up to $rung';
  }

  @override
  String rightOfAsked(int right, int asked) {
    return '$right of $asked right';
  }

  @override
  String saidSure(int sure) {
    return 'said $sure% sure';
  }

  @override
  String cardsCameBack(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards came back — answer them again',
      one: '1 card came back — answer it again',
    );
    return '$_temp0';
  }

  @override
  String get cameBack => 'Came back';

  @override
  String get holdACardYouLike => 'Hold a card you like';

  @override
  String likedToday(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n liked today',
      one: '1 liked today',
    );
    return '$_temp0';
  }

  @override
  String get liked => 'Liked';

  @override
  String likedN(int n) {
    return 'Liked · $n';
  }

  @override
  String get nothingLikedYet => 'Nothing liked yet';

  @override
  String get likeThisPill => 'Like this pill';

  @override
  String get removeFromLiked => 'Remove from liked';

  @override
  String get removedFromLiked => 'Removed from liked.';

  @override
  String get lessLikeThis => 'Less like this';

  @override
  String get whatYouLikedLandsHere => 'The ones you\'d read again';

  @override
  String get holdToLikeLandsHere =>
      'Hold any card you like and it lands here — and the app deals you more of the same.';

  @override
  String get tapTheBookmarkLandsHere =>
      'Tap the bookmark on any pill and it lands here — the ones that changed how you think, kept.';

  @override
  String get nudgeTitle => 'Your five are ready';

  @override
  String get nudgeFreezeTitle => 'Your freeze is holding';

  @override
  String nudgeFreezeBody(String question) {
    return 'Yesterday is covered. Today: $question';
  }

  @override
  String get nudgeSureTitle => 'You were sure about this one';

  @override
  String nudgeSureBody(String question, int sure) {
    return '$question — you said $sure%.';
  }

  @override
  String nudgeTwoWeeksTitle(int read) {
    return 'Two weeks ago you had read $read cards';
  }

  @override
  String nudgeTwoWeeksBody(int gap, String question) {
    return 'Your confidence sat $gap points off. Today: $question';
  }

  @override
  String nudgeTwoWeeksBodyNoGap(int answered, String question) {
    return '$answered answered so far. Today: $question';
  }

  @override
  String get friends => 'Friends';

  @override
  String friendsN(int n) {
    return 'Friends · $n';
  }

  @override
  String get yourFriendCode => 'Your friend code';

  @override
  String get codeCopied => 'Code copied.';

  @override
  String get addAFriend => 'Add a friend';

  @override
  String get theirCode => 'Their code';

  @override
  String get add => 'Add';

  @override
  String get noFriendsYet =>
      'Nobody yet. Swap codes with a friend and compare streaks and calibration — never answers.';

  @override
  String get friendsNeedAnAccount =>
      'Comparing needs the phone app and an account. Your codes are kept.';

  @override
  String get noReaderWithCode => 'No reader with that code.';

  @override
  String get thatsYourOwnCode => 'That\'s your own code.';

  @override
  String pointsOff(int n) {
    return '$n points off';
  }

  @override
  String get notMeasuredYet => 'not measured yet';

  @override
  String get thisWeekByCalibration => 'This week, by calibration';

  @override
  String get notYetToday => 'not yet today';

  @override
  String nOfSeven(int n) {
    return '$n of 7';
  }

  @override
  String get you => 'You';

  @override
  String get todaysQuestion => 'Today\'s question';

  @override
  String get right => 'right';

  @override
  String get wrong => 'wrong';

  @override
  String rightAtSure(int sure) {
    return 'right, $sure% sure';
  }

  @override
  String wrongAtSure(int sure) {
    return 'wrong, $sure% sure';
  }

  @override
  String get yourJourney => 'Your journey';

  @override
  String get thePath => 'The path';

  @override
  String get youAreHere => 'YOU ARE HERE';

  @override
  String reachedOn(String date) {
    return 'Reached $date';
  }

  @override
  String readSoFar(int n, int of) {
    return '$n of $of read so far';
  }

  @override
  String nRead(int n) {
    return '$n read';
  }

  @override
  String get topLevel => 'Top level';

  @override
  String plusNToday(int n) {
    return '+$n today';
  }

  @override
  String get bySubject => 'By subject';

  @override
  String get pts => 'points';

  @override
  String nStillWithYou(int n) {
    return '$n still with you';
  }

  @override
  String nMoves(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String get scoreStartsToday => 'Your score starts with today\'s five.';

  @override
  String get anonymousUsage => 'Usage data';

  @override
  String get anonymousUsageLine =>
      'How the app is used — what gets read, kept and said, and what goes wrong — so the next cards are better ones. Never your name, your email, or anything you write.';

  @override
  String get usageOn => 'Shared, without your name or your words.';

  @override
  String get usageOff => 'Nothing more is measured.';

  @override
  String get yourMix => 'Your mix';

  @override
  String get genresLine =>
      'Tap a genre to skip it. Hold one and the smaller topics inside open right below.';

  @override
  String get insideGenre => 'Inside';

  @override
  String nOfSixOn(int n, int total) {
    return '$n of $total on';
  }

  @override
  String get offInYourMix => 'off in your mix';

  @override
  String continueGenresOn(int on, int total) {
    return 'Continue · $on of $total genres on';
  }

  @override
  String get mixRarely => 'Rarely';

  @override
  String get mixSometimes => 'Sometimes';

  @override
  String get mixOften => 'Often';

  @override
  String get mixALot => 'A lot';

  @override
  String get mixFull => 'Full';

  @override
  String get forYouChip => 'FOR YOU';

  @override
  String get againChip => 'AGAIN';

  @override
  String get magicLine =>
      'Five cards a day chosen for you: from your mix, at your level, never one you have read. From tomorrow.';

  @override
  String get everyCardForYou => 'Every card, chosen for you.';

  @override
  String get perkOwnTitle => 'Five cards a day, all yours';

  @override
  String get perkOwnLine =>
      'From your strands, at your level, never one you have read. Free days give you two.';

  @override
  String get plusCardHeadline => 'Make all five yours.';

  @override
  String get plusCardLine =>
      'Five cards a day from your mix, at your level. Your journey. Your whole archive.';

  @override
  String get continueFree => 'Continue free';

  @override
  String get archiveBeforeThisWeek => 'Before this week';

  @override
  String get weekKeptThreeOwn =>
      'A week kept: tomorrow three of the five are yours.';

  @override
  String get perkJourneyLine =>
      'Your level, every subject strand by strand, what stayed, and the card to say tonight.';

  @override
  String get topOfTheWeek => 'Top of the week';

  @override
  String get topOfTheMonth => 'Top of the month';

  @override
  String topIn(String subject) {
    return 'Top in $subject';
  }

  @override
  String get topLineWeek => 'Most liked, saved and said in the last 7 days';

  @override
  String get topLineMonth => 'Most liked, saved and said in the last 30 days';

  @override
  String get topWeek => 'Week';

  @override
  String get topMonth => 'Month';

  @override
  String topReaders(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n readers',
      one: '1 reader',
    );
    return '$_temp0';
  }

  @override
  String get topEmpty =>
      'Nothing on the list yet. Every card you like, save or say counts.';

  @override
  String get readMark => 'Read';

  @override
  String get lovedSinceTheStart => 'Loved since the start';

  @override
  String lovedIn(String subject) {
    return 'Loved in $subject';
  }

  @override
  String get lovedLine => 'What readers kept most, and you have not read yet';

  @override
  String get forYouShelf => 'For you';

  @override
  String get forYouLine => 'What your reading puts first';

  @override
  String get exploreOffline =>
      'You are offline. This is Explore as it was last read.';

  @override
  String get askYourselfCaps => 'ASK YOURSELF';

  @override
  String get themeMyths => 'Myths, busted';

  @override
  String get themeMythsLine =>
      'What almost everyone believes, and why it is wrong';

  @override
  String get themeParadoxes => 'Paradoxes';

  @override
  String get themeParadoxesLine =>
      'Two true things that should not both be true';

  @override
  String get themeNumbers => 'Numbers that surprise';

  @override
  String get themeNumbersLine => 'Where the figure is the twist';

  @override
  String get themePractical => 'Use it today';

  @override
  String get themePracticalLine => 'Something to try before tonight';

  @override
  String get themeOrigins => 'Where it came from';

  @override
  String get themeOriginsLine => 'The beginnings of things you use every day';

  @override
  String get themeStories => 'True stories';

  @override
  String get themeStoriesLine => 'Things that really happened';

  @override
  String get themeDebates => 'Pick a side';

  @override
  String get themeDebatesLine => 'No right answer, only a better argument';

  @override
  String get themeWorkItOut => 'Work it out';

  @override
  String get themeWorkItOutLine => 'A number to reach in your head';

  @override
  String get themeSeen => 'Seen, not read';

  @override
  String get themeSeenLine => 'Cards that draw their point';

  @override
  String get themeSharpest => 'For the sharpest';

  @override
  String get themeSharpestLine => 'The hardest cards there are';

  @override
  String get themePast0 => 'The ancient world';

  @override
  String get themePast1 => 'The 1600s to the 1800s';

  @override
  String get themePast2 => 'The last century';

  @override
  String get themePastLine => 'A different age every time it comes round';

  @override
  String get themePlace0 => 'Asia and the Middle East';

  @override
  String get themePlace1 => 'The Americas';

  @override
  String get themePlace2 => 'Europe';

  @override
  String get themePlaceLine =>
      'A different part of the world every time it comes round';

  @override
  String get themeTrueOrFalse => 'True or false?';

  @override
  String get themeTrueOrFalseLine =>
      'Decide before you flip. Most people get these wrong';

  @override
  String get themeReasoning => 'Just reasoning';

  @override
  String get themeReasoningLine =>
      'No facts to know: only a way to think it through';

  @override
  String get themeIdeas => 'Big ideas';

  @override
  String get themeIdeasLine => 'The theory behind things, one idea at a time';

  @override
  String get themeCurious => 'Just curious';

  @override
  String get themeCuriousLine => 'For the pleasure of knowing why';

  @override
  String get themeMoving => 'Still moving';

  @override
  String get themeMovingLine =>
      'Things that are changing now, and why they matter';

  @override
  String get themeHowItWorks => 'How it really works';

  @override
  String get themeHowItWorksLine =>
      'The mechanism behind something you see every day';

  @override
  String get themePuzzles => 'Work it out';

  @override
  String get themePuzzlesLine =>
      'Puzzles you can solve with a pen and a minute';

  @override
  String get weekRecapCaps => 'THIS WEEK YOU ASKED YOURSELF';

  @override
  String get weekRecapLine => 'The questions your cards left you with';

  @override
  String weekRecapMore(int n) {
    return '$n more from your week with Plus';
  }

  @override
  String get plusInTheApp =>
      'Astute+ is in the app: download Astute on iPhone or Android to start your free trial.';

  @override
  String get purchaseComplete => 'Purchase complete.';

  @override
  String get successWelcome =>
      'Welcome to Astute+. Today’s five cards are ready.';

  @override
  String successWelcomeNamed(String name) {
    return 'Welcome to Astute+, $name. Today’s five cards are ready.';
  }

  @override
  String get successFiveCards => '5 cards a day';

  @override
  String get successArchive => 'Full archive';

  @override
  String successPlanName(String plan) {
    return 'Astute+ $plan';
  }

  @override
  String successFreeUntil(String date, String price, String suffix) {
    return 'Free until $date, then $price$suffix';
  }

  @override
  String successRenewsLine(String date, String price, String suffix) {
    return 'Renews $date · $price$suffix';
  }

  @override
  String get successReceipt => 'Receipt';

  @override
  String get letsStart => 'Let’s start';

  @override
  String successFootFirstCharge(String date) {
    return 'First charge $date · cancel any time';
  }

  @override
  String successFootRenews(String date) {
    return 'Renews $date · cancel any time';
  }

  @override
  String get tryToday => 'TRY TODAY';

  @override
  String minutesShort(int n) {
    return '$n MIN';
  }

  @override
  String get sideOr => 'or';

  @override
  String get nextStep => 'Next step';

  @override
  String get showAllSteps => 'Show all';

  @override
  String get revealSeePicture => 'See the picture';

  @override
  String get revealPlayScene => 'Play with it';

  @override
  String get revealBackToAnswer => 'Back to the answer';

  @override
  String get revealShowWorking => 'Show the working';

  @override
  String get sceneLockIn => 'LOCK IT IN';

  @override
  String get sceneYou => 'YOU';

  @override
  String get sceneTruth => 'TRUTH';

  @override
  String get sceneTryAgain => 'Try again';

  @override
  String get sceneDrawHint => 'Draw your guess with your finger';

  @override
  String get sceneHoldHint => 'Press and hold';

  @override
  String get sceneSwipeHint => 'Swipe or tap';

  @override
  String get sceneTapToPick => 'Tap your pick';

  @override
  String get sceneShowMe => 'Show me';

  @override
  String get sceneYourGuess => 'Your guess';

  @override
  String sceneNOfM(int n, int m) {
    return '$n of $m';
  }

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get reportedThanks => 'Reported. Thank you.';

  @override
  String get reportTitle => 'What\'s wrong with this card?';

  @override
  String get reportLead =>
      'We check every report against the sources and fix the card.';

  @override
  String get reportFact => 'A fact is wrong';

  @override
  String get reportAnswer => 'The answer marked right is wrong';

  @override
  String get reportSource => 'The source doesn\'t back it up';

  @override
  String get reportUnclear => 'It\'s confusing';

  @override
  String get reportTypo => 'A typo or a broken line';

  @override
  String get reportOther => 'Something else';

  @override
  String get reportNoteHint => 'Anything that helps us check it (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportSentToast => 'Thanks. We\'ll check it.';

  @override
  String get journeyPointsOff => 'points off';

  @override
  String journeyOffNotYet(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more answers with how sure, and it is measured.',
      one: 'One more answer with how sure, and it is measured.',
    );
    return '$_temp0';
  }

  @override
  String get journeyYourScore => 'Your score';

  @override
  String journeyPointsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'points',
      one: 'point',
    );
    return '$_temp0';
  }

  @override
  String journeyGainedIn(String n) {
    return '+$n in 4 weeks';
  }

  @override
  String journeyWeekSoFar(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'This week so far, you earned $n points.',
      one: 'This week so far, you earned 1 point.',
    );
    return '$_temp0';
  }

  @override
  String journeyWeekOf(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In the week of $date, you earned $n points.',
      one: 'In the week of $date, you earned 1 point.',
    );
    return '$_temp0';
  }

  @override
  String journeyCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String journeyScoreCaption(String date) {
    return 'Your score at the end of each week since $date. Tap a point to see that week.';
  }

  @override
  String journeyLevelOf(int n, int of) {
    return 'Level $n of $of';
  }

  @override
  String journeyStepFrom(String what, String rung) {
    return '$what\nfrom $rung';
  }

  @override
  String journeyToGoCards(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoAnswers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n answers',
      one: '1 answer',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoSure(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n answers with how sure',
      one: '1 answer with how sure',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoHeld(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cards held',
      one: '1 card held',
    );
    return '$_temp0';
  }

  @override
  String journeyToGoPoints(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get journeyWorth => 'Worth';

  @override
  String journeyBooks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String journeyOrDocumentaries(int h) {
    return 'or $h h of documentaries';
  }

  @override
  String journeyToFirstBook(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n to the first book',
      one: '1 to the first book',
    );
    return '$_temp0';
  }

  @override
  String get journeyInARow => 'In a row';

  @override
  String journeyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String journeyBestActive(int best, int active, int days) {
    return 'Best $best · $active of $days';
  }

  @override
  String journeySubjectsOf(int n, int of) {
    return '$n of $of';
  }

  @override
  String journeySubjectsDashed(String month) {
    return 'subjects · dashed: $month';
  }

  @override
  String get journeySubjects => 'subjects';

  @override
  String get journeyHowHard => 'How hard';

  @override
  String get journeyOfThree => 'of 3';

  @override
  String get journeyHardNow => 'The cards you open.';

  @override
  String journeyHardThen(String v, String month) {
    return 'The cards you open. $v in $month';
  }

  @override
  String get journeyReadingTime => 'Reading time';

  @override
  String journeyHoursMinutes(int h, String m) {
    return '$h h $m';
  }

  @override
  String journeyMinutes(int m) {
    return '$m min';
  }

  @override
  String journeyMinAWeek(int now, int was) {
    return '$now min a week, from $was';
  }

  @override
  String journeyMinThisWeek(int m) {
    return '$m min this week';
  }

  @override
  String get journeyTimedFromToday => 'Counted from today';

  @override
  String journeyPointsOffFrom(int was) {
    return 'points off, from $was';
  }

  @override
  String journeyRungOrLess(String rung, int n) {
    return '$rung · $n or less';
  }

  @override
  String get journeyRightWhenSure => 'Right when sure';

  @override
  String journeyFromIn(String v, String month) {
    return 'From $v in $month';
  }

  @override
  String get journeySureNone => 'Nothing said at 80% or more yet';

  @override
  String get journeyMovesTitle => 'Moves you can spot';

  @override
  String journeyOfN(int n) {
    return 'of $n';
  }

  @override
  String journeyNewest(String name) {
    return 'Newest: $name';
  }

  @override
  String get journeyNoneYet => 'None yet';

  @override
  String journeyStillWithYou(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'cards still with you',
      one: 'card still with you',
    );
    return '$_temp0';
  }

  @override
  String journeyRecallDays(int right, int of, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'a day',
    );
    return '$right of $of after $_temp0';
  }

  @override
  String journeyRecallWeeks(int right, int of, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: 'a week',
    );
    return '$right of $of after $_temp0';
  }

  @override
  String journeyActiveDays(int active, int days) {
    return '$active of $days days';
  }

  @override
  String get journeyMostlyMorning => 'Mostly mornings';

  @override
  String get journeyMostlyAfternoon => 'Mostly afternoons';

  @override
  String get journeyMostlyEvening => 'Mostly evenings';

  @override
  String get journeyMostlyNight => 'Mostly at night';

  @override
  String get journeyInTime => 'In time';

  @override
  String journeyYears(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString years';
  }

  @override
  String journeyFromEra(String era) {
    return 'from $era to this year';
  }

  @override
  String get journeyEraAncient => 'the ancient world';

  @override
  String get journeyEraMedieval => 'the Middle Ages';

  @override
  String get journeyEraEarlyModern => 'the 1500s';

  @override
  String get journeyEraNineteenth => 'the 1800s';

  @override
  String get journeyEraTwentieth => 'the 1900s';

  @override
  String get journeyEraRecent => '2000';

  @override
  String get journeyNothingDated => 'nothing dated yet';

  @override
  String get journeyInPlace => 'In place';

  @override
  String journeyRegions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regions',
      one: '1 region',
    );
    return '$_temp0';
  }

  @override
  String journeyPlacesAndSpace(String list) {
    return '$list, and space';
  }

  @override
  String get journeyRegionAmericas => 'the Americas';

  @override
  String get journeyRegionEurope => 'Europe';

  @override
  String get journeyRegionAsia => 'Asia';

  @override
  String get journeyRegionOceania => 'Oceania';

  @override
  String get journeyRegionAfrica => 'Africa';

  @override
  String get journeyRegionMiddleEast => 'the Middle East';

  @override
  String get journeyNoPlace => 'no place yet';

  @override
  String get journeyTopics => 'Topics';

  @override
  String journeyMet(int n) {
    return '$n met';
  }

  @override
  String journeyTopicsMost(int n, String subject) {
    return '$n of them in $subject';
  }

  @override
  String get journeyWords => 'Words';

  @override
  String journeyNew(int n) {
    return '$n new';
  }

  @override
  String get aMove => 'A move';

  @override
  String get anotherOne => 'Another';

  @override
  String answerIs(String said) {
    return 'Answer: $said';
  }

  @override
  String get answeredAlready => 'Answered already';

  @override
  String get anyCard => 'Any subject, any shelf, one card';

  @override
  String betN(int n) {
    return 'Bet $n';
  }

  @override
  String get betSlip => 'Your bet slip';

  @override
  String get betWord => 'Bet';

  @override
  String get biggerLabel => 'Bigger';

  @override
  String get biggerNote => 'Each figure is a card\'s own answer.';

  @override
  String biggerScore(int right, int asked) {
    return 'Right on $right of $asked.';
  }

  @override
  String get biggerYouGotIt => 'Bigger · you got it';

  @override
  String cameBackAfterDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'After $n days',
      one: 'After a day',
    );
    return '$_temp0';
  }

  @override
  String get cameBackAfterWeek => 'After a week';

  @override
  String cameBackAfterWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'After $n weeks',
      one: 'After a week',
    );
    return '$_temp0';
  }

  @override
  String get check => 'Check';

  @override
  String closerDone(String said, int right, int steps) {
    return 'It is $said. You got $right of $steps.';
  }

  @override
  String closerNoLess(String v) {
    return 'No: it is less than $v.';
  }

  @override
  String closerNoMore(String v) {
    return 'No: it is more than $v.';
  }

  @override
  String get closerStart => 'Three steps to close in on it.';

  @override
  String closerYesLess(String v) {
    return 'Right: it is less than $v.';
  }

  @override
  String closerYesMore(String v) {
    return 'Right: it is more than $v.';
  }

  @override
  String get corrections => 'Corrections';

  @override
  String get didYouKnow => 'Did you know?';

  @override
  String get didYouKnowLine => 'Turn it over, then: new to you, or knew it?';

  @override
  String get dragToSet => 'Drag to set';

  @override
  String get dykAgain => 'Again';

  @override
  String dykKnew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n you knew',
      one: '1 you knew',
      zero: 'None you knew',
    );
    return '$_temp0';
  }

  @override
  String dykNew(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new to you',
      one: '1 new to you',
      zero: 'Nothing new today',
    );
    return '$_temp0';
  }

  @override
  String get editionEnd => 'That\'s today\'s edition';

  @override
  String get editionTomorrow => 'Tomorrow\'s is out in the morning';

  @override
  String get eraAncient => 'The ancient world';

  @override
  String get eraAncientWhen => 'Before 500';

  @override
  String get eraEarlyModern => 'The early modern age';

  @override
  String get eraEarlyModernWhen => '1500 to 1800';

  @override
  String get eraMedieval => 'The Middle Ages';

  @override
  String get eraMedievalWhen => '500 to 1500';

  @override
  String eraMore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more from this age',
      one: '1 more from this age',
    );
    return '$_temp0';
  }

  @override
  String get eraNineteenth => 'The nineteenth century';

  @override
  String get eraNineteenthWhen => '1800 to 1900';

  @override
  String get eraRecent => 'This century';

  @override
  String get eraRecentWhen => 'Since 2000';

  @override
  String get eraRulerNow => 'Now';

  @override
  String get eraRulerOld => 'Antiquity';

  @override
  String get eraShortAncient => 'Antiquity';

  @override
  String get eraShortEarlyModern => '1500–1800';

  @override
  String get eraShortMedieval => 'Middle Ages';

  @override
  String get eraShortNineteenth => '1800s';

  @override
  String get eraShortRecent => '2000s';

  @override
  String get eraShortTwentieth => '1900s';

  @override
  String get eraTwentieth => 'The last century';

  @override
  String get eraTwentiethWhen => '1900 to 2000';

  @override
  String get fewCards => 'In a few cards';

  @override
  String get fewCardsLine => 'When one card isn\'t enough to explain it';

  @override
  String get firstLabel => 'First';

  @override
  String get forYouNow => 'For you, right now';

  @override
  String get goNarrow =>
      'Go narrow when you\'re sure: it pays three times as much.';

  @override
  String get hardBadge => 'Hard';

  @override
  String hidesIn(String where) {
    return 'In $where';
  }

  @override
  String get howSure => 'How sure am I, and why?';

  @override
  String get inNumbers => 'In numbers';

  @override
  String inRange(int pts, String said) {
    return 'In range: +$pts points. It is $said.';
  }

  @override
  String inYourMoves(int n) {
    return 'In your moves · $n×';
  }

  @override
  String itIs(String said) {
    return 'It is $said.';
  }

  @override
  String get knewIt => 'Knew it';

  @override
  String get less => 'Less';

  @override
  String get lookFirst => 'Look at the chart before you believe the headline.';

  @override
  String get markTried => 'Tried it';

  @override
  String minutesLabel(int n) {
    return '$n min';
  }

  @override
  String missedRange(String said) {
    return 'Missed: it is $said.';
  }

  @override
  String get modeBigger => 'Which is bigger?';

  @override
  String get modeBiggerLine =>
      'Two figures you can work out. Tap the bigger one';

  @override
  String get modeCloser => 'Closer, closer';

  @override
  String get modeCloserLine =>
      'Three steps of more or less to close in on the number';

  @override
  String get modePick => 'Pick one';

  @override
  String get modePickLine => 'Three amounts. Commit before you open the card';

  @override
  String get modeRange => 'Bet a range';

  @override
  String get modeRangeLine =>
      'The narrower you go, the more it pays, if you\'re right';

  @override
  String get modeSlide => 'Move it';

  @override
  String get modeSlideLine =>
      'Set your answer first, then see how far off you were';

  @override
  String get modeStake => 'Place your bet';

  @override
  String modeStakeLine(int n) {
    return '$n points a day. Win and you double your stake';
  }

  @override
  String get monthShelfLine =>
      'A new subject every month, the same for everyone';

  @override
  String moodMeta(int cards, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      cards,
      locale: localeName,
      other: '$cards cards',
      one: '1 card',
    );
    return '$_temp0 · $minutes min';
  }

  @override
  String get moodTime => 'Time you have';

  @override
  String get moodTitle => 'Your mood, your minutes';

  @override
  String get moodTone => 'Tone';

  @override
  String get more => 'More';

  @override
  String moreOrLess(String v) {
    return 'More or less than $v?';
  }

  @override
  String get moveComparedToWhat => 'Compared to what';

  @override
  String get moveComparedToWhatLine =>
      'A change means nothing without a control';

  @override
  String get moveSampling => 'Sampling';

  @override
  String get moveSamplingLine =>
      'Who ended up in the sample decides what it can say';

  @override
  String mythDeckHint(int at, int of) {
    return '$at of $of · swipe to turn it over';
  }

  @override
  String nOfM(int at, int of) {
    return '$at of $of';
  }

  @override
  String get newMove => 'New to you';

  @override
  String get newToMe => 'New to me';

  @override
  String get notEnoughPoints => 'Not enough points';

  @override
  String get notSureLine => 'One card from anywhere in Astute';

  @override
  String get notSureTitle => 'Not sure where to start?';

  @override
  String get openWord => 'Open';

  @override
  String get pickOneFirst => 'Pick one first';

  @override
  String pointsToday(int n) {
    return '+$n today';
  }

  @override
  String get puzzleOfTheDay => 'Puzzle of the day';

  @override
  String rangeWidth(int w, int pts) {
    return '±$w · $pts pts';
  }

  @override
  String get rightLastTime => 'Right last time';

  @override
  String get sameForEveryoneCaps => 'The same for everyone';

  @override
  String get sayFalse => 'False';

  @override
  String get sayTrue => 'True';

  @override
  String get seriesAnchors => 'First impressions';

  @override
  String get seriesGrowth => 'Numbers that run away';

  @override
  String seriesMeta(int n, int m) {
    return '$n cards · about $m min';
  }

  @override
  String get seriesOdds => 'Odds that lie';

  @override
  String get seriesRetold => 'History, retold';

  @override
  String seriesStrand(String name) {
    return '$name, in a few cards';
  }

  @override
  String get seriesStudies => 'Why studies mislead';

  @override
  String showAllN(int n) {
    return 'Show all $n';
  }

  @override
  String get showFewer => 'Show fewer';

  @override
  String get sixtyAgain => 'Play again';

  @override
  String sixtyIn(int s) {
    return 'in $s seconds';
  }

  @override
  String get sixtyLine => 'Eight true or false. Go with your gut';

  @override
  String get sixtyPerfect => 'All eight right.';

  @override
  String sixtyScore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n right so far',
      one: '1 right so far',
      zero: 'None right yet',
    );
    return '$_temp0';
  }

  @override
  String get sixtySecondsFor => 'seconds for eight\ntrue or false';

  @override
  String sixtySecondsLeft(int s) {
    return '$s s';
  }

  @override
  String get sixtyStart => 'Start';

  @override
  String get sixtyTimeUp => 'before the time ran out';

  @override
  String get sixtyTitle => 'Sixty seconds';

  @override
  String slideAverage(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n points off, on average.',
      one: '1 point off, on average.',
      zero: 'Spot on, on average.',
    );
    return '$_temp0';
  }

  @override
  String get slideNote =>
      'Set it, check it. How far off you were is the point.';

  @override
  String slideOff(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'You were $n points off.',
      one: 'You were 1 point off.',
      zero: 'Spot on.',
    );
    return '$_temp0';
  }

  @override
  String get slipEmpty => 'No bets yet. Each one you place lands here.';

  @override
  String get stakeLabel => 'Stake';

  @override
  String stepOf(int at, int of) {
    return 'Step $at of $of';
  }

  @override
  String get surpriseMe => 'Surprise me';

  @override
  String get tapIfBigger => 'Tap if bigger';

  @override
  String get tapToTurn => 'Tap to turn it over';

  @override
  String get tfRight => 'Right. Open it for why.';

  @override
  String tfWrong(String side) {
    return 'It\'s $side. Open it for why.';
  }

  @override
  String theAnswer(String said) {
    return 'The answer: $said.';
  }

  @override
  String get theAstute => 'The Astute';

  @override
  String get theLead => 'The lead';

  @override
  String get throughTime => 'Through time';

  @override
  String get throughTimeLine =>
      'From the ancient world to this year. Drag to travel';

  @override
  String get todayLabel => 'Today';

  @override
  String get todaysEdition => 'Today\'s edition';

  @override
  String get toneCurious => 'Curious';

  @override
  String get toneLight => 'Light';

  @override
  String get toneSerious => 'Serious';

  @override
  String get toneTough => 'Tough';

  @override
  String get unmaskBack => 'Show it as published';

  @override
  String get unmaskFlipped => 'Turn it the right way up';

  @override
  String get unmaskLine => 'Same numbers, a different picture';

  @override
  String get unmaskStretched => 'Use a fair scale';

  @override
  String get unmaskTitle => 'Unmask the chart';

  @override
  String get unmaskTotals => 'Make the comparison fair';

  @override
  String get unmaskTruncated => 'Start the axis at zero';

  @override
  String get unmaskWindow => 'Show the whole series';

  @override
  String get whatIfTrue => 'What if it\'s true?';

  @override
  String get whatIfTrueLine => 'Cards that keep working after you close them';

  @override
  String get whatYouBelieve => 'What you believe';

  @override
  String get wrongLastTime => 'Wrong last time';

  @override
  String youLose(int n) {
    return 'You lose $n.';
  }

  @override
  String youWin(int n) {
    return 'You win $n.';
  }

  @override
  String get yourPick => 'Your pick';
}
