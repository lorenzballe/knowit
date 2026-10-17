// The foot of Profile: the reader's two shelves as hands of their own cards,
// then the rows in raised boxes — what each one says, where each one goes,
// what each one measures, and that all of it holds at twice the text on the
// smallest phone.
//
//   flutter test test/profile_menu_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/models/place.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/how_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/account.dart';
import 'package:astuto/sync/board.dart';
import 'package:astuto/sync/place_finder.dart';
import 'package:astuto/sync/subscription.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/profile_menu.dart';
import 'package:astuto/widgets/subject_icon.dart';
import 'package:astuto/widgets/ui.dart';

/// The faces the app ships, so a row is measured in the text a reader sees.
Future<void> _loadRealFonts() async {
  const faces = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
  };
  for (final face in faces.entries) {
    final loader = FontLoader(face.key);
    final bytes = await File(face.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// What the app said to measurement, kept, so a test can read it back.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  Iterable<Map<String, Object>> of(String event) =>
      events.where((e) => e.$1 == event).map((e) => e.$2);

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

/// The store, with its screen for managing a plan counted, not opened.
class _Store extends Subscription {
  _Store() : super(keyOverride: '');

  int managed = 0;

  @override
  Future<void> presentCustomerCenter() async => managed++;
}

/// A phone that can be asked where it is, and has not been yet.
class _Phone implements PlaceFinder {
  @override
  bool get canAsk => true;

  @override
  Future<LocationAccess> access() async => LocationAccess.notAsked;

  @override
  Future<LocationAccess> ask() async => LocationAccess.denied;

  @override
  Future<bool?> precise() async => null;

  @override
  Future<Place?> find() async => null;

  @override
  Future<bool> openSettings() async => false;
}

/// A reader signed in for real, which FirebaseAuth lets no test be any other
/// way.
class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => _User();
}

class _User extends Fake implements User {
  @override
  bool get isAnonymous => false;

  @override
  String get uid => 'me';

  @override
  String? get email => null;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _ago(int days) => dateKey(DateTime.now().subtract(Duration(days: days)));

final Place _modena = Place.fromPhone(
  isoCountry: 'IT',
  adminArea: 'Emilia-Romagna',
  locality: 'Modena',
  lat: 44.6471,
  lon: 10.9252,
  at: DateTime.utc(2026, 10, 1, 9),
);

/// Cards of six different subjects, so a hand's colours can be told apart.
final List<Pill> _cards = () {
  final seen = <String>{};
  return [
    for (final Pill p in PillBank.cards)
      if (p.topic != 'Thinking' && seen.add(p.topic)) p,
  ].take(6).toList();
}();

Future<AppState> _app(
  WidgetTester tester, {
  bool plus = false,
  List<Pill> saved = const [],
  List<Pill> liked = const [],
  List<String> days = const [],
  Place? place,
}) async {
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.savedIds': [for (final p in saved) p.id],
    'knowit.likedIds': [for (final p in liked) p.id],
    'knowit.completedDates': days,
    if (place != null) 'knowit.place': jsonEncode(place.toJson()),
  });
  final AppState app = AppState();
  await app.init();
  await tester.pump();
  return app;
}

Account _account({bool signedIn = false}) => Account(
  uidOverride: 'me',
  authOverride: signedIn ? _Auth() : null,
  boardsOverride: MemoryBoardStore(),
);

Widget _host(
  AppState app, {
  Account? account,
  Locale locale = const Locale('en'),
}) {
  final Account who = account ?? _account();
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAstutoTheme(Brightness.dark),
    home: Scaffold(
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) =>
            ProfileScreen(app: app, account: who, onSignedOut: () {}),
      ),
    ),
  );
}

final Finder _list = find
    .descendant(
      of: find.byType(ProfileScreen),
      matching: find.byType(Scrollable),
    )
    .first;

/// The row with [key], brought on screen.
Future<Finder> _row(WidgetTester tester, String key) async {
  final Finder row = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(row, 200, scrollable: _list);
  await _settle(tester);
  return row;
}

Finder _in(Finder row, Finder what) => find.descendant(of: row, matching: what);

/// Back from whatever a row opened.
Future<void> _back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await _settle(tester);
}

void main() {
  setUpAll(_loadRealFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    // A phone tall enough that most of the profile is laid out at once.
    view.physicalSize = const Size(402, 1800) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    Analytics.useForTest(null);
    PlaceFinder.useForTest(null);
    Subscription.useForTest(Subscription());
  });

  group('Your cards', () {
    testWidgets('Saved and Liked say how many, and hold their newest cards '
        'fanned, the newest on top with its mark', (tester) async {
      final AppState app = await _app(
        tester,
        saved: _cards.take(5).toList(),
        liked: [_cards[5]],
      );
      await tester.pumpWidget(_host(app));
      await _settle(tester);

      final Finder saved = await _row(tester, 'profile-saved');
      expect(_in(saved, find.text('Saved')), findsOneWidget);
      expect(_in(saved, find.text('5 cards')), findsOneWidget);
      // The four newest — the shelf keeps the newest first — and not the
      // fifth.
      for (final Pill p in _cards.take(4)) {
        expect(_in(saved, find.byKey(ValueKey('fan-card-${p.id}'))), findsOne);
      }
      expect(find.byKey(ValueKey('fan-card-${_cards[4].id}')), findsNothing);
      // The newest in its own colour, with its subject's mark, painted last,
      // so on top; the ones behind it carry no mark.
      final Finder newest = find.byKey(ValueKey('fan-card-${_cards[0].id}'));
      final Container face = tester.widget<Container>(newest);
      expect((face.decoration! as BoxDecoration).color, _cards[0].color);
      expect(_in(newest, find.byType(SubjectIcon)), findsOneWidget);
      final SubjectIcon mark = tester.widget(
        _in(newest, find.byType(SubjectIcon)),
      );
      expect(mark.subject, _cards[0].topic);
      for (final Pill p in _cards.skip(1).take(3)) {
        expect(
          _in(
            find.byKey(ValueKey('fan-card-${p.id}')),
            find.byType(SubjectIcon),
          ),
          findsNothing,
        );
      }
      final Stack hand = tester.widget<Stack>(
        find.ancestor(of: newest, matching: find.byType(Stack)).first,
      );
      expect(_in(find.byWidget(hand.children.last), newest), findsOneWidget);

      final Finder liked = await _row(tester, 'profile-liked');
      expect(_in(liked, find.text('Liked')), findsOneWidget);
      expect(_in(liked, find.text('1 card')), findsOneWidget);
      expect(
        _in(liked, find.byKey(ValueKey('fan-card-${_cards[5].id}'))),
        findsOneWidget,
      );
    });

    testWidgets('an empty shelf still looks meant: one faint outline where '
        'the hand will be, and "Nothing yet"', (tester) async {
      final AppState app = await _app(tester);
      await tester.pumpWidget(_host(app));
      await _settle(tester);

      for (final String key in ['profile-saved', 'profile-liked']) {
        final Finder row = await _row(tester, key);
        expect(_in(row, find.text('Nothing yet')), findsOneWidget, reason: key);
        expect(_in(row, find.byKey(const ValueKey('fan-empty'))), findsOne);
        expect(_in(row, find.byType(SubjectIcon)), findsNothing, reason: key);
        expect(
          _in(row, find.textContaining('card')),
          findsNothing,
          reason: key,
        );
      }
    });
  });

  group('The rows say what is behind them', () {
    testWidgets('the archive says the free plan\'s week, and on Astute+ the '
        'days it keeps; the plan is named', (tester) async {
      // The words say seven because the free archive shows seven.
      expect(kFreeArchiveDays, 7);
      final List<String> days = [_ago(1), _ago(2), _ago(9)];

      final AppState free = await _app(tester, days: days);
      await tester.pumpWidget(_host(free));
      await _settle(tester);
      Finder archive = await _row(tester, 'profile-archive');
      expect(_in(archive, find.text('Last 7 days')), findsOneWidget);
      Finder plan = await _row(tester, 'profile-plan');
      expect(_in(plan, find.text('Free plan')), findsOneWidget);

      // A day written down twice is still one day.
      final AppState plus = await _app(
        tester,
        plus: true,
        days: [...days, _ago(2)],
      );
      await tester.pumpWidget(_host(plus));
      await _settle(tester);
      archive = await _row(tester, 'profile-archive');
      expect(_in(archive, find.text('3 days')), findsOneWidget);
      expect(_in(archive, find.text('Last 7 days')), findsNothing);
      plan = await _row(tester, 'profile-plan');
      expect(_in(plan, find.text('Astute+')), findsOneWidget);

      // Astute+ before a first day is finished: no "0 days".
      final AppState fresh = await _app(tester, plus: true);
      await tester.pumpWidget(_host(fresh));
      await _settle(tester);
      archive = await _row(tester, 'profile-archive');
      expect(_in(archive, find.textContaining('day')), findsNothing);
      expect(_in(archive, find.text('Archive')), findsOneWidget);
    });

    testWidgets('where you live: the city, or Off; the sheets behind the '
        'row say only the city is kept, and the row no longer does', (
      tester,
    ) async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      PlaceFinder.useForTest(_Phone());
      const String promise =
          'Only your city is kept, never your exact position.';

      final AppState off = await _app(tester);
      await tester.pumpWidget(_host(off));
      await _settle(tester);
      Finder row = await _row(tester, 'place-row');
      expect(_in(row, find.text('Where you live')), findsOneWidget);
      expect(_in(row, find.text('Off')), findsOneWidget);
      expect(find.text(promise), findsNothing);
      await tester.tap(row);
      await _settle(tester);
      expect(find.byKey(const ValueKey('place-ask')), findsOneWidget);
      expect(
        _in(find.byKey(const ValueKey('place-ask')), find.text(promise)),
        findsOneWidget,
      );
      expect(said.of('place asked'), [
        {'from': 'profile', 'nth': 1},
      ]);
      await tester.tap(find.byKey(const ValueKey('place-not-now')));
      await _settle(tester);

      final AppState kept = await _app(tester, place: _modena);
      await tester.pumpWidget(_host(kept));
      await _settle(tester);
      row = await _row(tester, 'place-row');
      expect(_in(row, find.text('Modena')), findsOneWidget);
      expect(find.text(promise), findsNothing);
      await tester.tap(row);
      await _settle(tester);
      expect(
        _in(find.byKey(const ValueKey('place-options')), find.text(promise)),
        findsOneWidget,
      );
    });
  });

  group('Every row opens what it opened before', () {
    testWidgets('the shelves, the archive, the plans, how cards are written, '
        'and deleting, asked first', (tester) async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      final AppState app = await _app(
        tester,
        saved: [_cards[0]],
        liked: [_cards[1]],
      );
      await tester.pumpWidget(_host(app));
      await _settle(tester);

      await tester.tap(await _row(tester, 'profile-saved'));
      await _settle(tester);
      expect(
        tester.widget<SavedScreen>(find.byType(SavedScreen)).shelf,
        Shelf.saved,
      );
      await _back(tester);

      await tester.tap(await _row(tester, 'profile-liked'));
      await _settle(tester);
      expect(
        tester.widget<SavedScreen>(find.byType(SavedScreen)).shelf,
        Shelf.liked,
      );
      await _back(tester);

      await tester.tap(await _row(tester, 'profile-archive'));
      await _settle(tester);
      expect(find.byType(ArchiveScreen), findsOneWidget);
      await _back(tester);

      // On the free plan, the plans — said as before.
      await tester.tap(await _row(tester, 'profile-plan'));
      await _settle(tester);
      expect(
        tester.widget<PaywallScreen>(find.byType(PaywallScreen)).source,
        'manage plan',
      );
      expect(said.of('manage subscription opened'), [
        {'is_plus': false},
      ]);
      await _back(tester);

      await tester.tap(await _row(tester, 'profile-how'));
      await _settle(tester);
      expect(find.byType(HowScreen), findsOneWidget);
      await _back(tester);

      await tester.tap(await _row(tester, 'profile-delete'));
      await _settle(tester);
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(said.of('account deletion asked'), [
        {'signed_in': false, 'is_plus': false},
      ]);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(said.of('account deletion cancelled'), hasLength(1));
    });

    testWidgets('on Astute+, Manage subscription is the store\'s own screen', (
      tester,
    ) async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      final _Store store = _Store();
      Subscription.useForTest(store);
      final AppState app = await _app(tester, plus: true);
      await tester.pumpWidget(_host(app));
      await _settle(tester);

      await tester.tap(await _row(tester, 'profile-plan'));
      await _settle(tester);
      expect(store.managed, 1);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(said.of('manage subscription opened'), [
        {'is_plus': true},
      ]);
    });

    testWidgets('signed out, Apple and Google, through the same sign-in', (
      tester,
    ) async {
      final AppState app = await _app(tester);
      await tester.pumpWidget(_host(app));
      await _settle(tester);

      expect(find.byKey(const ValueKey('profile-sign-out')), findsNothing);
      final Finder apple = await _row(tester, 'profile-apple');
      expect(_in(apple, find.text('Sign in with Apple')), findsOneWidget);
      final Finder google = await _row(tester, 'profile-google');
      expect(_in(google, find.text('Sign in with Google')), findsOneWidget);
      // No Firebase under a test: the sign-in says so, as it always has.
      await tester.tap(apple);
      await _settle(tester);
      expect(
        find.text('Signing in is not available on this build.'),
        findsOneWidget,
      );
    });

    testWidgets('signed in, Sign out in their place, and asked first', (
      tester,
    ) async {
      final AppState app = await _app(tester);
      await tester.pumpWidget(_host(app, account: _account(signedIn: true)));
      await _settle(tester);

      expect(find.byKey(const ValueKey('profile-apple')), findsNothing);
      expect(find.byKey(const ValueKey('profile-google')), findsNothing);
      await tester.tap(await _row(tester, 'profile-sign-out'));
      await _settle(tester);
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(find.text('Sign out?'), findsNothing);
    });

    testWidgets('the usage row is its switch, the whole of it, and says what '
        'it measures under it', (tester) async {
      final _Said said = _Said();
      Analytics.useForTest(said);
      final AppState app = await _app(tester);
      await tester.pumpWidget(_host(app));
      await _settle(tester);

      final Finder row = await _row(tester, 'profile-usage');
      expect(
        find.textContaining('How the app is used — what gets read'),
        findsOneWidget,
      );
      // The label turns it off …
      await tester.tap(_in(row, find.text('Usage data')));
      await _settle(tester);
      expect(Analytics.collecting, isFalse);
      expect(find.text('Nothing more is measured.'), findsOneWidget);
      // … and the switch itself back on, once each.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is NudgeSwitch && w.label == 'Usage data',
        ),
      );
      await _settle(tester);
      expect(Analytics.collecting, isTrue);
      expect(said.of('usage sharing switched'), [
        {'on': false},
        {'on': true},
      ]);
    });
  });

  testWidgets('every row is one button with its label and its value, and a '
      'finger high', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final AppState app = await _app(
      tester,
      saved: _cards.take(3).toList(),
      place: _modena,
    );
    await tester.pumpWidget(_host(app));
    await _settle(tester);

    const List<(String, String, String?)> rows = [
      ('profile-saved', 'Saved', '3 cards'),
      ('profile-liked', 'Liked', 'Nothing yet'),
      ('profile-archive', 'Archive', 'Last 7 days'),
      ('place-row', 'Where you live', 'Modena'),
      ('profile-plan', 'Manage subscription', 'Free plan'),
      ('profile-apple', 'Sign in with Apple', null),
      ('profile-google', 'Sign in with Google', null),
      ('profile-how', 'How cards are written', null),
      ('profile-delete', 'Delete account', null),
    ];
    for (final (String key, String label, String? value) in rows) {
      final Finder row = await _row(tester, key);
      expect(
        tester.getSemantics(row),
        isSemantics(
          label: label,
          value: value,
          isButton: true,
          hasTapAction: true,
        ),
        reason: key,
      );
      expect(tester.getSize(row).height, greaterThanOrEqualTo(44), reason: key);
    }
    final Finder usage = await _row(tester, 'profile-usage');
    expect(
      tester.getSemantics(usage),
      isSemantics(
        label: 'Usage data',
        hasToggledState: true,
        isToggled: true,
        isButton: false,
        hasTapAction: true,
      ),
    );
    expect(tester.getSize(usage).height, greaterThanOrEqualTo(44));
    // The headings are headings.
    for (final String heading in ['YOUR CARDS', 'ACCOUNT', 'ABOUT']) {
      await tester.scrollUntilVisible(
        find.text(heading),
        200,
        scrollable: _list,
      );
      expect(
        tester.getSemantics(find.text(heading)),
        isSemantics(isHeader: true),
        reason: heading,
      );
    }
    semantics.dispose();
  });

  testWidgets('at twice the text on a 375×667 phone, in every language: '
      'values under their labels, a long title with its hand under it, and '
      'nothing cut or overflowing', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // What a paragraph in the foot of the profile did not get out.
    final Finder foot = find.byWidgetPredicate(
      (w) =>
          w is ShelfRow ||
          w is ProfileRow ||
          w is ProfileHeader ||
          w is ProfileRowNote,
    );
    List<String> cut() {
      final out = <String>[];
      for (final Element e
          in find
              .descendant(of: foot, matching: find.byType(RichText))
              .evaluate()) {
        final RenderObject? ro = e.renderObject;
        if (ro is! RenderParagraph || !ro.attached || !ro.hasSize) continue;
        final TextPainter painter = TextPainter(
          text: ro.text,
          textDirection: ro.textDirection,
          textScaler: ro.textScaler,
          textAlign: ro.textAlign,
          maxLines: ro.maxLines,
        )..layout(maxWidth: ro.softWrap ? ro.size.width : double.infinity);
        if (ro.didExceedMaxLines ||
            painter.height > ro.size.height + 0.5 ||
            (!ro.softWrap && painter.width > ro.size.width + 0.5)) {
          out.add(ro.text.toPlainText());
        }
        painter.dispose();
      }
      return out;
    }

    // An overflow in the foot of the profile, named by the widgets that made
    // it, while they are still there to be named. The rest of the profile
    // is not this test's: the offer card at its top and the tab bar have
    // limits of their own at this size.
    const List<String> ours = [
      'ShelfRow',
      'CardFan',
      'ProfileRow',
      'ProfileBox',
      'ProfileHeader',
    ];
    final findings = <String>[];
    Locale? current;
    final before = FlutterError.onError;
    FlutterError.onError = (details) {
      final List<String> chains = [
        for (final DiagnosticsNode node
            in details.informationCollector?.call() ??
                const <DiagnosticsNode>[])
          if (node.value case final RenderObject ro
              when ro.debugCreator is DebugCreator)
            (ro.debugCreator! as DebugCreator).element.debugGetCreatorChain(24),
      ];
      if (chains.any((c) => ours.any(c.contains))) {
        findings.add(
          '[$current] ${details.exceptionAsString().split('\n').first} '
          '${chains.join(' | ')}',
        );
      }
    };
    try {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        current = locale;
        final AppState app = await _app(
          tester,
          saved: _cards.take(4).toList(),
          liked: _cards.skip(2).take(4).toList(),
          days: [_ago(1), _ago(2)],
          place: _modena,
        );
        await tester.pumpWidget(_host(app, locale: locale));
        await _settle(tester);
        final AppLocalizations l = lookupAppLocalizations(locale);
        for (var step = 0; step < 14; step++) {
          findings.addAll(cut().map((s) => '[$locale] cut: "$s"'));
          await tester.drag(_list, const Offset(0, -300));
          await _settle(tester);
        }
        // Back to the top, to look for the rows from there.
        tester.state<ScrollableState>(_list).position.jumpTo(0);
        await _settle(tester);

        if (locale.languageCode == 'en') {
          // "Where you live" and "Modena" do not share a line at this
          // size: the city goes under the words.
          final Finder row = await _row(tester, 'place-row');
          expect(
            tester.getTopLeft(_in(row, find.text('Modena'))).dy,
            greaterThanOrEqualTo(
              tester.getBottomLeft(_in(row, find.text('Where you live'))).dy -
                  1,
            ),
          );
        }
        if (locale.languageCode == 'it') {
          // "Piaciute" takes the width the hand needs: the hand goes under.
          final Finder row = await _row(tester, 'profile-liked');
          final Finder card = _in(
            row,
            find.byKey(ValueKey('fan-card-${_cards[2].id}')),
          );
          expect(
            tester.getTopLeft(card).dy,
            greaterThan(tester.getBottomLeft(_in(row, find.text(l.liked))).dy),
          );
        }
      }
    } finally {
      FlutterError.onError = before;
    }
    expect(findings, isEmpty, reason: findings.join('\n'));
  });
}
