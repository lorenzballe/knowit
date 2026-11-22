import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'thumb_store_base.dart';

export 'thumb_store_base.dart';

/// The pictures kept in the app's cache directory, which the phone may clear
/// when it runs short of room: a picture cleared is fetched again.
ThumbStore thumbStoreOnThisPhone() => FileThumbStore();

/// One file per picture, under `card_thumbs/` in [directory]; the [most]
/// most recently wanted are kept and the rest let go. A picture is named by
/// its address, version and all, so a card drawn again is a new file and the
/// old one goes in time.
class FileThumbStore implements ThumbStore {
  FileThumbStore({Future<Directory> Function()? directory, this.most = 700})
    : _directory = directory ?? getApplicationCacheDirectory;

  /// How many pictures are kept, at the most: a few weeks of days, the
  /// reader's shelves and what Explore showed them, at some 40 KB each.
  final int most;

  final Future<Directory> Function() _directory;
  Future<Directory>? _home;
  int _writes = 0;

  Future<Directory> get _folder => _home ??= () async {
    final Directory d = Directory('${(await _directory()).path}/card_thumbs');
    await d.create(recursive: true);
    return d;
  }();

  /// The file a picture is kept in: its name with nothing a path could
  /// misread.
  static String fileName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9.-]'), '_');

  Future<File> _file(String name) async =>
      File('${(await _folder).path}/${fileName(name)}');

  @override
  Future<Uint8List?> read(String name) async {
    final File f = await _file(name);
    if (!await f.exists()) return null;
    final Uint8List bytes = await f.readAsBytes();
    // Wanted again: the last to be let go.
    try {
      await f.setLastModified(DateTime.now());
    } catch (_) {}
    return bytes;
  }

  @override
  Future<bool> has(String name) async => (await _file(name)).exists();

  @override
  Future<void> write(String name, Uint8List bytes) async {
    final Directory d = await _folder;
    final String file = fileName(name);
    final File part = File('${d.path}/$file.part');
    await part.writeAsBytes(bytes, flush: true);
    await part.rename('${d.path}/$file');
    if (++_writes % 24 == 1) await _trim(d);
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
