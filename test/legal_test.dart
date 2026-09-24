import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/legal.dart';

void main() {
  test('the privacy link opens a page this site publishes', () {
    // The paywall links it and the App Store listing names it, so it has to
    // exist at the address both point to: web/ is published as the site.
    expect(kPrivacyUrl, endsWith('/privacy.html'));
    final File page = File('web/privacy.html');
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
    expect('mailto:'.allMatches(text), hasLength(2));
  });
}
