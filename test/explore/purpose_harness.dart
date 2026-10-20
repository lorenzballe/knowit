// What the purpose family's tests share: a reader a few weeks in, a page
// with nothing on it but one block, and the block's sizes as the server
// names them.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/purpose/kit.dart' show purposeClock;
import 'package:astuto/explore/blocks/purpose_blocks.dart' as purpose;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';

/// Every block's sizes, as the server names them; none for a block with
/// one size only (tool/remote/parts/explore_blocks/purpose.py, SIZES).
const Map<String, List<String>> kPurposeSizes = {
  'purpose.read-or-do': ['s', 'm', 'l'],
  'purpose.commit-note': [],
  'purpose.commit': ['s', 'm', 'l'],
  'purpose.move': ['s', 'm', 'l'],
  'purpose.step-above': ['s', 'm', 'l'],
  'purpose.thin-subject': ['s', 'm', 'l'],
  'purpose.other-side': ['s', 'm', 'l'],
  'purpose.in-your-head': ['s', 'm', 'l'],
  'purpose.seen': ['s', 'm', 'l'],
  'purpose.mechanism': ['s', 'm', 'l'],
  'purpose.curious': ['s', 'm', 'l'],
  'purpose.moving': ['s', 'm', 'l'],
  'purpose.why': ['s', 'm', 'l'],
  'purpose.thats-me': ['s', 'm', 'l'],
  'purpose.about-you': ['s', 'm', 'l'],
  'purpose.headline': ['s', 'm', 'l'],
  'purpose.out-of-what': ['s', 'm', 'l'],
  'purpose.price-tag': ['s', 'm', 'l'],
  'purpose.argument': ['s', 'm', 'l'],
  'purpose.keep': [],
  'purpose.life-question': ['s', 'm', 'wide', 'l'],
  'purpose.life-topics': ['s', 'm', 'l'],
  'purpose.spot-trick': ['s', 'm', 'l'],
  'purpose.played': [],
  'purpose.set': ['s', 'm', 'l'],
  'purpose.stamps': ['s', 'm', 'l'],
  'purpose.sets': [],
  'purpose.tomorrow': [],
  'purpose.end': [],
};

/// The blocks that say something of their own and show no cards: they are
/// drawn whatever the host hands them.
const Set<String> kWordsOnly = {
  'purpose.commit-note',
  'purpose.keep',
  'purpose.end',
};

/// The block named [name].
ExploreBlock purposeBlock(String name) =>
    purpose.blocks.firstWhere((b) => b.name == name);

/// The cards this reader has read: every ninth of the bank.
List<Pill> readCards() => [
  for (int i = 0; i < PillBank.cards.length; i += 9) PillBank.cards[i],
];

/// The first debates of the bank, which this reader took a side on: the
/// first No, the second Yes, and so on.
List<Pill> takenDebates() =>
    PillBank.cards.where((p) => p.challenge is TakeASide).take(6).toList();

/// A reader a few weeks in: cards read, debates taken. Run it with
/// `tester.runAsync`.
Future<AppState> purposeReader() async {
  final List<Pill> debates = takenDebates();
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.seenIds': [
      for (final Pill p in readCards()) p.id,
      for (final Pill p in debates) p.id,
    ],
    'knowit.answersJson': jsonEncode({
      for (int i = 0; i < debates.length; i++) debates[i].id: {'r': '${i % 2}'},
    }),
  });
  ExplorePlay.resetForTest();
  // The shelves turn with the day: the tests read them on one day, the
  // 19th of October 2026, whose turn holds cards to read and cards to do.
  purposeClock = () => DateTime(2026, 10, 19, 12);
  final AppState app = AppState();
  await app.init();
  return app;
}

/// A section of [block], with [fields].
ExploreSection purposeSection(
  String block, [
  Map<String, Object?> fields = const {},
]) => ExploreSection.fromJson({'id': 'x', 'block': block, ...fields});

/// What a block built for a section: the widget, or null.
class Built {
  Widget? widget;
}

/// Puts [block] drawing [section] on a page of its own, [width] wide, at
/// night or on paper and at the reader's text size [scale], and says what
/// the block built.
Future<Built> pumpPurpose(
  WidgetTester tester,
  ExploreBlock block,
  ExploreHost host,
  ExploreSection section, {
  bool dark = true,
  double width = 402,
  double scale = 1,
}) async {
  final Built built = Built();
  await tester.binding.setSurfaceSize(Size(width, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(host.language),
      theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 2400),
          textScaler: TextScaler.linear(scale),
        ),
        child: Builder(
          builder: (context) => Material(
            color: context.p.surface,
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  built.widget = block.build(context, host, section);
                  return built.widget ?? const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return built;
}

/// The widgets keyed with a string that [test] holds for.
Finder keyedLike(bool Function(String key) test) => find.byWidgetPredicate(
  (w) => w.key is ValueKey<String> && test((w.key! as ValueKey<String>).value),
);

/// The first card a block drew, by the key every card's tap carries.
Finder firstCard() => keyedLike((k) => k.startsWith('explore-')).first;

/// Taps a card's head, top left, where nothing on the card but the card
/// itself answers a tap.
Future<void> tapCard(WidgetTester tester, Finder card) async {
  await tester.tapAt(tester.getTopLeft(card) + const Offset(24, 18));
  await tester.pump(const Duration(milliseconds: 200));
}
