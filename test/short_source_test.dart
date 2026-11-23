// A card's source as the card says it (lib/models/pill.dart, shortSource):
// a video by its channel, not by a title that can run to a sentence.
//
//   flutter test test/short_source_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:astuto/models/pill.dart';

void main() {
  test('a video is cited by its channel and year; its title is left to Go '
      'deeper', () {
    expect(
      shortSource(
        'Veritasium, \u201cSpinning Tube Trick Explained\u201d (YouTube, 2012)',
      ),
      'Veritasium \u00b7 YouTube, 2012',
    );
    expect(
      shortSource(
        'Geopop, \u201cIl fenomeno delle \u201ccase bara\u201d di Hong Kong: come sono '
        'fatte?\u201d (YouTube, 2024)',
      ),
      'Geopop \u00b7 YouTube, 2024',
    );
  });

  test('anything else as it is', () {
    for (final String s in [
      'YouTube Creator Blog, October 2012',
      'Kahneman, Thinking, Fast and Slow, 2011',
      'GamesBeat on Monsters University, 2013',
    ]) {
      expect(shortSource(s), s);
    }
  });
}
