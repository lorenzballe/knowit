import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_json.dart';
import 'package:astuto/data/card_page_store_io.dart';
import 'package:astuto/data/card_pages.dart';
import 'package:astuto/models/pill.dart';

const String _html = '<article class="card" id="card">Hi</article>';

String _v(String html) =>
    sha256.convert(utf8.encode(html)).toString().substring(0, 12);

WebFace _named(String id, [String html = _html]) =>
    WebFace(page: 'pages/$id.html?v=${_v(html)}', label: 'A page.');

Pill _card(String id, {WebFace? web}) => cardFromJson({
  'id': id,
  'topic': 'medicine',
  'kind': 'page',
  'difficulty': 'medium',
  'principle': 'confounding',
  'question': 'Which group of children caught the most polio in 1954?',
  'answer': 'The children given salt water.',
  'move': 'Who picks a treatment can matter as much as the treatment.',
  'web': {
    'kit': 1,
    'label': 'A table with three groups of children and ten chips to stake.',
    if (web?.html != null) 'html': web!.html else 'page': web!.page,
  },
  'source': 'Francis et al., 1955',
});

void main() {
  late List<Uri> asked;
  late MemoryPageStore store;
  late CardPages pages;
  String? Function(Uri url) answer = (_) => _html;

  setUp(() {
    asked = [];
    store = MemoryPageStore();
    answer = (_) => _html;
    pages = CardPages(
      store: store,
      fetch: (url) async {
        asked.add(url);
        return answer(url);
      },
    );
  });

  test('a page inside its card is never fetched', () async {
    expect(await pages.html(const WebFace(html: _html)), _html);
    expect(asked, isEmpty);
    expect(pages.inHand(const WebFace(html: _html)), isTrue);
  });

  test('a named page is fetched from beside the bank, once', () async {
    final WebFace face = _named('medicine-a');
    expect(pages.inHand(face), isFalse);
    final List<String> both = await Future.wait([
      pages.html(face),
      pages.html(face),
    ]);
    expect(both, [_html, _html]);
    expect(asked, [Uri.parse('$kCardsBase${face.page}')]);
    expect(
      asked.single.toString(),
      startsWith('https://astutetheapp.com/cards/pages/medicine-a.html?v='),
    );
    expect(pages.inHand(face), isTrue);
    expect(await pages.html(face), _html);
    expect(asked, hasLength(1), reason: 'held in memory');
  });

  test('a page met once opens again without the network', () async {
    final WebFace face = _named('medicine-a');
    await pages.html(face);
    await Future<void>.delayed(Duration.zero);
    expect(store.pages[face.page], _html);
    pages.forget();
    answer = (_) => null;
    expect(await pages.html(face), _html);
    expect(asked, hasLength(1));
  });

  test('a page never met, with no signal, cannot be had', () async {
    answer = (_) => null;
    await expectLater(pages.html(_named('medicine-a')), throwsStateError);
    answer = (_) => throw const SocketException('offline');
    await expectLater(
      pages.html(_named('medicine-b')),
      throwsA(isA<SocketException>()),
    );
    // Nothing failed is kept as if it had come.
    answer = (_) => _html;
    expect(await pages.html(_named('medicine-a')), _html);
  });

  test(
    'a page that is not the one its name promises is shown but not kept',
    () async {
      const String stale = '<article class="card" id="card">Old</article>';
      answer = (_) => stale;
      final WebFace face = _named('medicine-a');
      expect(await pages.html(face), stale);
      await Future<void>.delayed(Duration.zero);
      expect(store.pages, isEmpty);
      expect(CardPages.matches(face.page!, _html), isTrue);
      expect(CardPages.matches(face.page!, stale), isFalse);
      expect(CardPages.matches('pages/a.html', stale), isTrue);
    },
  );

  test('the next pages are fetched before their cards are on top', () async {
    final List<Pill> deck = [
      for (int i = 0; i < 3; i++)
        _card('medicine-$i', web: _named('medicine-$i')),
      _card('medicine-inline', web: const WebFace(html: _html)),
    ];
    pages.warm(deck);
    await Future<void>.delayed(Duration.zero);
    expect(asked.map((u) => u.path), [
      '/cards/pages/medicine-0.html',
      '/cards/pages/medicine-1.html',
      '/cards/pages/medicine-2.html',
    ]);
    for (final Pill p in deck) {
      expect(pages.inHand(p.web!), isTrue, reason: p.id);
    }
    pages.warm(deck);
    await Future<void>.delayed(Duration.zero);
    expect(asked, hasLength(3), reason: 'nothing in hand is fetched again');
  });

  test('memory holds the most recently wanted pages only', () async {
    for (int i = 0; i <= CardPages.held; i++) {
      await pages.html(_named('medicine-$i'));
    }
    expect(pages.inHand(_named('medicine-0')), isFalse);
    expect(pages.inHand(_named('medicine-${CardPages.held}')), isTrue);
  });

  group('the pages kept on the phone', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('card_pages'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('are files named after the page, read back as written', () async {
      final FilePageStore files = FilePageStore(directory: () async => tmp);
      const String ref = 'pages/medicine-a.html?v=0123456789ab';
      expect(await files.read(ref), isNull);
      await files.write(ref, _html);
      expect(await files.read(ref), _html);
      expect(
        File('${tmp.path}/card_pages/${FilePageStore.fileName(ref)}')
            .existsSync(),
        isTrue,
      );
      expect(
        FilePageStore.fileName(ref),
        'pages_medicine-a.html_v_0123456789ab',
      );
    });

    test('let the least recently wanted go past the most they keep', () async {
      final FilePageStore first = FilePageStore(directory: () async => tmp);
      for (int i = 0; i < 5; i++) {
        await first.write('pages/p$i.html', _html);
        File(
          '${tmp.path}/card_pages/${FilePageStore.fileName('pages/p$i.html')}',
        ).setLastModifiedSync(DateTime(2026, 1, 1, 0, i));
      }
      // A run's first page kept trims what earlier runs left.
      final FilePageStore next = FilePageStore(
        directory: () async => tmp,
        most: 2,
      );
      await next.write('pages/last.html', _html);
      final List<String> left = [
        for (final FileSystemEntity e in Directory(
          '${tmp.path}/card_pages',
        ).listSync())
          e.uri.pathSegments.last,
      ]..sort();
      expect(left, [
        FilePageStore.fileName('pages/last.html'),
        FilePageStore.fileName('pages/p4.html'),
      ]);
    });
  });
}
