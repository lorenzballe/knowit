import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Astut'**
  String get appName;

  /// No description provided for @plusName.
  ///
  /// In en, this message translates to:
  /// **'Astut+'**
  String get plusName;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @signInNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{provider} sign-in is not connected yet. Your cards are kept on this device.'**
  String signInNotConnected(String provider);

  /// No description provided for @couldNotSignInCarryOn.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with {label}. You can carry on without an account.'**
  String couldNotSignInCarryOn(String label);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String streakDays(int n);

  /// No description provided for @freezeKeptStreak.
  ///
  /// In en, this message translates to:
  /// **'A freeze kept the streak'**
  String get freezeKeptStreak;

  /// No description provided for @countWord.
  ///
  /// In en, this message translates to:
  /// **'{n, select, 1{one} 2{two} 3{three} 4{four} 5{five} 6{six} 7{seven} 8{eight} 9{nine} 10{ten} other{{n}}}'**
  String countWord(String n);

  /// No description provided for @dayRead.
  ///
  /// In en, this message translates to:
  /// **'Day {n} · {word} read'**
  String dayRead(int n, String word);

  /// No description provided for @shelfEyebrow.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S {word} · SWIPE TO REVIEW'**
  String shelfEyebrow(String word);

  /// No description provided for @weekLine.
  ///
  /// In en, this message translates to:
  /// **'Your week · {days} of 7 kept'**
  String weekLine(int days);

  /// No description provided for @tapToFlip.
  ///
  /// In en, this message translates to:
  /// **'TAP TO FLIP'**
  String get tapToFlip;

  /// No description provided for @shareThisCard.
  ///
  /// In en, this message translates to:
  /// **'Share this card'**
  String get shareThisCard;

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeFromSaved;

  /// No description provided for @saveThisPill.
  ///
  /// In en, this message translates to:
  /// **'Save this pill'**
  String get saveThisPill;

  /// No description provided for @shareThisPill.
  ///
  /// In en, this message translates to:
  /// **'Share this pill'**
  String get shareThisPill;

  /// No description provided for @cardOf.
  ///
  /// In en, this message translates to:
  /// **'Card {k} of {n}'**
  String cardOf(int k, int n);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String hoursMinutes(int h, int m);

  /// No description provided for @tomorrowsFiveOpenIn.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s five open in {when}'**
  String tomorrowsFiveOpenIn(String when);

  /// No description provided for @topicOpensTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{topic} opens tomorrow\'s five, in {when}'**
  String topicOpensTomorrow(String topic, String when);

  /// No description provided for @exploreTodaysBest.
  ///
  /// In en, this message translates to:
  /// **'Explore today\'s best'**
  String get exploreTodaysBest;

  /// No description provided for @fiveMore.
  ///
  /// In en, this message translates to:
  /// **'Five more'**
  String get fiveMore;

  /// No description provided for @unlockFiveExtra.
  ///
  /// In en, this message translates to:
  /// **'Unlock five extra pills'**
  String get unlockFiveExtra;

  /// No description provided for @nothingInYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {subject} yet.'**
  String nothingInYet(String subject);

  /// No description provided for @here.
  ///
  /// In en, this message translates to:
  /// **'here'**
  String get here;

  /// No description provided for @todaysShelf.
  ///
  /// In en, this message translates to:
  /// **'Today\'s shelf'**
  String get todaysShelf;

  /// No description provided for @sameForEveryone.
  ///
  /// In en, this message translates to:
  /// **'The same for everyone, and only today'**
  String get sameForEveryone;

  /// No description provided for @onesThatAskTheMost.
  ///
  /// In en, this message translates to:
  /// **'The ones that ask the most'**
  String get onesThatAskTheMost;

  /// No description provided for @acrossEveryone.
  ///
  /// In en, this message translates to:
  /// **'Across everyone, not just your mix'**
  String get acrossEveryone;

  /// No description provided for @becauseSitsAtFull.
  ///
  /// In en, this message translates to:
  /// **'Because {name} sits at full'**
  String becauseSitsAtFull(String name);

  /// No description provided for @olderFromTurnedUp.
  ///
  /// In en, this message translates to:
  /// **'Older cards from the subjects you turned up'**
  String get olderFromTurnedUp;

  /// No description provided for @moreOn.
  ///
  /// In en, this message translates to:
  /// **'More on {name}'**
  String moreOn(String name);

  /// No description provided for @subjectReadMost.
  ///
  /// In en, this message translates to:
  /// **'The subject you have read most of'**
  String get subjectReadMost;

  /// No description provided for @monthOf.
  ///
  /// In en, this message translates to:
  /// **'A month of {name}'**
  String monthOf(String name);

  /// No description provided for @somewhereToStart.
  ///
  /// In en, this message translates to:
  /// **'Somewhere to start that is not today'**
  String get somewhereToStart;

  /// No description provided for @searchEveryCard.
  ///
  /// In en, this message translates to:
  /// **'Search every card'**
  String get searchEveryCard;

  /// No description provided for @nothingForYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing for \"{query}\" yet.'**
  String nothingForYet(String query);

  /// No description provided for @matching.
  ///
  /// In en, this message translates to:
  /// **'{n} matching'**
  String matching(int n);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @theArchive.
  ///
  /// In en, this message translates to:
  /// **'The archive'**
  String get theArchive;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 result} other{{n} results}}'**
  String results(int n);

  /// No description provided for @cardsTapADay.
  ///
  /// In en, this message translates to:
  /// **'{n} cards. Tap a day to open it.'**
  String cardsTapADay(int n);

  /// No description provided for @whatYouHaveCovered.
  ///
  /// In en, this message translates to:
  /// **'What you have covered'**
  String get whatYouHaveCovered;

  /// No description provided for @searchNCards.
  ///
  /// In en, this message translates to:
  /// **'Search {n} cards'**
  String searchNCards(int n);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @nCards.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card} other{{n} cards}}'**
  String nCards(int n);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @noPillsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No pills match that filter yet.'**
  String get noPillsMatchFilter;

  /// No description provided for @nothingForTryTopic.
  ///
  /// In en, this message translates to:
  /// **'Nothing for \"{query}\". Try a topic instead.'**
  String nothingForTryTopic(String query);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @removedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved.'**
  String get removedFromSaved;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @nothingKeptYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing kept yet'**
  String get nothingKeptYet;

  /// No description provided for @nInTopic.
  ///
  /// In en, this message translates to:
  /// **'{n} in {topic}'**
  String nInTopic(int n, String topic);

  /// No description provided for @keepTheOnesYoullUse.
  ///
  /// In en, this message translates to:
  /// **'Keep the ones you\'ll actually use'**
  String get keepTheOnesYoullUse;

  /// No description provided for @backToTodaysFive.
  ///
  /// In en, this message translates to:
  /// **'BACK TO TODAY\'S FIVE'**
  String get backToTodaysFive;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @yourWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get yourWeek;

  /// No description provided for @nothingThisWeekYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing this week yet. Five cards start it.'**
  String get nothingThisWeekYet;

  /// No description provided for @keptDaysOfSeven.
  ///
  /// In en, this message translates to:
  /// **'Kept — {days} days of seven.'**
  String keptDaysOfSeven(int days);

  /// No description provided for @daysOfSevenFiveKeeps.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day of seven.} other{{days} days of seven.}} Five keeps the week.'**
  String daysOfSevenFiveKeeps(int days);

  /// No description provided for @howSureAgainstHowRight.
  ///
  /// In en, this message translates to:
  /// **'How sure, against how right'**
  String get howSureAgainstHowRight;

  /// No description provided for @sureAndWrong.
  ///
  /// In en, this message translates to:
  /// **'Sure, and wrong'**
  String get sureAndWrong;

  /// No description provided for @worthGoingBackTo.
  ///
  /// In en, this message translates to:
  /// **'The ones worth going back to. Being wrong about something you were sure of is the only cheap way to find out what you actually believe.'**
  String get worthGoingBackTo;

  /// No description provided for @whereThisIsGoing.
  ///
  /// In en, this message translates to:
  /// **'Where this is going'**
  String get whereThisIsGoing;

  /// No description provided for @ofNRight.
  ///
  /// In en, this message translates to:
  /// **'of {n} right'**
  String ofNRight(int n);

  /// No description provided for @sayHowSureOnMore.
  ///
  /// In en, this message translates to:
  /// **'Say how sure you are on a few more and the app will tell you what that confidence is worth.'**
  String get sayHowSureOnMore;

  /// No description provided for @confidenceOff.
  ///
  /// In en, this message translates to:
  /// **'Your confidence was {gap} points off what you actually knew.'**
  String confidenceOff(int gap);

  /// No description provided for @confidenceClosing.
  ///
  /// In en, this message translates to:
  /// **'Your confidence was {gap} points off, against {before} last week. It is closing.'**
  String confidenceClosing(int gap, int before);

  /// No description provided for @confidenceOpened.
  ///
  /// In en, this message translates to:
  /// **'Your confidence was {gap} points off, against {before} last week. It opened up.'**
  String confidenceOpened(int gap, int before);

  /// No description provided for @nextRung.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}'**
  String nextRung(String name);

  /// No description provided for @youSaidPercentSure.
  ///
  /// In en, this message translates to:
  /// **'You said {n}% sure'**
  String youSaidPercentSure(int n);

  /// No description provided for @rungName.
  ///
  /// In en, this message translates to:
  /// **'{id, select, day_one{Day one} reading{Reading} answering{Answering} saying_how_sure{Saying how sure} calibrated{Calibrated} holding{Holding} sharp{Sharp} other{{id}}}'**
  String rungName(String id);

  /// No description provided for @rungClaim.
  ///
  /// In en, this message translates to:
  /// **'{id, select, day_one{Everybody starts here.} reading{The habit has started.} answering{You commit before you turn the card over.} saying_how_sure{You put a number on what you think you know.} calibrated{What you say you know, you know.} holding{It stays with you weeks later.} sharp{Sure when you should be, and right when you are.} other{{id}}}'**
  String rungClaim(String id);

  /// No description provided for @stepRead.
  ///
  /// In en, this message translates to:
  /// **'{n} more cards to read'**
  String stepRead(int n);

  /// No description provided for @stepAnswer.
  ///
  /// In en, this message translates to:
  /// **'{n} more cards to answer'**
  String stepAnswer(int n);

  /// No description provided for @stepJudge.
  ///
  /// In en, this message translates to:
  /// **'{n} more answers with how sure you are'**
  String stepJudge(int n);

  /// No description provided for @stepHold.
  ///
  /// In en, this message translates to:
  /// **'{n} more cards to hold'**
  String stepHold(int n);

  /// No description provided for @stepGap.
  ///
  /// In en, this message translates to:
  /// **'your confidence is {gap} points off — {target} does it'**
  String stepGap(int gap, int target);

  /// No description provided for @stepBeforeJudged.
  ///
  /// In en, this message translates to:
  /// **'{n} more answers before the app will judge your confidence'**
  String stepBeforeJudged(int n);

  /// No description provided for @stepThenRung.
  ///
  /// In en, this message translates to:
  /// **'{step} → {name}'**
  String stepThenRung(String step, String name);

  /// No description provided for @rungOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{at} / {of}'**
  String rungOfTotal(int at, int of);

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your streak, saved pills and record stay on your account. This clears them from this device.'**
  String get signOutBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signedInRecordOnAccount.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Your streak and record are on your account now.'**
  String get signedInRecordOnAccount;

  /// No description provided for @couldNotSignInWith.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in with {label}.'**
  String couldNotSignInWith(String label);

  /// No description provided for @signInNotAvailableBuild.
  ///
  /// In en, this message translates to:
  /// **'Signing in is not available on this build.'**
  String get signInNotAvailableBuild;

  /// No description provided for @startOverQuestion.
  ///
  /// In en, this message translates to:
  /// **'Start over?'**
  String get startOverQuestion;

  /// No description provided for @startOverBody.
  ///
  /// In en, this message translates to:
  /// **'Wipes everything on this device — streak, saved pills, answers, your judgement record, topics and plan — and reopens the intro.'**
  String get startOverBody;

  /// No description provided for @wipeIt.
  ///
  /// In en, this message translates to:
  /// **'Wipe it'**
  String get wipeIt;

  /// No description provided for @yourRecord.
  ///
  /// In en, this message translates to:
  /// **'Your record'**
  String get yourRecord;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @yourTopics.
  ///
  /// In en, this message translates to:
  /// **'Your topics'**
  String get yourTopics;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @howWellYouKnowYourself.
  ///
  /// In en, this message translates to:
  /// **'How well you know yourself'**
  String get howWellYouKnowYourself;

  /// No description provided for @isTheGapClosing.
  ///
  /// In en, this message translates to:
  /// **'Is the gap closing?'**
  String get isTheGapClosing;

  /// No description provided for @movesYouKeepMissing.
  ///
  /// In en, this message translates to:
  /// **'The moves you keep missing'**
  String get movesYouKeepMissing;

  /// No description provided for @dailyNudge.
  ///
  /// In en, this message translates to:
  /// **'Daily nudge'**
  String get dailyNudge;

  /// No description provided for @everyDayAt.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String everyDayAt(String time);

  /// No description provided for @yourFivePillsBeforeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Your 5 pills, before the first coffee.'**
  String get yourFivePillsBeforeCoffee;

  /// No description provided for @browserOnlySpeaksOpen.
  ///
  /// In en, this message translates to:
  /// **'A browser can only speak while it is open, so this one needs the phone build.'**
  String get browserOnlySpeaksOpen;

  /// No description provided for @nudgeOff.
  ///
  /// In en, this message translates to:
  /// **'Nudge off.'**
  String get nudgeOff;

  /// No description provided for @nudgeOnEveryDayAt.
  ///
  /// In en, this message translates to:
  /// **'Nudge on, every day at {time}.'**
  String nudgeOnEveryDayAt(String time);

  /// No description provided for @nudgeOnSystemSaidNo.
  ///
  /// In en, this message translates to:
  /// **'Nudge on, but the system said no. Turn notifications on for Astut in settings.'**
  String get nudgeOnSystemSaidNo;

  /// No description provided for @nudgeOnNeedsPhone.
  ///
  /// In en, this message translates to:
  /// **'Nudge on. Delivery needs the phone build.'**
  String get nudgeOnNeedsPhone;

  /// No description provided for @howMuchYouKnow.
  ///
  /// In en, this message translates to:
  /// **'How much you know'**
  String get howMuchYouKnow;

  /// No description provided for @savedN.
  ///
  /// In en, this message translates to:
  /// **'Saved · {n}'**
  String savedN(int n);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @howPillsAreWritten.
  ///
  /// In en, this message translates to:
  /// **'How pills are written'**
  String get howPillsAreWritten;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @acrossNAnswersHowSure.
  ///
  /// In en, this message translates to:
  /// **'Across {n} answers you said how sure you were. Here is what happened.'**
  String acrossNAnswersHowSure(int n);

  /// No description provided for @perfectlyCalibratedLine.
  ///
  /// In en, this message translates to:
  /// **'A perfectly calibrated person is right 70% of the time when they say 70%.'**
  String get perfectlyCalibratedLine;

  /// No description provided for @notEnoughAnswersYet.
  ///
  /// In en, this message translates to:
  /// **'Not enough answers yet'**
  String get notEnoughAnswersYet;

  /// No description provided for @confidenceMatchesAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Your confidence matches your accuracy'**
  String get confidenceMatchesAccuracy;

  /// No description provided for @overconfidentBy.
  ///
  /// In en, this message translates to:
  /// **'You are overconfident by {points} points'**
  String overconfidentBy(int points);

  /// No description provided for @underconfidentBy.
  ///
  /// In en, this message translates to:
  /// **'You are underconfident by {points} points'**
  String underconfidentBy(int points);

  /// No description provided for @saidPercent.
  ///
  /// In en, this message translates to:
  /// **'Said {n}%'**
  String saidPercent(int n);

  /// No description provided for @rightPercentOf.
  ///
  /// In en, this message translates to:
  /// **'right {pct}% ({right} of {count})'**
  String rightPercentOf(int pct, int right, int count);

  /// No description provided for @moreOfThisToCome.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 more context of this to come} other{{n} more contexts of this to come}}'**
  String moreOfThisToCome(int n);

  /// No description provided for @seeEveryPrincipleWithPlus.
  ///
  /// In en, this message translates to:
  /// **'See every principle with Astut plus'**
  String get seeEveryPrincipleWithPlus;

  /// No description provided for @moreBeingTracked.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 more being tracked} other{{n} more being tracked}}'**
  String moreBeingTracked(int n);

  /// No description provided for @shareMyRecord.
  ///
  /// In en, this message translates to:
  /// **'SHARE MY RECORD'**
  String get shareMyRecord;

  /// No description provided for @lastCallsAgainstFirst.
  ///
  /// In en, this message translates to:
  /// **'Your last {n} calls, against your first {n}'**
  String lastCallsAgainstFirst(int n);

  /// No description provided for @closedByPoints.
  ///
  /// In en, this message translates to:
  /// **'Closed by {n} points'**
  String closedByPoints(int n);

  /// No description provided for @openedByPoints.
  ///
  /// In en, this message translates to:
  /// **'Opened by {n} points'**
  String openedByPoints(int n);

  /// No description provided for @holdingSteady.
  ///
  /// In en, this message translates to:
  /// **'Holding steady'**
  String get holdingSteady;

  /// No description provided for @measurementRunningPlus.
  ///
  /// In en, this message translates to:
  /// **'The measurement is running. Astut+ shows you which way it is going.'**
  String get measurementRunningPlus;

  /// No description provided for @firstN.
  ///
  /// In en, this message translates to:
  /// **'First {n}'**
  String firstN(int n);

  /// No description provided for @lastN.
  ///
  /// In en, this message translates to:
  /// **'Last {n}'**
  String lastN(int n);

  /// No description provided for @trackingMoreClosely.
  ///
  /// In en, this message translates to:
  /// **'Your confidence is tracking your accuracy more closely than it did.'**
  String get trackingMoreClosely;

  /// No description provided for @distanceHasGrown.
  ///
  /// In en, this message translates to:
  /// **'The distance has grown. Worth slowing down before you commit.'**
  String get distanceHasGrown;

  /// No description provided for @noRealMovementYet.
  ///
  /// In en, this message translates to:
  /// **'No real movement yet. This takes weeks, not days.'**
  String get noRealMovementYet;

  /// No description provided for @seeWhichWay.
  ///
  /// In en, this message translates to:
  /// **'SEE WHICH WAY'**
  String get seeWhichWay;

  /// No description provided for @spotOn.
  ///
  /// In en, this message translates to:
  /// **'spot on'**
  String get spotOn;

  /// No description provided for @pointsOver.
  ///
  /// In en, this message translates to:
  /// **'{n} over'**
  String pointsOver(int n);

  /// No description provided for @pointsUnder.
  ///
  /// In en, this message translates to:
  /// **'{n} under'**
  String pointsUnder(int n);

  /// No description provided for @plusNameCaps.
  ///
  /// In en, this message translates to:
  /// **'ASTUT+'**
  String get plusNameCaps;

  /// No description provided for @sevenDaysFree.
  ///
  /// In en, this message translates to:
  /// **'7 days free'**
  String get sevenDaysFree;

  /// No description provided for @watchTheGapMove.
  ///
  /// In en, this message translates to:
  /// **'Watch the gap move.'**
  String get watchTheGapMove;

  /// No description provided for @measurementFreeForever.
  ///
  /// In en, this message translates to:
  /// **'The measurement is free and always will be. Astut+ is what tells you which way it is going.'**
  String get measurementFreeForever;

  /// No description provided for @seeThePlans.
  ///
  /// In en, this message translates to:
  /// **'SEE THE PLANS'**
  String get seeThePlans;

  /// No description provided for @recordStartsToday.
  ///
  /// In en, this message translates to:
  /// **'Your record starts today.'**
  String get recordStartsToday;

  /// No description provided for @dayWord.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{day} other{days}}'**
  String dayWord(int n);

  /// No description provided for @pillReadWord.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{pill read} other{pills read}}'**
  String pillReadWord(int n);

  /// No description provided for @nPillsRead.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 pill read} other{{n} pills read}}'**
  String nPillsRead(int n);

  /// No description provided for @nWeeksKept.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 week kept} other{{n} weeks kept}}'**
  String nWeeksKept(int n);

  /// No description provided for @nComingBack.
  ///
  /// In en, this message translates to:
  /// **'{n} coming back'**
  String nComingBack(int n);

  /// No description provided for @nFreezesInHand.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 freeze in hand} other{{n} freezes in hand}}'**
  String nFreezesInHand(int n);

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @streakReset.
  ///
  /// In en, this message translates to:
  /// **'Streak reset'**
  String get streakReset;

  /// No description provided for @youMissedDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{You missed\na day.} other{You missed\n{n} days.}}'**
  String youMissedDays(int n);

  /// No description provided for @bestStreakStillRecord.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{One day is} other{{n} days are}} still your record. Read today\'s five and the counter starts again from one.'**
  String bestStreakStillRecord(int n);

  /// No description provided for @whileYouWereAway.
  ///
  /// In en, this message translates to:
  /// **'While you were away'**
  String get whileYouWereAway;

  /// No description provided for @pillsWentUnread.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 pill went unread} other{{n} pills went unread}}'**
  String pillsWentUnread(int n);

  /// No description provided for @stillMostKeptTopic.
  ///
  /// In en, this message translates to:
  /// **'{topic} is still your most kept topic'**
  String stillMostKeptTopic(String topic);

  /// No description provided for @cardsDueBackToday.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card you got right is due back today} other{{n} cards you got right are due back today}}'**
  String cardsDueBackToday(int n);

  /// No description provided for @startAgainWithTodaysFive.
  ///
  /// In en, this message translates to:
  /// **'Start again with today\'s five'**
  String get startAgainWithTodaysFive;

  /// No description provided for @moveMyReminderTo.
  ///
  /// In en, this message translates to:
  /// **'Move my reminder to {time}'**
  String moveMyReminderTo(String time);

  /// No description provided for @dailyNudgeMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Daily nudge moved to {time}.'**
  String dailyNudgeMovedTo(String time);

  /// No description provided for @whatYouAlready.
  ///
  /// In en, this message translates to:
  /// **'What you already '**
  String get whatYouAlready;

  /// No description provided for @know.
  ///
  /// In en, this message translates to:
  /// **'know'**
  String get know;

  /// No description provided for @knowIntro.
  ///
  /// In en, this message translates to:
  /// **'The subjects you pushed highest. It changes what a day asks of you in each — solid gets questions, curious gets told — not how much of it you get.'**
  String get knowIntro;

  /// No description provided for @startWithMyFirstCards.
  ///
  /// In en, this message translates to:
  /// **'Start with my first cards'**
  String get startWithMyFirstCards;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @levelCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get levelCurious;

  /// No description provided for @levelSome.
  ///
  /// In en, this message translates to:
  /// **'Some'**
  String get levelSome;

  /// No description provided for @levelSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get levelSolid;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @subjectsInTheMix.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} subjects in the mix'**
  String subjectsInTheMix(int n, int total);

  /// No description provided for @yourSpace.
  ///
  /// In en, this message translates to:
  /// **'Your '**
  String get yourSpace;

  /// No description provided for @mix.
  ///
  /// In en, this message translates to:
  /// **'mix'**
  String get mix;

  /// No description provided for @everythingIsInDrag.
  ///
  /// In en, this message translates to:
  /// **'Everything is in. Drag a subject down to see less of it, or all the way to zero to drop it.'**
  String get everythingIsInDrag;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @whatShouldWeTalkAbout.
  ///
  /// In en, this message translates to:
  /// **'What should we talk about?'**
  String get whatShouldWeTalkAbout;

  /// No description provided for @fivePillsADayPick.
  ///
  /// In en, this message translates to:
  /// **'Five pills a day, written fresh each morning. Pick the topics you want in the mix — you can change them later.'**
  String get fivePillsADayPick;

  /// No description provided for @nSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String nSelected(int n);

  /// No description provided for @startWithNTopics.
  ///
  /// In en, this message translates to:
  /// **'Start with {n} topics'**
  String startWithNTopics(int n);

  /// No description provided for @saveNTopics.
  ///
  /// In en, this message translates to:
  /// **'Save {n} topics'**
  String saveNTopics(int n);

  /// No description provided for @pickAtLeastN.
  ///
  /// In en, this message translates to:
  /// **'Pick at least {n}'**
  String pickAtLeastN(int n);

  /// No description provided for @swipeToSeeMore.
  ///
  /// In en, this message translates to:
  /// **'Swipe to see more'**
  String get swipeToSeeMore;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Five smart things a day, ready to use in conversation'**
  String get tagline;

  /// No description provided for @introTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Twelve topics, five pills'**
  String get introTopicsTitle;

  /// No description provided for @introTopicsLine.
  ///
  /// In en, this message translates to:
  /// **'Written fresh every morning, and checked against a source.'**
  String get introTopicsLine;

  /// No description provided for @introQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'A question, then the answer'**
  String get introQuestionTitle;

  /// No description provided for @introQuestionLine.
  ///
  /// In en, this message translates to:
  /// **'Every pill carries the one line that makes it worth saying out loud.'**
  String get introQuestionLine;

  /// No description provided for @introMixTitle.
  ///
  /// In en, this message translates to:
  /// **'You choose the mix'**
  String get introMixTitle;

  /// No description provided for @introMixLine.
  ///
  /// In en, this message translates to:
  /// **'Turn a topic down to see less of it, or off for good.'**
  String get introMixLine;

  /// No description provided for @introThirtyTitle.
  ///
  /// In en, this message translates to:
  /// **'Thirty seconds a day'**
  String get introThirtyTitle;

  /// No description provided for @introThirtyLine.
  ///
  /// In en, this message translates to:
  /// **'One notification, five cards, and a streak you will not want to break.'**
  String get introThirtyLine;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @termsLine.
  ///
  /// In en, this message translates to:
  /// **'By signing up you agree to our Terms of Service & Privacy Policy'**
  String get termsLine;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @tapToRevealLower.
  ///
  /// In en, this message translates to:
  /// **'tap to reveal'**
  String get tapToRevealLower;

  /// No description provided for @barMoveCaps.
  ///
  /// In en, this message translates to:
  /// **'BAR MOVE'**
  String get barMoveCaps;

  /// No description provided for @theBarMoveCaps.
  ///
  /// In en, this message translates to:
  /// **'THE BAR MOVE'**
  String get theBarMoveCaps;

  /// No description provided for @dayStreakCaps.
  ///
  /// In en, this message translates to:
  /// **'DAY STREAK'**
  String get dayStreakCaps;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source · {source}'**
  String sourceLabel(String source);

  /// No description provided for @perkRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Your record over time'**
  String get perkRecordTitle;

  /// No description provided for @perkRecordLine.
  ///
  /// In en, this message translates to:
  /// **'Whether the gap between how sure you were and how right you were is actually closing.'**
  String get perkRecordLine;

  /// No description provided for @perkPrinciplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Every principle you have met'**
  String get perkPrinciplesTitle;

  /// No description provided for @perkPrinciplesLine.
  ///
  /// In en, this message translates to:
  /// **'Not just the three you are worst at — all of them, and the contexts you have not been shown yet.'**
  String get perkPrinciplesLine;

  /// No description provided for @perkFreezesTitle.
  ///
  /// In en, this message translates to:
  /// **'Three streak freezes, not one'**
  String get perkFreezesTitle;

  /// No description provided for @perkFreezesLine.
  ///
  /// In en, this message translates to:
  /// **'Enough to cover a weekend away. A streak you can only lose is a streak that eventually goes.'**
  String get perkFreezesLine;

  /// No description provided for @perkExtraTitle.
  ///
  /// In en, this message translates to:
  /// **'5 extra pills every day'**
  String get perkExtraTitle;

  /// No description provided for @perkExtraLine.
  ///
  /// In en, this message translates to:
  /// **'A second set unlocks the moment you finish the first.'**
  String get perkExtraLine;

  /// No description provided for @perkArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'The full archive'**
  String get perkArchiveTitle;

  /// No description provided for @perkArchiveLine.
  ///
  /// In en, this message translates to:
  /// **'Every pill you have ever read, searchable by topic.'**
  String get perkArchiveLine;

  /// No description provided for @perkTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your own topics'**
  String get perkTopicsTitle;

  /// No description provided for @perkTopicsLine.
  ///
  /// In en, this message translates to:
  /// **'Weight the mix toward what you actually like.'**
  String get perkTopicsLine;

  /// No description provided for @plusIsActive.
  ///
  /// In en, this message translates to:
  /// **'ASTUT+ IS ACTIVE'**
  String get plusIsActive;

  /// No description provided for @tryFreeThen.
  ///
  /// In en, this message translates to:
  /// **'Try 7 days free, then {price}{suffix}'**
  String tryFreeThen(String price, String suffix);

  /// No description provided for @trialStartedNoPayment.
  ///
  /// In en, this message translates to:
  /// **'Trial started. No payment is connected in this build.'**
  String get trialStartedNoPayment;

  /// No description provided for @thatDidNotGoThrough.
  ///
  /// In en, this message translates to:
  /// **'That did not go through.'**
  String get thatDidNotGoThrough;

  /// No description provided for @plusIsBack.
  ///
  /// In en, this message translates to:
  /// **'Astut+ is back.'**
  String get plusIsBack;

  /// No description provided for @nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore on this account.'**
  String get nothingToRestore;

  /// No description provided for @findOutIfBetter.
  ///
  /// In en, this message translates to:
  /// **'Find out if you are actually getting better.'**
  String get findOutIfBetter;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get perYear;

  /// No description provided for @aMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} a month'**
  String aMonth(String price);

  /// No description provided for @savePercent.
  ///
  /// In en, this message translates to:
  /// **'SAVE {n}%'**
  String savePercent(int n);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @billedMonthly.
  ///
  /// In en, this message translates to:
  /// **'billed monthly'**
  String get billedMonthly;

  /// No description provided for @cancelTheTrial.
  ///
  /// In en, this message translates to:
  /// **'Cancel the trial'**
  String get cancelTheTrial;

  /// No description provided for @cancelAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Cancel any time'**
  String get cancelAnyTime;

  /// No description provided for @cancelAnyTimeNoPayment.
  ///
  /// In en, this message translates to:
  /// **'Cancel any time · No payment is taken in this build'**
  String get cancelAnyTimeNoPayment;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @everythingOpensNothingCharged.
  ///
  /// In en, this message translates to:
  /// **'Everything opens. Nothing is charged.'**
  String get everythingOpensNothingCharged;

  /// No description provided for @dayN.
  ///
  /// In en, this message translates to:
  /// **'DAY {n}'**
  String dayN(int n);

  /// No description provided for @reminderTwoDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'A reminder, two days before it renews.'**
  String get reminderTwoDaysBefore;

  /// No description provided for @itRenewsUnlessCancelled.
  ///
  /// In en, this message translates to:
  /// **'It renews, unless you cancelled. You can, any time.'**
  String get itRenewsUnlessCancelled;

  /// No description provided for @howTheFreeWeekWorks.
  ///
  /// In en, this message translates to:
  /// **'HOW THE FREE WEEK WORKS'**
  String get howTheFreeWeekWorks;

  /// No description provided for @planPrice.
  ///
  /// In en, this message translates to:
  /// **'{label}, {price} {per}'**
  String planPrice(String label, String price, String per);

  /// No description provided for @pickASideNoRightAnswer.
  ///
  /// In en, this message translates to:
  /// **'Pick a side. There is no right answer.'**
  String get pickASideNoRightAnswer;

  /// No description provided for @estimateCloseEnough.
  ///
  /// In en, this message translates to:
  /// **'Estimate. Close enough counts.'**
  String get estimateCloseEnough;

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get tapToReveal;

  /// No description provided for @closeEnoughItIs.
  ///
  /// In en, this message translates to:
  /// **'Close enough · it is {answer}'**
  String closeEnoughItIs(String answer);

  /// No description provided for @youSaidItIsCounted.
  ///
  /// In en, this message translates to:
  /// **'You said {given} · it is {answer}, and {band} counted'**
  String youSaidItIsCounted(String given, String answer, String band);

  /// No description provided for @youGotIt.
  ///
  /// In en, this message translates to:
  /// **'You got it'**
  String get youGotIt;

  /// No description provided for @youSaidItIs.
  ///
  /// In en, this message translates to:
  /// **'You said {given} · it is {answer}'**
  String youSaidItIs(String given, String answer);

  /// No description provided for @almostEveryoneGetsThisWrong.
  ///
  /// In en, this message translates to:
  /// **'Almost everyone gets this wrong'**
  String get almostEveryoneGetsThisWrong;

  /// No description provided for @lineYouSaidSure.
  ///
  /// In en, this message translates to:
  /// **'{line} · you said {pct}% sure'**
  String lineYouSaidSure(String line, int pct);

  /// No description provided for @giveMeANudge.
  ///
  /// In en, this message translates to:
  /// **'Give me a nudge'**
  String get giveMeANudge;

  /// No description provided for @beingRightMattersLess.
  ///
  /// In en, this message translates to:
  /// **'Being right matters less than knowing how often you are.'**
  String get beingRightMattersLess;

  /// No description provided for @writeItBeforeTheirs.
  ///
  /// In en, this message translates to:
  /// **'Write it before you read theirs.'**
  String get writeItBeforeTheirs;

  /// No description provided for @youAnsweredThisOne.
  ///
  /// In en, this message translates to:
  /// **'You answered this one.'**
  String get youAnsweredThisOne;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'{id, select, easy{Easy} medium{Medium} hard{Hard} other{{id}}}'**
  String difficultyLabel(String id);

  /// No description provided for @commitBeforeYouTurn.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} · commit before you turn it over.'**
  String commitBeforeYouTurn(String difficulty);

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswer;

  /// No description provided for @checkMyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check my answer'**
  String get checkMyAnswer;

  /// No description provided for @howSureAreYou.
  ///
  /// In en, this message translates to:
  /// **'How sure are you?'**
  String get howSureAreYou;

  /// No description provided for @percentSure.
  ///
  /// In en, this message translates to:
  /// **'{n} percent sure'**
  String percentSure(int n);

  /// No description provided for @inOneLineWhy.
  ///
  /// In en, this message translates to:
  /// **'In one line — why?'**
  String get inOneLineWhy;

  /// No description provided for @because.
  ///
  /// In en, this message translates to:
  /// **'Because…'**
  String get because;

  /// No description provided for @nowShowMeTheOtherSide.
  ///
  /// In en, this message translates to:
  /// **'Now show me the other side'**
  String get nowShowMeTheOtherSide;

  /// No description provided for @skipShowMeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Skip — show me anyway'**
  String get skipShowMeAnyway;

  /// No description provided for @youTookCaps.
  ///
  /// In en, this message translates to:
  /// **'YOU TOOK'**
  String get youTookCaps;

  /// No description provided for @putSimplyCaps.
  ///
  /// In en, this message translates to:
  /// **'PUT SIMPLY'**
  String get putSimplyCaps;

  /// No description provided for @explainLikeImThree.
  ///
  /// In en, this message translates to:
  /// **'Explain it like I am three'**
  String get explainLikeImThree;

  /// No description provided for @whatTheOtherSideSaysCaps.
  ///
  /// In en, this message translates to:
  /// **'WHAT THE OTHER SIDE SAYS'**
  String get whatTheOtherSideSaysCaps;

  /// No description provided for @whatTheOtherSideSays.
  ///
  /// In en, this message translates to:
  /// **'What the other side says'**
  String get whatTheOtherSideSays;

  /// No description provided for @theTrap.
  ///
  /// In en, this message translates to:
  /// **'The trap: {trap}'**
  String theTrap(String trap);

  /// No description provided for @youTookTheSide.
  ///
  /// In en, this message translates to:
  /// **'You took the side: {side}'**
  String youTookTheSide(String side);

  /// No description provided for @atPercentSure.
  ///
  /// In en, this message translates to:
  /// **' at {n}% sure'**
  String atPercentSure(int n);

  /// No description provided for @youGotThisOne.
  ///
  /// In en, this message translates to:
  /// **'You got this one{sure}'**
  String youGotThisOne(String sure);

  /// No description provided for @youSaidAnswer.
  ///
  /// In en, this message translates to:
  /// **'You said {answer}{sure}'**
  String youSaidAnswer(String answer, String sure);

  /// No description provided for @swipeForTheNextOne.
  ///
  /// In en, this message translates to:
  /// **'Swipe for the next one'**
  String get swipeForTheNextOne;

  /// No description provided for @thatWasTheOnlyOne.
  ///
  /// In en, this message translates to:
  /// **'That was the only one'**
  String get thatWasTheOnlyOne;

  /// No description provided for @indexOfN.
  ///
  /// In en, this message translates to:
  /// **'{i}/{n}'**
  String indexOfN(int i, int n);

  /// No description provided for @couldNotRenderCard.
  ///
  /// In en, this message translates to:
  /// **'Could not render the card.'**
  String get couldNotRenderCard;

  /// No description provided for @textCopiedInstead.
  ///
  /// In en, this message translates to:
  /// **'Text copied instead.'**
  String get textCopiedInstead;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard.'**
  String get copiedToClipboard;

  /// No description provided for @rendering.
  ///
  /// In en, this message translates to:
  /// **'Rendering…'**
  String get rendering;

  /// No description provided for @theSourceGoesWithIt.
  ///
  /// In en, this message translates to:
  /// **'The source goes with it'**
  String get theSourceGoesWithIt;

  /// No description provided for @fiveADayALittleSharper.
  ///
  /// In en, this message translates to:
  /// **'Five a day. A little sharper.'**
  String get fiveADayALittleSharper;

  /// No description provided for @shareMyDay.
  ///
  /// In en, this message translates to:
  /// **'Share day'**
  String get shareMyDay;

  /// No description provided for @climbedTo.
  ///
  /// In en, this message translates to:
  /// **'Today took you up to {rung}'**
  String climbedTo(String rung);

  /// No description provided for @rightOfAsked.
  ///
  /// In en, this message translates to:
  /// **'{right} of {asked} right'**
  String rightOfAsked(int right, int asked);

  /// No description provided for @saidSure.
  ///
  /// In en, this message translates to:
  /// **'said {sure}% sure'**
  String saidSure(int sure);

  /// No description provided for @cardsCameBack.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card came back — answer it again} other{{n} cards came back — answer them again}}'**
  String cardsCameBack(int n);

  /// No description provided for @cameBack.
  ///
  /// In en, this message translates to:
  /// **'Came back'**
  String get cameBack;

  /// No description provided for @holdACardYouLike.
  ///
  /// In en, this message translates to:
  /// **'Hold a card you like'**
  String get holdACardYouLike;

  /// No description provided for @likedToday.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 liked today} other{{n} liked today}}'**
  String likedToday(int n);

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get liked;

  /// No description provided for @likedN.
  ///
  /// In en, this message translates to:
  /// **'Liked · {n}'**
  String likedN(int n);

  /// No description provided for @nothingLikedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing liked yet'**
  String get nothingLikedYet;

  /// No description provided for @likeThisPill.
  ///
  /// In en, this message translates to:
  /// **'Like this pill'**
  String get likeThisPill;

  /// No description provided for @removeFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Remove from liked'**
  String get removeFromLiked;

  /// No description provided for @removedFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Removed from liked.'**
  String get removedFromLiked;

  /// No description provided for @lessLikeThis.
  ///
  /// In en, this message translates to:
  /// **'Less like this'**
  String get lessLikeThis;

  /// No description provided for @whatYouLikedLandsHere.
  ///
  /// In en, this message translates to:
  /// **'The ones you\'d read again'**
  String get whatYouLikedLandsHere;

  /// No description provided for @holdToLikeLandsHere.
  ///
  /// In en, this message translates to:
  /// **'Hold any card you like and it lands here — and the app deals you more of the same.'**
  String get holdToLikeLandsHere;

  /// No description provided for @tapTheBookmarkLandsHere.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any pill and it lands here — the ones that changed how you think, kept.'**
  String get tapTheBookmarkLandsHere;

  /// No description provided for @nudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your five are ready'**
  String get nudgeTitle;

  /// No description provided for @nudgeFreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your freeze is holding'**
  String get nudgeFreezeTitle;

  /// No description provided for @nudgeFreezeBody.
  ///
  /// In en, this message translates to:
  /// **'Yesterday is covered. Today: {question}'**
  String nudgeFreezeBody(String question);

  /// No description provided for @nudgeSureTitle.
  ///
  /// In en, this message translates to:
  /// **'You were sure about this one'**
  String get nudgeSureTitle;

  /// No description provided for @nudgeSureBody.
  ///
  /// In en, this message translates to:
  /// **'{question} — you said {sure}%.'**
  String nudgeSureBody(String question, int sure);

  /// No description provided for @nudgeTwoWeeksTitle.
  ///
  /// In en, this message translates to:
  /// **'Two weeks ago you had read {read} cards'**
  String nudgeTwoWeeksTitle(int read);

  /// No description provided for @nudgeTwoWeeksBody.
  ///
  /// In en, this message translates to:
  /// **'Your confidence sat {gap} points off. Today: {question}'**
  String nudgeTwoWeeksBody(int gap, String question);

  /// No description provided for @nudgeTwoWeeksBodyNoGap.
  ///
  /// In en, this message translates to:
  /// **'{answered} answered so far. Today: {question}'**
  String nudgeTwoWeeksBodyNoGap(int answered, String question);

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @friendsN.
  ///
  /// In en, this message translates to:
  /// **'Friends · {n}'**
  String friendsN(int n);

  /// No description provided for @yourFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Your friend code'**
  String get yourFriendCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied.'**
  String get codeCopied;

  /// No description provided for @addAFriend.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get addAFriend;

  /// No description provided for @theirCode.
  ///
  /// In en, this message translates to:
  /// **'Their code'**
  String get theirCode;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet. Swap codes with a friend and compare streaks and calibration — never answers.'**
  String get noFriendsYet;

  /// No description provided for @friendsNeedAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Comparing needs the phone app and an account. Your codes are kept.'**
  String get friendsNeedAnAccount;

  /// No description provided for @noReaderWithCode.
  ///
  /// In en, this message translates to:
  /// **'No reader with that code.'**
  String get noReaderWithCode;

  /// No description provided for @thatsYourOwnCode.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own code.'**
  String get thatsYourOwnCode;

  /// No description provided for @pointsOff.
  ///
  /// In en, this message translates to:
  /// **'{n} points off'**
  String pointsOff(int n);

  /// No description provided for @notMeasuredYet.
  ///
  /// In en, this message translates to:
  /// **'not measured yet'**
  String get notMeasuredYet;

  /// No description provided for @thisWeekByCalibration.
  ///
  /// In en, this message translates to:
  /// **'This week, by calibration'**
  String get thisWeekByCalibration;

  /// No description provided for @notYetToday.
  ///
  /// In en, this message translates to:
  /// **'not yet today'**
  String get notYetToday;

  /// No description provided for @nOfSeven.
  ///
  /// In en, this message translates to:
  /// **'{n} of 7'**
  String nOfSeven(int n);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @todaysQuestion.
  ///
  /// In en, this message translates to:
  /// **'Today\'s question'**
  String get todaysQuestion;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get right;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'wrong'**
  String get wrong;

  /// No description provided for @rightAtSure.
  ///
  /// In en, this message translates to:
  /// **'right, {sure}% sure'**
  String rightAtSure(int sure);

  /// No description provided for @wrongAtSure.
  ///
  /// In en, this message translates to:
  /// **'wrong, {sure}% sure'**
  String wrongAtSure(int sure);

  /// No description provided for @yourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your journey'**
  String get yourJourney;

  /// No description provided for @thePath.
  ///
  /// In en, this message translates to:
  /// **'The path'**
  String get thePath;

  /// No description provided for @youAreHere.
  ///
  /// In en, this message translates to:
  /// **'YOU ARE HERE'**
  String get youAreHere;

  /// No description provided for @reachedOn.
  ///
  /// In en, this message translates to:
  /// **'Reached {date}'**
  String reachedOn(String date);

  /// No description provided for @readSoFar.
  ///
  /// In en, this message translates to:
  /// **'{n} of {of} read so far'**
  String readSoFar(int n, int of);

  /// No description provided for @nRead.
  ///
  /// In en, this message translates to:
  /// **'{n} read'**
  String nRead(int n);

  /// No description provided for @levelNamed.
  ///
  /// In en, this message translates to:
  /// **'Level {n} · {name}'**
  String levelNamed(int n, String name);

  /// No description provided for @topLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get topLevel;

  /// No description provided for @plusNToday.
  ///
  /// In en, this message translates to:
  /// **'+{n} today'**
  String plusNToday(int n);

  /// No description provided for @stillWithYouOf.
  ///
  /// In en, this message translates to:
  /// **'still with you · {n} of {total}'**
  String stillWithYouOf(int n, int total);

  /// No description provided for @stillWithYouNothing.
  ///
  /// In en, this message translates to:
  /// **'still with you · nothing answered yet'**
  String get stillWithYouNothing;

  /// No description provided for @calibrationPointsOff.
  ///
  /// In en, this message translates to:
  /// **'calibration · points off'**
  String get calibrationPointsOff;

  /// No description provided for @calibrationNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'calibration · not measured yet'**
  String get calibrationNotMeasured;

  /// No description provided for @inARowBest.
  ///
  /// In en, this message translates to:
  /// **'in a row · best {n}'**
  String inARowBest(int n);

  /// No description provided for @movesYouCanSpot.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{move you can spot} other{moves you can spot}}'**
  String movesYouCanSpot(int n);

  /// No description provided for @nCardsIsAbout.
  ///
  /// In en, this message translates to:
  /// **'{n} cards is about'**
  String nCardsIsAbout(int n);

  /// No description provided for @nonFictionBooks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{non-fiction book} other{non-fiction books}}'**
  String nonFictionBooks(int n);

  /// No description provided for @hoursOfDocumentaries.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{hour of documentary} other{hours of documentaries}}'**
  String hoursOfDocumentaries(int n);

  /// No description provided for @lectures.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{lecture} other{lectures}}'**
  String lectures(int n);

  /// No description provided for @inTotalACard.
  ///
  /// In en, this message translates to:
  /// **'{time} in total · about 40 seconds a card'**
  String inTotalACard(String time);

  /// No description provided for @bySubject.
  ///
  /// In en, this message translates to:
  /// **'By subject'**
  String get bySubject;

  /// No description provided for @readOfTheShelf.
  ///
  /// In en, this message translates to:
  /// **'read · of the shelf'**
  String get readOfTheShelf;

  /// No description provided for @toSayTonight.
  ///
  /// In en, this message translates to:
  /// **'To say tonight'**
  String get toSayTonight;

  /// No description provided for @anotherOne.
  ///
  /// In en, this message translates to:
  /// **'Another one'**
  String get anotherOne;

  /// No description provided for @saidIt.
  ///
  /// In en, this message translates to:
  /// **'Said it'**
  String get saidIt;

  /// No description provided for @saidAlready.
  ///
  /// In en, this message translates to:
  /// **'Said'**
  String get saidAlready;

  /// No description provided for @justMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String justMinutes(int m);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
