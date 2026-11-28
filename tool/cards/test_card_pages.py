import json
import re
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest import mock

import card_pages as qp

ROOT = Path(__file__).resolve().parents[2]
SM = "{http://www.sitemaps.org/schemas/sitemap/0.9}"

BANK = {
    "cards": [
        {"id": "space-moon-red", "topic": "space", "strand": "space.light.eclipses", "genre": "space.light",
         "kind": "page", "question": 'Why does the Moon turn "red" <in> an eclipse?',
         "answer": "Bent, filtered sunlight. Earth's air bends it into the shadow and lets only the red through.",
         "move": "The red Moon is lit by sunlight bent by Earth's air.",
         "source": "NASA, Lunar eclipses", "reference": "https://science.nasa.gov/moon/eclipses/. Seen 2026.",
         "written": "2026-11-03",
         "web": {"page": "pages/space-moon-red.html?v=abc", "label": "Sun, Earth and Moon in a row",
                 "thumbs": {"front": "thumbs/space-moon-red-front.webp?v=abc"}}},
        {"id": "space-dwarfs", "topic": "space", "strand": "space.light.eclipses", "genre": "space.light",
         "kind": "read", "question": "What share of nearby stars are red dwarfs?",
         "answer": "About three in four. Most stars near the Sun are small and dim.",
         "move": "The common star is the one you cannot see.", "source": "RECONS",
         "reference": "Henry et al., Astronomical Journal, 2006, doi:10.1086/507834", "checked": "2026-11-20",
         "written": "2026-10-01"},
        {"id": "art-pick", "topic": "art", "strand": "art.modern.abstraction", "genre": "art.modern",
         "kind": "pickOne", "question": "What linked them?",
         "options": ["A shared interest in theosophy", "One teacher", "Each other's work"], "correct": 0,
         "answer": "A shared interest in theosophy. Mondrian joined the society in 1909.",
         "move": "Look for the road they shared.", "source": "Ringbom, The Sounding Cosmos, 1970",
         "reference": "Sixten Ringbom, The Sounding Cosmos, Åbo Akademi, 1970"},
        {"id": "art-sum", "topic": "art", "kind": "number", "question": "What does the house keep?",
         "steps": ["Buyer pays 125", "Seller gets 90", "35 thousand pounds."], "answer": "35 thousand pounds.",
         "value": 35, "unit": "thousand pounds", "source": "Arithmetic", "reference": "Arithmetic"},
        {"id": "art-guess", "topic": "art", "kind": "estimate", "question": "Roughly how heavy is David?",
         "value": 5.6, "unit": "tonnes", "withinFactor": 3, "steps": ["Scale a man up.", "About 5 tonnes."],
         "answer": "About 5 tonnes.", "source": "Galleria dell'Accademia"},
        {"id": "art-side", "topic": "art", "kind": "debate", "question": "Did the money make it?",
         "sides": ["Yes", "No"], "answer": "The money came first.", "counterpoint": "It was famous before.",
         "move": "Look at what came before the money.", "source": "Saunders, 1999"},
        {"id": "life-dr", "topic": "life", "kind": "read", "question": "Who said it?",
         "answer": "Dr. J. Smith said it in the U.S. first. Then others did.", "source": "A paper"},
        {"id": "art-retired", "topic": "art", "kind": "read", "question": "Taken out?", "answer": "Yes.",
         "disabled": True},
        {"id": "art-book-1", "topic": "art", "kind": "read", "question": "A book's first idea?", "answer": "This.",
         "book": {"id": "the-story-of-art", "title": "The Story of Art", "part": 1}},
        {"id": "medicine-adult", "topic": "medicine", "kind": "read", "question": "Kept from families?",
         "answer": "Yes.", "mature": True},
        {"id": "no-question", "topic": "art", "kind": "read"},
    ]
}


def card(cid: str) -> dict:
    return next(c for c in BANK["cards"] if c["id"] == cid)


def cards() -> list:
    return [c for c in BANK["cards"] if qp.has_page(c)]


def render(cid: str) -> str:
    return qp.render(card(cid), cards())


def ld(page: str) -> dict:
    return json.loads(re.search(r'<script type="application/ld\+json">(.*?)</script>', page, re.S).group(1))


class CardPages(unittest.TestCase):
    def test_a_page_for_every_card_the_app_deals_but_a_book_s_or_a_card_kept_from_families(self):
        with tempfile.TemporaryDirectory() as d:
            written = qp.write(Path(d), BANK)
            ids = {c["id"] for c in written}
            self.assertEqual(ids, {"space-moon-red", "space-dwarfs", "art-pick", "art-sum", "art-guess", "art-side", "life-dr"})
            for cid in ids:
                self.assertTrue((Path(d) / "q" / f"{cid}.html").exists(), cid)
            for cid in ("art-retired", "art-book-1", "medicine-adult", "no-question"):
                self.assertFalse((Path(d) / "q" / f"{cid}.html").exists(), cid)
            # The pages' own style and script, beside them.
            self.assertIn(".q-front", (Path(d) / "q" / "q.css").read_text())
            self.assertIn("data-play", (Path(d) / "q" / "q.js").read_text())

    def test_the_question_is_the_title_at_a_clean_address(self):
        page = render("space-dwarfs")
        self.assertIn("<title>What share of nearby stars are red dwarfs? · Astute</title>", page)
        self.assertIn('<h1 class="q-q">What share of nearby stars are red dwarfs?</h1>', page)
        self.assertIn('<link rel="canonical" href="https://astutetheapp.com/q/space-dwarfs">', page)
        self.assertIn('<meta property="og:url" content="https://astutetheapp.com/q/space-dwarfs">', page)
        self.assertIn('<meta name="description" content="About three in four. Most stars near the Sun are small and dim.">', page)
        self.assertNotIn("noindex", page)

    def test_the_short_answer_then_the_why(self):
        page = render("space-dwarfs")
        self.assertIn('<p class="q-short">About three in four.</p>', page)
        self.assertIn("<p>Most stars near the Sun are small and dim.</p>", page)
        self.assertIn("The common star is the one you cannot see.", page)
        # A pick: its right option, marked, and the answer not said twice.
        short, why, _ = qp.answer_of(card("art-pick"))
        self.assertEqual(short, "A shared interest in theosophy.")
        self.assertEqual(why, ["Mondrian joined the society in 1909."])
        self.assertIn('<li class="is-right">A shared interest in theosophy<i>', render("art-pick"))
        # A number: the figure, and the steps that work it out.
        short, why, steps = qp.answer_of(card("art-sum"))
        self.assertEqual((short, steps), ("35 thousand pounds.", ["Buyer pays 125", "Seller gets 90"]))
        self.assertEqual(qp.answer_of(card("art-guess"))[0], "About 5.6 tonnes.")
        # A debate: both sides, and no answer of the page's own.
        page = render("art-side")
        self.assertIn("The money came first.", page)
        self.assertIn("It was famous before.", page)
        self.assertNotIn('class="q-short"', page)

    def test_a_sentence_is_never_cut_at_an_initial_or_an_abbreviation(self):
        self.assertEqual(qp.first_sentence("Dr. J. Smith said it in the U.S. first. Then others did."),
                         ("Dr. J. Smith said it in the U.S. first.", "Then others did."))
        self.assertEqual(qp.first_sentence("It is 3.4 joules. More."), ("It is 3.4 joules.", "More."))
        self.assertEqual(qp.first_sentence("No. The atoms line up."), ("No.", "The atoms line up."))
        self.assertEqual(qp.first_sentence("One long sentence without an end"), ("", "One long sentence without an end"))

    def test_the_source_linked_where_it_can_be_followed(self):
        self.assertEqual(qp.source_link(card("space-moon-red")), "https://science.nasa.gov/moon/eclipses/")
        self.assertEqual(qp.source_link(card("space-dwarfs")), "https://doi.org/10.1086/507834")
        self.assertIsNone(qp.source_link(card("art-pick")))
        page = render("space-dwarfs")
        self.assertIn('<a href="https://doi.org/10.1086/507834" rel="nofollow noopener" target="_blank">RECONS</a>', page)
        self.assertIn("Ringbom, The Sounding Cosmos, 1970</p>", render("art-pick"))

    def test_a_drawn_card_is_played_from_its_page(self):
        page = render("space-moon-red")
        self.assertIn('<a href="/cards/pages/space-moon-red.html" data-play', page)
        self.assertIn('<img src="/cards/thumbs/space-moon-red-front.webp?v=abc"', page)
        self.assertIn('alt="Sun, Earth and Moon in a row"', page)
        self.assertIn('og:image" content="https://astutetheapp.com/cards/thumbs/space-moon-red-front.webp?v=abc"', page)
        self.assertIn("Play the card", page)
        self.assertIn("Gioca la carta", page)
        # Its question is said once, above its drawing, not on a second card.
        self.assertIn('<div class="q-front q-plain">', page)
        self.assertNotIn("data-play", render("space-dwarfs"))

    def test_five_like_this_every_morning_over_the_stores_as_they_stand(self):
        page = render("space-dwarfs")
        self.assertIn("Five like this every morning.", page)
        self.assertIn("Cinque così ogni mattina.", page)
        self.assertIn("https://play.google.com/store/apps/details?id=com.astuto.app", page)
        with mock.patch.object(qp.chrome, "APP_STORE_OPEN", False):
            page = render("space-dwarfs")
            self.assertNotIn("apps.apple.com", page)
            self.assertIn('href="/get#notify"', page)
            self.assertIn('href="/it/get#notify"', page)
        with mock.patch.object(qp.chrome, "APP_STORE_OPEN", True):
            self.assertIn("https://apps.apple.com/app/id6806852300", render("space-dwarfs"))

    def test_the_question_and_its_answer_as_search_engines_read_them(self):
        data = ld(render("space-dwarfs"))
        self.assertEqual(data["@type"], "FAQPage")
        self.assertEqual(data["url"], "https://astutetheapp.com/q/space-dwarfs")
        question = data["mainEntity"][0]
        self.assertEqual(question["@type"], "Question")
        self.assertEqual(question["name"], "What share of nearby stars are red dwarfs?")
        self.assertEqual(question["acceptedAnswer"]["text"], "About three in four. Most stars near the Sun are small and dim.")
        # A card's words cannot end the script they are written in.
        evil = dict(card("space-dwarfs"), question="Is </script><b>x</b> safe?")
        page = qp.render(evil, cards())
        self.assertEqual(page.count("</script>"), 4)
        self.assertEqual(ld(page)["mainEntity"][0]["name"], "Is </script><b>x</b> safe?")

    def test_a_card_s_words_are_escaped(self):
        page = render("space-moon-red")
        self.assertIn("Why does the Moon turn &quot;red&quot; &lt;in&gt; an eclipse?", page)
        self.assertNotIn("<in>", page)

    def test_the_site_around_it_in_both_languages_the_reader_s_shown(self):
        page = render("space-dwarfs")
        self.assertIn(qp.chrome.lang_script("both", "/q/space-dwarfs"), page)
        self.assertIn('<html lang="en">', page)
        for words in ("The answer", "La risposta", "What to keep", "Da portare con te", "Source", "Fonte"):
            self.assertIn(words, page)
        self.assertIn('data-lang-to="it"', page)
        self.assertIn('href="/it/get"', page)
        # The subject in Italian as the app names it, around the card.
        self.assertEqual(qp.SUBJECTS_IT["space"], "Spazio")
        self.assertEqual(qp.SUBJECTS_IT["weird_facts"], "Stranezze")
        self.assertIn("Altro su Spazio", page)
        # On the card too, as the app labels a card in Italian.
        self.assertIn('<span class="l-en">Space</span><span class="l-it" lang="it">Spazio</span></p>', page)
        # The badges and marks drawn from the sprite, not carried.
        self.assertNotIn("<symbol", page)
        self.assertIn('<use href="/assets/sprite.svg?v=', page)
        self.assertTrue((ROOT / "site" / "assets" / "sprite.svg").exists())

    def test_more_on_the_subject_from_the_card_s_own_strand_first(self):
        more = qp.related(card("space-moon-red"), cards())
        self.assertEqual(more[0]["id"], "space-dwarfs")
        self.assertNotIn(card("space-moon-red"), more)
        self.assertLessEqual(len(qp.related(card("art-pick"), cards())), 4)

    def test_a_page_stays_small(self):
        for c in cards():
            self.assertLess(len(qp.render(c, cards()).encode("utf-8")), 16_000, c["id"])

    def test_the_sitemap_an_index_of_files_of_at_most_fifty_thousand(self):
        self.assertEqual(qp.PER_SITEMAP, 50_000)
        with tempfile.TemporaryDirectory() as d:
            written = qp.write(Path(d), BANK, per_sitemap=3)
            index = ET.parse(Path(d) / "sitemap.xml").getroot()
            self.assertEqual(index.tag, SM + "sitemapindex")
            locs = [s.find(SM + "loc").text for s in index]
            self.assertEqual(locs[0], "https://astutetheapp.com/sitemaps/pages.xml")
            self.assertEqual(locs[1:], [f"https://astutetheapp.com/sitemaps/cards-{n}.xml" for n in (1, 2, 3)])
            listed = []
            for loc in locs[1:]:
                urls = ET.parse(Path(d) / loc.split("astutetheapp.com/")[1]).getroot()
                self.assertLessEqual(len(urls), 3)
                listed += [u.find(SM + "loc").text for u in urls]
            self.assertEqual(sorted(listed), sorted(f"https://astutetheapp.com/q/{c['id']}" for c in written))
            pages = [u.find(SM + "loc").text for u in ET.parse(Path(d) / "sitemaps" / "pages.xml").getroot()]
            self.assertIn("https://astutetheapp.com/", pages)
            self.assertIn("https://astutetheapp.com/it/", pages)
            self.assertNotIn("https://astutetheapp.com/get", pages)
            # A card is dated by when it was last checked, or else written.
            text = (Path(d) / "sitemaps" / "cards-1.xml").read_text()
            self.assertIn("<lastmod>2026-11-20</lastmod>", text)
            self.assertNotIn("2026-10-01", text)

    def test_robots_name_the_sitemap_and_keep_out_the_raw_pages(self):
        robots = (ROOT / "site" / "robots.txt").read_text(encoding="utf-8")
        self.assertIn("Sitemap: https://astutetheapp.com/sitemap.xml", robots)
        self.assertIn("Disallow: /cards/pages/", robots)
        self.assertNotIn("Disallow: /q/", robots)
        # The sitemap is the deploy's, from the bank, not a file kept by hand.
        self.assertFalse((ROOT / "site" / "sitemap.xml").exists())

    def test_written_by_the_deploy_from_the_bank_and_stamped(self):
        deploy = (ROOT / ".github" / "workflows" / "deploy.yml").read_text(encoding="utf-8")
        self.assertIn("python3 tool/cards/card_pages.py _site", deploy)
        self.assertLess(deploy.index("cp -r web/cards _site/cards"), deploy.index("tool/cards/card_pages.py"))
        self.assertLess(deploy.index("tool/cards/card_pages.py"), deploy.index("Version the site's stylesheets"))
        self.assertIn("_site/q/*.html", deploy)

    def test_run_as_the_deploy_runs_it(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "cards" / "v2").mkdir(parents=True)
            (Path(d) / "cards" / "v2" / "cards.json").write_text(json.dumps(BANK), encoding="utf-8")
            self.assertEqual(qp.main([d]), 0)
            self.assertTrue((Path(d) / "q" / "space-dwarfs.html").exists())
            self.assertTrue((Path(d) / "sitemap.xml").exists())
        self.assertEqual(qp.main([]), 2)


if __name__ == "__main__":
    unittest.main()
