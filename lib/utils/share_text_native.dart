import 'package:share_plus/share_plus.dart';

/// Hands a line of text to the system share sheet. False when there is no
/// sheet to hand it to, so the caller can copy it instead.
Future<bool> shareText(String text) async {
  try {
    final result = await Share.share(text);
    return result.status != ShareResultStatus.unavailable;
  } catch (_) {
    // A host with no share plugin behind the channel — a desktop, a test.
    return false;
  }
}
