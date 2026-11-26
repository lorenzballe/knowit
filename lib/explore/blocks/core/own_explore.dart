/// The build's own Explore: the sections Explore shows when the remote
/// document says nothing of it, drawn by the same engine as any document's,
/// so `explore: null` is that Explore to the pixel. It opens on its cover,
/// the day's cards in a mosaic; then, as the strategic Explore laid it, the
/// reader's day, the day's challenge, the set they are filling, the challenges,
/// their subjects' levels, more like what they saved, the paths, the books
/// and what the founders read; it keeps four of the shelves Explore always
/// had, and ends on the feed. The other shelves are still blocks a document
/// can place.
///
/// remote/examples/explore-today.json is the same list as a document; a
/// test keeps the two the same.
library;

import '../../explore_block.dart';

/// The sections as the remote document would give them, as JSON.
const List<Map<String, Object?>> kOwnExploreJson = [
  // Two lines that are not shelves, then Explore in the order the owner's
  // strategic Explore lays it: the reader's own day first, then what is the
  // same for everyone today, the set they are filling, a minute's play, how
  // far they have gone in each subject, more of what they saved; then the
  // shelves that rank, place and sharpen, and the feed.
  {'id': 'nothing', 'block': 'nothing-here'},
  {'id': 'offline', 'block': 'offline'},
  // Today's three: the day's puzzle, the same three for everyone, scored
  // and set against today's other readers. It opens Explore.
  {'id': 'three', 'block': 'three', 'gap': 6},
  // What the reader started and left; none started, none drawn.
  {'id': 'continue', 'block': 'continue', 'gap': 20},
  // The cover: the day's cards in a mosaic, two large and four small, a
  // subject each.
  {
    'id': 'cover',
    'block': 'cover',
    'gap': 6,
    'source': {
      'query': {'unread': true, 'perSubject': 1, 'limit': 40},
    },
  },
  // Today's five, the week and the streak, a tap from Today.
  // The set the reader is filling: the week's theme, a card at a time.
  {'id': 'path', 'block': 'purpose.set'},
  // The challenges: the games, four tiles to a page, each opening its game.
  {
    'id': 'quick-games',
    'block': 'quick-games',
    'title': {
      'en': 'Challenges',
      'it': 'Sfide',
      'de': 'Herausforderungen',
      'es': 'Desafíos',
      'fr': 'Défis',
      'ja': 'チャレンジ',
      'ko': '챌린지',
      'nl': 'Uitdagingen',
      'pl': 'Wyzwania',
      'pt': 'Desafios',
      'ru': 'Испытания',
      'tr': 'Meydan okumalar',
      'zh': '挑战',
    },
    'subtitle': {
      'en': 'Short exercises in judgement and estimation, a few minutes each.',
      'it': 'Brevi esercizi di giudizio e di stima, pochi minuti ciascuno.',
      'de': 'Kurze Übungen in Urteilskraft und Schätzung, je ein paar Minuten.',
      'es':
          'Ejercicios breves de juicio y estimación, de unos minutos cada uno.',
      'fr': 'De courts exercices de jugement et d\'estimation, de quelques minutes chacun.',
      'ja': '判断と見積もりの短い練習。どれも数分で終わります。',
      'ko': '판단과 추정을 위한 짧은 연습, 하나에 몇 분이면 됩니다.',
      'nl': 'Korte oefeningen in oordeel en schatting, elk een paar minuten.',
      'pl': 'Krótkie ćwiczenia z oceniania i szacowania, po kilka minut każde.',
      'pt': 'Exercícios breves de juízo e estimativa, de poucos minutos cada.',
      'ru': 'Короткие упражнения на суждение и оценку, по несколько минут каждое.',
      'tr': 'Muhakeme ve tahmin üzerine kısa alıştırmalar, her biri birkaç dakika.',
      'zh': '关于判断与估算的简短练习，每个只需几分钟。',
    },
  },
  // How far the reader has gone in each subject they read, 1 to 10.
  {
    'id': 'subject-levels',
    'block': 'subject-levels',
    'title': {
      'en': 'Your subjects',
      'it': 'Le tue materie',
      'de': 'Deine Fächer',
      'es': 'Tus temas',
      'fr': 'Tes sujets',
      'ja': 'あなたの分野',
      'ko': '나의 주제',
      'nl': 'Jouw vakken',
      'pl': 'Twoje tematy',
      'pt': 'Os teus temas',
      'ru': 'Твои темы',
      'tr': 'Konuların',
      'zh': '你的主题',
    },
    'subtitle': {
      'en': 'Level 1 to 10, from the cards you read and get right.',
      'it': 'Livello da 1 a 10, dalle carte che leggi e indovini.',
      'de': 'Stufe 1 bis 10, aus den Karten, die du liest und richtig beantwortest.',
      'es': 'Nivel del 1 al 10, según las cartas que lees y aciertas.',
      'fr': 'Niveau 1 à 10, selon les cartes que tu lis et réussis.',
      'ja': '読んだカードと正解したカードから決まるレベル1〜10。',
      'ko': '읽고 맞힌 카드로 정해지는 레벨 1~10.',
      'nl': 'Niveau 1 tot 10, uit de kaarten die je leest en goed hebt.',
      'pl': 'Poziom od 1 do 10, z kart, które czytasz i odgadujesz.',
      'pt': 'Nível de 1 a 10, pelas cartas que lês e acertas.',
      'ru':
          'Уровень от 1 до 10 — по карточкам, которые ты читаешь и угадываешь.',
      'tr': 'Okuduğun ve doğru bildiğin kartlara göre 1\'den 10\'a seviye.',
      'zh': '等级 1 到 10，取决于你读过和答对的卡片。',
    },
  },
  // Cards close to the reader's latest save, saying which.
  {
    'id': 'like-saved',
    'block': 'like-saved',
    'title': {
      'en': 'More like what you saved',
      'it': 'Altre come quelle che hai salvato',
      'de': 'Mehr wie das, was du behalten hast',
      'es': 'Más como lo que guardaste',
      'fr': 'D\'autres comme celles que tu as gardées',
      'ja': '保存したカードに似たもの',
      'ko': '보관한 카드와 비슷한 카드',
      'nl': 'Meer zoals wat je bewaarde',
      'pl': 'Więcej podobnych do zachowanych',
      'pt': 'Mais como o que guardaste',
      'ru': 'Похожие на сохранённые',
      'tr': 'Sakladıklarına benzer kartlar',
      'zh': '和你收藏的相似',
    },
  },
  // Paths of ten cards on a theme, easy to hard: Astute+, a lock on each
  // for the free plan.
  {
    'id': 'paths',
    'block': 'paths',
    'title': {
      'en': 'Ten-card paths',
      'it': 'Percorsi da 10 carte',
      'de': 'Pfade aus zehn Karten',
      'es': 'Recorridos de 10 cartas',
      'fr': 'Parcours de 10 cartes',
      'ja': '10枚のコース',
      'ko': '10장 코스',
      'nl': 'Paden van tien kaarten',
      'pl': 'Ścieżki z 10 kart',
      'pt': 'Percursos de 10 cartas',
      'ru': 'Маршруты из 10 карточек',
      'tr': '10 kartlık yollar',
      'zh': '十张卡片之路',
    },
    'subtitle': {
      'en': 'One theme, from the easiest card to the hardest.',
      'it': 'Un tema, dalla carta più facile alla più difficile.',
      'de': 'Ein Thema, von der leichtesten Karte bis zur schwersten.',
      'es': 'Un tema, de la carta más fácil a la más difícil.',
      'fr': 'Un thème, de la carte la plus facile à la plus difficile.',
      'ja': 'ひとつのテーマを、やさしいカードから難しいカードへ。',
      'ko': '하나의 주제를 가장 쉬운 카드부터 가장 어려운 카드까지.',
      'nl': 'Eén thema, van de makkelijkste kaart tot de moeilijkste.',
      'pl': 'Jeden temat, od najłatwiejszej karty do najtrudniejszej.',
      'pt': 'Um tema, da carta mais fácil à mais difícil.',
      'ru': 'Одна тема — от самой лёгкой карточки до самой трудной.',
      'tr': 'Tek bir konu, en kolay karttan en zoruna.',
      'zh': '一个主题，从最简单的卡片到最难的。',
    },
  },
  // Books in pills: the book of the week set apart, its cover large, the
  // others in a row under it; two ideas of each free, the week's whole.
  {
    'id': 'books',
    'block': 'books',
    'title': {
      'en': 'Books in pills',
      'it': 'Libri in pillole',
      'de': 'Bücher in Häppchen',
      'es': 'Libros en píldoras',
      'fr': 'Livres en pilules',
      'ja': '本をひとくちで',
      'ko': '한입 책',
      'nl': 'Boeken in hapjes',
      'pl': 'Książki w pigułce',
      'pt': 'Livros em pílulas',
      'ru': 'Книги в двух словах',
      'tr': 'Kapsül kitaplar',
      'zh': '一口读书',
    },
    'subtitle': {
      'en': 'The big ideas of bestsellers, five cards a book, a few minutes in all.',
      'it': 'Le grandi idee dei bestseller, cinque carte a libro, pochi minuti in tutto.',
      'de': 'Die großen Ideen von Bestsellern, fünf Karten pro Buch, ein paar Minuten insgesamt.',
      'es': 'Las grandes ideas de los bestsellers, cinco tarjetas por libro, unos minutos en total.',
      'fr': 'Les grandes idées des best-sellers, cinq cartes par livre, quelques minutes en tout.',
      'ja': 'ベストセラーの大事なアイデアを、1冊5枚のカードで。全部で数分。',
      'ko': '베스트셀러의 핵심 아이디어를 책 한 권에 카드 다섯 장으로. 다 합쳐 몇 분.',
      'nl': 'De grote ideeën van bestsellers, vijf kaarten per boek, een paar minuten in totaal.',
      'pl': 'Najważniejsze idee bestsellerów, pięć kart na książkę, kilka minut w sumie.',
      'pt': 'As grandes ideias dos bestsellers, cinco cartas por livro, poucos minutos ao todo.',
      'ru': 'Главные идеи бестселлеров, пять карточек на книгу, несколько минут на всё.',
      'tr': 'Çok satan kitapların büyük fikirleri, kitap başına beş kart, toplamda birkaç dakika.',
      'zh': '畅销书的核心观点，每本五张卡片，总共几分钟。',
    },
  },
  // What founders read: the people who built the companies everyone
  // knows, each opening the books they recommended in public, and where
  // they said it.
  {
    'id': 'founders',
    'block': 'founders',
    'title': {
      'en': 'What founders read',
      'it': 'Cosa leggono i fondatori',
      'de': 'Was Gründer lesen',
      'es': 'Lo que leen los fundadores',
      'fr': 'Ce que lisent les fondateurs',
      'pt': 'O que leem os fundadores',
      'nl': 'Wat oprichters lezen',
      'pl': 'Co czytają założyciele',
      'ru': 'Что читают основатели',
      'tr': 'Kurucular ne okuyor',
      'ja': '創業者が読む本',
      'ko': '창업자들이 읽는 책',
      'zh': '创始人读什么',
    },
    'subtitle': {
      'en': 'The books they recommended in public, in their own words, and where they said it.',
      'it': 'I libri che hanno consigliato in pubblico, con le loro parole e dove l’hanno detto.',
      'de': 'Die Bücher, die sie öffentlich empfohlen haben, in ihren eigenen Worten, und wo sie es sagten.',
      'es': 'Los libros que recomendaron en público, con sus propias palabras, y dónde lo dijeron.',
      'fr': 'Les livres qu’ils ont recommandés en public, avec leurs propres mots, et où ils l’ont dit.',
      'pt': 'Os livros que recomendaram em público, com as suas palavras, e onde o disseram.',
      'nl': 'De boeken die ze in het openbaar aanraadden, in hun eigen woorden, en waar ze dat zeiden.',
      'pl': 'Książki, które publicznie polecili, ich własnymi słowami, i miejsce, gdzie to powiedzieli.',
      'ru': 'Книги, которые они советовали публично, их собственными словами, и где это было сказано.',
      'tr': 'Herkesin önünde önerdikleri kitaplar, kendi sözleriyle ve bunu nerede söyledikleriyle.',
      'ja': '公の場ですすめた本を、本人の言葉と、それを語った場所とともに。',
      'ko': '공개적으로 추천한 책을, 그들의 말과 그 말을 한 곳과 함께.',
      'zh': '他们公开推荐过的书，附上原话和说话的出处。',
    },
  },
  // The shelves that stay: the readers' top list, where the reader lives,
  // the sharpest, and something to use before tonight.
  {'id': 'top', 'block': 'top'},
  {'id': 'where-you-live', 'block': 'where-you-live'},
  {'id': 'theme-sharpest-0', 'block': 'sharpest'},
  {'id': 'theme-practical-0', 'block': 'practical'},
  // And then no end: the whole bank in the day's order, the same for
  // every reader and never picked for one, for as long as they scroll.
  {
    'id': 'feed',
    'block': 'feed',
    'title': {
      'en': 'Keep exploring',
      'it': 'Continua a esplorare',
      'de': 'Weiter entdecken',
      'es': 'Sigue explorando',
      'fr': 'Continue d\'explorer',
      'ja': 'もっと探す',
      'ko': '계속 둘러보기',
      'nl': 'Verder ontdekken',
      'pl': 'Odkrywaj dalej',
      'pt': 'Continua a explorar',
      'ru': 'Исследуй дальше',
      'tr': 'Keşfetmeye devam et',
      'zh': '继续探索',
    },
    'subtitle': {
      'en': 'The same for everyone. Nothing here is picked for you.',
      'it': 'Uguale per tutti. Niente qui è scelto per te.',
      'de': 'Für alle gleich. Nichts hier ist für dich ausgesucht.',
      'es': 'Igual para todos. Nada aquí está elegido para ti.',
      'fr': 'Pareil pour tout le monde. Rien ici n\'est choisi pour toi.',
      'ja': '誰にとっても同じ。あなた向けに選んだものはありません。',
      'ko': '누구에게나 똑같아요. 맞춤으로 고른 건 없어요.',
      'nl': 'Voor iedereen hetzelfde. Niets hier is voor jou gekozen.',
      'pl': 'Dla wszystkich to samo. Nic tu nie jest wybrane dla ciebie.',
      'pt': 'Igual para todos. Nada aqui foi escolhido para ti.',
      'ru': 'Для всех одинаково. Здесь ничего не подобрано под тебя.',
      'tr': 'Herkes için aynı. Burada hiçbir şey senin için seçilmedi.',
      'zh': '人人看到的都一样，没有为你挑选。',
    },
  },
];

/// The build's own sections.
final List<ExploreSection> kOwnExplore = List.unmodifiable([
  for (final Map<String, Object?> json in kOwnExploreJson)
    ExploreSection.fromJson(json),
]);
