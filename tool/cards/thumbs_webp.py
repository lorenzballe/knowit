"""Makes the photographs tool/cards/thumbs.cjs took small: each PNG in [raw] becomes a WebP of the
same name in [out], at quality 62. Run by thumbs.cjs; needs Pillow."""
import sys
from pathlib import Path

from PIL import Image

raw, out = Path(sys.argv[1]), Path(sys.argv[2])
for png in sorted(raw.glob("*.png")):
    Image.open(png).convert("RGB").save(out / (png.stem + ".webp"), "WEBP", quality=62, method=6)
