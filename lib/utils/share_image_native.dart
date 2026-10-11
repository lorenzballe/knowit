import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics.dart';
import 'share_origin.dart';

/// Hands a rendered card to the system share sheet. False when the sheet
/// would not take it, so the caller can copy the words instead.
///
/// Written to the temp directory first: the sheet wants a file, and a card
/// somebody is about to send to a friend is not something to keep.
///
/// [origin] is what the sheet points from; left out, the middle of the
/// screen (see [shareOrigin]).
Future<bool> shareCardImage(
  Uint8List bytes,
  String filename,
  String text, {
  Rect? origin,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: text,
      sharePositionOrigin: origin ?? shareOrigin(),
    );
    return result.status != ShareResultStatus.unavailable;
  } catch (error, stack) {
    // Thrown, it used to leave the button doing nothing at all. Now the
    // caller falls back to the clipboard, and the failure is reported.
    Analytics.error(error, stack, where: 'share image');
    return false;
  }
}
