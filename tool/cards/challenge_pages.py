"""A page on the site for every card, for a reader to send a friend.

A card leaves the app as a line and a link (lib/widgets/share_sheet.dart):
its question, and where to answer it. The link opens one of these. The
friend, with or without the app, meets the card itself under a line saying a
friend sent it, and over the way to get the app:

- a card with a page is played there, its drawing and all, in the browser;
- a card in words is drawn on the page in its subject's colour: the question,
  its options to pick from when it has them, and the answer behind a tap —
  the answer, what to keep, and where it comes from. The friend thinks
  first; the answer is never in the chat.

A link's preview in a chat is the card's question over a picture: the front
of its drawing, or for a card in words its subject's picture
(tool/cards/og_images.py).

As a post's link does, the link opens the app on a phone that has it: the
site vouches for the app (site/.well-known/), and on an iPhone browsing the
page Safari's own banner offers the app, Open where it is installed, Get where
it is not (apple-itunes-app, its argument the card's link). The link is
short, astutetheapp.com/c/<id>; the site serves it from c/<id>.html.

Written when the site is put together (.github/workflows/deploy.yml), from the
bank as it is published, into <site>/c/<id>.html; the card pages already sit
at <site>/cards/pages/, and the kit they load is copied beside them.

    python3 tool/cards/challenge_pages.py _site
"""
from __future__ import annotations

import hashlib
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

# A card's `topic` is its subject's key (tool/cards/bank/<topic>/).
NAMES = {"weird_facts": "Weird facts", "pop_culture": "Pop culture", "human_body": "Human body"}


def subject_name(topic: str) -> str:
    return NAMES.get(topic, topic.replace("_", " ").capitalize())


def _luminance(hex_colour: str) -> float:
    def lin(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    h = hex_colour.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def ink_of(hex_colour: str) -> str:
    """The words' colour on a subject's colour, as the app picks it (inkOn)."""
    return "#10100C" if _luminance(hex_colour) > 0.34 else "#FFFFFF"


CSS = """@font-face{font-family:Figtree;src:url(/assets/fonts/figtree-latin.woff2) format("woff2");font-weight:300 900;font-display:swap}
@font-face{font-family:Fraunces;src:url(/assets/fonts/fraunces-latin.woff2) format("woff2");font-weight:300 900;font-display:swap}
*{box-sizing:border-box}
html,body{margin:0;background:#0c0c0e;color:#f4f2ec;font-family:Figtree,system-ui,sans-serif}
body{min-height:100vh;display:flex;flex-direction:column;align-items:center;
  background:radial-gradient(120% 60% at 100% 0%,color-mix(in srgb,var(--c) 30%,transparent),transparent 70%),#0c0c0e;
  padding:max(16px,env(safe-area-inset-top)) 16px max(24px,env(safe-area-inset-bottom))}
header{width:100%;max-width:440px;display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}
.brand{display:flex;align-items:center;gap:9px;color:inherit;text-decoration:none;font:700 19px/1 Fraunces,Georgia,serif;letter-spacing:-.02em}
.brand img{border-radius:8px}
.from{font-size:13px;opacity:.65}
.card{width:100%;max-width:440px;border-radius:30px;overflow:hidden;background:var(--c);color:var(--ink);
  box-shadow:0 30px 80px -30px color-mix(in srgb,var(--c) 70%,transparent)}
.card.drawn{aspect-ratio:390/700}
.card.drawn iframe{width:100%;height:100%;border:0;display:block}
.card.words{padding:26px 24px 24px;min-height:min(560px,70vh);display:flex;flex-direction:column}
.subject{font-size:11.5px;font-weight:750;letter-spacing:.14em;opacity:.7}
.q{font:600 clamp(25px,7vw,32px)/1.12 Fraunces,Georgia,serif;letter-spacing:-.02em;margin:14px 0 22px}
.choices{display:flex;flex-direction:column;gap:9px;margin-top:auto}
.choices button,.reveal{all:unset;cursor:pointer;display:block;padding:15px 17px;border-radius:16px;font-size:16px;font-weight:650;line-height:1.3;
  background:color-mix(in srgb,var(--ink) 11%,transparent);border:1.5px solid transparent;transition:background .2s,border-color .2s,opacity .2s}
.reveal{text-align:center;margin-top:auto;background:var(--ink);color:var(--c)}
.choices button.right{border-color:var(--ink);background:color-mix(in srgb,var(--ink) 20%,transparent)}
.choices button.wrong{opacity:.55;text-decoration:line-through}
.choices button:disabled{cursor:default}
.answer{margin-top:20px;animation:in .35s ease-out}
.answer[hidden]{display:none}
@keyframes in{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
.verdict{font:700 20px/1.2 Fraunces,Georgia,serif;margin:0 0 8px}
.a{font-size:16px;line-height:1.5;margin:0}
.steps{margin:12px 0 0;padding-left:20px;font-size:15px;line-height:1.5}
.other{font-size:15px;line-height:1.5;margin:12px 0 0}
.keep{margin-top:16px;padding:14px 16px;border-radius:16px;background:color-mix(in srgb,var(--ink) 10%,transparent)}
.keep span{display:block;font-size:10.5px;font-weight:750;letter-spacing:.14em;opacity:.65;margin-bottom:6px}
.keep p{margin:0;font-size:15.5px;font-weight:650;line-height:1.4}
.src{font-size:12.5px;opacity:.7;margin:14px 0 0;line-height:1.4}
.more{width:100%;max-width:440px;text-align:center;margin-top:22px}
.more h2{font:600 22px/1.2 Fraunces,Georgia,serif;letter-spacing:-.02em;margin:0 0 6px}
.more p{margin:0 0 16px;opacity:.7;font-size:14px;line-height:1.45}
.stores{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}
.stores a{display:inline-flex;align-items:center;justify-content:center;height:46px;padding:0 18px;border-radius:14px;
  background:#f4f2ec;color:#0c0c0e;font-weight:700;font-size:15px;text-decoration:none}
.stores a.alt{background:transparent;color:#f4f2ec;border:1px solid rgba(244,242,236,.25)}
.hint{font-size:14.5px;line-height:1.45;opacity:.8;margin:auto 0 14px}
.hint+.reveal,.hint+.guess{margin-top:0}
.guess{margin-top:auto;display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.guess input{all:unset;flex:1 1 120px;min-width:0;padding:14px 16px;border-radius:16px;font-size:17px;font-weight:650;background:color-mix(in srgb,var(--ink) 11%,transparent);color:var(--ink)}
.guess input::placeholder{color:var(--ink);opacity:.55}
.guess .unit{font-size:14px;font-weight:650;opacity:.75}
.guess button{all:unset;cursor:pointer;padding:14px 18px;border-radius:16px;font-size:16px;font-weight:700;background:var(--ink);color:var(--c)}
.guess.done{opacity:.6;pointer-events:none}
.choices button.side{border-color:var(--ink);background:color-mix(in srgb,var(--ink) 20%,transparent)}
.choices button.other-side{opacity:.6}
"""

HEAD = """<!DOCTYPE html>
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
<meta property="og:description" content="{teaser}">
<meta property="og:url" content="{url}">
<meta name="apple-itunes-app" content="app-id=6806852300, app-argument={url}">
<link rel="canonical" href="{url}">
<meta property="og:image" content="{image}">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" type="image/png" sizes="64x64" href="/favicon.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="stylesheet" href="/c/card.css?v={v}">
<style>:root{{--c:{colour};--ink:{ink}}}</style>
</head>
<body>
<header>
  <a class="brand" href="/?ref=challenge"><img src="/assets/icon.webp" width="28" height="28" alt="">Astute</a>
  <span class="from">A friend sent you this card</span>
</header>
"""

FOOT = """<section class="more">
  <h2>Five cards like this, every morning.</h2>
  <p>Questions with a why, drawn to be played. Free on iPhone and Android.</p>
  <div class="stores">
    <a href="{app_store}">App Store</a>
    <a class="alt" href="{google_play}">Google Play</a>
  </div>
</section>
{script}</body>
</html>
"""

DRAWN = """<main class="card drawn">
  <iframe src="/cards/{page}" title="{title}" loading="eager" allow="autoplay"></iframe>
</main>
"""

# Picks an option, or shows the answer: the friend has thought first.
# Picks an option, takes a side, or shows the answer: the friend has thought first.
SCRIPT = """(function () {
  var answer = document.querySelector('.answer'), verdict = document.querySelector('.verdict');
  function open() { answer.hidden = false; answer.scrollIntoView({behavior: 'smooth', block: 'nearest'}); }
  document.querySelectorAll('.choices button').forEach(function (b) {
    b.addEventListener('click', function () {
      var side = b.dataset.right === 'side', right = b.dataset.right === '1';
      document.querySelectorAll('.choices button').forEach(function (o) {
        o.disabled = true;
        if (side) o.classList.add(o === b ? 'side' : 'other-side');
        else if (o.dataset.right === '1') o.classList.add('right');
        else if (o === b) o.classList.add('wrong');
      });
      if (verdict) verdict.textContent = side ? 'Both sides, then.' : right ? 'Right.' : 'Not quite.';
      open();
    });
  });
  var guess = document.querySelector('.guess');
  if (guess) guess.addEventListener('submit', function (e) {
    e.preventDefault();
    var said = parseFloat(guess.querySelector('input').value);
    if (isNaN(said)) return;
    var value = parseFloat(guess.dataset.value), unit = guess.dataset.unit || '';
    var factor = parseFloat(guess.dataset.factor || '');
    var off = Math.abs(said - value), shown = Math.round(off * 100) / 100;
    var close = factor > 0 && said > 0 && value > 0 && Math.max(said / value, value / said) <= factor;
    if (verdict) verdict.textContent = off === 0 ? 'Spot on.' : (close ? 'Close enough: ' : 'You were ') + shown + (unit ? ' ' + unit : '') + ' off.';
    guess.classList.add('done');
    var h = document.querySelector('.hint'); if (h) h.remove();
    open();
  });
  var reveal = document.querySelector('.reveal');
  if (reveal) reveal.addEventListener('click', function () { reveal.remove(); var h = document.querySelector('.hint'); if (h) h.remove(); open(); });
})();
"""


# The shared style and script, named by what is in them: a page asks for
# them at a new address whenever they change, so a browser holding
# yesterday's cannot dress today's page with it.
VERSION = hashlib.sha1((CSS + SCRIPT).encode("utf-8")).hexdigest()[:10]


def _e(text: object) -> str:
    return html.escape(str(text or ""), quote=True)


def words_card(card: dict) -> str:
    """A card in words, drawn on the page: the question, what to pick, and the answer behind a tap."""
    kind = card.get("kind")
    options = card.get("options") if kind == "pickOne" else None
    correct = card.get("correct")
    out = [f'<main class="card words">\n  <div class="subject">{_e(subject_name(card.get("topic", "")).upper())}</div>\n'
           f'  <h1 class="q">{_e(card.get("question"))}</h1>\n']
    sides = card.get("sides") if kind == "debate" else None
    if options:
        out.append('  <div class="choices">\n')
        for i, option in enumerate(options):
            out.append(f'    <button type="button" data-right="{1 if i == correct else 0}">{_e(option)}</button>\n')
        out.append("  </div>\n")
    elif sides and len(sides) == 2:
        # A debate has no right answer: the friend takes a side, then reads both.
        out.append('  <div class="choices">\n')
        for side in sides:
            out.append(f'    <button type="button" data-right="side">{_e(side)}</button>\n')
        out.append("  </div>\n")
    elif kind in ("number", "estimate") and isinstance(card.get("value"), (int, float)):
        # A number is guessed, not just shown: the friend locks a guess in
        # and is told how far off it was, as the day's challenge tells the
        # reader who sent it.
        if card.get("hint"):
            out.append(f'  <p class="hint">Hint · {_e(card["hint"])}</p>\n')
        factor = card.get("withinFactor") if kind == "estimate" else None
        out.append(f'  <form class="guess" data-value="{card["value"]}" data-unit="{_e(card.get("unit", ""))}"'
                   f'{f" data-factor={chr(34)}{factor}{chr(34)}" if factor else ""}>\n'
                   f'    <input type="number" inputmode="decimal" step="any" required placeholder="Your guess" aria-label="Your guess">\n'
                   f'    <span class="unit">{_e(card.get("unit", ""))}</span>\n'
                   f'    <button type="submit">Lock in</button>\n'
                   f'  </form>\n')
    else:
        if kind in ("number", "estimate") and card.get("hint"):
            out.append(f'  <p class="hint">Hint · {_e(card["hint"])}</p>\n')
        label = "See both sides" if kind == "debate" else "Show the answer"
        out.append(f'  <button type="button" class="reveal">{label}</button>\n')
    out.append('  <section class="answer" hidden>\n')
    if options or (sides and len(sides) == 2) or kind in ("number", "estimate"):
        out.append('    <p class="verdict"></p>\n')
    out.append(f'    <p class="a">{_e(card.get("answer"))}</p>\n')
    steps = card.get("steps") or []
    if kind in ("number", "estimate") and len(steps) > 1:
        out.append('    <ol class="steps">' + "".join(f"<li>{_e(s)}</li>" for s in steps[:-1]) + "</ol>\n")
    if kind == "debate" and card.get("counterpoint"):
        out.append(f'    <p class="other"><b>The other side.</b> {_e(card["counterpoint"])}</p>\n')
    if card.get("move"):
        out.append(f'    <div class="keep"><span>WHAT TO KEEP</span><p>{_e(card["move"])}</p></div>\n')
    if card.get("source"):
        out.append(f'    <p class="src">Source · {_e(card["source"])}</p>\n')
    out.append("  </section>\n</main>\n")
    return "".join(out)


def render(card: dict) -> str:
    cid = card["id"]
    topic = card.get("topic", "")
    colour = COLOURS.get(topic, "#F2F1EC")
    web = card.get("web") or {}
    page = web.get("page")
    front = (web.get("thumbs") or {}).get("front")
    image = f"{SITE}/cards/{front}" if page and front else f"{SITE}/cards/og/{topic if topic in COLOURS else 'thinking'}.png"
    asks = card.get("kind") not in ("read",)
    head = HEAD.format(
        title=_e(card.get("question")),
        teaser="Can you get it? A card from Astute, sent by a friend." if asks
        else "A card from Astute, sent by a friend. Tap to find out.",
        url=f"{SITE}/c/{cid}",
        image=_e(image),
        colour=colour,
        ink=ink_of(colour),
        v=VERSION,
    )
    body = DRAWN.format(page=_e(page), title=_e(card.get("question"))) if page else words_card(card)
    foot = FOOT.format(
        app_store=f"{APP_STORE}?ct=challenge",
        google_play=f"{GOOGLE_PLAY}&referrer=utm_source%3Dchallenge",
        script="" if page else f'<script src="/c/card.js?v={VERSION}" defer></script>\n',
    )
    return head + body + foot


def write(site: Path, bank: dict) -> int:
    out = site / "c"
    out.mkdir(parents=True, exist_ok=True)
    (out / "card.css").write_text(CSS, encoding="utf-8")
    (out / "card.js").write_text(SCRIPT, encoding="utf-8")
    n = 0
    for card in bank.get("cards") or []:
        if not card.get("id") or not card.get("question"):
            continue
        # A card taken out of the app (wrong, or the same as another) has no
        # page: its link, guessed or sent before it was taken out, finds the
        # site's own page for an address that is not there.
        if card.get("disabled"):
            continue
        (out / f"{card['id']}.html").write_text(render(card), encoding="utf-8")
        n += 1
    return n


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    site = Path(argv[0])
    bank = json.loads((site / "cards" / "v2" / "cards.json").read_text(encoding="utf-8"))
    n = write(site, bank)
    print(f"{n} card pages written to {site / 'c'}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
