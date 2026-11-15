"""A page on the site for every free card, for a reader to send a friend.

"Challenge a friend" in the app sends a link to one of these. The friend, with
or without the app, opens the card itself — its page, playable in the browser,
the drawing and all — under one line saying a friend sent it, and over the
way to get the app. The link's preview in a chat is the card's question and
the picture of its front, so the question is what makes them open it.

Written when the site is put together (.github/workflows/deploy.yml), from the
bank as it is published, into <site>/c/<id>.html; the card pages already sit
at <site>/cards/pages/, and the kit they load is copied beside them.

    python3 tool/cards/challenge_pages.py _site
"""
from __future__ import annotations

import html
import json
import sys
from pathlib import Path

SITE = "https://astutetheapp.com"
APP_STORE = "https://apps.apple.com/app/id6806852300"
GOOGLE_PLAY = "https://play.google.com/store/apps/details?id=com.astuto.app"

# The subjects' colours, as the app draws them (lib/data/topics.dart).
COLOURS = {
    "economics": "#FFE600", "sport": "#A6FF00", "nature": "#00D451", "science": "#00E5A0",
    "maths": "#0E9A70", "language": "#00D9D9", "technology": "#00A6FF", "space": "#2B5CFF",
    "philosophy": "#4C6FFF", "cinema": "#6E3AFF", "psychology": "#9B5CFF", "music": "#C13AFF",
    "weird_facts": "#E040FB", "art": "#FF00A8", "pop_culture": "#FF3D7F", "human_body": "#FF2D5F",
    "medicine": "#FF3B30", "food": "#FF7A1A", "history": "#FFB000", "life": "#FFC49B",
    "thinking": "#F2F1EC",
}

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{title} · Astute</title>
<meta name="description" content="A card from Astute, sent by a friend. Five like it every morning.">
<meta name="robots" content="noindex">
<meta name="theme-color" content="#0c0c0e">
<meta name="color-scheme" content="dark">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Astute">
<meta property="og:title" content="{title}">
<meta property="og:description" content="Can you get this one? A card from Astute, sent by a friend.">
<meta property="og:url" content="{url}">
{image}<meta name="twitter:card" content="{card}">
<link rel="icon" type="image/png" sizes="64x64" href="/favicon.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<style>
@font-face{{font-family:Figtree;src:url(/assets/fonts/figtree-latin.woff2) format("woff2");font-weight:300 900;font-display:swap}}
@font-face{{font-family:Fraunces;src:url(/assets/fonts/fraunces-latin.woff2) format("woff2");font-weight:300 900;font-display:swap}}
:root{{--c:{colour}}}
*{{box-sizing:border-box}}
html,body{{margin:0;background:#0c0c0e;color:#f4f2ec;font-family:Figtree,system-ui,sans-serif}}
body{{min-height:100vh;display:flex;flex-direction:column;align-items:center;
  background:radial-gradient(120% 60% at 100% 0%,color-mix(in srgb,var(--c) 30%,transparent),transparent 70%),#0c0c0e;
  padding:max(16px,env(safe-area-inset-top)) 16px max(24px,env(safe-area-inset-bottom))}}
header{{width:100%;max-width:440px;display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}}
.brand{{display:flex;align-items:center;gap:9px;color:inherit;text-decoration:none;font:700 19px/1 Fraunces,Georgia,serif;letter-spacing:-.02em}}
.brand img{{border-radius:8px}}
.from{{font-size:13px;opacity:.65}}
.card{{width:100%;max-width:440px;aspect-ratio:390/700;border-radius:30px;overflow:hidden;background:var(--c);
  box-shadow:0 30px 80px -30px color-mix(in srgb,var(--c) 70%,transparent)}}
.card iframe{{width:100%;height:100%;border:0;display:block}}
.more{{width:100%;max-width:440px;text-align:center;margin-top:22px}}
.more h1{{font:600 22px/1.2 Fraunces,Georgia,serif;letter-spacing:-.02em;margin:0 0 6px}}
.more p{{margin:0 0 16px;opacity:.7;font-size:14px;line-height:1.45}}
.stores{{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}}
.stores a{{display:inline-flex;align-items:center;justify-content:center;height:46px;padding:0 18px;border-radius:14px;
  background:#f4f2ec;color:#0c0c0e;font-weight:700;font-size:15px;text-decoration:none}}
.stores a.alt{{background:transparent;color:#f4f2ec;border:1px solid rgba(244,242,236,.25)}}
</style>
</head>
<body>
<header>
  <a class="brand" href="/?ref=challenge"><img src="/assets/icon.webp" width="28" height="28" alt="">Astute</a>
  <span class="from">A friend sent you this card</span>
</header>
<main class="card">
  <iframe src="/cards/{page}" title="{title}" loading="eager" allow="autoplay"></iframe>
</main>
<section class="more">
  <h1>Five cards like this, every morning.</h1>
  <p>Questions with a why, drawn to be played. Free on iPhone and Android.</p>
  <div class="stores">
    <a href="{app_store}">App Store</a>
    <a class="alt" href="{google_play}">Google Play</a>
  </div>
</section>
</body>
</html>
"""


def pages(bank: dict) -> list[tuple[str, str, str, str, str | None]]:
    """(id, topic, question, page, front picture) for every card with a page."""
    out = []
    for card in bank.get("cards") or []:
        web = card.get("web") or {}
        page = web.get("page")
        if not page or not card.get("id"):
            continue
        front = (web.get("thumbs") or {}).get("front")
        out.append((card["id"], card.get("topic", ""), card.get("question", ""), page, front))
    return out


def render(cid: str, topic: str, question: str, page: str, front: str | None) -> str:
    url = f"{SITE}/c/{cid}.html"
    image = (f'<meta property="og:image" content="{SITE}/cards/{html.escape(front, quote=True)}">\n'
             if front else "")
    return PAGE.format(
        title=html.escape(question, quote=True),
        url=url,
        image=image,
        card="summary_large_image" if front else "summary",
        colour=COLOURS.get(topic, "#F2F1EC"),
        page=html.escape(page, quote=True),
        app_store=f"{APP_STORE}?ct=challenge",
        google_play=f"{GOOGLE_PLAY}&referrer=utm_source%3Dchallenge",
    )


def write(site: Path, bank: dict) -> int:
    out = site / "c"
    out.mkdir(parents=True, exist_ok=True)
    n = 0
    for cid, topic, question, page, front in pages(bank):
        (out / f"{cid}.html").write_text(render(cid, topic, question, page, front), encoding="utf-8")
        n += 1
    return n


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    site = Path(argv[0])
    bank = json.loads((site / "cards" / "v2" / "cards.json").read_text(encoding="utf-8"))
    n = write(site, bank)
    print(f"{n} challenge pages written to {site / 'c'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
