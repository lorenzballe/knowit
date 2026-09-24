import 'package:url_launcher/url_launcher.dart';

/// Where the paywall's two required links go.
///
/// Apple asks for both beside an auto-renewing subscription, in the app and
/// in the App Store listing (guideline 3.1.2). The terms are Apple's own
/// standard licence, which the App Store applies to any app that does not
/// bring one; the privacy policy is a page of the site this repository
/// publishes, `web/privacy.html`.
const String kTermsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const String kPrivacyUrl = 'https://lorenzballe.github.io/knowit/privacy.html';

/// Opens a page in the phone's own browser sheet, and says nothing if it
/// cannot: a link that does not open is not worth an error over a paywall.
Future<void> openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url));
  } catch (_) {}
}
