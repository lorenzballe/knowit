import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:url_launcher/url_launcher.dart';

/// Where Astute is in the stores, wherever the app links to them: the update
/// gate's button, the sheet that says a new version is ready, and the
/// receipt a purchase ends on. The addresses are the site's own
/// (tool/site/chrome.py, site/assets/account.js), and
/// tool/remote/test_app.py holds the two to each other: an app that sent
/// readers to one page and a site that sent them to another would be one
/// store listing too many.
const String kAppStoreUrl = 'https://apps.apple.com/app/id6806852300';
const String kGooglePlayUrl =
    'https://play.google.com/store/apps/details?id=com.astuto.app';

/// Where a subscription is managed in each store, as the receipt after a
/// purchase links it.
const String kAppStoreSubscriptionsUrl =
    'https://apps.apple.com/account/subscriptions';
const String kGooglePlaySubscriptionsUrl =
    'https://play.google.com/store/account/subscriptions';

/// Astute's page in the store [platform] installs from — `ios` or
/// `android`, as Remote.platform names them — or null where there is none:
/// the web app is always the newest one, and has nothing to update.
String? storePageFor(String platform) => switch (platform) {
  'ios' => kAppStoreUrl,
  'android' => kGooglePlayUrl,
  _ => null,
};

/// The store as the app's words name it (`{store, select, …}` in the arb
/// files): `apple`, `google`, or `other`.
String storeWordFor(String platform) => switch (platform) {
  'ios' => 'apple',
  'android' => 'google',
  _ => 'other',
};

/// Opens a link outside the app. Replaced by the tests, which have no store
/// to open.
@visibleForTesting
Future<bool> Function(Uri uri) openOutside = _openOutside;

Future<bool> _openOutside(Uri uri) async {
  try {
    // In the store's own app: the App Store and Google Play both claim
    // their addresses, and a page of the store inside a browser sheet is
    // one more tap between the reader and the button that updates.
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  } catch (_) {}
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

/// Opens Astute's page in the store [platform] installs from. False where
/// there is no store, or the phone would not open it: nothing is said to
/// the reader, who can still find the app in the store themselves.
Future<bool> openStorePage(String platform) async {
  final String? url = storePageFor(platform);
  if (url == null) return false;
  return openOutside(Uri.parse(url));
}
