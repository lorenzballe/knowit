/// The build's own Explore: the sections Explore shows when the remote
/// document says nothing of it, drawn by the same engine as any document's,
/// so `explore: null` is that Explore to the pixel. Since the strategic
/// Explore it opens on the reader's day, the day's challenge, the set they
/// are filling, quick games, their subjects' levels and more like what they
/// saved, keeps four of the shelves Explore always had, and ends on the
/// feed; the other shelves are still blocks a document can place.
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
  // Today's five, the week and the streak, a tap from Today.
  {'id': 'your-day', 'block': 'your-day', 'gap': 4},
  // One bet, alone and large, the same for every reader today. What others
  // guessed is not shown: the phone has no such counts
  // (docs/explore/bets.md).
  {
    'id': 'bets-day',
    'block': 'bets-day',
    'size': 'l',
    'title': {
      'en': 'The daily challenge',
      'it': 'La sfida del giorno',
      'de': 'Die Herausforderung des Tages',
      'es': 'El reto del día',
      'fr': 'Le défi du jour',
      'ja': '今日のチャレンジ',
      'ko': '오늘의 도전',
      'nl': 'De uitdaging van de dag',
      'pl': 'Wyzwanie dnia',
      'pt': 'O desafio do dia',
      'ru': 'Задание дня',
      'tr': 'Günün meydan okuması',
      'zh': '每日挑战',
    },
    'subtitle': {
      'en': 'The same for everyone today. Lock in your guess, then see how far off you were.',
      'it': 'Uguale per tutti, oggi. Blocca la tua stima, poi guarda di quanto hai sbagliato.',
      'de': 'Heute für alle gleich. Leg dich fest, dann sieh, wie weit du danebenlagst.',
      'es': 'Hoy, igual para todos. Fija tu estimación y luego mira cuánto te has desviado.',
      'fr': 'Le même pour tout le monde aujourd\'hui. Valide ton estimation, puis découvre l\'écart.',
      'ja': '今日は誰にとっても同じ。予想を確定して、どれだけ近かったか確かめよう。',
      'ko': '오늘은 모두에게 같아요. 추측을 확정하고 얼마나 빗나갔는지 확인하세요.',
      'nl': 'Vandaag voor iedereen hetzelfde. Leg je schatting vast en zie hoe ver je ernaast zat.',
      'pl': 'Dziś dla wszystkich to samo. Zatwierdź swój typ i sprawdź, jak daleko był od prawdy.',
      'pt': 'Hoje, igual para todos. Fixa o teu palpite e vê a que distância ficaste.',
      'ru': 'Сегодня для всех одно и то же. Зафиксируй догадку и узнай, насколько она точна.',
      'tr': 'Bugün herkes için aynı. Tahminini kilitle, sonra ne kadar yaklaştığını gör.',
      'zh': '今天人人相同。锁定你的估计，再看看差了多少。',
    },
  },
  // The set the reader is filling: the week's theme, a card at a time.
  {'id': 'path', 'block': 'purpose.set'},
  // Four games, a tile each, each opening its game on a page of its own.
  {
    'id': 'quick-games',
    'block': 'quick-games',
    'title': {
      'en': 'Quick games',
      'it': 'Giochi veloci',
      'de': 'Schnelle Spiele',
      'es': 'Juegos rápidos',
      'fr': 'Jeux rapides',
      'ja': 'クイックゲーム',
      'ko': '빠른 게임',
      'nl': 'Snelle spelletjes',
      'pl': 'Szybkie gry',
      'pt': 'Jogos rápidos',
      'ru': 'Быстрые игры',
      'tr': 'Hızlı oyunlar',
      'zh': '快速游戏',
    },
    'subtitle': {
      'en': 'A minute or two each. Pick one and play.',
      'it': 'Un minuto o due ciascuno. Scegline uno e gioca.',
      'de': 'Je ein, zwei Minuten. Such dir eins aus und spiel.',
      'es': 'Uno o dos minutos cada uno. Elige uno y juega.',
      'fr': 'Une minute ou deux chacun. Choisis-en un et joue.',
      'ja': 'どれも1〜2分。選んで遊ぼう。',
      'ko': '하나에 1~2분. 골라서 플레이하세요.',
      'nl': 'Een minuutje of twee per stuk. Kies er een en speel.',
      'pl': 'Każda na minutę lub dwie. Wybierz i graj.',
      'pt': 'Um ou dois minutos cada. Escolhe um e joga.',
      'ru': 'По минуте-другой на каждую. Выбери и играй.',
      'tr': 'Her biri bir iki dakika. Birini seç ve oyna.',
      'zh': '每个只要一两分钟。选一个开始玩。',
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
