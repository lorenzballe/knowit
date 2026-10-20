"""The app part's checker: the update gate, the switches, the numbers and the
experiments, each held to what the app can read, item by item — and the
store links the gate sends readers to, held to the site's."""
from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

import check  # noqa: E402
from parts import app  # noqa: E402


def problems(doc) -> list[str]:
    return app.check(doc)


class GateTest(unittest.TestCase):
    def test_the_brief_s_three_gates_pass(self):
        self.assertEqual(problems({"gate": {"minBuild": {"ios": 7, "android": 7}, "blocked": [5, 6]}}), [])
        self.assertEqual(problems({"gate": {"suggestBuild": {"ios": 8}}}), [])
        self.assertEqual(problems({"gate": {"pause": {"on": True, "audience": {"platforms": ["android"]}}}}), [])
        self.assertEqual(problems({"gate": None}), [])
        self.assertEqual(problems({"gate": {
            "minBuild": {"ios": 7}, "suggestBuild": {"ios": 9}, "blocked": {"android": [3]},
            "pause": {"on": False},
            "message": {"hard": {"it": "Serve la versione nuova.", "en": "The new version is needed."},
                        "pause": {"en": "Back within the hour."}},
        }}), [])

    def test_a_build_is_a_whole_number_for_a_store(self):
        said = problems({"gate": {"minBuild": {"web": 3, "ios": 0, "android": "7"}}})
        self.assertTrue(any("gate.minBuild.web" in p and "store" in p for p in said), said)
        self.assertTrue(any("gate.minBuild.ios" in p for p in said), said)
        self.assertTrue(any("gate.minBuild.android" in p for p in said), said)
        self.assertTrue(problems({"gate": {"minBuild": 7}}))

    def test_a_suggestion_below_the_floor_would_never_be_seen(self):
        said = problems({"gate": {"minBuild": {"ios": 8}, "suggestBuild": {"ios": 8}}})
        self.assertEqual(len(said), 1)
        self.assertIn("gate.suggestBuild.ios", said[0])

    def test_blocked_builds(self):
        self.assertTrue(problems({"gate": {"blocked": [5, 5]}}))
        self.assertTrue(problems({"gate": {"blocked": []}}))
        self.assertTrue(problems({"gate": {"blocked": [0, "6"]}}))
        self.assertTrue(problems({"gate": {"blocked": {"web": [4]}}}))
        self.assertEqual(problems({"gate": {"blocked": {"ios": [4, 5], "android": [2]}}}), [])

    def test_a_pause_says_whether_it_is_on(self):
        self.assertTrue(problems({"gate": {"pause": {"audience": {}}}}))
        self.assertTrue(problems({"gate": {"pause": {"on": "yes"}}}))
        self.assertTrue(problems({"gate": {"pause": {"on": True, "until": "2026-10-20"}}}))
        self.assertTrue(problems({"gate": {"pause": {"on": True, "audience": {"country": "IT"}}}}))

    def test_messages_by_screen_and_language(self):
        self.assertTrue(problems({"gate": {"message": {"update": {"en": "x"}}}}))
        self.assertTrue(problems({"gate": {"message": {"pause": {"xx": "x"}}}}))
        self.assertTrue(problems({"gate": {"message": {"pause": {"en": " "}}}}))
        self.assertTrue(problems({"gate": {"message": {"pause": {"en": "x" * 301}}}}))
        self.assertTrue(problems({"gate": {"message": {"pause": {"en": "Back at {time}"}}}}))

    def test_unknown_keys_are_named(self):
        said = problems({"gate": {"minimum": {"ios": 3}}, "switches": {}})
        self.assertTrue(any("'minimum'" in p for p in said), said)
        self.assertTrue(any("'switches'" in p for p in said), said)


class FlagsTest(unittest.TestCase):
    def test_a_switch_is_a_bool_or_on_with_an_audience(self):
        self.assertEqual(problems({"flags": {"review.ask": False}}), [])
        self.assertEqual(problems({"flags": {"push.ask": {"on": False, "audience": {"maxBuild": 9, "rollout": 50}}}}), [])

    def test_only_the_app_s_own_switches(self):
        said = problems({"flags": {"push.asks": False}})
        self.assertEqual(len(said), 1)
        self.assertIn("flags.push.asks", said[0])
        self.assertIn("review.ask", said[0], "it lists the ones there are")

    def test_on_is_a_bool_and_the_audience_is_read(self):
        self.assertTrue(problems({"flags": {"place.ask": {"on": 1}}}))
        self.assertTrue(problems({"flags": {"place.ask": {"on": True, "when": 1}}}))
        self.assertTrue(problems({"flags": {"place.ask": "off"}}))
        self.assertTrue(problems({"flags": {"place.ask": {"on": True, "audience": {"languages": ["xx"]}}}}))


class TunablesTest(unittest.TestCase):
    def test_numbers_in_range(self):
        self.assertEqual(problems({"tunables": {"push.askGapDays": 5, "review.streakDays": 14}}), [])
        for bad in (0, 31, 2.5, "3", True, None):
            with self.subTest(bad=bad):
                self.assertTrue(problems({"tunables": {"push.askGapDays": bad}}))

    def test_the_second_place_day_comes_after_the_first(self):
        self.assertEqual(problems({"tunables": {"place.firstAskDay": 3, "place.lastAskDay": 9}}), [])
        self.assertTrue(problems({"tunables": {"place.lastAskDay": 2}}), "not after the build's 2")
        self.assertTrue(problems({"tunables": {"place.firstAskDay": 7}}), "not before the build's 7")
        self.assertTrue(problems({"tunables": {"place.firstAskDay": 9, "place.lastAskDay": 8}}))

    def test_the_reminder_times_stay_in_their_parts_of_the_day(self):
        self.assertEqual(problems({"tunables": {"push.times": ["07:45", "13:00", "21:30"]}}), [])
        for bad in (["08:30", "12:30"], ["08:30", "12:30", "16:00"], ["12:00", "12:30", "19:00"],
                    ["8:30", "12:30", "19:00"], ["08:30", "12:30", "24:00"], "08:30"):
            with self.subTest(bad=bad):
                self.assertTrue(problems({"tunables": {"push.times": bad}}))

    def test_only_the_app_s_own_numbers(self):
        self.assertTrue(problems({"tunables": {"push.askGap": 3}}))


class ExperimentsTest(unittest.TestCase):
    def test_a_well_formed_experiment(self):
        self.assertEqual(problems({"experiments": {"push.firstAsk": {
            "variants": ["cameBack", "firstDay"], "weights": [1, 1], "audience": {"rollout": 20},
        }}}), [])
        self.assertEqual(problems({"experiments": {"push.firstAsk": {"variants": ["firstDay"]}}}), [])

    def test_what_makes_one_ill_formed(self):
        for bad in (
            {"variants": ["cameBack", "secondDay"]},
            {"variants": []},
            {"variants": ["firstDay", "firstDay"]},
            {"variants": ["cameBack", "firstDay"], "weights": [1]},
            {"variants": ["cameBack", "firstDay"], "weights": [0, 0]},
            {"variants": ["cameBack", "firstDay"], "weights": [1, -1]},
            {"variants": ["cameBack", "firstDay"], "split": [1, 1]},
            {"variants": ["cameBack"], "audience": {"rollout": 120}},
            ["cameBack", "firstDay"],
        ):
            with self.subTest(bad=bad):
                self.assertTrue(problems({"experiments": {"push.firstAsk": bad}}))
        self.assertTrue(problems({"experiments": {"paywall.copy": {"variants": ["a"]}}}))


class AudienceTest(unittest.TestCase):
    def test_every_key_holds_what_it_asks_for(self):
        good = {
            "platforms": ["ios"], "minBuild": 3, "maxBuild": 9, "languages": ["it", "en"],
            "plus": False, "minDays": 1, "maxDays": 30, "from": "2026-10-20", "until": "2026-11-01",
            "weekdays": [6, 7], "hours": [22, 3], "rollout": 12.5, "salt": "autumn",
            "all": [{"plus": True}], "any": [{"minDays": 7}, {"platforms": ["web"]}], "not": {"languages": ["ru"]},
        }
        self.assertEqual(app.check_audience(good, "a"), [])
        for key, bad in (
            ("platforms", ["iphone"]), ("minBuild", -1), ("languages", ["english"]), ("plus", "yes"),
            ("from", "20/10/2026"), ("until", "2026-02-30"), ("weekdays", [0]), ("hours", [9, 9]),
            ("hours", [9]), ("rollout", 101), ("salt", ""), ("all", []), ("not", [{}]), ("country", "IT"),
        ):
            with self.subTest(key=key, bad=bad):
                self.assertTrue(app.check_audience({key: bad}, "a"))

    def test_a_rule_nobody_is_in(self):
        self.assertTrue(app.check_audience({"minBuild": 9, "maxBuild": 3}, "a"))
        self.assertTrue(app.check_audience({"from": "2026-11-02", "until": "2026-11-01"}, "a"))

    def test_nested_rules_are_read_too(self):
        said = app.check_audience({"any": [{"plus": True}, {"stars": 5}]}, "x")
        self.assertEqual(len(said), 1)
        self.assertIn("x.any[1]", said[0])


class KnobsTest(unittest.TestCase):
    def test_the_list_is_well_formed(self):
        spec = app.knobs()
        self.assertEqual(set(spec), {"flags", "tunables", "experiments"})
        self.assertTrue(8 <= sum(len(v) for v in spec.values()) <= 15)
        for name, flag in spec["flags"].items():
            self.assertIsInstance(flag["default"], bool, name)
        for name, t in spec["tunables"].items():
            if t["type"] == "count":
                self.assertTrue(t["min"] <= t["default"] <= t["max"], name)
            else:
                self.assertEqual(t["type"], "times")
                self.assertIsNone(app._times_problem(t["default"], t), name)
            if "after" in t:
                self.assertIn(t["after"], spec["tunables"])
        for name, e in spec["experiments"].items():
            self.assertIn(e["default"], e["variants"], name)
        # The defaults, written as a document, are a document that passes.
        doc = {
            "flags": {k: v["default"] for k, v in spec["flags"].items()},
            "tunables": {k: v["default"] for k, v in spec["tunables"].items()},
            "experiments": {k: {"variants": v["variants"]} for k, v in spec["experiments"].items()},
        }
        self.assertEqual(problems(doc), [])

    def test_the_docs_list_every_knob(self):
        docs = (ROOT / "docs" / "REMOTE.md").read_text(encoding="utf-8")
        for kind, names in app.knobs().items():
            for name in names:
                with self.subTest(name=name):
                    self.assertTrue(f"`{name}`" in docs, f"docs/REMOTE.md says nothing of the {kind[:-1]} {name}")

    def test_the_sources_as_they_are_pass(self):
        parts, said = check.load_and_check()
        self.assertEqual([p for p in said if p.startswith("app:")], [])
        self.assertIn("experiments", parts["app"])


class StoreLinksTest(unittest.TestCase):
    """The app's store links (lib/store_links.dart) are the site's."""

    def test_the_app_and_the_site_send_readers_to_the_same_pages(self):
        dart = (ROOT / "lib" / "store_links.dart").read_text(encoding="utf-8")

        def const(name: str) -> str:
            m = re.search(name + r"\s*=\s*'([^']+)'", dart)
            self.assertIsNotNone(m, name)
            return m.group(1)

        chrome = (ROOT / "tool" / "site" / "chrome.py").read_text(encoding="utf-8")
        site_app_store = re.search(r"^APP_STORE = '([^']+)'", chrome, re.M).group(1)
        site_play = re.search(r"^GOOGLE_PLAY = '([^']+)'", chrome, re.M).group(1)
        self.assertEqual(const("kAppStoreUrl"), site_app_store)
        self.assertEqual(const("kGooglePlayUrl"), site_play)
        account = (ROOT / "site" / "assets" / "account.js").read_text(encoding="utf-8")
        self.assertIn(f"'{const('kAppStoreUrl')}'", account)
        self.assertIn(f"'{const('kGooglePlayUrl')}'", account)
        self.assertIn(const("kAppStoreSubscriptionsUrl"), account)
        self.assertIn(const("kGooglePlaySubscriptionsUrl"), account)


if __name__ == "__main__":
    unittest.main()
