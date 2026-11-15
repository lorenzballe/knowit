// Photographs the paywall by each of its doors, on a small phone, a common
// one and a large one, at night and on paper: to be looked at whenever the
// paywall changes.
//
//   flutter test tool/paywall_shots.dart --update-goldens
//
// A camera, not a check, like the other shots: it lives outside test/ so CI
// never runs it. The pictures land in tool/shots/paywall/, to be looked at
// and not kept. No store answers here, so the plans are the debug build's
// own, at the prices written into the app.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/paywall_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/theme.dart';

import '../test/explore/core_harness.dart';

const String _out = 'shots/paywall';

Future<void> _settle(WidgetTester tester, [int frames = 30]) async {
  for (int f = 0; f < frames; f++) {
    await tester.pump(const Duration(milliseconds: 90));
  }
}

/// A reader who has said how sure they were [n] times, right [right] of
/// them, at [sure] percent.
Map<String, Object> _judged(int n, {required int sure, required int right}) =>
    {
      'knowit.judgements': jsonEncode([
        for (var i = 0; i < n; i++)
          {
            'c': sure,
            'k': i < right,
            'p': PillBank.cards[i].id,
            'd': dateKey(DateTime.now()),
          },
      ]),
    };

void main() {
  setUpAll(() async {
    await loadFonts();
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.baseline = const RemoteConfig(
      hash: 'the-build-own',
      schema: kRemoteSchema,
      parts: {},
    );
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
  });

  // The phones: an SE, a 16 Pro, a 16 Pro Max, each with its own insets.
  const phones = <(String, Size, EdgeInsets)>[
    ('se', Size(375, 667), EdgeInsets.only(top: 20)),
    ('pro', Size(402, 874), EdgeInsets.only(top: 62, bottom: 34)),
    ('max', Size(440, 956), EdgeInsets.only(top: 62, bottom: 34)),
  ];

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required String source,
    required (String, Size, EdgeInsets) phone,
    Brightness brightness = Brightness.dark,
    Map<String, Object> prefs = const {},
    Locale locale = const Locale('en'),
  }) async {
    final view = tester.view;
    view.physicalSize = phone.$2 * 3;
    view.devicePixelRatio = 3;
    view.padding = FakeViewPadding(
      top: phone.$3.top * 3,
      bottom: phone.$3.bottom * 3,
    );
    view.viewPadding = view.padding;
    final AppState app = await readyApp({'knowit.plus': false, ...prefs});
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildAstutoTheme(brightness),
        locale: locale,
        debugShowCheckedModeBanner: false,
        home: PaywallScreen(app: app, source: source),
      ),
    );
    await _settle(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('$_out/$name-${phone.$1}.png'),
    );
  }

  testWidgets('every door, on the three phones', (tester) async {
    addTearDown(tester.view.reset);
    for (final phone in phones) {
      await shoot(tester, '1-plans', source: 'see the plans', phone: phone);
      await shoot(tester, '2-paths', source: 'paths', phone: phone);
    }
    final pro = phones[1];
    await shoot(
      tester,
      '3-record',
      source: 'journey',
      phone: pro,
      prefs: _judged(12, sure: 80, right: 7),
    );
    await shoot(tester, '4-five', source: 'sixth card', phone: pro);
    await shoot(tester, '5-read', source: 'archive', phone: pro);
    for (final phone in phones) {
      await shoot(
        tester,
        '7-plans-it',
        source: 'see the plans',
        phone: phone,
        locale: const Locale('it'),
      );
    }
    await shoot(
      tester,
      '6-plans-paper',
      source: 'see the plans',
      phone: pro,
      brightness: Brightness.light,
    );
  });
}
