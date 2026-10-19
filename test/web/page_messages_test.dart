import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/models/pill.dart';
import 'package:astuto/widgets/web/page_messages.dart';

/// The bridge's words, as the app reads them: docs/cards/kit/astute-bridge.js
/// writes the same objects on the other side.
void main() {
  PageMessage? read(Map<String, Object?> message) =>
      PageMessage.parse(jsonEncode(message));

  group('what a page says', () {
    test('every message the bridge sends is read', () {
      expect(read({'t': 'ready'}), isA<PageReady>());
      expect(read({'t': 'flip'}), isA<PageFlip>());
      expect(read({'t': 'tap'}), isA<PageTap>());
      expect(read({'t': 'done'}), isA<PageDone>());

      final answer = read({
        't': 'answer',
        'choice': ' Salt water ',
        'correct': true,
        'sure': 70,
      });
      expect(answer, isA<PageAnswer>());
      answer as PageAnswer;
      expect(answer.choice, 'Salt water');
      expect(answer.correct, isTrue);
      expect(answer.sure, 70);

      expect(
        (read({'t': 'haptic', 'kind': 'success'}) as PageHaptic).kind,
        'success',
      );
      expect(
        (read({'t': 'open', 'url': 'https://example.org/a'}) as PageOpen).url,
        Uri.parse('https://example.org/a'),
      );
      final zones = read({
        't': 'zones',
        'rects': [
          [10, 20, 100, 50],
          ['x'],
        ],
      });
      expect((zones as PageZones).rects, [
        const Rect.fromLTWH(10, 20, 100, 50),
      ]);
      final pan = read({'t': 'pan', 'phase': 'end', 'vx': 900, 'vy': -12.5});
      expect((pan as PagePan).phase, 'end');
      expect(pan.velocity, const Offset(900, -12.5));
      expect(
        (read({
          't': 'error',
          'message': 'x is not defined',
        }) as PageError).message,
        'x is not defined',
      );
    });

    test('what it cannot mean is passed over, never guessed at', () {
      expect(PageMessage.parse('not json'), isNull);
      expect(PageMessage.parse('[1, 2]'), isNull);
      expect(read({'t': 'something new'}), isNull);
      // An answer says what the reader said.
      expect(read({'t': 'answer', 'choice': '  ', 'correct': true}), isNull);
      // A link opens a web page, and only a web page.
      expect(read({'t': 'open', 'url': 'javascript:alert(1)'}), isNull);
      expect(read({'t': 'open', 'url': 'file:///etc/hosts'}), isNull);
      expect(read({'t': 'pan', 'phase': 'sideways'}), isNull);
      // Right or wrong is a yes or a no; anything else is not said.
      final answer = read({
        't': 'answer',
        'choice': 'B',
        'correct': 'yes',
        'sure': 66.6,
      }) as PageAnswer;
      expect(answer.correct, isNull);
      expect(answer.sure, 67);
    });
  });

  group('an answer on a page, kept as the card keeps one', () {
    PageAnswer said(String choice, {bool? correct, int? sure}) =>
        PageAnswer(choice: choice, correct: correct, sure: sure);

    test('a page that marks its card keeps the mark with what was said', () {
      const PageJudged judged = PageJudged();
      final String? right = pageResponse(judged, said('C', correct: true));
      final String? wrong = pageResponse(
        judged,
        said('130 km off', correct: false),
      );
      expect(right, '1|C');
      expect(wrong, '0|130 km off');
      expect(judged.accepts(right!), isTrue);
      expect(judged.accepts(wrong!), isFalse);
      expect(judged.describe(wrong), '130 km off');
      // A graded page has to say which it was.
      expect(pageResponse(judged, said('C')), isNull);
    });

    test('a page that marks nothing keeps what was said, unmarked', () {
      const PageJudged open = PageJudged(graded: false);
      final String? side = pageResponse(open, said('Tax it', correct: true));
      expect(side, '-|Tax it');
      expect(open.isGraded, isFalse);
      expect(open.accepts(side!), isFalse);
      expect(open.describe(side), 'Tax it');
    });

    test('on a card the app marks itself, the page answers in its form', () {
      const PickOne pick = PickOne(options: ['A', 'B', 'C'], correct: 1);
      expect(pageResponse(pick, said('1')), '1');
      expect(pageResponse(pick, said('3')), isNull);
      expect(pageResponse(pick, said('B')), isNull);
      const TakeASide side = TakeASide(positions: ['Yes', 'No']);
      expect(pageResponse(side, said('0')), '0');
      expect(pageResponse(const TypeNumber(answer: 23), said('23')), '23');
      expect(pageResponse(const Estimate(answer: 9000), said('lots')), isNull);
      // A card that only tells records nothing.
      expect(pageResponse(const NoChallenge(), said('anything')), isNull);
    });

    test('how sure lands on one of the app\'s five', () {
      expect(nearestConfidence(70), 70);
      expect(nearestConfidence(74), 70);
      expect(nearestConfidence(76), 80);
      expect(nearestConfidence(12), 50);
      expect(nearestConfidence(100), 90);
    });
  });

  group('what the app tells the page', () {
    const PageEnv env = PageEnv(
      dark: false,
      language: 'it',
      calm: true,
      sound: true,
      touch: WebTouch.drags,
      platform: 'android',
      size: Size(366, 606),
      corner: Size(88, 37),
      subject: PageSubject(
        key: 'medicine',
        name: 'Medicina',
        colour: Color(0xFFFF3B30),
        ink: Color(0xFFFFFFFF),
        icon: 'M1 1',
      ),
      chip: 'DI NUOVO',
    );

    test('everything the kit reads, under the names it reads it by', () {
      final Map<String, Object?> json = env.toJson();
      expect(json['theme'], 'light');
      expect(json['lang'], 'it');
      expect(json['calm'], isTrue);
      expect(json['sound'], isTrue);
      expect(json['touch'], 'drags');
      expect(json['platform'], 'android');
      expect(json['size'], {'w': 366, 'h': 606});
      expect(json['corner'], {'w': 88, 'h': 37});
      expect(json['subject'], {
        'key': 'medicine',
        'name': 'Medicina',
        'c': '#ff3b30',
        'k': '#ffffff',
        'icon': 'M1 1',
      });
      expect(json['chip'], 'DI NUOVO');
      expect(json['note'], isNull);
    });

    test('only a change is said again, and being shown is not one', () {
      expect(env.since(null), isNotNull);
      expect(env.since(env), isNull);
      expect(env.copyWith(shown: true).since(env), isNull);
      expect(env.copyWith(size: const Size(339, 475)).since(env), isNotNull);
    });
  });
}
