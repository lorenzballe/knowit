import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import sfida_page as sp

# The site's chrome, as the page imports it (tool/site/chrome.py).
chrome = sp.chrome

ROOT = Path(__file__).resolve().parents[2]


class SfidaPage(unittest.TestCase):
    def test_written_where_the_site_serves_it(self):
        with tempfile.TemporaryDirectory() as d:
            out = sp.write(Path(d))
            self.assertEqual(out, Path(d) / "sfida.html")
            page = out.read_text(encoding="utf-8")
        self.assertTrue(page.startswith("<!DOCTYPE html>"))
        self.assertIn('<html lang="en">', page)
        self.assertIn('<link rel="canonical" href="https://astutetheapp.com/sfida">', page)
        self.assertIn('<meta name="robots" content="noindex">', page)
        self.assertIn('og:image" content="https://astutetheapp.com/assets/og.png"', page)

    def test_the_site_s_own_chrome_style_and_script(self):
        page = sp.render()
        # The nav and the footer, as chrome.py writes them for every page.
        self.assertIn(chrome.header("/", "/"), page)
        self.assertIn(chrome.footer("/", "/"), page)
        # The stylesheet and the script the deploy stamps with the commit,
        # and through which the site counts the page and its store buttons.
        self.assertIn('<link rel="stylesheet" href="/assets/site.css">', page)
        self.assertIn('<script src="/assets/main.js" defer></script>', page)
        # Every subject's mark, for a card to name its subject as the app does.
        for subject in ("science", "pop-culture", "human-body", "weird-facts", "thinking"):
            self.assertIn(f'<symbol id="subject-{subject}"', page)

    def test_it_plays_the_five_the_deploy_publishes(self):
        self.assertIn("json('/five/days.json')", sp.SCRIPT)
        self.assertIn("json('/five/cards/' + encodeURIComponent(id) + '.json')", sp.SCRIPT)
        self.assertIn('<link rel="preload" href="/five/days.json" as="fetch" crossorigin>', sp.render())
        deploy = (ROOT / ".github" / "workflows" / "deploy.yml").read_text(encoding="utf-8")
        self.assertIn("python3 tool/cards/sfida_page.py _site", deploy)
        self.assertIn("TODAYS_FIVE_OUT=_site/five", deploy)
        self.assertLess(deploy.index("tool/cards/sfida_page.py"), deploy.index("Version the site's stylesheets"))

    def test_the_link_says_the_day_and_the_score_and_nothing_else(self):
        read = re.findall(r"query\.get\('(\w+)'\)", sp.SCRIPT)
        self.assertEqual(set(read), {"d", "s"})
        self.assertIn(r"/^\d{4}-\d{2}-\d{2}$/", sp.SCRIPT)
        self.assertIn("/^[0-5]$/", sp.SCRIPT)
        # Nothing is kept on the device.
        for kept in ("localStorage", "sessionStorage", "document.cookie", "indexedDB"):
            self.assertNotIn(kept, sp.SCRIPT)

    def test_an_answer_is_judged_by_the_card_s_file_and_no_rule_of_its_own(self):
        # A pick on the option the card names; a share between the first and
        # last guess its file gives, which are the card's own test, read guess
        # by guess (tool/todays_five.dart). No tolerance, no factor here.
        self.assertIn("said === c.correct", sp.SCRIPT)
        self.assertIn("Array.isArray(c.right) && said >= c.right[0] && said <= c.right[1]", sp.SCRIPT)
        for rule in ("tolerance", "factor", "Math.abs"):
            self.assertNotIn(rule, sp.SCRIPT)
        # The track is set in whole points, from nought to a hundred, as the app's.
        self.assertIn('type="range" min="0" max="100" step="1" value="50"', sp.SCRIPT)

    def has(self, page: str, text: str) -> None:
        """[text] is on [page]; said without the whole page when it is not."""
        self.assertTrue(text in page, text)

    def test_it_says_it_in_the_owner_s_words(self):
        page = sp.render()
        self.has(page, "'A friend got ' + friend + ' of ' + whose + ' 5.'")
        self.has(page, "<span>Your turn.</span>")
        self.has(page, "<small>You</small>")
        self.has(page, "<small>Your friend</small>")
        # Each answer: the friend's, the right one, and its why.
        self.has(page, ">Yours: ' + esc(yours)")
        self.has(page, ">Right: ' + esc(right)")
        self.has(page, "esc(c.why)")
        self.has(page, "<h2>Five new ones tomorrow.</h2>")
        # A day the site no longer has falls back to today's, and says so.
        self.has(page, "so these are today")

    def test_without_its_script_it_still_reads(self):
        page = sp.render()
        self.assertIn("<noscript>", page)
        # The way to the app shows without the script; with it, at the end.
        self.assertIn('<section class="duel-more later" data-more>', page)
        self.assertIn(".js .duel-more.later{display:none}", sp.CSS)

    def test_the_stores_as_they_stand(self):
        with mock.patch.object(sp, "APP_STORE_OPEN", False), mock.patch.object(chrome, "APP_STORE_OPEN", False):
            stores = sp.stores()
            page = sp.render()
            # Google Play the button, the App Store after it and marked as coming.
            self.assertLess(stores.index("store-google-play"), stores.index("store-app-store"))
            self.assertIn("store-app-store store-soon", stores)
            self.assertIn("Coming soon", stores)
            self.assertIn("Free on Android, and coming to iPhone.", page)
        with mock.patch.object(sp, "APP_STORE_OPEN", True), mock.patch.object(chrome, "APP_STORE_OPEN", True):
            stores = sp.stores()
            self.assertLess(stores.index("store-app-store"), stores.index("store-google-play"))
            self.assertNotIn("Coming soon", stores)
            self.assertIn("Free on iPhone and Android.", sp.render())

    def test_its_words_are_escaped_where_the_page_writes_them(self):
        self.assertIn("esc(c.question)", sp.SCRIPT)
        self.assertIn("esc(o)", sp.SCRIPT)
        self.assertIn("esc(c.why)", sp.SCRIPT)
        self.assertIn("esc(c.topic)", sp.SCRIPT)
        self.assertNotRegex(sp.SCRIPT, r"innerHTML = [^;]*c\.question(?!\))")

    def test_run_as_the_deploy_runs_it(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(sp.main([d]), 0)
            self.assertTrue((Path(d) / "sfida.html").exists())
        self.assertEqual(sp.main([]), 2)


if __name__ == "__main__":
    unittest.main()
