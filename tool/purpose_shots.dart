// Photographs the purpose family's blocks (docs/explore/purpose.md) on
// their own, the way Explore will draw them: every block at each of its
// sizes and in the states a reader leaves it in, on three phones, at night
// and on paper, and once more at the narrowest with the text a size up.
//
//   flutter test tool/purpose_shots.dart --update-goldens
//   flutter test tool/purpose_shots.dart --update-goldens --dart-define=ONLY=purpose.why
//
// It lives outside test/ so it never runs in CI: this is a camera, not a
// check. The pictures land in tool/shots/gallery/purpose/ (gitignored), to
// be looked at beside the canvas's own designs rather than kept.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/explore_mix.dart' show percentOf;
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/themed_shelves.dart' show shelfHash;
import 'package:astuto/explore/blocks/purpose/kit.dart' show PurposePlay;
import 'package:astuto/explore/blocks/purpose_blocks.dart' as purpose;
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/state/explore_play.dart';
import 'package:astuto/theme.dart';

import '../test/explore/fake_host.dart';

/// One block, and what to photograph it with.
class _Spec {
  const _Spec(this.block, this.sections, {this.cards, this.adjust, this.play});

  final String block;

  /// What each picture is of — a size, a state — and the section for it.
  final Map<String, Map<String, Object?>> sections;

  /// The cards a section is handed, by label, when the bank's own order
  /// would not show the state photographed.
  final List<Pill>? Function(String label)? cards;

  /// The section as photographed, by label, for fields that name cards.
  final Map<String, Object?> Function(String label, Map<String, Object?> json)?
  adjust;

  /// Something done to the block before it is photographed, by label.
  final Future<void> Function(WidgetTester tester, String label)? play;
}

Map<String, Map<String, Object?>> _sizes(
  String block,
  List<String> sizes, [
  Map<String, Object?> extra = const {},
]) => {
  for (final String size in sizes)
    size: {'id': '$block-$size', 'block': block, 'size': size, ...extra},
};

Map<String, Object?> _one(
  String block, [
  Map<String, Object?> extra = const {},
]) => {'id': block, 'block': block, ...extra};

const List<String> _sml = ['s', 'm', 'l'];

/// The cards the reader of these pictures has read: every ninth of the
/// bank, as [_reader] sets them.
List<Pill> get _read => [
  for (int i = 0; i < PillBank.cards.length; i += 9) PillBank.cards[i],
];

/// Taps the [n]th widget of the private type [type].
Future<void> _tapType(WidgetTester tester, String type, [int n = 0]) async {
  final Finder found = find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == type,
  );
  await tester.tap(found.at(n), warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)).first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Taps the first widget whose key starts with [prefix] and ends with
/// [suffix].
Future<void> _tapLike(WidgetTester tester, String prefix, String suffix) async {
  final Finder found = find.byWidgetPredicate((w) {
    final Key? key = w.key;
    if (key is! ValueKey<String>) return false;
    return key.value.startsWith(prefix) && key.value.endsWith(suffix);
  });
  await tester.tap(found.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 200));
}

/// The blocks, as each is photographed.
final List<_Spec> _specs = [
  _Spec(
    'purpose.read-or-do',
    {
      ..._sizes('purpose.read-or-do', _sml),
      'one shelf': _one('purpose.read-or-do', {
        'shelves': [
          {'id': 'myths', 'theme': 'myths'},
        ],
      }),
      'to do': _one('purpose.read-or-do', {
        'style': {'shelves': 2},
      }),
    },
    play: (tester, label) async {
      if (label == 'to do') await _tapLike(tester, 'read-or-do-', '-2-off');
    },
  ),
  _Spec('purpose.commit-note', {'default': _one('purpose.commit-note')}),
  _Spec(
    'purpose.commit',
    {
      ..._sizes('purpose.commit', _sml),
      for (final String kind in ['true-false', 'side', 'pick'])
        kind: _one('purpose.commit', {'kind': kind}),
      'answered': _one('purpose.commit', {'kind': 'true-false'}),
    },
    play: (tester, label) async {
      if (label == 'answered') {
        await _tapType(tester, '_AnswerButton', 0);
        await _tapType(tester, '_AnswerButton', 3);
      }
    },
  ),
  _Spec('purpose.move', {
    ..._sizes('purpose.move', _sml),
    'named': _one('purpose.move', {'move': 'survivorship'}),
  }),
  _Spec('purpose.step-above', _sizes('purpose.step-above', _sml)),
  _Spec('purpose.thin-subject', _sizes('purpose.thin-subject', _sml)),
  _Spec('purpose.other-side', _sizes('purpose.other-side', _sml)),
  _Spec(
    'purpose.in-your-head',
    {
      ..._sizes('purpose.in-your-head', _sml),
      'answered': _one('purpose.in-your-head'),
      'typing': _one('purpose.in-your-head'),
    },
    play: (tester, label) async {
      if (label != 'answered' && label != 'typing') return;
      await _tapLike(tester, 'head-box-', '');
      final Finder field = find.byWidgetPredicate((w) {
        final Key? key = w.key;
        return key is ValueKey<String> && key.value.startsWith('head-field-');
      });
      await tester.enterText(field.first, '42');
      await tester.pump(const Duration(milliseconds: 200));
      if (label == 'answered') await _tapLike(tester, 'head-send-', '');
    },
  ),
  _Spec('purpose.seen', _sizes('purpose.seen', _sml)),
  _Spec('purpose.mechanism', _sizes('purpose.mechanism', _sml)),
  _Spec('purpose.curious', _sizes('purpose.curious', _sml)),
  _Spec(
    'purpose.moving',
    {..._sizes('purpose.moving', _sml), 'updated': _one('purpose.moving')},
    adjust: (label, json) {
      if (label != 'updated') return json;
      final List<Pill> moving = PillBank.cards
          .where((p) => p.shelfLife == 'years' || p.shelfLife == 'months')
          .take(3)
          .toList();
      return {
        ...json,
        'updated': {
          for (int i = 0; i < moving.length; i++)
            moving[i].id: '2026-10-0${i + 2}',
        },
      };
    },
  ),
  _Spec('purpose.why', _sizes('purpose.why', _sml)),
  _Spec(
    'purpose.thats-me',
    {..._sizes('purpose.thats-me', _sml), 'marked': _one('purpose.thats-me')},
    play: (tester, label) async {
      if (label == 'marked') {
        await _tapType(tester, '_MarkButton', 0);
        await _tapType(tester, '_MarkButton', 2);
      }
    },
  ),
  _Spec('purpose.about-you', _sizes('purpose.about-you', _sml)),
  _Spec('purpose.headline', _sizes('purpose.headline', _sml)),
  _Spec('purpose.out-of-what', _sizes('purpose.out-of-what', _sml)),
  _Spec('purpose.price-tag', _sizes('purpose.price-tag', _sml)),
  _Spec('purpose.argument', _sizes('purpose.argument', _sml)),
  _Spec('purpose.keep', {
    'default': _one('purpose.keep'),
    'five moves': _one('purpose.keep', {
      'moves': [
        'baseRate',
        'survivorship',
        'regression',
        'confirmation',
        'anchoring',
      ],
    }),
    'items': _one('purpose.keep', {
      'heading': {'en': 'Two things to ask any chart'},
      'items': [
        {
          'ask': {'en': 'Where does the axis start?'},
          'line': {'en': 'A bar cut off at the bottom shouts'},
        },
        {
          'ask': {'en': 'Per what?'},
          'line': {'en': 'A total grows with the people counted'},
        },
      ],
    }),
  }),
  _Spec('purpose.life-question', {
    for (final String topic in [
      'money',
      'work',
      'time',
      'body',
      'relationships',
      'belief',
    ])
      topic: _one('purpose.life-question', {'topic': topic}),
    for (final String size in ['s', 'm', 'wide', 'l'])
      'money $size': _one('purpose.life-question', {
        'topic': 'money',
        'size': size,
      }),
  }),
  _Spec(
    'purpose.life-topics',
    {
      'default': _one('purpose.life-topics'),
      for (final String size in _sml)
        'picked $size': _one('purpose.life-topics', {'size': size}),
    },
    play: (tester, label) async {
      if (!label.startsWith('picked')) return;
      await _tapKey(tester, 'life-money-off');
      await _tapKey(tester, 'life-body-off');
    },
  ),
  _Spec(
    'purpose.spot-trick',
    {
      ..._sizes('purpose.spot-trick', _sml),
      'picked': _one('purpose.spot-trick'),
    },
    play: (tester, label) async {
      if (label == 'picked') {
        await _tapType(tester, '_Option', 0);
        await _tapType(tester, '_Option', 4);
      }
    },
  ),
  _Spec(
    'purpose.played',
    {'empty': _one('purpose.played'), 'played': _one('purpose.played')},
    play: (tester, label) async {
      if (label != 'played') return;
      final List<Pill> shares = PillBank.cards
          .where((p) => percentOf(p) != null)
          .take(3)
          .toList();
      for (int i = 0; i < shares.length; i++) {
        ExplorePlay.instance.put('slide:${shares[i].id}', {
          'v': percentOf(shares[i])!.value + (i + 1) * 6,
          'ck': true,
        });
      }
      PurposePlay.write('tricks', {
        'a': {'move': 'baseRate', 'right': true},
        'b': {'move': 'sampling', 'right': false},
        'c': {'move': 'confounding', 'right': true},
      });
      PurposePlay.said('x');
      PurposePlay.said('y');
      await tester.pump(const Duration(milliseconds: 200));
    },
  ),
  _Spec('purpose.set', {
    ..._sizes('purpose.set', _sml),
    'myths': _one('purpose.set', {'theme': 'myths'}),
    'finished': _one('purpose.set', {
      'source': {'kind': 'ids'},
      'title': {'en': 'Paradoxes'},
    }),
  }, cards: (label) => label == 'finished' ? _read.take(8).toList() : null),
  _Spec(
    'purpose.stamps',
    {
      ..._sizes('purpose.stamps', _sml),
      'labels': _one('purpose.stamps', {
        'source': {'kind': 'ids'},
        'title': {'en': 'Europe'},
        'subtitle': {
          'en': 'A different part of the world every time it comes round',
        },
      }),
    },
    cards: (label) => label == 'labels' ? _europe() : null,
    adjust: (label, json) {
      if (label != 'labels') return json;
      const List<String> codes = [
        'HU',
        'UK',
        'DE',
        'IT',
        'NL',
        'FR',
        'ES',
        'PT',
        'GR',
        'PL',
        'SE',
        'IE',
      ];
      final List<Pill> cards = _europe();
      return {
        ...json,
        'labels': {
          for (int i = 0; i < cards.length; i++) cards[i].id: codes[i],
        },
      };
    },
  ),
  _Spec('purpose.sets', {'default': _one('purpose.sets')}),
  _Spec('purpose.tomorrow', {
    'default': _one('purpose.tomorrow'),
    'named': _one('purpose.tomorrow', {
      'shelves': [
        {
          'title': {'en': 'Where it came from'},
          'subtitle': {'en': 'The beginnings of things you use every day'},
        },
        {
          'title': {'en': 'True stories'},
          'subtitle': {'en': 'Things that really happened'},
        },
      ],
    }),
  }),
  _Spec('purpose.end', {'default': _one('purpose.end')}),
];

/// Twelve cards of Europe, the first five of them read.
List<Pill> _europe() {
  final Set<String> read = {for (final Pill p in _read) p.id};
  final List<Pill> europe = PillBank.cards
      .where((p) => p.region == 'europe')
      .toList();
  return [
    ...europe.where((p) => read.contains(p.id)).take(5),
    ...europe.where((p) => !read.contains(p.id)).take(7),
  ];
}

const List<Size> _phones = [Size(375, 667), Size(402, 874), Size(430, 932)];

/// The bank dealt the way a mixed source deals it, rather than in the
/// bank's own order, which runs a subject at a time.
final List<Pill> _dealt = [...PillBank.cards]
  ..sort(
    (a, b) =>
        shelfHash('camera:${a.id}').compareTo(shelfHash('camera:${b.id}')),
  );

/// The fake host, handing out the dealt bank where a picture names no
/// cards of its own.
class _DealtHost extends FakeExploreHost {
  _DealtHost(super.app);

  @override
  List<Pill> cardsFor(ExploreSection section, {int? limit}) {
    final Object? source = section.source;
    if (cards.containsKey(section.id) ||
        (source is Map && source['ids'] is List)) {
      return super.cardsFor(section, limit: limit);
    }
    return _dealt.take(limit ?? section.limit ?? 12).toList();
  }
}

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

/// A reader a few weeks in: cards read, debates taken, a level measured,
/// so the shelves picked for a reader have someone to pick for.
Future<AppState> _reader() async {
  final List<Pill> bank = PillBank.cards;
  final List<Pill> debates = bank
      .where((p) => p.challenge is TakeASide)
      .take(6)
      .toList();
  final List<String> read = [
    for (final Pill p in _read) p.id,
    ...debates.map((p) => p.id),
  ];
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'knowit.onboarded': true,
    'knowit.seenIds': read,
    'knowit.answersJson': jsonEncode({
      for (int i = 0; i < debates.length; i++) debates[i].id: {'r': '${i % 2}'},
    }),
  });
  _freshPlay();
  final AppState app = AppState();
  await app.init();
  return app;
}

/// A day with nothing played yet, for each picture.
void _freshPlay() {
  // ignore: invalid_use_of_visible_for_testing_member
  ExplorePlay.resetForTest();
}

void main() {
  const String only = String.fromEnvironment('ONLY');
  setUpAll(_loadFonts);

  for (final _Spec spec in _specs) {
    if (only.isNotEmpty && !only.split(',').contains(spec.block)) continue;
    testWidgets(spec.block, (tester) async {
      final AppState app = await tester.runAsync(_reader) as AppState;
      final ExploreBlock block = purpose.blocks.firstWhere(
        (b) => b.name == spec.block,
      );
      // Every picture, and the first state once more at the narrowest
      // phone with the reader's text a size up, at night.
      final List<(String, Map<String, Object?>, Size, bool, double)> shots = [
        for (final MapEntry<String, Map<String, Object?>> shot
            in spec.sections.entries)
          for (final Size phone in _phones)
            for (final bool dark in [true, false])
              (shot.key, shot.value, phone, dark, 1.0),
        (
          spec.sections.keys.first,
          spec.sections.values.first,
          _phones.first,
          true,
          1.3,
        ),
      ];
      for (final (
            String label,
            Map<String, Object?> json,
            Size phone,
            bool dark,
            double scale,
          )
          in shots) {
        _freshPlay();
        final ExploreSection section = ExploreSection.fromJson(
          spec.adjust?.call(label, json) ?? json,
        );
        final FakeExploreHost host = _DealtHost(app);
        final List<Pill>? given = spec.cards?.call(label);
        if (given != null) host.cards[section.id] = given;
        final Key frame = UniqueKey();
        Widget page(double height) => MaterialApp(
          key: frame,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildAstutoTheme(dark ? Brightness.dark : Brightness.light),
          debugShowCheckedModeBanner: false,
          // A page with nothing but the block on it, scrolling as Explore's
          // list does, so the block is laid out at the height it takes
          // there rather than stretched to the phone's.
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(phone.width, height),
              textScaler: TextScaler.linear(scale),
            ),
            child: Builder(
              builder: (context) => Material(
                color: context.p.surface,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: KeyedSubtree(
                      key: const ValueKey('shot'),
                      child:
                          block.build(context, host, section) ??
                          const SizedBox(height: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.binding.setSurfaceSize(Size(phone.width, 3200));
        await tester.pumpWidget(page(3200));
        await tester.pump(const Duration(milliseconds: 400));
        if (spec.play != null) await spec.play!(tester, label);
        final double h =
            tester.getSize(find.byKey(const ValueKey('shot'))).height + 36;
        await tester.binding.setSurfaceSize(Size(phone.width, h));
        await tester.pumpWidget(page(h));
        for (int f = 0; f < 6; f++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        final String name =
            '${spec.block.replaceFirst('purpose.', '')}-'
            '${label.replaceAll(' ', '_')}-${phone.width.round()}-'
            '${dark ? 'dark' : 'light'}${scale > 1 ? '-large' : ''}';
        await expectLater(
          find.byType(MaterialApp).first,
          matchesGoldenFile('shots/gallery/purpose/$name.png'),
        );
      }
      await tester.binding.setSurfaceSize(null);
    });
  }
}
