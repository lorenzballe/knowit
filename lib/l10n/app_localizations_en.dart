// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Astut';

  @override
  String get plusName => 'Astut+';

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
    return 'TODAY\'S $word · SWIPE TO REVIEW';
  }

  @override
  String weekLine(int days) {
    return 'Your week · $days of 7 kept';
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
  String hoursMinutes(int h, int m) {
    return '${h}h ${m}m';
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
  String get fiveMore => 'Five more';

  @override
  String get unlockFiveExtra => 'Unlock five extra pills';

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
      'Nudge on, but the system said no. Turn notifications on for Astut in settings.';

  @override
  String get nudgeOnNeedsPhone => 'Nudge on. Delivery needs the phone build.';

  @override
  String get howMuchYouKnow => 'How much you know';

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
  String get seeEveryPrincipleWithPlus => 'See every principle with Astut plus';

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
      'The measurement is running. Astut+ shows you which way it is going.';

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
  String get plusNameCaps => 'ASTUT+';

  @override
  String get sevenDaysFree => '7 days free';

  @override
  String get watchTheGapMove => 'Watch the gap move.';

  @override
  String get measurementFreeForever =>
      'The measurement is free and always will be. Astut+ is what tells you which way it is going.';

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
  String get whatYouAlready => 'What you already ';

  @override
  String get know => 'know';

  @override
  String get knowIntro =>
      'The subjects you pushed highest. It changes what a day asks of you in each — solid gets questions, curious gets told — not how much of it you get.';

  @override
  String get startWithMyFirstCards => 'Start with my first cards';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get levelCurious => 'Curious';

  @override
  String get levelSome => 'Some';

  @override
  String get levelSolid => 'Solid';

  @override
  String get save => 'Save';

  @override
  String subjectsInTheMix(int n, int total) {
    return '$n of $total subjects in the mix';
  }

  @override
  String get yourSpace => 'Your ';

  @override
  String get mix => 'mix';

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
  String get introTopicsTitle => 'Twelve topics, five pills';

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
  String get barMoveCaps => 'BAR MOVE';

  @override
  String get theBarMoveCaps => 'THE BAR MOVE';

  @override
  String get dayStreakCaps => 'DAY STREAK';

  @override
  String sourceLabel(String source) {
    return 'Source · $source';
  }

  @override
  String get perkRecordTitle => 'Your record over time';

  @override
  String get perkRecordLine =>
      'Whether the gap between how sure you were and how right you were is actually closing.';

  @override
  String get perkPrinciplesTitle => 'Every principle you have met';

  @override
  String get perkPrinciplesLine =>
      'Not just the three you are worst at — all of them, and the contexts you have not been shown yet.';

  @override
  String get perkFreezesTitle => 'Three streak freezes, not one';

  @override
  String get perkFreezesLine =>
      'Enough to cover a weekend away. A streak you can only lose is a streak that eventually goes.';

  @override
  String get perkExtraTitle => '5 extra pills every day';

  @override
  String get perkExtraLine =>
      'A second set unlocks the moment you finish the first.';

  @override
  String get perkArchiveTitle => 'The full archive';

  @override
  String get perkArchiveLine =>
      'Every pill you have ever read, searchable by topic.';

  @override
  String get perkTopicsTitle => 'Pick your own topics';

  @override
  String get perkTopicsLine => 'Weight the mix toward what you actually like.';

  @override
  String get plusIsActive => 'ASTUT+ IS ACTIVE';

  @override
  String tryFreeThen(String price, String suffix) {
    return 'Try 7 days free, then $price$suffix';
  }

  @override
  String get trialStartedNoPayment =>
      'Trial started. No payment is connected in this build.';

  @override
  String get thatDidNotGoThrough => 'That did not go through.';

  @override
  String get plusIsBack => 'Astut+ is back.';

  @override
  String get nothingToRestore => 'Nothing to restore on this account.';

  @override
  String get findOutIfBetter => 'Find out if you are actually getting better.';

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
  String get everythingOpensNothingCharged =>
      'Everything opens. Nothing is charged.';

  @override
  String dayN(int n) {
    return 'DAY $n';
  }

  @override
  String get reminderTwoDaysBefore => 'A reminder, two days before it renews.';

  @override
  String get itRenewsUnlessCancelled =>
      'It renews, unless you cancelled. You can, any time.';

  @override
  String get howTheFreeWeekWorks => 'HOW THE FREE WEEK WORKS';

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
}
