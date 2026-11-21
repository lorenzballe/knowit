/// The line of the day: one sentence worth keeping, the same for every
/// reader, each checked against where it was first written (the page
/// [DayLine.url] links to: the book, the letter, the talk, or a sourced
/// collection of them), never a line passed around under a famous name.
/// Explore draws it (explore/blocks/core/line_block.dart): on Explore for
/// every subject any of them, on a subject's page those of its themes.
library;

/// One line, and where it was first written.
class DayLine {
  const DayLine({
    required this.text,
    required this.author,
    required this.work,
    required this.year,
    this.translator = '',
    required this.theme,
    required this.url,
  });

  /// The words, as first written, or in the English translation named.
  final String text;

  final String author;

  /// Where it was first written: a book, an essay, a letter, a talk.
  final String work;

  /// When, as a year or the nearest a date allows: "1859", "c. 340 BC".
  final String year;

  /// Who put it into English, for a line first written in another
  /// language; empty for one written in English.
  final String translator;

  /// What it is about: thinking, science, life, decisions, people, money.
  final String theme;

  /// The page where anyone can read it where it was written.
  final String url;
}

/// The subjects whose page shows the lines of each theme, by their keys
/// (lib/data/topics.dart).
const Map<String, List<String>> dayLineSubjects = {
  'thinking': ['thinking', 'philosophy'],
  'science': ['science'],
  'life': ['life', 'philosophy'],
  'decisions': ['thinking', 'life', 'economics'],
  'people': ['psychology', 'life'],
  'money': ['economics'],
};

/// The line of [today], the same for every reader: on Explore for every
/// subject one of all of them, on the page of the subject keyed [subject]
/// one of its themes', or null where it has none. The lines go round in a stride that is prime to
/// their number, so each comes once before any comes again and no theme
/// runs for days on end.
DayLine? lineOfDay(DateTime today, {String? subject}) {
  final List<DayLine> lines = [
    for (final DayLine l in dayLines)
      if (subject == null ||
          (dayLineSubjects[l.theme] ?? const []).contains(subject))
        l,
  ];
  if (lines.isEmpty) return null;
  final int day = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(2026)).inDays;
  int stride = 37;
  while (_gcd(stride, lines.length) != 1) {
    stride++;
  }
  return lines[(day * stride) % lines.length];
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// Every line, by theme.
const List<DayLine> dayLines = [
  DayLine(
    text: 'The first principle is that you must not fool yourself—and you are the easiest person to fool.',
    author: 'Richard Feynman',
    work: '“Cargo Cult Science”',
    year: '1974',
    theme: 'thinking',
    url: 'https://calteches.library.caltech.edu/51/2/CargoCult.htm',
  ),
  DayLine(
    text: 'A wise man, therefore, proportions his belief to the evidence.',
    author: 'David Hume',
    work: 'An Enquiry Concerning Human Understanding',
    year: '1748',
    theme: 'thinking',
    url: 'https://standardebooks.org/ebooks/david-hume/an-enquiry-concerning-human-understanding/text/single-page',
  ),
  DayLine(
    text: 'He who knows only his own side of the case, knows little of that.',
    author: 'John Stuart Mill',
    work: 'On Liberty',
    year: '1859',
    theme: 'thinking',
    url: 'https://standardebooks.org/ebooks/john-stuart-mill/on-liberty/text/single-page',
  ),
  DayLine(
    text: 'Ignorance more frequently begets confidence than does knowledge: it is those who know little, and not those who know much, who so positively assert that this or that problem will never be solved by science.',
    author: 'Charles Darwin',
    work: 'The Descent of Man',
    year: '1871',
    theme: 'thinking',
    url: 'https://en.wikisource.org/wiki/The_Descent_of_Man_(Darwin)/Introduction',
  ),
  DayLine(
    text: 'The fundamental cause of the trouble is that in the modern world the stupid are cocksure, while the intelligent are full of doubt.',
    author: 'Bertrand Russell',
    work: '“The Triumph of Stupidity”',
    year: '1933',
    theme: 'thinking',
    url: 'https://quoteinvestigator.com/2015/03/04/self-doubt/',
  ),
  DayLine(
    text: 'So convenient a thing is it to be a reasonable creature, since it enables one to find or make a reason for everything one has a mind to do.',
    author: 'Benjamin Franklin',
    work: 'The Autobiography of Benjamin Franklin',
    year: '1771',
    theme: 'thinking',
    url: 'https://standardebooks.org/ebooks/benjamin-franklin/the-autobiography-of-benjamin-franklin/text/single-page',
  ),
  DayLine(
    text: 'To see what is in front of one’s nose needs a constant struggle.',
    author: 'George Orwell',
    work: '“In Front of Your Nose”',
    year: '1946',
    theme: 'thinking',
    url: 'https://www.orwellfoundation.com/the-orwell-foundation/orwell/essays-and-other-works/in-front-of-your-nose/',
  ),
  DayLine(
    text: 'The human understanding when it has once adopted an opinion (either as being the received opinion or as being agreeable to itself) draws all things else to support and agree with it.',
    author: 'Francis Bacon',
    work: 'Novum Organum',
    year: '1620',
    translator: 'James Spedding, Robert Leslie Ellis and Douglas Denon Heath',
    theme: 'thinking',
    url: 'https://en.wikisource.org/wiki/Novum_Organum/Book_I_(Spedding)',
  ),
  DayLine(
    text: 'Nothing in life is as important as you think it is, while you are thinking about it.',
    author: 'Daniel Kahneman',
    work: '“Focusing Illusion”, for Edge',
    year: '2011',
    theme: 'thinking',
    url: 'https://www.edge.org/response-detail/11984',
  ),
  DayLine(
    text: 'As the art of reading (after a certain stage in one’s education) is the art of skipping, so the art of being wise is the art of knowing what to overlook.',
    author: 'William James',
    work: 'The Principles of Psychology',
    year: '1890',
    theme: 'thinking',
    url: 'https://psychclassics.yorku.ca/James/Principles/prin22.htm',
  ),
  DayLine(
    text: 'For the mind does not require filling like a bottle, but rather, like wood, it only requires kindling to create in it an impulse to think independently and an ardent desire for the truth.',
    author: 'Plutarch',
    work: '“On Listening to Lectures”',
    year: 'c. 100',
    translator: 'Frank Cole Babbitt',
    theme: 'thinking',
    url: 'https://penelope.uchicago.edu/Thayer/E/Roman/Texts/Plutarch/Moralia/De_auditu*.html',
  ),
  DayLine(
    text: 'It is the mark of an educated man to look for precision in each class of things just so far as the nature of the subject admits; it is evidently equally foolish to accept probable reasoning from a mathematician and to demand from a rhetorician scientific proofs.',
    author: 'Aristotle',
    work: 'Nicomachean Ethics',
    year: 'c. 340 BC',
    translator: 'W. D. Ross',
    theme: 'thinking',
    url: 'https://classics.mit.edu/Aristotle/nicomachaen.1.i.html',
  ),
  DayLine(
    text: 'The difficulty lies, not in the new ideas, but in escaping from the old ones, which ramify, for those brought up as most of us have been, into every corner of our minds.',
    author: 'John Maynard Keynes',
    work: 'The General Theory of Employment, Interest and Money',
    year: '1936',
    theme: 'thinking',
    url: 'https://www.marxists.org/reference/subject/economics/keynes/general-theory/preface.htm',
  ),
  DayLine(
    text: 'The more labels you have for yourself, the dumber they make you.',
    author: 'Paul Graham',
    work: '“Keep Your Identity Small”',
    year: '2009',
    theme: 'thinking',
    url: 'https://www.paulgraham.com/identity.html',
  ),
  DayLine(
    text: 'What Orwell feared were those who would ban books. What Huxley feared was that there would be no reason to ban a book, for there would be no one who wanted to read one.',
    author: 'Neil Postman',
    work: 'Amusing Ourselves to Death',
    year: '1985',
    theme: 'thinking',
    url: 'https://en.wikiquote.org/wiki/Neil_Postman',
  ),
  DayLine(
    text: 'Reasoning will never make a Man correct an ill Opinion, which by Reasoning he never acquired.',
    author: 'Jonathan Swift',
    work: 'A Letter to a Young Gentleman',
    year: '1721',
    theme: 'thinking',
    url: 'https://quoteinvestigator.com/2015/07/10/reason-out/',
  ),
  DayLine(
    text: 'The most difficult subjects can be explained to the most slow-witted man if he has not formed any idea of them already; but the simplest thing cannot be made clear to the most intelligent man if he is firmly persuaded that he knows already, without a shadow of doubt, what is laid before him.',
    author: 'Leo Tolstoy',
    work: 'The Kingdom of God Is Within You',
    year: '1894',
    translator: 'Constance Garnett',
    theme: 'thinking',
    url: 'https://en.wikisource.org/wiki/The_Kingdom_of_God_Is_Within_You_(1894)/Chapter_3',
  ),
  DayLine(
    text: 'What information consumes is rather obvious: it consumes the attention of its recipients. Hence a wealth of information creates a poverty of attention and a need to allocate that attention efficiently among the overabundance of information sources that might consume it.',
    author: 'Herbert A. Simon',
    work: '“Designing Organizations for an Information-Rich World”',
    year: '1971',
    theme: 'thinking',
    url: 'https://en.wikiquote.org/wiki/Herbert_A._Simon',
  ),
  DayLine(
    text: 'Science is the belief in the ignorance of experts.',
    author: 'Richard Feynman',
    work: '“What Is Science?”',
    year: '1966',
    theme: 'science',
    url: 'https://doi.org/10.1119/1.2351388',
  ),
  DayLine(
    text: 'For a successful technology, reality must take precedence over public relations, for nature cannot be fooled.',
    author: 'Richard Feynman',
    work: 'Report on the Space Shuttle Challenger accident',
    year: '1986',
    theme: 'science',
    url: 'https://history.nasa.gov/rogersrep/v2appf.htm',
  ),
  DayLine(
    text: 'There is grandeur in this view of life, with its several powers, having been originally breathed into a few forms or into one; and that, whilst this planet has gone cycling on according to the fixed law of gravity, from so simple a beginning endless forms most beautiful and most wonderful have been, and are being, evolved.',
    author: 'Charles Darwin',
    work: 'On the Origin of Species',
    year: '1859',
    theme: 'science',
    url: 'https://en.wikisource.org/wiki/On_the_Origin_of_Species_(1859)/Chapter_XIV',
  ),
  DayLine(
    text: 'The great tragedy of Science—the slaying of a beautiful hypothesis by an ugly fact.',
    author: 'Thomas Henry Huxley',
    work: '“Biogenesis and Abiogenesis”',
    year: '1870',
    theme: 'science',
    url: 'https://mathcs.clarku.edu/huxley/CE8/B-Ab.html',
  ),
  DayLine(
    text: 'If I have seen further it is by standing on ye sholders of Giants.',
    author: 'Isaac Newton',
    work: 'Letter to Robert Hooke',
    year: '1676',
    theme: 'science',
    url: 'https://en.wikiquote.org/wiki/Isaac_Newton',
  ),
  DayLine(
    text: 'The Analytical Engine has no pretensions whatever to originate anything. It can do whatever we know how to order it to perform.',
    author: 'Ada Lovelace',
    work: 'Notes on the Analytical Engine',
    year: '1843',
    theme: 'science',
    url: 'https://www.fourmilab.ch/babbage/sketch.html',
  ),
  DayLine(
    text: 'We can only see a short distance ahead, but we can see plenty there that needs to be done.',
    author: 'Alan Turing',
    work: '“Computing Machinery and Intelligence”',
    year: '1950',
    theme: 'science',
    url: 'https://doi.org/10.1093/mind/LIX.236.433',
  ),
  DayLine(
    text: 'We have to remember that what we observe is not nature herself, but nature exposed to our method of questioning.',
    author: 'Werner Heisenberg',
    work: 'Physics and Philosophy',
    year: '1958',
    theme: 'science',
    url: 'https://en.wikiquote.org/wiki/Werner_Heisenberg',
  ),
  DayLine(
    text: 'Now, my own suspicion is that the universe is not only queerer than we suppose, but queerer than we can suppose.',
    author: 'J. B. S. Haldane',
    work: '“Possible Worlds”',
    year: '1927',
    theme: 'science',
    url: 'https://en.wikiquote.org/wiki/J._B._S._Haldane',
  ),
  DayLine(
    text: 'A new scientific truth does not triumph by convincing its opponents and making them see the light, but rather because its opponents eventually die, and a new generation grows up that is familiar with it.',
    author: 'Max Planck',
    work: 'Scientific Autobiography',
    year: '1948',
    translator: 'Frank Gaynor',
    theme: 'science',
    url: 'https://quoteinvestigator.com/2017/09/25/progress/',
  ),
  DayLine(
    text: 'Nothing is too wonderful to be true, if it be consistent with the laws of nature; and in such things as these, experiment is the best test of such consistency.',
    author: 'Michael Faraday',
    work: 'Laboratory journal',
    year: '1849',
    theme: 'science',
    url: 'https://en.wikiquote.org/wiki/Michael_Faraday',
  ),
  DayLine(
    text: 'Far better an approximate answer to the right question, which is often vague, than an exact answer to the wrong question, which can always be made precise.',
    author: 'John Tukey',
    work: '“The Future of Data Analysis”',
    year: '1962',
    theme: 'decisions',
    url: 'https://doi.org/10.1214/aoms/1177704711',
  ),
  DayLine(
    text: 'Should you find yourself in a chronically-leaking boat, energy devoted to changing vessels is likely to be more productive than energy devoted to patching leaks.',
    author: 'Warren Buffett',
    work: 'Letter to Berkshire Hathaway shareholders',
    year: '1986',
    theme: 'decisions',
    url: 'https://www.berkshirehathaway.com/letters/1985.html',
  ),
  DayLine(
    text: 'Worldly wisdom teaches that it is better for reputation to fail conventionally than to succeed unconventionally.',
    author: 'John Maynard Keynes',
    work: 'The General Theory of Employment, Interest and Money',
    year: '1936',
    theme: 'decisions',
    url: 'https://www.marxists.org/reference/subject/economics/keynes/general-theory/ch12.htm',
  ),
  DayLine(
    text: 'You can’t connect the dots looking forward; you can only connect them looking backwards. So you have to trust that the dots will somehow connect in your future.',
    author: 'Steve Jobs',
    work: 'Stanford commencement address',
    year: '2005',
    theme: 'decisions',
    url: 'https://news.stanford.edu/stories/2005/06/youve-got-find-love-jobs-says',
  ),
  DayLine(
    text: 'If you do not work on an important problem, it’s unlikely you’ll do important work.',
    author: 'Richard Hamming',
    work: '“You and Your Research”',
    year: '1986',
    theme: 'decisions',
    url: 'https://www.cs.virginia.edu/~robins/YouAndYourResearch.html',
  ),
  DayLine(
    text: 'If it is not right, do not do it: if it is not true, do not say it.',
    author: 'Marcus Aurelius',
    work: 'Meditations',
    year: 'c. 170–180',
    translator: 'George Long',
    theme: 'decisions',
    url: 'https://standardebooks.org/ebooks/marcus-aurelius/meditations/george-long/text/single-page',
  ),
  DayLine(
    text: 'Not everything that is faced can be changed; but nothing can be changed until it is faced.',
    author: 'James Baldwin',
    work: '“As Much Truth As One Can Bear”',
    year: '1962',
    theme: 'decisions',
    url: 'https://quoteinvestigator.com/2021/10/09/faced/',
  ),
  DayLine(
    text: 'As our case is new, so we must think anew and act anew.',
    author: 'Abraham Lincoln',
    work: 'Annual Message to Congress',
    year: '1862',
    theme: 'decisions',
    url: 'https://www.presidency.ucsb.edu/documents/second-annual-message-9',
  ),
  DayLine(
    text: 'Most decisions should probably be made with somewhere around 70% of the information you wish you had. If you wait for 90%, in most cases, you’re probably being slow.',
    author: 'Jeff Bezos',
    work: 'Letter to Amazon shareholders',
    year: '2017',
    theme: 'decisions',
    url: 'https://www.aboutamazon.com/news/company-news/2016-letter-to-shareholders',
  ),
  DayLine(
    text: 'I went to the woods because I wished to live deliberately, to front only the essential facts of life, and see if I could not learn what it had to teach, and not, when I came to die, discover that I had not lived.',
    author: 'Henry David Thoreau',
    work: 'Walden',
    year: '1854',
    theme: 'life',
    url: 'https://standardebooks.org/ebooks/henry-david-thoreau/walden/text/single-page',
  ),
  DayLine(
    text: 'There are more things, Lucilius, likely to frighten us than there are to crush us; we suffer more often in imagination than in reality.',
    author: 'Seneca',
    work: 'Moral Letters to Lucilius',
    year: 'c. 65',
    translator: 'Richard M. Gummere',
    theme: 'life',
    url: 'https://en.wikisource.org/wiki/Moral_letters_to_Lucilius/Letter_13',
  ),
  DayLine(
    text: 'Ask yourself whether you are happy, and you cease to be so.',
    author: 'John Stuart Mill',
    work: 'Autobiography',
    year: '1873',
    theme: 'life',
    url: 'https://standardebooks.org/ebooks/john-stuart-mill/the-autobiography-of-john-stuart-mill/text/single-page',
  ),
  DayLine(
    text: 'I have discovered that all the unhappiness of men arises from one single fact, that they cannot stay quietly in their own chamber.',
    author: 'Blaise Pascal',
    work: 'Pensées',
    year: '1670',
    translator: 'W. F. Trotter',
    theme: 'life',
    url: 'https://www.ccel.org/ccel/pascal/pensees.iii.html',
  ),
  DayLine(
    text: 'One must imagine Sisyphus happy.',
    author: 'Albert Camus',
    work: 'The Myth of Sisyphus',
    year: '1942',
    translator: 'Justin O’Brien',
    theme: 'life',
    url: 'https://en.wikiquote.org/wiki/Albert_Camus',
  ),
  DayLine(
    text: 'How we spend our days is, of course, how we spend our lives.',
    author: 'Annie Dillard',
    work: 'The Writing Life',
    year: '1989',
    theme: 'life',
    url: 'https://en.wikiquote.org/wiki/Annie_Dillard',
  ),
  DayLine(
    text: 'Tell me, what is it you plan to do / with your one wild and precious life?',
    author: 'Mary Oliver',
    work: '“The Summer Day”',
    year: '1990',
    theme: 'life',
    url: 'https://poets.org/poem/summer-day',
  ),
  DayLine(
    text: 'Your time is limited, so don’t waste it living someone else’s life.',
    author: 'Steve Jobs',
    work: 'Stanford commencement address',
    year: '2005',
    theme: 'life',
    url: 'https://news.stanford.edu/stories/2005/06/youve-got-find-love-jobs-says',
  ),
  DayLine(
    text: 'I constantly see people rise in life who are not the smartest, sometimes not even the most diligent. But they are learning machines.',
    author: 'Charlie Munger',
    work: 'USC Law School commencement address',
    year: '2007',
    theme: 'life',
    url: 'https://www.stripe.press/poor-charlies-almanack/book',
  ),
  DayLine(
    text: 'Men are disturbed not by the things which happen, but by the opinions about the things.',
    author: 'Epictetus',
    work: 'Enchiridion',
    year: 'c. 125',
    translator: 'George Long',
    theme: 'life',
    url: 'https://standardebooks.org/ebooks/epictetus/short-works/george-long/text/single-page',
  ),
  DayLine(
    text: 'What do we live for, if it is not to make life less difficult to each other?',
    author: 'George Eliot',
    work: 'Middlemarch',
    year: '1871–72',
    theme: 'people',
    url: 'https://standardebooks.org/ebooks/george-eliot/middlemarch/text/single-page',
  ),
  DayLine(
    text: 'Happy families are all alike; every unhappy family is unhappy in its own way.',
    author: 'Leo Tolstoy',
    work: 'Anna Karenina',
    year: '1878',
    translator: 'Constance Garnett',
    theme: 'people',
    url: 'https://standardebooks.org/ebooks/leo-tolstoy/anna-karenina/constance-garnett/text/single-page',
  ),
  DayLine(
    text: 'I am, somehow, less interested in the weight and convolutions of Einstein’s brain than in the near certainty that people of equal talent have lived and died in cotton fields and sweatshops.',
    author: 'Stephen Jay Gould',
    work: '“Wide Hats and Narrow Minds”',
    year: '1979',
    theme: 'people',
    url: 'https://en.wikiquote.org/wiki/Stephen_Jay_Gould',
  ),
  DayLine(
    text: 'The best way of avenging thyself is not to become like the wrong doer.',
    author: 'Marcus Aurelius',
    work: 'Meditations',
    year: 'c. 170–180',
    translator: 'George Long',
    theme: 'people',
    url: 'https://standardebooks.org/ebooks/marcus-aurelius/meditations/george-long/text/single-page',
  ),
  DayLine(
    text: 'We are what we pretend to be, so we must be careful about what we pretend to be.',
    author: 'Kurt Vonnegut',
    work: 'Mother Night',
    year: '1966',
    theme: 'people',
    url: 'https://en.wikiquote.org/wiki/Kurt_Vonnegut',
  ),
  DayLine(
    text: 'We tell ourselves stories in order to live.',
    author: 'Joan Didion',
    work: '“The White Album”',
    year: '1979',
    theme: 'people',
    url: 'https://en.wikiquote.org/wiki/Joan_Didion',
  ),
  DayLine(
    text: 'We simply attempt to be fearful when others are greedy and to be greedy only when others are fearful.',
    author: 'Warren Buffett',
    work: 'Letter to Berkshire Hathaway shareholders',
    year: '1987',
    theme: 'money',
    url: 'https://www.berkshirehathaway.com/letters/1986.html',
  ),
  DayLine(
    text: 'After all, you only find out who is swimming naked when the tide goes out.',
    author: 'Warren Buffett',
    work: 'Letter to Berkshire Hathaway shareholders',
    year: '2002',
    theme: 'money',
    url: 'https://www.berkshirehathaway.com/2001ar/2001letter.html',
  ),
  DayLine(
    text: 'But this long run is a misleading guide to current affairs. In the long run we are all dead.',
    author: 'John Maynard Keynes',
    work: 'A Tract on Monetary Reform',
    year: '1923',
    theme: 'money',
    url: 'https://en.wikiquote.org/wiki/John_Maynard_Keynes',
  ),
  DayLine(
    text: 'A woman must have money and a room of her own if she is to write fiction.',
    author: 'Virginia Woolf',
    work: 'A Room of One’s Own',
    year: '1929',
    theme: 'money',
    url: 'https://en.wikiquote.org/wiki/Virginia_Woolf',
  ),
  DayLine(
    text: 'It is not from the benevolence of the butcher, the brewer, or the baker, that we expect our dinner, but from their regard to their own interest.',
    author: 'Adam Smith',
    work: 'The Wealth of Nations',
    year: '1776',
    theme: 'money',
    url: 'https://standardebooks.org/ebooks/adam-smith/the-wealth-of-nations/text/single-page',
  ),
  DayLine(
    text: 'Play iterated games. All the returns in life, whether in wealth, relationships, or knowledge, come from compound interest.',
    author: 'Naval Ravikant',
    work: '“How to Get Rich (without getting lucky)”',
    year: '2018',
    theme: 'money',
    url: 'https://x.com/naval/status/1002103908947263488',
  ),
];
