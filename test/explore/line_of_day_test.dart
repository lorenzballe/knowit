// The line of the day (lib/data/day_lines.dart, explore/blocks/core/
// line_block.dart): one sentence worth keeping a day, the same for every
// reader, under who wrote it and where, sent on with where it is from.
//
//   flutter test test/explore/line_of_day_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astuto/data/day_lines.dart';
import 'package:astuto/data/topics.dart';
import 'package:astuto/explore/blocks/core/line_block.dart';
import 'package:astuto/explore/explore_block.dart';
import 'package:astuto/state/app_state.dart';
import 'package:astuto/utils/share_link.dart';

import 'core_harness.dart';

Future<AppState> _app() async {
  SharedPreferences.setMockInitialValues({'knowit.onboarded': true});
  final app = AppState();
  await app.init();
  return app;
}

final List<ExploreSection> _sections = sectionsOf([
  {
    'id': 'line-of-day',
    'block': 'line-of-day',
    'title': {'en': 'Line of the day'},
  },
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every line says who wrote it, where, when, and the page where '
      'anyone can read it', () {
    expect(dayLines.length, greaterThanOrEqualTo(60));
    final Set<String> seen = {};
    for (final DayLine l in dayLines) {
      expect(seen.add(l.text), isTrue, reason: l.text);
      expect(l.text.trim(), isNotEmpty);
      expect(l.author.trim(), isNotEmpty);
      expect(l.work.trim(), isNotEmpty);
      expect(l.year.trim(), isNotEmpty);
      expect(dayLineSubjects.keys, contains(l.theme), reason: l.text);
      expect(Uri.parse(l.url).scheme, 'https', reason: l.url);
      expect(RegExp(r'[.?!…]$').hasMatch(l.text), isTrue, reason: l.text);
      // Typeset like the cards: no straight quote marks.
      expect(l.text.contains("'") || l.text.contains('"'), isFalse);
    }
    // Every theme's subjects are subjects of the app.
    for (final List<String> subjects in dayLineSubjects.values) {
      for (final String s in subjects) {
        expect(kTopics.keys, contains(s));
      }
    }
  });

  test('one line a day, the same for everybody: each once before any '
      'comes again, and no theme for days on end', () {
    final DateTime start = DateTime(2026, 11, 20);
    final List<DayLine> days = [
      for (int d = 0; d < dayLines.length; d++)
        lineOfDay(start.add(Duration(days: d)))!,
    ];
    expect(days.toSet(), hasLength(dayLines.length));
    for (int d = 2; d < days.length; d++) {
      expect(
        days[d].theme == days[d - 1].theme &&
            days[d - 1].theme == days[d - 2].theme,
        isFalse,
        reason: 'three days of ${days[d].theme}',
      );
    }
    // The same all day.
    expect(
      lineOfDay(DateTime(2026, 11, 20, 0, 5)),
      lineOfDay(DateTime(2026, 11, 20, 23, 55)),
    );
  });

  test("a subject's page has the lines of its themes, and a subject "
      'with none has none', () {
    final DateTime day = DateTime(2026, 11, 20);
    for (int d = 0; d < 40; d++) {
      final DayLine l = lineOfDay(
        day.add(Duration(days: d)),
        subject: 'economics',
      )!;
      expect(dayLineSubjects[l.theme], contains('economics'));
    }
    expect(lineOfDay(day, subject: 'art'), isNull);
  });

  testWidgets('on Explore: the words, who and where, and a way to send it '
      'on with where it is from', (tester) async {
    final AppState app = await _app();
    final DayLine line = lineOfDay(app.today)!;
    final Future<bool> Function(String) was = sendText;
    addTearDown(() => sendText = was);
    String? sent;
    sendText = (text) async {
      sent = text;
      return true;
    };
    await pumpSections(tester, CoreHost(app), _sections);
    expect(find.text('Line of the day'), findsOneWidget);
    expect(find.text('“${line.text}”'), findsOneWidget);
    expect(find.text(line.author), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-line-share')));
    await tester.pump();
    expect(sent, contains(line.text));
    expect(sent, contains(line.author));
    expect(sent, contains(DayLineCard.whereOf(line)));
    expect(sent, contains(ShareRef.line.link));
    expect(tester.takeException(), isNull);

    // At twice the text, on a small phone, nothing spills.
    await pumpSections(
      tester,
      CoreHost(app),
      _sections,
      size: const Size(320, 640),
      text: 2,
    );
    expect(tester.takeException(), isNull);

    // Not on the page of a subject with no lines.
    await pumpSections(
      tester,
      CoreHost(app, subject: kTopics['art']!.name),
      _sections,
    );
    expect(find.byKey(const ValueKey('day-line')), findsNothing);
  });
}
