/// The books in pills that the people who built the companies everyone
/// knows have recommended: for each book (by its id, see lib/data/books.dart),
/// who recommended it, in their own words, and where they said it, so
/// anyone can check. Explore's founders' shelf draws them
/// (explore/blocks/core/books_block.dart), and a book's own page says them.
///
/// Every pick is one the person made in public, in words quoted exactly from
/// the page [BookPick.url] links to: their own site, letter, interview or
/// talk. A pick nobody can check is not here; a shorter list is better than
/// one wrong name.
library;

/// One person's recommendation of one book.
class BookPick {
  const BookPick({
    required this.who,
    required this.role,
    required this.said,
    required this.where,
    required this.year,
    required this.url,
  });

  /// Who, as everybody knows them: "Bill Gates".
  final String who;

  /// What they built, in a few words: "Co-founder of Microsoft".
  final String role;

  /// Their words about the book, quoted exactly from [url]; empty where the
  /// recommendation is a list with no words of its own.
  final String said;

  /// Where they said it: "GatesNotes", "Berkshire Hathaway's 2013 letter".
  final String where;

  /// The year they said it.
  final int year;

  /// The page where anyone can read it.
  final String url;
}

/// The picks, by book id, in the order the shelf names them.
const Map<String, List<BookPick>> bookPicks = {};

/// The picks of the book [id], none for a book nobody recommended.
List<BookPick> picksOf(String id) => bookPicks[id] ?? const [];
