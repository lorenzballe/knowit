/// The card kit as the app carries it, and the page a free card is shown as.
///
/// A free card's page links the kit (docs/cards/kit) the way a page on the
/// site would — `kit/astute-card.css`, `kit/vendor/gsap.min.js`, a CDN copy
/// of a library, a Google Fonts stylesheet — and the app has every one of
/// those files with it, as assets. So before a page is shown, every link it
/// makes is replaced by the file itself: stylesheets and scripts inside the
/// page, fonts and binaries as data. The page that results needs nothing
/// from anywhere — it loads offline, on a first run, in a lift — and a
/// Content-Security-Policy says so: a page that tried to reach the network
/// would find it shut.
///
/// Ahead of everything the page says go two things of the app's own: one
/// line setting `window.ASTUTE_ENV` (the theme, the language, reduced
/// motion, sound, the size, the subject; see [PageEnv]) and the bridge
/// (docs/cards/kit/astute-bridge.js), so the page's first script already
/// knows where it is and how to speak.
///
/// Why the files go inside the page rather than beside it: a page loaded
/// from files on the phone runs from an origin of its own that WebViews keep
/// apart from the files next to it — modules, fonts and fetches across it
/// fail on one platform or another — and a page that is one string loads
/// the same way on Android, on iOS and in the web build's iframe.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'page_messages.dart';

/// Where the kit's files are among the app's assets.
const String kKitRoot = 'docs/cards/kit/';

/// The kit's files, read.
abstract class KitFiles {
  /// Every file, by its path inside the kit: `astute-card.css`,
  /// `vendor/gsap.min.js`, `fonts/Fraunces.woff2`.
  Set<String> get paths;

  /// A file's bytes. Only the files [filesFor] named are asked for.
  Uint8List bytes(String path);

  /// A file as text.
  String text(String path) => utf8.decode(bytes(path));

  /// A file as a data URL.
  String dataUrl(String path) =>
      'data:${mimeOf(path)};base64,${base64Encode(bytes(path))}';
}

/// The kit, from the app's assets, for every page shown.
class CardKit {
  CardKit({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// The one the app uses. Tests replace it.
  static CardKit instance = CardKit();

  Future<Set<String>>? _paths;
  final Map<String, Future<Uint8List>> _files = {};

  // The fonts and the libraries are the same few files on every page:
  // decoded and encoded once, not once a card.
  final Map<String, String> _texts = {};
  final Map<String, String> _urls = {};

  /// The kit's files the app was built with.
  Future<Set<String>> paths() =>
      _paths ??= AssetManifest.loadFromAssetBundle(_bundle)
          .then((manifest) => kitPathsOf(manifest.listAssets()));

  Future<Uint8List> _read(String path) => _files[path] ??= _bundle
      .load('$kKitRoot$path')
      .then(
        (data) =>
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

  /// [html] as the app shows it: whole, with [env] and the bridge first.
  Future<String> page(String html, PageEnv env) async {
    final Set<String> all = await paths();
    final Map<String, Uint8List> read = {
      for (final String path in filesFor(html, all)) path: await _read(path),
    };
    return assemblePage(html, env: env, files: _Read(this, all, read));
  }
}

class _Read extends KitFiles {
  _Read(this._kit, this.paths, this._bytes);

  final CardKit _kit;

  @override
  final Set<String> paths;
  final Map<String, Uint8List> _bytes;

  @override
  Uint8List bytes(String path) => _bytes[path]!;

  @override
  String text(String path) => _kit._texts[path] ??= super.text(path);

  @override
  String dataUrl(String path) => _kit._urls[path] ??= super.dataUrl(path);
}

/// The kit's paths among an app's asset keys.
Set<String> kitPathsOf(Iterable<String> assets) => {
  for (final String key in assets)
    if (key.startsWith(kKitRoot)) key.substring(kKitRoot.length),
};

/// The CDNs a card page may link a kit library from, as published pages
/// do (docs/cards/kit/LIBRERIE.md). The file is the kit's own copy, by name.
final RegExp _cdn = RegExp(
  r'^https?://(cdn\.jsdelivr\.net|unpkg\.com|cdnjs\.cloudflare\.com)/',
  caseSensitive: false,
);
final RegExp _googleFonts = RegExp(
  r'^https?://fonts\.googleapis\.com/css2?\b',
  caseSensitive: false,
);

/// The kit file a link in a page stands for, or null when it stands for
/// nothing the kit has: then the page will not get it, and nothing else.
String? kitPathOf(String ref, Set<String> paths) {
  final String bare = ref.trim().split(RegExp(r'[?#]')).first;
  if (_googleFonts.hasMatch(bare)) return 'fonts.css';
  if (_cdn.hasMatch(bare)) {
    final String name = bare.split('/').last;
    for (final String path in paths) {
      if (path.startsWith('vendor/') && path.split('/').last == name) {
        return path;
      }
    }
    return null;
  }
  if (bare.contains(':') || bare.startsWith('//') || bare.isEmpty) {
    return null;
  }
  // `kit/vendor/d3.min.js`, or the prototypes' `../../kit/astute-card.css`.
  final int at = bare.lastIndexOf('kit/');
  final String inKit = at >= 0
      ? bare.substring(at + 4)
      : bare.replaceFirst(RegExp(r'^(\./|\.\./)+'), '');
  return paths.contains(inKit) ? inKit : null;
}

final RegExp _linkTag = RegExp(r'<link\b[^>]*>', caseSensitive: false);
final RegExp _scriptWithSrc = RegExp(
  r'<script\b([^>]*\bsrc\s*=[^>]*)>\s*</script\s*>',
  caseSensitive: false,
);
final RegExp _importMap = RegExp(
  r'''(<script\b[^>]*\btype\s*=\s*["']importmap["'][^>]*>)([\s\S]*?)(</script\s*>)''',
  caseSensitive: false,
);
final RegExp _kitUrl = RegExp(r'''Kit\.url\(\s*['"]([^'"]+)['"]\s*\)''');
final RegExp _cssUrl = RegExp(r'''url\(\s*(['"]?)([^'")]+)\1\s*\)''');
final RegExp _styleBlock = RegExp(
  r'(<style\b[^>]*>)([\s\S]*?)(</style\s*>)',
  caseSensitive: false,
);
final RegExp _fontFace = RegExp(r'@font-face\s*\{[^}]*\}');
final RegExp _viewport = RegExp(
  r'''<meta\b[^>]*\bname\s*=\s*["']?viewport["']?[^>]*>''',
  caseSensitive: false,
);

String? _attr(String tag, String name) {
  final Match? m = RegExp(
    '\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\'|([^\\s>]+))',
    caseSensitive: false,
  ).firstMatch(tag);
  return m == null ? null : (m.group(1) ?? m.group(2) ?? m.group(3));
}

bool _isStylesheet(String tag) => (_attr(tag, 'rel') ?? '')
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .contains('stylesheet');

/// Which of the kit's faces a page draws with: the app's Fraunces and
/// Figtree always; Fraunces's italic, JetBrains Mono and Caveat only on a
/// page that uses them, since each is tens of kilobytes the page carries.
({bool italic, bool mono, bool hand}) _facesOf(String html) => (
  italic: RegExp(r'<(em|i)\b|italic', caseSensitive: false).hasMatch(html),
  mono: RegExp(r'\bmono\b|--mono|JetBrains').hasMatch(html),
  hand: RegExp(r'--hand|Caveat').hasMatch(html),
);

bool _faceWanted(String block, ({bool italic, bool mono, bool hand}) faces) {
  if (block.contains('JetBrains Mono')) return faces.mono;
  if (block.contains('Caveat')) return faces.hand;
  if (block.contains('font-style:italic')) return faces.italic;
  return true;
}

/// Every kit file [html] will carry once assembled: the bridge, what it
/// links, the fonts its stylesheets name, the files its import map and its
/// `Kit.url` calls point at.
Set<String> filesFor(String html, Set<String> paths) {
  final Set<String> out = {'astute-bridge.js'};
  void add(String? path) {
    if (path != null && paths.contains(path)) out.add(path);
  }

  for (final Match m in _linkTag.allMatches(html)) {
    final String tag = m.group(0)!;
    if (_isStylesheet(tag)) add(kitPathOf(_attr(tag, 'href') ?? '', paths));
  }
  for (final Match m in _scriptWithSrc.allMatches(html)) {
    add(kitPathOf(_attr(m.group(0)!, 'src') ?? '', paths));
  }
  for (final Match m in _importMap.allMatches(html)) {
    for (final String ref in _importTargets(m.group(2)!)) {
      add(kitPathOf(ref, paths));
    }
  }
  for (final Match m in _kitUrl.allMatches(html)) {
    add(kitPathOf(m.group(1)!, paths));
  }
  for (final Match m in _cssUrl.allMatches(html)) {
    add(kitPathOf(m.group(2)!, paths));
  }
  if (out.contains('fonts.css')) {
    final faces = _facesOf(html);
    for (final String path in paths) {
      if (!path.startsWith('fonts/')) continue;
      final String name = path.substring(6);
      final bool wanted = name.startsWith('FrauncesItalic')
          ? faces.italic
          : name.startsWith('JetBrainsMono')
          ? faces.mono
          : name.startsWith('Caveat')
          ? faces.hand
          : true;
      if (wanted) out.add(path);
    }
  }
  return out;
}

Iterable<String> _importTargets(String json) {
  try {
    final Object? map = jsonDecode(json);
    if (map is Map && map['imports'] is Map) {
      return (map['imports'] as Map).values.whereType<String>();
    }
  } on FormatException {
    // An import map the browser could not read either: left as it is.
  }
  return const [];
}

/// What a file is, for a data URL.
String mimeOf(String path) => switch (path.split('.').last.toLowerCase()) {
  'woff2' => 'font/woff2',
  'woff' => 'font/woff',
  'ttf' => 'font/ttf',
  'js' || 'mjs' => 'text/javascript',
  'css' => 'text/css',
  'json' => 'application/json',
  'wasm' => 'application/wasm',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'webp' => 'image/webp',
  'svg' => 'image/svg+xml',
  'mp3' => 'audio/mpeg',
  'mp4' => 'video/mp4',
  _ => 'application/octet-stream',
};

/// What a page may load, said to the WebView: nothing from a network, and
/// everything it needs from inside itself.
const String kPagePolicy =
    "default-src 'none'; "
    "script-src 'unsafe-inline' 'unsafe-eval' 'wasm-unsafe-eval' data: blob:; "
    "style-src 'unsafe-inline'; font-src data:; img-src data: blob:; "
    "media-src data: blob:; connect-src data: blob:; worker-src data: blob:; "
    "base-uri 'none'; form-action 'none'";

const String _viewportMeta =
    '<meta name="viewport" content="width=device-width,initial-scale=1,'
    'maximum-scale=1,user-scalable=no,viewport-fit=cover">';

/// Text put inside a `<script>`: nothing in it may close the element or
/// open a comment the HTML parser would read.
String _scriptText(String js) => js
    .replaceAll(RegExp(r'</script', caseSensitive: false), r'<\/script')
    .replaceAll('<!--', r'<\!--');

String _styleText(String css) =>
    css.replaceAll(RegExp(r'</style', caseSensitive: false), r'<\/style');

/// Stylesheet text with the kit files it points at as data. The kit's own
/// stylesheets name their fonts beside them, `fonts/…`, which is a kit
/// path too.
String _cssWithData(String css, KitFiles files) =>
    css.replaceAllMapped(_cssUrl, (m) {
      final String ref = m.group(2)!;
      if (ref.startsWith('data:')) return m.group(0)!;
      final String? path = kitPathOf(ref, files.paths);
      return path == null ? m.group(0)! : 'url(${files.dataUrl(path)})';
    });

/// [html] with the kit inside it, [env] and the bridge ahead of it, and a
/// policy that keeps it off the network. Links the kit has no file for are
/// dropped: what the page cannot have offline, it does not get at all.
///
/// The page's own markup is rewritten first and the kit's files are put in
/// last, so nothing here ever reads a library's code as if it were markup.
String assemblePage(
  String html, {
  required PageEnv env,
  required KitFiles files,
}) {
  final Set<String> paths = files.paths;
  final faces = _facesOf(html);

  // The page's own styles, with any kit file they name as data.
  String page = html.replaceAllMapped(
    _styleBlock,
    (m) => '${m.group(1)}${_cssWithData(m.group(2)!, files)}${m.group(3)}',
  );

  // An import map naming the kit's modules (three.js), pointed at the
  // modules themselves.
  page = page.replaceAllMapped(_importMap, (m) {
    final Object? map;
    try {
      map = jsonDecode(m.group(2)!);
    } on FormatException {
      return m.group(0)!;
    }
    if (map is! Map || map['imports'] is! Map) return m.group(0)!;
    final Map<String, Object?> imports = {
      for (final MapEntry<Object?, Object?> e
          in (map['imports'] as Map).entries)
        '${e.key}': switch (e.value) {
          final String ref => switch (kitPathOf(ref, paths)) {
            final String path => files.dataUrl(path),
            null => ref,
          },
          final Object? other => other,
        },
    };
    return '${m.group(1)}${jsonEncode({...map, 'imports': imports})}${m.group(3)}';
  });

  // Files the page asks the kit for by name, kept inside it as base64 for
  // Kit.url to turn into blob URLs: a block of data, never run.
  final StringBuffer kept = StringBuffer();
  final Set<String> named = {};
  for (final Match m in _kitUrl.allMatches(html)) {
    final String? path = kitPathOf(m.group(1)!, paths);
    if (path == null || !named.add(m.group(1)!)) continue;
    kept.write(
      '<script type="application/octet-stream" data-mime="${mimeOf(path)}" '
      'data-kit-url="${m.group(1)}">${base64Encode(files.bytes(path))}</script>',
    );
  }

  // The app's head: the policy, the viewport, where the page is, the bridge.
  page = page.replaceAll(_viewport, '');
  final String envJson = jsonEncode(env.toJson()).replaceAll('<', r'\u003c');
  final String head =
      '<meta http-equiv="Content-Security-Policy" content="$kPagePolicy">'
      '$_viewportMeta'
      '<script>window.ASTUTE_ENV=$envJson;</script>'
      '<script data-kit="astute-bridge.js">'
      '${_scriptText(files.text('astute-bridge.js'))}</script>'
      '$kept';
  final Match? at =
      RegExp(
        r'<meta\b[^>]*charset[^>]*>',
        caseSensitive: false,
      ).firstMatch(page) ??
      RegExp(r'<head\b[^>]*>', caseSensitive: false).firstMatch(page) ??
      RegExp(r'<html\b[^>]*>', caseSensitive: false).firstMatch(page);
  page = at == null
      ? '<meta charset="utf-8">$head$page'
      : '${page.substring(0, at.end)}$head${page.substring(at.end)}';

  // Last, the kit's stylesheets and scripts in place of their links.
  page = page.replaceAllMapped(_linkTag, (m) {
    final String tag = m.group(0)!;
    if (!_isStylesheet(tag)) return '';
    final String? path = kitPathOf(_attr(tag, 'href') ?? '', paths);
    if (path == null) return '';
    String css = files.text(path);
    if (path == 'fonts.css') {
      css = css.replaceAllMapped(
        _fontFace,
        (f) => _faceWanted(f.group(0)!, faces) ? f.group(0)! : '',
      );
    }
    return '<style data-kit="$path">'
        '${_styleText(_cssWithData(css, files))}</style>';
  });
  return page.replaceAllMapped(_scriptWithSrc, (m) {
    final String attrs = m.group(1)!;
    final String? path = kitPathOf(_attr(attrs, 'src') ?? '', paths);
    if (path == null) return '';
    final bool module = (_attr(attrs, 'type') ?? '').toLowerCase() == 'module';
    return '<script${module ? ' type="module"' : ''} data-kit="$path">'
        '${_scriptText(files.text(path))}</script>';
  });
}
