// Invita un amico (lib/sync/invite.dart, lib/widgets/invite_sheet.dart): the
// profile's entry and the message it sends, the field where a friend's code
// is typed, the link that brings one, the week's moment and the customer
// read again, the inviter told of a friend's week once — and all of it gone
// while the server's switch is off, the build cannot take part, or the
// server says invitations are not set up. The server's own rules are
// functions/src/invite.test.ts; here it is a stand-in that answers as it
// does.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/analytics.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/main.dart';
import 'package:astuto/remote/remote.dart';
import 'package:astuto/screens/profile_screen.dart';
import 'package:astuto/screens/purchase_success_screen.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/sync/invite.dart';
import 'package:astuto/utils/share_link.dart';
import 'package:astuto/utils/share_text.dart';
import 'package:astuto/utils/widget_open.dart';

final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The server, as invite.ts answers: a code made when asked with `make`,
/// where a friend's code stands, and what a code used comes to.
class _Server implements InviteServer {
  String? code;
  int weeks = 0;
  String redeemState = 'open';
  DateTime? until;
  bool givenNow = false;
  Object? redeemAnswer = {'state': 'waiting'};
  bool unconfigured = false;
  final List<bool> asked = [];
  final List<String> used = [];

  @override
  Future<Object?> state({required bool make}) async {
    asked.add(make);
    if (unconfigured) return {'none': 'unconfigured'};
    if (make) code ??= 'K7MQ2P';
    final bool given = givenNow;
    givenNow = false;
    return {
      'code': code,
      'weeks': weeks,
      'cap': 8,
      'friends': weeks,
      'redeem': redeemState,
      'until': ?until?.millisecondsSinceEpoch,
      if (given) 'granted': true,
    };
  }

  @override
  Future<Object?> redeem(String code) async {
    used.add(code);
    if (unconfigured) return {'none': 'unconfigured'};
    return redeemAnswer;
  }
}

class _Said implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];

  List<Map<String, Object>> of(String event) => [
    for (final e in events)
      if (e.$1 == event) e.$2,
  ];

  @override
  Future<void> capture(String event, Map<String, Object> properties) async =>
      events.add((event, properties));

  @override
  Future<void> screen(String name) async {}

  @override
  Future<void> identify(String id, Map<String, Object> properties) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> register(String key, Object value) async {}

  @override
  Future<void> setCollecting(bool on) async {}

  @override
  Future<void> setPerson(
    Map<String, Object> set,
    Map<String, Object> setOnce,
  ) async {}

  @override
  Future<void> error(
    Object error,
    StackTrace? stack,
    Map<String, Object> properties,
  ) async {}
}

_Said _listen() {
  final said = _Said();
  Analytics.useForTest(said);
  addTearDown(() => Analytics.useForTest(null));
  return said;
}

int _docs = 0;

/// The server's document, saying [flags].
void _take(Map<String, Object?> flags) => Remote.adopt(
  RemoteConfig.parse(
    jsonEncode({
      'schema': 1,
      'hash': 'invite-${_docs++}',
      'app': {'flags': flags},
      'strings': <String, Object?>{},
      'explore': null,
      'looks': null,
    }),
  ),
);

/// The app's invitations, with the stand-in server, on a build that can
/// take part unless told otherwise; [plans] counts the customer read again.
(_Server, List<int>) _invites({bool reachable = true}) {
  final server = _Server();
  final List<int> plans = [];
  Invites.useForTest(
    Invites(
      serverOverride: server,
      reachableOverride: reachable,
      planOverride: () async => plans.add(1),
    ),
  );
  addTearDown(() => Invites.useForTest(Invites()));
  return (server, plans);
}

/// The phone's side of the links: what the app is handed when it asks, and
/// the word that one has just come in (as test/widget_test.dart's).
class _Phone {
  _Phone(this.tester);

  final WidgetTester tester;
  Object? tap;

  static const MethodChannel channel = MethodChannel('astut/widget');

  void listen() {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'takeOpenedFrom':
          final Object? held = tap;
          tap = null;
          return held;
        case 'installed':
          return const <Object?>[];
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  Future<void> open(Object link) async {
    tap = link;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('opened')),
      (_) {},
    );
    await _settle(tester);
  }
}

final Finder _profileList = find
    .descendant(
      of: find.byType(ProfileScreen),
      matching: find.byType(Scrollable),
    )
    .first;

/// The profile, scrolled to [key]'s row and that row brought up past the
/// tab bar that floats over the foot of the screen.
Future<Finder> _profileRow(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(const ValueKey('tab-Profile')));
  await _settle(tester);
  final Finder row = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(row, 200, scrollable: _profileList);
  await _settle(tester);
  final double floor =
      tester.view.physicalSize.height / tester.view.devicePixelRatio - 110;
  final double bottom = tester.getBottomLeft(row).dy;
  if (bottom > floor) {
    await tester.drag(_profileList, Offset(0, floor - bottom - 20));
    await _settle(tester);
  }
  return row;
}

Map<String, Object> _reader([Map<String, Object> more = const {}]) => {
  'knowit.onboarded': true,
  'knowit.plus': false,
  ...more,
};

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(402, 874) * 3;
    view.devicePixelRatio = 3;
    Remote.reset();
    Remote.fetch = (url) async => null;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
    Remote.reset();
    sendText = shareText;
  });

  group('the code and the link', () {
    test(
      'a code is read as a reader types it, from the server\'s alphabet',
      () {
        final String server = File('functions/src/invite.ts')
            .readAsStringSync();
        expect(
          server,
          contains("export const CODE_ALPHABET = '$kInviteAlphabet';"),
        );
        expect(
          server,
          contains('export const CODE_LENGTH = $kInviteCodeLength;'),
        );
        expect(readInviteCode('K7MQ2P'), 'K7MQ2P');
        expect(readInviteCode(' k7m-q2p '), 'K7MQ2P');
        for (final String? bad in [
          null,
          '',
          'K7MQ2',
          'K7MQ2PP',
          'K7MQ2O',
          'A7MQ2P',
          'K1MQ2P',
          'x' * 60,
        ]) {
          expect(readInviteCode(bad), isNull, reason: bad);
        }
      },
    );

    test('the link is the site\'s page with the code and nothing else, and '
        'the phones hand it to the app', () {
      expect(inviteLink('K7MQ2P'), 'https://astutetheapp.com/invito?c=K7MQ2P');
      for (final String url in [
        'https://astutetheapp.com/invito?c=K7MQ2P',
        'https://www.astutetheapp.com/invito?c=K7MQ2P',
        'https://astutetheapp.com/invito.html?c=K7MQ2P',
        'https://astutetheapp.com/invito/?c=K7MQ2P&ref=x',
      ]) {
        expect(
          WidgetOpen.inviteCodeOfLink(Uri.parse(url)),
          'K7MQ2P',
          reason: url,
        );
        expect(WidgetOpen.cardOfLink(Uri.parse(url)), isNull, reason: url);
      }
      for (final String url in [
        'https://astutetheapp.com/invito',
        'https://astutetheapp.com/invito?c=',
        'https://astutetheapp.com/sfida?c=K7MQ2P',
        'https://example.com/invito?c=K7MQ2P',
        'https://astutetheapp.com/c/invito',
      ]) {
        expect(
          WidgetOpen.inviteCodeOfLink(Uri.parse(url)),
          isNull,
          reason: url,
        );
      }
      // What the phones hand over, read.
      final WidgetOpen open = WidgetOpen.read({
        'from': 'link',
        'in': 'invite',
        'code': 'K7MQ2P',
      })!;
      expect(open.place, WidgetOpen.invite);
      expect(open.code, 'K7MQ2P');
      expect(open.card, isNull);
      expect(open.toString(), isNot(contains('K7MQ2P')));
      // The site says the app may open it, with a code; Android asks for it.
      final Map<String, Object?> apple = jsonDecode(
        File('site/.well-known/apple-app-site-association').readAsStringSync(),
      ) as Map<String, Object?>;
      final List<Object?> components =
          (((apple['applinks'] as Map)['details'] as List).first
                  as Map)['components']
              as List;
      expect(
        components,
        anyElement(
          equals({
            '/': '/invito',
            '?': {'c': '?*'},
            'comment':
                'An invitation with its code: on a phone with the app, the code '
                'in the app.',
          }),
        ),
      );
      final String manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('<data android:path="/invito"/>'));
      expect(manifest, contains('android:pathPrefix="/c/"'));
      for (final String native in [
        'ios/Runner/AppDelegate.swift',
        'android/app/src/main/kotlin/com/astuto/app/MainActivity.kt',
      ]) {
        final String source = File(native).readAsStringSync();
        expect(source, contains('"invito"'), reason: native);
        expect(
          source,
          contains(
            native.endsWith('.kt') ? '"in" to "invite"' : '"in": "invite"',
          ),
          reason: native,
        );
      }
    });

    test('the message says the code and the link in every language, and '
        'promises the friend\'s week alone once the year\'s are given', () {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final AppLocalizations l = lookupAppLocalizations(locale);
        final String link = inviteLink('K7MQ2P');
        for (final String text in [
          l.inviteMessage('K7MQ2P', link),
          l.inviteMessageCapped('K7MQ2P', link),
        ]) {
          expect(text, contains('K7MQ2P'), reason: '$locale');
          expect(text.split('\n').last, link, reason: '$locale');
          expect(text, contains('Astute+'), reason: '$locale');
        }
      }
      expect(
        en.inviteMessage('K7MQ2P', inviteLink('K7MQ2P')),
        'Join me on Astute: five cards a day to keep your mind sharp. With my '
        'code K7MQ2P, once you finish your first day we each get a week of '
        'Astute+.\nhttps://astutetheapp.com/invito?c=K7MQ2P',
      );
      expect(
        en.inviteMessageCapped('K7MQ2P', inviteLink('K7MQ2P')),
        contains('you get a week of Astute+'),
      );
    });
  });

  group('the switch hides it all', () {
    testWidgets('off, as built: no box, no rows, and nothing asked', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_reader());
      final (server, _) = _invites();
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await _settle(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-plan')),
        300,
        scrollable: _profileList,
      );
      await _settle(tester);
      expect(find.byKey(const ValueKey('profile-invite')), findsNothing);
      expect(find.byKey(const ValueKey('profile-invite-code')), findsNothing);
      expect(find.text(en.inviteSection.toUpperCase()), findsNothing);
      expect(server.asked, isEmpty);
    });

    testWidgets('on, but the server says invitations are not set up: gone', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, _) = _invites();
      server.unconfigured = true;
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await _settle(tester);
      // The box is asked for as it comes into view, and goes.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-plan')),
        300,
        scrollable: _profileList,
      );
      await _settle(tester);
      expect(server.asked, isNotEmpty);
      expect(Invites.instance.unconfigured, isTrue);
      expect(find.byKey(const ValueKey('profile-invite')), findsNothing);
    });

    testWidgets('on, on a build that cannot take part (the web app): gone', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, _) = _invites(reachable: false);
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('tab-Profile')));
      await _settle(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-plan')),
        300,
        scrollable: _profileList,
      );
      expect(find.byKey(const ValueKey('profile-invite')), findsNothing);
      expect(server.asked, isEmpty);
    });

    testWidgets('off, an invitation\'s link opens nothing, and the code is '
        'kept for when it is on', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _invites();
      final phone = _Phone(tester)..listen();
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await phone.open({'from': 'link', 'in': 'invite', 'code': 'K7MQ2P'});
      expect(find.byKey(const ValueKey('invite-code-sheet')), findsNothing);
      expect(Invites.instance.held, 'K7MQ2P');
      expect(tester.takeException(), isNull);
    });
  });

  group('the profile\'s entry', () {
    testWidgets('"Invite a friend" shows the reader\'s code, made on the '
        'server, and sends the message with the link through the share sheet; '
        'the code is never measured', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, _) = _invites();
      final said = _listen();
      final List<String> sent = [];
      sendText = (text) async {
        sent.add(text);
        return true;
      };
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      final Finder row = await _profileRow(tester, 'profile-invite');
      expect(
        find.descendant(of: row, matching: find.text(en.inviteRow)),
        findsOneWidget,
      );
      expect(find.text(en.inviteSection.toUpperCase()), findsOneWidget);
      await tester.tap(row);
      await _settle(tester);
      expect(find.byKey(const ValueKey('invite-sheet')), findsOneWidget);
      expect(server.asked, contains(true));
      expect(find.byKey(const ValueKey('invite-code')), findsOneWidget);
      expect(find.text('K7MQ2P'), findsOneWidget);
      expect(find.text(en.inviteRowLine), findsWidgets);
      expect(find.text(en.inviteRules(8)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('invite-send')));
      await _settle(tester);
      expect(sent, [
        en.inviteMessage('K7MQ2P', 'https://astutetheapp.com/invito?c=K7MQ2P'),
      ]);
      expect(said.of('invite sent'), [
        {'as': 'link', 'weeks': 0, 'friends': 0, 'capped': false},
      ]);
      for (final (String _, Map<String, Object> facts) in said.events) {
        expect(jsonEncode(facts), isNot(contains('K7MQ2P')));
      }
    });

    testWidgets('where there is no share sheet the message is copied', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      _invites();
      final said = _listen();
      final List<String> copied = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      sendText = (text) async => false;
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(await _profileRow(tester, 'profile-invite'));
      await _settle(tester);
      // The code alone, copied: said beside it.
      await tester.tap(find.byKey(const ValueKey('invite-copy')));
      await _settle(tester);
      expect(copied, ['K7MQ2P']);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('invite-copy')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      copied.clear();
      await tester.tap(find.byKey(const ValueKey('invite-send')));
      await _settle(tester);
      expect(
        copied.single,
        contains('https://astutetheapp.com/invito?c=K7MQ2P'),
      );
      expect(said.of('invite sent').single['as'], 'copied');
      expect(find.text(en.copiedToClipboard), findsOneWidget);
    });

    testWidgets('the year\'s weeks so far, and once they are all given, the '
        'message promises the friend\'s week alone', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, _) = _invites();
      server
        ..code = 'K7MQ2P'
        ..weeks = 8
        ..redeemState = 'closed';
      final List<String> sent = [];
      sendText = (text) async {
        sent.add(text);
        return true;
      };
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(await _profileRow(tester, 'profile-invite'));
      await _settle(tester);
      expect(find.text(en.inviteWeeksSoFar(8, 8)), findsOneWidget);
      expect(find.text(en.inviteCapped(8)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('invite-send')));
      await _settle(tester);
      expect(
        sent.single,
        en.inviteMessageCapped('K7MQ2P', inviteLink('K7MQ2P')),
      );
    });
  });

  group('a friend\'s code', () {
    testWidgets('"Have a code?" for a new account: the field takes the code '
        'however it is typed, and once it is taken says the week starts with '
        'the first day', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, plans) = _invites();
      final said = _listen();
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(await _profileRow(tester, 'profile-invite-code'));
      await _settle(tester);
      expect(find.byKey(const ValueKey('invite-code-sheet')), findsOneWidget);
      final Finder field = find.byKey(const ValueKey('invite-code-field'));
      await tester.enterText(field, 'k7m-q2p and more');
      await _settle(tester);
      expect(tester.widget<TextField>(field).controller!.text, 'K7MQ2P');
      await tester.tap(find.byKey(const ValueKey('invite-code-use')));
      await _settle(tester);
      expect(server.used, ['K7MQ2P']);
      expect(
        find.byKey(const ValueKey('invite-code-accepted')),
        findsOneWidget,
      );
      expect(find.text(en.inviteCodeWaitingLine), findsOneWidget);
      expect(Invites.instance.waiting, isTrue);
      expect(plans, isEmpty);
      expect(said.of('invite code redeemed'), [
        {'from': 'typed', 'outcome': 'waiting'},
      ]);
      // Back on the profile: the code taken, the week waiting on the day.
      await tester.tap(find.byKey(const ValueKey('invite-code-done')));
      await _settle(tester);
      expect(
        find.byKey(const ValueKey('profile-invite-accepted')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('profile-invite-code')), findsNothing);
    });

    testWidgets('a code refused says why, and no more', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, _) = _invites();
      final said = _listen();
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(await _profileRow(tester, 'profile-invite-code'));
      await _settle(tester);
      for (final (String why, String line) in [
        ('own', en.inviteRefusedOwn),
        ('used', en.inviteRefusedUsed),
        ('late', en.inviteRefusedLate),
        ('plus', en.inviteRefusedPlus),
        ('unknown', en.inviteRefusedUnknown),
      ]) {
        server.redeemAnswer = {'refused': why};
        await tester.enterText(
          find.byKey(const ValueKey('invite-code-field')),
          'BBBBBB',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('invite-code-use')));
        await _settle(tester);
        expect(find.text(line), findsOneWidget, reason: why);
      }
      server.redeemAnswer = null;
      await tester.tap(find.byKey(const ValueKey('invite-code-use')));
      await _settle(tester);
      expect(find.text(en.deeperTryAgain), findsOneWidget);
      expect(
        said.of('invite code redeemed').map((e) => e['reason'] ?? e['outcome']),
        ['own', 'used', 'late', 'plus', 'unknown', 'unavailable'],
      );
    });

    testWidgets('an invitation\'s link opens its code in the sheet, ready to '
        'use, and is counted without the code', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, _) = _invites();
      final said = _listen();
      final phone = _Phone(tester)..listen();
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await phone.open({'from': 'link', 'in': 'invite', 'code': 'k7mq2p'});
      expect(find.byKey(const ValueKey('invite-code-sheet')), findsOneWidget);
      final Finder field = find.byKey(const ValueKey('invite-code-field'));
      expect(tester.widget<TextField>(field).controller!.text, 'K7MQ2P');
      expect(said.of('app opened from link'), [
        {'invite': true},
      ]);
      await tester.tap(find.byKey(const ValueKey('invite-code-use')));
      await _settle(tester);
      expect(server.used, ['K7MQ2P']);
      expect(said.of('invite code redeemed').single['from'], 'link');
      expect(Invites.instance.held, isNull);
    });

    testWidgets('a code used after the first day gives the week at once: the '
        'customer is read again and the week\'s moment rises, saying it was '
        'given', (tester) async {
      SharedPreferences.setMockInitialValues(_reader());
      _take({'invite': true});
      final (server, plans) = _invites();
      final said = _listen();
      final DateTime until = DateTime(2026, 12, 4, 18);
      server.redeemAnswer = {
        'state': 'granted',
        'until': until.millisecondsSinceEpoch,
        'granted': true,
      };
      await tester.pumpWidget(const AstutoApp());
      await _settle(tester);
      await tester.tap(await _profileRow(tester, 'profile-invite-code'));
      await _settle(tester);
      await tester.enterText(
        find.byKey(const ValueKey('invite-code-field')),
        'K7MQ2P',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('invite-code-use')));
      await _settle(tester);
      expect(plans, [1]);
      final PurchaseSuccessScreen moment = tester.widget(
        find.byType(PurchaseSuccessScreen),
      );
      expect(moment.title, en.inviteSuccessTitle);
      expect(moment.planName, en.inviteSuccessPlan);
      expect(moment.planLine, en.inviteSuccessUntil('December 4'));
      expect(moment.foot, en.inviteSuccessFoot);
      expect(moment.onReceipt, isNull);
      expect(moment.screenName, 'invite week');
      expect(said.of('invite reward granted'), [
        {'side': 'friend'},
      ]);
      expect(Invites.instance.unseen, isNull);
    });
  });

  group('the week, after the first day', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'a code waiting on the first day: the backup written, the server '
      'asked, the week kept to be shown and the customer read again',
      () async {
        final (server, plans) = _invites();
        final Invites invites = Invites.instance;
        server.redeemState = 'waiting';
        await invites.refresh(force: true);
        expect(invites.waiting, isTrue);
        int flushed = 0;
        invites.beforeSettle = () async => flushed++;
        // The five read: the server finds the day and gives the two weeks.
        final DateTime until = DateTime(2026, 12, 4);
        server
          ..redeemState = 'granted'
          ..until = until
          ..givenNow = true;
        final state = await invites.settle();
        expect(flushed, 1);
        expect(state?.redeem, InviteRedeem.granted);
        expect(invites.waiting, isFalse);
        expect(invites.unseen, until);
        expect(plans, [1]);
        // Shown once, and not asked again.
        await invites.seen();
        expect(invites.unseen, isNull);
        final int asks = server.asked.length;
        await invites.settle();
        expect(server.asked.length, asks);
        expect(plans, [1]);
      },
    );

    test(
      'an answer lost while the phone waited is still the week\'s moment',
      () async {
        final (server, plans) = _invites();
        final Invites invites = Invites.instance;
        server.redeemState = 'waiting';
        await invites.refresh(force: true);
        // Given on the server by an ask whose answer never came.
        server.redeemState = 'granted';
        await invites.refresh(force: true);
        expect(invites.waiting, isFalse);
        expect(invites.unseen, isNotNull);
        expect(plans, [1]);
      },
    );

    test('the inviter hears of a friend\'s week once, and a phone that never '
        'knew the count takes it as said', () async {
      final said = _listen();
      SharedPreferences.setMockInitialValues({'knowit.invite.weeksSeen': 0});
      final (server, plans) = _invites();
      server.code = 'K7MQ2P';
      final Invites invites = Invites.instance;
      await invites.restore();
      await invites.refresh(force: true);
      expect(invites.newWeeks, 0);
      server.weeks = 1;
      await invites.refresh(force: true);
      expect(invites.newWeeks, 1);
      expect(plans, [1]);
      expect(said.of('invite reward granted'), [
        {'side': 'inviter', 'weeks': 1, 'new_weeks': 1, 'capped': false},
      ]);
      invites.saidNewWeeks();
      await invites.refresh(force: true);
      expect(invites.newWeeks, 0);
      expect(said.of('invite reward granted'), hasLength(1));

      // A new phone, three weeks already on the server: nothing said.
      SharedPreferences.setMockInitialValues({});
      final (fresh, _) = _invites();
      fresh
        ..code = 'K7MQ2P'
        ..weeks = 3;
      await Invites.instance.restore();
      await Invites.instance.refresh(force: true);
      expect(Invites.instance.newWeeks, 0);
    });

    test('asked at most every two minutes, unless it matters', () async {
      final (server, _) = _invites();
      final Invites invites = Invites.instance;
      await invites.refresh();
      await invites.refresh();
      expect(server.asked, [false]);
      // Making the code, or a day just finished, asks at once.
      await invites.refresh(make: true);
      await invites.refresh(force: true);
      expect(server.asked, [false, true, false]);
    });

    test('signing out forgets it all', () async {
      final (server, _) = _invites();
      final Invites invites = Invites.instance;
      invites.hold('K7MQ2P');
      server.redeemState = 'waiting';
      await invites.refresh(force: true);
      await invites.reset();
      expect(invites.held, isNull);
      expect(invites.waiting, isFalse);
      expect(invites.state, isNull);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('knowit.invite')),
        isEmpty,
      );
    });
  });

  test('the switch is the server\'s, off as built', () {
    expect(AppState.kInviteFlag.name, 'invite');
    expect(AppState.kInviteFlag.fallback, isFalse);
    final Map<String, Object?> app = jsonDecode(
      File('remote/app.json').readAsStringSync(),
    ) as Map<String, Object?>;
    expect((app['flags'] as Map)['invite'], isFalse);
  });
}
