import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/genres.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/screens/genres_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/widgets/subject_icon.dart';

Future<AppState> _app(Map<String, double> mix) async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  final app = AppState(
    hasPermission: () async => false,
    askPermission: () async => false,
    arm: (_) async {},
    disarm: () async {},
    pushWidget: (_) async {},
  );
  await app.init();
  await app.setTopicMix(mix);
  return app;
}

Future<void> _pump(
  WidgetTester tester,
  AppState app, {
  void Function(Set<String>, Set<String>)? onDone,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GenresScreen(app: app, onDone: onDone ?? (_, _) {}, onSkip: () {}),
    ),
  );
  await tester.pump();
}

/// The planet drawn for a subject, found by the icon inside it.
double _planetOf(WidgetTester tester, String topicName) {
  final icon = find.byWidgetPredicate(
    (w) => w is SubjectIcon && w.subject == topicName,
  );
  // The icon is drawn at half the planet, which is the one number the row
  // reads off the wheel.
  return tester.getSize(icon).width * 2;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A phone's worth of width and far more than a phone's worth of height.
  // The list builds lazily, as it should on a real one, and a row the test
  // never scrolls to is a row that is not in the tree to be asked about —
  // so the test is given a screen tall enough to hold the whole wheel.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(400, 4000);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  group('the content tree', () {
    test('every subject on the wheel has six genres of three', () {
      // Thinking is the exception on purpose: it is not a subject, it is not
      // on the wheel, and it is never off the deck.
      final onWheel = kTopicOrder.where((k) => k != 'thinking');
      for (final key in onWheel) {
        expect(
          kGenres[key],
          isNotNull,
          reason: '$key is offered on the wheel with nothing under it',
        );
        expect(kGenres[key]!, hasLength(6), reason: key);
        for (final genre in kGenres[key]!) {
          expect(genre.strands, hasLength(3), reason: genre.id);
        }
      }
      expect(kGenres.containsKey('thinking'), isFalse);
    });

    test('no id is used twice, and a strand knows its genre', () {
      final ids = <String>{};
      for (final genre in kAllGenres) {
        expect(ids.add(genre.id), isTrue, reason: 'twice: ${genre.id}');
        for (final strand in genre.strands) {
          expect(ids.add(strand.id), isTrue, reason: 'twice: ${strand.id}');
          expect(genreIdOf(strand.id), genre.id);
        }
      }
      expect(kAllGenres, hasLength(108));
    });
  });

  group('the screen reads the wheel', () {
    testWidgets('the subject asked for most is first and drawn largest', (
      tester,
    ) async {
      final app = await _app({'history': 1.0, 'space': 0.2, 'science': 0.6});
      await _pump(tester, app);

      // Ordered by what the wheel was left at, not by the wheel's own order.
      final names = ['History', 'Science', 'Space'];
      final tops = [
        for (final n in names)
          tester.getTopLeft(find.text(n, skipOffstage: false)).dy,
      ];
      expect(tops[0], lessThan(tops[1]));
      expect(tops[1], lessThan(tops[2]));

      // And the planet carries the same answer: more of a subject is more of
      // a circle. 26 at nothing, 61 at everything.
      expect(_planetOf(tester, 'History'), closeTo(61, 0.5));
      expect(_planetOf(tester, 'Science'), closeTo(47, 0.5));
      expect(_planetOf(tester, 'Space'), closeTo(33, 0.5));
    });

    testWidgets('a subject left out of the mix keeps a quiet line', (
      tester,
    ) async {
      final app = await _app({'history': 1.0});
      await _pump(tester, app);

      // Not gone: a subject that vanishes reads as one the app does not have.
      expect(
        find.text('Food · off in your mix', skipOffstage: false),
        findsOneWidget,
      );
      // And it is below every subject that is in the mix.
      expect(
        tester.getTopLeft(find.text('History', skipOffstage: false)).dy,
        lessThan(
          tester
              .getTopLeft(
                find.text('Food · off in your mix', skipOffstage: false),
              )
              .dy,
        ),
      );
    });

    testWidgets('the title is the wheel it belongs to', (tester) async {
      final app = await _app({'history': 1.0});
      await _pump(tester, app);
      expect(find.text('Your mix'), findsOneWidget);
    });
  });

  group('turning things down', () {
    testWidgets('everything starts on, and the footer counts it', (
      tester,
    ) async {
      final app = await _app({'history': 1.0});
      await _pump(tester, app);
      expect(find.text('Continue · 108 of 108 genres on'), findsOneWidget);
    });

    testWidgets('a genre tapped off is handed over at the end', (tester) async {
      final app = await _app({'history': 1.0});
      Set<String>? off;
      await _pump(tester, app, onDone: (g, _) => off = g);

      await tester.tap(find.text('Ancient Rome'));
      await tester.pump();
      expect(find.text('Continue · 107 of 108 genres on'), findsOneWidget);

      await tester.tap(find.textContaining('Continue ·'));
      await tester.pump();
      expect(off, contains('history.ancient_rome'));
    });

    testWidgets('holding a genre opens its three in place', (tester) async {
      final app = await _app({'history': 1.0});
      await _pump(tester, app);

      // Nothing is open until it is asked for.
      expect(find.text('Roads'), findsNothing);

      await tester.longPress(find.text('Ancient Rome'));
      await tester.pump();

      // The three, under the row rather than over it: the six they belong to
      // are still on screen, which is the whole point of opening in place.
      expect(find.text('Roads'), findsOneWidget);
      expect(find.text('Daily Rome'), findsOneWidget);
      expect(find.text('The fall'), findsOneWidget);
      expect(find.text('Ancient Rome'), findsOneWidget);
    });

    testWidgets('a strand turned off travels, and the chip says so', (
      tester,
    ) async {
      final app = await _app({'history': 1.0});
      Set<String>? strands;
      await _pump(tester, app, onDone: (_, s) => strands = s);

      await tester.longPress(find.text('Ancient Rome'));
      await tester.pump();
      await tester.tap(find.text('Roads'));
      await tester.pump();

      // Two of the three left, said on the chip itself — a badge on every
      // genre would say nothing, one that appears when something changed
      // says the reader has been inside this one.
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.textContaining('Continue ·'));
      await tester.pump();
      expect(strands, contains('history.ancient_rome.roads'));
    });

    testWidgets('the choice is remembered and comes back with the screen', (
      tester,
    ) async {
      final app = await _app({'history': 1.0});
      await app.setGenresOff({'history.ancient_rome'}, const {});

      await _pump(tester, app);
      expect(find.text('Continue · 107 of 108 genres on'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('knowit.genresOff'), ['history.ancient_rome']);
    });
  });
}
