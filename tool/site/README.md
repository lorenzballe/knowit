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
