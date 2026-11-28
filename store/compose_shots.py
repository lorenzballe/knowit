"""Sets the app's screens for Google Play: each in an Android phone, under
its caption, on the night paper, as a 1080 by 1920 picture.

    SHOTS=/some/folder LANG_SHOT=it flutter test --no-pub tool/store_shots.dart --update-goldens
    python3 store/compose_shots.py /some/folder it

The first line photographs the five screens (tool/store_shots.dart says
which); this one writes store/play/<language>/01-today.png and the rest,
the order the listing shows them in. Play takes 1080 by 1920, 9:16, as a
24-bit PNG with no transparency, two to eight of them.

The captions are written by hand in each language, below: two lines that
say what the screen is for, broken where they are read, and a quieter one
under them. They never say
anything the screen does not show, never a price, never a call to press
anything, which the store's rules forbid on screenshots.

The phone is drawn here, not taken from a picture: a plain Android phone,
its corners, its bezel and the buttons on its right side, the camera's
hole where the screen's status bar left room for it.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONTS = ROOT / "assets" / "fonts"
OUT = Path(__file__).resolve().parent / "play"

W, H = 1080, 1920
NIGHT = (13, 13, 15)
CREAM = (242, 241, 236)
QUIET = (168, 165, 157)
BEZEL = (24, 24, 27)
EDGE = (58, 58, 63)

# The screens as tool/store_shots.dart names them, and each one's caption.
SHOTS = [
    ("play-1-today", "01-today"),
    ("play-2-drawn", "02-drawn"),
    ("play-3-answer", "03-answer"),
    ("play-4-journey", "04-journey"),
    ("play-5-explore", "05-explore"),
]

CAPTIONS = {
    "en": {
        "01-today": ("Five cards\nevery morning.", "Real questions, from the subjects you choose."),
        "02-drawn": ("Cards you play,\nnot just read.", "Tap, drag, and watch the answer happen."),
        "03-answer": ("Say how sure you are.\nThen see why.", "The answer, the trap and the source."),
        "04-journey": ("Watch yourself\nget sharper.", "Your journey, week by week, with Astute+."),
        "05-explore": ("After your five,\nExplore.", "Today’s challenge for everyone, and the line of the day."),
    },
    "it": {
        "01-today": ("Cinque carte\nogni mattina.", "Domande vere, dalle materie che scegli tu."),
        "02-drawn": ("Carte da giocare,\nnon solo da leggere.", "Tocchi, trascini, e la risposta prende forma."),
        "03-answer": ("Di’ quanto sei sicuro.\nPoi scopri perché.", "La risposta, la trappola e la fonte."),
        "04-journey": ("Guarda quanto\nmigliori.", "Il tuo viaggio, settimana per settimana, con Astute+."),
        "05-explore": ("Dopo le tue cinque,\nc’è Esplora.", "La sfida di oggi, uguale per tutti, e la frase del giorno."),
    },
}

# The phone the camera holds (tool/store_shots.dart): its width in points,
# and where the camera's hole is in its status bar.
PHONE_POINTS = 402
HOLE = (201, 16)

# Drawn at four times the size and brought down, so every curve is smooth.
SS = 4


def fraunces(size: int, weight: int = 560) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONTS / "Fraunces.ttf"), size)
    # Optical size, weight, softness, wonky: the display cut the app's
    # titles use, upright and plain.
    font.set_variation_by_axes([min(144, size), weight, 0, 0])
    return font


def figtree(size: int, weight: int = 500) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONTS / "Figtree.ttf"), size)
    font.set_variation_by_axes([weight])
    return font


def phone(screen: Image.Image, width: int) -> Image.Image:
    """[screen] in a plain Android phone [width] pixels wide, its bezel,
    corners and right-side buttons, on the night paper."""
    bezel = round(width * 0.021)
    inner_w = width - 2 * bezel
    scale = inner_w / screen.width
    inner_h = round(screen.height * scale)
    height = inner_h + 2 * bezel
    pad = round(width * 0.012)  # room for the buttons on the right edge
    big = Image.new("RGB", ((width + 2 * pad) * SS, (height + 2 * pad) * SS), NIGHT)
    d = ImageDraw.Draw(big)
    radius = round(width * 0.085)
    x0, y0 = pad * SS, pad * SS
    # The buttons first, so the body covers their inner half: the power
    # key high on the right, the volume rocker under it.
    for top, length in ((0.19, 0.075), (0.30, 0.13)):
        by = y0 + round(height * top) * SS
        d.rounded_rectangle(
            [x0 + (width - 2) * SS, by, x0 + (width + pad - 2) * SS, by + round(height * length) * SS],
            radius=3 * SS,
            fill=EDGE,
        )
    d.rounded_rectangle(
        [x0, y0, x0 + width * SS - 1, y0 + height * SS - 1],
        radius=radius * SS,
        fill=BEZEL,
        outline=EDGE,
        width=2 * SS,
    )
    big = big.resize((width + 2 * pad, height + 2 * pad), Image.LANCZOS)
    # The screen, with corners a little tighter than the body's.
    shown = screen.convert("RGB").resize((inner_w, inner_h), Image.LANCZOS)
    mask = Image.new("L", (inner_w * SS, inner_h * SS), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, inner_w * SS - 1, inner_h * SS - 1],
        radius=(radius - bezel) * SS,
        fill=255,
    )
    mask = mask.resize((inner_w, inner_h), Image.LANCZOS)
    big.paste(shown, (pad + bezel, pad + bezel), mask)
    # The camera's hole: dark glass with a faint ring round the lens.
    k = inner_w / PHONE_POINTS
    cx, cy = pad + bezel + HOLE[0] * k, pad + bezel + HOLE[1] * k
    r = 6.5 * k
    lens = Image.new("RGBA", (round(4 * r) * SS, round(4 * r) * SS), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lens)
    c = 2 * r * SS
    ld.ellipse([c - r * SS, c - r * SS, c + r * SS, c + r * SS], fill=(4, 4, 5, 255), outline=(44, 44, 49, 255), width=round(1.2 * k * SS))
    ld.ellipse([c - 0.38 * r * SS, c - 0.38 * r * SS, c + 0.38 * r * SS, c + 0.38 * r * SS], fill=(16, 18, 26, 255))
    lens = lens.resize((round(4 * r), round(4 * r)), Image.LANCZOS)
    big.paste(lens, (round(cx - 2 * r), round(cy - 2 * r)), lens)
    return big


def compose(screen: Image.Image, title: str, under: str) -> Image.Image:
    canvas = Image.new("RGB", (W, H), NIGHT)
    d = ImageDraw.Draw(canvas)
    margin = 72
    head = fraunces(80, 560)
    sub = figtree(36, 500)
    # Two lines on every picture, so the set reads as one when swiped.
    lines = title.split("\n")
    assert len(lines) == 2, title
    top, lead = 100, 92
    for i, line in enumerate(lines):
        assert head.getlength(line) <= W - 2 * margin, line
        d.text((W / 2, top + i * lead), line, font=head, fill=CREAM, anchor="ma")
    assert sub.getlength(under) <= W - 2 * margin, under
    d.text((W / 2, top + 2 * lead + 26), under, font=sub, fill=QUIET, anchor="ma")
    # The phone takes the rest, whole, a little clear of the foot.
    room_top = 392
    foot = 40
    width = 760
    ph = phone(screen, width)
    while ph.height > H - room_top - foot:
        width -= 2
        ph = phone(screen, width)
    canvas.paste(ph, ((W - ph.width) // 2, room_top))
    return canvas


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[1] not in CAPTIONS:
        print(__doc__, file=sys.stderr)
        return 2
    shots, lang = Path(argv[0]), argv[1]
    out = OUT / lang
    out.mkdir(parents=True, exist_ok=True)
    made = []
    for shot, name in SHOTS:
        src = shots / f"{shot}.png"
        if not src.exists():
            print(f"no {src.name} in {shots}", file=sys.stderr)
            continue
        title, under = CAPTIONS[lang][name]
        picture = compose(Image.open(src), title, under)
        assert picture.size == (W, H) and picture.mode == "RGB"
        path = out / f"{name}.png"
        picture.save(path, "PNG", optimize=True)
        made.append(f"{path.relative_to(ROOT)} ({path.stat().st_size // 1024} kB)")
    print("\n".join(made) or f"no screens in {shots}")
    return 0 if len(made) == len(SHOTS) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
