#!/usr/bin/env python3
"""Renders one figure to an SVG, from a spec the card generator can write.

    echo '{"kind": "frequency_grid", "total": 100, "marked": 4, "flagged": 20}' \
      | python render.py > out.svg

    python render.py --examples examples/

The spec is a flat JSON object: `kind` names the figure and everything else
is passed to it. Unknown keys are refused rather than ignored — a spec with
a typo in it should fail here, where a person is looking, rather than
silently render the default.
"""

from __future__ import annotations

import argparse
import inspect
import json
import sys
from pathlib import Path

from astuto_figures import KINDS


def render(spec: dict) -> str:
    kind = spec.get("kind")
    if kind not in KINDS:
        raise SystemExit(
            f"unknown kind {kind!r}; the ones there are: "
            f"{', '.join(sorted(KINDS))}"
        )
    figure = KINDS[kind]
    allowed = set(inspect.signature(figure).parameters)
    given = {k: v for k, v in spec.items() if k != "kind"}
    unknown = set(given) - allowed
    if unknown:
        raise SystemExit(
            f"{kind} takes {sorted(allowed)}; it was given {sorted(unknown)}"
        )
    return figure(**given)


#: One per figure kind, drawn from cards that are actually in the pool, so
#: the examples are a test of the real thing rather than of round numbers.
EXAMPLES = {
    # thinking-1: 2,000 pupils, 1 in 500 have it, the screen flags 5% of the
    # rest. Shown as 100 people: 1 ill, about 5 flagged anyway.
    "base-rate-screening": {
        "kind": "frequency_grid", "total": 100, "marked": 1, "flagged": 6,
    },
    # thinking-2: everyone with a car and panels also has a car.
    "conjunction-car": {
        "kind": "nested_sets", "inner_share": 0.3,
    },
    # Doubling, for the exponential-growth cards.
    "doubling": {
        "kind": "curve", "points": [1, 2, 4, 8, 16, 32, 64], "fill_under": True,
    },
    # A calibration gap: what was claimed against what happened.
    "claimed-against-actual": {
        "kind": "rings", "values": [0.8, 0.55],
    },
    # Two flips, four outcomes.
    "coin-tree": {
        "kind": "tree", "branches": [1, 2, 4],
    },
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--examples", metavar="DIR",
        help="write one SVG per example into DIR instead of reading a spec",
    )
    args = parser.parse_args()

    if args.examples:
        out = Path(args.examples)
        out.mkdir(parents=True, exist_ok=True)
        for name, spec in EXAMPLES.items():
            (out / f"{name}.svg").write_text(render(spec), encoding="utf-8")
            print(f"{out / f'{name}.svg'}")
        return

    spec = json.load(sys.stdin)
    sys.stdout.write(render(spec))


if __name__ == "__main__":
    main()
