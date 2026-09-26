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

  test('the site offers both stores and names the company', () {
    // The landing page links both listings with the stores' own badges.
    final String home = File('site/index.html').readAsStringSync();
    expect(home, contains('https://apps.apple.com/app/id6806852300'));
    expect(
      home,
      contains('https://play.google.com/store/apps/details?id=com.astuto.app'),
    );
    for (final String badge in const [
      'site/assets/badges/app-store.svg',
      'site/assets/badges/google-play.png',
      // The code a computer's visitor scans, which leads to /get.
      'site/assets/qr-get.svg',
    ]) {
      expect(File(badge).existsSync(), isTrue, reason: badge);
    }
    // Every page is signed by TheBaleCompany, and none still waits for a
    // store.
    for (final String page in const [
      'site/index.html',
      'site/privacy.html',
      'site/terms.html',
      'site/support.html',
      'site/404.html',
      'site/get.html',
    ]) {
      final String text = File(page).readAsStringSync();
      expect(text, contains('© 2026 TheBaleCompany'), reason: page);
      expect(text.toLowerCase(), isNot(contains('coming soon')), reason: page);
      expect(text, isNot(contains('Android soon')), reason: page);
    }
  });
}
