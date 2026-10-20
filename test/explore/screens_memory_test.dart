// What the whole-screen blocks keep on the phone: under
// knowit.explore.screens.* and nowhere else, kept across a restart, taken
// once where a thing is done once, and gone the moment a sign-out clears
// the phone.
//
//   flutter test test/explore/screens_memory_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/explore/blocks/screens/memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ScreensMemory> fresh([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues(stored);
    ScreensMemory.resetForTest();
    await ScreensMemory.instance.ready();
    return ScreensMemory.instance;
  }

  test('everything is kept under knowit.explore.screens.*, as JSON', () async {
    final memory = await fresh();
    memory.setPick('front', 'historian');
    memory.setDepth('whys', 'sky', 2);
    memory.setBefore('card-a', 1, on: '2026-10-19');
    memory.setAfter('card-a', 0);
    memory.markSaid('card-b', on: '2026-10-19');
    memory.keep('Why is the sky blue?', cardId: 'card-c', on: '2026-10-19');
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    expect(
      keys,
      containsAll([
        'knowit.explore.screens.picks',
        'knowit.explore.screens.whys',
        'knowit.explore.screens.stances',
        'knowit.explore.screens.said',
        'knowit.explore.screens.asked',
      ]),
    );
    for (final String key in keys) {
      expect(key.startsWith(ScreensMemory.prefix), isTrue, reason: key);
      expect(() => jsonDecode(prefs.getString(key)!), returnsNormally);
    }
    // Read back as a new run would read it.
    ScreensMemory.resetForTest();
    await ScreensMemory.instance.ready();
    final again = ScreensMemory.instance;
    expect(again.pick('front'), 'historian');
    expect(again.depth('whys', 'sky'), 2);
    expect(again.stance('card-a').before, 1);
    expect(again.stance('card-a').after, 0);
    expect(again.said, {'card-b': '2026-10-19'});
    expect(again.asked.single.question, 'Why is the sky blue?');
    expect(again.asked.single.cardId, 'card-c');
  });

  test('what is done before the store is reached is kept', () async {
    SharedPreferences.setMockInitialValues({});
    ScreensMemory.resetForTest();
    final memory = ScreensMemory.instance;
    expect(memory.isOpen, isFalse);
    memory.setPick('dots', 'economics');
    expect(memory.pick('dots'), 'economics');
    await memory.ready();
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('knowit.explore.screens.picks')!), {
      'dots': 'economics',
    });
  });

  test('a sign-out, which clears the phone, clears it at once', () async {
    final memory = await fresh();
    memory.keep('A question of mine', on: '2026-10-19');
    memory.setPick('front', 'doctor');
    expect(memory.asked, isNotEmpty);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    expect(memory.asked, isEmpty);
    expect(memory.pick('front'), isNull);
  });

  test('a stance before is taken once, and one after only after it', () async {
    final memory = await fresh();
    memory.setAfter('card', 3);
    expect(memory.stance('card').after, isNull);
    memory.setBefore('card', 4, on: '2026-10-19');
    memory.setBefore('card', 0, on: '2026-10-19');
    expect(memory.stance('card').before, 4);
    memory.setAfter('card', 1);
    memory.setAfter('card', 2);
    expect(memory.stance('card').after, 1);
  });

  test('a line said is said once, on the day it was', () async {
    final memory = await fresh();
    memory.markSaid('card', on: '2026-10-19');
    memory.markSaid('card', on: '2026-10-20');
    expect(memory.said, {'card': '2026-10-19'});
  });

  test(
    'a question asked again replaces the older, keeping its answer',
    () async {
      final memory = await fresh();
      memory.keep('Why do onions make you cry?', cardId: 'onion', on: 'd1');
      memory.keep('Is coffee bad for you?', on: 'd2');
      memory.keep('why do ONIONS make you cry', on: 'd3');
      expect(
        [for (final q in memory.asked) q.question],
        ['why do ONIONS make you cry', 'Is coffee bad for you?'],
      );
      expect(memory.asked.first.cardId, 'onion');
      memory.keep('   ', on: 'd4');
      expect(memory.asked, hasLength(2));
    },
  );

  test('no more questions are kept than a reader can read down', () async {
    final memory = await fresh();
    for (int i = 0; i < ScreensMemory.keepQuestions + 5; i++) {
      memory.keep('Question number $i', on: 'd');
    }
    expect(memory.asked, hasLength(ScreensMemory.keepQuestions));
    expect(memory.asked.first.question, 'Question number 34');
  });

  test('a question forgotten can be put back where it was', () async {
    final memory = await fresh();
    memory.keep('First', on: 'd');
    memory.keep('Second', on: 'd');
    memory.keep('Third', on: 'd');
    final gone = memory.forget(1);
    expect(gone?.question, 'Second');
    expect([for (final q in memory.asked) q.question], ['Third', 'First']);
    memory.restore(1, gone!);
    expect(
      [for (final q in memory.asked) q.question],
      ['Third', 'Second', 'First'],
    );
    expect(memory.forget(9), isNull);
  });

  test('a part the build cannot read starts clean', () async {
    final memory = await fresh({
      'knowit.explore.screens.picks': '{not json',
      'knowit.explore.screens.asked': '[{"nope": 1}, "x", {"q": "Kept"}]',
      'knowit.explore.screens.stances': '{"card": {"b": 9, "a": "x"}}',
    });
    expect(memory.pick('front'), isNull);
    expect([for (final q in memory.asked) q.question], ['Kept']);
    expect(memory.stance('card').before, isNull);
    expect(memory.stance('card').after, isNull);
  });

  test('a day is kept as the phone\'s calendar says it', () {
    expect(screensDayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });
}
