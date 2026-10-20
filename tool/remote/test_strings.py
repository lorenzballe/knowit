"""Words from the server: the checker holds them to what the app's wrapper
can say exactly as the build would, and the generator keeps the wrapper in
step with the arb files and gen-l10n's class."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

import gen_strings  # noqa: E402
from parts import strings  # noqa: E402


def problems(language: str, words: dict) -> list[str]:
    return strings.check({language: words})


def _has_dart() -> bool:
    try:
        gen_strings.find_dart()
        return True
    except gen_strings.Stale:
        return False


class ReaderTest(unittest.TestCase):
    def test_what_it_reads(self):
        self.assertEqual(strings.read("Plain words").names, set())
        self.assertEqual(strings.read("Day {day} of {days}").names, {"day", "days"})
        m = strings.read("{n, plural, =0{None} =1{One card} few{{n} karty} other{{n} cards}} · {minutes} min")
        self.assertEqual(m.names, {"n", "minutes"})
        self.assertEqual(m.plurals, {"n"})
        m = strings.read("{store, select, apple{the App Store} google{Google Play} other{{store}}}")
        self.assertEqual(m.selects, {"store"})
        # Space between the parts of an expression is passed over, as
        # gen-l10n passes it over; inside a case it is the words' own.
        self.assertEqual(strings.read("{ n ,plural, =1 { one } other {{ n } many}}").names, {"n"})
        # Nested as deep as it goes.
        m = strings.read("{plan, select, year{{n, plural, =1{a year} other{{n} years}}} other{a month}}")
        self.assertEqual((m.selects, m.plurals), ({"plan"}, {"n"}))

    def test_what_it_refuses(self):
        for bad in (
            "Unclosed {name",
            "A } alone",
            "{n, plural, =1{one}}",
            "{n, plural, =3{three} other{many}}",
            "{n, plural, =1{a} one{b} other{c}}",
            "{s, select, a{x} a{y} other{z}}",
            "{s, select, a{x}}",
            "{when, date, ::yMd}",
            "{n, number}",
            "{n, plural, other{unclosed}",
            "{}",
        ):
            with self.subTest(bad=bad):
                with self.assertRaises(strings.Unreadable):
                    strings.read(bad)


class CheckerTest(unittest.TestCase):
    def test_every_word_the_build_ships_would_pass_as_the_server_s(self):
        # The strictest test of the checker's grammar: everything the app
        # already says, in all thirteen languages, is something the server
        # could say in its place.
        template = gen_strings.read_template()
        for language in gen_strings.languages():
            arb = json.loads((ROOT / "lib" / "l10n" / f"app_{language}.arb").read_text(encoding="utf-8"))
            words = {k: v for k, v in arb.items() if not k.startswith("@") and k in template}
            with self.subTest(language=language):
                self.assertGreater(len(words), 700)
                self.assertEqual(problems(language, words), [])

    def test_one_file_per_language_of_the_app(self):
        said = strings.check({"klingon": {"tabToday": "Heute"}, "it": {"tabToday": "Oggi"}})
        self.assertEqual(len(said), 1)
        self.assertIn("remote/strings/klingon.json", said[0])
        self.assertTrue(strings.check({"it": ["Oggi"]}))
        self.assertEqual(strings.check({}), [])
        self.assertEqual(strings.check(None), [])

    def test_keys_of_the_template_only(self):
        said = problems("it", {"tabTodays": "Oggi"})
        self.assertEqual(len(said), 1)
        self.assertIn("tabTodays", said[0])
        self.assertIn("app_en.arb", said[0])

    def test_no_empty_words(self):
        self.assertTrue(problems("it", {"tabToday": ""}))
        self.assertTrue(problems("it", {"tabToday": "   "}))
        self.assertTrue(problems("it", {"tabToday": None}))

    def test_the_placeholders_must_be_the_build_s(self):
        self.assertEqual(problems("it", {"couldNotSignInCarryOn": "Niente da fare con {label}."}), [])
        said = problems("it", {"couldNotSignInCarryOn": "Niente da fare."})
        self.assertTrue(any("leaves out {label}" in p for p in said), said)
        said = problems("it", {"couldNotSignInCarryOn": "Niente con {label} e {who}."})
        self.assertTrue(any("{who}" in p for p in said), said)
        said = problems("it", {"tabToday": "Oggi, {name}"})
        self.assertTrue(any("no placeholders" in p for p in said), said)

    def test_plurals_count_numbers_and_selects_choose_by_strings(self):
        self.assertEqual(problems("ru", {"streakDays": "{n, plural, one{{n} день} few{{n} дня} many{{n} дней} other{{n} дня}}"}), [])
        said = problems("it", {"couldNotSignInCarryOn": "{label, plural, =1{uno} other{{label}}}"})
        self.assertTrue(any("not a number" in p for p in said), said)
        said = problems("it", {"streakDays": "{n, select, 1{un giorno} other{{n} giorni}}"})
        self.assertTrue(any("not a String" in p for p in said), said)

    def test_a_date_argument_is_refused_with_the_way_out(self):
        said = problems("en", {"couldNotSignInCarryOn": "{label, date, ::yMd}"})
        self.assertEqual(len(said), 1)
        self.assertIn("write {label}", said[0])

    def test_the_sources_as_they_are_pass(self):
        sources = ROOT / "remote" / "strings"
        for path in sorted(sources.glob("*.json")):
            with self.subTest(path=path.name):
                self.assertEqual(strings.check({path.stem: json.loads(path.read_text(encoding="utf-8"))}), [])


class GeneratorTest(unittest.TestCase):
    def test_it_reads_gen_l10n_s_class(self):
        members = gen_strings.read_members()
        template = gen_strings.read_template()
        self.assertEqual(list(members), gen_strings.template_keys(template))
        self.assertTrue(members["appName"].getter)
        trial = members["trialCharge"]
        self.assertEqual([(p.type, p.name) for p in trial.params], [("int", "day"), ("String", "price"), ("String", "plan")])
        gen_strings.check_agreement(template, members)

    def test_it_says_when_gen_l10n_was_not_run(self):
        template = gen_strings.read_template()
        members = gen_strings.read_members()
        members.pop("appName")
        with self.assertRaises(gen_strings.Stale) as said:
            gen_strings.check_agreement(template, members)
        self.assertIn("flutter gen-l10n", str(said.exception))
        template = dict(template, brandNewKey="New", **{"@brandNewKey": {}})
        with self.assertRaises(gen_strings.Stale):
            gen_strings.check_agreement(template, gen_strings.read_members())

    def test_placeholders_are_formatted_as_gen_l10n_formats_them(self):
        p = gen_strings.Param
        self.assertIsNone(gen_strings.shown_expression("k", p("int", "n"), {}))
        self.assertIsNone(gen_strings.shown_expression("k", p("String", "s"), {"format": "x"}))
        self.assertEqual(
            gen_strings.shown_expression("k", p("int", "n"), {"format": "decimalPattern"}),
            "intl.NumberFormat.decimalPattern(localeName).format(n)",
        )
        self.assertEqual(
            gen_strings.shown_expression(
                "k", p("double", "price"),
                {"format": "compactCurrency", "optionalParameters": {"decimalDigits": 2, "symbol": "€"}},
            ),
            "intl.NumberFormat.compactCurrency(locale: localeName, decimalDigits: 2, symbol: '€').format(price)",
        )
        self.assertEqual(
            gen_strings.shown_expression("k", p("DateTime", "d"), {"format": "yMMMd+jm"}),
            "intl.DateFormat.yMMMd(localeName).add_jm().format(d)",
        )
        self.assertEqual(
            gen_strings.shown_expression("k", p("DateTime", "d"), {"format": "d 'de' MMM", "isCustomDateFormat": "true"}),
            "intl.DateFormat('d \\'de\\' MMM', localeName).format(d)",
        )
        with self.assertRaises(gen_strings.Stale):
            gen_strings.shown_expression("k", p("int", "n"), {"format": "roman"})
        with self.assertRaises(gen_strings.Stale):
            gen_strings.shown_expression("k", p("DateTime", "d"), {})

    def test_the_wrapper_answers_every_string(self):
        template = gen_strings.read_template()
        members = gen_strings.read_members()
        text = gen_strings.render(template, members)
        self.assertIn("class RemoteLocalizations extends AppLocalizations", text)
        for name, member in members.items():
            self.assertIn(f"_base.{name}", text, name)
        self.assertIn("intl.NumberFormat.decimalPattern(localeName).format(n)", text)

    @unittest.skipUnless(_has_dart(), "no dart to format the wrapper with")
    def test_the_wrapper_is_current(self):
        self.assertEqual(gen_strings.main(["--check"]), 0)


if __name__ == "__main__":
    unittest.main()
