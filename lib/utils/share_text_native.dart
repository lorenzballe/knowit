import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../analytics.dart';
import 'share_origin.dart';

/// Hands a line of text to the system share sheet. False when there is no
/// sheet to hand it to, so the caller can copy it instead.
///
/// [origin] is what the sheet points from; left out, the middle of the
/// screen (see [shareOrigin]).
Future<bool> shareText(String text, {Rect? origin}) async {
  try {
    final result = await Share.share(
      text,
      sharePositionOrigin: origin ?? shareOrigin(),
    );
    return result.status != ShareResultStatus.unavailable;
  } on MissingPluginException {
    // A host with no share plugin behind the channel — a desktop, a test.
    return false;
  } catch (error, stack) {
    // The sheet refused. The caller copies the text instead, and the
    // refusal is reported: it is how the iOS 26 one went unseen.
    Analytics.error(error, stack, where: 'share text');
    return false;
  }
}
