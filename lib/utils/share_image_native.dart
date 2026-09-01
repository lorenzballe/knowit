import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a rendered card to the system share sheet.
///
/// Written to the temp directory first: the sheet wants a file, and a card
/// somebody is about to send to a friend is not something to keep.
Future<bool> shareCardImage(
  Uint8List bytes,
  String filename,
  String text,
) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  final result = await Share.shareXFiles([
    XFile(file.path, mimeType: 'image/png'),
  ], text: text);
  return result.status != ShareResultStatus.unavailable;
}
