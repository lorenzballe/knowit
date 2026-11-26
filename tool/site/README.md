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
