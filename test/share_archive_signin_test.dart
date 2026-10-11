import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/intro_screen.dart';
import 'package:astuto/screens/mix_screen.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/saved_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/utils/share_link.dart';
import 'package:astuto/utils/share_text.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/record_share_sheet.dart';
import 'package:astuto/widgets/share_day.dart';
import 'package:astuto/widgets/share_sheet.dart';

/// Pumps a second of frames. The app's ambient loops never stop, so a test
/// waits for a while rather than for stillness.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// An install past the first run, on the free plan, that finished [days].
Map<String, Object> _free({List<String> days = const []}) => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  'knowit.completedDates': days,
};

String _daysAgo(int n) => dateKey(DateTime.now().subtract(Duration(days: n)));

/// What the app said, kept, so a test can read its measurement back.
class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  List<Map<String, Object>> of(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

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

_Said _listen() {
  final said = _Said();
  Analytics.useForTest(said);
  addTearDown(() => Analytics.useForTest(null));
  return said;
}

/// Everything the app puts on the clipboard, in order.
List<String> _clipboard(WidgetTester tester) {
  final copied = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copied;
}

/// A screen of its own, in English, as the app dresses it.
Widget _host(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildAstutoTheme(Brightness.dark),
  home: home,
);

/// Throws the top card off the deck, from the question at its top: on a
/// card with a scene, the middle belongs to the scene.
Future<void> _swipeCardAway(WidgetTester tester) async {
  final deck = tester.getRect(find.byType(PillCardStack));
  await tester.flingFrom(
    Offset(deck.center.dx, deck.top + 90),
    const Offset(-320, 0),
    900,
  );
  await _settle(tester);
}

/// Reads the day through: the five, and on the free plan the card after
/// them that offers the rest, thrown like the rest.
Future<void> _finishDay(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    if (find.byType(PillCardStack).evaluate().isEmpty) break;
    await _swipeCardAway(tester);
  }
}

/// The profile's own list. The tabs sit in a page view, which is a
/// scrollable too, and comes first.
final Finder _profileList = find
    .descendant(
      of: find.byType(ProfileScreen),
      matching: find.byType(Scrollable),
    )
    .first;

/// Opens the profile, and the row named [label] on it.
Future<void> _openProfileRow(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('tab-Profile')));
  await _settle(tester);
  final Finder row = find.descendant(
    of: find.byType(ProfileScreen),
    matching: find.text(label),
  );
  await tester.scrollUntilVisible(row, 200, scrollable: _profileList);
  await _settle(tester);
  // The tab bar floats over the foot of the body, so a row can be on screen
  // and under it: bring it up past the bar before pressing it.
  final double floor =
      tester.view.physicalSize.height / tester.view.devicePixelRatio - 110;
  final double bottom = tester.getBottomLeft(row).dy;
  if (bottom > floor) {
    await tester.drag(_profileList, Offset(0, floor - bottom - 20));
    await _settle(tester);
  }
  await tester.tap(row);
  await _settle(tester);
}

/// What a reader on the free plan meets, each true to what is behind it:
/// the archive's week, the day sent from where it was finished, links that
/// say which share they came from, an intro that offers no sign-in it
/// cannot do, and a wrong answer not told what everybody else did when
/// nothing counted it.
void main() {
  // A real handset rather than the 800 by 600 default.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  group('The archive opens on the free plan, a week deep', () {
    /// Yesterday is inside the week; ten days back is behind the lock.
    Map<String, Object> aWeekAndMore() =>
        _free(days: [_daysAgo(10), _daysAgo(1)]);

    /// The archive as a reader on the free plan finds it: no gate on the
    /// way in, the week, and after it the row with the lock — which is the
    /// one way from here to the paywall.
    Future<void> seeTheWeek(WidgetTester tester, _Said said) async {
      expect(find.byType(ArchiveScreen), findsOneWidget);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(said.of('plus gate reached'), isEmpty);

      expect(find.text('The archive'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      // The day ten days back is not shown as a day, but it is named and
      // counted, with the lock on it.
      final Finder locked = find.byKey(const ValueKey('archive-locked'));
      expect(locked, findsOneWidget);
      expect(
        find.descendant(of: locked, matching: find.text('Before this week')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: locked, matching: find.text('1 day')),
        findsOneWidget,
      );

      await tester.tap(locked);
      await _settle(tester);
      expect(
        tester.widget<PaywallScreen>(find.byType(PaywallScreen)).source,
        'archive',
      );
      expect(said.of('plus gate reached'), [
        {'source': 'archive', 'is_plus': false},
      ]);
    }

    testWidgets('from the profile', (tester) async {
      final said = _listen();
      SharedPreferences.setMockInitialValues(aWeekAndMore());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await _openProfileRow(tester, 'Archive');
      await seeTheWeek(tester, said);
    });

    testWidgets('from the saved shelf', (tester) async {
      final said = _listen();
      SharedPreferences.setMockInitialValues(aWeekAndMore());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await _openProfileRow(tester, 'Saved');
      expect(find.byType(SavedScreen), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(SavedScreen),
          matching: find.text('Archive'),
        ),
      );
      await _settle(tester);
      await seeTheWeek(tester, said);
    });

    testWidgets('newest first, however the days arrived', (tester) async {
      // After a sign-in the finished days are this phone's with the other
      // phone's added at the end, out of order.
      SharedPreferences.setMockInitialValues(
        _free(days: [_daysAgo(2), _daysAgo(9), _daysAgo(1), _daysAgo(3)]),
      );
      final app = AppState();
      await app.init();
      await tester.pumpWidget(_host(ArchiveScreen(app: app, onBack: () {})));
      await _settle(tester);

      // The archive's own way of naming a day before yesterday.
      String named(int back) {
        final weekdays = 'Mon Tue Wed Thu Fri Sat Sun'.split(' ');
        final months = 'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec'.split(
          ' ',
        );
        final d = DateTime.now().subtract(Duration(days: back));
        return '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
      }

      final List<double> tops = [
        for (final label in ['Today', 'Yesterday', named(2), named(3)])
          tester.getTopLeft(find.text(label)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      // Nine days back is outside the week: counted under the lock.
      final Finder locked = find.byKey(const ValueKey('archive-locked'));
      expect(
        find.descendant(of: locked, matching: find.text('1 day')),
        findsOneWidget,
      );
      expect(find.text(named(9)), findsNothing);
    });
  });

  group('The day is sent from where it was finished', () {
    testWidgets('a free reader finds it on the shelf, beside the journey', (
      tester,
    ) async {
      final said = _listen();
      final copied = _clipboard(tester);
      // No share sheet under a test, and the desktop stand-in never
      // returns: the day is copied instead.
      ShareDay.share = (_) async => false;
      addTearDown(() => ShareDay.share = shareText);
      SharedPreferences.setMockInitialValues(_free());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      final Finder send = find.byKey(const ValueKey('shelf-share-day'));
      expect(send, findsNothing);
      await _finishDay(tester);
      expect(find.byType(TodayDoneView), findsOneWidget);
      expect(send, findsOneWidget);
      expect(find.text('Share day'), findsOneWidget);

      // On the journey's row, not one of its own: the shelf keeps all the
      // room it had.
      final Finder journey = find.descendant(
        of: find.byType(TodayDoneView),
        matching: find.text('Your journey'),
      );
      expect(
        tester.getCenter(send).dy,
        moreOrLessEquals(tester.getCenter(journey).dy, epsilon: 0.5),
      );
      expect(
        tester.getRect(send).left,
        greaterThan(tester.getRect(journey).right),
      );

      // No gate: it sends, on the free plan, and says from where.
      await tester.tap(send);
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(copied, hasLength(1));
      expect(copied.single, startsWith('Astute #'));
      expect(copied.single, endsWith('\n${ShareRef.day.link}'));
      expect(said.of('day shared'), hasLength(1));
      expect(said.of('day shared').single['from'], 'done view');
      expect(said.of('day shared').single['as'], 'copied');
      expect(said.of('plus gate reached'), isEmpty);

      // At the last card on the shelf, the one that sells, it is still the
      // row under the shelf: nothing of it lies on the offer.
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(TodayDoneView), const Offset(-200, 0));
        await _settle(tester);
      }
      final Finder offer = find.byKey(const ValueKey('shelf-magic'));
      expect(offer, findsOneWidget);
      expect(send, findsOneWidget);
      expect(tester.getRect(offer).overlaps(tester.getRect(send)), isFalse);
    });
  });

  group('Every shared link says which share it came from', () {
    test('three refs, one site', () {
      expect(ShareRef.day.link, 'https://astutetheapp.com/?ref=share_day');
      expect(ShareRef.card.link, 'https://astutetheapp.com/?ref=share_card');
      expect(
        ShareRef.record.link,
        'https://astutetheapp.com/?ref=share_record',
      );
    });

    /// Opens a share sheet over a bare screen and copies what it would
    /// send, with the copy button at the end of its row.
    Future<String> copiedFrom(
      WidgetTester tester,
      Future<void> Function(BuildContext context) open,
    ) async {
      final copied = _clipboard(tester);
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => open(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await _settle(tester);
      expect(copied, hasLength(1));
      return copied.single;
    }

    testWidgets('a card', (tester) async {
      final Pill pill = PillBank.cards.first;
      final String text = await copiedFrom(
        tester,
        (context) => showShareSheet(context, pill),
      );
      expect(text, endsWith('— Astute · ${ShareRef.card.link}'));
    });

    testWidgets('the record', (tester) async {
      SharedPreferences.setMockInitialValues(_free());
      final app = AppState();
      await app.init();
      final String text = await copiedFrom(
        tester,
        (context) => showRecordShareSheet(context, app),
      );
      expect(text, endsWith('— Astute · ${ShareRef.record.link}'));
    });
  });

  group('The intro offers no sign-in it cannot do', () {
    testWidgets('continuing without an account goes where Skip goes', (
      tester,
    ) async {
      final said = _listen();
      var continued = 0;
      await tester.pumpWidget(
        _host(
          IntroScreen(
            onContinue: () => continued++,
            onApple: () async => false,
            onGoogle: () async => false,
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('Continue with Email'), findsNothing);
      // True of all three ways on, so it no longer says signing up.
      expect(
        find.text(
          'By continuing you agree to our Terms of Service & Privacy Policy',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue without an account'));
      await _settle(tester);
      expect(continued, 1);
      expect(said.of('intro skipped'), hasLength(1));
      expect(said.of('intro skipped').single['by'], 'no account');
      expect(said.of('intro skipped').single['at_scene'], 1);
      // Nothing was signed in to, and nothing says it was tried.
      expect(find.byType(SnackBar), findsNothing);

      // The corner goes the same way, and says it was the corner.
      await tester.tap(find.text('Skip'));
      await _settle(tester);
      expect(continued, 2);
      expect(said.of('intro skipped').last['by'], 'corner');
    });

    testWidgets('in the app it lands on the subjects', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.text('Continue without an account'));
      await _settle(tester);
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.byType(MixScreen), findsOneWidget);
      expect(find.text('19 of 19 subjects in the mix'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('A wrong pick is told what it was, not what everyone does', () {
    testWidgets('no count of readers, so no "almost everyone"', (tester) async {
      final Pill pick = PillBank.cards.firstWhere(
        (p) => p.challenge is PickOne,
      );
      final challenge = pick.challenge as PickOne;
      final int wrong = (challenge.correct + 1) % challenge.options.length;
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 354,
                height: 624,
                child: PillCard(
                  pill: pick,
                  flipped: true,
                  given: Answer('$wrong', confidence: 70),
                  onSave: () {},
                  onShare: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      expect(find.textContaining('Almost everyone'), findsNothing);
      expect(
        find.text(
          'You said ${challenge.options[wrong]} · '
          'it is ${challenge.correctOption} · you said 70% sure',
        ),
        findsOneWidget,
      );
    });
  });
}
