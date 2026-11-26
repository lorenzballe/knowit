// Photographs the foot of a card's back being tried (lib/widgets/source_foot.dart)
// on Today, on a medium phone in the dark, on Astute+: a card in words
// answered and turned over, a drawn card answered on its page, where "Report
// a problem" lives with that foot, and where Why this card does.
//
//   flutter test tool/source_shots.dart --dart-define=SOURCE_FOOT=line \
//     --update-goldens
//
// once for each of line, stack and pill. A drawn card cannot draw its page
// here, where there is no WebView: its page is a photograph in the page's
// place (FakeWebSurface's face), taken by tool/cards/card_check.cjs with
// BARE=1 on a kit that draws the same foot, and named <card>-<foot>.png in
// PAGE_SHOTS. The page says `deeper` as it does when its source is tapped,
// and Go deeper opens from it as it would on a phone.
//
// A camera, not a check: it lives outside test/ so CI never runs it. SHOTS
// (a folder) and LANG_SHOT (a language, Italian by default) move it.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/card_page_store_base.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/main.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/widgets/pill_card.dart';
import 'package:astuto/widgets/source_foot.dart';
import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/fake_web_surface.dart';
import 'package:astuto/widgets/web/page_messages.dart';
import 'package:astuto/widgets/web/web_surface.dart';

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

/// The kit, put together at once: the page is a photograph here, so what
/// the kit would put inside it does not matter.
class _InstantKit extends CardKit {
  @override
  Future<String> page(String html, PageEnv env) => Future.value(html);
}

/// The card in words: a question about stars, answered wrong and turned.
const String _native = 'space-star-death-1';

/// The drawn card: a page whose source is a Geopop video, 2021, the line
/// the owner quoted.
const String _drawn = 'history-vajont-four-minutes';

/// The medium phone, its insets an iPhone's of that size.
const Size _phone = Size(390, 844);
const EdgeInsets _insets = EdgeInsets.only(top: 47, bottom: 34);

/// Two pixels a point: the page's photograph is taken at two.
const double _ratio = 2;

Future<void> _settle(WidgetTester tester, [int frames = 14]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// Every picture on screen, decoded before the photograph, in real time.
Future<void> _decodeShown(WidgetTester tester) async {
  final Set<ImageProvider> shown = {
    for (final Image image in tester.widgetList<Image>(find.byType(Image)))
      image.image,
  };
  if (shown.isEmpty) return;
  final BuildContext context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final ImageProvider p in shown) {
      await precacheImage(
        p,
        context,
        onError: (_, _) {},
      ).timeout(const Duration(seconds: 10), onTimeout: () {});
    }
  });
  await _settle(tester, 5);
}

void main() {
  final String out = Platform.environment['SHOTS'] ?? 'shots/source';
  final String lang = Platform.environment['LANG_SHOT'] ?? 'it';
  final String pages =
      Platform.environment['PAGE_SHOTS'] ?? 'shots/source/pages';
  final String foot = sourceFoot.name;

  setUpAll(() async {
    await _loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
  });

  Pill card(String id) => PillBank.cards.firstWhere((p) => p.id == id);

  /// Today, on the phone, with [first] on top of the day's five.
  Future<void> today(WidgetTester tester, String first) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final view = tester.view;
    view.physicalSize = _phone * _ratio;
    view.devicePixelRatio = _ratio;
    view.padding = FakeViewPadding(
      top: _insets.top * _ratio,
      bottom: _insets.bottom * _ratio,
    );
    view.viewPadding = view.padding;
    tester.platformDispatcher.localesTestValue = [Locale(lang)];
    tester.platformDispatcher.localeTestValue = Locale(lang);
    addTearDown(() {
      view.reset();
      tester.platformDispatcher.clearLocalesTestValue();
      tester.platformDispatcher.clearLocaleTestValue();
    });
    final List<String> deck = [
      first,
      ...pickedPills(
        seed: 'shot',
        count: 6,
      ).map((p) => p.id).where((id) => id != _native && id != _drawn).take(4),
    ];
    // On Astute+, where every card of the day is the reader's own and most
    // are dealt at their level: the cards that lost their line.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      'knowit.plus': true,
      'knowit.todayDate': dateKey(DateTime.now()),
      'knowit.todayDeckIds': deck,
      'knowit.todayIndex': 0,
    });
    await tester.pumpWidget(const AstutoApp());
    await _settle(tester, 20);
  }

  Future<void> shoot(WidgetTester tester, String name) async {
    await _decodeShown(tester);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('$out/$name-$foot.png'),
    );
  }

  /// The drawn card's page in place: its photograph with this foot.
  void drawnPage() {
    final File photo = File('$pages/$_drawn-$foot.png');
    final ImageProvider picture = MemoryImage(photo.readAsBytesSync());
    final String html = File('tool/cards/bank/history/$_drawn.html')
        .readAsStringSync();
    CardKit.instance = _InstantKit();
    CardPages.instance = CardPages(
      fetch: (url) async => html,
      store: MemoryPageStore(),
    );
    FakeWebSurface.reset();
    // ignore: invalid_use_of_visible_for_testing_member
    WebSurfaces.debugUse(
      () => FakeWebSurface(
        face: (_) => Image(image: picture, fit: BoxFit.fill),
      ),
    );
  }

  tearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    WebSurfaces.debugUse(null);
    CardKit.instance = CardKit();
    debugDefaultTargetPlatformOverride = null;
  });

  /// The card in words answered wrong, how sure said, and turned over.
  Future<void> answer(WidgetTester tester, Pill pill) async {
    final PickOne pick = pill.challenge as PickOne;
    await tester.tap(
      find.text(pick.options[(pick.correct + 1) % pick.options.length]),
    );
    await _settle(tester, 8);
    final Finder sure = find.text('70%');
    if (sure.evaluate().isNotEmpty) {
      await tester.tap(sure.first);
      await _settle(tester, 20);
    }
    final Finder foot = find.byKey(ValueKey('card-foot-${pill.id}'));
    if (foot.evaluate().isEmpty) {
      await tester.tap(find.byType(PillCard).last);
      await _settle(tester, 20);
    }
    expect(foot, findsOneWidget);
  }

  testWidgets('a card in words, answered and turned', (tester) async {
    final Pill pill = card(_native);
    await today(tester, pill.id);
    await answer(tester, pill);
    await shoot(tester, 'native');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a drawn card, answered on its page', (tester) async {
    drawnPage();
    await today(tester, _drawn);
    await _settle(tester, 10);
    await shoot(tester, 'drawn');
    debugDefaultTargetPlatformOverride = null;
  });

  // Why this card: from the foot of the back, beside Go deeper; or, where
  // the foot being tried says it on the front, the line under the head that
  // every card carries again, as this card, dealt at its reader's level,
  // carried none.
  testWidgets('where Why this card lives', (tester) async {
    final Pill pill = card(_native);
    await today(tester, pill.id);
    if (sourceFoot == SourceFoot.stack) {
      expect(find.byKey(const ValueKey('card-note')), findsWidgets);
      await shoot(tester, 'why');
    } else {
      await answer(tester, pill);
      await tester.tap(find.byKey(ValueKey('card-why-${pill.id}')));
      await _settle(tester, 20);
      expect(find.byKey(const ValueKey('why-sheet')), findsOneWidget);
      await shoot(tester, 'why');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('where Report lives', (tester) async {
    drawnPage();
    await today(tester, _drawn);
    await _settle(tester, 10);
    final FakeWebSurface page = FakeWebSurface.made.firstWhere(
      (s) => (s.html ?? '').contains('Vajont'),
    );
    switch (sourceFoot) {
      // The page's source tapped: Go deeper, and under its source the line
      // to report the card.
      case SourceFoot.line:
        page.say(const PageDeeper());
        await _settle(tester, 30);
        await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey('deeper-report'))),
          alignment: 0.62,
        );
        await _settle(tester, 10);
      // The card's share: the sheet, with the line to report at its foot.
      case SourceFoot.stack:
        await tester.tap(
          find.byIcon(Icons.ios_share_rounded).hitTestable().first,
        );
        await _settle(tester, 20);
        await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey('share-report'))),
          alignment: 1,
        );
        await _settle(tester, 10);
      // The page's source tapped: Go deeper, the flag beside its name.
      case SourceFoot.pill:
        page.say(const PageDeeper());
        await _settle(tester, 30);
    }
    await shoot(tester, 'report');
    debugDefaultTargetPlatformOverride = null;
  });
}
