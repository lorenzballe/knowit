import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/widgets/web/card_kit.dart';
import 'package:astuto/widgets/web/page_messages.dart';

/// A kit of a few small files, so what is put where can be read off.
class _Kit extends KitFiles {
  _Kit(this.files);

  final Map<String, String> files;

  @override
  Set<String> get paths => files.keys.toSet();

  @override
  Uint8List bytes(String path) => utf8.encode(files[path]!);
}

final _Kit _small = _Kit({
  'astute-bridge.js': 'window.Astute={bridge:1};',
  'astute-card.css': '.card{color:red}',
  'astute-card.js': 'const Kit={single(){}}; if (a</script>b) {} <!-- x',
  'fonts.css':
      '@font-face{font-family:"Fraunces";font-style:normal;src:url(fonts/F.woff2)}'
      '@font-face{font-family:"Fraunces";font-style:italic;src:url(fonts/FrauncesItalic-latin.woff2)}'
      '@font-face{font-family:"Caveat";font-style:normal;src:url(fonts/Caveat-latin.woff2)}',
  'fonts/F.woff2': 'regular',
  'fonts/FrauncesItalic-latin.woff2': 'italic',
  'fonts/Caveat-latin.woff2': 'hand',
  'vendor/gsap.min.js': 'window.gsap={};',
  'vendor/three.module.min.js': 'export const three = 3;',
  'vendor/rive.wasm': 'wasm',
});

const PageEnv _env = PageEnv(language: 'it', note: '</script><b>');

void main() {
  group('a link stands for a kit file, or for nothing', () {
    final Set<String> paths = _small.paths;

    test('the kit by its own path, as a card links it', () {
      expect(kitPathOf('kit/astute-card.css', paths), 'astute-card.css');
      expect(
        kitPathOf('kit/vendor/gsap.min.js?v=2', paths),
        'vendor/gsap.min.js',
      );
      // The prototypes link the kit two folders up.
      expect(kitPathOf('../../kit/astute-card.js', paths), 'astute-card.js');
    });

    test('a library from a CDN is the kit\'s copy of it, by name', () {
      expect(
        kitPathOf(
          'https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js',
          paths,
        ),
        'vendor/gsap.min.js',
      );
      expect(
        kitPathOf(
          'https://unpkg.com/three@0.170.0/build/three.module.min.js',
          paths,
        ),
        'vendor/three.module.min.js',
      );
      expect(
        kitPathOf(
          'https://fonts.googleapis.com/css2?family=Fraunces:wght@800',
          paths,
        ),
        'fonts.css',
      );
    });

    test('anything else is nothing', () {
      expect(kitPathOf('https://example.org/tracker.js', paths), isNull);
      expect(
        kitPathOf('https://cdn.jsdelivr.net/npm/left-pad/index.js', paths),
        isNull,
      );
      expect(kitPathOf('kit/vendor/missing.js', paths), isNull);
      expect(kitPathOf('data:text/javascript,1', paths), isNull);
      expect(kitPathOf('//evil.example/x.js', paths), isNull);
    });
  });

  group('the page the app shows', () {
    const String card = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<link rel="preconnect" href="https://fonts.gstatic.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces">
<link rel="stylesheet" href="kit/astute-card.css">
<link rel="stylesheet" href="https://example.org/theirs.css">
<script src="kit/vendor/gsap.min.js"></script>
<script src="https://example.org/tracker.js"></script>
<script type="importmap">{"imports":{"three":"kit/vendor/three.module.min.js"}}</script>
<style>.x{background:url(kit/fonts/F.woff2)}</style>
<article class="card" id="card"><div class="in"><h2 class="q">A <em>real</em> question?</h2></div></article>
<script src="kit/astute-card.js"></script>
<script>Kit.url('vendor/rive.wasm'); Kit.single();</script>''';

    final String page = assemblePage(card, env: _env, files: _small);

    test(
      'the app comes first: the policy, the viewport, the env, the bridge',
      () {
        final int policy = page.indexOf('Content-Security-Policy');
        final int env = page.indexOf('window.ASTUTE_ENV=');
        final int bridge = page.indexOf('window.Astute={bridge:1}');
        final int kit = page.indexOf('.card{color:red}');
        expect(policy, greaterThan(page.indexOf('<meta charset')));
        expect(env, greaterThan(policy));
        expect(bridge, greaterThan(env));
        expect(kit, greaterThan(bridge));
        expect('user-scalable=no'.allMatches(page), hasLength(1));
        expect(page, isNot(contains('content="width=device-width">')));
      },
    );

    test('the env is the reader\'s, and cannot close its own script', () {
      final String line = RegExp(r'window\.ASTUTE_ENV=(.*?);</script>')
          .firstMatch(page)!
          .group(1)!;
      expect(line, isNot(contains('</script')));
      final Map<String, Object?> env = jsonDecode(line) as Map<String, Object?>;
      expect(env['lang'], 'it');
      expect(env['note'], '</script><b>');
    });

    test('every kit file is inside it, and nothing else is linked', () {
      expect(
        page,
        contains('<style data-kit="astute-card.css">.card{color:red}</style>'),
      );
      expect(
        page,
        contains(
          '<script data-kit="vendor/gsap.min.js">window.gsap={};</script>',
        ),
      );
      expect(page, isNot(contains('example.org')));
      expect(page, isNot(contains('preconnect')));
      expect(page, isNot(contains('src="kit/')));
      expect(page, isNot(contains('href="kit/')));
      // A script carried inside cannot end the element it is in.
      expect(page, contains(r'if (a<\/script>b) {} <\!-- x'));
    });

    test('the fonts are data, and only the faces the page uses', () {
      expect(
        page,
        contains(
          'data:font/woff2;base64,${base64Encode(utf8.encode('regular'))}',
        ),
      );
      expect(
        page,
        contains(
          'data:font/woff2;base64,${base64Encode(utf8.encode('italic'))}',
        ),
      );
      // No --hand, no Caveat: the handwriting stays out.
      expect(page, isNot(contains('Caveat')));
      // The page's own style is given the file it names, too.
      expect(page, contains('.x{background:url(data:font/woff2;base64,'));
    });

    test('a module map points at the module itself, a named file is kept as data', () {
      final Match map = RegExp(r'<script type="importmap">(.*?)</script>')
          .firstMatch(page)!;
      final Object? imports = (jsonDecode(map.group(1)!) as Map)['imports'];
      expect(
        (imports as Map)['three'],
        startsWith('data:text/javascript;base64,'),
      );
      expect(
        page,
        contains(
          '<script type="application/octet-stream" data-mime="application/wasm" '
          'data-kit-url="vendor/rive.wasm">${base64Encode(utf8.encode('wasm'))}</script>',
        ),
      );
    });

    test('only what a page uses is read from the kit', () {
      final Set<String> needed = filesFor(card, _small.paths);
      expect(
        needed,
        containsAll([
          'astute-bridge.js',
          'astute-card.css',
          'astute-card.js',
          'fonts.css',
          'vendor/gsap.min.js',
          'vendor/three.module.min.js',
          'vendor/rive.wasm',
          'fonts/F.woff2',
          'fonts/FrauncesItalic-latin.woff2',
        ]),
      );
      expect(needed, isNot(contains('fonts/Caveat-latin.woff2')));
    });
  });

  group('the kit the app ships', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test(
      'every file of it is an asset, and the template is put together whole',
      () async {
        final Set<String> shipped = await CardKit.instance.paths();
        final Directory kit = Directory('docs/cards/kit');
        for (final FileSystemEntity f in kit.listSync(recursive: true)) {
          if (f is! File) continue;
          final String path = f.path.substring(kit.path.length + 1);
          final bool kept =
              path.startsWith('fonts/') ||
              path.startsWith('vendor/') ||
              const {
                'astute-card.css',
                'astute-card.js',
                'astute-bridge.js',
                'fonts.css',
              }.contains(path);
          expect(shipped.contains(path), kept, reason: path);
        }

        final String template = File('tool/cards/web/template.html')
            .readAsStringSync();
        final String page = await CardKit.instance.page(template, _env);
        // Nothing left for the network: every link became the file.
        expect(
          RegExp(r'''(src|href)\s*=\s*["'](https?:|kit/)''').hasMatch(page),
          isFalse,
        );
        expect(page, contains('data-kit="vendor/gsap.min.js"'));
        expect(page, contains('data-kit="astute-card.js"'));
        expect(page, contains('font-family:"Fraunces"'));
        // The app's own Fraunces and Figtree, carried as data.
        final Uint8List fraunces = (await rootBundle.load(
          'docs/cards/kit/fonts/Fraunces.woff2',
        )).buffer.asUint8List();
        expect(page, contains(base64Encode(fraunces).substring(0, 200)));
        expect(
          page.length,
          lessThan(600 * 1024),
          reason: 'a card page loads in a moment',
        );
      },
    );
  });
}
