/// A book's summary: a book of Books in pills read whole, in about a quarter
/// of an hour, in five to eight parts, in the app's own words.
///
/// Written one file per book (`tool/cards/summaries/<book>.json`, which
/// tool/cards/summaries.py holds to its rules), published beside the cards
/// (`summaries/<book>.json`) and named in the bank with the hash of its
/// bytes, the way a free card's page is ([SummaryRef]). The app fetches it
/// when the book is opened and keeps it (lib/data/book_summaries.dart); the
/// reader turns through it a part at a time (lib/books/summary_reader.dart),
/// and the player hears it a part a clip (lib/books/book_player.dart).
library;

import 'dart:convert';

/// Words a minute, read with attention or heard: what the minutes on a
/// book's page are reckoned at, here and in tool/cards/summaries.py
/// (READING_PACE).
const int kSummaryPace = 150;

/// How the bank names a book's summary, before it is fetched: where it is,
/// and what the book's page says of it.
class SummaryRef {
  const SummaryRef({
    required this.file,
    required this.minutes,
    required this.parts,
    this.words = 0,
  });

  /// The file under the site's cards, with the hash of its bytes:
  /// `summaries/<book>.json?v=<hash>`.
  final String file;

  /// How long it takes, and in how many parts.
  final int minutes;
  final int parts;
  final int words;

  /// The book it is of, read off its name.
  String get book {
    final String name = Uri.parse(file).path.split('/').last;
    return name.endsWith('.json') ? name.substring(0, name.length - 5) : name;
  }

  static SummaryRef? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final Object? file = raw['file'], minutes = raw['minutes'];
    final Object? parts = raw['parts'], words = raw['words'];
    if (file is! String || !file.startsWith('summaries/')) return null;
    if (minutes is! int || parts is! int || minutes < 1 || parts < 1) {
      return null;
    }
    return SummaryRef(
      file: file,
      minutes: minutes,
      parts: parts,
      words: words is int ? words : 0,
    );
  }

  Map<String, Object?> toJson() => {
    'file': file,
    'minutes': minutes,
    'parts': parts,
    if (words > 0) 'words': words,
  };
}

/// One part of a summary: its title and its paragraphs. One clip, heard.
class SummaryPart {
  const SummaryPart({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  /// The words a reader reads in it, its title aside.
  int get words => paragraphs.fold(0, (n, p) => n + wordsIn(p));
}

/// A book's summary, whole.
class BookSummary {
  const BookSummary({
    required this.book,
    required this.title,
    required this.author,
    required this.year,
    required this.parts,
    this.sources = const [],
    this.minutes = 0,
  });

  /// The book's id, as its cards name it.
  final String book;
  final String title;
  final String author;
  final int year;
  final List<SummaryPart> parts;

  /// The edition first, then any study it names that the book does not.
  final List<String> sources;

  /// The minutes, as published; reckoned from the words when not.
  final int minutes;

  int get words => parts.fold(0, (n, p) => n + p.words);

  /// How long it takes: as published, or its words at [kSummaryPace].
  int get duration =>
      minutes > 0 ? minutes : (words / kSummaryPace).round().clamp(1, 999);

  /// How far through the whole summary a reader is at part [part],
  /// [through] of the way into it, by words: from 0 to 1.
  double progress(int part, double through) {
    final int total = words;
    if (total == 0 || parts.isEmpty) return 0;
    int done = 0;
    for (int i = 0; i < part && i < parts.length; i++) {
      done += parts[i].words;
    }
    final int at = part.clamp(0, parts.length - 1);
    final double inPart = part >= parts.length
        ? 0
        : parts[at].words * through.clamp(0.0, 1.0);
    return ((done + inPart) / total).clamp(0.0, 1.0);
  }

  /// The minutes left from part [part], [through] of the way into it,
  /// scaled to the published minutes, so the first part says what the
  /// book's page said. Never under one while anything is left.
  int minutesLeft(int part, double through) {
    final double left = 1 - progress(part, through);
    if (left <= 0.001) return 0;
    return (duration * left).ceil().clamp(1, 999);
  }

  /// Reads a summary as published. Throws [FormatException] on one the app
  /// could not show whole: a summary is read whole or not at all.
  factory BookSummary.parse(String text) {
    final Object? doc = jsonDecode(text);
    if (doc is! Map<String, Object?>) {
      throw const FormatException('a summary is an object');
    }
    String need(String key) {
      final Object? v = doc[key];
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('a summary has a $key');
      }
      return v;
    }

    final Object? rawParts = doc['parts'];
    if (rawParts is! List || rawParts.isEmpty) {
      throw const FormatException('a summary has parts');
    }
    final List<SummaryPart> parts = [];
    for (final Object? raw in rawParts) {
      if (raw is! Map) throw const FormatException('a part is an object');
      final Object? title = raw['title'], text = raw['text'];
      if (title is! String || text is! List) {
        throw const FormatException('a part has a title and its text');
      }
      final List<String> paragraphs = [
        for (final Object? p in text)
          if (p is String && p.trim().isNotEmpty) p,
      ];
      if (paragraphs.isEmpty) {
        throw const FormatException('a part has words');
      }
      parts.add(SummaryPart(title: title, paragraphs: paragraphs));
    }
    final Object? year = doc['year'], minutes = doc['minutes'];
    final Object? sources = doc['sources'];
    return BookSummary(
      book: need('book'),
      title: need('title'),
      author: need('author'),
      year: year is int ? year : 0,
      parts: parts,
      sources: [
        if (sources is List)
          for (final Object? s in sources)
            if (s is String) s,
      ],
      minutes: minutes is int ? minutes : 0,
    );
  }
}

/// The words in [text], as tool/cards/summaries.py counts them.
int wordsIn(String text) {
  final String t = text.trim();
  return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
}

/// [text] as a book sets it: straight quotes turned the way they face, an
/// apostrophe as one. A summary is written with straight quotes, the way a
/// keyboard types them; the reader shows them curled.
String typeset(String text) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final String c = text[i];
    if (c != '"' && c != "'") {
      out.write(c);
      continue;
    }
    // Opening where nothing, a space or an opening bracket comes before.
    final bool opens = i == 0 || RegExp(r'[\s(\[{]').hasMatch(text[i - 1]);
    if (c == '"') {
      out.write(opens ? '“' : '”');
    } else {
      out.write(opens ? '‘' : '’');
    }
  }
  return out.toString();
}
