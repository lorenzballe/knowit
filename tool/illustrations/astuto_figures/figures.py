"""The kinds of figure a card can ask for.

Each one takes numbers and returns an SVG string. They are deliberately
few: a card is read in ten seconds on a phone, and a figure that needs a
legend has already lost. What is here is what the pool actually needs —
counts against a background rate, one set inside another, a curve over
time, and a share of a whole.

Adding a kind means adding a function here and a name to `KINDS`; the CLI
and the model reach them by name.
"""

from __future__ import annotations

import math

from .canvas import SIZE, STROKE, STROKE_FINE, Figure


def frequency_grid(
    total: int = 100,
    marked: int = 4,
    flagged: int = 0,
    columns: int = 10,
) -> str:
    """Natural frequencies: a crowd, and who in it the number is about.

    The one figure this app most needs. "1 in 500, and the test flags 5%"
    is a sentence almost nobody can hold; a hundred dots of which four are
    filled and a ring around the ones a test would point at is the same
    fact, seen at a glance. Gigerenzer's work on natural frequencies is
    the whole argument for drawing it this way rather than as percentages.

    [marked] of [total] are the thing itself, drawn filled. [flagged] is
    how many the test points at, drawn ringed — the marked ones first, so
    the overlap reads correctly.
    """
    rows = math.ceil(total / columns)
    step = SIZE / (max(columns, rows) + 1)
    r = step * 0.26
    ring = step * 0.44
    left = (SIZE - (columns - 1) * step) / 2
    top = (SIZE - (rows - 1) * step) / 2

    # The ill are kept together, because the whole point is that you can
    # count them. The test's flags are spread through the crowd, because
    # that is where false positives actually fall — bunched in the corner
    # with the ill they read as one group, which is the opposite of the
    # thing being shown. Spread by a stride rather than at random, so the
    # same numbers always draw the same picture.
    flags = set(range(min(marked, flagged)))
    rest = [i for i in range(total) if i >= marked]
    left_to_place = max(0, flagged - len(flags))
    if left_to_place and rest:
        stride = len(rest) / left_to_place
        flags.update(rest[min(len(rest) - 1, int(k * stride))]
                     for k in range(left_to_place))

    fig = Figure.new()
    for i in range(total):
        cx = left + (i % columns) * step
        cy = top + (i // columns) * step
        fig.circle(cx, cy, r, filled=i < marked)
        if i in flags:
            fig.circle(cx, cy, ring, width=STROKE_FINE)
    return fig.svg()


def nested_sets(
    outer: str = "",
    inner: str = "",
    inner_share: float = 0.42,
) -> str:
    """One set drawn inside another, for every conjunction card.

    "Owns a car" and "owns a car and has solar panels" is not an argument
    once the second circle is visibly inside the first. The labels are not
    drawn: type on a figure would be set in whatever face the renderer had,
    and the card already carries the words.
    """
    fig = Figure.new()
    big = SIZE * 0.40
    small = big * math.sqrt(max(0.02, min(0.9, inner_share)))
    cx, cy = SIZE / 2, SIZE / 2
    fig.circle(cx, cy, big)
    # Sitting low and left inside it, so the eye reads containment rather
    # than two rings drawn on one centre.
    fig.circle(cx - (big - small) * 0.35, cy + (big - small) * 0.35, small,
               filled=True)
    return fig.svg()


def curve(
    points: list[float] | None = None,
    baseline: bool = True,
    fill_under: bool = False,
) -> str:
    """A shape over time — growth, decay, a gap closing.

    Values are plotted in the order given and scaled to the box, so the
    caller passes a shape rather than pixel coordinates.
    """
    values = points or [1, 2, 4, 8, 16, 32, 64]
    if len(values) < 2:
        values = [0, 1]
    lo, hi = min(values), max(values)
    span = (hi - lo) or 1
    pad = SIZE * 0.14
    width = SIZE - pad * 2
    height = SIZE - pad * 2

    plotted = [
        (pad + width * i / (len(values) - 1),
         SIZE - pad - height * (v - lo) / span)
        for i, v in enumerate(values)
    ]

    fig = Figure.new()
    if baseline:
        fig.line(pad, SIZE - pad, SIZE - pad, SIZE - pad, width=STROKE_FINE)
        fig.line(pad, pad, pad, SIZE - pad, width=STROKE_FINE)
    if fill_under:
        under = plotted + [(plotted[-1][0], SIZE - pad), (pad, SIZE - pad)]
        fig.polyline(under, close=True, filled=True)
    fig.polyline(plotted)
    return fig.svg()


def rings(values: list[float] | None = None) -> str:
    """Shares of a whole, as rings rather than as a pie.

    A pie chart of two numbers is a circle cut in half and a legend; a ring
    with one arc filled is the same number and no legend. More than one
    value stacks them, outermost first — what was claimed against what
    actually happened, which is the only chart this app really owes anyone.
    """
    shares = values if values is not None else [0.8]
    fig = Figure.new()
    outer = SIZE * 0.38
    for k, value in enumerate(shares):
        r = outer - k * (outer * 0.30)
        cx = cy = SIZE / 2
        # The whole, faint, so a short arc still reads as a share of
        # something rather than as a stray mark.
        fig.circle(cx, cy, r, width=STROKE_FINE)
        fig.arc(cx, cy, r, value, width=STROKE * 1.5)
    return fig.svg()


def tree(branches: list[int] | None = None) -> str:
    """A branching count — a screening tree, a run of coin flips.

    [branches] is how many nodes each level holds; every node splits into
    the next level evenly.
    """
    levels = branches or [1, 2, 4]
    fig = Figure.new()
    pad = SIZE * 0.16
    height = SIZE - pad * 2
    gap = height / (len(levels) - 1) if len(levels) > 1 else height
    r = max(2.0, min(4.5, SIZE / (max(levels) * 6)))

    def row(n: int) -> list[float]:
        if n == 1:
            return [SIZE / 2]
        span = SIZE - pad * 2
        return [pad + span * i / (n - 1) for i in range(n)]

    for level, count in enumerate(levels):
        y = pad + gap * level
        xs = row(count)
        if level:
            parents = row(levels[level - 1])
            for i, x in enumerate(xs):
                px = parents[i * len(parents) // count]
                fig.line(px, pad + gap * (level - 1) + r, x, y - r,
                         width=STROKE_FINE)
        for x in xs:
            fig.circle(x, y, r, filled=level == len(levels) - 1)
    return fig.svg()


KINDS = {
    "frequency_grid": frequency_grid,
    "nested_sets": nested_sets,
    "curve": curve,
    "rings": rings,
    "tree": tree,
}
