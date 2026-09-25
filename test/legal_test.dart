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
}
