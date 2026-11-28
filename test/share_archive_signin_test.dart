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
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/archive_screen.dart';
import 'package:astuto/screens/deck_viewer_screen.dart';
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
    testWidgets('a free reader finds it at the end of the shelf\'s heading', (
      tester,
    ) async {
      final said = _listen();
      final copied = _clipboard(tester);
      SharedPreferences.setMockInitialValues(_free());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      final Finder send = find.byKey(const ValueKey('shelf-share-day'));
      expect(send, findsNothing);
      await _finishDay(tester);
      expect(find.byType(TodayDoneView), findsOneWidget);
      expect(send, findsOneWidget);
      expect(find.bySemanticsLabel('Share day'), findsOneWidget);

      // A mark at the end of the shelf's heading — the day's name and the
      // aside under it — on its row, not a button of its own beside the
      // journey: the journey has the row to itself and the shelf keeps its
      // room.
      final Finder heading = find.text('Day 1');
      final Finder aside = find.byKey(const ValueKey('shelf-aside'));
      final double middle = tester.getCenter(send).dy;
      expect(middle, greaterThan(tester.getRect(heading).top));
      expect(middle, lessThan(tester.getRect(aside).bottom));
      expect(
        tester.getRect(send).left,
        greaterThan(tester.getRect(heading).right),
      );
      final Finder journey = find.descendant(
        of: find.byType(TodayDoneView),
        matching: find.text('Your journey'),
      );
      expect(
        tester.getCenter(journey).dy,
        greaterThan(tester.getCenter(send).dy),
      );

      // No gate: it opens the day as a picture, on the free plan, with the
      // words that go with it a tap away, and says from where.
      await tester.tap(send);
      await _settle(tester);
      expect(find.byType(PaywallScreen), findsNothing);
      expect(find.text('Share your day'), findsOneWidget);
      expect(find.byType(DayPicture), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('share-day-copy')));
      await _settle(tester);
      expect(copied, hasLength(1));
      expect(copied.single, startsWith('Astute #'));
      expect(copied.single, endsWith('\n${ShareRef.day.link}'));
      expect(said.of('day shared'), hasLength(1));
      expect(said.of('day shared').single['from'], 'done view');
      expect(said.of('day shared').single['as'], 'copied');
      expect(said.of('plus gate reached'), isEmpty);
      Navigator.of(tester.element(find.byType(DayPicture))).pop();
      await _settle(tester);

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

    testWidgets('as a story too, the whole sheet is on the screen, with a '
        'way out beside its title', (tester) async {
      SharedPreferences.setMockInitialValues(_free());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _finishDay(tester);
      await tester.tap(find.byKey(const ValueKey('shelf-share-day')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('share-day-story')));
      await _settle(tester);

      // Taller than the screen it used to scroll where it should close,
      // with nothing left above it to tap.
      final double screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final Rect close = tester.getRect(
        find.byKey(const ValueKey('share-day-close')),
      );
      final Rect share = tester.getRect(
        find.byKey(const ValueKey('share-day-send')),
      );
      expect(close.top, greaterThan(24));
      expect(share.bottom, lessThanOrEqualTo(screen));
      expect(
        tester.getRect(find.byType(DayPicture)).bottom,
        lessThan(share.top),
      );
      // Nothing of the sheet scrolls. (The shelf behind it is the day's
      // cards, and a card in words there may scroll its own words.)
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('share-day-close')));
      await _settle(tester);
      expect(find.byType(DayPicture), findsNothing);
    });

    testWidgets('beside it, See again: the five again at full size, as they '
        'came, always from the first card, wherever the reader was; and the '
        'same from Explore', (tester) async {
      final said = _listen();
      // Explore as the document lays it: the reader's own five near its
      // top.
      Remote.adopt(
        const RemoteConfig(
          hash: 'your-five',
          schema: kRemoteSchema,
          parts: {
            'explore': {
              'sections': [
                {'id': 'your-five', 'block': 'your-five'},
              ],
            },
          },
        ),
      );
      addTearDown(Remote.reset);
      SharedPreferences.setMockInitialValues(_free());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _finishDay(tester);

      // A small pill on the day's row, just before the share's mark: the
      // owner wanted it back over the shelf.
      final Finder again = find.byKey(const ValueKey('shelf-see-again'));
      final Finder send = find.byKey(const ValueKey('shelf-share-day'));
      expect(again, findsOneWidget);
      expect(find.bySemanticsLabel('See again'), findsOneWidget);
      expect(
        find.descendant(of: again, matching: find.text('See again')),
        findsOneWidget,
      );
      expect(tester.getCenter(again).dy, closeTo(tester.getCenter(send).dy, 1));
      expect(
        tester.getRect(again).right,
        lessThanOrEqualTo(tester.getRect(send).left),
      );
      expect(
        tester.getRect(again).left,
        greaterThan(tester.getRect(find.text('Day 1')).right),
      );

      final AppState app = tester
          .widget<TodayDoneView>(find.byType(TodayDoneView))
          .app;
      // The reader has the third card at the front of the shelf.
      final Finder third = find.descendant(
        of: find.byType(TodayDoneView),
        matching: find.bySemanticsLabel('Card 3 of 5'),
      );
      await tester.tap(third);
      await _settle(tester);
      expect(tester.getSemantics(third), isSemantics(isSelected: true));

      Finder inViewer(Finder what) =>
          find.descendant(of: find.byType(DeckViewerScreen), matching: what);
      int onTop() => tester
          .widget<PillCardStack>(inViewer(find.byType(PillCardStack)))
          .index;

      // The cards themselves, the way a tap on the widget opens them: the
      // day's five under Today, from the first, not from the card the
      // shelf has at its front.
      void expectFromTheFirst() {
        expect(find.byType(DeckViewerScreen), findsOneWidget);
        final DeckViewerScreen viewer = tester.widget(
          find.byType(DeckViewerScreen),
        );
        expect(viewer.title, 'Today');
        expect(
          viewer.deck.map((p) => p.id),
          orderedEquals(app.todaysDeck.map((p) => p.id)),
        );
        expect(viewer.initialIndex, 0);
        // Read back, not answered again.
        expect(viewer.answering, isFalse);
        expect(onTop(), 0);
        expect(inViewer(find.text('1/5')), findsOneWidget);
      }

      await tester.tap(again);
      await _settle(tester);
      expectFromTheFirst();
      expect(said.of('today seen again').single['from'], 'today');

      // Left on the second card, the next time starts from the first too.
      await _swipeCardAway(tester);
      expect(onTop(), 1);
      expect(inViewer(find.text('2/5')), findsOneWidget);
      await tester.tap(inViewer(find.bySemanticsLabel('Close')).first);
      await _settle(tester);
      expect(find.byType(DeckViewerScreen), findsNothing);
      await tester.tap(again);
      await _settle(tester);
      expectFromTheFirst();
      await tester.tap(inViewer(find.bySemanticsLabel('Close')).first);
      await _settle(tester);

      // Explore's row opens them the same way, from the same viewer.
      await tester.tap(find.byKey(const ValueKey('tab-Explore')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('your-five')));
      await _settle(tester);
      expectFromTheFirst();
      expect(said.of('today seen again').map((e) => e['from']), [
        'today',
        'today',
        'explore',
      ]);

      // Left on the second card, the next time starts from the first too.
      await _swipeCardAway(tester);
      expect(onTop(), 1);
      expect(inViewer(find.text('2/5')), findsOneWidget);
      await tester.tap(inViewer(find.bySemanticsLabel('Close')).first);
      await _settle(tester);
      expect(find.byType(DeckViewerScreen), findsNothing);
      await tester.tap(find.byKey(const ValueKey('your-five')));
      await _settle(tester);
      expectFromTheFirst();
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

    test('a card leaves as its own page on the site, its link short', () {
      expect(
        cardLink('space-aerogel-comet-catch'),
        'https://astutetheapp.com/c/space-aerogel-comet-catch'
        '?ref=share_card',
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

    /// Opens a card's share sheet over a bare screen, taps [button] and
    /// returns what reached the clipboard. No share sheet under a test: a
    /// message is copied instead.
    Future<List<String>> sentFrom(
      WidgetTester tester,
      Pill pill,
      String button,
    ) async {
      final copied = _clipboard(tester);
      sendText = (_) async => false;
      addTearDown(() => sendText = shareText);
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showShareSheet(context, pill),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      await tester.ensureVisible(find.byKey(ValueKey(button)));
      await tester.tap(find.byKey(ValueKey(button)));
      await _settle(tester);
      return copied;
    }

    testWidgets('a card that asks: what is asked, its question and its page, '
        'never its answer', (tester) async {
      final Pill pill = PillBank.cards.firstWhere(
        (p) => p.asksSomething && p.challenge is! TakeASide,
      );
      final List<String> copied = await sentFrom(tester, pill, 'share-send');
      expect(copied, hasLength(1));
      expect(
        copied.single,
        'Can you get this one?\n${pill.question}\n${cardLink(pill.id)}',
      );
      expect(copied.single, isNot(contains(pill.answer)));
      expect(find.byKey(const ValueKey('share-note')), findsOneWidget);
    });

    testWidgets('a card that tells: its question and its page, and nothing '
        'asked', (tester) async {
      final Pill pill = PillBank.cards.firstWhere(
        (p) => !p.asksSomething && p.web == null,
      );
      final List<String> copied = await sentFrom(tester, pill, 'share-send');
      expect(copied.single, '${pill.question}\n${cardLink(pill.id)}');
    });

    testWidgets('a debate asks which side', (tester) async {
      final Pill pill = PillBank.cards.firstWhere(
        (p) => p.challenge is TakeASide,
      );
      final List<String> copied = await sentFrom(tester, pill, 'share-send');
      expect(copied.single, startsWith('Which side are you on?\n'));
    });

    testWidgets('the link alone, copied', (tester) async {
      final Pill pill = PillBank.cards.firstWhere((p) => p.hasPage);
      final List<String> copied = await sentFrom(
        tester,
        pill,
        'share-copy-link',
      );
      expect(copied.single, cardLink(pill.id));
    });

    testWidgets('the old long text is gone', (tester) async {
      final Pill pill = PillBank.cards.firstWhere((p) => p.hasPage);
      await tester.pumpWidget(
        _host(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showShareSheet(context, pill),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      // One way to send, one picture, one link: no challenge apart, no
      // second button doing the same as the first.
      expect(find.byKey(const ValueKey('share-challenge')), findsNothing);
      expect(find.byIcon(Icons.download_rounded), findsNothing);
      expect(find.byKey(const ValueKey('share-image')), findsOneWidget);
      // And the picture asks; it does not answer.
      expect(find.text(pill.barMove), findsNothing);
      expect(find.text(pill.answer), findsNothing);
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

  group('The intro leads with reading, and a sign-in never fails silently', () {
    testWidgets('Start reading is the one way on: there is no Skip beside it', (
      tester,
    ) async {
      final said = _listen();
      var continued = 0;
      var asked = 0;
      await tester.pumpWidget(
        _host(
          IntroScreen(
            onContinue: () => continued++,
            onSignIn: (_) async {
              asked++;
              return false;
            },
          ),
        ),
      );
      await _settle(tester);

      // No provider on the first screen: an account is behind a quiet line.
      expect(find.text('Continue with Apple'), findsNothing);
      expect(find.text('Continue with Google'), findsNothing);
      expect(
        find.textContaining('Already have an account?', findRichText: true),
        findsOneWidget,
      );

      await tester.tap(find.text('Start reading'));
      await _settle(tester);
      expect(continued, 1);
      expect(said.of('intro skipped'), hasLength(1));
      expect(said.of('intro skipped').single['by'], 'start reading');
      expect(said.of('intro skipped').single['at_scene'], 1);
      // Nothing was signed in to, and nothing says it was tried.
      expect(find.byType(SnackBar), findsNothing);

      // No corner doing what the button does: one way on.
      expect(find.text('Skip'), findsNothing);

      // The quiet line asks for a sign-in; one that does not end in an
      // account leaves the reader where they were.
      await tester.tap(find.byKey(const ValueKey('intro-sign-in')));
      await _settle(tester);
      expect(asked, 1);
      expect(continued, 1);
    });

    testWidgets('in the app it lands on the subjects', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.text('Start reading'));
      await _settle(tester);
      expect(find.byType(IntroScreen), findsNothing);
      expect(find.byType(MixScreen), findsOneWidget);
      expect(find.text('20 of 20 subjects in the mix'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('signing in opens Apple and Google on a sheet, and a build '
        'that cannot sign in says so there, in the reader\'s language', (
      tester,
    ) async {
      final said = _listen();
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('intro-sign-in')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('sign-in-sheet')), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(said.of('sign in sheet shown').single['from'], 'intro');

      // No Firebase under a test: the sheet says so, rather than a tap that
      // does nothing, and the reader stays where they were.
      await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
      await _settle(tester);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('sign-in-sheet')),
          matching: find.text('Signing in is not available on this build.'),
        ),
        findsOneWidget,
      );
      expect(said.of('sign in ended').single, containsPair('from', 'intro'));
      expect(
        said.of('sign in ended').single,
        containsPair('outcome', 'unavailable'),
      );

      // Not now: back on the intro, with nothing signed in.
      await tester.tap(find.byKey(const ValueKey('sign-in-not-now')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('sign-in-sheet')), findsNothing);
      expect(find.byType(IntroScreen), findsOneWidget);
      expect(said.of('sign in sheet closed').single['signed_in'], false);
    });
  });

  group('An account is offered once, when the reader is back for a day', () {
    Future<AppState> app(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final AppState app = AppState(
        hasPermission: () async => false,
        askPermission: () async => false,
        arm: (_) async {},
        disarm: () async {},
        pushWidget: (_) async {},
      );
      await app.init();
      return app;
    }

    test('not before a day is behind the reader, nor after only the '
        'first', () async {
      expect((await app(_free())).shouldOfferAccount, isFalse);
      expect(
        (await app(_free(days: [_daysAgo(1)]))).shouldOfferAccount,
        isFalse,
      );
    });

    test('after another, once, and again for somebody new', () async {
      final AppState reader = await app(
        _free(days: [_daysAgo(2), _daysAgo(1)]),
      );
      expect(reader.shouldOfferAccount, isTrue);
      await reader.notedAccountOffered();
      expect(reader.shouldOfferAccount, isFalse);
      // Remembered across a launch.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('knowit.accountOffered'), isTrue);
      // Signing out wipes the phone: whoever comes next is offered it after
      // a day of their own.
      await reader.signOut();
      expect(reader.accountOffered, isFalse);
      expect(reader.shouldOfferAccount, isFalse);
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
      // The verdict runs into what was picked, quoted, how sure, and what
      // is right: one paragraph, its first words set large, each said once.
      expect(
        find.text(
          'Not quite.  You said “${challenge.options[wrong]}”, '
          '70%\u00A0sure\u00A0· Right: “${challenge.correctOption}”',
        ),
        findsOneWidget,
      );
    });
  });
}
