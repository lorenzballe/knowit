import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astuto/data/card_catalog.dart';
import 'package:astuto/data/card_codec.dart';
import 'package:astuto/data/pills_data.dart';
import 'package:astuto/data/pills_repository.dart';
import 'package:astuto/data/taste.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/sync/card_feed.dart';

/// A card with exactly the facets a test cares about and nothing else.
Pill card(
  String id,
  String topicKey, {
  Challenge challenge = const NoChallenge(),
  Difficulty difficulty = Difficulty.easy,
  Principle principle = Principle.none,
  List<String> tags = const [],
  Tone? tone,
}) {
  final style = kTopics[topicKey]!;
  return Pill(
    id: id,
    topicKey: topicKey,
    topic: style.name,
    color: style.color,
    ink: style.ink,
    tint: style.tint,
    question: 'q $id',
    answer: 'a $id',
    barMove: 'bar',
    source: 'src',
    challenge: challenge,
    difficulty: difficulty,
    principle: principle,
    tags: tags,
    tone: tone,
    steps: challenge is NoChallenge ? const [] : const ['one', 'two'],
  );
}

const _pick = PickOne(options: ['a', 'b', 'c'], correct: 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(CardCatalog.reset);

  group('What a card is made of', () {
    test('facets are only what the card actually states', () {
      final bare = card('x-1', 'science');
      expect(bare.facets, ['topic:science', 'format:read', 'level:easy']);

      final full = card(
        'x-2',
        'science',
        challenge: _pick,
        difficulty: Difficulty.hard,
        principle: Principle.baseRate,
        tags: ['money', 'risk'],
        tone: Tone.startling,
      );
      expect(full.facets, [
        'topic:science',
        'format:pick',
        'level:hard',
        'move:baseRate',
        'tone:startling',
        'tag:money',
        'tag:risk',
      ]);
    });
  });

  group('Learning what someone likes', () {
    test('one signal barely moves anything', () {
      final taste = ReaderTaste();
      taste.learn(card('a', 'science'), Signal.saved);
      // Saving is the strongest signal there is, and one of them is still
      // one card: the pull is shrunk toward the prior until there is
      // evidence behind it.
      expect(taste.pullOf('topic:science'), lessThan(0.3));
    });

    test('a run of the same signal is believed', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 12; i++) {
        taste.learn(card('a$i', 'science'), Signal.saved);
      }
      expect(taste.pullOf('topic:science'), greaterThan(0.7));
    });

    test('what they said is the prior, what they did overrules it', () {
      final taste = ReaderTaste()..declare({'science': 1.0, 'history': 0.0});

      // Before any evidence, the answer is exactly what they asked for.
      expect(taste.pullOf('topic:science'), 1.0);
      expect(taste.pullOf('topic:history'), -1.0);

      // Then they skip every science card and keep every history one.
      for (var i = 0; i < 15; i++) {
        taste.learn(card('s$i', 'science'), Signal.skipped);
        taste.learn(card('h$i', 'history'), Signal.saved);
      }
      expect(taste.pullOf('topic:science'), lessThan(0));
      expect(taste.pullOf('topic:history'), greaterThan(0));
      expect(
        taste.match(card('h', 'history')),
        greaterThan(taste.match(card('s', 'science'))),
      );
    });

    test('a taste can change back', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 40; i++) {
        taste.learn(card('a$i', 'space'), Signal.skipped);
      }
      final low = taste.pullOf('topic:space');
      for (var i = 0; i < 25; i++) {
        taste.learn(card('b$i', 'space'), Signal.saved);
      }
      // The learning rate has a floor precisely so this is possible: a reader
      // who has changed their mind is not stuck with who they were.
      expect(taste.pullOf('topic:space'), greaterThan(low + 0.4));
    });

    test('a tag-heavy card does not outvote its subject', () {
      final taste = ReaderTaste()..declare({'nature': 0.0});
      for (var i = 0; i < 10; i++) {
        taste.learn(
          card('n$i', 'nature', tags: ['bees', 'trees', 'soil']),
          Signal.saved,
        );
      }
      // Tags and topic are one family each, so three liked tags weigh the
      // same as one disliked subject rather than three times as much.
      final tagged = card('n', 'nature', tags: ['bees', 'trees', 'soil']);
      expect(taste.match(tagged), lessThan(1.0));
      expect(taste.match(tagged), greaterThan(-1.0));
    });
  });

  group('Not only what they like', () {
    test('a subject just dealt is worth less than one that was not', () {
      final taste = ReaderTaste();
      final fresh = card('f', 'history');
      final tired = card('t', 'science');
      for (var i = 0; i < 4; i++) {
        taste.noteDealt(card('s$i', 'science'));
      }
      expect(taste.fatigue(tired), greaterThan(taste.fatigue(fresh)));
      expect(taste.score(tired), lessThan(taste.score(fresh)));
    });

    test('a rested subject comes back', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 4; i++) {
        taste.noteDealt(card('s$i', 'science'));
      }
      final tired = taste.fatigue(card('t', 'science'));
      for (var i = 0; i < 5; i++) {
        taste.ageOneDay();
      }
      expect(taste.fatigue(card('t', 'science')), lessThan(tired * 0.2));
    });

    test('the unknown is worth more than the known', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 20; i++) {
        taste.learn(card('k$i', 'science'), Signal.read);
      }
      expect(
        taste.curiosity(card('new', 'philosophy')),
        greaterThan(taste.curiosity(card('old', 'science'))),
      );
    });

    test('a card is pitched where the reader can win it', () {
      final taste = ReaderTaste();
      final easy = card('e', 'science', challenge: _pick);
      final hard = card(
        'h',
        'science',
        challenge: _pick,
        difficulty: Difficulty.hard,
      );
      // Someone who gets nearly everything easy right and almost nothing hard
      // is served the level in between, not the one they always win.
      const measured = {Difficulty.easy: 0.98, Difficulty.hard: 0.3};
      expect(taste.fit(hard, measured), lessThan(taste.fit(easy, measured)));
      expect(
        taste.fit(card('m', 'science', challenge: _pick), {
          Difficulty.easy: 0.75,
        }),
        1.0,
      );
    });

    test('a card that tells you something is not scored on being winnable', () {
      final taste = ReaderTaste();
      expect(taste.fit(card('r', 'science'), {Difficulty.easy: 0.1}), 0);
    });

    test('the move you keep missing is worth showing again', () {
      final taste = ReaderTaste();
      final weak = card(
        'w',
        'science',
        challenge: _pick,
        principle: Principle.baseRate,
      );
      final other = card(
        'o',
        'science',
        challenge: _pick,
        principle: Principle.anchoring,
      );
      expect(
        taste.score(weak, weakMoves: {Principle.baseRate}),
        greaterThan(taste.score(other, weakMoves: {Principle.baseRate})),
      );
    });
  });

  group('A day dealt for a reader', () {
    final pool = [
      for (var i = 0; i < 8; i++)
        card('science-$i', 'science', challenge: _pick),
      for (var i = 0; i < 8; i++)
        card('history-$i', 'history', challenge: _pick),
      for (var i = 0; i < 4; i++) card('nature-$i', 'nature'),
      for (var i = 0; i < 4; i++) card('space-$i', 'space'),
    ];

    List<Pill> deal(ReaderTaste taste, {DateTime? on}) => pillsForDate(
      on ?? DateTime(2026, 3, 14),
      taste: taste,
      catalogue: pool,
    );

    test('the same day comes out the same way twice', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 6; i++) {
        taste.learn(card('h$i', 'history'), Signal.saved);
      }
      final first = deal(taste).map((p) => p.id).toList();
      final second = deal(taste).map((p) => p.id).toList();
      expect(first, second);
    });

    test('a liked subject turns up more than a skipped one', () {
      final liked = ReaderTaste();
      for (var i = 0; i < 15; i++) {
        liked.learn(card('h$i', 'history'), Signal.saved);
        liked.learn(card('s$i', 'science'), Signal.skipped);
      }

      // Counted over a fortnight rather than one day: a single deck is five
      // cards and the wildcard slot is one of them, so any one day is a small
      // sample of an algorithm that is supposed to be right on average.
      var history = 0;
      var science = 0;
      for (var day = 1; day <= 14; day++) {
        for (final pill in deal(liked, on: DateTime(2026, 3, day))) {
          if (pill.topicKey == 'history') history++;
          if (pill.topicKey == 'science') science++;
        }
      }
      expect(history, greaterThan(science * 2));

      // And not only that: the skipped subject still turns up. A model that
      // drives a subject to zero has closed the only door through which it
      // could ever learn it was wrong about it.
      expect(science, greaterThan(0));
    });

    test('the wildcard slot is a card the model did not choose', () {
      // Everything is disliked except history, so any non-history card in the
      // deck can only have arrived through the slot that is not the model's
      // to fill.
      final narrow = ReaderTaste();
      for (var i = 0; i < 20; i++) {
        narrow.learn(card('h$i', 'history'), Signal.saved);
        narrow.learn(card('s$i', 'science'), Signal.skipped);
      }
      var wildcards = 0;
      for (var day = 1; day <= 10; day++) {
        for (final pill in deal(narrow, on: DateTime(2026, 3, day))) {
          if (pill.topicKey == 'science') wildcards++;
        }
      }
      expect(wildcards, inInclusiveRange(1, 10));
    });

    test('a liked subject does not become the only subject', () {
      final narrow = ReaderTaste();
      for (var i = 0; i < 20; i++) {
        narrow.learn(card('h$i', 'history'), Signal.saved);
        narrow.learn(card('s$i', 'science'), Signal.skipped);
        narrow.learn(card('n$i', 'nature'), Signal.skipped);
        narrow.learn(card('p$i', 'space'), Signal.skipped);
      }
      final subjects = <String>{};
      for (var day = 1; day <= 14; day++) {
        for (final pill in deal(narrow, on: DateTime(2026, 3, day))) {
          subjects.add(pill.topicKey);
        }
      }
      // Exploration is the point: a model that only ever serves its own best
      // guess never finds out it was wrong.
      expect(subjects.length, greaterThan(1));
    });

    test('a reader the app knows nothing about still gets a full day', () {
      expect(deal(ReaderTaste()).length, kPillsPerDay);
    });
  });

  group('Carrying a taste to another phone', () {
    test('it survives being written and read back', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 5; i++) {
        taste.learn(card('a$i', 'science', tags: ['ai']), Signal.saved);
      }
      taste.noteDealt(card('a', 'science'));
      final back = ReaderTaste.fromJson(taste.toJson());
      expect(back.pullOf('topic:science'), closeTo(taste.pullOf('topic:science'), 0.001));
      expect(back.pullOf('tag:ai'), closeTo(taste.pullOf('tag:ai'), 0.001));
      expect(back.fatigue(card('a', 'science')), taste.fatigue(card('a', 'science')));
    });

    test('rubbish on disk is a reader the app knows nothing about', () {
      expect(ReaderTaste.fromJson('not a taste').evidence, 0);
      expect(ReaderTaste.fromJson({'t': {'topic:science': 'nope'}}).evidence, 0);
    });

    test('two phones add up rather than one winning', () {
      final phone = ReaderTaste();
      for (var i = 0; i < 10; i++) {
        phone.learn(card('a$i', 'science'), Signal.saved);
      }
      final tablet = ReaderTaste();
      for (var i = 0; i < 10; i++) {
        tablet.learn(card('b$i', 'science'), Signal.skipped);
      }
      final both = phone.mergedWith(tablet);
      expect(both.traits['topic:science']!.met, 20);
      // Equal evidence either way, so neither device's verdict stands alone.
      expect(both.pullOf('topic:science'), closeTo(0, 0.2));
    });

    test('the quieter phone does not overrule the busier one', () {
      final busy = ReaderTaste();
      for (var i = 0; i < 40; i++) {
        busy.learn(card('a$i', 'space'), Signal.saved);
      }
      final quiet = ReaderTaste()..learn(card('b', 'space'), Signal.skipped);
      expect(busy.mergedWith(quiet).pullOf('topic:space'), greaterThan(0.5));
    });
  });

  group('A card written somewhere else', () {
    Map<String, dynamic> wire() => {
      'id': 'space-g7',
      'topic': 'space',
      'question': 'How long does sunlight take to reach us?',
      'answer': 'About eight minutes and twenty seconds.',
      'barMove': 'Nothing you see in the sky is now.',
      'source': 'NASA',
      'difficulty': 'medium',
      'move': 'estimation',
      'tags': ['light', 'distance'],
      'tone': 'startling',
      'seconds': 40,
      'hint': 'Distance over speed.',
      'trap': 'That light is instant.',
      'steps': ['150 million km', 'divided by 300,000 km/s', 'is 500 seconds'],
      'challenge': {'kind': 'number', 'answer': 500, 'unit': 'seconds'},
    };

    test('it arrives as a card, palette and all', () {
      final pill = cardFromJson(wire())!;
      expect(pill.id, 'space-g7');
      expect(pill.topic, 'Space');
      expect(pill.color, kTopics['space']!.color);
      expect(pill.tone, Tone.startling);
      expect(pill.tags, ['light', 'distance']);
      expect(pill.principle, Principle.estimation);
      expect(pill.challenge, isA<TypeNumber>());
      expect(pill.challenge.accepts('500'), isTrue);
    });

    test('it survives a round trip through the cache', () {
      final once = cardFromJson(wire())!;
      final twice = cardFromJson(cardToJson(once))!;
      expect(twice.facets, once.facets);
      expect(twice.steps, once.steps);
      expect(twice.challenge.toJson(), once.challenge.toJson());
    });

    test('a card missing what makes it a card is refused', () {
      expect(cardFromJson({...wire(), 'id': ''}), isNull);
      expect(cardFromJson({...wire(), 'question': ''}), isNull);
      expect(cardFromJson({...wire(), 'topic': 'astrology'}), isNull);
      expect(cardFromJson('a string'), isNull);
    });

    test('a graded card with no explanation is refused', () {
      // The app's whole claim is that it tells you why you were wrong. A
      // card that cannot is worse than one card fewer.
      expect(cardFromJson({...wire(), 'steps': <String>[]}), isNull);
    });

    test('a broken challenge degrades to a card that just tells you', () {
      final off = cardFromJson({
        ...wire(),
        'steps': <String>[],
        'challenge': {'kind': 'pick', 'options': ['a', 'b'], 'correct': 9},
      });
      expect(off, isNotNull);
      expect(off!.challenge, isA<NoChallenge>());
      expect(off.asksSomething, isFalse);
    });
  });

  group('Cards written after the build shipped', () {
    Map<String, dynamic> written(String id, String question) => {
      'id': id,
      'topic': 'nature',
      'question': question,
      'answer': 'Because of how bees see ultraviolet.',
      'barMove': 'A flower is a landing strip.',
      'source': 'Chittka, 1992',
      'difficulty': 'easy',
      'tags': ['bees'],
      'tone': 'playful',
      'challenge': {'kind': 'none'},
    };

    test('they are dealt alongside the ones that shipped', () {
      expect(CardCatalog.cards.length, kPillPool.length);
      CardCatalog.adopt([cardFromJson(written('nature-z1', 'Why?'))!]);
      expect(CardCatalog.writtenCount, 1);
      expect(CardCatalog.cards.length, kPillPool.length + 1);
      expect(CardCatalog.cards.any((p) => p.id == 'nature-z1'), isTrue);
    });

    test('one can correct a card that shipped with a mistake in it', () {
      final wrong = kPillPool.first;
      CardCatalog.adopt([
        cardFromJson({...written(wrong.id, 'The corrected question'), 'topic': 'nature'})!,
      ]);
      // Same count, not one more: the id is the identity of a card, so
      // rewriting one does not leave the old one on the shelf.
      expect(CardCatalog.cards.length, kPillPool.length);
      final now = CardCatalog.cards.firstWhere((p) => p.id == wrong.id);
      expect(now.question, 'The corrected question');
    });

    test('a second fetch replaces rather than doubles the catalogue', () {
      CardCatalog.adopt([cardFromJson(written('nature-z1', 'One?'))!]);
      CardCatalog.adopt([cardFromJson(written('nature-z2', 'Two?'))!]);
      expect(CardCatalog.writtenCount, 1);
      expect(CardCatalog.cards.any((p) => p.id == 'nature-z1'), isFalse);
    });

    test('the cache is what a reader on a train has', () async {
      SharedPreferences.setMockInitialValues({
        'knowit.writtenCards': jsonEncode([written('nature-z9', 'Cached?')]),
      });
      await CardFeed.loadCache(await SharedPreferences.getInstance());
      expect(CardCatalog.cards.any((p) => p.id == 'nature-z9'), isTrue);
    });

    test('a cache that will not read costs the reader nothing', () async {
      SharedPreferences.setMockInitialValues({
        'knowit.writtenCards': 'half a json file',
      });
      await CardFeed.loadCache(await SharedPreferences.getInstance());
      expect(CardCatalog.cards.length, kPillPool.length);
    });

    test('a card in the cache that no longer reads is skipped, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        'knowit.writtenCards': jsonEncode([
          written('nature-z1', 'Fine?'),
          {'id': 'nature-z2', 'topic': 'astrology'},
        ]),
      });
      await CardFeed.loadCache(await SharedPreferences.getInstance());
      expect(CardCatalog.writtenCount, 1);
    });

    test('signing out forgets them', () async {
      SharedPreferences.setMockInitialValues({
        'knowit.writtenCards': jsonEncode([written('nature-z1', 'Gone?')]),
      });
      final prefs = await SharedPreferences.getInstance();
      await CardFeed.loadCache(prefs);
      await CardFeed.clear(prefs);
      expect(CardCatalog.writtenCount, 0);
      expect(prefs.getString('knowit.writtenCards'), isNull);
    });
  });

  group('Saying it out loud', () {
    test('says nothing on evidence too thin to stand behind', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 3; i++) {
        taste.learn(card('a$i', 'science'), Signal.saved);
      }
      // The deck may act on a hunch — that is what the wildcard slot is
      // for. Telling somebody what they like is a different claim.
      expect(taste.leanings(), isEmpty);
    });

    test('reports what it would stand behind, strongest first', () {
      final taste = ReaderTaste();
      for (var i = 0; i < 12; i++) {
        taste.learn(card('h$i', 'history', tone: Tone.sober), Signal.saved);
        taste.learn(card('s$i', 'science'), Signal.skipped);
      }
      final said = taste.leanings();
      expect(said, isNotEmpty);
      expect(said.first.pull.abs(), greaterThanOrEqualTo(said.last.pull.abs()));
      expect(
        said.where((l) => l.facet == 'topic:history').single.isToward,
        isTrue,
      );
      expect(
        said.where((l) => l.facet == 'topic:science').single.isToward,
        isFalse,
      );
    });

    test('a facet reads as something a person would say', () {
      expect(facetLabel('topic:human_body'), 'Human body');
      expect(facetLabel('tag:money'), 'money');
      expect(facetLabel('format:estimate'), 'estimating');
      expect(facetLabel('tone:playful'), "cards that are enjoying themselves");
      expect(facetLabel('move:baseRate'), 'Base rates');
      expect(facetLabel('level:hard'), 'the hard ones');
      // Anything a later build invents still reads as itself rather than
      // crashing a screen.
      expect(facetLabel('mood:blue'), 'blue');
      expect(facetLabel('nonsense'), 'nonsense');
    });
  });
}
