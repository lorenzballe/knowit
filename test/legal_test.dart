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

  test('the site has every page the stores ask for', () {
    // The App Store wants a support page and a privacy policy; the paywall
    // and the listing link the terms. Each one at the address its link uses.
    for (final String page in const [
      'site/index.html',
      'site/privacy.html',
      'site/terms.html',
      'site/support.html',
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
    // Every page is signed by TheBaleCompany. Astute is not on Google Play
    // yet, so every page says Android is coming and none links a listing
    // that is not there; the day it is, Google's badge goes back and this
    // says so instead.
    for (final String page in const [
      'site/index.html',
      'site/privacy.html',
      'site/terms.html',
      'site/support.html',
      'site/404.html',
      'site/get.html',
      'site/account.html',
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
