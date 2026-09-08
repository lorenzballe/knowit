"""The one drawing surface every Astuto figure is made on.

A figure lands on a card that is already one flat colour, and the app
paints it with `ColorFilter.mode(ink, BlendMode.srcIn)` — which recolours
every pixel that is not transparent. So a figure has exactly one colour to
work with, and everything it says has to be said with line weight, fill
against outline, and space. That is a constraint worth having: it is the
same discipline as the subject marks, and it means a figure cannot fight
the card it sits on.

The primitives are drawsvg's. What is here is the house rules on top of
them — the grid, the two stroke weights, the one colour, and an output
that is `currentColor` throughout so a file opened on its own is legible
too.
"""

from __future__ import annotations

import re

import drawsvg as dw

from .normalise import card_ready

#: Figures are drawn on a square grid and scaled by the app, so every
#: coordinate below is in these units rather than in points.
SIZE = 100

#: One stroke weight, in the same units, so figures drawn months apart still
#: look like they came from the same hand. Fine is for guides and rings.
STROKE = 1.9
STROKE_FINE = 1.1

#: What a filled shape means: a thing being counted. What an outline means:
#: a thing being counted against. Nothing else may be filled.
INK = "currentColor"


class Figure:
    """A drawing under construction, in [0, SIZE] coordinates."""

    def __init__(self) -> None:
        self.d = dw.Drawing(SIZE, SIZE, origin=(0, 0))

    @classmethod
    def new(cls) -> "Figure":
        return cls()

    # ── primitives ────────────────────────────────────────────────────────

    def line(self, x1: float, y1: float, x2: float, y2: float,
             width: float = STROKE) -> "Figure":
        self.d.append(dw.Line(x1, y1, x2, y2, stroke=INK, stroke_width=width,
                              stroke_linecap="round", fill="none"))
        return self

    def circle(self, cx: float, cy: float, r: float, filled: bool = False,
               width: float = STROKE) -> "Figure":
        if filled:
            self.d.append(dw.Circle(cx, cy, r, fill=INK))
        else:
            self.d.append(dw.Circle(cx, cy, r, fill="none", stroke=INK,
                                    stroke_width=width))
        return self

    def rect(self, x: float, y: float, w: float, h: float, r: float = 0,
             filled: bool = False, width: float = STROKE) -> "Figure":
        extra = {"rx": r} if r else {}
        if filled:
            self.d.append(dw.Rectangle(x, y, w, h, fill=INK, **extra))
        else:
            self.d.append(dw.Rectangle(x, y, w, h, fill="none", stroke=INK,
                                       stroke_width=width, **extra))
        return self

    def polyline(self, points: list[tuple[float, float]],
                 width: float = STROKE, close: bool = False,
                 filled: bool = False) -> "Figure":
        if len(points) < 2:
            return self
        flat = [c for point in points for c in point]
        self.d.append(dw.Lines(
            *flat,
            close=close,
            fill=INK if filled else "none",
            stroke="none" if filled else INK,
            stroke_width=0 if filled else width,
            stroke_linecap="round",
            stroke_linejoin="round",
        ))
        return self

    def arc(self, cx: float, cy: float, r: float, share: float,
            width: float = STROKE) -> "Figure":
        """A share of a ring, starting at twelve o'clock and going round.

        Drawn as a dashed circle rather than as an arc path: an arc that
        closes on itself is a stroke with two ends, and at these weights
        the join shows.
        """
        circumference = 2 * 3.141592653589793 * r
        lit = circumference * max(0.0, min(1.0, share))
        self.d.append(dw.Circle(
            cx, cy, r, fill="none", stroke=INK, stroke_width=width,
            stroke_linecap="round",
            stroke_dasharray=f"{lit:.2f} {circumference - lit:.2f}",
            transform=f"rotate(-90 {cx:g} {cy:g})",
        ))
        return self

    # ── output ────────────────────────────────────────────────────────────

    def svg(self) -> str:
        """The finished document.

        `currentColor` throughout, so the same file reads on any card: the
        app's colour filter paints it, and anything that opens the file on
        its own inherits the surrounding text colour rather than defaulting
        to black on a black card. No width or height, so it takes the size
        of the slot it is put in.
        """
        svg = re.sub(r"<\?xml[^>]*\?>\s*", "", self.d.as_svg())
        # Through the same gate everything else goes through, so a figure
        # drawn here and a figure drawn by matplotlib cannot come out under
        # different rules.
        return card_ready(svg, size=SIZE)

    def png(self, path: str, scale: int = 3) -> None:
        """A raster of the same drawing, for anywhere SVG is not welcome."""
        self.d.set_pixel_scale(scale)
        self.d.save_png(path)
