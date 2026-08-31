"""Cuts the app icon down to every size iOS, Android and the web ask for.

    python3 tool/icons/sizes.py

The two masters in tool/icons/source/ are the artwork — this script only
resizes them, so what ships is the drawing as supplied. They are square and
full bleed, which is what iOS wants; the corners are rounded here for the
places that do not round them themselves.
"""

import pathlib
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tool" / "icons" / "source"
IOS = "ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Apple masks its own corners and App Store Connect rejects an alpha channel,
# so iOS gets the square master flattened to RGB.
IOS_SIZES = [(20, 1), (20, 2), (20, 3), (29, 1), (29, 2), (29, 3), (40, 1),
             (40, 2), (40, 3), (60, 2), (60, 3), (76, 1), (76, 2), (83.5, 2),
             (1024, 1)]

ANDROID_SIZES = [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144),
                 ("xxxhdpi", 192)]

# Matches the rounded artwork supplied alongside the masters.
CORNER = 0.20

# A maskable icon is cropped to whatever shape the launcher uses, so the
# artwork sits inside the safe circle and the ground fills the rest.
MASKABLE_INSET = 0.80


def ios_name(pt, scale):
    label = f"{pt:g}"
    return f"{IOS}/Icon-App-{label}x{label}@{scale}x.png"


# (master, output, size, shape)
TARGETS = [("light", ios_name(pt, s), round(pt * s), "square")
           for pt, s in IOS_SIZES]
TARGETS += [("light", f"android/app/src/main/res/mipmap-{d}/ic_launcher.png", px, "rounded")
            for d, px in ANDROID_SIZES]
TARGETS += [
    ("light", "web/favicon.png", 64, "rounded"),
    ("dark", "web/favicon-dark.png", 64, "rounded"),
    ("light", "web/icons/Icon-192.png", 192, "rounded"),
    ("light", "web/icons/Icon-512.png", 512, "rounded"),
    ("light", "web/icons/Icon-maskable-192.png", 192, "maskable"),
    ("light", "web/icons/Icon-maskable-512.png", 512, "maskable"),
    # Shown inside the app, so both themes ship as assets.
    ("light", "assets/brand/mark-light.png", 512, "rounded"),
    ("dark", "assets/brand/mark-dark.png", 512, "rounded"),
]


def rounded(img):
    """Clips the image to a rounded square, antialiased 4x."""
    size = img.width
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size * 4 - 1, size * 4 - 1),
        radius=int(size * 4 * CORNER),
        fill=255,
    )
    out = img.copy()
    out.putalpha(mask.resize((size, size), Image.LANCZOS))
    return out


def maskable(master, size):
    """Full-bleed ground with the artwork shrunk into the safe area."""
    ground = Image.new("RGBA", (size, size), master.getpixel((2, 2)))
    inner = round(size * MASKABLE_INSET)
    art = master.resize((inner, inner), Image.LANCZOS)
    offset = (size - inner) // 2
    ground.paste(art, (offset, offset), art)
    return ground


def main():
    masters = {
        name: Image.open(SOURCE / f"master-{name}.png").convert("RGBA")
        for name in ("light", "dark")
    }
    for name, master in masters.items():
        if master.width != master.height:
            sys.exit(f"master-{name}.png is not square: {master.size}")

    for key, out, size, shape in TARGETS:
        master = masters[key]
        if shape == "maskable":
            img = maskable(master, size)
        else:
            img = master.resize((size, size), Image.LANCZOS)
            if shape == "rounded":
                img = rounded(img)
            else:
                # Flatten onto the ground the artwork already sits on.
                flat = Image.new("RGB", img.size, master.getpixel((2, 2))[:3])
                flat.paste(img, mask=img.split()[3])
                img = flat
        path = ROOT / out
        path.parent.mkdir(parents=True, exist_ok=True)
        img.save(path)
        print(f"{size:>4}px  {shape:8} {out}")


if __name__ == "__main__":
    main()
