import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'card_page_store_base.dart';

export 'card_page_store_base.dart';

/// The pages kept in the app's cache directory, which the phone may clear
/// when it runs short of room: a page cleared is fetched again.
PageStore pageStoreOnThisPhone() => FilePageStore();

/// One file per page, under `card_pages/` in [directory]; the [most] most
/// recently wanted are kept and the rest let go.
class FilePageStore implements PageStore {
  FilePageStore({Future<Directory> Function()? directory, this.most = 400})
    : _directory = directory ?? getApplicationCacheDirectory;

  /// How many pages are kept, at the most.
  final int most;

  final Future<Directory> Function() _directory;
  Future<Directory>? _home;
  int _writes = 0;

  Future<Directory> get _folder => _home ??= () async {
    final Directory d = Directory('${(await _directory()).path}/card_pages');
    await d.create(recursive: true);
    return d;
  }();

  /// The file a page is kept in: its name with nothing a path could misread.
  static String fileName(String ref) =>
      ref.replaceAll(RegExp(r'[^A-Za-z0-9.-]'), '_');

  @override
  Future<String?> read(String ref) async {
    final File f = File('${(await _folder).path}/${fileName(ref)}');
    if (!await f.exists()) return null;
    final String html = await f.readAsString();
    // Wanted again: the last to be let go.
    try {
      await f.setLastModified(DateTime.now());
    } catch (_) {}
    return html;
  }

  @override
  Future<void> write(String ref, String html) async {
    final Directory d = await _folder;
    final String name = fileName(ref);
    final File part = File('${d.path}/$name.part');
    await part.writeAsString(html, flush: true);
    await part.rename('${d.path}/$name');
    if (++_writes % 16 == 1) await _trim(d);
  }

  Future<void> _trim(Directory d) async {
    final List<File> files = [
      await for (final FileSystemEntity e in d.list())
        if (e is File && !e.path.endsWith('.part')) e,
    ];
    if (files.length <= most) return;
    final List<(File, DateTime)> dated = [
      for (final File f in files) (f, await f.lastModified()),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (File f, DateTime _) in dated.take(files.length - most)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
