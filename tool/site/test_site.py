"""The site as a reader meets it: in English and in Italian, with the list
for the iPhone, the slim bar, a real title on every page, and every link
going somewhere."""
import json
import re
import unittest
from pathlib import Path
from unittest import mock

import chrome
import i18n

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "site"
PAGES = sorted(SITE.glob("*.html")) + sorted((SITE / "it").glob("*.html"))


def read(rel: str) -> str:
    return (SITE / rel).read_text(encoding="utf-8")


class Languages(unittest.TestCase):
    def test_every_twin_is_what_i18n_writes_and_every_word_is_said(self):
        for lang in chrome.LANGS[1:]:
            pages, missing, stale = i18n.build(lang)
            self.assertEqual(missing, [], "words on the English pages not said in tool/site/lang/%s.json" % lang)
            self.assertEqual(stale, [], "words tool/site/lang/%s.json says that no page shows" % lang)
            for rel, text in pages.items():
                self.assertEqual(read(rel), text, f"site/{rel}: run python3 tool/site/i18n.py")

    def test_a_word_changed_on_the_english_page_is_caught(self):
        words = i18n.table("it")
        words.pop("Five cards a day, two minutes.")
        words["A line no page shows."] = "Una riga che nessuna pagina mostra."
        with mock.patch.object(i18n, "table", lambda lang: words):
            _, missing, stale = i18n.build("it")
        self.assertEqual(missing, ["Five cards a day, two minutes."])
        self.assertEqual(stale, ["A line no page shows."])

    def test_the_italian_landing_page_is_a_page_of_its_own(self):
        page = read("it/index.html")
        self.assertIn('<html lang="it">', page)
        self.assertIn("<title>Astute — cinque carte al giorno: il perché delle cose, e quanto fidarti di ciò che sai</title>", page)
        self.assertIn('<link rel="canonical" href="https://astutetheapp.com/it/">', page)
        self.assertIn('<meta property="og:url" content="https://astutetheapp.com/it/">', page)
        self.assertIn('<meta property="og:locale" content="it_IT">', page)
        self.assertIn("Un po’ più svegli.", page)
        english = read("index.html")
        self.assertIn("<title>Astute — five cards a day: the why behind things, and how far to trust what you know</title>", english)
        # Each names the other for search engines, and English for everyone else.
        for p in (page, english):
            self.assertIn('<link rel="alternate" hreflang="it" href="https://astutetheapp.com/it/">', p)
            self.assertIn('<link rel="alternate" hreflang="en" href="https://astutetheapp.com/">', p)
            self.assertIn('<link rel="alternate" hreflang="x-default" href="https://astutetheapp.com/">', p)

    def test_the_italian_pages_show_the_app_in_italian(self):
        page = read("it/index.html")
        shown = set(re.findall(r'src="/assets/(?:it/)?(app-[a-z-]+\.webp|share-day\.webp)"', page))
        self.assertGreater(len(shown), 8)
        for name in shown:
            self.assertTrue((SITE / "assets" / "it" / name).exists(), name)
            self.assertIn(f'src="/assets/it/{name}"', page, name)
            self.assertNotIn(f'src="/assets/{name}"', page, name)
            self.assertIn(f'src="/assets/{name}"', read("index.html"), name)

    def test_the_twin_links_to_its_own_language(self):
        page = read("it/index.html")
        hrefs = set(re.findall(r'href="(/[^"]*)"', page))
        for english in ("/get", "/sfida", "/privacy", "/terms", "/support", "/delete-account", "/#how"):
            self.assertNotIn(english, hrefs, english)
        for italian in ("/it/get", "/it/sfida", "/privacy#it", "/it/get#notify"):
            self.assertIn(italian, hrefs, italian)
        # Off the landing page, its sections are the Italian landing page's.
        self.assertIn('href="/it/#how"', read("it/get.html"))
        self.assertNotIn('href="/#how"', read("it/get.html"))
        self.assertIn('href="/?lang=en"', page)
        self.assertIn('href="/it/"', read("index.html"))

    def test_a_card_s_own_words_stay_the_card_s_and_say_so(self):
        page = read("it/index.html")
        kept = re.findall(r'<p lang="en" class="deck-q"[^>]*><span>([^<]*)</span>', page)
        self.assertEqual(len(kept), 80)
        self.assertIn("Does foreign aid make poor countries grow faster?", kept)
        self.assertNotIn('<p lang="en" class="deck-q"', read("index.html"))
        # The subjects around them are said, as the app names them.
        self.assertIn("<span>Economia</span>", page)
        self.assertIn("<span>Stranezze</span>", page)

    def test_the_first_screen_reads_its_cards_out_in_the_page_s_language(self):
        page = read("it/index.html")
        self.assertIn('data-t-card="Una carta di {subject}: {what}"', page)
        self.assertIn('["science-bradyseism-breathing-ground", "un tempio romano su un suolo che sale e scende sopra il magma"]', page)
        self.assertIn("science: ['Scienza', '#00E5A0']", page)
        self.assertIn("shelf.dataset.tCard", read("index.html"))

    def test_each_page_picks_its_language_before_it_is_drawn(self):
        english = chrome.lang_script("en", "/")
        self.assertIn("go('/it/')", english)
        self.assertIn("localStorage.getItem(k)", english)
        self.assertIn("/^it(-|$)/i.test(navigator.language||'')", english)
        italian = chrome.lang_script("it", "/")
        self.assertIn("if(s==='en'){go('/');return}", italian)
        self.assertNotIn("&&it", italian, "an Italian twin is never left for a browser's language")
        both = chrome.lang_script("both", "/privacy")
        self.assertIn("location.hash==='#it'?'it'", both)
        self.assertNotIn("go(", both.split("var go")[1].split(";", 1)[1])
        # The one thing kept: the reader's choice, and only when made.
        for script in (english, italian, both):
            self.assertEqual(script.count("localStorage.setItem("), 1)
            self.assertIn("if(q){s=q[2];try{localStorage.setItem(k,s)}", script)
        for page in PAGES:
            text = page.read_text(encoding="utf-8")
            self.assertIn("<!-- @lang --><script>", text, page.name)
            self.assertLess(text.index("<!-- @lang -->"), text.index("<title>"), page.name)

    def test_a_page_in_both_languages_carries_the_chrome_twice_and_shows_one(self):
        header = chrome.header("both", "/privacy")
        self.assertIn('<a class="l-en" href="/#how">How it works</a><a class="l-it" lang="it" href="/it/#how">Come funziona</a>', header)
        self.assertIn('href="#it" hreflang="it" data-lang-to="it"', header)
        self.assertIn('<a class="btn-download l-it" lang="it" href="/it/get" data-store>Scarica</a>', header)
        footer = chrome.footer("both", "/privacy")
        self.assertIn('<a class="l-it" lang="it" href="/privacy#it">Privacy</a>', footer)
        css = read("assets/site.css")
        self.assertIn('html[data-lang="it"] .l-en, html:not([data-lang="it"]) .l-it { display: none !important; }', css)
        self.assertIn('.js[data-lang="it"] .doc section[lang="en"]', css)
        for name in ("privacy.html", "terms.html", "support.html", "delete-account.html", "404.html", "account.html"):
            self.assertIn(chrome.header("both", "/" + name[:-5]), read(name), name)

    def test_the_site_s_script_says_everything_in_both_languages(self):
        script = read("assets/main.js")
        block = script[script.index("const WORDS = {"):script.index("const word = ")]
        en = re.findall(r"^      (\w+):", block[:block.index("    it: {")], re.M)
        it = re.findall(r"^      (\w+):", block[block.index("    it: {"):], re.M)
        self.assertEqual(sorted(en), sorted(it))
        self.assertIn("edition", en)
        # Its prices are the page's, said the same way.
        table = i18n.table("it")
        self.assertIn("yearly: '" + table["Try 14 days free, then €29.99/yr"] + "'", script)
        self.assertIn("right: (acc, gap) => 'Ci hai preso il ' + acc + '% delle volte: ' + gap + ' punti di sicurezza in più del dovuto.'", script)
        self.assertEqual(table["You were right 63% of the time. 7 points overconfident."],
                         "Ci hai preso il 63% delle volte: 7 punti di sicurezza in più del dovuto.")

    def test_everyone_s_five_is_today_s_challenge(self):
        arb = {lang: json.loads((ROOT / "lib" / "l10n" / f"app_{lang}.arb").read_text(encoding="utf-8")) for lang in ("en", "it")}
        self.assertIn("<span>" + arb["en"]["fiveTitle"].replace("'", "’") + "</span>", read("index.html"))
        self.assertIn("<span>" + arb["it"]["fiveTitle"] + "</span>", read("it/index.html"))
        self.assertNotIn("Explore, with Today’s five", read("index.html"))


class TheList(unittest.TestCase):
    def test_apple_s_badge_leads_to_the_list_until_its_listing_is_live(self):
        with mock.patch.object(chrome, "APP_STORE_OPEN", False):
            for lang in ("en", "it", "both"):
                stores = chrome.stores(lang)
                self.assertNotIn("apps.apple.com", stores, lang)
                self.assertIn("store-app-store store-soon", stores)
            self.assertIn('href="/get#notify"', chrome.stores("en"))
            self.assertIn('href="/it/get#notify"', chrome.stores("it"))
            self.assertIn(">In arrivo<", chrome.stores("it"))
        with mock.patch.object(chrome, "APP_STORE_OPEN", True):
            self.assertIn('href="https://apps.apple.com/app/id6806852300"', chrome.stores("en"))
            self.assertEqual(chrome.notify("en"), "<!-- @notify --><!-- /@notify -->")

    def test_no_page_sends_anyone_to_the_app_store_s_empty_page(self):
        self.assertFalse(chrome.APP_STORE_OPEN)
        for page in PAGES:
            self.assertNotRegex(page.read_text(encoding="utf-8"), r'href="https://apps\.apple\.com', page.name)

    def test_get_offers_the_list_and_today_s_challenge_in_each_language(self):
        english, italian = read("get.html"), read("it/get.html")
        self.assertIn('<section class="notify" id="notify"', english)
        self.assertIn("Notify me when it’s on iPhone", english)
        self.assertIn("Avvisami quando arriva su iPhone", italian)
        self.assertIn("Prova la sfida di oggi nel browser", italian)
        self.assertIn('<a class="notify-try" href="/it/sfida">', italian)
        self.assertIn('<a class="notify-try" href="/sfida">', english)
        self.assertIn('data-lang="it"', italian)
        self.assertIn('<script src="/assets/notify.js" type="module"></script>', english)
        self.assertIn('href="/privacy#iphone-list"', english)
        self.assertIn('href="/privacy#lista-iphone"', italian)
        # An Android phone sent for the list stays on it.
        self.assertIn("if (/android/i.test(ua) && location.hash !== '#notify')", english)
        # And the first screen offers both too, to anyone not on Android.
        self.assertIn('<p class="hero-iphone"><a href="/get#notify">', read("index.html"))
        self.assertIn(".android .hero-iphone { display: none; }", read("assets/landing.css"))

    def test_the_page_sends_exactly_what_the_rules_take(self):
        script = read("assets/notify.js")
        rules = (ROOT / "firestore.rules").read_text(encoding="utf-8")
        block = rules[rules.index("match /waitlist/{id}"):]
        block = block[:block.index("}\n")]
        # The address's shape and length, the same on both sides.
        self.assertIn("const SHAPE = /^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$/;", script)
        self.assertIn("request.resource.data.email.matches('[^@\\\\s]+@[^@\\\\s]+[.][^@\\\\s]+')", block)
        self.assertIn("const MAX = 254;", script)
        self.assertIn("request.resource.data.email.size() <= 254", block)
        # Its three fields and nothing else, the moment the server's own.
        self.assertIn("fields: { email: { stringValue: email }, lang: { stringValue: lang } }", script)
        self.assertIn("updateTransforms: [{ fieldPath: 'at', setToServerValue: 'REQUEST_TIME' }]", script)
        self.assertIn("currentDocument: { exists: false }", script)
        self.assertIn("request.resource.data.keys().hasOnly(['email', 'lang', 'at'])", block)
        self.assertIn("request.resource.data.at == request.time", block)
        self.assertIn("/documents/waitlist/${id}", script)
        self.assertIn("id.matches('[A-Za-z0-9]{20}')", block)
        self.assertIn("crypto.getRandomValues(new Uint8Array(20))", script)
        self.assertIn("allow read, update, delete: if false;", block)
        # Through the project the site's account page names, and no other.
        self.assertIn("import { FIREBASE } from './keys.js';", script)
        self.assertIn("projectId: 'astuto-3d398'", read("assets/keys.js"))
        for kept in ("localStorage", "document.cookie", "posthog"):
            self.assertNotIn(kept, script)

    def test_the_privacy_policy_says_what_is_kept_why_and_how_to_leave(self):
        page = read("privacy.html")
        english = page[page.index('<p id="iphone-list">'):]
        english = english[:english.index("</p>")]
        for words in ("your email address", "the language of the page", "Cloud Firestore", "nothing else",
                      "a single email", "Nobody can read the list", "thebalecompany@gmail.com"):
            self.assertIn(words, english)
        italian = page[page.index('<p id="lista-iphone">'):]
        italian = italian[:italian.index("</p>")]
        for words in ("indirizzo email", "la lingua della pagina", "Cloud Firestore", "nient’altro",
                      "un’unica email", "Nessuno può leggere la lista", "thebalecompany@gmail.com"):
            self.assertIn(words, italian)
        self.assertIn("The iPhone list rests on your consent", page)
        self.assertIn("La lista per iPhone si basa sul tuo consenso", page)
        self.assertIn("that choice, in your browser’s storage", page)


class SlimBarAndTitles(unittest.TestCase):
    def test_a_phone_has_the_prices_and_the_store_from_anywhere(self):
        page = read("index.html")
        bar = page[page.index("<!-- @slimbar -->"):page.index("<!-- /@slimbar -->")]
        self.assertIn('<a class="slim-link" href="#pricing">Pricing</a>', bar)
        self.assertIn('<a class="slim-link" href="#faq">FAQ</a>', bar)
        self.assertIn('href="/get" data-store>Download</a>', bar)
        self.assertIn('<a class="slim-go slim-notify" href="/get#notify">Notify me</a>', bar)
        italian = read("it/index.html")
        self.assertIn('<a class="slim-link" href="#pricing">Prezzi</a>', italian)
        self.assertIn('<a class="slim-go slim-notify" href="/it/get#notify">Avvisami</a>', italian)
        css = read("assets/landing.css")
        self.assertIn(".slimbar { display: none; }", css)
        self.assertIn(".slimbar.on { transform: none; opacity: 1; pointer-events: auto; }", css)
        script = read("assets/main.js")
        self.assertIn("const slim = $('[data-slimbar]');", script)
        self.assertIn("slim.inert = !on;", script)

    def test_every_page_has_a_real_title_a_description_and_open_graph(self):
        for page in PAGES:
            text = page.read_text(encoding="utf-8")
            title = re.search(r"<title>([^<]+)</title>", text).group(1)
            self.assertNotEqual(title.strip(), "Astute", page.name)
            self.assertGreater(len(title), 12, page.name)
            for tag in ('<meta name="description" content="', 'property="og:title" content="',
                        'property="og:description" content="', 'property="og:image" content="https://astutetheapp.com/'):
                self.assertIn(tag, text, (page.name, tag))


class Links(unittest.TestCase):
    """Every link on the site goes somewhere: a page of site/, a file the
    deploy copies or writes, or a part of a page that is there."""

    # What the deploy puts beside site/ (.github/workflows/deploy.yml).
    WRITTEN = ("/sfida", "/it/sfida", "/invito", "/app/")
    WRITTEN_UNDER = ("/c/", "/q/", "/cards/", "/five/", "/widget/", "/remote/")

    def resolves(self, path: str) -> bool:
        path = path.split("?")[0]
        if path in self.WRITTEN or path.startswith(self.WRITTEN_UNDER):
            return True
        target = SITE / path.lstrip("/")
        if path.endswith("/"):
            return (target / "index.html").exists()
        return target.exists() or target.with_name(target.name + ".html").exists()

    def page_of(self, path: str):
        path = path.split("?")[0]
        if path.endswith("/"):
            return SITE / path.lstrip("/") / "index.html"
        target = SITE / path.lstrip("/")
        return target.with_name(target.name + ".html") if not target.suffix else target

    def test_every_link_and_source_on_every_page_resolves(self):
        for page in PAGES:
            text = page.read_text(encoding="utf-8")
            here = "/" + str(page.relative_to(SITE)).replace("index.html", "").replace(".html", "")
            for ref in re.findall(r'(?:href|src)="([^"]+)"', text):
                if ref.startswith(("http://", "https://", "mailto:", "data:")):
                    continue
                path, _, part = ref.partition("#")
                if path:
                    self.assertTrue(self.resolves(path), f"{page.name}: {ref}")
                if not part or part in ("it", "en", "top") and path in ("", "/privacy", "/terms", "/support", "/delete-account", here):
                    continue
                target = page if not path else self.page_of(path)
                if target.exists():
                    self.assertRegex(target.read_text(encoding="utf-8"), f'id="{re.escape(part)}"', f"{page.name}: {ref}")

    def test_every_page_of_both_languages_has_its_two_halves(self):
        for name in ("privacy.html", "terms.html", "support.html", "delete-account.html"):
            text = read(name)
            self.assertIn('<section id="en" lang="en">', text, name)
            self.assertIn('<section id="it" lang="it">', text, name)


if __name__ == "__main__":
    unittest.main()
