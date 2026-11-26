// Photographs Explore's two-column grid of a subject (the feed a subject's
// page ends on) and the mix fine-tuned, as a 390 by 844 phone shows them at
// night: the grid for a few subjects, in English and in Italian, with the
// room each card leaves under its question written beside each picture;
// the fine-tuning at the top, scrolled, and its hint that holding a part
// opens what is inside.
//
//   flutter test tool/gridmix_shots.dart --update-goldens \
//     --dart-define=GRIDMIX_DIR=/some/folder --dart-define=GRIDMIX_LABEL=now
//
// A camera, not a check: it lives outside test/ so CI never runs it. The
// pictures land in tool/shots/gridmix/ unless GRIDMIX_DIR says otherwise,
// to be looked at and not kept.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/core/feed_block.dart';
import 'package:astuto/explore/blocks/shapes/tile.dart' show ShapeTile;
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/tune_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/served.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/explore/card_tiles.dart';
import 'package:astuto/widgets/explore/explore_engine.dart';
import 'package:astuto/widgets/scaled_text.dart';

import '../test/explore/core_harness.dart';

const String _dir = String.fromEnvironment(
  'GRIDMIX_DIR',
  defaultValue: 'tool/shots/gridmix',
);
const String _label = String.fromEnvironment(
  'GRIDMIX_LABEL',
  defaultValue: 'now',
);

const Size _phone = Size(390, 844);
const EdgeInsets _insets = EdgeInsets.only(top: 47, bottom: 34);

Uri _out(String name) =>
    Uri.file(File('$_dir/$_label/$name.png').absolute.path);

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

void _phoneOf(WidgetTester tester, {Size size = _phone}) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(
    top: _insets.top * 3,
    bottom: _insets.bottom * 3,
  );
  tester.view.viewPadding = tester.view.padding;
  addTearDown(tester.view.reset);
}

/// The feed, as a subject's page ends on it.
Map<String, Object?> _feed(String id) => {
  'id': id,
  'block': 'feed',
  'title': {'en': 'Keep exploring', 'it': 'Continua a esplorare'},
  'subtitle': {
    'en': 'The same for everyone. Nothing here is picked for you.',
    'it': 'Uguale per tutti. Niente qui è scelto per te.',
  },
};

/// The bands on screen: the shape drawn for each by lot, and the one it was
/// laid in.
String _shapes(WidgetTester tester) => [
  for (final FeedBand band in tester.widgetList<FeedBand>(
    find.byType(FeedBand),
  ))
    '  band ${band.index}: drawn ${band.deal.pattern.shapeAt(band.index).name}'
        ', laid ${band.band.shape.name}'
        '${band.band.clean ? '' : ' (not clean)'}',
].join('\n');

/// Every card on screen with the room its question leaves under it, worst
/// first: what a picture is judged by besides the eye.
String _room(WidgetTester tester) {
  final List<String> lines = [];
  final double top = 0, bottom = _phone.height;
  for (final Element e in [
    ...find.byType(BoxTile).evaluate(),
    ...find.byType(ShapeTile).evaluate(),
  ]) {
    final Pill pill = switch (e.widget) {
      final BoxTile tile => tile.pill,
      final ShapeTile tile => tile.pill,
      _ => throw StateError('not a tile'),
    };
    final Finder at = find.byElementPredicate((x) => x == e);
    final Rect box = tester.getRect(at);
    if (box.bottom < top || box.top > bottom) continue;
    final Finder scaled = find.descendant(
      of: at,
      matching: find.byType(ScaledText),
    );
    if (scaled.evaluate().isEmpty) continue;
    final Size room = tester.getSize(scaled.first);
    final Finder text = find.descendant(
      of: scaled.first,
      matching: find.byType(RichText),
    );
    final Size set = tester.getSize(text.first);
    final double size =
        (tester.widget<RichText>(text.first).text as TextSpan).style!.fontSize!;
    final double empty = room.height - set.height;
    lines.add(
      '${(empty / box.height * 100).round().toString().padLeft(3)}% '
      '${empty.round().toString().padLeft(3)}pt empty  '
      '${box.width.round()}x${box.height.round()}  '
      '${size.toStringAsFixed(1)}pt  ${pill.question.length}c  '
      '${pill.question}',
    );
  }
  lines.sort((a, b) => b.compareTo(a));
  return lines.join('\n');
}

Future<void> _feedPage(
  WidgetTester tester, {
  required String subject,
  String language = 'en',
  List<Pill>? first,
  String name = '',
  int screens = 3,
  List<Map<String, Object?>>? sections,
  Map<String, List<Pill>> given = const {},
  String kind = 'grid',
}) async {
  _phoneOf(tester);
  final AppState app = await readyApp();
  // A shelf a section names keeps to its own subject; the feed, to the
  // subject in view.
  final CoreHost host = CoreHost(
    app,
    language: language,
    subject: sections == null ? subject : null,
  );
  const String id = 'feed';
  host.cards.addAll(given);
  if (first != null) {
    final Set<String> given = {for (final Pill p in first) p.id};
    host.cards[id] = [
      ...first,
      ...PillBank.cards.where(
        (p) => p.topic == subject && !given.contains(p.id),
      ),
    ];
  }
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildAstutoTheme(Brightness.dark),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.p.surface,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ExploreSliver(
                  host: host,
                  slots: exploreSlots(
                    context,
                    host,
                    sectionsOf(sections ?? [_feed(id)]),
                    host.app.remoteContext(host.language),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  final ScrollableState list = tester.state(
    find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  final String base =
      '$kind-${subject.toLowerCase().replaceAll(' ', '-')}-$language'
      '${name.isEmpty ? '' : '-$name'}';
  final StringBuffer report = StringBuffer();
  for (int i = 0; i < screens; i++) {
    final String shot = '$base-${i + 1}';
    report.writeln('== $shot');
    report.writeln(_room(tester));
    report.writeln(_shapes(tester));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(_out(shot)));
    list.position.jumpTo(list.position.pixels + _phone.height * 0.8);
    await _settle(tester, 4);
  }
  final File file = File('$_dir/$_label/$base.txt');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(report.toString());
}

Pill _asking(String text) =>
    PillBank.cards.firstWhere((p) => p.question.startsWith(text));

void main() {
  setUpAll(() async {
    await loadFonts();
    Remote.fetch = (_) async => null;
  });
  // ignore: invalid_use_of_visible_for_testing_member
  setUp(() => Served.useForTest(Served()));

  testWidgets('grid: Science, the owner\'s three first', (tester) async {
    await _feedPage(
      tester,
      subject: 'Science',
      name: 'owner',
      first: [
        _asking('A weighted guitar string sinks through ice'),
        _asking('What does the vertical axis of a raw seismic section'),
        _asking('Why does a grape in a microwave produce plasma'),
      ],
    );
  });

  for (final (String subject, String language) in [
    ('Science', 'en'),
    ('Science', 'it'),
    ('History', 'en'),
    ('Psychology', 'en'),
    ('Space', 'it'),
  ]) {
    testWidgets('grid: $subject in $language', (tester) async {
      await _feedPage(tester, subject: subject, language: language);
    });
  }

  /// The fine-tuning on a phone, [hinted] if the hint that holding a part
  /// opens it was shown before; the page's list, to scroll.
  Future<ScrollableState> tune(
    WidgetTester tester,
    String language, {
    required bool hinted,
  }) async {
    _phoneOf(tester);
    final AppState app = await readyApp({
      if (hinted) 'knowit.tuneHoldHint': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: TuneScreen(app: app, picked: app.pickedTopics),
      ),
    );
    // The bars come in one after another: all of them in.
    await _settle(tester, 16);
    return tester.state(
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }

  Future<void> take(WidgetTester tester, String name) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(_out(name)));

  // The other masonry, a shelf a section can name: a month of one subject,
  // each card as tall as its question, the mark behind the tall ones.
  testWidgets('masonry: a month of Science and of History', (tester) async {
    await _feedPage(
      tester,
      subject: 'Science',
      kind: 'masonry',
      screens: 2,
      given: {
        for (final (String id, String topic) in [
          ('month', 'Science'),
          ('month-mark', 'History'),
        ])
          id: PillBank.cards.where((p) => p.topic == topic).skip(40).toList(),
      },
      sections: [
        {
          'id': 'month',
          'block': 'shape-masonry',
          'subject': 'science',
          'limit': 8,
        },
        {
          'id': 'month-mark',
          'block': 'shape-masonry',
          'subject': 'history',
          'limit': 6,
          'signature': 'mark',
        },
      ],
    );
  });

  for (final String language in ['en', 'it']) {
    testWidgets('tune your mix: $language', (tester) async {
      final ScrollableState list = await tune(tester, language, hinted: true);
      await take(tester, 'tune-$language-top');
      // A little way down: the title gone up with the page, the way back
      // where it was, the page fading under it.
      list.position.jumpTo(36);
      await _settle(tester, 4);
      await take(tester, 'tune-$language-scrolled-a-little');
      list.position.jumpTo(420);
      await _settle(tester, 4);
      await take(tester, 'tune-$language-scrolled');
      // To the foot: as far as the page goes once all of it is laid out,
      // which a list built as it comes into view only learns on the way.
      for (int i = 0; i < 40; i++) {
        if (i > 0 &&
            (list.position.pixels - list.position.maxScrollExtent).abs() <
                0.5) {
          break;
        }
        list.position.jumpTo(list.position.maxScrollExtent);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await _settle(tester, 4);
      await take(tester, 'tune-$language-end');
    });

    testWidgets('tune your mix, the hint: $language', (tester) async {
      final ScrollableState list = await tune(tester, language, hinted: false);
      // Nothing is played while the parts are not all on screen.
      list.position.jumpTo(420);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await take(tester, 'tune-$language-hint-0-not-yet');
      // Come to rest with the first subject's parts whole on screen: the
      // hint plays, once.
      list.position.jumpTo(560);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      for (final (int ms, String frame) in [
        (450, '1-press'),
        (1250, '2-open'),
        (1450, '3-folding'),
      ]) {
        await tester.pump(Duration(milliseconds: ms));
        await take(tester, 'tune-$language-hint-$frame');
      }
      await tester.pump(const Duration(milliseconds: 1500));
      await take(tester, 'tune-$language-hint-4-done');
    });
  }

  testWidgets('tune your mix, the hint still: en', (tester) async {
    _phoneOf(tester);
    final AppState app = await readyApp();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: TuneScreen(app: app, picked: app.pickedTopics),
          ),
        ),
      ),
    );
    await _settle(tester, 16);
    final ScrollableState list = tester.state(
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    list.position.jumpTo(560);
    await _settle(tester, 4);
    await take(tester, 'tune-en-hint-still');
  });
}
