"""The picture a card's link shows in a chat, one for each subject.

A card sent from the app is a line and a link (lib/widgets/share_sheet.dart):
the link opens the card on the site (tool/cards/challenge_pages.py), and a
chat draws its preview from the page's `og:image`. A card with a drawing
shows the drawing; a card in words shows this — its subject's colour, its
subject, and the question it is: can you get it? The card's own question is
the preview's title, under the picture.

Written once and kept in web/cards/og/, where the site serves it; run again
when a subject or its colour changes.

    python3 tool/cards/og_images.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

from challenge_pages import COLOURS, ink_of, subject_name  # noqa: E402

OUT = ROOT / "web" / "cards" / "og"
FRAUNCES = str(ROOT / "assets" / "fonts" / "Fraunces.ttf")
FIGTREE = str(ROOT / "assets" / "fonts" / "Figtree.ttf")
W, H = 1200, 630


def font(path: str, size: int, weight: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def rgb(hex_colour: str) -> tuple[int, int, int]:
    h = hex_colour.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def picture(topic: str) -> Image.Image:
    ground = rgb(COLOURS[topic])
    ink = rgb(ink_of(COLOURS[topic]))
    im = Image.new("RGBA", (W, H), ground + (255,))
    # The words drawn on a layer of their own, so the quiet ones can be
    # quiet: text drawn straight onto a picture keeps no alpha.
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # A question mark the height of the picture, at the right: what the
    # card is, read at a glance in a chat.
    d.text((W - 60, H // 2 + 20), "?", font=font(FRAUNCES, 640, 700), fill=ink + (255,), anchor="rm")
    d.text((76, 92), subject_name(topic).upper(), font=font(FIGTREE, 30, 750), fill=ink + (190,))
    title = font(FRAUNCES, 104, 640)
    d.text((70, 150), "Can you", font=title, fill=ink + (255,))
    d.text((70, 262), "get it?", font=title, fill=ink + (255,))
    d.text((76, H - 112), "Astute", font=font(FRAUNCES, 46, 620), fill=ink + (240,))
    d.text((78, H - 58), "Tap to answer · astutetheapp.com", font=font(FIGTREE, 26, 600), fill=ink + (175,))
    return Image.alpha_composite(im, layer).convert("RGB")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for topic in COLOURS:
        picture(topic).save(OUT / f"{topic}.png", optimize=True)
    print(f"{len(COLOURS)} pictures written to {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
