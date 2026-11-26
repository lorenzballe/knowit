// Photographs the head of the finished day on Today, each way it can be
// drawn (DoneHead in lib/screens/today_done_view.dart): at night on a
// 390 by 844 phone and an SE's 375 by 667, the one the app ships on paper
// and with the line under its name, and Explore's way back to the reader's
// own five, "Your five from today", with what it opens.
//
//   SHOTS=/some/folder flutter test tool/today_head_shots.dart --update-goldens
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
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/screens/today_done_view.dart';
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
  return MemoryImage(
    file.existsSync() ? file.readAsBytesSync() : Uint8List(0),
  );
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

void _hold(WidgetTester tester, _Phone phone) {
  const double ratio = 3;
  tester.view.physicalSize = phone.size * ratio;
  tester.view.devicePixelRatio = ratio;
  tester.view.padding = FakeViewPadding(
    top: phone.top * ratio,
    bottom: phone.bottom * ratio,
  );
  tester.view.viewPadding = FakeViewPadding(
    top: phone.top * ratio,
    bottom: phone.bottom * ratio,
  );
}

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

/// A reader on the fourth day running, today's five read, on the free plan.
/// [liked]: a card liked some other day, so the hint about liking is spent.
Map<String, Object> _finished({bool paper = false, bool liked = true}) {
  final DateTime now = DateTime.now();
  String back(int days) =>
      dateKey(DateTime(now.year, now.month, now.day - days));
  final List<String> deck = [for (final Pill p in _five()) p.id];
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    if (paper) 'knowit.theme': 'light',
    // Nothing asked of the reader over the finished day.
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
    if (liked) 'knowit.likedIds': [PillBank.cards[7].id],
  };
}

/// The app on the finished day, its head drawn as [head].
Future<void> _open(
  WidgetTester tester,
  _Phone phone,
  DoneHead head, {
  bool paper = false,
  bool liked = true,
}) async {
  _hold(tester, phone);
  addTearDown(tester.view.reset);
  // ignore: invalid_use_of_visible_for_testing_member
  TodayDoneView.head = head;
  addTearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    TodayDoneView.head = kDoneHead;
  });
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(
    _finished(paper: paper, liked: liked),
  );
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
      Platform.environment['SHOTS'] ?? 'shots/gallery/todayhead';

  Future<void> shoot(WidgetTester tester, String name) => expectLater(
    find.byType(AstutoApp),
    matchesGoldenFile('$out/$name.png'),
  );

  // Each head at night, on both phones.
  for (final DoneHead head in DoneHead.values) {
    for (final _Phone phone in [_tall, _se]) {
      testWidgets('${head.name}, ${phone.name}', (tester) async {
        await _open(tester, phone, head);
        await shoot(tester, '${head.name}-${phone.name}-dark');
      });
    }
  }

  // The head the app ships, on paper, and with the line under its name: a
  // reader who has not liked a card yet is told how.
  testWidgets('${kDoneHead.name} on paper', (tester) async {
    await _open(tester, _tall, kDoneHead, paper: true);
    await shoot(tester, '${kDoneHead.name}-390-light');
  });
  for (final DoneHead head in DoneHead.values) {
    testWidgets('${head.name} with its aside', (tester) async {
      await _open(tester, _tall, head, liked: false);
      await shoot(tester, '${head.name}-aside-390-dark');
    });
  }

  // Explore, once the day is read: the way back to the reader's own five,
  // near the top, and what it opens — from the first card, though the
  // reader left the shelf on the third.
  for (final _Phone phone in [_tall, _se]) {
    testWidgets('your five from today, ${phone.name}', (tester) async {
      await _open(tester, phone, kDoneHead);
      await tester.tap(find.bySemanticsLabel('Card 3 of 5').last);
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('tab-Explore')));
      await _settle(tester);
      await _pictures(tester);
      await shoot(tester, 'explore-${phone.name}-dark');
      if (phone == _tall) {
        await tester.tap(find.byKey(const ValueKey('your-five')));
        await _settle(tester);
        await _pictures(tester);
        await shoot(tester, 'explore-opened-${phone.name}-dark');
      }
    });
  }
  testWidgets('your five from today, on paper', (tester) async {
    await _open(tester, _tall, kDoneHead, paper: true);
    await tester.tap(find.byKey(const ValueKey('tab-Explore')));
    await _settle(tester);
    await _pictures(tester);
    await shoot(tester, 'explore-390-light');
  });
}
