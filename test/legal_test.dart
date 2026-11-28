import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/card_pages.dart';
import 'package:astuto/data/pill_bank.dart';
import 'package:astuto/l10n/app_localizations.dart';
import 'package:astuto/legal.dart';

void main() {
  test('the privacy link opens a page this site publishes', () {
    // The paywall links it and the App Store listing names it, so it has to
    // exist at the address both point to: site/ is published as the root of
    // astutetheapp.com, where /privacy serves privacy.html.
    expect(kPrivacyUrl, 'https://astutetheapp.com/privacy');
    final File page = File('site/privacy.html');
    expect(page.existsSync(), isTrue);

    // Everyone who handles a reader's data is named on it — a service added
    // to the app and left off the page is a policy that is no longer true.
    final String text = page.readAsStringSync();
    for (final String processor in const [
      'Firebase',
      'Anthropic',
      'ElevenLabs',
      'RevenueCat',
      'PostHog',
      'Apple',
      'Google Play',
      'GitHub Pages',
    ]) {
      expect(text, contains(processor), reason: processor);
    }
    // And a way to reach whoever answers for it, in both languages.
    expect(
      'mailto:thebalecompany@gmail.com'.allMatches(text).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('the policy says what the app says about where a reader lives, in '
      'both its languages, word for word', () {
    final String policy = File('site/privacy.html').readAsStringSync();
    String plain(String html) => html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    expect(kPlacePolicy.keys, unorderedEquals(kPlacePolicyAnchors.keys));
    for (final MapEntry<String, String> said in kPlacePolicy.entries) {
      final String anchor = kPlacePolicyAnchors[said.key]!;
      final RegExpMatch? paragraph = RegExp(
        '<p id="$anchor">(.*?)</p>',
        dotAll: true,
      ).firstMatch(policy);
      expect(paragraph, isNotNull, reason: anchor);
      expect(plain(paragraph!.group(1)!), said.value, reason: anchor);
      expect(placePolicyUrl(said.key), '$kPrivacyUrl#$anchor');
    }
    // The promises themselves, so that a rewrite cannot quietly drop one:
    // what is kept and how finely, that it is asked for and can be refused,
    // that the position stays on the phone, that PostHog gets the city at
    // most, and how it goes.
    final String en = kPlacePolicy['en']!;
    for (final String promise in const [
      'your country, your region, your city and a point rounded to about '
          '10 km',
      'It asks first',
      'you can say no',
      'Your exact position never leaves your phone',
      'PostHog receives your city at most, never a coordinate',
      'Profile → Where you live',
      'it is deleted with your account',
      'consent',
    ]) {
      expect(en, contains(promise), reason: promise);
    }
    final String it = kPlacePolicy['it']!;
    for (final String promise in const [
      'il paese, la regione, la città e un punto arrotondato a circa 10 km',
      'Prima lo chiede',
      'puoi dire di no',
      'La tua posizione esatta non lascia mai il telefono',
      'A PostHog arriva al massimo la città, mai una coordinata',
      'Profilo → Dove vivi',
      'viene eliminata con il tuo account',
      'consenso',
    ]) {
      expect(it, contains(promise), reason: promise);
    }
    // And the way out is listed with the reader's other choices.
    expect(policy, contains('<li><strong>Where you live.</strong>'));
    expect(policy, contains('<li><strong>Dove vivi.</strong>'));
  });

  test('the policy says how the first run is counted, in both its '
      'languages, word for word as the app keeps it', () {
    final String policy = File('site/privacy.html').readAsStringSync();
    String plain(String html) => html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    expect(
      kFirstStepsPolicy.keys,
      unorderedEquals(kFirstStepsPolicyAnchors.keys),
    );
    for (final MapEntry<String, String> said in kFirstStepsPolicy.entries) {
      final String anchor = kFirstStepsPolicyAnchors[said.key]!;
      final RegExpMatch? paragraph = RegExp(
        '<p id="$anchor">(.*?)</p>',
        dotAll: true,
      ).firstMatch(policy);
      expect(paragraph, isNotNull, reason: anchor);
      expect(plain(paragraph!.group(1)!), said.value, reason: anchor);
      expect(firstStepsPolicyUrl(said.key), '$kPrivacyUrl#$anchor');
    }
    // The promises, so that a rewrite cannot quietly drop one: nothing that
    // says whose, the address only in the cloud's own log, counted whatever
    // the answer about usage data, and only from the stores.
    final String en = kFirstStepsPolicy['en']!;
    for (final String promise in const [
      'counts four steps',
      'the name of the step and the date, and nothing else',
      'not your account, not an identifier of the phone',
      'not your IP address',
      'that log does not say which step was counted',
      'whatever you answer about usage data',
      'only an app installed from the App Store or Google Play',
    ]) {
      expect(en, contains(promise), reason: promise);
    }
    final String it = kFirstStepsPolicy['it']!;
    for (final String promise in const [
      'conta quattro passi',
      'il nome del passo e la data, e nient’altro',
      'né il tuo account, né un identificativo del telefono',
      'né il tuo indirizzo IP',
      'quel registro non dice quale passo è stato contato',
      'qualunque cosa tu risponda sui dati di utilizzo',
      'solo un’app installata dall’App Store o da Google Play',
    ]) {
      expect(it, contains(promise), reason: promise);
    }
    // And the question about usage data is said where it is now asked.
    expect(policy, contains('At the end of your first day'));
    expect(policy, contains('Alla fine della tua prima giornata'));
  });

  test('the policy says what goes to Anthropic, in both its languages', () {
    // The assistant, the coach and the news are written by Claude: the
    // policy says what is sent for each, that nothing in it says who the
    // reader is, and how much of what they write goes, at the length the
    // server cuts it to (functions/src/ask.ts, MAX_TEXT).
    final String policy = File('site/privacy.html').readAsStringSync();
    final RegExpMatch? cap = RegExp(r'export const MAX_TEXT = (\d+);')
        .firstMatch(File('functions/src/ask.ts').readAsStringSync());
    expect(cap, isNotNull);
    for (final String said in [
      '<p id="assistant">',
      '<p id="assistente">',
      '<p id="news">',
      '<p id="notizie">',
      '<p id="links">',
      '<p id="link">',
      '<p id="todays-five">',
      '<p id="cinque-di-oggi">',
      // The day's cards read aloud (Listen): the card's own words go to
      // ElevenLabs, nothing about the reader.
      '<p id="listen">',
      '<p id="ascolta">',
      'up to ${cap!.group(1)} characters',
      'fino a ${cap.group(1)} caratteri',
      'nothing that identifies you',
      'niente che ti identifichi',
    ]) {
      expect(policy, contains(said), reason: said);
    }
  });

  test('the site has every page the stores ask for', () {
    // The App Store wants a support page and a privacy policy; the paywall
    // and the listing link the terms. Each one at the address its link uses.
    // Google Play wants a page that says how to delete an account without
    // the app, too.
    for (final String page in const [
      'site/index.html',
      'site/privacy.html',
      'site/terms.html',
      'site/support.html',
      'site/delete-account.html',
      'site/404.html',
    ]) {
      expect(File(page).existsSync(), isTrue, reason: page);
    }
    // The pages the app and its widget read stay where a phone already
    // out there looks for them.
    expect(kBankUrl, 'https://astutetheapp.com/cards/v2/cards.json');
    expect(File('web/cards/v2/cards.json').existsSync(), isTrue);
    // And where every build from before looks for theirs.
    expect(File('web/cards/cards.json').existsSync(), isTrue);
    expect(kCardsBase, 'https://astutetheapp.com/cards/');
    final String deploy = File('.github/workflows/deploy.yml')
        .readAsStringSync();
    expect(deploy, contains('cp -r web/cards _site/cards'));
    expect(deploy, contains('WIDGET_DAYS_OUT=_site/widget/days.json'));
  });

  test('the site offers the App Store and Google Play, and names the '
      'company', () {
    // The landing page shows both stores with their own badges.
    final String home = File('site/index.html').readAsStringSync();
    for (final String badge in const [
      'site/assets/badges/app-store.svg',
      'site/assets/badges/google-play.svg',
      // The code a computer's visitor scans, which leads to /get.
      'site/assets/qr-get.svg',
    ]) {
      expect(File(badge).existsSync(), isTrue, reason: badge);
    }
    // Astute is on Google Play (tool/site/chrome.py, GOOGLE_PLAY_OPEN):
    // Google's badge is a link, never marked as coming. Apple's listing is
    // made but not live until chrome.py's APP_STORE_OPEN says it is: until
    // then its badge keeps its link but is marked "Coming soon", and no
    // Download button leads to a store page that is not there.
    expect(home, isNot(contains('store-google-play store-soon')));
    final bool appStoreOpen = RegExp(
      r'^APP_STORE_OPEN = True$',
      multiLine: true,
    ).hasMatch(File('tool/site/chrome.py').readAsStringSync());
    // Apple's listing answers 404 until it is live: no page links to it
    // before then, and the home links it from the day it is.
    expect(
      home.contains('href="https://apps.apple.com/app/id6806852300'),
      appStoreOpen,
    );
    final RegExp download = RegExp(r'<a\b[^>]*\bdata-store\b[^>]*>');
    // Every page is signed by TheBaleCompany, says where the app is, as
    // chrome.py writes it, and links the Play listing.
    for (final String page in const [
      'site/index.html',
      'site/privacy.html',
      'site/terms.html',
      'site/support.html',
      'site/404.html',
      'site/get.html',
      'site/account.html',
      'site/delete-account.html',
    ]) {
      final String text = File(page).readAsStringSync();
      expect(text, contains('© 2026 TheBaleCompany'), reason: page);
      expect(
        text,
        anyOf(
          contains('Free on iPhone and Android'),
          contains('Free on Android · coming to iPhone'),
        ),
        reason: page,
      );
      expect(text, isNot(contains('Android coming soon')), reason: page);
      expect(
        text,
        contains(
          'https://play.google.com/store/apps/details?id=com.astuto.app',
        ),
        reason: page,
      );
      final List<String> buttons = [
        for (final RegExpMatch m in download.allMatches(text)) m.group(0)!,
      ];
      expect(buttons, isNotEmpty, reason: page);
      for (final String button in buttons) {
        // A page in both languages has a button in each: the Italian one
        // leads to the Italian /get.
        expect(
          button,
          appStoreOpen
              ? contains('href="https://apps.apple.com/app/id6806852300')
              : anyOf(contains('href="/get"'), contains('href="/it/get"')),
          reason: '$page: $button',
        );
      }
      if (appStoreOpen) {
        expect(text, isNot(contains('store-app-store store-soon')));
      } else {
        // Apple's badge, marked as coming, leads to the list of those who
        // want to be told the day it is (/get#notify), never to a page of
        // Apple's that is not there yet.
        expect(
          text,
          matches(
            RegExp(
              r'<a class="store store-app-store store-soon[^"]*" '
              r'href="/get#notify"',
            ),
          ),
          reason: page,
        );
        expect(
          text,
          isNot(contains('href="https://apps.apple.com/')),
          reason: page,
        );
        expect(
          text,
          isNot(contains('<a class="store store-app-store" ')),
          reason: page,
        );
      }
    }
  });

  test('an account can be deleted without the app, and the site says how', () {
    final String page = File('site/delete-account.html').readAsStringSync();
    // The steps in the app, and the way by email, in both languages.
    expect(page, contains('Profile'));
    expect(page, contains('Delete account'));
    expect(page, contains('Elimina account'));
    expect(
      'mailto:thebalecompany@gmail.com'.allMatches(page).length,
      greaterThanOrEqualTo(2),
    );
    // What is deleted, what is not, and how long a request takes.
    expect(page, contains('What is deleted'));
    expect(page, contains('does not cancel an Astute+ subscription'));
    expect(page, contains('within 30 days'));
    // Found from where a reader looks: support, the policy, every footer
    // and the sitemap.
    for (final String from in const [
      'site/support.html',
      'site/privacy.html',
      'site/index.html',
    ]) {
      expect(
        File(from).readAsStringSync(),
        contains('href="/delete-account'),
        reason: from,
      );
    }
    // The sitemap is written as the site is put together (card_pages.py),
    // its own pages first.
    expect(
      File('tool/cards/card_pages.py').readAsStringSync(),
      contains('"/delete-account"'),
    );
  });

  test('the site says who writes the cards, as the app does', () {
    // "Every card here is written by an AI model" on the app's How screen;
    // the landing page and the terms say it too, and promise no more than
    // the app does.
    final String home = File('site/index.html').readAsStringSync();
    expect(home, contains('Who writes the cards?'));
    expect(home, contains('An AI model writes every card'));
    final String terms = File('site/terms.html').readAsStringSync();
    expect(terms, contains('written by an AI model'));
    expect(terms, isNot(contains('We check them and cite')));
    for (final String text in [home, terms]) {
      expect(text, isNot(contains('every month')));
    }
  });

  test('How cards are written says no more than is true', () {
    // Two lines used to promise what nobody did: that what could not be
    // backed up was cut, and that the sources were checked every month.
    // The screen now says that most cards are read by a critic and that
    // the list of claims it could not confirm is not empty yet.
    final l = lookupAppLocalizations(const Locale('en'));
    final String screen = [
      l.howTitle,
      l.howIntro,
      l.howStep1Line,
      l.howStep2Title,
      l.howStep2Line,
      l.howStep3Line,
      l.howStep4Line,
      l.howReportLine,
      l.howFoot,
    ].join(' ');
    expect(screen, isNot(contains('every month')));
    expect(screen, isNot(contains('is cut')));
    expect(screen, isNot(contains('never one you have already read')));
    expect(l.howStep2Line, contains('Most are read by a second model'));
    expect(l.howStep2Line, contains('That list isn’t empty yet.'));
  });

  test('the site measures what its privacy policy says, and no more', () {
    // Page views and store clicks through PostHog, kept in memory — no
    // cookie, no storage — and not loaded at all under Do Not Track or
    // Global Privacy Control. The policy says so in both its languages.
    final String script = File('site/assets/main.js').readAsStringSync();
    for (final String setting in const [
      "persistence: 'memory'",
      'autocapture: false',
      'disable_session_recording: true',
      'capture_pageleave: false',
      "navigator.doNotTrack !== '1'",
      'navigator.globalPrivacyControl !== true',
    ]) {
      expect(script, contains(setting), reason: setting);
    }
    // The library is the site's own copy, at the version the script names.
    final RegExpMatch? library = RegExp(
      r"POSTHOG_JS = '/(assets/vendor/[^']+)'",
    ).firstMatch(script);
    expect(library, isNotNull);
    expect(
      File('site/${library!.group(1)}').existsSync(),
      isTrue,
      reason: library.group(1),
    );

    final String policy = File('site/privacy.html').readAsStringSync();
    expect(policy, contains('<strong>This website.</strong>'));
    expect(policy, contains('<strong>Questo sito.</strong>'));
    expect(policy, isNot(contains('runs no analytics')));
    for (final String signal in const [
      'Do Not Track',
      'Global Privacy Control',
    ]) {
      expect(
        signal.allMatches(policy).length,
        greaterThanOrEqualTo(4),
        reason: signal,
      );
    }
  });
}
