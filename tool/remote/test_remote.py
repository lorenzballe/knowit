"""The remote bundler and checker: one document from the sources, named by
what it holds, refused whole when a part does not pass."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import bundle  # noqa: E402
import check  # noqa: E402


class BundleTest(unittest.TestCase):
    def test_the_hash_names_the_contents(self):
        a = bundle.build({"app": {"flags": {}}, "strings": {}, "explore": None, "looks": None})
        b = bundle.build({"app": {"flags": {}}, "strings": {}, "explore": None, "looks": None})
        c = bundle.build({"app": {"flags": {"x": True}}, "strings": {}, "explore": None, "looks": None})
        self.assertEqual(a["hash"], b["hash"])
        self.assertNotEqual(a["hash"], c["hash"])
        self.assertEqual(list(a)[:2], ["schema", "hash"])
        self.assertEqual([k for k in a if k not in ("schema", "hash")], list(check.PARTS))

    def test_the_note_names_the_document(self):
        doc = bundle.build({"app": {}, "strings": {}, "explore": None, "looks": None})
        self.assertEqual(json.loads(bundle.version_note(doc)), {"schema": 1, "hash": doc["hash"]})

    def test_the_sources_as_they_are_pass_and_are_bundled(self):
        parts, problems = check.load_and_check()
        self.assertEqual(problems, [])
        self.assertEqual(bundle.main(["--check"]), 0)
        self.assertEqual(set(parts), set(check.PARTS))


if __name__ == "__main__":
    unittest.main()
