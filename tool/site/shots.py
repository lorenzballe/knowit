"""The app's pictures on the site, made from what tool/site_shots.dart takes.

    SHOTS=/some/folder flutter test tool/site_shots.dart --update-goldens
    python3 tool/site/shots.py /some/folder

    SHOTS=/other/folder LANG_SHOT=it flutter test tool/site_shots.dart --update-goldens
    python3 tool/site/shots.py /other/folder it

The camera photographs an iPhone 16 Pro, 402 by 874 points at three pixels a
point (1206 by 2622); the site shows each picture in a phone of its own drawn
in CSS (site/assets/landing.css, .device), 290 pixels across at the most, so
840 by 1826 is about three pixels for each one it is shown at, and each
picture stays under 100 kB. The day as it is sent (share-day.png, 1080
across) is shown flat, and kept at two thirds of its size.

Each picture is written under the name the pages use (SHOTS below), as WebP;
a name the camera has no picture for is left as it is. Pictures of the app in
another language go under site/assets/<lang>/, where that language's pages
(tool/site/i18n.py) take them in place of the English ones.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'site' / 'assets'

# The camera's name for each picture, the site's name for it, and its size.
PHONE = (840, 1826)
SHOTS = {
    'today': ('app-today', PHONE),
    'answer': ('app-flipped', PHONE),
    'deeper': ('app-deeper', PHONE),
    'done': ('app-day-done', PHONE),
    'explore': ('app-explore', PHONE),
    'challenges': ('app-challenges', PHONE),
    'explore-news': ('app-news', PHONE),
    'journey': ('app-journey', PHONE),
    'level': ('app-level', PHONE),
    'profile': ('app-profile', PHONE),
    'share-day': ('share-day', (720, 900)),
}


def main(argv: list[str]) -> int:
    if len(argv) not in (1, 2):
        print(__doc__, file=sys.stderr)
        return 2
    shots = Path(argv[0])
    into = ASSETS / argv[1] if len(argv) == 2 else ASSETS
    into.mkdir(parents=True, exist_ok=True)
    made = []
    for shot, (name, size) in SHOTS.items():
        src = shots / f'{shot}.png'
        if not src.exists():
            continue
        picture = Image.open(src).convert('RGB').resize(size, Image.LANCZOS)
        out = into / f'{name}.webp'
        picture.save(out, 'WEBP', quality=82, method=6)
        made.append(f'{out.relative_to(ROOT)} ({out.stat().st_size // 1024} kB)')
    print('\n'.join(made) or 'no pictures in ' + str(shots))
    return 0 if made else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
