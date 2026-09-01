import 'dart:typed_data';

import 'image_saver.dart';

/// A browser has no share sheet worth the name, so the card downloads.
Future<bool> shareCardImage(Uint8List bytes, String filename, String text) =>
    savePng(bytes, filename);
