"""The places tools: the fit matches the phone's, the gaps are the right ones.

    python3 -m unittest discover -s tool/places -p "test_*.py"
"""
from __future__ import annotations

import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

import missing
from places import distance_km, place_cards, place_fit

HERE = Path(__file__).resolve().parent

MODENA = {"country": "IT", "region": "IT-45", "city": "Modena",
          "lat": 44.647, "lon": 10.925, "km": 20}


class FitTest(unittest.TestCase):
    def test_the_cases_the_phone_and_the_server_share(self):
        shared = json.loads((HERE / "fit_cases.json").read_text(encoding="utf-8"))
        for case in shared["cases"]:
            with self.subTest(case["name"]):
                self.assertEqual(place_fit(case["card"], case["reader"]), case["fit"])

    def test_distance_along_the_ground(self):
        # Modena to Bologna, centre to centre: about 37 km.
        self.assertAlmostEqual(distance_km(44.647, 10.925, 44.494, 11.343), 37, delta=2)
        self.assertEqual(distance_km(45.0, 7.0, 45.0, 7.0), 0)


def bank_with(cards: list[dict]) -> Path:
    root = Path(tempfile.mkdtemp())
    for i, place in enumerate(cards):
        folder = root / "history"
        folder.mkdir(exist_ok=True)
        card = {"id": f"history-test-{i}", "place": place}
        if place.pop("disabled", False):
            card["disabled"] = True
        (folder / f"history-test-{i}.json").write_text(json.dumps(card))
    return root


class GapsTest(unittest.TestCase):
    def test_a_reader_with_nothing_needs_city_region_and_country(self):
        reader = {"country": "IT", "region": "IT-45", "city": "Formigine",
                  "lat": 44.574, "lon": 10.848}
        todo = missing.gaps([reader], [])
        self.assertEqual([e["kind"] for e in todo], ["city", "region", "country"])
        self.assertEqual([e["need"] for e in todo], [6, 8, 10])

    def test_a_city_card_nearby_counts_for_the_town_next_to_it(self):
        bank = bank_with([dict(MODENA) for _ in range(6)])
        reader = {"country": "IT", "region": "IT-45", "city": "Formigine",
                  "lat": 44.574, "lon": 10.848}
        kinds = [e["kind"] for e in missing.gaps([reader], place_cards(bank))]
        self.assertNotIn("city", kinds)

    def test_retired_cards_do_not_count(self):
        bank = bank_with([{**MODENA, "disabled": True} for _ in range(6)])
        reader = {"country": "IT", "region": "IT-45", "city": "Modena",
                  "lat": 44.647, "lon": 10.925}
        todo = missing.gaps([reader], place_cards(bank))
        self.assertEqual(todo[0]["kind"], "city")
        self.assertEqual(todo[0]["need"], 6)

    def test_a_city_without_its_centre_is_flagged_not_guessed(self):
        todo = missing.gaps([{"country": "IT", "city": "Formigine"}], [])
        city = [e for e in todo if e["kind"] == "city"][0]
        self.assertTrue(city["needs_centre"])

    def test_two_readers_in_one_place_are_one_place(self):
        reader = {"country": "IT", "region": "IT-45"}
        todo = missing.gaps([reader, dict(reader)], [])
        region = [e for e in todo if e["kind"] == "region"]
        self.assertEqual(len(region), 1)
        self.assertEqual(region[0]["readers"], 2)

    def test_a_region_without_a_code_is_left_to_its_country(self):
        todo = missing.gaps([{"country": "FR", "region": "Bretagne"}], [])
        self.assertEqual([e["kind"] for e in todo], ["country"])

    def test_cities_come_before_regions_before_countries(self):
        readers = [{"country": "IT"},
                   {"country": "IT", "region": "IT-82", "city": "Palermo",
                    "lat": 38.116, "lon": 13.361}]
        kinds = [e["kind"] for e in missing.gaps(readers, [])]
        self.assertEqual(kinds, ["city", "region", "country"])

    def test_the_command_line_takes_at_most_max_places(self):
        readers = Path(tempfile.mkdtemp()) / "readers.json"
        readers.write_text(json.dumps([{"country": "IT", "region": "IT-45",
                                        "city": "Modena", "lat": 44.647,
                                        "lon": 10.925}]))
        empty = Path(tempfile.mkdtemp())
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(missing.main([str(readers), "--bank", str(empty),
                                           "--max", "2", "--json"]), 0)
        self.assertEqual([e["kind"] for e in json.loads(out.getvalue())],
                         ["city", "region"])
        table = io.StringIO()
        with contextlib.redirect_stdout(table):
            missing.main([str(readers), "--bank", str(empty)])
        self.assertIn("Modena", table.getvalue())
        self.assertIn("country", table.getvalue())


if __name__ == "__main__":
    unittest.main()
