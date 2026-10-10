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
  /// **'Astute'**
  String get appName;

  /// No description provided for @plusName.
  ///
  /// In en, this message translates to:
  /// **'Astute+'**
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
  /// **'TODAY\'S {word}'**
  String shelfEyebrow(String word);

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
  /// **'Save this card'**
  String get saveThisPill;

  /// No description provided for @shareThisPill.
  ///
  /// In en, this message translates to:
  /// **'Share this card'**
  String get shareThisPill;

  /// No description provided for @cardOf.
  ///
  /// In en, this message translates to:
  /// **'Card {k} of {n}'**
  String cardOf(int k, int n);

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

  /// The action on the card after the fifth for a reader the store will still give the free trial. {days} is the trial's length, as the store has it.
  ///
  /// In en, this message translates to:
  /// **'Try {days} days free'**
  String magicUnlock(int days);

  /// The same action for a reader who has already had the free trial, which the store gives once.
  ///
  /// In en, this message translates to:
  /// **'Get Astute+'**
  String get getPlus;

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
  /// **'No cards match that filter yet.'**
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
  /// **'Your streak, saved cards and record stay on your account. This clears them from this device.'**
  String get signOutBody;

  /// Profile row that deletes the reader's account (Apple requires it in the app).
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// The same row while the deletion runs.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get deletingAccount;

  /// Title of the confirmation before deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQuestion;

  /// Body of that confirmation: what is deleted, that it cannot be undone, and that the App Store subscription is not cancelled by it.
  ///
  /// In en, this message translates to:
  /// **'Your account, its backup and the board your friends see are deleted for good, and this device starts again from the beginning. This does not cancel Astute+: a subscription is managed in your App Store settings.'**
  String get deleteAccountBody;

  /// The destructive button of that confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete for good'**
  String get deleteAccountConfirm;

  /// Shown once the account is gone.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// Shown when the deletion failed.
  ///
  /// In en, this message translates to:
  /// **'The account could not be deleted. Try again in a moment.'**
  String get couldNotDeleteAccount;

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
  /// **'Wipes everything on this device — streak, saved cards, answers, your judgement record, topics and plan — and reopens the intro.'**
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

  /// No description provided for @journeyButtonLine.
  ///
  /// In en, this message translates to:
  /// **'Your level, the moves you keep missing, your week in questions'**
  String get journeyButtonLine;

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
  /// **'Your 5 cards, before the first coffee.'**
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
  /// **'Nudge on, but the system said no. Turn notifications on for Astute in settings.'**
  String get nudgeOnSystemSaidNo;

  /// No description provided for @nudgeOnNeedsPhone.
  ///
  /// In en, this message translates to:
  /// **'Nudge on. Delivery needs the phone build.'**
  String get nudgeOnNeedsPhone;

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
  /// **'How cards are written'**
  String get howPillsAreWritten;

  /// No description provided for @howTitle.
  ///
  /// In en, this message translates to:
  /// **'Every card here is written by an AI model.'**
  String get howTitle;

  /// No description provided for @howIntro.
  ///
  /// In en, this message translates to:
  /// **'We\'d rather say it up front than have you find out. Here is how a card reaches you.'**
  String get howIntro;

  /// No description provided for @howStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Written ahead, by a model'**
  String get howStep1Title;

  /// No description provided for @howStep1Line.
  ///
  /// In en, this message translates to:
  /// **'Each card is drafted to one brief: a question worth asking, an answer that says why, and one move you can use again.'**
  String get howStep1Line;

  /// No description provided for @howStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Checked against its source'**
  String get howStep2Title;

  /// No description provided for @howStep2Line.
  ///
  /// In en, this message translates to:
  /// **'Every card names where it comes from, and a second model reads it as a critic before it ships. What can\'t be backed up is cut.'**
  String get howStep2Line;

  /// No description provided for @howStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Five, dealt each morning'**
  String get howStep3Title;

  /// No description provided for @howStep3Line.
  ///
  /// In en, this message translates to:
  /// **'From the subjects you picked, and never one you have already read.'**
  String get howStep3Line;

  /// No description provided for @howStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Kept honest by readers'**
  String get howStep4Title;

  /// No description provided for @howStep4Line.
  ///
  /// In en, this message translates to:
  /// **'When enough readers say a card is wrong, it stops being dealt until a person has checked it.'**
  String get howStep4Line;

  /// No description provided for @howReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Found something wrong?'**
  String get howReportTitle;

  /// No description provided for @howReportLine.
  ///
  /// In en, this message translates to:
  /// **'Tap the flag next to a card\'s source to report it.'**
  String get howReportLine;

  /// No description provided for @howFoot.
  ///
  /// In en, this message translates to:
  /// **'Sources are checked again every month.'**
  String get howFoot;

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
  /// **'See every principle with Astute plus'**
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
  /// **'The measurement is running. Astute+ shows you which way it is going.'**
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
  /// **'ASTUTE+'**
  String get plusNameCaps;

  /// No description provided for @trialDaysFree.
  ///
  /// In en, this message translates to:
  /// **'{days} days free'**
  String trialDaysFree(int days);

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
  /// **'{n, plural, =1{card read} other{cards read}}'**
  String pillReadWord(int n);

  /// No description provided for @nPillsRead.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card read} other{{n} cards read}}'**
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

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

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
  /// **'{n, plural, =1{1 card went unread} other{{n} cards went unread}}'**
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

  /// No description provided for @subjectsInTheMix.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} subjects in the mix'**
  String subjectsInTheMix(int n, int total);

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
  /// **'Five cards a day, new every morning. Pick the topics you want in the mix — you can change them later.'**
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
  /// **'Nineteen topics, five cards'**
  String get introTopicsTitle;

  /// No description provided for @introTopicsLine.
  ///
  /// In en, this message translates to:
  /// **'Written ahead by a model, and every one checked against its source.'**
  String get introTopicsLine;

  /// No description provided for @introQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'A question, then the answer'**
  String get introQuestionTitle;

  /// No description provided for @introQuestionLine.
  ///
  /// In en, this message translates to:
  /// **'Every card carries the one line that makes it worth saying out loud.'**
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
  /// **'Two minutes a day'**
  String get introThirtyTitle;

  /// No description provided for @introThirtyLine.
  ///
  /// In en, this message translates to:
  /// **'One notification, five cards, and a streak you will not want to break.'**
  String get introThirtyLine;

  /// The time on the notification drawn in the intro's last scene. {time} is 8:30 in the reader's clock format.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String introNotifyWhen(String time);

  /// The line of the notification drawn in the intro's last scene.
  ///
  /// In en, this message translates to:
  /// **'Your five are ready. Day 1.'**
  String get introNotifyLine;

  /// On the card drawn in the intro's last scene, after the subject: the first of the day's five. Capitals where the script has them.
  ///
  /// In en, this message translates to:
  /// **'1 OF 5'**
  String get introOneOfFive;

  /// The day on the card drawn in the intro's last scene. Capitals where the script has them.
  ///
  /// In en, this message translates to:
  /// **'DAY 1'**
  String get introDayOne;

  /// The foot of the card drawn in the intro's last scene: its answer opens tomorrow. Capitals where the script has them.
  ///
  /// In en, this message translates to:
  /// **'TAP TOMORROW TO FIND OUT'**
  String get introTapTomorrow;

  /// Under the fourteen days in the intro's last scene, at the left: day one is tomorrow.
  ///
  /// In en, this message translates to:
  /// **'DAY 1 · TOMORROW'**
  String get introDayOneTomorrow;

  /// Under the fourteen days in the intro's last scene, at the right: the seventh day is the first streak.
  ///
  /// In en, this message translates to:
  /// **'DAY 7 · FIRST STREAK'**
  String get introDaySevenStreak;

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
  /// **'WHAT TO KEEP'**
  String get barMoveCaps;

  /// No description provided for @theBarMoveCaps.
  ///
  /// In en, this message translates to:
  /// **'THE BAR MOVE'**
  String get theBarMoveCaps;

  /// The home-screen widget's foot on a morning with no streak to show.
  ///
  /// In en, this message translates to:
  /// **'Five cards, two minutes.'**
  String get widgetFootPlain;

  /// The home-screen widget's foot while a streak is live.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1-day streak} other{{n}-day streak}}'**
  String widgetFootStreak(int n);

  /// The home-screen widget's foot once today's cards are read.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get widgetFootDone;

  /// The streak widget's line while there is no streak.
  ///
  /// In en, this message translates to:
  /// **'Read today\'s five to start a streak.'**
  String get widgetStreakStart;

  /// The five widget's heading, in capitals.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S FIVE'**
  String get widgetFiveTitle;

  /// The five widget's count of today's cards read.
  ///
  /// In en, this message translates to:
  /// **'{n} of 5 read'**
  String widgetFiveRead(int n);

  /// The five widget once all of today's cards are read.
  ///
  /// In en, this message translates to:
  /// **'All five read'**
  String get widgetFiveDone;

  /// The five widget after midnight, before the app has dealt the new day.
  ///
  /// In en, this message translates to:
  /// **'A new five is waiting'**
  String get widgetFiveWaiting;

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

  /// No description provided for @perkArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your whole archive'**
  String get perkArchiveTitle;

  /// No description provided for @perkArchiveLine.
  ///
  /// In en, this message translates to:
  /// **'Every day you have read, kept for good.'**
  String get perkArchiveLine;

  /// No description provided for @plusIsActive.
  ///
  /// In en, this message translates to:
  /// **'ASTUTE+ IS ACTIVE'**
  String get plusIsActive;

  /// No description provided for @tryFreeThen.
  ///
  /// In en, this message translates to:
  /// **'Try {days} days free, then {price}{suffix}'**
  String tryFreeThen(int days, String price, String suffix);

  /// The paywall's button for a plan that starts without a free trial.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {price}{suffix}'**
  String subscribeFor(String price, String suffix);

  /// No description provided for @noChargeTodayCancel.
  ///
  /// In en, this message translates to:
  /// **'No charge today · cancel any time'**
  String get noChargeTodayCancel;

  /// No description provided for @chargedTodayCancel.
  ///
  /// In en, this message translates to:
  /// **'Charged today · cancel any time'**
  String get chargedTodayCancel;

  /// The part of everyCardForYou painted in the gradient: the word for 'you', exactly as it is written there.
  ///
  /// In en, this message translates to:
  /// **'you.'**
  String get everyCardForYouMark;

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
  /// **'Astute+ is back.'**
  String get plusIsBack;

  /// No description provided for @nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore on this account.'**
  String get nothingToRestore;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @perYearShort.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get perYearShort;

  /// No description provided for @perMonthShort.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMonthShort;

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

  /// Link under the paywall to the terms of use (Apple's standard licence). Shares one line with Restore purchases and the privacy link, so keep it short.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// Link under the paywall to the privacy policy. Shares one line with Restore purchases and the terms link, so keep it short.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

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
  /// **'Like this card'**
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
  /// **'Tap the bookmark on any card and it lands here — the ones that changed how you think, kept.'**
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

  /// No description provided for @bySubject.
  ///
  /// In en, this message translates to:
  /// **'By subject'**
  String get bySubject;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get pts;

  /// No description provided for @nStillWithYou.
  ///
  /// In en, this message translates to:
  /// **'{n} still with you'**
  String nStillWithYou(int n);

  /// No description provided for @nMoves.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 move} other{{n} moves}}'**
  String nMoves(int n);

  /// No description provided for @scoreStartsToday.
  ///
  /// In en, this message translates to:
  /// **'Your score starts with today\'s five.'**
  String get scoreStartsToday;

  /// No description provided for @anonymousUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage data'**
  String get anonymousUsage;

  /// No description provided for @anonymousUsageLine.
  ///
  /// In en, this message translates to:
  /// **'How the app is used — what gets read, kept and said, and what goes wrong — so the next cards are better ones. Never your name, your email, or anything you write.'**
  String get anonymousUsageLine;

  /// No description provided for @usageOn.
  ///
  /// In en, this message translates to:
  /// **'Shared, without your name or your words.'**
  String get usageOn;

  /// No description provided for @usageOff.
  ///
  /// In en, this message translates to:
  /// **'Nothing more is measured.'**
  String get usageOff;

  /// No description provided for @yourMix.
  ///
  /// In en, this message translates to:
  /// **'Your mix'**
  String get yourMix;

  /// No description provided for @genresLine.
  ///
  /// In en, this message translates to:
  /// **'Tap a genre to skip it. Hold one and the smaller topics inside open right below.'**
  String get genresLine;

  /// No description provided for @insideGenre.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get insideGenre;

  /// No description provided for @nOfSixOn.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} on'**
  String nOfSixOn(int n, int total);

  /// No description provided for @offInYourMix.
  ///
  /// In en, this message translates to:
  /// **'off in your mix'**
  String get offInYourMix;

  /// No description provided for @continueGenresOn.
  ///
  /// In en, this message translates to:
  /// **'Continue · {on} of {total} genres on'**
  String continueGenresOn(int on, int total);

  /// No description provided for @mixRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get mixRarely;

  /// No description provided for @mixSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get mixSometimes;

  /// No description provided for @mixOften.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get mixOften;

  /// No description provided for @mixALot.
  ///
  /// In en, this message translates to:
  /// **'A lot'**
  String get mixALot;

  /// No description provided for @mixFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get mixFull;

  /// No description provided for @forYouChip.
  ///
  /// In en, this message translates to:
  /// **'FOR YOU'**
  String get forYouChip;

  /// No description provided for @againChip.
  ///
  /// In en, this message translates to:
  /// **'AGAIN'**
  String get againChip;

  /// No description provided for @magicLine.
  ///
  /// In en, this message translates to:
  /// **'Five cards a day chosen for you: from your mix, at your level, never one you have read. From tomorrow.'**
  String get magicLine;

  /// No description provided for @everyCardForYou.
  ///
  /// In en, this message translates to:
  /// **'Every card, chosen for you.'**
  String get everyCardForYou;

  /// No description provided for @perkOwnTitle.
  ///
  /// In en, this message translates to:
  /// **'Five cards a day, all yours'**
  String get perkOwnTitle;

  /// No description provided for @perkOwnLine.
  ///
  /// In en, this message translates to:
  /// **'From your strands, at your level, never one you have read. Free days give you two.'**
  String get perkOwnLine;

  /// No description provided for @plusCardHeadline.
  ///
  /// In en, this message translates to:
  /// **'Make all five yours.'**
  String get plusCardHeadline;

  /// No description provided for @plusCardLine.
  ///
  /// In en, this message translates to:
  /// **'Five cards a day from your mix, at your level. Your journey. Your whole archive.'**
  String get plusCardLine;

  /// No description provided for @continueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue free'**
  String get continueFree;

  /// No description provided for @archiveBeforeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Before this week'**
  String get archiveBeforeThisWeek;

  /// No description provided for @weekKeptThreeOwn.
  ///
  /// In en, this message translates to:
  /// **'A week kept: tomorrow three of the five are yours.'**
  String get weekKeptThreeOwn;

  /// No description provided for @perkJourneyLine.
  ///
  /// In en, this message translates to:
  /// **'Your level, every subject strand by strand, what stayed, and the moves you keep missing.'**
  String get perkJourneyLine;

  /// No description provided for @topOfTheWeek.
  ///
  /// In en, this message translates to:
  /// **'Top of the week'**
  String get topOfTheWeek;

  /// No description provided for @topOfTheMonth.
  ///
  /// In en, this message translates to:
  /// **'Top of the month'**
  String get topOfTheMonth;

  /// No description provided for @topIn.
  ///
  /// In en, this message translates to:
  /// **'Top in {subject}'**
  String topIn(String subject);

  /// No description provided for @topLineWeek.
  ///
  /// In en, this message translates to:
  /// **'Most liked, saved and said in the last 7 days'**
  String get topLineWeek;

  /// No description provided for @topLineMonth.
  ///
  /// In en, this message translates to:
  /// **'Most liked, saved and said in the last 30 days'**
  String get topLineMonth;

  /// No description provided for @topWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get topWeek;

  /// No description provided for @topMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get topMonth;

  /// No description provided for @topReaders.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 reader} other{{n} readers}}'**
  String topReaders(int n);

  /// No description provided for @topEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the list yet. Every card you like, save or say counts.'**
  String get topEmpty;

  /// No description provided for @readMark.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readMark;

  /// No description provided for @lovedSinceTheStart.
  ///
  /// In en, this message translates to:
  /// **'Loved since the start'**
  String get lovedSinceTheStart;

  /// No description provided for @lovedIn.
  ///
  /// In en, this message translates to:
  /// **'Loved in {subject}'**
  String lovedIn(String subject);

  /// No description provided for @lovedLine.
  ///
  /// In en, this message translates to:
  /// **'What readers kept most, and you have not read yet'**
  String get lovedLine;

  /// No description provided for @forYouShelf.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get forYouShelf;

  /// No description provided for @forYouLine.
  ///
  /// In en, this message translates to:
  /// **'What your reading puts first'**
  String get forYouLine;

  /// No description provided for @exploreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. This is Explore as it was last read.'**
  String get exploreOffline;

  /// No description provided for @askYourselfCaps.
  ///
  /// In en, this message translates to:
  /// **'ASK YOURSELF'**
  String get askYourselfCaps;

  /// No description provided for @themeMyths.
  ///
  /// In en, this message translates to:
  /// **'Myths, busted'**
  String get themeMyths;

  /// No description provided for @themeMythsLine.
  ///
  /// In en, this message translates to:
  /// **'What almost everyone believes, and why it is wrong'**
  String get themeMythsLine;

  /// No description provided for @themeParadoxes.
  ///
  /// In en, this message translates to:
  /// **'Paradoxes'**
  String get themeParadoxes;

  /// No description provided for @themeParadoxesLine.
  ///
  /// In en, this message translates to:
  /// **'Two true things that should not both be true'**
  String get themeParadoxesLine;

  /// No description provided for @themeNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers that surprise'**
  String get themeNumbers;

  /// No description provided for @themeNumbersLine.
  ///
  /// In en, this message translates to:
  /// **'Where the figure is the twist'**
  String get themeNumbersLine;

  /// No description provided for @themePractical.
  ///
  /// In en, this message translates to:
  /// **'Use it today'**
  String get themePractical;

  /// No description provided for @themePracticalLine.
  ///
  /// In en, this message translates to:
  /// **'Something to try before tonight'**
  String get themePracticalLine;

  /// No description provided for @themeOrigins.
  ///
  /// In en, this message translates to:
  /// **'Where it came from'**
  String get themeOrigins;

  /// No description provided for @themeOriginsLine.
  ///
  /// In en, this message translates to:
  /// **'The beginnings of things you use every day'**
  String get themeOriginsLine;

  /// No description provided for @themeStories.
  ///
  /// In en, this message translates to:
  /// **'True stories'**
  String get themeStories;

  /// No description provided for @themeStoriesLine.
  ///
  /// In en, this message translates to:
  /// **'Things that really happened'**
  String get themeStoriesLine;

  /// No description provided for @themeDebates.
  ///
  /// In en, this message translates to:
  /// **'Pick a side'**
  String get themeDebates;

  /// No description provided for @themeDebatesLine.
  ///
  /// In en, this message translates to:
  /// **'No right answer, only a better argument'**
  String get themeDebatesLine;

  /// No description provided for @themeWorkItOut.
  ///
  /// In en, this message translates to:
  /// **'Work it out'**
  String get themeWorkItOut;

  /// No description provided for @themeWorkItOutLine.
  ///
  /// In en, this message translates to:
  /// **'A number to reach in your head'**
  String get themeWorkItOutLine;

  /// No description provided for @themeSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen, not read'**
  String get themeSeen;

  /// No description provided for @themeSeenLine.
  ///
  /// In en, this message translates to:
  /// **'Cards that draw their point'**
  String get themeSeenLine;

  /// No description provided for @themeSharpest.
  ///
  /// In en, this message translates to:
  /// **'For the sharpest'**
  String get themeSharpest;

  /// No description provided for @themeSharpestLine.
  ///
  /// In en, this message translates to:
  /// **'The hardest cards there are'**
  String get themeSharpestLine;

  /// No description provided for @themePast0.
  ///
  /// In en, this message translates to:
  /// **'The ancient world'**
  String get themePast0;

  /// No description provided for @themePast1.
  ///
  /// In en, this message translates to:
  /// **'The 1600s to the 1800s'**
  String get themePast1;

  /// No description provided for @themePast2.
  ///
  /// In en, this message translates to:
  /// **'The last century'**
  String get themePast2;

  /// No description provided for @themePastLine.
  ///
  /// In en, this message translates to:
  /// **'A different age every time it comes round'**
  String get themePastLine;

  /// No description provided for @themePlace0.
  ///
  /// In en, this message translates to:
  /// **'Asia and the Middle East'**
  String get themePlace0;

  /// No description provided for @themePlace1.
  ///
  /// In en, this message translates to:
  /// **'The Americas'**
  String get themePlace1;

  /// No description provided for @themePlace2.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get themePlace2;

  /// No description provided for @themePlaceLine.
  ///
  /// In en, this message translates to:
  /// **'A different part of the world every time it comes round'**
  String get themePlaceLine;

  /// No description provided for @themeTrueOrFalse.
  ///
  /// In en, this message translates to:
  /// **'True or false?'**
  String get themeTrueOrFalse;

  /// No description provided for @themeTrueOrFalseLine.
  ///
  /// In en, this message translates to:
  /// **'Decide before you flip. Most people get these wrong'**
  String get themeTrueOrFalseLine;

  /// No description provided for @themeReasoning.
  ///
  /// In en, this message translates to:
  /// **'Just reasoning'**
  String get themeReasoning;

  /// No description provided for @themeReasoningLine.
  ///
  /// In en, this message translates to:
  /// **'No facts to know: only a way to think it through'**
  String get themeReasoningLine;

  /// No description provided for @themeIdeas.
  ///
  /// In en, this message translates to:
  /// **'Big ideas'**
  String get themeIdeas;

  /// No description provided for @themeIdeasLine.
  ///
  /// In en, this message translates to:
  /// **'The theory behind things, one idea at a time'**
  String get themeIdeasLine;

  /// No description provided for @themeCurious.
  ///
  /// In en, this message translates to:
  /// **'Just curious'**
  String get themeCurious;

  /// No description provided for @themeCuriousLine.
  ///
  /// In en, this message translates to:
  /// **'For the pleasure of knowing why'**
  String get themeCuriousLine;

  /// No description provided for @themeMoving.
  ///
  /// In en, this message translates to:
  /// **'Still moving'**
  String get themeMoving;

  /// No description provided for @themeMovingLine.
  ///
  /// In en, this message translates to:
  /// **'Things that are changing now, and why they matter'**
  String get themeMovingLine;

  /// No description provided for @themeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it really works'**
  String get themeHowItWorks;

  /// No description provided for @themeHowItWorksLine.
  ///
  /// In en, this message translates to:
  /// **'The mechanism behind something you see every day'**
  String get themeHowItWorksLine;

  /// No description provided for @themePuzzles.
  ///
  /// In en, this message translates to:
  /// **'Work it out'**
  String get themePuzzles;

  /// No description provided for @themePuzzlesLine.
  ///
  /// In en, this message translates to:
  /// **'Puzzles you can solve with a pen and a minute'**
  String get themePuzzlesLine;

  /// No description provided for @weekRecapCaps.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK YOU ASKED YOURSELF'**
  String get weekRecapCaps;

  /// No description provided for @weekRecapLine.
  ///
  /// In en, this message translates to:
  /// **'The questions your cards left you with'**
  String get weekRecapLine;

  /// No description provided for @weekRecapMore.
  ///
  /// In en, this message translates to:
  /// **'{n} more from your week with Plus'**
  String weekRecapMore(int n);

  /// No description provided for @plusInTheApp.
  ///
  /// In en, this message translates to:
  /// **'Astute+ is in the app: download Astute on iPhone or Android to start your free trial.'**
  String get plusInTheApp;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Purchase complete.'**
  String get purchaseComplete;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Welcome to Astute+. Today’s five cards are ready.'**
  String get successWelcome;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Welcome to Astute+, {name}. Today’s five cards are ready.'**
  String successWelcomeNamed(String name);

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'5 cards a day'**
  String get successFiveCards;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Full archive'**
  String get successArchive;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Astute+ {plan}'**
  String successPlanName(String plan);

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Free until {date}, then {price}{suffix}'**
  String successFreeUntil(String date, String price, String suffix);

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Renews {date} · {price}{suffix}'**
  String successRenewsLine(String date, String price, String suffix);

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get successReceipt;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Let’s start'**
  String get letsStart;

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'First charge {date} · cancel any time'**
  String successFootFirstCharge(String date);

  /// Purchase success screen (design 129a).
  ///
  /// In en, this message translates to:
  /// **'Renews {date} · cancel any time'**
  String successFootRenews(String date);

  /// Footer of a card on the Use it today shelf: something to try before tonight.
  ///
  /// In en, this message translates to:
  /// **'TRY TODAY'**
  String get tryToday;

  /// How long a card takes, in minutes, short and uppercase.
  ///
  /// In en, this message translates to:
  /// **'{n} MIN'**
  String minutesShort(int n);

  /// Between the two sides of a debate on the Pick a side shelf: Yes or No.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get sideOr;

  /// Button under a worked solution: show its next step.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// Button under a worked solution: show every step at once.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAllSteps;

  /// On the back of a card with no room for its diagram beside the words: tap to see the diagram in place of the answer.
  ///
  /// In en, this message translates to:
  /// **'See the picture'**
  String get revealSeePicture;

  /// On the back of a card with no room for its interactive scene beside the words: tap to play the scene in place of the answer.
  ///
  /// In en, this message translates to:
  /// **'Play with it'**
  String get revealPlayScene;

  /// Shown with the diagram or scene on the back of a card: tap to bring the answer back.
  ///
  /// In en, this message translates to:
  /// **'Back to the answer'**
  String get revealBackToAnswer;

  /// On the back of a card with no room for its worked solution beside the answer: tap to see the steps in place of the answer.
  ///
  /// In en, this message translates to:
  /// **'Show the working'**
  String get revealShowWorking;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'LOCK IT IN'**
  String get sceneLockIn;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get sceneYou;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'TRUTH'**
  String get sceneTruth;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get sceneTryAgain;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Draw your guess with your finger'**
  String get sceneDrawHint;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Press and hold'**
  String get sceneHoldHint;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Swipe or tap'**
  String get sceneSwipeHint;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Tap your pick'**
  String get sceneTapToPick;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get sceneShowMe;

  /// Label inside an interactive card scene.
  ///
  /// In en, this message translates to:
  /// **'Your guess'**
  String get sceneYourGuess;

  /// A score inside a card scene, e.g. 4 of 7.
  ///
  /// In en, this message translates to:
  /// **'{n} of {m}'**
  String sceneNOfM(int n, int m);

  /// Link under a card's source that opens the report sheet.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// Shown instead of the report link once this phone has reported the card.
  ///
  /// In en, this message translates to:
  /// **'Reported. Thank you.'**
  String get reportedThanks;

  /// Title of the sheet for reporting a problem with a card.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong with this card?'**
  String get reportTitle;

  /// Line under the report sheet's title.
  ///
  /// In en, this message translates to:
  /// **'We check every report against the sources and fix the card.'**
  String get reportLead;

  /// Report reason: the card states something untrue.
  ///
  /// In en, this message translates to:
  /// **'A fact is wrong'**
  String get reportFact;

  /// Report reason: the option marked correct is not correct.
  ///
  /// In en, this message translates to:
  /// **'The answer marked right is wrong'**
  String get reportAnswer;

  /// Report reason: the cited source does not support the card.
  ///
  /// In en, this message translates to:
  /// **'The source doesn\'t back it up'**
  String get reportSource;

  /// Report reason: the card is hard to understand.
  ///
  /// In en, this message translates to:
  /// **'It\'s confusing'**
  String get reportUnclear;

  /// Report reason: a spelling mistake or text laid out wrong.
  ///
  /// In en, this message translates to:
  /// **'A typo or a broken line'**
  String get reportTypo;

  /// Report reason: anything else.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportOther;

  /// Placeholder in the optional note field of the report sheet.
  ///
  /// In en, this message translates to:
  /// **'Anything that helps us check it (optional)'**
  String get reportNoteHint;

  /// Button that sends a report.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get reportSend;

  /// Brief message after a report is sent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We\'ll check it.'**
  String get reportSentToast;

  /// Beside the big number at the top of Your journey: how many points the reader's confidence runs off their results.
  ///
  /// In en, this message translates to:
  /// **'points off'**
  String get journeyPointsOff;

  /// Added to that line until there are enough answers with a confidence to measure it.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{One more answer with how sure, and it is measured.} other{{n} more answers with how sure, and it is measured.}}'**
  String journeyOffNotYet(int n);

  /// Small capitals over the big score at the top of Your journey (shown in capitals).
  ///
  /// In en, this message translates to:
  /// **'Your score'**
  String get journeyYourScore;

  /// Beside the big score: the word for points, no number (the number is set large before it).
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{point} other{points}}'**
  String journeyPointsUnit(int n);

  /// Green chip beside the score: what it gained in the last four weeks.
  ///
  /// In en, this message translates to:
  /// **'+{n} in 4 weeks'**
  String journeyGainedIn(String n);

  /// Under the score chart, for the week in hand.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{This week so far, you earned 1 point.} other{This week so far, you earned {n} points.}}'**
  String journeyWeekSoFar(int n);

  /// Under the score chart, for a past week the reader tapped. date is the day the week started, e.g. 14 July.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{In the week of {date}, you earned 1 point.} other{In the week of {date}, you earned {n} points.}}'**
  String journeyWeekOf(int n, String date);

  /// Beside that sentence: how many cards were first read that week.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card} other{{n} cards}}'**
  String journeyCards(int n);

  /// Small print under the score chart. date is the first day, e.g. 14 July.
  ///
  /// In en, this message translates to:
  /// **'Your score at the end of each week since {date}. Tap a point to see that week.'**
  String journeyScoreCaption(String date);

  /// Small capitals over the level's name (shown in capitals).
  ///
  /// In en, this message translates to:
  /// **'Level {n} of {of}'**
  String journeyLevelOf(int n, int of);

  /// Right of the level's name, on two lines: how far the next level is. what is e.g. '2 points' or '12 cards'; rung is the next level's name.
  ///
  /// In en, this message translates to:
  /// **'{what}\nfrom {rung}'**
  String journeyStepFrom(String what, String rung);

  /// How far the next level is: cards still to read.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card} other{{n} cards}}'**
  String journeyToGoCards(int n);

  /// How far the next level is: answers still to give.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 answer} other{{n} answers}}'**
  String journeyToGoAnswers(int n);

  /// How far the next level is: answers given with how sure the reader was.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 answer with how sure} other{{n} answers with how sure}}'**
  String journeyToGoSure(int n);

  /// How far the next level is: cards still to keep (come back and get right).
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 card held} other{{n} cards held}}'**
  String journeyToGoHeld(int n);

  /// How far the next level is: points off still to lose.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 point} other{{n} points}}'**
  String journeyToGoPoints(int n);

  /// Tile title: what the cards read are worth in books.
  ///
  /// In en, this message translates to:
  /// **'Worth'**
  String get journeyWorth;

  /// Big number in the Worth tile: non-fiction books, at fifty cards a book.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 book} other{{n} books}}'**
  String journeyBooks(int n);

  /// Under the books: the same in hours of documentaries.
  ///
  /// In en, this message translates to:
  /// **'or {h} h of documentaries'**
  String journeyOrDocumentaries(int h);

  /// Under the cards read, before the first fifty: how many until the first book.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 to the first book} other{{n} to the first book}}'**
  String journeyToFirstBook(int n);

  /// Tile title: days in a row.
  ///
  /// In en, this message translates to:
  /// **'In a row'**
  String get journeyInARow;

  /// Big number in the In a row tile.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String journeyDays(int n);

  /// Under the days in a row: the best run, and the days read of the days since the first.
  ///
  /// In en, this message translates to:
  /// **'Best {best} · {active} of {days}'**
  String journeyBestActive(int best, int active, int days);

  /// Big number over the subjects chart: subjects opened of all of them.
  ///
  /// In en, this message translates to:
  /// **'{n} of {of}'**
  String journeySubjectsOf(int n, int of);

  /// Beside it: the dashed shape is the reading as it stood at the end of the first month, e.g. July.
  ///
  /// In en, this message translates to:
  /// **'subjects · dashed: {month}'**
  String journeySubjectsDashed(String month);

  /// Beside it, before there is a first month to compare with.
  ///
  /// In en, this message translates to:
  /// **'subjects'**
  String get journeySubjects;

  /// Tile title: how hard the cards the reader opens are.
  ///
  /// In en, this message translates to:
  /// **'How hard'**
  String get journeyHowHard;

  /// Beside the average level: out of 3 (easy 1, medium 2, hard 3).
  ///
  /// In en, this message translates to:
  /// **'of 3'**
  String get journeyOfThree;

  /// Under the average level.
  ///
  /// In en, this message translates to:
  /// **'The cards you open.'**
  String get journeyHardNow;

  /// Under the average level, once there is a first month to compare with, e.g. 1.8 in July.
  ///
  /// In en, this message translates to:
  /// **'The cards you open. {v} in {month}'**
  String journeyHardThen(String v, String month);

  /// Tile title: time spent on the cards.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get journeyReadingTime;

  /// Big number: hours and minutes, e.g. 3 h 28.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m}'**
  String journeyHoursMinutes(int h, String m);

  /// Big number under an hour.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String journeyMinutes(int m);

  /// Under the reading time: minutes a week lately, and at the start.
  ///
  /// In en, this message translates to:
  /// **'{now} min a week, from {was}'**
  String journeyMinAWeek(int now, int was);

  /// Under the reading time, before there is a start to compare with.
  ///
  /// In en, this message translates to:
  /// **'{m} min this week'**
  String journeyMinThisWeek(int m);

  /// Under a dash: the app has started timing the cards today.
  ///
  /// In en, this message translates to:
  /// **'Counted from today'**
  String get journeyTimedFromToday;

  /// Beside the points off: what they were at the start.
  ///
  /// In en, this message translates to:
  /// **'points off, from {was}'**
  String journeyPointsOffFrom(int was);

  /// Green small capitals, right of the points off: what the top level asks (shown in capitals).
  ///
  /// In en, this message translates to:
  /// **'{rung} · {n} or less'**
  String journeyRungOrLess(String rung, int n);

  /// Tile title: how often the reader was right when 80% sure or more.
  ///
  /// In en, this message translates to:
  /// **'Right when sure'**
  String get journeyRightWhenSure;

  /// Under a number: what it was in the first month, e.g. From 50% in July.
  ///
  /// In en, this message translates to:
  /// **'From {v} in {month}'**
  String journeyFromIn(String v, String month);

  /// Under a dash, before any answer at 80% sure or more.
  ///
  /// In en, this message translates to:
  /// **'Nothing said at 80% or more yet'**
  String get journeySureNone;

  /// Tile title: the reasoning moves the reader has down.
  ///
  /// In en, this message translates to:
  /// **'Moves you can spot'**
  String get journeyMovesTitle;

  /// Beside the moves: out of how many there are.
  ///
  /// In en, this message translates to:
  /// **'of {n}'**
  String journeyOfN(int n);

  /// Under the moves: the one the reader got most recently.
  ///
  /// In en, this message translates to:
  /// **'Newest: {name}'**
  String journeyNewest(String name);

  /// Under the moves, before the first.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get journeyNoneYet;

  /// Beside the big number of cards held: no number in it.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{card still with you} other{cards still with you}}'**
  String journeyStillWithYou(int n);

  /// Under a bar: of the cards that came back after that many days, how many the reader still knew.
  ///
  /// In en, this message translates to:
  /// **'{right} of {of} after {days, plural, =1{a day} other{{days} days}}'**
  String journeyRecallDays(int right, int of, int days);

  /// The same, after weeks.
  ///
  /// In en, this message translates to:
  /// **'{right} of {of} after {weeks, plural, =1{a week} other{{weeks} weeks}}'**
  String journeyRecallWeeks(int right, int of, int weeks);

  /// Over the calendar: days read of the days since the first.
  ///
  /// In en, this message translates to:
  /// **'{active} of {days} days'**
  String journeyActiveDays(int active, int days);

  /// Right of it: when most cards are read.
  ///
  /// In en, this message translates to:
  /// **'Mostly mornings'**
  String get journeyMostlyMorning;

  /// Right of it: when most cards are read.
  ///
  /// In en, this message translates to:
  /// **'Mostly afternoons'**
  String get journeyMostlyAfternoon;

  /// Right of it: when most cards are read.
  ///
  /// In en, this message translates to:
  /// **'Mostly evenings'**
  String get journeyMostlyEvening;

  /// Right of it: when most cards are read.
  ///
  /// In en, this message translates to:
  /// **'Mostly at night'**
  String get journeyMostlyNight;

  /// Tile title: how far back in time the cards read reach.
  ///
  /// In en, this message translates to:
  /// **'In time'**
  String get journeyInTime;

  /// Big number: years, e.g. 5,000 years.
  ///
  /// In en, this message translates to:
  /// **'{n} years'**
  String journeyYears(int n);

  /// Under it: the oldest time the cards read are set in.
  ///
  /// In en, this message translates to:
  /// **'from {era} to this year'**
  String journeyFromEra(String era);

  /// An era, inside 'from … to this year'.
  ///
  /// In en, this message translates to:
  /// **'the ancient world'**
  String get journeyEraAncient;

  /// An era, inside 'from … to this year'.
  ///
  /// In en, this message translates to:
  /// **'the Middle Ages'**
  String get journeyEraMedieval;

  /// An era, inside 'from … to this year'.
  ///
  /// In en, this message translates to:
  /// **'the 1500s'**
  String get journeyEraEarlyModern;

  /// An era, inside 'from … to this year'.
  ///
  /// In en, this message translates to:
  /// **'the 1800s'**
  String get journeyEraNineteenth;

  /// An era, inside 'from … to this year'.
  ///
  /// In en, this message translates to:
  /// **'the 1900s'**
  String get journeyEraTwentieth;

  /// An era, inside 'from … to this year': the year 2000.
  ///
  /// In en, this message translates to:
  /// **'2000'**
  String get journeyEraRecent;

  /// Under a dash in the In time tile.
  ///
  /// In en, this message translates to:
  /// **'nothing dated yet'**
  String get journeyNothingDated;

  /// Tile title: where in the world the cards read are set.
  ///
  /// In en, this message translates to:
  /// **'In place'**
  String get journeyInPlace;

  /// Big number: regions of the world.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 region} other{{n} regions}}'**
  String journeyRegions(int n);

  /// Under it: the regions read most, and space.
  ///
  /// In en, this message translates to:
  /// **'{list}, and space'**
  String journeyPlacesAndSpace(String list);

  /// A region of the world.
  ///
  /// In en, this message translates to:
  /// **'the Americas'**
  String get journeyRegionAmericas;

  /// A region of the world.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get journeyRegionEurope;

  /// A region of the world.
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get journeyRegionAsia;

  /// A region of the world.
  ///
  /// In en, this message translates to:
  /// **'Oceania'**
  String get journeyRegionOceania;

  /// A region of the world.
  ///
  /// In en, this message translates to:
  /// **'Africa'**
  String get journeyRegionAfrica;

  /// A region of the world.
  ///
  /// In en, this message translates to:
  /// **'the Middle East'**
  String get journeyRegionMiddleEast;

  /// Under a dash in the In place tile.
  ///
  /// In en, this message translates to:
  /// **'no place yet'**
  String get journeyNoPlace;

  /// Tile title: the topics inside the subjects that the reader has met.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get journeyTopics;

  /// Big number: topics met.
  ///
  /// In en, this message translates to:
  /// **'{n} met'**
  String journeyMet(int n);

  /// Under it: how many of them are in the subject with most.
  ///
  /// In en, this message translates to:
  /// **'{n} of them in {subject}'**
  String journeyTopicsMost(int n, String subject);

  /// Tile title: the terms the reader has met in the cards.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get journeyWords;

  /// Big number: terms met for the first time.
  ///
  /// In en, this message translates to:
  /// **'{n} new'**
  String journeyNew(int n);

  /// No description provided for @aMove.
  ///
  /// In en, this message translates to:
  /// **'A move'**
  String get aMove;

  /// No description provided for @anotherOne.
  ///
  /// In en, this message translates to:
  /// **'Another'**
  String get anotherOne;

  /// No description provided for @answerIs.
  ///
  /// In en, this message translates to:
  /// **'Answer: {said}'**
  String answerIs(String said);

  /// No description provided for @answeredAlready.
  ///
  /// In en, this message translates to:
  /// **'Answered already'**
  String get answeredAlready;

  /// No description provided for @anyCard.
  ///
  /// In en, this message translates to:
  /// **'Any subject, any shelf, one card'**
  String get anyCard;

  /// No description provided for @betN.
  ///
  /// In en, this message translates to:
  /// **'Bet {n}'**
  String betN(int n);

  /// No description provided for @betSlip.
  ///
  /// In en, this message translates to:
  /// **'Your bet slip'**
  String get betSlip;

  /// No description provided for @betWord.
  ///
  /// In en, this message translates to:
  /// **'Bet'**
  String get betWord;

  /// No description provided for @biggerLabel.
  ///
  /// In en, this message translates to:
  /// **'Bigger'**
  String get biggerLabel;

  /// No description provided for @biggerNote.
  ///
  /// In en, this message translates to:
  /// **'Each figure is a card\'s own answer.'**
  String get biggerNote;

  /// No description provided for @biggerScore.
  ///
  /// In en, this message translates to:
  /// **'Right on {right} of {asked}.'**
  String biggerScore(int right, int asked);

  /// No description provided for @biggerYouGotIt.
  ///
  /// In en, this message translates to:
  /// **'Bigger · you got it'**
  String get biggerYouGotIt;

  /// No description provided for @cameBackAfterDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{After a day} other{After {n} days}}'**
  String cameBackAfterDays(int n);

  /// No description provided for @cameBackAfterWeek.
  ///
  /// In en, this message translates to:
  /// **'After a week'**
  String get cameBackAfterWeek;

  /// No description provided for @cameBackAfterWeeks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{After a week} other{After {n} weeks}}'**
  String cameBackAfterWeeks(int n);

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @closerDone.
  ///
  /// In en, this message translates to:
  /// **'It is {said}. You got {right} of {steps}.'**
  String closerDone(String said, int right, int steps);

  /// No description provided for @closerNoLess.
  ///
  /// In en, this message translates to:
  /// **'No: it is less than {v}.'**
  String closerNoLess(String v);

  /// No description provided for @closerNoMore.
  ///
  /// In en, this message translates to:
  /// **'No: it is more than {v}.'**
  String closerNoMore(String v);

  /// No description provided for @closerStart.
  ///
  /// In en, this message translates to:
  /// **'Three steps to close in on it.'**
  String get closerStart;

  /// No description provided for @closerYesLess.
  ///
  /// In en, this message translates to:
  /// **'Right: it is less than {v}.'**
  String closerYesLess(String v);

  /// No description provided for @closerYesMore.
  ///
  /// In en, this message translates to:
  /// **'Right: it is more than {v}.'**
  String closerYesMore(String v);

  /// No description provided for @corrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get corrections;

  /// No description provided for @didYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get didYouKnow;

  /// No description provided for @didYouKnowLine.
  ///
  /// In en, this message translates to:
  /// **'Turn it over, then: new to you, or knew it?'**
  String get didYouKnowLine;

  /// No description provided for @dragToSet.
  ///
  /// In en, this message translates to:
  /// **'Drag to set'**
  String get dragToSet;

  /// No description provided for @dykAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get dykAgain;

  /// No description provided for @dykKnew.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{None you knew} =1{1 you knew} other{{n} you knew}}'**
  String dykKnew(int n);

  /// No description provided for @dykNew.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nothing new today} =1{1 new to you} other{{n} new to you}}'**
  String dykNew(int n);

  /// No description provided for @editionEnd.
  ///
  /// In en, this message translates to:
  /// **'That\'s today\'s edition'**
  String get editionEnd;

  /// No description provided for @editionTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s is out in the morning'**
  String get editionTomorrow;

  /// No description provided for @eraAncient.
  ///
  /// In en, this message translates to:
  /// **'The ancient world'**
  String get eraAncient;

  /// No description provided for @eraAncientWhen.
  ///
  /// In en, this message translates to:
  /// **'Before 500'**
  String get eraAncientWhen;

  /// No description provided for @eraEarlyModern.
  ///
  /// In en, this message translates to:
  /// **'The early modern age'**
  String get eraEarlyModern;

  /// No description provided for @eraEarlyModernWhen.
  ///
  /// In en, this message translates to:
  /// **'1500 to 1800'**
  String get eraEarlyModernWhen;

  /// No description provided for @eraMedieval.
  ///
  /// In en, this message translates to:
  /// **'The Middle Ages'**
  String get eraMedieval;

  /// No description provided for @eraMedievalWhen.
  ///
  /// In en, this message translates to:
  /// **'500 to 1500'**
  String get eraMedievalWhen;

  /// No description provided for @eraMore.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 more from this age} other{{n} more from this age}}'**
  String eraMore(int n);

  /// No description provided for @eraNineteenth.
  ///
  /// In en, this message translates to:
  /// **'The nineteenth century'**
  String get eraNineteenth;

  /// No description provided for @eraNineteenthWhen.
  ///
  /// In en, this message translates to:
  /// **'1800 to 1900'**
  String get eraNineteenthWhen;

  /// No description provided for @eraRecent.
  ///
  /// In en, this message translates to:
  /// **'This century'**
  String get eraRecent;

  /// No description provided for @eraRecentWhen.
  ///
  /// In en, this message translates to:
  /// **'Since 2000'**
  String get eraRecentWhen;

  /// No description provided for @eraRulerNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get eraRulerNow;

  /// No description provided for @eraRulerOld.
  ///
  /// In en, this message translates to:
  /// **'Antiquity'**
  String get eraRulerOld;

  /// No description provided for @eraShortAncient.
  ///
  /// In en, this message translates to:
  /// **'Antiquity'**
  String get eraShortAncient;

  /// No description provided for @eraShortEarlyModern.
  ///
  /// In en, this message translates to:
  /// **'1500–1800'**
  String get eraShortEarlyModern;

  /// No description provided for @eraShortMedieval.
  ///
  /// In en, this message translates to:
  /// **'Middle Ages'**
  String get eraShortMedieval;

  /// No description provided for @eraShortNineteenth.
  ///
  /// In en, this message translates to:
  /// **'1800s'**
  String get eraShortNineteenth;

  /// No description provided for @eraShortRecent.
  ///
  /// In en, this message translates to:
  /// **'2000s'**
  String get eraShortRecent;

  /// No description provided for @eraShortTwentieth.
  ///
  /// In en, this message translates to:
  /// **'1900s'**
  String get eraShortTwentieth;

  /// No description provided for @eraTwentieth.
  ///
  /// In en, this message translates to:
  /// **'The last century'**
  String get eraTwentieth;

  /// No description provided for @eraTwentiethWhen.
  ///
  /// In en, this message translates to:
  /// **'1900 to 2000'**
  String get eraTwentiethWhen;

  /// No description provided for @fewCards.
  ///
  /// In en, this message translates to:
  /// **'In a few cards'**
  String get fewCards;

  /// No description provided for @fewCardsLine.
  ///
  /// In en, this message translates to:
  /// **'When one card isn\'t enough to explain it'**
  String get fewCardsLine;

  /// No description provided for @firstLabel.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get firstLabel;

  /// No description provided for @forYouNow.
  ///
  /// In en, this message translates to:
  /// **'For you, right now'**
  String get forYouNow;

  /// No description provided for @goNarrow.
  ///
  /// In en, this message translates to:
  /// **'Go narrow when you\'re sure: it pays three times as much.'**
  String get goNarrow;

  /// No description provided for @hardBadge.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hardBadge;

  /// No description provided for @hidesIn.
  ///
  /// In en, this message translates to:
  /// **'In {where}'**
  String hidesIn(String where);

  /// No description provided for @howSure.
  ///
  /// In en, this message translates to:
  /// **'How sure am I, and why?'**
  String get howSure;

  /// No description provided for @inNumbers.
  ///
  /// In en, this message translates to:
  /// **'In numbers'**
  String get inNumbers;

  /// No description provided for @inRange.
  ///
  /// In en, this message translates to:
  /// **'In range: +{pts} points. It is {said}.'**
  String inRange(int pts, String said);

  /// No description provided for @inYourMoves.
  ///
  /// In en, this message translates to:
  /// **'In your moves · {n}×'**
  String inYourMoves(int n);

  /// No description provided for @itIs.
  ///
  /// In en, this message translates to:
  /// **'It is {said}.'**
  String itIs(String said);

  /// No description provided for @knewIt.
  ///
  /// In en, this message translates to:
  /// **'Knew it'**
  String get knewIt;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @lookFirst.
  ///
  /// In en, this message translates to:
  /// **'Look at the chart before you believe the headline.'**
  String get lookFirst;

  /// No description provided for @markTried.
  ///
  /// In en, this message translates to:
  /// **'Tried it'**
  String get markTried;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesLabel(int n);

  /// No description provided for @missedRange.
  ///
  /// In en, this message translates to:
  /// **'Missed: it is {said}.'**
  String missedRange(String said);

  /// No description provided for @modeBigger.
  ///
  /// In en, this message translates to:
  /// **'Which is bigger?'**
  String get modeBigger;

  /// No description provided for @modeBiggerLine.
  ///
  /// In en, this message translates to:
  /// **'Two figures you can work out. Tap the bigger one'**
  String get modeBiggerLine;

  /// No description provided for @modeCloser.
  ///
  /// In en, this message translates to:
  /// **'Closer, closer'**
  String get modeCloser;

  /// No description provided for @modeCloserLine.
  ///
  /// In en, this message translates to:
  /// **'Three steps of more or less to close in on the number'**
  String get modeCloserLine;

  /// No description provided for @modePick.
  ///
  /// In en, this message translates to:
  /// **'Pick one'**
  String get modePick;

  /// No description provided for @modePickLine.
  ///
  /// In en, this message translates to:
  /// **'Three amounts. Commit before you open the card'**
  String get modePickLine;

  /// No description provided for @modeRange.
  ///
  /// In en, this message translates to:
  /// **'Bet a range'**
  String get modeRange;

  /// No description provided for @modeRangeLine.
  ///
  /// In en, this message translates to:
  /// **'The narrower you go, the more it pays, if you\'re right'**
  String get modeRangeLine;

  /// No description provided for @modeSlide.
  ///
  /// In en, this message translates to:
  /// **'Move it'**
  String get modeSlide;

  /// No description provided for @modeSlideLine.
  ///
  /// In en, this message translates to:
  /// **'Set your answer first, then see how far off you were'**
  String get modeSlideLine;

  /// No description provided for @modeStake.
  ///
  /// In en, this message translates to:
  /// **'Place your bet'**
  String get modeStake;

  /// No description provided for @modeStakeLine.
  ///
  /// In en, this message translates to:
  /// **'{n} points a day. Win and you double your stake'**
  String modeStakeLine(int n);

  /// No description provided for @monthShelfLine.
  ///
  /// In en, this message translates to:
  /// **'A new subject every month, the same for everyone'**
  String get monthShelfLine;

  /// No description provided for @moodMeta.
  ///
  /// In en, this message translates to:
  /// **'{cards, plural, =1{1 card} other{{cards} cards}} · {minutes} min'**
  String moodMeta(int cards, int minutes);

  /// No description provided for @moodTime.
  ///
  /// In en, this message translates to:
  /// **'Time you have'**
  String get moodTime;

  /// No description provided for @moodTitle.
  ///
  /// In en, this message translates to:
  /// **'Your mood, your minutes'**
  String get moodTitle;

  /// No description provided for @moodTone.
  ///
  /// In en, this message translates to:
  /// **'Tone'**
  String get moodTone;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @moreOrLess.
  ///
  /// In en, this message translates to:
  /// **'More or less than {v}?'**
  String moreOrLess(String v);

  /// No description provided for @moveComparedToWhat.
  ///
  /// In en, this message translates to:
  /// **'Compared to what'**
  String get moveComparedToWhat;

  /// No description provided for @moveComparedToWhatLine.
  ///
  /// In en, this message translates to:
  /// **'A change means nothing without a control'**
  String get moveComparedToWhatLine;

  /// No description provided for @moveSampling.
  ///
  /// In en, this message translates to:
  /// **'Sampling'**
  String get moveSampling;

  /// No description provided for @moveSamplingLine.
  ///
  /// In en, this message translates to:
  /// **'Who ended up in the sample decides what it can say'**
  String get moveSamplingLine;

  /// No description provided for @mythDeckHint.
  ///
  /// In en, this message translates to:
  /// **'{at} of {of} · swipe to turn it over'**
  String mythDeckHint(int at, int of);

  /// No description provided for @nOfM.
  ///
  /// In en, this message translates to:
  /// **'{at} of {of}'**
  String nOfM(int at, int of);

  /// No description provided for @newMove.
  ///
  /// In en, this message translates to:
  /// **'New to you'**
  String get newMove;

  /// No description provided for @newToMe.
  ///
  /// In en, this message translates to:
  /// **'New to me'**
  String get newToMe;

  /// No description provided for @notEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points'**
  String get notEnoughPoints;

  /// No description provided for @notSureLine.
  ///
  /// In en, this message translates to:
  /// **'One card from anywhere in Astute'**
  String get notSureLine;

  /// No description provided for @notSureTitle.
  ///
  /// In en, this message translates to:
  /// **'Not sure where to start?'**
  String get notSureTitle;

  /// No description provided for @openWord.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openWord;

  /// No description provided for @pickOneFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick one first'**
  String get pickOneFirst;

  /// No description provided for @pointsToday.
  ///
  /// In en, this message translates to:
  /// **'+{n} today'**
  String pointsToday(int n);

  /// No description provided for @puzzleOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Puzzle of the day'**
  String get puzzleOfTheDay;

  /// No description provided for @rangeWidth.
  ///
  /// In en, this message translates to:
  /// **'±{w} · {pts} pts'**
  String rangeWidth(int w, int pts);

  /// No description provided for @rightLastTime.
  ///
  /// In en, this message translates to:
  /// **'Right last time'**
  String get rightLastTime;

  /// No description provided for @sameForEveryoneCaps.
  ///
  /// In en, this message translates to:
  /// **'The same for everyone'**
  String get sameForEveryoneCaps;

  /// No description provided for @sayFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get sayFalse;

  /// No description provided for @sayTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get sayTrue;

  /// No description provided for @seriesAnchors.
  ///
  /// In en, this message translates to:
  /// **'First impressions'**
  String get seriesAnchors;

  /// No description provided for @seriesGrowth.
  ///
  /// In en, this message translates to:
  /// **'Numbers that run away'**
  String get seriesGrowth;

  /// No description provided for @seriesMeta.
  ///
  /// In en, this message translates to:
  /// **'{n} cards · about {m} min'**
  String seriesMeta(int n, int m);

  /// No description provided for @seriesOdds.
  ///
  /// In en, this message translates to:
  /// **'Odds that lie'**
  String get seriesOdds;

  /// No description provided for @seriesRetold.
  ///
  /// In en, this message translates to:
  /// **'History, retold'**
  String get seriesRetold;

  /// No description provided for @seriesStrand.
  ///
  /// In en, this message translates to:
  /// **'{name}, in a few cards'**
  String seriesStrand(String name);

  /// No description provided for @seriesStudies.
  ///
  /// In en, this message translates to:
  /// **'Why studies mislead'**
  String get seriesStudies;

  /// No description provided for @showAllN.
  ///
  /// In en, this message translates to:
  /// **'Show all {n}'**
  String showAllN(int n);

  /// No description provided for @showFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get showFewer;

  /// No description provided for @sixtyAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get sixtyAgain;

  /// No description provided for @sixtyIn.
  ///
  /// In en, this message translates to:
  /// **'in {s} seconds'**
  String sixtyIn(int s);

  /// No description provided for @sixtyLine.
  ///
  /// In en, this message translates to:
  /// **'Eight true or false. Go with your gut'**
  String get sixtyLine;

  /// No description provided for @sixtyPerfect.
  ///
  /// In en, this message translates to:
  /// **'All eight right.'**
  String get sixtyPerfect;

  /// No description provided for @sixtyScore.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{None right yet} =1{1 right so far} other{{n} right so far}}'**
  String sixtyScore(int n);

  /// No description provided for @sixtySecondsFor.
  ///
  /// In en, this message translates to:
  /// **'seconds for eight\ntrue or false'**
  String get sixtySecondsFor;

  /// No description provided for @sixtySecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{s} s'**
  String sixtySecondsLeft(int s);

  /// No description provided for @sixtyStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get sixtyStart;

  /// No description provided for @sixtyTimeUp.
  ///
  /// In en, this message translates to:
  /// **'before the time ran out'**
  String get sixtyTimeUp;

  /// No description provided for @sixtyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sixty seconds'**
  String get sixtyTitle;

  /// No description provided for @slideAverage.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Spot on, on average.} =1{1 point off, on average.} other{{n} points off, on average.}}'**
  String slideAverage(int n);

  /// No description provided for @slideNote.
  ///
  /// In en, this message translates to:
  /// **'Set it, check it. How far off you were is the point.'**
  String get slideNote;

  /// No description provided for @slideOff.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Spot on.} =1{You were 1 point off.} other{You were {n} points off.}}'**
  String slideOff(int n);

  /// No description provided for @slipEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bets yet. Each one you place lands here.'**
  String get slipEmpty;

  /// No description provided for @stakeLabel.
  ///
  /// In en, this message translates to:
  /// **'Stake'**
  String get stakeLabel;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {at} of {of}'**
  String stepOf(int at, int of);

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseMe;

  /// No description provided for @tapIfBigger.
  ///
  /// In en, this message translates to:
  /// **'Tap if bigger'**
  String get tapIfBigger;

  /// No description provided for @tapToTurn.
  ///
  /// In en, this message translates to:
  /// **'Tap to turn it over'**
  String get tapToTurn;

  /// No description provided for @tfRight.
  ///
  /// In en, this message translates to:
  /// **'Right. Open it for why.'**
  String get tfRight;

  /// No description provided for @tfWrong.
  ///
  /// In en, this message translates to:
  /// **'It\'s {side}. Open it for why.'**
  String tfWrong(String side);

  /// No description provided for @theAnswer.
  ///
  /// In en, this message translates to:
  /// **'The answer: {said}.'**
  String theAnswer(String said);

  /// No description provided for @theAstute.
  ///
  /// In en, this message translates to:
  /// **'The Astute'**
  String get theAstute;

  /// No description provided for @theLead.
  ///
  /// In en, this message translates to:
  /// **'The lead'**
  String get theLead;

  /// No description provided for @throughTime.
  ///
  /// In en, this message translates to:
  /// **'Through time'**
  String get throughTime;

  /// No description provided for @throughTimeLine.
  ///
  /// In en, this message translates to:
  /// **'From the ancient world to this year. Drag to travel'**
  String get throughTimeLine;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @todaysEdition.
  ///
  /// In en, this message translates to:
  /// **'Today\'s edition'**
  String get todaysEdition;

  /// No description provided for @toneCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get toneCurious;

  /// No description provided for @toneLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get toneLight;

  /// No description provided for @toneSerious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get toneSerious;

  /// No description provided for @toneTough.
  ///
  /// In en, this message translates to:
  /// **'Tough'**
  String get toneTough;

  /// No description provided for @unmaskBack.
  ///
  /// In en, this message translates to:
  /// **'Show it as published'**
  String get unmaskBack;

  /// No description provided for @unmaskFlipped.
  ///
  /// In en, this message translates to:
  /// **'Turn it the right way up'**
  String get unmaskFlipped;

  /// No description provided for @unmaskLine.
  ///
  /// In en, this message translates to:
  /// **'Same numbers, a different picture'**
  String get unmaskLine;

  /// No description provided for @unmaskStretched.
  ///
  /// In en, this message translates to:
  /// **'Use a fair scale'**
  String get unmaskStretched;

  /// No description provided for @unmaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Unmask the chart'**
  String get unmaskTitle;

  /// No description provided for @unmaskTotals.
  ///
  /// In en, this message translates to:
  /// **'Make the comparison fair'**
  String get unmaskTotals;

  /// No description provided for @unmaskTruncated.
  ///
  /// In en, this message translates to:
  /// **'Start the axis at zero'**
  String get unmaskTruncated;

  /// No description provided for @unmaskWindow.
  ///
  /// In en, this message translates to:
  /// **'Show the whole series'**
  String get unmaskWindow;

  /// No description provided for @whatIfTrue.
  ///
  /// In en, this message translates to:
  /// **'What if it\'s true?'**
  String get whatIfTrue;

  /// No description provided for @whatIfTrueLine.
  ///
  /// In en, this message translates to:
  /// **'Cards that keep working after you close them'**
  String get whatIfTrueLine;

  /// No description provided for @whatYouBelieve.
  ///
  /// In en, this message translates to:
  /// **'What you believe'**
  String get whatYouBelieve;

  /// No description provided for @wrongLastTime.
  ///
  /// In en, this message translates to:
  /// **'Wrong last time'**
  String get wrongLastTime;

  /// No description provided for @youLose.
  ///
  /// In en, this message translates to:
  /// **'You lose {n}.'**
  String youLose(int n);

  /// No description provided for @youWin.
  ///
  /// In en, this message translates to:
  /// **'You win {n}.'**
  String youWin(int n);

  /// No description provided for @yourPick.
  ///
  /// In en, this message translates to:
  /// **'Your pick'**
  String get yourPick;
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
