// Photographs where sharing the day lives once the five are read, each of
// the four ways drawn for the owner (ShareDayPick in
// lib/state/debug_looks.dart), as the developer tools set them on a phone:
// A as it ships, See again and the share's mark over the shelf; B the mark
// alone; C the day's own moment, and the shelf after it; D the day as a
// card after the five, at the front, where the shelf lands on it. Each at
// night, in Italian on a 390 by 844 phone (the owner's sheet), and the long
// and the narrow: German, an SE's 375 by 667 at a larger text size, and a
// 320 by 640 at the largest.
//
//   SHOTS=/some/folder flutter test tool/share_day_place_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// cards' pictures are read from web/cards, as the site serves them.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/debug_flags.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_done_view.dart';
import 'package:astuto/state/debug_looks.dart';
import 'package:astuto/widgets/day_moment.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Fraunces': 'assets/fonts/Fraunces.ttf',
    'Figtree': 'assets/fonts/Figtree.ttf',
    'MaterialIcons':
        '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    final bytes = await File(entry.value).readAsBytes();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
    await loader.load();
  }
}

/// A card's picture, from the site's own folder rather than the network.
ImageProvider _local(Uri url) {
  final String path = url.path.startsWith('/cards/')
      ? url.path.substring('/cards/'.length)
      : url.path;
  final File file = File('web/cards/$path');
  return MemoryImage(file.existsSync() ? file.readAsBytesSync() : Uint8List(0));
}

/// Waits for the pictures on screen to come, as a phone would.
Future<void> _pictures(WidgetTester tester) async {
  for (int round = 0; round < 3; round++) {
    await tester.runAsync(() async {
      for (final Element e in find.byType(Image).evaluate().toList()) {
        final Image image = e.widget as Image;
        try {
          await precacheImage(image.image, e, onError: (_, _) {});
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }
}

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// A phone: its size in points, and its status bar and home bar.
typedef _Phone = ({String name, Size size, double top, double bottom});

const _Phone _tall = (name: '390', size: Size(390, 844), top: 47, bottom: 34);
const _Phone _se = (name: '375', size: Size(375, 667), top: 20, bottom: 0);
const _Phone _small = (name: '320', size: Size(320, 640), top: 20, bottom: 0);

/// A phone, its language and its text size.
typedef _Take = ({String lang, _Phone phone, double text});

const List<_Take> _takes = [
  (lang: 'it', phone: _tall, text: 1),
  (lang: 'de', phone: _tall, text: 1),
  (lang: 'de', phone: _se, text: 1.3),
  (lang: 'de', phone: _small, text: 2),
];

String _nameOf(_Take take) =>
    '${take.lang}-${take.phone.name}-x${take.text.toString().replaceAll('.0', '')}';

/// The day's five, a picture each, the first red, as the owner's was.
List<Pill> _five() {
  Pill of(String topic, [int skip = 0]) => PillBank.cards
      .where((p) => p.topic == topic && p.web?.thumbs != null)
      .elementAt(skip);
  return [
    of('Human body'),
    of('Space', 3),
    of('Psychology', 2),
    of('Economics', 1),
    of('History', 4),
  ];
}

/// A reader on the fourth day running, today's five read, on the free plan,
/// a card liked some other day, nothing asked of them over the shelf, and
/// the day sent from [pick].
Map<String, Object> _finished(ShareDayPick pick) {
  final DateTime now = DateTime.now();
  String back(int days) =>
      dateKey(DateTime(now.year, now.month, now.day - days));
  final List<String> deck = [for (final Pill p in _five()) p.id];
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.todayDate': back(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': deck.length,
    'knowit.streak': 4,
    'knowit.bestStreak': 4,
    'knowit.lastCompletionDate': back(0),
    'knowit.completedDates': [for (int d = 3; d >= 0; d--) back(d)],
    'knowit.seenIds': [...PillBank.cards.take(40).map((p) => p.id), ...deck],
    'knowit.likedIds': [PillBank.cards[7].id],
    'knowit.debug.shareDay': pick.name,
  };
}

/// The app on the finished day, the day sent from [pick], as [take] holds
/// the phone.
Future<void> _open(WidgetTester tester, _Take take, ShareDayPick pick) async {
  const double ratio = 3;
  tester.view.physicalSize = take.phone.size * ratio;
  tester.view.devicePixelRatio = ratio;
  final FakeViewPadding padding = FakeViewPadding(
    top: take.phone.top * ratio,
    bottom: take.phone.bottom * ratio,
  );
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
  final Locale locale = Locale(take.lang);
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.textScaleFactorTestValue = take.text;
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final bool tools = debugToolsOn;
  debugToolsOn = true;
  addTearDown(() {
    debugToolsOn = tools;
    // ignore: invalid_use_of_visible_for_testing_member
    DebugLooks.reset();
  });
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(_finished(pick));
  await tester.pumpWidget(const AstutoApp());
  await _settle(tester);
  await _pictures(tester);
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    CardThumb.image = _local;
  });

  final String out =
      Platform.environment['SHOTS'] ?? 'shots/gallery/sharedayplace';

  Future<void> shoot(WidgetTester tester, String name) =>
      expectLater(find.byType(AstutoApp), matchesGoldenFile('$out/$name.png'));

  for (final _Take take in _takes) {
    final String at = _nameOf(take);

    // A, B and C's shelf, as each heads it.
    for (final ShareDayPick pick in [
      ShareDayPick.a,
      ShareDayPick.b,
      ShareDayPick.c,
    ]) {
      testWidgets('${pick.name}, $at', (tester) async {
        await _open(tester, take, pick);
        expect(tester.takeException(), isNull);
        await shoot(tester, '${pick.name}-$at');
      });
    }

    // C's moment, over the shelf it closes onto.
    testWidgets('c, the moment, $at', (tester) async {
      await _open(tester, take, ShareDayPick.c);
      final TodayDoneView shelf = tester.widget<TodayDoneView>(
        find.byType(TodayDoneView),
      );
      Navigator.of(
        tester.element(find.byType(TodayDoneView)),
        rootNavigator: true,
      ).push(DayMoment.route(shelf.app, preview: true));
      await _settle(tester);
      await _pictures(tester);
      await _settle(tester, 4);
      expect(tester.takeException(), isNull);
      await shoot(tester, 'c-moment-$at');
    });

    // D, the day's card at the front, where the shelf lands on it the
    // evening the day is finished.
    testWidgets('d, the day\'s card, $at', (tester) async {
      await _open(tester, take, ShareDayPick.d);
      final String yours = lookupAppLocalizations(Locale(take.lang))
          .yourDayCard;
      await tester.tap(find.bySemanticsLabel(yours).last);
      await _settle(tester);
      await _pictures(tester);
      await _settle(tester, 4);
      expect(tester.takeException(), isNull);
      await shoot(tester, 'd-$at');
    });
  }
}
