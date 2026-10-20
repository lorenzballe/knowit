// Photographs the whole-screen blocks of Explore (docs/explore/screens.md):
// every block on its own, as `{"id": …, "block": …}` alone would draw it,
// each played into its other states, and every whole screen of rounds 140
// and 141 assembled from remote/examples/, under a stand-in for Explore's
// own head — on three phones, at night and on paper.
//
//   flutter test tool/screens_shots.dart --update-goldens
//
// A camera, not a check, so it lives outside test/ like the other shots.
// The pictures land in tool/shots/screens/, to be looked at and not kept.
// Each is the block's whole height at the phone's width, so a picture is
// everything the block draws, not the part of it a screen happens to show.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/themed_shelves.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/screens/memory.dart';
import 'package:astuto/explore/blocks/screens_blocks.dart' as screens;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/subject_icon.dart';

import '../test/explore/fake_host.dart';

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

/// The three phones every block is photographed on.
const Map<String, double> _phones = {'375': 375, '402': 402, '430': 430};

/// A host that deals what a section without a source of its own would be
/// dealt from: every card of the bank in an order fixed for the camera, so
/// the pictures are the same from one run to the next and every subject is
/// on them.
class _CameraHost extends FakeExploreHost {
  _CameraHost(super.app, {super.language});

  @override
  List<Pill> cardsFor(ExploreSection section, {int? limit}) {
    final Object? source = section.source;
    if (cards.containsKey(section.id) ||
        (source is Map && source['ids'] is List)) {
      return super.cardsFor(section, limit: limit);
    }
    final int most = limit ?? section.limit ?? 12;
    final List<Pill> pool =
        PillBank.cards
            .where((p) => subject == null || p.topic == subject)
            .toList()
          ..sort(
            (a, b) =>
                shelfHash('camera:${a.id}')
                    .compareTo(shelfHash('camera:${b.id}')),
          );
    return pool.take(most).toList();
  }
}

/// The blocks of the family, by name.
final Map<String, ExploreBlock> _blocks = {
  for (final ExploreBlock b in screens.blocks) b.name: b,
};

/// Explore's head as the canvas draws it over every screen — the title, the
/// search, the subject chips — drawn here only so a screen photographed is
/// a screen and not a list of blocks. The real one is the engine's.
class _StandInHead extends StatelessWidget {
  const _StandInHead();

  @override
  Widget build(BuildContext context) {
    final Palette p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).tabExplore,
                style: AppText.display(
                  size: 27,
                  weight: FontWeight.w600,
                  height: 1,
                  spacing: -0.8,
                  color: p.ink,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.ink.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: p.ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _chip(context, null, true),
              for (final String key in const [
                'economics',
                'sport',
                'nature',
                'science',
                'language',
              ])
                _chip(context, key, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String? key, bool on) {
    final Palette p = context.p;
    final TopicStyle? s = key == null ? null : kTopics[key];
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: on ? p.inverse : p.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s != null) ...[
                SubjectIcon(subject: s.name, size: 14, ink: s.color),
                const SizedBox(width: 8),
              ],
              Text(
                s == null
                    ? AppLocalizations.of(context).all
                    : AppLocalizations.of(context).subjectName(key!),
                style: AppText.body(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: on ? p.onInverse : p.ink.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sections of a screen in remote/examples/.
List<ExploreSection> _example(String name) {
  final Object? doc = jsonDecode(
    File('remote/examples/explore-$name.json').readAsStringSync(),
  );
  return [
    for (final Object? s in (doc as Map)['sections'] as List)
      ExploreSection.fromJson((s as Map).cast<String, Object?>()),
  ];
}

const ValueKey<String> _frame = ValueKey('screens-frame');

Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<ExploreSection> sections,
  required FakeExploreHost host,
  required double width,
  required bool paper,
  bool head = false,
  String language = 'en',
  double text = 1,
}) async {
  final view = tester.view;
  view.physicalSize = Size(width * 2, 7000 * 2);
  view.devicePixelRatio = 2;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAstutoTheme(paper ? Brightness.light : Brightness.dark),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(text)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: _frame,
                child: ColoredBox(
                  color: context.p.surface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Builder(
                      builder: (context) {
                        final List<Widget> built = [];
                        for (final ExploreSection s in sections) {
                          final Widget? w = _blocks[s.block]?.build(
                            context,
                            host,
                            s,
                          );
                          if (w == null) continue;
                          if (built.isNotEmpty) {
                            built.add(const SizedBox(height: 24));
                          }
                          built.add(w);
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (head) ...[
                              const _StandInHead(),
                              const SizedBox(height: 12),
                            ],
                            ...built,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  for (int f = 0; f < 10; f++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _shoot(WidgetTester tester, String path) => expectLater(
  find.byKey(_frame),
  matchesGoldenFile('shots/screens/$path.png'),
);

Future<void> _settle(WidgetTester tester) async {
  for (int f = 0; f < 10; f++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  setUpAll(_loadFonts);

  late AppState app;

  Future<void> fresh(Map<String, Object> stored) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'knowit.onboarded': true,
      ...stored,
    });
    // ignore: invalid_use_of_visible_for_testing_member
    ScreensMemory.resetForTest();
    app = AppState();
    await app.init();
    await ScreensMemory.instance.ready();
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });

  // Every block alone, as the bare section draws it.
  for (final String name in _blocks.keys) {
    for (final MapEntry<String, double> phone in _phones.entries) {
      for (final bool paper in [false, true]) {
        testWidgets('$name on ${phone.key}${paper ? ' paper' : ''}', (
          tester,
        ) async {
          await fresh({
            if (name == 'questions-asked')
              'knowit.explore.screens.asked': jsonEncode([
                {'q': 'Why does the same coffee taste so different?'},
                {
                  'q': 'Are blind auditions really fairer?',
                  'c': 'music-classical-1',
                },
                {
                  'q': 'Is a 99% accurate test good news?',
                  'c': 'medicine-false-positives-1',
                },
              ]),
          });
          final List<ExploreSection> sections = name == 'keep-asking'
              ? _example('keep-asking')
              : [
                  ExploreSection(
                    id: name,
                    block: name,
                    json: {'id': name, 'block': name},
                  ),
                ];
          await _pumpScreen(
            tester,
            sections: sections,
            host: _CameraHost(app),
            width: phone.value,
            paper: paper,
          );
          await _shoot(
            tester,
            'block/$name-${phone.key}${paper ? '-paper' : ''}',
          );
        });
      }
    }
  }

  // Every whole screen, from its example, under Explore's head.
  for (final String screen in const [
    'expert',
    'connect-dots',
    'ask-first',
    'keep-asking',
    'through-time',
    'change-your-mind',
    'say-it-tonight',
    'front-page',
  ]) {
    for (final MapEntry<String, double> phone in _phones.entries) {
      for (final bool paper in [false, true]) {
        testWidgets('screen $screen on ${phone.key}${paper ? ' paper' : ''}', (
          tester,
        ) async {
          await fresh({});
          await _pumpScreen(
            tester,
            sections: _example(screen),
            host: _CameraHost(app),
            width: phone.value,
            paper: paper,
            head: screen != 'front-page',
          );
          await _shoot(
            tester,
            'screen/$screen-${phone.key}${paper ? '-paper' : ''}',
          );
        });
      }
    }
  }

  // The states a reader plays them into, at the canvas's width.
  testWidgets('played: an expert picked', (tester) async {
    await fresh({});
    await _pumpScreen(
      tester,
      sections: _example('expert'),
      host: _CameraHost(app),
      width: 402,
      paper: false,
      head: true,
    );
    await tester.tap(find.byKey(const ValueKey('expert-historian-off')));
    await _settle(tester);
    await _shoot(tester, 'played/expert-historian');
  });

  testWidgets('played: a why, then the bottom', (tester) async {
    await fresh({});
    await _pumpScreen(
      tester,
      sections: _example('keep-asking'),
      host: _CameraHost(app),
      width: 402,
      paper: false,
      head: true,
    );
    await tester.tap(find.byKey(const ValueKey('why-ask-sky')));
    await _settle(tester);
    await _shoot(tester, 'played/whys-two');
    await tester.tap(find.byKey(const ValueKey('why-ask-sky')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('why-ask-sky')));
    await _settle(tester);
    await _shoot(tester, 'played/whys-bottom');
  });

  testWidgets('played: a question asked, and one kept', (tester) async {
    await fresh({});
    await _pumpScreen(
      tester,
      sections: _example('ask-first'),
      host: _CameraHost(app),
      width: 402,
      paper: false,
      head: false,
    );
    await tester.enterText(
      find.byKey(const ValueKey('ask-field-ask')),
      'Why do onions make you cry?',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    await _shoot(tester, 'played/ask-found');
    await tester.enterText(
      find.byKey(const ValueKey('ask-field-ask')),
      'Why do cats purr when they are hurt?',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('ask-keep-ask')));
    await _settle(tester);
    await _shoot(tester, 'played/ask-kept');
  });

  testWidgets('played: the ruler travelled', (tester) async {
    await fresh({});
    await _pumpScreen(
      tester,
      sections: _example('through-time'),
      host: _CameraHost(app),
      width: 402,
      paper: false,
      head: true,
    );
    for (int i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('time-on')));
      await _settle(tester);
    }
    await _shoot(tester, 'played/time-ancient');
    for (int i = 0; i < 9; i++) {
      await tester.tap(find.byKey(const ValueKey('time-back')));
      await _settle(tester);
    }
    await _shoot(tester, 'played/time-first-light');
  });

  testWidgets('played: a mind changed', (tester) async {
    await fresh({});
    await _pumpScreen(
      tester,
      sections: _example('change-your-mind'),
      host: _CameraHost(app),
      width: 402,
      paper: false,
      head: true,
    );
    await tester.tap(
      find.byKey(const ValueKey('mind-before-science-cold-myths-1-3')),
    );
    await _settle(tester);
    await _shoot(tester, 'played/mind-before');
    await tester.tap(
      find.byKey(const ValueKey('mind-after-science-cold-myths-1-0')),
    );
    await _settle(tester);
    await _shoot(tester, 'played/mind-after');
  });

  testWidgets('played: a line said', (tester) async {
    await fresh({});
    await _pumpScreen(
      tester,
      sections: _example('say-it-tonight'),
      host: _CameraHost(app),
      width: 402,
      paper: false,
      head: true,
    );
    await tester.tap(find.byKey(const ValueKey('say-cinema-destroyed-4-not')));
    await _settle(tester);
    await _shoot(tester, 'played/say-said');
  });

  // Large text and a small phone: where a block runs out of room first.
  for (final String screen in const [
    'expert',
    'connect-dots',
    'ask-first',
    'keep-asking',
    'through-time',
    'change-your-mind',
    'say-it-tonight',
    'front-page',
  ]) {
    testWidgets('screen $screen at large text on 375', (tester) async {
      await fresh({});
      await _pumpScreen(
        tester,
        sections: _example(screen),
        host: _CameraHost(app),
        width: 375,
        paper: false,
        text: 1.35,
      );
      await _shoot(tester, 'large/$screen-375');
    });
  }

  // The longest of the languages set in the faces the camera has: the
  // words of the app in the reader's language, the section's own in it
  // where it gives them and in English where it does not.
  for (final String screen in const [
    'expert',
    'connect-dots',
    'ask-first',
    'keep-asking',
    'through-time',
    'change-your-mind',
    'say-it-tonight',
    'front-page',
  ]) {
    for (final String language in const ['de', 'fr', 'it']) {
      testWidgets('screen $screen in $language on 375', (tester) async {
        await fresh({});
        await _pumpScreen(
          tester,
          sections: _example(screen),
          host: _CameraHost(app, language: language),
          width: 375,
          paper: false,
          head: screen != 'front-page',
          language: language,
        );
        await _shoot(tester, 'language/$screen-$language');
      });
    }
  }
}
