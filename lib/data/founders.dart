/// What founders read: the people who built the companies everyone knows,
/// and the investors who built Berkshire Hathaway, each with the books in
/// pills they recommended in public, in their own words, and where they
/// said it, so anyone can check. Explore's row of them draws them
/// (explore/blocks/core/founders_block.dart), each opening a page of their
/// books; a book's own page says who recommended it.
///
/// Every pick is one the person made in public, in words quoted exactly from
/// the page [BookPick.url] links to: their own site, letter, interview or
/// talk. A pick nobody can check is not here; a shorter list is better than
/// one wrong name. None of them has any connection with Astute, and their
/// page says so.
///
/// Each person's face is a photo free to use, from Wikimedia Commons (CC0,
/// public domain, CC BY or CC BY-SA), cropped square and kept small in the
/// app at `assets/founders/<id>.webp`; who took it, under what licence, where
/// it is and what was done to it are in assets/founders/CREDITS.md and in
/// [FounderPhoto], and the person's page says them. Without one, the
/// initials of their name stand in. (Builds before these faces were in the
/// app fetch the earlier photos from the site, web/cards/people/, which stay
/// for them.)
///
/// A pick names a book by its id (lib/data/books.dart): the book is listed,
/// and opened, while its cards are in the bank, and passed over while they
/// are not, as is a person none of whose books are.
library;

/// One person's recommendation of one book.
class BookPick {
  const BookPick({
    required this.book,
    required this.said,
    required this.where,
    required this.year,
    required this.url,
    this.whereKey,
  });

  /// The book, by its id: "sapiens".
  final String book;

  /// Their words about the book, quoted exactly from [url]; empty where the
  /// recommendation is a list with no words of its own.
  final String said;

  /// Where they said it, in English: "GatesNotes", "Berkshire Hathaway’s
  /// annual meeting".
  final String where;

  /// [where] by name, when it is a phrase to say in the reader's language
  /// (`founderWhere` in the arb files: "berkshire_meeting"); null where it
  /// is a name every language keeps as it is: "GatesNotes", "Twitter".
  final String? whereKey;

  /// The year they said it.
  final int year;

  /// The page where anyone can read it.
  final String url;

  /// Where and when, in English, as a page prints it: "GatesNotes, 2016",
  /// its first letter set up where the place is a phrase ("His letter
  /// to…"). A page says it in the reader's language (founders_block.dart).
  String get source {
    final String place = where.isEmpty
        ? where
        : where[0].toUpperCase() + where.substring(1);
    return '$place, $year';
  }
}

/// A person's photo: who took it, under what licence, and its page on
/// Wikimedia Commons; the file itself is `assets/founders/<id>.webp`, cropped
/// square from the original.
class FounderPhoto {
  const FounderPhoto({
    required this.author,
    required this.licence,
    required this.page,
  });

  /// Who took it, as Commons credits them: "Nick".
  final String author;

  /// Its licence, as Commons names it: "CC BY 2.0", "Public domain".
  final String licence;

  /// Its page on Commons, with the licence.
  final String page;
}

/// One person and the books they recommended, in the order their page
/// lists them.
class Founder {
  const Founder({
    required this.id,
    required this.name,
    required this.role,
    required this.picks,
    this.photo,
  });

  /// Their name in a key or an event: "bill-gates".
  final String id;

  /// Who, as everybody knows them: "Bill Gates".
  final String name;

  /// What they built, in a few words, in English: "Co-founder of
  /// Microsoft". A page says it in the reader's language, by [id]
  /// (`founderRole` in the arb files).
  final String role;

  /// Their picks, the one they said most about first.
  final List<BookPick> picks;

  /// Their photo, or null where there is none yet.
  final FounderPhoto? photo;

  /// Where their photo is kept in the app.
  String get photoAsset => 'assets/founders/$id.webp';

  /// The initials of their first and last names: "BG".
  String get monogram {
    final List<String> words = [
      for (final String w in name.split(' '))
        if (w.isNotEmpty) w,
    ];
    if (words.isEmpty) return '';
    return words.length == 1
        ? words.first[0]
        : '${words.first[0]}${words.last[0]}';
  }
}

/// The people, in the order the row shows them.
const List<Founder> kFounders = [
  Founder(
    id: 'bill-gates',
    name: 'Bill Gates',
    role: 'Co-founder of Microsoft',
    photo: FounderPhoto(
      author: 'Bogdan Hoyaux / European Union',
      licence: 'CC BY 4.0',
      page: 'https://commons.wikimedia.org/wiki/File:Bill_Gates_at_the_European_Commission_-_P067383-987995_(cropped)_5.jpg',
    ),
    picks: [
      BookPick(
        book: 'business-adventures',
        said: 'The best business book I’ve ever read',
        where: 'GatesNotes',
        year: 2014,
        url: 'https://www.gatesnotes.com/Business-Adventures',
      ),
      BookPick(
        book: 'factfulness',
        said: 'I can’t recommend Factfulness highly enough.',
        where: 'Twitter',
        year: 2018,
        url: 'https://x.com/BillGates/status/981532684211052545',
      ),
      BookPick(
        book: 'sapiens',
        said:
            'I would recommend Sapiens to anyone who’s interested in the '
            'history and future of our species.',
        where: 'GatesNotes',
        year: 2016,
        url: 'https://www.gatesnotes.com/Summer-Books-2016',
      ),
      BookPick(
        book: 'guns-germs-and-steel',
        said:
            'Diamond’s best-known book, Guns, Germs, and Steel, had a '
            'profound effect on the way I think about history',
        where: 'GatesNotes',
        year: 2013,
        url: 'https://www.gatesnotes.com/about-bill-gates/summer-reading-list-2013',
      ),
      BookPick(
        book: 'how-not-to-be-wrong',
        said: '',
        where: 'GatesNotes, his books for the summer',
        whereKey: 'gates_summer',
        year: 2016,
        url: 'https://www.gatesnotes.com/Summer-Books-2016',
      ),
      BookPick(
        book: 'range',
        said: '',
        where: 'GatesNotes',
        year: 2020,
        url: 'https://www.gatesnotes.com/Range',
      ),
    ],
  ),
  Founder(
    id: 'warren-buffett',
    name: 'Warren Buffett',
    role: 'The investor who built Berkshire Hathaway',
    photo: FounderPhoto(
      author: 'USA International Trade Administration',
      licence: 'Public domain',
      page: 'https://commons.wikimedia.org/wiki/File:Warren_Buffett_at_the_2015_SelectUSA_Investment_Summit_(cropped).jpg',
    ),
    picks: [
      BookPick(
        book: 'the-intelligent-investor',
        said:
            '… read The Intelligent Investor. That’s the book that gave me '
            'the philosophy that has taken me now for a lot of years.',
        where: _meeting,
        whereKey: _meetingKey,
        year: 2008,
        url: 'https://buffett.cnbc.com/video/2008/05/03/morning-session---2008-berkshire-hathaway-annual-meeting.html',
      ),
      BookPick(
        book: 'shoe-dog',
        said:
            'The best book I read last year was Shoe Dog, by Nike’s Phil '
            'Knight.',
        where: 'his letter to Berkshire Hathaway’s shareholders',
        whereKey: 'berkshire_letter',
        year: 2017,
        url: 'https://www.berkshirehathaway.com/letters/2016ltr.pdf',
      ),
      BookPick(
        book: 'a-short-history-of-nearly-everything',
        said:
            'I’ve been reading ‘A Short History of Nearly Everything.’ It’s '
            'very impressive',
        where: _meeting,
        whereKey: _meetingKey,
        year: 2004,
        url: 'https://buffett.cnbc.com/video/2004/05/01/morning-session---2004-berkshire-hathaway-annual-meeting.html',
      ),
    ],
  ),
  Founder(
    id: 'mark-zuckerberg',
    name: 'Mark Zuckerberg',
    role: 'Founder of Facebook',
    photo: FounderPhoto(
      author: 'The White House',
      licence: 'Public domain',
      page: 'https://commons.wikimedia.org/wiki/File:P20260929DT-1655_(55561811540)_(cropped_2).jpg',
    ),
    picks: [
      BookPick(
        book: 'sapiens',
        said: '',
        where: 'A Year of Books, on Facebook',
        whereKey: 'year_of_books',
        year: 2015,
        url: 'https://www.facebook.com/zuck/posts/10102182252999291',
      ),
      BookPick(
        book: 'the-structure-of-scientific-revolutions',
        said: '',
        where: 'A Year of Books, on Facebook',
        whereKey: 'year_of_books',
        year: 2015,
        url: 'https://www.facebook.com/zuck/posts/10101977184917371',
      ),
    ],
  ),
  Founder(
    id: 'charlie-munger',
    name: 'Charlie Munger',
    role: 'Warren Buffett’s partner at Berkshire Hathaway',
    photo: FounderPhoto(
      author: 'Nick',
      licence: 'CC BY 2.0',
      page: 'https://commons.wikimedia.org/wiki/File:Charlie_Munger_(cropped).jpg',
    ),
    picks: [
      BookPick(
        book: 'influence',
        said:
            'I immediately sent copies of Cialdini’s book to all my children.',
        where: 'Poor Charlie’s Almanack',
        year: 2005,
        url: 'https://www.stripe.press/poor-charlies-almanack/book',
      ),
      BookPick(
        book: 'guns-germs-and-steel',
        said:
            '‘Guns, Germs and Steel’ by Jared Diamond. And it’s a marvelous '
            'book.',
        where: _meeting,
        whereKey: _meetingKey,
        year: 1998,
        url: 'https://buffett.cnbc.com/video/1998/05/04/morning-session---1998-berkshire-hathaway-annual-meeting.html',
      ),
      BookPick(
        book: 'the-selfish-gene',
        said:
            '… Dawkins, ‘The Selfish Gene’ and ‘The Blind Watchmaker’, I '
            'mean, these are marvelous books.',
        where: _meeting,
        whereKey: _meetingKey,
        year: 1996,
        url: 'https://buffett.cnbc.com/video/1996/05/06/afternoon-session---1996-berkshire-hathaway-annual-meeting.html',
      ),
    ],
  ),
  Founder(
    id: 'marc-andreessen',
    name: 'Marc Andreessen',
    role: 'Co-founder of Netscape and Andreessen Horowitz',
    photo: FounderPhoto(
      author: 'TechCrunch',
      licence: 'CC BY 2.0',
      page: 'https://commons.wikimedia.org/wiki/File:TechCrunch_Disrupt_SF_2016_-_Day_2.jpg',
    ),
    picks: [
      BookPick(
        book: 'zero-to-one',
        said:
            'Zero to One is the first book any working or aspiring '
            'entrepreneur must read—period.',
        where: 'his praise for the book, at its publisher',
        whereKey: 'publisher_praise',
        year: 2014,
        url: 'https://www.penguinrandomhouse.com/books/234730/zero-to-one-by-peter-thiel-with-blake-masters/',
      ),
      BookPick(
        book: 'thinking-in-bets',
        said:
            'Compact guide to probabilistic domains like poker, or venture '
            'capital. … Recommend for people operating in the real world.',
        where: 'Twitter',
        year: 2018,
        url: 'https://x.com/pmarca/status/1014991295025012736',
      ),
    ],
  ),
  Founder(
    id: 'tobi-lutke',
    name: 'Tobi Lütke',
    role: 'Founder of Shopify',
    photo: FounderPhoto(
      author: 'Benjamin Forrest',
      licence: 'CC BY-SA 4.0',
      page: 'https://commons.wikimedia.org/wiki/File:NYC-Commerce-Tobi-L%C3%BCtki-561.jpg',
    ),
    picks: [
      BookPick(
        book: 'influence',
        said: 'Influence was just the most mind-bending book you can imagine',
        where: 'The Tim Ferriss Show',
        year: 2019,
        url: 'https://tim.blog/2019/02/11/the-tim-ferriss-show-transcripts-tobi-lutke/',
      ),
      BookPick(
        book: 'high-output-management',
        said: '',
        where: 'The Tim Ferriss Show, among the five best books he has read',
        whereKey: 'ferriss_five',
        year: 2019,
        url: 'https://tim.blog/2019/02/11/the-tim-ferriss-show-transcripts-tobi-lutke/',
      ),
    ],
  ),
  Founder(
    id: 'naval-ravikant',
    name: 'Naval Ravikant',
    role: 'Co-founder of AngelList',
    photo: FounderPhoto(
      author: 'Edmund Hillary Fellowship',
      licence: 'CC BY 3.0',
      page: 'https://commons.wikimedia.org/wiki/File:Naval2019.png',
    ),
    picks: [
      BookPick(
        book: 'sapiens',
        said:
            '‘Sapiens’ by Yuval Noah Harari is the best book I’ve read since '
            '‘The Rational Optimist’',
        where: 'Twitter',
        year: 2015,
        url: 'https://x.com/naval/status/579365173485379584',
      ),
    ],
  ),
];

const String _meeting = 'Berkshire Hathaway’s annual meeting';
const String _meetingKey = 'berkshire_meeting';

/// The person [id] names, or null.
Founder? founderById(String id) {
  for (final Founder f in kFounders) {
    if (f.id == id) return f;
  }
  return null;
}

/// Who recommended the book [id], each with their pick, in the row's
/// order; none for a book nobody here recommended.
List<(Founder, BookPick)> picksOf(String id) => [
  for (final Founder f in kFounders)
    for (final BookPick k in f.picks)
      if (k.book == id) (f, k),
];
