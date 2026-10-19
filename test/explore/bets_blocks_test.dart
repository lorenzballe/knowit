// The blocks of bets on a fake Explore: every one drawn at every size, in
// both themes and at a large text size, with nothing cut off; left out
// where there is nothing to bet on; and every bet, right and wrong,
// recorded the way the card records an answer.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/explore/blocks/bets/answers.dart';
import 'package:astuto/explore/blocks/bets/bets_day.dart';
import 'package:astuto/explore/blocks/bets_blocks.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/state/app_state.dart';

import 'bets_host.dart';

// Cards from the bank, one for each way of betting.
const String share = 'art-detection-9'; // 28 percent, within 1
const String streak = 'psychology-streaks-6'; // 21.5 percent, within 1.5
const String amounts = 'art-motives-2'; // the third option is right
const String stepped = 'art-art-and-money-3'; // 35 thousand pounds
const String estimate = 'art-marble-3'; // 5.6 tonnes, within a factor of 3
const String odds = 'thinking-h13'; // 1 in 6, 1 in 11 (right), 1 in 36
const String otherShare = 'maths-percentages-4'; // 55 percent

late DateTime now;
DateTime clock() => now;

Future<BetsTestHost> start(WidgetTester tester, {bool records = true}) async {
  now = DateTime(2026, 10, 18, 12);
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  // ignore: invalid_use_of_visible_for_testing_member
  BetsDay.resetForTest(clock: clock);
  final AppState app = AppState(clock: clock);
  await tester.runAsync(app.init);
  await tester.runAsync(BetsDay.instance.load);
  return BetsTestHost(app, records: records);
}

Future<void> settle(WidgetTester tester) async {
  for (int f = 0; f < 8; f++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> show(
  WidgetTester tester,
  BetsTestHost host,
  List<Map<String, Object?>> sections, {
  Brightness brightness = Brightness.dark,
  Locale locale = const Locale('en'),
  double text = 1,
  double width = 375,
}) async {
  tester.view.physicalSize = Size(width * 2, 7000 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    betsApp(
      BetsPage(
        host: host,
        sections: [for (final s in sections) ExploreSection.fromJson(s)],
      ),
      brightness: brightness,
      locale: locale,
      phone: Size(width, 7000),
      text: text,
    ),
  );
  await settle(tester);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final Finder f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await tester.tap(f, warnIfMissed: false);
  await settle(tester);
}

/// Sets the track keyed [key] to [value] with a tap where it lies.
Future<void> setTrack(WidgetTester tester, String key, double value) async {
  final Rect r = tester.getRect(find.byKey(ValueKey(key)));
  await tester.tapAt(
    Offset(r.left + 11 + (r.width - 22) * value / 100, r.center.dy),
  );
  await settle(tester);
}

/// The words of the verdict, note or line keyed [key].
String said(WidgetTester tester, String key) =>
    tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(ValueKey(key)),
                matching: find.byType(Text),
                matchRoot: true,
              )
              .first,
        )
        .data ??
    '';

Map<String, Object?> section(String block, [Map<String, Object?>? more]) => {
  'id': block,
  'block': block,
  ...?more,
};

void main() {
  group('every block', () {
    for (final String name in [for (final b in blocks) b.name]) {
      testWidgets('$name draws at every size, dark and light', (tester) async {
        final BetsTestHost host = await start(tester);
        for (final Brightness b in Brightness.values) {
          for (final String size in ['s', 'm', 'l']) {
            await show(tester, host, [
              section(name, {'size': size}),
            ], brightness: b);
            expect(tester.takeException(), isNull, reason: '$name $size');
            expect(find.byKey(ValueKey('page-$name')), findsOneWidget);
          }
        }
        // And with nothing but its block.
        await show(tester, host, [section(name)]);
        expect(find.byKey(ValueKey('page-$name')), findsOneWidget);
      });

      testWidgets('$name fits at twice the text size on the smallest phone', (
        tester,
      ) async {
        final BetsTestHost host = await start(tester);
        for (final String size in ['s', 'm', 'l']) {
          await show(tester, host, [
            section(name, {'size': size}),
          ], text: 2);
          expect(tester.takeException(), isNull, reason: '$name $size');
        }
      });

      testWidgets('$name fits in every language, in its narrowest tiles', (
        tester,
      ) async {
        final BetsTestHost host = await start(tester);
        for (final Locale locale in AppLocalizations.supportedLocales) {
          await show(
            tester,
            host,
            [
              section(name, {'size': 's'}),
            ],
            locale: locale,
            text: 1.3,
          );
          expect(tester.takeException(), isNull, reason: '$name $locale');
        }
      });

      testWidgets('$name is left out with nothing to bet on', (tester) async {
        final BetsTestHost host = await start(tester);
        host.cards[name] = [
          for (final Pill p in PillBank.cards)
            if (BetAnswer.of(p) == null) p,
        ].take(40).toList();
        await show(tester, host, [section(name)]);
        expect(find.byKey(ValueKey('page-$name')), findsNothing);
      });
    }
  });

  group('a range', () {
    testWidgets('in range: recorded as the number typed, and paid', (
      tester,
    ) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-range', {
          'size': 'l',
          'source': {
            'ids': [share],
          },
        }),
      ]);
      await setTrack(tester, 'bets-range-track-$share', 28);
      await tapKey(tester, 'bets-range-$share-w0');
      await tapKey(tester, 'bets-range-bet-$share');

      expect(host.answered, [(share, '28')]);
      expect(host.sure, isEmpty, reason: 'the width is how sure');
      expect(host.app.answerFor(share)!.response, '28');
      expect(host.app.answerFor(share)!.confidence, isNull);
      final Bet bet = BetsDay.instance.betOn('range', share)!;
      expect(bet.right, isTrue);
      expect(bet.points, 30);
      expect(BetsDay.instance.points, 130);
      expect(said(tester, 'bets-range-said-$share'), contains('+30'));
      expect(host.notes.last.$2, 'bet laid');
      expect(host.notes.last.$3['hit'], isTrue);
    });

    testWidgets('missed: recorded, judged wrong by the card, not paid', (
      tester,
    ) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-range', {
          'size': 'l',
          'source': {
            'ids': [share],
          },
        }),
      ]);
      await setTrack(tester, 'bets-range-track-$share', 80);
      await tapKey(tester, 'bets-range-bet-$share');

      expect(host.answered, [(share, '80')]);
      expect(host.app.answerFor(share)!.response, '80');
      expect(BetsDay.instance.betOn('range', share)!.right, isFalse);
      expect(BetsDay.instance.points, 100);
      expect(said(tester, 'bets-range-said-$share'), startsWith('Missed'));
    });

    testWidgets('a card answered already is not bet on again', (tester) async {
      final BetsTestHost host = await start(tester);
      await tester.runAsync(() => host.app.recordAnswer(share, '30'));
      host.cards['bets-range'] = [PillBank.byId(share)!];
      // The deal skips it: nothing left to bet on.
      await show(tester, host, [section('bets-range')]);
      expect(find.byKey(const ValueKey('page-bets-range')), findsNothing);
    });
  });

  group('a stake', () {
    Future<BetsTestHost> stakeOn(
      WidgetTester tester, {
      Map<String, Object?> more = const {},
      bool records = true,
    }) async {
      final BetsTestHost host = await start(tester, records: records);
      await show(tester, host, [
        section('bets-stake', {
          'size': 'l',
          'source': {
            'ids': [amounts],
          },
          ...more,
        }),
      ]);
      return host;
    }

    testWidgets('won: recorded with how sure, the stake doubled', (
      tester,
    ) async {
      final BetsTestHost host = await stakeOn(tester);
      await tapKey(tester, 'bets-stake-$amounts-o2');
      await tapKey(tester, 'bets-stake-$amounts-k1');
      await tapKey(tester, 'bets-stake-bet-$amounts');
      expect(host.answered, isEmpty, reason: 'how sure comes first');
      await tapKey(tester, 'bets-sure-$amounts-70');

      expect(host.sure, [(amounts, '2', 70)]);
      expect(host.app.answerFor(amounts)!.response, '2');
      expect(host.app.answerFor(amounts)!.confidence, 70);
      expect(host.app.judgements.last.correct, isTrue);
      expect(BetsDay.instance.points, 120);
      expect(said(tester, 'bets-stake-said-$amounts'), contains('You win 20.'));
      expect(said(tester, 'bets-stake-said-$amounts'), contains('70% sure'));
    });

    testWidgets('lost: recorded as wrong, the stake spent', (tester) async {
      final BetsTestHost host = await stakeOn(tester);
      await tapKey(tester, 'bets-stake-$amounts-o0');
      await tapKey(tester, 'bets-stake-$amounts-k2');
      await tapKey(tester, 'bets-stake-bet-$amounts');
      await tapKey(tester, 'bets-sure-$amounts-90');

      expect(host.sure, [(amounts, '0', 90)]);
      expect(host.app.judgements.last.correct, isFalse);
      expect(BetsDay.instance.points, 70);
      expect(
        said(tester, 'bets-stake-said-$amounts'),
        contains('You lose 30.'),
      );
    });

    testWidgets('without how sure where the section says so', (tester) async {
      final BetsTestHost host = await stakeOn(tester, more: {'sure': false});
      await tapKey(tester, 'bets-stake-$amounts-o2');
      await tapKey(tester, 'bets-stake-bet-$amounts');
      expect(host.sure, isEmpty);
      expect(host.answered, [(amounts, '2')]);
      expect(host.app.answerFor(amounts)!.confidence, isNull);
    });

    testWidgets('spent, and a hundred again the next day', (tester) async {
      final BetsTestHost host = await stakeOn(tester, records: false);
      await tapKey(tester, 'bets-stake-$amounts-o0');
      await tapKey(tester, 'bets-stake-$amounts-k2');
      await tapKey(tester, 'bets-stake-bet-$amounts');
      await tapKey(tester, 'bets-sure-$amounts-50');
      expect(find.text('70'), findsOneWidget, reason: 'the points left');

      now = DateTime(2026, 10, 19, 0, 5);
      await show(tester, host, [
        section('bets-stake', {
          'size': 'l',
          'source': {
            'ids': [amounts],
          },
        }),
      ]);
      expect(find.text('100'), findsOneWidget);
      expect(BetsDay.instance.slip, isEmpty);
      // The card is open to bet on again.
      expect(
        find.byKey(const ValueKey('bets-stake-said-$amounts')),
        findsNothing,
      );
    });

    testWidgets('a stake above the points left cannot be laid', (tester) async {
      final BetsTestHost host = await start(tester);
      for (final String p in ['x1', 'x2', 'x3']) {
        BetsDay.instance.place(
          Bet(
            kind: 'stake',
            section: 's',
            pill: p,
            said: '0',
            right: false,
            points: -30,
          ),
        );
      }
      expect(BetsDay.instance.points, 10);
      await show(tester, host, [
        section('bets-stake', {
          'size': 'l',
          'source': {
            'ids': [amounts],
          },
        }),
      ]);
      await tapKey(tester, 'bets-stake-$amounts-o1');
      await tapKey(tester, 'bets-stake-$amounts-k2');
      // Still the stake of 10: 30 is more than is left.
      await tapKey(tester, 'bets-stake-bet-$amounts');
      await tapKey(tester, 'bets-sure-$amounts-60');
      expect(BetsDay.instance.betOn('stake', amounts)!.facts['stake'], 10);
      expect(BetsDay.instance.points, 0);
    });
  });

  group('a number', () {
    Future<(BetsTestHost, StepScale)> numberOn(WidgetTester tester) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-number', {
          'size': 'l',
          'source': {
            'ids': [stepped],
          },
        }),
      ]);
      return (host, StepScale.around(BetAnswer.of(PillBank.byId(stepped)!)!)!);
    }

    testWidgets('set on the steppers to the answer: right', (tester) async {
      final (BetsTestHost host, StepScale s) = await numberOn(tester);
      double v = s.start;
      while ((35 - v).abs() >= s.big) {
        final double by = 35 > v ? s.big : -s.big;
        await tapKey(tester, 'bets-number-$stepped-$by');
        v = s.move(v, by);
      }
      while (v != 35) {
        final double by = 35 > v ? s.small : -s.small;
        await tapKey(tester, 'bets-number-$stepped-$by');
        v = s.move(v, by);
      }
      await tapKey(tester, 'bets-number-lock-$stepped');
      await tapKey(tester, 'bets-sure-$stepped-80');

      expect(host.sure, [(stepped, '35', 80)]);
      expect(host.app.judgements.last.correct, isTrue);
      expect(said(tester, 'bets-number-said-$stepped'), startsWith('Spot on.'));
    });

    testWidgets('locked where it started: wrong, and how far', (tester) async {
      final (BetsTestHost host, StepScale s) = await numberOn(tester);
      await tapKey(tester, 'bets-number-lock-$stepped');
      await tapKey(tester, 'bets-sure-$stepped-50');
      expect(host.sure.single.$2, plainResponse(s.start));
      expect(host.app.judgements.last.correct, isFalse);
      expect(said(tester, 'bets-number-said-$stepped'), startsWith('Off by'));
    });
  });

  group('orders of magnitude', () {
    Future<(BetsTestHost, Notches)> sizesOf(
      WidgetTester tester,
      String id,
    ) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-magnitude', {
          'size': 'l',
          'source': {
            'ids': [id],
          },
        }),
      ]);
      return (host, Notches.of(BetAnswer.of(PillBank.byId(id)!)!)!);
    }

    testWidgets('the right power of ten: right', (tester) async {
      final (BetsTestHost host, Notches n) = await sizesOf(tester, estimate);
      await tapKey(tester, 'bets-magnitude-$estimate-${n.right}');
      await tapKey(tester, 'bets-sure-$estimate-60');
      expect(host.sure, [(estimate, n.responseAt(n.right), 60)]);
      expect(host.app.judgements.last.correct, isTrue);
      expect(
        said(tester, 'bets-magnitude-said-$estimate'),
        startsWith('Right'),
      );
    });

    testWidgets('two stairs off: wrong, by two', (tester) async {
      final (BetsTestHost host, Notches n) = await sizesOf(tester, estimate);
      final int at = n.right >= 2 ? n.right - 2 : n.right + 2;
      await tapKey(tester, 'bets-magnitude-$estimate-$at');
      await tapKey(tester, 'bets-sure-$estimate-80');
      expect(host.app.judgements.last.correct, isFalse);
      expect(
        said(tester, 'bets-magnitude-said-$estimate'),
        startsWith('Off by 2 orders of magnitude.'),
      );
    });

    testWidgets('odds: the card own options, smallest first', (tester) async {
      final (BetsTestHost host, Notches n) = await sizesOf(tester, odds);
      expect(n.values, [6, 11, 36]);
      await tapKey(tester, 'bets-magnitude-$odds-${n.right}');
      await tapKey(tester, 'bets-sure-$odds-70');
      expect(host.sure, [(odds, '1', 70)]);
      expect(host.app.judgements.last.correct, isTrue);
    });
  });

  group('the bet of the day', () {
    testWidgets('locked in near the answer: right, and how far', (
      tester,
    ) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-day', {
          'size': 'l',
          'same': true,
          'source': {
            'ids': [streak],
          },
        }),
      ]);
      expect(
        find.text('BET OF THE DAY · THE SAME FOR EVERYONE'),
        findsOneWidget,
      );
      await setTrack(tester, 'bets-day-track-$streak', 21);
      await tapKey(tester, 'bets-day-lock-$streak');
      await tapKey(tester, 'bets-sure-$streak-70');
      expect(host.sure, [(streak, '21', 70)]);
      expect(host.app.judgements.last.correct, isTrue);
      expect(
        BetsDay.instance.betOn('day', streak)!.facts['of_the_day'],
        isTrue,
      );
    });

    testWidgets('far off: wrong', (tester) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-day', {
          'size': 'l',
          'source': {
            'ids': [streak],
          },
        }),
      ]);
      await setTrack(tester, 'bets-day-track-$streak', 70);
      await tapKey(tester, 'bets-day-lock-$streak');
      await tapKey(tester, 'bets-sure-$streak-90');
      expect(host.sure.single.$2, '70');
      expect(host.app.judgements.last.correct, isFalse);
    });
  });

  group('games that are not the card answer', () {
    testWidgets('closer: nothing answered, the card counted read', (
      tester,
    ) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-closer', {
          'size': 'l',
          'steps': 2,
          'source': {
            'ids': [share],
          },
        }),
      ]);
      // 28%: less than 50, then more than 25.
      await tapKey(tester, 'bets-closer-$share-less');
      await tapKey(tester, 'bets-closer-$share-more');
      expect(host.answered, isEmpty);
      expect(host.revealedCards, [('bets-closer', share)]);
      expect(host.app.seenIds, contains(share));
      final Bet bet = BetsDay.instance.betOn('closer', share)!;
      expect(bet.facts, {'right': 2, 'steps': 2});
      expect(said(tester, 'bets-closer-said-$share'), contains('2 of 2'));
    });

    testWidgets('bigger: nothing answered, both cards counted read', (
      tester,
    ) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-bigger', {
          'pairs': [
            [share, otherShare],
          ],
        }),
      ]);
      // 28 against 55: the first is the smaller.
      await tapKey(tester, 'bets-bigger-$share');
      expect(host.answered, isEmpty);
      expect(host.revealedCards, [
        ('bets-bigger', share),
        ('bets-bigger', otherShare),
      ]);
      final Bet bet = BetsDay.instance.betOn('bigger', share)!;
      expect(bet.right, isFalse);
      expect(bet.other, otherShare);
      expect(find.text('Right on 0 of 1.'), findsOneWidget);
      // Once picked, a figure opens its card.
      await tapKey(tester, 'bets-bigger-$otherShare');
      expect(host.opened, [('bets-bigger', otherShare)]);
    });
  });

  group('a friend', () {
    testWidgets('the question is copied without its answer', (tester) async {
      final List<MethodCall> calls = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-friend', {'card': amounts}),
      ]);
      await tapKey(tester, 'bets-friend-copy');
      final MethodCall copied = calls.firstWhere(
        (c) => c.method == 'Clipboard.setData',
      );
      final String text = (copied.arguments as Map)['text'] as String;
      final Pill pill = PillBank.byId(amounts)!;
      expect(text, contains(pill.question));
      expect(text, contains('About £45,000'));
      expect(text, isNot(contains(pill.answer)));
      expect(host.notes.last.$2, 'bet copied');
    });

    testWidgets('sent through the share sheet every card has', (tester) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-friend', {'card': amounts}),
      ]);
      await tapKey(tester, 'bets-friend-send');
      expect(host.notes.last.$2, 'bet sent');
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('says what was staked on it', (tester) async {
      final BetsTestHost host = await start(tester);
      await show(tester, host, [
        section('bets-stake', {
          'size': 'l',
          'sure': false,
          'source': {
            'ids': [amounts],
          },
        }),
        section('bets-friend'),
      ]);
      await tapKey(tester, 'bets-stake-$amounts-o1');
      await tapKey(tester, 'bets-stake-bet-$amounts');
      expect(
        said(tester, 'bets-friend-note'),
        startsWith('You said about £45,000.'),
      );
    });
  });

  group('the slip', () {
    testWidgets('lists the day bets, of the kinds it is given', (tester) async {
      final BetsTestHost host = await start(tester);
      BetsDay.instance.place(
        const Bet(
          kind: 'stake',
          section: 's',
          pill: amounts,
          said: '2',
          right: true,
          points: 20,
          facts: {'stake': 20},
        ),
      );
      BetsDay.instance.place(
        const Bet(
          kind: 'magnitude',
          section: 'm',
          pill: estimate,
          said: '10',
          right: true,
          facts: {'value': 10.0},
        ),
      );
      await show(tester, host, [
        section('bets-slip', {'size': 'l'}),
      ]);
      expect(
        find.byKey(const ValueKey('bets-slip-stake-$amounts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('bets-slip-magnitude-$estimate')),
        findsOneWidget,
      );
      expect(find.text('+20 today'), findsOneWidget);

      await show(tester, host, [
        section('bets-slip', {
          'size': 'l',
          'kinds': ['magnitude'],
        }),
      ]);
      expect(
        find.byKey(const ValueKey('bets-slip-stake-$amounts')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('bets-slip-magnitude-$estimate')),
        findsOneWidget,
      );
    });
  });
}
