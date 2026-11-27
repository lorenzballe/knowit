# The site's chrome

`chrome.py` writes the nav and the footer onto every page under `site/`,
between the markers each page carries — `<!-- @header -->` … `<!-- /@header -->`,
and the same for the footer — so that six pages cannot drift apart. Run it
after changing either:

    python3 tool/site/chrome.py

The deploy runs it with `--check` and stops if a page has drifted.

It also writes every link to the App Store, in the chrome and in the pages
alike, as the one URL it builds: with `APP_STORE_PROVIDER_TOKEN` set, each
carries the provider token Apple's campaign links need, beside the campaign
(`ct`) that `site/assets/main.js` adds as the page loads. The token is not in
the repository; the comment above it says where in App Store Connect to find
it. Set it, run the script, and every page has it.

It writes where the app can be had, too. `GOOGLE_PLAY_OPEN` and
`APP_STORE_OPEN` at the top of the script say which listings are live (today
Google Play is, the App Store is not), and from them it writes the store
badges (Apple's marked "Coming soon", its link kept, while its listing is
not live), where every Download button leads (`/get` until the App Store is
live, never the store's empty page), the line between `<!-- @where -->` …
`<!-- /@where -->`, the FAQ's answer between `<!-- @where-faq -->` …
`<!-- /@where-faq -->`, the switch in `/get` that sends an iPhone to the App
Store only once it is live, and the operating systems the landing page names
to search engines. Each challenge page (`tool/cards/challenge_pages.py`)
reads the same switch for its footer and its buttons. The day the App Store
listing is live, set `APP_STORE_OPEN = True`, run the script and commit what
it rewrites: that one line is the whole change.

# The site's pictures of the app

The phones on the landing page are the app itself, shot on an iPhone 16 Pro
in English, dark, with real cards, by `tool/site_shots.dart`. Shoot them and
copy them into `site/assets/` at the size and quality the page uses:

    SHOTS=/some/folder flutter test tool/site_shots.dart --update-goldens
    python3 tool/site/shots.py /some/folder

The camera says in its header what each picture shows.

# The cards on the first screen

The phone on the landing page holds five of the bank's drawn cards on its
shelf, going on by themselves, and four more stand around it. They are a
new nine every day, the same for everyone that day, never a card two days
running: the page's own script (`site/index.html`, after the phone) deals
them from the date, out of a pool written into it, and `site/assets/main.js`
moves them.

The pool is the bank's most beautiful drawings, chosen by eye in November
2026 from two lists: the ranking every drawn card was given against the
owner's lessons on drawings (docs/cards/ESEMPI.md, lessons 3, 5 and 6: of
934, one excellent and 34 good), and the cards redrawn in the waves that
followed it, which the owner set as the level. Of those, the ones whose
front shows the real thing big, at a glance, in the house style; then a few
of the acceptable ones, for subjects the drawn cards rarely reach (space,
food, sport). Cards on war, drugs or politics were left out of the first
screen. Each entry is the card's id and a few words on what its drawing
shows, which the page reads out to whoever cannot see it.

`test/web/site_hero_test.dart` checks that every card of the pool is in the
bank, dealt, drawn, with its pictures and its page on the site, and named
for its subject as the page expects. To change the pool, change the list in
the page; a card taken out of the bank fails the test until it is taken out
of the list too.

# Today's five

Under the first screen the site shows Today's five: the five questions at
the top of Explore in the app, the same on every phone that day. The deploy
deals them with the app's own deal (`DailyDeal.five`) for every day from the
day before it to four hundred days after, `flutter test tool/todays_five.dart`
writing `five/days.json` (each day's five ids and its edition) and
`five/cards/<id>.json` (what the page shows of each card). The page picks the
reader's own date and links each question to its card's page (`/c/<id>`).
`test/web/todays_five_test.dart` checks what the script writes against the
deal itself, date by date.
