import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/l10n/app_localizations.dart';

/// The iPhone asks for the reader's location, and to add to their photos,
/// in words the app writes — and in the reader's language, not in English
/// whatever the phone speaks. Three files have to agree for that: the
/// languages Info.plist declares, a `<lang>.lproj/InfoPlist.strings` for
/// each with every prompt Info.plist has, and the Xcode project copying
/// each of them into the app.
void main() {
  final String plist = File('ios/Runner/Info.plist').readAsStringSync();
  final String project = File('ios/Runner.xcodeproj/project.pbxproj')
      .readAsStringSync();

  /// The folder iOS names a language by: Simplified Chinese is zh-Hans.
  String folderOf(String language) => language == 'zh' ? 'zh-Hans' : language;

  final List<String> declared =
      RegExp(
            r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
            dotAll: true,
          )
          .firstMatch(plist)!
          .group(1)!
          .split('\n')
          .map((line) => RegExp(r'<string>([^<]+)</string>').firstMatch(line))
          .whereType<RegExpMatch>()
          .map((m) => m.group(1)!)
          .toList();

  final List<String> prompts = RegExp(r'<key>(NS\w+UsageDescription)</key>')
      .allMatches(plist)
      .map((m) => m.group(1)!)
      .toList();

  test('Info.plist declares every language the app speaks', () {
    expect(
      declared,
      unorderedEquals([
        for (final l in AppLocalizations.supportedLocales)
          folderOf(l.languageCode),
      ]),
    );
  });

  test('adding to the photos is asked for, since the share sheet saves '
      'pictures', () {
    expect(prompts, contains('NSPhotoLibraryAddUsageDescription'));
    // Adding only: the app never reads the library.
    expect(prompts, isNot(contains('NSPhotoLibraryUsageDescription')));
  });

  test('every language has every prompt, and the project copies it', () {
    for (final String folder in declared) {
      final File strings = File('ios/Runner/$folder.lproj/InfoPlist.strings');
      expect(strings.existsSync(), isTrue, reason: folder);
      final String text = strings.readAsStringSync();
      for (final String prompt in prompts) {
        expect(
          RegExp('^"$prompt" = "[^"]+";\$', multiLine: true).hasMatch(text),
          isTrue,
          reason: '$folder: $prompt',
        );
      }
      final String path = folder.contains('-')
          ? '"$folder.lproj/InfoPlist.strings"'
          : '$folder.lproj/InfoPlist.strings';
      expect(project, contains('path = $path;'), reason: folder);
    }
    expect(project, contains('/* InfoPlist.strings in Resources */,'));
  });

  test('the English strings say what Info.plist says', () {
    final String en = File('ios/Runner/en.lproj/InfoPlist.strings')
        .readAsStringSync();
    for (final String prompt in prompts) {
      final String said = RegExp(
        '<key>$prompt</key>\\s*<string>([^<]+)</string>',
      ).firstMatch(plist)!.group(1)!;
      expect(en, contains('"$prompt" = "$said";'), reason: prompt);
    }
  });
}
