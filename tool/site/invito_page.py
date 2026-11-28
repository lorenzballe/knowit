"""Invita un amico: the page a friend lands on from a reader's invitation.

A reader sends "Invita un amico" from the profile (lib/widgets/invite_sheet.dart):
a line in their language and a link with their code,

    https://astutetheapp.com/invito?c=K7MQ2P

and nothing else: the code is six characters drawn at random, and says
nothing about anyone (functions/src/invite.ts). On a phone with the app the
phone hands the link to the app, which takes the code (site/.well-known/,
lib/utils/widget_open.dart); anywhere else it opens this page, which says
what the friend gets and how:

- a week of Astute+, theirs and the inviter's, once their first day is read;
- the code, large, with a button to copy it;
- the three steps: get the app; come back to the message and open the link
  again, or type the code in the app, in the profile under "Have a code?";
  finish the first day, the five cards;
- on Android, where Chrome can hand a link to a given app, one button that
  opens Astute with the code, or Google Play when it is not installed;
- the rules in a line: a new account that never had Astute+, one code each,
  nothing to pay or to cancel, eight weeks a year at most for whoever invites.

In English and in Italian, the site's two languages, the reader's shown:
the one they chose with the site's switch, or else their browser's (both,
one after the other, without a script), and the site's chrome around it in
the same, as on every page that holds both (chrome.header("both")). The
code is read from the link by the page's script, shown, and taken out of
the address before anything is counted: the site counts the page as it
counts every page (site/assets/main.js), never the code. Nothing is kept on
the device.

Written when the site is put together (.github/workflows/deploy.yml), into
<site>/invito.html, which the site serves at /invito.

    python3 tool/site/invito_page.py _site
"""
from __future__ import annotations

import html
import sys
from pathlib import Path

import chrome
from chrome import APP_STORE_OPEN, GOOGLE_PLAY, GOOGLE_PLAY_OPEN, where

SITE = "https://astutetheapp.com"
PATH = "invito"

# What a code is drawn from (functions/src/invite.ts, CODE_ALPHABET) and how
# long it is: the page shows only a code that could be one.
CODE_ALPHABET = "23456789BCDFGHJKMNPQRSTVWXYZ"
CODE_LENGTH = 6

# The app's package, for the button that opens it on Android.
PACKAGE = "com.astuto.app"

# What the page says, in each of its languages. The words for the app's own
# rows ("Have a code?", the profile) are the app's (lib/l10n/app_*.arb), and
# a test holds them to it.
WORDS = {
    "en": {
        "kicker": "An invitation",
        "title": "A week of Astute+, on a friend.",
        "lede": ("Whoever sent you this link is giving you a week of Astute+: five cards a day all your own, "
                 "your journey and the whole archive. Finish your first day and the week is yours, and they get one too."),
        "code": "The code",
        "copy": "Copy",
        "copied": "Copied",
        "nocode": "The code is in the message from whoever invited you: six characters, letters and digits.",
        "steps": "How",
        "step1": "Get Astute.",
        "step2": ("Come back to the message and open this link again: the app takes the code by itself. "
                  "Or type it in the app, under “{row}” in {profile}."),
        "step3": ("Finish your first day, the five cards. The week of Astute+ starts there and then, "
                  "for you and for the friend who invited you."),
        "open": "Open Astute with the code",
        "rules": ("For an account opened less than a week ago that has never had Astute+, one code per account. "
                  "Nothing to pay and nothing to cancel: when the week is over you are back on the free plan. "
                  "Whoever invites gets up to eight weeks a year."),
        "other": "Leggi in italiano",
    },
    "it": {
        "kicker": "Un invito",
        "title": "Una settimana di Astute+, in regalo.",
        "lede": ("Chi ti ha mandato questo link ti regala una settimana di Astute+: cinque carte al giorno tutte tue, "
                 "il tuo viaggio e tutto l’archivio. Finisci la tua prima giornata e la settimana è tua, "
                 "e una ne riceve anche chi ti ha invitato."),
        "code": "Il codice",
        "copy": "Copia",
        "copied": "Copiato",
        "nocode": "Il codice è nel messaggio di chi ti ha invitato: sei caratteri, lettere e cifre.",
        "steps": "Come",
        "step1": "Scarica Astute.",
        "step2": ("Torna al messaggio e apri di nuovo questo link: l’app prende il codice da sola. "
                  "Oppure scrivilo nell’app, alla voce “{row}” in {profile}."),
        "step3": ("Finisci la tua prima giornata, le cinque carte. La settimana di Astute+ parte subito, "
                  "per te e per chi ti ha invitato."),
        "open": "Apri Astute con il codice",
        "rules": ("Vale per un account aperto da meno di una settimana che non ha mai avuto Astute+, "
                  "un codice per account. Niente da pagare e niente da disdire: finita la settimana, "
                  "si torna al piano gratuito. Chi invita riceve fino a otto settimane l’anno."),
        "other": "Read in English",
    },
}

# The app's words for where the code is typed (lib/l10n/app_en.arb,
# app_it.arb: tabProfile, inviteCodeRow).
APP_WORDS = {
    "en": {"profile": "Profile", "row": "Have a code?"},
    "it": {"profile": "Profilo", "row": "Hai un codice?"},
}


def where_it(sentence: bool = False) -> str:
    """chrome.where, in Italian: where the app can be had, as the stores stand."""
    return chrome.where(sentence, "it")


def stores(lang: str = "en") -> str:
    """The two stores' badges, as the site draws them (chrome.stores), in
    [lang]: the store the app is in first. Until the App Store listing is
    live, Google Play's is the button and Apple's comes after it, marked as
    coming and leading to the list for the iPhone."""
    return chrome.stores(lang, play_first=True)


CSS = """.invite-page{position:relative;overflow:hidden}
.invite-glow{position:absolute;left:0;right:0;top:0;height:720px;pointer-events:none;
  background:radial-gradient(60% 70% at 50% 0%,rgba(242,241,236,.10),transparent 70%)}
.invite{position:relative;max-width:600px;margin:0 auto;padding:calc(var(--nav-h) + 40px) var(--gutter) 64px}
.invite+.invite{border-top:1px solid var(--hairline)}
.js .invite{display:none}
.js[data-lang="en"] .invite[lang="en"],.js[data-lang="it"] .invite[lang="it"]{display:block}
.js .invite+.invite{border-top:0}
.invite-top{display:flex;align-items:center;justify-content:space-between;gap:12px;margin:0 0 18px}
.invite-kicker{margin:0;font:700 11px/1.4 var(--font-text);letter-spacing:.14em;text-transform:uppercase;color:var(--cream-60)}
.invite-other{font:500 13px/1.4 var(--font-text);color:var(--cream-60);text-decoration:underline;text-underline-offset:3px}
.invite-title{margin:0;font:500 clamp(36px,9.6vw,60px)/1.02 var(--font-display);letter-spacing:-.03em;font-variation-settings:'opsz' 144;text-wrap:balance}
.invite-lede{margin:16px 0 0;max-width:540px;font:400 16.5px/1.55 var(--font-text);color:var(--cream-70);text-wrap:pretty}
.invite-code{margin:30px 0 0;padding:20px 20px 18px;border-radius:24px;background:var(--cream);color:var(--night);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.6),0 40px 90px -50px rgba(0,0,0,.9)}
.invite-code small{display:block;font:700 11px/1.4 var(--font-text);letter-spacing:.14em;text-transform:uppercase;color:var(--ink-60)}
.invite-code-row{display:flex;align-items:center;justify-content:space-between;gap:14px;margin-top:6px}
.invite-code b{font:600 clamp(40px,12vw,56px)/1 var(--font-display);letter-spacing:.08em;font-variant-numeric:tabular-nums;font-variation-settings:'opsz' 72,'SOFT' 0,'WONK' 0}
.invite-copy{all:unset;box-sizing:border-box;flex:none;display:inline-flex;align-items:center;justify-content:center;min-height:44px;padding:0 18px;border-radius:22px;cursor:pointer;
  border:1.5px solid var(--night);color:var(--night);font:700 14px/1 var(--font-text);transition:background .2s ease,color .2s ease}
@media (hover:hover){.invite-copy:hover{background:var(--night);color:var(--cream)}}
.invite-copy:focus-visible{outline:2px solid var(--night);outline-offset:3px}
.invite-nocode{margin:30px 0 0;padding:14px 16px;border-radius:16px;border:1px solid var(--hairline-strong);font:500 15px/1.5 var(--font-text);color:var(--cream-85)}
.invite-code,.invite-open{display:none}
.has-code .invite-code{display:block}
.has-code .invite-nocode{display:none}
.has-code.android .invite-open{display:flex}
.invite-steps-h{margin:40px 0 4px;font:700 11px/1.4 var(--font-text);letter-spacing:.14em;text-transform:uppercase;color:var(--cream-60)}
.invite-steps{margin:0;padding:0;list-style:none;counter-reset:step}
.invite-steps li{position:relative;padding:18px 0 18px 46px;border-bottom:1px solid var(--hairline);counter-increment:step;font:400 16px/1.5 var(--font-text);color:var(--cream-85);text-wrap:pretty}
.invite-steps li::before{content:counter(step);position:absolute;left:0;top:15px;width:30px;height:30px;border-radius:50%;border:1.5px solid var(--cream-40);
  display:flex;align-items:center;justify-content:center;font:600 15px/1 var(--font-display);color:var(--cream)}
.invite-steps li b{font-weight:600;color:var(--cream)}
.invite-steps .stores{margin-top:14px}
.invite-steps .where{display:block;margin-top:10px;font:500 13px/1.4 var(--font-text);color:var(--cream-50)}
.invite-open{align-items:center;justify-content:center;margin:26px 0 0;width:100%;height:54px;border-radius:27px;
  background:var(--cream);color:var(--night);font:700 16px/1 var(--font-text);text-decoration:none;box-shadow:0 5px 0 0 var(--edge)}
.invite-rules{margin:26px 0 0;font:400 13.5px/1.55 var(--font-text);color:var(--cream-50);text-wrap:pretty}
@media (min-width:768px){.invite{padding-top:calc(var(--nav-h) + 72px)}}
"""

SCRIPT = """(() => {
  const html = document.documentElement;
  // The link: the code, and nothing else is read. A code is what the server
  // could have drawn (functions/src/invite.ts); anything else is no code.
  const query = new URLSearchParams(location.search);
  const raw = (query.get('c') || '').toUpperCase().replace(/[\\s-]+/g, '');
  const code = /^[@ALPHABET@]{@LENGTH@}$/.test(raw) ? raw : null;
  // Out of the address before anything is counted: the site counts the page,
  // never the code. The message the friend was sent still has the link.
  if (query.has('c')) {
    query.delete('c');
    const rest = query.toString();
    history.replaceState(null, '', location.pathname + (rest ? '?' + rest : '') + location.hash);
  }
  if (code) {
    html.classList.add('has-code');
    document.querySelectorAll('[data-code]').forEach(el => { el.textContent = code; });
  }
  // On Android, Chrome hands an intent to the app, or goes to Google Play when
  // it is not there: one button that opens Astute on the code.
  if (/android/i.test(navigator.userAgent)) {
    html.classList.add('android');
    const store = '@PLAY@';
    document.querySelectorAll('[data-open]').forEach(a => {
      if (code) a.href = 'intent://astutetheapp.com/invito?c=' + code + '#Intent;scheme=https;package=@PACKAGE@;S.browser_fallback_url=' + encodeURIComponent(store) + ';end';
    });
  }
  document.querySelectorAll('[data-copy]').forEach(button => button.addEventListener('click', () => {
    if (!code) return;
    const done = () => { button.textContent = button.dataset.copied; };
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(code).then(done, () => {});
  }));
  // The other language, on the same page.
  document.querySelectorAll('[data-switch]').forEach(a => a.addEventListener('click', e => {
    e.preventDefault();
    const to = a.dataset.switch;
    html.dataset.lang = to;
    html.lang = to;
    document.title = document.querySelector('.invite[lang="' + to + '"]').dataset.title;
  }));
  document.title = document.querySelector('.invite[lang="' + (html.dataset.lang || 'en') + '"]').dataset.title;
})();
""".replace("@ALPHABET@", CODE_ALPHABET).replace("@LENGTH@", str(CODE_LENGTH)).replace("@PACKAGE@", PACKAGE).replace("@PLAY@", GOOGLE_PLAY)

# Before the page is drawn: the language the reader chose on the site, or
# else the one the browser asks for, Italian or English, so the page is never
# drawn in the other one first (chrome.lang_script, as every page of the
# site has it).
EARLY = chrome.lang_script("both", "/" + PATH)

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{title_en} · Astute</title>
<meta name="description" content="{description}">
<meta name="robots" content="noindex">
<meta name="theme-color" content="#141416">
<meta name="color-scheme" content="dark">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Astute">
<meta property="og:title" content="{og_title}">
<meta property="og:description" content="{description}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{site}/assets/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<link rel="canonical" href="{url}">
<link rel="icon" type="image/png" sizes="64x64" href="/favicon.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="preload" href="/assets/fonts/figtree-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/assets/fonts/fraunces-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="/assets/site.css">
<style>
{css}</style>
{early}
<script src="/assets/main.js" defer></script>
</head>
<body>
<a class="skip" href="#top">Skip to content</a>
<div class="grain" aria-hidden="true"></div>

{header}

<main class="invite-page" id="top">
<div class="invite-glow" aria-hidden="true"></div>
{sections}
</main>

{footer}
<script>
{script}</script>
</body>
</html>
"""

SECTION = """<section class="invite" id="{lang}" lang="{lang}" data-title="{title_plain} · Astute">
  <div class="invite-top">
    <p class="invite-kicker">{kicker}</p>
    <a class="invite-other" href="#{other_lang}" data-switch="{other_lang}" data-lang-to="{other_lang}" lang="{other_lang}">{other}</a>
  </div>
  <h1 class="invite-title">{title}</h1>
  <p class="invite-lede">{lede}</p>
  <div class="invite-code" aria-live="polite">
    <small>{code}</small>
    <div class="invite-code-row"><b data-code></b><button type="button" class="invite-copy" data-copy data-copied="{copied}">{copy}</button></div>
  </div>
  <p class="invite-nocode">{nocode}</p>
  <a class="invite-open" href="{play}" data-open>{open}</a>
  <h2 class="invite-steps-h">{steps}</h2>
  <ol class="invite-steps">
    <li><b>{step1}</b><div class="stores large">{stores}</div><span class="where">{where}.</span></li>
    <li>{step2}</li>
    <li>{step3}</li>
  </ol>
  <p class="invite-rules">{rules}</p>
</section>"""


def section(lang: str) -> str:
    w = WORDS[lang]
    other = "it" if lang == "en" else "en"
    app = APP_WORDS[lang]
    e = lambda s: html.escape(s, quote=True)  # noqa: E731
    return SECTION.format(
        lang=lang,
        other_lang=other,
        other=e(w["other"]),
        kicker=e(w["kicker"]),
        title=e(w["title"]),
        title_plain=e(w["title"].rstrip(".")),
        lede=e(w["lede"]),
        code=e(w["code"]),
        copy=e(w["copy"]),
        copied=e(w["copied"]),
        nocode=e(w["nocode"]),
        open=e(w["open"]),
        play=GOOGLE_PLAY,
        steps=e(w["steps"]),
        step1=e(w["step1"]),
        stores=stores(lang),
        where=e(where(sentence=True, lang=lang)),
        step2=e(w["step2"].format(profile=app["profile"], row=app["row"])),
        step3=e(w["step3"]),
        rules=e(w["rules"]),
    )


def render() -> str:
    """The page, whole: the site's chrome around the invitation, in English
    and in Italian."""
    return PAGE.format(
        title_en=html.escape(WORDS["en"]["title"].rstrip("."), quote=True),
        og_title=html.escape(WORDS["en"]["title"].rstrip("."), quote=True),
        description=html.escape(
            "A friend is giving you a week of Astute+, five cards a day all your own. "
            "Get the app, use the code, finish your first day.", quote=True),
        url=f"{SITE}/{PATH}",
        site=SITE,
        css=CSS,
        early=EARLY,
        header=chrome.header("both", "/" + PATH),
        sections="\n".join(section(lang) for lang in ("en", "it")),
        footer=chrome.footer("both", "/" + PATH),
        script=SCRIPT,
    )


def write(site: Path) -> Path:
    """Writes the page into [site], where the site serves it at /invito."""
    out = site / f"{PATH}.html"
    out.write_text(render(), encoding="utf-8")
    return out


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    out = write(Path(argv[0]))
    print(f"the invitation's page written to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
