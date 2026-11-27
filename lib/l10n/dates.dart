import 'package:intl/intl.dart' show DateFormat;

/// [format] applied to [day], the first of a month said as French says it:
/// "1er décembre", "mardi 1er décembre", never "1 décembre". The phone's
/// own formats write the day as a bare number in every language; French
/// alone puts the ordinal on the first, and a date without it reads as a
/// machine's. Every date with a day in it goes through here.
String formatDay(DateFormat format, DateTime day) {
  final String out = format.format(day);
  if (day.day != 1 || !format.locale.startsWith('fr')) return out;
  return out.replaceFirstMapped(RegExp(r'(^|\s)1(?=\s)'), (m) => '${m[1]}1er');
}
