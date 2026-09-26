# The site's chrome

`chrome.py` writes the nav and the footer onto every page under `site/`,
between the markers each page carries — `<!-- @header -->` … `<!-- /@header -->`,
and the same for the footer — so that six pages cannot drift apart. Run it
after changing either:

    python3 tool/site/chrome.py

The deploy runs it with `--check` and stops if a page has drifted.
