import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Hands the PNG to the browser as a download.
Future<bool> savePng(Uint8List bytes, String filename) async {
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = 'data:image/png;base64,${base64Encode(bytes)}'
        ..download = filename
        ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
