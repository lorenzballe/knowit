"""Keys Google's mark off its dark plate and writes the app asset.

    python3 tool/icons/google_g.py

The source is the file as supplied — this only removes the plate and resizes,
it does not redraw anything. Alpha comes from how far each pixel sits from the
plate colour, and the colour is un-premultiplied afterwards so the edge does
not keep a dark rim once the plate is gone.
"""
import numpy as np
from PIL import Image

SOURCE = 'tool/icons/source/google-g-master.webp'
TARGET = 'assets/brand/google-g.png'
SIZE = 192

im = Image.open(SOURCE).convert('RGB')
a = np.asarray(im).astype(np.float32)
bg = np.median(a[:40, :40].reshape(-1, 3), axis=0)

# Every hue in the mark clears the plate by well over 120 at full coverage,
# so this ramp reads the edge's own coverage rather than guessing a threshold.
alpha = np.clip(np.abs(a - bg).max(axis=2) / 120.0, 0, 1)
al = alpha[..., None]
rgb = np.clip(np.where(al > 0.004, (a - (1 - al) * bg) / np.maximum(al, 0.004), 0), 0, 255)

img = Image.fromarray(np.dstack([rgb, alpha * 255]).astype(np.uint8), 'RGBA')
img = img.crop(img.getbbox())

w, h = img.size
side = max(w, h)
square = Image.new('RGBA', (side, side), (0, 0, 0, 0))
square.paste(img, ((side - w) // 2, (side - h) // 2))

# Premultiply across the resample, or the transparent border bleeds inward.
p = np.asarray(square).astype(np.float32)
p[..., :3] *= p[..., 3:4] / 255.0
small = Image.fromarray(p.astype(np.uint8), 'RGBA').resize((SIZE, SIZE), Image.LANCZOS)
q = np.asarray(small).astype(np.float32)
q[..., :3] = np.clip(q[..., :3] / (np.maximum(q[..., 3:4], 1) / 255.0), 0, 255)
Image.fromarray(q.astype(np.uint8), 'RGBA').save(TARGET)
print('wrote', TARGET, SIZE)
