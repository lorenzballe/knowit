// A card's picture fetched once and kept on the phone (CachedThumb,
// FileThumbStore), the day's fetched ahead, and the card's outline in grey,
// with nothing on it, while one is still on its way (CardThumb, CardSkeleton).
//
//   flutter test test/web/cached_thumb_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/models/pill.dart';
import 'package:astuto/theme.dart';
import 'package:astuto/widgets/card_skeleton.dart';
import 'package:astuto/widgets/web/cached_thumb.dart';
import 'package:astuto/widgets/web/card_thumb.dart';
import 'package:astuto/widgets/web/thumb_store_io.dart';

import '../flutter_test_config.dart' show NoPicture;
import 'thumbs_harness.dart';

/// A picture that comes when the test says.
class _Later extends ImageProvider<_Later> {
  final Completer<ImageInfo> done = Completer();

  @override
  Future<_Later> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_Later>(this);

  @override
  ImageStreamCompleter loadImage(_Later key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(done.future);
}

void main() {
  final Uri a = Uri.parse('https://astutetheapp.com/cards/thumbs/a.webp?v=1');
  final Uri b = Uri.parse('https://astutetheapp.com/cards/thumbs/b.webp?v=1');
  final Uri c = Uri.parse('https://astutetheapp.com/cards/thumbs/c.webp?v=1');

  late MemoryThumbStore store;
  late List<Uri> fetched;

  setUp(() {
    store = MemoryThumbStore();
    fetched = [];
    CachedThumb.store = store;
    CachedThumb.download = (url) async {
      fetched.add(url);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (url == c) throw Exception('no connection');
      return Uint8List.fromList([1, 2, 3]);
    };
  });

  test('a picture is fetched once, kept, and after that read from the '
      'phone', () async {
    expect(await CachedThumb.bytesOf(a), [1, 2, 3]);
    expect(await store.has(CachedThumb.nameOf(a)), isTrue);
    expect(await CachedThumb.bytesOf(a), [1, 2, 3]);
    expect(fetched, [a]);
  });

  test('asked for twice at once, it is fetched once', () async {
    await Future.wait([CachedThumb.bytesOf(b), CachedThumb.bytesOf(b)]);
    expect(fetched, [b]);
  });

  test('a new version of a card is a new picture', () {
    expect(
      CachedThumb.nameOf(a),
      isNot(CachedThumb.nameOf(a.replace(query: 'v=2'))),
    );
  });

  test('warming fetches only what the phone does not keep, and one that '
      'will not come is let be', () async {
    await CachedThumb.bytesOf(a);
    fetched.clear();
    await CachedThumb.warm([a, b, c]);
    expect(fetched.toSet(), {b, c});
    expect(await store.has(CachedThumb.nameOf(b)), isTrue);
    expect(await store.has(CachedThumb.nameOf(c)), isFalse);
  });

  test(
    'on the phone: kept in files, the oldest let go past the most',
    () async {
      final Directory dir = await Directory.systemTemp.createTemp('thumbs');
      addTearDown(() => dir.delete(recursive: true));
      final FileThumbStore files = FileThumbStore(
        directory: () async => dir,
        most: 3,
      );
      expect(await files.read('thumbs/x.webp?v=1'), isNull);
      for (int i = 0; i < 30; i++) {
        await files.write('thumbs/$i.webp?v=1', Uint8List.fromList([i]));
      }
      expect(await files.read('thumbs/29.webp?v=1'), [29]);
      expect(await files.has('thumbs/29.webp?v=1'), isTrue);
      final int kept = (await Directory(
        '${dir.path}/card_thumbs',
      ).list().toList()).length;
      expect(kept, lessThanOrEqualTo(3 + 24), reason: 'trimmed as it goes');
    },
  );

  group('while a picture comes', () {
    tearDown(() {
      PillBank.reset();
      CardThumb.image = NoPicture.new;
    });

    testWidgets('the card\'s outline in grey and nothing on it; then the card, '
        'with what sits on it', (tester) async {
      final Pill card = pagedCards().first;
      PillBank.adopt(bankWithPictures({card.id}));
      final Pill pill = PillBank.byId(card.id)!;
      final _Later later = _Later();
      CardThumb.image = (url) => later;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAstutoTheme(Brightness.dark),
          home: Center(
            child: SizedBox(
              width: 200,
              height: 330,
              child: CardThumb(
                pill: pill,
                side: CardSide.front,
                foreground: TextButton(
                  onPressed: () {},
                  child: const Text('save'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CardSkeleton), findsOneWidget);
      // Nothing on the card until the card is there: not seen, not tapped.
      expect(find.text('save').hitTestable(), findsNothing);
      final AnimatedOpacity hidden = tester.widget(
        find.ancestor(
          of: find.text('save'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(hidden.opacity, 0);

      final ui.Image image = await tester.runAsync(
        () => createTestImage(width: 4, height: 6),
      ) as ui.Image;
      later.done.complete(ImageInfo(image: image));
      await tester.pump();
      await tester.pump(CardThumb.fade);
      await tester.pump(const Duration(milliseconds: 50));
      final AnimatedOpacity shown = tester.widget(
        find.ancestor(
          of: find.text('save'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(shown.opacity, 1);
      expect(find.text('save').hitTestable(), findsOneWidget);
      // The outline under it holds still.
      expect(
        tester.widget<CardSkeleton>(find.byType(CardSkeleton)).moving,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the outline fits any box, the shelf\'s or a tile\'s', (
      tester,
    ) async {
      for (final Size box in const [
        Size(324, 452),
        Size(120, 200),
        Size(160, 90),
        Size(60, 60),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAstutoTheme(Brightness.light),
            home: Center(
              child: SizedBox.fromSize(size: box, child: const CardSkeleton()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: '$box');
      }
    });
  });
}
