import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import chrome
import invito_page as ip

ROOT = Path(__file__).resolve().parents[2]


class InvitoPage(unittest.TestCase):
    def test_written_where_the_site_serves_it(self):
        with tempfile.TemporaryDirectory() as d:
            out = ip.write(Path(d))
            self.assertEqual(out, Path(d) / "invito.html")
            page = out.read_text(encoding="utf-8")
        self.assertTrue(page.startswith("<!DOCTYPE html>"))
        self.assertIn('<link rel="canonical" href="https://astutetheapp.com/invito">', page)
        self.assertIn('<meta name="robots" content="noindex">', page)
        self.assertIn('og:image" content="https://astutetheapp.com/assets/og.png"', page)

    def test_the_site_s_own_chrome_style_and_script(self):
        page = ip.render()
        # In both languages, the reader's shown, as on every page that holds both.
        self.assertIn(chrome.header("both", "/invito"), page)
        self.assertIn(chrome.footer("both", "/invito"), page)
        # The stylesheet and the script the deploy stamps with the commit, and
        # through which the site counts the page and its store buttons.
        self.assertIn('<link rel="stylesheet" href="/assets/site.css">', page)
        self.assertIn('<script src="/assets/main.js" defer></script>', page)

    def test_the_code_the_server_draws_and_nothing_else(self):
        # The alphabet and the length are the server's (functions/src/invite.ts).
        server = (ROOT / "functions" / "src" / "invite.ts").read_text(encoding="utf-8")
        self.assertIn(f"export const CODE_ALPHABET = '{ip.CODE_ALPHABET}';", server)
        self.assertIn(f"export const CODE_LENGTH = {ip.CODE_LENGTH};", server)
        self.assertIn("/^[23456789BCDFGHJKMNPQRSTVWXYZ]{6}$/.test(raw)", ip.SCRIPT)
        # The link says the code alone, and the page reads nothing else of it.
        self.assertEqual(set(re.findall(r"query\.get\('(\w+)'\)", ip.SCRIPT)), {"c"})
        # Shown as text, never as markup.
        self.assertIn("el.textContent = code", ip.SCRIPT)
        self.assertNotIn("innerHTML", ip.SCRIPT)

    def test_the_code_leaves_the_address_before_anything_is_counted(self):
        page = ip.render()
        self.assertIn("history.replaceState(", ip.SCRIPT)
        self.assertIn("query.delete('c')", ip.SCRIPT)
        # The page's script runs as the page is read; the site's, which loads
        # what counts, only after it (defer).
        self.assertLess(page.index("history.replaceState("), page.index("</body>"))
        self.assertIn('<script src="/assets/main.js" defer></script>', page)
        for kept in ("localStorage", "sessionStorage", "document.cookie", "indexedDB"):
            self.assertNotIn(kept, ip.SCRIPT)

    def test_on_android_one_button_opens_the_app_on_the_code_or_the_store(self):
        self.assertIn(
            "'intent://astutetheapp.com/invito?c=' + code + '#Intent;scheme=https;package=com.astuto.app;"
            "S.browser_fallback_url=' + encodeURIComponent(store) + ';end'", ip.SCRIPT)
        self.assertIn(f"const store = '{chrome.GOOGLE_PLAY}';", ip.SCRIPT)
        # The path the app is handed (AndroidManifest.xml, apple-app-site-association).
        manifest = (ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml").read_text(encoding="utf-8")
        self.assertIn('android:path="/invito"', manifest)
        apple = json.loads((ROOT / "site" / ".well-known" / "apple-app-site-association").read_text(encoding="utf-8"))
        components = apple["applinks"]["details"][0]["components"]
        self.assertIn("/invito", [c["/"] for c in components])

    def test_in_english_and_italian_the_browser_s_first(self):
        page = ip.render()
        self.assertIn('<section class="invite" id="en" lang="en"', page)
        self.assertIn('<section class="invite" id="it" lang="it"', page)
        # The site's own choice of language, before the page is drawn: the one
        # chosen with the switch, or else the browser's.
        self.assertEqual(ip.EARLY, chrome.lang_script("both", "/invito"))
        self.assertIn("/^it(-|$)/i.test(navigator.language||'')", ip.EARLY)
        self.assertIn("localStorage.getItem(k)", ip.EARLY)
        self.assertLess(page.index(ip.EARLY), page.index("<body>"))
        # The page's own way to the other language keeps the choice too.
        self.assertIn('data-switch="it" data-lang-to="it"', page)
        for lang in ("en", "it"):
            self.assertEqual(set(ip.WORDS[lang]), set(ip.WORDS["en"]), lang)
        self.assertIn("Una settimana di Astute+, in regalo.", page)
        self.assertIn("A week of Astute+, on a friend.", page)

    def test_the_app_s_own_words_for_where_a_code_is_typed(self):
        for lang in ("en", "it"):
            arb = json.loads((ROOT / "lib" / "l10n" / f"app_{lang}.arb").read_text(encoding="utf-8"))
            self.assertEqual(ip.APP_WORDS[lang]["row"], arb["inviteCodeRow"], lang)
            self.assertEqual(ip.APP_WORDS[lang]["profile"], arb["tabProfile"], lang)
            self.assertIn(ip.APP_WORDS[lang]["row"], ip.section(lang))

    def test_what_it_promises_is_what_the_server_does(self):
        server = (ROOT / "functions" / "src" / "invite.ts").read_text(encoding="utf-8")
        self.assertIn("export const NEW_FOR_DAYS = 7;", server)
        self.assertIn("export const WEEKS_A_YEAR = 8;", server)
        self.assertIn("less than a week ago", ip.WORDS["en"]["rules"])
        self.assertIn("eight weeks a year", ip.WORDS["en"]["rules"])
        self.assertIn("meno di una settimana", ip.WORDS["it"]["rules"])
        self.assertIn("otto settimane", ip.WORDS["it"]["rules"])
        # Free time, and nothing else: no price, no rating, no review.
        for lang in ("en", "it"):
            words = " ".join(ip.WORDS[lang].values()).lower()
            for never in ("€", "$", "price", "prezzo", "rating", "review", "recensione", "stelle", "stars"):
                self.assertNotIn(never, words, (lang, never))

    def test_the_stores_as_they_stand(self):
        with mock.patch.object(ip, "APP_STORE_OPEN", False), mock.patch.object(chrome, "APP_STORE_OPEN", False):
            stores = ip.stores()
            page = ip.render()
            self.assertLess(stores.index("store-google-play"), stores.index("store-app-store"))
            self.assertIn("store-app-store store-soon", stores)
            self.assertIn("Free on Android, and coming to iPhone.", page)
            self.assertIn("Gratis su Android, e presto su iPhone.", page)
        with mock.patch.object(ip, "APP_STORE_OPEN", True), mock.patch.object(chrome, "APP_STORE_OPEN", True):
            stores = ip.stores()
            self.assertLess(stores.index("store-app-store"), stores.index("store-google-play"))
            self.assertNotIn("Coming soon", stores)
            self.assertIn("Gratis su iPhone e Android.", ip.render())

    def test_without_its_script_it_still_reads(self):
        page = ip.render()
        # Both languages, one after the other, and the line that says where
        # the code is; the code itself only with the script.
        self.assertIn(".js .invite{display:none}", ip.CSS)
        self.assertIn(".has-code .invite-code{display:block}", ip.CSS)
        self.assertIn('class="invite-nocode"', page)

    def test_written_by_the_deploy_before_the_stamp(self):
        deploy = (ROOT / ".github" / "workflows" / "deploy.yml").read_text(encoding="utf-8")
        self.assertIn("python3 tool/site/invito_page.py _site", deploy)
        self.assertIn('python3 -m unittest discover -s tool/site -p "test_*.py"', deploy)
        self.assertLess(deploy.index("tool/site/invito_page.py"), deploy.index("Version the site's stylesheets"))

    def test_run_as_the_deploy_runs_it(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(ip.main([d]), 0)
            self.assertTrue((Path(d) / "invito.html").exists())
        self.assertEqual(ip.main([]), 2)


if __name__ == "__main__":
    unittest.main()
