"""Splits the app icon into its layers, for the icons that are drawn in layers.

    python3 tool/icons/glass.py [--preview DIR]

Needs numpy as well as Pillow. Writes:

- ios/Runner/AppIcon.icon: the Icon Composer file iOS 26 draws as Liquid
  Glass. The ground is a fill (cream, or near-black in dark mode), and the mark
  stands on it in two groups: the A in front and the two cards behind, each
  layer its own image, so the system can give them depth, light and shadow.
  Older iOS gets icons Xcode makes from the same file.
- Android's adaptive icon: the mark as a foreground over the cream ground,
  and a one-colour monochrome layer that Android 13 and later tint with the
  phone's theme. The cards sit at lower strengths than the A, so they still
  read as cards in a single colour.

Nothing is redrawn. The layers come out of the two supplied masters, which
differ only in the A and the ground (dark on cream, cream on dark): where the
A sits on the ground the two masters add up to the same colour everywhere,
and where it sits on a card their difference is the A's coverage alone. That
gives the A exactly, and whatever shows round it is a mix of the ground and
the two card colours. Each card runs on a few pixels under whatever covers
it, so no seam of ground shows where the layers meet.
"""

import argparse
import json
import pathlib

import numpy as np
from PIL import Image, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tool" / "icons" / "source"
ICON = ROOT / "ios" / "Runner" / "AppIcon.icon"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

INK = np.array([19, 19, 22.0])       # the A on the light icon; the dark ground
CREAM = np.array([245, 243, 238.0])  # the light ground; the A on the dark icon
PINK = np.array([255, 46, 156.0])
BLUE = np.array([43, 75, 255.0])

# Android draws the foreground on a 108dp square and masks it to as little as
# a 66dp circle, so the mark has to fit well inside that circle.
ANDROID_DENSITIES = [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)]
SAFE_RADIUS = 0.30  # of the 108dp side; the guaranteed circle is 0.3055

MONO_PINK = 0.6
MONO_BLUE = 0.35


def load(name):
    return np.asarray(Image.open(SOURCE / f"master-{name}.png").convert("RGB"), dtype=np.float64)


def dilate(mask, px):
    img = Image.fromarray((mask * 255).astype(np.uint8))
    return np.asarray(img.filter(ImageFilter.MaxFilter(2 * px + 1)), dtype=np.float64) / 255


def layers():
    light, dark = load("light"), load("dark")
    ratio = (light - dark) / (INK - CREAM)
    over_ground = np.abs(light + dark - (INK + CREAM)).sum(-1) < 24
    a = np.clip(np.where(over_ground, (ratio.mean(-1) + 1) / 2, ratio.mean(-1)), 0, 1)

    with np.errstate(divide="ignore", invalid="ignore"):
        behind = (light - a[..., None] * INK) / (1 - a[..., None])
    behind[a > 0.97] = CREAM
    basis = np.stack([PINK - CREAM, BLUE - CREAM], axis=1)
    w = np.linalg.pinv(basis) @ (behind - CREAM).reshape(-1, 3).T
    pink = np.clip(w[0].reshape(a.shape), 0, 1)
    blue = np.clip(w[1].reshape(a.shape), 0, 1)

    # Keep only what belongs to each card's own shape: faint fringes along the
    # A's edges are rounding, not card.
    pink = np.where(dilate(pink > 0.5, 4) > 0, pink, 0)
    blue = np.where(dilate(blue > 0.5, 4) > 0, blue, 0)
    # Run each card on under what covers it, so the layers meet without a seam.
    pink = np.maximum(pink, dilate(pink > 0.5, 10) * (a > 0.02))
    blue = np.maximum(blue, dilate(blue > 0.5, 12) * ((a > 0.02) | (pink > 0.02)))
    return a, pink, blue


def rgba(colour, alpha):
    out = np.zeros(alpha.shape + (4,), dtype=np.uint8)
    out[..., :3] = colour.round().astype(np.uint8)
    out[..., 3] = (alpha * 255).round().astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def over(top_rgb, top_a, base_rgb):
    return top_rgb * top_a[..., None] + base_rgb * (1 - top_a[..., None])


def flat(ground, a, pink, blue, letter):
    out = np.broadcast_to(ground, a.shape + (3,)).astype(np.float64)
    out = over(BLUE, blue, out)
    out = over(PINK, pink, out)
    return over(letter, a, out)


def colour(c):
    r, g, b = (c / 255).tolist()
    return f"srgb:{r:.5f},{g:.5f},{b:.5f},1.00000"


def write_icon(a, pink, blue):
    assets = ICON / "Assets"
    assets.mkdir(parents=True, exist_ok=True)
    rgba(BLUE, blue).save(assets / "1-card-blue.png", optimize=True)
    rgba(PINK, pink).save(assets / "2-card-pink.png", optimize=True)
    rgba(INK, a).save(assets / "3-letter-light.png", optimize=True)
    rgba(CREAM, a).save(assets / "3-letter-dark.png", optimize=True)

    def group(name, layer_list, shadow):
        return {
            "layers": layer_list,
            "lighting": "individual",
            "name": name,
            "shadow": {"kind": shadow, "opacity": 0.5},
            "specular": True,
            "translucency": {"enabled": False, "value": 0.5},
        }

    doc = {
        "fill-specializations": [
            {"value": {"solid": colour(CREAM)}},
            {"appearance": "dark", "value": {"solid": colour(INK)}},
        ],
        # Front to back: the first group is drawn on top.
        "groups": [
            group("Letter", [{
                "glass": True,
                "image-name-specializations": [
                    {"value": "3-letter-light.png"},
                    {"appearance": "dark", "value": "3-letter-dark.png"},
                ],
                "name": "3-letter",
            }], "neutral"),
            group("Cards", [
                {"glass": True, "image-name": "2-card-pink.png", "name": "2-card-pink"},
                {"glass": True, "image-name": "1-card-blue.png", "name": "1-card-blue"},
            ], "layer-color"),
        ],
        "supported-platforms": {"squares": "shared"},
    }
    (ICON / "icon.json").write_text(json.dumps(doc, indent=2, sort_keys=True) + "\n")


def android(a, pink, blue):
    # Scale the mark about the icon's centre so its farthest point sits inside
    # the safe circle of the 108dp canvas.
    alpha = np.maximum(a, np.maximum(pink, blue))
    ys, xs = np.nonzero(alpha > 0.02)
    n = a.shape[0]
    far = np.sqrt((xs + 0.5 - n / 2) ** 2 + (ys + 0.5 - n / 2) ** 2).max() / n
    scale = SAFE_RADIUS / far

    colour_img = flat(np.zeros(3), a, pink, blue, INK)
    fg_alpha = 1 - (1 - a) * (1 - pink) * (1 - blue)
    mono = a + (1 - a) * (MONO_PINK * pink + (1 - MONO_PINK * pink) * MONO_BLUE * blue)
    with np.errstate(divide="ignore", invalid="ignore"):
        unpremult = np.where(fg_alpha[..., None] > 0, colour_img / fg_alpha[..., None], 0)
    fg = rgba(np.clip(unpremult, 0, 255), fg_alpha)
    mono_img = rgba(np.full(3, 255.0), np.clip(mono, 0, 1))

    for density, px in ANDROID_DENSITIES:
        inner = round(px * scale)
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        for name, img in (("ic_launcher_foreground", fg), ("ic_launcher_monochrome", mono_img)):
            canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
            small = img.resize((inner, inner), Image.LANCZOS)
            canvas.paste(small, ((px - inner) // 2, (px - inner) // 2))
            canvas.save(folder / f"{name}.png", optimize=True)

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Made by tool/icons/glass.py: the mark over the cream ground, and one\n'
        '     colour for the themed icons of Android 13 and later. -->\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n')
    hexcolour = "#{:02X}{:02X}{:02X}".format(*CREAM.astype(int))
    (RES / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{hexcolour}</color>\n'
        '</resources>\n')
    return scale


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", help="where to write checks of the split, rebuilt flat")
    args = parser.parse_args()
    a, pink, blue = layers()
    write_icon(a, pink, blue)
    scale = android(a, pink, blue)
    light, dark = load("light"), load("dark")
    err_light = np.abs(flat(CREAM, a, pink, blue, INK) - light).mean(-1)
    err_dark = np.abs(flat(INK, a, pink, blue, CREAM) - dark).mean(-1)
    print(f"rebuilt light: mean {err_light.mean():.3f}, pixels off by more than 16: {(err_light > 16).sum()}")
    print(f"rebuilt dark:  mean {err_dark.mean():.3f}, pixels off by more than 16: {(err_dark > 16).sum()}")
    print(f"android mark scale: {scale:.3f}")
    if args.preview:
        out = pathlib.Path(args.preview)
        out.mkdir(parents=True, exist_ok=True)
        Image.fromarray(flat(CREAM, a, pink, blue, INK).round().astype(np.uint8)).save(out / "rebuilt-light.png")
        Image.fromarray(flat(INK, a, pink, blue, CREAM).round().astype(np.uint8)).save(out / "rebuilt-dark.png")
        Image.fromarray((np.maximum(err_light, err_dark) * 8).clip(0, 255).astype(np.uint8)).save(out / "error.png")


if __name__ == "__main__":
    main()
