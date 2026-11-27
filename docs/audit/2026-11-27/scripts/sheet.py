#!/usr/bin/env python3
"""Tiles screenshots side by side so several screens can be read at once.

  sheet.py out.png a01 a02 a03        # by name, from $SHOTS (the .s.png copies)
  sheet.py --slice out.png long.png   # one tall page cut into columns
"""
import os
import sys

from PIL import Image, ImageDraw

SHOTS = os.environ.get("SHOTS", ".")


def load(name):
    for cand in (name, os.path.join(SHOTS, name), os.path.join(SHOTS, name + ".s.png"), os.path.join(SHOTS, name + ".png")):
        if os.path.isfile(cand):
            return Image.open(cand).convert("RGB")
    raise SystemExit("no such shot: " + name)


def tile(images, labels, gap=10, head=18):
    h = max(i.height for i in images) + head
    w = sum(i.width for i in images) + gap * (len(images) - 1)
    sheet = Image.new("RGB", (w, h), (40, 40, 40))
    draw = ImageDraw.Draw(sheet)
    x = 0
    for img, label in zip(images, labels):
        draw.text((x + 4, 3), label, fill=(255, 255, 255))
        sheet.paste(img, (x, head))
        x += img.width + gap
    return sheet


def main():
    args = sys.argv[1:]
    if args[0] == "--slice":
        out, src = args[1], args[2]
        col = int(args[3]) if len(args) > 3 else 1500
        width = int(args[4]) if len(args) > 4 else 0
        img = load(src)
        if width and img.width > width:
            img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
            col = col
        parts = [img.crop((0, y, img.width, min(y + col, img.height))) for y in range(0, img.height, col)]
        per = int(args[5]) if len(args) > 5 else 4
        outs = []
        for i in range(0, len(parts), per):
            chunk = parts[i:i + per]
            name = out.replace(".png", f"-{i // per + 1}.png")
            tile(chunk, [f"{src} y={(i + j) * col}" for j in range(len(chunk))]).save(name)
            outs.append(name)
        print("\n".join(outs))
        return
    out, names = args[0], args[1:]
    scale = 1.0
    if names and names[0].startswith("scale="):
        scale = float(names.pop(0).split("=")[1])
    images = [load(n) for n in names]
    if scale != 1.0:
        images = [i.resize((round(i.width * scale), round(i.height * scale)), Image.LANCZOS) for i in images]
    tile(images, names).save(out)
    print(out)


if __name__ == "__main__":
    main()
