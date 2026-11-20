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
const Map<String, List<BookPick>> bookPicks = {
  'factfulness': [
    BookPick(
      who: 'Bill Gates',
      role: _gates,
      said: 'I can’t recommend Factfulness highly enough.',
      where: 'Twitter',
      year: 2018,
      url: 'https://x.com/BillGates/status/981532684211052545',
    ),
  ],
  'sapiens': [
    BookPick(
      who: 'Bill Gates',
      role: _gates,
      said:
          'I would recommend Sapiens to anyone who’s interested in the '
          'history and future of our species.',
      where: 'GatesNotes',
      year: 2016,
      url: 'https://www.gatesnotes.com/Summer-Books-2016',
    ),
    BookPick(
      who: 'Mark Zuckerberg',
      role: _zuckerberg,
      said: '',
      where: 'A Year of Books, on Facebook',
      year: 2015,
      url: 'https://www.facebook.com/zuck/posts/10102182252999291',
    ),
    BookPick(
      who: 'Naval Ravikant',
      role: _naval,
      said:
          '‘Sapiens’ by Yuval Noah Harari is the best book I’ve read since '
          '‘The Rational Optimist’',
      where: 'Twitter',
      year: 2015,
      url: 'https://x.com/naval/status/579365173485379584',
    ),
  ],
  'influence': [
    BookPick(
      who: 'Charlie Munger',
      role: _munger,
      said: 'I immediately sent copies of Cialdini’s book to all my children.',
      where: 'Poor Charlie’s Almanack',
      year: 2005,
      url: 'https://www.stripe.press/poor-charlies-almanack/book',
    ),
    BookPick(
      who: 'Tobi Lütke',
      role: 'Founder of Shopify',
      said: 'Influence was just the most mind-bending book you can imagine',
      where: 'The Tim Ferriss Show',
      year: 2019,
      url: 'https://tim.blog/2019/02/11/the-tim-ferriss-show-transcripts-tobi-lutke/',
    ),
  ],
  'guns-germs-and-steel': [
    BookPick(
      who: 'Bill Gates',
      role: _gates,
      said:
          'Diamond’s best-known book, Guns, Germs, and Steel, had a profound '
          'effect on the way I think about history',
      where: 'GatesNotes',
      year: 2013,
      url: 'https://www.gatesnotes.com/about-bill-gates/summer-reading-list-2013',
    ),
    BookPick(
      who: 'Charlie Munger',
      role: _munger,
      said:
          '‘Guns, Germs and Steel’ by Jared Diamond. And it’s a marvelous '
          'book.',
      where: _meeting,
      year: 1998,
      url: 'https://buffett.cnbc.com/video/1998/05/04/morning-session---1998-berkshire-hathaway-annual-meeting.html',
    ),
  ],
  'the-selfish-gene': [
    BookPick(
      who: 'Charlie Munger',
      role: _munger,
      said:
          '… Dawkins, ‘The Selfish Gene’ and ‘The Blind Watchmaker’, I mean, '
          'these are marvelous books.',
      where: _meeting,
      year: 1996,
      url: 'https://buffett.cnbc.com/video/1996/05/06/afternoon-session---1996-berkshire-hathaway-annual-meeting.html',
    ),
  ],
  'a-short-history-of-nearly-everything': [
    BookPick(
      who: 'Warren Buffett',
      role: _buffett,
      said:
          'I’ve been reading ‘A Short History of Nearly Everything.’ It’s '
          'very impressive',
      where: _meeting,
      year: 2004,
      url: 'https://buffett.cnbc.com/video/2004/05/01/morning-session---2004-berkshire-hathaway-annual-meeting.html',
    ),
  ],
  'thinking-in-bets': [
    BookPick(
      who: 'Marc Andreessen',
      role: 'Co-founder of Netscape and Andreessen Horowitz',
      said:
          'Compact guide to probabilistic domains like poker, or venture '
          'capital. … Recommend for people operating in the real world.',
      where: 'Twitter',
      year: 2018,
      url: 'https://x.com/pmarca/status/1014991295025012736',
    ),
  ],
  'the-structure-of-scientific-revolutions': [
    BookPick(
      who: 'Mark Zuckerberg',
      role: _zuckerberg,
      said: '',
      where: 'A Year of Books, on Facebook',
      year: 2015,
      url: 'https://www.facebook.com/zuck/posts/10101977184917371',
    ),
  ],
  'how-not-to-be-wrong': [
    BookPick(
      who: 'Bill Gates',
      role: _gates,
      said: '',
      where: 'GatesNotes, his books for the summer',
      year: 2016,
      url: 'https://www.gatesnotes.com/Summer-Books-2016',
    ),
  ],
  'range': [
    BookPick(
      who: 'Bill Gates',
      role: _gates,
      said: '',
      where: 'GatesNotes',
      year: 2020,
      url: 'https://www.gatesnotes.com/Range',
    ),
  ],
};

const String _gates = 'Co-founder of Microsoft';
const String _zuckerberg = 'Founder of Facebook';
const String _naval = 'Co-founder of AngelList';
const String _munger = 'Warren Buffett’s partner at Berkshire Hathaway';
const String _buffett = 'The investor who built Berkshire Hathaway';
const String _meeting = 'Berkshire Hathaway’s annual meeting';

/// The picks of the book [id], none for a book nobody recommended.
List<BookPick> picksOf(String id) => bookPicks[id] ?? const [];
