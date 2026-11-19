import '../l10n/app_localizations.dart';
import '../models/pill.dart';

/// A reasoning move as the reader reads it: its name in their language. The
/// English is the move's own label ([Principle.label]).
String moveName(AppLocalizations l, Principle p) =>
    p.isReal ? l.moveName(p.name) : '';

/// The one line that names the move, in the reader's language
/// ([Principle.oneLine] in English).
String moveLine(AppLocalizations l, Principle p) =>
    p.isReal ? l.moveLine(p.name) : '';
