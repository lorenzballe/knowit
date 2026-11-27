import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:astuto/l10n/dates.dart';

/// French puts an ordinal on the first of the month, and only there:
/// "1er décembre", "mardi 1er décembre", never "1 décembre".
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('it');
    await initializeDateFormatting('en');
  });

  final DateTime first = DateTime(2026, 12, 1);
  final DateTime second = DateTime(2026, 12, 2);

  test('the first of the month, in French, in every format the app uses', () {
    expect(formatDay(DateFormat.MMMMd('fr'), first), '1er décembre');
    expect(formatDay(DateFormat.MMMd('fr'), first), '1er déc.');
    expect(formatDay(DateFormat.MMMMEEEEd('fr'), first), 'mardi 1er décembre');
    expect(
      formatDay(DateFormat('EEEE d MMMM', 'fr'), first),
      'mardi 1er décembre',
    );
    expect(formatDay(DateFormat('d MMMM y', 'fr'), first), '1er décembre 2026');
    expect(formatDay(DateFormat('EEE d MMM', 'fr'), first), 'mar. 1er déc.');
  });

  test('any other day, and any other language, as the phone writes it', () {
    expect(formatDay(DateFormat.MMMMd('fr'), second), '2 décembre');
    expect(
      formatDay(DateFormat.MMMMd('fr'), DateTime(2026, 12, 11)),
      '11 décembre',
    );
    expect(
      formatDay(DateFormat.MMMMd('fr'), DateTime(2026, 12, 21)),
      '21 décembre',
    );
    expect(
      formatDay(DateFormat('d MMMM y', 'fr'), DateTime(2031, 1, 31)),
      '31 janvier 2031',
    );
    expect(formatDay(DateFormat.MMMMd('it'), first), '1 dicembre');
    expect(formatDay(DateFormat.MMMMd('en'), first), 'December 1');
  });
}
