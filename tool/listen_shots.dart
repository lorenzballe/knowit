// Photographs Listen where it sits (lib/listen/), for the owner, with the
// server's switch on (`listen`): the entry at the end of Today's header
// while the five are read; the player reading a card on Astute+, at the
// pause to think; and on the free plan the moment after the free card, when
// the rest is offered. In Italian, at night, on a 390 by 844 phone. No
// sound and no server: the queue is silent and the clips made up.
//
//   SHOTS=/some/folder flutter test tool/listen_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/listen/listen_audio.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/sync/listen_client.dart';
import 'package:astuto/widgets/web/card_thumb.dart';

import '../test/explore/bets_host.dart' show loadBetsFonts;
import '../test/listen/silent_audio.dart';

/// The server's switch, on.
void _listenOn() => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'listen-shots',
      'app': {
        'flags': {'listen': true},
      },
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// A card's picture, from the site's own folder rather than the network.
ImageProvider _local(Uri url) {
  final String path = url.path.startsWith('/cards/')
      ? url.path.substring('/cards/'.length)
      : url.path;
  final File file = File('web/cards/$path');
  return MemoryImage(file.existsSync() ? file.readAsBytesSync() : Uint8List(0));
}

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

void _phone(WidgetTester tester, Size size) {
  const double ratio = 3;
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  const FakeViewPadding padding = FakeViewPadding(
    top: 47 * ratio,
    bottom: 34 * ratio,
  );
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
}

/// Five cards in words from five subjects, with questions short enough to
/// read at a glance: what a morning on Today looks like.
List<String> _five() {
  final List<String> out = [];
  for (final String topic in const [
    'Science',
    'History',
    'Psychology',
    'Space',
    'Economics',
  ]) {
    final Pill p = PillBank.live.firstWhere(
      (p) =>
          p.topic == topic &&
          p.web == null &&
          p.scene == null &&
          p.challenge is NoChallenge &&
          p.question.length < 80,
    );
    out.add(p.id);
  }
  return out;
}

Map<String, Object> _reading(List<String> deck, {required bool plus}) {
  final DateTime now = DateTime.now();
  String back(int days) =>
      dateKey(DateTime(now.year, now.month, now.day - days));
  return {
    'knowit.onboarded': true,
    'knowit.plus': plus,
    'knowit.theme': 'dark',
    'knowit.pushAsked': true,
    'knowit.widgetAsked': true,
    'knowit.accountOffered': true,
    'knowit.reviewAsked': true,
    'knowit.goalAsked': true,
    'knowit.placeAsks': 9,
    'knowit.todayDate': back(0),
    'knowit.todayDeckIds': deck,
    'knowit.todayIndex': 0,
    'knowit.streak': 4,
    'knowit.bestStreak': 4,
    'knowit.lastCompletionDate': back(1),
    'knowit.completedDates': [for (int d = 4; d >= 1; d--) back(d)],
    'knowit.seenIds': [deck.first],
    'knowit.pillsRead': 30,
  };
}

void main() {
  late SilentListenAudio audio;

  setUpAll(() async {
    await loadBetsFonts();
    CardThumb.image = _local;
  });

  setUp(() {
    _listenOn();
    audio = SilentListenAudio();
    ListenAudio.make = () => audio;
    // ignore: invalid_use_of_visible_for_testing_member
    ListenClient.resetForTest();
    ListenClient.reachable = () => true;
    ListenClient.call = (card, {required date, required tz}) async =>
        ListenClips(
          question: Uri.parse('https://clips.test/$card-q.mp3'),
          answer: Uri.parse('https://clips.test/$card-a.mp3'),
        );
  });

  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
    // ignore: invalid_use_of_visible_for_testing_member
    ListenClient.resetForTest();
    ListenAudio.make = JustAudioListen.new;
  });

  final String out = Platform.environment['SHOTS'] ?? 'tool/shots/listen';

  Future<void> open(WidgetTester tester, {required bool plus}) async {
    _phone(tester, const Size(390, 844));
    const Locale locale = Locale('it');
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(_reading(_five(), plus: plus));
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester);
  }

  testWidgets('the entry on Today', (tester) async {
    await open(tester, plus: false);
    expect(find.byKey(const ValueKey('listen-entry')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AstutoApp),
      matchesGoldenFile('$out/1-today.png'),
    );
  });

  testWidgets('the player, reading the second card', (tester) async {
    await open(tester, plus: true);
    await tester.tap(find.byKey(const ValueKey('listen-entry')));
    await _settle(tester);
    audio.finishCard();
    await _settle(tester, 4);
    // The question read, the pause to think a second in.
    audio.finish();
    audio.position = const Duration(milliseconds: 1500);
    audio.play();
    await _settle(tester, 6);
    expect(find.byKey(const ValueKey('listen-row-1-lit')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AstutoApp),
      matchesGoldenFile('$out/2-player.png'),
    );
  });

  testWidgets('after the free card, the rest offered', (tester) async {
    await open(tester, plus: false);
    await tester.tap(find.byKey(const ValueKey('listen-entry')));
    await _settle(tester);
    audio.finishCard();
    await _settle(tester, 6);
    expect(find.byKey(const ValueKey('listen-offer')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(AstutoApp),
      matchesGoldenFile('$out/3-offer.png'),
    );
  });
}
