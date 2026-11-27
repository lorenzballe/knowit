// Photographs Invita un amico (lib/widgets/invite_sheet.dart) for the owner:
// the profile's entry, the sheet with the reader's code, the field with a
// friend's code typed, the code taken, and the week's moment once it is
// given — on a 390 × 844 phone at night, with the server's switch on and a
// stand-in for the server that answers as functions/src/invite.ts does.
//
//   SHOTS=/some/folder LANG_SHOT=it flutter test tool/invite_shots.dart --update-goldens
//
// A camera, not a check: it lives outside test/ so CI never runs it. SHOTS is
// where the pictures go (tool/shots by default); LANG_SHOT is the phone's
// language, Italian when not given; THEME=light shoots the day.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/data/pills_repository.dart' show dateKey;
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/sync/invite.dart';

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

/// The server as invite.ts answers: Ana's code, made when asked; Ben, new,
/// may use a friend's; what a code used comes to is [redeemed].
class _Server implements InviteServer {
  _Server(this.redeemed);

  final Object? redeemed;

  @override
  Future<Object?> state({required bool make}) async => {
    'code': 'K7MQ2P',
    'weeks': 0,
    'cap': 8,
    'friends': 0,
    'redeem': 'open',
  };

  @override
  Future<Object?> redeem(String code) async => redeemed;
}

void _invites(Object? redeemed) {
  // ignore: invalid_use_of_visible_for_testing_member
  Invites.useForTest(
    Invites(
      serverOverride: _Server(redeemed),
      reachableOverride: true,
      planOverride: () async {},
    ),
  );
}

void _prefs(Map<String, Object> values) {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(values);
}

/// A reader a few days in, on the free plan.
Map<String, Object> _reader() {
  final DateTime now = DateTime.now();
  String day(int back) =>
      dateKey(DateTime(now.year, now.month, now.day - back));
  return {
    'knowit.onboarded': true,
    'knowit.plus': false,
    'knowit.streak': 3,
    'knowit.bestStreak': 3,
    'knowit.lastCompletionDate': day(1),
    'knowit.completedDates': [day(3), day(2), day(1)],
    'knowit.theme': Platform.environment['THEME'] ?? 'dark',
  };
}

void main() {
  setUpAll(_loadFonts);

  final String out = Platform.environment['SHOTS'] ?? 'shots';
  final Locale locale = Locale(Platform.environment['LANG_SHOT'] ?? 'it');

  setUp(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    final view = dispatcher.views.first;
    view.physicalSize = const Size(390, 844) * 3;
    view.devicePixelRatio = 3;
    view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    dispatcher.localeTestValue = locale;
    dispatcher.localesTestValue = [locale];
    PillBank.fetch = (url) async => null;
    Remote.fetch = (url) async => null;
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
    Remote.adopt(
      RemoteConfig.parse(
        jsonEncode({
          'schema': 1,
          'hash': 'invite-shots',
          'app': {
            'flags': {'invite': true},
          },
          'strings': <String, Object?>{},
          'explore': null,
          'looks': null,
        }),
      ),
    );
  });

  tearDown(() {
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.views.first.reset();
    dispatcher.clearLocaleTestValue();
    dispatcher.clearLocalesTestValue();
    // ignore: invalid_use_of_visible_for_testing_member
    Remote.reset();
  });

  Future<void> settle(WidgetTester tester, [int frames = 14]) async {
    for (int f = 0; f < frames; f++) {
      await tester.pump(const Duration(milliseconds: 90));
    }
  }

  /// The pictures on screen, decoded: a test's images arrive only when it
  /// waits for them outside its fake clock.
  Future<void> pictures(WidgetTester tester) async {
    final Set<ImageProvider> shown = {
      for (final Image image in tester.widgetList<Image>(find.byType(Image)))
        image.image,
    };
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
    await settle(tester, 5);
  }

  Future<void> shoot(String name) => expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$out/$name.png'),
  );

  final Finder list = find
      .descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  /// The profile, with its invitation's box in the middle of the screen.
  Future<void> toTheBox(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('tab-Profile')));
    await settle(tester);
    final Finder row = find.byKey(const ValueKey('profile-invite'));
    await tester.scrollUntilVisible(row, 300, scrollable: list);
    await settle(tester);
    final ScrollPosition position = tester
        .state<ScrollableState>(list)
        .position;
    position.jumpTo(position.pixels + tester.getRect(row).top - 330);
    await settle(tester);
  }

  testWidgets('the entry, the code, the field, the code taken', (tester) async {
    _prefs(_reader());
    _invites({'state': 'waiting'});
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await toTheBox(tester);
    await shoot('invite-1-entry');

    await tester.tap(find.byKey(const ValueKey('profile-invite')));
    await settle(tester, 20);
    await shoot('invite-2-sheet');

    Navigator.of(tester.element(find.byKey(const ValueKey('invite-sheet'))))
        .pop();
    await settle(tester, 20);
    await tester.tap(find.byKey(const ValueKey('profile-invite-code')));
    await settle(tester, 20);
    await tester.enterText(
      find.byKey(const ValueKey('invite-code-field')),
      'K7MQ2P',
    );
    await settle(tester);
    // No keyboard in the picture: the field as typed, at rest.
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    await shoot('invite-3-code');

    await tester.tap(find.byKey(const ValueKey('invite-code-use')));
    await settle(tester, 20);
    await shoot('invite-4-accepted');
  });

  testWidgets('the week, given', (tester) async {
    _prefs(_reader());
    final DateTime until = DateTime.now().add(const Duration(days: 7));
    _invites({
      'state': 'granted',
      'until': until.millisecondsSinceEpoch,
      'granted': true,
    });
    await tester.pumpWidget(const AstutoApp());
    await settle(tester);
    await toTheBox(tester);
    await tester.tap(find.byKey(const ValueKey('profile-invite-code')));
    await settle(tester, 20);
    await tester.enterText(
      find.byKey(const ValueKey('invite-code-field')),
      'K7MQ2P',
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('invite-code-use')));
    // The take, to its end.
    await settle(tester, 70);
    await pictures(tester);
    await shoot('invite-5-week');
  });
}
