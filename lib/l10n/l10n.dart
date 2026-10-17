import 'package:flutter/widgets.dart';

import '../data/topics.dart' show topicKeyForName;
import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app's strings, in the language the phone is set to.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
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
