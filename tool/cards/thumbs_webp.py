"""Makes the photographs tool/cards/thumbs.cjs took into the pictures the app shows: each PNG in
[raw], taken at two and a half times the card's size, becomes two WebPs of the same name. The small
one in [out], 458 wide at quality 62, for shelves and tiles; the large one in [out]/large, as taken at
quality 66, for the places that show the card at full width, where the small one was soft. Run by
thumbs.cjs; needs Pillow."""
import sys
from pathlib import Path

from PIL import Image

SMALL = (458, 758)

raw, out = Path(sys.argv[1]), Path(sys.argv[2])
if "--one" in sys.argv[3:]:
    # The shelf's pictures: one size, as taken, for the finished day's cards.
    out.mkdir(parents=True, exist_ok=True)
    for png in sorted(raw.glob("*.png")):
        Image.open(png).convert("RGB").save(out / (png.stem + ".webp"), "WEBP", quality=62, method=6)
    sys.exit(0)
(out / "large").mkdir(parents=True, exist_ok=True)
for png in sorted(raw.glob("*.png")):
    im = Image.open(png).convert("RGB")
    im.save(out / "large" / (png.stem + ".webp"), "WEBP", quality=66, method=6)
    im.resize(SMALL, Image.LANCZOS).save(out / (png.stem + ".webp"), "WEBP", quality=62, method=6)
