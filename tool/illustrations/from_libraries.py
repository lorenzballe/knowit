#!/usr/bin/env python3
"""Card-ready figures drawn by the libraries rather than by hand.

The five kinds in `astuto_figures` are drawn from primitives because they
are small, and a chart library asked for a hundred dots gives back a
scatter plot with axes. Everything else is somebody else's problem solved
already, and this is where those get used:

  matplotlib  every curve, distribution and fit that is really a plot
  schemdraw   circuits, and the flow diagrams that are the same shape
  networkx    graphs whose layout has to be computed rather than chosen

Each one is drawn, then put through `card_ready`, which is what makes a
library's output usable: it strips the white page, spends the colour, and
squares the box.

    python from_libraries.py examples/
"""

from __future__ import annotations

import io
import sys
from pathlib import Path

from astuto_figures.normalise import card_ready


def matplotlib_curve() -> str:
    """A plot, from the library everybody already has.

    Everything a page needs and a card does not — the frame, the ticks,
    the numbers, the background — is turned off here rather than stripped
    later: a figure that never draws them cannot have them survive.
    """
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np

    x = np.linspace(0, 6, 200)
    fig, ax = plt.subplots(figsize=(3, 3))
    ax.plot(x, np.exp(x / 2), lw=3, solid_capstyle="round")
    ax.plot(x, x**2, lw=2, ls=(0, (1, 3)), solid_capstyle="round")
    ax.set_axis_off()
    ax.margins(0.06)
    fig.tight_layout(pad=0)

    buf = io.StringIO()
    fig.savefig(buf, format="svg", transparent=True)
    plt.close(fig)
    return card_ready(buf.getvalue())


def schemdraw_circuit() -> str:
    """A circuit, for the physics and technology cards.

    schemdraw is pure Python and writes SVG, so it needs nothing installed
    beside it — which on a server is most of the argument.
    """
    import schemdraw
    import schemdraw.elements as elm

    # Its own SVG backend rather than the matplotlib one, which is the
    # whole reason to reach for schemdraw: nothing is installed behind it.
    schemdraw.use("svg")
    schemdraw.config(bgcolor="none")
    with schemdraw.Drawing(show=False, file=None) as d:
        d.config(unit=2.4, lw=2.4)
        d += elm.SourceV().up().label("V")
        d += elm.Resistor().right().label("R")
        d += elm.Capacitor().down().label("C")
        d += elm.Line().left()
        svg = d.get_imagedata("svg").decode("utf-8")
    return card_ready(svg)


def networkx_graph() -> str:
    """A graph whose shape has to be worked out rather than placed.

    The layout is the library's; the drawing is matplotlib's; the colour
    and the page are taken away afterwards.
    """
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import networkx as nx

    graph = nx.random_regular_graph(3, 12, seed=7)
    fig, ax = plt.subplots(figsize=(3, 3))
    nx.draw_networkx(
        graph,
        pos=nx.spring_layout(graph, seed=7),
        ax=ax,
        with_labels=False,
        node_size=90,
        width=1.8,
    )
    ax.set_axis_off()
    fig.tight_layout(pad=0)

    buf = io.StringIO()
    fig.savefig(buf, format="svg", transparent=True)
    plt.close(fig)
    return card_ready(buf.getvalue())


DRAWN_BY_LIBRARY = {
    "library-matplotlib-growth": matplotlib_curve,
    "library-schemdraw-circuit": schemdraw_circuit,
    "library-networkx-graph": networkx_graph,
}


def main() -> None:
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "examples")
    out.mkdir(parents=True, exist_ok=True)
    for name, draw in DRAWN_BY_LIBRARY.items():
        path = out / f"{name}.svg"
        path.write_text(draw(), encoding="utf-8")
        print(f"{path}  {path.stat().st_size:,} bytes")


if __name__ == "__main__":
    main()
