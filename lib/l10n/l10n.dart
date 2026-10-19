import 'package:flutter/widgets.dart';

import '../data/topics.dart' show topicKeyForName;
import '../remote/remote.dart';
import '../remote/remote_strings.dart';
import 'app_localizations.dart';
import 'remote_localizations.dart';

export 'app_localizations.dart';

/// The app's strings, in the language the phone is set to — with the
/// server's words in place of the build's wherever the remote document has
/// some for that language (lib/remote/remote_strings.dart).
extension L10nX on BuildContext {
  AppLocalizations get l10n {
    // A newer document can bring new words: whatever reads them is drawn
    // again when one is taken up.
    RemoteWordsScope.watch(this);
    return withRemoteWords(AppLocalizations.of(this));
  }
}

/// The document the wrappers below were made for, and the wrapper for each
/// language it has words for — null for a language it has none for, which
/// is then the build's own strings, untouched.
RemoteConfig? _wordsOf;
final Map<String, AppLocalizations?> _wrapped = {};

/// [base], or [base] with the server's words for its language in their
/// place when the document in use has some: for the strings said with no
/// screen to say them on — a notification, a widget — as much as for those
/// on one. One wrapper per document and language, made the first time it is
/// asked for and kept until another document is taken up.
AppLocalizations withRemoteWords(AppLocalizations base) {
  if (base is RemoteLocalizations) return base;
  final RemoteConfig doc = Remote.config;
  if (!identical(doc, _wordsOf)) {
    _wordsOf = doc;
    _wrapped.clear();
  }
  final String language = base.localeName.split(RegExp('[_-]')).first;
  if (!_wrapped.containsKey(language)) {
    final RemoteWords? words = RemoteWords.of(doc, language);
    _wrapped[language] = words == null
        ? null
        : RemoteLocalizations(base, words);
  }
  return _wrapped[language] ?? base;
}

/// A subject's name in the reader's language.
///
/// The bank, kTopics and every card name a subject in English, and that
/// name is the key everything is filed and matched under; this is only how
/// it is shown. A name this build has no word for is shown as it is.
extension SubjectNames on AppLocalizations {
  String subjectOf(String name) {
    final String? key = topicKeyForName(name);
    return key == null ? name : subjectName(key);
  }
}
