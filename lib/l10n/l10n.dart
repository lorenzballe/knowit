import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app's strings, in the language the phone is set to.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
