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

/// What the privacy policy says about the first run's four steps, counted
/// on the server with nothing about the reader (lib/measure/
/// first_steps.dart), word for word as site/privacy.html prints it, in both
/// of its languages: the app's own copy. test/legal_test.dart holds the
/// page to it, and test/first_steps_test.dart holds the code to it.
const Map<String, String> kFirstStepsPolicy = {
  'en':
      'The first run, counted without knowing who. To know whether the '
      'start of the app works, our server counts four steps: opening the '
      'app for the first time, finishing the first questions, finishing '
      'a first day, and coming back the day after the first open. For '
      'each one, the phone sends our server the name of the step and the '
      'date, and nothing else: not your account, not an identifier of '
      'the phone. The server adds one to that day’s total for that step, '
      'and our code keeps nothing beside the totals: not who, not which '
      'phone, not your IP address. Google Cloud, where it runs, notes '
      'the network address of each request in its own short-lived '
      'request log, as it does for every request to our server; that log '
      'does not say which step was counted. So that each step counts '
      'once, the phone remembers which steps it has sent. Because these '
      'totals carry nothing about you, they are counted whatever you '
      'answer about usage data; only an app installed from the App Store '
      'or Google Play sends them.',
  'it':
      'I primi passi, contati senza sapere di chi. Per sapere se '
      'l’inizio dell’app funziona, il nostro server conta quattro passi: '
      'aprire l’app la prima volta, finire le prime domande, finire una '
      'prima giornata e tornare il giorno dopo la prima apertura. Per '
      'ciascuno il telefono invia al nostro server il nome del passo e '
      'la data, e nient’altro: né il tuo account, né un identificativo '
      'del telefono. Il server aggiunge uno al totale di quel giorno per '
      'quel passo, e il nostro codice oltre ai totali non conserva '
      'niente: né chi, né quale telefono, né il tuo indirizzo IP. Google '
      'Cloud, su cui gira, annota l’indirizzo di rete di ogni richiesta '
      'in un proprio registro delle richieste, tenuto per poco tempo, '
      'come fa per ogni richiesta al nostro server; quel registro non '
      'dice quale passo è stato contato. Perché ogni passo conti una '
      'volta sola, il telefono ricorda quali passi ha già inviato. Visto '
      'che questi totali non dicono niente di te, vengono contati '
      'qualunque cosa tu risponda sui dati di utilizzo; li invia solo '
      'un’app installata dall’App Store o da Google Play.',
};

/// Where each language's paragraph about the first steps sits on the page.
const Map<String, String> kFirstStepsPolicyAnchors = {
  'en': 'first-steps',
  'it': 'primi-passi',
};

/// The policy's paragraph about the first steps, in the app's language
/// where the policy has one, and in English otherwise.
String firstStepsPolicyUrl(String language) =>
    '$kPrivacyUrl#${kFirstStepsPolicyAnchors[language] ?? kFirstStepsPolicyAnchors['en']}';

/// Opens a page in the phone's own browser sheet, and says nothing if it
/// cannot: a link that does not open is not worth an error over a paywall.
Future<void> openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url));
  } catch (_) {}
}
