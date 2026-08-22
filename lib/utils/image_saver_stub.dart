import 'dart:typed_data';

/// Saving a capture straight to disk needs a platform file picker this app
/// does not carry yet, so outside the web build the caller falls back to
/// copying the text.
Future<bool> savePng(Uint8List bytes, String filename) async => false;
