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

  /// The share sheet's main button: sends the card's picture.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

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

  /// The delete-account dialog. {store} is apple on an iPhone, google on Android, other elsewhere: where the subscription, which deleting does not cancel, is managed.
  ///
  /// In en, this message translates to:
  /// **'Your account and its backup are deleted for good, and this device starts again from the beginning. This does not cancel Astute+: {store, select, apple{a subscription is managed in your App Store settings.} google{a subscription is managed in Google Play, under Payments & subscriptions.} other{a subscription is managed in the store you bought it from.}}'**
  String deleteAccountBody(String store);

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

  /// Profile: the heading over Saved and Liked, the reader's own two shelves.
  ///
  /// In en, this message translates to:
  /// **'Your cards'**
  String get yourCards;

  /// Profile: under Liked while the shelf is empty, the gesture that likes a card (a long press).
  ///
  /// In en, this message translates to:
  /// **'Hold any card you like'**
  String get emptyLikedHint;

  /// Profile: under Saved while the shelf is empty, the gesture that saves a card (the bookmark on it).
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any card'**
  String get emptySavedHint;

  /// Profile: the Archive row's value on the free plan, whose archive shows only the last seven days (kFreeArchiveDays). Astute+ readers see how many days instead.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastSevenDays;

  /// Profile: the heading over Manage subscription and signing in or out.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// Profile: the heading over How cards are written and Usage data.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

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

  /// How cards are written, step two: every card names its sources, and a second model reads most of them as a critic.
  ///
  /// In en, this message translates to:
  /// **'Sourced, then read by a critic'**
  String get howStep2Title;

  /// Step two, said as it is: every card names its sources; most, not all, are read by a second model as a critic; what it cannot confirm waits on a list for a person, and that list is not empty. Do not promise that every claim is confirmed.
  ///
  /// In en, this message translates to:
  /// **'Every card names where its facts come from, so you can check it yourself. Most are read by a second model acting as a critic, and what it can’t confirm goes on a list for a person to check. That list isn’t empty yet.'**
  String get howStep2Line;

  /// No description provided for @howStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Five, dealt each morning'**
  String get howStep3Title;

  /// Step three: the day is dealt from the reader's subjects, cards they have not read, and a card they got right comes back later to see whether it stuck.
  ///
  /// In en, this message translates to:
  /// **'From the subjects you picked, cards you haven’t read yet. One you got right comes back later, to see if it stuck.'**
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

  /// The foot of How cards are written, under the way to report a card.
  ///
  /// In en, this message translates to:
  /// **'We read every report, and we’d rather fix a card than defend it.'**
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

  /// The come-back screen's title, under "Welcome back", for a reader whose streak lapsed: glad they are here, never what they missed.
  ///
  /// In en, this message translates to:
  /// **'Good to see you again.'**
  String get comebackTitle;

  /// Over what a lapsed streak did not take, on the come-back screen: the weeks kept, the most kept subject, the cards due back. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Still yours'**
  String get comebackStillYours;

  /// No description provided for @bestStreakStillRecord.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{One day is} other{{n} days are}} still your record. Read today\'s five and the counter starts again from one.'**
  String bestStreakStillRecord(int n);

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

  /// Title of the sheet that asks when to remind the reader. It comes before the system's own notification prompt, which iOS shows only once.
  ///
  /// In en, this message translates to:
  /// **'When should we remind you?'**
  String get reminderAskTitle;

  /// Under the sheet's title: what the reminder is. One notification a day, each carrying a question from the reader's cards (most days the first question of that day's five).
  ///
  /// In en, this message translates to:
  /// **'One notification a day, with a question from your cards.'**
  String get reminderAskLine;

  /// On the reminder sheet, only for a reader in a free trial that will turn into a paid year: a notification also comes two days before it does.
  ///
  /// In en, this message translates to:
  /// **'We’ll remind you two days before your trial ends.'**
  String get reminderAskTrialLine;

  /// A choice on the reminder sheet, with 8:30 written beside it.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get reminderAskMorning;

  /// A choice on the reminder sheet, with 12:30 written beside it.
  ///
  /// In en, this message translates to:
  /// **'Lunchtime'**
  String get reminderAskLunch;

  /// A choice on the reminder sheet, with 19:00 written beside it.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get reminderAskEvening;

  /// A choice on the reminder sheet that opens a clock, to pick any other time.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get reminderAskOther;

  /// A note under the time on the reminder sheet that the sheet started on, because the reader tends to start reading then.
  ///
  /// In en, this message translates to:
  /// **'When you usually read'**
  String get reminderAskUsual;

  /// The reminder sheet's button: keeps the time chosen, then the system asks whether the app may send notifications.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get reminderAskYes;

  /// The reminder sheet's way out. Nothing is asked of the system; the sheet comes back after the next day the reader finishes, at most twice more.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get reminderAskNotNow;

  /// Title of the sheet that asks whether Astute may use the reader's location. It comes before the system's own location prompt, and only a yes on it leads there.
  ///
  /// In en, this message translates to:
  /// **'Cards about where you live'**
  String get placeAskTitle;

  /// Under the sheet's title: what the reader gets. Now and then — at most one a day — a card about their city, region or country.
  ///
  /// In en, this message translates to:
  /// **'Now and then, Astute will deal you a card about the place you live — its history, its science, its surprises.'**
  String get placeAskLine;

  /// The promise, on the sheet and in Profile: the phone's position is turned into a city on the phone and dropped. Only the country, the region, the city and a point rounded to about 10 km are kept.
  ///
  /// In en, this message translates to:
  /// **'Only your city is kept, never your exact position.'**
  String get placeOnlyCity;

  /// A small example card on the sheet: the line a card about the reader's own city carries. Modena is the example city; write it as your language does.
  ///
  /// In en, this message translates to:
  /// **'Near you · Modena'**
  String get placeAskPreviewLine;

  /// The example card's question. The Ghirlandina is the bell tower of Modena's cathedral, which leans a little.
  ///
  /// In en, this message translates to:
  /// **'The Ghirlandina leans. By how much?'**
  String get placeAskPreviewQuestion;

  /// The sheet's button: keeps the yes, then the system asks whether the app may use the location while it is open.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get placeAskYes;

  /// The sheet's way out. Nothing is asked of the system; the sheet comes back once, after the seventh finished day.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get placeAskNotNow;

  /// In Profile: the setting for the place the reader lives, and the title of its sheet.
  ///
  /// In en, this message translates to:
  /// **'Where you live'**
  String get placeRowTitle;

  /// In Profile, under Where you live, when Astute keeps no place.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get placeRowOff;

  /// In Profile, under Off: what switching it on gives.
  ///
  /// In en, this message translates to:
  /// **'Switch it on for cards about the place you live.'**
  String get placeRowOffLine;

  /// In Profile, beside Where you live when it is off: opens the sheet that asks.
  ///
  /// In en, this message translates to:
  /// **'Switch on'**
  String get placeSwitchOn;

  /// In the Where you live sheet: reads where the reader is again, now.
  ///
  /// In en, this message translates to:
  /// **'Use my location now'**
  String get placeUseNow;

  /// In the Where you live sheet: forgets the place on the phone, in the backup and in measurement.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get placeRemove;

  /// A short message once the place is read. {place} is the city, or the region or country when there is no city.
  ///
  /// In en, this message translates to:
  /// **'Where you live: {place}'**
  String placeSetTo(String place);

  /// A short message after the place is removed.
  ///
  /// In en, this message translates to:
  /// **'Removed. Astute no longer keeps where you live.'**
  String get placeRemoved;

  /// A short message when the phone could not say where the reader is (no fix, no name for it). The app tries again on a later day by itself.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t find where you are just now. Astute will try again another day.'**
  String get placeNotFound;

  /// A short message after the reader said no to the system's location prompt.
  ///
  /// In en, this message translates to:
  /// **'No problem. You can switch it on in Profile whenever you like.'**
  String get placeDeniedNote;

  /// A short message when location services are switched off for the whole phone.
  ///
  /// In en, this message translates to:
  /// **'Location is off on this phone. Switch it on in Settings, then try again.'**
  String get placeServicesOff;

  /// A short message where nothing can say where the reader is: the web.
  ///
  /// In en, this message translates to:
  /// **'This device can’t say where you are.'**
  String get placeNotHere;

  /// Title of the dialog shown when the system will no longer ask for the location itself: the reader can only allow it in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Location is off for Astute'**
  String get placeSettingsTitle;

  /// The body of that dialog.
  ///
  /// In en, this message translates to:
  /// **'To get cards about the place you live, allow location for Astute in Settings. Only your city is kept.'**
  String get placeSettingsBody;

  /// The dialog's button: opens the app's page in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get placeSettingsOpen;

  /// Title of the notification sent two days before a free trial turns into a paid year. {days} is how many calendar days are left: 0 is today, 1 tomorrow.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Your Astute+ trial ends today.} =1{Your Astute+ trial ends tomorrow.} other{Your Astute+ trial ends in {days} days.}}'**
  String trialWarningTitle(int days);

  /// Body of that notification. {date} is the day the trial ends, as the language writes a day and month; {price} is the store's own price for the year; {path} is the way to the subscription, made of the tab's and the row's own names, e.g. 'Profile → Manage subscription'.
  ///
  /// In en, this message translates to:
  /// **'On {date} your year starts at {price}. To keep going, do nothing. To stop: {path}.'**
  String trialWarningBody(String date, String price, String path);

  /// One quiet line on the profile in a free trial's last two days, for a reader no notification will reach. {days} is how many calendar days are left: 0 is today, 1 tomorrow. Followed by ' · ' and trialNoticeManage.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Your trial ends today} =1{Your trial ends tomorrow} other{Your trial ends in {days} days}}'**
  String trialEndsNotice(int days);

  /// After the trial's line on the profile: opens the store's own screen for managing the subscription.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get trialNoticeManage;

  /// No description provided for @subjectsInTheMix.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} subjects in the mix'**
  String subjectsInTheMix(int n, int total);

  /// No description provided for @everythingIsInDrag.
  ///
  /// In en, this message translates to:
  /// **'Everything is in. Slide a subject left to see less of it, or all the way to drop it.'**
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
  /// **'Learn the why behind things, and how far to trust what you know'**
  String get tagline;

  /// No description provided for @introTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Twenty topics, five cards'**
  String get introTopicsTitle;

  /// No description provided for @introTopicsLine.
  ///
  /// In en, this message translates to:
  /// **'Written ahead by a model, and each one names its source.'**
  String get introTopicsLine;

  /// No description provided for @introQuestionTitle.
  ///
  /// In en, this message translates to:
  /// **'A question, how sure, then why'**
  String get introQuestionTitle;

  /// No description provided for @introQuestionLine.
  ///
  /// In en, this message translates to:
  /// **'Say how sure you are first. In time you see what your “sure” is worth.'**
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

  /// The intro's one big button: into the app with no account.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// The quiet line under Start reading, before the words that sign in.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAnAccount;

  /// The words that open the sign-in sheet, right after haveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// The sign-in sheet's title when it is opened from the intro, by a reader who already has an account.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get signInWelcomeTitle;

  /// Under signInWelcomeTitle: what an account brings back.
  ///
  /// In en, this message translates to:
  /// **'Sign in, and your streak, your saved cards and your record come back with you.'**
  String get signInWelcomeLine;

  /// Profile's row that offers an account, and the title of the sheet it opens.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak on a new phone'**
  String get keepStreakOnNewPhone;

  /// The title of the sheet that offers an account once, after the reader's first finished day.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak'**
  String get keepStreakTitle;

  /// Under keepStreakTitle and keepStreakOnNewPhone on the sign-in sheet: what an account keeps.
  ///
  /// In en, this message translates to:
  /// **'Sign in, and a new phone picks up where this one leaves off: your streak, your saved cards, your record.'**
  String get keepStreakLine;

  /// The way past the sign-in sheet, without an account.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get signInNotNow;

  /// A subject's name, by its key. Shown on the mix, the cards, the shelves and wherever else a subject is named. Keep each short: the mix sets them on one line in half the screen's width.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, thinking{Thinking} science{Science} maths{Maths} space{Space} psychology{Psychology} economics{Economics} technology{Technology} history{History} human_body{Human body} philosophy{Philosophy} pop_culture{Pop culture} nature{Nature} language{Language} weird_facts{Weird facts} sport{Sport} cinema{Cinema} music{Music} art{Art} medicine{Medicine} food{Food} life{Life} other{{topic}}}'**
  String subjectName(String topic);

  /// Said once in the first run, on the mix, to a reader whose phone is not in English: the cards themselves are written in English for now.
  ///
  /// In en, this message translates to:
  /// **'The cards are in English for now; the app speaks your language.'**
  String get cardsInEnglishNote;

  /// Under the intro's buttons. {terms} and {privacy} are termsLineTerms and termsLinePrivacy, drawn as links to the terms and the privacy policy; write them in the case and form this sentence needs.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our {terms} and {privacy}'**
  String termsLine(String terms, String privacy);

  /// The link to the terms inside termsLine, in the form that sentence needs.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsLineTerms;

  /// The link to the privacy policy inside termsLine, in the form that sentence needs.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get termsLinePrivacy;

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

  /// No description provided for @widgetShelfTitle.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SHELF'**
  String get widgetShelfTitle;

  /// No description provided for @widgetShelfFrom.
  ///
  /// In en, this message translates to:
  /// **'From today\'s shelf'**
  String get widgetShelfFrom;

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

  /// No description provided for @paywallRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'See how much you really know.'**
  String get paywallRecordTitle;

  /// The part of paywallRecordTitle painted in the gradient: the word for 'really', exactly as it is written there.
  ///
  /// In en, this message translates to:
  /// **'really'**
  String get paywallRecordMark;

  /// Under the paywall's headline when it was opened from the journey, for a reader without enough answers yet to have their own numbers.
  ///
  /// In en, this message translates to:
  /// **'Every day you say how sure you are. Astute+ shows whether the gap between sure and right is closing, and the moves you keep missing.'**
  String get paywallRecordLine;

  /// Under the paywall's headline, for a reader more sure than right. {sure} is how sure they say they are on average, {right} how often they are right, both in percent.
  ///
  /// In en, this message translates to:
  /// **'You say {sure}% sure and you\'re right {right}% of the time. Astute+ shows whether that gap is closing, and the moves you keep missing.'**
  String paywallRecordOver(int sure, int right);

  /// Under the paywall's headline, for a reader more often right than sure. {sure} is how sure they say they are on average, {right} how often they are right, both in percent.
  ///
  /// In en, this message translates to:
  /// **'You say {sure}% sure and you\'re right {right}% of the time: you know more than you think. Astute+ shows whether that gap is closing.'**
  String paywallRecordUnder(int sure, int right);

  /// Under the paywall's headline, for a reader whose confidence is within five points of how often they are right. {sure} and {right} in percent.
  ///
  /// In en, this message translates to:
  /// **'You say {sure}% sure and you\'re right {right}% of the time: a close match. Astute+ shows whether it holds, and the moves you keep missing.'**
  String paywallRecordEven(int sure, int right);

  /// No description provided for @paywallOutcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Be the one nobody fools.'**
  String get paywallOutcomeTitle;

  /// The part of paywallOutcomeTitle painted in the gradient: the word for being fooled, exactly as it is written there.
  ///
  /// In en, this message translates to:
  /// **'fools.'**
  String get paywallOutcomeMark;

  /// No description provided for @paywallOutcomeLine.
  ///
  /// In en, this message translates to:
  /// **'Five cards a day at your level. The ones you miss come back until they stick. And you see yourself change, week by week.'**
  String get paywallOutcomeLine;

  /// No description provided for @paywallFiveTitle.
  ///
  /// In en, this message translates to:
  /// **'All five, yours.'**
  String get paywallFiveTitle;

  /// The part of paywallFiveTitle painted in the gradient: the word for 'yours', exactly as it is written there.
  ///
  /// In en, this message translates to:
  /// **'yours.'**
  String get paywallFiveMark;

  /// No description provided for @paywallFiveLine.
  ///
  /// In en, this message translates to:
  /// **'Free days pick two of the five for you, three after a week in a row. Astute+ picks all five from your strands, at your level, and brings back the ones you miss.'**
  String get paywallFiveLine;

  /// No description provided for @paywallReadTitle.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve read, day by day.'**
  String get paywallReadTitle;

  /// The part of paywallReadTitle painted in the gradient: the words for 'day by day', exactly as they are written there.
  ///
  /// In en, this message translates to:
  /// **'day by day.'**
  String get paywallReadMark;

  /// Under the paywall's headline when it was opened from the archive, which lists the days the reader finished, newest first.
  ///
  /// In en, this message translates to:
  /// **'The days you\'ve read lately, newest first. Tap one to open its five cards, and a card to read it again.'**
  String get paywallReadLine;

  /// No description provided for @perkGapTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch the gap close'**
  String get perkGapTitle;

  /// No description provided for @perkGapLine.
  ///
  /// In en, this message translates to:
  /// **'Your journey, week by week: how sure against how right, and the moves you keep missing.'**
  String get perkGapLine;

  /// No description provided for @perkOwnFiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Five of your own cards'**
  String get perkOwnFiveTitle;

  /// No description provided for @perkOwnFiveLine.
  ///
  /// In en, this message translates to:
  /// **'Every day, at your level, with the ones you miss coming back.'**
  String get perkOwnFiveLine;

  /// No description provided for @perkReadTitle.
  ///
  /// In en, this message translates to:
  /// **'What you\'ve read'**
  String get perkReadTitle;

  /// No description provided for @perkReadLine.
  ///
  /// In en, this message translates to:
  /// **'Your recent days, each with its five cards, ready to open again.'**
  String get perkReadLine;

  /// First step of the trial timeline under the paywall's button.
  ///
  /// In en, this message translates to:
  /// **'Today · all of Astute+, free'**
  String get trialToday;

  /// Second step of the trial timeline: the day, counted from today, a reminder that the trial is ending is sent.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · we remind you'**
  String trialReminder(int day);

  /// The last step of the free trial under the paywall's button: the day the plan is charged, at the store's price, and that it renews automatically.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {price} {plan, select, year{a year} other{a month}}, renewing automatically until you cancel'**
  String trialCharge(int day, String price, String plan);

  /// Under the paywall's button, for a plan with no free days: what is charged today, and that it renews automatically.
  ///
  /// In en, this message translates to:
  /// **'{price}{suffix} charged today, renewing automatically until you cancel'**
  String chargedTodayRenews(String price, String suffix);

  /// Under the paywall's terms: where the plan is cancelled, and by when. {where} is cancelWhereIos or cancelWhereAndroid.
  ///
  /// In en, this message translates to:
  /// **'Cancel any time in {where}, at least 24 hours before it renews.'**
  String cancelHow(String where);

  /// Where a subscription is cancelled on an iPhone, as the Settings app names it.
  ///
  /// In en, this message translates to:
  /// **'Settings › your name › Subscriptions'**
  String get cancelWhereIos;

  /// Where a subscription is cancelled on Android, as the Play Store names it.
  ///
  /// In en, this message translates to:
  /// **'Google Play › Payments & subscriptions › Subscriptions'**
  String get cancelWhereAndroid;

  /// On the paywall while the store is asked for its prices. apple is the App Store; other is Google Play.
  ///
  /// In en, this message translates to:
  /// **'{store, select, apple{Asking the App Store for the prices…} other{Asking Google Play for the prices…}}'**
  String storeAsking(String store);

  /// On the paywall when the store did not answer, in place of the plans; and after a restore that could not reach it.
  ///
  /// In en, this message translates to:
  /// **'{store, select, apple{Couldn’t reach the App Store} other{Couldn’t reach Google Play}}'**
  String storeUnreachable(String store);

  /// Under storeUnreachable on the paywall.
  ///
  /// In en, this message translates to:
  /// **'The prices and the free trial come from the store. Check your connection and try again.'**
  String get storeUnreachableLine;

  /// The button that asks the store again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// After a purchase that waits on someone's approval (Ask to Buy, a bank): not a failure.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval. Astute+ opens as soon as the payment goes through.'**
  String get purchasePending;

  /// The paywall's button while a purchase is under way.
  ///
  /// In en, this message translates to:
  /// **'One moment…'**
  String get oneMoment;

  /// What a screen reader says for the cross that closes the paywall.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

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

  /// No description provided for @youSaidItIsCounted.
  ///
  /// In en, this message translates to:
  /// **'You said {given} · it is {answer}, and {band} counted'**
  String youSaidItIsCounted(String given, String answer, String band);

  /// No description provided for @youSaidItIs.
  ///
  /// In en, this message translates to:
  /// **'You said {given} · it is {answer}'**
  String youSaidItIs(String given, String answer);

  /// No description provided for @lineYouSaidSure.
  ///
  /// In en, this message translates to:
  /// **'{line} · you said {pct}% sure'**
  String lineYouSaidSure(String line, int pct);

  /// The verdict on the back of a card answered right, set large.
  ///
  /// In en, this message translates to:
  /// **'Right.'**
  String get verdictRight;

  /// The verdict on the back of an estimate placed close enough, set large.
  ///
  /// In en, this message translates to:
  /// **'Close enough.'**
  String get verdictClose;

  /// The verdict on the back of a card answered wrong, set large: kind, not a scolding.
  ///
  /// In en, this message translates to:
  /// **'Not quite.'**
  String get verdictWrong;

  /// Under the verdict: how sure the reader said they were. {pct} is 50 to 90.
  ///
  /// In en, this message translates to:
  /// **'You were {pct}% sure.'**
  String verdictSure(int pct);

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

  /// No description provided for @musicSound.
  ///
  /// In en, this message translates to:
  /// **'Sound in music cards'**
  String get musicSound;

  /// No description provided for @musicSoundIsOff.
  ///
  /// In en, this message translates to:
  /// **'Sound is off for music cards.'**
  String get musicSoundIsOff;

  /// No description provided for @musicSoundTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get musicSoundTurnOn;

  /// No description provided for @thatWasTheOnlyOne.
  ///
  /// In en, this message translates to:
  /// **'That was the only one'**
  String get thatWasTheOnlyOne;

  /// Under the re-read deck, on its last card: the next throw ends the deck.
  ///
  /// In en, this message translates to:
  /// **'The last one'**
  String get lastOne;

  /// The card after the last one in a re-read deck. {word} is how many cards there were, as countWord says it: 'eight'.
  ///
  /// In en, this message translates to:
  /// **'That\'s all {word}.'**
  String deckEndTitle(String word);

  /// The quiet button on the card after the last one: back to the first card of the deck.
  ///
  /// In en, this message translates to:
  /// **'Start again from the first'**
  String get deckEndAgain;

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
  /// **'{n, plural, =1{A card you answered days ago, back to see if it stuck} other{{n} cards you answered days ago, back to see if they stuck}}'**
  String cardsCameBack(int n);

  /// No description provided for @cameBack.
  ///
  /// In en, this message translates to:
  /// **'Do you still remember?'**
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

  /// The question asked on the intro, and as a sheet once after the first finished day, before anything is measured: may Astute measure how the app is used?
  ///
  /// In en, this message translates to:
  /// **'Help make Astute better?'**
  String get consentTitle;

  /// Under consentTitle on the intro, in one breath with it: what would be shared, and what never is. Short: two lines on a small phone, so the intro keeps its picture.
  ///
  /// In en, this message translates to:
  /// **'Share how you use the app — never your name, your email or what you write.'**
  String get consentLine;

  /// The answer that keeps measurement off. Exactly as prominent as consentYes, side by side.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get consentNo;

  /// The answer that turns measurement on. Exactly as prominent as consentNo, side by side.
  ///
  /// In en, this message translates to:
  /// **'Yes, share'**
  String get consentYes;

  /// The foot of the consent sheet: where the answer can be changed. {profile} is the Profile tab's name (tabProfile), {setting} the switch's (anonymousUsage).
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in {profile}, under {setting}.'**
  String consentChangeLater(String profile, String setting);

  /// No description provided for @yourMix.
  ///
  /// In en, this message translates to:
  /// **'Your mix'**
  String get yourMix;

  /// The title of the onboarding step after the mix, where the reader picks which genres of each subject they want.
  ///
  /// In en, this message translates to:
  /// **'Which parts?'**
  String get genresTitle;

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

  /// On the card after the fifth, offering Astute+: what it gives from tomorrow. All five chosen for the reader, at their level, and the cards they miss come back (reviews are Astute+ only).
  ///
  /// In en, this message translates to:
  /// **'Five cards a day chosen for you: from your mix, at your level, and the ones you miss come back. From tomorrow.'**
  String get magicLine;

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

  /// No description provided for @archiveBeforeThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Before this week'**
  String get archiveBeforeThisWeek;

  /// The note the evening of a seventh day in a row on the free plan: tomorrow has one more card of the reader's own, so three of the five are chosen for them. Not "a week kept", which is five days of a calendar week.
  ///
  /// In en, this message translates to:
  /// **'Seven days in a row: tomorrow three of the five are yours.'**
  String get weekKeptThreeOwn;

  /// The note the evening of a seventh day in a row on the free plan, when tomorrow is also Sunday: the extra card of the reader's own and Sunday's both, so four of the five cards are chosen for them.
  ///
  /// In en, this message translates to:
  /// **'Seven days in a row, and tomorrow is Sunday: four of the five are yours.'**
  String get weekKeptSundayFourOwn;

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
  /// **'Something to try, or to drop into a conversation, before tonight'**
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

  /// No description provided for @storyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to go on · hold to pause'**
  String get storyHint;

  /// No description provided for @storyTapOn.
  ///
  /// In en, this message translates to:
  /// **'Tap to go on'**
  String get storyTapOn;

  /// No description provided for @storyPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get storyPrevious;

  /// No description provided for @storyClose.
  ///
  /// In en, this message translates to:
  /// **'Close the story'**
  String get storyClose;

  /// No description provided for @storySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get storySave;

  /// No description provided for @storySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get storySaved;

  /// No description provided for @storyShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get storyShare;

  /// No description provided for @storyOpenCard.
  ///
  /// In en, this message translates to:
  /// **'Open the card'**
  String get storyOpenCard;

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
  /// **'Guess the number before the card tells you'**
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

  /// The title of the screen a purchase ends on, when what began is a free trial rather than a paid plan.
  ///
  /// In en, this message translates to:
  /// **'Free trial started.'**
  String get trialStartedTitle;

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

  /// Under the title of the screen a purchase ends on, when today's five are already read.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Astute+. Tomorrow’s five are all yours.'**
  String get successWelcomeTomorrow;

  /// successWelcomeTomorrow with the reader's first name.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Astute+, {name}. Tomorrow’s five are all yours.'**
  String successWelcomeTomorrowNamed(String name);

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

  /// No description provided for @modeCloser.
  ///
  /// In en, this message translates to:
  /// **'Closer, closer'**
  String get modeCloser;

  /// No description provided for @modePick.
  ///
  /// In en, this message translates to:
  /// **'Pick one'**
  String get modePick;

  /// No description provided for @modeRange.
  ///
  /// In en, this message translates to:
  /// **'Bet a range'**
  String get modeRange;

  /// No description provided for @modeSlide.
  ///
  /// In en, this message translates to:
  /// **'Move it'**
  String get modeSlide;

  /// No description provided for @modeStake.
  ///
  /// In en, this message translates to:
  /// **'Place your bet'**
  String get modeStake;

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
  /// **'A lot, or a little?'**
  String get moveComparedToWhat;

  /// No description provided for @moveComparedToWhatLine.
  ///
  /// In en, this message translates to:
  /// **'“Up 30%” means nothing until you know: compared to what?'**
  String get moveComparedToWhatLine;

  /// No description provided for @askingTitle.
  ///
  /// In en, this message translates to:
  /// **'A question from every subject'**
  String get askingTitle;

  /// No description provided for @askingIn.
  ///
  /// In en, this message translates to:
  /// **'Questions in {subject}'**
  String askingIn(String subject);

  /// No description provided for @askingLine.
  ///
  /// In en, this message translates to:
  /// **'The same for everyone. Answer first, then see why'**
  String get askingLine;

  /// No description provided for @moveSampling.
  ///
  /// In en, this message translates to:
  /// **'Who\'s missing from the data?'**
  String get moveSampling;

  /// No description provided for @moveSamplingLine.
  ///
  /// In en, this message translates to:
  /// **'Every statistic counts some people and misses others. Who was left out can flip the answer'**
  String get moveSamplingLine;

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

  /// No description provided for @slideOff.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Spot on.} =1{You were 1 point off.} other{You were {n} points off.}}'**
  String slideOff(int n);

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

  /// Under a debate on the Pick a side shelf, before the reader has leant either way: the word between the two sides is a handle to drag.
  ///
  /// In en, this message translates to:
  /// **'Slide the “{or}” to where you stand'**
  String leanHint(String or);

  /// How far the reader leant towards a side, from 1 (just past the middle) to 4 (the end of the track).
  ///
  /// In en, this message translates to:
  /// **'{level, select, 1{a little} 2{on balance} 3{firmly} other{all the way}}'**
  String leanHow(String level);

  /// A side and how far the reader leans to it: Yes, firmly.
  ///
  /// In en, this message translates to:
  /// **'{side}, {how}'**
  String leanSays(String side, String how);

  /// No description provided for @leanTook.
  ///
  /// In en, this message translates to:
  /// **'You took {side}'**
  String leanTook(String side);

  /// No description provided for @leanVerdict.
  ///
  /// In en, this message translates to:
  /// **'{says}. Open it for the other side.'**
  String leanVerdict(String says);

  /// No description provided for @spotTitle.
  ///
  /// In en, this message translates to:
  /// **'Spot the false one'**
  String get spotTitle;

  /// No description provided for @spotLine.
  ///
  /// In en, this message translates to:
  /// **'Four claims. Three are true, one is false.'**
  String get spotLine;

  /// No description provided for @spotPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap the one you think is false'**
  String get spotPrompt;

  /// No description provided for @spotConfirm.
  ///
  /// In en, this message translates to:
  /// **'That\'s the false one'**
  String get spotConfirm;

  /// No description provided for @spotFound.
  ///
  /// In en, this message translates to:
  /// **'Found it. The other three are true.'**
  String get spotFound;

  /// No description provided for @spotMissed.
  ///
  /// In en, this message translates to:
  /// **'Not that one: it\'s true. The false one is struck out.'**
  String get spotMissed;

  /// No description provided for @spotWhy.
  ///
  /// In en, this message translates to:
  /// **'Tap any of them to read why'**
  String get spotWhy;

  /// No description provided for @spotYours.
  ///
  /// In en, this message translates to:
  /// **'Your pick'**
  String get spotYours;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

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

  /// On the front of a card about the reader's city, in small type under the subject: why the card is in front of them. {place} is the city's name, in English for now.
  ///
  /// In en, this message translates to:
  /// **'Near you · {place}'**
  String placeNearYou(String place);

  /// On the front of a card about the reader's region, in small type under the subject. {place} is the region's name, in English for now: Emilia-Romagna.
  ///
  /// In en, this message translates to:
  /// **'Your region · {place}'**
  String placeYourRegion(String place);

  /// On the front of a card about the reader's country, in small type under the subject. {place} is the country's name, in English for now: Italy.
  ///
  /// In en, this message translates to:
  /// **'Your country · {place}'**
  String placeYourCountry(String place);

  /// On the reader's Sunday, on the free plan, a quiet line under the head of the first of their own cards: one of the five that would have come at random was chosen for them instead. The card is the one more, so it need not say 'card'.
  ///
  /// In en, this message translates to:
  /// **'Sunday: one more chosen for you'**
  String get sundayOneMore;

  /// Title of the Explore shelf of cards about the reader's city, region and country.
  ///
  /// In en, this message translates to:
  /// **'Where you live'**
  String get whereYouLive;

  /// Under the title of the Where you live shelf: the order its cards come in.
  ///
  /// In en, this message translates to:
  /// **'Your city first, then your region, then your country'**
  String get whereYouLiveLine;

  /// On the Where you live shelf for a reader who has not said where they live: what switching it on gives, and the promise about what is kept.
  ///
  /// In en, this message translates to:
  /// **'Cards about your city, your region and your country: one a day at most, and this shelf. Only your city is kept, never where you are exactly.'**
  String get whereYouLiveAsk;

  /// The button on the Where you live shelf that asks the reader where they live.
  ///
  /// In en, this message translates to:
  /// **'Switch it on'**
  String get whereYouLiveSwitchOn;

  /// Over the read-or-do shelves: how many of their cards ask the reader to do something, and how many are to read.
  ///
  /// In en, this message translates to:
  /// **'{toDo} to do, {toRead} to read'**
  String purposeReadOrDoCount(int toDo, int toRead);

  /// Beside one read-or-do shelf: how many of its cards are to do and to read.
  ///
  /// In en, this message translates to:
  /// **'{toDo} to do · {toRead} to read'**
  String purposeShelfCount(int toDo, int toRead);

  /// The read-or-do filter: only the cards to read. Short, it shares a small bar with two others.
  ///
  /// In en, this message translates to:
  /// **'To read'**
  String get purposeFilterToRead;

  /// The read-or-do filter: only the cards that ask something of the reader. Short.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get purposeFilterToDo;

  /// What a card has the reader do, on a chip at its foot: answer true or false, pick an option, type a number, bet on a number, take a side, answer for yourself first, move a slider, guess what happens next, and the other ways a card can be played. Short: it sits on one line in a chip half a card wide.
  ///
  /// In en, this message translates to:
  /// **'{verb, select, trueFalse{True or false} pick{Pick one} typeNumber{Type a number} bet{Bet the number} side{Pick a side} youFirst{You first} moveIt{Move it and watch} whatNext{What happens next?} spotTrick{Spot the trick} drawIt{Draw it} sortThem{Sort them} putInOrder{Put them in order} holdIt{Hold it} growSample{Grow a sample} askWhy{Ask why} sayPlainly{Say it plainly} pairUp{Pair them up} followClues{Follow the clues} look{Just look} listen{Listen} other{{verb}}}'**
  String purposeVerb(String verb);

  /// On a card with nothing to answer: read it, and about how long it takes.
  ///
  /// In en, this message translates to:
  /// **'Read · {n} min'**
  String purposeVerbRead(int n);

  /// Over the shelves where the reader answers before the card opens, beside a lock.
  ///
  /// In en, this message translates to:
  /// **'Answer here, then open the card to see if you were right. A guess you commit to stays with you longer.'**
  String get purposeCommitNote;

  /// A shelf of cards answered on the shelf, before they open: true or false, a side, an amount.
  ///
  /// In en, this message translates to:
  /// **'Answer first'**
  String get purposeCommitTitle;

  /// Under Answer first.
  ///
  /// In en, this message translates to:
  /// **'Say what you think, then open the card'**
  String get purposeCommitLine;

  /// Under Work it out, on a shelf of numbers worked out before the card opens.
  ///
  /// In en, this message translates to:
  /// **'A number to reach in your head'**
  String get purposeInYourHeadLine;

  /// In the answer box on a card: work the number out in your head and type it. Small capitals.
  ///
  /// In en, this message translates to:
  /// **'In your head'**
  String get purposeInYourHead;

  /// Over a thinking move's name, set large in a box: what the box holds. Small capitals.
  ///
  /// In en, this message translates to:
  /// **'A move'**
  String get purposeMoveKicker;

  /// On a thinking move the reader has not met yet: what it adds to their score once they have it down.
  ///
  /// In en, this message translates to:
  /// **'New · +{points} when you have it down'**
  String purposeMoveNew(int points);

  /// A thinking move's name: the trap or the skill a card trains, by its key. Short: set large on a box and on a button.
  ///
  /// In en, this message translates to:
  /// **'{move, select, baseRate{Base rates} survivorship{Survivorship} regression{Regression to the mean} confirmation{Confirmation} anchoring{Anchoring} sampling{Sampling} confounding{Confounding} counterfactual{Compared to what} multipleComparisons{Multiple looks} availability{Availability} sunkCost{Sunk cost} conjunction{Conjunction} conditional{Conditional odds} independence{Independence} coincidence{Coincidence} exponential{Exponential growth} reflection{The quick answer} simpson{Aggregates} estimation{Estimation} computation{Working it out} other{{move}}}'**
  String purposeMoveName(String move);

  /// A thinking move in one line, under its name.
  ///
  /// In en, this message translates to:
  /// **'{move, select, baseRate{How accurate a test is, is not how likely you are} survivorship{The data you have is the data that survived} regression{Extremes drift back on their own} confirmation{Looking for a yes is not a test} anchoring{The first number said moves every number after} sampling{Who ended up in the sample decides what it can say} confounding{Something else may be causing both} counterfactual{A change means nothing without a control} multipleComparisons{Test enough things and one will pass} availability{Easy to picture is not the same as common} sunkCost{Spent is spent; only what is left can be decided} conjunction{Detail makes a story likelier and less probable} conditional{What you were told changes the odds} independence{Chance has no memory} coincidence{Rare things are common when there are many tries} exponential{Nobody has intuition for doubling} reflection{The answer that arrives first is the one to check} simpson{A whole can lean the way no part of it does} estimation{Break the unanswerable into things you can guess} computation{A problem you can actually finish} other{{move}}}'**
  String purposeMoveLine(String move);

  /// The question each thinking move asks: what to ask of a claim to catch the trap. One short question.
  ///
  /// In en, this message translates to:
  /// **'{move, select, baseRate{How common was it to begin with?} survivorship{What never made it into the data?} regression{Is it just an extreme drifting back?} confirmation{What would prove me wrong?} anchoring{Which number came first?} sampling{Who got counted?} confounding{What else could cause both?} counterfactual{Compared to what?} multipleComparisons{How many things were tried?} availability{Is it common, or just easy to picture?} sunkCost{What is left to decide from here?} conjunction{Does each detail make it less likely?} conditional{What does knowing that change?} independence{Does the last result change the next?} coincidence{How many chances were there?} exponential{What happens when it doubles again?} reflection{Is the first answer the right one?} simpson{Does every part lean the same way?} estimation{What can I guess on the way there?} computation{Can I work it out step by step?} other{{move}}}'**
  String purposeMoveAsk(String move);

  /// A shelf of cards a step harder than the reader's level in their subject.
  ///
  /// In en, this message translates to:
  /// **'A step above'**
  String get purposeStepAbove;

  /// Under A step above.
  ///
  /// In en, this message translates to:
  /// **'Harder than what you usually read'**
  String get purposeStepAboveLine;

  /// A shelf of the subject the reader has read least of. {subject} is the subject's name.
  ///
  /// In en, this message translates to:
  /// **'Thin for you: {subject}'**
  String purposeThinTitle(String subject);

  /// Under the thinnest subject's name: how much of its cards the reader has read, in per cent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the {subject} shelf read, your least'**
  String purposeThinLine(int percent, String subject);

  /// A shelf of the debates the reader took a side on, each opening on the case against it.
  ///
  /// In en, this message translates to:
  /// **'The other side'**
  String get purposeOtherSide;

  /// Under The other side.
  ///
  /// In en, this message translates to:
  /// **'You took a side. Here is the best case against it'**
  String get purposeOtherSideLine;

  /// On a debate the reader answered: the side they took, in a small badge. {side} is the side's word, from the card (Yes, No).
  ///
  /// In en, this message translates to:
  /// **'You said {side}'**
  String purposeYouSaid(String side);

  /// On a debate the reader answered: the button that opens the card on the other side's case. {side} is that side's word, from the card.
  ///
  /// In en, this message translates to:
  /// **'The case for “{side}”'**
  String purposeCaseFor(String side);

  /// At the foot of a card on How it really works: what the card explains. Small capitals.
  ///
  /// In en, this message translates to:
  /// **'The mechanism'**
  String get purposeMechanism;

  /// Across the top of a card about something still changing: when it was last brought up to date. {date} is a short date, 4 Oct.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String purposeMovingUpdated(String date);

  /// Across the top of a card whose answer could go stale within a few years.
  ///
  /// In en, this message translates to:
  /// **'Could change in a few years'**
  String get purposeMovingYears;

  /// Across the top of a card whose answer could go stale within the year.
  ///
  /// In en, this message translates to:
  /// **'Could change this year'**
  String get purposeMovingMonths;

  /// A shelf of cards that each explain one mechanism: the feeling of finally understanding why.
  ///
  /// In en, this message translates to:
  /// **'Ah, so that\'s why'**
  String get purposeWhy;

  /// Under Ah, so that's why.
  ///
  /// In en, this message translates to:
  /// **'One mechanism, explained until it clicks'**
  String get purposeWhyLine;

  /// At the foot of a card on Ah, so that's why: the why it explains, and how long it takes. Small capitals.
  ///
  /// In en, this message translates to:
  /// **'The why · {n} min'**
  String purposeWhyBand(int n);

  /// A shelf of cards about habits the reader may recognise in themselves, and the button on each to say so.
  ///
  /// In en, this message translates to:
  /// **'That\'s me'**
  String get purposeMe;

  /// Under That's me.
  ///
  /// In en, this message translates to:
  /// **'Things you do without noticing'**
  String get purposeMeLine;

  /// Beside the count of cards the reader marked That's me.
  ///
  /// In en, this message translates to:
  /// **'Mark the cards that sound like you.'**
  String get purposeMeFooter;

  /// A shelf of discoveries about the reader's own body and health.
  ///
  /// In en, this message translates to:
  /// **'News to me, and about me'**
  String get purposeAboutYou;

  /// Under News to me, and about me.
  ///
  /// In en, this message translates to:
  /// **'Your body, your health, your odds'**
  String get purposeAboutYouLine;

  /// A shelf of claims and studies set like newspaper headlines.
  ///
  /// In en, this message translates to:
  /// **'In a headline'**
  String get purposeHeadline;

  /// Under In a headline.
  ///
  /// In en, this message translates to:
  /// **'Studies and claims that sound better than they are'**
  String get purposeHeadlineLine;

  /// Over a headline on a card: what it is. Small capitals.
  ///
  /// In en, this message translates to:
  /// **'The claim'**
  String get purposeTheClaim;

  /// A shelf of figures that need a second look: odds, percentages.
  ///
  /// In en, this message translates to:
  /// **'In a number'**
  String get purposeNumber;

  /// Under In a number.
  ///
  /// In en, this message translates to:
  /// **'Odds and percentages that need a second look'**
  String get purposeNumberLine;

  /// Under a figure set large on a card: the question to ask of it. Small capitals.
  ///
  /// In en, this message translates to:
  /// **'Out of what?'**
  String get purposeOutOfWhat;

  /// A shelf of cards drawn as price tags: prices, deals and who pays.
  ///
  /// In en, this message translates to:
  /// **'In an offer'**
  String get purposeOffer;

  /// Under In an offer.
  ///
  /// In en, this message translates to:
  /// **'Prices, deals and who really pays'**
  String get purposeOfferLine;

  /// A shelf of cards drawn as speech bubbles: arguments and where they go wrong.
  ///
  /// In en, this message translates to:
  /// **'In an argument'**
  String get purposeArgument;

  /// Under In an argument.
  ///
  /// In en, this message translates to:
  /// **'Where the reasoning slips'**
  String get purposeArgumentLine;

  /// Over a short list of questions, each one a thinking move, that catch most of the tricks on the shelves above. {n} is how many, 1 to 5.
  ///
  /// In en, this message translates to:
  /// **'{n, select, 1{One question that catches most of these} 2{Two questions that catch most of these} 3{Three questions that catch most of these} 4{Four questions that catch most of these} 5{Five questions that catch most of these} other{{n} questions that catch most of these}}'**
  String purposeKeepHeading(String n);

  /// What a question for the reader's own life is about, in small capitals over it: money, work and time, time, the body, relationships, beliefs.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, money{Money} work{Work and time} clock{Time} body{Your body} relationships{Relationships} belief{What you believe} other{{topic}}}'**
  String purposeLifeAbout(String topic);

  /// A question for the reader to ask of their own life, set large over the cards that ask it, by what it is about.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, money{Am I paying for what I actually use?} work{What would make tomorrow easier to start?} clock{Where does my time actually go?} body{Is what I know about my body still true?} relationships{What do the people close to me actually need?} belief{How sure am I, and why?} other{{topic}}}'**
  String purposeLifeQuestion(String topic);

  /// A chip the reader picks to say what they want better questions about. Short.
  ///
  /// In en, this message translates to:
  /// **'{topic, select, money{Money} work{Work} clock{Time} body{Body} relationships{Relationships} belief{What I believe} other{{topic}}}'**
  String purposeLifeChip(String topic);

  /// Over the chips that pick what the reader wants better questions about.
  ///
  /// In en, this message translates to:
  /// **'What do you want better questions about?'**
  String get purposeLifeAsk;

  /// Under those chips: picking one shows its cards just below.
  ///
  /// In en, this message translates to:
  /// **'Pick any, and the cards that ask about it come up here.'**
  String get purposeLifeFooter;

  /// A shelf of cards where the reader picks the thinking move that would catch the trick in each.
  ///
  /// In en, this message translates to:
  /// **'Spot the trick'**
  String get purposeSpotTrick;

  /// Under Spot the trick.
  ///
  /// In en, this message translates to:
  /// **'Which question would catch it?'**
  String get purposeSpotTrickLine;

  /// Over what the reader played on Explore's shelves today.
  ///
  /// In en, this message translates to:
  /// **'What you played today'**
  String get purposePlayed;

  /// Under a number: how far off the reader's guesses on a slider were, on average, in points.
  ///
  /// In en, this message translates to:
  /// **'points off, on average'**
  String get purposePlayedOff;

  /// Under a count like 2 of 3: the tricks the reader spotted on the shelf.
  ///
  /// In en, this message translates to:
  /// **'tricks spotted'**
  String get purposePlayedTricks;

  /// Under a number: cards the reader answered on a shelf rather than on the card.
  ///
  /// In en, this message translates to:
  /// **'answered on a shelf'**
  String get purposePlayedAnswered;

  /// Under what was played: answers given on a shelf count in the reader's journey. Your journey and Today are the names of two screens.
  ///
  /// In en, this message translates to:
  /// **'Answers given on a shelf count in Your journey, like the ones from Today.'**
  String get purposePlayedFooter;

  /// A count out of a total, short: 2 of 3, 7 of 12.
  ///
  /// In en, this message translates to:
  /// **'{n} of {of}'**
  String purposeOf(int n, int of);

  /// Beside a set of cards to finish: how many of them the reader has read.
  ///
  /// In en, this message translates to:
  /// **'{n} of {of} read'**
  String purposeSetRead(int n, int of);

  /// A set the reader has read every card of. {n} is how many cards.
  ///
  /// In en, this message translates to:
  /// **'All {n} read. New ones join the set when the shelf comes round again.'**
  String purposeSetDone(int n);

  /// A set the reader has finished, on its ring.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get purposeComplete;

  /// Under a set drawn as stamps, one for each card.
  ///
  /// In en, this message translates to:
  /// **'Each card you read adds its stamp.'**
  String get purposeStampsFooter;

  /// A grid of every set of cards and how far along the reader is with each.
  ///
  /// In en, this message translates to:
  /// **'Your sets'**
  String get purposeSets;

  /// Under Your sets.
  ///
  /// In en, this message translates to:
  /// **'Reading counts. You don\'t have to answer to fill a set.'**
  String get purposeSetsLine;

  /// Near the bottom of Explore: the shelves that come tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow on the shelves'**
  String get purposeTomorrow;

  /// Under Tomorrow on the shelves.
  ///
  /// In en, this message translates to:
  /// **'The shelves change every day. These come next'**
  String get purposeTomorrowLine;

  /// The last line of Explore, at the very bottom. Explore is the name of the tab.
  ///
  /// In en, this message translates to:
  /// **'That\'s the bottom of Explore'**
  String get purposeEnd;

  /// Under the last line of Explore.
  ///
  /// In en, this message translates to:
  /// **'See you tomorrow'**
  String get purposeEndLine;
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
