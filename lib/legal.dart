import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:url_launcher/url_launcher.dart';

/// Where the terms and the privacy policy are, wherever the app links them:
/// the paywall, the intro, Profile.
///
/// Apple asks for both beside an auto-renewing subscription, in the app and
/// in the App Store listing (guideline 3.1.2). On an iPhone the terms are
/// Apple's own standard licence, which the App Store applies to any app that
/// does not bring one. Everywhere else they are the site's own
/// (`site/terms.html`), which cover a purchase on Google Play and say that
/// Apple's licence is the one on an iPhone: Apple's licence governs App
/// Store purchases only, and Android's readers used to be sent to it. The
/// privacy policy is a page of the same site, `site/privacy.html`.
const String kAppleEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const String kSiteTermsUrl = 'https://astutetheapp.com/terms';
const String kPrivacyUrl = 'https://astutetheapp.com/privacy';

/// The terms a reader on [platform] buys under.
String termsUrlFor(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? kAppleEulaUrl : kSiteTermsUrl;

/// What the privacy policy says about where a reader lives, word for word
/// as site/privacy.html prints it, in both of its languages: the app's own
/// copy. The sheet that asks promises it in one line ("Only your city is
/// kept, never your exact position"); this is the promise whole, and
/// test/legal_test.dart holds the page to it, so that the two cannot drift
/// apart — and test/place_capture_test.dart holds the code to it.
const Map<String, String> kPlacePolicy = {
  'en':
      'Where you live. If you allow it, Astute deals you cards about the '
      'place you live. It asks first, with a question of its own and then '
      'your phone’s, and you can say no: the app works the same without it. '
      'Your phone’s location is read once and turned into a place on the '
      'phone itself; Astute keeps only your country, your region, your city '
      'and a point rounded to about 10 km, with your account and its '
      'backup, and reads it again at most once a week, so that a move is '
      'noticed. Your exact position never leaves your phone through Astute: '
      'it is not stored, logged or sent to us, to PostHog or to anyone else. '
      'To give the place its name, the phone uses its own map service — '
      'Apple’s on iPhone, Google’s on Android — as it does for any app. '
      'PostHog receives your city at most, never a coordinate. This rests on '
      'your consent: you can remove it at any time in the app, under Profile '
      '→ Where you live, and it is deleted with your account.',
  'it':
      'Dove vivi. Se lo consenti, Astute ti propone carte sul posto in cui '
      'vivi. Prima lo chiede, con una domanda sua e poi con quella del '
      'telefono, e puoi dire di no: l’app funziona allo stesso modo anche '
      'senza. La posizione del telefono viene letta una volta e trasformata '
      'in un luogo sul telefono stesso; Astute conserva solo il paese, la '
      'regione, la città e un punto arrotondato a circa 10 km, insieme al '
      'tuo account e al suo backup, e la rilegge al massimo una volta a '
      'settimana, per accorgersi di un trasloco. La tua posizione esatta non '
      'lascia mai il telefono attraverso Astute: non viene conservata, '
      'registrata né inviata a noi, a PostHog o a chiunque altro. Per dare '
      'un nome al luogo, il telefono usa il proprio servizio di mappe — '
      'quello di Apple su iPhone, quello di Google su Android — come fa per '
      'qualsiasi app. A PostHog arriva al massimo la città, mai una '
      'coordinata. Si basa sul tuo consenso: puoi rimuoverla in qualsiasi '
      'momento nell’app, in Profilo → Dove vivi, e viene eliminata con il '
      'tuo account.',
};

/// Where each language's paragraph sits on the page.
const Map<String, String> kPlacePolicyAnchors = {
  'en': 'where-you-live',
  'it': 'dove-vivi',
};

/// The policy's paragraph about where a reader lives, in the app's
/// language where the policy has one, and in English otherwise.
String placePolicyUrl(String language) =>
    '$kPrivacyUrl#${kPlacePolicyAnchors[language] ?? kPlacePolicyAnchors['en']}';

/// Opens a page in the phone's own browser sheet, and says nothing if it
/// cannot: a link that does not open is not worth an error over a paywall.
Future<void> openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url));
  } catch (_) {}
}
