// Where the day is sent from once the five are read: the four ways drawn for
// the owner (ShareDayPick, lib/state/debug_looks.dart), picked in the debug
// section at the foot of the profile, kept like the other looks, and read
// only while the developer tools are on. A as it ships, See again and the
// share's mark over the shelf; B the mark alone; C the day's own moment,
// right after the five, once, never nagging (lib/widgets/day_moment.dart);
// D the day as a card after the five on the shelf. In long languages, at a
// large text size, on a small phone, nothing is cut.
//
//   flutter test test/share_day_place_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/data/daily.dart' show dealDay;
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/l10n.dart';
import 'package:astuto/main.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/day_moment.dart';
import 'package:astuto/widgets/pill_card_stack.dart';
import 'package:astuto/widgets/share_day.dart';

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

/// Today's five, as the day deals them.
List<String> _deck() =>
    dealDay(date: DateTime.now()).cards
        .take(kPillsPerDay)
        .map((p) => p.id)
        .toList();

/// A reader three days running, nothing asked of them over the shelf, the
/// day sent from [pick]: today's five read, or, with [left], that many still
/// to read, the day not yet finished.
Map<String, Object> _reader(
  ShareDayPick pick, {
  bool plus = false,
  int left = 0,
  Map<String, Object> more = const {},
}) {
  final DateTime now = DateTime.now();
  String day(int back) => dateKey(now.subtract(Duration(days: back)));
  final List<String> deck = _deck();
  final bool done = left == 0;
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.todayDate': day(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': deck.length - left,
    'knowit.streak': done ? 3 : 2,
    'knowit.bestStreak': 3,
    'knowit.lastCompletionDate': day(done ? 0 : 1),
    'knowit.completedDates': [day(2), day(1), if (done) day(0)],
    'knowit.seenIds': deck,
    'knowit.debug.shareDay': pick.name,
    ...more,
  };
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Throws the card on top of the deck, from the question at its top.
Future<void> _throwTop(WidgetTester tester) async {
  final Rect deck = tester.getRect(find.byType(PillCardStack));
  await tester.flingFrom(
    Offset(deck.center.dx, deck.top + 90),
    const Offset(-320, 0),
    900,
  );
  await _settle(tester);
}

/// Reads the rest of the day: what is left of the five, and on the free
/// plan the card after them that offers the rest, thrown like the rest.
Future<void> _finishDay(WidgetTester tester) async {
  for (var i = 0; i < 7; i++) {
    if (find.byType(PillCardStack).evaluate().isEmpty) break;
    await _throwTop(tester);
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

/// Picks [pick] in the debug section at the foot of the profile, and goes
/// back to Today.
Future<void> _pick(WidgetTester tester, ShareDayPick pick) async {
  await tester.tap(find.byKey(const ValueKey('tab-Profile')));
  await _settle(tester);
  final Finder choice = find.byKey(ValueKey('debug-share-day-${pick.name}'));
  await tester.scrollUntilVisible(choice, 400, scrollable: _profileList);
  await _settle(tester);
  await tester.tap(choice);
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('tab-Today')));
  await _settle(tester);
}

final Finder _moment = find.byKey(const ValueKey('day-moment'));
final Finder _again = find.byKey(const ValueKey('shelf-see-again'));
final Finder _mark = find.byKey(const ValueKey('shelf-share-day'));
final Finder _dayCard = find.byKey(const ValueKey('shelf-day-card'));

/// What the app said, kept, so a test can read its counting back.
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

/// How many lines the text under [finder] takes at the width it was given.
int _lines(WidgetTester tester, Finder finder) {
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)).first,
  );
  final TextPainter painter = TextPainter(
    text: paragraph.text,
    textDirection: TextDirection.ltr,
    textScaler: paragraph.textScaler,
  )..layout(maxWidth: paragraph.constraints.maxWidth);
  final int lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

/// Whether the text under [finder] is laid out whole in the room it was
/// given: as tall as it is set, not clipped at its foot.
bool _whole(WidgetTester tester, Finder finder) {
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)).first,
  );
  final TextPainter painter = TextPainter(
    text: paragraph.text,
    textDirection: TextDirection.ltr,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
  )..layout(maxWidth: paragraph.constraints.maxWidth);
  final bool whole =
      !painter.didExceedMaxLines &&
      painter.height <= paragraph.size.height + 0.5;
  painter.dispose();
  return whole;
}

void main() {
  setUpAll(_loadRealFonts);

  late bool tools;

  setUp(() {
    tools = debugToolsOn;
    debugToolsOn = true;
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    debugToolsOn = tools;
    DebugLooks.reset();
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
  });

  test(
    'kept on the phone, read back at the next start, kept through the '
    'wipe; read only while the tools are on, and A as the app ships',
    () async {
      SharedPreferences.setMockInitialValues(_reader(ShareDayPick.a));
      await DebugLooks.setShareDay(ShareDayPick.c);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowit.debug.shareDay'), 'c');

      DebugLooks.reset();
      expect(DebugLooks.shareDayPicked, ShareDayPick.a);
      final AppState app = AppState();
      await app.init();
      expect(DebugLooks.shareDay.value, ShareDayPick.c);

      await app.signOut();
      expect(prefs.getBool('knowit.onboarded'), isNull);
      expect(prefs.getString('knowit.debug.shareDay'), 'c');

      // A build without the tools never reads it.
      debugToolsOn = false;
      expect(DebugLooks.shareDayPicked, ShareDayPick.a);
      expect(TodayDoneView.share, ShareDayPick.a);
      expect(TodayDoneView.seeAgainOn, isTrue);
      expect(TodayDoneView.dayCardOn, isFalse);
      debugToolsOn = true;
      expect(TodayDoneView.share, ShareDayPick.c);
    },
  );

  testWidgets('picked in the debug section, the shelf changes at once: A See '
      'again and the mark, B and C the mark alone, D nothing over the shelf '
      'and the day\'s own card after the five', (tester) async {
    SharedPreferences.setMockInitialValues(_reader(ShareDayPick.a));
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(_again, findsOneWidget);
    expect(_mark, findsOneWidget);

    for (final ShareDayPick pick in [ShareDayPick.b, ShareDayPick.c]) {
      await _pick(tester, pick);
      expect(DebugLooks.shareDay.value, pick);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'knowit.debug.shareDay',
        ),
        pick.name,
      );
      expect(_again, findsNothing, reason: pick.name);
      expect(_mark, findsOneWidget, reason: pick.name);
      // Still at the end of the day's row, over the card.
      expect(
        tester.getRect(_mark).left,
        greaterThan(tester.getRect(find.text('Day 3')).right),
      );
    }

    await _pick(tester, ShareDayPick.d);
    expect(_again, findsNothing);
    expect(_mark, findsNothing);
    expect(find.text('Day 3'), findsOneWidget);
    // One dot more, the day's, between the fifth and the offer's.
    final Finder dot = find.bySemanticsLabel('Your day');
    expect(dot, findsOneWidget);
    await tester.tap(dot);
    await _settle(tester);
    expect(_dayCard, findsOneWidget);
    expect(find.text('YOUR DAY'), findsOneWidget);
    expect(find.byType(DayPicture), findsOneWidget);
    expect(find.byKey(const ValueKey('shelf-day-send')), findsOneWidget);
    // At the front, in the middle of the screen.
    expect(
      tester.getCenter(_dayCard).dx,
      closeTo(tester.view.physicalSize.width / 2, 2),
    );
    // And the offer still after it, on the free plan.
    await tester.drag(find.byType(TodayDoneView), const Offset(-200, 0));
    await _settle(tester);
    expect(find.byKey(const ValueKey('shelf-magic')), findsOneWidget);

    // Back as it ships, from the same place.
    await _pick(tester, ShareDayPick.a);
    expect(_again, findsOneWidget);
    expect(_mark, findsOneWidget);
    expect(find.bySemanticsLabel('Your day'), findsNothing);
  });

  testWidgets('D: the evening the day is finished, the shelf lands on the '
      'day\'s card, after the offer is thrown; opened again, it starts from '
      'the first card', (tester) async {
    SharedPreferences.setMockInitialValues(_reader(ShareDayPick.d, left: 1));
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    expect(find.byType(TodayDoneView), findsNothing);
    await _finishDay(tester);
    await _settle(tester, 20);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(_dayCard, findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Your day')),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    // Nothing rises over it: the day's card is the moment.
    expect(_moment, findsNothing);

    // The next time Today opens on the finished day, the first card.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 20);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Card 1 of 5')),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
  });

  testWidgets('C: right after the fifth the day\'s own moment rises over the '
      'shelf, its picture, Share your day and Later; Later closes it onto '
      'the shelf with the mark alone, and it is kept as risen today', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(
      _reader(ShareDayPick.c, plus: true, left: 1),
    );
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await _finishDay(tester);
    await _settle(tester, 20);

    expect(_moment, findsOneWidget);
    expect(find.text('DAY 3'), findsOneWidget);
    expect(find.text('Day complete.'), findsOneWidget);
    expect(find.byType(DayPicture), findsOneWidget);
    expect(find.text('Share your day'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('knowit.dayMomentOn'), dateKey(DateTime.now()));

    await tester.tap(find.byKey(const ValueKey('day-moment-later')));
    await _settle(tester);
    expect(_moment, findsNothing);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(_mark, findsOneWidget);
    expect(_again, findsNothing);
    expect(prefs.getInt('knowit.dayMomentLaters'), 1);

    // Opening the app onto the finished day never raises it.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 30);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(_moment, findsNothing);
  });

  testWidgets('C never nags: not twice in a day, not after three Laters in a '
      'row, not on an evening something else is asked, not on opening onto a '
      'finished day, and not where it is not the look picked', (tester) async {
    final String today = dateKey(DateTime.now());
    for (final (String why, Map<String, Object> prefs) in [
      (
        'risen today already',
        _reader(
          ShareDayPick.c,
          plus: true,
          left: 1,
          more: {'knowit.dayMomentOn': today},
        ),
      ),
      (
        'three Laters in a row',
        _reader(
          ShareDayPick.c,
          plus: true,
          left: 1,
          more: {'knowit.dayMomentLaters': DayMomentMemory.restsAfter},
        ),
      ),
      (
        'the store\'s rating sheet put tonight',
        _reader(
          ShareDayPick.c,
          plus: true,
          left: 1,
          more: {'knowit.reviewAskedOn': today, 'knowit.reviewAsks': 1},
        ),
      ),
      ('as it ships', _reader(ShareDayPick.a, plus: true, left: 1)),
      ('the day as a card', _reader(ShareDayPick.d, plus: true, left: 1)),
    ]) {
      SharedPreferences.setMockInitialValues(prefs);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await _finishDay(tester);
      await _settle(tester, 25);
      expect(find.byType(TodayDoneView), findsOneWidget, reason: why);
      expect(_moment, findsNothing, reason: why);
    }

    // Opened onto a day finished before this sitting.
    SharedPreferences.setMockInitialValues(_reader(ShareDayPick.c));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 25);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(_moment, findsNothing);
  });

  testWidgets('C gives the evening to anything else asked at the finished '
      'day: not when the reminder is due, nor when the store\'s rating sheet '
      'was put; otherwise it rises', (tester) async {
    final String today = dateKey(DateTime.now());
    late BuildContext context;
    for (final (String why, Map<String, Object> more, bool rises) in [
      ('the reminder is due', {'knowit.pushAsked': false}, false),
      (
        'the rating sheet was put tonight',
        {'knowit.reviewAskedOn': today, 'knowit.reviewAsks': 1},
        false,
      ),
      ('nothing else asked', <String, Object>{}, true),
    ]) {
      SharedPreferences.setMockInitialValues(
        _reader(ShareDayPick.c, more: more),
      );
      DebugLooks.shareDay.value = ShareDayPick.c;
      final AppState app = AppState();
      await app.init();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(Brightness.dark),
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final bool rose = await showDayMomentIfDue(context, app);
      await _settle(tester);
      expect(rose, rises, reason: why);
      expect(_moment, rises ? findsOneWidget : findsNothing, reason: why);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('C on the free plan: the moment waits for the offer after the '
      'fifth to be thrown, and rises once the shelf is up', (tester) async {
    SharedPreferences.setMockInitialValues(_reader(ShareDayPick.c, left: 1));
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await _throwTop(tester);
    await _settle(tester, 20);
    // The offer is on the table, and nothing over it.
    expect(find.byKey(const ValueKey('magic-card')), findsOneWidget);
    expect(_moment, findsNothing);
    await _finishDay(tester);
    await _settle(tester, 20);
    expect(_moment, findsOneWidget);
  });

  testWidgets('C for a reader who asked for less motion: the moment is there '
      'at once, nothing fading or rising', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(
      _reader(ShareDayPick.c, plus: true, left: 1),
    );
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await _throwTop(tester);
    // The shelf lands, and the moment comes a beat after it.
    for (var i = 0; i < 40 && _moment.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(_moment, findsOneWidget);
    await tester.pump();
    final Finder title = find.text('Day complete.');
    for (final Element e
        in find
            .ancestor(of: title, matching: find.byType(FadeTransition))
            .evaluate()) {
      expect((e.widget as FadeTransition).opacity.value, 1);
    }
    for (final Element e
        in find
            .ancestor(of: title, matching: find.byType(Opacity))
            .evaluate()) {
      expect((e.widget as Opacity).opacity, 1);
    }
    for (final Element e
        in find
            .ancestor(of: title, matching: find.byType(Transform))
            .evaluate()) {
      final Matrix4 m = (e.widget as Transform).transform;
      expect(m.getTranslation().y, 0);
    }
  });

  testWidgets('C: Share your day sends the day\'s picture as the sheet sends '
      'it, counted from the moment; the moment closes onto the shelf and the '
      'count of Laters starts again', (tester) async {
    final _Said said = _Said();
    Analytics.useForTest(said);
    addTearDown(() => Analytics.useForTest(null));
    final List<String> sent = [];
    final previous = ShareDay.shareImage;
    ShareDay.shareImage = (bytes, name, text, origin) async {
      sent.add(name);
      return true;
    };
    addTearDown(() => ShareDay.shareImage = previous);
    SharedPreferences.setMockInitialValues(
      _reader(
        ShareDayPick.c,
        plus: true,
        left: 1,
        more: {'knowit.dayMomentLaters': 2},
      ),
    );
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
    await _finishDay(tester);
    await _settle(tester, 20);
    expect(_moment, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-moment-send')));
    // The picture is made off the frame: pictures come, the frame is drawn,
    // the picture is taken; real time and frames, turn about.
    for (var i = 0; i < 80 && sent.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(sent, hasLength(1));
    expect(sent.single, startsWith('astute-'));
    await _settle(tester);
    expect(_moment, findsNothing);
    expect(find.byType(TodayDoneView), findsOneWidget);
    expect(said.of('day shared'), hasLength(1));
    expect(said.of('day shared').single['from'], 'day moment');
    expect(said.of('day shared').single['as'], 'image');
    expect(said.of('day shared').single['layout'], 'cover');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('knowit.dayMomentLaters'), isNull);
  });

  group(
    'in long languages, at large text, on a small phone, nothing is cut',
    () {
      Future<AppState> finished(WidgetTester tester, ShareDayPick pick) async {
        SharedPreferences.setMockInitialValues(_reader(pick));
        DebugLooks.shareDay.value = pick;
        final AppState app = AppState();
        await app.init();
        await tester.pump();
        return app;
      }

      Widget host(Locale locale, Widget child) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        home: Scaffold(body: SafeArea(child: child)),
      );

      const List<Size> phones = [
        Size(390, 844),
        Size(375, 667),
        Size(320, 640),
      ];
      const List<double> sizes = [1.0, 1.3, 2.0];
      const List<String> languages = ['de', 'ru', 'fr', 'pl', 'tr', 'ja', 'it'];

      testWidgets('C: the moment, its line on two lines at most, its buttons '
          'whole, all of it on the screen', (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final AppState app = await finished(tester, ShareDayPick.c);
        for (final Size phone in phones) {
          tester.view.physicalSize = phone;
          for (final double text in sizes) {
            tester.platformDispatcher.textScaleFactorTestValue = text;
            for (final String language in languages) {
              final String at = '${phone.width} ${text}x $language';
              await tester.pumpWidget(
                host(Locale(language), DayMoment(app: app, preview: true)),
              );
              await tester.pump(const Duration(seconds: 1));
              expect(tester.takeException(), isNull, reason: at);
              final Finder title = find.byKey(
                const ValueKey('day-moment-title'),
              );
              expect(_lines(tester, title), lessThanOrEqualTo(2), reason: at);
              final Rect later = tester.getRect(
                find.byKey(const ValueKey('day-moment-later')),
              );
              expect(later.bottom, lessThanOrEqualTo(phone.height), reason: at);
              final Rect send = tester.getRect(
                find.byKey(const ValueKey('day-moment-send')),
              );
              final Rect picture = tester.getRect(find.byType(DayPicture));
              expect(picture.height, greaterThan(120), reason: at);
              expect(picture.bottom, lessThanOrEqualTo(send.top), reason: at);
              expect(
                tester.getRect(title).bottom,
                lessThanOrEqualTo(picture.top),
                reason: at,
              );
              // The day's name on its one line, whole.
              expect(
                _lines(tester, find.byKey(const ValueKey('day-moment-day'))),
                1,
                reason: at,
              );
            }
          }
        }
      });

      testWidgets(
        'D: the day\'s card at the front, its name on one line and its '
        'button inside it',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final AppState app = await finished(tester, ShareDayPick.d);
          final int day = app.todaysDeck.length;
          for (final Size phone in phones) {
            tester.view.physicalSize = phone;
            for (final double text in sizes) {
              tester.platformDispatcher.textScaleFactorTestValue = text;
              for (final String language in languages) {
                final String at = '${phone.width} ${text}x $language';
                await tester.pumpWidget(
                  host(
                    Locale(language),
                    Builder(
                      builder: (context) => TodayDoneView(
                        app: app,
                        at: day,
                        onPick: (_) {},
                        heading: (
                          line: context.l10n.dayTitle(app.dayNumber),
                          aside: null,
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pump(const Duration(milliseconds: 400));
                expect(tester.takeException(), isNull, reason: at);
                final Rect card = tester.getRect(_dayCard);
                final Rect name = tester.getRect(
                  find.byKey(const ValueKey('shelf-day-card-name')),
                );
                final Rect send = tester.getRect(
                  find.byKey(const ValueKey('shelf-day-send')),
                );
                expect(card.contains(name.topLeft), isTrue, reason: at);
                expect(name.right, lessThanOrEqualTo(card.right), reason: at);
                expect(send.bottom, lessThanOrEqualTo(card.bottom), reason: at);
                expect(send.left, greaterThanOrEqualTo(card.left), reason: at);
                final Rect picture = tester.getRect(find.byType(DayPicture));
                expect(picture.bottom, lessThanOrEqualTo(send.top), reason: at);
                expect(
                  picture.top,
                  greaterThanOrEqualTo(name.bottom),
                  reason: at,
                );
                // Nothing at the end of the day's row.
                expect(_mark, findsNothing, reason: at);
                expect(_again, findsNothing, reason: at);
              }
            }
          }
        },
      );

      testWidgets('B and C: the mark alone at the end of the day\'s row, the '
          'day\'s name on its line', (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final AppState app = await finished(tester, ShareDayPick.b);
        for (final ShareDayPick pick in [ShareDayPick.b, ShareDayPick.c]) {
          DebugLooks.shareDay.value = pick;
          for (final Size phone in phones) {
            tester.view.physicalSize = phone;
            for (final double text in sizes) {
              tester.platformDispatcher.textScaleFactorTestValue = text;
              for (final String language in languages) {
                final String at =
                    '${pick.name} ${phone.width} ${text}x $language';
                await tester.pumpWidget(
                  host(
                    Locale(language),
                    Builder(
                      builder: (context) => TodayDoneView(
                        app: app,
                        at: 0,
                        onPick: (_) {},
                        heading: (
                          line: context.l10n.dayTitle(app.dayNumber),
                          aside: null,
                        ),
                      ),
                    ),
                  ),
                );
                await tester.pump(const Duration(milliseconds: 300));
                expect(tester.takeException(), isNull, reason: at);
                final Finder name = find.byKey(const ValueKey('shelf-day'));
                expect(_lines(tester, name), 1, reason: at);
                expect(_again, findsNothing, reason: at);
                expect(
                  tester.getRect(_mark).left,
                  greaterThanOrEqualTo(tester.getRect(name).right),
                  reason: at,
                );
                // The name stands whole over the shelf: its row gives it all
                // the height it is set at, so none of it is clipped or runs
                // under the card.
                expect(_whole(tester, name), isTrue, reason: at);
              }
            }
          }
        }
      });
    },
  );
}
