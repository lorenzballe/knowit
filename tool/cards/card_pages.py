"""A public page for every card, for whoever searches for its question.

The cards' own pages (cards/pages/<id>.html, the drawn ones) are made to be
played inside the app's frame, and a friend's link (/c/<id>, from
challenge_pages.py) is kept out of search engines on purpose: what a friend
was sent should not give the answer away. So the five thousand questions
the bank asks — most of them a why — were on the domain without a door from
a search. These are the doors: one light page per card, at a clean address,

    https://astutetheapp.com/q/<id>

with the question as the title, the short answer and the why, the source
linked where it can be followed, the card itself to play where it is drawn
(its page, opened in place), and "Five like this every morning" over the
stores as they stand (tool/site/chrome.py). The answer is on the page, as a
search would want it: this is the page that says it, not a friend's
challenge.

Every card the app deals has one, from the bank as it is published
(cards/v2/cards.json), but three kinds: a card taken out of the app
(disabled), whose address finds the site's own page for one that is not
there; a card of Books in pills (book), a book's ideas in five cards, which
is Astute+'s to give whole and not the site's to give away; and a card kept
from a family setting (mature).

Each page is small and has no framework: the site's own stylesheet and
script, which every page shares and a browser holds once, and a few lines of
its own (q/q.css, q/q.js, named by what is in them so a new one is fetched
the day it changes); the badges and the subjects' marks drawn from the
site's sprite (assets/sprite.svg) instead of carried. The card's words are
the card's, in English, as the app shows them; around them the site's own
words are in English and in Italian, the reader's shown (chrome.py, "both").

For search engines, each page carries its question and answer as Google
documents them for a page that asks one question and answers it itself
(schema.org FAQPage, one Question with its acceptedAnswer; QAPage is for
pages where users answer), and the site's sitemap is written here as an
index (sitemap.xml) of files of at most 50,000 addresses each
(sitemaps/pages.xml for the site's own pages, sitemaps/cards-<n>.xml for
these), each card's dated by when it was last checked or written.

Written when the site is put together (.github/workflows/deploy.yml), from
the bank as it is published, so the pages are always the bank's:

    python3 tool/cards/card_pages.py _site
"""
from __future__ import annotations

import hashlib
import html
import json
import math
import re
import sys
from datetime import date
from pathlib import Path

from challenge_pages import COLOURS, ink_of, subject_name

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "site"))
import chrome  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
SITE = "https://astutetheapp.com"
DIR = "q"
# Sitemaps hold at most 50,000 addresses a file (sitemaps.org).
PER_SITEMAP = 50_000
# The site's own pages a search should find (the others say noindex).
SITE_PAGES = ("/", "/it/", "/privacy", "/terms", "/support", "/delete-account")

# What the page says around the card, in each of the site's languages.
WORDS = {
    "en": {
        "skip": "Skip to content",
        "answer": "The answer",
        "options": "The options",
        "right": "the right one",
        "sides": "The two sides",
        "side": "One side",
        "other": "The other side",
        "steps": "How it works out",
        "why": "Why it matters",
        "keep": "What to keep",
        "source": "Source",
        "play": "Play the card",
        "drawn": "Drawn to be played, as in the app",
        "more": "Five like this every morning.",
        "more_line": "Questions with a why, answered in two minutes, in the Astute app.",
        "related": "More on {subject}",
        "foot": "Astute: five cards a day, a little sharper.",
        "how": "How it works",
        "pricing": "Pricing",
        "support": "Support",
        "privacy": "Privacy",
        "terms": "Terms",
        "kicker": "A card from Astute",
    },
    "it": {
        "skip": "Vai al contenuto",
        "answer": "La risposta",
        "options": "Le opzioni",
        "right": "quella giusta",
        "sides": "Le due parti",
        "side": "Una parte",
        "other": "L’altra parte",
        "steps": "I passaggi",
        "why": "Perché conta",
        "keep": "Da portare con te",
        "source": "Fonte",
        "play": "Gioca la carta",
        "drawn": "Disegnata per essere giocata, come nell’app",
        "more": "Cinque così ogni mattina.",
        "more_line": "Domande con il perché, a cui rispondi in due minuti, nell’app Astute.",
        "related": "Altro su {subject}",
        "foot": "Astute: cinque carte al giorno, un po’ più svegli.",
        "how": "Come funziona",
        "pricing": "Prezzi",
        "support": "Assistenza",
        "privacy": "Privacy",
        "terms": "Termini",
        "kicker": "Una carta di Astute",
    },
}


def subjects_it() -> dict[str, str]:
    """The subjects' names in Italian, as the app says them (subjectName)."""
    arb = json.loads((ROOT / "lib" / "l10n" / "app_it.arb").read_text(encoding="utf-8"))
    return dict(re.findall(r"(\w+)\{([^{}]+)\}", arb["subjectName"]))


SUBJECTS_IT = subjects_it()

CSS = """.qpage{position:relative;max-width:760px;margin:0 auto;padding:calc(var(--nav-h) + 44px) var(--gutter) 40px}
.q-front{position:relative;padding:22px 22px 26px;border-radius:28px;background-color:var(--c);color:rgb(var(--ink));
  background-image:linear-gradient(160deg,rgba(255,255,255,.16),rgba(255,255,255,0) 48%),radial-gradient(120% 90% at 100% 100%,rgba(0,0,0,.08),transparent 60%);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.28),0 30px 60px -30px rgba(0,0,0,.7)}
.q-label{display:flex;align-items:center;gap:8px;margin:0;font:600 11px/16px var(--font-text);letter-spacing:1.4px;text-transform:uppercase;color:rgb(var(--ink) / .72)}
.q-label .mark{width:16px;height:16px;color:rgb(var(--ink));fill:none;stroke:currentColor;stroke-width:1.9;stroke-linecap:round;stroke-linejoin:round;overflow:visible}
.q-q{margin:18px 0 0;font:600 clamp(28px,7.4vw,44px)/1.08 var(--font-display);letter-spacing:-.025em;font-optical-sizing:auto;font-variation-settings:'SOFT' 30,'WONK' 0;text-wrap:balance}
.q-opts{margin:22px 0 0;padding:0;list-style:none;display:flex;flex-direction:column;gap:8px}
.q-opts li{display:flex;align-items:center;gap:12px;padding:13px 16px;border-radius:16px;background:rgb(var(--ink) / .1);font:600 16px/1.35 var(--font-text)}
.q-opts li.is-right{background:rgb(var(--ink));color:var(--c)}
.q-opts li i{flex:none;margin-left:auto;font:700 11px/1 var(--font-text);font-style:normal;letter-spacing:.1em;text-transform:uppercase}
.q-pic{margin:22px auto 0;width:min(100%,320px)}
.q-plain{padding:0;background:none;box-shadow:none;color:var(--cream)}
.q-plain .q-label{color:var(--cream-60)}
.q-plain .q-label .mark{color:var(--c)}
.q-pic a,.q-frame{display:block;position:relative;aspect-ratio:390/700;border-radius:28px;overflow:hidden;background:var(--c);
  box-shadow:0 30px 70px -30px color-mix(in srgb,var(--c) 60%,transparent)}
.q-pic img{display:block;width:100%;height:100%;object-fit:cover}
.q-pic .q-go{position:absolute;left:50%;bottom:18px;transform:translateX(-50%);display:inline-flex;align-items:center;gap:8px;height:48px;padding:0 22px;border-radius:24px;
  background:var(--cream);color:var(--night);font:700 15px/1 var(--font-text);white-space:nowrap;box-shadow:0 5px 0 0 var(--edge),0 18px 30px -12px rgba(0,0,0,.6)}
.q-frame{width:100%;border:0}
.q-pic figcaption{margin:10px 0 0;text-align:center;font:500 13px/1.4 var(--font-text);color:var(--cream-50)}
.q-body{margin:34px 0 0;font:400 18px/1.6 var(--font-text);color:var(--cream-85)}
.q-body h2,.q-more-k{margin:30px 0 8px;font:700 11px/1.3 var(--font-text);letter-spacing:.16em;text-transform:uppercase;color:var(--cream-50)}
.q-body h2:first-child{margin-top:0}
.q-short{margin:0;font:500 clamp(24px,5.6vw,30px)/1.2 var(--font-display);letter-spacing:-.015em;color:var(--cream);text-wrap:pretty}
.q-body p{margin:10px 0 0;text-wrap:pretty}
.q-steps{margin:10px 0 0;padding-left:22px}
.q-steps li+li{margin-top:6px}
.q-keep{margin:30px 0 0;padding:18px 20px;border-radius:20px;background:var(--cream);color:var(--night)}
.q-keep h2{margin:0 0 6px;color:var(--ink-60)}
.q-keep p{margin:0;font:600 17px/1.45 var(--font-text);color:var(--night)}
.q-source{margin:28px 0 0;padding-top:16px;border-top:1px solid var(--hairline);font:500 14.5px/1.5 var(--font-text);color:var(--cream-60)}
.q-source a{color:var(--cream-85);text-decoration:underline;text-underline-offset:3px;text-decoration-color:rgba(242,241,236,.35);overflow-wrap:anywhere}
.q-more{margin:56px 0 0;padding:30px 24px 32px;border-radius:28px;border:1px solid var(--hairline-strong);text-align:center}
.q-more .stores{--bh:clamp(40px,10.4vw,48px);gap:20px 10px}
.q-more h2{margin:0 0 8px;font:500 clamp(30px,7vw,40px)/1.05 var(--font-display);letter-spacing:-.025em;font-variation-settings:'opsz' 144;text-wrap:balance}
.q-more p{margin:0 auto 22px;max-width:440px;font:400 16px/1.5 var(--font-text);color:var(--cream-70)}
.q-related{margin:44px 0 0}
.q-related ul{margin:0;padding:0;list-style:none;border-top:1px solid var(--hairline)}
.q-related li{border-bottom:1px solid var(--hairline)}
.q-related a{display:block;padding:14px 0;font:500 17px/1.4 var(--font-display);color:var(--cream-85);text-decoration:none}
.q-related a:hover{color:var(--cream)}
.q-foot .foot-wrap{padding-top:40px;padding-bottom:36px}
.q-foot-line{margin:0;font:500 15px/1.5 var(--font-text);color:var(--cream-70)}
.q-foot-links{display:flex;flex-wrap:wrap;gap:8px 20px;margin:16px 0 0}
.q-foot-links a{font:500 14px/1.4 var(--font-text);color:var(--cream-60);text-decoration:none}
.q-foot-links a:hover{color:var(--cream)}
.q-foot .foot-bottom{margin-top:24px}
@media (min-width:768px){.qpage{padding-top:calc(var(--nav-h) + 72px)}.q-front{padding:30px 32px 34px}}
"""

# Opens the card's drawn page in place of its picture, as the app shows it.
SCRIPT = """document.querySelectorAll('[data-play]').forEach(function (a) {
  a.addEventListener('click', function (e) {
    e.preventDefault();
    var f = document.createElement('iframe');
    f.className = 'q-frame';
    f.src = a.getAttribute('href');
    f.title = a.dataset.title || '';
    f.setAttribute('allow', 'autoplay');
    a.replaceWith(f);
  });
});
"""

VERSION = hashlib.sha1((CSS + SCRIPT).encode("utf-8")).hexdigest()[:10]


def sprite_src() -> str:
    """The site's sprite, named by what is in it, so that a page drawn from a
    new one never draws from a browser's old copy."""
    v = hashlib.sha1(chrome.sprite_file().encode("utf-8")).hexdigest()[:10]
    return f"/assets/sprite.svg?v={v}"


def e(text: object) -> str:
    return html.escape(str(text or ""), quote=True)


def both(key: str, **kw) -> str:
    """One of the page's own lines, in each language, the reader's shown."""
    return "".join(f'<span class="l-{lg}"{" lang=" + chr(34) + lg + chr(34) if lg != "en" else ""}>'
                   f'{e(WORDS[lg][key].format(**{k: v[lg] for k, v in kw.items()}))}</span>' for lg in chrome.LANGS)


def has_page(card: dict) -> bool:
    """Whether a card gets a public page: one the app deals, not a book's, not kept from a family setting."""
    return bool(card.get("id") and card.get("question") and not card.get("disabled")
                and not card.get("book") and not card.get("mature"))


# Words that end in a full stop without ending a sentence: always (titles,
# Latin, a single capital, which is an initial), and before a number only
# (No. 5, Fig. 2, c. 1500), so that "No." can still be a whole answer.
ABBREVIATIONS = re.compile(r"(?:\b(?:e\.g|i\.e|vs|Dr|Mr|Mrs|Ms|St|Mt|cf|al|Inc|Ltd|Jr|Sr|approx)|(?:^|[\s(])[A-Z])$")
BEFORE_A_NUMBER = re.compile(r"\b(?:No|Nos|Fig|Vol|pp|p|c|ca|Art|ch)$")


def first_sentence(text: str) -> tuple[str, str]:
    """[text] as its first sentence and the rest, where the first is a
    sentence of its own: never cut at an initial, an abbreviation or a
    decimal point, and never longer than a short answer is."""
    for m in re.finditer(r"[.!?](?=\s+([A-Z0-9“\"‘'(]))", text):
        head = text[:m.end()]
        if m.group(0) == ".":
            word = head[:-1]
            if ABBREVIATIONS.search(word) or (m.group(1).isdigit() and BEFORE_A_NUMBER.search(word)):
                continue
        if len(head) > 220:
            break
        return head.strip(), text[m.end():].strip()
    return "", text.strip()


def simple(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", s.lower()).strip()


def answer_of(card: dict) -> tuple[str, list[str], list[str]]:
    """The card's answer as the page says it: the short answer, the why in
    paragraphs, and the worked steps where the card has them."""
    kind = card.get("kind")
    answer = (card.get("answer") or "").strip()
    steps = [s for s in (card.get("steps") or []) if s]
    if kind == "pickOne" and isinstance(card.get("correct"), int) and card.get("options"):
        short = card["options"][card["correct"]]
        head, rest = first_sentence(answer)
        # The answer often opens by naming the option: not said twice.
        why = rest if head and (simple(head).startswith(simple(short)) or simple(short).startswith(simple(head))) else answer
        return short.rstrip(".") + ".", [why] if why else [], []
    if kind in ("number", "estimate") and isinstance(card.get("value"), (int, float)):
        value = card["value"]
        shown = f"{value:,.10g}" if abs(value) >= 10_000 else f"{value:g}"
        unit = (card.get("unit") or "").strip()
        short = ("About " if kind == "estimate" else "") + shown + (" " + unit if unit else "") + "."
        worked = steps[:-1] if steps and steps[-1].strip() == answer else steps
        return short, [answer] if answer and answer != short else [], worked
    if kind == "debate":
        return "", [answer] if answer else [], []
    head, rest = first_sentence(answer)
    return head, [rest] if rest else [], steps


URL = re.compile(r"https?://[^\s<>\"]+")
DOI = re.compile(r"\b(10\.\d{4,9}/[^\s,;<>\"]+)")


def source_link(card: dict) -> str | None:
    """Where the card's claim can be followed: the first address its
    reference gives, or its DOI; none for a book and page alone."""
    ref = card.get("reference") or ""
    m = URL.search(ref)
    if m:
        return m.group(0).rstrip(".,;)")
    m = DOI.search(ref)
    if m:
        return "https://doi.org/" + m.group(1).rstrip(".,;)")
    return None


def description(short: str, why: list[str], card: dict) -> str:
    text = " ".join([short] + why) if short else " ".join(why) or card.get("move") or ""
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= 158:
        return text
    cut = text[:155].rsplit(" ", 1)[0].rstrip(",;:—-")
    return cut + "…"


def json_ld(card: dict, short: str, why: list[str], url: str) -> str:
    """The question and its answer, as schema.org says one page's own: a
    FAQPage with one Question and its acceptedAnswer."""
    text = " ".join(x for x in [short] + why if x) or card.get("answer") or ""
    data = {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "url": url,
        "inLanguage": card.get("language") or "en",
        "mainEntity": [{
            "@type": "Question",
            "name": card["question"],
            "acceptedAnswer": {"@type": "Answer", "text": text},
        }],
    }
    # Written inside a script element: no '<' of a card's words may open or close a tag there.
    return json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")


def related(card: dict, cards: list[dict], n: int = 4) -> list[dict]:
    """A few more cards to read next: the card's own strand first, then its
    genre, then its subject, in the bank's order after it."""
    out: list[dict] = []
    for key in ("strand", "genre", "topic"):
        same = [c for c in cards if c.get(key) and c.get(key) == card.get(key)]
        if card in same:
            i = same.index(card)
            same = same[i + 1:] + same[:i]
        for c in same:
            if c is not card and c not in out:
                out.append(c)
            if len(out) == n:
                return out
    return out


def header() -> str:
    """The site's nav, as small as a card's page needs it: home, the other
    language, Download."""
    def brand(lg):
        lang = f' lang="{lg}"' if lg != "en" else ""
        return (f'<a class="brand l-{lg}"{lang} href="{chrome.at("/", lg)}" aria-label="{chrome.w("home", lg)}">'
                '<img src="/assets/icon.webp" width="30" height="30" alt=""><span>Astute</span></a>')
    return ('<header class="site-nav">\n  <nav aria-label="Main">\n    '
            + "".join(brand(lg) for lg in chrome.LANGS)
            + '\n    <div class="nav-actions">'
            + chrome.switch("both", None)
            + chrome.link(chrome.download, "download", "both", cls="btn-download", extra=" data-store")
            + "</div>\n  </nav>\n</header>")


def footer() -> str:
    def to(key, path, page=False):
        return "".join(
            f'<a class="l-{lg}"{" lang=" + chr(34) + lg + chr(34) if lg != "en" else ""} '
            f'href="{(path + ("#" + lg if lg != "en" else "")) if page else chrome.at(path, lg)}">{e(WORDS[lg][key])}</a>'
            for lg in chrome.LANGS)
    links = "".join([to("how", "/#how"), to("pricing", "/#pricing"), to("support", "/support", True),
                     to("privacy", "/privacy", True), to("terms", "/terms", True)])
    return ('<footer class="site-foot q-foot">\n  <div class="foot-wrap">\n'
            f'    <p class="q-foot-line">{both("foot")}</p>\n'
            f'    <nav class="q-foot-links" aria-label="Footer">{links}</nav>\n'
            f'    <div class="foot-bottom"><span>© 2026 TheBaleCompany</span><span class="tm">{chrome.say("tm", "both")}</span></div>\n'
            "  </div>\n</footer>")


def render(card: dict, cards: list[dict]) -> str:
    cid = card["id"]
    topic = card.get("topic", "")
    colour = COLOURS.get(topic, "#F2F1EC")
    ink = ink_of(colour)
    triplet = " ".join(str(int(ink[i:i + 2], 16)) for i in (1, 3, 5))
    url = f"{SITE}/{DIR}/{cid}"
    web = card.get("web") or {}
    page = (web.get("page") or "").split("?")[0]
    front = (web.get("thumbs") or {}).get("front")
    image = f"{SITE}/cards/{front}" if page and front else f"{SITE}/cards/og/{topic if topic in COLOURS else 'thinking'}.png"
    short, why, steps = answer_of(card)
    name = {"en": subject_name(topic), "it": SUBJECTS_IT.get(topic, subject_name(topic))}
    mark = "subject-" + subject_name(topic).lower().replace(" ", "-")
    sprite = sprite_src()

    body = [f'<article class="q-card" style="--c:{colour};--ink:{triplet}">',
            f'<div class="q-front{" q-plain" if page else ""}">',
            f'<p class="q-label"><svg class="mark" aria-hidden="true"><use href="{sprite}#{mark}"/></svg><span>{e(name["en"])}</span></p>',
            f'<h1 class="q-q">{e(card["question"])}</h1>']
    if card.get("kind") == "pickOne" and card.get("options"):
        items = "".join(
            f'<li class="is-right">{e(o)}<i>{both("right")}</i></li>' if i == card.get("correct") else f"<li>{e(o)}</li>"
            for i, o in enumerate(card["options"]))
        body.append(f'<ol class="q-opts" aria-label="{e(WORDS["en"]["options"])}">{items}</ol>')
    if card.get("kind") == "debate" and len(card.get("sides") or []) == 2:
        body.append('<ol class="q-opts">' + "".join(f"<li>{e(s)}</li>" for s in card["sides"]) + "</ol>")
    body.append("</div>")
    if page:
        body.append(f'<figure class="q-pic"><a href="/cards/{e(page)}" data-play data-title="{e(card["question"])}" rel="nofollow">'
                    f'<img src="/cards/{e(front)}" width="458" height="758" alt="{e(web.get("label") or card["question"])}" decoding="async">'
                    f'<span class="q-go">{both("play")} <span aria-hidden="true">→</span></span></a>'
                    f'<figcaption>{both("drawn")}</figcaption></figure>')
    body.append('<div class="q-body">')
    if card.get("kind") == "debate":
        body.append(f"<h2>{both('side')}</h2>")
        body += [f"<p>{e(p)}</p>" for p in why]
        if card.get("counterpoint"):
            body.append(f"<h2>{both('other')}</h2><p>{e(card['counterpoint'])}</p>")
    else:
        body.append(f"<h2>{both('answer')}</h2>")
        if short:
            body.append(f'<p class="q-short">{e(short)}</p>')
        body += [f"<p>{e(p)}</p>" for p in why]
        if steps:
            body.append(f"<h2>{both('steps')}</h2><ol class=\"q-steps\">" + "".join(f"<li>{e(s)}</li>" for s in steps) + "</ol>")
    if card.get("why"):
        body.append(f"<h2>{both('why')}</h2><p>{e(card['why'])}</p>")
    if card.get("move"):
        body.append(f'<aside class="q-keep"><h2>{both("keep")}</h2><p>{e(card["move"])}</p></aside>')
    link = source_link(card)
    label = card.get("source") or card.get("reference") or ""
    if label:
        shown = f'<a href="{e(link)}" rel="nofollow noopener" target="_blank">{e(label)}</a>' if link else e(label)
        body.append(f'<p class="q-source">{both("source")}: {shown}</p>')
    body.append("</div></article>")
    where = "".join(f'<span class="l-{lg}"{" lang=" + chr(34) + lg + chr(34) if lg != "en" else ""}>'
                    f'{e(WORDS[lg]["more_line"])} {e(chrome.where(True, lg))}.</span>' for lg in chrome.LANGS)
    body.append(f'<section class="q-more"><h2>{both("more")}</h2><p>{where}</p>'
                f'<div class="stores center">{chrome.stores("both", play_first=True, src=sprite)}</div></section>')
    more = related(card, cards)
    if more:
        body.append(f'<nav class="q-related" aria-label="{e(WORDS["en"]["related"].format(subject=name["en"]))}">'
                    f'<h2 class="q-more-k">{both("related", subject=name)}</h2><ul>'
                    + "".join(f'<li><a href="/{DIR}/{e(c["id"])}">{e(c["question"])}</a></li>' for c in more)
                    + "</ul></nav>")
    desc = description(short, why, card)
    title = card["question"]
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
{chrome.lang_script("both", f"/{DIR}/{cid}")}
<title>{e(title)} · Astute</title>
<meta name="description" content="{e(desc)}">
<link rel="canonical" href="{url}">
<meta name="theme-color" content="#141416">
<meta name="color-scheme" content="dark">
<meta property="og:type" content="article">
<meta property="og:site_name" content="Astute">
<meta property="og:locale" content="en_GB">
<meta property="og:url" content="{url}">
<meta property="og:title" content="{e(title)}">
<meta property="og:description" content="{e(desc)}">
<meta property="og:image" content="{e(image)}">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" type="image/png" sizes="64x64" href="/favicon.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="preload" href="/assets/fonts/figtree-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/assets/fonts/fraunces-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="/assets/site.css">
<link rel="stylesheet" href="/{DIR}/q.css?v={VERSION}">
<script src="/assets/main.js" defer></script>
<script src="/{DIR}/q.js?v={VERSION}" defer></script>
<script type="application/ld+json">{json_ld(card, short, why, url)}</script>
</head>
<body>
<a class="skip" href="#top">{both("skip")}</a>
{header()}
<main class="qpage" id="top">
{chr(10).join(body)}
</main>
{footer()}
</body>
</html>
"""


def lastmod(card: dict) -> str | None:
    day = card.get("checked") or card.get("written")
    return day if isinstance(day, str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}", day) else None


def sitemap(urls: list[tuple[str, str | None]]) -> str:
    rows = "".join(f"  <url><loc>{e(u)}</loc>" + (f"<lastmod>{m}</lastmod>" if m else "") + "</url>\n" for u, m in urls)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + rows + "</urlset>\n")


def sitemap_index(files: list[tuple[str, str | None]]) -> str:
    rows = "".join(f"  <sitemap><loc>{SITE}/{f}</loc>" + (f"<lastmod>{m}</lastmod>" if m else "") + "</sitemap>\n"
                   for f, m in files)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + rows + "</sitemapindex>\n")


def write(site: Path, bank: dict, per_sitemap: int = PER_SITEMAP) -> list[dict]:
    """Writes a page for every card that has one into [site]/q/, the
    pages' style and script beside them, and the sitemaps. Returns the cards
    written."""
    cards = [c for c in bank.get("cards") or [] if has_page(c)]
    out = site / DIR
    out.mkdir(parents=True, exist_ok=True)
    (out / "q.css").write_text(CSS, encoding="utf-8")
    (out / "q.js").write_text(SCRIPT, encoding="utf-8")
    for card in cards:
        (out / f"{card['id']}.html").write_text(render(card, cards), encoding="utf-8")
    maps = site / "sitemaps"
    maps.mkdir(parents=True, exist_ok=True)
    for old in maps.glob("*.xml"):
        old.unlink()
    (maps / "pages.xml").write_text(sitemap([(SITE + p, None) for p in SITE_PAGES]), encoding="utf-8")
    files: list[tuple[str, str | None]] = [("sitemaps/pages.xml", None)]
    entries = [(f"{SITE}/{DIR}/{c['id']}", lastmod(c)) for c in cards]
    for n in range(max(1, math.ceil(len(entries) / per_sitemap))):
        chunk = entries[n * per_sitemap:(n + 1) * per_sitemap]
        name = f"sitemaps/cards-{n + 1}.xml"
        (site / name).write_text(sitemap(chunk), encoding="utf-8")
        files.append((name, max((m for _, m in chunk if m), default=None)))
    (site / "sitemap.xml").write_text(sitemap_index(files), encoding="utf-8")
    return cards


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    site = Path(argv[0])
    bank = json.loads((site / "cards" / "v2" / "cards.json").read_text(encoding="utf-8"))
    cards = write(site, bank)
    size = sum((site / DIR / f"{c['id']}.html").stat().st_size for c in cards)
    print(f"{len(cards)} card pages written to {site / DIR} ({size / 1e6:.1f} MB, "
          f"{size / max(1, len(cards)) / 1e3:.1f} kB each), and the sitemaps, on {date.today().isoformat()}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
