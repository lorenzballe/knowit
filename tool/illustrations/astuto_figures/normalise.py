"""Makes an SVG from any library fit on a card.

matplotlib, schemdraw and manim all draw for a white page: a background
rectangle, grey axes, a title in whatever font the machine had, several
colours. A card is one flat colour and the app paints the figure with
`ColorFilter.mode(ink, BlendMode.srcIn)`, which turns every pixel that is
not transparent into the card's ink — so a white background arrives as a
solid ink slab over the card, and two colours arrive as one.

This is the gate every figure passes through, whoever drew it: no
background, one colour, a square viewBox, and no more precision than a
drawing on a phone can show.
"""

from __future__ import annotations

import re
import xml.etree.ElementTree as ET

SVG = "http://www.w3.org/2000/svg"
XLINK = "http://www.w3.org/1999/xlink"
ET.register_namespace("", SVG)
# The prefix has to be this one, spelled this way. A parser reading SVG as
# XML resolves `ns4:href` by its namespace and is happy; an HTML parser —
# which is what a browser uses for an inlined figure — has a fixed list of
# foreign attributes it recognises, `xlink:href` is on it and `ns4:href` is
# not, so every <use> silently draws nothing. Matplotlib's scatter markers
# are all <use>, which is how a graph arrives with its edges and no nodes.
ET.register_namespace("xlink", XLINK)

#: What a page's background looks like, whichever library drew it.
_PAGE = {"#fff", "#ffffff", "white", "#f0f0f0", "#eee", "#eeeeee", "none"}

#: Attributes that carry a colour, and the ones that carry a paint we keep.
_COLOUR_ATTRS = ("fill", "stroke", "stop-color", "flood-color")


def card_ready(svg: str, size: int = 100) -> str:
    """One colour, no ground, square. Returns an SVG string.

    A figure that has already been drawn to these rules passes through
    unchanged apart from the tidying.
    """
    root = ET.fromstring(svg)
    _drop_page(root)
    _one_colour(root)
    _scrub(root)
    _square(root, size)
    out = ET.tostring(root, encoding="unicode")
    # ElementTree writes the default namespace on every element it made;
    # one on the root is enough.
    out = out.replace(f' xmlns:ns0="{SVG}"', "").replace("ns0:", "")
    return _tidy(out)


#: Shapes in here are not drawings, they are the definition of a clip, a
#: mask or an arrowhead. A path with no fill and no stroke is dead weight
#: in the picture and load-bearing in here — remove the rect inside a
#: clipPath and the clip becomes empty, which throws the whole figure away.
_PROTECTED = {"defs", "clipPath", "mask", "marker", "pattern", "symbol"}


def _drop_page(root: ET.Element) -> None:
    """Removes the sheet of paper the figure was drawn on.

    A background is a rect or a path that covers the whole viewBox in a
    page colour. Matplotlib draws two of them, one for the figure and one
    for the axes, and both would land on the card as slabs of ink. What is
    also removed is anything that neither fills nor strokes: a box a
    library drew to hold something, which on a card is one more thing to
    parse and nothing to see.
    """

    def walk(parent: ET.Element, protected: bool) -> None:
        for child in list(parent):
            tag = _tag(child)
            inside = protected or tag in _PROTECTED
            if not inside and tag in ("rect", "path") and _is_page(child):
                parent.remove(child)
                continue
            walk(child, inside)

    walk(root, False)


def _is_page(el: ET.Element) -> bool:
    fill = _paint(el, "fill")
    stroke = _paint(el, "stroke")
    if fill in _PAGE - {"none"}:
        return True
    return fill in ("none", "") and stroke in ("none", "")


def _paint(el: ET.Element, attr: str) -> str:
    """What this element says it paints with, attribute or style."""
    style = el.get("style") or ""
    if f"{attr}:" in style:
        return style.split(f"{attr}:")[1].split(";")[0].strip().lower()
    return (el.get(attr) or "").strip().lower()


def _one_colour(root: ET.Element) -> None:
    """Everything that draws, draws in the card's ink.

    Colour carried meaning on the page it came from; on a card it cannot,
    so it is spent here rather than arriving as a surprise. What survives
    is the distinction the app can still show: a filled shape against an
    outlined one.

    `none` is not a colour and must survive as itself. A `fill: none` that
    becomes `fill: currentColor` is how matplotlib's invisible background
    patch turns into a slab of ink over the whole card — so the value is
    read and decided on rather than matched around with a lookahead, which
    a regex will happily backtrack past.
    """
    for el in root.iter():
        for attr in _COLOUR_ATTRS:
            value = (el.get(attr) or "").strip()
            if not value or value in ("none", "currentColor"):
                continue
            el.set(attr, "currentColor")
        style = el.get("style")
        if style:
            for attr in _COLOUR_ATTRS:
                style = re.sub(
                    rf"({attr}\s*:\s*)([^;]+)",
                    lambda m: m.group(1)
                    + ("none" if m.group(2).strip() == "none" else "currentColor"),
                    style,
                )
            el.set("style", style)


def _scrub(root: ET.Element) -> None:
    """Takes out what a browser forgives and a renderer does not.

    A browser is a forgiving parser and the app's is not: schemdraw writes
    `stroke-dasharray:-` on everything it draws with a solid line, which
    Chromium ignores and flutter_svg reads as a number, throwing
    `FormatException: Invalid double` — one bad property and the whole
    figure fails to draw. A figure is checked in a browser and shipped to
    a renderer, so the difference between the two is exactly where a fault
    hides.
    """
    for el in root.iter():
        value = el.get("stroke-dasharray")
        if value is not None and not any(c.isdigit() for c in value):
            del el.attrib["stroke-dasharray"]
        style = el.get("style")
        if not style:
            continue
        kept = []
        for part in style.split(";"):
            name, _, val = part.partition(":")
            if not name.strip():
                continue
            if name.strip() == "stroke-dasharray" and not any(
                c.isdigit() for c in val
            ):
                continue
            # A background belongs to the page, and there is no page.
            if name.strip() == "background-color":
                continue
            kept.append(part)
        el.set("style", ";".join(kept))


def _square(root: ET.Element, size: int) -> None:
    """A square box, so every figure sits the same way in the same slot."""
    box = root.get("viewBox")
    if box:
        try:
            x, y, w, h = (float(v) for v in box.replace(",", " ").split())
        except ValueError:
            x = y = 0.0
            w = h = float(size)
    else:
        x = y = 0.0
        w = _number(root.get("width") or "") or float(size)
        h = _number(root.get("height") or "") or float(size)
    side = max(w, h)
    root.set(
        "viewBox",
        f"{x - (side - w) / 2:g} {y - (side - h) / 2:g} {side:g} {side:g}",
    )
    for attr in ("width", "height"):
        root.attrib.pop(attr, None)
    root.set("color", "#000")


def _tidy(svg: str) -> str:
    """Trims the precision a drawing on a phone cannot show."""
    def cut(match: re.Match[str]) -> str:
        return f"{float(match.group(0)):g}"

    svg = re.sub(r"-?\d+\.\d{3,}(?![0-9eE])", cut, svg)
    # Scientific notation is a rounding error wearing a costume: a
    # coordinate of 2.97589e-15 is zero, and not every parser reads the
    # exponent.
    svg = re.sub(r"-?\d+(?:\.\d+)?[eE][-+]?\d+",
                 lambda m: f"{round(float(m.group(0)), 4):g}", svg)
    return re.sub(r">\s+<", "><", svg).strip()


def _tag(el: ET.Element) -> str:
    return el.tag.split("}")[-1]


def _number(value: str) -> float | None:
    try:
        return float(re.sub(r"[^0-9.eE+-]", "", value))
    except ValueError:
        return None
