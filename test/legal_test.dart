import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/data/pill_bank.dart';
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
    expect(kBankUrl, 'https://astutetheapp.com/cards/cards.json');
    expect(File('web/cards/cards.json').existsSync(), isTrue);
    final String deploy = File('.github/workflows/deploy.yml')
        .readAsStringSync();
    expect(deploy, contains('cp -r web/cards _site/cards'));
    expect(deploy, contains('WIDGET_DAYS_OUT=_site/widget/days.json'));
  });

  test('the site offers the App Store, says Android is coming, and names '
      'the company', () {
    // The landing page links the App Store listing with Apple's own badge.
    final String home = File('site/index.html').readAsStringSync();
    expect(home, contains('https://apps.apple.com/app/id6806852300'));
    for (final String badge in const [
      'site/assets/badges/app-store.svg',
      // The code a computer's visitor scans, which leads to /get.
      'site/assets/qr-get.svg',
    ]) {
      expect(File(badge).existsSync(), isTrue, reason: badge);
    }
    // Google's badge stands beside Apple's, marked as coming: the listing is
    // not open to everybody yet (tool/site/chrome.py, GOOGLE_PLAY_OPEN).
    expect(home, contains('store-google-play store-soon'));
    // Every page is signed by TheBaleCompany. Astute is not on Google Play
    // yet, so every page says Android is coming and none links a listing
    // that is not there; the day it is, the badge becomes the link and this
    // says so instead.
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
      expect(text, contains('Android coming soon'), reason: page);
      expect(text, isNot(contains('iPhone and Android')), reason: page);
      expect(
        text,
        isNot(contains('play.google.com/store/apps/details')),
        reason: page,
      );
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
    expect(
      File('site/sitemap.xml').readAsStringSync(),
      contains('https://astutetheapp.com/delete-account'),
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
