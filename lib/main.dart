import 'dart:async' show Timer, unawaited;

import 'package:flutter/foundation.dart'
    show ValueListenable, kIsWeb, visibleForTesting;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posthog_flutter/posthog_flutter.dart' show PostHogWidget;
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics.dart';
import 'cloud.dart';
import 'data/pill_bank.dart';
import 'debug_flags.dart';
import 'screens/comeback_screen.dart';
import 'screens/deck_viewer_screen.dart';
import 'l10n/l10n.dart';
import 'measure/install.dart';
import 'measure/screens.dart';
import 'measure/session.dart';
import 'models/pill.dart';
import 'screens/genres_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/mix_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/today_screen.dart';
import 'state/app_state.dart';
import 'sync/account.dart';
import 'sync/place_finder.dart';
import 'sync/push.dart';
import 'sync/reports.dart';
import 'sync/subscription.dart';
import 'sync/served.dart';
import 'sync/tally.dart';
import 'sync/trace.dart';
import 'utils/home_widget.dart';
import 'utils/reminders.dart' show remindersSupported;
import 'utils/upright.dart';
import 'theme.dart';
import 'widgets/ambient.dart';
import 'widgets/place_ask.dart';
import 'widgets/reminder_ask.dart';
import 'widgets/sign_in_sheet.dart';

/// The seeded crowd for Explore's top list: the live bank, tilted to what
/// readers keep — a question over a fact, a debate over both, the hard ones,
/// and the subjects people pass on.
TopSeed launchCrowd() => TopSeed(
  ids: () => PillBank.cards.map((p) => p.id),
  appeal: (id) {
    final Pill? p = PillBank.byId(id);
    if (p == null) return 0;
    var a = 1.0;
    if (p.challenge is TakeASide) {
      a *= 1.3;
    } else if (p.asksSomething) {
      a *= 1.2;
    }
    if (p.difficulty == Difficulty.hard) a *= 1.2;
    if (const {
      'Weird facts',
      'Psychology',
      'Space',
      'Human body',
    }.contains(p.topic)) {
      a *= 1.2;
    }
    return a;
  },
);

Future<void> main() async {
  Analytics.launched();
  Session.instance.launched();
  WidgetsFlutterBinding.ensureInitialized();
  // Upright on a phone, said before the first frame and not waited for.
  unawaited(holdUpright());
  // Where this install came from — the App Store, TestFlight, Google Play,
  // a test lab's robot — asked of the phone now, and answered while the
  // rest starts: by the time measurement is up it has long been said.
  final Future<String> installChannel = readInstallChannel();
  // Settled before anything is built, since the profile and a failed
  // sign-in both read it. An iPhone release build asks the phone where it
  // was installed from, and waits for the answer no longer than
  // kTestFlightWait.
  await readDebugTools();
  // Never blocks the app: see Cloud.start.
  final Stopwatch cloud = Stopwatch()..start();
  await Cloud.start();
  final int cloudMs = cloud.elapsedMilliseconds;
  // Nor this, and for the same reason: see Analytics.start. It goes before
  // runApp so that the reader's opt-out is read before the first event could
  // be sent, and not one launch later.
  await Analytics.start();
  if (Analytics.ready) {
    // Stamped before the first event, so a reviewer's phone or a robot is
    // told apart from its very first one.
    await Analytics.installedFrom(await installChannel);
    // How smoothly the phone draws, counted per session (see Session).
    Session.instance.frames.listen();
  }
  // Said once measurement is up: a Firebase that would not start is the
  // cause of half the bug reports this app could ever get.
  Analytics.capture('cloud started', {
    'ok': Cloud.ready,
    'ms': cloudMs,
    'failure': Cloud.failure == null ? null : Analytics.short(Cloud.failure!),
  });
  // Explore's top list, with the launch crowd under the real counts until
  // there are enough of them. See TopSeed.
  Tallies.instance = Tallies(seed: launchCrowd());
  // Session replay takes its pictures from under this widget. Only where
  // measurement is running and the platform records at all.
  runApp(
    Analytics.ready && !kIsWeb
        ? const PostHogWidget(child: AstutoApp())
        : const AstutoApp(),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => _saidStarted());
}

/// The first frame is on screen: how long the reader waited for it, and the
/// phone it happened on, as far as it changes what they see — the language,
/// the text size they chose, dark or light, and whether they asked for less
/// motion.
void _saidStarted() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  final view = dispatcher.views.isEmpty ? null : dispatcher.views.first;
  Analytics.capture('app started', {
    'ms_to_first_frame': Analytics.msSinceLaunch,
    'locale': dispatcher.locale.toLanguageTag(),
    'text_scale': (dispatcher.textScaleFactor * 100).round() / 100,
    'system_dark': dispatcher.platformBrightness == Brightness.dark,
    'reduce_motion': dispatcher.accessibilityFeatures.disableAnimations,
    'bold_text': dispatcher.accessibilityFeatures.boldText,
    'screen_width': view == null
        ? null
        : (view.physicalSize.width / view.devicePixelRatio).round(),
  });
  _stampDisplay();
}

/// The phone's settings that change what the reader sees, stamped on every
/// event: the text size as a band, and whether they asked for less motion.
/// Again whenever the app comes back, since either can be changed while it
/// is away.
void _stampDisplay() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  Analytics.register(
    'text_scale_bucket',
    textScaleBucket(dispatcher.textScaleFactor),
  );
  Analytics.register(
    'reduce_motion',
    dispatcher.accessibilityFeatures.disableAnimations,
  );
}

/// A text size as a band: `smaller` under the phone's default, `default`,
/// `large` up to 1.3×, `larger` up to 1.6×, and `largest` past it — where
/// a card's back has to scroll.
@visibleForTesting
String textScaleBucket(double scale) => scale < 0.95
    ? 'smaller'
    : scale <= 1.05
    ? 'default'
    : scale <= 1.3
    ? 'large'
    : scale <= 1.6
    ? 'larger'
    : 'largest';

/// On the web a list should follow the mouse the way it follows a finger.
class _DragAnywhereScrollBehavior extends MaterialScrollBehavior {
  const _DragAnywhereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// Owns the stored state, because the theme is part of it and has to be
/// known above MaterialApp — otherwise the choice could only repaint the
/// screen that made it.
class AstutoApp extends StatefulWidget {
  const AstutoApp({super.key});

  @override
  State<AstutoApp> createState() => _AstutoAppState();
}

class _AstutoAppState extends State<AstutoApp> {
  final AppState _app = AppState();

  /// Tells the screens which full-screen route is on top, and nothing more:
  /// every screen names itself (see ScreenView).
  final ScreenObserver _screens = ScreenObserver();

  @override
  void initState() {
    super.initState();
    _app.addListener(_onChanged);
    _app.init();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _app.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astute',
      // Every language the app has strings for, and the phone's own
      // choice among them. Anything the phone asks for that is not here
      // falls back to English; anything not yet translated inside a
      // language falls back to English one string at a time.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: buildAstutoTheme(Brightness.light),
      darkTheme: buildAstutoTheme(Brightness.dark),
      themeMode: _app.themeMode,
      navigatorObservers: [_screens],
      home: AstutoRoot(app: _app),
      scrollBehavior: const _DragAnywhereScrollBehavior(),
      builder: (context, child) => _PhoneFrame(child: child),
    );
  }
}

/// Astute is a phone app served from a web page, so on anything wider than a
/// handset it sits in a centred column at handset width rather than stretching
/// a card across a desktop monitor.
class _PhoneFrame extends StatelessWidget {
  final Widget? child;
  const _PhoneFrame({required this.child});

  static const double _maxWidth = 460;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    if (width <= _maxWidth) return content;

    return ColoredBox(
      color: context.p.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ClipRect(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: context.p.line),
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the first-run flow lives. Everything before [_Stage.shell] runs once
/// per install; after that the app opens straight on the tab bar.
/// The onboarding is the intro that says what the app is, then the subject
/// run that fills the deck, and then the first day. Nothing stands between
/// the last of those and the first card: no offer, no sign-in, no
/// permission. Astute+ is offered by the card after the fifth, in Profile
/// and at the features it opens, once the reader has seen what it adds to.
enum _Stage {
  intro,
  subjects,
  genres,
  comeback,
  shell;

  /// What this stage is called in the funnel. The onboarding is the one part
  /// of the app worth watching screen by screen: it is the only place a
  /// reader can be lost before they have seen a single card.
  String get screen => switch (this) {
    _Stage.intro => 'intro',
    _Stage.subjects => 'onboarding subjects',
    _Stage.genres => 'onboarding genres',
    _Stage.comeback => 'comeback',
    _Stage.shell => 'today',
  };
}

class AstutoRoot extends StatefulWidget {
  final AppState app;
  const AstutoRoot({super.key, required this.app});

  @override
  State<AstutoRoot> createState() => _AstutoRootState();
}

class _AstutoRootState extends State<AstutoRoot> {
  AppState get _app => widget.app;

  /// One account for the whole app. It works signed out — this only decides
  /// whether the phone's work also lives somewhere it survives the phone.
  final Account _account = Account();

  /// Backing up is best done at the last moment anything is certain to run,
  /// which on a phone is the moment the app leaves the screen.
  AppLifecycleListener? _lifecycle;

  Push get _push => Push.instance;

  /// True while the question about notifications is being put: the app's
  /// own sheet, and the system's prompt behind it until it is answered.
  bool _askingForPush = false;

  /// Whether the question about notifications was put in this session — the
  /// app's own sheet, and the system's prompt where it led there: the
  /// store's rating prompt never follows it in the same one, two sheets in
  /// a row being one too many.
  bool _pushAskedThisSession = false;

  /// Whether the Today tab has a deck on its table: the five, or the card
  /// after them, which is the evening's offer. Told by the shell.
  bool _deckOnTable = true;

  /// Whether the tabs are the top of the stack, nothing pushed over them —
  /// no paywall, no screen a purchase ends on, no card, dialog or sheet.
  /// Read from the route, which says so again whenever it changes.
  bool _onTop = true;

  /// A trial started in this session, while the system's prompt was still
  /// unasked: the sheet is offered for it once the purchase's screens close.
  bool _trialAskDue = false;

  /// Whether the reader was in a trial when the app last looked, so one that
  /// starts in this session can be told from one the phone already knew.
  bool? _hadTrial;

  /// The beat between the reminder sheet's moment arriving and the sheet
  /// rising, so what the reader just did — the shelf coming up, a paywall
  /// closing — lands first.
  static const Duration _kReminderAskBeat = Duration(milliseconds: 1500);
  Timer? _reminderAskTimer;

  /// Whether a question has been put in this sitting — the reminder sheet,
  /// a system prompt, the store's rating sheet or the place sheet — and
  /// whether the place sheet was that question. A sitting ends when the app
  /// goes to the background; a system prompt only makes it inactive, so the
  /// one the reminder sheet leads to is in the same sitting as the sheet.
  /// The place sheet waits for a sitting nothing else has asked in, and
  /// nothing else asks in the sitting it did.
  bool _askedThisSitting = false;
  bool _placeAskedThisSitting = false;

  /// True while the place is being asked about: the sheet, the system's
  /// prompt behind it, and the read after.
  bool _askingForPlace = false;
  Timer? _placeAskTimer;

  /// True while an account is being offered after a finished day: the
  /// sheet, and Apple's or Google's own behind it.
  bool _askingForAccount = false;
  Timer? _accountAskTimer;

  bool _askingForReview = false;
  _Stage _stage = _Stage.intro;
  bool _stageResolved = false;

  /// A home-screen widget's tap, waiting for the tabs. The splash, the
  /// first run and the come-back screen hold it; the shell takes it the
  /// moment it is built, and lands on the card it names.
  final ValueNotifier<WidgetOpen?> _widgetOpen = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _account.watch(_app);
    _lifecycle = AppLifecycleListener(
      onPause: () {
        // The sitting, said once as it ends: how long the app was open this
        // time — the one number a daily habit is measured by — how it was
        // opened, how much was read in it and whether the phone kept up.
        // Every screen visit, card and shelf still open is said first, and
        // all of it before the flush that carries it.
        Analytics.capture('app paused', Session.instance.end());
        // The reader's profile, written once for the sitting rather than at
        // every card it changed on.
        if (_app.ready) Analytics.person(set: _app.readerFacts);
        Analytics.flushPerson();
        _account.flush();
        Trace.instance.flush();
        // The home screen is what the reader sees next, so the widgets
        // hear of everything since the last card: a card of today's shelf
        // read in Explore is not offered there again.
        if (_app.ready) _app.refreshHomeWidget();
        // The sitting is over, and the questions put in it with it.
        _askedThisSitting = false;
        _placeAskedThisSitting = false;
        _placeAskTimer?.cancel();
        _placeAskTimer = null;
        _accountAskTimer?.cancel();
        _accountAskTimer = null;
      },
      onDetach: () {
        _account.flush();
        Trace.instance.flush();
      },
      // Coming back to the foreground re-arms tomorrow's nudge with today's
      // streak in it, and quietly — no prompt ever comes from here.
      onResume: () {
        // A new sitting, and the screen in front a new visit in it; what
        // the phone may have changed while away is stamped again.
        Session.instance.begin();
        _stampDisplay();
        if (_app.ready) _app.refreshAnalytics();
        _app.refreshDailyReminder();
        _app.refreshHomeWidget();
        // A store that did not answer is asked again: the network that was
        // missing at launch is often back by now.
        unawaited(Subscription.instance.reloadOffering());
        // Where the reader lives, read again once a week for a reader who
        // allowed it, and never with a prompt.
        if (_app.ready) _app.refreshPlaceIfDue();
        // A night asleep in memory: the day turned while the app was away,
        // and it is dealt before a widget's tap looks for its card in it.
        unawaited(
          _app.turnDayIfDue().then((_) {
            if (mounted) _takeWidgetOpen();
          }),
        );
        _sayWidgets();
        // A new sitting can be the moment of the account's sheet or the
        // place's: a finished day still on the screen.
        _considerAccountAsk();
        _considerPlaceAsk();
      },
    );
    // A widget's tap: the one that started the app, and any that brings it
    // back, which the phone also says the moment it arrives.
    onWidgetOpened(_takeWidgetOpen);
    _takeWidgetOpen();
    _refreshPushToken();
    _startAccountAndStore();
    _app.addListener(_onAppStateChanged);
    if (_app.ready) _onAppStateChanged();
    // On the site, /app/?simulate=purchase opens the screen a purchase ends
    // on, to look at. Only the screen: nothing is unlocked, so the link is
    // safe to have in the open.
    if (kIsWeb && Uri.base.queryParameters['simulate'] == 'purchase') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showPurchaseSuccess(context, _app, source: 'site preview');
        }
      });
    }
  }

  /// The store and the account, side by side. The store used to wait for
  /// the account — the Firebase sign-in and the backup fold behind it — so
  /// a phone whose account was slow to come up could not buy at all. Now
  /// it starts at once, under the account the phone already has if it has
  /// one, and is told who the reader is the moment the account is there:
  /// the entitlement follows them to a new phone rather than staying here.
  Future<void> _startAccountAndStore() async {
    final Subscription store = Subscription.instance
      ..addListener(_onEntitlementChanged);
    final Future<void> storeStarted = store.start(accountId: _account.uid);
    await _account.ensureAnonymous(_app);
    if (!mounted) return;
    _identify();
    // Signed in, even anonymously, is what the counts ask of a reader.
    Tallies.instance.refresh();
    // And what a report waits for, when one was made before there was an
    // account or a signal.
    Reports.instance.flush();
    await _sayWidgets();
    await storeStarted;
    if (!mounted) return;
    await store.switchTo(_account.uid);
  }

  /// Takes the widget whose tap brought the app forward, if one did, and
  /// hands it to the tabs. Taking clears it, so whichever of launch, the
  /// return to the foreground and the phone's own word asks first has it,
  /// and the tap is followed once.
  Future<void> _takeWidgetOpen() async {
    final WidgetOpen? open = await takeWidgetOpen();
    if (open == null || !mounted) return;
    Session.instance.cameFrom('widget');
    Analytics.capture('app opened from widget', {
      'widget': open.from,
      'pill_id': open.card,
      'where': open.place,
    });
    _widgetOpen.value = open;
  }

  static const _kWidgetsSaid = 'knowit.widgetsSaid';

  /// Which widgets the reader has placed — said when the set changes, not
  /// at every launch, and carried on every event as a count.
  Future<void> _sayWidgets() async {
    final List<String> placed = await installedHomeWidgets();
    final String summary = placed.isEmpty
        ? 'none'
        : (List.of(placed)..sort()).join(',');
    Analytics.register('widgets_placed', placed.length);
    Analytics.register('widget_on_home', placed.isNotEmpty);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_kWidgetsSaid) == summary) return;
      await prefs.setString(_kWidgetsSaid, summary);
    } catch (_) {
      return;
    }
    Analytics.capture('widgets placed', {
      'count': placed.length,
      'widgets': summary,
      'kinds': {for (final w in placed) w.split('.').first}.join(','),
    });
    Analytics.person(
      set: {'widgets_placed': placed.length, 'widgets': summary},
    );
  }

  void _onEntitlementChanged() {
    final Subscription store = Subscription.instance;
    // Until the store has answered, the app should not decide the reader has
    // nothing: a launch with no network would drop them off their own plan.
    // A reviewer's code needs no store to answer: it is already on the phone.
    // The trial goes first, so a plan that turns on with a trial is heard of
    // with the trial already known — and for the same reason it waits for
    // an answer: before one, no trial means "not asked", not "none".
    if (store.ready) _app.applyTrial(store.trial);
    if (store.ready || store.reviewAccess) _app.applyEntitlement(store.isPlus);
  }

  /// A token the system reissued is one the server can no longer reach, so
  /// it is picked up again on every launch — without asking anything.
  Future<void> _refreshPushToken() async {
    final String? token = await _push.refresh();
    if (token != null && mounted) await _app.rememberPushToken(token);
  }

  /// The one prompt iOS allows, spent at the only moment it is worth
  /// something: a day is finished, so there is a streak to protect and the
  /// reader knows what they would be agreeing to — and, on a phone, once
  /// they have chosen a time on the app's own sheet (see [_offerReminder]).
  /// Where no sheet can lead to it, it is asked for as it always was; there
  /// it shows nothing and only settles that it was asked.
  Future<void> _askForPush() async {
    if (_askingForPush) return;
    _askingForPush = true;
    _pushAskedThisSession = true;
    _askedThisSitting = true;
    Analytics.capture('push permission asked');
    final String? token = await _push.ask();
    if (!mounted) return;
    Analytics.capture('push permission answered', {'granted': token != null});
    await _app.notedPushAnswer(token: token);
    _askingForPush = false;
  }

  /// Whether the app's own sheet can lead anywhere here: a phone, whose
  /// reminders can be delivered, with a system prompt behind the sheet to
  /// put. The web build has neither, and a test has no Firebase.
  bool get _canOfferReminder => remindersSupported && _push.canAsk;

  /// The app's own question about notifications: when, before the system
  /// asks whether. A time chosen is kept, and then the system's prompt is
  /// put exactly as it always was. "Not now" spends nothing, and the sheet
  /// comes back after the next day finished (AppState.shouldAskForPush).
  Future<void> _offerReminder(String reason) async {
    if (_askingForPush) return;
    _askingForPush = true;
    // The sheet is a question too, and the store's rating prompt never
    // follows one in the same session.
    _pushAskedThisSession = true;
    _askedThisSitting = true;
    _trialAskDue = false;
    Analytics.capture('push preprompt shown', {'reason': reason});
    final String? at = await showReminderAsk(context, _app);
    if (!mounted) return;
    Analytics.capture('push preprompt answered', {'choice': at ?? 'not now'});
    if (at == null) {
      await _app.notedPushDeferred();
      _askingForPush = false;
      return;
    }
    // Kept quietly: the prompt is the one below, and only that one.
    await _app.setNotifyTime(at, quietly: true);
    _askingForPush = false;
    if (mounted) await _askForPush();
  }

  /// Why the reminder sheet would rise now — 'trial' or 'day done' — or
  /// null when this is not its moment.
  ///
  /// Never over anything: whatever is pushed over the tabs, from a paywall
  /// to the screen a purchase ends on, keeps it waiting until it closes.
  /// Never over the evening's offer either, the card after the fifth, which
  /// stays on the table until it is thrown. The shelf that comes up under
  /// it is the finished day at rest — on Astute+, which deals no such card,
  /// straight after the fifth — and that is the day's moment; so is a launch
  /// that opens on a finished day. A trial just started has its own moment:
  /// the purchase's screens closed, whatever is on the table.
  String? _reminderAskReason() {
    if (_stage != _Stage.shell || !_onTop || !_canOfferReminder) return null;
    if (_app.pushAsked || !_app.notificationsOn) return null;
    // Not over the place sheet, nor in the sitting it was put in.
    if (_askingForPlace || _placeAskedThisSitting) return null;
    if (_trialAskDue) return 'trial';
    if (_app.shouldAskForPush && _app.dayClosed && !_deckOnTable) {
      return 'day done';
    }
    return null;
  }

  /// Raises the reminder sheet a beat after its moment arrives, and only if
  /// the moment is still there when the beat is over. Called whenever
  /// anything it depends on moves: the state, the table, the stack.
  void _considerReminderAsk() {
    if (!mounted || _askingForPush) return;
    if (_reminderAskReason() == null) {
      _reminderAskTimer?.cancel();
      _reminderAskTimer = null;
      return;
    }
    if (_reminderAskTimer?.isActive ?? false) return;
    _reminderAskTimer = Timer(_kReminderAskBeat, () {
      _reminderAskTimer = null;
      if (!mounted || _askingForPush) return;
      final String? reason = _reminderAskReason();
      if (reason != null) _offerReminder(reason);
    });
  }

  /// Why the place sheet would rise now — after a finished day — or null
  /// when this is not its moment (AppState.shouldAskForPlace says whether
  /// it is due at all).
  ///
  /// The same moment as the reminder sheet's — the finished day at rest,
  /// with nothing pushed over the tabs and the card after the fifth thrown —
  /// and the reminder goes first, then the account: the place sheet waits
  /// while either is due, and for a sitting in which nothing else, the
  /// system's prompts and the store's rating sheet included, has been
  /// asked. Only on a phone, where there is a place to read.
  String? _placeAskReason() {
    if (!_app.ready || _stage != _Stage.shell) return null;
    if (!_onTop || _deckOnTable) return null;
    if (_askingForPush || _askingForPlace || _askedThisSitting) return null;
    if (_askingForAccount) return null;
    if (_reminderAskReason() != null ||
        (_reminderAskTimer?.isActive ?? false)) {
      return null;
    }
    if (_accountAskReason() != null || (_accountAskTimer?.isActive ?? false)) {
      return null;
    }
    if (!_app.dayClosed || !_app.shouldAskForPlace) return null;
    if (!PlaceFinder.instance.canAsk) return null;
    return 'day done';
  }

  /// Raises the place sheet a beat after its moment arrives, as the
  /// reminder sheet rises, and only if the moment is still there then.
  void _considerPlaceAsk() {
    if (!mounted || _askingForPlace) return;
    if (_placeAskReason() == null) {
      _placeAskTimer?.cancel();
      _placeAskTimer = null;
      return;
    }
    if (_placeAskTimer?.isActive ?? false) return;
    _placeAskTimer = Timer(_kReminderAskBeat, () {
      _placeAskTimer = null;
      if (!mounted || _placeAskReason() == null) return;
      _offerPlace();
    });
  }

  Future<void> _offerPlace() async {
    if (_askingForPlace) return;
    _askingForPlace = true;
    // Asked or not, this sitting has had its chance: a phone that turned
    // out to have nothing to give is not asked again until the next one.
    _askedThisSitting = true;
    try {
      _placeAskedThisSitting = await offerPlace(context, _app);
    } finally {
      _askingForPlace = false;
    }
  }

  /// Notes a trial that starts in this session — a purchase just made, or a
  /// phone that has just heard of one — rather than one it knew at launch.
  void _noteTrialStart() {
    if (!_app.ready) return;
    final bool inTrial = _app.trial != null;
    if (_hadTrial == false && inTrial && _canOfferReminder) {
      _trialAskDue = true;
    }
    if (_app.pushAsked || !_app.notificationsOn) _trialAskDue = false;
    _hadTrial = inTrial;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Told again whenever the route stops or starts being the top of the
    // stack: a paywall pushed over the tabs, and the moment it closes.
    _onTop = ModalRoute.isCurrentOf(context) ?? true;
    _considerReminderAsk();
    _considerAccountAsk();
    _considerPlaceAsk();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    setState(() {
      // The opening stage is decided once, the first time state is ready:
      // after that the flow drives itself and must not be reset under it.
      if (_app.ready && !_stageResolved) {
        _stageResolved = true;
        if (!_app.onboarded) {
          _stage = _Stage.intro;
          Analytics.capture('onboarding started');
        } else if (_app.shouldShowComeback) {
          _stage = _Stage.comeback;
          Analytics.capture('comeback shown', {
            'days_missed': _app.missedDays,
            'streak_lost': _app.streak,
          });
        } else {
          _stage = _Stage.shell;
        }
        // Which screen this is, the stage says itself (see _stageScreen).
      }
    });
    _noteTrialStart();
    if (_stage == _Stage.shell && _app.shouldAskForPush && !_canOfferReminder) {
      _askForPush();
    }
    _considerReminderAsk();
    if (_stage == _Stage.shell &&
        _app.shouldAskForReview &&
        !_pushAskedThisSession &&
        !_placeAskedThisSitting &&
        !_askingForPlace &&
        !_askingForAccount &&
        !_trialAskDue) {
      _askForReview();
    }
    // Last, so that a rating sheet decided just now has this sitting.
    _considerAccountAsk();
    _considerPlaceAsk();
  }

  /// The store's own rating sheet, once, at the end of a seventh day in a
  /// row (AppState.shouldAskForReview). Nothing of the app's is asked first:
  /// Google forbids a question before its sheet and Apple allows only its
  /// own. A moment after the day closes, so the shelf has landed first.
  Future<void> _askForReview() async {
    if (_askingForReview) return;
    _askingForReview = true;
    _askedThisSitting = true;
    await _app.notedReviewAsked();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final InAppReview review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      Analytics.capture('rating prompt requested', {
        'streak_days': _app.liveStreak,
        'is_plus': _app.isPlus,
      });
      await review.requestReview();
    } catch (_) {
      // No store behind this build — a browser, a test: nothing to ask.
    }
  }

  @override
  void dispose() {
    _reminderAskTimer?.cancel();
    _placeAskTimer?.cancel();
    _accountAskTimer?.cancel();
    _app.removeListener(_onAppStateChanged);
    _lifecycle?.dispose();
    Subscription.instance.removeListener(_onEntitlementChanged);
    _account.dispose();
    onWidgetOpened(null);
    _widgetOpen.dispose();
    super.dispose();
  }

  /// How long the reader has been on the current stage of the first run.
  final Stopwatch _stageClock = Stopwatch()..start();

  void _go(_Stage stage) {
    final _Stage from = _stage;
    // The first run, step by step: which step was left for which, and how
    // long it held the reader. Where a funnel drops, this says how long
    // people stood there first.
    if (from != _Stage.shell && from != _Stage.comeback && from != stage) {
      Analytics.capture('onboarding step done', {
        'step': from.screen,
        'next': stage.screen,
        'ms_on_step': _stageClock.elapsedMilliseconds,
      });
    }
    _stageClock
      ..reset()
      ..start();
    setState(() => _stage = stage);
    // The sheets wait for the tabs: arriving on them, each is asked whether
    // this is its moment.
    _considerReminderAsk();
    _considerAccountAsk();
    _considerPlaceAsk();
  }

  /// A step passed over rather than answered.
  void _noteSkipped(_Stage from) {
    Analytics.capture('onboarding step skipped', {
      'step': from.screen,
      'ms_on_step': _stageClock.elapsedMilliseconds,
    });
  }

  /// Why the account sheet would rise now — after a finished day — or null
  /// when this is not its moment (AppState.shouldOfferAccount says whether
  /// it is due at all).
  ///
  /// The finished day at rest, as for the place sheet, with nothing pushed
  /// over the tabs and the card after the fifth thrown; after the reminder
  /// sheet, which goes first, and in a sitting nothing else has asked in.
  /// Only where a sign-in can run, and only for a reader not signed in.
  String? _accountAskReason() {
    if (!_app.ready || _stage != _Stage.shell) return null;
    if (!_onTop || _deckOnTable) return null;
    if (_askingForPush || _askingForPlace || _askingForAccount) return null;
    if (_askedThisSitting) return null;
    if (_reminderAskReason() != null ||
        (_reminderAskTimer?.isActive ?? false)) {
      return null;
    }
    if (!_app.dayClosed || !_app.shouldOfferAccount) return null;
    if (!_account.canSignIn || _account.signedInForReal) return null;
    return 'day done';
  }

  /// Raises the account sheet a beat after its moment arrives, as the
  /// reminder and place sheets rise, and only if the moment is still there.
  void _considerAccountAsk() {
    if (!mounted || _askingForAccount) return;
    if (_accountAskReason() == null) {
      _accountAskTimer?.cancel();
      _accountAskTimer = null;
      return;
    }
    if (_accountAskTimer?.isActive ?? false) return;
    _accountAskTimer = Timer(_kReminderAskBeat, () {
      _accountAskTimer = null;
      if (!mounted || _accountAskReason() == null) return;
      _offerAccount();
    });
  }

  /// The offer itself: once, whatever the answer.
  Future<void> _offerAccount() async {
    if (_askingForAccount) return;
    _askingForAccount = true;
    _askedThisSitting = true;
    try {
      await _app.notedAccountOffered();
      if (!mounted) return;
      final bool signedIn = await showSignInSheet(
        context,
        account: _account,
        app: _app,
        door: SignInDoor.firstDay,
      );
      if (signedIn && mounted) _say(context.l10n.signedInRecordOnAccount);
    } finally {
      _askingForAccount = false;
    }
  }

  /// Tells the funnel which account this phone is, without telling it who.
  ///
  /// The id is the Firebase uid: the same one the backup is keyed by, so a
  /// reader who restores onto a new phone is one person here rather than two.
  /// The email and the name they typed stay on the phone — see Analytics.
  void _identify({String? method}) {
    final String? uid = _account.uid;
    if (uid == null) return;
    Analytics.identify(
      uid,
      anonymous: !_account.signedInForReal,
      method: method,
    );
  }

  void _say(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _finishOnboarding() async {
    await _app.completeOnboarding();
    if (mounted) _go(_Stage.shell);
  }

  @override
  Widget build(BuildContext context) {
    if (!_app.ready) return const _Splash();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_stage),
        // Each step of the first run is a screen of its own, named for the
        // funnel, and the tabs name their own three.
        child: _stage == _Stage.shell
            ? _stageScreen()
            : ScreenView(name: _stage.screen, child: _stageScreen()),
      ),
    );
  }

  Widget _stageScreen() {
    switch (_stage) {
      case _Stage.intro:
        return IntroScreen(
          onContinue: () => _go(_Stage.subjects),
          onSignIn: (context) => showSignInSheet(
            context,
            account: _account,
            app: _app,
            door: SignInDoor.intro,
          ),
        );

      case _Stage.subjects:
        return MixScreen(
          onDone: (weights) async {
            await _app.setTopicMix(weights);
            if (mounted) _go(_Stage.genres);
          },
          // Skipping the mix skips the genres under it too, straight to the
          // first day: there is nothing to narrow in a mix nobody set.
          onSkip: () {
            _noteSkipped(_Stage.subjects);
            _finishOnboarding();
          },
        );

      // The same answer, one layer finer: which six of each subject, and
      // which three inside those. The wheel decides how much; this decides
      // what of it. And the last step of the first run: answered or passed
      // over, it opens on the first day's cards. There used to be an offer
      // of Astute+ here, the paywall with "continue free" under it — one
      // more screen, and one more tap, between a new reader and the first
      // card, for a plan they had not yet seen anything of.
      case _Stage.genres:
        return GenresScreen(
          app: _app,
          onDone: (genresOff, strandsOff) async {
            await _app.setGenresOff(genresOff, strandsOff);
            if (mounted) await _finishOnboarding();
          },
          onSkip: () {
            _noteSkipped(_Stage.genres);
            _finishOnboarding();
          },
        );

      case _Stage.comeback:
        return ComebackScreen(
          app: _app,
          onContinue: () async {
            await _app.dismissComeback();
            if (mounted) _go(_Stage.shell);
          },
        );

      case _Stage.shell:
        return AstutoShell(
          app: _app,
          account: _account,
          widgetOpen: _widgetOpen,
          onDeckOnTable: (onTable) {
            _deckOnTable = onTable;
            _considerReminderAsk();
            _considerAccountAsk();
            _considerPlaceAsk();
          },
          onSignedOut: () {
            // Back at the first screen, as a stranger: AppState.signOut has
            // already told the funnel to forget who this was, and the intro
            // says itself.
            setState(() {
              _stageResolved = true;
              _stage = _Stage.intro;
            });
          },
        );
    }
  }
}

/// The opening frame: the wordmark on paper, so the app never shows a bare
/// spinner while stored state loads.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.p.surface,
      body: Stack(
        children: [
          // The colour arrives before anything else does. A launch screen is
          // the one moment the app is only a promise, and a plain background
          // spends it saying nothing.
          Positioned.fill(child: AmbientBlooms(colors: kSceneBlooms.first)),
          const Positioned.fill(child: Bokeh()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Astute',
                  style: AppText.display(
                    size: 30,
                    weight: FontWeight.w700,
                    spacing: -1,
                    color: context.p.ink,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.p.ink.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AstutoShell extends StatefulWidget {
  final AppState app;
  final Account account;
  final VoidCallback onSignedOut;

  /// A home-screen widget's tap still to follow. The shell lands on the
  /// card it names and clears it.
  final ValueNotifier<WidgetOpen?>? widgetOpen;

  /// Told whenever the Today tab's table changes: a deck on it — the five,
  /// or the card after them — or the shelf.
  final ValueChanged<bool>? onDeckOnTable;

  const AstutoShell({
    super.key,
    required this.app,
    required this.account,
    required this.onSignedOut,
    this.widgetOpen,
    this.onDeckOnTable,
  });

  @override
  State<AstutoShell> createState() => _AstutoShellState();
}

class _AstutoShellState extends State<AstutoShell>
    with SingleTickerProviderStateMixin {
  /// The tab the app is on. Only ever changed once a move has settled:
  /// setting it mid-gesture would rebuild the shell — and swap the page
  /// physics — while a finger is still on the glass.
  int _tab = 0;

  /// The three tabs as pages, so a finger can slide between them.
  final PageController _pages = PageController();

  /// How lit each tab is, 0 to 1, rebuilt every frame of a move.
  ///
  /// The bar used to follow the page index, which changes once, in the
  /// middle of a move: two tabs apart that meant two 240ms animations
  /// starting one on top of the other, which is what read as a stutter.
  /// This is a number per tab instead, and nothing else on the screen
  /// rebuilds while it changes.
  final ValueNotifier<List<double>> _lit = ValueNotifier(const [1, 0, 0]);

  /// Carries the bar across a jump the page does not animate.
  late final AnimationController _jump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  int _jumpFrom = 0;
  int _jumpTo = 0;

  /// True while a card is under the finger.
  bool _cardMoving = false;

  /// True while a deck is on the Today tab — the five, or the card after
  /// them. The tabs are locked for as long as it is, because a throw and a
  /// swipe to the next tab are the same gesture and the deck must win it.
  bool _deckOnTable = true;

  /// The Explore tab keeps its state across tab changes, which is right
  /// until the finished day sends the reader to "today's best" and finds
  /// the tab still on last week's month filter.
  final GlobalKey<ExploreScreenState> _explore = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pages.addListener(_followPage);
    _jump.addListener(_followJump);
    // A tap that came in before the tabs existed — on the splash, through
    // the first run — is followed as soon as they do.
    widget.widgetOpen?.addListener(_followWidget);
    _followWidget();
  }

  @override
  void didUpdateWidget(covariant AstutoShell old) {
    super.didUpdateWidget(old);
    if (old.widgetOpen == widget.widgetOpen) return;
    old.widgetOpen?.removeListener(_followWidget);
    widget.widgetOpen?.addListener(_followWidget);
    _followWidget();
  }

  @override
  void dispose() {
    widget.widgetOpen?.removeListener(_followWidget);
    _pages.removeListener(_followPage);
    _pages.dispose();
    _jump.dispose();
    _lit.dispose();
    super.dispose();
  }

  /// A widget's tap is followed after the frame: the pages have to be laid
  /// out before one can be jumped to, and a card cannot be opened over a
  /// tab that is not there yet.
  void _followWidget() {
    if (widget.widgetOpen?.value == null) return;
    _afterFrame(_land);
  }

  /// Runs [then] after the next frame, and asks for that frame: a tap that
  /// comes in while the app sits still would otherwise wait for the
  /// reader's next touch to be followed.
  void _afterFrame(VoidCallback then) {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => then())
      ..ensureVisualUpdate();
  }

  /// Where a widget's tap lands: exactly on the card it showed.
  ///
  /// One of today's five still to read is the deck on Today — the five are
  /// read in order, so the deck is where it is waiting. One already read
  /// opens over Today, read back, among the cards read so far: the ones
  /// still to come stay face down where they are. A card of today's shelf
  /// opens in Explore, among the shelf it came from. Anything else — the
  /// streak, a card from a day that is over — is Today.
  void _land() {
    final ValueNotifier<WidgetOpen?>? pending = widget.widgetOpen;
    final WidgetOpen? open = pending?.value;
    if (!mounted || pending == null || open == null) return;
    if (!_pages.hasClients) {
      _afterFrame(_land);
      return;
    }
    pending.value = null;
    final AppState app = widget.app;
    final String? id = open.card;
    // Whatever was open over the tabs gives way to the card asked for.
    Navigator.of(context).popUntil((route) => route.isFirst);

    final bool shelf =
        open.place == WidgetOpen.shelf ||
        (open.place == null && id == null && open.kind == 'shelf');
    if (shelf) {
      _goTo(1, by: 'widget');
      if (id != null) _openOnShelf(id);
      return;
    }

    _goTo(0, by: 'widget');
    final int at = id == null
        ? -1
        : app.todaysDeck.indexWhere((p) => p.id == id);
    if (at < 0 || at >= app.todayIndex) return;
    final List<Pill> read = app.todaysDeck.take(app.todayIndex).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckViewerScreen(
          app: app,
          deck: read,
          title: context.l10n.tabToday,
          initialIndex: at,
          source: 'widget',
        ),
      ),
    );
  }

  /// Opens a card of today's shelf in Explore, once the tab is there.
  void _openOnShelf(String id, {int tries = 3}) {
    _afterFrame(() {
      if (!mounted) return;
      final ExploreScreenState? explore = _explore.currentState;
      if (explore != null) {
        explore.openFromWidget(id);
      } else if (tries > 0) {
        _openOnShelf(id, tries: tries - 1);
      }
    });
  }

  /// The bar follows the page while the page is moving under a finger, or
  /// animating to the tab beside it.
  void _followPage() {
    if (_jump.isAnimating || !_pages.hasClients) return;
    final double? page = _pages.page;
    if (page == null) return;
    final int lo = page.floor().clamp(0, _AstutoTabBar.tabs.length - 1);
    final int hi = page.ceil().clamp(0, _AstutoTabBar.tabs.length - 1);
    final double t = page - lo;
    _lit.value = [
      for (int i = 0; i < _AstutoTabBar.tabs.length; i++)
        i == lo && i == hi
            ? 1
            : i == lo
            ? 1 - t
            : i == hi
            ? t
            : 0,
    ];
  }

  void _followJump() {
    final double t = Curves.easeOutCubic.transform(_jump.value);
    _lit.value = [
      for (int i = 0; i < _AstutoTabBar.tabs.length; i++)
        i == _jumpFrom
            ? 1 - t
            : i == _jumpTo
            ? t
            : 0,
    ];
  }

  /// Goes to a tab from the bar, or for a widget's tap.
  ///
  /// The tab beside this one slides, because there is nothing in between to
  /// drag across. Two tabs apart, the page cuts instead: a slide would haul
  /// the middle screen over the glass on its way past, which is a screen
  /// nobody asked for. The bar carries that move on its own, and it moves
  /// from the tab you left to the tab you asked for without lighting the
  /// one between them. A widget's tap always cuts, and without the click:
  /// the app is only just on the screen, and nobody touched the bar.
  void _goTo(int tab, {String by = 'bar'}) {
    if (tab == _tab || !mounted) return;
    final bool fromBar = by == 'bar';
    if (fromBar) HapticFeedback.selectionClick();
    final int from = _tab;
    setState(() => _tab = tab);
    _noteTab(tab, by: by);
    if ((tab - from).abs() == 1 && fromBar) {
      _jump.stop();
      _pages.animateToPage(
        tab,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _jumpFrom = from;
    _jumpTo = tab;
    _jump
      ..reset()
      ..forward();
    _pages.jumpToPage(tab);
  }

  /// A move is over. This is the only place the tab is written down, so a
  /// drag that crosses into Today is not cut short by the page locking
  /// under the finger that is still dragging it.
  bool _settle(ScrollNotification note) {
    if (note is! ScrollEndNotification || !_pages.hasClients) return false;
    final int page = (_pages.page ?? _tab.toDouble()).round();
    if (page != _tab) {
      setState(() => _tab = page);
      _noteTab(page, by: 'swipe');
    }
    return false;
  }

  /// The three tabs, by the names their screens go by.
  static const List<String> _tabNames = ['today', 'explore', 'profile'];

  /// Says which of the three the reader is now on, and how they got there.
  ///
  /// The tabs are one route, so the navigator cannot tell them apart:
  /// pushing a PostHog route observer at this app would report "/" three
  /// times and call it a session. Each tab is a ScreenView instead, shown
  /// only while it is the one in front, and says `$screen` itself when the
  /// reader arrives; this says the arrival.
  void _noteTab(int tab, {required String by}) {
    if (tab < 0 || tab >= _tabNames.length) return;
    Analytics.capture('tab opened', {'tab': _tabNames[tab], 'by': by});
    // Explore's top list, read again on the way in when it is ten minutes
    // old; the call says so itself when it is not.
    if (_tabNames[tab] == 'explore') {
      Tallies.instance.refresh();
      Served.instance.explore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(
        app: widget.app,
        onCardMotion: (moving) {
          if (moving != _cardMoving) setState(() => _cardMoving = moving);
        },
        onDeckOnTable: (onTable) {
          if (onTable != _deckOnTable) setState(() => _deckOnTable = onTable);
          widget.onDeckOnTable?.call(onTable);
        },
      ),
      ExploreScreen(key: _explore, app: widget.app),
      ProfileScreen(
        app: widget.app,
        account: widget.account,
        onSignedOut: widget.onSignedOut,
      ),
    ];
    // Each tab is a screen of its own, in front only while it is the tab
    // the reader is on: the one beside it is built before it is reached,
    // and neither it nor what is on it has been seen.
    final List<Widget> tabs = [
      for (int i = 0; i < screens.length; i++)
        ScreenView(name: _tabNames[i], showing: _tab == i, child: screens[i]),
    ];

    // The status bar follows the one palette, like everything else.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.p.isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        // Still, and black. The drifting light belongs to the onboarding,
        // which is a pitch and can afford atmosphere; this is the thing
        // itself, and a tool reads as well made when it holds still. The
        // cards are the only colour, which is the whole idea.
        backgroundColor: context.p.surface,
        // The body runs the whole height, under the tab bar, and each
        // screen puts the bar's height back as padding — so nothing moves,
        // and a card thrown downward is not sliced off at the top of a bar
        // that has already faded out of its way. A card is the thing on
        // this screen: nothing should be able to cover it.
        extendBody: true,
        body: SafeArea(
          bottom: false,
          // A browser has no status bar to sit under, so the page would
          // otherwise start hard against the top edge. On a phone the real
          // inset is larger and this does nothing.
          minimum: const EdgeInsets.only(top: 12),
          // The tabs slide under the finger, the way they do in every app
          // with three of them side by side, and the bar is the other way
          // to the same place.
          //
          // Except while the day is running. Today is then a screen with
          // one thing on it, and every sideways drag belongs to the card
          // being thrown — a page that slid instead, depending on where the
          // finger landed, was the worst of both. The five are a screen you
          // finish, not one you slide off. The bar still goes anywhere; it
          // is the sliding that stops.
          //
          // No glow at the ends: there is nothing past the last tab, and
          // the Android indicator would say so in a colour of its own.
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(overscroll: false),
            child: NotificationListener<ScrollNotification>(
              onNotification: _settle,
              child: PageView(
                controller: _pages,
                physics: _tab == 0 && _deckOnTable
                    ? const NeverScrollableScrollPhysics()
                    : null,
                // The next tab is built before it is reached, so the first
                // swipe does not pay for a screen being laid out
                // mid-gesture.
                allowImplicitScrolling: true,
                children: [
                  // Clipped to its own page. A screen is free to paint past
                  // its edges — the shelf lets a card's glow bleed, a card
                  // being thrown goes under the tab bar — and without this
                  // the overflow lands on the tab beside it and rides there
                  // until the next repaint.
                  //
                  // The padding is the height the tab bar would have taken
                  // if it still reserved room, read back from the media
                  // query the Scaffold hands a body it has extended. The
                  // page is taller than the screen it draws; the screens
                  // are exactly where they were.
                  for (final screen in tabs)
                    ClipRect(
                      child: _KeepAlive(
                        child: Builder(
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.paddingOf(context).bottom,
                            ),
                            child: screen,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // The bar steps aside while a card is being thrown. Two rows of
        // controls along the bottom edge was one too many, and a card thrown
        // downward should not be thrown at a row of buttons.
        bottomNavigationBar: _AstutoTabBar(
          hidden: _cardMoving,
          lit: _lit,
          onChanged: _goTo,
        ),
      ),
    );
  }
}

/// Keeps a tab alive while another is on screen.
///
/// The tabs used to sit in an IndexedStack, which builds all three and
/// keeps them. A page view lets go of a page once it has slid out of
/// reach, and a tab that forgets its search, its range or how far down it
/// was scrolled every time the reader looks away is a worse tab than the
/// one it replaced.
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// The tab bar, floating.
///
/// It used to be a full-width slab pinned to the bottom edge with a hairline
/// over it, and two rows of content — icon above label — which made it the
/// thickest thing on the screen after the card. A detached pill reads as
/// something laid on top of the app rather than part of its frame, and
/// putting the label beside the icon rather than under it takes a row out.
///
/// The Scaffold still reserves the height rather than letting content run
/// underneath: a bar that floats over a scrolling list has to be paid for in
/// bottom padding on every screen, and getting that wrong hides the last row
/// of something.
class _AstutoTabBar extends StatelessWidget {
  /// How lit each tab is, 0 to 1. A number rather than a selected index, so
  /// the bar can follow a finger between two tabs and cross straight from
  /// one end to the other without the middle one lighting up on the way.
  final ValueListenable<List<double>> lit;
  final ValueChanged<int> onChanged;
  final bool hidden;
  const _AstutoTabBar({
    required this.lit,
    required this.onChanged,
    this.hidden = false,
  });

  /// Icons here; the labels come from the strings, by tab.
  static const tabs = [
    (icon: Icons.wb_sunny_rounded, label: 'Today'),
    // A compass, not a bookmark and not a lens: the middle tab stopped being
    // the reader's own shelf and became the one place with cards nobody
    // dealt them. Saved moved into the profile, where a list of your own
    // things belongs, and the tab is named for the shelf rather than for
    // the search field at the top of it.
    //
    // Drawn in outline, like the lens it replaced. Filled, it is a solid
    // disc — the heaviest thing on the bar by some way, and enough on its
    // own to make a bar whose measurements never changed look fatter.
    (icon: Icons.explore_outlined, label: 'Explore'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    // Faded and lifted away rather than removed: taking it out of the tree
    // would change the page's height mid-gesture and shove the card.
    return AnimatedSlide(
      offset: hidden ? const Offset(0, 0.6) : Offset.zero,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: hidden ? 0 : 1,
        duration: const Duration(milliseconds: 180),
        child: IgnorePointer(ignoring: hidden, child: _bar(context)),
      ),
    );
  }

  Widget _bar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        4,
        18,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: context.p.surfaceRaised,
          // A little less round than a pill: 26 on the bar and 16 on the lit
          // tab, the pair chosen on the tab-bar sheet (107b). Only the
          // corners changed; every size, weight and icon is as it was.
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: context.p.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.p.isDark ? 0.5 : 0.1,
              ),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // Only the row of tabs is rebuilt as a move runs. The bar itself —
        // its ground, its ring, its shadow — is built once and held.
        child: ValueListenableBuilder<List<double>>(
          valueListenable: lit,
          builder: (context, lit, _) => Row(
            children: List.generate(tabs.length, (i) {
              final double on = lit[i].clamp(0.0, 1.0);
              final tab = tabs[i];
              final String label = switch (i) {
                0 => context.l10n.tabToday,
                1 => context.l10n.tabExplore,
                _ => context.l10n.tabProfile,
              };
              final Color tint = Color.lerp(
                context.p.inkFaint,
                context.p.onInverse,
                on,
              )!;

              // The lit tab is the one with a word in it, so it is the
              // one that gets the room: three equal thirds fit "Today" and
              // not "Aujourd'hui". The extra is taken back as the light
              // moves on, so the bar rebalances with it.
              return Expanded(
                flex: 100 + (60 * on).round(),
                child: Semantics(
                  key: ValueKey('tab-${tab.label}'),
                  button: true,
                  selected: on > 0.5,
                  label: tab.label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 + 4 * on,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.p.inverse.withValues(alpha: on),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 19, color: tint),
                            // The label belongs to the tab you are on, and
                            // unfurls as you arrive rather than appearing
                            // once you have. Three of them side by side is
                            // a legend nobody reads.
                            //
                            // It has to be able to take less than it asks
                            // for: a third of the bar is not much, and it
                            // is narrower still while the pill grows.
                            Flexible(
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: on,
                                  // Width only. Left to size itself, an
                                  // Align takes all the height it is
                                  // offered, which stretched the pill from
                                  // the height of its own contents to the
                                  // height of the whole bar — a pill with
                                  // its ends against both edges, which is
                                  // what a bar looks like when it has got
                                  // fat without a single number changing.
                                  heightFactor: 1,
                                  // The fade is in the colour rather than
                                  // in an Opacity: three of those is three
                                  // saved layers on every frame of a move,
                                  // for text that is only ever one colour.
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: tint.withValues(alpha: on),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
